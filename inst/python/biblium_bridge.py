"""Minimal, stable bridge from biblioIntegrator to Biblium 2.16."""
from __future__ import annotations
import pandas as pd
import numpy as np


def _to_frame(x):
    if isinstance(x, pd.DataFrame):
        return x.copy()
    return pd.DataFrame(x)


def compare_groups(records, group_matrix, entity="keyword", permutations=999, random_state=None):
    from biblium.bibgroup import BiblioGroup

    df = _to_frame(records)
    gm = _to_frame(group_matrix)
    gm.index = df.index
    bg = BiblioGroup(
        df=df,
        db="",
        group_desc=gm,
        res_folder=None,
        preprocess_level=0,
        force_type="binary",
    )
    common = dict(
        include_stats=("chi2",),
        min_freq=1,
        filename=None,
        inference="both",
        n_permutations=int(permutations),
        random_state=None if random_state is None else int(random_state),
        permutation_tests=("chi2", "residuals"),
        multiple_testing="bh",
    )
    if entity == "keyword":
        bg.associate_author_keywords(**common)
        rel = bg.author_keywords_associations
        cont = bg.author_keywords_contingency
    elif entity == "author":
        bg.associate_authors(**common)
        rel = bg.authors_associations
        cont = bg.authors_contingency
    else:
        raise ValueError("entity must be 'keyword' or 'author'")

    if rel is None:
        raise ValueError("Biblium selected no entities for the requested analysis")
    obs = np.asarray(cont, dtype=float)
    n = obs.sum()
    expected = np.outer(obs.sum(axis=1), obs.sum(axis=0)) / n if n else np.zeros_like(obs)
    rowp = obs.sum(axis=1) / n if n else np.zeros(obs.shape[0])
    colp = obs.sum(axis=0) / n if n else np.zeros(obs.shape[1])
    den = np.sqrt(expected * np.outer(1-rowp, 1-colp)) if n else np.ones_like(obs)
    stdres = np.divide(obs-expected, den, out=np.zeros_like(obs), where=den>0)
    chi = float(getattr(rel, "permutation_chi2", np.nansum(np.divide((obs-expected)**2, expected, out=np.zeros_like(obs), where=expected>0))))
    denom = n * max(1, min(obs.shape[0]-1, obs.shape[1]-1)) if n else np.nan
    v = float(np.sqrt(chi / denom)) if denom and np.isfinite(denom) else np.nan
    perm_res = getattr(rel, "permutation_residuals", None)
    perm_padj = getattr(rel, "permutation_residuals_p_adj", None)
    return {
        "observed": pd.DataFrame(obs, index=cont.index, columns=cont.columns),
        "expected": pd.DataFrame(expected, index=cont.index, columns=cont.columns),
        "residuals": pd.DataFrame(stdres, index=cont.index, columns=cont.columns),
        "permutation_residuals": perm_res,
        "permutation_residuals_p_adj": perm_padj,
        "chi_square": chi,
        "p_value": float(getattr(rel, "permutation_chi2_p", np.nan)),
        "cramers_v": v,
        "permutations": int(getattr(rel, "permutation_n", permutations)),
        "seed": getattr(rel, "permutation_seed", random_state),
        "disjoint": bool(getattr(rel, "permutation_disjoint", False)),
    }


_BIBLIUM_ENTITIES = {"author": "Authors", "keyword": "Author Keywords", "source": "Sources"}


def _diversity_entity(entity):
    return _BIBLIUM_ENTITIES.get(entity, entity)


def diversity_overall(records, entity="keyword"):
    from biblium.diversity import compute_research_diversity

    df = _to_frame(records)
    res = compute_research_diversity(df, entities=[_diversity_entity(entity)])
    return {"indices": res.to_dataframe(), "summary": res.summary()}


def diversity_temporal(records, entity="keyword", min_items_per_year=5):
    from biblium.diversity import compute_temporal_diversity

    df = _to_frame(records)
    res = compute_temporal_diversity(df, entity=_diversity_entity(entity),
                                     min_items_per_year=int(min_items_per_year))
    return {"series": res.to_dataframe(), "trend": list(res.get_trend())}


def diversity_group(records, group_matrix, entity="keyword"):
    from biblium.diversity import compute_research_diversity

    df = _to_frame(records)
    gm = _to_frame(group_matrix)
    ent = _diversity_entity(entity)
    out = []
    for g in gm.columns:
        sub = df[gm[g].astype(bool).to_numpy()]
        if len(sub) == 0:
            continue
        r = compute_research_diversity(sub, entities=[ent]).to_dataframe()
        r.insert(0, "Group", g)
        out.append(r)
    return {"indices": pd.concat(out, ignore_index=True) if out else pd.DataFrame()}


def representation_year(observed_years, observed_counts, start_year, end_year,
                        threshold=1.0, reference_years=None, reference_counts=None):
    from biblium.representation import compute_relative_representation, fetch_openalex_yearly_counts
    import contextlib
    import io

    obs = pd.DataFrame({"Year": pd.to_numeric(list(observed_years), errors="coerce").astype(int),
                        "Count": list(observed_counts)})
    if reference_years is None:
        ref = fetch_openalex_yearly_counts(start_year=int(start_year), end_year=int(end_year))
    else:
        ref = pd.DataFrame({"Year": pd.to_numeric(list(reference_years), errors="coerce").astype(int),
                            "Count": list(reference_counts)})
    # compute_* imprime diagnosticos no stdout; so o stderr vira warning no R
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        out = compute_relative_representation(obs, ref, category_col="Year",
                                              threshold=float(threshold))
    return {"table": out, "reference": ref[["Year", "Count"]]}


def _plain(o):
    import dataclasses
    import numpy as np

    if dataclasses.is_dataclass(o):
        return {k: _plain(v) for k, v in dataclasses.asdict(o).items()}
    if isinstance(o, dict):
        return {k: _plain(v) for k, v in o.items()}
    if isinstance(o, (list, tuple)):
        return [_plain(v) for v in o]
    if isinstance(o, (np.integer,)):
        return int(o)
    if isinstance(o, (np.floating,)):
        return float(o)
    if isinstance(o, (np.bool_,)):
        return bool(o)
    return o


def compare_means(values, groups, alpha=0.05):
    from biblium.compare_means import compare_means as _cm

    df = pd.DataFrame({"value": list(values), "group": list(groups)})
    res = _cm(df, dependent_var="value", grouping_var="group",
              alpha=float(alpha), verbose=False)
    desc = [_plain(res.overall_descriptives)]
    desc += [dict(d) for d in _plain(res.group_descriptives)]
    norm = [dict(group=g, **_plain(t)) for g, t in _plain(res.normality_tests).items()]
    tests = [_plain(res.parametric_test), _plain(res.nonparametric_test)]
    return {
        "n_groups": int(res.n_groups),
        "n_total": int(res.n_total),
        "recommended_test": res.recommended_test,
        "interpretation": res.interpretation,
        "assumptions_met": bool(res.assumptions_met),
        "descriptives": pd.DataFrame(desc),
        "normality": pd.DataFrame(norm),
        "homogeneity": _plain(res.homogeneity_test),
        "tests": pd.DataFrame([t for t in tests if t]),
        "post_hoc_method": res.post_hoc_method,
        "posthoc": pd.DataFrame(_plain(res.post_hoc_results)),
    }


def main_path(cited_ids, citing_ids, node_ids=None, node_years=None, node_titles=None,
              method="SPC"):
    import networkx as nx
    from biblium.main_path import compute_main_path_analysis

    G = nx.DiGraph()
    G.add_edges_from(zip(list(cited_ids), list(citing_ids)))
    nd = None
    if node_ids is not None:
        nd = {}
        for i, y, t in zip(list(node_ids), list(node_years), list(node_titles)):
            nd[str(i)] = {"year": (None if y is None else int(y)), "title": str(t)}
    res = compute_main_path_analysis(G, method=method, node_data=nd, verbose=False)
    ew = [{"from": str(a), "to": str(b), "weight": float(w)}
          for (a, b), w in res.edge_weights.items()]
    nw = [{"node": str(k), "weight": float(v)} for k, v in res.node_weights.items()]
    docs = [{"node_id": n, **(nd.get(n, {}) if nd else {})} for n in res.global_main_path]
    return {
        "n_nodes": int(res.n_nodes),
        "n_edges": int(res.n_edges),
        "n_sources": int(res.n_sources),
        "n_sinks": int(res.n_sinks),
        "global_main_path": [str(n) for n in res.global_main_path],
        "forward_main_path": [str(n) for n in res.forward_main_path],
        "backward_main_path": [str(n) for n in res.backward_main_path],
        "key_routes": [" > ".join(str(n) for n in r) for r in res.key_routes],
        "path_length": int(res.path_length),
        "path_documents": pd.DataFrame(docs) if docs else pd.DataFrame(),
        "weight_method": res.weight_method,
        "edge_weights": pd.DataFrame(ew) if ew else pd.DataFrame(),
        "node_weights": pd.DataFrame(nw) if nw else pd.DataFrame(),
        "statistics": _plain(res.statistics),
    }


def crosstab(row_values, col_values, alpha=0.05):
    from biblium.crosstabs import compute_crosstab

    df = pd.DataFrame({"row": list(row_values), "col": list(col_values)})
    res = compute_crosstab(df, row_var="row", col_var="col",
                           alpha=float(alpha), verbose=False)
    return {
        "n_rows": int(res.n_rows),
        "n_cols": int(res.n_cols),
        "n_total": int(res.n_total),
        "is_2x2": bool(res.is_2x2),
        "observed": res.observed.reset_index(),
        "expected": res.expected.reset_index(),
        "residuals": res.residuals.reset_index(),
        "chi_squared": _plain(res.chi_squared),
        "fisher": _plain(res.fisher) if res.fisher is not None else None,
        "effect_size": _plain(res.effect_size),
        "interpretation": res.interpretation,
    }


def correlate(values, names, method="pearson", alpha=0.05):
    from biblium.correlation import compute_correlation

    df = pd.DataFrame({str(k): list(v) for k, v in zip(names, values)})
    res = compute_correlation(df, variables=[str(k) for k in names],
                              method=method, alpha=float(alpha), verbose=False)
    return {
        "method": res.method_name,
        "n_significant": int(res.n_significant),
        "n_total_pairs": int(res.n_total_pairs),
        "corr_matrix": res.corr_matrix,
        "p_matrix": res.p_matrix,
        "pairs": pd.DataFrame(_plain(res.pairs)) if res.pairs else pd.DataFrame(),
    }


def citation_patterns(titles, years, citations, dois, use_openalex=True,
                      max_papers=500, min_age=3):
    from biblium.citation_patterns import analyze_citation_patterns

    df = pd.DataFrame({
        "Title": list(titles),
        "Year": list(years),
        "Cited by": list(citations),
        "DOI": list(dois),
    })
    res = analyze_citation_patterns(df, use_openalex=bool(use_openalex),
                                    max_papers=int(max_papers),
                                    min_age=int(min_age), verbose=False)
    return {
        "data_source": res.data_source,
        "n_papers": int(res.n_papers),
        "n_analyzed": int(res.n_analyzed),
        "trajectories": res.to_dataframe(),
        "summary": res.get_pattern_summary(),
    }


def rao_stirling(counts, names):
    from biblium.reference_diversity import compute_rao_stirling

    dist = {str(k): int(v) for k, v in zip(names, counts)}
    return {"rao_stirling": float(compute_rao_stirling(dist, None))}


def geo_countries(titles, years, cited, countries, keywords, authors):
    from biblium.addons.geographic_analysis import analyze_countries

    df = pd.DataFrame({
        "Title": list(titles),
        "Year": list(years),
        "Cited by": list(cited),
        "Country": list(countries),
        "Author Keywords": list(keywords),
        "Authors": list(authors),
    })
    metrics, table = analyze_countries(df, country_col="Country", citations_col="Cited by",
                                       year_col="Year", keywords_col="Author Keywords",
                                       authors_col="Authors", verbose=False)
    return {"n_countries": len(metrics), "table": table}


def topic_models(texts, n_topics=None, max_topics=10, model="LDA"):
    from biblium.utilsbib_modules.topic_modeling import (
        topic_modeling, get_topic_summary, compute_topic_coherence)

    df = pd.DataFrame({"text": list(texts)})
    kw = dict(model_type=model, max_topics=int(max_topics))
    if n_topics is not None:
        kw["n_topics"] = int(n_topics)
    weights_df, topics_df = topic_modeling(df, text_column="text", **kw)
    summary = get_topic_summary(topics_df)
    coher = compute_topic_coherence(df, text_column="text", topics_df=topics_df)
    rows = []
    for tid, terms in summary.items():
        rows.append({"topic": int(tid), "terms": "; ".join(terms),
                     "coherence": float(coher.get(tid, float("nan")))})
    return {"topics": topics_df, "weights": weights_df, "summary": pd.DataFrame(rows)}
def disruption(citing_ids, cited_ids, focal_ids, focal_refs):
    from biblium.disruption import compute_disruption_for_paper

    network = {}
    cited_by = {}
    for a, b in zip(list(citing_ids), list(cited_ids)):
        network.setdefault(str(a), set()).add(str(b))
        cited_by.setdefault(str(b), set()).add(str(a))
    rows = []
    for f, refs in zip(list(focal_ids), list(focal_refs)):
        f = str(f)
        r = compute_disruption_for_paper(f, set(map(str, list(refs))),
                                         set(cited_by.get(f, ())), network, cited_by)
        rows.append({"focal_id": f, "N_i": int(r["n_i"]), "N_j": int(r["n_j"]),
                     "N_k": int(r["n_k"]), "disruption": float(r["cd_index"]),
                     "interpretation": r["interpretation"]})
    return {"table": pd.DataFrame(rows)}


def sdg_labels(titles, abstracts, text="abstract"):
    from biblium.sdg_identifier import identify_sdgs
    import contextlib
    import io

    df = pd.DataFrame({"Title": list(titles), "Abstract": list(abstracts)})
    col = "Abstract" if text == "abstract" else "Title"
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        res = identify_sdgs(df, text_column=col,
                            return_perspectives=False, return_dimensions=False)
    keep = [c for c in res.columns if c.startswith("SDG")]
    out = res[keep].copy()
    out.insert(0, "n_sdgs", out.sum(axis=1).astype(int))
    return {"sdg": out}


def classify_groups(records, group_matrix):
    from biblium.bibclass import BiblioGroupClassifier

    df = _to_frame(records)
    gm = _to_frame(group_matrix)
    gm.index = df.index
    clf = BiblioGroupClassifier(df=df, db="", group_desc=gm, res_folder=None,
                                preprocess_level=0, force_type="binary",
                                text_columns=["Title"])
    clf.prepare_features(features_columns=["Year"])
    import warnings
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        perf = clf.classify_groups(method="cross_validation", multilabel=False)
    rows = []
    for grp, models in perf.items():
        for model, metrics in models.items():
            row = {"group": str(grp), "model": str(model)}
            row.update(_plain(metrics))
            rows.append(row)
    return {"performance": pd.DataFrame(rows) if rows else pd.DataFrame()}
