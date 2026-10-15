#' DOIs found in OpenAlex for items without a DOI
#'
#' For items without a DOI, OpenAlex was searched by title (see
#' [get_doi_candidates()]). The works found are compared with the item:
#' title (ignoring case and punctuation), year and the surname of the first
#' author. A work is a *likely* match if the titles are (nearly) the same
#' (similarity at least 0.95), the years differ by at most 1 and the first
#' authors have the same surname (year or author are not compared if the item
#' has none), and the title has at least 4 words (short titles like
#' "Zoonoses" are too general). It is a *possible* match if the titles are similar (at least
#' 0.8). All likely and possible works with a DOI are kept, sorted per item,
#' best first. DOIs used by another item in the group are noted (the item
#' would be a duplicate).
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex Not used.
#' @param candidates Works found in OpenAlex, as saved by
#'   [get_doi_candidates()].
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `year`, `author` (first author) of
#'   the item, and `doi`, `id`, `cand_title`, `cand_year`, `cand_author`,
#'   `cand_journal` of the work found, `similarity` (titles), `match`
#'   (`likely` or `possible`), `note` (DOI used by another item, else `NA`)
#'   and `single` (`TRUE` for the only likely match of an item), one row per
#'   item and work
#' - `count_items`: number of items with at least one match
#' - `count_searched`: number of items searched
#' - `count_likely`: items with exactly one likely match
#' - `count_choice`: items with several or only possible matches
met_id_candidates <- function(
  zotero,
  openalex = NULL,
  candidates = NULL
) {
  metrics <- list()
  metrics$items <- tibble::tibble(
    key = character(),
    title = character(),
    year = integer(),
    author = character(),
    doi = character(),
    id = character(),
    cand_title = character(),
    cand_year = integer(),
    cand_author = character(),
    cand_journal = character(),
    similarity = numeric(),
    match = character(),
    note = character(),
    single = logical()
  )
  if (is.null(candidates) || nrow(candidates) == 0) {
    metrics$count_items <- 0L
    metrics$count_searched <- 0L
    metrics$count_likely <- 0L
    metrics$count_choice <- 0L
    return(metrics)
  }

  surname <- function(x) {
    gsub("[^a-z]", "", tolower(iconv(x, to = "ASCII//TRANSLIT")))
  }
  items <- tibble::tibble(
    key = zotero$Key,
    title = zotero$Title,
    year = suppressWarnings(as.integer(zotero$Publication.Year)),
    author = sub(";.*", "", zotero$Author)
  )

  x <- dplyr::inner_join(
    items,
    candidates[!is.na(candidates$doi), ] |>
      dplyr::select(
        key,
        doi,
        id,
        cand_title = title,
        cand_year = year,
        cand_author = first_author,
        cand_journal = journal
      ),
    by = "key"
  )
  x$similarity <- title_similarity(x$title, x$cand_title)
  # last word of the OpenAlex name, e.g. "Berg" of "Anna van den Berg"
  author_ok <- x$author == "" | is.na(x$cand_author) |
    endsWith(
      surname(sub(",.*", "", x$author)),
      surname(sub(".* ", "", x$cand_author))
    )
  year_ok <- is.na(x$year) | is.na(x$cand_year) | abs(x$year - x$cand_year) <= 1
  long <- lengths(strsplit(trimws(x$title), "\\s+")) >= 4
  x$match <- dplyr::case_when(
    x$similarity >= 0.95 & year_ok & author_ok & long ~ "likely",
    x$similarity >= 0.8 ~ "possible",
    .default = NA_character_
  )
  x <- x[!is.na(x$match), ]

  # one row per item and DOI; DOIs already in the group are noted
  in_group <- openalexPro::extract_doi(
    zotero$DOI,
    non_doi_value = as.character(NA),
    what = "doi"
  )
  x <- x |>
    dplyr::arrange(
      tolower(title),
      key,
      match != "likely",
      -similarity
    ) |>
    dplyr::distinct(key, tolower(doi), .keep_all = TRUE) |>
    dplyr::select(-`tolower(doi)`)
  x$note <- ifelse(
    tolower(x$doi) %in% in_group,
    "DOI used by another item in the group (duplicate?)",
    NA_character_
  )
  # the only likely match of an item (not a duplicate)
  ok <- x$match == "likely" & is.na(x$note)
  n_likely <- tapply(ok, x$key, sum)
  x$single <- ok & unname(n_likely[x$key]) == 1

  metrics$items <- dplyr::bind_rows(metrics$items, x)
  metrics$count_items <- length(unique(x$key))
  metrics$count_searched <- length(unique(candidates$key))
  metrics$count_likely <- sum(x$single)
  metrics$count_choice <- metrics$count_items - metrics$count_likely

  return(metrics)
}
