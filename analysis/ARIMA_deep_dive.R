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

### Increasing DPI so it doesn't look like the 90s:
options(repr.plot.res = 200)

### Loading in data:
dallas_housing_long <- readRDS("data/processed_dfs/dallas_housing_long.rds")
dallas_forecast_simple <- readRDS("data/processed_dfs/dallas_forecast_simple.rds")

### Creating dataframe that has predicted & actual vals:
#### Predicted df:
predicted_df <- dallas_forecast_simple |> 
  filter(Date <= yearmonth("2025-01")) |>
  rename(Prediction = Price)

#### Actual vals:
actual_df <- dallas_housing_long |>
  filter(Date > '2024-11-30') |>
  select(RegionName, Date, Price) |>

  ##### Converting the date to year-month format:
  mutate(Date = yearmonth(Date))

#### Joining them:
comparision_df <- inner_join(predicted_df, actual_df, by = c("RegionName", "Date")) |>
 
  #### Rounding:
  mutate(Price = round(Price, 0)) |>
  mutate(Prediction = round(Prediction, 0)) |>
  
  #### Creating Residual column:
  mutate(Residual = Price - Prediction)

# Understanding if ARIMA is a good predictor!
## First we'll calculate some errors:
### Mean Absolute Error:
arima_mae <- mean(abs(comparision_df$Residual))

### Mean Squared Error:
arima_mse <- mean((comparision_df$Residual)^2)

### Root Mean Squared Error:
arima_rmse <- sqrt(arima_mse)

### Mean Absolute Percentage Error:
arima_mape <- mean(abs((comparision_df$Residual)
                       /comparision_df$Price)) * 100

### Creating a well-formatted output:
metrics_text <- paste0(
  "MAE: $", format(round(arima_mae, 2), big.mark = ","), "\n",
  "RMSE: $", format(round(arima_rmse, 2), big.mark = ","), "\n",
  "MAPE: ", format(round(arima_mape, 2), nsmall = 2), "%"
)

## Plotting:
## Residual vs. Fitted Plot:
p <- ggplot(comparision_df, aes(x = Prediction, y = Residual)) +
  geom_point(alpha = 0.5) +  
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "blue") +
  labs(title = "Residuals vs. Predicted Values",
       x = "Predicted Price",
       y = "Residual") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5)) +
  annotate("text", x = min(comparision_df$Prediction), 
           y = min(comparision_df$Residual) * 0.9, 
           label = metrics_text, 
           hjust = 0, size = 4, color = "black")
