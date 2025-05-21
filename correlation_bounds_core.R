# correlation_bounds_core.R
#
# Core functions for computing theoretical bounds on Pearson's correlation
# coefficient for categorical variables with fixed marginal distributions.
#
# Author: [Your Name]
# Date: March 2, 2025

# -----------------------------------------------------------------------------
# Function to compute the maximum correlation (comonotonic coupling)
# This implements the Fréchet–Hoeffding upper bound for the joint distribution
#
# Arguments:
#   marginalX - Vector of marginal probabilities or counts for variable X
#   marginalY - Vector of marginal probabilities or counts for variable Y
#   sample_size - Sample size (used if marginals are probabilities)
#
# Returns:
#   The maximum possible Pearson's correlation coefficient
# -----------------------------------------------------------------------------
max_corr_bound <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals sum to ~1, treat as probabilities and generate counts
  if (sum(marginalX) <= 1.1) {
    countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
  } else {
    countsX <- marginalX
    sample_size <- sum(countsX)
  }
  if (sum(marginalY) <= 1.1) {
    countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
  } else {
    countsY <- marginalY
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  # Define ordinal levels (0, 1, 2, ...)
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Compute proportions and moments
  pX <- countsX / sum(countsX)
  pY <- countsY / sum(countsY)
  muX <- sum(x_levels * pX)
  muY <- sum(y_levels * pY)
  sigmaX <- sqrt(sum(x_levels^2 * pX) - muX^2)
  sigmaY <- sqrt(sum(y_levels^2 * pY) - muY^2)
  
  # Compute the joint distribution using cumulative probabilities
  cum_pX <- cumsum(pX)
  cum_pY <- cumsum(pY)
  joint <- matrix(0, nrow = length(x_levels), ncol = length(y_levels))
  
  i <- 1; j <- 1
  cumX_prev <- 0; cumY_prev <- 0
  while (i <= length(x_levels) && j <= length(y_levels)) {
    currX <- cum_pX[i]
    currY <- cum_pY[j]
    joint[i, j] <- min(currX, currY) - max(cumX_prev, cumY_prev)
    
    if (currX < currY) {
      cumX_prev <- currX
      i <- i + 1
    } else if (currX > currY) {
      cumY_prev <- currY
      j <- j + 1
    } else {
      cumX_prev <- currX
      cumY_prev <- currY
      i <- i + 1
      j <- j + 1
    }
  }
  
  # Compute E[XY] based on the joint distribution
  E_XY <- sum(outer(x_levels, y_levels, FUN = "*") * joint)
  
  # Calculate the maximum Pearson correlation
  r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
  return(r_max)
}

# -----------------------------------------------------------------------------
# Function to compute the minimum correlation (anti-comonotonic pairing)
# Pairs highest values of X with lowest values of Y to minimize correlation
#
# Arguments:
#   marginalX - Vector of marginal probabilities or counts for variable X
#   marginalY - Vector of marginal probabilities or counts for variable Y
#   sample_size - Sample size (used if marginals are probabilities)
#
# Returns:
#   The minimum possible Pearson's correlation coefficient
# -----------------------------------------------------------------------------
min_corr_bound <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals sum to ~1, treat as probabilities and generate counts
  if (sum(marginalX) <= 1.1) {
    countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
  } else {
    countsX <- marginalX
    sample_size <- sum(countsX)
  }
  if (sum(marginalY) <= 1.1) {
    countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
  } else {
    countsY <- marginalY
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  # Define ordinal levels (0, 1, 2, ...)
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Create full sample vectors based on counts
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # Pair the highest X with the lowest Y (anti-comonotonic pairing)
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  # Calculate correlation
  r_min <- cor(x_sorted, y_sorted)
  return(r_min)
}

# -----------------------------------------------------------------------------
# Function to simulate the permutation (randomization) distribution of Pearson's r
# Generates the distribution of correlations under the null hypothesis of independence
#
# Arguments:
#   marginalX - Vector of marginal probabilities or counts for variable X
#   marginalY - Vector of marginal probabilities or counts for variable Y
#   nsim - Number of simulations
#   sample_size - Sample size (used if marginals are probabilities)
#
# Returns:
#   Vector of simulated Pearson's correlation coefficients
# -----------------------------------------------------------------------------
simulate_permutation_distribution <- function(marginalX, marginalY, nsim = 1000, sample_size = 10000) {
  # If marginals sum to ~1, treat as probabilities and generate counts
  if (sum(marginalX) <= 1.1) {
    countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
  } else {
    countsX <- marginalX
    sample_size <- sum(countsX)
  }
  if (sum(marginalY) <= 1.1) {
    countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
  } else {
    countsY <- marginalY
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  # Define ordinal levels (0, 1, 2, ...)
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Create sample vectors based on counts
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # Initialize storage for simulated correlations
  r_vals <- numeric(nsim)
  for (i in 1:nsim) {
    # Randomly permute y values to simulate independence
    x_perm <- sample(x_vec, size = length(x_vec), replace = FALSE)
    y_perm <- sample(y_vec, size = length(y_vec), replace = FALSE)
    r_vals[i] <- cor(x_perm, y_perm)
  }
  return(r_vals)
}

# -----------------------------------------------------------------------------
# Function to create paired data for maximum correlation (comonotonic coupling)
#
# Arguments:
#   marginalX - Vector of marginal probabilities or counts for variable X
#   marginalY - Vector of marginal probabilities or counts for variable Y
#   sample_size - Sample size (used if marginals are probabilities)
#
# Returns:
#   Data frame with paired X and Y values that maximize correlation
# -----------------------------------------------------------------------------
create_max_corr_pairs <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals sum to ~1, treat as probabilities and generate counts
  if (sum(marginalX) <= 1.1) {
    countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
  } else {
    countsX <- marginalX
    sample_size <- sum(countsX)
  }
  if (sum(marginalY) <= 1.1) {
    countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
  } else {
    countsY <- marginalY
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  # Adjust counts to sum exactly to sample_size
  diffX <- sample_size - sum(countsX)
  if(diffX != 0) {
    i_max <- which.max(countsX)
    countsX[i_max] <- countsX[i_max] + diffX
  }
  diffY <- sample_size - sum(countsY)
  if(diffY != 0) {
    i_max <- which.max(countsY)
    countsY[i_max] <- countsY[i_max] + diffY
  }
  
  # Define ordinal levels (0, 1, 2, ...)
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Create sample vectors based on counts
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # Sort both in the same direction (comonotonic)
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = TRUE)
  
  return(data.frame(X = x_sorted, Y = y_sorted))
}

# -----------------------------------------------------------------------------
# Function to create paired data for minimum correlation (anti-comonotonic pairing)
#
# Arguments:
#   marginalX - Vector of marginal probabilities or counts for variable X
#   marginalY - Vector of marginal probabilities or counts for variable Y
#   sample_size - Sample size (used if marginals are probabilities)
#
# Returns:
#   Data frame with paired X and Y values that minimize correlation
# -----------------------------------------------------------------------------
create_min_corr_pairs <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals sum to ~1, treat as probabilities and generate counts
  if (sum(marginalX) <= 1.1) {
    countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
  } else {
    countsX <- marginalX
    sample_size <- sum(countsX)
  }
  if (sum(marginalY) <= 1.1) {
    countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
  } else {
    countsY <- marginalY
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  # Adjust counts to sum exactly to sample_size
  diffX <- sample_size - sum(countsX)
  if(diffX != 0) {
    i_max <- which.max(countsX)
    countsX[i_max] <- countsX[i_max] + diffX
  }
  diffY <- sample_size - sum(countsY)
  if(diffY != 0) {
    i_max <- which.max(countsY)
    countsY[i_max] <- countsY[i_max] + diffY
  }
  
  # Define ordinal levels (0, 1, 2, ...)
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Create sample vectors based on counts
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # Sort in opposite directions (anti-comonotonic)
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  return(data.frame(X = x_sorted, Y = y_sorted))
}

# -----------------------------------------------------------------------------
# Function to convert probabilities to counts
#
# Arguments:
#   probs - Vector of probabilities
#   sample_size - Desired sample size
#
# Returns:
#   Vector of counts with sum equal to sample_size
# -----------------------------------------------------------------------------
probs_to_counts <- function(probs, sample_size) {
  counts <- round(probs * sample_size)
  diff <- sample_size - sum(counts)
  
  if(diff != 0) {
    # Adjust the count of the largest category to ensure total equals sample_size
    i_max <- which.max(counts)
    counts[i_max] <- counts[i_max] + diff
  }
  
  return(counts)
}
