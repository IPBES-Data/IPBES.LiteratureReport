#' Fix: language differs from OpenAlex → language from OpenAlex, or keep
#'
#' For items whose language differs from the language of their DOI in
#' OpenAlex (`met_check_language`), offers the language from OpenAlex, or to
#' keep the item as it is: this adds the line `Language checked: correct` to
#' Extra, and the item is no longer listed. Only one can be selected, and
#' neither is selected at the start: OpenAlex detects the language from the
#' title and abstract, and many publications in other languages have an
#' English abstract, so the language in Zotero is often right.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_language_openalex <- function(
  m,
  group_id
) {
  x <- m$openalex_check$met_check_language$items
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  oa <- tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "language",
    old = x$language,
    new = x$language_openalex,
    reason = paste0(
      "Language in OpenAlex (detected from title and abstract, which may be ",
      "in another language than the publication)"
    ),
    proposed = TRUE,
    note = NA_character_,
    doi = x$doi,
    openalex = x$openalex,
    choice = x$key,
    preselect = FALSE
  )

  keep_line <- "Language checked: correct"
  keep <- tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "extra",
    old = x$extra,
    new = as.character(ifelse(x$extra == "", keep_line, paste0(x$extra, "\n", keep_line))),
    reason = paste0(
      "Keep as it is: the language in Zotero is right (adds \"", keep_line,
      "\" to Extra, the item is then no longer listed)"
    ),
    proposed = TRUE,
    note = NA_character_,
    doi = x$doi,
    openalex = x$openalex,
    choice = x$key,
    preselect = FALSE,
    append = keep_line
  )

  dplyr::bind_rows(oa, keep) |>
    dplyr::arrange(match(item_key, x$key), match(field, c("language", "extra")))
}
