#' Fix: no DOI → DOI found in OpenAlex
#'
#' Offers the DOIs of the works found in OpenAlex for items without a DOI, as
#' found by `met_id_candidates`. The works found for an item are alternatives
#' (`choice`): only one of them can be selected. The only likely match of an
#' item (same title, year and first author) is selected at the start
#' (`preselect`), possible matches are not. DOIs used by another item in the
#' group are listed as not proposed.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_doi_candidates <- function(
  m,
  group_id
) {
  x <- m$identifiers$met_id_candidates$items
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "DOI",
    old = "",
    new = x$doi,
    reason = paste0(
      ifelse(x$match == "likely", "Likely match", "Possible match"),
      ": ", x$cand_title, " (", x$cand_year, ", ",
      dplyr::coalesce(x$cand_author, "no author"),
      ifelse(is.na(x$cand_journal), "", paste0(", ", x$cand_journal)), ")"
    ),
    proposed = is.na(x$note),
    note = ifelse(is.na(x$note), NA_character_, paste0(x$note, ": ", x$doi)),
    doi = x$doi,
    openalex = x$id,
    choice = x$key,
    preselect = x$single
  )
}
