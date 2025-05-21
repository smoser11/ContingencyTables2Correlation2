# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# --- Functions defined earlier ---

# Maximum Spearman correlation via comonotonic coupling
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	# Generate counts if marginals sum to ~1 (i.e., probabilities)
	if (sum(marginalX) <= 1.1) {
		countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
	} else {
		countsX <- marginalX; sample_size <- sum(countsX)
	}
	if (sum(marginalY) <= 1.1) {
		countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
	} else {
		countsY <- marginalY
		if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX)-1)
	y_levels <- 0:(length(countsY)-1)
	
	pX <- countsX/sum(countsX); pY <- countsY/sum(countsY)
	muX <- sum(x_levels * pX); muY <- sum(y_levels * pY)
	sigmaX <- sqrt(sum(x_levels^2 * pX)-muX^2)
	sigmaY <- sqrt(sum(y_levels^2 * pY)-muY^2)
	
	# Comonotonic coupling: use the cumulative probabilities (Fréchet–Hoeffding upper bound)
	cum_pX <- cumsum(pX)
	cum_pY <- cumsum(pY)
	joint <- matrix(0, nrow = length(x_levels), ncol = length(y_levels))
	
	i <- 1; j <- 1; cumX_prev <- 0; cumY_prev <- 0
	while(i <= length(x_levels) && j <= length(y_levels)){
		currX <- cum_pX[i]; currY <- cum_pY[j]
		joint[i, j] <- min(currX, currY) - max(cumX_prev, cumY_prev)
		if(currX < currY){
			cumX_prev <- currX; i <- i+1
		} else if(currX > currY){
			cumY_prev <- currY; j <- j+1
		} else {
			cumX_prev <- currX; cumY_prev <- currY; i <- i+1; j <- j+1
		}
	}
	E_XY <- sum(outer(x_levels, y_levels, FUN="*") * joint)
	r_max <- (E_XY - muX * muY)/(sigmaX * sigmaY)
	return(r_max)
}

# Minimum Spearman correlation via countermonotonic coupling
min_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	if (sum(marginalX) <= 1.1) {
		countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
	} else {
		countsX <- marginalX; sample_size <- sum(countsX)
	}
	if (sum(marginalY) <= 1.1) {
		countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
	} else {
		countsY <- marginalY
		if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX)-1)
	y_levels <- 0:(length(countsY)-1)
	
	x_vec <- rep(x_levels, times = countsX)
	y_vec <- rep(y_levels, times = countsY)
	
	# Countermonotonic coupling: sort X in descending order, Y in ascending order
	x_sorted <- sort(x_vec, decreasing = TRUE)
	y_sorted <- sort(y_vec, decreasing = FALSE)
	
	r_min <- cor(x_sorted, y_sorted)
	return(r_min)
}

# --- End functions ---

# Set fixed marginal for X (uniform over 5 categories)
p_X <- rep(1/5, 5)

# Define Y: Uniform and Extreme marginals
p_Y_uniform <- rep(1/5, 5)
p_Y_extreme <- c(0.02, 0.02, 0.02, 0.02, 0.92)

# Define a sequence of interpolation parameters t in [0,1]
t_seq <- seq(0, 1, length.out = 20)

# Initialize storage for results
results <- data.frame(t = t_seq, 
					  D_TV = NA, 
					  r_max = NA, 
					  r_min = NA,
					  diff = NA)

# Function to compute total variation distance between p and its reflection
TV_distance <- function(p) {
	K <- length(p)
	p_reflect <- p[K:1]
	return(0.5 * sum(abs(p - p_reflect)))
}

sample_size <- 10000  # fixed sample size

for(i in seq_along(t_seq)){
	t <- t_seq[i]
	# Interpolate: p_Y(t) = (1-t)*uniform + t*extreme
	p_Y <- (1-t)*p_Y_uniform + t*p_Y_extreme
	# Compute total variation distance between p_Y and its mirror
	D_TV <- TV_distance(p_Y)
	# Compute theoretical extremes for Spearman correlation
	r_max_val <- max_corr_sorted(p_X, p_Y, sample_size = sample_size)
	r_min_val <- min_corr_sorted(p_X, p_Y, sample_size = sample_size)
	
	results$t[i] <- t
	results$D_TV[i] <- D_TV
	results$r_max[i] <- r_max_val
	results$r_min[i] <- r_min_val
	results$diff[i] <- r_max_val + r_min_val  # if symmetric, this would be 0
}

print(results)

# Plot the total variation distance versus t
p1 <- ggplot(results, aes(x=t, y=D_TV)) +
	geom_line(size=1, color="blue") +
	geom_point(color="blue") +
	labs(title="Total Variation Distance from Symmetry vs. t", x="t", y="TV Distance") +
	theme_minimal()

# Plot r_max and r_min versus t
p2 <- ggplot(results, aes(x=t)) +
	geom_line(aes(y=r_max, color="r_max"), size=1) +
	geom_line(aes(y=r_min, color="r_min"), size=1) +
	geom_point(aes(y=r_max, color="r_max"), size=2) +
	geom_point(aes(y=r_min, color="r_min"), size=2) +
	labs(title="Extreme Spearman Correlations vs. t", x="t", y="Correlation") +
	scale_color_manual(name="Legend", values=c("r_max"="green", "r_min"="red")) +
	theme_minimal()

# Plot the sum r_max + r_min (should be 0 if symmetric)
p3 <- ggplot(results, aes(x=t, y=diff)) +
	geom_line(size=1, color="purple") +
	geom_point(size=2, color="purple") +
	labs(title="r_max + r_min vs. t (Symmetry Indicator)", x="t", y="r_max + r_min") +
	theme_minimal()

# Arrange the plots in one display
library(gridExtra)
grid.arrange(p1, p2, p3, ncol=1)
