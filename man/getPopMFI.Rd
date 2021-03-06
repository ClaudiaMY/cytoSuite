% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/population-statistics.R
\name{getPopMFI}
\alias{getPopMFI}
\title{Extract Population Level Statistics from GatingSet.}
\usage{
getPopMFI(gs, pops, stat = "median", channels = NULL)
}
\arguments{
\item{gs}{a \code{GatingSet} object defining populations for which statistics should be calulated.}

\item{pops}{a vector containing the \code{node} names of the populations of interest.}

\item{stat}{specify the statistic of interest by name, can be either "mean", "median" or "count". By default we use the more robust
median fluorescent intensity (MedFI).}

\item{channels}{a vector of channel names for which population statistics should be calculated, all channels by default.}
}
\value{
a \code{list} object containing the calculated statistics for specified populations in all samples.
}
\description{
\code{PopStats} function allows easy extraction of population level statistics from a \code{GatingSet} object,
including geometric mean and median fluorescent intensities. \code{PopStats} searches \code{GatingSet} object for logicle
transformation parameters and if present performs the inverse logicle transformation prior to calculation of relevant
statistic. By default if no channels are supplied \code{PopStats} returns statistics for channels containing \code{markernames},
if no \code{markernames} are found statistics are performed on all fluorescent channels.
}
\author{
Dillon Hammill (Dillon.Hammill@anu.edu.au)
}
\keyword{MFI}
\keyword{geometric}
\keyword{mean,}
\keyword{median,}
\keyword{population,}
\keyword{statistics,}
