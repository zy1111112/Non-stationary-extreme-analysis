# Load the extRemes package
library(extRemes)

# Read the dataset
data <- read.csv("data.csv")

# Define the non-stationary location formula with 2 harmonics
location_formula <- ~ cos(omega * scaled_time) + sin(omega * scaled_time) + 
  cos(2 * omega * scaled_time) + sin(2 * omega * scaled_time)

# Define the non-stationary scale formula with 2 harmonics to be exponentiated
scale_formula <- ~ cos(omega * scaled_time) + sin(omega * scaled_time) + 
  cos(2 * omega * scaled_time) + sin(2 * omega * scaled_time)

# Fit the non-stationary GEV model using Peaks-Over-Threshold (POT) method
fit <- fevd(max_WHT, data, location.fun = location_formula, 
            scale.fun = scale_formula, threshold = data$threshold, type = "PP", 
            shape.fun = ~1, use.phi = TRUE,
            time.units = "121/year")

# Print the summary and diagnostic plots
fit_summary <- summary(fit)
plot(fit)

# Find effective return level
scaled_time <- data$scaled_time

v <- make.qcov(fit, vals = list(
  mu1 = cos(omega * scaled_time), mu2 = sin(omega * scaled_time),
  mu3 = cos(2 * omega * scaled_time), mu4 = sin(2 * omega * scaled_time),
  phi1 = cos(omega * scaled_time), phi2 = sin(omega * scaled_time),
  phi3 = cos(2 * omega * scaled_time), phi4 = sin(2 * omega * scaled_time)))


ciEffRL100 <- ci(fit, return.period = 100, qcov = v)
plot(data$max_WHT, ylim = c(0, 30), xlab = "year",
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

Pu <- 2
Pa <- 2

library(nleqslv)

# Define the harmonic function for mu(t)
mu_t <- function(t, mu0, mu_params, Pu, omega) {
  mu0 + sum(sapply(1:Pu, function(i) mu_params[2*i-1] * cos(i * omega * t) + mu_params[2*i] * sin(i * omega * t)))
}

# Define the harmonic function for sigma(t)
sigma_t <- function(t, sigma0, sigma_params, Pa, omega) {
  exp(sigma0 + sum(sapply(1:Pa, function(i) sigma_params[2*i-1] * cos(i * omega * t) + sigma_params[2*i] * sin(i * omega * t))))
}

# Define a function to calculate z_m given the parameters
calculate_zm <- function(params, t, m) {
  location_params <- params[1:5]  # Assuming the first 5 parameters are for location
  scale_params <- params[6:10]    # Assuming the next 5 parameters are for scale
  shape_param <- params[11]       # Assuming the 11th parameter is for shape
  
  mu0 <- location_params[1]
  mu_params <- location_params[2:5]
  
  sigma0 <- scale_params[1]
  sigma_params <- scale_params[2:5]
  
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
  
  # Debugging: Print function values at the endpoints
  cat("zm_function at lower bound:", zm_function(0), "\n")
  cat("zm_function at upper bound:", zm_function(1000), "\n")
  
  # Check for NA values and adjust bounds if necessary
  if (is.na(zm_function(0)) || is.na(zm_function(1000))) {
    cat("Invalid function values at bounds\n")
    return(NA)
  }
  
  zm <- tryCatch({
    uniroot(zm_function, c(0, 1000))$root
  }, error = function(e) {
    cat("uniroot error:", e$message, "\n")
    return(NA)
  })
  
  return(zm)
}

# Calculate z_m for each simulated parameter vector
m <- 20  # For example, 50-year return level
t <- data$scaled_time
t <- t[t < 1] 
z_m_values <- apply(param_samples, 1, calculate_zm, t = t, m = m)

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



# Define a function to calculate z_m given the parameters
calculate_zm <- function(params, t, m) {
  location_params <- params[1:5]  # Assuming the first 5 parameters are for location
  scale_params <- params[6:10]    # Assuming the next 5 parameters are for scale
  shape_param <- params[11]       # Assuming the 11th parameter is for shape
  
  mu0 <- location_params[1]
  mu_params <- location_params[2:5]
  
  sigma0 <- scale_params[1]
  sigma_params <- scale_params[2:5]
  
  # Calculate mu(t) and sigma(t) for each time point
  mu_vals <- sapply(t, mu_t, mu0 = mu0, mu_params = mu_params, Pu = Pu, omega = omega)
  sigma_vals <- sapply(t, sigma_t, sigma0 = sigma0, sigma_params = sigma_params, Pa = Pa, omega = omega)
  
  # Solve for zm using numerical methods
  zm_function <- function(zm) {
    p_i <- sapply(1:length(t), function(i) {
      if ((1 + shape_param * (zm - mu_vals[i])) / sigma_vals[i] > 0) {
        1 - (1 / 1212) * ((1 + shape_param * (zm - mu_vals[i])) / sigma_vals[i])^(-1 / shape_param)
      } else {
        1
      }
    })
    p_i <- pmax(p_i, 1e-10)  # Ensure p_i values are positive and not zero
    return(sum(log(p_i)) - log(1 - 1/m))
  }
  
  zm <- tryCatch({
    nleqslv(0, zm_function)$x
  }, error = function(e) {
    cat("nleqslv error:", e$message, "\n")
    return(NA)
  })
  
  return(zm)
}

# Calculate z_m for each simulated parameter vector
m <- 50  # For example, 50-year return level
t <- data$scaled_time
t <- t[t < 1] 
z_m_values <- apply(param_samples, 1, calculate_zm, t = t, m = m, reconstruct)

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

param_samples <- rmvnorm(1, mean = param_means, sigma = param_cov)
z_m_values <- apply(param_samples, 1, calculate_zm, t = t, m = m)
z_m_values
zm = z_m_values
p_i <- sapply(1:length(t), function(i) {
  if ((1 + shape_param * (zm - mu_vals[i])) / sigma_vals[i] > 0) {
    1 - (1 / 1212) * ((1 + shape_param * (zm - mu_vals[i])) / sigma_vals[i])^(-1 / shape_param)
  } else {
    1
  }
})
p_i <- pmax(p_i, 1e-10)
p_i

# Define a function to calculate z_m given the parameters
