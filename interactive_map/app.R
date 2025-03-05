### Shiny App ###

# Setting things up:
## General imports:
library(tidyverse)
library(dplyr)
library(lubridate)
library(scales)

## Shiny imports:
library(shiny)
library(bslib)

## Viz imports:
library(ggplot2)
library(tmap)
library(sf)
library(plotly)

## Loading in our beautiful dataset:
shiny_df <- readRDS("shiny_df.rds")
regional_avg <- readRDS("regional_avg.rds")

### This is for the time series tab as shing_df is an sf_object:
shiny_df_normal <- st_drop_geometry(shiny_df) |>
  mutate(ZCTA5CE10 = as.character(ZCTA5CE10))

## Valid zips:
valid_zips <- unique(shiny_df_normal$ZCTA5CE10)

## Initilaizing map as program is moving too quickly!
tmap_mode("view")

# UI Stuff!
ui <- fluidPage(
  titlePanel("Dallas Real Estate Market Tool"),
    h2(
      "Single-Family Home Prices by Zip Code in Dallas MSA Over Time",
      align = "center"
    ),
  
  ## Initializing a panel:
  tabsetPanel(
    
    ### First Tab - Map!
    tabPanel(
      "Geographic View",
      fluidRow(
        column(
          width = 5,
          wellPanel(
            
            #### Slider input:
            sliderInput(
              "date_slider",
              "Select Month/Year:",
              min = min(shiny_df$Date),
              max = max(shiny_df$Date),
              value = min(shiny_df$Date),
              timeFormat = "%Y-%m",
              step = 31,
              animate = animationOptions(interval = 2000, loop = TRUE)
            ),
            
            #### Horizontal line:
            hr(),
            
            #### Showing summary stats:
            textOutput("price_summary")
          )
        ),
        
        #### Displaying the changing-map:
        column(
          width = 7,
          tmapOutput("price_map", height = "600px")
        )
      )
    ),
    
    ### Second Tab - Time Series
    tabPanel(
      "Prices over Time by Zip",
      
      #### Formatting the row:
      fluidRow(
        column(
          width = 3,
          wellPanel(
            textInput("zip_input", "Enter a Zip Code:", placeholder = "e.g., 75001"),
            actionButton("submit_zip", "View Trends", class = "btn-primary"),
            htmlOutput("zip_validation"),
            br(),
            checkboxInput("show_regional", "Show Dallas MSA Average", value = TRUE),
            br(),
            htmlOutput("zip_info")
          )
        ),
        
        #### Formatting the column:
        column(
          width = 9,
          plotlyOutput("time_series_plot", height = "500px", width = "100%"),
          uiOutput("info_blurb")
        )
      )
    )
  )
)

# Server stuff!
server <- function(input, output, session) {

  ## Creating a function that gives us a date based on selection:
  prices_for_date <- reactive({
    
    ### Getting selected date:
    date_data <- shiny_df |> 
      filter(floor_date(Date, "month") == floor_date(input$date_slider, "month"))
    
    ### Select needed columns
    date_data <- date_data |>
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
        palette = "viridis",
        alpha = 0.7,
        border.col = "black",
        border.alpha = 0.5,
        title = "Housing Prices ($)",
        style = "fixed",
        n = 9,
        breaks = c(0, 300000, 350000, 400000, 450000, 550000, 650000
                   , 800000, 1200000, 2000000),
        labels = c("Under $300k", 
                   "$300k - $350k",
                   "$350k - $400k", 
                   "$400k - $450k",
                   "$450k - $550k",
                   "$550k - $650k",
                   "$650k - $800k",
                   "$800k - $1.2M",
                   "Over $1.2M"),
        popup.vars = c(
          "Zip Code" = "ZCTA5CE10",
          "Average Price" = "Price"
        )
      ) +
      
      ### Layout:
      tm_layout(
        title = paste0(
          "Single-Family Home Prices - ", 
          format(input$date_slider, "%B %Y"),
          if(input$date_slider > as.Date("2024-11-30")) " (Predicted)" else ""
        ),
        title.position = c("center", "top")
      ) +
      
      ### Setting the view & zoom:
      tm_view(
        set_view = c(-96.8, 32.8, 8),
        set_zoom_limits = c(7, 13)
      )
  })
  
  ## Creating a price summary output:
  output$price_summary <- renderText({
    current_data <- prices_for_date()
    
    ### Calculate summary statistics
    mean_price <- round(mean(current_data$Price, na.rm = TRUE), 0)
    median_price <- round(median(current_data$Price, na.rm = TRUE), 0)
    
    ### Information blurb:
    paste0(
      "Summary Statistics for ", format(input$date_slider, "%B %Y"), ":\n",
      if(input$date_slider > as.Date("2024-11-30")) " (Predicted)" else "", ":\n",
      "Average Price: $", format(mean_price, big.mark = ",", scientific = FALSE), "\n",
      "Median Price: $", format(median_price, big.mark = ",", scientific = FALSE)
    )
  })
  
  ## Server code for zip selection:
  selected_zip <- reactiveVal("")
  
  ## Handling zip code submission:
  observeEvent(input$submit_zip, {
    entered_zip <- trimws(input$zip_input)
    if(entered_zip %in% valid_zips) {
      selected_zip(entered_zip)
    }
  })
  
  ## Zip code validation:
  output$zip_validation <- renderUI({
    if(input$submit_zip == 0) return(NULL)
    
    ### Checking if zip code is valid:
    entered_zip <- trimws(input$zip_input)
    if(entered_zip %in% valid_zips) {
      tags$span(icon("check-circle"), "Valid zip code", style = "color: green")
    } else {
      tags$span(icon("exclamation-triangle")
                , "Please enter a valid Dallas MSA zip code"
                , style = "color: red")
    }
  })
  
  ## Time Series Plotting:
  output$time_series_plot <- renderPlotly({
    zip <- selected_zip()
    if(zip == "") {
      return(ggplot() + 
               annotate("text", x = 0.5, y = 0.5, 
                        label = "Enter a valid zip code and click 'View Trends'",
                        size = 5) +
               theme_void())
    }
    
    ## Initializing plotly object:
    p <- plot_ly()
    
    ## Adding zip code plot:
    p <- add_trace(p,
                   data = shiny_df_normal |> filter(ZCTA5CE10 == zip),
                   x = ~Date,
                   y = ~Price,
                   type = 'scatter',
                   mode = 'lines',
                   name = paste("Zip Code", zip),
                   line = list(color = 'blue'))
    
    ## Adding regional average comparison:
    if(input$show_regional) {
      p <- add_trace(p,
                     data = regional_avg,
                     x = ~Date,
                     y = ~Price,
                     type = 'scatter',
                     mode = 'lines',
                     name = "MSA Avg",
                     line = list(color = 'red', dash = 'dot'))
    }

    ## Adding a vline function because plotly is goofy:
    vline <- function(x = 0, color = "grey") {
      list(
        type = "line", 
        y0 = 0, 
        y1 = 1, 
        yref = "paper",
        x0 = x, 
        x1 = x, 
        line = list(color = color, dash = "dash")
      )
    }
    
    ## Adding a vertical line in Nov. 2024:
    p <- layout(p, 
                shapes = list(vline(as.Date("2024-11-30"))),
                annotations = list(
                  list(
                    x = as.Date("2024-10-31"),
                    y = 0.25,
                    yref = "paper",
                    text = "Actual Data Ends"
                  )
                ))
    
    ## Adding information blurb as well as hover details:
    p <- layout(p,
                title = paste("Price Trend for Zip Code", zip),
                xaxis = list(title = "Date"),
                yaxis = list(title = "Home Price ($)",
                             tickformat = "$,"),
                hoverlabel = list(
                  bgcolor = "white",
                  font = list(
                    size = 14,
                    color = "black"
                  ),
                  bordercolor = "gray",
                  width = 400,
                  height = 200
                ),
                hovermode = 'x unified',
                hoverdistance = 100)
    
    # Return plot:
    p <- config(p, displayModeBar = FALSE)
})
  
  ## Time Series summary info:
  output$zip_info <- renderUI({
    zip <- selected_zip()
    if(zip == "") return(NULL)
    
    ### Some callout information:
    zip_data <- shiny_df_normal |>
      filter(ZCTA5CE10 == zip)
    
    ### Hard-coding date because Zillow has a goofy csv and not an API!
    latest <- zip_data |>
      filter(Date == "2024-11-01") |>
      pull(Price)
    
    first <- zip_data |>
      arrange(Date) |>
      slice(1) |>
      pull(Price)
    
    growth <- (latest / first - 1) * 100
    
    ### Formatting for callouts:
    tags$div(
      style = "margin-top: 15px; padding: 10px; background-color: #f8f9fa; border-radius: 5px;",
      tags$h4(paste("Zip Code", zip, "Overview")),
      tags$p(paste0("Current Price: $", format(round(latest), big.mark = ","))),
      tags$p(paste0("Starting Price: $", format(round(first), big.mark = ","))),
      tags$p(paste0("Total Growth: ", round(growth, 1), "%"))
    )
  })
}

# Bringing it all together!
shinyApp(ui = ui, server = server)
