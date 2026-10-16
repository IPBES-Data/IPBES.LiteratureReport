#' Build the Zotero plugins for the website
#'
#' Builds the `.xpi` of each plugin (git submodules in `plugins/`, at the
#' released version) into `output/report/plugins/<plugin>/`, with an
#' `updates.json` from which installed copies update themselves (the
#' `update_url` of the plugins points there), and `plugins.json` with name,
#' version, description and download link of each plugin for the index page.
#' The file `<plugin>.xpi` is the latest version under a fixed name, for the
#' download link.
#'
#' @param plugins Directories of the plugins, each with `addon/manifest.json`.
#' @param sources Not used. Only passed so that targets rebuilds the plugins
#'   when a file of the plugins changes.
#' @param site URL of the website.
#' @param dir Directory to write to.
#'
#' @return Paths of the files written.
build_plugins <- function(
  plugins,
  sources = NULL,
  site = "https://ipbes-data.github.io/IPBES.LiteratureReport/",
  dir = file.path("output", "report", "plugins")
) {
  files <- character()
  info <- list()
  for (p in plugins) {
    repo <- basename(p)
    manifest <- jsonlite::read_json(file.path(p, "addon", "manifest.json"))
    zotero <- manifest$applications$zotero
    out <- file.path(dir, repo)
    unlink(out, recursive = TRUE)
    dir.create(out, recursive = TRUE)
    xpi <- file.path(out, paste0(repo, "-", manifest$version, ".xpi"))
    target <- file.path(normalizePath(out), basename(xpi))
    withr::with_dir(file.path(p, "addon"), {
      utils::zip(target, list.files(".", recursive = TRUE), flags = "-qX")
    })
    latest <- file.path(out, paste0(repo, ".xpi"))
    file.copy(xpi, latest)
    hash <- as.character(openssl::sha256(file(xpi)))

    updates <- file.path(out, "updates.json")
    jsonlite::write_json(
      list(addons = stats::setNames(
        list(list(updates = list(list(
          version = manifest$version,
          update_link = paste0(site, "plugins/", repo, "/", basename(xpi)),
          update_hash = paste0("sha256:", hash),
          applications = list(zotero = list(
            strict_min_version = zotero$strict_min_version,
            strict_max_version = zotero$strict_max_version
          ))
        )))),
        zotero$id
      )),
      updates,
      auto_unbox = TRUE,
      pretty = TRUE
    )
    files <- c(files, xpi, latest, updates)
    info[[repo]] <- list(
      name = manifest$name,
      version = manifest$version,
      description = manifest$description,
      download = paste0("plugins/", repo, "/", repo, ".xpi")
    )
  }
  index <- file.path(dir, "plugins.json")
  jsonlite::write_json(unname(info), index, auto_unbox = TRUE, pretty = TRUE)
  return(c(files, index))
}
