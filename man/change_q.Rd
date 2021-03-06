% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/change_q.R
\name{change_q}
\alias{change_q}
\title{Add or remove a q in an SS control file}
\usage{
change_q(
  string_add = NULL,
  string_remove = NULL,
  ctl_list,
  dat_list,
  ctl_file_in = NULL,
  dat_file_in = NULL,
  ctl_file_out = NULL,
  overwrite = FALSE,
  verbose = FALSE
)
}
\arguments{
\item{string_add}{A vector of character strings with the fleetnames to add.
Numeric values representing the fleet number are also allowed or any
combination thereof.}

\item{string_remove}{A vector of character strings with the fleetnames to remove.
Numeric values representing the fleet number are also allowed or any
combination thereof.}

\item{ctl_list}{A control file read in by \code{\link[r4ss]{SS_readctl}}.}

\item{dat_list}{An SS data list object as read in from
\code{\link[r4ss]{SS_readdat}}.
Be sure to correctly specify which section of the data file you want
to work with when reading it in using the \code{section} argument.
Where, \code{section = 1} reads in the input values used to run the model
and \code{section = 2} reads in the expected values generated give all the
input to the OM. \code{section = 3} is not used within ss3sim, but this
section provides bootstrapped data sets that have been sampled internally
within SS.}

\item{ctl_file_in}{A string providing the path to the input SS \code{.ctl} file.}

\item{dat_file_in}{A string providing the path to the input SS \code{.dat} file.}

\item{ctl_file_out}{A string providing the path to the output SS control file. If the value is \code{NULL}, the file will not be written to the disk.}

\item{overwrite}{A logical value specifying if the file being written to the
disk should overwrite an existing file with the same name.
The default is to not overwrite files, i.e., \code{overwrite = FALSE}.}

\item{verbose}{When \code{TRUE} messages will be returned
from the function. Often useful for debugging. The default
is \code{FALSE}.}
}
\value{
A modified SS control file list with the same structure as that read
in by \code{\link[r4ss]{SS_readctl}}.
}
\description{
This function adds or removes a q setup line in an SS control file.
}
\details{
Parameters that are added are simple versions of the structures available
within Stock Synthesis. For example, the current functionality of
\code{change_q} does not allow for modeling an additional parameter for
added variance for the given survey of interest. Though it will remove
that parameter if present for a given fleet that no longer has survey data.
Additionally, the float term is not used and is instead set to zero.

\code{change_q} can add and remove parameters in the control file
simultaneously, and thus, it is not necessary to call the function twice
when wanting to perform both operations. A helper function,
\code{\link{check_q}} is a available to determine which fleets one should
remove and add.
}
\seealso{
\code{\link{change_q}}
}
\author{
Kelli Faye Johnson
}
