#' Fix: OpenAlex ID in Extra not valid → corrected
#'
#' For items whose `OpenAlex: …` line in Extra is not valid (see
#' `met_check_extra_id`): if the item's DOI is in OpenAlex, its OpenAlex lines
#' are replaced by one line with the ID of the DOI. Otherwise lines which are
#' not an OpenAlex ID or not in OpenAlex are removed; a different publication
#' or several IDs are listed as not proposed (they need a decision).
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_extra_id <- function(
  m,
  group_id
) {
  x <- m$openalex_check$met_check_extra_id$items
  if (is.null(x) || nrow(x) == 0 || !"extra" %in% names(x)) {
    return(no_changes())
  }

  # one change per item
  problems <- tapply(x$problem, x$key, function(p) paste(unique(p), collapse = "; "))
  x <- x[!duplicated(x$key), ]
  x$problem <- unname(problems[x$key])

  # Extra without its OpenAlex lines
  rest <- gsub("(?mi)^OpenAlex:[^\n]*(\n|$)", "", x$extra, perl = TRUE)
  rest <- sub("\n+$", "", gsub("\n{2,}", "\n", rest))
  line <- ifelse(is.na(x$doi_id), "", paste0("OpenAlex: ", x$doi_id))
  new <- ifelse(rest == "", line, ifelse(line == "", rest, paste0(rest, "\n", line)))
  removable <- grepl("^(Not an OpenAlex ID|Not in OpenAlex[^;]*)(; (Not an OpenAlex ID|Not in OpenAlex[^;]*))*$", x$problem)
  proposed <- !is.na(x$doi_id) | removable

  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "extra",
    old = x$extra,
    new = new,
    reason = paste0(
      x$problem, ": ",
      ifelse(is.na(x$doi_id), "line removed", paste0("ID of the DOI (", x$doi_id, ")"))
    ),
    proposed = proposed,
    note = ifelse(proposed, NA_character_, paste0(x$problem, ": check by hand")),
    doi = NA_character_
  )
}
