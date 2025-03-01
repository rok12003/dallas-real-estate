### ARIMA Analysis ###

# Setting things up:
## Library imports:
### General imports:
library(tidyverse)
library(dplyr)

### ARIMA imports:
library(tsibble)
library(zoo)
library(urca)
library(feasts)

### Loading in data:
dallas_housing_long <- readRDS("data/processed_dfs/dallas_housing_long.rds")
dallas_forecast_simple <- readRDS("data/processed_dfs/dallas_forecast_simple.rds")

# Seeing if Dec 2024/Jan 2025 (predicted) actually hold up to Dec 2024/Jan 2025 (actual)
## Initializing the validation df:
validation_df <- dallas_forecast_simple |> 
  filter(Date <= yearmonth("2025-01")) |>
  rename(Prediction = Price)

## Reading in just the columns w/ Dec 2024 & Jan 2025 data:
actual_vals <- dallas_housing_long |>
  filter(Date > '2024-11-30') |>
  select(RegionName, Date, Price) |>
  
  #### Converting the date to year-month format:
  mutate(Date = yearmonth(Date))

### Joining validation_df to actual_vals:
validation_df <- inner_join(validation_df, actual_vals, by = c(
  "RegionName", "Date"))

### Creating a column that calculates the difference between predicted & actual:
validation_df <- validation_df |> 
  mutate(diff = Prediction - Price) |> 
  arrange(desc(diff)) 

### HOLY SHIT--only an average of $363 difference between ARIMA & actual price
### Linear model kinda goated ngl. 

# Look at distribution
# Does it vary greatly by zip code? 
# How's it working under the hood?
