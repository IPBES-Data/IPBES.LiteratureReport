# _targets.R

library(targets)

list.files(
    "R",
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
    tar_target(ilk_file, "input/IPBES ILK.csv", format = "file"),
    tar_target(ilk_bibliography.rds, make_bibliography(ilk_file, mc.cores = 5)),
    tar_target(ilk_metrics.rds, dois_measures(ilk_bibliography.rds)),

    # IAS
    tar_target(ias_file, "input/IPBES IAS.csv", format = "file"),
    tar_target(ias_bibliography.rds, make_bibliography(ias_file, mc.cores = 5)),
    tar_target(ias_metrics.rds, dois_measures(ias_bibliography.rds))
 )
