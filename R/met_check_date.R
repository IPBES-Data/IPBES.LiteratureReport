#' Missing dates found in OpenAlex
#'
#' Items without a date whose DOI was found in OpenAlex: the publication date
#' in OpenAlex is proposed. OpenAlex gives 1 January when only the year is
#' known, so such dates are proposed as the year only. Items whose DOI points
#' to a different publication are left out.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `doi` and `date` (the publication
#'   date in OpenAlex, `YYYY-MM-DD`, or `YYYY` if only the year is known)
#' - `count`: number of items without a date for which OpenAlex has one
met_check_date <- function(
  zotero,
  openalex
) {
  metrics <- list()

  if (!"publication_date" %in% names(openalex)) {
    metrics$items <- tibble::tibble(
      key = character(),
      title = character(),
      doi = character(),
      date = character()
    )
    metrics$count <- 0L
    return(metrics)
  }

  works <- openalex |>
    dplyr::select(
      doi,
      publication_date
    ) |>
    dplyr::collect()
  items <- oa_join(zotero, openalex, works)
  items <- items[items$Date == "" & !is.na(items$publication_date), ]

  metrics$items <- tibble::tibble(
    key = items$Key,
    title = items$Title,
    doi = items$doi,
    date = sub("-01-01$", "", as.character(as.Date(items$publication_date)))
  )
  metrics$count <- nrow(metrics$items)

  return(metrics)
}
