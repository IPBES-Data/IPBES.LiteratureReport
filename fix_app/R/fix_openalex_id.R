#' Fix: no OpenAlex ID → OpenAlex ID in Extra field
#'
#' Proposes to add a line `OpenAlex: W…` to the Extra field of items whose DOI
#' was found in OpenAlex, as found by `met_check_openalex_id`. The line is
#' added to the current content of Extra (`append`). Items with a different
#' OpenAlex ID in Extra are listed as not proposed.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_openalex_id <- function(
  m,
  group_id
) {
  x <- m$openalex_check$met_check_openalex_id$items
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  different <- !is.na(x$extra_id)
  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "extra",
    old = x$extra,
    new = ifelse(x$extra == "", x$line, paste0(x$extra, "\n", x$line)),
    reason = "OpenAlex ID of the DOI",
    proposed = !different,
    note = ifelse(
      different,
      paste0("Extra has OpenAlex ", x$extra_id, ", the DOI is ", x$id, " in OpenAlex"),
      NA_character_
    ),
    doi = x$doi,
    append = x$line
  )
}
