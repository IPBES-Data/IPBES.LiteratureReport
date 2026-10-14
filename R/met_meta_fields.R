#' Filled fields per item type
#'
#' Percentage of items with a filled field, per item type, for the main
#' fields: Title, Author, Publication Year, Publication Title, Publisher, DOI,
#' ISBN, ISSN, Url, Abstract Note and Language. Not every field is expected
#' for every item type, e.g. reports have no Publication Title.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `pc_filled`: tibble with one row per item type: `type`, `count` and the
#'   percentage of items with a filled field, one column per field
met_meta_fields <- function(
  zotero,
  ...
) {
  fields <- c(
    "Title",
    "Author",
    "Publication.Year",
    "Publication.Title",
    "Publisher",
    "DOI",
    "ISBN",
    "ISSN",
    "Url",
    "Abstract.Note",
    "Language"
  )

  metrics <- list()

  metrics$pc_filled <- zotero |>
    dplyr::group_by(
      type = Item.Type
    ) |>
    dplyr::summarise(
      count = dplyr::n(),
      dplyr::across(
        dplyr::all_of(fields),
        ~ 100 * mean(.x != "")
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      dplyr::desc(count)
    )

  return(metrics)
}
