#' Used in the pipeline - Plot Open Access Status by Publication Year
#'
#' This function takes a bibliography object and plots the distribution of open access status
#' by publication year using a stacked bar chart.
#'
#' @param bibliography A bibliography object containing information about publications.
#' @importFrom ggplot2 aes geom_bar scale_fill_manual ggtitle theme element_text
#' @return A ggplot object representing the stacked bar chart.
#' @examples
#' \dontrun{
#' bibliography <- read_bibliography("path/to/bibliography.csv")
#' plot_oa_status(bibliography)
#' }
#' 
plot_oa_status <- function(bibliography) {
    figure <- bibliography$works |>
        ggplot(
            aes(
                x = publication_year,
                fill = oa_status
            )
        ) +
        geom_bar(
            position = "fill"
        ) +
        scale_fill_manual(values = c("#CD7F32", "red", "gold", "green", "pink")) +
        ggtitle("Publication Year") +
        theme(
            plot.title = element_text(size = 15)
        ) +
        theme(legend.position = "bottom")
    
    return(figure)
}