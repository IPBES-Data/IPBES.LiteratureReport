#' Generate Reports for Assessments
#'
#' This function generates reports for assessments based on the provided bibliography files in the
#' folder `input`. The reports are generated using the `bibliography_report.qmd` Quarto document and
#' will bie located in the `output` folder.
#'
#' @param overwrite Logical value indicating whether to overwrite existing reports. Default is \code{FALSE}.
#' @importFrom quarto quarto_render
#' @md
#' @examples
#' \dontrun{
#' # Generate reports without overwriting existing reports
#' make_reports()
#'
#' # Generate reports and overwrite existing reports
#' make_reports(overwrite = TRUE)
#' }
#' @export
#'
make_reports <- function(
    overwrite = FALSE) {
  ##
  dir.create("output", showWarnings = FALSE)

  bib_names <- list.files(
    path = "input",
    pattern = "IPBES.*\\.csv$"
  ) |>
    gsub(pattern = "\\.csv$", replacement = "")

  # bib_names <- paste0("IPBES.", assessments)

  for (bib_name in bib_names) {
    message(">>>>>>>\nGenerating Report for Assessment ", bib_name, " ...")

    output <- file.path("output", paste0(bib_name, ".bibliography_report.html"))

    if (file.exists(output) & !overwrite) {
      message("Report already exists! Skipping report generation.\n<<<<<<<\n")
      next
    } else {
      unlink(output, force = TRUE)
    }

    quarto::quarto_render(
      file.path("inst/bibliography_report.qmd"),
      execute_params = list(
        bib_name = bib_name,
        targets_store = targets::tar_config_get("store")
      )
    )

    file.rename(
      from = "bibliography_report.html",
      to = output
    )

    message("Generated Report for Assessment ", bib_name, " in ", output, "\n<<<<<<<\n")
  }
}
