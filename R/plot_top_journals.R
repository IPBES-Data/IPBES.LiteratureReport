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