#' Edit Spillover Matrix
#' 
#' Edit spillover matrix using single stain compensation controls and an unstained control.
#' 
#' @param x object of class \code{flowSet} or \code{GatingSet}.
#' 
#' @author Dillon Hammill, \email{Dillon.Hammill@anu.edu.au}
#'
#' @export
setGeneric(name="editSpillover",
           def=function(x, ...){standardGeneric("editSpillover")}
)


#' Edit Spillover Matrix flowSet Method
#' 
#' @param x object of class \code{flowSet}.
#' @param spfile name of spillover matrix csv file including .csv file extension to use as a starting point for editing.
#' 
#' @return write edited spillover matrix to csv file called \code{"Spillover Matrix.csv"} for later use.
#' 
#' @export
setMethod(editSpillover, signature = "flowSet", definition = function(x, spfile = "Spillover Matrix.csv", ...){
  
  require(shiny)
  require(shinythemes)
  require(rhandsontable)
  require(ggcyto)
  
  fs <- x
  nms <- sampleNames(fs)
  channels <- getChannels(fs)
  
  # Read in spillover matrix to object spill
  if(!is.null(spfile)){
    
    spill <- read.csv(spfile, header = TRUE, row.names = 1)
    spill <- as.matrix(spill)
    
  }else{
    
    spill <- fs[[1]]@description$SPILL
    
  }
  colnames(spill) <- channels
  rownames(spill) <- channels
  
  # Rhandsontable does handle decimal points if none are supplied in the dataset - if matrix is empty edit first value in second column to 0.01
  if(all(spill %in% c(0,1))){
    
    spill[1,2] <- 0.0001
    
  }
  
  shinyApp(
    ui <- fluidPage(
      
      theme = shinytheme("yeti"),
      
      titlePanel("Edit Spillover Matrix"),
      
      sidebarPanel(
        selectInput(inputId = "Unstained", label = "Select Unstained Control:", choices = sampleNames(fs)),
        selectInput(inputId = "flowFrame", label = "Select Sample:", choices = sampleNames(fs)),
        selectInput(inputId = "xchannel", label = "X Axis:", choices = channels, selected = channels[1]),
        selectInput(inputId = "ychannel", label = "Y Axis:", choices = channels, selected = channels[2]),
        checkboxInput(inputId = "NIL", label = "Overlay Unstained Control", value = FALSE),
        checkboxInput(inputId = "median", label = "Unstained Control Median", value = TRUE),
        checkboxInput(inputId = "trace", label = "Median Tracker", value = TRUE),
        actionButton("saveBtn", "Save")
      ),
      
      mainPanel(
        rHandsontableOutput("spillover"),
        plotOutput("plot", height = "500px", width = "70%")
      )
    ),
    
    server = function(input, output, session){
      
      values <- reactiveValues()
      
      observe({
        
        if(!is.null(input$spillover)){
          
          spill <- hot_to_r(input$spillover)
          rownames(spill) <- colnames(spill)
          values$spill <- spill
          
        }else{
          
          values$spill <- spill*100
          
        }
        
      })    
      
      
      output$spillover <- renderRHandsontable({
        
        
        rhandsontable(values$spill, rowHeaderWidth = 105, readOnly = FALSE) %>% hot_cols(type = "numeric", colWidths = 105, format = "0.000", halign = "htCenter", renderer = "
                                                                                         function (instance, td, row, col, prop, value, cellProperties) {
                                                                                         Handsontable.renderers.TextRenderer.apply(this, arguments);
                                                                                         if(value < 0 ){
                                                                                         td.style.background = 'lightblue';
                                                                                         } else if (value == 0 ){
                                                                                         td.style.background = 'white';
                                                                                         } else if (value > 0 & value <= 10) {
                                                                                         td.style.background = 'lightgreen';
                                                                                         } else if (value > 10 & value <= 25){
                                                                                         td.style.background = 'yellow';
                                                                                         } else if (value > 25 & value <= 50){
                                                                                         td.style.background = 'orange';
                                                                                         } else if (value > 50 & value < 100){
                                                                                         td.style.background = 'red';
                                                                                         } else if (value == 100){
                                                                                         td.style.background = 'darkgrey';
                                                                                         } else if (value > 100){
                                                                                         td.style.background = 'violet';
                                                                                         }
                                                                                         }") %>% hot_rows(rowHeights = 20)
      
      })
      
      fs.comp <- eventReactive(values$spill, {
        
        gs <- GatingSet(fs)
        gs <- compensate(gs, values$spill/100)
        
        return(gs)
        
      })
      
      
      output$plot <- renderPlot({
        
        p <- ggcyto(fs.comp()[[input$flowFrame]], max_nrow_to_plot = 10000, subset = "root", aes_(x = as.name(input$xchannel), y = as.name(input$ychannel)))
        p <- p + geom_hex(bins = 150)
        
        if(input$NIL == TRUE){
          p <- p + geom_point(data = Subset(getData(fs.comp(),"root")[[input$Unstained]], sampleFilter(size = 10000)), alpha = 0.4,color = "black")
        }
        
        if(input$median == TRUE){      
          
          medians <- fsApply(fs.comp()@data, each_col, median)[input$Unstained,channels]
          MFI <- data.frame("Channel" = channels, "Median" = medians)
          
          cutoff <- MFI[match(input$ychannel, MFI$Channel),]
          
          p <- p + geom_hline(aes(yintercept = Median), color = "red", size = 1.2, data = cutoff)
        }
        
        if(input$trace == TRUE){
          cells <- exprs(getData(fs.comp(),"root")[[input$flowFrame]])
          cells <- cells[order(cells[,input$xchannel]),]
          cells <- as.data.frame(cells)
          
          n <- nrow(cells)
          splt <- seq(1,50,1)
          r <- ceiling(nrow(cells)/50)
          cuts <- splt*r
          cells <- split(cells, cumsum(1:nrow(cells) %in% cuts))
          
          xmedians <- lapply(cells, function(x) median(x[,input$xchannel]))
          ymedians <- lapply(cells, function(x) median(x[,input$ychannel]))
          
          medians <- data.frame(unlist(xmedians), unlist(ymedians))
          colnames(medians) <- c(input$xchannel,input$ychannel)
          
          p <- p + geom_smooth(method = "gam", se = FALSE, mapping = aes_(x = as.name(input$xchannel), y = as.name(input$ychannel)), data = medians, color = "magenta", size = 1.2)
          
        }
        
        # if transformation applied use axis_inverse_trans 0 < range <= 5
        # Ranges
        xrange <- max(exprs(fs.comp()@data[[input$flowFrame]])[,input$xchannel]) - min(exprs(fs.comp()@data[[input$flowFrame]])[,input$xchannel])
        yrange <- max(exprs(fs.comp()@data[[input$flowFrame]])[,input$ychannel]) - min(exprs(fs.comp()@data[[input$flowFrame]])[,input$ychannel])
        
        # X Axis
        if(xrange > 0 & xrange <= 5){
          
          p <- p + axis_x_inverse_trans()
          
        }else{
          
          p <- p + scale_x_logicle(limits = c(min(exprs(fs.comp()@data[[input$flowFrame]])[,input$xchannel]),250000))
          
        }
        
        # Y Axis
        if(yrange > 0 & yrange <= 5){
          
          p <- p + axis_y_inverse_trans()
          
        }else{
          
          p <- p + scale_y_logicle(limits = c(min(exprs(fs.comp()@data[[input$flowFrame]])[,input$ychannel]),250000))
          
        }
        
        p <- p + facet_null()
        p <- p + ggtitle(sampleNames(fs.comp()[[input$flowFrame]]),"\n")
        p <- p + xlab(paste("\n",input$xchannel))
        p <- p + ylab(paste(input$ychannel,"\n"))
        p <- p + editSpillover_theme()
        print(p)
        
      })
      
      observe({
        input$saveBtn
        class(values$spill) <- "numeric"
        spill.mat <- values$spill/100
        write.csv(spill.mat, "Spillover Matrix.csv")
      })
      
    })
  
  
})

#' Edit Spillover Matrix GatingSet Method
#'
#' @param x object of class \code{GatingSet}.
#' @param parent name of the population to use for plotting (defaults to "root").
#' @param spfile name of spillover matrix csv file including .csv file extension to use as a starting point for editing.
#' 
#' @return write edited spillover matrix to csv file called \code{"Spillover Matrix.csv"} for later use.
#' 
#' @export
setMethod(editSpillover, signature = "GatingSet", definition = function(x, parent = "root", spfile = "Spillover Matrix.csv", ...){
  
  require(shiny)
  require(shinythemes)
  require(rhandsontable)
  require(ggcyto)
  
  gs <- x
  nms <- sampleNames(gs)
  channels <- getChannels(gs)
  
  # Extract population for downstream plotting
  fs <- getData(gs, parent)
  
  # Read in spillover matrix to object spill
  if(!is.null(spfile)){
    
    spill <- read.csv(spfile, header = TRUE, row.names = 1)
    spill <- as.matrix(spill)
    
  }else{
    
    spill <- fs[[1]]@description$SPILL
    
  }
  colnames(spill) <- channels
  rownames(spill) <- channels
  
  # Rhandsontable does handle decimal points if none are supplied in the dataset - if matrix is empty edit first value in second column to 0.01
  if(all(spill %in% c(0,1))){
    
    spill[1,2] <- 0.0001
    
  }
  
  shinyApp(
    ui <- fluidPage(
      
      theme = shinytheme("yeti"),
      
      titlePanel("Edit Spillover Matrix"),
      
      sidebarPanel(
        selectInput(inputId = "Unstained", label = "Select Unstained Control:", choices = sampleNames(fs)),
        selectInput(inputId = "flowFrame", label = "Select Sample:", choices = sampleNames(fs)),
        selectInput(inputId = "xchannel", label = "X Axis:", choices = channels, selected = channels[1]),
        selectInput(inputId = "ychannel", label = "Y Axis:", choices = channels, selected = channels[2]),
        checkboxInput(inputId = "NIL", label = "Overlay Unstained Control", value = FALSE),
        checkboxInput(inputId = "median", label = "Unstained Control Median", value = TRUE),
        checkboxInput(inputId = "trace", label = "Median Tracker", value = TRUE),
        actionButton("saveBtn", "Save")
      ),
      
      mainPanel(
        rHandsontableOutput("spillover"),
        plotOutput("plot", height = "500px", width = "70%")
      )
    ),
    
    server = function(input, output, session){
      
      values <- reactiveValues()
      
      observe({
        
        if(!is.null(input$spillover)){
          
          spill <- hot_to_r(input$spillover)
          rownames(spill) <- colnames(spill)
          values$spill <- spill
          
        }else{
          
          values$spill <- spill*100
          
        }
        
      })    
      
      
      output$spillover <- renderRHandsontable({
        
        
        rhandsontable(values$spill, rowHeaderWidth = 105, readOnly = FALSE) %>% hot_cols(type = "numeric", colWidths = 105, format = "0.000", halign = "htCenter", renderer = "
                                                                                         function (instance, td, row, col, prop, value, cellProperties) {
                                                                                         Handsontable.renderers.TextRenderer.apply(this, arguments);
                                                                                         if(value < 0 ){
                                                                                         td.style.background = 'lightblue';
                                                                                         } else if (value == 0 ){
                                                                                         td.style.background = 'white';
                                                                                         } else if (value > 0 & value <= 10) {
                                                                                         td.style.background = 'lightgreen';
                                                                                         } else if (value > 10 & value <= 25){
                                                                                         td.style.background = 'yellow';
                                                                                         } else if (value > 25 & value <= 50){
                                                                                         td.style.background = 'orange';
                                                                                         } else if (value > 50 & value < 100){
                                                                                         td.style.background = 'red';
                                                                                         } else if (value == 100){
                                                                                         td.style.background = 'darkgrey';
                                                                                         } else if (value > 100){
                                                                                         td.style.background = 'violet';
                                                                                         }
                                                                                         }") %>% hot_rows(rowHeights = 20)
      
      })
      
      fs.comp <- eventReactive(values$spill, {
        
        gs <- GatingSet(fs)
        gs <- compensate(gs, values$spill/100)
        
        return(gs)
        
      })
      
      
      output$plot <- renderPlot({
        
        p <- ggcyto(fs.comp()[[input$flowFrame]], max_nrow_to_plot = 10000, subset = "root", aes_(x = as.name(input$xchannel), y = as.name(input$ychannel)))
        p <- p + geom_hex(bins = 150)
        
        if(input$NIL == TRUE){
          p <- p + geom_point(data = Subset(getData(fs.comp(),"root")[[input$Unstained]], sampleFilter(size = 10000)), alpha = 0.4,color = "black")
        }
        
        if(input$median == TRUE){      
          
          medians <- fsApply(fs.comp()@data, each_col, median)[input$Unstained,channels]
          MFI <- data.frame("Channel" = channels, "Median" = medians)
          
          cutoff <- MFI[match(input$ychannel, MFI$Channel),]
          
          p <- p + geom_hline(aes(yintercept = Median), color = "red", size = 1.2, data = cutoff)
        }
        
        if(input$trace == TRUE){
          cells <- exprs(getData(fs.comp(),"root")[[input$flowFrame]])
          cells <- cells[order(cells[,input$xchannel]),]
          cells <- as.data.frame(cells)
          
          n <- nrow(cells)
          splt <- seq(1,50,1)
          r <- ceiling(nrow(cells)/50)
          cuts <- splt*r
          cells <- split(cells, cumsum(1:nrow(cells) %in% cuts))
          
          xmedians <- lapply(cells, function(x) median(x[,input$xchannel]))
          ymedians <- lapply(cells, function(x) median(x[,input$ychannel]))
          
          medians <- data.frame(unlist(xmedians), unlist(ymedians))
          colnames(medians) <- c(input$xchannel,input$ychannel)
          
          p <- p + geom_smooth(method = "gam", se = FALSE, mapping = aes_(x = as.name(input$xchannel), y = as.name(input$ychannel)), data = medians, color = "magenta", size = 1.2)
          
        }
        
        # if transformation applied use axis_inverse_trans 0 < range <= 5
        # Ranges
        xrange <- max(exprs(fs.comp()@data[[input$flowFrame]])[,input$xchannel]) - min(exprs(fs.comp()@data[[input$flowFrame]])[,input$xchannel])
        yrange <- max(exprs(fs.comp()@data[[input$flowFrame]])[,input$ychannel]) - min(exprs(fs.comp()@data[[input$flowFrame]])[,input$ychannel])
        
        # X Axis
        if(xrange > 0 & xrange <= 5){
          
          p <- p + axis_x_inverse_trans()
          
        }else{
          
          p <- p + scale_x_logicle(limits = c(min(exprs(fs.comp()@data[[input$flowFrame]])[,input$xchannel]),250000))
          
        }
        
        # Y Axis
        if(yrange > 0 & yrange <= 5){
          
          p <- p + axis_y_inverse_trans()
          
        }else{
          
          p <- p + scale_y_logicle(limits = c(min(exprs(fs.comp()@data[[input$flowFrame]])[,input$ychannel]),250000))
          
        }
        
        p <- p + facet_null()
        p <- p + ggtitle(sampleNames(fs.comp()[[input$flowFrame]]),"\n")
        p <- p + xlab(paste("\n",input$xchannel))
        p <- p + ylab(paste(input$ychannel,"\n"))
        p <- p + editSpillover_theme()
        print(p)
        
      })
      
      observe({
        input$saveBtn
        class(values$spill) <- "numeric"
        spill.mat <- values$spill/100
        write.csv(spill.mat, "Spillover Matrix.csv")
      })
      
    })
  
  
})