% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gating-functions.R
\name{drawPolygon}
\alias{drawPolygon}
\title{Draw Polygon Gate(s) for Analysis of Flow Cytometry Data.}
\usage{
drawPolygon(fr, channels, alias = NULL, subSample = NULL, plot = TRUE,
  labs = TRUE, ...)
}
\arguments{
\item{fr}{a \code{flowFrame} object containing the flow cytometry data for plotting and gating.}

\item{channels}{a vector indicating the fluorescent channel(s) to be used for gating. If a single channel is supplied, a histogram of
of the kernel density will be constructed.}

\item{alias}{the name(s) of the populations to be gated. If multiple population names are supplied (e.g. \code{c("CD3","CD4")}) multiple 
gates will be returned. \code{alias} is \code{NULL} by default which will halt the gating routine.}

\item{subSample}{numeric indicating the number of events to plot to speed up plotting. If \code{subSample} is greater than the total
number of events, all events will be plotted which is the default plotting behaviour.}

\item{plot}{logical indicating whether the data should be plotted. This feature allows for constructing gates of different types over 
existing plots which may already contain a different gate type. For demonstration of this feature refer to the package vignette.}

\item{labs}{logical indicating whether to include \code{plotLabels} for the gated population(s), \code{TRUE} by default.}

\item{...}{additional arguments for \code{plotDens}.}
}
\value{
a list containing the constructed \code{polygonGate} object(s).
}
\description{
\code{drawPolygon} constructs an interactive plotting window for user to select the coordinates a polygon gate which then constructed
into a \code{polygonGate} object and stored in a list.
}
\author{
Dillon Hammill (Dillon.Hammill@anu.edu.au)
}
\keyword{FlowJo,}
\keyword{draw,}
\keyword{gating,}
\keyword{manual,}
\keyword{openCyto}
\keyword{polygonGate,}
