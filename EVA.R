# Loading necessary libraries
library(data.table)
library(dplyr)
library(ggplot2)
library(purrr)

# Define the directory containing your files
directory_path <- "Desktop/#41043"  

# List all files for processing
file_paths <- list.files(directory_path, pattern = "\\.txt$", full.names = TRUE)
process_data_file <- function(file_path) {
  # Load the data
  data <- fread(file_path)
  setnames(data, "#YY", "YY")
  
  # Assuming the data includes datetime and WVHT columns correctly formatted
  data[, datetime := as.POSIXct(paste(YY, MM, DD, hh, mm), format = "%Y %m %d %H %M")]
  data <- data[!is.na(datetime), ]
  data[, WVHT := as.numeric(WVHT)]
  
  # Remove unwanted data points
  data <- data[!is.na(WVHT) & WVHT != 99.00, ]
  
  # Return processed data
  return(data)
}

# Process each file and store the results
results_list <- lapply(file_paths, process_data_file)

# Combine all yearly results into one data.table
combined_results <- rbindlist(results_list)

origional_data_41043 <- combined_results

# Set up the plotting area to have 2 rows and 2 columns
par(mfrow = c(2, 2))

# Plot for Station 41049
plot(origional_data_41049$datetime, origional_data_41049$WVHT, type = "l", col="blue", 
     xlab = "Year", ylab = "Wave Height (WVHT)", 
     main = "Station 41049")

# Plot for Station 41047
plot(origional_data_41047$datetime, origional_data_41047$WVHT, type = "l", col = "red", 
     xlab = "Year", ylab = "Wave Height (WVHT)", 
     main = "Station 41047")

# Plot for Station 41044
plot(origional_data_41044$datetime, origional_data_41044$WVHT, type = "l", col = "green", 
     xlab = "Year", ylab = "Wave Height (WVHT)", 
     main = "Station 41044")

# Plot for Station 41043
plot(origional_data_41043$datetime, origional_data_41043$WVHT, type = "l", col = "purple", 
     xlab = "Year", ylab = "Wave Height (WVHT)", 
     main = "Station 41043")



