library(extRemes)
library(dplyr)

# Load the dataset
data <- read.csv("data_41049.csv")

# Define the number of harmonics
Pu <- 2 # in location parameter
Pa <- 2 # in scale parameter 

# Compute omega
omega <- 2 * pi

# Generate harmonic components for location and scale
for (i in 1:max(Pu, Pa)) {
  if (i <= Pu) {
    data[[paste0("mu", 2*i-1)]] <- cos(i * omega * data$scaled_time)
    data[[paste0("mu", 2*i)]] <- sin(i * omega * data$scaled_time)
  }
  if (i <= Pa) {
    data[[paste0("phi", 2*i-1)]] <- cos(i * omega * data$scaled_time)
    data[[paste0("phi", 2*i)]] <- sin(i * omega * data$scaled_time)
  }
}

# Define the location and scale formulas
location_formula <- if (Pu > 0) {
  as.formula(paste("~", paste(c(paste0("mu", 1:(2*Pu))), collapse = " + ")))
} else {
  ~ 1  # Constant if Pu = 0
}

scale_formula <- if (Pa > 0) {
  as.formula(paste("~", paste(c(paste0("phi", 1:(2*Pa))), collapse = " + ")))
} else {
  ~ 1  # Constant if Pa = 0
}

# Fit the non-stationary GEV model using Peaks-Over-Threshold (POT) method
fit <- fevd(max_WHT, data, location.fun = location_formula, 
            scale.fun = scale_formula, threshold = data$threshold, type = "PP", 
            shape.fun = ~1, use.phi = TRUE, time.units = "121/year")

# Print the summary and diagnostic plots
fit_summary <- summary(fit)
print(fit_summary)
plot(fit)

# Build the qcov list dynamically based on Pu and Pa
qcov_list <- list()

# Always include the threshold if needed
qcov_list[["threshold"]] <- data$threshold

# Add harmonic components for location if Pu > 0
if (Pu > 0) {
  for (i in 1:Pu) {
    qcov_list[[paste0("mu", 2*i-1)]] <- cos(i * omega * data$scaled_time)
    qcov_list[[paste0("mu", 2*i)]] <- sin(i * omega * data$scaled_time)
  }
}

# Add harmonic components for scale if Pa > 0
if (Pa > 0) {
  for (i in 1:Pa) {
    qcov_list[[paste0("phi", 2*i-1)]] <- cos(i * omega * data$scaled_time)
    qcov_list[[paste0("phi", 2*i)]] <- sin(i * omega * data$scaled_time)
  }
}

# If Pu = 0 and Pa = 0, qcov_list will only contain the threshold if used in the model.
# If there are no dynamic covariates for location and scale, qcov_list should not include any mu or phi terms.

# Example when Pu = 0, Pa = 0:
if (Pu == 0 && Pa == 0) {
  qcov_list <- list(threshold = data$threshold)
}

# Now qcov_list is ready to be used in make.qcov


# Ensure the names in qcov_list match those used in the model
v <- make.qcov(fit, vals = qcov_list)

# Calculate the confidence interval for the effective 100-year return level
ciEffRL100 <- ci(fit, return.period = 100, qcov = v)

# Plot the results
plot(data$scaled_time, data$max_WHT, ylim = c(0, 30), xlab = "Scaled Time",
     ylab = "MWHT")
lines(ciEffRL100[, 1], lty = 2, col = "darkblue", lwd = 1.25)
lines(ciEffRL100[, 2], col = "darkblue", lwd = 1.25)
lines(ciEffRL100[, 3], lty = 2, col = "darkblue", lwd = 1.25)
legend("topleft", legend = c("Effective 100-year return level",
                             "95% CI (normal approx)"), col = "darkblue", lty = c(1, 2), 
       lwd = 1.25, bty = "n")




# Number of simulations
n_simulations <- 1000

# Simulate parameter sets from the estimated distribution
library(mvtnorm)
set.seed(123)  # For reproducibility
param_means <- fit_summary$par
param_cov <- fit_summary$cov.theta
param_samples <- rmvnorm(n_simulations, mean = param_means, sigma = param_cov)


# Calculate aggregated return level
# Define the harmonic function for mu(t)
mu_t <- function(t, mu0, mu_params, Pu, omega) {
  if (Pu == 0) {
    return(rep(mu0, length(t)))  # Return constant mu0 if no harmonics
  }
  mu0 + sum(sapply(1:Pu, function(i) mu_params[2*i-1] * cos(i * omega * t) + mu_params[2*i] * sin(i * omega * t)))
}

# Define the harmonic function for sigma(t)
sigma_t <- function(t, sigma0, sigma_params, Pa, omega) {
  if (Pa == 0) {
    return(rep(exp(sigma0), length(t)))  # Return constant sigma0 if no harmonics
  }
  exp(sigma0 + sum(sapply(1:Pa, function(i) sigma_params[2*i-1] * cos(i * omega * t) + sigma_params[2*i] * sin(i * omega * t))))
}

# Function to calculate z_m given the parameters
calculate_zm <- function(params, t, m, Pu, Pa, omega) {
  # Determine the indices for parameter extraction
  location_end <- 1 + 2 * Pu  # End index for location parameters
  scale_end <- location_end + 2 * Pa + 1  # End index for scale parameters
  
  # Extract location and scale parameters
  location_params <- params[1:location_end]
  scale_params <- params[(location_end + 1):scale_end]
  shape_param <- params[scale_end + 1]
  
  # Separate the individual parameters
  mu0 <- location_params[1]
  mu_params <- if (Pu > 0) location_params[2:(1 + 2 * Pu)] else NULL
  
  sigma0 <- scale_params[1]
  sigma_params <- if (Pa > 0) scale_params[2:(1 + 2 * Pa)] else NULL
  
  # Calculate mu(t) and sigma(t) for each time point
  mu_vals <- sapply(t, mu_t, mu0 = mu0, mu_params = mu_params, Pu = Pu, omega = omega)
  sigma_vals <- sapply(t, sigma_t, sigma0 = sigma0, sigma_params = sigma_params, Pa = Pa, omega = omega)
  
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

# Assume param_samples is already defined and contains your sampled parameters
# Calculate z_m for each simulated parameter vector
m <- 100  # For example, 100-year return level
t <- data$scaled_time
t <- t[t < 1]  # Example filtering condition
z_m_values <- apply(param_samples, 1, calculate_zm, t = t, m = m, Pu = Pu, Pa = Pa, omega = omega)

# Remove NA values (if any)
z_m_values <- na.omit(z_m_values)

# Construct confidence intervals for z_m
z_m_mean <- mean(z_m_values)
z_m_sd <- sd(z_m_values)
conf_interval <- quantile(z_m_values, c(0.025, 0.975))

# Print results
cat("Mean of z_m:", z_m_mean, "\n")
cat("Standard deviation of z_m:", z_m_sd, "\n")
cat("95% confidence interval for z_m:", conf_interval, "\n")
