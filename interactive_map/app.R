### Shiny App ###

# Setting things up:
## Shiny imports:
library(shiny)
library(bslib)

## Viz imports:

## Loading in dataframes from ts analysis:
load("data/validation_data.RData")
dallas_ts <- readRDS("data/dallas_ts.rds")

# ui.R
ui

# server.R
server

# Bringing it all together
shinyApp(ui = ui, server = server)