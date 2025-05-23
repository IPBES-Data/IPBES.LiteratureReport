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
plot_oa_status <- function(data_fn) {
  data <- readRDS(data_fn)
  figure <- data |>
    ggplot2::ggplot(
      aes(
        x = publication_year,
        fill = factor(
          oa_status,
          levels = c("closed", "hybrid", "bronze", "green", "gold", "diamond")
        )
      )
    ) +
    ggplot2::geom_bar(
      # position = "fill"
    ) +
    ggplot2::scale_fill_manual(
      breaks = c("diamond", "gold", "green", "bronze", "hybrid", "closed"),
      values = c("white", "gold", "green", "#CD7F32", "cyan", "red")
    ) +
    ggplot2::ggtitle("Publication Year") +
    ggplot2::theme(
      plot.title = element_text(size = 15)
    ) +
    ggplot2::theme(legend.position = "bottom") +
    ggplot2::labs(fill = "Open Access Status")

  dir <- normalizePath(
    file.path("output", "plot_oa_status"),
    mustWork = FALSE
  )
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)

  file <- file.path(dir, basename(data_fn)) |>
    gsub(
      pattern = "\\.rds$",
      replacement = "_ggplot.rds"
    )

  saveRDS(figure, file = file)

  return(file)
}
