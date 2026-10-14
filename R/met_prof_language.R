#' Languages
#'
#' Languages as entered, and normalised to two letter codes (lower case,
#' region removed, English spellings mapped to `en`). Inconsistent codes in
#' the language as entered are a quality issue in themselves.
#'
#' @param ... One or two data sources: the Zotero items (data frame) and / or
#'   the OpenAlex works (arrow dataset). With two, the measure is computed for
#'   each source and returned as a list named after the arguments.
#'
#' @return A list with
#' - `raw`: tibble with `language` as entered and `count`
#' - `by_language`: tibble with normalised `language` and `count`
#' - `pc_missing`: percentage of items without language
#' - `pc_english`: percentage of items in English
met_prof_language <- function(
  ...
) {
  if (...length() == 2) {
    # two sources: run once per source, keeps names (zotero / openalex)
    return(per_source(met_prof_language, ...))
  }
  if (...length() != 1) {
    stop("met_prof_language() takes one or two data arguments, got ", ...length())
  }

  bib <- as_bib(..1)

  # ponytail: only strips regions ("en-us") and maps English spellings;
  # add a lookup table if other languages show up in several spellings
  language <- sub("[-_].*", "", tolower(trimws(bib$language)))
  language[language %in% c("eng", "english")] <- "en"

  metrics <- list()

  # as entered, inconsistent codes are a quality issue in themselves
  metrics$raw <- bib |>
    dplyr::count(
      language,
      name = "count",
      sort = TRUE
    )

  metrics$by_language <- tibble::tibble(
    language = language
  ) |>
    dplyr::count(
      language,
      name = "count",
      sort = TRUE
    )

  metrics$pc_missing <- 100 * mean(is.na(language))
  metrics$pc_english <- 100 * mean(language %in% "en")

  return(metrics)
}
