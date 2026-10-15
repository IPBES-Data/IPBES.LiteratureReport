#' Language not given as a standard code
#'
#' Items whose language is not given as a standard language code, i.e. a
#' two-letter ISO 639-1 code, optionally with a region (`en`, `en-US`), but
#' e.g. as a name (`English`), a three-letter code (`eng`) or in a different
#' spelling (`EN`, `en_us`). Citation styles and other tools only recognise the
#' codes. Where the value is recognised, the standard code is proposed, based
#' on the ISO 639-2 list (R package ISOcodes): codes, three-letter codes and
#' the English names of the languages. Other values, e.g. names in the language
#' itself, several languages or other text, are listed without a proposal.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param ... Not used. Takes `openalex` when called by [get_metrics()].
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `language` (as entered) and `code`
#'   (proposed standard code, `NA` if not recognised)
#' - `count`: number of items whose language is not a standard code
#' - `count_recognised`: of these, items for which a code is proposed
#' - `pc`: percentage of all items whose language is not a standard code
met_meta_language <- function(
  zotero,
  ...
) {
  language <- zotero$Language
  code <- language_code(language)
  wrong <- trimws(language) != "" & (is.na(code) | code != language)

  metrics <- list()

  metrics$items <- tibble::tibble(
    key = zotero$Key,
    title = zotero$Title,
    language = language,
    code = code
  )[wrong, ]

  metrics$count <- nrow(metrics$items)
  metrics$count_recognised <- sum(!is.na(metrics$items$code))
  metrics$pc <- 100 * metrics$count / nrow(zotero)

  return(metrics)
}
