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
#' @export
plot_oa_status <- function(data) {
  figure <- data |>
    ggplot(
      aes(
        x = publication_year,
        fill = factor(
          oa_status,
          levels = c("closed", "hybrid", "bronze", "green", "gold", "diamond")
        )
      )
    ) +
    geom_bar(
      # position = "fill"
    ) +
    scale_fill_manual(
      breaks = c("diamond", "gold", "green", "bronze", "hybrid", "closed"),
      values = c("white", "gold", "green", "#CD7F32", "cyan", "red")
    ) +
    ggtitle("Publication Year") +
    theme(
      plot.title = element_text(size = 15)
    ) +
    theme(legend.position = "bottom") +
    labs(fill = "Open Access Status")

  return(figure)
}
