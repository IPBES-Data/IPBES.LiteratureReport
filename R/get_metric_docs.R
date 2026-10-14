#' Combine the documentation of the measures
#'
#' Reads the roxygen documentation of the measures named in `metric_names`
#' and combines it into one markdown document, with one section per metric
#' group and one subsection per measure, in the order of `input/config.yaml`.
#'
#' @param metric_names Named list of metric groups, each a character vector
#'   of `met_*` function names (`metrics` in `input/config.yaml`).
#' @param metric_code Paths of the `R/met_*.R` files containing the measures.
#' @param result If `TRUE`, include the description of the result of each
#'   measure. Use `FALSE` for readers who only need to know what is checked.
#'
#' @return Markdown text (character string).
get_metric_docs <- function(
  metric_names,
  metric_code,
  result = TRUE
) {
  blocks <- lapply(metric_code, roxygen2::parse_file, env = NULL) |>
    unlist(recursive = FALSE)
  names(blocks) <- vapply(
    blocks,
    function(b) deparse1(b$call[[2]]),
    ""
  )

  missing <- setdiff(unlist(metric_names), names(blocks))
  if (length(missing) > 0) {
    stop("No documentation for measure(s): ", paste(missing, collapse = ", "))
  }

  doc <- function(m) {
    b <- blocks[[m]]
    paste0(
      "### ", roxygen2::block_get_tag_value(b, "title"), " (`", m, "`)\n\n",
      roxygen2::block_get_tag_value(b, "description"),
      if (result) {
        paste0("\n\n**Result:** ", roxygen2::block_get_tag_value(b, "return"))
      }
    )
  }

  docs <- lapply(
    names(metric_names),
    function(group) {
      c(paste("##", group), vapply(metric_names[[group]], doc, ""))
    }
  )

  return(paste(unlist(docs), collapse = "\n\n"))
}
