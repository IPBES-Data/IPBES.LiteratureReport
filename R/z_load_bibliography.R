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
    tibble::as_tibble()

  #| label: load_bibliography

  #| label: get_works

  dois <- bibliography$bibliography$DOI
  dois <- dois[dois != ""]
  dois <- dois[!is.na(dois)]
  dois <- dois |>
    gsub(pattern = "^https://doi.org/", replacement = "") |>
    gsub(pattern = "^https://dx.doi.org/", replacement = "") |>
    gsub(pattern = "^https://hdl.handle.net/", replacement = "") |>
    gsub(pattern = "^http://doi.org/", replacement = "") |>
    gsub(pattern = "^http://dx.doi.org/", replacement = "") |>
    gsub(pattern = "^http://hdl.handle.net/", replacement = "") |>
    gsub(pattern = "^doi:", replacement = "") |>
    gsub(pattern = "^DOI ", replacement = "")

  bibliography$works <-
    openalexR::oa_fetch(
      entity = "works",
      doi = names(IPBES.R::doi_valid(
        bibliography$bibliography$DOI
      ))[IPBES.R::doi_valid(bibliography$bibliography$DOI)],
      verbose = verbose
    )

  #| label: get_standardise_dois_works

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
