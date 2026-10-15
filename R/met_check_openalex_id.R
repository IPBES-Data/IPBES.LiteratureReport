#' OpenAlex ID in the Extra field
#'
#' Items whose DOI was found in OpenAlex, compared with the OpenAlex ID noted
#' in their Extra field (a line `OpenAlex: W…`). Items without such a line
#' can get it, which links them to OpenAlex for later checks. Items with a
#' different ID are listed for checking: OpenAlex merges records, and the ID
#' of a merged record redirects to the new one. Items whose DOI points to a
#' different publication are left out.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `doi`, `id` (OpenAlex ID of the
#'   DOI, e.g. `W2741809807`), `extra_id` (ID in the Extra field, `NA` if
#'   none), `extra` (content of Extra) and `line` (line to add to Extra),
#'   for items without the ID or
#'   with a different one
#' - `count_missing`: items without an OpenAlex ID in Extra
#' - `count_different`: items with a different OpenAlex ID in Extra
met_check_openalex_id <- function(
  zotero,
  openalex
) {
  metrics <- list()
  metrics$items <- tibble::tibble(
    key = character(),
    title = character(),
    doi = character(),
    id = character(),
    extra_id = character(),
    extra = character(),
    line = character()
  )

  if ("id" %in% names(openalex)) {
    works <- openalex |>
      dplyr::select(
        doi,
        id
      ) |>
      dplyr::collect()
    x <- oa_join(zotero, openalex, works)
    x$id <- sub("^https://openalex.org/", "", x$id)
    m <- regmatches(x$Extra, regexec("(?m)^OpenAlex:\\s*(W[0-9]+)", x$Extra, perl = TRUE))
    x$extra_id <- vapply(m, function(v) if (length(v)) v[2] else NA_character_, "")
    x <- x[is.na(x$extra_id) | x$extra_id != x$id, ]

    metrics$items <- tibble::tibble(
      key = x$Key,
      title = x$Title,
      doi = x$doi,
      id = x$id,
      extra_id = x$extra_id,
      extra = x$Extra,
      line = paste0("OpenAlex: ", x$id)
    )
  }

  metrics$count_missing <- sum(is.na(metrics$items$extra_id))
  metrics$count_different <- sum(!is.na(metrics$items$extra_id))

  return(metrics)
}
