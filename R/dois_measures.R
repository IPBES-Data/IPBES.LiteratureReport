dois_measures <- function(
    bibliography
){
    result <- list()
    
    ##
    
    dois_not_in_oa <- unique(params$bibliography$dois)[!(unique(params$bibliography$dois) %in% params$bibliography$dois_works)]

    dois_valid <- dois_not_in_oa[IPBES.R::doi_valid(dois_not_in_oa)]

    result$dois_valid <- unique(bibliography$dois)[IPBES.R::doi_valid(unique(bibliography$dois))]
    
    result$dois_in_oa <- intersect(
        bibliography$dois,
        bibliography$dois_works
    ) |>
        unique()
    # result$dois_valid_not_oa_exist <- IPBES.R::doi_exists(
    #     setdiff(
    #         result$dois_valid,
    #         result$dois_in_oa
    #     )
    #     cache_file = params$exists_cache
    # )

    ##

    return(result)
}