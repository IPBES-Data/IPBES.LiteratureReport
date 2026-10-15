#' ISSN not in the standard form
#'
#' Items whose ISSN field is not in the standard form: each ISSN as
#' `1234-567X` (with hyphen, capital X), several separated by ", ". The ISSNs
#' are checked with their check digit. If all are valid, the standard form is
#' proposed; otherwise the item is listed with the ISSNs which are not valid.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `issn` (as entered), `standard`
#'   (standard form, `NA` if an ISSN is not valid) and `invalid` (ISSNs which
#'   are not valid, `NA` if none)
#' - `count`: number of items whose ISSN field is not in the standard form
#' - `count_invalid`: of these, items with an ISSN which is not valid
met_id_issn_form <- function(
  zotero,
  ...
) {
  issn <- zotero$ISSN
  parts <- strsplit(trimws(issn), "[,;[:space:]]+")
  ok <- lapply(parts, issn_valid)
  standard <- vapply(
    seq_along(parts),
    function(i) {
      if (!length(parts[[i]]) || !all(ok[[i]])) return(NA_character_)
      p <- toupper(gsub("-", "", parts[[i]]))
      paste(unique(paste0(substr(p, 1, 4), "-", substr(p, 5, 8))), collapse = ", ")
    },
    ""
  )
  invalid <- vapply(
    seq_along(parts),
    function(i) if (all(ok[[i]])) NA_character_ else paste(parts[[i]][!ok[[i]]], collapse = ", "),
    ""
  )
  wrong <- issn != "" & (is.na(standard) | standard != issn)

  metrics <- list()
  metrics$items <- tibble::tibble(
    key = zotero$Key,
    title = zotero$Title,
    issn = issn,
    standard = standard,
    invalid = invalid
  )[wrong, ]
  metrics$count <- nrow(metrics$items)
  metrics$count_invalid <- sum(!is.na(metrics$items$invalid))

  return(metrics)
}

#' Valid ISSNs
#'
#' @param x ISSNs, with or without hyphen.
#'
#' @return `TRUE` for ISSNs with 8 characters (7 digits and a check digit or
#'   X) whose check digit is right.
issn_valid <- function(
  x
) {
  x <- toupper(gsub("-", "", x))
  vapply(
    x,
    function(v) {
      if (!grepl("^[0-9]{7}[0-9X]$", v)) return(FALSE)
      d <- as.integer(strsplit(substr(v, 1, 7), "")[[1]])
      check <- (11 - sum(d * 8:2) %% 11) %% 11
      substr(v, 8, 8) == if (check == 10) "X" else as.character(check)
    },
    logical(1),
    USE.NAMES = FALSE
  )
}
