#' The fixes
#'
#' One row per fix: the problem, the value written and the field, the fix
#' function `fix_*(m, group_id)`, the check in the report ([rep_checks()]) it
#' belongs to, and whether it is sent with one button, without a table
#' (`bulk`, nothing to check). Sorted by field: DOI first, as the fixes with
#' values from OpenAlex rely on it, Extra (identifiers for other tools) last.
#' Used by the fix app and for the proposals published by the pipeline.
#'
#' @return A tibble with `id`, `problem`, `value`, `field`, `fun`, `check`,
#'   `bulk` and `label`.
fix_table <- function() {
  fixes <- tibble::tribble(
    ~id, ~problem, ~value, ~field, ~fun, ~check, ~bulk,
    "doi_misplaced", "DOI in wrong field", "DOI from other field (URL, Extra)", "DOI", fix_doi_misplaced, "misplaced-doi", FALSE,
    "doi_form", "DOI as link or with prefix", "DOI without link or prefix", "DOI", fix_doi_form, "doi-form", FALSE,
    "language", "Language not as ISO code", "ISO language code", "Language", fix_language, "language", FALSE,
    "date", "No date", "Date from OpenAlex", "Date", fix_date, "year", FALSE,
    "fill", "Empty fields", "Values from OpenAlex", "Journal, Volume, Issue, Pages", fix_fill, "fill", FALSE,
    "doi_candidates", "No DOI", "DOI found in OpenAlex", "DOI", fix_doi_candidates, "doi-candidates", FALSE,
    "openalex_id", "No OpenAlex ID", "OpenAlex ID of the DOI", "Extra", fix_openalex_id, "openalex-id", TRUE,
    "issn_form", "ISSN not in standard form", "ISSN in standard form", "ISSN", fix_issn_form, "issn-form", FALSE,
    "extra_id", "OpenAlex ID not valid", "OpenAlex ID of the DOI", "Extra", fix_extra_id, "extra-id", FALSE
  )
  fixes$label <- paste0(
    fixes$problem, " → ", fixes$value, " in ",
    fixes$field, ifelse(grepl(",", fixes$field), " fields", " field")
  )
  fixes[order(
    fixes$field != "DOI",
    fixes$field == "Extra",
    tolower(fixes$field)
  ), ]
}
