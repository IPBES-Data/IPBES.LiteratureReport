plot_top_journals_data <- function(bibliography) {
    data <- bibliography$bibliography |>
        dplyr::group_by(
            Publication.Title
        ) |>
        dplyr::summarise(
            count = n()
        ) |>
        dplyr::rename(
            Journal = Publication.Title
        ) |>
        dplyr::filter(
            Journal != ""
        ) |>
        dplyr::slice_max(
            count,
            n = 50
        )
    
    return(data)
}