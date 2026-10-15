# Helpers for the met_* metrics (not metrics themselves) --------------------

#' Run a measure once per data source
#'
#' Calls `fun` once for each data source. The results are named after the
#' argument names, or after the variable names if the arguments are unnamed.
#'
#' @param fun Measure function taking one data source.
#' @param ... The data sources, e.g. `zotero = zotero, openalex = works`.
#'
#' @return A list with one element per data source.
per_source <- function(
  fun,
  ...
) {
  args <- list(...)
  vars <- vapply(as.list(substitute(list(...)))[-1], deparse1, "")
  nms <- names(args)
  names(args) <- if (is.null(nms)) vars else ifelse(nms == "", vars, nms)
  return(lapply(args, fun))
}

#' Standard language codes
#'
#' Converts language values to standard codes (ISO 639-1, optionally with a
#' region: `en`, `en-US`), using the ISO 639-2 list of the R package ISOcodes.
#' Recognised are two-letter codes in any spelling (`EN`, `en_us`),
#' three-letter codes (`eng`, `fre`, `fra`) and the English names of the
#' languages, incl. alternative names (`Flemish` for Dutch).
#'
#' @param x Language values.
#'
#' @return The standard codes, `NA` where a value is not recognised.
language_code <- function(
  x
) {
  iso <- ISOcodes::ISO_639_2
  iso <- iso[!is.na(iso$Alpha_2), ]
  names_all <- strsplit(iso$Name, ";\\s*")
  by_name <- stats::setNames(
    rep(iso$Alpha_2, lengths(names_all)),
    tolower(unlist(names_all))
  )
  by_three <- c(
    stats::setNames(iso$Alpha_2, iso$Alpha_3_B),
    stats::setNames(iso$Alpha_2, iso$Alpha_3_T)
  )

  vapply(
    trimws(x),
    function(v) {
      if (is.na(v) || v == "") {
        return(as.character(NA))
      }
      m <- regmatches(v, regexec("^([A-Za-z]{2})(?:[-_]([A-Za-z]{2}))?$", v, perl = TRUE))[[1]]
      if (length(m) && tolower(m[2]) %in% iso$Alpha_2) {
        return(if (nzchar(m[3])) paste0(tolower(m[2]), "-", toupper(m[3])) else tolower(m[2]))
      }
      l <- tolower(v)
      if (l %in% names(by_three)) {
        return(unname(by_three[l]))
      }
      if (l %in% names(by_name)) {
        return(unname(by_name[l]))
      }
      as.character(NA)
    },
    "",
    USE.NAMES = FALSE
  )
}

#' Common bibliography columns
#'
#' Extracts the same columns from the Zotero items or the OpenAlex works, so
#' that measures can treat both sources alike. Empty strings become `NA`.
#'
#' @param data Zotero items (data frame) or OpenAlex works (arrow dataset).
#'
#' @return A tibble with `id` (item key / OpenAlex id), `doi_raw`, `title`,
#'   `year`, `type`, `language`, `journal` and `doi` (valid DOI, lower case).
as_bib <- function(
  data
) {
  if (all(c("Key", "DOI") %in% names(data))) {
    bib <- tibble::tibble(
      id = data$Key,
      doi_raw = data$DOI,
      title = data$Title,
      year = suppressWarnings(as.integer(data$Publication.Year)),
      type = data$Item.Type,
      language = data$Language,
      journal = data$Publication.Title
    )
  } else {
    works <- data |>
      dplyr::select(
        id,
        doi,
        title,
        publication_year,
        type,
        language,
        primary_location
      ) |>
      dplyr::collect()
    bib <- tibble::tibble(
      id = works$id,
      doi_raw = works$doi,
      title = works$title,
      year = as.integer(works$publication_year),
      type = works$type,
      language = works$language,
      journal = works$primary_location$source$display_name
    )
  }

  bib <- bib |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(is.character),
        ~ dplyr::na_if(.x, "")
      )
    )

  bib$doi <- openalexPro::extract_doi(
    bib$doi_raw,
    non_doi_value = as.character(NA),
    what = "doi"
  ) |>
    tolower()

  return(bib)
}
