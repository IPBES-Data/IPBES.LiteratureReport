#' Fix: language → language code
#'
#' Proposes to replace the language by the standard language code found by
#' `met_meta_language` (`English` → `en`, `EN` → `en`, `en_US` → `en-US`).
#' Values which were not recognised are listed as not proposed.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#' @param group_id Zotero group id.
fix_language <- function(
  m,
  group_id
) {
  x <- m$metadata$met_meta_language$items
  if (is.null(x) || nrow(x) == 0) {
    return(no_changes())
  }

  tibble::tibble(
    group_id = as.numeric(group_id),
    item_key = x$key,
    title = x$title,
    field = "language",
    old = x$language,
    new = dplyr::coalesce(x$code, ""),
    reason = "Language not given as a language code",
    proposed = !is.na(x$code),
    note = ifelse(is.na(x$code), "Language not recognised", NA_character_)
  )
}
