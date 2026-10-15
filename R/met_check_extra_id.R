#' OpenAlex ID in the Extra field not valid
#'
#' Checks the lines `OpenAlex: …` in the Extra field (looked up by
#' [get_extra_ids()]). A line is not valid if
#' - it is not an OpenAlex work ID (`W` and digits),
#' - the item has several lines with different IDs,
#' - the ID is not in OpenAlex (wrong, or merged into another record), or
#' - the work is a different publication: its DOI is not the DOI of the item,
#'   or, for items without DOI, its title is not similar (similarity below
#'   0.8, see [title_similarity()]).
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset), for the ID of the item's
#'   DOI.
#' @param extra_ids OpenAlex IDs in Extra, as saved by [get_extra_ids()].
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `value` (after `OpenAlex:`),
#'   `oa_title`, `oa_doi` (of the work in OpenAlex), `problem`, `extra`
#'   (content of Extra) and `doi_id` (OpenAlex ID of the item's DOI, `NA` if
#'   none), one row per line which is not valid
#' - `count`: number of items with a line which is not valid
#' - `count_checked`: number of items with an OpenAlex line
met_check_extra_id <- function(
  zotero,
  openalex = NULL,
  extra_ids = NULL
) {
  metrics <- list()
  metrics$items <- tibble::tibble(
    key = character(),
    title = character(),
    value = character(),
    oa_title = character(),
    oa_doi = character(),
    problem = character(),
    extra = character(),
    doi_id = character()
  )
  if (is.null(extra_ids) || nrow(extra_ids) == 0) {
    metrics$count <- 0L
    metrics$count_checked <- 0L
    return(metrics)
  }

  bib <- as_bib(zotero)
  x <- dplyr::left_join(
    extra_ids,
    dplyr::select(bib, key = id, title, doi),
    by = "key"
  )
  several <- x$key %in% x$key[duplicated(x$key)] &
    ave(x$extra_id, x$key, FUN = function(v) length(unique(v))) != "1"
  other <- !is.na(x$oa_title) & ifelse(
    !is.na(x$doi) & !is.na(x$oa_doi),
    tolower(x$oa_doi) != x$doi,
    title_similarity(x$title, x$oa_title) < 0.8
  )
  x$problem <- dplyr::case_when(
    is.na(x$extra_id) ~ "Not an OpenAlex ID",
    several ~ "Several different OpenAlex IDs",
    x$found %in% FALSE ~ "Not in OpenAlex (wrong, or merged into another record)",
    other ~ "Different publication in OpenAlex",
    .default = NA_character_
  )
  x <- x[!is.na(x$problem), ]

  # the right ID: the one of the item's DOI
  x$extra <- zotero$Extra[match(x$key, zotero$Key)]
  x$doi_id <- NA_character_
  if (nrow(x) && "id" %in% names(openalex)) {
    works <- openalex |>
      dplyr::select(
        doi,
        id
      ) |>
      dplyr::collect()
    j <- oa_join(zotero[zotero$Key %in% x$key, ], openalex, works)
    x$doi_id <- sub("^https://openalex.org/", "", j$id[match(x$key, j$Key)])
  }

  metrics$items <- dplyr::bind_rows(
    metrics$items,
    dplyr::select(x, key, title, value, oa_title, oa_doi, problem, extra, doi_id)
  )
  metrics$count <- length(unique(x$key))
  metrics$count_checked <- length(unique(extra_ids$key))

  return(metrics)
}
