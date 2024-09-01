# Load necessary libraries
library(readr)
library(dplyr)
library(stats)
library(GenSA)

# Load the data from the CSV file
data <- read_csv("data_41043.csv")

# Convert the `period_start` column to Date format
data <- data %>% mutate(period_start = as.Date(period_start))

# Calculate the min and max date
min_date <- min(data$period_start)
max_date <- max(data$period_start)

# Calculate the total number of days between the min and max date
total_days <- as.numeric(difftime(max_date, min_date, units = "days"))

# Create the `scaled_time` column
data <- data %>% mutate(scaled_time = as.numeric(difftime(period_start, min_date, units = "days")) / total_days * 10)

# View the updated dataframe
print(data)

# Extract the fractional part of scaled_time
data$frac_scaled_time <- data$scaled_time %% 1

# Define the function u(t; a, b)
u <- function(t, a, b) {
  a + b * cos(2 * pi * t)
}

# Define the function to minimize
h <- function(params, q = 0.05, data) {
  a <- params[1]
  b <- params[2]
  
  # Split the data into summer and winter periods based on the fractional part
  summer_data <- subset(data, frac_scaled_time >= 0.25 & frac_scaled_time <= 0.75)
  winter_data <- subset(data, frac_scaled_time < 0.25 | frac_scaled_time > 0.75)
  
  # Calculate the thresholds for summer and winter
  p_s <- mean(summer_data$max_WHT > u(summer_data$frac_scaled_time, a, b))
  p_w <- mean(winter_data$max_WHT > u(winter_data$frac_scaled_time, a, b))
  
  # Objective function to minimize
  max((p_s - q)^2, (p_w - q)^2)
}

# Initial guess for a and b
start <- c(a = 0, b = 1)

# Define the lower and upper bounds for a and b
lower <- c(-10, -10)
upper <- c(10, 10)

# Optimize the function using Generalized Simulated Annealing
fit <- GenSA(par = start, fn = h, lower = lower, upper = upper, data = data)

# Extract the optimized parameters
a_opt <- fit$par[1]
b_opt <- fit$par[2]

# Print the optimized parameters
cat("Optimized a:", a_opt, "\n")
cat("Optimized b:", b_opt, "\n")

# Calculate the threshold u(t; a, b) for a given range of t
t_values <- seq(0, 1, length.out = 100)
u_values <- u(t_values, a_opt, b_opt)

# Plot the threshold u(t; a, b)
plot(t_values, u_values, type = "l", col = "blue", xlab = "Fractional Scaled Time (years)", ylab = "Threshold u(t; a, b)",
     main = "Time-varying Threshold with Constant Rate q = 0.05")

## Data over threshold
# Calculate the threshold u(t; a, b) for each row in the dataset
# Calculate the threshold u(t; a, b) for each row in the dataset
data$threshold <- u(data$frac_scaled_time, a_opt, b_opt)

# Create a new column indicating if max_WHT exceeds the threshold
data$amount_over_threshold <- data$max_WHT - data$threshold

# Set negative values in amount_over_threshold to 0
data$amount_over_threshold[data$amount_over_threshold < 0] <- 0

# Save the updated dataset to a new CSV file
write.csv(data, "data_41049.csv", row.names = FALSE)

# Print the first few rows of the updated dataset
head(data)
