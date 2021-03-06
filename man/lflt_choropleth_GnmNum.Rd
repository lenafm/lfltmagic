% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/choropleth_GnmNum.R
\name{lflt_choropleth_GnmNum}
\alias{lflt_choropleth_GnmNum}
\title{Leaflet choropleths by numerical variable}
\usage{
lflt_choropleth_GnmNum(data = NULL, ...)
}
\arguments{
\item{data}{A data.frame}
}
\value{
leaflet viz
}
\description{
Leaflet choropleths by numerical variable
}
\section{ctypes}{
 Gnm-Num
}

\examples{
lflt_choropleth_GnmNum(sampleData("Gnm-Num", nrow = 10))
}
