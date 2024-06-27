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
get_bibliography_measures <- function(
    bibliography) {
    result <- list()

    ##

    result$dois_count <- sum(!is.na(bibliography$dois))
    result$dois_pc <- 100 * result$dois_count / nrow(bibliography$bibliography)
    result$dois_duplicates <- length(bibliography$dois) - length(unique((bibliography$dois)))
    result$dois_unique <- unique(bibliography$dois) |> length()
    #
    result$isbns_count <- sum(!is.na(bibliography$isbns))
    result$isbns_pc <- 100 * result$isbns_count / nrow(bibliography$bibliography)
    result$isbns_duplicates <- length(bibliography$isbns) - length(unique((bibliography$isbns)))
    result$isbns_unique <- unique(bibliography$isbns) |> length()
    #
    result$issns_count <- sum(!is.na(bibliography$issns))
    result$issns_pc <- 100 * result$issns_count / nrow(bibliography$bibliography)
    result$issns_duplicates <- length(bibliography$issns) - length(unique((bibliography$issns)))
    result$issns_unique <- unique(bibliography$issns) |> length()

    ##

    result$dois_not_in_oa <- setdiff(
        bibliography$dois,
        bibliography$dois_works
    ) |> unique()

    result$dois_in_oa <- intersect(
        bibliography$dois,
        bibliography$dois_works
    ) |>
        unique()

    ##

    result$dois_valid <- bibliography$dois[IPBES.R::doi_valid(bibliography$dois)] |>
        unique()


    # result$dois_exist <- IPBES.R::doi_exists(
    #     result$dois_valid,
    #     cache_file = file.path(".", "cache", "doi_exist.rds")
    # )

    ##

    return(result)
}
