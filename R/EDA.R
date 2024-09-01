library(data.table)
library(dplyr)
library(stringr)

# List of station IDs for which data needs to be processed
station_ids <- c(41043, 41044, 41047, 41049)

# Base path where station directories are located
base_directory_path <- "Desktop"

# Loop through each station ID
for (station_id in station_ids) {
  # Define the directory containing your files for the current station
  directory_path <- file.path(base_directory_path, paste0("#", station_id))
  
  # List all .txt files for processing in the specific station directory
  file_paths <- list.files(directory_path, pattern = "\\.txt$", full.names = TRUE)
  
  # Function to process data files
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
    
    return(data)
  }
  
  # Process each file and store the results
  results_list <- lapply(file_paths, process_data_file)
  
  # Combine all results into one data.table
  combined_results <- rbindlist(results_list)
  
  # Dynamically name the variable to store results based on the station ID
  variable_name <- paste("original_data", station_id, sep = "_")
  assign(variable_name, combined_results, envir = .GlobalEnv)
}

# Set up the plotting area to have 2 rows and 2 columns
par(mfrow = c(2, 2))

# Plot for Station 41049
plot(original_data_41049$datetime, original_data_41049$WVHT, type = "l", col="blue", 
     xlab = "Year", ylab = "Wave Height (WVHT)", 
     main = "Station 41049")

# Plot for Station 41047
plot(original_data_41047$datetime, original_data_41047$WVHT, type = "l", col = "red", 
     xlab = "Year", ylab = "Wave Height (WVHT)", 
     main = "Station 41047")

# Plot for Station 41044
plot(original_data_41044$datetime, original_data_41044$WVHT, type = "l", col = "green", 
     xlab = "Year", ylab = "Wave Height (WVHT)", 
     main = "Station 41044")

# Plot for Station 41043
plot(original_data_41043$datetime, original_data_41043$WVHT, type = "l", col = "purple", 
     xlab = "Year", ylab = "Wave Height (WVHT)", 
     main = "Station 41043")
