#' DOIs which do not exist
#'
#' Items whose DOI field contains a DOI in the right form which does not exist
#' at doi.org: usually a typo, a shortened DOI, or a DOI with extra
#' characters at the end (`.`, `;`, a link to supplementary material). Only
#' DOIs which are not found in OpenAlex are checked at doi.org. Where the DOI
#' without the extra characters at the end exists, it is given as
#' suggestion.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#' @param doi_check DOIs looked up one by one, as saved by
#'   [get_doi_check()].
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `doi_raw` (content of the DOI
#'   field), `doi` and `suggestion` (existing DOI without the extra
#'   characters, `NA` if none)
#' - `count`: number of items with a DOI which does not exist
#' - `count_unchecked`: number of DOIs which could not be checked (no answer
#'   from OpenAlex or doi.org)
#' - `pc`: percentage of the items with a valid DOI whose DOI does not exist
met_id_doi_exists <- function(
  zotero,
  ...,
  doi_check = NULL
) {
  bib <- as_bib(zotero)
  bib <- bib[!is.na(bib$doi), ]
  check <- if (is.null(doi_check)) {
    tibble::tibble(doi = character(), registered = logical(), suggestion = character())
  } else {
    doi_check
  }
  m <- match(bib$doi, check$doi)
  missing <- !is.na(m) & check$registered[m] %in% FALSE

  metrics <- list()

  metrics$items <- tibble::tibble(
    key = bib$id,
    title = bib$title,
    doi_raw = bib$doi_raw,
    doi = bib$doi,
    suggestion = check$suggestion[m]
  )[missing, ]

  metrics$count <- nrow(metrics$items)
  metrics$count_unchecked <- sum(!is.na(m) & is.na(check$registered[m]))
  metrics$pc <- 100 * metrics$count / max(nrow(bib), 1)

  return(metrics)
}
