#' Used in the pipeline - Load and prepare bibliography
#'
#' This function loads and prepares the bibliography for rurther analysis.
#'
#' @param bibliography_zotero_file The file path to the bibliography exported from Zotero in CSV format \bold{without extension}.
#' @param verbose Whether to display verbose output.
#'
#' @return A list containing the calculated metrics for the bibliography:
#'   - timestamp: The timestamp when the bibliography was created.
#'   - name: The name of the bibliography.
#'   - url: The URL of the bibliography.
#'   - bibliography: The data frame containing the bibliography.
#'   - dois_bib: The DOIs extracted from the bibliography.
#'   - isbns: The ISBNs extracted from the bibliography.
#'   - issns: The ISSNs extracted from the bibliography.
#'   - works: The works fetched using the DOIs.
#'   - dois_works: The standardized DOIs extracted from the works.
#'
#'
#' @examples
#' \dontrun{
#' bibliography <- load_bibliography(
#'   bibliography_zotero_file = "path/to/bibliography.csv",
#'   verbose = TRUE
#' )
#'
#' # Print the calculated metrics
#' print(bibliography)
#' }
#'
#' @md
#'
#' @importFrom tibble as_tibble
#' @importFrom utils read.csv
#' @importFrom openalexR oa_fetch
#' @importFrom openalexPro2 extract_doi
#'
#' @export

load_bibliography <- function(
  bibliography_zotero_file = NULL,
  verbose = FALSE
) {
  ##

  bibliography_name <- bibliography_zotero_file |>
    gsub(
      pattern = "\\.csv",
      replacement = ""
    ) |>
    strsplit(
      split = "_"
    )
  bibliography_name <- bibliography_name[[1]][[2]]

  bibliography_url <- bibliography_zotero_file |>
    gsub(
      pattern = "\\.csv",
      replacement = ""
    ) |>
    strsplit(
      split = "_"
    )
  bibliography_url <- paste0(
    "https://www.zotero.org/groups/",
    bibliography_url[[1]][[3]]
  )

  bibliography <- list(
    timestamp = Sys.time(),
    name = bibliography_name,
    url = bibliography_url
  )

  class(bibliography) <- c("IPBES.bibliography", class(bibliography))

  if (!grepl("\\.csv", bibliography_zotero_file)) {
    bibliography_zotero_file <- paste0(bibliography_zotero_file, ".csv")
    if (!file.exists(bibliography_zotero_file)) {
      bibliography_zotero_file <- file.path(
        "input",
        bibliography_zotero_file
      )
    }
  }

  bibliography$bibliography <- read.csv(
    bibliography_zotero_file,
    stringsAsFactors = FALSE
  ) |>
    dplyr::mutate(
      doi_short = openalexPro2::extract_doi(
        DOI,
        non_doi_value = NA_character_
      )
    ) |>
    tibble::as_tibble()

  #| label: load_bibliography

  #| label: get_works

  bibliography$works <-
    openalexR::oa_fetch(
      entity = "works",
      doi = bibliography$bibliography$doi_short[
        !is.na(bibliography$bibliography$doi_short)
      ],
      verbose = verbose
    )

  #| label: get_standardise_dois_works

  # add in_oa to bibliography_bibliography

  bibliography$bibliography$in_oa <-
    bibliography$bibliography$doi_short %in%
    openalexPro2::extract_doi(bibliography$works$doi)

  ###

  dir <- normalizePath(file.path("output", "bibliographies"), mustWork = FALSE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  file <- file.path(dir, basename(bibliography_zotero_file)) |>
    gsub(
      pattern = "\\.csv$",
      replacement = ".rds"
    )

  saveRDS(bibliography, file = file)

  return(file)
}
