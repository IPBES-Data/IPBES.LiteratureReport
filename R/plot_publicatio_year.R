plot_publication_year <- function(bibliography) {
    data_bib <- bibliography$bibliography |>
        dplyr::group_by(
            Publication.Year,
            Item.Type
        ) |>
        dplyr::summarize(
            count = n(),
            p = count / sum(count),
        ) |>
        dplyr::group_by(
            Item.Type
        ) |>
        dplyr::arrange(
            Publication.Year
        ) |>
        mutate(
            count_cumsum = cumsum(count),
            p_cumsum = cumsum(p)
        ) |>
        dplyr::rename(
            publication_year = Publication.Year,
            type = Item.Type
        ) |>
        dplyr::mutate(
            type = dplyr::case_match(
                type,
                "journalArticle" ~ "article",
                .default = type
            )
        )

    data_works <- bibliography$works |>
        dplyr::group_by(
            publication_year,
            type
        ) |>
        dplyr::summarize(
            count = n(),
            p = count / sum(count),
        ) |>
        dplyr::group_by(
            type
        ) |>
        dplyr::arrange(
            publication_year
        ) |>
        mutate(
            count_cumsum = cumsum(count),
            p_cumsum = cumsum(p)
        ) |>
        dplyr::rename(
            publication_year = publication_year,
            type = type,
            count_oa = count,
            p_oa = p,
            count_oa_cumsum = count_cumsum,
            p_oa_cumsum = p_cumsum
        )

    data <- dplyr::full_join(
        x = data_bib,
        y = data_works,
        by = c("publication_year", "type")
    )

    rm(data_bib, data_works)

    figure <- data |>
        dplyr::filter(publication_year >= 1950) |>
        ggplot() +
        scale_fill_viridis_d(option = "plasma") +
        geom_line(aes(x = publication_year, y = count_cumsum / 10, colour = type), linetype = "solid") + # Zotero
        geom_line(aes(x = publication_year, y = count_oa_cumsum / 10, colour = type), linetype = "dashed") + # OpenAlex
        scale_x_continuous(
            breaks = seq(1500, 2020, 10)
        ) +
        scale_y_continuous(
            "Proportion of publications",
            sec.axis = sec_axis(~ . * 10, name = "Cumulative number of references") # divide by 10 to scale back the secondary axis
        ) +
        labs(
            title = "Publications over time",
            x = "Year",
            y = "Number of publications"
        ) +
        theme_minimal() +
        theme(axis.text.y.right = element_text(color = "red")) +
        theme(legend.position = "bottom") +
        guides(
            fill = guide_legend(
                title = "Legend"
            )
        )
    return(figure)
}