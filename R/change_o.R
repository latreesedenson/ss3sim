#' Methods to include parameters in an SS3operating model
#'
#' \code{change_o} takes an SS3 \code{.ctl}file
#' and implements parameter value changes that are NOT time varying.
#' \code{change_o} is specifically set up to work with an operating model
#' \code{.ctl} file.
#'
#' @param change_o_list A list of named vectors. Names correspond to parameters
#'   in the operating model and the vectors correspond to deviations.
#'   Alternatively, \code{par_name} and \code{par_init} can be passed to this
#'   function.
#' @template ctl_file_in
#' @template ctl_file_out
#' @template par_name
#' @template par_int
#' @template verbose
#' @author Kathryn Doering
#' @family change functions
#' @return The function creates modified versions of the  \code{.ctl} files. The
#'   function also returns \code{change_o_list} invisibly.
#'
#' @section Specifying the \code{change_o_list}:
#'
#' Parameters initial values will change according to the values passed to
#' \code{change_o_list}. Each parameter should have a single value specified.
#'
#' Parameter names must be unique and match the full parameter name in the
#' \code{.ctl} file.
#'
#' @section Passing arguments to \code{change_o} through \code{\link{run_ss3sim}}:
#' (1) add a column called `co.par_name` to the `simdf` that specifies which parameters
#' you want to change in the OM, each element of this vector needs to be
#' wrapped in quotations to be later evaluated, e.g., `'c("SR_BH_steep","SR_sigmaR")'`
#' represents a single entry;
#' and (2) add an additional column called `co.par_int` to the `simdf` that specifies
#' INIT values for each parameter in the previous column, e.g., `"c(0.6, 1.0)"`, if
#' there is more than one value, the vector needs to be wrapped in quotations to be
#' evaluated later.
#'
#' @importFrom r4ss SS_parlines SS_changepars
#'
#' @export


change_o <- function(change_o_list,
                     ctl_file_in = "control.ss_new", ctl_file_out = "om.ctl",
                     par_name = NULL, par_int = NULL, verbose = FALSE) {
  # make par_name and par_int into change_o_list, if passing variable that way.
  if ((!is.null(par_name)) & (!is.null(par_int))){
    check_eqlength("par_name" = par_name, "par_int" = par_int)
    change_o_list <- lapply(par_int, function(x) x)
    names(change_o_list) <- par_name
  } else if (!(is.null(par_name) & is.null(par_int))){ # check for valid values
    stop("Please make sure if you want to pass in arguments to change_o via ",
         "par_name and par_int that BOTH have values. Par_name had value(s): ",
         paste0(par_name, collapse = ", "), ", while par_int had value(s): ",
         paste0(par_int, collapse = ", "), ".")
  }

  # read in necessary ss files.
  ss3.ctl.parlines <- SS_parlines(ctl_file_in, verbose = FALSE)
  # check for valid input ------------------------------------------------------
  # check that the variables can all be found and warn user if not
  if(any(!(names(change_o_list) %in% ss3.ctl.parlines$Label))) {
    tmp_names <- names(change_o_list)
    tmp_names <- tmp_names[-which(tmp_names %in% ss3.ctl.parlines)]
    stop("The variables", paste(tmp_names, collapse = ", "), ", which the user",
    " requested to modify in the OM could not be found in the OM control file.",
    " Please check that this variable is in the OM control file.")
  }
  # make sure only 1 value for each variable
  if(any(lapply(change_o_list, function(x) length(x)) != 1)) {
    tmp_pos <- which(lapply(change_o_list, function(x) length(x)) != 1)
    stop("The function change_o should only be used for changing single ",
         "initial values in the OM control file. However, multiple values for ",
         "the parameter", names(change_o_list)[tmp_pos], "were passed. If you ",
         "wish to implement any parameter as time varying, please use the ",
         "function change_tv instead and note that the input should be ",
         "additive with the value already specified.")
  }
  # change the intial values ---------------------------------------------------
  #make into a named vector
  change_o_vec <- vapply(change_o_list, function(x) x[[1]], FUN.VALUE = 0.1 )
  # pass to SS_changepars
  SS_changepars(dir = NULL, ctlfile = ctl_file_in,
                newctlfile = ctl_file_out, strings = names(change_o_vec),
                newvals = change_o_vec, verbose = FALSE)
  # TODO: the way SS_changepars is written means it is necessary to write to file.
  # May need to explore ways so a file does not need to be written, but a ctl r
  # object can be passed back with the changes.
  invisible(change_o_list)
}
