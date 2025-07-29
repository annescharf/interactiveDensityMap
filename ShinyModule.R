library(shiny)
library(move2)
library(sf)
library(terra)
library(viridis)
library(mapview)
library(leaflet)
library(leaflegend)
library(shinycssloaders)
library(webshot)
# webshot::install_phantomjs() ## add in docker images in moveapps: R -e 'webshot::install_phantomjs()' 

# data <- readRDS("./data/raw/input2_move2loc_LatLon.rds")


shinyModuleUserInterface <- function(id, label) {
  ns <- NS(id)
  
  tagList(
    titlePanel("Interactive Density Map"),
    fluidPage(
      fluidRow(class = "myRow1"), #we give a tag to the row to add a style below
      sidebarLayout(
        
        sidebarPanel(verticalLayout(
          selectInput(inputId = ns("var"), 
                      label = "Variable to rasterize", 
                      choices = list( "N. of GPS locations" = "n_locations", 
                                      "N. of individuals" = "n_individuals", 
                                      "N. of species" = "n_species", 
                                      "N. of Movebank studies" = "n_studies"),
                      selected = "n_locations"),
          
          sliderInput(inputId = ns("pxSize"), 
                      label = "Raster pixel size (Km)", 
                      value = 100, min = 1, max = 500), # range in deg, from about 1 km to 500 km
          
          checkboxInput(inputId = ns("reverse"), 
                        label = "Reverse color palette", 
                        value = FALSE), #by default false
        ), width = 2),
        
        mainPanel(withSpinner(leafletOutput(ns("leafmap"), height="82vh"),type=6, size=2),
                  #actionButton(ns('savePlot'), 'Save Plot'), #for artefact in output
                  downloadButton(ns('savePlot'), 'Save Plot'), # for downloading map on local computer
                  width = 10)
      ), tags$head(tags$style(".myRow1{height:25px;background-color: white;}"))
    )
  )
}

shinyModule <- function(input, output, session, data) {
  current <- reactiveVal(data) 
  
  rmap <- reactive({
    
    
    merc_pr <- "EPSG:3857"
    
    data_red <- mt_as_event_attribute(data, c("taxon_canonical_name", "study_id"))
    data_red$track_id <- mt_track_id(data_red)
    data_red$locs <- 1
    data_red <- dplyr::select(data_red, taxon_canonical_name, study_id, track_id, locs)
    data_red_p <- st_transform(data_red,merc_pr)
    vec_data_red <- vect(data_red_p)
   
    
    rr <- rast(extent = st_bbox(data_red_p),resolution = input$pxSize*1000, crs = merc_pr) 
  
    if(input$var=="n_locations"){
      vec_r <- rasterize(vec_data_red, rr,field="locs", fun="length", update=T)
      legendTitle <- "N. of GPS locations"
    }else if(input$var=="n_individuals"){
      vec_r <- rasterize(vec_data_red, rr, field="track_id", fun=function(x, ...){length(unique(na.omit(x)))}, update=TRUE)
      legendTitle <- "N. of individuals"
    }else if(input$var=="n_species"){
      vec_r <- rasterize(vec_data_red, rr, field="taxon_canonical_name", fun=function(x, ...){length(unique(na.omit(x)))}, update=TRUE)
      legendTitle <- "N. of species"
    } else if(input$var=="n_studies"){
      vec_r <- rasterize(vec_data_red, rr, field="study_id", fun=function(x, ...){length(unique(na.omit(x)))}, update=TRUE)
      legendTitle <- "N. of Movebank studies"
    }
    # bounds <- as.vector(bbox(extent(data_red_p)))

    if(max(values(vec_r), na.rm=T) <= 7){
      myBins <- length(1:max(values(vec_r), na.rm=T))
    }else{myBins <- 7}
    
    brewCol <- viridis(7)
    if(myBins == 7){
      rPal <- colorBin(brewCol, 1:max(values(vec_r), na.rm=T), reverse = input$reverse,
                       na.color = "transparent", bins=myBins)
    }else{
      rPal <- colorFactor(brewCol[1:myBins], as.factor(1:max(values(vec_r), na.rm=T)), reverse = input$reverse, 
                          na.color = "transparent")
    }
    
    outl <- leaflet() %>% 
      # fitBounds(bounds[1], bounds[2], bounds[3], bounds[4]) %>%
      addTiles() %>%
      addProviderTiles("Esri.WorldTopoMap", group = "TopoMap") %>%
      addProviderTiles("Esri.WorldImagery", group = "Aerial") %>%
      addRasterImage(vec_r, colors = rPal, opacity = 0.7, project = FALSE, group = "raster") %>%
      addScaleBar(position="bottomright",
                  options=scaleBarOptions(maxWidth = 100, metric = TRUE, imperial = FALSE, updateWhenIdle = TRUE)) %>%
      addLayersControl(
        baseGroups = c("TopoMap","Aerial"),
        overlayGroups = "raster",
        options = layersControlOptions(collapsed = FALSE)) #%>%
    # addLegend(position="topright", opacity = 0.6,
    #              pal = rPal, values = values(vec_r), title = legendTitle)
    
    if(input$var=="n_locations"){
      outl <- outl %>%
        addLegend(position="topright", opacity = 0.6, #bins = myBins, 
                  pal = rPal, values = 1:max(values(vec_r), na.rm=T), title = legendTitle)
    }else{
      outl <- outl %>%
        addLegend(position="topright", opacity = 0.6, 
                  pal = rPal, values = as.factor(1:max(values(vec_r), na.rm=T)), title = legendTitle)
    }
    
    outl   
  })
  
  
  output$leafmap <- renderLeaflet({
    rmap()  
  })  
  
  ## save plot to moveapps output folder to be able to link it with API.
  ## This would be the best option but in moveapps it does not work at the moment.
  ## once shiny can save settings on moveapps, figure out how to save automatically, without hitting the save plot button
  # observeEvent("savePlot", {
  #   mymap <- rmap()
  #   mapshot( x = mymap
  #            , remove_controls = c("zoomControl","layersControl")
  #            , file = paste0(Sys.getenv(x = "APP_ARTIFACTS_DIR", "/tmp/"),"DensityMap.png")
  #            , cliprect = "viewport"
  #            , selfcontained = FALSE)
  # })
  
  ### save map, takes some seconds ### here user can choose directory
  output$savePlot <- downloadHandler(
    filename = "Leaflet_densityMap.png",
    content = function(file) {
      leafmap <- rmap()
      mapshot( x = leafmap
               , remove_controls = c("zoomControl","layersControl")
               , file = file
               , cliprect = "viewport"
               , selfcontained = FALSE
               , zoom = 1.5
               , vwidth = 992*2, vheight = 744*2 #default size * 1.1
      ) 
    }
  )
  
  return(reactive({ current() }))
}


