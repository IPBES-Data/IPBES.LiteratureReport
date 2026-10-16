# Checks of the fixes, the published proposals and the fix app, from the repo
# root:
#
#   Rscript tests/check_fixes.R          # one group (PAND), fast
#   Rscript tests/check_fixes.R all      # all groups in output/metrics/
#
# Needs the pipeline output (output/metrics, output/zotero_works).

for (f in list.files("R", "[.]R$", full.names = TRUE)) source(f)
all <- identical(commandArgs(TRUE)[1], "all")
files <- list.files("output/metrics", "[.]rds$", full.names = TRUE)
if (!all) files <- grep("PAND", files, value = TRUE)
stopifnot("no metrics found, run the pipeline first" = length(files) > 0)
ok <- function(...) cat("OK  ", ..., "\n")

# every fix returns changes in the form the app and the plugin expect
required <- c("group_id", "item_key", "title", "field", "old", "new", "reason", "proposed", "note")
fixes <- fix_table()
for (file in files) {
  m <- readRDS(file)
  for (i in seq_len(nrow(fixes))) {
    x <- fixes$fun[[i]](m, 1)
    stopifnot(
      all(required %in% names(x)),
      is.logical(x$proposed),
      is.character(x$old), is.character(x$new),
      !anyNA(x$item_key), !anyNA(x$field),
      !"choice" %in% names(x) || "preselect" %in% names(x)
    )
  }
  ok(basename(file), ":", nrow(fixes), "fixes return changes in the agreed form")

  # the published file matches the schema (written to a temporary folder)
  name <- tools::file_path_sans_ext(basename(file))
  id <- sub(".*_", "", name)
  out <- export_proposals(file, file.path("output/zotero_works", name),
    list(name = sub("^IPBES_(.*)_[0-9]+$", "\\1", name), id = id), dir = tempdir())
  j <- jsonlite::read_json(out)
  stopifnot(length(j$fixes) == nrow(fixes))
  ok(basename(out), ": proposals file valid against the schema")
}

# the schema catches broken files
j <- jsonlite::read_json(out)
check <- function(x) jsonvalidate::json_validate(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"),
  "input/proposals.schema.json", engine = "ajv")
first <- which(vapply(j$fixes, function(f) length(f$changes) > 0, NA))[1]
bad_key <- j; bad_key$fixes[[first]]$changes[[1]]$item_key <- "abc"
no_old <- j; no_old$fixes[[first]]$changes[[1]]$old <- NULL
stopifnot(check(j), !check(bad_key), !check(no_old))
ok("schema: valid file accepted, broken files refused")

# the Zotero plugins build for the website, with matching hashes
built <- build_plugins(file.path("plugins", c("zotero-safe-edit", "zotero-fix-proposals")), dir = tempfile())
for (u in grep("updates[.]json$", built, value = TRUE)) {
  e <- jsonlite::read_json(u)$addons[[1]]$updates[[1]]
  xpi <- file.path(dirname(u), basename(e$update_link))
  stopifnot(identical(e$update_hash, paste0("sha256:", as.character(openssl::sha256(file(xpi))))))
}
ok("plugins build, update hashes match")

# the fix app loads with the shared code
local({
  old <- setwd("fix_app")
  on.exit(setwd(old))
  options(fix_app.project = normalizePath(".."))
  env <- new.env()
  sys.source("app.R", envir = env)
  stopifnot(is.function(env$server), !is.null(env$ui), length(env$fixes) == nrow(fixes))
})
ok("fix app loads,", nrow(fixes), "fixes")
