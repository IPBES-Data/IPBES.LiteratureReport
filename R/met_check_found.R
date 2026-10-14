#' Zotero DOIs found in OpenAlex
#'
#' Valid Zotero DOIs which were / were not found in OpenAlex. A DOI which is
#' not found is either not indexed by OpenAlex or wrong.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#'
#' @return A list with
#' - `zotero_in_oa`: DOIs found, named by item key
#' - `zotero_not_in_oa`: DOIs not found, named by item key
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

  metrics$count_not_in_oa <- length(metrics$zotero_not_in_oa)
  metrics$pc_in_oa <- 100 * mean(found)

  return(metrics)
}
