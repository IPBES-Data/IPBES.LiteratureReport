#' Plot the types of publications
#'
#' This function takes a data frame as input and plots a bar chart of the types of publications.
#'
#' The `plot_types` function takes a data frame as input and plots a bar chart of the types of publications.
#' It filters the data frame to include only publications with a count greater than 10, and then uses
#' `ggplot2` to create the bar chart. The x-axis represents the types of publications, and the y-axis represents the count of publications.
#' The title of the plot is "Most often cited Journals". The function returns a `ggplot` object representing
#' the bar chart.
#' @param data A data frame containing the following columns:
#'   \describe{
#'     \item{type}{The type of publication.}
#'     \item{count}{The count of publications.}
#'   }
#'
#' @importFrom dplyr filter
#' @importFrom ggplot2 aes geom_bar coord_flip labs ggtitle theme element_text facet_wrap
#'
#' @return A ggplot object representing the bar chart.
#'
#' @md
#'
#' @export
plot_types <- function(data_fn) {
  data <- readRDS(data_fn)
  figure <- data |>
    ggplot2::ggplot(
      aes(
        x = reorder(type, count),
        y = count
      )
    ) +
    ggplot2::geom_bar(
      stat = "identity",
      fill = "steelblue"
    ) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      x = "Journal",
      y = "Count"
    ) +
    ggplot2::ggtitle(
      "Most often cited Journals"
    ) +
    ggplot2::theme(
      plot.title = element_text(size = 15)
    ) +
    ggplot2::facet_wrap(
      dplyr::vars(from) # Add this line to create facets by the 'from' variable
    )

  dir <- normalizePath(
    file.path("output", "plot_types"),
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
