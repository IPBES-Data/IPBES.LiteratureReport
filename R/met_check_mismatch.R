#' Wrong DOIs
#'
#' Items whose DOI points in OpenAlex to a work with a different title or
#' year, which usually means that the wrong DOI is attached to the item. An
#' item is flagged when the title similarity (normalised Levenshtein
#' distance) is below 0.8 or the years differ by more than one.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#'
#' @return A list with
#' - `items`: tibble with `key`, `doi`, `title_zotero`, `title_openalex`,
#'   `title_similarity`, `year_zotero` and `year_openalex`
#' - `count`: number of flagged items
#' - `pc`: percentage of the items found in OpenAlex which are flagged
met_check_mismatch <- function(
  zotero,
  openalex
) {
  pairs <- dplyr::inner_join(
    as_bib(zotero) |>
      dplyr::filter(!is.na(doi)),
    as_bib(openalex) |>
      dplyr::filter(!is.na(doi)) |>
      dplyr::distinct(doi, .keep_all = TRUE),
    by = "doi",
    suffix = c("_zotero", "_openalex")
  )

  norm <- function(x) tolower(gsub("[^[:alnum:]]", "", x))
  a <- norm(pairs$title_zotero)
  b <- norm(pairs$title_openalex)

  distance <- vapply(
    seq_along(a),
    function(i) as.numeric(utils::adist(a[i], b[i])),
    numeric(1)
  )
  pairs$title_similarity <- 1 - distance / pmax(nchar(a), nchar(b), 1)
  pairs$year_diff <- abs(pairs$year_zotero - pairs$year_openalex)

  metrics <- list()

  # ponytail: fixed thresholds (title similarity < 0.8, year off by more
  # than 1, as online-first often shifts the year by 1); tune on real cases
  metrics$items <- pairs |>
    dplyr::filter(
      title_similarity < 0.8 | year_diff > 1
    ) |>
    dplyr::select(
      key = id_zotero,
      doi,
      title_zotero,
      title_openalex,
      title_similarity,
      year_zotero,
      year_openalex
    )

  metrics$count <- nrow(metrics$items)
  metrics$pc <- 100 * metrics$count / nrow(pairs)

  return(metrics)
}
