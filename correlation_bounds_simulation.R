# correlation_bounds_simulation.R
#
# Simulation study of correlation matrix properties when rescaling correlations
# using complete data and ordinal variables with different numbers of categories
#
# Author: [Your Name]
# Date: March 2, 2025

# -----------------------------------------------------------------------------
# 0. Load required libraries and source functions
# -----------------------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(gridExtra)
library(Matrix)
library(MASS)  # For mvrnorm

# Source the required functions (assuming they're in your working directory)
source("correlation_bounds_core.R")

# -----------------------------------------------------------------------------
# 1. Functions for generating ordinal data
# -----------------------------------------------------------------------------

#' Generate multivariate normal data and convert to ordinal categories
#'
#' @param n Number of observations
#' @param categories Vector of category counts for each variable
#' @param cor_matrix Correlation matrix for the underlying continuous variables
#'
#' @return A list containing the ordinal data and the true correlation matrix
#'
generate_ordinal_data <- function(n, categories, cor_matrix = NULL) {
	# Number of variables
	p <- length(categories)
	
	# If no correlation matrix provided, generate a random one
	if (is.null(cor_matrix)) {
		# Generate a random correlation matrix
		cor_matrix <- matrix(0.5, nrow = p, ncol = p)
		diag(cor_matrix) <- 1
		
		# Ensure it's positive definite
		eigen_decomp <- eigen(cor_matrix)
		if (min(eigen_decomp$values) <= 0) {
			# Adjust eigenvalues to ensure positive definiteness
			eigen_decomp$values[eigen_decomp$values <= 0] <- 0.01
			cor_matrix <- eigen_decomp$vectors %*% diag(eigen_decomp$values) %*% t(eigen_decomp$vectors)
			
			# Ensure diagonal is 1
			D <- diag(1/sqrt(diag(cor_matrix)))
			cor_matrix <- D %*% cor_matrix %*% D
		}
	}
	
	# Generate multivariate normal data
	z <- MASS::mvrnorm(n = n, mu = rep(0, p), Sigma = cor_matrix)
	
	# Convert to ordinal by discretizing
	ordinal_data <- matrix(0, nrow = n, ncol = p)
	for (j in 1:p) {
		# Create cut points based on desired category proportions
		# For simplicity, we'll use equal proportions
		probs <- seq(0, 1, length.out = categories[j] + 1)
		cutpoints <- c(-Inf, quantile(z[, j], probs = probs[2:categories[j]]), Inf)
		
		# Discretize
		ordinal_data[, j] <- as.numeric(cut(z[, j], breaks = cutpoints, labels = 0:(categories[j]-1)))
	}
	
	# Calculate the actual correlation matrix of the ordinal data
	true_cor_matrix <- cor(ordinal_data)
	
	# Return both the data and its true correlation matrix
	return(list(
		data = ordinal_data,
		true_cor_matrix = true_cor_matrix
	))
}

# -----------------------------------------------------------------------------
# 2. Functions for rescaling correlations and testing matrix properties
# -----------------------------------------------------------------------------

#' Compute theoretical bounds for correlation between two ordinal variables
#'
#' @param x Vector of ordinal variable values
#' @param y Vector of ordinal variable values
#'
#' @return A list with minimum and maximum possible correlations
#'
compute_bounds <- function(x, y) {
	# Get frequency counts for each variable
	x_counts <- table(factor(x, levels = 0:max(x)))
	y_counts <- table(factor(y, levels = 0:max(y)))
	
	# Calculate theoretical bounds
	r_min <- min_corr_bound(x_counts, y_counts)
	r_max <- max_corr_bound(x_counts, y_counts)
	
	return(list(r_min = r_min, r_max = r_max))
}

#' Rescale a correlation based on theoretical bounds
#'
#' @param r The correlation to rescale
#' @param r_min Minimum possible correlation
#' @param r_max Maximum possible correlation
#'
#' @return The rescaled correlation
#'
rescale_correlation <- function(r, r_min, r_max) {
	if (r < 0) {
		# For negative correlations, rescale between r_min and 0
		if (r_min < 0) {  # Ensure we don't divide by zero
			return((-1 / r_min) * r)
		} else {
			# If r_min >= 0, rescaling negative correlation isn't possible
			return(-1)  # Default to -1 in this edge case
		}
	} else if (r > 0) {
		# For positive correlations, rescale between 0 and r_max
		if (r_max > 0) {  # Ensure we don't divide by zero
			return((1 / r_max) * r)
		} else {
			# If r_max <= 0, rescaling positive correlation isn't possible
			return(1)  # Default to 1 in this edge case
		}
	} else {
		# If correlation is exactly 0, keep it as 0
		return(0)
	}
}

#' Test if a matrix is positive semidefinite
#'
#' @param matrix The matrix to test
#' @param tolerance Numerical tolerance for eigenvalue tests
#'
#' @return TRUE if the matrix is positive semidefinite, FALSE otherwise
#'
is_positive_semidefinite <- function(matrix, tolerance = 1e-10) {
	eigen_values <- eigen(matrix, symmetric = TRUE, only.values = TRUE)$values
	return(min(eigen_values) >= -tolerance)
}

#' Test if a matrix is invertible
#'
#' @param matrix The matrix to test
#' @param tolerance Numerical tolerance for eigenvalue tests
#'
#' @return TRUE if the matrix is invertible, FALSE otherwise
#'
is_invertible <- function(matrix, tolerance = 1e-10) {
	eigen_values <- eigen(matrix, symmetric = TRUE, only.values = TRUE)$values
	return(min(abs(eigen_values)) >= tolerance)
}

#' Compute the condition number of a matrix
#'
#' @param matrix The matrix
#'
#' @return The condition number
#'
condition_number <- function(matrix) {
	eigen_values <- eigen(matrix, symmetric = TRUE, only.values = TRUE)$values
	return(max(eigen_values) / min(eigen_values))
}

# -----------------------------------------------------------------------------
# 3. Simulation function for a single run
# -----------------------------------------------------------------------------

#' Run a single simulation 
#'
#' @param n Number of observations
#' @param categories Vector of category counts for each variable
#' @param cor_strength Base correlation strength
#'
#' @return A list with results
#'
run_simulation <- function(n = 10000, categories = c(3, 4, 5, 6, 7,11), cor_strength = 0.5) {
	# Generate correlation matrix for simulation
	p <- length(categories)
	true_cor <- matrix(cor_strength, nrow = p, ncol = p)
	diag(true_cor) <- 1
	
	# Generate ordinal data
	data_result <- generate_ordinal_data(n, categories, true_cor)
	ordinal_data <- data_result$data
	
	# Calculate observed correlation matrix
	observed_cor <- cor(ordinal_data)
	
	# Calculate theoretical bounds for each pair
	bounds_matrix <- list()
	for (i in 1:(p-1)) {
		for (j in (i+1):p) {
			bounds_matrix[[paste(i, j, sep = "_")]] <- compute_bounds(ordinal_data[, i], ordinal_data[, j])
		}
	}
	
	# Create rescaled correlation matrix
	rescaled_cor <- observed_cor
	for (i in 1:(p-1)) {
		for (j in (i+1):p) {
			# Get bounds for this pair
			bounds <- bounds_matrix[[paste(i, j, sep = "_")]]
			
			# Rescale the correlation
			rescaled_cor[i, j] <- rescale_correlation(observed_cor[i, j], bounds$r_min, bounds$r_max)
			rescaled_cor[j, i] <- rescaled_cor[i, j]  # Ensure symmetry
		}
	}
	
	# Test matrix properties
	observed_psd <- is_positive_semidefinite(observed_cor)
	observed_invertible <- is_invertible(observed_cor)
	observed_condition <- condition_number(observed_cor)
	
	rescaled_psd <- is_positive_semidefinite(rescaled_cor)
	rescaled_invertible <- is_invertible(rescaled_cor)
	rescaled_condition <- condition_number(rescaled_cor)
	
	# Return results
	return(list(
		n = n,
		categories = categories,
		observed_cor = observed_cor,
		rescaled_cor = rescaled_cor,
		bounds = bounds_matrix,
		observed_psd = observed_psd,
		observed_invertible = observed_invertible,
		observed_condition = observed_condition,
		rescaled_psd = rescaled_psd,
		rescaled_invertible = rescaled_invertible,
		rescaled_condition = rescaled_condition
	))
}

# -----------------------------------------------------------------------------
# 4. Run multiple simulations with various parameters
# -----------------------------------------------------------------------------

#' Run multiple simulations with varying parameters
#'
#' @param n_sims Number of simulations to run
#' @param n_obs Vector of sample sizes to test
#' @param category_sets List of category vectors to test
#' @param cor_strengths Vector of correlation strengths to test
#'
#' @return A data frame with simulation results
#'
run_multiple_simulations <- function(n_sims = 100, 
									 n_obs = c(100, 500, 1000), 
									 category_sets = list(
									 	c(2, 3, 4, 5,7),
									 	c(3, 5, 7, 9,11),
									 	c(2, 2, 7, 7,9),
									 	c(4, 4, 4, 4,5),
									 	c(2, 4, 6, 8, 10)
									 ),
									 cor_strengths = c(0.2, 0.5, 0.8)) {
	# Initialize results data frame
	results <- data.frame()
	
	# Parameter combinations
	param_combinations <- expand.grid(
		sim_id = 1:n_sims,
		n_obs = n_obs,
		category_set = 1:length(category_sets),
		cor_strength = cor_strengths
	)
	
	# Run simulations
	total_runs <- nrow(param_combinations)
	cat("Running", total_runs, "simulations...\n")
	
	for (i in 1:total_runs) {
		if (i %% 10 == 0 || i == total_runs) {
			cat("Completed", i, "of", total_runs, "simulations\n")
		}
		
		# Get parameters for this run
		sim_id <- param_combinations$sim_id[i]
		n_obs <- param_combinations$n_obs[i]
		category_set <- category_sets[[param_combinations$category_set[i]]]
		cor_strength <- param_combinations$cor_strength[i]
		
		# Run simulation
		sim_result <- run_simulation(n = n_obs, categories = category_set, cor_strength = cor_strength)
		
		# Extract key results
		result_row <- data.frame(
			sim_id = sim_id,
			n_obs = n_obs,
			category_set = paste(category_set, collapse = ","),
			n_vars = length(category_set),
			cor_strength = cor_strength,
			observed_psd = sim_result$observed_psd,
			observed_invertible = sim_result$observed_invertible,
			observed_condition = sim_result$observed_condition,
			rescaled_psd = sim_result$rescaled_psd,
			rescaled_invertible = sim_result$rescaled_invertible,
			rescaled_condition = sim_result$rescaled_condition,
			properties_differ = sim_result$observed_psd != sim_result$rescaled_psd || 
				sim_result$observed_invertible != sim_result$rescaled_invertible
		)
		
		# Add to results
		results <- rbind(results, result_row)
	}
	
	return(results)
}

# -----------------------------------------------------------------------------
# 5. Analyze simulation results
# -----------------------------------------------------------------------------

#' Summarize and analyze simulation results
#'
#' @param results Data frame of simulation results
#'
#' @return A list containing summary statistics and plots
#'
analyze_simulation_results <- function(results) {
	# Overall summary
	overall <- data.frame(
		total_simulations = nrow(results),
		observed_psd_percent = 100 * mean(results$observed_psd),
		observed_invertible_percent = 100 * mean(results$observed_invertible),
		rescaled_psd_percent = 100 * mean(results$rescaled_psd),
		rescaled_invertible_percent = 100 * mean(results$rescaled_invertible),
		properties_differ_percent = 100 * mean(results$properties_differ),
		mean_observed_condition = mean(results$observed_condition[is.finite(results$observed_condition)]),
		mean_rescaled_condition = mean(results$rescaled_condition[is.finite(results$rescaled_condition)])
	)
	
	# Summary by parameters
	by_n_obs <- results %>%
		group_by(n_obs) %>%
		summarize(
			n_sims = n(),
			observed_psd_percent = 100 * mean(observed_psd),
			rescaled_psd_percent = 100 * mean(rescaled_psd),
			observed_invertible_percent = 100 * mean(observed_invertible),
			rescaled_invertible_percent = 100 * mean(rescaled_invertible),
			properties_differ_percent = 100 * mean(properties_differ)
		)
	
	by_category_set <- results %>%
		group_by(category_set) %>%
		summarize(
			n_sims = n(),
			n_vars = first(n_vars),
			observed_psd_percent = 100 * mean(observed_psd),
			rescaled_psd_percent = 100 * mean(rescaled_psd),
			observed_invertible_percent = 100 * mean(observed_invertible),
			rescaled_invertible_percent = 100 * mean(rescaled_invertible),
			properties_differ_percent = 100 * mean(properties_differ)
		)
	
	by_cor_strength <- results %>%
		group_by(cor_strength) %>%
		summarize(
			n_sims = n(),
			observed_psd_percent = 100 * mean(observed_psd),
			rescaled_psd_percent = 100 * mean(rescaled_psd),
			observed_invertible_percent = 100 * mean(observed_invertible),
			rescaled_invertible_percent = 100 * mean(rescaled_invertible),
			properties_differ_percent = 100 * mean(properties_differ)
		)
	
	# Create plots
	# 1. Overall comparison plot
	plot_data <- data.frame(
		Property = rep(c("Positive Semidefinite", "Invertible"), 2),
		Type = c(rep("Original", 2), rep("Rescaled", 2)),
		Percentage = c(
			overall$observed_psd_percent, overall$observed_invertible_percent,
			overall$rescaled_psd_percent, overall$rescaled_invertible_percent
		)
	)
	
	p1 <- ggplot(plot_data, aes(x = Property, y = Percentage, fill = Type)) +
		geom_bar(stat = "identity", position = "dodge") +
		geom_text(aes(label = sprintf("%.1f%%", Percentage)), 
				  position = position_dodge(width = 0.9), vjust = -0.5) +
		scale_fill_manual(values = c("Original" = "skyblue", "Rescaled" = "coral")) +
		labs(title = "Matrix Properties: Original vs. Rescaled",
			 subtitle = paste("Based on", overall$total_simulations, "simulations"),
			 y = "Percentage of Matrices", x = "") +
		theme_minimal() +
		ylim(0, 110)  # Leave room for text labels
	
	# 2. Condition number comparison
	if (sum(is.finite(results$observed_condition) & is.finite(results$rescaled_condition)) > 0) {
		cond_data <- results %>% 
			filter(is.finite(observed_condition) & is.finite(rescaled_condition))
		
		p2 <- ggplot(cond_data, aes(x = observed_condition, y = rescaled_condition)) +
			geom_point(aes(color = factor(n_vars)), alpha = 0.7) +
			geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray") +
			labs(title = "Condition Numbers: Original vs. Rescaled",
				 x = "Original Matrix", y = "Rescaled Matrix",
				 color = "Number of Variables") +
			theme_minimal() +
			coord_equal()
	} else {
		p2 <- NULL
	}
	
	# 3. Properties by category set
	p3 <- ggplot(by_category_set, aes(x = category_set, y = observed_psd_percent, fill = "Original")) +
		geom_bar(stat = "identity", position = "dodge", alpha = 0.7) +
		geom_bar(aes(y = rescaled_psd_percent, fill = "Rescaled"), stat = "identity", 
				 position = position_dodge(width = 0.9), alpha = 0.7) +
		labs(title = "Positive Semidefiniteness by Category Set",
			 x = "Category Set", y = "Percentage of PSD Matrices",
			 fill = "Matrix Type") +
		scale_fill_manual(values = c("Original" = "skyblue", "Rescaled" = "coral")) +
		theme_minimal() +
		theme(axis.text.x = element_text(angle = 45, hjust = 1))
	
	# Return results
	return(list(
		overall = overall,
		by_n_obs = by_n_obs,
		by_category_set = by_category_set,
		by_cor_strength = by_cor_strength,
		plot_overall = p1,
		plot_condition = p2,
		plot_by_category = p3
	))
}

# -----------------------------------------------------------------------------
# 6. Detailed investigation of a single case
# -----------------------------------------------------------------------------

#' Investigate a specific case in depth
#'
#' @param categories Vector of category counts for each variable
#' @param n_obs Number of observations
#' @param cor_strength Base correlation strength
#'
#' @return A list with detailed analysis
#'
investigate_specific_case <- function(categories = c(2, 4, 6, 8,9,11), n_obs = 1000, cor_strength = 0.5) {
	# Run simulation
	cat("Running detailed investigation with categories:", paste(categories, collapse = ", "), "\n")
	sim_result <- run_simulation(n = n_obs, categories = categories, cor_strength = cor_strength)
	
	# Print detailed results
	cat("\nOriginal correlation matrix:\n")
	print(round(sim_result$observed_cor, 3))
	
	cat("\nRescaled correlation matrix:\n")
	print(round(sim_result$rescaled_cor, 3))
	
	cat("\nTheoretical bounds for each pair:\n")
	for (pair in names(sim_result$bounds)) {
		bounds <- sim_result$bounds[[pair]]
		cat(pair, ": r_min =", round(bounds$r_min, 3), ", r_max =", round(bounds$r_max, 3), "\n")
	}
	
	cat("\nMatrix properties:\n")
	cat("Original matrix is positive semidefinite:", sim_result$observed_psd, "\n")
	cat("Original matrix is invertible:", sim_result$observed_invertible, "\n")
	cat("Original matrix condition number:", sim_result$observed_condition, "\n")
	cat("Rescaled matrix is positive semidefinite:", sim_result$rescaled_psd, "\n")
	cat("Rescaled matrix is invertible:", sim_result$rescaled_invertible, "\n")
	cat("Rescaled matrix condition number:", sim_result$rescaled_condition, "\n")
	
	# Create visualizations
	# 1. Heatmap of original correlation matrix
	orig_df <- reshape2::melt(sim_result$observed_cor)
	names(orig_df) <- c("Var1", "Var2", "value")
	
	p1 <- ggplot(orig_df, aes(x = Var1, y = Var2, fill = value)) +
		geom_tile() +
		scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0,
							 limits = c(-1, 1), name = "Correlation") +
		theme_minimal() +
		labs(title = "Original Correlation Matrix")
	
	# 2. Heatmap of rescaled correlation matrix
	rescaled_df <- reshape2::melt(sim_result$rescaled_cor)
	names(rescaled_df) <- c("Var1", "Var2", "value")
	
	p2 <- ggplot(rescaled_df, aes(x = Var1, y = Var2, fill = value)) +
		geom_tile() +
		scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0,
							 limits = c(-1, 1), name = "Correlation") +
		theme_minimal() +
		labs(title = "Rescaled Correlation Matrix")
	
	# 3. Heatmap of differences
	diff_matrix <- sim_result$rescaled_cor - sim_result$observed_cor
	diff_df <- reshape2::melt(diff_matrix)
	names(diff_df) <- c("Var1", "Var2", "value")
	
	p3 <- ggplot(diff_df, aes(x = Var1, y = Var2, fill = value)) +
		geom_tile() +
		scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0,
							 name = "Difference") +
		theme_minimal() +
		labs(title = "Difference (Rescaled - Original)")
	
	# Display plots
	grid.arrange(p1, p2, p3, ncol = 3)
	
	# Return the detailed results
	return(sim_result)
}

# -----------------------------------------------------------------------------
# 7. Main execution
# -----------------------------------------------------------------------------

# Run a detailed investigation of a single case
cat("========================================================\n")
cat("PART 1: DETAILED INVESTIGATION OF A SINGLE CASE\n")
cat("========================================================\n\n")

detailed_result <- investigate_specific_case(categories = c(2, 4, 6, 8, 9, 11), n_obs = 1000)

# Run multiple simulations
cat("\n========================================================\n")
cat("PART 2: MULTIPLE SIMULATIONS\n")
cat("========================================================\n\n")

simulation_results <- run_multiple_simulations(
	n_sims = 5,  # Small number for quick demonstration
	n_obs = c(100, 500, 1000),
	category_sets = list(
		c(2, 3, 4, 5),       # Different categories for each variable
		c(3, 5, 7, 9),       # Different odd categories
		c(2, 2, 7, 7),       # Mix of binary and multi-category
		c(4, 4, 4, 4),       # Equal categories (symmetric case)
		c(2, 4, 6, 8, 10)    # Increasing even categories
	),
	cor_strengths = c(0.2, 0.5, 0.8)
)

# Analyze results
cat("\n========================================================\n")
cat("PART 3: ANALYSIS OF SIMULATION RESULTS\n")
cat("========================================================\n\n")

analysis <- analyze_simulation_results(simulation_results)

# Print summary
cat("Overall Summary:\n")
print(analysis$overall)

cat("\nSummary by Sample Size:\n")
print(analysis$by_n_obs)

cat("\nSummary by Category Set:\n")
print(analysis$by_category_set)

cat("\nSummary by Correlation Strength:\n")
print(analysis$by_cor_strength)

# Display plots
print(analysis$plot_overall)
if (!is.null(analysis$plot_condition)) print(analysis$plot_condition)
print(analysis$plot_by_category)

# Conclusions
cat("\n========================================================\n")
cat("PART 4: CONCLUSIONS\n")
cat("========================================================\n\n")

cat("Based on", analysis$overall$total_simulations, "simulations with complete data:\n\n")

if (analysis$overall$observed_psd_percent == 100) {
	cat("1. Original correlation matrices are always positive semidefinite, as expected\n")
} else {
	cat("1. WARNING: Some original correlation matrices are not positive semidefinite\n")
	cat("   This may indicate a numerical issue in the simulation\n")
}

if (analysis$overall$rescaled_psd_percent == 100) {
	cat("2. Rescaled correlation matrices are always positive semidefinite\n")
	cat("   This indicates rescaling preserves this important property\n")
} else {
	cat("2. Some rescaled correlation matrices are not positive semidefinite\n")
	cat("   This suggests rescaling may not always preserve this property\n")
}

if (analysis$overall$observed_invertible_percent == analysis$overall$rescaled_invertible_percent) {
	cat("3. Rescaling does not affect matrix invertibility\n")
} else if (analysis$overall$observed_invertible_percent < analysis$overall$rescaled_invertible_percent) {
	cat("3. Rescaling improves matrix invertibility\n")
} else {
	cat("3. Rescaling reduces matrix invertibility\n")
}

if (analysis$overall$mean_observed_condition > analysis$overall$mean_rescaled_condition) {
	cat("4. Rescaling improves the condition number (from", 
		round(analysis$overall$mean_observed_condition, 2), "to",
		round(analysis$overall$mean_rescaled_condition, 2), "on average)\n")
} else if (analysis$overall$mean_observed_condition < analysis$overall$mean_rescaled_condition) {
	cat("4. Rescaling worsens the condition number (from", 
		round(analysis$overall$mean_observed_condition, 2), "to",
		round(analysis$overall$mean_rescaled_condition, 2), "on average)\n")
} else {
	cat("4. Rescaling has no significant effect on the condition number\n")
}

cat("\nFinal conclusion: When working with complete data, rescaling correlations\n")
cat("between ordinal variables with different numbers of categories appears to\n")
if (analysis$overall$properties_differ_percent == 0) {
	cat("preserve all important mathematical properties of the correlation matrix.\n")
} else {
	cat("affect some mathematical properties of the correlation matrix.\n")
}