#' Fix: DOI does not exist → corrected DOI, or no DOI
#'
#' For items whose DOI does not exist at doi.org (`met_id_doi_exists`):
#' where the DOI without extra characters at the end exists, proposes that
#' DOI (selected at the start); otherwise proposes to empty the DOI field
#' (not selected at the start: the right DOI may be found by hand, and once
#' the field is empty, the search by title can offer one).
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_doi_exists <- function(
  m,
  group_id
) {
  x <- m$identifiers$met_id_doi_exists$items
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  fixed <- !is.na(x$suggestion)
  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "DOI",
    old = x$doi_raw,
    new = dplyr::coalesce(x$suggestion, ""),
    reason = ifelse(
      fixed,
      "The DOI does not exist; without the characters at the end it does",
      "The DOI does not exist (doi.org)"
    ),
    proposed = TRUE,
    note = NA_character_,
    doi = ifelse(fixed, x$suggestion, x$doi),
    preselect = fixed
  )
}
