#' Used in the pipeline - Load and prepare bibliography
#'
#' This function gets the works associated with dois in the zotero library.

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

  path <- normalizePath(path)

  ##

  zotBib <- list.files(
    zotero_group,
    pattern = "\\.csv$",
    full.names = TRUE
  ) |>
    lapply(
      FUN = read.table,
      header = TRUE,
      colClasses = "character",
      sep = ","
    ) |>
    dplyr::bind_rows() |>
    dplyr::select(
      Key,
      DOI
    ) |>
    dplyr::mutate(
      DOI = openalexPro::extract_doi(
        DOI,
        non_doi_value = NA_character_
      )
    ) |>
    dplyr::filter(
      !is.na(DOI)
    )

  zotWorksDB <-
    openalexPro::pro_query(
      entity = "works",
      doi = zotBib$DOI
    ) |>
    openalexPro::pro_fetch(
      project_folder = file.path(path),
      delete_input = TRUE,
      overwrite = TRUE
    )

  # add in_oa to bibliography_bibliography

  return(zotWorksDB)
}
