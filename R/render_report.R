#' Render a Quarto report into the report folder
#'
#' Renders `qmd` in a temporary directory, so that no intermediate files are
#' left in `input/`, and copies the resulting self-contained HTML file to
#' `output_file`.
#'
#' @param qmd Path to the Quarto template.
#' @param output_file Path of the HTML file to create, e.g.
#'   `output/report/index.html`.
#' @param params List of parameters passed to the template.
#' @param title Title of the report.
#'
#' @return Path to the HTML file.
render_report <- function(
  qmd,
  output_file,
  params,
  title
) {
  dir <- tempfile("report_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))

  file.copy(qmd, dir)

  quarto::quarto_render(
    input = file.path(dir, basename(qmd)),
    output_file = basename(output_file),
    execute_params = params,
    metadata = list(title = title),
    quiet = TRUE
  )

  dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
  file.copy(
    file.path(dir, basename(output_file)),
    output_file,
    overwrite = TRUE
  )

  return(output_file)
}
