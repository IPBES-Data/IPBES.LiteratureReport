dois_measures <- function(bibliography, params
){
    result <- list()
    
    ##
    
    result$dois_bib_valid <- unique(bibliography$dois_bib)[IPBES.R::doi_valid(unique(bibliography$dois_bib))]
    result$dois_bib_in_oa <- intersect(
        bibliography$dois_bib,
        bibliography$dois_works
    ) |>
        unique()
    # result$dois_bib_valid_not_oa_exist <- IPBES.R::doi_exists(
    #     setdiff(
    #         result$dois_valid,
    #         result$dois_in_oa
    #     )
    #     cache_file = params$exists_cache
    # )

    ##

    return(result)
}