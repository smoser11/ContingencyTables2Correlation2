#' Summarize correlation matrix test results
#'
#' @param test_results The output from test_random_correlation_matrices
#'
#' @return A data frame with summarized results
#'
#' @examples
#' # Assuming 'matrix_tests' is the output from test_random_correlation_matrices
#' summary <- summarize_matrix_tests(matrix_tests)
summarize_matrix_tests <- function(test_results) {
	# Calculate overall statistics
	summary <- list(
		n_trials = nrow(test_results),
		
		# Original matrix results
		orig_symmetric_count = sum(test_results$orig_symmetric),
		orig_symmetric_percent = 100 * mean(test_results$orig_symmetric),
		orig_unit_diagonal_count = sum(test_results$orig_unit_diagonal),
		orig_unit_diagonal_percent = 100 * mean(test_results$orig_unit_diagonal),
		orig_psd_count = sum(test_results$orig_psd),
		orig_psd_percent = 100 * mean(test_results$orig_psd),
		orig_invertible_count = sum(test_results$orig_invertible),
		orig_invertible_percent = 100 * mean(test_results$orig_invertible),
		orig_valid_count = sum(test_results$orig_valid),
		orig_valid_percent = 100 * mean(test_results$orig_valid),
		orig_mean_condition = mean(test_results$orig_condition[is.finite(test_results$orig_condition)]),
		orig_mean_min_eigenvalue = mean(test_results$orig_min_eigenvalue),
		
		# Rescaled matrix results
		rescaled_symmetric_count = sum(test_results$rescaled_symmetric),
		rescaled_symmetric_percent = 100 * mean(test_results$rescaled_symmetric),
		rescaled_unit_diagonal_count = sum(test_results$rescaled_unit_diagonal),
		rescaled_unit_diagonal_percent = 100 * mean(test_results$rescaled_unit_diagonal),
		rescaled_psd_count = sum(test_results$rescaled_psd),
		rescaled_psd_percent = 100 * mean(test_results$rescaled_psd),
		rescaled_invertible_count = sum(test_results$rescaled_invertible),
		rescaled_invertible_percent = 100 * mean(test_results$rescaled_invertible),
		rescaled_valid_count = sum(test_results$rescaled_valid),
		rescaled_valid_percent = 100 * mean(test_results$rescaled_valid),
		rescaled_mean_condition = mean(test_results$rescaled_condition[is.finite(test_results$rescaled_condition)]),
		rescaled_mean_min_eigenvalue = mean(test_results$rescaled_min_eigenvalue),
		
		# Comparison
		properties_differ_count = sum(test_results$properties_differ),
		properties_differ_percent = 100 * mean(test_results$properties_differ),
		
		# PSD comparison
		psd_differ_count = sum(test_results$orig_psd != test_results$rescaled_psd),
		psd_differ_percent = 100 * mean(test_results$orig_psd != test_results$rescaled_psd),
		
		# Invertibility comparison
		invertible_differ_count = sum(test_results$orig_invertible != test_results$rescaled_invertible),
		invertible_differ_percent = 100 * mean(test_results$orig_invertible != test_results$rescaled_invertible),
		
		# Correlations where rescaled is better
		rescaled_better_psd = sum(!test_results$orig_psd & test_results$rescaled_psd),
		rescaled_better_invertible = sum(!test_results$orig_invertible & test_results$rescaled_invertible),
		
		# Correlations where original is better
		orig_better_psd = sum(test_results$orig_psd & !test_results$rescaled_psd),
		orig_better_invertible = sum(test_results$orig_invertible & !test_results$rescaled_invertible),
		
		# Enforcement of PSD
		psd_enforced = all(test_results$enforce_psd)
	)
	
	# Convert to data frame for nicer printing
	summary_df <- as.data.frame(t(unlist(summary)))
	
	return(summary_df)
}# correlation_matrix_test.R
#
# Functions to test the properties of correlation matrices constructed using
# both original and rescaled correlation coefficients
#
# Author: [Your Name]
# Date: March 2, 2025

# Load required libraries
library(Matrix)
library(matrixcalc)
library(dplyr)

#' Construct a correlation matrix from pairwise correlations
#'
#' @param correlations A data frame with columns var1, var2, and either observed_r or r_rescaled
#' @param use_rescaled Logical; if TRUE, use rescaled correlations instead of observed correlations
#' @param enforce_psd Logical; if TRUE, adjust the matrix to ensure positive semidefiniteness
#'
#' @return A correlation matrix with variables as rows and columns
#'
#' @examples
#' # Assuming 'results_df' is the output from analyze_all_corr_bounds
#' corr_matrix <- construct_correlation_matrix(results_df)
construct_correlation_matrix <- function(correlations, use_rescaled = FALSE, enforce_psd = TRUE) {
	# Identify all unique variables
	all_vars <- unique(c(correlations$var1, correlations$var2))
	n_vars <- length(all_vars)
	
	# Create a mapping from variable names to matrix indices
	var_indices <- setNames(1:n_vars, all_vars)
	
	# Initialize correlation matrix with ones on the diagonal
	corr_matrix <- matrix(0, nrow = n_vars, ncol = n_vars)
	diag(corr_matrix) <- 1
	
	# Track which pairs we've filled in
	pairs_filled <- matrix(FALSE, nrow = n_vars, ncol = n_vars)
	diag(pairs_filled) <- TRUE  # Diagonal is always filled
	
	# Fill in the correlation matrix using either observed or rescaled correlations
	corr_column <- ifelse(use_rescaled, "r_rescaled", "observed_r")
	
	for (i in 1:nrow(correlations)) {
		var1 <- correlations$var1[i]
		var2 <- correlations$var2[i]
		corr_value <- correlations[[corr_column]][i]
		
		# Skip if the correlation value is missing
		if (is.na(corr_value)) next
		
		# Ensure the variables exist in our mapping
		if (var1 %in% all_vars && var2 %in% all_vars) {
			idx1 <- var_indices[var1]
			idx2 <- var_indices[var2]
			
			# Fill both the upper and lower triangles to ensure symmetry
			corr_matrix[idx1, idx2] <- corr_value
			corr_matrix[idx2, idx1] <- corr_value
			
			# Mark as filled
			pairs_filled[idx1, idx2] <- TRUE
			pairs_filled[idx2, idx1] <- TRUE
		}
	}
	
	# Check if all pairs were filled
	if (!all(pairs_filled)) {
		warning("Some variable pairs are missing correlations. The matrix may not be valid.")
	}
	
	# Enforce positive semidefiniteness if requested
	if (enforce_psd) {
		# Check if the matrix is already PSD
		eigen_values <- eigen(corr_matrix, symmetric = TRUE, only.values = TRUE)$values
		
		if (min(eigen_values) < 0) {
			# Matrix is not PSD, perform nearest PSD projection
			# Using eigendecomposition method
			eig <- eigen(corr_matrix, symmetric = TRUE)
			P <- eig$vectors
			L <- eig$values
			
			# Set negative eigenvalues to small positive value
			L[L < 0] <- 1e-8
			
			# Reconstruct matrix
			corr_matrix <- P %*% diag(L) %*% t(P)
			
			# Rescale to ensure diagonal is 1
			D <- diag(1/sqrt(diag(corr_matrix)))
			corr_matrix <- D %*% corr_matrix %*% D
			
			# For numerical stability, ensure exact symmetry and unit diagonal
			corr_matrix <- (corr_matrix + t(corr_matrix)) / 2
			diag(corr_matrix) <- 1
		}
	}
	
	# Name rows and columns for better readability
	rownames(corr_matrix) <- all_vars
	colnames(corr_matrix) <- all_vars
	
	return(corr_matrix)
}

#' Test properties of a correlation matrix
#'
#' @param matrix The correlation matrix to test
#' @param tolerance Numerical tolerance for eigenvalue tests
#'
#' @return A list with test results for symmetry, positive semidefiniteness, invertibility,
#'         and condition number
#'
#' @examples
#' # Assuming 'corr_matrix' is a correlation matrix
#' test_results <- test_matrix_properties(corr_matrix)
test_matrix_properties <- function(matrix, tolerance = 1e-10) {
	# Initialize result list
	results <- list()
	
	# Check symmetry
	results$is_symmetric <- isSymmetric(matrix, tol = tolerance)
	
	# Check diagonal elements are 1
	diag_elements <- diag(matrix)
	results$has_unit_diagonal <- all(abs(diag_elements - 1) < tolerance)
	
	# Ensure the matrix is exactly symmetric (fix tiny numerical issues)
	if (!results$is_symmetric) {
		matrix <- (matrix + t(matrix)) / 2
	}
	
	# Check positive semidefiniteness using eigenvalues
	# A matrix is PSD if all eigenvalues are non-negative
	eigen_values <- eigen(matrix, symmetric = TRUE, only.values = TRUE)$values
	results$min_eigenvalue <- min(eigen_values)
	results$max_eigenvalue <- max(eigen_values)
	
	# Consider numerical tolerance for PSD check
	results$is_positive_semidefinite <- results$min_eigenvalue > -tolerance
	
	# For a correlation matrix, we expect eigenvalues between 0 and n (matrix dimension)
	results$eigenvalues <- eigen_values
	
	# Check invertibility (a matrix is invertible if all eigenvalues are non-zero)
	results$is_invertible <- results$min_eigenvalue > tolerance
	
	# Calculate determinant
	results$determinant <- prod(eigen_values)
	
	# Calculate condition number (ratio of largest to smallest eigenvalue)
	if (results$is_invertible) {
		results$condition_number <- results$max_eigenvalue / results$min_eigenvalue
	} else {
		results$condition_number <- Inf
	}
	
	# Verify it's a proper correlation matrix (symmetric, unit diagonal, PSD)
	results$is_valid_correlation_matrix <- 
		results$is_symmetric && 
		results$has_unit_diagonal && 
		results$is_positive_semidefinite
	
	return(results)
}

#' Test random subsets of correlations for matrix properties
#'
#' This function randomly selects subsets of variables, constructs correlation matrices
#' using both original and rescaled correlations, and tests their properties.
#'
#' @param results_df The results data frame from analyze_all_corr_bounds
#' @param n_trials Number of random trials to perform
#' @param min_vars Minimum number of variables to include in each trial
#' @param max_vars Maximum number of variables to include in each trial
#' @param seed Random seed for reproducibility
#' @param enforce_psd Whether to enforce positive semidefiniteness in matrix construction
#'
#' @return A data frame with test results for each trial
#'
#' @examples
#' # Assuming 'all_results' is the output from analyze_all_corr_bounds
#' matrix_tests <- test_random_correlation_matrices(all_results)
test_random_correlation_matrices <- function(results_df, n_trials = 10, 
											 min_vars = 3, max_vars = NULL,
											 seed = 123, enforce_psd = TRUE) {
	# Set random seed for reproducibility
	set.seed(seed)
	
	# Get all unique variables
	all_vars <- unique(c(results_df$var1, results_df$var2))
	n_all_vars <- length(all_vars)
	
	# If max_vars is not specified, use all variables
	if (is.null(max_vars)) {
		max_vars <- n_all_vars
	}
	
	# Ensure max_vars doesn't exceed the total number of variables
	max_vars <- min(max_vars, n_all_vars)
	
	# Initialize results
	trial_results <- data.frame()
	
	# Run trials
	for (trial in 1:n_trials) {
		# Randomly determine number of variables for this trial
		n_vars <- sample(min_vars:max_vars, 1)
		
		# Randomly select variables
		selected_vars <- sample(all_vars, n_vars)
		
		# Subset correlations for selected variables
		subset_corrs <- results_df %>%
			filter(var1 %in% selected_vars & var2 %in% selected_vars)
		
		# Skip if not enough correlations
		if (nrow(subset_corrs) < n_vars) {
			next
		}
		
		# Construct correlation matrices
		orig_matrix <- tryCatch({
			construct_correlation_matrix(subset_corrs, use_rescaled = FALSE, enforce_psd = enforce_psd)
		}, error = function(e) {
			return(NULL)
		})
		
		rescaled_matrix <- tryCatch({
			construct_correlation_matrix(subset_corrs, use_rescaled = TRUE, enforce_psd = enforce_psd)
		}, error = function(e) {
			return(NULL)
		})
		
		# Skip if any matrix construction failed
		if (is.null(orig_matrix) || is.null(rescaled_matrix)) {
			next
		}
		
		# Check dimensions match expected
		if (nrow(orig_matrix) != n_vars || nrow(rescaled_matrix) != n_vars) {
			next
		}
		
		# Test matrix properties
		orig_results <- test_matrix_properties(orig_matrix)
		rescaled_results <- test_matrix_properties(rescaled_matrix)
		
		# Combine results for this trial
		trial_result <- data.frame(
			trial = trial,
			n_variables = n_vars,
			n_correlations = nrow(subset_corrs),
			enforce_psd = enforce_psd,
			
			# Original matrix properties
			orig_symmetric = orig_results$is_symmetric,
			orig_unit_diagonal = orig_results$has_unit_diagonal,
			orig_psd = orig_results$is_positive_semidefinite,
			orig_invertible = orig_results$is_invertible,
			orig_determinant = orig_results$determinant,
			orig_condition = orig_results$condition_number,
			orig_min_eigenvalue = orig_results$min_eigenvalue,
			orig_valid = orig_results$is_valid_correlation_matrix,
			
			# Rescaled matrix properties
			rescaled_symmetric = rescaled_results$is_symmetric,
			rescaled_unit_diagonal = rescaled_results$has_unit_diagonal,
			rescaled_psd = rescaled_results$is_positive_semidefinite,
			rescaled_invertible = rescaled_results$is_invertible,
			rescaled_determinant = rescaled_results$determinant,
			rescaled_condition = rescaled_results$condition_number,
			rescaled_min_eigenvalue = rescaled_results$min_eigenvalue,
			rescaled_valid = rescaled_results$is_valid_correlation_matrix,
			
			# Comparison
			properties_differ = (orig_results$is_positive_semidefinite != rescaled_results$is_positive_semidefinite) ||
				(orig_results$is_invertible != rescaled_results$is_invertible) ||
				(orig_results$is_valid_correlation_matrix != rescaled_results$is_valid_correlation_matrix)
		)
		
		# Add to overall results
		trial_results <- rbind(trial_results, trial_result)
	}
	
	return(trial_results)
}

#' Summarize correlation matrix test results
#'
#' @param test_results The output from test_random_correlation_matrices
#'
#' @return A data frame with summarized results
#'
#' @examples
#' # Assuming 'matrix_tests' is the output from test_random_correlation_matrices
#' summary <- summarize_matrix_tests(matrix_tests)
summarize_matrix_tests <- function(test_results) {
	# Calculate overall statistics
	summary <- list(
		n_trials = nrow(test_results),
		
		# Original matrix results
		orig_psd_count = sum(test_results$orig_psd),
		orig_psd_percent = 100 * mean(test_results$orig_psd),
		orig_invertible_count = sum(test_results$orig_invertible),
		orig_invertible_percent = 100 * mean(test_results$orig_invertible),
		orig_mean_condition = mean(test_results$orig_condition[is.finite(test_results$orig_condition)]),
		orig_mean_min_eigenvalue = mean(test_results$orig_min_eigenvalue),
		
		# Rescaled matrix results
		rescaled_psd_count = sum(test_results$rescaled_psd),
		rescaled_psd_percent = 100 * mean(test_results$rescaled_psd),
		rescaled_invertible_count = sum(test_results$rescaled_invertible),
		rescaled_invertible_percent = 100 * mean(test_results$rescaled_invertible),
		rescaled_mean_condition = mean(test_results$rescaled_condition[is.finite(test_results$rescaled_condition)]),
		rescaled_mean_min_eigenvalue = mean(test_results$rescaled_min_eigenvalue),
		
		# Comparison
		properties_differ_count = sum(test_results$properties_differ),
		properties_differ_percent = 100 * mean(test_results$properties_differ),
		
		# Correlations where rescaled is better
		rescaled_better_psd = sum(!test_results$orig_psd & test_results$rescaled_psd),
		rescaled_better_invertible = sum(!test_results$orig_invertible & test_results$rescaled_invertible),
		
		# Correlations where original is better
		orig_better_psd = sum(test_results$orig_psd & !test_results$rescaled_psd),
		orig_better_invertible = sum(test_results$orig_invertible & !test_results$rescaled_invertible)
	)
	
	# Convert to data frame for nicer printing
	summary_df <- as.data.frame(t(unlist(summary)))
	
	return(summary_df)
}

#' Analyze a specific correlation matrix in detail
#'
#' @param results_df The results data frame from analyze_all_corr_bounds
#' @param vars The vector of variable names to include
#' @param use_rescaled Logical; if TRUE, use rescaled correlations
#' @param enforce_psd Logical; if TRUE, adjust the matrix to ensure positive semidefiniteness
#'
#' @return A list with the correlation matrix and its properties
#'
#' @examples
#' # Assuming 'all_results' is the output from analyze_all_corr_bounds
#' # and we want to analyze variables 1, 2, and 3
#' analysis <- analyze_specific_matrix(all_results, c(1, 2, 3))
analyze_specific_matrix <- function(results_df, vars, use_rescaled = FALSE, enforce_psd = TRUE) {
	# Subset correlations for selected variables
	subset_corrs <- results_df %>%
		filter(var1 %in% vars & var2 %in% vars)
	
	# Construct correlation matrices - both original and rescaled for comparison
	original_matrix <- construct_correlation_matrix(subset_corrs, use_rescaled = FALSE, enforce_psd = enforce_psd)
	rescaled_matrix <- construct_correlation_matrix(subset_corrs, use_rescaled = TRUE, enforce_psd = enforce_psd)
	
	# Test matrix properties
	original_properties <- test_matrix_properties(original_matrix)
	rescaled_properties <- test_matrix_properties(rescaled_matrix)
	
	# Return results
	return(list(
		variables = vars,
		correlations = subset_corrs,
		original = list(
			matrix = original_matrix,
			properties = original_properties
		),
		rescaled = list(
			matrix = rescaled_matrix,
			properties = rescaled_properties
		),
		comparison = list(
			psd_difference = original_properties$is_positive_semidefinite != rescaled_properties$is_positive_semidefinite,
			invertibility_difference = original_properties$is_invertible != rescaled_properties$is_invertible,
			condition_ratio = if(is.finite(original_properties$condition_number) && 
								 is.finite(rescaled_properties$condition_number)) {
				rescaled_properties$condition_number / original_properties$condition_number
			} else {
				NA
			}
		)
	))
}

#' Visualize comparison of original and rescaled correlation matrices
#'
#' @param orig_matrix The original correlation matrix
#' @param rescaled_matrix The rescaled correlation matrix
#'
#' @return A list of ggplot objects showing the matrices and their differences
#'
#' @examples
#' # Assuming we have both original and rescaled matrices
#' plots <- visualize_matrix_comparison(orig_matrix, rescaled_matrix)
visualize_matrix_comparison <- function(orig_matrix, rescaled_matrix) {
	# Compute difference matrix
	diff_matrix <- rescaled_matrix - orig_matrix
	
	# First, ensure matrices have row and column names
	if (is.null(rownames(orig_matrix))) {
		rownames(orig_matrix) <- paste0("V", 1:nrow(orig_matrix))
	}
	if (is.null(colnames(orig_matrix))) {
		colnames(orig_matrix) <- paste0("V", 1:ncol(orig_matrix))
	}
	
	if (is.null(rownames(rescaled_matrix))) {
		rownames(rescaled_matrix) <- paste0("V", 1:nrow(rescaled_matrix))
	}
	if (is.null(colnames(rescaled_matrix))) {
		colnames(rescaled_matrix) <- paste0("V", 1:ncol(rescaled_matrix))
	}
	
	# Convert matrices to long format for ggplot in a safer way
	orig_df <- data.frame()
	for (i in 1:nrow(orig_matrix)) {
		for (j in 1:ncol(orig_matrix)) {
			orig_df <- rbind(orig_df, data.frame(
				Var1 = rownames(orig_matrix)[i],
				Var2 = colnames(orig_matrix)[j],
				value = orig_matrix[i, j]
			))
		}
	}
	
	rescaled_df <- data.frame()
	for (i in 1:nrow(rescaled_matrix)) {
		for (j in 1:ncol(rescaled_matrix)) {
			rescaled_df <- rbind(rescaled_df, data.frame(
				Var1 = rownames(rescaled_matrix)[i],
				Var2 = colnames(rescaled_matrix)[j],
				value = rescaled_matrix[i, j]
			))
		}
	}
	
	diff_df <- data.frame()
	for (i in 1:nrow(diff_matrix)) {
		for (j in 1:ncol(diff_matrix)) {
			diff_df <- rbind(diff_df, data.frame(
				Var1 = rownames(diff_matrix)[i],
				Var2 = colnames(diff_matrix)[j],
				value = diff_matrix[i, j]
			))
		}
	}
	
	# Create heatmap for original matrix
	p1 <- ggplot(orig_df, aes(x = Var1, y = Var2, fill = value)) +
		geom_tile() +
		scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0,
							 limits = c(-1, 1), name = "Correlation") +
		theme_minimal() +
		theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
		labs(title = "Original Correlation Matrix",
			 x = "", y = "")
	
	# Create heatmap for rescaled matrix
	p2 <- ggplot(rescaled_df, aes(x = Var1, y = Var2, fill = value)) +
		geom_tile() +
		scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0,
							 limits = c(-1, 1), name = "Correlation") +
		theme_minimal() +
		theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
		labs(title = "Rescaled Correlation Matrix",
			 x = "", y = "")
	
	# Create heatmap for difference matrix
	p3 <- ggplot(diff_df, aes(x = Var1, y = Var2, fill = value)) +
		geom_tile() +
		scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0,
							 name = "Difference") +
		theme_minimal() +
		theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
		labs(title = "Difference (Rescaled - Original)",
			 x = "", y = "")
	
	return(list(original = p1, rescaled = p2, difference = p3))
}

#' Run a comprehensive analysis of correlation matrix properties
#'
#' @param results_df The results data frame from analyze_all_corr_bounds
#' @param n_trials Number of random trials to perform
#' @param min_vars Minimum number of variables per trial
#' @param max_vars Maximum number of variables per trial
#' @param seed Random seed
#' @param enforce_psd Whether to enforce positive semidefiniteness in matrix construction
#'
#' @return A list with test results and summary statistics
#'
#' @examples
#' # Assuming 'all_results' is the output from analyze_all_corr_bounds
#' analysis <- analyze_correlation_matrices(all_results)
analyze_correlation_matrices <- function(results_df, n_trials = 20, 
										 min_vars = 3, max_vars = 10,
										 seed = 123, enforce_psd = TRUE) {
	# Run random matrix tests
	cat("Testing", n_trials, "random correlation matrices...\n")
	test_results <- test_random_correlation_matrices(
		results_df, n_trials = n_trials, 
		min_vars = min_vars, max_vars = max_vars,
		seed = seed, enforce_psd = enforce_psd
	)
	
	# Summarize results
	cat("\nSummarizing results...\n")
	summary <- summarize_matrix_tests(test_results)
	
	# Print key findings
	cat("\nKey findings:\n")
	cat("Number of trials:", summary$n_trials, "\n")
	
	# Verify all correlation matrices are valid
	cat("Original matrices - valid correlation matrices:", 
		sprintf("%.1f%%", summary$orig_valid_percent), "\n")
	cat("Rescaled matrices - valid correlation matrices:", 
		sprintf("%.1f%%", summary$rescaled_valid_percent), "\n")
	
	cat("Original matrices - positive semidefinite:", 
		sprintf("%.1f%%", summary$orig_psd_percent), "\n")
	cat("Rescaled matrices - positive semidefinite:", 
		sprintf("%.1f%%", summary$rescaled_psd_percent), "\n")
	
	cat("Original matrices - invertible:", 
		sprintf("%.1f%%", summary$orig_invertible_percent), "\n")
	cat("Rescaled matrices - invertible:", 
		sprintf("%.1f%%", summary$rescaled_invertible_percent), "\n")
	
	cat("Original matrices - average condition number:", 
		sprintf("%.2f", summary$orig_mean_condition), "\n")
	cat("Rescaled matrices - average condition number:", 
		sprintf("%.2f", summary$rescaled_mean_condition), "\n")
	
	cat("Cases where properties differ:", 
		sprintf("%.1f%%", summary$properties_differ_percent), "\n")
	
	# Find an interesting case where properties differ
	if (any(test_results$properties_differ)) {
		cat("\nAnalyzing a specific case where properties differ...\n")
		different_case <- test_results %>% 
			filter(properties_differ) %>% 
			arrange(desc(n_variables)) %>% 
			slice(1)
		
		trial_number <- different_case$trial
		cat("Analyzing trial", trial_number, "with", 
			different_case$n_variables, "variables...\n")
		
		# This would require tracking the specific variables used in each trial
		cat("Note: To analyze specific cases, we would need to track the variables in each trial.\n")
	}
	
	return(list(
		test_results = test_results,
		summary = summary
	))
}