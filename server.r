TRACE = FALSE

WELCOME = TRUE

library(DT)  ## tested on development version 0.1.32
library(shiny)
library(GEOquery)
library(Biobase)
library(reshape2) ## needs to be loaded before GGally
library(survival)
library(affy)
library(limma)
library(shinyBS)
library(GGally)
library(ggplot2)
library(shinyAce)
library(knitr)
library(rmarkdown)
library(RCurl)

source("stripchart2.R")
source("plot.shiny.km.R")

#options(shiny.deprecation.messages=FALSE)

COUNTER = 1

shinyServer(function(input, output, session){
  
  
  source("server-reactives.R", local = TRUE)
  source("server-output.R", local = TRUE)
  source("formatDE.R", local = TRUE)
  observe({
    
    if (is.null(input$tabs)) {
      cat("\ntoggle #", COUNTER, "\n\n")
      toggleModal(session, "welcomeModal", toggle = "open")
    }
    COUNTER = COUNTER + 1
    
    
      if (is.null(input$tabs) | input$tabs!= "Differential Expression Analysis") {
        return(NULL)
      }

      PLOT = TRUE
      
      if (input$selectProbes == "") {
        cat("\n\n=====NO GENE=====\n\n")
        output$selectGroupsMessage <-renderUI({HTML("<h3>Please Select a Gene and Probe to Analyze</h3>")})
        createAlert(session, "alert2", alertId = "Gene-alert", 
                    title = "Please select a gene and probe to continue", 
                    style = "danger",
                    content = "", append = TRUE,
                    dismiss = FALSE) 
        PLOT = FALSE
      }    
      else {
        closeAlert(session, "Gene-alert")
          if (length(input$Group1Values) == 0) {
            output$selectGroupsMessage <-renderUI({
              HTML("<h3>Please Choose The Groups to Compare</h3>")}
            )
            PLOT = FALSE
          }
      }
      
      if (!PLOT) {
              output$plot <-renderPlot({NULL})
      } else  {
          output$selectGroupsMessage <-renderText({""})
          output$plot <- renderPlot({
              x = profiles()[selectedProbe(),] # effected by data transformation
              iv = input$selectedColumn
              m = match(as.character(iv), colnames(clinicalInput()))  # GD: change grep to match
              clinical = as.character(clinicalInput()[,m])  # clinicalInput() should be the new edited table once fixed
              selected = c(as.character(input$Group1Values))
              k = clinical%in% selected
    
              y = clinical
              y[!k] = NA
              
              ## make sure levels are in selected order for plot
              y = factor(y, levels = input$Group1Values)
              
              main = paste(input$GSE, input$selectGenes, input$selectProbes, sep = "/")
              #gd              
              #stripchart2(x,y, col = colorsDE(), group.names = labelsDE(), main = main, ylab = "log2 expression")
              #jd
              print(stripchart2(x,y, group.names = labelsDE(), main = main, col=colorsDE()))
             
              }) # end of plot reactive
          
    }
  })  # end observe
  
  observe({
    if (!(input$parseEnter)) {  
      output$SurvMessage <-renderUI({HTML("<h3>Please Choose The Columns for Survival Analysis</h3>")})
      output$kmSurvival <-renderPlot({NULL})
    } else  {
      output$SurvMessage <-renderText({""})
      output$kmSurvival <- renderPlot({

      time = as.double(parse.modal()[,1])
      outcome = as.integer(parse.modal()[,2])
      x = x()
        
      save(time, outcome, x, file = "check.RData")
        
        
      return(plot.shiny.km(time = as.double(parse.modal()[,1]), 
                           death = as.integer(parse.modal()[,2]), 
                           x = x(), 
                           col = colorsDE3()))
 
      })
    }
  }) # end of second observe
  
})
