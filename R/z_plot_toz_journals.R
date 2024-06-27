#' Used in the pipeline - Plot Top Journals
#'
#' This function takes a data frame as input and plots a bar chart of the top cited journals.
#'
#' The `plot_top_journals` function takes a data frame as input and creates a bar chart using the `ggplot2` package. 
#' The x-axis represents the journal names, ordered by their citation count, and the y-axis represents the count of 
#' citations. The function returns a `ggplot` object representing the bar chart.
#' 
#' @param data A data frame containing the journal names and their corresponding citation counts.
#'
#' @importFrom ggplot2 ggplot aes geom_bar coord_flip labs ggtitle theme element_text
#'
#' @return A ggplot object representing the bar chart of the top cited journals.
#'
#' @examples
#' \dontrun{
#' # Create sample data frame
#' data <- data.frame(
#'   Journal = c("Journal A", "Journal B", "Journal C"),
#'   count = c(10, 15, 5)
#' )
#'
#' # Plot top journals
#' plot_top_journals(data)
#' }
#'
#' @md
#' 

plot_top_journals <- function(data) {
    figure <- data |>
        ggplot(
            aes(
                x = reorder(Journal, count),
                y = count
            )
        ) +
        geom_bar(
            stat = "identity",
            fill = "steelblue"
        ) +
        coord_flip() +
        labs(
            x = "Journal",
            y = "Count"
        ) +
        ggtitle(
            "Most often cited Journals"
        ) +
        theme(
            plot.title = element_text(size = 15)
        )
    
    return(figure)
}