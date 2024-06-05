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