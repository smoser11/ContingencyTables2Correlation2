max_corr <- function(pX, pY) {
	# Step 1: Normalize the marginal distributions (in case they are not probabilities)
	pX <- pX / sum(pX)
	pY <- pY / sum(pY)
	
	# Step 2: Define the support of X and Y.
	# Here we assume X takes values 0, 1, ..., length(pX)-1 and similarly for Y.
	nX <- length(pX)
	nY <- length(pY)
	x_vals <- 0:(nX - 1)
	y_vals <- 0:(nY - 1)
	
	# Step 3: Compute means and standard deviations for X and Y
	muX <- sum(x_vals * pX)
	muY <- sum(y_vals * pY)
	varX <- sum(x_vals^2 * pX) - muX^2
	varY <- sum(y_vals^2 * pY) - muY^2
	sigmaX <- sqrt(varX)
	sigmaY <- sqrt(varY)
	
	# Step 4: Construct the joint probability matrix that maximizes E[XY]
	# We do this using the comonotonic (Fréchet–Hoeffding upper bound) algorithm.
	cum_pX <- cumsum(pX)
	cum_pY <- cumsum(pY)
	joint <- matrix(0, nX, nY)
	
	i <- 1
	j <- 1
	cumX_prev <- 0
	cumY_prev <- 0
	
	while (i <= nX && j <= nY) {
		currX <- cum_pX[i]
		currY <- cum_pY[j]
		# The mass assigned to cell (i, j) is the increase in the minimum of the cumulative probabilities.
		joint[i, j] <- min(currX, currY) - max(cumX_prev, cumY_prev)
		
		# Update indices and the "previous" cumulative sums.
		if (currX < currY) {
			cumX_prev <- currX
			i <- i + 1
		} else if (currX > currY) {
			cumY_prev <- currY
			j <- j + 1
		} else { # equal case: move both indices
			cumX_prev <- currX
			cumY_prev <- currY
			i <- i + 1
			j <- j + 1
		}
	}
	
	# Step 5: Compute E[XY] for the constructed joint distribution.
	# The outer product creates a matrix with entries x_i * y_j.
	E_XY <- sum(outer(x_vals, y_vals, FUN = "*") * joint)
	
	# Step 6: Calculate the maximum Pearson correlation coefficient.
	r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
	
	return(r_max)
}





#############################################################


# ================================
# Improved R Script Demonstration
# ================================

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	# If marginals are probabilities (sum ~1), generate counts; else, assume counts.
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
		if(sum(countsY) != sample_size) stop("Total counts for X and Y must be equal.")
	}
	
	# Define ordinal levels (assumed to be 0,1,2,...)
	x_levels <- 0:(length(countsX) - 1)
	y_levels <- 0:(length(countsY) - 1)
	
	# Compute proportions, means, and standard deviations
	pX <- countsX / sum(countsX)
	pY <- countsY / sum(countsY)
	muX <- sum(x_levels * pX)
	muY <- sum(y_levels * pY)
	sigmaX <- sqrt(sum(x_levels^2 * pX) - muX^2)
	sigmaY <- sqrt(sum(y_levels^2 * pY) - muY^2)
	
	# Construct joint distribution using cumulative probabilities (Fréchet–Hoeffding upper bound)
	cum_pX <- cumsum(pX)
	cum_pY <- cumsum(pY)
	joint <- matrix(0, nrow = length(x_levels), ncol = length(y_levels))
	
	i <- 1
	j <- 1
	cumX_prev <- 0
	cumY_prev <- 0
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

# Function to compute the minimum correlation (pair X sorted descending with Y sorted ascending)
min_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
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
		if(sum(countsY) != sample_size) stop("Total counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX) - 1)
	y_levels <- 0:(length(countsY) - 1)
	
	# Create full sample vectors based on counts
	x_vec <- rep(x_levels, times = countsX)
	y_vec <- rep(y_levels, times = countsY)
	
	# Pair the highest X with the lowest Y to minimize E[XY]
	x_sorted <- sort(x_vec, decreasing = TRUE)
	y_sorted <- sort(y_vec, decreasing = FALSE)
	
	r_min <- cor(x_sorted, y_sorted)
	return(r_min)
}




### EXAMPLES

# Step 1: Define sample marginal distributions as frequencies (counts)
sample_size <- 10000
# For example, X has 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# Y has 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

max_corr(marginalX_counts, marginalY_counts)
max_corr_sorted(marginalX_counts, marginalY_counts)

min_corr(marginalX_counts, marginalY_counts)
min_corr_sorted(marginalX_counts, marginalY_counts)
























# Function to simulate the random (permutation) distribution of Pearson's r
simulate_random_corr <- function(marginalX, marginalY, nsim = 1000, sample_size = 10000) {
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
		if(sum(countsY) != sample_size) stop("Total counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX) - 1)
	y_levels <- 0:(length(countsY) - 1)
	
	# Create sample vectors based on counts
	x_vec <- rep(x_levels, times = countsX)
	y_vec <- rep(y_levels, times = countsY)
	
	# Initialize storage for simulated correlations
	r_vals <- numeric(nsim)
	for (i in 1:nsim) {
		x_perm <- sample(x_vec, size = length(x_vec), replace = FALSE)
		y_perm <- sample(y_vec, size = length(y_vec), replace = FALSE)
		r_vals[i] <- cor(x_perm, y_perm)
	}
	return(r_vals)
}

# Function to plot the empirical distribution with theoretical bounds and 95% CI
plot_empirical_distribution <- function(r_vals, r_min, r_max, ci_bounds,
										main = "Empirical Distribution of Pearson's r") {
	hist(r_vals, breaks = 30, probability = TRUE,
		 main = main, xlab = "Pearson's r", col = "lightblue", border = "white")
	lines(density(r_vals), col = "darkblue", lwd = 2)
	# Add vertical lines for theoretical min and max
	abline(v = r_min, col = "red", lwd = 2, lty = 2)
	abline(v = r_max, col = "green", lwd = 2, lty = 2)
	# Add vertical lines for 95% CI bounds
	abline(v = ci_bounds[1], col = "purple", lwd = 2, lty = 3)
	abline(v = ci_bounds[2], col = "purple", lwd = 2, lty = 3)
	
	legend("topright",
		   legend = c(paste("Min r =", round(r_min, 3)),
		   		   paste("Max r =", round(r_max, 3)),
		   		   paste("95% CI:", paste(round(ci_bounds, 3), collapse = " to "))),
		   col = c("red", "green", "purple"), lwd = 2, lty = c(2, 2, 3))
}

# ---------------------------
# Demonstration using example data


# Step 1: Define sample marginal distributions as frequencies (counts)
sample_size <- 10000
# For example, X has 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# Y has 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Step 1: Define sample marginal distributions as frequencies (counts)
sample_size <- 10000
# For example, X has 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# Y has 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Step 1: Define sample marginal distributions as frequencies (counts)
sample_size <- 10000
# For example, X has 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# Y has 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Step 1: Define sample marginal distributions as frequencies (counts)
sample_size <- 10000
# For example, X has 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# Y has 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Step 1: Define sample marginal distributions as frequencies (counts)
sample_size <- 10000
# For example, X has 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# Y has 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Step 1: Define sample marginal distributions as frequencies (counts)
sample_size <- 10000
# For example, X has 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# Y has 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Step 1: Define sample marginal distributions as frequencies (counts)
sample_size <- 10000
# For example, X has 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# Y has 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Step 1: Define sample marginal distributions as frequencies (counts)
sample_size <- 10000
# For example, X has 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# Y has 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Step 1: Define sample marginal distributions as frequencies (counts)
sample_size <- 10000
# For example, X has 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# Y has 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 1000, 500, 500)


# Display the marginal distributions in the console
cat("Marginal distribution for X (counts):\n")
print(marginalX_counts)
cat("Marginal distribution for Y (counts):\n")
print(marginalY_counts)

# Also, plot barplots for the marginal distributions
par(mfrow = c(1, 2))
barplot(marginalX_counts, names.arg = 0:(length(marginalX_counts) - 1),
		main = "Marginal Distribution of X", xlab = "X categories", col = "skyblue")
barplot(marginalY_counts, names.arg = 0:(length(marginalY_counts) - 1),
		main = "Marginal Distribution of Y", xlab = "Y categories", col = "salmon")
par(mfrow = c(1, 1))  # Reset layout

# Step 2: Compute theoretical maximum and minimum Pearson correlations
r_max <- max_corr_sorted(marginalX_counts, marginalY_counts, sample_size = sample_size)
r_min <- min_corr_sorted(marginalX_counts, marginalY_counts, sample_size = sample_size)
cat("Theoretical maximum Pearson's r:", round(r_max, 3), "\n")
cat("Theoretical minimum Pearson's r:", round(r_min, 3), "\n")

# Step 3: Simulate the permutation (randomization) distribution of Pearson's r
set.seed(123)  # for reproducibility
r_vals <- simulate_random_corr(marginalX_counts, marginalY_counts, nsim = 1000, sample_size = sample_size)

# Step 4: Calculate the 95% CI from the permutation distribution
ci_bounds <- quantile(r_vals, probs = c(0.025, 0.975))
cat("95% CI for Pearson's r (from permutation distribution):\n")
print(ci_bounds)

# Step 5: Plot the empirical distribution along with theoretical bounds and the 95% CI
plot_empirical_distribution(r_vals, r_min, r_max, ci_bounds,
							main = "Permutation Distribution of Pearson's r")
