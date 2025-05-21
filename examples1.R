# -------------------------------
# Step 0: Define the functions
# (Assuming the functions below have been defined earlier)
# max_corr_sorted, min_corr_sorted, simulate_random_corr, plot_empirical_distribution

# For demonstration, here are the functions again:

max_corr_sorted <- function(marginalX, marginalY, N = 10000) {
	pX <- marginalX / sum(marginalX)
	pY <- marginalY / sum(marginalY)
	
	nX <- length(pX)
	nY <- length(pY)
	x_vals <- 0:(nX - 1)
	y_vals <- 0:(nY - 1)
	
	muX <- sum(x_vals * pX)
	muY <- sum(y_vals * pY)
	varX <- sum(x_vals^2 * pX) - muX^2
	varY <- sum(y_vals^2 * pY) - muY^2
	sigmaX <- sqrt(varX)
	sigmaY <- sqrt(varY)
	
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
	
	E_XY <- sum(outer(x_vals, y_vals, FUN = "*") * joint)
	r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
	return(r_max)
}

min_corr_sorted <- function(marginalX, marginalY, N = 10000) {
	# Normalize marginals if needed.
	pX <- marginalX / sum(marginalX)
	pY <- marginalY / sum(marginalY)
	
	nX <- length(pX)
	nY <- length(pY)
	x_vals <- 0:(nX - 1)
	y_vals <- 0:(nY - 1)
	
	# Create counts vectors
	countsX <- as.vector(rmultinom(1, size = N, prob = pX))
	countsY <- as.vector(rmultinom(1, size = N, prob = pY))
	
	x_vec <- rep(x_vals, times = countsX)
	y_vec <- rep(y_vals, times = countsY)
	
	# Sort X in descending order and Y in ascending order.
	x_sorted <- sort(x_vec, decreasing = TRUE)
	y_sorted <- sort(y_vec, decreasing = FALSE)
	
	r_min <- cor(x_sorted, y_sorted)
	return(r_min)
}

simulate_random_corr <- function(marginalX, marginalY, nsim = 1000, N = 10000) {
	if (abs(sum(marginalX) - 1) < 1e-6) {
		countsX <- as.vector(rmultinom(1, size = N, prob = marginalX))
	} else {
		countsX <- marginalX
		N <- sum(countsX)
	}
	
	if (abs(sum(marginalY) - 1) < 1e-6) {
		countsY <- as.vector(rmultinom(1, size = N, prob = marginalY))
	} else {
		countsY <- marginalY
		if(sum(countsY) != N)
			stop("Total counts for marginalX and marginalY must be equal.")
	}
	
	x_vals <- rep(0:(length(countsX) - 1), times = countsX)
	y_vals <- rep(0:(length(countsY) - 1), times = countsY)
	
	# Sort each vector in descending order (optional but consistent with previous functions)
	x_sorted <- sort(x_vals, decreasing = TRUE)
	y_sorted <- sort(y_vals, decreasing = TRUE)
	
	r_vals <- numeric(nsim)
	
	for (i in 1:nsim) {
		x_perm <- sample(x_sorted, size = length(x_sorted), replace = FALSE)
		y_perm <- sample(y_sorted, size = length(y_sorted), replace = FALSE)
		r_vals[i] <- cor(x_perm, y_perm)
	}
	
	return(r_vals)
}

plot_empirical_distribution <- function(r_vals, r_min, r_max, main = "Empirical Distribution of Pearson's r") {
	hist(r_vals, breaks = 30, probability = TRUE,
		 main = main, xlab = "Pearson's r", col = "lightblue", border = "white")
	lines(density(r_vals), col = "darkblue", lwd = 2)
	abline(v = r_min, col = "red", lwd = 2, lty = 2)
	abline(v = r_max, col = "green", lwd = 2, lty = 2)
	legend("topright",
		   legend = c(paste("Min r =", round(r_min, 3)),
		   		   paste("Max r =", round(r_max, 3))),
		   col = c("red", "green"), lwd = 2, lty = 2)
}

# -------------------------------
# Step 1: Define example marginal distributions (made-up data)
marginalX <- c(0.1, 0.3, 0.4, 0.2)  # Probabilities sum to 1 for X
marginalY <- c(0.2, 0.3, 0.3, 0.2)  # Probabilities sum to 1 for Y

# -------------------------------
# Step 2: Compute theoretical maximum and minimum correlations
r_max <- max_corr_sorted(marginalX, marginalY, N = 10000)
r_min <- min_corr_sorted(marginalX, marginalY, N = 10000)
cat("Theoretical maximum Pearson's r:", round(r_max, 3), "\n")
cat("Theoretical minimum Pearson's r:", round(r_min, 3), "\n")

# -------------------------------
# Step 3: Simulate the permutation (randomization) distribution of Pearson's r
set.seed(123)  # for reproducibility
r_vals <- simulate_random_corr(marginalX, marginalY, nsim = 1000, N = 10000)

# -------------------------------
# Step 4: Plot the empirical distribution along with theoretical bounds
plot_empirical_distribution(r_vals, r_min, r_max)

# -------------------------------
# Step 5: Compute and display the 95% quantile interval from the permutation distribution
ci <- quantile(r_vals, probs = c(0.025, 0.975))
cat("95% quantile interval for r (permutation distribution):\n")
print(ci)
