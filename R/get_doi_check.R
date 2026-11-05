#' Look up the DOIs not found in OpenAlex one by one
#'
#' Called by [get_works()]. The OpenAlex lookup of all DOIs returns the works
#' under the DOI OpenAlex has for them. When a publication has more than one
#' DOI (e.g. the old SICI form `10.1890/1540-9295(2007)5[475:NCNCAE]2.0.CO;2`
#' and `10.1890/070037`), the work comes back under the other DOI, and the
#' Zotero DOI seems not to be in OpenAlex; the lookup of all DOIs also misses
#' some works. Each Zotero DOI which is not among the DOIs of the works
#' returned is therefore looked up on its own in OpenAlex (`/works/doi:…`,
#' which also finds a work by its other DOIs), and, if not found there, at
#' doi.org (whether the DOI exists at all). For a DOI which does not exist,
#' the DOI without extra characters at the end (`.`, `;`, `>`, …, or a link
#' to supplementary material after `/-/`) is checked as well.
#'
#' The results are kept in `output/doi_check/<group>.rds`, and a DOI is only
#' looked up again when it was not looked up completely (e.g. no network).
#' Delete the file to look up all DOIs again.
#'
#' @param zotero_group Directory with the Zotero CSV files, as returned by
#'   [get_zotero_group()].
#' @param found_doi DOIs of the works returned by the lookup of all DOIs (as
#'   given by OpenAlex, e.g. `https://doi.org/10.…`).
#'
#' @return Path to the RDS file: a tibble with one row per DOI looked up, with
#'   `doi` (lower case), `found` (in OpenAlex), the work's `oa_id`, `oa_doi`,
#'   `oa_title` and `oa_year`, `registered` (exists at doi.org; `TRUE` for
#'   DOIs found in OpenAlex) and `suggestion` (for DOIs which do not exist:
#'   the DOI without extra characters at the end, if that exists). `found` and
#'   `registered` are `NA` when the lookup failed.
get_doi_check <- function(
  zotero_group,
  found_doi
) {
  zotero <- read_zotero(zotero_group)
  doi <- tolower(openalexPro::extract_doi(
    zotero$DOI,
    non_doi_value = NA_character_,
    what = "doi"
  ))
  oa_doi <- tolower(openalexPro::extract_doi(
    found_doi,
    non_doi_value = NA_character_,
    what = "doi"
  ))
  todo <- setdiff(unique(stats::na.omit(doi)), oa_doi)

  file <- file.path(
    "output",
    "doi_check",
    paste0(basename(zotero_group), ".rds")
  )
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

  # earlier results, for DOIs still to check which were looked up completely
  cached <- if (file.exists(file)) readRDS(file) else NULL
  if (!is.null(cached)) {
    cached <- cached[
      cached$doi %in% todo &
        !is.na(cached$found) &
        (cached$found | !is.na(cached$registered)),
    ]
  }
  todo <- setdiff(todo, cached$doi)

  x <- tibble::tibble(
    doi = todo,
    found = NA,
    oa_id = NA_character_,
    oa_doi = NA_character_,
    oa_title = NA_character_,
    oa_year = NA_integer_,
    registered = NA,
    suggestion = NA_character_
  )

  # OpenAlex, one request per DOI
  resp <- perform(lapply(x$doi, function(d) {
    httr2::request("https://api.openalex.org/works") |>
      httr2::req_url_path_append(curl::curl_escape(paste0("https://doi.org/", d))) |>
      httr2::req_url_query(
        select = "id,doi,title,publication_year",
        api_key = openalexPro::pro_api_key()
      )
  }))
  for (i in seq_along(resp)) {
    if (!resp[[i]]$status %in% c(200, 404)) next
    x$found[i] <- resp[[i]]$status == 200
    if (x$found[i]) {
      w <- resp[[i]]$body
      x$oa_id[i] <- w$id %||% NA_character_
      x$oa_doi[i] <- tolower(sub("^https://doi.org/", "", w$doi %||% NA_character_))
      x$oa_title[i] <- w$title %||% NA_character_
      x$oa_year[i] <- as.integer(w$publication_year %||% NA)
      x$registered[i] <- TRUE
    }
  }

  # doi.org, for the DOIs not in OpenAlex
  i <- which(!is.na(x$found) & !x$found)
  x$registered[i] <- doi_registered(x$doi[i])

  # without extra characters at the end
  i <- which(x$registered %in% FALSE)
  variants <- lapply(x$doi[i], function(d) {
    v <- unique(c(
      sub("[.,;:>]+$", "", d),
      sub("/-/.*$", "", d)
    ))
    v[v != d & grepl("^10\\.[0-9]+/.+", v)]
  })
  ok <- doi_registered(unlist(variants))
  ok <- split(ok, rep(seq_along(variants), lengths(variants)))
  for (j in seq_along(variants)) {
    hit <- variants[[j]][ok[[as.character(j)]] %in% TRUE]
    if (length(hit)) x$suggestion[i[j]] <- hit[1]
  }

  result <- dplyr::bind_rows(cached, x)
  saveRDS(result, file)

  return(file)
}

#' Whether DOIs exist at doi.org
#'
#' @param doi DOIs.
#'
#' @return `TRUE` / `FALSE` per DOI, `NA` where the lookup failed.
doi_registered <- function(
  doi
) {
  resp <- perform(lapply(doi, function(d) {
    httr2::request("https://doi.org/api/handles") |>
      httr2::req_url_path_append(gsub("%2F", "/", curl::curl_escape(d), fixed = TRUE))
  }))
  vapply(
    resp,
    function(r) if (r$status %in% c(200, 404)) r$status == 200 else NA,
    NA
  )
}

#' Perform requests in parallel
#'
#' At most 10 requests per second per host, with retries; HTTP errors are
#' returned, not raised.
#'
#' @param reqs List of httr2 requests.
#'
#' @return One list per request with `status` (`NA` if it failed) and the
#'   parsed JSON `body` (only for status 200).
perform <- function(
  reqs
) {
  if (!length(reqs)) {
    return(list())
  }
  reqs <- lapply(reqs, function(r) {
    r |>
      httr2::req_user_agent("IPBES Literature Report (https://github.com/IPBES-Data/IPBES.LiteratureReport)") |>
      httr2::req_error(is_error = function(resp) FALSE) |>
      httr2::req_throttle(capacity = 10, fill_time_s = 1) |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_timeout(30)
  })
  resp <- httr2::req_perform_parallel(reqs, on_error = "continue", progress = FALSE)
  lapply(resp, function(r) {
    if (!inherits(r, "httr2_response")) {
      return(list(status = NA_integer_, body = NULL))
    }
    s <- httr2::resp_status(r)
    list(
      status = s,
      body = if (s == 200) tryCatch(httr2::resp_body_json(r), error = function(e) NULL)
    )
  })
}
