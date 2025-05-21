# correlation_bounds_examples.R
#
# Examples and demonstrations of correlation bounds and permutation distributions
#
# Author: [Your Name]
# Date: March 2, 2025

# -----------------------------------------------------------------------------
# Load required libraries and source the core and visualization functions
# -----------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
library(gridExtra)

# Source the core and visualization functions
# Adjust the path as needed
source("correlation_bounds_core.R")
source("correlation_bounds_visualization.R")

# -----------------------------------------------------------------------------
# Example 1: Basic demonstration with uniform and extreme distributions
# -----------------------------------------------------------------------------
basic_demonstration <- function() {
  # Define scenarios with 5 categories each
  scenarios <- list(
    Extreme = list(
      marginalX = c(0.7, rep(0.3/4, 4)),  # X has 70% mass on first category
      marginalY = c(rep(0.02, 4), 1 - 0.02*4)  # Y has low mass on all but last category
    ),
    Uniform = list(
      marginalX = rep(1/5, 5),  # Uniform distribution for X
      marginalY = rep(1/5, 5)   # Uniform distribution for Y
    )
  )
  
  # Sample sizes to explore
  sample_sizes <- c(500, 1000, 5000, 10000)
  
  # Storage for summary statistics and simulated r values
  summary_df <- data.frame()
  sim_r_df <- data.frame()
  
  # Set random seed for reproducibility
  set.seed(123)
  
  # Loop over scenarios and sample sizes
  for (sc in names(scenarios)) {
    pX <- scenarios[[sc]]$marginalX
    pY <- scenarios[[sc]]$marginalY
    
    for (s in sample_sizes) {
      # Compute theoretical bounds
      r_min_val <- min_corr_bound(pX, pY, sample_size = s)
      r_max_val <- max_corr_bound(pX, pY, sample_size = s)
      
      # Simulate permutation distribution
      r_sim <- simulate_permutation_distribution(pX, pY, nsim = 1000, sample_size = s)
      med_r <- median(r_sim)
      lower_ci <- quantile(r_sim, 0.025)
      upper_ci <- quantile(r_sim, 0.975)
      
      # Save summary statistics
      summary_df <- rbind(summary_df, data.frame(
        scenario = sc,
        sample_size = s,
        r_min = r_min_val,
        r_max = r_max_val,
        median_r = med_r,
        lower_ci = lower_ci,
        upper_ci = upper_ci
      ))
      
      # Save simulated r values
      sim_r_df <- rbind(sim_r_df, data.frame(
        scenario = sc,
        sample_size = s,
        r = r_sim
      ))
    }
  }
  
  # Print the simulation summary
  cat("Simulation Summary:\n")
  print(summary_df)
  
  # Create and display plots
  
  # 1. Bounds summary plot
  p_summary <- plot_bounds_summary(summary_df)
  print(p_summary)
  
  # 2. Boxplot of simulated distributions
  p_box <- plot_sim_boxplot(sim_r_df)
  print(p_box)
  
  # 3. Display permutation distribution for Extreme scenario at largest sample size
  extreme_large <- summary_df %>% 
    filter(scenario == "Extreme", sample_size == max(sample_sizes))
  r_vals <- sim_r_df %>% 
    filter(scenario == "Extreme", sample_size == max(sample_sizes)) %>% 
    pull(r)
  ci_bounds <- c(extreme_large$lower_ci, extreme_large$upper_ci)
  
  p_extreme <- plot_permutation_distribution(
    r_vals, extreme_large$r_min, extreme_large$r_max, ci_bounds,
    main = paste("Permutation Distribution (Extreme, n =", max(sample_sizes), ")")
  )
  print(p_extreme)
  
  # 4. Display permutation distribution for Uniform scenario at largest sample size
  uniform_large <- summary_df %>% 
    filter(scenario == "Uniform", sample_size == max(sample_sizes))
  r_vals <- sim_r_df %>% 
    filter(scenario == "Uniform", sample_size == max(sample_sizes)) %>% 
    pull(r)
  ci_bounds <- c(uniform_large$lower_ci, uniform_large$upper_ci)
  
  p_uniform <- plot_permutation_distribution(
    r_vals, uniform_large$r_min, uniform_large$r_max, ci_bounds,
    main = paste("Permutation Distribution (Uniform, n =", max(sample_sizes), ")")
  )
  print(p_uniform)
  
  # 5. Display marginal distributions for both scenarios
  cat("\nMarginal distributions for the Extreme scenario:\n")
  extreme_countsX <- probs_to_counts(scenarios$Extreme$marginalX, 1000)
  extreme_countsY <- probs_to_counts(scenarios$Extreme$marginalY, 1000)
  plot_paired_marginals(extreme_countsX, extreme_countsY)
  
  cat("\nMarginal distributions for the Uniform scenario:\n")
  uniform_countsX <- probs_to_counts(scenarios$Uniform$marginalX, 1000)
  uniform_countsY <- probs_to_counts(scenarios$Uniform$marginalY, 1000)
  plot_paired_marginals(uniform_countsX, uniform_countsY)
  
  return(list(summary = summary_df, simulations = sim_r_df))
}

# -----------------------------------------------------------------------------
# Example 2: Range comparison across multiple distribution scenarios
# -----------------------------------------------------------------------------
range_comparison_demonstration <- function() {
  # Define a variety of scenarios with 5 categories each
  scenarios <- list(
    Extreme = list(
      marginalX = c(0.7, rep(0.3/4, 4)),
      marginalY = c(rep(0.02, 4), 1 - 0.02*4)
    ),
    Uniform = list(
      marginalX = rep(1/5, 5),
      marginalY = rep(1/5, 5)
    ),
    Bimodal = list(
      marginalX = c(0.45, 0.05, 0.05, 0.05, 0.4),
      marginalY = c(0.1, 0.1, 0.1, 0.1, 0.6)
    ),
    HighlySkewed = list(
      marginalX = c(0.9, rep(0.1/4, 4)),
      marginalY = c(rep(0.01, 4), 1 - 0.01*4)
    ),
    Moderate = list(
      marginalX = c(0.4, 0.15, 0.15, 0.15, 0.15),
      marginalY = c(0.15, 0.2, 0.2, 0.2, 0.25)
    )
  )
  
  # Fixed sample size and number of simulations
  sample_size <- 10000
  nsim <- 1000
  
  # Storage for results
  results <- data.frame(Scenario = character(), 
                        r_min = numeric(),
                        r_max = numeric(),
                        theo_range = numeric(),
                        emp_range = numeric(),
                        stringsAsFactors = FALSE)
  
  # Set random seed for reproducibility
  set.seed(123)
  
  # Loop over scenarios
  for (sc in names(scenarios)) {
    margX <- scenarios[[sc]]$marginalX
    margY <- scenarios[[sc]]$marginalY
    
    # Compute theoretical bounds
    rmin <- min_corr_bound(margX, margY, sample_size = sample_size)
    rmax <- max_corr_bound(margX, margY, sample_size = sample_size)
    
    # Simulate permutation distribution
    r_sim <- simulate_permutation_distribution(margX, margY, nsim = nsim, sample_size = sample_size)
    
    # Calculate theoretical and empirical ranges
    theo_range <- rmax - rmin
    emp_range <- max(r_sim) - min(r_sim)
    
    # Store results
    results <- rbind(results, data.frame(
      Scenario = sc, 
      r_min = rmin,
      r_max = rmax,
      theo_range = theo_range,
      emp_range = emp_range
    ))
  }
  
  # Print results
  cat("Results of Range Comparison:\n")
  print(results)
  
  # Plot the range comparison
  p_range <- plot_range_comparison(results)
  print(p_range)
  
  # Display permutation distributions for each scenario
  plots <- list()
  for (sc in names(scenarios)) {
    # Get scenario data
    row <- results %>% filter(Scenario == sc)
    r_sim <- simulate_permutation_distribution(
      scenarios[[sc]]$marginalX, 
      scenarios[[sc]]$marginalY, 
      nsim = nsim, 
      sample_size = sample_size
    )
    
    # Calculate CI bounds
    ci_bounds <- quantile(r_sim, probs = c(0.025, 0.975))
    
    # Create plot
    p <- plot_permutation_distribution(
      r_sim, row$r_min, row$r_max, ci_bounds,
      main = paste("Permutation Distribution -", sc)
    )
    plots[[sc]] <- p
  }
  
  # Display plots in a grid
  grid.arrange(grobs = plots, ncol = 2)
  
  return(results)
}

# -----------------------------------------------------------------------------
# Example 3: Exploring different numbers of categories
# -----------------------------------------------------------------------------
category_count_demonstration <- function() {
  # Define a range for number of categories for X and Y
  # X categories: 5, 7, or 9
  # Y categories: 6, 8, 10, or 11 (ensuring they differ from X)
  nX_values <- c(5, 7, 9)
  nY_values <- c(6, 8, 10, 11)
  
  # Sample size and number of simulations
  sample_size <- 5000
  nsim <- 1000
  
  # Create all combinations (only use combinations where nX != nY)
  combinations <- expand.grid(nX = nX_values, nY = nY_values) %>%
    filter(nX != nY)
  
  # Prepare storage for results
  results <- data.frame()
  plots <- list()
  
  # Set random seed for reproducibility
  set.seed(123)
  
  # Loop over each combination of categories
  for(i in 1:nrow(combinations)) {
    nX <- combinations$nX[i]
    nY <- combinations$nY[i]
    
    # Generate extreme marginals:
    # For X: assign 70% probability to the first category and split the remaining 30% equally
    pX <- c(0.7, rep(0.3/(nX - 1), nX - 1))
    
    # For Y: assign a very small probability (e.g., 0.02) to the first (nY - 1) categories,
    # and the remainder to the last category
    pY <- c(rep(0.02, nY - 1), 1 - 0.02*(nY - 1))
    
    # Compute theoretical bounds
    r_max <- max_corr_bound(pX, pY, sample_size = sample_size)
    r_min <- min_corr_bound(pX, pY, sample_size = sample_size)
    
    # Simulate permutation distribution
    r_vals <- simulate_permutation_distribution(pX, pY, nsim = nsim, sample_size = sample_size)
    
    # Compute the 95% confidence interval
    ci_bounds <- quantile(r_vals, probs = c(0.025, 0.975))
    median_r <- median(r_vals)
    
    # Save the summary results
    results <- rbind(results, data.frame(
      nX = nX, nY = nY,
      r_min = r_min, r_max = r_max,
      median_r = median_r,
      CI_lower = ci_bounds[1], CI_upper = ci_bounds[2]
    ))
    
    # Create a title string for the plot
    title_str <- paste("nX =", nX, ", nY =", nY)
    
    # Create the permutation distribution plot
    p_emp <- plot_permutation_distribution(
      r_vals, r_min, r_max, ci_bounds,
      main = paste("Permutation Distribution (", title_str, ")", sep = "")
    )
    
    plots[[i]] <- p_emp
  }
  
  # Print the summary results
  cat("Summary of Category Count Exploration:\n")
  print(results)
  
  # Display all the plots
  grid.arrange(grobs = plots, ncol = 2)
  
  # Also, display the marginal distributions for the first combination as an example
  example_nX <- combinations$nX[1]
  example_nY <- combinations$nY[1]
  
  # Generate extreme marginals for this instance
  example_pX <- c(0.7, rep(0.3/(example_nX - 1), example_nX - 1))
  example_pY <- c(rep(0.02, example_nY - 1), 1 - 0.02*(example_nY - 1))
  
  # Convert probabilities to counts for display
  example_countsX <- probs_to_counts(example_pX, sample_size)
  example_countsY <- probs_to_counts(example_pY, sample_size)
  
  # Plot the marginal distributions
  cat("\nMarginal distributions for example combination (nX =", example_nX, ", nY =", example_nY, "):\n")
  pX_plot <- plot_marginal_distribution(example_countsX, varname = "X")
  pY_plot <- plot_marginal_distribution(example_countsY, varname = "Y")
  grid.arrange(pX_plot, pY_plot, ncol = 2)
  
  return(results)
}

# -----------------------------------------------------------------------------
# Example 4: Investigation of extreme cases where simulated bounds approximate theoretical
# -----------------------------------------------------------------------------
extremal_bounds_investigation <- function() {
  # Define scenarios with 5 categories each
  scenarios <- list(
    Extreme = list(
      marginalX = c(0.7, rep(0.3/4, 4)),
      marginalY = c(rep(0.02, 4), 1 - 0.02*4)
    ),
    Uniform = list(
      marginalX = rep(1/5, 5),
      marginalY = rep(1/5, 5)
    ),
    Bimodal = list(
      marginalX = c(0.45, 0.05, 0.05, 0.05, 0.4),
      marginalY = c(0.1, 0.1, 0.1, 0.1, 0.6)
    ),
    HighlySkewed = list(
      marginalX = c(0.9, rep(0.1/4, 4)),
      marginalY = c(rep(0.01, 4), 1 - 0.01*4)
    )
  )
  
  # Sample sizes and number of simulations
  sample_sizes <- c(100, 500, 1000, 5000, 10000)
  nsim <- 1000
  
  # Storage for summary statistics
  summary_df <- data.frame()
  
  # Set random seed for reproducibility
  set.seed(123)
  
  # Loop over scenarios and sample sizes
  for (sc in names(scenarios)) {
    pX <- scenarios[[sc]]$marginalX
    pY <- scenarios[[sc]]$marginalY
    
    for (s in sample_sizes) {
      # Compute theoretical bounds
      r_min_val <- min_corr_bound(pX, pY, sample_size = s)
      r_max_val <- max_corr_bound(pX, pY, sample_size = s)
      
      # Simulate permutation distribution
      r_sim <- simulate_permutation_distribution(pX, pY, nsim = nsim, sample_size = s)
      med_r <- median(r_sim)
      lower_ci <- quantile(r_sim, 0.025)
      upper_ci <- quantile(r_sim, 0.975)
      
      # Compute differences between theoretical bounds and empirical bounds
      diff_lower <- abs(r_min_val - lower_ci)
      diff_upper <- abs(r_max_val - upper_ci)
      
      # Save summary statistics
      summary_df <- rbind(summary_df, data.frame(
        scenario = sc,
        sample_size = s,
        r_min = r_min_val,
        lower_ci = lower_ci,
        diff_lower = diff_lower,
        r_max = r_max_val,
        upper_ci = upper_ci,
        diff_upper = diff_upper,
        median_r = med_r
      ))
    }
  }
  
  # Print the simulation summary
  cat("Simulation Summary:\n")
  print(summary_df)
  
  # Identify cases where the theoretical bounds are close to the empirical bounds
  threshold <- 0.01  # tolerance for differences
  cat("\nCases where |r_min - lower_ci| < ", threshold, " and |r_max - upper_ci| < ", threshold, ":\n", sep = "")
  close_cases <- subset(summary_df, diff_lower < threshold & diff_upper < threshold)
  print(close_cases)
  
  # Create plots for cases where bounds are close
  if (nrow(close_cases) > 0) {
    plots <- list()
    for (i in 1:nrow(close_cases)) {
      row <- close_cases[i, ]
      
      # Generate new simulation for plotting
      r_sim <- simulate_permutation_distribution(
        scenarios[[row$scenario]]$marginalX,
        scenarios[[row$scenario]]$marginalY,
        nsim = nsim,
        sample_size = row$sample_size
      )
      
      # Create plot
      title_str <- paste(
        "Scenario:", row$scenario, 
        "Sample Size:", row$sample_size,
        "\nDiff Lower:", round(row$diff_lower, 4),
        "Diff Upper:", round(row$diff_upper, 4)
      )
      
      p <- plot_permutation_distribution(
        r_sim, row$r_min, row$r_max, c(row$lower_ci, row$upper_ci),
        main = title_str
      )
      
      plots[[i]] <- p
    }
    
    # Display plots in a grid
    if (length(plots) > 0) {
      grid.arrange(grobs = plots, ncol = 2)
    }
  } else {
    cat("No cases found where theoretical bounds are close to empirical bounds.\n")
  }
  
  return(summary_df)
}

# -----------------------------------------------------------------------------
# Main function to run all examples
# -----------------------------------------------------------------------------
run_all_examples <- function() {
  cat("Running Example 1: Basic Demonstration\n")
  cat("=====================================\n\n")
  results1 <- basic_demonstration()
  
  cat("\n\nRunning Example 2: Range Comparison Demonstration\n")
  cat("================================================\n\n")
  results2 <- range_comparison_demonstration()
  
  cat("\n\nRunning Example 3: Category Count Demonstration\n")
  cat("===============================================\n\n")
  results3 <- category_count_demonstration()
  
  cat("\n\nRunning Example 4: Extremal Bounds Investigation\n")
  cat("===============================================\n\n")
  results4 <- extremal_bounds_investigation()
  
  return(list(
    basic = results1,
    range_comparison = results2,
    category_count = results3,
    extremal_bounds = results4
  ))
}

# Run all examples if this file is executed directly
if (!interactive()) {
  run_all_examples()
}
