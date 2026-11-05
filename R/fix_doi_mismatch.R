#' Fix: DOI points to a different publication → no DOI
#'
#' For items whose DOI leads to a work with a different title or year
#' (`met_check_mismatch`), proposes to empty the DOI field, showing where the
#' DOI leads. Not selected at the start: the check uses fixed thresholds, so
#' some items are listed although their DOI is right (e.g. translated or
#' short titles). Once the field is empty, the search by title can offer the
#' right DOI.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_doi_mismatch <- function(
  m,
  group_id
) {
  x <- m$openalex_check$met_check_mismatch$items
  if (is.null(x) || nrow(x) == 0 || !"doi_raw" %in% names(x)) {
    return(no_changes())
  }

  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title_zotero,
    field = "DOI",
    old = x$doi_raw,
    new = "",
    reason = paste0(
      "The DOI leads to a publication with a different ",
      # as flagged by met_check_mismatch
      dplyr::case_when(
        x$title_similarity < 0.8 & abs(x$year_zotero - x$year_openalex) %in% 2:9999 ~
          paste0("title and year (in Zotero: ", x$year_zotero, ")"),
        x$title_similarity < 0.8 ~ "title",
        .default = paste0("year (in Zotero: ", x$year_zotero, ")")
      ),
      ": ", dplyr::coalesce(x$title_openalex, "(no title)"),
      " (", dplyr::coalesce(as.character(x$year_openalex), "no year"), ")"
    ),
    proposed = TRUE,
    note = NA_character_,
    doi = x$doi,
    openalex = x$openalex,
    preselect = FALSE
  )
}
