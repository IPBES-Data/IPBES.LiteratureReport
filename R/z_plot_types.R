plot_types <- function(data) {
  figure <- data |>
    ggplot(
      aes(
        x = reorder(type, count),
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
    ) +
    facet_wrap(
      vars(from) # Add this line to create facets by the 'from' variable
    )

  return(figure)
}
