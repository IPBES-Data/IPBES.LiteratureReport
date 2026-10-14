#' DOI coverage
#'
#' Number and share of items with a valid DOI, and items whose DOI field is
#' filled but contains no valid DOI. DOIs are extracted with
#' `openalexPro::extract_doi()` and lower cased.
#'
#' @param ... One or two data sources: the Zotero items (data frame) and / or
#'   the OpenAlex works (arrow dataset). With two, the measure is computed for
#'   each source and returned as a list named after the arguments.
#'
#' @return A list with
#' - `doi_raw`: content of the DOI field, named by item key / OpenAlex id
#' - `doi`: valid DOIs, named by item key / OpenAlex id
#' - `invalid`: filled DOI fields without a valid DOI
#' - `count`: number of valid DOIs
#' - `count_invalid`: number of invalid DOI fields
#' - `pc`: percentage of items with a valid DOI
met_id_doi <- function(
  ...
) {
  if (...length() == 2) {
    # two sources: run once per source, keeps names (zotero / openalex)
    return(per_source(met_id_doi, ...))
  }
  if (...length() != 1) {
    stop("met_id_doi() takes one or two data arguments, got ", ...length())
  }

  bib <- as_bib(..1)

  metrics <- list()

  metrics$doi_raw <- stats::setNames(bib$doi_raw, bib$id)
  metrics$doi <- stats::setNames(bib$doi, bib$id)

  metrics$invalid <- metrics$doi_raw[
    !is.na(metrics$doi_raw) & is.na(metrics$doi)
  ]

  metrics$doi <- metrics$doi[
    !is.na(metrics$doi)
  ]

  metrics$count <- length(metrics$doi)
  metrics$count_invalid <- length(metrics$invalid)

  metrics$pc <- 100 * metrics$count / nrow(bib)

  return(metrics)
}
