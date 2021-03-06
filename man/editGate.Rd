% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helper-functions.R
\name{editGate}
\alias{editGate}
\title{Edit Existing Gate(s).}
\usage{
editGate(x, pData = NULL, parent = NULL, alias = NULL, gate_type = NULL,
  gtfile = NULL)
}
\arguments{
\item{x}{an object of class \code{GatingSet}.}

\item{pData}{vector of form \code{c("column","row")} indicating the rows of \code{pData(fs)} to extract.}

\item{parent}{name of the parental population.}

\item{alias}{name(s) of the gate to edit (e.g. "Single Cells").}

\item{gate_type}{vector of gate type names used to construct the gates. Multiple \code{gate_types} are supported but should be accompanied with
an \code{alias} argument of the same length (i.e. one \code{gate_type} per \code{alias}). Supported \code{gate_types} are \code{polygon, rectangle,
ellipse, threshold, boundary, interval, quadrant and web} which can be abbreviated as upper or lower case first letters as well. Default \code{gate_type}
is \code{"polygon"}.}

\item{gtfile}{name of the \code{gatingTemplate} csv file (e.g. "gatingTemplate.csv") where the gate is saved.}
}
\value{
an object of calss \code{GatingSet} with edited gate applied, as well as gatingTemplate file with editied gate saved.
}
\description{
Edit Existing Gate(s).
}
\author{
Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
}
