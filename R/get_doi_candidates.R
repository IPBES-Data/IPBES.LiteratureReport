#' Search OpenAlex for the works of items without a DOI
#'
#' Searches OpenAlex by title for each item without a DOI whose type usually
#' has one (see `types`), and keeps the first five works found. The results
#' are kept in `output/doi_candidates/<group>.rds`, and an item is only
#' searched again when it is new or its title changed. Items whose search
#' failed (e.g. no network) are searched again in the next run.
#'
#' Scoring the candidates is done by [met_id_candidates()].
#'
#' @param zotero_group Directory with the Zotero CSV files, as returned by
#'   [get_zotero_group()].
#' @param types Zotero item types to search.
#'
#' @return Path to the RDS file: a tibble with one row per item and work
#'   found, with the item `key`, the `query` (title searched), and the work's
#'   `id`, `doi`, `title`, `year`, `first_author`, `type` and `journal`
#'   (`id` is `NA` for items for which nothing was found).
get_doi_candidates <- function(
  zotero_group,
  types = c(
    "journalArticle",
    "bookSection",
    "book",
    "report",
    "conferencePaper",
    "thesis",
    "preprint"
  )
) {
  zotero <- read_zotero(zotero_group)
  items <- zotero[
    zotero$DOI == "" & zotero$`Item Type` %in% types & zotero$Title != "",
  ]
  query <- trimws(gsub("[^[:alnum:]]+", " ", items$Title))

  file <- file.path(
    "output",
    "doi_candidates",
    paste0(basename(zotero_group), ".rds")
  )
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

  # earlier results, for items which are still there with the same title
  cached <- if (file.exists(file)) readRDS(file) else NULL
  if (!is.null(cached)) {
    cached <- cached[paste(cached$key, cached$query) %in% paste(items$Key, query), ]
  }
  todo <- !items$Key %in% cached$key

  # parallel, at most 10 requests per second (the OpenAlex limit)
  responses <- httr2::req_perform_parallel(
    lapply(query[todo], openalex_search),
    on_error = "continue"
  )
  found <- unname(Map(openalex_found, items$Key[todo], query[todo], responses))

  result <- dplyr::bind_rows(cached, found)
  saveRDS(result, file)

  return(file)
}

#' Request to search OpenAlex works by title
#'
#' @param query Title, without punctuation (commas separate OpenAlex
#'   filters).
#'
#' @return An httr2 request for the first five works found.
openalex_search <- function(
  query
) {
  httr2::request("https://api.openalex.org/works") |>
    httr2::req_url_query(
      filter = paste0("title.search:", query),
      select = "id,doi,title,publication_year,authorships,type,primary_location",
      `per-page` = 5,
      api_key = openalexPro::pro_api_key()
    ) |>
    httr2::req_throttle(capacity = 10, fill_time_s = 1) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_timeout(30)
}

#' Works found by an OpenAlex search
#'
#' @param key Zotero item key.
#' @param query Title searched.
#' @param resp Response of [openalex_search()], or an error.
#'
#' @return Tibble with the works found (one row with `id = NA` if none), or
#'   `NULL` if the search failed.
openalex_found <- function(
  key,
  query,
  resp
) {
  if (!inherits(resp, "httr2_response")) {
    return(NULL)
  }
  res <- httr2::resp_body_json(resp)

  none <- tibble::tibble(
    key = key,
    query = query,
    id = NA_character_,
    doi = NA_character_,
    title = NA_character_,
    year = NA_integer_,
    first_author = NA_character_,
    type = NA_character_,
    journal = NA_character_
  )
  if (!length(res$results)) {
    return(none)
  }

  dplyr::bind_rows(lapply(res$results, function(w) {
    tibble::tibble(
      key = key,
      query = query,
      id = w$id,
      doi = sub("^https://doi.org/", "", w$doi %||% NA_character_),
      title = w$title %||% NA_character_,
      year = as.integer(w$publication_year %||% NA),
      first_author = if (length(w$authorships)) {
        w$authorships[[1]]$author$display_name %||% NA_character_
      } else {
        NA_character_
      },
      type = w$type %||% NA_character_,
      journal = w$primary_location$source$display_name %||% NA_character_
    )
  }))
}
