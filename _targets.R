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
        "pbmcapply",
        "pbapply",
        "IPBES.R"
    )
)

# list(
#     tar_target(file, "IPBES ILK.csv)
#     tar_target(data, )
# )