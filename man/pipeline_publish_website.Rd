% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pipeline_publish_website.R
\name{pipeline_publish_website}
\alias{pipeline_publish_website}
\title{Publish a built website to a GitHub repo}
\usage{
pipeline_publish_website(
  dir,
  repo_url = "https://github.com/IPBES-Data/IPBES_website_report_bibliographies.git",
  branch = "main",
  repo_dir,
  delete_repo_dir = TRUE
)
}
\arguments{
\item{repo_url}{URL of the GitHub repo (HTTPS or SSH).}

\item{branch}{Target branch to publish to (default "main").}

\item{repo_dir}{Optional path for cloning the repo (default: tempfile()).}

\item{build_dir}{Directory where the website is already built.}
}
\description{
Publish a built website to a GitHub repo
}
