# _targets.R
# see https://github.com/ropensci/targets/discussions/1297 for long discussion

library(targets)
library(tarchetypes)

list.files(
    path = "R",
    pattern = "\\.R$",
    full.names = TRUE
) |>
    sapply(
        FUN = source
    )

tar_option_set(
    packages = c(
        "openalexR",
        "knitr",
        "dplyr",
        "ggplot2",
        # "ggraph",
        # "tidygraph",
        "IPBES.R"
    )
)

#### Dynamic Branching
# list(
#     tar_files(
#         files,
#         list.files(file.path(".", "input"), pattern = "\\.csv$", full.names = TRUE)
#     ),
#     tar_target(bibliography, load_bibliography(files), pattern = map(files)),
#     tar_target(metrics, get_bibliography_measures(bibliography), pattern = map(bibliography)),
#     tar_target(figure_pub_year, plot_publication_year(bibliography), pattern = map(bibliography)),
#     tar_target(figure_oa_status, plot_oa_status(bibliography), pattern = map(bibliography)),
#     tar_target(figure_top_journ_data, plot_top_journals_data(bibliography), pattern = map(bibliography)),
#     tar_target(figure_top_journals, plot_top_journals(figure_top_journ_data), pattern = map(figure_top_journ_data)),
#     tar_target(figure_top_country_data, plot_top_country_data(bibliography), pattern = map(bibliography)),
#     tar_target(figure_top_country, plot_top_country(figure_top_country_data), pattern = map(figure_top_country_data)),
#     tar_quarto_rep(
#         report,
#         "bibliography_report.qmd",
#         execute_params = list(
#             bibliography,
#             metrics,
#             figure_pub_year,
#             figure_oa_status,
#             figure_top_journ_data,
#             figure_top_journals,
#             figure_top_country_data,
#             figure_top_country
#         )
#     )
#     # tar_quarto(
#     #     report_ias,
#     #     "bibliography_report.qmd",
#     #     quiet = FALSE
#     #     map = (???)
#     # )
# )


#### Static Branching

values <- data.frame(
    files = list.files(
        path = "input",
        pattern = "\\.csv$",
        full.names = FALSE
    ) |>
        gsub(pattern = "\\.csv$", replacement = "")
)
names <- data.frame(
    name = gsub(values$files, pattern = " ", replacement = ".")
)
list(
    tar_map(
        values = values,
        tar_target(bibliography, load_bibliography(files)),
        tar_target(metrics, get_bibliography_measures(bibliography)),
        tar_target(figure_pub_year, plot_publication_year(bibliography)),
        tar_target(figure_oa_status, plot_oa_status(bibliography)),
        tar_target(figure_top_journals_data, plot_top_journals_data(bibliography)),
        tar_target(figure_top_journals, plot_top_journals(figure_top_journals_data)),
        tar_target(figure_top_country_data, plot_top_country_data(bibliography)),
        tar_target(figure_top_country, plot_top_country(figure_top_country_data))
    )
)

# list(
#     mapped,
#     tar_eval(
#         tar_quarto(
#             name = name,
#             path = "bibliography_report.qmd",
#             execute_params = list(branch = tar_name()),
#             quarto_args = 'output_file = your_output_filename.html',
#             quiet = FALSE
#         ),
#         values = names
#     )
# )




# quarto::quarto_render("bibliography_report.qmd", execute_params = list(bibliography = tar_read(ias_bibliography)))
