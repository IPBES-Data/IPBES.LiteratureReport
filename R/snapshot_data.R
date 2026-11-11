#' Zip the data for the paper snapshot
#'
#' Zips `zotero_groups/`, `zotero_works/` and `doi_check/` from inside
#' `output/` (no `output/` prefix in the zip) into `snapshot_data.zip`, the
#' release asset which `update_snapshot(source = "github")` of the paper repo
#' downloads. Only the groups listed in `config` are included; the other
#' folders of `output/` are left out. The data must come from a `tar_make()`
#' run at the commit of the release it is attached to.
#'
#' @param zipfile Path of the zip file.
#' @param output Directory with the pipeline output.
#' @param config The pipeline configuration (`assessments`).
#'
#' @return Path to the zip file.
zip_snapshot_data <- function(
  zipfile = "snapshot_data.zip",
  output = "output",
  config = file.path("input", "config.yaml")
) {
  dirs <- c("zotero_groups", "zotero_works", "doi_check")
  missing <- dirs[!dir.exists(file.path(output, dirs))]
  if (length(missing) > 0) {
    stop("Not in ", output, ": ", paste(missing, collapse = ", "))
  }
  # only the groups in the config, not left-overs of removed groups
  groups <- vapply(
    yaml::read_yaml(config)$assessments,
    function(a) paste0("IPBES_", a$name, "_", a$id),
    ""
  )
  files <- c(
    file.path(rep(dirs[1:2], each = length(groups)), groups),
    file.path(dirs[3], paste0(groups, ".rds"))
  )
  files <- files[file.exists(file.path(output, files))]
  # absolute, as zip runs inside output/ (normalizePath() of a file which
  # does not exist yet stays relative on Linux)
  zipfile <- file.path(normalizePath(dirname(zipfile)), basename(zipfile))
  unlink(zipfile)
  old <- setwd(output)
  on.exit(setwd(old))
  if (utils::zip(zipfile, files, flags = "-r9Xq") != 0 || !file.exists(zipfile)) {
    stop("zip failed: ", zipfile)
  }
  zipfile
}

#' Upload the snapshot data to a release
#'
#' Attaches `zipfile` as asset `snapshot_data.zip` to the GitHub release with
#' tag `tag`, replacing an asset of that name. Authenticates with
#' `GITHUB_TOKEN` if set (GitHub Actions, see
#' `.github/workflows/snapshot-data.yml`), otherwise with the token git uses
#' for github.com (`git credential fill`).
#'
#' @param tag Tag of the release, e.g. `"v0.6.0"`.
#' @param zipfile The zip file made by [zip_snapshot_data()].
#' @param repo Repository, `owner/name`.
#'
#' @return URL to download the asset.
upload_snapshot_data <- function(
  tag,
  zipfile = "snapshot_data.zip",
  repo = "IPBES-Data/IPBES.LiteratureReport"
) {
  name <- "snapshot_data.zip"
  token <- Sys.getenv("GITHUB_TOKEN")
  if (token == "") {
    cred <- system2(
      "git",
      c("credential", "fill"),
      input = c("protocol=https", "host=github.com", ""),
      stdout = TRUE
    )
    token <- sub("^password=", "", grep("^password=", cred, value = TRUE))
  }
  if (length(token) != 1 || token == "") {
    stop("No token for github.com from git credential fill")
  }
  gh <- function(url) {
    httr2::request(url) |>
      httr2::req_auth_bearer_token(token) |>
      httr2::req_headers(Accept = "application/vnd.github+json")
  }
  api <- paste0("https://api.github.com/repos/", repo)
  release <- gh(paste0(api, "/releases/tags/", tag)) |>
    httr2::req_perform() |>
    httr2::resp_body_json()
  for (asset in release$assets) {
    if (asset$name == name) {
      gh(paste0(api, "/releases/assets/", asset$id)) |>
        httr2::req_method("DELETE") |>
        httr2::req_perform()
    }
  }
  paste0(
    "https://uploads.github.com/repos/", repo,
    "/releases/", release$id, "/assets"
  ) |>
    gh() |>
    httr2::req_url_query(name = name) |>
    httr2::req_body_file(zipfile, type = "application/zip") |>
    httr2::req_timeout(3600) |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    _$browser_download_url
}
