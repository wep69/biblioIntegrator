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
