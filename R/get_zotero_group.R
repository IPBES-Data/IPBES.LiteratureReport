#' Download a Zotero group
#'
#' Downloads all items of a Zotero group with `zotFunc::get_group()` as CSV
#' files into `output/zotero_groups/IPBES_<name>_<id>/`. An existing directory
#' is deleted first.
#'
#' The Zotero API key, needed for private groups, is read with
#' `keyring::key_get("API_zotero")`. Without a key, only public groups can be
#' downloaded.
#'
#' @param group List with the group `name` and the Zotero group `id`, i.e.
#'   one entry of `assessments` in `input/config.yaml`.
#'
#' @return Path to the directory with the CSV files.
get_zotero_group <- function(
  group
) {
  ##
  dir <- file.path("output", "zotero_groups")

  path <- file.path(
    dir,
    paste0("IPBES_", group$name, "_", group$id)
  )

  unlink(path, recursive = TRUE)

  dir.create(
    dir,
    recursive = TRUE,
    showWarnings = FALSE
  )

  ##

  message(">>>>>>>\nDownloading group ", group$name, " ...")

  api_key <- NULL
  try(
    api_key <- keyring::key_get("API_zotero"),
    silent = TRUE
  )

  get_group(
    group_id = group$id,
    path = path,
    output_format = "csv",
    api_key = api_key
  )

  message("Downloaded group ", group$name, "!\n<<<<<<<\n")

  path <- normalizePath(path)
  message(path)
  message(file.exists(path))
  return(path)
}
