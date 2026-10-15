#' Fix: DOI from the URL or Extra field into the DOI field
#'
#' Proposes to set the empty DOI field of items for which
#' `met_id_doi_misplaced` found a DOI in the URL or Extra field. Items with
#' different DOIs in URL and Extra are not proposed. The plugin rejects items
#' whose type has no DOI field (the DOI is fine in Extra there).
#'
#' All `fix_*` functions take the metrics of a group and its id and return a
#' tibble with `group_id`, `item_key`, `title`, `field`, `old`, `new`,
#' `reason`, `proposed` and `note`, and optionally `doi` (the item's DOI, for
#' the DOI and OpenAlex links, if the field changed is not the DOI field),
#' `choice` (rows with the same value are alternatives, of which only one can
#' be selected) and `preselect` (`FALSE` for rows not selected at the start).
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_doi_misplaced <- function(
  m,
  group_id
) {
  x <- m$identifiers$met_id_doi_misplaced$items
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  ambiguous <- !is.na(x$doi_in_url) &
    !is.na(x$doi_in_extra) &
    x$doi_in_url != x$doi_in_extra

  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "DOI",
    old = "",
    new = dplyr::coalesce(x$doi_in_url, x$doi_in_extra),
    reason = ifelse(
      !is.na(x$doi_in_url),
      "DOI found in the URL field",
      "DOI found in the Extra field"
    ),
    proposed = !ambiguous,
    note = ifelse(ambiguous, "Different DOIs in URL and Extra", NA_character_)
  )
}

#' No changes, in the form returned by the `fix_*` functions
no_changes <- function() {
  tibble::tibble(
    group_id = numeric(),
    item_key = character(),
    title = character(),
    field = character(),
    old = character(),
    new = character(),
    reason = character(),
    proposed = logical(),
    note = character()
  )
}
