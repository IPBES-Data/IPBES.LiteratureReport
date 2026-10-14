#' Item types and grey literature
#'
#' Number of items per item type (Zotero) or work type (OpenAlex), and the
#' share of grey literature, i.e. reports, theses, dissertations, web pages,
#' documents, presentations, manuscripts, blog posts and preprints.
#'
#' @param ... One or two data sources: the Zotero items (data frame) and / or
#'   the OpenAlex works (arrow dataset). With two, the measure is computed for
#'   each source and returned as a list named after the arguments.
#'
#' @return A list with
#' - `by_type`: tibble with `type`, `count`, `grey` (logical) and `pc`
#' - `pc_grey`: percentage of grey literature
met_prof_types <- function(
  ...
) {
  if (...length() == 2) {
    # two sources: run once per source, keeps names (zotero / openalex)
    return(per_source(met_prof_types, ...))
  }
  if (...length() != 1) {
    stop("met_prof_types() takes one or two data arguments, got ", ...length())
  }

  bib <- as_bib(..1)

  # Zotero and OpenAlex type names counted as grey literature
  grey <- c(
    "report",
    "thesis",
    "dissertation",
    "webpage",
    "document",
    "presentation",
    "manuscript",
    "blogPost",
    "preprint"
  )

  metrics <- list()

  metrics$by_type <- bib |>
    dplyr::count(
      type,
      name = "count",
      sort = TRUE
    ) |>
    dplyr::mutate(
      grey = type %in% grey,
      pc = 100 * count / sum(count)
    )

  metrics$pc_grey <- 100 * mean(bib$type %in% grey)

  return(metrics)
}
