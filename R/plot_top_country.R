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
