#' Sample age compositions from expected values
#'
#' Take a \code{data.SS_new} file containing expected values and sample to
#' create observed age compositions which are then written to file for use by
#' the EM.
#'
#' @author Cole Monnahan and Kotaro Ono; modified from a version by Roberto
#' Licandeo and Felipe Hurtado-Ferro
#'
#' @template lcomp-agecomp-index
#' @template lcomp-agecomp
#' @param agebin_vector A numeric vector giving the new age bins to
#' use. \code{agebin_vector} must be within the [min;max] of
#' population bin. This feature alows dynamic binning by the user, but
#' is not fully tested. Users should consult the vignette and
#' carefully check the function bins the data as desired before
#' proceeding with simulations.
#'
#' @template sampling-return
#'
#' @examples
#' \dontrun{
#' d <- system.file("extdata", package = "ss3sim")
#' f_in <- paste0(d, "/example-om/data.ss_new")
#' infile <- r4ss::SS_readdat(f_in, section = 2, verbose = FALSE)
#'
#' ## Generate with a smaller number of fleet taking samples
#' ex1 <- change_agecomp(infile=infile, outfile="test1.dat", fleets=c(2),
#'                Nsamp=list(c(10,50)), years=list(c(1999,2000)))
#'
#' ## Generate with varying Nsamp by year for first fleet
#' ex2 <- change_agecomp(infile=infile, outfile="test2.dat", fleets=c(1,2),
#'                Nsamp=list(c(rep(50, 5), rep(100, 5)), 50),
#'                years=list(seq(1994, 2012, by=2),
#'                2003:2012))
#'
#' ## Generate with varying Nsamp by year for first fleet AND with different age bins
#' ex3 <- change_agecomp(infile=infile, outfile="codEM.dat", fleets=c(1,2),
#'                Nsamp=list(c(rep(50, 5), rep(100, 5)), 50),
#'                years=list(seq(1994, 2012, by=2),
#'                2003:2012), agebin_vector = seq(1,15,by=3))
#'
#' plot(seq(0,15, by=3), as.numeric(ex3[1, -(1:9)]), type="b", col=2,
#'      xlab="Age Bin", ylab="Proportion of Age",
#'      main="Comparison of different age bin structures via agebin_vector")
#' lines(0:15, as.numeric(ex1[1, -(1:9)]), type="b", col=1)
#' legend("topright", legend=c("ex1", "ex3"), col=c(1,2), pch=1)
#'
#' unlink(x=c("test1.dat", "test2.dat", "test3.dat")) # clean up
#'
#' ## Plot distributions for a particular year for a cpar of 5 and 1 to
#' ## demonstrate the impact of cpar
#' temp.list <- list()
#' for(i in 1:500){
#'     temp.list[[i]] <-
#'         change_agecomp(infile=infile, outfile="test1.dat",
#'                        fleets=c(1,2), cpar=c(5,1), Nsamp=list(100,100),
#'                        years=list(1995, 1995), write_file=F)
#' }
#' xx <- do.call(rbind, temp.list)[,-(1:9)[-3]]
#' xx <- reshape2::melt(xx, id.vars="FltSvy")
#' par(mfrow=c(2,1))
#' with(subset(xx, FltSvy==1), boxplot(value~variable, las=2,
#'                 main="Overdispersed",  xlab="Age bin"))
#' temp <- as.numeric(subset(infile$agecomp, Yr==1995 & FltSvy == 1)[-(1:9)])
#' points(temp/sum(temp), pch="-", col="red")
#' with(subset(xx, FltSvy==2), boxplot(value~variable, las=2,
#'                 main="Multinomial", xlab="Age bin"))
#' temp <- as.numeric(subset(infile$agecomp, Yr==1995 & FltSvy == 2)[-(1:9)])
#' points(temp/sum(temp), pch="-", col="red")
#' #' }
#' @export

change_agecomp <- function(infile, outfile, fleets = c(1,2), Nsamp,
                           years, cpar=1, agebin_vector=NULL, write_file=TRUE){
    ## The new agecomp is mostly based on the old one so start with
    ## that
    agecomp <- infile$agecomp
    newbins <- agebin_vector
    oldbins <- infile$aigebin_vector
    if(!is.null(newbins)){
        if (min(newbins) > min(oldbins)) newbins <- c(min(oldbins), newbins)
        Nbins <- length(newbins)
    }
        ## Check inputs for errors
    if(substr_r(outfile,4) != ".dat" & write_file)
        stop(paste0("outfile ", outfile, " needs to end in .dat"))
    Nfleets <- length(fleets)
    # if(length(unique(agecomp$FltSvy)) != Nfleets)
        # stop(paste0("Number of fleets specified (",Nfleets,
                    # ") does not match input file (",
                    # length(unique(agecomp$FltSvy)), ")"))
    if(FALSE %in% (fleets %in% unique(agecomp$FltSvy)))
        stop(paste0("The specified fleet number does not match input file"))
    if(Nfleets!= 0 & class(Nsamp) != "list" | length(Nsamp) != Nfleets)
        stop("Nsamp needs to be a list of same length as fleets")
    if(Nfleets!= 0 & class(years) != "list" | length(years) != Nfleets)
        stop("years needs to be a list of same length as fleets")
    if (!is.null(fleets)){
  for(i in 1:Nfleets){
        if(length(Nsamp[[i]])>1 & length(Nsamp[[i]]) != length(years[[i]]))
            stop(paste0("Length of Nsamp does not match length of years for fleet ",fleets[i]))
    }}  
    if(length(cpar) == 1){
        ## If only 1 value provided, use it for all fleets
        cpar <- rep(cpar, times=Nfleets)
    } else if(length(cpar) != Nfleets){
        stop(paste0("Length of cpar (", length(cpar),
                    ") needs to be length of fleets (", Nfleets,
                    ") or 1"))
    }
    ## End input checks

    ## Recalculate age bins depending on user input
    if (!is.null(newbins)) {
        if (class(newbins) != "numeric") {
            stop("agebin_vector must have a numeric input")
        }
        if (min(newbins) < min(oldbins) |
            max(newbins) > max(oldbins)) {
            stop("agebin_vector must be within the [min;max] of population bin")
        }
        ## Adjust the "old" age bins to the "new" one
        if (length(oldbins) != Nbins) {
            newbin.index <- findInterval(oldbins, newbins)
            ## Calculate new bins by consolidating old bins, and then and sum
            ## across appropriate columns to create the new columns
            temp.index <- 1:length(unique(newbin.index))
            temp <- sapply(temp.index, function(x)
                           apply(as.matrix(agecomp[, 9+which(newbin.index==x)]),1, sum))
            new.agecomp <- cbind(agecomp[,1:9], temp)
            names(new.agecomp)[-(1:9)] <-
                c(paste0("a", newbins[-Nbins], "-",
                         newbins[-1]), paste0("a>",newbins[Nbins]))

            ## Change the corresponding locations in the .dat file
            infile$N_agebins <- Nbins
            infile$agebin_vector <- newbins
            agecomp <- new.agecomp
        }
    }

    ## Resample from the age data
    ## The general approach here is to loop through each row to keep
    ## (depends on years input) and resample depending on Nsamp and
    ## cvar. All these rows are then combined back together to form
    ## the final agecomp.
    newcomp.list <- list()                  # temp storage for the new rows
    k <- 1
    ## Loop through each fleet
    if (!is.null(fleets)){
  for(i in 1:length(fleets)){
        fl <- fleets[i]
        if(!is.na(fl)){
            agecomp.fl <- agecomp[agecomp$FltSvy == fl & agecomp$Yr %in% years[[i]], ]
            if(length(years[[i]]) != nrow(agecomp.fl))
                stop(paste("A year specified in years was not found in the input file for fleet", fl))
            agecomp.fl$Nsamp <- Nsamp[[i]]
            ## Now loop through each year and resample that row
            for(yr in years[[i]]) {
                newcomp <- agecomp.fl[agecomp.fl$Yr==yr, ]
                ## First 1-9 cols aren't age bins so skip them
                probs <- as.numeric(newcomp[-(1:9)]/sum(newcomp[-(1:9)]))
                lambda <- newcomp$Nsamp/cpar[i]^2 - 1
                ## Replace expected values with sampled values
                newcomp[-(1:9)] <-
                    gtools::rdirichlet(1, as.numeric(probs) * lambda)
                newcomp.list[[k]] <- newcomp
                k <- k+1
            }
        }
    }}
    ## Combine new rows together into one data.frame
    if(Nfleets>0) newcomp.final <- do.call(rbind, newcomp.list)
    if(Nfleets==0) newcomp.final = data.frame("#")
  
    ## Build the new dat file
    newfile <- infile
    newfile$agecomp <- newcomp.final
    if(Nfleets>0) newfile$N_agecomp <- nrow(newcomp.final)
    if(Nfleets==0) newfile$N_agecomp <- 0

    ## Write the modified file
    if(write_file)
        r4ss::SS_writedat(datlist = newfile, outfile = outfile, overwrite = T)
    return(invisible(newcomp.final))
}


