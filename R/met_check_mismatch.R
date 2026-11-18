#' Wrong DOIs
#'
#' Items whose DOI points in OpenAlex to a work with a different title or
#' year, which usually means that the wrong DOI is attached to the item. An
#' item is flagged when the title similarity (normalised Levenshtein
#' distance) is below 0.8 or the years differ by more than one. Items with
#' the line `DOI checked: correct` in Extra (someone checked that the DOI is
#' right, e.g. a book chapter with the DOI of the book, or a wrong year in
#' OpenAlex) are not listed.
#'
#' OpenAlex often has the title without the subtitle (the part after the
#' colon), e.g. "Urban Ecology" for "Urban Ecology: Patterns, Processes, and
#' Applications". Items whose titles differ only by this (the title without
#' the subtitle is similar, at least 0.8, and the years differ by at most one)
#' are marked as `subtitle_only`: they are listed, but not counted as wrong
#' DOIs.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#' @param checked Also list the items with `DOI checked: correct` in Extra.
#'
#' @return A list with
#' - `items`: tibble with `key`, `doi`, `doi_raw` (content of the DOI
#'   field), `openalex` (the work's OpenAlex ID), `title_zotero`,
#'   `title_openalex`, `title_similarity`, `year_zotero`, `year_openalex`,
#'   `date_zotero` (content of the Date field) and `date_openalex`
#'   (publication date in OpenAlex), `extra` (content of the Extra field)
#'   and `subtitle_only` (only a subtitle missing on one side)
#' - `count`: number of flagged items, without those with `subtitle_only`
#' - `count_subtitle`: number of items with `subtitle_only`
#' - `pc`: percentage of the items found in OpenAlex which are counted
met_check_mismatch <- function(
  zotero,
  openalex,
  checked = FALSE
) {
  pairs <- dplyr::inner_join(
    as_bib(zotero) |>
      dplyr::filter(!is.na(doi)),
    as_bib(openalex) |>
      dplyr::filter(!is.na(doi)) |>
      dplyr::distinct(doi, .keep_all = TRUE),
    by = "doi",
    suffix = c("_zotero", "_openalex")
  )

  pairs$title_similarity <- title_similarity(
    pairs$title_zotero,
    pairs$title_openalex
  )
  pairs$year_diff <- abs(pairs$year_zotero - pairs$year_openalex)

  # only a subtitle (after the colon) missing on one side, year as well
  main <- function(t) sub("\\s*:.*", "", t)
  has_sub <- function(t) grepl(":\\s*\\S", t)
  tz <- pairs$title_zotero
  to <- pairs$title_openalex
  short <- (has_sub(tz) & !has_sub(to) & title_similarity(main(tz), to) >= 0.8) |
    (has_sub(to) & !has_sub(tz) & title_similarity(tz, main(to)) >= 0.8)
  pairs$subtitle_only <- pairs$title_similarity < 0.8 &
    short %in% TRUE &
    !(pairs$year_diff > 1) %in% TRUE

  row <- match(pairs$id_zotero, zotero$Key)
  pairs$date_zotero <- zotero$Date[row]
  pairs$extra <- zotero$Extra[row]
  pairs$date_openalex <- NA_character_
  if ("publication_date" %in% names(openalex)) {
    dates <- openalex |>
      dplyr::select(id, publication_date) |>
      dplyr::collect()
    pairs$date_openalex <- as.character(
      dates$publication_date[match(pairs$id_openalex, dates$id)]
    )
  }

  metrics <- list()

  # ponytail: fixed thresholds (title similarity < 0.8, year off by more
  # than 1, as online-first often shifts the year by 1); tune on real cases
  metrics$items <- pairs |>
    dplyr::filter(
      title_similarity < 0.8 | year_diff > 1,
      checked | !doi_checked(extra)
    ) |>
    dplyr::select(
      key = id_zotero,
      doi,
      doi_raw = doi_raw_zotero,
      openalex = id_openalex,
      title_zotero,
      title_openalex,
      title_similarity,
      year_zotero,
      year_openalex,
      date_zotero,
      date_openalex,
      extra,
      subtitle_only
    )

  metrics$count <- sum(!metrics$items$subtitle_only)
  metrics$count_subtitle <- sum(metrics$items$subtitle_only)
  metrics$pc <- 100 * metrics$count / nrow(pairs)

  return(metrics)
}
