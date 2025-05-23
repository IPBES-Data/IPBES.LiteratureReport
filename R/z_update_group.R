#' Update group
#'
#' This function updates the group by downloading the group data from Zotero.
#'
#' The \code{update_group} function is used to update the group by downloading the
#' group data from Zotero. It takes two arguments: \code{group} and \code{overwrite}.
#'
#' The \code{group} argument is a named character vector that specifies the group names
#' and their corresponding group IDs. By default, it uses the \code{group()} function
#' to retrieve the group names and IDs.
#'
#' The \code{overwrite} argument is a logical value that indicates whether to
#' overwrite existing files. If set to \code{FALSE}, the function will skip
#' downloading the group data if the corresponding file already exists. If set to
#' \code{TRUE}, the function will overwrite existing files.
#'
#' The function uses the \code{zotero_get_group} function from the \code{IPBES.R}
#' package to download the group data. It iterates over each group in the \code{group}
#' vector, downloads the group data, and saves it as a CSV file in the "input"
#' directory.
#' @param group A named character vector specifying the group names and their
#' corresponding group IDs.
#' @param overwrite Logical value indicating whether to overwrite existing files.
#' Default is \code{FALSE}.
#'
#' @importFrom IPBES.R zotero_get_group
#'
#' @examples
#' # Update group using default settings
#' \dontrun{
#' update_group()
#'
#' # Update group and overwrite existing files
#' update_group(overwrite = TRUE)
#' }
#'
#' @md
#'
#' @export
update_group <- function(
  group
) {
  ##
  dir <- normalizePath(file.path("output", "zotero_groups"), mustWork = FALSE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  ##

  message(">>>>>>>\nDownloading group ", group$name, " ...")
  file <- file.path(
    dir,
    paste0("IPBES_", group$name, "_", group$id)
  )

  zotero_get_group(
    group_id = group$id,
    file = file,
    output_format = "csv"
  )

  message("Downloaded group ", group$name, "!\n<<<<<<<\n")

  file <- paste0(file, ".csv")

  return(file)
}
