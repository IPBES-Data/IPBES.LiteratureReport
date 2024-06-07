# _targets.R

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
#     # ILK
#     # tar_target(
#     #     ilk_parameter,
#     #     list(
#     #         # input
#     #         bibliography_zotero = file.path(".", "input", "IPBES ILK.csv"),
#     #         bibliography_name = "IPBES ILK Bibliography",
#     #         abbr = "ilk",
#     #         bibliography_url = "https://www.zotero.org/groups/xxxxxxx/",
#     #         mc.cores = 1
#     #     )
#     # ),

#     tar_files(
#         files,
#         c(
#             file.path(".", "input", "IPBES ILK.csv"),
#             file.path(".", "input", "IPBES IAS.csv")
#         )
#     ),
#     tar_target(bibliography, load_bibliography(files), pattern = map(files)),
#     # tar_target(metrics, dois_measures(bibliography), pattern = map(bibliography)),
#     tar_target(figure_pub_year, plot_publication_year(bibliography), pattern = map(bibliography)),
#     tar_target(figure_oa_status, plot_oa_status(bibliography), pattern = map(bibliography)),
#     tar_target(figure_top_journ_data, plot_top_journals_data(bibliography), pattern = map(bibliography)),
#     tar_target(figure_top_journals, plot_top_journals(figure_top_journ_data), pattern = map(figure_top_journ_data)),
#     tar_target(figure_top_country_data, plot_top_country_data(bibliography), pattern = map(bibliography)),
#     tar_target(figure_top_country, plot_top_country(figure_top_country_data), pattern = map(figure_top_country_data))
#     # tar_quarto(
#     #     report_ias,
#     #     "bibliography_report.qmd",
#     #     quiet = FALSE
#     #     map = (???)
#     # )

#     # IAS
#     # tar_target(
#     #     ias_parameter,
#     #     list(
#     #         # input
#     #         bibliography_zotero = file.path(".", "input", "IPBES IAS.csv"),
#     #         bibliography_name = "IPBES IAS Assessment",
#     #         abbr = "ias",
#     #         bibliography_url = "https://www.zotero.org/groups/2352922/ipbes_ias"
#     #     )
#     # ),
#     # tar_target(ias_file, ias_parameter$bibliography_zotero, format = "file"),
#     # tar_target(ias_bibliography, load_bibliography(ias_file)),
#     # # tar_target(ias_metrics, dois_measures(ias_bibliography)),
#     # tar_target(plot_pub_year_ias, plot_publication_year(ias_bibliography)),
#     # tar_target(plot_oa_status_ias, plot_oa_status(ias_bibliography)),
#     # tar_target(plot_top_journals_data_ias, plot_top_journals_data(ias_bibliography)),
#     # tar_target(plot_top_journals_ias, plot_top_journals(plot_top_journals_data_ias)),
#     # tar_target(plot_top_country_data_ias, plot_top_country_data(ias_bibliography)),
#     # tar_target(plot_top_country_ias, plot_top_country(plot_top_country_data_ias)),
#     # tar_quarto(
#     #     report_ias,
#     #     "bibliography_report.qmd",
#     #     quiet = FALSE
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
    # c(
    #     ILK = file.path(".", "input", "IPBES ILK.csv"),
    #     IAS = file.path(".", "input", "IPBES IAS.csv")
    # )
)
tar_map(
    values = values,
    tar_target(bibliography, load_bibliography(files)),
    # tar_target(metrics, dois_measures(bibliography)),
    tar_target(figure_pub_year, plot_publication_year(bibliography)),
    tar_target(figure_oa_status, plot_oa_status(bibliography)),
    tar_target(figure_top_journ_data, plot_top_journals_data(bibliography)),
    tar_target(figure_top_journals, plot_top_journals(figure_top_journ_data)),
    tar_target(figure_top_country_data, plot_top_country_data(bibliography)),
    tar_target(figure_top_country, plot_top_country(figure_top_country_data))
    # tar_quarto(
    #     report,
    #     "bibliography_report.qmd",
    #     quiet = FALSE
    # )
)



# quarto::quarto_render("bibliography_report.qmd", execute_params = list(bibliography = tar_read(ias_bibliography)))
