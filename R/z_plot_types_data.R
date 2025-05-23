#' Used in the pipeline - Plot Types Data
#'
#' This function takes a bibliography object and returns a data frame with the count of each type of publication from both Zotero and OpenAlex.
#'
#' @param bibliography_fn A bibliography object containing publication information.
#'
#' @importFrom dplyr bind_rows group_by summarize arrange mutate select
#' @importFrom utils readRDS
#'
#' @md
#'
#' @return A data frame with the count of each type of publication from both Zotero and OpenAlex.
#'
#' @export
plot_types_data <- function(bibliography_fn) {
  bibliography <- readRDS(bibliography_fn)
  data <- dplyr::bind_rows(
    bibliography$bibliography |>
      dplyr::select(
        type = Item.Type
      ) |>
      dplyr::group_by(
        type
      ) |>
      dplyr::summarize(
        count = n()
      ) |>
      dplyr::arrange(
        desc(count)
      ) |>
      dplyr::mutate(
        from = "Zotero"
      ),
    bibliography$works |>
      dplyr::group_by(
        type
      ) |>
      dplyr::summarize(
        count = n()
      ) |>
      dplyr::arrange(
        desc(count)
      ) |>
      dplyr::mutate(
        from = "OpenAlex"
      )
  )

  dir <- normalizePath(
    file.path("output", "plot_types"),
    mustWork = FALSE
  )
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  file <- file.path(dir, basename(bibliography_fn))

  saveRDS(data, file = file)

  return(file)
}
