#' Fix: no language → language from OpenAlex or detected from the abstract
#'
#' Proposes a language for the items with an empty language field found by
#' `met_meta_language_missing`: the language of the DOI in OpenAlex, or else
#' the language detected from the abstract. Selected at the start: the field
#' is empty, so nothing is overwritten. Items for which no language was found
#' are not listed.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_language_missing <- function(
  m,
  group_id
) {
  x <- m$metadata$met_meta_language_missing$items
  if (!is.null(x)) x <- x[!is.na(x$language), ]
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "language",
    old = "",
    new = x$language,
    reason = ifelse(
      x$source == "openalex",
      "Language of the DOI in OpenAlex (detected from title and abstract)",
      "Language detected from the abstract"
    ),
    proposed = TRUE,
    note = "Language of the title or abstract, which may differ from the language of the publication",
    doi = x$doi
  )
}
