#' Look up the OpenAlex IDs in the Extra field
#'
#' Reads the lines `OpenAlex: …` in the Extra field of the Zotero items and
#' looks up all IDs in OpenAlex in one query ([openalexPro::pro_query()] splits
#' it as needed). IDs which are not returned are not in OpenAlex: wrong, or
#' merged into another record.
#'
#' @param zotero_group Directory with the Zotero CSV files, as returned by
#'   [get_zotero_group()].
#'
#' @return Path to `output/extra_ids/<group>.rds`: a tibble with one row per
#'   line, with the item `key`, the `value` after `OpenAlex:`, `extra_id`
#'   (the ID, `NA` if the value is not an OpenAlex work ID), `found` (in
#'   OpenAlex; `NA` if not looked up, e.g. no network) and the work's
#'   `oa_doi`, `oa_title` and `oa_year`.
get_extra_ids <- function(
  zotero_group
) {
  zotero <- read_zotero(zotero_group)
  lines <- regmatches(
    zotero$Extra,
    gregexpr("(?mi)^OpenAlex:[^\n]*", zotero$Extra, perl = TRUE)
  )
  x <- tibble::tibble(
    key = rep(zotero$Key, lengths(lines)),
    value = trimws(sub("^OpenAlex:", "", unlist(lines), ignore.case = TRUE))
  )
  # W… or https://openalex.org/W…
  x$extra_id <- ifelse(
    grepl("^(https?://openalex\\.org/)?W[0-9]+$", x$value, ignore.case = TRUE),
    toupper(sub(".*/", "", x$value)),
    NA_character_
  )

  works <- tibble::tibble(
    id = character(),
    doi = character(),
    title = character(),
    publication_year = integer()
  )
  ids <- unique(stats::na.omit(x$extra_id))
  if (length(ids)) {
    works <- tryCatch(
      {
        dir <- tempfile()
        on.exit(unlink(dir, recursive = TRUE), add = TRUE)
        openalexPro::pro_query(
          entity = "works",
          id = ids,
          select = c("id", "doi", "title", "publication_year")
        ) |>
          openalexPro::pro_fetch(project_folder = dir, progress = FALSE) |>
          arrow::open_dataset() |>
          dplyr::select(id, doi, title, publication_year) |>
          dplyr::collect()
      },
      error = function(e) NULL # not looked up
    )
  }

  if (!is.null(works)) {
    works$id <- sub("^https://openalex.org/", "", works$id)
    m <- match(x$extra_id, works$id)
    x$found <- ifelse(is.na(x$extra_id), NA, !is.na(m))
    x$oa_doi <- sub("^https://doi.org/", "", works$doi[m])
    x$oa_title <- works$title[m]
    x$oa_year <- as.integer(works$publication_year[m])
  } else {
    x$found <- NA
    x$oa_doi <- NA_character_
    x$oa_title <- NA_character_
    x$oa_year <- NA_integer_
  }

  file <- file.path(
    "output",
    "extra_ids",
    paste0(basename(zotero_group), ".rds")
  )
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  saveRDS(x, file)

  return(file)
}
