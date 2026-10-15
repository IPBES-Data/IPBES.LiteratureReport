#' Empty fields found in OpenAlex
#'
#' Journal articles with an empty journal, volume, issue or pages field whose
#' DOI was found in OpenAlex with these details: the values in OpenAlex are
#' proposed. The journal is only taken if the publication is in a journal in
#' OpenAlex (not e.g. a repository). Page ranges which end before they start
#' (e.g. `1260-2`, shortened or wrong) are not proposed. Items whose DOI
#' points to a different publication are left out.
#'
#' @param zotero Zotero items as read from the CSV export (data frame).
#' @param openalex OpenAlex works (arrow dataset).
#'
#' @return A list with
#' - `items`: tibble with `key`, `title`, `doi`, `field` (Zotero field:
#'   `publicationTitle`, `volume`, `issue` or `pages`) and `value` (in
#'   OpenAlex), one row per empty field, sorted by publication
#' - `count`: number of items with at least one field to fill
#' - `count_fields`: number of fields to fill
met_check_fill <- function(
  zotero,
  openalex
) {
  metrics <- list()
  metrics$items <- tibble::tibble(
    key = character(),
    title = character(),
    doi = character(),
    field = character(),
    value = character()
  )

  if (all(c("biblio", "primary_location") %in% names(openalex))) {
    works <- openalex |>
      dplyr::select(
        doi,
        biblio,
        primary_location
      ) |>
      dplyr::collect()
    source <- works$primary_location$source
    first <- works$biblio$first_page
    last <- works$biblio$last_page
    # ranges ending before they start (e.g. "1260-2", shortened or wrong) are
    # not proposed
    odd <- suppressWarnings(as.numeric(last) < as.numeric(first)) %in% TRUE
    first[odd] <- NA
    works <- tibble::tibble(
      doi = works$doi,
      publicationTitle = ifelse(source$type %in% "journal", source$display_name, NA),
      volume = works$biblio$volume,
      issue = works$biblio$issue,
      pages = ifelse(!is.na(last) & last != first, paste0(first, "-", last), first)
    )

    items <- oa_join(zotero, openalex, works)
    items <- items[items$Item.Type == "journalArticle", ]

    fields <- c(
      publicationTitle = "Publication.Title",
      volume = "Volume",
      issue = "Issue",
      pages = "Pages"
    )
    metrics$items <- dplyr::bind_rows(
      metrics$items,
      lapply(names(fields), function(f) {
        x <- items[items[[fields[[f]]]] == "" & !is.na(items[[f]]) & items[[f]] != "", ]
        tibble::tibble(
          key = x$Key,
          title = x$Title,
          doi = x$doi,
          field = rep(f, nrow(x)),
          value = as.character(x[[f]])
        )
      })
    ) |>
      # all fields of a publication together, in the order of `fields`
      dplyr::arrange(
        tolower(title),
        key,
        match(field, names(fields))
      )
  }

  metrics$count <- length(unique(metrics$items$key))
  metrics$count_fields <- nrow(metrics$items)

  return(metrics)
}
