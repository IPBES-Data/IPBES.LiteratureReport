#' OpenAlex works for DOIs
#'
#' Looks up DOIs in OpenAlex, 50 per request. DOIs which are not found, or
#' cannot be looked up (e.g. no network), are left out.
#'
#' @param dois DOIs.
#'
#' @return Named character vector: OpenAlex work URLs, named by lower case DOI.
openalex_ids <- function(
  dois
) {
  dois <- unique(tolower(dois[!is.na(dois) & dois != ""]))
  ids <- character()
  for (chunk in split(dois, ceiling(seq_along(dois) / 50))) {
    res <- tryCatch(
      httr2::request("https://api.openalex.org/works") |>
        httr2::req_url_query(
          filter = paste0("doi:", paste(chunk, collapse = "|")),
          select = "id,doi",
          `per-page` = 50
        ) |>
        httr2::req_timeout(15) |>
        httr2::req_perform() |>
        httr2::resp_body_json(),
      error = function(e) NULL
    )
    for (w in res$results) {
      ids[tolower(sub("^https://doi.org/", "", w$doi))] <- w$id
    }
  }
  return(ids)
}

#' Link to resolve a DOI at doi.org, or an empty string
#'
#' DOIs come from the Zotero data, so they are encoded for the URL and
#' escaped for HTML.
doi_link <- function(
  doi
) {
  ifelse(
    is.na(doi) | doi == "",
    "",
    paste0(
      '<br><a href="https://doi.org/',
      htmltools::htmlEscape(utils::URLencode(doi), attribute = TRUE),
      '" target="_blank">DOI</a>'
    )
  )
}

#' Link to an OpenAlex work, or an empty string
openalex_link <- function(
  id
) {
  ifelse(
    is.na(id),
    "",
    paste0('<br><a href="', id, '" target="_blank">OpenAlex</a>')
  )
}
