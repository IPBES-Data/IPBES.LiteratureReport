#' Retracted works
#'
#' Works flagged as retracted by OpenAlex, with the key of the Zotero item(s)
#' with the same DOI.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#'
#' @return A list with
#' - `items`: tibble with the OpenAlex `id`, `doi`, `title` and the Zotero
#'   item `key`
#' - `count`: number of retracted works
met_check_retracted <- function(
  zotero,
  openalex
) {
  retracted <- openalex |>
    dplyr::filter(
      is_retracted
    ) |>
    dplyr::select(
      id,
      doi,
      title
    ) |>
    dplyr::collect()

  retracted$doi <- openalexPro::extract_doi(
    retracted$doi,
    non_doi_value = as.character(NA),
    what = "doi"
  ) |>
    tolower()

  metrics <- list()

  metrics$items <- retracted |>
    dplyr::left_join(
      as_bib(zotero) |>
        dplyr::select(
          key = id,
          doi
        ),
      by = "doi"
    )

  metrics$count <- nrow(retracted)

  return(metrics)
}
