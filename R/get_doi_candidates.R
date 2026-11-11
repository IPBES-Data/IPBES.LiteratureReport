#' Search OpenAlex and Crossref for the works of items without a DOI
#'
#' For each item without a DOI whose type usually has one (see `types`):
#' - OpenAlex is searched by title, keeping the first five works found;
#' - a PubMed ID (line `PMID: …` in Extra) is looked up in OpenAlex;
#' - the ISBNs are looked up in Crossref (with the rOpenSci package
#'   rcrossref), searching the works with these ISBNs (a book and its
#'   chapters) for the title, keeping the first five.
#'
#' The results are kept in `output/doi_candidates/<group>.rds`, and an item
#' is only searched again when it is new or its title or identifiers
#' changed. Searches which failed (e.g. no network) are done again in the
#' next run. Crossref is asked through its faster "polite" service if the
#' environment variable `crossref_email` is set.
#'
#' Scoring the candidates is done by [met_id_candidates()].
#'
#' @param zotero_group Directory with the Zotero CSV files, as returned by
#'   [get_zotero_group()].
#' @param types Zotero item types to search.
#'
#' @return Path to the RDS file: a tibble with one row per item, search and
#'   work found, with the item `key`, the `query`, `by` (what was searched:
#'   `title`, `pmid` or `isbn`), and the work's `id` (OpenAlex; `NA` for
#'   Crossref), `doi`, `title`, `year`, `first_author`, `type` and `journal`
#'   (`id` and `doi` are `NA` for searches which found nothing).
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
  title <- trimws(gsub("[^[:alnum:]]+", " ", items$Title))

  # what to search, one row per item and search
  pmid <- regmatches(items$Extra, regexpr("(?mi)^PMID:\\s*\\d+", items$Extra, perl = TRUE))
  has_pmid <- grepl("(?mi)^PMID:\\s*\\d+", items$Extra, perl = TRUE)
  isbn <- lapply(items$ISBN, isbn13)
  has_isbn <- lengths(isbn) > 0
  searches <- dplyr::bind_rows(
    tibble::tibble(key = items$Key, by = "title", query = title, value = title),
    tibble::tibble(
      key = items$Key[has_pmid],
      by = "pmid",
      query = paste0("pmid:", gsub("\\D", "", pmid)),
      value = gsub("\\D", "", pmid)
    ),
    tibble::tibble(
      key = items$Key[has_isbn],
      by = "isbn",
      query = paste0("isbn:", vapply(isbn[has_isbn], paste, "", collapse = ","), " ", title[has_isbn]),
      value = title[has_isbn],
      isbn = isbn[has_isbn]
    )
  )

  file <- file.path(
    "output",
    "doi_candidates",
    paste0(basename(zotero_group), ".rds")
  )
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

  # earlier results, for searches which are still to be done
  cached <- if (file.exists(file)) readRDS(file) else NULL
  if (!is.null(cached)) {
    if (!"by" %in% names(cached)) cached$by <- "title" # made before the lookups
    cached <- cached[paste(cached$key, cached$query) %in% paste(searches$key, searches$query), ]
  }
  todo <- searches[!paste(searches$key, searches$query) %in% paste(cached$key, cached$query), ]

  # OpenAlex, parallel, at most 10 requests per second (the OpenAlex limit)
  oa <- todo[todo$by != "isbn", ]
  responses <- httr2::req_perform_parallel(
    Map(openalex_search, oa$value, ifelse(oa$by == "pmid", "ids.pmid", "title.search")),
    on_error = "continue"
  )
  found <- unname(Map(openalex_found, oa$key, oa$query, responses))
  found <- Map(function(f, by) if (!is.null(f)) dplyr::mutate(f, by = by), found, oa$by)

  # Crossref, one after the other
  cr <- todo[todo$by == "isbn", ]
  found_cr <- unname(Map(crossref_isbn, cr$key, cr$query, cr$isbn, cr$value))

  result <- dplyr::bind_rows(cached, found, found_cr)
  saveRDS(result, file)

  return(file)
}

#' Request to search OpenAlex works by title (or another filter)
#'
#' @param query Title, without punctuation (commas separate OpenAlex
#'   filters), or the value of `filter`.
#' @param filter OpenAlex filter, e.g. `ids.pmid` for a PubMed ID.
#'
#' @return An httr2 request for the first five works found.
openalex_search <- function(
  query,
  filter = "title.search"
) {
  httr2::request("https://api.openalex.org/works") |>
    httr2::req_url_query(
      filter = paste0(filter, ":", query),
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

#' Works found in Crossref by ISBN and title
#'
#' Searches the works with one of the ISBNs (a book and its chapters) for the
#' title, with [rcrossref::cr_works_()].
#'
#' @param key Zotero item key.
#' @param query Search, as kept in the cache.
#' @param isbn ISBN-13s, without hyphens.
#' @param title Title, without punctuation.
#'
#' @return Tibble as [openalex_found()] (`id` is `NA`, `by` is `isbn`), or
#'   `NULL` if the search failed.
crossref_isbn <- function(
  key,
  query,
  isbn,
  title
) {
  res <- tryCatch(
    rcrossref::cr_works_(
      filter = stats::setNames(isbn, rep("isbn", length(isbn))),
      flq = c(query.bibliographic = title),
      limit = 5,
      select = c("DOI", "title", "type", "issued", "author", "container-title"),
      parse = TRUE
    ),
    error = function(e) NULL
  )
  if (is.null(res$message)) {
    return(NULL)
  }
  first <- function(x) if (length(x)) unlist(x)[[1]] else NA_character_
  works <- lapply(res$message$items, function(w) {
    a <- if (length(w$author)) w$author[[1]] else NULL
    tibble::tibble(
      key = key,
      query = query,
      by = "isbn",
      id = NA_character_,
      doi = w$DOI %||% NA_character_,
      title = first(w$title),
      year = as.integer(first(w$issued$`date-parts`)),
      first_author = if (is.null(a)) NA_character_ else trimws(paste(a$given %||% "", a$family %||% a$name %||% "")),
      type = w$type %||% NA_character_,
      journal = first(w$`container-title`)
    )
  })
  if (!length(works)) {
    return(tibble::tibble(
      key = key, query = query, by = "isbn", id = NA_character_,
      doi = NA_character_, title = NA_character_, year = NA_integer_,
      first_author = NA_character_, type = NA_character_, journal = NA_character_
    ))
  }
  dplyr::bind_rows(works)
}

#' ISBNs as ISBN-13
#'
#' Crossref finds books by ISBN-13 only.
#'
#' @param x ISBN field: one or more ISBNs, with or without hyphens.
#'
#' @return Unique ISBN-13s, without hyphens (ISBN-10s converted).
isbn13 <- function(
  x
) {
  v <- toupper(gsub("[^0-9Xx ,;]", "", x))
  v <- unlist(strsplit(v, "[ ,;]+"))
  v <- v[grepl("^([0-9]{9}[0-9X]|97[89][0-9]{10})$", v)]
  ten <- nchar(v) == 10
  v[ten] <- vapply(v[ten], function(i) {
    d <- as.integer(strsplit(paste0("978", substr(i, 1, 9)), "")[[1]])
    paste0("978", substr(i, 1, 9), (10 - sum(d * rep(c(1, 3), 6)) %% 10) %% 10)
  }, "")
  unique(v)
}
