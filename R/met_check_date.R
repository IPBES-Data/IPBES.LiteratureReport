#' Missing dates found in OpenAlex
#'
#' Items without a date whose DOI was found in OpenAlex: the publication date
#' in OpenAlex is proposed. OpenAlex gives 1 January when only the year is
#' known, so such dates are proposed as the year only.
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
  empty <- tibble::tibble(
    key = character(),
    title = character(),
    doi = character(),
    date = character()
  )

  if (!"publication_date" %in% names(openalex)) {
    metrics$items <- empty
    metrics$count <- 0L
    return(metrics)
  }

  bib <- as_bib(zotero)
  missing <- bib[zotero$Date == "" & !is.na(bib$doi), c("id", "title", "doi")]

  works <- openalex |>
    dplyr::select(
      doi,
      publication_date
    ) |>
    dplyr::collect()
  works$doi <- openalexPro::extract_doi(
    works$doi,
    non_doi_value = as.character(NA),
    what = "doi"
  ) |>
    tolower()
  works <- works[!is.na(works$doi) & !is.na(works$publication_date), ] |>
    dplyr::distinct(doi, .keep_all = TRUE)

  items <- dplyr::inner_join(missing, works, by = "doi")
  date <- sub("-01-01$", "", as.character(as.Date(items$publication_date)))

  metrics$items <- tibble::tibble(
    key = items$id,
    title = items$title,
    doi = items$doi,
    date = date
  )
  metrics$count <- nrow(metrics$items)

  return(metrics)
}
