# Loading necessary libraries
library(data.table)
library(dplyr)
library(ggplot2)
library(purrr)

# Load and prepare data using data.table 41049 station
# Change station and year for differen test
data <- fread("Desktop/#41049/2023_41049.txt")
setnames(data, "#YY", "YY")
data <- data[WVHT != "99.00", ]
data[, WVHT := as.numeric(WVHT)]
data[, datetime := as.POSIXct(paste(YY, MM, DD, hh, mm), format = "%Y %m %d %H %M")]
data <- data[!is.na(datetime), ]

# Convert to tibble for easier manipulation with dplyr
data <- as_tibble(data)

# Define periods and calculate maxima
period_lengths <- c(24, 48, 72)  # Hours

calculate_maxima <- function(df, hours) {
  period_seconds <- hours * 3600
  df %>%
    group_by(month_id = format(datetime, "%Y-%m"),
             segment = floor(as.numeric(difftime(datetime, min(datetime), units = "secs")) / period_seconds) + 1) %>%
    summarise(max_wave_height = max(WVHT, na.rm = TRUE), .groups = 'drop') %>%
    arrange(month_id, segment)
}

results <- lapply(period_lengths, function(p) {
  calculate_maxima(data, p)
})

names(results) <- paste("maxima", period_lengths, "h", sep = "_")

data_72 <- results$maxima_72_h  
data_48 <- results$maxima_48_h 
data_24 <- results$maxima_24_h 

# Applying the Ljung-Box test to each monthly group
lb_results_72 <- data_72 %>%
  group_by(month_id) %>%
  do({
    model <- lm(max_wave_height ~ seq_along(max_wave_height), data = .)
    residuals <- residuals(model)
    lb_test <- Box.test(residuals, type = "Ljung-Box")
    data.frame(Q_statistic = lb_test$statistic, p_value = lb_test$p.value)
  })

lb_results_48 <- data_48 %>%
  group_by(month_id) %>%
  do({
    model <- lm(max_wave_height ~ seq_along(max_wave_height), data = .)
    residuals <- residuals(model)
    lb_test <- Box.test(residuals, type = "Ljung-Box")
    data.frame(Q_statistic = lb_test$statistic, p_value = lb_test$p.value)
  })

lb_results_24 <- data_24 %>%
  group_by(month_id) %>%
  do({
    model <- lm(max_wave_height ~ seq_along(max_wave_height), data = .)
    residuals <- residuals(model)
    lb_test <- Box.test(residuals, type = "Ljung-Box")
    data.frame(Q_statistic = lb_test$statistic, p_value = lb_test$p.value)
  })

# Review the results
print(lb_results_72)
print(lb_results_48)
print(lb_results_24)





