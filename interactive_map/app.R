### Shiny App ###

# Setting things up:
## General imports:
library(tidyverse)
library(dplyr)
library(lubridate)
library(pryr)

## Shiny imports:
library(shiny)
library(bslib)

## Viz imports:
library(ggplot2)
library(tmap)
library(sf)

## Loading in our beautiful dataset:
shiny_df <- readRDS("shiny_df.rds")

## Initilaizing map as program is moving too quickly!
tmap_mode("view")

# UI Stuff!
ui <- fluidPage(
  titlePanel(
    h1("Single-Family Home Prices by Zip Code in Dallas MSA Over Time"
             , align = "center")),
  
  ## Creating a row with a slider on the left & a map on the right:
  fluidRow(
    column(
      width = 4,
      wellPanel(
        
        ### Slider input:
        sliderInput(
          "date_slider",
          "Select Month/Year:",
          min = min(shiny_df$Date),
          max = max(shiny_df$Date),
          value = min(shiny_df$Date),
          timeFormat = "%Y-%m",
          step = 31,
          animate = animationOptions(interval = 3000, loop = TRUE)
        ),
        
        ### Horizontal line:
        hr(),
        
        ### Showing summary stats:
        textOutput("price_summary") 
      )
    ),
    
    ## Displaying the changing-map:
    column(
      width = 8,
      tmapOutput("price_map", height = "800px")
    )
  )
)

# Server stuff!
server <- function(input, output, session) {

  ## Creating a function that gives us a date based on selection:
  prices_for_date <- reactive({
    
    ### Getting selected date:
    date_data <- shiny_df |> 
      filter(floor_date(Date, "month") == floor_date(input$date_slider, "month")) |> 
      select(ZCTA5CE10, Price, geometry)
    
    ### Returning filtered spatial data frame
    return(date_data)
  })

  ## Creating the map output:
  output$price_map <- renderTmap({
    
    ### Fetching reactive data with the spatial information:
    current_data <- prices_for_date()
    
    ### Data Viz:
    tm_basemap("OpenStreetMap") +
    tm_shape(current_data) +
      
      ### Formatting & data stuff:
      tm_polygons(
        col = "Price",
        palette = "inferno",
        alpha = 0.5,
        border.col = "black",
        border.alpha = 0.5,
        title = "Housing Prices ($)",
        style = "jenks",
        n = 8,
        breaks = c(0, 300000, 400000, 500000, 600000, 
                   750000, 1000000, 1500000, 2000000),
        labels = c("Under $300k", 
                   "$300k - $400k",
                   "$400k - $500k", 
                   "$500k - $600k",
                   "$600k - $750k",
                   "$750k - $1M",
                   "$1M - $1.5M",
                   "Over $1.5M"),
        popup.vars = c(
          "Zip Code" = "ZCTA5CE10",
          "Average Price" = "Price"
        )
      ) +
      
      ### Layout:
      tm_layout(
        title = paste("Single-Family Home Prices -", 
                      format(input$date_slider, "%B %Y")),
        title.position = c("center", "top")
      ) +
      
      ### Setting the view & zoom:
      tm_view(
        set_view = c(-96.8, 32.8, 8.5),
        set_zoom_limits = c(7, 13)
      )
  })
  
  ## Creating a price summary output:
  ## Creating a price summary output:
  output$price_summary <- renderText({
    current_data <- prices_for_date()
    
    ### Calculate summary statistics
    mean_price <- round(mean(current_data$Price, na.rm = TRUE), 0)
    median_price <- round(median(current_data$Price, na.rm = TRUE), 0)
    
    ### Information blurb:
    paste0(
      "Summary Statistics for ", format(input$date_slider, "%B %Y"), ":\n",
      "Average Price: $", format(mean_price, big.mark = ",", scientific = FALSE), "\n",
      "Median Price: $", format(median_price, big.mark = ",", scientific = FALSE)
    )
  })
}

# Bringing it all together!
shinyApp(ui = ui, server = server)
