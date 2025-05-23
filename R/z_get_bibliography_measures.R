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

  ################################
  result <- list(
    timestamp = bibliography$timestamp,
    name = bibliography$name,
    url = bibliography$url
  )

  ### DOIs OpenAlex

  result$oa_dois <- list(
    id = bibliography$works$doi
  )
  names(result$oa_dois$id) <- bibliography$works$id
  result$oa_dois$id <- result$oa_dois$id[result$oa_dois$id != ""]
  result$oa_dois$id <- result$oa_dois$id[!is.na(result$oa_dois$id)]

  result$oa_dois$id <- result$oa_dois$id |>
    gsub(pattern = "^https://doi.org/", replacement = "") |>
    gsub(pattern = "^https://dx.doi.org/", replacement = "") |>
    gsub(pattern = "^https://hdl.handle.net/", replacement = "") |>
    gsub(pattern = "^http://doi.org/", replacement = "") |>
    gsub(pattern = "^http://dx.doi.org/", replacement = "") |>
    gsub(pattern = "^http://hdl.handle.net/", replacement = "") |>
    gsub(pattern = "^doi:", replacement = "") |>
    gsub(pattern = "^DOI ", replacement = "") |>
    unique()

  result$oa_dois$count <- sum(!is.na(result$oa_dois$id))
  result$oa_dois$pc <- 100 *
    result$oa_dois$count /
    nrow(bibliography$bibliography)

  result$oa_dois$duplicate <- result$oa_dois$id[duplicated(result$oa_dois$id)]
  result$oa_dois$unique <- unique(result$oa_dois$id)

  ### DOIs Zotero

  result$zotero_dois <- list(
    id = bibliography$bibliography$DOI
  )
  names(result$zotero_dois$id) <- bibliography$bibliography$Key
  result$zotero_dois$id <- result$zotero_dois$id[result$zotero_dois$id != ""]
  result$zotero_dois$id <- result$zotero_dois$id[!is.na(result$zotero_dois$id)]
  result$zotero_dois$id_raw <- result$zotero_dois$id

  result$zotero_dois$id <- result$zotero_dois$id |>
    gsub(pattern = "^https://doi.org/", replacement = "") |>
    gsub(pattern = "^https://dx.doi.org/", replacement = "") |>
    gsub(pattern = "^https://hdl.handle.net/", replacement = "") |>
    gsub(pattern = "^http://doi.org/", replacement = "") |>
    gsub(pattern = "^http://dx.doi.org/", replacement = "") |>
    gsub(pattern = "^http://hdl.handle.net/", replacement = "") |>
    gsub(pattern = "^doi:", replacement = "") |>
    gsub(pattern = "^DOI ", replacement = "")

  result$zotero_dois$count <- sum(!is.na(result$zotero_dois$id))
  result$zotero_dois$pc <- 100 *
    result$zotero_dois$count /
    nrow(bibliography$bibliography)

  result$zotero_dois$duplicate <- result$zotero_dois$id[
    result$zotero_dois$id %in%
      result$zotero_dois$id[duplicated(result$zotero_dois$id)]
  ]
  result$zotero_dois$unique <- result$zotero_dois$id[
    result$zotero_dois$id %in% unique(result$zotero_dois$id)
  ]

  result$zotero_dois$valid <- result$zotero_dois$unique[IPBES.R::doi_valid(
    result$zotero_dois$unique
  )]
  result$zotero_dois$not_valid <- result$zotero_dois$unique[
    !IPBES.R::doi_valid(result$zotero_dois$unique)
  ]

  result$zotero_dois$in_oa <- result$zotero_dois$id[
    (result$zotero_dois$unique %in% result$oa_dois$id)
  ]
  result$zotero_dois$not_in_oa <- result$zotero_dois$id[
    !(result$zotero_dois$unique %in% result$oa_dois$id)
  ]

  ### ISBNs Zotero

  result$zotero_isbns <- list(
    id = bibliography$bibliography$ISBN
  )
  names(result$zotero_isbns$id) <- bibliography$bibliography$Key
  result$zotero_isbns$id <- result$zotero_isbns$id[result$zotero_isbns$id != ""]
  result$zotero_isbns$id <- result$zotero_isbns$id[
    !is.na(result$zotero_isbns$id)
  ]

  result$zotero_isbns$count <- sum(!is.na(result$zotero_isbns$id))
  result$zotero_isbns$pc <- 100 *
    result$zotero_isbns$count /
    nrow(bibliography$bibliography)

  result$zotero_isbns$duplicate <- result$zotero_isbns$id[
    result$zotero_isbns$id %in%
      result$zotero_isbns$id[duplicated(result$zotero_isbns$id)]
  ]
  result$zotero_isbns$unique <- result$zotero_isbns$id[
    result$zotero_isbns$id %in% unique(result$zotero_isbns$id)
  ]

  ### ISSNs Zotero

  result$zotero_issns <- list(
    id = bibliography$bibliography$ISSN
  )
  names(result$zotero_issns$id) <- bibliography$bibliography$Key
  result$zotero_issns$id <- result$zotero_issns$id[result$zotero_issns$id != ""]
  result$zotero_issns$id <- result$zotero_issns$id[
    !is.na(result$zotero_issns$id)
  ]

  result$zotero_issns$count <- sum(!is.na(result$zotero_issns$id))
  result$zotero_issns$pc <- 100 *
    result$zotero_issns$count /
    nrow(bibliography$bibliography)

  result$zotero_issns$duplicate <- result$zotero_issns$id[
    result$zotero_issns$id %in%
      result$zotero_issns$id[duplicated(result$zotero_issns$id)]
  ]
  result$zotero_issns$unique <- result$zotero_issns$id[
    result$zotero_issns$id %in% unique(result$zotero_issns$id)
  ]

  ### Types

  result$types <- list()
  result$types$types <- bibliography$bibliography |>
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

  result$types$comparison <- result$types$types |>
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

  dir <- normalizePath(
    file.path("output", "metrics"),
    mustWork = FALSE
  )
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  file <- file.path(dir, basename(bibliography_fn))

  saveRDS(result, file = file)

  return(file)
}
