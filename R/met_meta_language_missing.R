#' No language
#'
#' Items with an empty language field, with a proposed language where one is
#' found:
#'
#' - from OpenAlex, for items whose DOI is in OpenAlex with a language;
#' - otherwise detected from the abstract in Zotero with the Compact Language
#'   Detector 2 (R package cld2, a statistical method based on letter
#'   sequences, not AI), if the abstract is at least 100 characters long and
#'   the result reliable.
#'
#' Both give the language of the title or abstract, not necessarily of the
#' publication: many publications in other languages have an English
#' abstract (OpenAlex detects the language in the same way). Items whose DOI
#' points to a different publication get no language from OpenAlex.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `doi`, `language` (proposed code,
#'   `NA` if none found) and `source` (`openalex`, `abstract` or `NA`)
#' - `count`: number of items without language
#' - `count_openalex`: of these, items with the language from OpenAlex
#' - `count_abstract`: of these, items with the language from the abstract
#' - `pc`: percentage of all items without language
met_meta_language_missing <- function(
  zotero,
  openalex
) {
  x <- zotero[trimws(zotero$Language) == "" &
    !zotero$Item.Type %in% c("note", "attachment", "annotation"), ]

  works <- openalex |>
    dplyr::select(doi, language) |>
    dplyr::collect()
  oa <- oa_join(x, openalex, works)
  from_oa <- oa$language[match(x$Key, oa$Key)]
  from_oa[from_oa %in% ""] <- NA

  from_abstract <- rep(NA_character_, nrow(x))
  todo <- is.na(from_oa) & trimws(x$Abstract.Note) != ""
  from_abstract[todo] <- text_language(x$Abstract.Note[todo])

  metrics <- list()

  metrics$items <- tibble::tibble(
    key = x$Key,
    title = x$Title,
    doi = as_bib(x)$doi,
    language = dplyr::coalesce(from_oa, from_abstract),
    source = dplyr::case_when(
      !is.na(from_oa) ~ "openalex",
      !is.na(from_abstract) ~ "abstract"
    )
  )

  metrics$count <- nrow(metrics$items)
  metrics$count_openalex <- sum(metrics$items$source %in% "openalex")
  metrics$count_abstract <- sum(metrics$items$source %in% "abstract")
  metrics$pc <- 100 * metrics$count / nrow(zotero)

  return(metrics)
}
