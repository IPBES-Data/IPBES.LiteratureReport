#' Fix: no DOI → DOI found in OpenAlex
#'
#' Offers the DOIs of the works found in OpenAlex for items without a DOI, as
#' found by `met_id_candidates`. The works found for an item are alternatives
#' (`choice`): only one of them can be selected. The only likely match of an
#' item (same title, year and first author) is selected at the start
#' (`preselect`), possible matches are not. DOIs used by another item in the
#' group are listed as not proposed.
#'
#' `compare` shows the item and the work found side by side (title, year,
#' first author; journal and type in the details), each marked as the same
#' or different.
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
    preselect = x$single,
    # NULL (no column) for metrics made before the comparison
    compare = if ("same_title" %in% names(x)) compare_candidates(x)
  )
}

# per work found: the item and the work side by side; `more`: only in the
# details
compare_candidates <- function(x) {
  txt <- function(v) dplyr::na_if(as.character(v), "")
  lapply(seq_len(nrow(x)), function(i) {
    list(
      heading = if (x$match[i] == "likely") "Likely match" else "Possible match",
      fields = data.frame(
        label = c("Title", "Year", "Author", "Journal", "Type"),
        zotero = c(txt(x$title[i]), txt(x$year[i]), txt(x$author[i]),
          txt(x$journal[i]), txt(x$type[i])),
        found = c(txt(x$cand_title[i]), txt(x$cand_year[i]),
          txt(x$cand_author[i]), txt(x$cand_journal[i]), txt(x$cand_type[i])),
        same = c(x$same_title[i], x$same_year[i], x$same_author[i], NA, NA),
        more = c(FALSE, FALSE, FALSE, TRUE, TRUE)
      )
    )
  })
}
