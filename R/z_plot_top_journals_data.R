#' Used in the pipeline - Plot Top Journals Data
#'
#' This function takes a bibliography object and returns a data frame with the
#' top 50 journals based on the number of publications.
#'
#' @param bibliography A bibliography object.
#'
#' @importFrom dplyr group_by summarise rename filter slice_max
#'
#' @return A data frame with the top 50 journals and their publication counts.
#'
#' @md
#' @examples
#' \dontrun{
#' bibliography <- read_bibliography("path/to/bibliography.csv")
#' plot_top_journals_data(bibliography)
#' }
#'
#' @export
plot_top_journals_data <- function(bibliography_fn) {
    bibliography <- readRDS(bibliography_fn)
    data <- bibliography$bibliography |>
        dplyr::group_by(
            Publication.Title
        ) |>
        dplyr::summarise(
            count = n()
        ) |>
        dplyr::rename(
            Journal = Publication.Title
        ) |>
        dplyr::filter(
            Journal != ""
        ) |>
        dplyr::slice_max(
            count,
            n = 50
        )

    dir <- normalizePath(
        file.path("output", "plot_top_journals"),
        mustWork = FALSE
    )
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)

    file <- file.path(dir, basename(bibliography_fn))

    saveRDS(data, file = file)

    return(file)
}
