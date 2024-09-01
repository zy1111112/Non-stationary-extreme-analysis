# Load the necessary package
library(extRemes)

# Read the dataset
data <- read.csv("data_41049.csv")

# Define the frequency for the trigonometric terms
omega <- 2 * pi

# Define the non-stationary location formula with 2 harmonics
location_formula <- ~ cos(omega * scaled_time) + sin(omega * scaled_time) + reconstruct

# Define the non-stationary scale formula with 2 harmonics to be exponentiated
scale_formula <- ~ reconstruct

# Fit the non-stationary GEV model using Peaks-Over-Threshold (POT) method
fit <- fevd(max_WHT, data, location.fun = location_formula, 
            scale.fun = scale_formula, 
            threshold = data$threshold, type = "PP", 
            shape.fun = ~1, use.phi = TRUE,
            time.units = "121/year")

# Print the summary
fit_summary <- summary(fit)
print(fit_summary)

# Plot the diagnostic plots
plot(fit)

# Preparing the covariate matrix for prediction
scaled_time <- data$scaled_time
reconstruct <- data$reconstruct

# Mapping scaled time to actual years (continuous)
years <- 2014 + scaled_time * (2023 - 2014) / 10

# Ensure the covariate matrix matches the fitted model and varies over time
v <- make.qcov(fit, vals = list(
  mu1 = cos(omega * scaled_time), 
  mu2 = sin(omega * scaled_time),
  mu3 = reconstruct,
  phi1 = reconstruct,
  threshold = data$threshold))

# Plotting the observed data with continuous time mapping
plot(years, data$max_WHT, ylim = c(0, 30), xlab = "Year",
     ylab = "MWHT", pch = 16, col = "black")

# Compute and plot Confidence Intervals for different return periods over time
ciEffRL100 <- ci(fit, return.period = 100, qcov = v)
lines(years, ciEffRL100[, 2], col = "darkblue", lwd = 1.25)

ciEffRL50 <- ci(fit, return.period = 50, qcov = v)
lines(years, ciEffRL50[, 2], col = "red", lwd = 1.25)

ciEffRL20 <- ci(fit, return.period = 20, qcov = v)
lines(years, ciEffRL20[, 2], col = "green", lwd = 1.25)

# Adding a legend
legend("topleft",                    
       legend = c("Return Period 100", "Return Period 50", "Return Period 20"), 
       col = c("darkblue", "red", "green"), 
       lwd = 1.25)

# Define the harmonic function for mu(t)
mu_t <- function(t, mu0, mu_params, Pu, omega, reconstruct_value) {
  mu0 + sum(sapply(1:Pu, function(i) mu_params[2*i-1] * cos(i * omega * t) + mu_params[2*i] * sin(i * omega * t))) + mu_params[3] * reconstruct_value
}

# Define the harmonic function for sigma(t)
sigma_t <- function(t, sigma0, sigma1, reconstruct_value) {
  exp(sigma0 + sigma1 * reconstruct_value)
}

# Define a function to calculate z_m given the parameters
calculate_zm <- function(params, t, m, reconstruct) {
  location_params <- params[1:4]  # Assuming the first 4 parameters are for location
  scale_params <- params[5:6]     # Assuming the next 2 parameters are for scale
  shape_param <- params[7]        # Assuming the 7th parameter is for shape
  
  mu0 <- location_params[1]
  mu_params <- location_params[2:4]
  
  sigma0 <- scale_params[1]
  sigma1 <- scale_params[2]
  
  # Calculate mu(t) and sigma(t) for each time point using corresponding reconstruct value
  mu_vals <- sapply(1:length(t), function(i) mu_t(t[i], mu0=mu0, mu_params=mu_params, Pu=1, omega=omega, reconstruct_value=reconstruct[[i]]))
  sigma_vals <- sapply(1:length(t), function(i) sigma_t(t[i], sigma0=sigma0, sigma1=sigma1, reconstruct_value=reconstruct[[i]]))
  
  # Solve for zm using numerical methods
  zm_function <- function(zm) {
    p_i <- sapply(1:length(t), function(i) {
      if (1 + shape_param * (zm - mu_vals[i]) / sigma_vals[i] > 0) {
        1 - (1 / 1212) * (1 + shape_param * (zm - mu_vals[i]) / sigma_vals[i])^(-1 / shape_param)
      } else {
        1
      }
    })
    p_i <- pmax(p_i, 1e-10)  # Ensure p_i values are positive and not zero
    return(sum(log(p_i)) - log(1 - 1/m))
  }
  
  zm <- tryCatch({
    uniroot(zm_function, c(0, 1000))$root
  }, error = function(e) {
    cat("uniroot error:", e$message, "\n")
    return(NA)
  })
  
  return(zm)
}

# Define your intervals
intervals <- list(c(0,1), c(1,2), c(2,3), c(3,4), c(4,5), c(5,6), c(6,7), c(7,8), c(8,9), c(9,10))

# Calculate z_m for each interval and return period
return_periods <- c(100, 50, 20)
colors <- c("darkblue", "red", "green")
z_m_results <- list()

for (m in return_periods) {
  z_m_values <- numeric(length(intervals))
  
  for (i in seq_along(intervals)) {
    interval <- intervals[[i]]
    
    # Filter t and reconstruct values within the current interval
    t_filtered <- scaled_time[scaled_time >= interval[1] & scaled_time < interval[2]]
    reconstruct_filtered <- reconstruct[scaled_time >= interval[1] & scaled_time < interval[2]]
    
    # Calculate z_m for each parameter set in the current interval
    z_m_values[i] <- calculate_zm(fit_summary$par, t_filtered, m = m, reconstruct = reconstruct_filtered)
  }
  
  z_m_results[[paste0("RP_", m)]] <- z_m_values
}

# Map intervals to corresponding years for plotting
interval_years_start <- 2014 + (0:9)  # Starting year for each interval
interval_years_end <- interval_years_start + 1  # Ending year for each interval

# Plot the z_m results as straight dashed lines within each year for each return period
for (j in seq_along(return_periods)) {
  for (i in seq_along(intervals)) {
    segments(x0 = interval_years_start[i], y0 = z_m_results[[j]][i], 
             x1 = interval_years_end[i], y1 = z_m_results[[j]][i], 
             col = colors[j], lwd = 2, lty = 2)  # lty = 2 for dashed lines
  }
}

