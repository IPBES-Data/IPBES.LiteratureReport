clean_doi <- function(
    doi) {
  doi <- doi |>
    gsub(pattern = "^https://doi.org/", replacement = "") |>
    gsub(pattern = "^https://dx.doi.org/", replacement = "") |>
    gsub(pattern = "^https://hdl.handle.net/", replacement = "") |>
    gsub(pattern = "^http://doi.org/", replacement = "") |>
    gsub(pattern = "^http://dx.doi.org/", replacement = "") |>
    gsub(pattern = "^http://hdl.handle.net/", replacement = "") |>
    gsub(pattern = "^doi:", replacement = "") |>
    gsub(pattern = "^DOI ", replacement = "")
  return(doi)
}
