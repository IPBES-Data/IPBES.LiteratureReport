met_doi_comp <- function(
  zotero,
  openalex
) {
  doi <- met_doi(zotero = zotero, openalex = openalex)

  dois_comp <- list()

  dois_comp$zotero_in_oa <- doi$zotero$doi[
    doi$zotero$doi %in% doi$openalex$doi
  ]
  dois_comp$zotero_not_in_oa <- doi$zotero$doi[
    !(doi$zotero$doi %in% doi$openalex$doi)
  ]
  return(dois_comp)
}
