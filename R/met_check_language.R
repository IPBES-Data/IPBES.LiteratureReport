#' Language differs from OpenAlex
#'
#' Items whose language in Zotero differs from the language of their DOI in
#' OpenAlex. Only the language is compared, not the region (`en-US` and `en`
#' are the same), and only for items whose language is given as a language
#' code (see "Language not given as a language code"). Items without a
#' language are listed under "No language".
#'
#' OpenAlex does not record the language of a work, but detects it from the
#' title and abstract. Many publications in other languages have an English
#' abstract and are therefore `en` in OpenAlex: the language in Zotero is
#' often right. Items with the line `Language checked: correct` in Extra
#' (someone checked that the language in Zotero is right) are not listed.
#' Items whose DOI points to a different publication are left out.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#' @param checked Also list the items with `Language checked: correct` in
#'   Extra.
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `doi`, `openalex` (the work's
#'   OpenAlex ID), `language` (as entered in Zotero), `language_openalex` and
#'   `extra` (content of the Extra field)
#' - `count`: number of items whose language differs
#' - `pc`: percentage of the items with a language in Zotero and in OpenAlex
#'   whose language differs
met_check_language <- function(
  zotero,
  openalex,
  checked = FALSE
) {
  works <- openalex |>
    dplyr::select(id, doi, language) |>
    dplyr::collect()
  items <- oa_join(zotero, openalex, works)

  main <- function(x) sub("-.*", "", x)
  zotero_code <- language_code(items$Language)
  compared <- !is.na(zotero_code) &
    zotero_code == trimws(items$Language) &
    !is.na(items$language) & items$language != ""
  differs <- compared & main(zotero_code) != main(items$language)

  x <- items[differs & (checked | !language_checked(items$Extra)), ]

  metrics <- list()

  metrics$items <- tibble::tibble(
    key = x$Key,
    title = x$Title,
    doi = x$doi,
    openalex = x$id,
    language = x$Language,
    language_openalex = x$language,
    extra = x$Extra
  )

  metrics$count <- nrow(metrics$items)
  metrics$pc <- 100 * metrics$count / max(sum(compared), 1)

  return(metrics)
}
