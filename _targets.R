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
        "parallel",
        "IPBES.R"
    )
)

list(
    # ILK
    # tar_target(
    #     ilk_parameter,
    #     list(
    #         # input
    #         bibliography_zotero = file.path(".", "input", "IPBES ILK.csv"),
    #         bibliography_name = "IPBES ILK Bibliography",
    #         abbr = "ilk",
    #         bibliography_url = "https://www.zotero.org/groups/xxxxxxx/",
    #         mc.cores = 1
    #     )
    # ),
    tar_target(ilk_file, file.path(".", "input", "IPBES ILK.csv"), format = "file"),
    tar_target(ilk_bibliography, bibliography_metrics(ilk_file, mc.cores = 1)),
    tar_target(ilk_metrics, dois_measures(ilk_bibliography)),
    tar_target(plot_pub_year_ilk, plot_publication_year(ilk_bibliography)),
    tar_target(plot_oa_status_ilk, plot_oa_status(ilk_bibliography)),
    tar_target(plot_top_journals_data_ilk, plot_top_journals_data(ilk_bibliography)),
    tar_target(plot_top_journals_ilk, plot_top_journals(plot_top_journals_data_ilk)),
    tar_target(plot_top_country_data_ilk, plot_top_country_data(ilk_bibliography)),
    tar_target(plot_top_country_ilk, plot_top_country(plot_top_country_data_ilk)),

    # IAS
    tar_target(
        ias_parameter,
        list(
            # input
            bibliography_zotero = file.path(".", "input", "IPBES IAS.csv"),
            bibliography_name = "IPBES IAS Assessment",
            abbr = "ias",
            bibliography_url = "https://www.zotero.org/groups/2352922/",
            #
            # exists_cache =  file.path(".", "cache", "doi_exist.rds"),
            #
            mc.cores = 1
        )
    ),
    tar_target(ias_file, ias_parameter$bibliography_zotero, format = "file"),
    tar_target(ias_bibliography, bibliography_metrics(ias_file, mc.cores = ias_parameter$mc.cores)),
    tar_target(ias_metrics, dois_measures(ias_bibliography)),
    tar_target(plot_pub_year_ias, plot_publication_year(ias_bibliography)),
    tar_target(plot_oa_status_ias, plot_oa_status(ias_bibliography)),
    tar_target(plot_top_journals_data_ias, plot_top_journals_data(ias_bibliography)),
    tar_target(plot_top_journals_ias, plot_top_journals(plot_top_journals_data_ias)),
    tar_target(plot_top_country_data_ias, plot_top_country_data(ias_bibliography)),
    tar_target(plot_top_country_ias, plot_top_country(plot_top_country_data_ias)),
    tar_quarto(
        report,
        "bibliography_report.qmd",
        execute_params = ias_parameter,
        quiet = FALSE
    )
)

