#' Prepare folder to run targets pipeline from the package
#'
#' Copies a default `_targets.R` and `groups.csv` file to the specified directory (if not already present).
#'
#' @param dir Path to the directory where the pipeline should run. Default is the current directory.
#' @param script Optional path to a custom _targets.R file. If NULL, uses the package default.
#' @param groups_file Optional path to a custom groups.csv file. If NULL, uses the package default.
#' @param overwrite Logical. Overwrite an existing _targets.R in `dir`? Default is FALSE.
#'
#' @md
#'
#' @export
pipeline_prepare <- function(
  dir = ".",
  template_dir = NULL,
  overwrite = TRUE
) {
  if (dir.exists(dir)) {
    stop(
      "`dir` already exists!\n",
      "  Use `overwrite = TRUE` to overwrite with new template files for the targets pipeline.\n"
    )
  } else {
    dir.create(dir)
  }

  if (is.null(template_dir)) {
    template_dir <- system.file(
      "targets_template",
      package = utils::packageName()
    )
  }

  files <- list.files(
    template_dir,
    recursive = FALSE
  )
  lapply(
    files,
    function(x) {
      file.copy(
        from = file.path(template_dir, x),
        to = dir,
        recursive = TRUE,
        overwrite = overwrite
      )
    }
  ) |>
    unlist() |>
    invisible()
}
