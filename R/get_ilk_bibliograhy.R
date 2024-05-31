get_ilk_bibliography <- function(params) {
    ilk_bibliography <- bibliography_metrics(
        bibliography_zotero = params$ilk_bibliography_zotero,
        bibliography_name = params$ilk_bibliography_name,
        bibliography_url = params$ilk_bibliography_url,
        mc.cores = params$mc.cores
    )
    return(ilk_bibliography)
}
