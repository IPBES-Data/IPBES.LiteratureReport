#' Version of this repository
#'
#' The version of the pipeline, the fix app and the website, from the file
#' `VERSION` (changes in `CHANGELOG.md`).
#'
#' @param file The file with the version.
#'
#' @return The version, e.g. `"0.3.0"`.
repo_version <- function(
  file = "VERSION"
) {
  trimws(readLines(file, n = 1, warn = FALSE))
}
