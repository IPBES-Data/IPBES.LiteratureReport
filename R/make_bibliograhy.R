make_bibliography <- function(bibliography_zotero, mc.cores = 3) {
    bibliography <- bibliography_metrics(
        bibliography_zotero = bibliography_zotero,
        mc.cores = mc.cores
    )
    return(bibliography)
}