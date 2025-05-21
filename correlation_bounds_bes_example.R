# correlation_bounds_bes_example.R
#
# Example usage of the correlation bounds functions with BES data
#
# Author: [Your Name]
# Date: March 2, 2025

# Load required libraries
library(dplyr)
library(ggplot2)
library(gridExtra)

# Source the required functions
source("correlation_bounds_core.R")
source("correlation_bounds_bes.R")

# Example data row (based on the provided example)
create_example_row <- function() {
	row <- list(
		var1 = 1,
		var2 = 117,
		cov = 0.2549444,
		variance1 = 0.5705637,
		variance2 = 4.846892,
		nobs = 1979,
		var1mean = 2.014654,
		var1st_dev = 0.7553567,
		var1skewness = 0.4897322,
		var1kurtosis = 3.075024,
		var1min = 1,
		var1max = 4,
		var1nobs_su = 1979,
		var2mean = 2.576554,
		var2st_dev = 2.201566,
		var2skewness = 1.023969,
		var2kurtosis = 4.127645,
		var2min = 0,
		var2max = 10,
		var2nobs_su = 1979,
		var1q75 = 2.661652,
		var1q50 = 1.971539,
		var1q25 = 1.331501,
		var2q75 = 3.81446,
		var2q50 = 2.308609,
		var2q25 = 0.8509545,
		var1freq0 = 0,
		var1freq1 = 477,
		var1freq2 = 1069,
		var1freq3 = 360,
		var1freq4 = 73,
		var1freq5 = 0,
		var1freq6 = 0,
		var1freq7 = 0,
		var1freq8 = 0,
		var1freq9 = 0,
		var1freq10 = 0,
		var2freq0 = 410,
		var2freq1 = 271,
		var2freq2 = 384,
		var2freq3 = 371,
		var2freq4 = 203,
		var2freq5 = 178,
		var2freq6 = 37,
		var2freq7 = 48,
		var2freq8 = 37,
		var2freq9 = 9,
		var2freq10 = 31,
		corr = 0.1533069,
		var1ftots = 1979,
		var2ftots = 1979,
		var1prop0 = 0,
		var1prop1 = 0.2410308,
		var1prop2 = 0.5401718,
		var1prop3 = 0.1819101,
		var1prop4 = 0.03688732,
		var1prop5 = 0,
		var1prop6 = 0,
		var1prop7 = 0,
		var1prop8 = 0,
		var1prop9 = 0,
		var1prop10 = 0,
		var2prop0 = 0.2071753,
		var2prop1 = 0.1369378,
		var2prop2 = 0.1940374,
		var2prop3 = 0.1874684,
		var2prop4 = 0.1025771,
		var2prop5 = 0.08994441,
		var2prop6 = 0.01869631,
		var2prop7 = 0.02425467,
		var2prop8 = 0.01869631,
		var2prop9 = 0.004547752,
		var2prop10 = 0.01566448,
		diff_means = 0.5618999,
		diff_imedians = 0.3370697,
		var1iqr = 1.330151,
		var2iqr = 2.963506,
		var1cats = 4,
		var2cats = 11
	)
	
	# Convert to data frame
	row_df <- as.data.frame(row)
	
	return(row_df)
}

# Function to demonstrate usage with a single row
demonstrate_single_row <- function() {
	# Create example row
	row_df <- create_example_row()
	
	# Analysis with frequency counts
	cat("Analyzing with frequency counts:\n")
	result_freq <- analyze_corr_bounds(row_df, nsim = 1000, return_simulations = TRUE)
	
	# Print key results
	cat("\nKey results:\n")
	cat("Theoretical minimum correlation:", round(result_freq$r_min, 4), "\n")
	cat("Theoretical maximum correlation:", round(result_freq$r_max, 4), "\n")
	cat("95% CI lower bound:", round(result_freq$ci_lower, 4), "\n")
	cat("95% CI upper bound:", round(result_freq$ci_upper, 4), "\n")
	cat("Observed correlation:", round(result_freq$observed_r, 4), "\n")
	cat("Rescaled correlation:", round(result_freq$r_rescaled, 4), "\n")
	cat("Variable 1 starts at category:", result_freq$var1_start, "\n")
	cat("Variable 2 starts at category:", result_freq$var2_start, "\n")
	
	# Visualize the results
	cat("\nGenerating visualization...\n")
	plot <- visualize_corr_bounds(result_freq)
	print(plot)
	
	# Analysis with proportions
	cat("\nAnalyzing with proportions:\n")
	result_prop <- analyze_corr_bounds(row_df, nsim = 1000, use_prop = TRUE, return_simulations = TRUE)
	
	# Check if results are similar
	cat("\nChecking if results are similar between frequencies and proportions:\n")
	cat("r_min difference:", abs(result_freq$r_min - result_prop$r_min), "\n")
	cat("r_max difference:", abs(result_freq$r_max - result_prop$r_max), "\n")
	cat("r_rescaled difference:", abs(result_freq$r_rescaled - result_prop$r_rescaled), "\n")
	
	return(list(freq = result_freq, prop = result_prop))
}

# Function to demonstrate batch processing with multiple rows
demonstrate_batch_processing <- function(n_rows = 5) {
	# Create multiple rows by modifying the original example
	rows_list <- list()
	example_row <- create_example_row()
	
	for (i in 1:n_rows) {
		# Make a copy of the example row
		new_row <- example_row
		
		# Modify some values to create variation
		new_row$var1 <- i
		new_row$var2 <- 100 + i
		new_row$corr <- example_row$corr + (i - 3) * 0.05  # Vary correlation
		
		# Adjust marginals slightly
		freq_shift <- round(i * 20)
		if (new_row$var1freq2 > freq_shift) {
			new_row$var1freq1 <- new_row$var1freq1 + freq_shift
			new_row$var1freq2 <- new_row$var1freq2 - freq_shift
		}
		
		rows_list[[i]] <- new_row
	}
	
	# Combine into a data frame
	multi_rows <- do.call(rbind, rows_list)
	
	# Process all rows
	cat("Processing", n_rows, "rows...\n")
	all_results <- analyze_all_corr_bounds(multi_rows, nsim = 500)
	
	# Generate summary
	cat("\nGenerating summary...\n")
	summary_report <- generate_bounds_summary(all_results)
	
	# Print summary
	cat("\nSummary Report:\n")
	print(summary_report[, c("var1", "var2", "observed_r", "r_min", "r_max", "outside_ci", "rel_position")])
	
	# Create plots
	cat("\nCreating visualization plots...\n")
	bounds_plot <- plot_correlation_bounds_scatter(summary_report, "bounds")
	ci_plot <- plot_correlation_bounds_scatter(summary_report, "ci")
	
	grid.arrange(bounds_plot, ci_plot, ncol = 2)
	
	return(summary_report)
}

# Run demonstrations if this file is executed directly
if (!interactive()) {
	cat("========================================\n")
	cat("DEMONSTRATION: SINGLE ROW ANALYSIS\n")
	cat("========================================\n\n")
	single_results <- demonstrate_single_row()
	
	cat("\n\n========================================\n")
	cat("DEMONSTRATION: BATCH PROCESSING\n")
	cat("========================================\n\n")
	batch_results <- demonstrate_batch_processing(5)
	
	cat("\n\n========================================\n")
	cat("DEMONSTRATION: SIGNIFICANCE TEST COMPARISON\n")
	cat("========================================\n\n")
	
	# Generate more diverse sample for significance comparison
	n_rows <- 20
	rows_list <- list()
	example_row <- create_example_row()
	
	for (i in 1:n_rows) {
		# Make a copy of the example row
		new_row <- example_row
		
		# Modify values to create more variation
		new_row$var1 <- i
		new_row$var2 <- 100 + i
		
		# Vary correlation (some high, some low, some near zero)
		if (i < 7) {
			new_row$corr <- 0.05 + i * 0.01  # Low correlations
		} else if (i < 14) {
			new_row$corr <- 0.2 + (i - 7) * 0.03  # Medium correlations
		} else {
			new_row$corr <- 0.4 + (i - 14) * 0.05  # Higher correlations
		}
		
		# Vary sample size (some near boundary of significance)
		new_row$nobs <- round(500 + (i - 10)^2 * 30)
		
		# Adjust the marginals to ensure they sum to the new nobs
		scaling_factor <- new_row$nobs / sum(example_row$var1freq1, example_row$var1freq2, 
											 example_row$var1freq3, example_row$var1freq4)
		
		new_row$var1freq1 <- round(example_row$var1freq1 * scaling_factor)
		new_row$var1freq2 <- round(example_row$var1freq2 * scaling_factor)
		new_row$var1freq3 <- round(example_row$var1freq3 * scaling_factor)
		new_row$var1freq4 <- round(example_row$var1freq4 * scaling_factor)
		
		# Adjust to make sure sum is exact
		total <- sum(new_row$var1freq1, new_row$var1freq2, new_row$var1freq3, new_row$var1freq4)
		diff <- new_row$nobs - total
		new_row$var1freq2 <- new_row$var1freq2 + diff
		
		# Do the same for var2
		scaling_factor <- new_row$nobs / sum(example_row$var2freq0, example_row$var2freq1, 
											 example_row$var2freq2, example_row$var2freq3,
											 example_row$var2freq4, example_row$var2freq5,
											 example_row$var2freq6, example_row$var2freq7,
											 example_row$var2freq8, example_row$var2freq9,
											 example_row$var2freq10)
		
		for (j in 0:10) {
			col_name <- paste0("var2freq", j)
			new_row[[col_name]] <- round(example_row[[col_name]] * scaling_factor)
		}
		
		# Adjust to make sure sum is exact
		total <- sum(new_row$var2freq0, new_row$var2freq1, new_row$var2freq2, new_row$var2freq3,
					 new_row$var2freq4, new_row$var2freq5, new_row$var2freq6, new_row$var2freq7,
					 new_row$var2freq8, new_row$var2freq9, new_row$var2freq10)
		diff <- new_row$nobs - total
		new_row$var2freq2 <- new_row$var2freq2 + diff
		
		rows_list[[i]] <- new_row
	}
	
	# Combine into a data frame
	sig_test_df <- do.call(rbind, rows_list)
	
	# Process all rows
	cat("Processing", n_rows, "rows for significance test comparison...\n")
	sig_results <- analyze_all_corr_bounds(sig_test_df, nsim = 1000)
	
	# Generate summary with significance comparison
	cat("\nGenerating significance comparison summary...\n")
	sig_summary <- generate_bounds_summary(sig_results)
	
	# Print summary of significance comparisons
	cat("\nSignificance Test Comparison:\n")
	sig_table <- table(sig_summary$significance_difference)
	print(sig_table)
	
	cat("\nPercentage where t-test and randomization test disagree:", 
		round(100 * sum(sig_summary$significance_difference %in% c("t-test only", "Randomization only")) / nrow(sig_summary), 1),
		"%\n")
	
	# Create comparison plots
	cat("\nCreating significance comparison visualizations...\n")
	plot_significance_comparison(sig_summary)
	
	# Plot relationship between bounds and significance
	p_bounds <- plot_bounds_significance(sig_summary)
	print(p_bounds)
	
	# Plot comparison between observed and rescaled correlations
	cat("\nCreating rescaled correlation visualization...\n")
	p_rescaled <- plot_rescaled_comparison(sig_summary)
	print(p_rescaled)
}