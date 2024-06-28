#' Make all
#'
#' This function renders the document `index.qmd`. This includes:
#'    - install "devtools" and all dependencies needed for the code to run
#'    - dowlnoad the IPBES Zotero Libraries and store them as `.csv` files in ther folder `input`
#'    - generate the measures and graphs for the reports from all Zotero Libraries in the folde `_targets`
#'    - generate the reports in the folder `output`
#'    - create or update the file `index.html` which contains all the links to the reports
#' @param overwrite If `TRUE, the file `index.html` will be overwritten. Default is `TRUE`.
#' @return Return value from quarto::quarto_render
#' @md
#' @export
#' @importFrom quarto quarto_render
#' @examples
#' \dontrun{
#' make_all(overwrite = FALSE)
#' }
make_all <- function(
    overwrite = TRUE) {
    output <- "index.html"

    if (file.exists(output)) {
        if (overwrite) {
            unlink(output, force = TRUE)
        } else {
            message("Report already exists! Skipping report generation.\n<<<<<<<\n")
            return()
        }
    }

    file.copy(
        from = system.file(package = "IPBES.LiteratureReport", "index.qmd"),
        to = "index.qmd",
        overwrite = TRUE
    )
    on.exit(unlink("index.qmd"))

    quarto::quarto_render(
        file.path("index.qmd")
    )
}
