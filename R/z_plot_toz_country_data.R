#' Used in the pipeline - Plot Top Country Data
#'
#' This function takes a bibliography as input and returns a data frame with the count of works per country.
#'
#' @param bibliography A bibliography object containing information about works.
#'#'
#' @return A data frame with two columns: `Country`` and `Count`.
#'
#' @md
#' @examples
#' \dontrun{
#' bibliography <- read_bibliography("path/to/bibliography.csv")
#' plot_top_country_data(bibliography)
#' }
#' 
#' @export
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
