update_groups <- function(
    x = groups(),
    overwrite = FALSE) {
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