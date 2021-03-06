% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/editSpillover-methods.R
\name{editSpillover}
\alias{editSpillover}
\title{Edit Spillover Matrix}
\usage{
editSpillover(x, ...)
}
\arguments{
\item{x}{object of class \code{flowSet} or \code{GatingSet}.}
}
\description{
\code{editSpillover} provides an interactive shiny interface for editing fluorescent spillover matrices. \code{editSpillover} takes on either a \code{flowSet} 
or \code{GatingSet} containing untransformed single stain compensation controls and a universal unstained control. It is recommended that samples be pre-gated based on FSC
and SSC parameters to obtain a homogeneous population for calculation of fluorescent spillover. Users begin by selecting the unstained control and a stained control
from dropdown menus of sample names. \code{editSpillover} leverages \code{ggcyto} to plot the stained sample and overlay the unstained control in black. Users should
then select the channel associated with the selected control on the \code{x axis} and go through all other channels on the \code{y axis}. The displayed spillover
matrix is extracted directly from the \code{flowSet} or \code{GatingSet} unless another spillover matrix is supplied through the spfile argument. To edit the spillover
matrix simply modify the appropriate cell in the the table. The new spillover matrix will be re-applied to the samples with each edit and automatically re-plotted
so you can track changes in real time. To aid in selection of an appropriate spillover value, the median fluorescent intensity of the unstained control is indicated by
a red line and median fluorescent intensity of the stained control is tracked with a blue line. These features can be turned off by de-selecting the check boxes. Changes
to the spillover matrix are automatically saved to a csv file called \code{"Spillover Matrix.csv"} in the case where the \code{spfile} is not specified or to the same 
name as the specified \code{spfile}. \code{editSpillover} has methods for both \code{flowSet} and \code{GatingSet} objects 
refer to their respective help pages for more information - ?`editSpillover,flowSet-method` or ?`editSpillover,GatingSet-method`.
}
\author{
Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
}
