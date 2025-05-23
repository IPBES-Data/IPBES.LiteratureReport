#' Plot a targets pipeline as a visNetwork graph
#'
#' This function temporarily runs `tar_visnetwork()` in the specified directory
#' using the `_targets.R` file found there.
#'
#' @param dir Directory containing the `_targets.R` file and pipeline metadata.
#' @param ... Additional arguments passed to `targets::tar_visnetwork()`
#'
#' @importFrom targets tar_visnetwork
#'
#' @return A `visNetwork` object (plotted interactively).
#' @export
pipeline_visnetwork <- function(dir = ".", ...) {
  if (!file.exists(file.path(dir, "_targets.R"))) {
    stop("No _targets.R file found in directory: ", dir, call. = FALSE)
  }

  withr::with_dir(dir, {
    targets::tar_visnetwork(...)
  })
}
