#' Used in the pipeline - Plot Top Country
#'
#' This function takes a data frame as input and plots a bar chart of the top countries based on the count of authors.
#'
#' The `plot_top_country` function takes a data frame as input and plots a bar chart of the top countries based on the 
#' count of authors. It filters the data frame to include only countries with a count greater than 10, and then uses 
#' `ggplot2` to create the bar chart. The x-axis represents the countries, and the y-axis represents the count of authors. 
#' The title of the plot is "Countries of Institutes of all Authors". The function returns a `ggplot` object representing 
#' the bar chart.
#' @param data A data frame containing the following columns:
#'   \describe{
#'     \item{Country}{The country of the author.}
#'     \item{Count}{The count of authors from the country.}
#'   }
#'
#' @importFrom dplyr filter
#' @importFrom ggplot2 aes geom_bar coord_flip labs theme element_text
#'
#' @return A ggplot object representing the bar chart.
#'
#' @md
#' 
#' @examples
#' \dontrun{
#' data <- data.frame(
#'   Country = c("USA", "Germany", "China", "India"),
#'   Count = c(20, 15, 12, 10)
#' )
#' 
#' plot_top_country(data)
#' }
#'
#' \dontrun{
#' data <- data.frame(
#'   Country = c("USA", "Germany", "China", "India"),
#'   Count = c(20, 15, 12, 10)
#' )
#' 
#' plot_top_country(data)
#' }
#'
#' @export
plot_top_country <- function(data) {
    figure <- data |>
        dplyr::filter(
            Count > 10
        ) |>
        ggplot(
            aes(
                x = Country,
                y = Count
            )
        ) +
        geom_bar(
            stat = "identity",
            fill = "steelblue"
        ) +
        coord_flip() +
        labs(
            x = "Country",
            y = "Count",
            title = "Countries of Institutes of all Authors"
        ) +
        theme(
            plot.title = element_text(size = 15)
        )
    
    return(figure)
}
