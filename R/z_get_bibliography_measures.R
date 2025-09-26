#' Used in the pipeline - Get Bibliography Measures
#'
#' This function calculates various measures related to a bibliography dataset.
#'
#' @param bibliography A data frame containing the bibliography dataset.
#'
#' @return A list containing the calculated measures.
#'
#' @importFrom IPBES.R doi_valid
#'
#' @md
#' @export

get_bibliography_measures <- function(
  bibliography_fn
) {
  bibliography <- readRDS(bibliography_fn)

  # Metric groups functions ----------------------------------------------------------

  doi_metrics <- function(
    bibliography,
    source # either "openalex" or "zotero"
  ) {
    doi_metrics <- list()

    switch(
      source,
      openalex = {
        doi_metrics$id_raw <- bibliography$works$doi
        names(doi_metrics$id_raw) <- bibliography$works$id
      },
      zotero = {
        doi_metrics$id_raw <- bibliography$bibliography$DOI
        names(doi_metrics$id_raw) <- bibliography$bibliography$Key
      }
    )

    doi_metrics$id <- openalexPro2::extract_doi(
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

    doi_metrics$valid <- doi_metrics$unique[IPBES.R::doi_valid(
      doi_metrics$unique
    )]
    doi_metrics$not_valid <- doi_metrics$unique[
      !IPBES.R::doi_valid(doi_metrics$unique)
    ]

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
    timestamp = bibliography$timestamp,
    name = bibliography$name,
    url = bibliography$url,
    openalex_doi = doi_metrics(bibliography, "openalex"),
    zotero_doi = doi_metrics(bibliography, "zotero"),
    zotero_isbn = isbn_metrics(bibliography),
    zotero_issn = issn_metrics(bibliography),
    types = types_metrics(bibliography)
  )

  result$dois_comp <- dois_comp(result$openalex_doi, result$zotero_doi)

  class(metrics) <- c(class(metrics), "bibliography_metrics")

  # Save Metrics -----------------------------------------------------------

  dir <- file.path("output", "metrics")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  file <- file.path(dir, basename(bibliography_fn))

  saveRDS(result, file = file)

  return(file)
}
