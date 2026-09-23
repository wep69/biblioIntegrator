skip_if_no_biblium <- function() {
  testthat::skip_if_not(
    isTRUE(tryCatch(biblium_backend_status()$available, error = function(e) FALSE)),
    "Biblium Python backend is unavailable"
  )
}
