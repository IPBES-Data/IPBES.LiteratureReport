#' Fix: ISSN → standard form
#'
#' Proposes the standard form of the ISSN field (`1234-567X`, several
#' separated by ", ") found by `met_id_issn_form`. Items with an ISSN which
#' is not valid are listed as not proposed.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_issn_form <- function(
  m,
  group_id
) {
  x <- m$identifiers$met_id_issn_form$items
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "ISSN",
    old = x$issn,
    new = dplyr::coalesce(x$standard, ""),
    reason = "ISSN in the standard form",
    proposed = !is.na(x$standard),
    note = ifelse(
      is.na(x$invalid),
      NA_character_,
      paste0(
        "Not a valid ISSN: ", x$invalid,
        ifelse(grepl("^([0-9]{9}[0-9X]|97[89][0-9]{10})$", gsub("-", "", x$invalid)), " (looks like an ISBN)", "")
      )
    )
  )
}
