make_report <- function(
    x = groups(),
    overwrite = FALSE) {
    dir.create("output", showWarnings = FALSE)

    for (i in names(x)) {
        message(">>>>>>>\nGenerating Report for group ", i, " ...")

        output <- file.path("output", paste0(x, ".bibliography_report.html"))

        if (file.exists(output) & !overwrite) {
            message("Report already exists! Skipping report generation.\n<<<<<<<\n")
            next
        } else {
            unlink(output, force = TRUE)
        }

        quarto::quarto_render(
            "bibliography_report.qmd",
            execute_params = list(bib_name = bib_name)
        )

        file.rename(
            from = "bibliography_report.html",
            to = output,
            overwrite = TRUE
        )

        message("Generated Report for group ", i, "!\n<<<<<<<\n")
    }
}
