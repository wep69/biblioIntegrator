#' Create a Biblium-ready data frame
#' @param x A `biblio_project`.
#' @return A data frame with Biblium canonical field names.
#' @export
#' @examples
#' to_biblium(as_biblio_project(example_biblio()))
#' head(to_biblium(as_biblio_project(example_biblio())),3)
#' names(to_biblium(as_biblio_project(example_biblio())))
to_biblium <- function(x) {
  w=x$works; au=tapply(x$authors$display_name[match(x$authorships$author_id,x$authors$author_id)],x$authorships$work_id,paste,collapse="; "); kw=tapply(x$keywords$keyword,x$keywords$work_id,paste,collapse="; ")
  data.frame(Title=w$title,Year=w$year,Authors=unname(au[w$work_id]),`Author Keywords`=unname(kw[w$work_id]),check.names=FALSE,stringsAsFactors=FALSE)
}

.bi_python <- function(python=NULL) {
  if(!is.null(python)) return(normalizePath(python,winslash="/",mustWork=FALSE))
  e=Sys.getenv("BIBLIOINTEGRATOR_PYTHON",unset=""); if(nzchar(e))return(e)
  o=getOption("biblioIntegrator.python",NULL); if(!is.null(o))return(o)
  NULL
}

#' Status of the optional Biblium Python backend
#' @param python Optional Python executable.
#' @return A list with availability, Python path and Biblium version.
#' @export
#' @examples
#' biblium_backend_status()
#' python_backend_status()
#' names(biblium_backend_status())
.bi_status_cache <- new.env(parent=emptyenv())
biblium_backend_status <- function(python=NULL) {
  if(is.null(python)&&!is.null(.bi_status_cache$status))return(.bi_status_cache$status)
  if(!requireNamespace("reticulate",quietly=TRUE)) return(list(available=FALSE,python=NA_character_,version=NA_character_,reason="reticulate not installed"))
  py=.bi_python(python); if(!is.null(py)) try(reticulate::use_python(py,required=FALSE),silent=TRUE)
  ok=tryCatch(reticulate::py_module_available("biblium"),error=function(e)FALSE)
  ver=if(ok)tryCatch(as.character(reticulate::import("biblium",convert=TRUE)$`__version__`),error=function(e)NA_character_) else NA_character_
  cfg=tryCatch(reticulate::py_config(),error=function(e)NULL)
  res=list(available=isTRUE(ok)&&!is.na(ver),python=if(is.null(cfg)) py %||% NA_character_ else cfg$python,version=ver,reason=if(ok&&!is.na(ver))"ok" else "Biblium could not be imported"); if(is.null(python)).bi_status_cache$status=res; res
}

#' Backward-compatible Python backend status
#' @param python Optional Python executable.
#' @return Same result as [biblium_backend_status()].
#' @export
#' @examples
#' python_backend_status()
#' names(python_backend_status())
#' is.list(python_backend_status())
python_backend_status <- function(python=NULL) biblium_backend_status(python)

#' Install an isolated Biblium backend
#' @param envname Virtual environment name or path.
#' @param python Python executable used to create the environment.
#' @param version Biblium version.
#' @return Invisible virtual environment path.
#' @export
#' @examples
#' \dontrun{
#' install_biblium_backend()
#' install_biblium_backend(version="2.16.0")
#' install_biblium_backend(envname="r-bibliointegrator")
#' }
install_biblium_backend <- function(envname="r-bibliointegrator",python=NULL,version="2.16.0") {
  if(!requireNamespace("reticulate",quietly=TRUE)) stop("Install 'reticulate'.",call.=FALSE)
  if(!reticulate::virtualenv_exists(envname)) reticulate::virtualenv_create(envname=envname,python=python)
  reticulate::py_install(c(paste0("biblium==",version),"huggingface_hub","plotly"),envname=envname,pip=TRUE)
  .bi_status_cache$status <- NULL; p=reticulate::virtualenv_python(envname); message("Set options(biblioIntegrator.python = ",dQuote(p),") before initializing Python."); invisible(p)
}

#' Enable an existing Python backend
#' @param python Python executable.
#' @return Backend status.
#' @export
#' @examples
#' \dontrun{
#' enable_python_backend("path/to/python")
#' enable_python_backend(Sys.which("python"))
#' enable_python_backend(reticulate::virtualenv_python("r-bibliointegrator"))
#' }
enable_python_backend <- function(python) { options(biblioIntegrator.python=python); biblium_backend_status(python) }

#' Compare bibliometric groups with Biblium 2.16
#'
#' Calls the public `BiblioGroup` association interface with permutation inference,
#' then converts the result to the same R structure used by the native engine.
#' @param x A `biblio_project`.
#' @param groups Group definition accepted by [form_groups()].
#' @param entity `"keyword"` or `"author"`.
#' @param permutations Number of Biblium permutations.
#' @param seed Random seed.
#' @param python Optional Python executable.
#' @return A `biblio_group_comparison`.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio()); g <- rep(c("early","late"),6)
#' biblium_compare_groups(x,g,permutations=99,seed=1)
#' biblium_compare_groups(x,cbind(a=1:12<=7,b=1:12>=5),permutations=99,seed=2)
#' biblium_compare_groups(x,g,entity="author",permutations=99,seed=3)
#' }
biblium_compare_groups <- function(x,groups,entity=c("keyword","author"),permutations=999,seed=NULL,python=NULL) {
  entity=match.arg(entity); st=biblium_backend_status(python); if(!isTRUE(st$available))stop("Biblium 2.16 backend is unavailable or not importable.",call.=FALSE)
  path=system.file("python",package="biblioIntegrator"); mod=reticulate::import_from_path("biblium_bridge",path=path,convert=TRUE)
  G=as.data.frame(form_groups(x,groups),check.names=FALSE); ans=mod$compare_groups(to_biblium(x),G,entity=entity,permutations=as.integer(permutations),random_state=if(is.null(seed))NULL else as.integer(seed))
  structure(list(engine="biblium",entity=entity,groups=as.matrix(G),observed=as.matrix(ans$observed),expected=as.matrix(ans$expected),residuals=as.matrix(ans$residuals),chi_square=as.numeric(ans$chi_square),p_value=as.numeric(ans$p_value),cramers_v=as.numeric(ans$cramers_v),cramers_v_ci=c(NA_real_,NA_real_),overlap=!isTRUE(ans$disjoint),permutations=as.integer(ans$permutations),cell_p_adjusted=if(is.null(ans$permutation_residuals_p_adj))NULL else as.matrix(ans$permutation_residuals_p_adj)),class="biblio_group_comparison")
}

#' Cross-validate native and Biblium group inference
#' @param x A `biblio_project`.
#' @param groups Group definition.
#' @param entity Entity type.
#' @param permutations Number of permutations.
#' @param seed Seed used by both engines.
#' @return A comparison data frame and both fitted objects.
#' @export
#' @examples
#' \dontrun{
#' x <- as_biblio_project(example_biblio())
#' g <- rep(c("a", "b"), 6)
#' validate_biblium(x, g, permutations = 99, seed = 1)
#' validate_biblium(x,g,entity="author",permutations=99,seed=2)
#' validate_biblium(x,cbind(a=1:12<=7,b=1:12>=5),permutations=99,seed=3)
#' }
validate_biblium <- function(x,groups,entity=c("keyword","author"),permutations=999,seed=1) {
  entity=match.arg(entity); a=compare_groups(x,groups,entity=entity,permutations=permutations,seed=seed,engine="native"); b=biblium_compare_groups(x,groups,entity=entity,permutations=permutations,seed=seed)
  list(comparison=data.frame(metric=c("chi_square","p_value","cramers_v"),native=c(a$chi_square,a$p_value,a$cramers_v),biblium=c(b$chi_square,b$p_value,b$cramers_v),difference=c(a$chi_square-b$chi_square,a$p_value-b$p_value,a$cramers_v-b$cramers_v)),native=a,biblium=b)
}
