#' Publish a built website to a GitHub repo
#'
#' @param build_dir Directory where the website is already built.
#' @param repo_url URL of the GitHub repo (HTTPS or SSH).
#' @param branch Target branch to publish to (default "main").
#' @param repo_dir Optional path for cloning the repo (default: tempfile()).
#'
#' @importFrom gert git_clone git_add git_commit git_push
#' @export
pipeline_publish_website <- function(
  dir,
  repo_url = "https://github.com/IPBES-Data/IPBES_website_report_bibliographies.git",
  branch = "main",
  repo_dir,
  delete_repo_dir = TRUE
) {
  if (!dir.exists(dir)) {
    stop("The directory '", dir, "' does not exist.")
  }
  build_dir <- file.path(dir, "output", "report")
  if (!dir.exists(build_dir)) {
    stop(
      "The build directory which should contain the new website '",
      build_dir,
      "' does not exist."
    )
  }

  # Prepare publish directory (repo_dir)
  if (!dir.exists(repo_dir)) {
    dir.create(
      repo_dir,
      recursive = TRUE
    )
  }

  # Prepare publish directory (repo_dir)
  if (!dir.exists(file.path(repo_dir, ".git"))) {
    message("Cloning repo...")
    gert::git_clone(repo_url, path = repo_dir, branch = branch)
  } else {
    message("Using existing repo directory; pulling and resetting...")
    gert::git_fetch(remote = "origin", repo = repo_dir)
    # Force reset local branch to remote branch
    gert::git_reset_hard(paste0("origin/", branch), repo = repo_dir)
    gert::git_branch_checkout(branch, repo = repo_dir)
  }

  # Copy contents from build_dir into repo folder (overwrite existing files)
  message("Copying website files into repo...")
  files <- list.files(
    build_dir,
    recursive = TRUE,
    full.names = FALSE
  )
  for (f in files) {
    dest <- file.path(
      repo_dir,
      f
    )
    dir.create(
      dirname(dest),
      recursive = TRUE,
      showWarnings = FALSE
    )
    file.copy(
      file.path(build_dir, f),
      dest,
      overwrite = TRUE
    )
  }

  # Stage all changes
  message("Staging changes...")
  gert::git_add(
    ".",
    repo = repo_dir
  )

  # Check if there are changes to commit
  if (nrow(gert::git_status(repo = repo_dir)) > 0) {
    message("Committing changes...")
    gert::git_commit(
      "Publish website",
      repo = repo_dir
    )

    # Push changes
    message("Pushing to remote...")
    gert::git_push(
      repo = repo_dir
    )
    message("Publish complete!")
  } else {
    message("No changes to push.")
  }

  if (delete_repo_dir) {
    unlink(
      repo_dir,
      recursive = TRUE,
      force = TRUE
    )
  }
}
