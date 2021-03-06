#' Compute Spillover Matrix
#' 
#' \code{computeSpillover} uses the method described by Bagwell & Adams 1993 to calculate fluorescent spillover values using single 
#' stain compensation controls and a universal unstained control. \code{computeSpillover} begins by the user selecting which fluorescent
#' channel is associated with each control from a dropdown menu. Following channel selection, \code{computeSpillover} runs through each control
#' and plots a histogram which is gated by the user using an interval gate (refer to cytoSuite drawInterval documentation) to 
#' select the positive population to use for the spillover calculation. The percentage spillover is calculated based on the median fluorescent
#' intensities of the stained populations and the universal unstained sample. The computed spillover matrix is returned as an r object and written
#' to a named .csv file for future use. \code{computeSpillover} has methods for both \code{flowSet} and \code{GatingSet} objects refer to their
#' respective help pages for more information - ?`computeSpillover,flowSet-method` or ?`computeSpillover,GatingSet-method`.
#' 
#' @param x object of class \code{flowSet} or \code{GatingSet}.
#' @param ... additional method-specific arguments, see ?`computeSpillover,flowSet-method` or ?`computeSpillover,GatingSet-method` for details.
#' 
#' @author Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
#' 
#' @references C. B. Bagwell \& E. G. Adams (1993). Fluorescence spectral overlap compensation for any number of flow cytometry parameters. in: Annals of the New York Academy of Sciences, 677:167-184.
#' 
#' @export
setGeneric(name="computeSpillover",
           def=function(x, ...){standardGeneric("computeSpillover")}
)

#' Compute Spillover Matrix - flowSet Method
#' 
#' Calculate spillover matrix using \code{GatingSet} containing gated single stain compensation controls and an unstained control.
#' \code{computeSpillover} uses the method described by Bagwell & Adams 1993 to calculate fluorescent spillover values using single 
#' stain compensation controls and a universal unstained control. \code{computeSpillover} begins by the user selecting which fluorescent
#' channel is associated with each control from a dropdown menu. Following channel selection, \code{computeSpillover} runs through each control
#' and plots a histogram which is gated by the user using an interval gate (refer to cytoSuite drawInterval documentation) to 
#' select the positive population to use for the spillover calculation. The percentage spillover is calculated based on the median fluorescent
#' intensities of the stained populations and the universal unstained sample. The computed spillover matrix is returned as an r object and written
#' to a named .csv file for future use.
#'
#' @param x object of class \code{flowSet} containing pre-gated single stain compensation controls and a universal unstained control. Currently,
#' computeSpillover does not pre-gate samples to obtain a homogeneous cell population for downstream calculations. We therefore recommmend pre-gating
#' samples based on FSC and SSC parameters prior to passing them to computeSpillover (i.e. \code{x} should contain events for single cells only).
#' Passing raw files to computeSpillover will result in inaccurate calculations of fluorescent spillover.
#' @param trans object of class \code{"transformList"} generated by \code{estimateLogicle} to transform fluorescent channels for gating. \code{trans}
#' is required if logicle transformation has already been applied to \code{x} using estimateLogicle. \code{computeSpillover} will automatically call
#' estimateLogicle internally to transform channels prior to gating, if \code{trans} is supplied it will be used for the transformation instead.
#' @param cmfile name of .csv file containing the names of the samples in a column called "name" and their matching channel in a column called "channel".
#' \code{computeSpillover} will the guide you through the channel selection process and generate a channel match file called "Compensation Channels.csv" 
#' automatically. If you already have a complete cmfile and would like to bypass the channel selection process, simply pass the name of the cmfile to 
#' this argument (e.g. "Compensation Channels.csv").
#' @param spfile name of the output spillover csv file, set to \code{"Spillover Matrix.csv"} by default.
#' @param ... additional arguments passed to estimateLogicle to transform fluorescent channels prior to gating.
#' 
#' @return spillover matrix object and \code{"Spillover Matrix.csv"} file.
#' 
#' @examples
#' \dontrun{
#' fs <- Activation
#' gate1 <- drawGate(fs, alias = "Cells", channels = c("FSC-A","SSC-A"))
#' Cells <- Subset(fs, g1[[1]])
#' gate2 <- drawGate(Cells, alias = "Singlets", channels = c("FSC-A","FSC-H"))
#' Singlets <- Subset(Cells, g2[[1]])
#' spill <- computeSpillover(Singlets, spfile = "Example Spillover Matrix.csv")
#' }
#' 
#' @importFrom flowCore estimateLogicle transform each_col fsApply inverseLogicleTransform
#' @importFrom flowWorkspace pData
#' 
#' @author Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
#' 
#' @export
setMethod(computeSpillover, signature = "flowSet", definition = function(x, trans = NULL, cmfile = NULL, spfile = "Spillover Matrix.csv", ...){
  
  fs <- x
  
  # Extract fluorescent channels
  channels <- getChannels(fs)
  
  # Select a fluorescent channel for each compensation control
  if(is.null(cmfile)){
    
    pData(fs)$channel <- paste(selectChannels(fs))
    write.csv(pData(fs), "Compensation Channels.csv", row.names = FALSE)
    
  }else{
    
    pd <- read.csv(cmfile, header = TRUE, row.names = 1)
    pData(fs)$channel <- paste(pd$channel)
    
  }
  
  # Merge files for use with estimateLogicle
  fr <- as(fs, "flowFrame")
  
  # Apply logicle transformation for gating
  if(is.null(trans) | class(trans) != "transformList"){
    
    message("No transformList supplied to transfom channels prior to gating. All fluorescent channels will be transformed using the logicle transformation.")
    
    # Check if transformation has been applied using range of values
    if(!all(each_col(fs[[1]], range)[,channels][1,] >= -5 & each_col(fs[[1]], range)[,channels][2,] <= 5)){
      
      # Transformation has not been applied
      trans <- estimateLogicle(fr, channels, ...)
      fs <- suppressMessages(transform(fs, trans))
      
    }else{
      
      stop("Please provide transformList object used to transform the flowSet to the trans argument.")
      
    }
    
  }else if(!all(channels %in% names(trans))){
    
    # Not all fluorescent channels are listed in transformList
    message("Not all channels are transformed using this transformList - applying logicle transformation to remaining fluorescent channels.")
    
    # Check if transformation has been applied using range of values
    if(!all(each_col(fs[[1]], range)[,names(trans)][1,] >= -5 & each_col(fs[[1]], range)[,names(trans)][2,] <= 5)){
      
      # Get transformList for remaining channels
      chnls <- channels[-match(names(trans), channels)]
      trans <- c(trans, estimateLogicle(fr, chnls, ...))
      
      # Transformation has not been applied
      fs <- suppressMessages(transform(fs, trans))
      
    }
    
  }else if(all(channels %in% names(trans))){
    
    # Check if transformation has been applied using range of values
    if(!all(each_col(fs[[1]], range)[,channels][1,] >= -5 & each_col(fs[[1]], range)[,channels][2,] <= 5)){
      
      # Transformation has not been applied
      fs <- suppressMessages(transform(fs, trans))
      
    }
    
  }
  
  # Extract unstained control based on selected channels in pData(fs)
  NIL <- fs[[match("Unstained", pData(fs)$channel)]]
  fs <- fs[-match("Unstained", pData(fs)$channel)]
  
  # Assign channel to each flowFrame to description slot called "channel"
  suppressWarnings(sapply(1:length(pData(fs)$channel), function(x){
    
    fs[[x]]@description$channel <- paste(pData(fs)$channel[x])
    
  }))
  
  # Gate positive populations
  pops <- fsApply(fs, function(fr){
    
    # Call drawGate on each flowFrame using interval gate on selected channel
    gt <- drawGate(x = fr, alias = paste(fr@description$channel,"+"), channels = fr@description$channel, gate_type = "interval", adjust = 1.5)
    fr <- Subset(fr, gt[[1]])
    
  }, simplify = TRUE)
  
  # Inverse logicle transformation
  inv <-  inverseLogicleTransform(trans)
  pops <- suppressMessages(transform(pops, inv))
  NIL <- suppressMessages(transform(NIL, inv))
  
  # Calculate MedFI for all channels for unstained control
  neg <- each_col(NIL, median)[channels]
  
  # Calculate MedFI for all channels for all stained controls
  pos <- fsApply(pops, each_col, median)[,channels]
  
  # Subtract background fluorescence
  signal <- sweep(pos, 2, neg)
  
  # Construct spillover matrix - only include values for which there is a control
  spill <- diag(x = 1, nrow = length(channels), ncol = length(channels))  
  colnames(spill) <- channels
  rownames(spill) <- channels
  
  # Normalise each row to stained channel
  for(i in 1:nrow(signal)){
    
    signal[i, ] <- signal[i, ]/signal[i, match(fs[[i]]@description$channel, colnames(spill))]
    
  } 
  
  # Insert values into appropriate rows
  rws <- match(pData(fs)$channel, rownames(spill))
  spill[rws,] <- signal
  
  write.csv(spill, spfile)
  return(spill)
  
})

#' Compute Spillover Matrix - GatingSet Method
#' 
#' Calculate spillover matrix using \code{flowSet} containing gated single stain compensation controls and an unstained control.
#' \code{computeSpillover} uses the method described by Bagwell & Adams 1993 to calculate fluorescent spillover values using single 
#' stain compensation controls and a universal unstained control. \code{computeSpillover} begins by the user selecting which fluorescent
#' channel is associated with each control from a dropdown menu. Following channel selection, \code{computeSpillover} runs through each control
#' and plots a histogram which is gated by the user using an interval gate (refer to cytoSuite drawInterval documentation) to 
#' select the positive population to use for the spillover calculation. The percentage spillover is calculated based on the median fluorescent
#' intensities of the stained populations and the universal unstained sample. The computed spillover matrix is returned as an r object and written
#' to a named .csv file for future use. 
#' 
#' @param x object of class \code{GatingSet} containing pre-gated single stain compensation controls and a universal unstained control. Currently,
#' computeSpillover does not pre-gate samples to obtain a homogeneous cell population for downstream calculations. We therefore recommmend pre-gating
#' samples based on FSC and SSC parameters prior to passing them to computeSpillover and indicate the population of interest using the \code{alias} argument.
#' @param alias name of the pre-gated population to use for downstream calculations, set to the last node of the GatingSet by default (e.g. "Single Cells").
#' @param trans object of class \code{"transformList"} generated by \code{estimateLogicle} to transform fluorescent channels for gating. \code{trans}
#' is required if logicle transformation has already been applied to \code{x} using estimateLogicle. \code{computeSpillover} will automatically call
#' estimateLogicle internally to transform channels prior to gating, if \code{trans} is supplied it will be used for the transformation instead.
#' @param cmfile name of .csv file containing the names of the samples in a column called "name" and their matching channel in a column called "channel".
#' \code{computeSpillover} will the guide you through the channel selection process and generate a channel match file called "Compensation Channels.csv" 
#' automatically. If you already have a complete cmfile and would like to bypass the channel selection process, simply pass the name of the cmfile to 
#' this argument (e.g. "Compensation Channels.csv").
#' @param spfile name of the output spillover csv file, set to \code{"Spillover Matrix.csv"} by default.
#' @param ... additional arguments passed to estimateLogicle to transform fluorescent channels prior to gating.
#' 
#' @return spillover matrix object and \code{"Spillover Matrix.csv"} file.
#' 
#' #' @examples
#' \dontrun{
#' fs <- Activation
#' gs <- GatingSet(fs)
#' drawGate(gs, parent = "root", alias = "Cells", channels = c("FSC-A","SSC-A"), gtfile = "Example gatingTemplate.csv")
#' drawGate(gs, parent = "Cells", alias = "Singlets", channels = c("FSC-A","FSC-H"), gtfile = "Example gatingTemplate.csv")
#' spill <- computeSpillover(gs, alias = "Single Cells", spfile = "Example Spillover Matrix.csv")
#' }
#' 
#' @importFrom flowCore estimateLogicle transform each_col fsApply inverseLogicleTransform
#' @importFrom flowWorkspace getData pData
#' 
#' @author Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
#' 
#' @export
setMethod(computeSpillover, signature = "GatingSet", definition = function(x, alias = NULL, trans = NULL, cmfile = NULL, spfile = "Spillover Matrix.csv", ...){
  
  gs <- x
  
  # Extract fluorescent channels
  channels <- getChannels(gs)
  
  # Apply logicle transformation for gating
  if(!is.null(trans)){
    
    if(class(trans) != "transformerList"){
      
      stop("Transformation object should be of class transformerList.")
      
    }

    if(length(gs[[1]]@transformation) == 0){
      
      # No transformation has been applied to GatingSet
      chans <- names(trans)
      
      if(all(chans %in% channels)){
        
        gs <- transform(gs, trans)
        
      }else if(length(gs[[1]]@transformation) != 0){
        
       # Some transformation applied - check that all channels are transformed
        chans <- names(gs[[1]]@transformation)
        
        if(all(chans %in% channels)){
          
          # All channels have been transformed
          trans <- gs[[1]]@transformation
          
        }else{
          
          # Only some of the channels are transformed
          # Which channels are in trans object get remainder using estimateLogicle
          chans <- names(gs@transformation[[1]])
          chans <- channels[is.na(match(channels,chans))]
          chans <- channels[is.na(match(channels, names(trans)))]
          
          if(length(chans) != 0){
            
          trns <- estimateLogicle(gs.m[[1]], chans)
          gs <- transform(gs, trns)
          trans <- gs[[1]]@transformation
          
          }else{
            
            trans
            
          }
          
          gs <- suppressMessages(transform(gs, trans))
          
        }
        
      }
    }
    
   
  # No transformation object supplied - use estimateLogicle   
  }else{
  
  # Extract Population for Downstream Analyses
  if(!is.null(alias)){
    
    fs <- getData(gs, alias)
    
  }else if(is.null(alias)){
    
    fs <- getData(gs, getNodes(gs)[length(getNodes(gs))])
    
  }
  
  # Merge files for use with estimateLogicle
  fr <- as(fs, "flowFrame")
  fs.m <- flowSet(fr)
  gs.m <- suppressMessages(GatingSet(fs.m))
  
  # Check if fluorescent channels have been transformed
  if(length(gs[[1]]@transformation) == 0){
    
    # Calculate transformation parameters using estimateLogicle
    trans <- estimateLogicle(gs.m[[1]], channels)
    gs <- suppressMessages(transform(gs, trans))
    
  }else if(length(gs[[1]]@transformation) != 0){
    
    # Check which channels have been transformed
    chans <- names(gs@transformation[[1]])
    
    if(all(channels %in% chans)){
      
      # All fluorescent channels have been transformed
      trans <- gs@transformation[[1]]
      
    }else{
      
      # Not all fluorescent channels are transformed - transform remaining channels
      # Which channels need transform? Use appropriate sample to get transform (indx of samples)
      chans <- names(gs@transformation[[1]])
      chans <- channels[is.na(match(channels,chans))]
      
      trns <- gs@transformation[[1]]
      trans <- estimateLogicle(gs.m[[1]], chans)
      gs <- suppressMessages(transform(gs, trans))
      trans <- c(trns,trans)
      
    }
    
  }
  
  }
  # Extract Transformed flowSet for Downstream Analyses
  if(!is.null(alias)){
    
    fs <- getData(gs, alias)
    
  }else if(is.null(alias)){
    
    fs <- getData(gs, getNodes(gs)[length(getNodes(gs))])
    
  }
  
  # Select a fluorescent channel for each compensation control
  if(is.null(cmfile)){
    
    pData(fs)$channel <- paste(selectChannels(fs))
    write.csv(pData(fs), "Compensation Channels.csv", row.names = FALSE)
    
  }else{
    
    pd <- read.csv(cmfile, header = TRUE, row.names = 1)
    pData(fs)$channel <- paste(pd$channel)
    
  }
  
  # Extract unstained control based on selected channels in pData(fs)
  NIL <- fs[[match("Unstained", pData(fs)$channel)]]
  fs <- fs[-match("Unstained", pData(fs)$channel)]
  
  # Assign channel to each flowFrame to description slot called "channel"
  suppressWarnings(sapply(1:length(pData(fs)$channel), function(x){
    
    fs[[x]]@description$channel <- paste(pData(fs)$channel[x])
    
  }))
  
  # Gate positive populations
  pops <- fsApply(fs, function(fr){
    
    # Call drawGate on each flowFrame using interval gate on selected channel
    gt <- drawGate(x = fr, alias = paste(fr@description$channel,"+"), channels = fr@description$channel, gate_type = "interval", adjust = 1.5)
    fr <- Subset(fr, gt[[1]])
    
  }, simplify = TRUE)
  
  # Inverse logicle transformation
  inv <- transformList(names(trans), lapply(trans, `[[`, "inverse"))
  pops <- suppressMessages(transform(pops, inv))
  NIL <- suppressMessages(transform(NIL, inv))
  
  # Calculate MedFI for all channels for unstained control
  neg <- each_col(NIL, median)[channels]
  
  # Calculate MedFI for all channels for all stained controls
  pos <- fsApply(pops, each_col, median)[,channels]
  
  # Subtract background fluorescence
  signal <- sweep(pos, 2, neg)
  
  # Construct spillover matrix - only include values for which there is a control
  spill <- diag(x = 1, nrow = length(channels), ncol = length(channels))  
  colnames(spill) <- channels
  rownames(spill) <- channels
  
  # Normalise each row to stained channel
  for(i in 1:nrow(signal)){
    
    signal[i, ] <- signal[i, ]/signal[i, match(fs[[i]]@description$channel, colnames(spill))]
  
  } 
  
  # Insert values into appropriate rows
  rws <- match(pData(fs)$channel, rownames(spill))
  spill[rws,] <- signal
  
  write.csv(spill, spfile)
  return(spill)
  
})
