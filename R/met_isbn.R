met_isbn <- function(
  data,
  ...
) {
  args <- list(...)

  if (length(args) == 2) {
    # two sources: run once per source, keeps names (zotero / openalex)
    vars <- vapply(as.list(substitute(list(...)))[-1], deparse1, "")
    nms <- names(args)
    names(args) <- if (is.null(nms)) vars else ifelse(nms == "", vars, nms)
    return(lapply(args, met_doi))
  }
  if (length(args) != 1) {
    stop("met_doi() takes one or two data arguments, got ", length(args))
  }

  metrics <- list()

  if (c("Key", "DOI") %in% names(data)) {
    metrics$isbn_raw <- data$DOI
    names(
      metrics$isbn_raw
    ) <- data$Key
  } else {
    metrics$isbn_raw <- data |>
      dplyr::select(doi) |>
      dplyr::collect() |>
      dplyr::pull(doi)
    names(
      metrics$isbn_raw
    ) <- data |>
      dplyr::select(id) |>
      dplyr::collect() |>
      dplyr::pull(id)
  }

  metrics <- list(
    id = bibliography$bibliography$ISBN
  )

  names(metrics$id) <- bibliography$bibliography$Key
  metrics$id <- metrics$id[
    metrics$id != ""
  ]
  metrics$id <- metrics$id[
    !is.na(metrics$id)
  ]

  metrics$count <- sum(!is.na(metrics$id))
  metrics$pc <- 100 *
    metrics$count /
    nrow(bibliography$bibliography)

  metrics$duplicate <- metrics$id[
    metrics$id %in%
      metrics$id[duplicated(metrics$id)]
  ]
  metrics$unique <- metrics$id[
    metrics$id %in% unique(metrics$id)
  ]
  return(metrics)
}
