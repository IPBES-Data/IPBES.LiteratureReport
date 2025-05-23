#' Run a targets pipeline from the package
#'
#' Runs `pipeline_prepare() and then runs `tar_make()` there.
#'
#' @param dir Path to the directory where the pipeline should run. Default is the current directory.
#' @param ... Additional arguments passed to `targets::tar_make()`.
#'
#' @importFrom targets tar_visnetwork
#' @importFrom withr with_dir
#'
#' @md
#'
#' @export
pipeline_make <- function(
  dir = ".",
  ...
) {
  # run the pipeline inside the target directory
  withr::with_dir(dir, {
    targets::tar_make(...)
  })
}
