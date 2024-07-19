# _targets.R
# see https://github.com/ropensci/targets/discussions/1297 for long discussion


library(targets)
library(tarchetypes)

lapply(
  list.files(
    "R",
    pattern = "^z_.*\\.R$",
    full.names = TRUE
  ),
  source
)

targets::tar_option_set(
  packages = c(
    "openalexR",
    "knitr",
    "dplyr",
    "ggplot2",
    "IPBES.R"
  )
)

# if (FALSE) {
#   #### Dynamic Branching
#   list(
#     tar_files_input(
#       name = files,
#       files = list.files(
#         file.path(
#           "input"
#         ),
#         pattern = "\\.csv$",
#         full.names = TRUE
#       )
#     ),
#     tar_target(bibliography, load_bibliography(files), pattern = map(files)),
#     tar_target(metrics, get_bibliography_measures(bibliography), pattern = map(bibliography)),
#     tar_target(figure_pub_year, plot_publication_year(bibliography), pattern = map(bibliography)),
#     tar_target(figure_oa_status, plot_oa_status(bibliography), pattern = map(bibliography)),
#     tar_target(figure_top_journals_data, plot_top_journals_data(bibliography), pattern = map(bibliography)),
#     tar_target(figure_top_journals, plot_top_journals(figure_top_journals_data), pattern = map(figure_top_journals_data)),
#     tar_target(figure_top_country_data, plot_top_country_data(bibliography), pattern = map(bibliography)),
#     tar_target(figure_top_country, plot_top_country(figure_top_country_data), pattern = map(figure_top_country_data)),
#     tar_target(figure_types_data, plot_types_data(bibliography), pattern = map(bibliography)),
#     tar_target(
#       combined_data,
#       list(
#         bibliography = bibliography,
#         metrics = metrics,
#         figure_pub_year = figure_pub_year,
#         figure_oa_status = figure_oa_status,
#         figure_top_journals_data = figure_top_journals_data,
#         figure_top_journals = figure_top_journals,
#         figure_top_country_data = figure_top_country_data,
#         figure_top_country = figure_top_country,
#         figure_types_data = figure_types_data
#       ),
#       pattern = map(
#         files,
#         bibliography,
#         metrics,
#         figure_top_journals_data,
#         figure_top_journals,
#         figure_top_country_data,
#         figure_top_country,
#         figure_pub_year,
#         figure_oa_status
#       )
#     )
#   )
# } else {

#### Static Branching

list(
  tarchetypes::tar_map(
    values = data.frame(
      files = list.files(
        path = "input",
        pattern = "\\.csv$",
        full.names = FALSE
      ) |>
        gsub(
          pattern = "\\.csv",
          replacement = ""
        )
    ),
    tar_target(bibliography, load_bibliography(files)),
    #
    tar_target(metrics, get_bibliography_measures(bibliography)),
    #
    tar_target(figure_pub_year_data, plot_publication_year_data(bibliography)),
    tar_target(figure_pub_year, plot_publication_year(figure_pub_year_data)),
    #
    tar_target(figure_oa_status_data, plot_oa_status_data(bibliography)),
    tar_target(figure_oa_status, plot_oa_status(figure_oa_status_data)),
    #
    tar_target(figure_top_journals_data, plot_top_journals_data(bibliography)),
    tar_target(figure_top_journals, plot_top_journals(figure_top_journals_data)),
    #
    tar_target(figure_top_country_data, plot_top_country_data(bibliography)),
    tar_target(figure_top_country, plot_top_country(figure_top_country_data)),
    #
    tar_target(figure_types_data, plot_types_data(bibliography)),
    tar_target(figure_types, plot_types(figure_types_data)),
    #
    tar_target(
      combined_data,
      list(
        bibliography = bibliography,
        #
        metrics = metrics,
        #
        figure_pub_year_data = figure_pub_year_data,
        figure_pub_year = figure_pub_year,
        #
        figure_oa_status_dara = figure_oa_status_data,
        figure_oa_status = figure_oa_status,
        #
        figure_top_journals_data = figure_top_journals_data,
        figure_top_journals = figure_top_journals,
        #
        figure_top_country_data = figure_top_country_data,
        figure_top_country = figure_top_country,
        #
        figure_types_data = figure_types_data,
        figure_types = figure_types
      )
    )
  )
)
# }
