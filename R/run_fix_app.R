#' Start the app to fix Zotero groups
#'
#' Opens the local app in the browser. It proposes fixes for the problems found
#' by the metrics and sends them to Zotero through the Zotero Safe Edit plugin,
#' where they have to be approved. Needs Zotero running on this computer with
#' the plugin installed. Not part of the pipeline.
#'
#' @param project Project directory (with `input/`, `output/` and `R/`).
#'
#' @return Called for its side effect.
run_fix_app <- function(
  project = getwd()
) {
  options(fix_app.project = normalizePath(project))
  shiny::runApp(file.path(project, "fix_app"), launch.browser = TRUE)
}
