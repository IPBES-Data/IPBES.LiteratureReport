met_doi <- function(
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

  data <- args[[1]]

  metrics <- list()

  if (all(c("Key", "DOI") %in% names(data))) {
    metrics$doi_raw <- data$DOI
    names(
      metrics$doi_raw
    ) <- data$Key
  } else {
    metrics$doi_raw <- data |>
      dplyr::select(doi) |>
      dplyr::collect() |>
      dplyr::pull(doi)
    names(
      metrics$doi_raw
    ) <- data |>
      dplyr::select(id) |>
      dplyr::collect() |>
      dplyr::pull(id)
  }

  metrics$doi <- openalexPro::extract_doi(
    metrics$doi_raw,
    non_doi_value = as.character(NA),
    what = "doi"
  )

  metrics$doi <-
    metrics$doi[
      !is.na(
        metrics$doi
      )
    ]

  metrics$count_doi <- length(metrics$doi)

  metrics$pc <- 100 * metrics$count_doi / length(metrics$doi_raw)

  metrics$no_duplicated <- metrics$doi |>
    table() |>
    as.data.frame() |>
    setNames(c("occurrance", "count"))

  #
  #metrics$valid <-
  #metrics$unique[IPBES.R::doi_valid(
  #
  #metrics$unique
  # )]
  #
  #metrics$not_valid <-
  #metrics$unique[
  #   !IPBES.R::doi_valid(
  #metrics$unique)
  # ]

  return(
    metrics
  )
}
