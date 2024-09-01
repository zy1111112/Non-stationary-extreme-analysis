# Loading necessary libraries
library(data.table)
library(dplyr)
library(ggplot2)
library(purrr)

calculate_maxima <- function(df, hours) {
  period_seconds <- hours * 3600
  df %>%
    group_by(month_id = format(datetime, "%Y-%m"),
             segment = floor(as.numeric(difftime(datetime, min(datetime), units = "secs")) / period_seconds) + 1) %>%
    summarise(max_wave_height = max(WVHT, na.rm = TRUE), .groups = 'drop') %>%
    arrange(month_id, segment)
}


# Define the directory containing files
directory_path <- "Desktop/#41049"  

# List all files for processing
file_paths <- list.files(directory_path, pattern = "\\.txt$", full.names = TRUE)
process_data_file <- function(file_path) {
  # Load the data
  data <- fread(file_path)
  setnames(data, "#YY", "YY")
  
  data[, datetime := as.POSIXct(paste(YY, MM, DD, hh, mm), format = "%Y %m %d %H %M")]
  data <- data[!is.na(datetime), ]
  data[, WVHT := as.numeric(WVHT)]
  
  # Remove unwanted data points
  data <- data[!is.na(WVHT) & WVHT != 99.00, ]
  
  # Return processed data
  return(calculate_maxima(data, 72))
}

# Process each file and store the results
results_list <- lapply(file_paths, process_data_file)

# Combine all yearly results into one data.table
combined_results <- rbindlist(results_list)

print(combined_results)

# Calculate the 95% quantile for max_wave_height
quantile_95 <- combined_results[, quantile(max_wave_height, 0.95, na.rm = TRUE)]

# Extract just the month part (MM) from month_id
combined_results[, month := as.integer(substr(month_id, 6, 7))]

# Split data by month
monthly_data <- split(combined_results, by = "month")

# Add a new column 'tag' where 0 = below or equal to threshold, 1 = above threshold
combined_results[, tag := ifelse(max_wave_height > quantile_95, 1, 0)]

# Calculate transitions for each month
combined_results[, next_tag := shift(tag, type = "lead"), by = month_id]  # Shift to get the next tag

# Count transitions (nrs)
transition_counts <- combined_results[, .(
  n00 = sum(tag == 0 & next_tag == 0, na.rm = TRUE),
  n01 = sum(tag == 0 & next_tag == 1, na.rm = TRUE),
  n10 = sum(tag == 1 & next_tag == 0, na.rm = TRUE),
  n11 = sum(tag == 1 & next_tag == 1, na.rm = TRUE)
), by = month]

# Print transition counts by month
print(transition_counts)


