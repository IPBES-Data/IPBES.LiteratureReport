plot_top_country_data <- function(bibliography) {
    data <- sapply(
        bibliography$works$author,
        function(x) {
            x["institution_country_code"]
        }
    ) |>
        unlist() |>
        table() |>
        sort(decreasing = FALSE) |>
        as.data.frame() |>
        setNames(
            c(
                "Country",
                "Count"
            )
        )           
    
    return(data)
}
