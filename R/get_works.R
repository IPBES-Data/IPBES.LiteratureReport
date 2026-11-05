#' Get the OpenAlex works of a Zotero group
#'
#' Extracts the DOIs from the Zotero CSV files and fetches the matching works
#' from OpenAlex with `openalexPro::pro_query()` and
#' `openalexPro::pro_fetch()`. The works are saved as a parquet dataset in
#' `output/zotero_works/<group>/`. An existing directory is deleted first.
#'
#' The DOIs not returned are then looked up one by one with
#' [get_doi_check()]: OpenAlex has some works under another DOI, and misses
#' some works in the lookup by DOI. If works are found that way, all works
#' are fetched again by their OpenAlex ID, so that they are in one dataset
#' (works fetched separately can have different column types).
#'
#' @param zotero_group Directory with the Zotero CSV files, as returned by
#'   [get_zotero_group()].
#' @param verbose Not used.
#'
#' @return Path to the parquet dataset, as returned by
#'   `openalexPro::pro_fetch()`.
get_works <- function(
  zotero_group = NULL,
  verbose = FALSE
) {
  ##
  dir <- file.path("output", "zotero_works")

  path <- file.path(
    dir,
    basename(zotero_group)
  )

  unlink(path, recursive = TRUE)

  dir.create(
    path,
    recursive = TRUE,
    showWarnings = FALSE
  )

  ##

  zotBib <- read_zotero(zotero_group) |>
    dplyr::select(
      Key,
      DOI
    ) |>
    dplyr::filter(
      DOI != ""
    ) |>
    dplyr::mutate(
      DOI = openalexPro::extract_doi(
        DOI,
        non_doi_value = NA_character_
      )
    )

  fetch <- function(query, folder) {
    openalexPro::pro_fetch(
      query,
      project_folder = normalizePath(folder, mustWork = FALSE),
      delete_input = TRUE,
      overwrite = TRUE,
      compact_parquet = 250000,
      via = "oqo"
    )
  }

  zotWorksDB <- openalexPro::pro_query(
    entity = "works",
    doi = zotBib$DOI,
    chunk_limit = 200
  ) |>
    fetch(path)

  works <- arrow::open_dataset(zotWorksDB) |>
    dplyr::select(id, doi) |>
    dplyr::collect()
  check <- readRDS(get_doi_check(zotero_group, works$doi))
  extra <- setdiff(stats::na.omit(check$oa_id), works$id)
  if (length(extra)) {
    tmp <- tempfile()
    on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
    db <- openalexPro::pro_query(
      entity = "works",
      id = sub("^https://openalex.org/", "", union(works$id, extra))
    ) |>
      fetch(tmp)
    unlink(zotWorksDB, recursive = TRUE)
    file.copy(db, path, recursive = TRUE)
    zotWorksDB <- file.path(path, basename(db))
  }

  # relative, so that the pipeline's cache works in any location (e.g. the
  # Docker container)
  return(file.path(path, basename(zotWorksDB)))
}
