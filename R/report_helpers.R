#' Links to open Zotero items
#'
#' HTML links which open a Zotero item in the Zotero web library and in the
#' Zotero app. Several keys in one string, separated by `"; "` (e.g.
#' duplicates), get one line of links each.
#'
#' @param keys Zotero item keys.
#' @param group_id Zotero group id.
#'
#' @return Character vector of HTML.
rep_zotero_links <- function(
  keys,
  group_id
) {
  vapply(
    strsplit(ifelse(is.na(keys), "", keys), "; "),
    function(k) {
      if (length(k) == 0 || all(k == "")) {
        return("")
      }
      paste0(
        '<a href="https://www.zotero.org/groups/', group_id, "/items/", k,
        '" target="_blank">web</a> &middot; ',
        '<a href="zotero://select/groups/', group_id, "/items/", k,
        '">app</a>',
        collapse = "<br>"
      )
    },
    ""
  )
}

#' Links to resolve DOIs
#'
#' @param doi DOIs.
#'
#' @return Character vector of HTML links to `https://doi.org/`.
rep_doi_links <- function(
  doi
) {
  ifelse(
    is.na(doi) | doi == "",
    "",
    paste0('<a href="https://doi.org/', doi, '" target="_blank">', doi, "</a>")
  )
}

#' Readable Zotero item types
#'
#' @param type Zotero item types, e.g. `journalArticle`.
#'
#' @return Item types as words, e.g. `journal article`.
rep_type <- function(
  type
) {
  tolower(gsub("([a-z])([A-Z])", "\\1 \\2", type))
}

#' Table of items to fix
#'
#' Interactive table with a column of links to open each item in Zotero.
#'
#' @param items Data frame with a column `key` (Zotero item key(s)) and the
#'   columns to show, already with readable names.
#' @param group_id Zotero group id.
#' @param doi_cols Names of columns containing DOIs, shown as links.
#'
#' @return A `reactable` table, or a short note if there is nothing to fix.
rep_fix_table <- function(
  items,
  group_id,
  doi_cols = character()
) {
  if (is.null(items) || nrow(items) == 0) {
    return(htmltools::p(htmltools::strong("✔ Nothing to fix.")))
  }

  items <- as.data.frame(items)
  items <- cbind(
    `Open in Zotero` = rep_zotero_links(items$key, group_id),
    items[setdiff(names(items), "key")]
  )

  columns <- list(
    `Open in Zotero` = reactable::colDef(html = TRUE, minWidth = 110)
  )
  for (col in doi_cols) {
    items[[col]] <- rep_doi_links(items[[col]])
    columns[[col]] <- reactable::colDef(html = TRUE)
  }

  reactable::reactable(
    items,
    columns = columns,
    searchable = TRUE,
    defaultPageSize = 10,
    striped = TRUE,
    compact = TRUE,
    wrap = TRUE
  )
}

#' Duplicate items
#'
#' Combines the duplicates found by DOI and by title, year and first author,
#' so that each set of duplicates is listed once.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#'
#' @return Tibble with `keys`, `title` and `count`, or `NULL` if the measure
#'   was not calculated.
rep_duplicates <- function(
  m
) {
  dup <- m$metadata$met_meta_duplicates
  if (is.null(dup)) {
    return(NULL)
  }
  dplyr::bind_rows(
    dup$by_doi[, c("keys", "title", "count")],
    dup$by_title[, c("keys", "title", "count")]
  ) |>
    dplyr::distinct(keys, .keep_all = TRUE)
}

#' Overview of the checks
#'
#' One row per check with the number of affected items and a status. Checks
#' whose measure is not configured are left out.
#'
#' @param m Metrics of one group, as saved by [get_metrics()].
#'
#' @return Tibble with `id` (section anchor), `check`, `count`, `severity`
#'   (`fix`, `check` or `info`) and `status` (readable status).
rep_checks <- function(
  m
) {
  n <- function(x) if (is.null(x)) NA_integer_ else as.integer(sum(x))
  dup <- rep_duplicates(m)

  checks <- tibble::tribble(
    ~id, ~check, ~count, ~severity,
    "retracted", "Retracted publications",
    n(m$openalex_check$met_check_retracted$count), "fix",
    "wrong-doi", "DOI points to a different publication",
    n(m$openalex_check$met_check_mismatch$count), "fix",
    "duplicates", "Items which are in the group more than once",
    if (is.null(dup)) NA_integer_ else n(dup$count - 1), "fix",
    "invalid-doi", "DOI field with an invalid DOI",
    n(m$identifiers$met_id_doi$zotero$count_invalid), "fix",
    "doi-form", "DOI field with a link or prefix instead of the DOI",
    n(m$identifiers$met_id_doi_form$count), "fix",
    "misplaced-doi", "DOI in the wrong field",
    n(m$identifiers$met_id_doi_misplaced$count), "check",
    "not-found", "DOI not found in OpenAlex",
    n(m$openalex_check$met_check_found$count_not_in_oa), "check",
    "year", "Missing or unusual publication year",
    n(m$metadata$met_meta_year$count), "check",
    "fill", "Empty journal, volume, issue or pages, found in OpenAlex",
    n(m$openalex_check$met_check_fill$count), "check",
    "language", "Language not given as a language code",
    n(m$metadata$met_meta_language$count), "check",
    "no-identifier", "Items without DOI, ISBN, ISSN or URL",
    n(m$identifiers$met_id_none$count), "check",
    "doi-candidates", "Items without DOI, for which OpenAlex has one",
    n(m$identifiers$met_id_candidates$count_items), "check",
    "openalex-id", "Items without their OpenAlex ID in Extra",
    n(nrow(m$openalex_check$met_check_openalex_id$items)), "info",
    "untagged", "Items without tags",
    n(m$maintenance$met_maint_tags$count), "info"
  )

  checks |>
    dplyr::filter(
      !is.na(count)
    ) |>
    dplyr::mutate(
      status = dplyr::case_when(
        count == 0 ~ "OK",
        severity == "fix" ~ "Please fix",
        severity == "check" ~ "Please check",
        .default = "For information"
      )
    )
}

#' Coloured status label
#'
#' @param status Status as returned by [rep_checks()].
#'
#' @return Character vector of HTML.
rep_status_label <- function(
  status
) {
  colour <- c(
    "OK" = "#1a7f37",
    "Please fix" = "#c62828",
    "Please check" = "#b26a00",
    "For information" = "#5f6b7a"
  )[status]
  paste0(
    '<span style="color:', colour, '; font-weight:bold;">&#9679; ',
    status,
    "</span>"
  )
}
