#' Used in the pipeline - Used in the pipeline - Plot Publication Year
#'
#' This function takes a bibliography object and plots the number of publications over time.
#'
#' #' The function first processes the bibliography object to calculate the count and proportion of publications for each year and item type.
#' It then joins the processed data from the bibliography object and creates a plot using ggplot2.
#' The plot shows the cumulative number of publications over time, with separate lines for different item types.
#' The x-axis represents the publication year, and the y-axis represents the number of publications.
#' The secondary y-axis represents the cumulative number of references, scaled back by a factor of 10.
#' The plot also includes a legend for the item types.
#' @param bibliography A bibliography object containing publication information.
#'
#' @importFrom dplyr group_by summarize arrange mutate rename case_match full_join filter
#' @importFrom ggplot2 ggplot geom_line scale_fill_viridis_d scale_x_continuous scale_y_continuous labs theme_minimal theme guides element_text guide_legend sec_axis
#'
#' @md
#'
#' @examples
#' \dontrun{
#' # Load required packages
#' library(dplyr)
#' library(ggplot2)
#'
#' # Create a sample bibliography object
#' bibliography <- list(
#'   bibliography = data.frame(
#'     Publication.Year = c(2000, 2001, 2002, 2003, 2004),
#'     Item.Type = c("journalArticle", "book", "journalArticle", "book", "conferencePaper")
#'   ),
#'   works = data.frame(
#'     publication_year = c(2000, 2001, 2002, 2003, 2004),
#'     type = c("journalArticle", "book", "journalArticle", "book", "conferencePaper")
#'   )
#' )
#'
#' # Plot the publication year
#' plot_publication_year_data(bibliography)
#' }
#' @export
plot_publication_year_data <- function(bibliography) {
  data_bib <- bibliography$bibliography |>
    dplyr::group_by(
      Publication.Year,
    ) |>
    dplyr::summarize(
      count = n(),
      p = count / sum(count),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      Publication.Year
    ) |>
    mutate(
      count_cumsum = cumsum(count),
      p_cumsum = cumsum(p),
      from = "Zenodo"
    ) |>
    dplyr::rename(
      publication_year = Publication.Year,
    )

  data_works <- bibliography$works |>
    dplyr::group_by(
      publication_year,
    ) |>
    dplyr::summarize(
      count = n(),
      p = count / sum(count),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      publication_year
    ) |>
    mutate(
      count_cumsum = cumsum(count),
      p_cumsum = cumsum(p),
      from = "OpenAlex"
    ) |>
    dplyr::rename(
      publication_year = publication_year,
      count = count,
      p = p,
      count_cumsum = count_cumsum,
      p_cumsum = p_cumsum
    )

  data <- dplyr::bind_rows(
    data_bib,
    data_works
  ) |>
    dplyr::ungroup()

  return(data)
}
