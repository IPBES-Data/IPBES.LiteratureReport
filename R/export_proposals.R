#' Publish the proposed fixes of a group
#'
#' Runs all fixes ([fix_table()]) on the metrics of a group and writes the
#' proposed changes as JSON to `output/report/fixes/<group>.json`, next to
#' the reports. The file is checked against `input/proposals.schema.json`. It
#' is read by the Zotero plugin which shows the fixes; the changes are applied
#' only through Zotero Safe Edit, after approval in Zotero.
#'
#' @param metrics RDS file with the metrics of the group, from [get_metrics()].
#' @param zotero_works Directory with the OpenAlex works of the group, for the
#'   OpenAlex links of the DOIs.
#' @param group The group (`name`, `id`) from `input/config.yaml`.
#' @param schema JSON schema of the file.
#' @param site URL of the published reports.
#' @param dir Directory to write to.
#'
#' @return Path to the JSON file.
export_proposals <- function(
  metrics,
  zotero_works,
  group,
  schema = file.path("input", "proposals.schema.json"),
  site = "https://ipbes-data.github.io/IPBES.LiteratureReport/",
  dir = file.path("output", "report", "fixes")
) {
  m <- readRDS(metrics)
  group_id <- as.numeric(group$id)
  name <- tools::file_path_sans_ext(basename(metrics))

  # OpenAlex works of the DOIs in the group, for the links
  works <- tryCatch(
    arrow::open_dataset(zotero_works) |>
      dplyr::select(doi, id) |>
      dplyr::collect(),
    error = function(e) NULL
  )
  oa <- if (is.null(works)) {
    character()
  } else {
    stats::setNames(works$id, tolower(sub("^https://doi.org/", "", works$doi)))
  }

  # plain vectors (e.g. no 1-d arrays from tapply()), for the JSON
  column <- function(x, col, value = NA) {
    if (col %in% names(x)) as.vector(x[[col]]) else rep(value, nrow(x))
  }
  fixes <- fix_table()
  out <- lapply(seq_len(nrow(fixes)), function(i) {
    x <- fixes$fun[[i]](m, group_id)
    # the DOI of the item: in the DOI field the one it gets (or keeps)
    doi <- column(x, "doi", NA_character_)
    doi <- ifelse(x$field == "DOI", ifelse(x$new != "", x$new, x$old), doi)
    doi[!is.na(doi) & doi == ""] <- NA
    openalex <- dplyr::coalesce(column(x, "openalex", NA_character_), unname(oa[tolower(doi)]))
    list(
      id = fixes$id[i],
      problem = fixes$problem[i],
      value = fixes$value[i],
      field = fixes$field[i],
      check = fixes$check[i],
      bulk = fixes$bulk[i],
      changes = tibble::tibble(
        item_key = x$item_key,
        title = x$title,
        field = x$field,
        old = dplyr::coalesce(x$old, ""),
        new = dplyr::coalesce(x$new, ""),
        reason = x$reason,
        proposed = x$proposed,
        note = x$note,
        doi = doi,
        openalex = openalex,
        choice = column(x, "choice", NA_character_),
        preselect = column(x, "preselect", NA),
        append = column(x, "append", NA_character_)
      )
    )
  })

  checks <- rep_checks(m)
  json <- jsonlite::toJSON(
    list(
      format = "zotero-fix-proposals",
      version = 1L,
      created = format(file.mtime(metrics), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      group_id = group_id,
      name = group$name,
      report = paste0(site, name, ".html"),
      checks = dplyr::transmute(
        checks,
        id,
        check,
        count = as.integer(count),
        severity,
        status
      ),
      fixes = out
    ),
    auto_unbox = TRUE,
    dataframe = "rows",
    na = "null",
    null = "null",
    digits = NA
  )
  jsonvalidate::json_validate(json, schema, engine = "ajv", error = TRUE)

  file <- file.path(dir, paste0(name, ".json"))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  writeLines(json, file, useBytes = TRUE)
  return(file)
}

#' Index of the published proposals
#'
#' Writes `output/report/fixes/index.json` with the groups and their
#' proposals files, and publishes the schema of these files next to them.
#'
#' @param proposals Paths of the proposals files, from [export_proposals()].
#' @param groups The groups (`name`, `id`) from `input/config.yaml`.
#' @param schema JSON schema of the proposals files.
#'
#' @return Paths of the index and the schema.
export_proposals_index <- function(
  proposals,
  groups,
  schema = file.path("input", "proposals.schema.json")
) {
  dir <- file.path("output", "report", "fixes")
  index <- file.path(dir, "index.json")
  jsonlite::write_json(
    list(
      format = "zotero-fix-proposals-index",
      version = 1L,
      created = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      groups = lapply(seq_along(groups), function(i) {
        list(
          group_id = as.numeric(groups[[i]]$id),
          name = groups[[i]]$name,
          file = basename(proposals[[i]])
        )
      })
    ),
    index,
    auto_unbox = TRUE,
    pretty = TRUE
  )
  file.copy(schema, file.path(dir, "schema.json"), overwrite = TRUE)
  return(c(index, file.path(dir, "schema.json")))
}
