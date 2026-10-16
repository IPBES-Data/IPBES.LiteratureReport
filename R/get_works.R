#' Get the OpenAlex works of a Zotero group
#'
#' Extracts the DOIs from the Zotero CSV files and fetches the matching works
#' from OpenAlex with `openalexPro::pro_query()` and
#' `openalexPro::pro_fetch()`. The works are saved as a parquet dataset in
#' `output/zotero_works/<group>/`. An existing directory is deleted first.
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

  zotWorksDB <-
    openalexPro::pro_query(
      entity = "works",
      doi = zotBib$DOI,
      chunk_limit = 200
    ) |>
    openalexPro::pro_fetch(
      project_folder = normalizePath(path, mustWork = FALSE),
      delete_input = TRUE,
      overwrite = TRUE,
      compact_parquet = 250000,
      via = "oqo"
    )

  # relative, so that the pipeline's cache works in any location (e.g. the
  # Docker container)
  return(file.path(path, basename(zotWorksDB)))
}
