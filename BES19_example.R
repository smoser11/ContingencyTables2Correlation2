library(readstata13)
bes19 <- read.dta13("correlation and other data about pairs of BES2019 variables.dta")

# correlation_bounds_bes.R
#
# Function to calculate correlation bounds for BES 2019 ordinal variables
#
# Author: [Your Name]
# Date: March 2, 2025

# Load required libraries
library(dplyr)

# Source the core functions
# Adjust the path as needed
source("correlation_bounds_core.R")

#' Calculate correlation bounds for a pair of ordinal variables
#'
#' This function takes the marginal distributions of two ordinal variables 
#' and calculates the theoretical bounds (minimum and maximum) of Pearson's 
#' correlation coefficient, as well as the empirical bounds from the 
#' permutation distribution.
#'
#' @param row A data frame row containing the marginal frequencies for two variables
#' @param nsim Number of simulations for the permutation distribution (default: 1000)
#' @param use_prop Logical; if TRUE, use proportion columns instead of frequency columns (default: FALSE)
#' @param return_simulations Logical; if TRUE, return the simulated r values (default: FALSE)
#'
#' @return A list containing the theoretical bounds, empirical bounds, and optionally the simulated values
#'
#' @examples
#' # Assuming 'bes_data' is your data frame
#' results <- analyze_corr_bounds(bes_data[1, ])
analyze_corr_bounds <- function(row, nsim = 1000, use_prop = FALSE, return_simulations = FALSE) {
	# Extract the number of categories for each variable
	var1_cats <- row$var1cats
	var2_cats <- row$var2cats
	
	# Extract the number of observations
	n_obs <- row$nobs
	
	# Extract the marginal distributions, handling variables that start at either 0 or 1
	if (use_prop) {
		# Use proportions if requested
		var1_marginals <- c()
		var2_marginals <- c()
		
		# Determine start category for var1 (0 or 1)
		var1_start <- ifelse("var1prop0" %in% names(row) && !is.na(row$var1prop0) && row$var1prop0 > 0, 0, 1)
		var1_end <- var1_start + var1_cats - 1
		
		for (i in var1_start:var1_end) {
			prop_col <- paste0("var1prop", i)
			if (prop_col %in% names(row) && !is.na(row[[prop_col]])) {
				var1_marginals <- c(var1_marginals, row[[prop_col]])
			} else {
				var1_marginals <- c(var1_marginals, 0)  # Add 0 for missing categories
			}
		}
		
		# Determine start category for var2 (0 or 1)
		var2_start <- ifelse("var2prop0" %in% names(row) && !is.na(row$var2prop0) && row$var2prop0 > 0, 0, 1)
		var2_end <- var2_start + var2_cats - 1
		
		for (i in var2_start:var2_end) {
			prop_col <- paste0("var2prop", i)
			if (prop_col %in% names(row) && !is.na(row[[prop_col]])) {
				var2_marginals <- c(var2_marginals, row[[prop_col]])
			} else {
				var2_marginals <- c(var2_marginals, 0)  # Add 0 for missing categories
			}
		}
	} else {
		# Use frequencies (default)
		var1_marginals <- c()
		var2_marginals <- c()
		
		# Determine start category for var1 (0 or 1)
		var1_start <- ifelse("var1freq0" %in% names(row) && !is.na(row$var1freq0) && row$var1freq0 > 0, 0, 1)
		var1_end <- var1_start + var1_cats - 1
		
		for (i in var1_start:var1_end) {
			freq_col <- paste0("var1freq", i)
			if (freq_col %in% names(row) && !is.na(row[[freq_col]])) {
				var1_marginals <- c(var1_marginals, row[[freq_col]])
			} else {
				var1_marginals <- c(var1_marginals, 0)  # Add 0 for missing categories
			}
		}
		
		# Determine start category for var2 (0 or 1)
		var2_start <- ifelse("var2freq0" %in% names(row) && !is.na(row$var2freq0) && row$var2freq0 > 0, 0, 1)
		var2_end <- var2_start + var2_cats - 1
		
		for (i in var2_start:var2_end) {
			freq_col <- paste0("var2freq", i)
			if (freq_col %in% names(row) && !is.na(row[[freq_col]])) {
				var2_marginals <- c(var2_marginals, row[[freq_col]])
			} else {
				var2_marginals <- c(var2_marginals, 0)  # Add 0 for missing categories
			}
		}
	}
	
	# Remove any NAs and ensure non-negative values
	var1_marginals <- pmax(0, var1_marginals, na.rm = TRUE)
	var2_marginals <- pmax(0, var2_marginals, na.rm = TRUE)
	
	# Skip if we have empty marginals
	if (sum(var1_marginals) == 0 || sum(var2_marginals) == 0) {
		warning("Empty marginal distributions detected.")
		return(list(
			r_min = NA,
			r_max = NA,
			ci_lower = NA,
			ci_upper = NA,
			observed_r = row$corr,
			success = FALSE,
			message = "Empty marginal distributions"
		))
	}
	
	# Calculate theoretical bounds
	r_min <- min_corr_bound(var1_marginals, var2_marginals, sample_size = n_obs)
	r_max <- max_corr_bound(var1_marginals, var2_marginals, sample_size = n_obs)
	
	# Simulate permutation distribution
	r_sim <- simulate_permutation_distribution(var1_marginals, var2_marginals, 
											   nsim = nsim, sample_size = n_obs)
	
	# Calculate 95% confidence interval
	ci_bounds <- quantile(r_sim, probs = c(0.025, 0.975))
	
	# Prepare results
	result <- list(
		r_min = r_min,
		r_max = r_max,
		ci_lower = ci_bounds[1],
		ci_upper = ci_bounds[2],
		observed_r = row$corr,
		success = TRUE,
		var1_categories = var1_cats,
		var2_categories = var2_cats,
		n_obs = n_obs,
		var1_start = var1_start,
		var2_start = var2_start,
		var1_marginals = var1_marginals,
		var2_marginals = var2_marginals
	)
	
	# Add simulations if requested
	if (return_simulations) {
		result$simulations <- r_sim
	}
	
	return(result)
}

#' Apply correlation bounds analysis to an entire data frame
#'
#' This function applies the analyze_corr_bounds function to each row of a data frame,
#' allowing for batch processing of many variable pairs.
#'
#' @param df A data frame where each row represents a pair of ordinal variables
#' @param nsim Number of simulations for the permutation distribution (default: 1000)
#' @param use_prop Logical; if TRUE, use proportion columns instead of frequency columns (default: FALSE)
#' @param return_simulations Logical; if TRUE, return the simulated r values (default: FALSE)
#' @param progress Logical; if TRUE, display a progress indicator (default: TRUE)
#'
#' @return A data frame with correlation bounds analysis results for each row
#'
#' @examples
#' # Assuming 'bes_data' is your data frame
#' all_results <- analyze_all_corr_bounds(bes_data)
analyze_all_corr_bounds <- function(df, nsim = 1000, use_prop = FALSE, 
									return_simulations = FALSE, progress = TRUE) {
	# Initialize results list
	results_list <- list()
	
	# Progress tracking
	n_rows <- nrow(df)
	if (progress) cat("Processing", n_rows, "variable pairs...\n")
	
	# Process each row
	for (i in 1:n_rows) {
		if (progress && i %% 100 == 0) cat("Processed", i, "of", n_rows, "pairs\n")
		
		# Extract row
		row <- df[i, ]
		
		# Analyze bounds
		bounds_result <- analyze_corr_bounds(row, nsim = nsim, use_prop = use_prop, 
											 return_simulations = return_simulations)
		
		# Add original variables
		bounds_result$var1 <- row$var1
		bounds_result$var2 <- row$var2
		
		# Store results
		results_list[[i]] <- bounds_result
	}
	
	# Convert list to data frame, managing nested structures
	results_df <- data.frame(
		var1 = sapply(results_list, function(x) x$var1),
		var2 = sapply(results_list, function(x) x$var2),
		r_min = sapply(results_list, function(x) x$r_min),
		r_max = sapply(results_list, function(x) x$r_max),
		ci_lower = sapply(results_list, function(x) x$ci_lower),
		ci_upper = sapply(results_list, function(x) x$ci_upper),
		observed_r = sapply(results_list, function(x) x$observed_r),
		var1_categories = sapply(results_list, function(x) x$var1_categories),
		var2_categories = sapply(results_list, function(x) x$var2_categories),
		var1_start = sapply(results_list, function(x) x$var1_start),
		var2_start = sapply(results_list, function(x) x$var2_start),
		n_obs = sapply(results_list, function(x) x$n_obs),
		success = sapply(results_list, function(x) x$success)
	)
	
	# Add simulations if requested (as a list column)
	if (return_simulations) {
		results_df$simulations <- lapply(results_list, function(x) x$simulations)
	}
	
	return(results_df)
}

#' Visualize correlation bounds for a single variable pair
#'
#' Creates a visualization of the permutation distribution, theoretical bounds,
#' confidence interval, and observed correlation for a single pair of variables.
#'
#' @param result The result from analyze_corr_bounds or a row from analyze_all_corr_bounds
#' @param title Optional custom title for the plot
#'
#' @return A ggplot2 object
#'
#' @examples
#' # For a single result
#' result <- analyze_corr_bounds(bes_data[1, ], return_simulations = TRUE)
#' plot <- visualize_corr_bounds(result)
#' print(plot)
visualize_corr_bounds <- function(result, title = NULL) {
	# Check if simulations are present
	if (is.null(result$simulations)) {
		stop("Simulations not found in result. Please re-run analyze_corr_bounds with return_simulations = TRUE.")
	}
	
	# Create a data frame for the simulations
	df <- data.frame(r = result$simulations)
	
	# Set x-axis limits to include r_min, r_max, and observed_r
	x_lower <- min(result$r_min, quantile(result$simulations, 0.01), result$observed_r) - 0.05
	x_upper <- max(result$r_max, quantile(result$simulations, 0.99), result$observed_r) + 0.05
	
	# Create data frame for vertical lines
	vlines <- data.frame(
		xintercept = c(result$r_min, result$r_max, result$ci_lower, result$ci_upper, result$observed_r),
		label = factor(c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper", "Observed Correlation"),
					   levels = c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper", "Observed Correlation"))
	)
	
	# Generate default title if none provided
	if (is.null(title)) {
		title <- paste0("Correlation Bounds Analysis: ", 
						result$var1, " vs ", result$var2,
						" (n=", result$n_obs, ")")
	}
	
	# Create the plot
	p <- ggplot(df, aes(x = r)) +
		geom_histogram(aes(y = ..density..), bins = 30,
					   fill = "lightblue", color = "white", alpha = 0.7) +
		geom_density(color = "darkblue", size = 1) +
		geom_vline(data = vlines,
				   aes(xintercept = xintercept, color = label, linetype = label),
				   size = 1) +
		scale_color_manual(name = "Reference Lines", 
						   values = c("Theoretical Min" = "red", 
						   		   "Theoretical Max" = "green", 
						   		   "95% CI Lower" = "purple", 
						   		   "95% CI Upper" = "purple",
						   		   "Observed Correlation" = "black")) +
		scale_linetype_manual(name = "Reference Lines",
							  values = c("Theoretical Min" = "dashed", 
							  		   "Theoretical Max" = "dashed", 
							  		   "95% CI Lower" = "dotted", 
							  		   "95% CI Upper" = "dotted",
							  		   "Observed Correlation" = "solid")) +
		labs(title = title,
			 subtitle = paste0("Theoretical range: [", round(result$r_min, 3), ", ", round(result$r_max, 3), "]",
			 				  "\nEmpirical 95% CI: [", round(result$ci_lower, 3), ", ", round(result$ci_upper, 3), "]",
			 				  "\nObserved r: ", round(result$observed_r, 3)),
			 x = "Pearson's r",
			 y = "Density") +
		xlim(x_lower, x_upper) +
		theme_minimal()
	
	return(p)
}

#' Generate a summary report for correlation bounds analysis
#'
#' Creates a data frame with summary statistics comparing observed correlations
#' with theoretical bounds and permutation confidence intervals.
#'
#' @param results_df The results data frame from analyze_all_corr_bounds
#'
#' @return A data frame with summary statistics
#'
#' @examples
#' # Assuming 'all_results' is the output from analyze_all_corr_bounds
#' summary_report <- generate_bounds_summary(all_results)
generate_bounds_summary <- function(results_df) {
	# Calculate statistics
	results_df <- results_df %>%
		filter(success == TRUE) %>%
		mutate(
			# Distance from observed to bounds
			distance_to_min = observed_r - r_min,
			distance_to_max = r_max - observed_r,
			
			# Check if observed is outside theoretical bounds (shouldn't happen)
			outside_bounds = observed_r < r_min | observed_r > r_max,
			
			# Check if observed is outside empirical CI (indicates significance)
			outside_ci = observed_r < ci_lower | observed_r > ci_upper,
			
			# Theoretical range
			theo_range = r_max - r_min,
			
			# Empirical range (CI width)
			emp_range = ci_upper - ci_lower,
			
			# Position within theoretical range (0 = at min, 1 = at max)
			rel_position = (observed_r - r_min) / (r_max - r_min),
			
			# Bounds width ratio (empirical CI width as proportion of theoretical range)
			bounds_ratio = emp_range / theo_range
		)
	
	return(results_df)
}

#' Create a scatter plot of observed correlations vs bounds or CI
#'
#' @param summary_df The results data frame from generate_bounds_summary
#' @param plot_type Type of plot: "bounds" for theoretical, "ci" for confidence interval
#'
#' @return A ggplot2 object
#'
#' @examples
#' # Assuming 'summary_report' is the output from generate_bounds_summary
#' plot <- plot_correlation_bounds_scatter(summary_report, "bounds")
#' print(plot)
plot_correlation_bounds_scatter <- function(summary_df, plot_type = c("bounds", "ci")) {
	plot_type <- match.arg(plot_type)
	
	if (plot_type == "bounds") {
		# Plot observed correlations against theoretical bounds
		p <- ggplot(summary_df) +
			geom_segment(aes(x = r_min, xend = r_max, y = observed_r, yend = observed_r), 
						 alpha = 0.3, color = "grey") +
			geom_point(aes(x = r_min, y = observed_r), color = "red", alpha = 0.6) +
			geom_point(aes(x = r_max, y = observed_r), color = "green", alpha = 0.6) +
			geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "blue") +
			labs(title = "Observed Correlations vs. Theoretical Bounds",
				 x = "Theoretical Bounds (Min = Red, Max = Green)",
				 y = "Observed Correlation") +
			theme_minimal() +
			coord_equal()
	} else {
		# Plot observed correlations against empirical CI
		p <- ggplot(summary_df) +
			geom_segment(aes(x = ci_lower, xend = ci_upper, y = observed_r, yend = observed_r), 
						 alpha = 0.3, color = "grey") +
			geom_point(aes(x = ci_lower, y = observed_r), color = "purple", alpha = 0.6) +
			geom_point(aes(x = ci_upper, y = observed_r), color = "purple", alpha = 0.6) +
			geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "blue") +
			labs(title = "Observed Correlations vs. Empirical 95% CI",
				 x = "Empirical 95% Confidence Interval",
				 y = "Observed Correlation") +
			theme_minimal() +
			coord_equal()
	}
	
	return(p)
}

