#' Used in the pipeline - Get Bibliography Measures
#'
#' This function calculates various measures related to a bibliography dataset.
#'
#' @param bibliography A data frame containing the bibliography dataset.
#'
#' @return A list containing the calculated measures.
#'
#' @md
#' @export

get_metrics <- function(
  zotero_group,
  zotero_works
) {
  zotero <- list.files(
    zotero_group,
    pattern = "\\.csv$",
    full.names = TRUE
  ) |>
    lapply(read.csv, colClasses = "character") |>
    dplyr::bind_rows()

  works <- arrow::open_dataset(zotero_works)

  # Metric groups functions ----------------------------------------------------------

  result <- list()

  doi_metrics <- function(
    data,
    source # either "openalex" or "zotero"
  ) {
    doi_metrics <- list()

    switch(
      source,
      openalex = {
        doi_metrics$id_raw <- data |>
          dplyr::select(doi) |>
          dplyr::collect() |>
          dplyr::pull(doi)
        names(doi_metrics$id_raw) <- data |>
          dplyr::select(id) |>
          dplyr::collect() |>
          dplyr::pull(id)
      },
      zotero = {
        doi_metrics$id_raw <- zotero$DOI
        names(doi_metrics$id_raw) <- zotero$Key
      }
    )

    doi_metrics$id <- openalexPro::extract_doi(
      doi_metrics$id_raw,
      non_doi_value = as.character(NA)
    )
    doi_metrics$id <- doi_metrics$id[!is.na(doi_metrics$id)]
    doi_metrics$id <- doi_metrics$id[doi_metrics$id != ""]

    doi_metrics$count <- sum(!is.na(doi_metrics$id))
    doi_metrics$pc <- 100 *
      doi_metrics$count /
      length(doi_metrics$id_raw)

    doi_metrics$duplicate <- doi_metrics$id[duplicated(doi_metrics$id)]

    doi_metrics$unique <- unique(doi_metrics$id)

    # doi_metrics$valid <- doi_metrics$unique[IPBES.R::doi_valid(
    #   doi_metrics$unique
    # )]
    # doi_metrics$not_valid <- doi_metrics$unique[
    #   !IPBES.R::doi_valid(doi_metrics$unique)
    # ]

    return(doi_metrics)
  }

  dois_comp <- function(openalex_doi, zotero_doi) {
    dois_comp <- list()
    dois_comp$zotero_in_oa <- zotero_doi$id[
      (zotero_doi$unique %in% openalex_doi$id)
    ]
    dois_comp$zotero_not_in_oa <- zotero_doi$id[
      !(zotero_doi$unique %in% openalex_doi$id)
    ]
    return(dois_comp)
  }

  isbn_metrics <- function(bibliography) {
    metrics <- list(
      id = bibliography$bibliography$ISBN
    )
    names(metrics$id) <- bibliography$bibliography$Key
    metrics$id <- metrics$id[
      metrics$id != ""
    ]
    metrics$id <- metrics$id[
      !is.na(metrics$id)
    ]

    metrics$count <- sum(!is.na(metrics$id))
    metrics$pc <- 100 *
      metrics$count /
      nrow(bibliography$bibliography)

    metrics$duplicate <- metrics$id[
      metrics$id %in%
        metrics$id[duplicated(metrics$id)]
    ]
    metrics$unique <- metrics$id[
      metrics$id %in% unique(metrics$id)
    ]
    return(metrics)
  }

  issn_metrics <- function(bibliography) {
    metrics <- list(
      id = bibliography$bibliography$ISSN
    )
    names(metrics$id) <- bibliography$bibliography$Key
    metrics$id <- metrics$id[
      metrics$id != ""
    ]
    metrics$id <- metrics$id[
      !is.na(metrics$id)
    ]

    metrics$count <- sum(!is.na(metrics$id))
    metrics$pc <- 100 *
      metrics$count /
      nrow(bibliography$bibliography)

    metrics$duplicate <- metrics$id[
      metrics$id %in%
        metrics$id[duplicated(metrics$id)]
    ]
    metrics$unique <- metrics$id[
      metrics$id %in% unique(metrics$id)
    ]
    return(metrics)
  }

  types_metrics <- function(bibliography) {
    metrics <- list()
    metrics$metrics <- bibliography$bibliography |>
      dplyr::select(
        doi = DOI,
        type_zenodo = Item.Type
      ) |>
      dplyr::full_join(
        y = bibliography$works |>
          dplyr::select(
            doi = doi,
            type_openalex = type
          ) |>
          dplyr::mutate(
            doi = gsub(pattern = "https://doi.org/", replacement = "", doi)
          ),
        relationship = "many-to-many",
        by = join_by(doi)
      )

    metrics$comparison <- metrics$metrics |>
      dplyr::mutate(
        doi = NULL
      ) |>
      dplyr::summarise(
        count = n(),
        .by = c(type_zenodo, type_openalex)
      ) |>
      dplyr::arrange(
        desc(count)
      )

    return(metrics)
  }

  # Assemble Metrics -------------------------------------------------------

  result <- list(
    # timestamp = bibliography$timestamp,
    name = basename(zotero_group),
    # url = bibliography$url,
    openalex_doi = doi_metrics(works, "openalex"),
    zotero_doi = doi_metrics(zotero, "zotero")
    # zotero_isbn = isbn_metrics(bibliography),
    # zotero_issn = issn_metrics(bibliography),
    # types = types_metrics(bibliography)
  )

  result$dois_comp <- dois_comp(result$openalex_doi, result$zotero_doi)

  class(result) <- c(class(result), "bibliography_metrics")

  # Save Metrics -----------------------------------------------------------

  dir <- file.path("output", "metrics")

  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  file <- file.path(dir, basename(zotero_group))

  saveRDS(result, file = file)

  return(file)
}
