#' Read the Zotero CSV files of a group
#'
#' Reads all CSV files of a downloaded Zotero group with
#' `arrow::read_csv_arrow()` and combines them into one data frame, with all
#' columns as strings. Arrow would otherwise guess the column types per file,
#' which fails for files with only a header row, and when the guessed types
#' differ between files. Empty fields are empty strings.
#'
#' All files of a group are expected to have the same columns, as in the CSV
#' export of Zotero.
#'
#' @param zotero_group Directory with the Zotero CSV files, as returned by
#'   [get_zotero_group()].
#'
#' @return A tibble with one row per Zotero item.
read_zotero <- function(
  zotero_group
) {
  files <- list.files(zotero_group, pattern = "\\.csv$", full.names = TRUE)

  cols <- names(arrow::read_csv_arrow(files[1], as_data_frame = FALSE))

  zotero <- lapply(
    files,
    arrow::read_csv_arrow,
    col_names = cols,
    col_types = arrow::schema(
      stats::setNames(rep(list(arrow::string()), length(cols)), cols)
    ),
    skip = 1,
    na = character()
  ) |>
    dplyr::bind_rows()

  return(zotero)
}
