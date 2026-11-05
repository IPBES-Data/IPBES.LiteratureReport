#' Zotero DOIs found in OpenAlex
#'
#' Valid Zotero DOIs which were / were not found in OpenAlex. A DOI which is
#' not found is either not indexed by OpenAlex or wrong (see
#' `met_id_doi_exists` for DOIs which do not exist). DOIs of works which
#' OpenAlex has under another DOI (e.g. the old and the new DOI of an
#' article) count as found.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#'
#' @return A list with
#' - `zotero_in_oa`: DOIs found, named by item key (for works OpenAlex has
#'   under another DOI: that DOI)
#' - `zotero_not_in_oa`: DOIs not found, named by item key
#' - `other_doi`: tibble with `key`, `doi` (in Zotero) and `oa_doi` of the
#'   works OpenAlex has under another DOI
#' - `count_not_in_oa`: number of DOIs not found
#' - `pc_in_oa`: percentage of valid Zotero DOIs found
met_check_found <- function(
  zotero,
  openalex
) {
  doi <- met_id_doi(zotero = zotero, openalex = openalex)

  found <- doi$zotero$doi %in% doi$openalex$doi

  metrics <- list()

  metrics$zotero_in_oa <- doi$zotero$doi[found]
  metrics$zotero_not_in_oa <- doi$zotero$doi[!found]

  metrics$other_doi <- if ("DOI.OpenAlex" %in% names(zotero)) {
    x <- zotero[!is.na(zotero$DOI.OpenAlex), ]
    tibble::tibble(
      key = x$Key,
      doi = openalexPro::extract_doi(x$DOI, non_doi_value = NA_character_, what = "doi"),
      oa_doi = x$DOI.OpenAlex
    )
  } else {
    tibble::tibble(key = character(), doi = character(), oa_doi = character())
  }

  metrics$count_not_in_oa <- length(metrics$zotero_not_in_oa)
  metrics$pc_in_oa <- 100 * mean(found)

  return(metrics)
}
