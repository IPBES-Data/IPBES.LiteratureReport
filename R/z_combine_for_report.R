#' Combine multiple objects for a report
#'
#' This function takes an arbitrary number of objects as arguments and combines them
#' into a single object. The combined object can then be used for further analysis
#' or reporting.
#'
#' @param ... Objects to be combined.
#'
#' @return A combined object.
#'
#' @importFrom targets tar_read
#' @export

combine_for_report <- function(...) {
  return(list(...))
}
