#' Update Groups
#'
#' This function updates the groups by downloading the group data from Zotero.
#'
#' The \code{update_groups} function is used to update the groups by downloading the
#' group data from Zotero. It takes two arguments: \code{x} and \code{overwrite}.
#'
#' The \code{x} argument is a named character vector that specifies the group names
#' and their corresponding group IDs. By default, it uses the \code{groups()} function
#' to retrieve the group names and IDs.
#'
#' The \code{overwrite} argument is a logical value that indicates whether to
#' overwrite existing files. If set to \code{FALSE}, the function will skip
#' downloading the group data if the corresponding file already exists. If set to
#' \code{TRUE}, the function will overwrite existing files.
#'
#' The function uses the \code{zotero_get_group} function from the \code{IPBES.R}
#' package to download the group data. It iterates over each group in the \code{x}
#' vector, downloads the group data, and saves it as a CSV file in the "input"
#' directory.
#' @param x A named character vector specifying the group names and their
#' corresponding group IDs.
#' @param overwrite Logical value indicating whether to overwrite existing files. 
#' Default is \code{FALSE}.
#'
#' @importFrom IPBES.R zotero_get_group
#'
#' @examples
#' # Update groups using default settings
#' \dontrun{
#' update_groups()
#' 
#' # Update groups and overwrite existing files
#' update_groups(overwrite = TRUE)
#' }
#' 
#' @md
#' 
#' @export
update_groups <- function(
    x = groups(),
    overwrite = FALSE) {
    ##
    dir.create("input", showWarnings = FALSE)
    ##
    for (i in names(x)) {
        message(">>>>>>>\nDownloading group ", i, " ...")

        file <- file.path("input", paste0("IPBES ", i, ".csv"))

        if (file.exists(file) & !overwrite) {
            message("File already exists! Skipping download.\n<<<<<<<\n")
            next
        } else {
            unlink(file, force = TRUE)
        }

        IPBES.R::zotero_get_group(
            group_id = x[i],
            file = file
        )

        message("Downloaded group ", i, "!\n<<<<<<<\n")
    }
}