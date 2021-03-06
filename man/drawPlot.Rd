% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotting-functions.R
\name{drawPlot}
\alias{drawPlot}
\title{Interactive Plots of Flow Cytometry Data.}
\usage{
drawPlot(fr, channels, subSample = NULL, cex = 3, adjust = 1.5, ...)
}
\arguments{
\item{fr}{a \code{flowFrame} object containing the flow cytometry data for plotting and gating.}

\item{channels}{a vector indicating the fluorescent channel(s) to be used for gating. If a single channel is supplied, a histogram of
of the kernel density will be constructed.}

\item{subSample}{numeric indicating the number of events to display in 2D plots.}

\item{cex}{numeric passed to plotDens to alter the point size (defaults to 3).}

\item{adjust}{numeric smoothing factor used for 1D density plots (defaults to 1.5).}

\item{...}{additional arguments for plotDens.}
}
\value{
\code{NULL}
}
\description{
\code{drawPlot} opens an interactive plotting window and constructs either a 1-dimensional (1D) density plot or
a 2-dimensional (2D) plot based on teh number of channels supplied.
}
\author{
Dillon Hammill (Dillon.Hammill@anu.edu.au)
}
\keyword{cytometry}
\keyword{density,}
\keyword{draw,}
\keyword{flow}
\keyword{gates,}
\keyword{gating,}
\keyword{manual,}
\keyword{openCyto,}
\keyword{plot,}
