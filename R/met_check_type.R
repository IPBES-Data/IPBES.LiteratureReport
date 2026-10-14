#' Item type agreement
#'
#' Zotero item type compared with the OpenAlex work type for items with the
#' same DOI.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#'
#' @return A list with
#' - `comparison`: tibble with `type_zotero`, `type_openalex` and `count`
met_check_type <- function(
  zotero,
  openalex
) {
  metrics <- list()

  metrics$comparison <- dplyr::inner_join(
    as_bib(zotero) |>
      dplyr::filter(!is.na(doi)) |>
      dplyr::select(doi, type_zotero = type),
    as_bib(openalex) |>
      dplyr::filter(!is.na(doi)) |>
      dplyr::distinct(doi, .keep_all = TRUE) |>
      dplyr::select(doi, type_openalex = type),
    by = "doi"
  ) |>
    dplyr::count(
      type_zotero,
      type_openalex,
      name = "count",
      sort = TRUE
    )

  return(metrics)
}
