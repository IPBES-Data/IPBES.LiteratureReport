#' Calculate Bibliography Metrics
#'
#' This function calculates various metrics for a given bibliography.
#'
#' @param bibliography_zotero The file path to the bibliography exported from Zotero in CSV format.
#' @param bibliography_name The name of the bibliography.
#' @param bibliography_url The URL of the bibliography.
#' @param mc.cores The number of CPU cores to use for parallel processing.
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
#' # Load the bibliography from a CSV file
#' bibliography <- bibliography_metrics(
#'     bibliography_zotero = "path/to/bibliography.csv",
#'     bibliography_name = "My Bibliography",
#'     bibliography_url = "https://example.com/bibliography",
#'     mc.cores = 4,
#'     verbose = TRUE
#' )
#'
#' # Print the calculated metrics
#' print(bibliography)
#' @md
#'
#' @importFrom tibble as_tibble
#' @importFrom utils read.csv
#'
#' @export
bibliography_metrics <- function(
    bibliography_zotero = NULL,
    bibliography_name = "bibliography",
    bibliography_url = "",
    mc.cores = getOption("mc.cores", 2L),
    verbose = FALSE) {
    #
    #| label: setup
    bibliography <- list(
        timestamp = Sys.time(),
        name = bibliography_name,
        url = bibliography_url
    )

    class(bibliography) <- c("IPBES.bib_metrics", class(bibliography))

    bibliography$bibliography <- read.csv(
        bibliography_zotero,
        stringsAsFactors = FALSE
    ) |>
        tibble::as_tibble()

    #| label: load_bibliography

    bibliography$dois_bib <- bibliography$bibliography$DOI
    names(bibliography$dois_bib) <- bibliography$bibliography$Key
    bibliography$dois_bib <- bibliography$dois_bib[bibliography$dois_bib != ""]

    bibliography$dois_bib <- bibliography$dois_bib |>
        gsub(pattern = "^https://doi.org/", replacement = "") |>
        gsub(pattern = "^https://dx.doi.org/", replacement = "") |>
        gsub(pattern = "^https://hdl.handle.net/", replacement = "") |>
        gsub(pattern = "^http://doi.org/", replacement = "") |>
        gsub(pattern = "^http://dx.doi.org/", replacement = "") |>
        gsub(pattern = "^http://hdl.handle.net/", replacement = "") |>
        gsub(pattern = "^doi:", replacement = "") |>
        gsub(pattern = "^DOI ", replacement = "")

    bibliography$isbns <- bibliography$bibliography$ISBN
    names(bibliography$isbns) <- bibliography$bibliography$Key
    bibliography$isbns <- bibliography$isbns[bibliography$isbns != ""]


    bibliography$issns <- bibliography$bibliography$ISSN
    names(bibliography$issns) <- bibliography$bibliography$Key
    bibliography$issns <- bibliography$issns[bibliography$issns != ""]

    #| label: get_works

    doi_chunks <- split(unique(bibliography$dois_bib), ceiling(seq_along(unique(bibliography$dois_bib)) / 199))
    #
    bibliography$works <- parallel::mclapply(
        seq_along(doi_chunks),
        function(i) {
            valid <- IPBES.R::doi_valid(doi_chunks[[i]])
            dois <- names(valid)[valid]
            oa_fetch(
                entity = "works",
                doi = dois,
                per_page = 200,
                verbose = verbose
            )
        },
        mc.cores = mc.cores
    ) |>
        do.call(what = rbind)

    rm(doi_chunks)

    #| label: get_standardise_dois_works

    bibliography$dois_works <- bibliography$works$doi |>
        gsub(pattern = "^https://doi.org/", replacement = "") |>
        gsub(pattern = "^https://dx.doi.org/", replacement = "") |>
        gsub(pattern = "^https://hdl.handle.net/", replacement = "") |>
        gsub(pattern = "^http://doi.org/", replacement = "") |>
        gsub(pattern = "^http://dx.doi.org/", replacement = "") |>
        gsub(pattern = "^http://hdl.handle.net/", replacement = "") |>
        gsub(pattern = "^doi:", replacement = "") |>
        gsub(pattern = "^DOI ", replacement = "") |>
        unique()

    ###
    return(bibliography)
}
