% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/z_plot_types.R
\name{plot_types}
\alias{plot_types}
\title{Plot the types of publications}
\usage{
plot_types(data_fn)
}
\arguments{
\item{data}{A data frame containing the following columns:
\describe{
\item{type}{The type of publication.}
\item{count}{The count of publications.}
}}
}
\value{
A ggplot object representing the bar chart.
}
\description{
This function takes a data frame as input and plots a bar chart of the types of publications.
}
\details{
The \code{plot_types} function takes a data frame as input and plots a bar chart of the types of publications.
It filters the data frame to include only publications with a count greater than 10, and then uses
\code{ggplot2} to create the bar chart. The x-axis represents the types of publications, and the y-axis represents the count of publications.
The title of the plot is "Most often cited Journals". The function returns a \code{ggplot} object representing
the bar chart.
}
