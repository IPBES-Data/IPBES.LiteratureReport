# _targets.R
# see https://github.com/ropensci/targets/discussions/1297 for long discussion

library(targets)
library(tarchetypes)

# lapply(
#   list.files(
#     "R",
#     pattern = "^z_.*\\.R$",
#     full.names = TRUE
#   ),
#   source
# )

targets::tar_option_set(
  packages = c(
    "LitReport"
    # "openalexR",
    # "knitr",
    # "dplyr",
    # "ggplot2",
    # "IPBES.R"
  )
)

list(
  # Track input groups.csv -------------------------------------------------

  tar_target(
    group_file,
    file.path("input", "groups.csv"),
    format = "file"
  ),

  # Read full table as data.frame ------------------------------------------

  tar_target(
    groups_df,
    read.csv(group_file, stringsAsFactors = FALSE)
  ),

  # Create one branch per row ----------------------------------------------

  tar_target(
    group,
    groups_df,
    pattern = map(groups_df),
    iteration = "list"
  ),

  # Get Zotero group file for each row -------------------------------------

  tar_target(
    zotero_group,
    update_group(group = group),
    pattern = map(group),
    format = "file"
  ),

  # Get Bibliographies from OpenAlex ---------------------------------------

  tar_target(
    bibliography,
    suppressWarnings(load_bibliography(zotero_group)),
    pattern = map(zotero_group),
    format = "file"
  ),

  # Calculate metrics ------------------------------------------------------

  tar_target(
    metrics,
    get_bibliography_measures(bibliography),
    pattern = map(bibliography),
    format = "file"
  ),

  # Plot pub year ----------------------------------------------------------

  tar_target(
    figure_pub_year_data,
    plot_publication_year_data(bibliography_fn = bibliography),
    pattern = map(bibliography),
    format = "file"
  ),
  tar_target(
    figure_pub_year,
    suppressWarnings(plot_publication_year(figure_pub_year_data)),
    pattern = map(figure_pub_year_data),
    format = "file"
  ),

  # Plot OA status ---------------------------------------------------------

  tar_target(
    figure_oa_status_data,
    plot_oa_status_data(bibliography),
    pattern = map(bibliography),
    format = "file"
  ),
  tar_target(
    figure_oa_status,
    plot_oa_status(figure_oa_status_data),
    pattern = map(figure_oa_status_data),
    format = "file"
  ),

  # Plot top Journals ------------------------------------------------------

  tar_target(
    figure_top_journals_data,
    plot_top_journals_data(bibliography),
    pattern = map(bibliography),
    format = "file"
  ),
  tar_target(
    figure_top_journals,
    plot_top_journals(figure_top_journals_data),
    pattern = map(figure_top_journals_data),
    format = "file"
  ),

  # Plot top Countries -----------------------------------------------------
  # I have to think about this as it is not working at the moment
  # tar_target(
  #   figure_top_country_data,
  #   plot_top_country_data(bibliography),
  #   pattern = map(bibliography),
  #   format = "file"
  # ),
  # tar_target(
  #   figure_top_country,
  #   plot_top_country(figure_top_country_data),
  #   pattern = map(figure_top_country_data),
  #   format = "file"
  # ),
  # tar_target(
  #   figure_top_country_map,
  #   plot_top_country_map(figure_top_country_data),
  #   pattern = map(figure_top_country_data),
  #   format = "file"
  # ),
  #

  # Plot Types -------------------------------------------------------------

  tar_target(
    figure_types_data,
    plot_types_data(bibliography),
    pattern = map(bibliography),
    format = "file"
  ),
  tar_target(
    figure_types,
    plot_types(figure_types_data),
    pattern = map(figure_types_data),
    format = "file"
  ),

  # Combined Results per Branch------------------------------------------------

  tar_target(
    group_output,
    list(
      name = paste0("IPBES_", group$name, "_", group$id),
      zotero_group = zotero_group,
      bibliography = bibliography,
      metrics = metrics,
      pub_year_data = figure_pub_year_data,
      pub_year = figure_pub_year,
      oa_status_data = figure_oa_status_data,
      oa_status = figure_oa_status,
      top_journals_data = figure_top_journals_data,
      top_journals = figure_top_journals,
      types_data = figure_types_data,
      types = figure_types
    ),
    pattern = map(
      group,
      zotero_group,
      bibliography,
      metrics,
      figure_pub_year_data,
      figure_pub_year,
      figure_oa_status_data,
      figure_oa_status,
      figure_top_journals_data,
      figure_top_journals,
      figure_types_data,
      figure_types
    ),
    iteration = "list"
  ),

  # Create Bibliograpy Report ----------------------------------------------

  tar_target(
    group_report,
    {
      out_dir <- file.path("output", "report", "bibliography")
      out_file <- paste0(group_output$name, ".html")

      quarto::quarto_render(
        input = "bibliography_Report.qmd",
        execute_params = list(output_files = group_output),
        output_file = out_file
      )

      dir.create(
        dirname(out_dir),
        recursive = TRUE,
        showWarnings = FALSE
      )
      to_file <- file.path(out_dir, basename(out_file))

      file.rename(
        out_file,
        to_file
      ) # move out_file
      to_file
    },
    pattern = map(group_output),
    format = "file"
  ),

  tar_target(
    group_reports,
    data.frame(
      full_name = paste0("IPBES_", group$name, "_", group$id),
      name = group$name,
      id = group$id,
      file = group_report
    ),
    pattern = map(
      group,
      group_report
    ),
    iteration = "vector"
  ),

  # Create index page report -----------------------------------------------

  tar_target(
    index,
    {
      out_dir <- file.path("output", "report")
      out_file <- "index.html"

      quarto::quarto_render(
        input = "index.qmd",
        execute_params = list(report_files = group_reports),
        output_file = out_file
      )

      dir.create(
        dirname(out_dir),
        recursive = TRUE,
        showWarnings = FALSE
      )

      to_file <- file.path(out_dir, basename(out_file))

      file.rename(
        out_file,
        to_file
      ) # move out_file
      to_file
    },
    format = "file"
  ),
  ###
  NULL
)
