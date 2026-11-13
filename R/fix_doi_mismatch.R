#' Fix: DOI points to a different publication → no DOI, the date, or keep
#'
#' For items whose DOI leads to a work with a different title or year
#' (`met_check_mismatch`), proposes to empty the DOI field, showing where the
#' DOI leads. Once the field is empty, the search by title can offer the
#' right DOI. If only the year differs (the titles match), the DOI is likely
#' right and the date in Zotero wrong: then the date from OpenAlex is offered
#' as well, as an alternative to removing the DOI (only one can be selected;
#' remove the DOI if it is another edition, select neither if Zotero has the
#' year of the printed issue and OpenAlex the online date). Not selected at
#' the start: the check uses fixed thresholds, so some items are listed
#' although their DOI is right (e.g. translated or short titles).
#'
#' The last alternative of each item is to keep it as it is: this adds the
#' line `DOI checked: correct` to Extra, and the item is no longer listed
#' (e.g. a book chapter with the DOI of the whole book, or a wrong year in
#' OpenAlex).
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
  if (!"date_openalex" %in% names(x)) {
    x$date_zotero <- NA_character_
    x$date_openalex <- NA_character_
  }
  # NA for metrics made before the column: no "keep" alternative
  if (!"extra" %in% names(x)) {
    x$extra <- NA_character_
  }

  found <- paste0(
    ": ", dplyr::coalesce(x$title_openalex, "(no title)"),
    " (", dplyr::coalesce(as.character(x$year_openalex), "no year"), ")"
  )
  # as flagged by met_check_mismatch
  title_differs <- x$title_similarity < 0.8
  year_differs <- abs(x$year_zotero - x$year_openalex) %in% 2:9999
  date_option <- !title_differs & !is.na(x$date_openalex) & !is.na(x$date_zotero)

  no_doi <- tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title_zotero,
    field = "DOI",
    old = x$doi_raw,
    new = "",
    reason = paste0(
      "The DOI leads to a publication with a different ",
      dplyr::case_when(
        title_differs & year_differs ~
          paste0("title and year (in Zotero: ", x$year_zotero, ")"),
        title_differs ~ "title",
        .default = paste0("year (in Zotero: ", x$year_zotero, ")")
      ),
      found
    ),
    proposed = TRUE,
    note = NA_character_,
    doi = x$doi,
    openalex = x$openalex,
    choice = ifelse(date_option | !is.na(x$extra), x$key, NA_character_),
    preselect = FALSE
  )

  d <- x[date_option, ]
  date <- tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = d$key,
    title = d$title_zotero,
    field = "date",
    old = d$date_zotero,
    new = sub("-01-01$", "", d$date_openalex),
    reason = paste0(
      "The DOI leads to this publication with another year: date from ",
      "OpenAlex. Or remove the DOI (another edition), or keep as it is ",
      "(year of the printed issue, OpenAlex has the online date)"
    ),
    proposed = TRUE,
    note = NA_character_,
    doi = d$doi,
    openalex = d$openalex,
    choice = d$key,
    preselect = FALSE
  )

  # last alternative: keep the item as it is
  k <- x[!is.na(x$extra), ]
  keep_line <- "DOI checked: correct"
  keep <- tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = k$key,
    title = k$title_zotero,
    field = "extra",
    old = k$extra,
    new = as.character(ifelse(k$extra == "", keep_line, paste0(k$extra, "\n", keep_line))),
    reason = paste0(
      "Keep as it is: the DOI is right (e.g. the DOI of the whole book for ",
      "a chapter, or a wrong year in OpenAlex; adds \"", keep_line,
      "\" to Extra, the item is then no longer listed)"
    ),
    proposed = TRUE,
    note = NA_character_,
    doi = k$doi,
    openalex = k$openalex,
    choice = k$key,
    preselect = FALSE,
    append = keep_line
  )

  # alternatives next to each other: the date, no DOI, keep
  dplyr::bind_rows(date, no_doi, keep) |>
    dplyr::arrange(
      match(item_key, x$key),
      match(field, c("date", "DOI", "extra"))
    )
}
