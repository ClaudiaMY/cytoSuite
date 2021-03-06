#' Interactive Plots of Flow Cytometry Data.
#'
#' \code{drawPlot} opens an interactive plotting window and constructs either a 1-dimensional (1D) density plot or
#' a 2-dimensional (2D) plot based on teh number of channels supplied.
#' 
#' @param fr a \code{flowFrame} object containing the flow cytometry data for plotting and gating.
#' @param channels a vector indicating the fluorescent channel(s) to be used for gating. If a single channel is supplied, a histogram of
#' of the kernel density will be constructed.
#' @param subSample numeric indicating the number of events to display in 2D plots. 
#' @param cex numeric passed to plotDens to alter the point size (defaults to 3).
#' @param adjust numeric smoothing factor used for 1D density plots (defaults to 1.5).
#' @param ... additional arguments for plotDens.
#'
#' @return \code{NULL}
#'
#' @keywords manual, gating, draw, openCyto, gates, plot, density, flow cytometry
#' @importFrom flowDensity plotDens
#' @importFrom flowCore exprs
#' @export
#'
#' @author Dillon Hammill (Dillon.Hammill@anu.edu.au)
drawPlot <- function(fr, channels, subSample = NULL, cex = 3, adjust = 1.5, ...){
  
  # Check supplied channel(s) are valid
  checkChannels(fr, channels)
  
  # Open new plotting window
  checkOSGD()
  
  # 1D Density Plot if length(channels) == 1
  if(length(channels) == 1){
    
    # Calculate Kernel Density
    d <- density(flowCore::exprs(fr)[,channels], adjust = adjust)
    
    # Plot Kernel Density - channel as plot title
    plot(d, main=paste(channels), col.main = "red")
    polygon(d, col="dodgerblue", border="black", lwd = 1)
    
  }else if(length(channels) == 2){
    
    # subSample fr to speed up plotting
    if(is.null(subSample)){
      
    # 2D Plot using flowDensity::plotDens
    flowDensity::plotDens(fr, channels = channels, cex = cex, ...)  
      
    }else{
      
      # Restrict fr to # of subSample events
      fr <- sampleFrame(fr, size = subSample)
      
      # 2D Plot using flowDensity::plotDens
      flowDensity::plotDens(fr, channels = channels, cex = 3, ...)  
      
    }
    
  }
  
}

#' Label Plots with Population Name and Frequency.
#'
#' \code{plotLabels} takes on a \code{flowFrame} object, population name \code{alias}, \code{channels} and a gate object to construct
#' a text label for the plot with the population name and frequency.
#' 
#' @param fr a \code{flowFrame} object containing the flow cytometry data for plotting and gating.
#' @param channels a vector indicating the fluorescent channel(s) to be used for gating.
#' @param alias the name of the gated population.
#' @param gate an object of class \code{polygonGate}, \code{rectangleGate} or \code{ellipsoidGate}.
#' @param ... additional arguments for plotDens.
#'
#' @return add text box label to existing plot with population name and frequency.
#'
#' @keywords manual, gating, draw, openCyto, gates, drawPlot, flow cytometry, labels
#' @importFrom plotrix boxed.labels
#' @importFrom flowCore Subset
#' @export
#'
#' @author Dillon Hammill (Dillon.Hammill@anu.edu.au)
plotLabels <- function(fr, channels, alias, gate){
  
  # Total events
  events <- nrow(fr)
  
  # Population events
  pop <- nrow(flowCore::Subset(fr, gate))
  
  # Population frequency
  freq <- round(pop/events,4)
  freq <- sprintf("%.2f %%",100*freq)
  
  # Center of gate
  if(class(gate) == "polygonGate"){
    
    center <- c((sum(gate@boundaries[,1])/nrow(gate@boundaries)),(sum(gate@boundaries[,2])/nrow(gate@boundaries)))
  
  }else if(class(gate) == "rectangleGate"){
    
    xmin <- gate@min[1]
    ymin <- gate@min[2]
    xmax <- gate@max[1]
    ymax <- gate@max[2]
    
    if(is.infinite(xmin)){
      
      xmin <- par("usr")[1]
      
    }
    
    if(is.infinite(ymin)){
      
      ymin <- par("usr")[3]
      
    }
    
    if(is.infinite(xmax)){
      
      xmax <- par("usr")[2]
      
    }
    
    if(is.infinite(ymax)){
      
      ymax <- par("usr")[4]
      
    }
    
    if(length(gate@max) == 1){
      
      ymin <- par("usr")[3]
      ymax <- par("usr")[4]
      
      center <- c((sum(xmin,xmax)/2),(sum(ymin,ymax)/2))
      
    }else{
  
    center <- c((sum(xmin,xmax)/2),(sum(ymin,ymax)/2))
    
    }
    
  }else if(class(gate) == "ellipsoidGate"){
    
    center <- gate@mean
  
  }
  
  # Add text annotation to plot with population name & frequency
  plotrix::boxed.labels(x = center[1], y = center[2], labels = paste(alias,freq, sep = "\n"), border = FALSE, font = 2)
}

#' Compensation Plots
#' 
#' @param fs object of class \code{flowSet} containing gated compensation controls and an unstained control.
#' @param pdfile \code{pData} csv file containing additional column \code{"channel"} indicating the fluorescent channel associated
#' with each sample. This channel should be set to \code{"Unstained"} for unstained controls.
#' @param subSample numeric indicating the number of events to plot, set to 2500 events by default to increase plotting speed.
#' @return plot grid with associated channel against all other channels for each compensation control.
#' 
#' @export
drawCompPlots <- function(fs, pdfile = NULL, subSample = 2500, title = "Compensated"){
  
  if(is.na(match("Original",colnames(fs[[1]]))) == FALSE){
    
    fs <- fsApply(fs,function(fr){
      
      fr <- fr[,-match("Original",colnames(fs[[1]]))]
      
    },simplify=TRUE)
    
  }else if(is.na(match("Original",colnames(fs[[1]]))) == TRUE){
    
  }
  
  if(!is.null(pdfile)){
    
    pd <- read.csv(pdfile)
    
    for(i in 1:length(fs)){
      
      pData(fs)$channel <- pd$channel
      fs[[i]]@description$channel <- paste(pd$channel[i])
    }
  
  }else{
    
    chans <- selectChannels(fs)
    pData(fs)$channel <- chans
    
    pd <- pData(fs)$channel
    
    for(i in 1:length(fs)){
      
      fs[[i]]@description$channel <- paste(pd[i])
    
      }
  }
  
  fluor.channels <- getChannels(fs)
  
  # Extract unstained control if present
  if("Unstained" %in% pData(fs)$channel){
    
    NIL <- fs[[match("Unstained", pData(fs)$channel)]]
      
  }
  
  plots <- fsApply(fs[-match("Unstained", pData(fs)$channel)], function(fr){
    
    objs <- lapply(fluor.channels[-(match(fr@description$channel,fluor.channels))], function(y){
      
      p <- autoplot(Subset(fr, sampleFilter(size = subSample)), fr@description$channel, y, bins = 100)
      
      if("Unstained" %in% pData(fs)$channel){
        
        p <- p + geom_point(data = Subset(NIL, sampleFilter(size = subSample)), alpha = 0.4, color = "black", size = 0.2)
        
      }
      
      p <- p + labs_cyto("channel")
      
      p <- p + theme(legend.position="none", strip.background = element_blank(),strip.text.x = element_blank(),plot.title = element_text(size = 8,hjust = 0.5))
      
      p <- p + scale_x_logicle(limits = c(-250000,250000)) + scale_y_logicle(limits = c(-250000,250000))
      
      p <- p + ggtitle(paste(fr@description$channel,title))
      
      p <- p + facet_null()
      
      as.ggplot(p)
      
    })
    
    gridExtra::grid.arrange(grobs = objs, nrow = 4)
    
  },simplify = FALSE)
  
}

#' Plot gates stored in filters list on an existing plot.
#' 
#' @param gates an object of class \code{filters} containing the gate(s) for plotting.
#' @param col indicates the colour of the gate to be constructed, set to \code{"red"} by default.
#' 
#' @export
plotGates <- function(gates, col = "red"){
  
    for(i in 1:length(gates)){
    
    if(class(gates[[i]]) == "rectangleGate" ){
      
      if(length(gates[[i]]@min) == 2){
      
      # Replace -Inf x values for plotting
      if(is.infinite(gates[[i]]@min[1])){
        
        gates[[i]]@min[1] <- par("usr")[1]
        
      }
      
      # Replace Inf x values for plotting
      if(is.infinite(gates[[i]]@max[1])){
        
        gates[[i]]@max[1] <- par("usr")[2]
        
      }
      
      # Replace -Inf y values for plotting
      if(is.infinite(gates[[i]]@min[2])){
        
        gates[[i]]@min[2] <- par("usr")[3]
        
      }
      
      # Replace Inf y values for plotting
      if(is.infinite(gates[[i]]@max[2])){
        
        gates[[i]]@max[2] <- par("usr")[4]
        
      }
      
      points(x = c(gates[[i]]@min[1],gates[[i]]@max[1]), y = c(gates[[i]]@min[2],gates[[i]]@max[2]), col = col, pch = 16)
      rect(xleft = gates[[i]]@min[1], ybottom = gates[[i]]@min[2], xright = gates[[i]]@max[1], ytop = gates[[i]]@max[2], border = col, lwd = 2.5)
     
      }else if(length(gates[[i]]@min) == 1){
       
      # Replace -Inf values for plotting
      if(is.infinite(gates[[i]]@min[1])){
        
        gates[[i]]@min[1] <- par("usr")[1]
        
      }
      
      # Replace Inf values for plotting
      if(is.infinite(gates[[i]]@max[1])){
        
        gates[[i]]@max[1] <- par("usr")[2]
        
      }
      
      # height of horizontal line
      hln <- 0.5*par("usr")[4]
      
      # Add points (x1,hln) and (x2, hln)
      points(x = c(gates[[i]]@min[1],gates[[i]]@max[1]), y = c(hln,hln), col = col, pch = 16)
      
      # Add vertical lines through x1 and x2
      abline(v = c(gates[[i]]@min[1], gates[[i]]@max[1]), lwd = 2.5, col = col)
      
      # Add horizontal line
      lines(x = c(gates[[i]]@min[1], gates[[i]]@max[1]), y = c(hln,hln), col = col, lwd = 2.5)
      
      }
      
    }else if(class(gates[[i]]) == "polygonGate"){
      
      points(x = c(gates[[i]]@boundaries[,1]), y = c(gates[[i]]@boundaries[,2]), pch = 16, col = col)
      polygon(gates[[i]]@boundaries[,1], gates[[i]]@boundaries[,2], border = col, lwd = 2.5)
      
    }else if(class(gates[[i]]) == "ellipsoidGate"){
      
      gates[[i]] <- as(gates[[i]], "polygonGate")
      points(x = c(gates[[i]]@boundaries[,1]), y = c(gates[[i]]@boundaries[,2]), pch = 16, col = col)
      polygon(gates[[i]]@boundaries[,1], gates[[i]]@boundaries[,2], border = col, lwd = 2.5)
      
    }
    
  }
  
}