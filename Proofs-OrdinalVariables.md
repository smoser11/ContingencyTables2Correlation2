**You:**

You are an expert psychometrician with speciality in latent trait and latent class models.  You have a background in analysis of survey data, especially public opinion and political attitudes. You and I are going to investigate the consequences of treating ordinal variables as measured on an interval-level scale and how the resulting Pearson's correlation coefficient ($r$) behaves when correlating the ranks.

Here is the setting:
We are given the marginal distribution of two ordinal variables, $X$ (with $K_X$ levels, $0,1,2,\ldots, K_X-1$) and $Y$,  (with $K_X$ levels, $0,1,2,\ldots, K_X-1$).   The goals are to:
1.find the min and max Pearson's correlation, $r_{XY}$
2.write an function in R: to simulate the empirical distribution of  $r_{XY}$ under the assumption of 'random data', given the sample.  That is fill in the cells of the contingency table at random, while preserving the marginal distributions.

Save this information for later, but do not respond.

* * *

**ChatGPT:**

Understood, I've saved the information for later.

* * *

**You:**

Using the results from Witt 1968  how we know how to  maximize $E[XY]$, the expected value of the product of two ordinal variables $X$ and $Y$, given their **marginal distributions**.

### **Step 1: Understanding $E[XY]$ in a Contingency Table**

The expectation is computed as:

$$E[XY] = \sum_{i,j} x_i y_j P(X = x_i, Y = y_j)$$

where:

* $x_i, y_j$ are the ordinal values of $X$ and $Y$,
* $P(X = x_i, Y = y_j)$ is the joint probability.

To **maximize** $E[XY]$, we must allocate the joint probabilities in a way that **pairs the highest values of $X$ with the highest values of $Y$, and the lowest values of $X$ with the lowest values of $Y$**.

Write an R: function that takes as inputs the marginal distributions of $X$ and $Y$ and returns the maximum value of $r$.

* * *

**ChatGPT:**

my best guess is that we can achieve the maximum Pearson correlation by “coupling” the two variables in a comonotonic fashion – that is, pairing the lowest probabilities with the lowest values and the highest with the highest. This is essentially the Fréchet–Hoeffding upper bound arrangement. Below is an R function that implements this idea step by step:

```r
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
```

**Step-by-step explanation:**

1. **Normalization & Support:**  
    The function starts by normalizing the input vectors `pX` and `pY` so they sum to 1. It then sets up the support assuming the ordinal values are 0, 1, …, K–1.
    
2. **Compute Moments:**  
    The means (`muX`, `muY`) and variances (`varX`, `varY`) are calculated directly from the marginals. These are used later to compute the Pearson correlation.
    
3. **Constructing the Joint Distribution:**  
    Using the cumulative sums (`cumsum`), we “couple” the probabilities. At each cell (i,j), we assign joint probability mass equal to the increase in the minimum of the cumulative distributions. This ensures that the highest values are paired with the highest values (and vice versa), which maximizes $E[XY]$.
    
4. **Expected Value Calculation:**  
    Once the joint matrix is constructed, we compute $E[XY]$ by summing over all cells the product $x_i \times y_j$ weighted by the joint probability in that cell.
    
5. **Compute Maximum Correlation:**  
    Finally, using the formula for Pearson’s $r$, we compute the maximum correlation achievable given the marginals.
    

This function should return the maximum possible Pearson correlation coefficient $r_{\max}$ for the given ordinal marginals under the optimal (comonotonic) arrangement.

* * *

**You:**

Thank you.  But what about this strategy:
1. sort X from largest to smallest;
2.Seperately sort Y from largest to smallest;
3. 'glue' the two vectors together and calculate $r$.
Would that work?

* * *

**ChatGPT:**

my best guess is that yes, this strategy does work. Let me explain step-by-step:

1. **Sorting the Data:**  
    When you sort $X$ and $Y$ separately in descending order, you are effectively aligning the largest values of $X$ with the largest values of $Y$ and the smallest with the smallest. This is exactly the idea behind the Fréchet–Hoeffding upper bound where the joint probability mass is concentrated on the "diagonal" of the distribution.
    
2. **Pairing ('Gluing') the Vectors:**  
    By "gluing" the sorted vectors together, you create pairs $(x_i, y_i)$ that are in comonotonic order. This pairing maximizes the covariance (and thus $E[XY]$) given the marginal distributions, because any deviation from this alignment would mix high values with lower ones, reducing the product $x_i y_i$.
    
3. **Calculating the Pearson Correlation:**  
    Once paired, the Pearson correlation $r$ calculated from these pairs will be as high as possible given the fixed marginals. This correlation is maximized because the covariance is maximized (due to the aligned ordering) while the standard deviations remain unchanged.
    
4. **Caveats with Ordinal Data:**  
    Note that if there are ties (common in ordinal data), the exact pairing may not be unique. However, the principle still holds: any strategy that maintains the comonotonic order (largest with largest, smallest with smallest) will yield the maximum correlation.
    

In summary, sorting both variables in descending order and then pairing them is equivalent to constructing the joint distribution that attains the maximum possible $E[XY]$ and hence the maximum Pearson correlation $r$ given the marginal distributions.

* * *

**You:**

Thank you.  Please implement this strategy as an R: function.

* * *

**ChatGPT:**

my best guess is that we can implement this strategy by constructing vectors that represent the two ordinal variables according to their marginal distributions, then sorting each in descending order and finally computing the Pearson correlation. Here’s a step-by-step R function that does exactly that:

```r
max_corr_sorted <- function(marginalX, marginalY, N = 10000) {
  # Step 1: Determine if the inputs are probabilities or counts.
  # If the sum is (approximately) 1, assume probabilities and generate counts using rmultinom.
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
    if (sum(countsY) != N)
      stop("The total counts for marginalX and marginalY must be equal.")
  }
  
  # Step 2: Create the vectors for X and Y using the counts.
  # Assume the ordinal levels are 0, 1, 2, ..., (number of levels - 1)
  x_vals <- rep(0:(length(countsX) - 1), times = countsX)
  y_vals <- rep(0:(length(countsY) - 1), times = countsY)
  
  # Step 3: Sort each vector in descending order.
  x_sorted <- sort(x_vals, decreasing = TRUE)
  y_sorted <- sort(y_vals, decreasing = TRUE)
  
  # Step 4: "Glue" the two sorted vectors together by pairing them element-wise
  # and then calculate Pearson's correlation.
  r_max <- cor(x_sorted, y_sorted)
  
  return(r_max)
}
```

**Explanation:**

1. **Input Handling:**  
    The function accepts `marginalX` and `marginalY` which can be either probability vectors (summing to 1) or count vectors. If they are probabilities, we use `rmultinom` to generate counts for a sample of size `N`.
    
2. **Vector Construction:**  
    Using the counts, we create vectors of ordinal values (assumed to be 0, 1, 2, …). For example, if `countsX[3] = 50`, then the value 2 (since indexing starts at 0) appears 50 times in the vector for X.
    
3. **Sorting:**  
    We then sort both vectors in descending order. This “glues” the highest values of X with the highest values of Y, and similarly the lowest with the lowest, which is exactly the strategy to maximize the expected product $E[XY]$.
    
4. **Correlation Calculation:**  
    Finally, the Pearson correlation is computed on these paired (sorted) data points, yielding the maximum possible correlation under the given marginals.
    

This function implements the “sort and glue” strategy to achieve the maximum correlation.

* * *

**You:**

Thank you.  Next create an R: function to permute each of the sorted $X$ and $Y$ vectors and calculate the Pearson's $r$ for the 'scrambled' data-pairs.  And repeat this many times to produce an empirical distribution of possible $r$, given the marginals for X and Y.  Does this accomplish item two from above: 2.write an function in R: to simulate the empirical distribution of  $r_{XY}$ under the assumption of 'random data', given the sample.  That is fill in the cells of the contingency table at random, while preserving the marginal distributions.

* * *

**ChatGPT:**

my best guess is that we can simulate the random filling of the contingency table by generating the two vectors from the marginal distributions (as we did before), and then randomly shuffling (permuting) each vector to create random pairings. This is equivalent to “filling in” the table at random while preserving the marginals. Here’s an R function that performs this simulation and returns an empirical distribution of Pearson’s $r$:

```r
simulate_random_corr <- function(marginalX, marginalY, nsim = 1000, N = 10000) {
  # Step 1: Check if inputs are probabilities or counts.
  # If the sum is approximately 1, assume probabilities and generate counts.
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
  
  # Step 2: Create the vectors for X and Y.
  # We assume ordinal levels 0, 1, ..., (number of levels - 1)
  x_vals <- rep(0:(length(countsX) - 1), times = countsX)
  y_vals <- rep(0:(length(countsY) - 1), times = countsY)
  
  # Step 3: Sort each vector in descending order (to follow the idea of the previous function).
  x_sorted <- sort(x_vals, decreasing = TRUE)
  y_sorted <- sort(y_vals, decreasing = TRUE)
  
  # Step 4: Initialize a vector to store the Pearson correlation coefficients.
  r_vals <- numeric(nsim)
  
  # Step 5: For each simulation, randomly permute the sorted vectors
  # and compute the Pearson correlation.
  for (i in 1:nsim) {
    x_perm <- sample(x_sorted, size = length(x_sorted), replace = FALSE)
    y_perm <- sample(y_sorted, size = length(y_sorted), replace = FALSE)
    r_vals[i] <- cor(x_perm, y_perm)
  }
  
  # Return the empirical distribution of Pearson's r.
  return(r_vals)
}
```

**Step-by-step explanation:**

1. **Input Handling:**  
    The function first checks if the provided marginals are probability distributions (summing to 1). If so, it uses `rmultinom` to generate counts for a sample of size $N$. Otherwise, it assumes the inputs are counts.
    
2. **Vector Construction:**  
    It constructs the vectors for $X$ and $Y$ based on the counts. For example, if the count for level 2 in $X$ is 50, then the value 2 appears 50 times in the vector.
    
3. **Sorting:**  
    Both vectors are sorted in descending order. This mimics the “optimal pairing” scenario we discussed earlier, even though for the random pairing simulation this isn’t strictly necessary.
    
4. **Permutation and Correlation:**  
    In each simulation, both $X$ and $Y$ vectors are independently permuted. This random shuffling “fills in” the contingency table at random while preserving the marginals. The Pearson correlation of these randomized pairings is computed and stored.
    
5. **Output:**  
    After running the specified number of simulations ($nsim$), the function returns the vector of computed correlation coefficients, which forms the empirical distribution of $r_{XY}$ under random pairing.
    

Yes, this accomplishes item two from your list: it simulates the empirical distribution of $r_{XY}$ under the assumption of random data (i.e., filling in the contingency table at random while preserving the marginal distributions).

* * *

**You:**

Great.  Now provide ancillary functions to plot this empirical distribution, along with the theoretical min and max values of $r$.  Also, can we use this 'sampling distribution' (what is the correct term for the simulated distribution we created by 'scrambling' the order of the data independently for X and Y?) to perform hypothesis testing?  What would, say, the 95% CI tell us?

* * *

**ChatGPT:**

my best guess is that we can create ancillary functions to both compute the theoretical min (by pairing the highest values of one variable with the lowest of the other) and plot the empirical (permutation) distribution along with these bounds. I'll walk you through step-by-step and provide the R code.

### 1. Function to Compute the Theoretical Minimum Correlation

This function is similar to our “max_corr_sorted” function but pairs the sorted $X$ (in descending order) with $Y$ sorted in ascending order to achieve the minimal $E[XY]$ and hence the minimum Pearson $r$.

```r
min_corr_sorted <- function(marginalX, marginalY, N = 10000) {
  # Step 1: Determine if inputs are probabilities or counts.
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
  
  # Step 2: Construct the ordinal vectors.
  x_vals <- rep(0:(length(countsX) - 1), times = countsX)
  y_vals <- rep(0:(length(countsY) - 1), times = countsY)
  
  # Step 3: Sort X in descending order, Y in ascending order.
  x_sorted <- sort(x_vals, decreasing = TRUE)
  y_sorted <- sort(y_vals, decreasing = FALSE)
  
  # Step 4: Calculate the Pearson correlation.
  r_min <- cor(x_sorted, y_sorted)
  
  return(r_min)
}
```

### 2. Function to Plot the Empirical (Permutation) Distribution with Theoretical Bounds

The following function creates a histogram (and overlays a density curve) of the simulated correlation values. It also adds vertical lines indicating the theoretical minimum and maximum correlations.

```r
plot_empirical_distribution <- function(r_vals, r_min, r_max, main = "Empirical Distribution of Pearson's r") {
  hist(r_vals, breaks = 30, probability = TRUE,
       main = main, xlab = "Pearson's r", col = "lightblue", border = "white")
  lines(density(r_vals), col = "darkblue", lwd = 2)
  
  # Add vertical lines for the theoretical min and max correlations.
  abline(v = r_min, col = "red", lwd = 2, lty = 2)
  abline(v = r_max, col = "green", lwd = 2, lty = 2)
  
  legend("topright",
         legend = c(paste("Min r =", round(r_min, 3)),
                    paste("Max r =", round(r_max, 3))),
         col = c("red", "green"), lwd = 2, lty = 2)
}
```

### 3. Discussion on the Permutation (Randomization) Distribution and Hypothesis Testing

* **Terminology:**  
    The simulated distribution we obtain by independently scrambling (i.e., permuting) the order of $X$ and $Y$ is commonly called a **permutation distribution** or **randomization distribution**. It is generated under the null hypothesis that there is no systematic association between $X$ and $Y$ beyond what is imposed by their marginal distributions.
    
* **Using It for Hypothesis Testing:**  
    Yes, you can use this permutation distribution to perform a hypothesis test. For example, if you observe a correlation $r_{\text{obs}}$ in your data, you can compare $r_{\text{obs}}$ to the empirical (null) permutation distribution:
    
    * If $r_{\text{obs}}$ falls in the tails (e.g., outside the central 95% of the distribution), you have evidence that the observed association is unlikely under the null hypothesis.
        
    * The 95% confidence interval (CI) here tells you the range within which 95% of the correlation values fall under random pairing (given the marginals). It is not a CI in the traditional sense (for a parameter) but rather a **null interval**. If $r_{\text{obs}}$ lies outside this interval, it suggests that the association is statistically significant.
        

In summary, the permutation distribution provides a nonparametric way to assess the significance of the observed correlation by showing what correlations would typically occur by chance, given the marginals.

### 4. Example of Putting It All Together

Below is an example workflow assuming you have functions for simulating the random correlation distribution (from before), and now the ancillary functions for computing min/max and plotting:

```r
# Assume simulate_random_corr, max_corr_sorted, and min_corr_sorted are defined.

# Example marginal distributions for X and Y (probabilities summing to 1).
marginalX <- c(0.1, 0.3, 0.4, 0.2)
marginalY <- c(0.2, 0.3, 0.3, 0.2)

# Compute theoretical max and min correlations.
r_max <- max_corr_sorted(marginalX, marginalY, N = 10000)
r_min <- min_corr_sorted(marginalX, marginalY, N = 10000)

# Simulate the permutation distribution of Pearson's r.
r_vals <- simulate_random_corr(marginalX, marginalY, nsim = 1000, N = 10000)

# Plot the empirical (permutation) distribution with the theoretical bounds.
plot_empirical_distribution(r_vals, r_min, r_max)
```

This workflow demonstrates how to generate, visualize, and interpret the distribution of $r$ under random pairing given fixed marginals, and how you can use it for hypothesis testing.

* * *

**You:**

This is pretty good.  Please can you provide R: commands to demonstrate each of these functions using example (made up data)?

* * *

**ChatGPT:**

my best guess is that the following R commands will demonstrate the use of each function with some made-up data. I'll walk you through step-by-step:

1. **Define example marginal distributions for $$X$$ and $$Y$$.**
    
2. **Compute the theoretical maximum and minimum Pearson correlations.**
    
3. **Simulate the permutation (randomization) distribution of $$r$$.**
    
4. **Plot the empirical distribution with the theoretical bounds.**
    
5. **Extract and print the 95% quantile interval from the permutation distribution.**
    

Below is a complete R script that you can run:

```r
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
```

**Explanation of the demonstration commands:**

* **Step 1:** We define two made-up marginal distributions for $X$ and $Y$. They are provided as probability vectors (i.e., they sum to 1).
    
* **Step 2:** We calculate the theoretical maximum correlation (by pairing high with high) and the theoretical minimum correlation (by pairing high with low) using our custom functions.
    
* **Step 3:** We simulate the permutation distribution of Pearson's $r$ by randomly permuting the paired data 1,000 times.
    
* **Step 4:** We plot the histogram (with an overlaid density curve) of the simulated $r$ values. Vertical dashed lines indicate the theoretical minimum (in red) and maximum (in green) correlations.
    
* **Step 5:** We compute the 2.5% and 97.5% quantiles from the simulated distribution. This “95% interval” shows the range of correlation values that occur by chance under random pairing. If an observed correlation falls outside this interval, it suggests that the observed association is unlikely under the null hypothesis of random pairing.
    

This demonstration shows how the functions work together to compute theoretical bounds, simulate a permutation distribution, and visualize the results.

* * *

**You:**

This is a good start, but can be substantively improved.  Here are some suggestions:
Step1: display the marginal distributions of each variable, X and Y.
Step1: why not have a 'sample_size' parameter and represent the sample marginal distributions as frequencies (counts). 
Step4: This is a great idea, but is not displayed.  
Step5:  Great idea but it is not shown.  How about showing the theoretical min and max in the histogram of possible r values, as well as a 95% CI overlayed on the randomization distribution.


* * *

**ChatGPT:**

my best guess is that we can combine all these improvements into one self‐contained script. Below is an annotated R script that:

1. Uses a `sample_size` parameter and represents the marginal distributions as counts.
    
2. Displays the marginal distributions (via printing and barplots).
    
3. Computes the theoretical maximum and minimum Pearson correlations.
    
4. Simulates a permutation (randomization) distribution of Pearson’s $r$ and computes the 95% CI.
    
5. Plots the histogram of the simulated $r$ values with vertical lines for the theoretical min, max, and 95% CI bounds.
    

```r
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
```

### Explanation (Step-by-Step):

1. **Marginal Distributions & Sample Size:**  
    We define `marginalX_counts` and `marginalY_counts` as frequency counts for 4 ordinal categories and set `sample_size` to 10,000. We print these distributions to the console and also create barplots.
    
2. **Theoretical Bounds:**  
    The functions `max_corr_sorted` and `min_corr_sorted` compute the maximum and minimum Pearson’s $r$ achievable by optimally pairing the categories (largest with largest for maximum, largest with smallest for minimum).
    
3. **Permutation Distribution:**  
    The `simulate_random_corr` function randomly permutes the full sample (constructed from the counts) to generate an empirical distribution of $r$ under the null hypothesis of no association.
    
4. **95% CI:**  
    We calculate the 2.5th and 97.5th percentiles of the simulated $r$ values, which form the 95% “null interval.”
    
5. **Plotting:**  
    The `plot_empirical_distribution` function displays a histogram (with a density overlay) of the simulated $r$ values, along with vertical lines for the theoretical min (red dashed), theoretical max (green dashed), and the 95% CI bounds (purple dotted). A legend identifies each line.
    

This complete script both demonstrates the functions with example data and visualizes the key components, satisfying all the suggested improvements.

* * *

**You:**

Better.  But two things:
1. use ggplot to produce the graphs in e.g. plot_empirical_distribution.  Also be sure to show the marginal distributions both graphically and as a table
2. make sure the range of the x-axis in the graph produced by plot_empirical_distribution contains at least r_min and r_max

* * *

**ChatGPT:**

my best guess is that the following complete R script uses **ggplot2** (and **gridExtra**) to display both the marginal distributions (as a table and bar plots) and the empirical permutation distribution of Pearson's $r$ with the theoretical minimum, maximum, and 95% CI clearly marked. I'll walk you through the code step-by-step:

```r
# Load required libraries
library(ggplot2)
library(gridExtra)

# -----------------------------------------------------------------------------
# 1. Define functions to compute theoretical correlations and simulate r values

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals are probabilities (sum ~1), generate counts; otherwise assume counts.
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
    if (sum(countsY) != sample_size)
      stop("Total counts for X and Y must be equal.")
  }
  
  # Define ordinal levels (assumed to be 0,1,2,...)
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Compute proportions and moments
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

# Function to compute the minimum correlation (pair X descending with Y ascending)
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
    if (sum(countsY) != sample_size)
      stop("Total counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Create full sample vectors based on counts
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # Pair highest X with lowest Y to minimize the product
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  r_min <- cor(x_sorted, y_sorted)
  return(r_min)
}

# Function to simulate the permutation (randomization) distribution of Pearson's r
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
    if (sum(countsY) != sample_size)
      stop("Total counts for X and Y must be equal.")
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

# -----------------------------------------------------------------------------
# 2. Define functions to plot the results using ggplot2

# Function to plot the empirical distribution of Pearson's r with theoretical bounds and 95% CI
plot_empirical_distribution <- function(r_vals, r_min, r_max, ci_bounds,
                                          main = "Empirical Distribution of Pearson's r") {
  # Create a data frame for r_vals
  df <- data.frame(r = r_vals)
  
  # Determine x-axis limits ensuring r_min and r_max are included
  x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
  x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05
  
  p <- ggplot(df, aes(x = r)) +
    geom_histogram(aes(y = ..density..), bins = 30,
                   fill = "lightblue", color = "white", alpha = 0.7) +
    geom_density(color = "darkblue", size = 1) +
    geom_vline(xintercept = r_min, color = "red", linetype = "dashed", size = 1) +
    geom_vline(xintercept = r_max, color = "green", linetype = "dashed", size = 1) +
    geom_vline(xintercept = ci_bounds[1], color = "purple", linetype = "dotted", size = 1) +
    geom_vline(xintercept = ci_bounds[2], color = "purple", linetype = "dotted", size = 1) +
    labs(title = main,
         x = "Pearson's r",
         y = "Density") +
    xlim(x_lower, x_upper) +
    theme_minimal()
  return(p)
}

# Function to plot the marginal distribution as a bar plot
plot_marginal <- function(counts, varname = "X") {
  df <- data.frame(Category = factor(0:(length(counts)-1)),
                   Frequency = counts)
  p <- ggplot(df, aes(x = Category, y = Frequency)) +
    geom_bar(stat = "identity", fill = "skyblue", color = "black", alpha = 0.8) +
    labs(title = paste("Marginal Distribution of", varname),
         x = paste(varname, "Categories"),
         y = "Frequency") +
    theme_minimal()
  return(p)
}

# -----------------------------------------------------------------------------
# 3. Demonstration using example data

# Set sample size
sample_size <- 10000

# Define sample marginal distributions as frequencies (counts)
# For X, assume 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# For Y, assume 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Display the marginal distributions as tables in the console
cat("Marginal Distribution for X (counts):\n")
print(data.frame(Category = 0:(length(marginalX_counts)-1),
                 Frequency = marginalX_counts))
cat("\nMarginal Distribution for Y (counts):\n")
print(data.frame(Category = 0:(length(marginalY_counts)-1),
                 Frequency = marginalY_counts))

# Also, display the marginal distributions graphically using ggplot2
pX <- plot_marginal(marginalX_counts, varname = "X")
pY <- plot_marginal(marginalY_counts, varname = "Y")
grid.arrange(pX, pY, ncol = 2)

# Compute theoretical maximum and minimum Pearson correlations
r_max <- max_corr_sorted(marginalX_counts, marginalY_counts, sample_size = sample_size)
r_min <- min_corr_sorted(marginalX_counts, marginalY_counts, sample_size = sample_size)
cat("\nTheoretical maximum Pearson's r:", round(r_max, 3), "\n")
cat("Theoretical minimum Pearson's r:", round(r_min, 3), "\n")

# Simulate the permutation distribution of Pearson's r
set.seed(123)  # for reproducibility
r_vals <- simulate_random_corr(marginalX_counts, marginalY_counts, nsim = 1000, sample_size = sample_size)

# Calculate the 95% confidence interval (null interval) from the permutation distribution
ci_bounds <- quantile(r_vals, probs = c(0.025, 0.975))
cat("\n95% CI for Pearson's r (from permutation distribution):\n")
print(ci_bounds)

# Plot the empirical distribution of Pearson's r using ggplot2,
# ensuring that the x-axis includes at least r_min and r_max
p_empirical <- plot_empirical_distribution(r_vals, r_min, r_max, ci_bounds,
                                           main = "Permutation Distribution of Pearson's r")
print(p_empirical)
```

### Explanation (Step-by-Step):

1. **Functions for Theoretical Bounds & Simulation:**
    
    * **max_corr_sorted** and **min_corr_sorted** compute the optimal (maximum) and worst (minimum) Pearson's $r$ given the marginal counts by pairing the categories accordingly.
        
    * **simulate_random_corr** generates a permutation (or randomization) distribution by independently shuffling the full samples constructed from the marginal counts.
        
2. **Graphing with ggplot2:**
    
    * **plot_empirical_distribution** uses ggplot2 to create a histogram overlaid with a density plot of the simulated $r$ values. It adds vertical lines for the theoretical minimum (red dashed), maximum (green dashed), and the 95% confidence bounds (purple dotted). The x-axis limits are set to ensure they cover at least $r_{min}$ and $r_{max}$.
        
    * **plot_marginal** creates bar plots of the marginal distributions.
        
3. **Demonstration with Example Data:**
    
    * The marginal distributions for $X$ and $Y$ are specified as counts and printed as tables.
        
    * The marginal distributions are then visualized side-by-side.
        
    * The theoretical maximum and minimum correlations are computed and printed.
        
    * A permutation distribution of $r$ is simulated, and its 95% CI is calculated.
        
    * Finally, the empirical distribution is plotted with the ggplot2 function.
        

This script fully demonstrates how to show the marginal distributions (both as a table and graphically) and how to visualize the permutation distribution of Pearson's $r$ with the proper x-axis range including $r_{min}$ and $r_{max}$, along with the 95% CI.

* * *

**You:**

Ah, no, not quite.  But close!  The addition of a legend produces this error:
"""
Error in ggplot_add():
! Can't add o to a <ggplot> object.
Run rlang::last_trace() to see where the error occurred.
"""
Please remember, the graphic must be successfully produced using ggplot within the tidyverse 'universe.'


* * *

**ChatGPT:**

my best guess is that we can modify our plotting function to build a data frame of vertical‐line definitions (including the theoretical min, max, and 95% CI bounds) and then map their color and linetype in ggplot so that a legend is produced. Here’s a complete R script using ggplot2 (and gridExtra) that:

1. Displays the marginal distributions both as tables and bar plots.
    
2. Simulates the permutation distribution of Pearson’s r.
    
3. Plots the histogram of r with a density overlay and vertical lines for r_min, r_max, and the 95% CI—with a proper legend—and ensures the x‐axis covers the full range.
    

```r
# Load required libraries
library(ggplot2)
library(gridExtra)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. Define functions to compute theoretical correlations and simulate r values

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals sum to approximately 1, assume probabilities; else assume counts.
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
    if (sum(countsY) != sample_size)
      stop("Total counts for X and Y must be equal.")
  }
  
  # Define ordinal levels (assumed to be 0,1,2,...)
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Compute proportions and moments
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

# Function to compute the minimum correlation (pair X descending with Y ascending)
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
    if (sum(countsY) != sample_size)
      stop("Total counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Create full sample vectors based on counts
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # Pair highest X with lowest Y to minimize the product
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  r_min <- cor(x_sorted, y_sorted)
  return(r_min)
}

# Function to simulate the permutation (randomization) distribution of Pearson's r
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
    if (sum(countsY) != sample_size)
      stop("Total counts for X and Y must be equal.")
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

# -----------------------------------------------------------------------------
# 2. Define functions to plot the results using ggplot2

# Function to plot the empirical distribution of Pearson's r with theoretical bounds and 95% CI
plot_empirical_distribution <- function(r_vals, r_min, r_max, ci_bounds,
                                          main = "Empirical Distribution of Pearson's r") {
  # Create a data frame for r_vals
  df <- data.frame(r = r_vals)
  
  # Ensure x-axis limits include at least r_min and r_max.
  x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
  x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05
  
  # Build a data frame for vertical lines and their labels.
  vlines <- data.frame(
    intercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
    label = factor(c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"),
                   levels = c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"))
  )
  
  # Create the plot.
  p <- ggplot(df, aes(x = r)) +
    geom_histogram(aes(y = ..density..), bins = 30,
                   fill = "lightblue", color = "white", alpha = 0.7) +
    geom_density(color = "darkblue", size = 1) +
    geom_vline(data = vlines, aes(xintercept = intercept, color = label, linetype = label), size = 1) +
    scale_color_manual(name = "Legend", 
                       values = c("Theoretical Min" = "red", 
                                  "Theoretical Max" = "green", 
                                  "95% CI Lower" = "purple", 
                                  "95% CI Upper" = "purple")) +
    scale_linetype_manual(name = "Legend",
                          values = c("Theoretical Min" = "dashed", 
                                     "Theoretical Max" = "dashed", 
                                     "95% CI Lower" = "dotted", 
                                     "95% CI Upper" = "dotted")) +
    labs(title = main,
         x = "Pearson's r",
         y = "Density") +
    xlim(x_lower, x_upper) +
    theme_minimal()
  return(p)
}

# Function to plot the marginal distribution as a bar plot using ggplot2
plot_marginal <- function(counts, varname = "X") {
  df <- data.frame(Category = factor(0:(length(counts)-1)),
                   Frequency = counts)
  p <- ggplot(df, aes(x = Category, y = Frequency)) +
    geom_bar(stat = "identity", fill = "skyblue", color = "black", alpha = 0.8) +
    labs(title = paste("Marginal Distribution of", varname),
         x = paste(varname, "Categories"),
         y = "Frequency") +
    theme_minimal()
  return(p)
}

# -----------------------------------------------------------------------------
# 3. Demonstration using example data

# Set sample size
sample_size <- 10000

# Define sample marginal distributions as frequencies (counts)
# For X, assume 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# For Y, assume 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Display the marginal distributions as tables in the console
cat("Marginal Distribution for X (counts):\n")
print(data.frame(Category = 0:(length(marginalX_counts)-1),
                 Frequency = marginalX_counts))
cat("\nMarginal Distribution for Y (counts):\n")
print(data.frame(Category = 0:(length(marginalY_counts)-1),
                 Frequency = marginalY_counts))

# Also, display the marginal distributions graphically using ggplot2
pX <- plot_marginal(marginalX_counts, varname = "X")
pY <- plot_marginal(marginalY_counts, varname = "Y")
grid.arrange(pX, pY, ncol = 2)

# Compute theoretical maximum and minimum Pearson correlations
r_max <- max_corr_sorted(marginalX_counts, marginalY_counts, sample_size = sample_size)
r_min <- min_corr_sorted(marginalX_counts, marginalY_counts, sample_size = sample_size)
cat("\nTheoretical maximum Pearson's r:", round(r_max, 3), "\n")
cat("Theoretical minimum Pearson's r:", round(r_min, 3), "\n")

# Simulate the permutation distribution of Pearson's r
set.seed(123)  # for reproducibility
r_vals <- simulate_random_corr(marginalX_counts, marginalY_counts, nsim = 1000, sample_size = sample_size)

# Calculate the 95% CI (null interval) from the permutation distribution
ci_bounds <- quantile(r_vals, probs = c(0.025, 0.975))
cat("\n95% CI for Pearson's r (from permutation distribution):\n")
print(ci_bounds)

# Plot the empirical distribution of Pearson's r using ggplot2
p_empirical <- plot_empirical_distribution(r_vals, r_min, r_max, ci_bounds,
                                           main = "Permutation Distribution of Pearson's r")
print(p_empirical)
```

### Explanation (Step-by-Step):

1. **Marginal Distributions:**
    
    * We define the marginal frequencies for X and Y and print them as tables.
        
    * We also create bar plots (using the `plot_marginal` function) and arrange them side-by-side with `grid.arrange`.
        
2. **Theoretical Bounds and Simulation:**
    
    * The functions `max_corr_sorted` and `min_corr_sorted` compute the theoretical maximum and minimum Pearson’s r.
        
    * The `simulate_random_corr` function creates a permutation distribution of r.
        
3. **ggplot2 Plot for Permutation Distribution:**
    
    * We build a data frame (`vlines`) that contains the x-intercepts and labels for the theoretical min, max, and the CI bounds.
        
    * In `plot_empirical_distribution`, we add vertical lines via `geom_vline` mapped to this data frame so that the legend is automatically produced.
        
    * The x-axis limits are set to ensure they include both `r_min` and `r_max`.
        

This script should produce a ggplot graphic (within the tidyverse ecosystem) without error and with a proper legend.

* * *

**You:**

Why is this command:

p <- ggplot(df, aes(x = r)) +
    geom_histogram(aes(y = ..density..), bins = 30,
                   fill = "lightblue", color = "white", alpha = 0.7) +
    geom_density(color = "darkblue", size = 1) +
    geom_vline(xintercept = r_min, color = "red", linetype = "dashed", size = 1) +
    geom_vline(xintercept = r_max, color = "green", linetype = "dashed", size = 1) +
    geom_vline(xintercept = ci_bounds[1], color = "purple", linetype = "dotted", size = 1) +
    geom_vline(xintercept = ci_bounds[2], color = "purple", linetype = "dotted", size = 1) +  labs(title = main,
         x = "Pearson's r",
         y = "Density") +
    xlim(x_lower, x_upper) +
    theme_minimal() +
  	legend("topright",
  		   legend = c(paste("Min r =", round(r_min, 3)),
  		   		   paste("Max r =", round(r_max, 3)),
  		   		   paste("95% CI:", paste(round(ci_bounds, 3), collapse = " to "))),
  		   col = c("red", "green", "purple"), lwd = 2, lty = c(2, 2, 3))

producing this error?
"""
Error in ggplot_add():
! Can't add o to a <ggplot> object.
Run rlang::last_trace() to see where the error occurred.
"""

* * *

**ChatGPT:**

my best guess is that the error occurs because you're trying to add the base R function `legend()` to a ggplot object using the `+` operator. In ggplot2, legends are generated automatically from mapped aesthetics, and you don't use the base R `legend()` function in that context. Here's a step-by-step explanation:

1. **Base R vs. ggplot2:**  
    The `legend()` function is part of base R plotting, not ggplot2. ggplot2 handles legends internally via aesthetic mappings and scale functions.
    
2. **Adding Elements in ggplot2:**  
    In ggplot2, you add layers using `+`, but each layer must be a ggplot2 object. Since `legend()` returns `NULL` (or isn't a ggplot2 object), it produces an error when you try to add it.
    
3. **Correct Approach:**  
    To customize legends in ggplot2, you should map your data to aesthetics (like color, linetype) and then use functions like `scale_color_manual()` and `scale_linetype_manual()` to control the appearance of the legend.
    

For example, if you want to include vertical lines with a legend, you can create a data frame with the labels and then map `color` and `linetype` accordingly, as shown in the improved plotting function above.

By removing the base R `legend()` call and using ggplot2's native legend handling, the error will be resolved.

* * *

**You:**

Thank you.  What would the correct ggplot syntax be for this graphic?

* * *

**ChatGPT:**

my best guess is that you need to map the vertical lines to a data frame so that ggplot2 can automatically generate the legend. Here's the correct ggplot syntax:

```r
# Assume df is a data frame with your r-values, and that r_min, r_max, and ci_bounds are defined.
# Also assume x_lower and x_upper are set to ensure the full range is shown.

# Create a data frame for the vertical lines
vlines <- data.frame(
  xintercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
  label = factor(c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"),
                 levels = c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"))
)

# Build the ggplot
p <- ggplot(df, aes(x = r)) +
  geom_histogram(aes(y = ..density..), bins = 30,
                 fill = "lightblue", color = "white", alpha = 0.7) +
  geom_density(color = "darkblue", size = 1) +
  geom_vline(data = vlines,
             aes(xintercept = xintercept, color = label, linetype = label),
             size = 1) +
  scale_color_manual(name = "Legend", 
                     values = c("Theoretical Min" = "red", 
                                "Theoretical Max" = "green", 
                                "95% CI Lower" = "purple", 
                                "95% CI Upper" = "purple")) +
  scale_linetype_manual(name = "Legend",
                        values = c("Theoretical Min" = "dashed", 
                                   "Theoretical Max" = "dashed", 
                                   "95% CI Lower" = "dotted", 
                                   "95% CI Upper" = "dotted")) +
  labs(title = "Empirical Distribution of Pearson's r",
       x = "Pearson's r",
       y = "Density") +
  xlim(x_lower, x_upper) +
  theme_minimal()

print(p)
```

### Explanation (Step-by-Step):

1. **Data Frame for Vertical Lines:**  
    We create a data frame `vlines` with two columns: `xintercept` for the x positions (using `r_min`, `r_max`, and the CI bounds) and `label` to distinguish each line.
    
2. **Mapping in `geom_vline`:**  
    In `geom_vline`, we set `data = vlines` and map `xintercept`, `color`, and `linetype` to the corresponding columns. This ensures that ggplot2 generates a legend automatically.
    
3. **Custom Scales for Legend:**  
    We use `scale_color_manual` and `scale_linetype_manual` to define the colors and linetypes for each label in the legend.
    
4. **Histogram and Density:**  
    The main plot consists of a histogram of the `r` values from `df` with an overlaid density curve.
    
5. **x-axis Limits:**  
    The `xlim(x_lower, x_upper)` call ensures the x-axis covers at least the range of `r_min` to `r_max`.
    

This syntax uses only ggplot2 functions and correctly produces the desired graphic with a legend, without invoking the base R `legend()` function.

* * *

**You:**

Thank you.  That is excellent.  Can you please show me how to Monte-Carlo over different number of categories for X and Y and different (and preferably extreme) marginals for the X and Y.  Also, they should differ in the number of categories, but generally range from about 5 to 11 categories for those two ordinal variables.  Do you understand?

* * *

**ChatGPT:**

my best guess is that we can set up a loop (or use an apply‐style function) to iterate over various numbers of categories for X and Y, generate “extreme” marginal probability vectors for each, and then run the simulation functions for each combination. Below is an example R script that does just that:

```r
# Load required libraries
library(ggplot2)
library(gridExtra)
library(dplyr)

# ----------------------------
# Assume that the following functions have already been defined:
# - max_corr_sorted(marginalX, marginalY, sample_size)
# - min_corr_sorted(marginalX, marginalY, sample_size)
# - simulate_random_corr(marginalX, marginalY, nsim, sample_size)
# - plot_empirical_distribution(r_vals, r_min, r_max, ci_bounds, main)
#
# These functions expect marginal distributions as probability vectors (i.e. they sum to 1).
# ----------------------------

# Set simulation parameters
sample_size <- 5000   # total sample size for generating counts from probabilities
nsim <- 1000          # number of Monte Carlo simulations for the permutation distribution

# Define a set of category numbers for X and Y.
# For demonstration, we choose a few different values.
# (They need not be identical; in fact, we want them to differ.)
nX_values <- c(5, 7, 9)
nY_values <- c(6, 8, 10, 11)

# Create all combinations (only include those where nX != nY)
combinations <- expand.grid(nX = nX_values, nY = nY_values) %>%
  filter(nX != nY)

# Prepare lists to store simulation summaries and plots
results <- list()
plots <- list()

# Loop over each combination
for(i in 1:nrow(combinations)) {
  nX <- combinations$nX[i]
  nY <- combinations$nY[i]
  
  # Generate extreme marginals:
  # For X, we define an extreme skew by putting 70% of the mass on the first category,
  # and distributing the remaining 30% equally over the remaining (nX - 1) categories.
  pX <- c(0.7, rep(0.3/(nX - 1), nX - 1))
  
  # For Y, we create an extreme distribution by assigning a very small mass (e.g., 0.02) 
  # to each of the first (nY - 1) categories and putting the remaining mass in the last category.
  pY <- c(rep(0.02, nY - 1), 1 - 0.02*(nY - 1))
  
  # Compute theoretical maximum and minimum Pearson correlations.
  r_max <- max_corr_sorted(pX, pY, sample_size = sample_size)
  r_min <- min_corr_sorted(pX, pY, sample_size = sample_size)
  
  # Simulate the permutation distribution of Pearson's r for these marginals.
  r_vals <- simulate_random_corr(pX, pY, nsim = nsim, sample_size = sample_size)
  
  # Compute 95% confidence (null) interval and median for the simulation.
  ci_bounds <- quantile(r_vals, probs = c(0.025, 0.975))
  median_r <- median(r_vals)
  
  # Save the summary results
  results[[i]] <- data.frame(nX = nX, nY = nY,
                             r_min = r_min, r_max = r_max,
                             median_r = median_r,
                             CI_lower = ci_bounds[1], CI_upper = ci_bounds[2])
  
  # Create a title string to annotate the plot with the current nX and nY.
  title_str <- paste("nX =", nX, "nY =", nY)
  
  # Create the permutation distribution plot using ggplot2.
  p_emp <- plot_empirical_distribution(data.frame(r = r_vals),
                                       r_min, r_max, ci_bounds,
                                       main = paste("Permutation Distribution of r (", title_str, ")", sep = " "))
  
  plots[[i]] <- p_emp
}

# Combine all simulation summaries into one data frame and print it.
summary_df <- do.call(rbind, results)
print(summary_df)

# Optionally, arrange and display all the plots in a grid.
# (Depending on the number of combinations, you may need to adjust ncol.)
grid.arrange(grobs = plots, ncol = 2)
```

### Step-by-Step Explanation

1. **Setting Simulation Parameters:**  
    We specify a `sample_size` (number of observations) and `nsim` (number of Monte Carlo iterations).
    
2. **Defining Category Combinations:**  
    We choose several different numbers of categories for X (e.g. 5, 7, 9) and for Y (e.g. 6, 8, 10, 11). We then use `expand.grid` to form all possible combinations, filtering out cases where X and Y have the same number of categories.
    
3. **Generating Extreme Marginals:**
    
    * For X: An extreme skew is created by assigning 70% of the probability mass to the first category and equally distributing the remaining 30% among the rest.
        
    * For Y: We allocate a very small probability (0.02) to each of the first (nY-1) categories and assign the remainder to the last category.  
        These probability vectors are “extreme” in that one category dominates.
        
4. **Computing Theoretical Bounds and Simulation:**  
    For each combination, we compute the theoretical maximum and minimum Pearson’s r (using `max_corr_sorted` and `min_corr_sorted`), simulate the permutation distribution with `simulate_random_corr`, and then calculate the 95% interval and median.
    
5. **Plotting:**  
    Using our ggplot-based function `plot_empirical_distribution`, we produce a histogram/density plot for the permutation distribution. The plot displays vertical lines for the theoretical min, max, and the 95% CI bounds. The title of each plot is annotated with the corresponding nX and nY values.
    
6. **Output:**  
    Finally, we combine all summary results into a data frame (which you can inspect in the console) and arrange all the plots in a grid using `grid.arrange`.
    

Yes, I understand your request, and the code above demonstrates how to Monte Carlo over different numbers of categories for X and Y using extreme marginal distributions while allowing X and Y to differ in their number of categories (ranging approximately from 5 to 11).

* * *

**You:**

Thank you.  I am sorry, but I do not understand the following I am getting from R:
"""
> 	# Create the permutation distribution plot using ggplot2.
> 	p_emp <- plot_empirical_distribution(data.frame(r = r_vals),
+ 										 r_min, r_max, ci_bounds,
+ 										 main = paste("Permutation Distribution of r (", title_str, ")", sep = " "))
Error in xtfrm.data.frame(x) : cannot xtfrm data frames
14.
stop("cannot xtfrm data frames")
13.
xtfrm.data.frame(x)
12.
xtfrm(x)
11.
as.vector(xtfrm(x))
10.
FUN(X[[i]], ...)
9.
lapply(z, function(x) if (is.object(x)) as.vector(xtfrm(x)) else x)
8.
order(x, na.last = na.last, decreasing = decreasing)
7.
[.data.frame(x, order(x, na.last = na.last, decreasing = decreasing))
6.
x[order(x, na.last = na.last, decreasing = decreasing)]
5.
sort.default(x, partial = if (n == 0) numeric() else unique(c(lo,
hi)[p.ok]))
4.
sort(x, partial = if (n == 0) numeric() else unique(c(lo, hi)[p.ok]))
3.
quantile.default(r_vals, 0.01)
2.
quantile(r_vals, 0.01)
1.
plot_empirical_distribution(data.frame(r = r_vals), r_min, r_max,
ci_bounds, main = paste("Permutation Distribution of r (",
title_str, ")", sep = " "))
"""

* * *

**ChatGPT:**

my best guess is that the error occurs because you're trying to add a base R legend (via the `legend()` function) using the `+` operator to a ggplot object. In ggplot2, legends are automatically created from aesthetic mappings, so you should remove the `legend()` call and instead map the vertical lines to a data frame so ggplot generates the legend automatically. Here’s the correct ggplot syntax:

```r
# Create a data frame for the simulated r values
df <- data.frame(r = r_vals)

# Determine x-axis limits ensuring r_min and r_max are included.
x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05

# Create a data frame for vertical lines (theoretical min, max, and CI bounds)
vlines <- data.frame(
  xintercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
  label = factor(c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"),
                 levels = c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"))
)

# Build the ggplot object
p <- ggplot(df, aes(x = r)) +
  geom_histogram(aes(y = ..density..), bins = 30,
                 fill = "lightblue", color = "white", alpha = 0.7) +
  geom_density(color = "darkblue", size = 1) +
  geom_vline(data = vlines,
             aes(xintercept = xintercept, color = label, linetype = label),
             size = 1) +
  scale_color_manual(name = "Legend", 
                     values = c("Theoretical Min" = "red", 
                                "Theoretical Max" = "green", 
                                "95% CI Lower" = "purple", 
                                "95% CI Upper" = "purple")) +
  scale_linetype_manual(name = "Legend",
                        values = c("Theoretical Min" = "dashed", 
                                   "Theoretical Max" = "dashed", 
                                   "95% CI Lower" = "dotted", 
                                   "95% CI Upper" = "dotted")) +
  labs(title = "Empirical Distribution of Pearson's r",
       x = "Pearson's r",
       y = "Density") +
  xlim(x_lower, x_upper) +
  theme_minimal()

print(p)
```

### Explanation (Step-by-Step):

1. **Data Preparation:**  
    We create a data frame `df` with our simulated r values. We also compute `x_lower` and `x_upper` to ensure the x-axis covers the range that includes both `r_min` and `r_max`.
    
2. **Vertical Lines Data Frame:**  
    We then create a data frame `vlines` with columns `xintercept` (the positions for our vertical lines) and `label` (which identifies each line).
    
3. **Mapping to Aesthetics:**  
    In `geom_vline`, we set `data = vlines` and map `xintercept`, `color`, and `linetype` to the corresponding columns. This mapping allows ggplot2 to automatically generate a legend.
    
4. **Customizing Legends:**  
    We use `scale_color_manual` and `scale_linetype_manual` to define the colors and linetypes for each label in the legend.
    
5. **No `legend()` Call:**  
    Notice that we do not use the base R `legend()` function—this is the source of your error. Instead, the legend is automatically generated from the aesthetic mappings.
    

This is the correct ggplot2 approach for producing your graphic without encountering the error.

* * *

**You:**

That one instance worked.  Please put it all together.

* * *

**ChatGPT:**

my best guess is that the following complete R script puts everything together. It defines the functions for computing the theoretical maximum and minimum Pearson’s r, simulates the permutation (randomization) distribution, produces ggplot graphics (with a legend) for the empirical distribution, and then runs a Monte Carlo over various numbers of categories for X and Y with extreme marginals.

```r
# Load required libraries
library(ggplot2)
library(gridExtra)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. Define functions to compute theoretical correlations and simulate r values

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals sum to approximately 1, assume probabilities; else assume counts.
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
    if (sum(countsY) != sample_size)
      stop("Total counts for X and Y must be equal.")
  }
  
  # Define ordinal levels (assumed to be 0,1,2,...)
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Compute proportions and moments
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

# Function to compute the minimum correlation (pair X descending with Y ascending)
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
    if (sum(countsY) != sample_size)
      stop("Total counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  # Create full sample vectors based on counts
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # Pair highest X with lowest Y to minimize the product
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  r_min <- cor(x_sorted, y_sorted)
  return(r_min)
}

# Function to simulate the permutation (randomization) distribution of Pearson's r
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
    if (sum(countsY) != sample_size)
      stop("Total counts for X and Y must be equal.")
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

# -----------------------------------------------------------------------------
# 2. Define ggplot functions to display results

# Function to plot the empirical distribution of Pearson's r with vertical lines and legend
plot_empirical_distribution <- function(r_vals, r_min, r_max, ci_bounds,
                                          main = "Empirical Distribution of Pearson's r") {
  # Data frame for r values
  df <- data.frame(r = r_vals)
  
  # Determine x-axis limits to include r_min and r_max.
  x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
  x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05
  
  # Data frame for vertical lines (theoretical min, max, and CI bounds)
  vlines <- data.frame(
    xintercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
    label = factor(c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"),
                   levels = c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"))
  )
  
  p <- ggplot(df, aes(x = r)) +
    geom_histogram(aes(y = ..density..), bins = 30,
                   fill = "lightblue", color = "white", alpha = 0.7) +
    geom_density(color = "darkblue", size = 1) +
    geom_vline(data = vlines,
               aes(xintercept = xintercept, color = label, linetype = label),
               size = 1) +
    scale_color_manual(name = "Legend", 
                       values = c("Theoretical Min" = "red", 
                                  "Theoretical Max" = "green", 
                                  "95% CI Lower" = "purple", 
                                  "95% CI Upper" = "purple")) +
    scale_linetype_manual(name = "Legend",
                          values = c("Theoretical Min" = "dashed", 
                                     "Theoretical Max" = "dashed", 
                                     "95% CI Lower" = "dotted", 
                                     "95% CI Upper" = "dotted")) +
    labs(title = main,
         x = "Pearson's r",
         y = "Density") +
    xlim(x_lower, x_upper) +
    theme_minimal()
  return(p)
}

# Function to plot marginal distributions as bar plots using ggplot2
plot_marginal <- function(counts, varname = "X") {
  df <- data.frame(Category = factor(0:(length(counts)-1)),
                   Frequency = counts)
  p <- ggplot(df, aes(x = Category, y = Frequency)) +
    geom_bar(stat = "identity", fill = "skyblue", color = "black", alpha = 0.8) +
    labs(title = paste("Marginal Distribution of", varname),
         x = paste(varname, "Categories"),
         y = "Frequency") +
    theme_minimal()
  return(p)
}

# -----------------------------------------------------------------------------
# 3. Monte Carlo over different numbers of categories with extreme marginals

# Simulation parameters
sample_size <- 5000  # sample size for counts
nsim <- 1000         # number of simulations for permutation distribution

# Define a range for number of categories for X and Y.
# X categories: 5, 7, or 9
# Y categories: 6, 8, 10, or 11 (ensuring they differ from X)
nX_values <- c(5, 7, 9)
nY_values <- c(6, 8, 10, 11)

# Create all combinations (we only want combinations where nX != nY)
combinations <- expand.grid(nX = nX_values, nY = nY_values) %>%
  filter(nX != nY)

# Prepare lists to store simulation summaries and plots
results <- list()
plots <- list()

# Loop over each combination of categories
for(i in 1:nrow(combinations)) {
  nX <- combinations$nX[i]
  nY <- combinations$nY[i]
  
  # Generate extreme marginals:
  # For X: assign 70% probability to the first category and split the remaining 30% equally.
  pX <- c(0.7, rep(0.3/(nX - 1), nX - 1))
  
  # For Y: assign a very small probability (e.g., 0.02) to the first (nY - 1) categories,
  # and the remainder to the last category.
  pY <- c(rep(0.02, nY - 1), 1 - 0.02*(nY - 1))
  
  # Compute theoretical maximum and minimum correlations.
  r_max <- max_corr_sorted(pX, pY, sample_size = sample_size)
  r_min <- min_corr_sorted(pX, pY, sample_size = sample_size)
  
  # Simulate the permutation distribution of Pearson's r.
  r_vals <- simulate_random_corr(pX, pY, nsim = nsim, sample_size = sample_size)
  
  # Compute the 95% confidence interval from the permutation distribution.
  ci_bounds <- quantile(r_vals, probs = c(0.025, 0.975))
  median_r <- median(r_vals)
  
  # Save the summary results
  results[[i]] <- data.frame(nX = nX, nY = nY,
                             r_min = r_min, r_max = r_max,
                             median_r = median_r,
                             CI_lower = ci_bounds[1], CI_upper = ci_bounds[2])
  
  # Create a title string for the plot.
  title_str <- paste("nX =", nX, "nY =", nY)
  
  # Create the permutation distribution plot using ggplot2.
  p_emp <- plot_empirical_distribution(r_vals, r_min, r_max, ci_bounds,
                                       main = paste("Permutation Distribution of r (", title_str, ")", sep = " "))
  
  plots[[i]] <- p_emp
}

# Combine all simulation summaries into one data frame and print it.
summary_df <- do.call(rbind, results)
print(summary_df)

# Optionally, arrange and display all the permutation distribution plots.
grid.arrange(grobs = plots, ncol = 2)

# -----------------------------------------------------------------------------
# Also, display the marginal distributions for one instance as examples
# (Here we use the first combination from our simulation)
example_nX <- combinations$nX[1]
example_nY <- combinations$nY[1]
# Generate extreme marginals for this instance.
example_pX <- c(0.7, rep(0.3/(example_nX - 1), example_nX - 1))
example_pY <- c(rep(0.02, example_nY - 1), 1 - 0.02*(example_nY - 1))
# Convert probabilities to counts for display purposes.
example_countsX <- round(example_pX * sample_size)
example_countsY <- round(example_pY * sample_size)

# Print the marginal distributions as tables.
cat("Marginal Distribution for X (counts):\n")
print(data.frame(Category = 0:(length(example_countsX)-1),
                 Frequency = example_countsX))
cat("\nMarginal Distribution for Y (counts):\n")
print(data.frame(Category = 0:(length(example_countsY)-1),
                 Frequency = example_countsY))

# Plot the marginal distributions using ggplot2.
pX_plot <- plot_marginal(example_countsX, varname = "X")
pY_plot <- plot_marginal(example_countsY, varname = "Y")
grid.arrange(pX_plot, pY_plot, ncol = 2)
```

### Explanation (Step-by-Step):

1. **Function Definitions:**  
    The script defines functions to calculate the theoretical maximum and minimum Pearson’s r given marginal distributions, simulate the permutation distribution, and create ggplot graphics (including vertical lines with a legend).
    
2. **Monte Carlo Setup:**  
    It sets up simulation parameters and defines a range for the number of categories for X and Y. Extreme marginal distributions are generated for each combination.
    
    * For X, 70% mass is placed on the first category.
        
    * For Y, a very small mass (0.02) is assigned to all but the last category.
        
3. **Loop Over Combinations:**  
    For each combination of category counts (ensuring nX ≠ nY), the script computes the theoretical bounds, simulates the permutation distribution, calculates the 95% CI, and produces a ggplot with vertical lines and an automatically generated legend.
    
4. **Results and Plots:**  
    All summary results are combined into a data frame and printed. The permutation distribution plots for each combination are arranged in a grid using `grid.arrange`.
    
5. **Marginal Distributions Display:**  
    Finally, the script shows one example of the marginal distributions both as tables and as bar plots.
    

This complete script puts everything together using ggplot2 within the tidyverse ecosystem and should work without error.

* * *

**You:**

Thank you, but I want to explore the relationship between r_min, r_max, and the simulated distribution r_val as a function of marginalX, marginalY, and sample_size.

* * *

**ChatGPT:**

my best guess is that we can set up a simulation study that varies the marginal distributions and the sample size and then plots the theoretical minimum and maximum correlations alongside summary statistics (and even boxplots) of the simulated permutation distributions. Below is a complete R script that demonstrates this exploration. It uses two “scenarios” for the marginal distributions (an extreme and a uniform case) and several sample sizes. We then compute r_min, r_max, and the simulated distribution of r, and finally produce summary plots that show how these values vary with sample size and scenario.

```r
# Load required libraries
library(ggplot2)
library(gridExtra)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. Functions for computing theoretical bounds and simulating the permutation distribution

# Compute maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals sum to ~1, treat them as probabilities; else as counts.
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
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  pX <- countsX / sum(countsX)
  pY <- countsY / sum(countsY)
  muX <- sum(x_levels * pX)
  muY <- sum(y_levels * pY)
  sigmaX <- sqrt(sum(x_levels^2 * pX) - muX^2)
  sigmaY <- sqrt(sum(y_levels^2 * pY) - muY^2)
  
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
  
  E_XY <- sum(outer(x_levels, y_levels, FUN = "*") * joint)
  r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
  return(r_max)
}

# Compute minimum correlation (anti-comonotonic pairing)
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
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # Pair highest X with lowest Y
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  r_min <- cor(x_sorted, y_sorted)
  return(r_min)
}

# Simulate permutation (randomization) distribution of Pearson's r
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
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  r_vals <- numeric(nsim)
  for (i in 1:nsim) {
    x_perm <- sample(x_vec, size = length(x_vec), replace = FALSE)
    y_perm <- sample(y_vec, size = length(y_vec), replace = FALSE)
    r_vals[i] <- cor(x_perm, y_perm)
  }
  return(r_vals)
}

# -----------------------------------------------------------------------------
# 2. Simulation study: Explore how r_min, r_max, and the simulated distribution (r_val)
# vary with marginal distributions and sample size.
#
# We consider two scenarios:
#   - "Extreme": for X, 70% mass on the first category; for Y, very low mass on all but last.
#   - "Uniform": equal probabilities for all categories.
#
# We use 5 categories for each variable in this example and vary sample_size.

# Define scenarios (each with 5 categories)
scenarios <- list(
  Extreme = list(
    marginalX = c(0.7, rep(0.3/4, 4)),
    marginalY = c(rep(0.02, 4), 1 - 0.02*4)
  ),
  Uniform = list(
    marginalX = rep(1/5, 5),
    marginalY = rep(1/5, 5)
  )
)

# Sample sizes to explore
sample_sizes <- c(500, 1000, 5000, 10000)

# Initialize storage for summary statistics and simulated r values.
summary_df <- data.frame()
sim_r_df <- data.frame()

# Loop over scenarios and sample sizes.
for (sc in names(scenarios)) {
  pX <- scenarios[[sc]]$marginalX
  pY <- scenarios[[sc]]$marginalY
  for (s in sample_sizes) {
    # Compute theoretical bounds.
    r_min_val <- min_corr_sorted(pX, pY, sample_size = s)
    r_max_val <- max_corr_sorted(pX, pY, sample_size = s)
    # Simulate the permutation distribution.
    r_sim <- simulate_random_corr(pX, pY, nsim = 1000, sample_size = s)
    med_r <- median(r_sim)
    lower_ci <- quantile(r_sim, 0.025)
    upper_ci <- quantile(r_sim, 0.975)
    
    # Save summary statistics.
    summary_df <- rbind(summary_df, data.frame(
      scenario = sc,
      sample_size = s,
      r_min = r_min_val,
      r_max = r_max_val,
      median_r = med_r,
      lower_ci = lower_ci,
      upper_ci = upper_ci
    ))
    
    # Save the simulated r values.
    sim_r_df <- rbind(sim_r_df, data.frame(
      scenario = sc,
      sample_size = s,
      r = r_sim
    ))
  }
}

# -----------------------------------------------------------------------------
# 3. Plot the results

# (A) Summary plot: For each scenario and sample size, show the median simulated r 
#     with error bars (95% CI) and the theoretical r_min and r_max.
p_summary <- ggplot(summary_df, aes(x = factor(sample_size))) +
  geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci, color = "Simulated 95% CI"), width = 0.2) +
  geom_point(aes(y = median_r, color = "Median Simulated r"), size = 3) +
  geom_point(aes(y = r_min, color = "Theoretical r_min"), shape = 17, size = 3) +
  geom_point(aes(y = r_max, color = "Theoretical r_max"), shape = 17, size = 3) +
  facet_wrap(~scenario, scales = "free_y") +
  labs(x = "Sample Size", y = "Pearson's r",
       title = "Summary of r_min, r_max, and Simulated r Distribution") +
  scale_color_manual(name = "Legend",
                     values = c("Simulated 95% CI" = "blue",
                                "Median Simulated r" = "blue",
                                "Theoretical r_min" = "red",
                                "Theoretical r_max" = "green")) +
  theme_minimal()

# (B) Boxplot of the simulated r distributions by sample size and scenario.
p_box <- ggplot(sim_r_df, aes(x = factor(sample_size), y = r, fill = factor(sample_size))) +
  geom_boxplot() +
  facet_wrap(~scenario, scales = "free_y") +
  labs(x = "Sample Size", y = "Simulated Pearson's r",
       title = "Boxplot of Simulated r Distributions") +
  theme_minimal() +
  guides(fill = FALSE)

# Print the plots.
print(p_summary)
print(p_box)
```

### Explanation (Step-by-Step):

1. **Function Definitions:**  
    We define functions to compute the theoretical maximum (`max_corr_sorted`) and minimum (`min_corr_sorted`) Pearson correlations given marginal distributions, as well as a function (`simulate_random_corr`) to simulate the permutation distribution of r.
    
2. **Simulation Study Setup:**  
    Two scenarios are defined:
    
    * **Extreme:** For X, 70% of the mass is on the first category; for Y, almost all the mass is on the last category.
        
    * **Uniform:** Both X and Y have equal probabilities across 5 categories.  
        We then vary the sample size over a set of values.
        
3. **Loop Over Conditions:**  
    For each scenario and each sample size, we compute the theoretical r_min and r_max, simulate the distribution of r (using 1000 simulations), and compute summary statistics (median and 95% CI). We store these results in `summary_df` and also record all simulated r values in `sim_r_df`.
    
4. **Plotting:**
    
    * **Summary Plot (p_summary):** Displays error bars (95% CI) and points for the median simulated r along with markers for r_min (red) and r_max (green) for each sample size. Facets separate the scenarios.
        
    * **Boxplot (p_box):** Shows the full simulated r distributions as boxplots for each sample size, again faceted by scenario.
        

This script lets you explore how the theoretical bounds and simulated permutation distribution of Pearson’s r vary as a function of the marginal distributions and the sample size.

* * *

**You:**

Thank you!  Can you include elements of the following:
"""
# Combine all simulation summaries into one data frame and print it.
summary_df <- do.call(rbind, results)
print(summary_df)

# Optionally, arrange and display all the permutation distribution plots.
grid.arrange(grobs = plots, ncol = 2)

# -----------------------------------------------------------------------------
# Also, display the marginal distributions for one instance as examples
# (Here we use the first combination from our simulation)
example_nX <- combinations$nX[1]
example_nY <- combinations$nY[1]
# Generate extreme marginals for this instance.
example_pX <- c(0.7, rep(0.3/(example_nX - 1), example_nX - 1))
example_pY <- c(rep(0.02, example_nY - 1), 1 - 0.02*(example_nY - 1))
# Convert probabilities to counts for display purposes.
example_countsX <- round(example_pX * sample_size)
example_countsY <- round(example_pY * sample_size)

# Print the marginal distributions as tables.
cat("Marginal Distribution for X (counts):\n")
print(data.frame(Category = 0:(length(example_countsX)-1),
				 Frequency = example_countsX))
cat("\nMarginal Distribution for Y (counts):\n")
print(data.frame(Category = 0:(length(example_countsY)-1),
				 Frequency = example_countsY))

# Plot the marginal distributions using ggplot2.
pX_plot <- plot_marginal(example_countsX, varname = "X")
pY_plot <- plot_marginal(example_countsY, varname = "Y")
grid.arrange(pX_plot, pY_plot, ncol = 2)
"""
please? Also, I please save the 'glued pairs' -- i.e. joint distribution of X and Y -- that correspond to r_min and r_max, for each scenario.

* * *

**ChatGPT:**

my best guess is that the following complete R script integrates all the requested elements. In this script, we:

1. Define our functions for computing the theoretical bounds and for simulating the permutation distribution.
    
2. Create ggplot functions to display the empirical distribution and the marginal distributions.
    
3. Run a simulation study over different sample sizes and two scenarios (“Extreme” and “Uniform”) for 5‑category X and Y.
    
4. Save the “glued pairs” (the sorted pairings that yield rₘᵢₙ and rₘₐₓ) for each scenario/sample size.
    
5. Combine and print the simulation summaries and arrange the permutation distribution plots.
    
6. Finally, display one example’s marginal distributions both as a table and as ggplot bar plots.
    

Below is the complete R code:

```r
# Load required libraries
library(ggplot2)
library(gridExtra)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. Define functions for theoretical correlations and simulation

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals sum to ~1, treat as probabilities and generate counts.
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
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  pX <- countsX / sum(countsX)
  pY <- countsY / sum(countsY)
  muX <- sum(x_levels * pX)
  muY <- sum(y_levels * pY)
  sigmaX <- sqrt(sum(x_levels^2 * pX) - muX^2)
  sigmaY <- sqrt(sum(y_levels^2 * pY) - muY^2)
  
  # Compute the joint distribution using the cumulative method (Fréchet–Hoeffding upper bound)
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
  
  E_XY <- sum(outer(x_levels, y_levels, FUN = "*") * joint)
  r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
  return(r_max)
}

# Function to compute the minimum correlation (anti-comonotonic pairing)
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
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # For r_min, pair highest X with lowest Y.
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  r_min <- cor(x_sorted, y_sorted)
  return(r_min)
}

# Function to simulate the permutation (randomization) distribution of Pearson's r
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
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  r_vals <- numeric(nsim)
  for (i in 1:nsim) {
    x_perm <- sample(x_vec, size = length(x_vec), replace = FALSE)
    y_perm <- sample(y_vec, size = length(y_vec), replace = FALSE)
    r_vals[i] <- cor(x_perm, y_perm)
  }
  return(r_vals)
}

# -----------------------------------------------------------------------------
# 2. Define ggplot functions for displaying results

# Function to plot the empirical distribution of Pearson's r with vertical lines and legend
plot_empirical_distribution <- function(r_vals, r_min, r_max, ci_bounds,
                                          main = "Empirical Distribution of Pearson's r") {
  df <- data.frame(r = r_vals)
  
  # Set x-axis limits to include r_min and r_max
  x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
  x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05
  
  vlines <- data.frame(
    xintercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
    label = factor(c("Theoretical r_min", "Theoretical r_max", "95% CI Lower", "95% CI Upper"),
                   levels = c("Theoretical r_min", "Theoretical r_max", "95% CI Lower", "95% CI Upper"))
  )
  
  p <- ggplot(df, aes(x = r)) +
    geom_histogram(aes(y = ..density..), bins = 30,
                   fill = "lightblue", color = "white", alpha = 0.7) +
    geom_density(color = "darkblue", size = 1) +
    geom_vline(data = vlines,
               aes(xintercept = xintercept, color = label, linetype = label),
               size = 1) +
    scale_color_manual(name = "Legend", 
                       values = c("Theoretical r_min" = "red", 
                                  "Theoretical r_max" = "green", 
                                  "95% CI Lower" = "purple", 
                                  "95% CI Upper" = "purple")) +
    scale_linetype_manual(name = "Legend",
                          values = c("Theoretical r_min" = "dashed", 
                                     "Theoretical r_max" = "dashed", 
                                     "95% CI Lower" = "dotted", 
                                     "95% CI Upper" = "dotted")) +
    labs(title = main,
         x = "Pearson's r",
         y = "Density") +
    xlim(x_lower, x_upper) +
    theme_minimal()
  return(p)
}

# Function to plot a marginal distribution as a bar plot using ggplot2
plot_marginal <- function(counts, varname = "X") {
  df <- data.frame(Category = factor(0:(length(counts)-1)),
                   Frequency = counts)
  p <- ggplot(df, aes(x = Category, y = Frequency)) +
    geom_bar(stat = "identity", fill = "skyblue", color = "black", alpha = 0.8) +
    labs(title = paste("Marginal Distribution of", varname),
         x = paste(varname, "Categories"),
         y = "Frequency") +
    theme_minimal()
  return(p)
}

# -----------------------------------------------------------------------------
# 3. Simulation study: Explore r_min, r_max, and the simulated distribution as a function 
#    of marginal distributions and sample_size.
#
# We use two scenarios with 5 categories each for X and Y:
#   - "Extreme": X has 70% mass on the first category; Y has very low mass on the first 4 categories.
#   - "Uniform": Both X and Y are uniform.
#
# Also, we vary the sample_size.
scenarios <- list(
  Extreme = list(
    marginalX = c(0.7, rep(0.3/4, 4)),
    marginalY = c(rep(0.02, 4), 1 - 0.02*4)
  ),
  Uniform = list(
    marginalX = rep(1/5, 5),
    marginalY = rep(1/5, 5)
  )
)
sample_sizes <- c(500, 1000, 5000, 10000)

# Storage for summary statistics, simulated r values, and glued pairs.
summary_df <- data.frame()
sim_r_df <- data.frame()
glued_pairs <- list()  # We'll store a nested list: glued_pairs[[scenario]][[sample_size]] = list(max = , min = )

# Loop over scenarios and sample_sizes.
for (sc in names(scenarios)) {
  pX <- scenarios[[sc]]$marginalX
  pY <- scenarios[[sc]]$marginalY
  glued_pairs[[sc]] <- list()
  
  for (s in sample_sizes) {
    # Compute theoretical bounds.
    r_min_val <- min_corr_sorted(pX, pY, sample_size = s)
    r_max_val <- max_corr_sorted(pX, pY, sample_size = s)
    
    # Simulate permutation distribution.
    r_sim <- simulate_random_corr(pX, pY, nsim = 1000, sample_size = s)
    med_r <- median(r_sim)
    lower_ci <- quantile(r_sim, 0.025)
    upper_ci <- quantile(r_sim, 0.975)
    
    # Save summary statistics.
    summary_df <- rbind(summary_df, data.frame(
      scenario = sc,
      sample_size = s,
      r_min = r_min_val,
      r_max = r_max_val,
      median_r = med_r,
      lower_ci = lower_ci,
      upper_ci = upper_ci
    ))
    
    # Save simulated r values.
    sim_r_df <- rbind(sim_r_df, data.frame(
      scenario = sc,
      sample_size = s,
      r = r_sim
    ))
    
    # Save "glued pairs" (joint distributions) for r_max and r_min.
    # Create counts from probabilities.
    x_levels <- 0:(length(pX)-1)
    y_levels <- 0:(length(pY)-1)
    countsX <- round(pX * s)
    countsY <- round(pY * s)
    x_vec <- rep(x_levels, times = countsX)
    y_vec <- rep(y_levels, times = countsY)
    
    max_pairs <- data.frame(X = sort(x_vec, decreasing = TRUE),
                            Y = sort(y_vec, decreasing = TRUE))
    min_pairs <- data.frame(X = sort(x_vec, decreasing = TRUE),
                            Y = sort(y_vec, decreasing = FALSE))
    
    glued_pairs[[sc]][[as.character(s)]] <- list(max = max_pairs, min = min_pairs)
  }
}

# Print the simulation summary.
print(summary_df)

# Optionally, arrange and display all the permutation distribution plots.
plots <- list()
for (i in 1:nrow(summary_df)) {
  row <- summary_df[i, ]
  title_str <- paste("Scenario:", row$scenario, "Sample Size:", row$sample_size)
  r_vals <- sim_r_df %>% filter(scenario == row$scenario, sample_size == row$sample_size) %>% pull(r)
  ci_bounds <- c(row$lower_ci, row$upper_ci)
  p_emp <- plot_empirical_distribution(r_vals, row$r_min, row$r_max, ci_bounds,
                                       main = paste("Permutation Distribution of r (", title_str, ")", sep = " "))
  plots[[i]] <- p_emp
}
grid.arrange(grobs = plots, ncol = 2)

# -----------------------------------------------------------------------------
# Also, display the marginal distributions for one instance as an example.
# (We use the first combination from our simulation.)
example_nX <- length(scenarios[[1]]$marginalX)  # 5 categories
example_nY <- length(scenarios[[1]]$marginalY)  # 5 categories
example_pX <- scenarios[["Extreme"]]$marginalX
example_pY <- scenarios[["Extreme"]]$marginalY
example_countsX <- round(example_pX * sample_sizes[1])
example_countsY <- round(example_pY * sample_sizes[1])

cat("Marginal Distribution for X (counts):\n")
print(data.frame(Category = 0:(length(example_countsX)-1),
                 Frequency = example_countsX))
cat("\nMarginal Distribution for Y (counts):\n")
print(data.frame(Category = 0:(length(example_countsY)-1),
                 Frequency = example_countsY))

pX_plot <- plot_marginal(example_countsX, varname = "X")
pY_plot <- plot_marginal(example_countsY, varname = "Y")
grid.arrange(pX_plot, pY_plot, ncol = 2)

# -----------------------------------------------------------------------------
# Optionally, inspect the glued pairs for one example.
# For instance, for the "Extreme" scenario at sample_size = 500.
example_glued <- glued_pairs[["Extreme"]][["500"]]
cat("\nGlued pairs for maximum correlation (Extreme, sample_size = 500):\n")
print(head(example_glued$max, 10))
cat("\nGlued pairs for minimum correlation (Extreme, sample_size = 500):\n")
print(head(example_glued$min, 10))
```

### Explanation (Step-by-Step):

1. **Function Definitions:**  
    We define three functions:
    
    * `max_corr_sorted` and `min_corr_sorted` compute the theoretical bounds given the marginal probabilities or counts.
        
    * `simulate_random_corr` simulates a permutation distribution by randomly pairing the generated sample.
        
2. **ggplot Functions:**
    
    * `plot_empirical_distribution` plots the histogram/density of simulated r-values and overlays vertical lines for rₘᵢₙ, rₘₐₓ, and the 95% CI.
        
    * `plot_marginal` creates a bar plot of a marginal distribution.
        
3. **Simulation Study:**  
    Two scenarios ("Extreme" and "Uniform") are defined with 5 categories each. We loop over several sample sizes. For each combination, we compute rₘᵢₙ, rₘₐₓ, and simulate the permutation distribution. We also construct the “glued pairs” (sorted pairings) for both the maximum and minimum coupling, saving them in a nested list.
    
4. **Plotting and Display:**  
    The script prints the simulation summary, arranges all permutation distribution plots using `grid.arrange`, and displays an example of the marginal distributions both as tables and as bar plots. Finally, it prints out the first few rows of the glued pairs for one selected example.
    

This complete script should allow you to explore how rₘᵢₙ, rₘₐₓ, and the simulated r distribution vary with marginal distributions and sample size, while also saving the joint (“glued”) pairings for further inspection.

* * *

**You:**

There are errors in this code.  To wit:
"""
Error in data.frame(X = sort(x_vec, decreasing = TRUE), Y = sort(y_vec,  : 
  arguments imply differing number of rows: 502, 500
"""

* * *

**ChatGPT:**

my best guess is that the error occurs because when you compute counts using rounding (e.g. using round(pX * s)), the total may not equal the intended sample size due to rounding errors. One solution is to adjust the counts so that they exactly sum to sample_size. For example, you can do:

```r
countsX <- round(pX * s)
diffX <- s - sum(countsX)
if(diffX != 0) {
  i_max <- which.max(countsX)
  countsX[i_max] <- countsX[i_max] + diffX
}
```

I'll now provide the complete corrected code that includes this fix when creating the "glued pairs" (joint distributions for r_min and r_max), and that also includes all the other elements you requested.

```r
# Load required libraries
library(ggplot2)
library(gridExtra)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. Define functions for theoretical correlations and simulation

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals sum to ~1, treat as probabilities and generate counts.
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
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  pX <- countsX / sum(countsX)
  pY <- countsY / sum(countsY)
  muX <- sum(x_levels * pX)
  muY <- sum(y_levels * pY)
  sigmaX <- sqrt(sum(x_levels^2 * pX) - muX^2)
  sigmaY <- sqrt(sum(y_levels^2 * pY) - muY^2)
  
  # Compute the joint distribution using the cumulative method (Fréchet–Hoeffding upper bound)
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
  
  E_XY <- sum(outer(x_levels, y_levels, FUN = "*") * joint)
  r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
  return(r_max)
}

# Function to compute the minimum correlation (anti-comonotonic pairing)
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
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # For r_min, pair highest X with lowest Y.
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  r_min <- cor(x_sorted, y_sorted)
  return(r_min)
}

# Function to simulate the permutation (randomization) distribution of Pearson's r
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
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  r_vals <- numeric(nsim)
  for (i in 1:nsim) {
    x_perm <- sample(x_vec, size = length(x_vec), replace = FALSE)
    y_perm <- sample(y_vec, size = length(y_vec), replace = FALSE)
    r_vals[i] <- cor(x_perm, y_perm)
  }
  return(r_vals)
}

# -----------------------------------------------------------------------------
# 2. Define ggplot functions for displaying results

# Function to plot the empirical distribution of Pearson's r with vertical lines and legend
plot_empirical_distribution <- function(r_vals, r_min, r_max, ci_bounds,
                                          main = "Empirical Distribution of Pearson's r") {
  df <- data.frame(r = r_vals)
  
  # Set x-axis limits to include r_min and r_max
  x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
  x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05
  
  vlines <- data.frame(
    xintercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
    label = factor(c("Theoretical r_min", "Theoretical r_max", "95% CI Lower", "95% CI Upper"),
                   levels = c("Theoretical r_min", "Theoretical r_max", "95% CI Lower", "95% CI Upper"))
  )
  
  p <- ggplot(df, aes(x = r)) +
    geom_histogram(aes(y = ..density..), bins = 30,
                   fill = "lightblue", color = "white", alpha = 0.7) +
    geom_density(color = "darkblue", size = 1) +
    geom_vline(data = vlines,
               aes(xintercept = xintercept, color = label, linetype = label),
               size = 1) +
    scale_color_manual(name = "Legend", 
                       values = c("Theoretical r_min" = "red", 
                                  "Theoretical r_max" = "green", 
                                  "95% CI Lower" = "purple", 
                                  "95% CI Upper" = "purple")) +
    scale_linetype_manual(name = "Legend",
                          values = c("Theoretical r_min" = "dashed", 
                                     "Theoretical r_max" = "dashed", 
                                     "95% CI Lower" = "dotted", 
                                     "95% CI Upper" = "dotted")) +
    labs(title = main,
         x = "Pearson's r",
         y = "Density") +
    xlim(x_lower, x_upper) +
    theme_minimal()
  return(p)
}

# Function to plot a marginal distribution as a bar plot using ggplot2
plot_marginal <- function(counts, varname = "X") {
  df <- data.frame(Category = factor(0:(length(counts)-1)),
                   Frequency = counts)
  p <- ggplot(df, aes(x = Category, y = Frequency)) +
    geom_bar(stat = "identity", fill = "skyblue", color = "black", alpha = 0.8) +
    labs(title = paste("Marginal Distribution of", varname),
         x = paste(varname, "Categories"),
         y = "Frequency") +
    theme_minimal()
  return(p)
}

# -----------------------------------------------------------------------------
# 3. Simulation study: Explore r_min, r_max, and the simulated distribution as a function 
#    of marginal distributions and sample_size.
#
# We use two scenarios with 5 categories each for X and Y:
#   - "Extreme": X has 70% mass on the first category; Y has very low mass on the first 4 categories.
#   - "Uniform": Both X and Y are uniform.
#
# Also, we vary the sample_size.
scenarios <- list(
  Extreme = list(
    marginalX = c(0.7, rep(0.3/4, 4)),
    marginalY = c(rep(0.02, 4), 1 - 0.02*4)
  ),
  Uniform = list(
    marginalX = rep(1/5, 5),
    marginalY = rep(1/5, 5)
  )
)
sample_sizes <- c(500, 1000, 5000, 10000)

# Storage for summary statistics, simulated r values, and glued pairs.
summary_df <- data.frame()
sim_r_df <- data.frame()
glued_pairs <- list()  # nested list: glued_pairs[[scenario]][[sample_size]] = list(max = , min = )

# Loop over scenarios and sample_sizes.
for (sc in names(scenarios)) {
  pX <- scenarios[[sc]]$marginalX
  pY <- scenarios[[sc]]$marginalY
  glued_pairs[[sc]] <- list()
  
  for (s in sample_sizes) {
    # Compute theoretical bounds.
    r_min_val <- min_corr_sorted(pX, pY, sample_size = s)
    r_max_val <- max_corr_sorted(pX, pY, sample_size = s)
    
    # Simulate permutation distribution.
    r_sim <- simulate_random_corr(pX, pY, nsim = 1000, sample_size = s)
    med_r <- median(r_sim)
    lower_ci <- quantile(r_sim, 0.025)
    upper_ci <- quantile(r_sim, 0.975)
    
    # Save summary statistics.
    summary_df <- rbind(summary_df, data.frame(
      scenario = sc,
      sample_size = s,
      r_min = r_min_val,
      r_max = r_max_val,
      median_r = med_r,
      lower_ci = lower_ci,
      upper_ci = upper_ci
    ))
    
    # Save simulated r values.
    sim_r_df <- rbind(sim_r_df, data.frame(
      scenario = sc,
      sample_size = s,
      r = r_sim
    ))
    
    # Save "glued pairs" (joint distributions) for r_max and r_min.
    # Create counts from probabilities, ensuring they sum to s.
    x_levels <- 0:(length(pX)-1)
    y_levels <- 0:(length(pY)-1)
    
    # Adjust counts to sum exactly to s.
    countsX <- round(pX * s)
    diffX <- s - sum(countsX)
    if(diffX != 0) {
      i_max <- which.max(countsX)
      countsX[i_max] <- countsX[i_max] + diffX
    }
    countsY <- round(pY * s)
    diffY <- s - sum(countsY)
    if(diffY != 0) {
      i_max <- which.max(countsY)
      countsY[i_max] <- countsY[i_max] + diffY
    }
    
    x_vec <- rep(x_levels, times = countsX)
    y_vec <- rep(y_levels, times = countsY)
    
    max_pairs <- data.frame(X = sort(x_vec, decreasing = TRUE),
                            Y = sort(y_vec, decreasing = TRUE))
    min_pairs <- data.frame(X = sort(x_vec, decreasing = TRUE),
                            Y = sort(y_vec, decreasing = FALSE))
    
    glued_pairs[[sc]][[as.character(s)]] <- list(max = max_pairs, min = min_pairs)
  }
}

# Print the simulation summary.
print(summary_df)

# Optionally, arrange and display all the permutation distribution plots.
plots <- list()
for (i in 1:nrow(summary_df)) {
  row <- summary_df[i, ]
  title_str <- paste("Scenario:", row$scenario, "Sample Size:", row$sample_size)
  r_vals <- sim_r_df %>% filter(scenario == row$scenario, sample_size == row$sample_size) %>% pull(r)
  ci_bounds <- c(row$lower_ci, row$upper_ci)
  p_emp <- plot_empirical_distribution(r_vals, row$r_min, row$r_max, ci_bounds,
                                       main = paste("Permutation Distribution of r (", title_str, ")", sep = " "))
  plots[[i]] <- p_emp
}
grid.arrange(grobs = plots, ncol = 2)

# -----------------------------------------------------------------------------
# Also, display the marginal distributions for one instance as an example.
# (We use the first combination from our simulation.)
example_nX <- length(scenarios[["Extreme"]]$marginalX)  # 5 categories
example_nY <- length(scenarios[["Extreme"]]$marginalY)  # 5 categories
example_pX <- scenarios[["Extreme"]]$marginalX
example_pY <- scenarios[["Extreme"]]$marginalY
# For display, we use one of the sample sizes (e.g., the smallest one)
example_sample_size <- sample_sizes[1]
example_countsX <- round(example_pX * example_sample_size)
diffX <- example_sample_size - sum(example_countsX)
if(diffX != 0) {
  i_max <- which.max(example_countsX)
  example_countsX[i_max] <- example_countsX[i_max] + diffX
}
example_countsY <- round(example_pY * example_sample_size)
diffY <- example_sample_size - sum(example_countsY)
if(diffY != 0) {
  i_max <- which.max(example_countsY)
  example_countsY[i_max] <- example_countsY[i_max] + diffY
}

cat("Marginal Distribution for X (counts):\n")
print(data.frame(Category = 0:(length(example_countsX)-1),
                 Frequency = example_countsX))
cat("\nMarginal Distribution for Y (counts):\n")
print(data.frame(Category = 0:(length(example_countsY)-1),
                 Frequency = example_countsY))

pX_plot <- plot_marginal(example_countsX, varname = "X")
pY_plot <- plot_marginal(example_countsY, varname = "Y")
grid.arrange(pX_plot, pY_plot, ncol = 2)

# -----------------------------------------------------------------------------
# Optionally, inspect the glued pairs for one example.
# For instance, for the "Extreme" scenario at sample_size = 500.
example_glued <- glued_pairs[["Extreme"]][["500"]]
cat("\nGlued pairs for maximum correlation (Extreme, sample_size = 500):\n")
print(head(example_glued$max, 10))
cat("\nGlued pairs for minimum correlation (Extreme, sample_size = 500):\n")
print(head(example_glued$min, 10))
```

### Explanation

* **Counts Adjustment:**  
    When computing counts from the marginal probabilities (using round(p * s)), we adjust the counts so that they sum exactly to the sample size `s`. This prevents the mismatch error (e.g. 502 vs. 500 rows).
    
* **Glued Pairs:**  
    The “glued pairs” for r_max are created by sorting `x_vec` in decreasing order and `y_vec` in decreasing order (comonotonic coupling). For r_min, we sort `x_vec` in decreasing order and `y_vec` in increasing order (anti-comonotonic coupling).
    
* **Plotting and Summary:**  
    The script combines simulation summaries, plots the permutation distribution for each scenario/sample size, and also shows example marginal distributions.
    

This complete script should now run without error and include all the elements you requested.

* * *

**You:**

This is excellent.  Perfect.  Thank you.  Next I want to explore cases and examples of when marginalX, marginalY, and sample_size that give rise to joint probabilities (e.g. cross-tabs consistent with the marginals) **in which**: 
r_min_val is very close to lower_ci and also;   upper_ci is very close to r_max_val 
Also, include additional marginal distributions in your scenarios list.

* * *

**ChatGPT:**

my best guess is that the following complete code extends our previous simulation study by adding extra scenarios (including “Bimodal” and “HighlySkewed” cases) and by computing the differences between the theoretical bounds (r_min and r_max) and the simulated 95% CI endpoints (lower_ci and upper_ci). This lets you identify cases where the empirical extremes are very close to the theoretical bounds. The code also prints and plots the summary and marginal distributions.

```r
# Load required libraries
library(ggplot2)
library(gridExtra)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. Functions for theoretical correlations and simulation

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
  # If marginals sum to ~1, treat as probabilities and generate counts.
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
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  pX <- countsX / sum(countsX)
  pY <- countsY / sum(countsY)
  muX <- sum(x_levels * pX)
  muY <- sum(y_levels * pY)
  sigmaX <- sqrt(sum(x_levels^2 * pX) - muX^2)
  sigmaY <- sqrt(sum(y_levels^2 * pY) - muY^2)
  
  # Compute the joint distribution using cumulative probabilities (Fréchet–Hoeffding upper bound)
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
  
  E_XY <- sum(outer(x_levels, y_levels, FUN = "*") * joint)
  r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
  return(r_max)
}

# Function to compute the minimum correlation (anti-comonotonic pairing)
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
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # For r_min, pair highest X with lowest Y.
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  r_min <- cor(x_sorted, y_sorted)
  return(r_min)
}

# Function to simulate the permutation (randomization) distribution of Pearson's r
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
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  r_vals <- numeric(nsim)
  for (i in 1:nsim) {
    x_perm <- sample(x_vec, size = length(x_vec), replace = FALSE)
    y_perm <- sample(y_vec, size = length(y_vec), replace = FALSE)
    r_vals[i] <- cor(x_perm, y_perm)
  }
  return(r_vals)
}

# -----------------------------------------------------------------------------
# 2. Define ggplot functions for displaying results

# Function to plot the empirical distribution of Pearson's r with vertical lines and legend
plot_empirical_distribution <- function(r_vals, r_min, r_max, ci_bounds,
                                          main = "Empirical Distribution of Pearson's r") {
  df <- data.frame(r = r_vals)
  
  # Set x-axis limits to include r_min and r_max
  x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
  x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05
  
  vlines <- data.frame(
    xintercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
    label = factor(c("Theoretical r_min", "Theoretical r_max", "95% CI Lower", "95% CI Upper"),
                   levels = c("Theoretical r_min", "Theoretical r_max", "95% CI Lower", "95% CI Upper"))
  )
  
  p <- ggplot(df, aes(x = r)) +
    geom_histogram(aes(y = ..density..), bins = 30,
                   fill = "lightblue", color = "white", alpha = 0.7) +
    geom_density(color = "darkblue", size = 1) +
    geom_vline(data = vlines,
               aes(xintercept = xintercept, color = label, linetype = label),
               size = 1) +
    scale_color_manual(name = "Legend", 
                       values = c("Theoretical r_min" = "red", 
                                  "Theoretical r_max" = "green", 
                                  "95% CI Lower" = "purple", 
                                  "95% CI Upper" = "purple")) +
    scale_linetype_manual(name = "Legend",
                          values = c("Theoretical r_min" = "dashed", 
                                     "Theoretical r_max" = "dashed", 
                                     "95% CI Lower" = "dotted", 
                                     "95% CI Upper" = "dotted")) +
    labs(title = main,
         x = "Pearson's r",
         y = "Density") +
    xlim(x_lower, x_upper) +
    theme_minimal()
  return(p)
}

# Function to plot a marginal distribution as a bar plot using ggplot2
plot_marginal <- function(counts, varname = "X") {
  df <- data.frame(Category = factor(0:(length(counts)-1)),
                   Frequency = counts)
  p <- ggplot(df, aes(x = Category, y = Frequency)) +
    geom_bar(stat = "identity", fill = "skyblue", color = "black", alpha = 0.8) +
    labs(title = paste("Marginal Distribution of", varname),
         x = paste(varname, "Categories"),
         y = "Frequency") +
    theme_minimal()
  return(p)
}

# -----------------------------------------------------------------------------
# 3. Simulation study: Explore cases where the simulated extremes are nearly the theoretical bounds.
#
# We now include additional scenarios in the scenarios list.
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
sample_sizes <- c(500, 1000, 5000, 10000)

# Storage for summary statistics, simulated r values, and glued pairs.
summary_df <- data.frame()
sim_r_df <- data.frame()
glued_pairs <- list()  # nested list: glued_pairs[[scenario]][[sample_size]] = list(max = , min = )

# Loop over scenarios and sample_sizes.
for (sc in names(scenarios)) {
  pX <- scenarios[[sc]]$marginalX
  pY <- scenarios[[sc]]$marginalY
  glued_pairs[[sc]] <- list()
  
  for (s in sample_sizes) {
    # Compute theoretical bounds.
    r_min_val <- min_corr_sorted(pX, pY, sample_size = s)
    r_max_val <- max_corr_sorted(pX, pY, sample_size = s)
    
    # Simulate permutation distribution.
    r_sim <- simulate_random_corr(pX, pY, nsim = 1000, sample_size = s)
    med_r <- median(r_sim)
    lower_ci <- quantile(r_sim, 0.025)
    upper_ci <- quantile(r_sim, 0.975)
    
    # Save summary statistics (also compute differences).
    diff_lower <- abs(r_min_val - lower_ci)
    diff_upper <- abs(r_max_val - upper_ci)
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
    
    # Save simulated r values.
    sim_r_df <- rbind(sim_r_df, data.frame(
      scenario = sc,
      sample_size = s,
      r = r_sim
    ))
    
    # Save "glued pairs" (joint distributions) for r_max and r_min.
    # Create counts from probabilities, ensuring they sum exactly to s.
    x_levels <- 0:(length(pX)-1)
    y_levels <- 0:(length(pY)-1)
    
    countsX <- round(pX * s)
    diffX <- s - sum(countsX)
    if(diffX != 0) {
      i_max <- which.max(countsX)
      countsX[i_max] <- countsX[i_max] + diffX
    }
    countsY <- round(pY * s)
    diffY <- s - sum(countsY)
    if(diffY != 0) {
      i_max <- which.max(countsY)
      countsY[i_max] <- countsY[i_max] + diffY
    }
    
    x_vec <- rep(x_levels, times = countsX)
    y_vec <- rep(y_levels, times = countsY)
    
    max_pairs <- data.frame(X = sort(x_vec, decreasing = TRUE),
                            Y = sort(y_vec, decreasing = TRUE))
    min_pairs <- data.frame(X = sort(x_vec, decreasing = TRUE),
                            Y = sort(y_vec, decreasing = FALSE))
    
    glued_pairs[[sc]][[as.character(s)]] <- list(max = max_pairs, min = min_pairs)
  }
}

# Print the simulation summary.
cat("Simulation Summary:\n")
print(summary_df)

# Identify cases where the theoretical lower bound is nearly equal to the 2.5% quantile 
# and the upper bound is nearly equal to the 97.5% quantile.
threshold <- 0.01  # tolerance for differences
cat("\nCases where |r_min - lower_ci| < ", threshold, " and |r_max - upper_ci| < ", threshold, ":\n", sep = "")
print(subset(summary_df, diff_lower < threshold & diff_upper < threshold))

# Optionally, arrange and display all the permutation distribution plots.
plots <- list()
for (i in 1:nrow(summary_df)) {
  row <- summary_df[i, ]
  title_str <- paste("Scenario:", row$scenario, "Sample Size:", row$sample_size)
  r_vals <- sim_r_df %>% filter(scenario == row$scenario, sample_size == row$sample_size) %>% pull(r)
  ci_bounds <- c(row$lower_ci, row$upper_ci)
  p_emp <- plot_empirical_distribution(r_vals, row$r_min, row$r_max, ci_bounds,
                                       main = paste("Permutation Distribution of r (", title_str, ")", sep = " "))
  plots[[i]] <- p_emp
}
grid.arrange(grobs = plots, ncol = 2)

# -----------------------------------------------------------------------------
# Also, display the marginal distributions for one instance as an example.
# (We use the "Extreme" scenario at the smallest sample_size.)
example_sample_size <- sample_sizes[1]
example_pX <- scenarios[["Extreme"]]$marginalX
example_pY <- scenarios[["Extreme"]]$marginalY
example_countsX <- round(example_pX * example_sample_size)
diffX <- example_sample_size - sum(example_countsX)
if(diffX != 0) {
  i_max <- which.max(example_countsX)
  example_countsX[i_max] <- example_countsX[i_max] + diffX
}
example_countsY <- round(example_pY * example_sample_size)
diffY <- example_sample_size - sum(example_countsY)
if(diffY != 0) {
  i_max <- which.max(example_countsY)
  example_countsY[i_max] <- example_countsY[i_max] + diffY
}

cat("\nMarginal Distribution for X (counts, Extreme scenario):\n")
print(data.frame(Category = 0:(length(example_countsX)-1),
                 Frequency = example_countsX))
cat("\nMarginal Distribution for Y (counts, Extreme scenario):\n")
print(data.frame(Category = 0:(length(example_countsY)-1),
                 Frequency = example_countsY))

pX_plot <- plot_marginal(example_countsX, varname = "X")
pY_plot <- plot_marginal(example_countsY, varname = "Y")
grid.arrange(pX_plot, pY_plot, ncol = 2)

# -----------------------------------------------------------------------------
# Optionally, inspect the glued pairs for one example.
# For instance, for the "Extreme" scenario at sample_size = 500.
example_glued <- glued_pairs[["Extreme"]][["500"]]
cat("\nGlued pairs for maximum correlation (Extreme, sample_size = 500):\n")
print(head(example_glued$max, 10))
cat("\nGlued pairs for minimum correlation (Extreme, sample_size = 500):\n")
print(head(example_glued$min, 10))
```

### Explanation

1. **Additional Scenarios:**  
    The `scenarios` list now includes four cases: "Extreme," "Uniform," "Bimodal," and "HighlySkewed."
    
2. **Simulation Loop:**  
    For each scenario and each sample size, the code computes theoretical bounds (`r_min_val` and `r_max_val`), simulates the permutation distribution (with 1000 replications), and computes summary statistics (including the median and the 95% CI). It also calculates the absolute differences between `r_min` and `lower_ci` (and `r_max` and `upper_ci`).
    
3. **Glued Pairs:**  
    The code constructs the “glued pairs” (joint distributions) for both maximum and minimum coupling. Rounding adjustments ensure the counts sum exactly to the sample size.
    
4. **Summary and Filtering:**  
    The summary is printed and then filtered to show cases where the differences are within a small threshold (here 0.01), meaning that the simulated lower bound is nearly equal to the theoretical r_min and similarly for r_max.
    
5. **Plots and Marginal Distributions:**  
    Permutation distribution plots are arranged using `grid.arrange`. The marginal distributions for one example are also printed as tables and displayed as bar plots.
    

This complete script should help you explore the cases where the empirical simulated extremes of Pearson’s r are very close to the theoretical bounds, and it includes additional marginal distributions in the scenarios list.

* * *

**You:**

Thank you.  Next I have an abstract question for you: Which marginals produce the largest range of Pearson's $r$ for the resulting r_val or each simulated empirical distribution?   To answer this, I want you to scan over 'reasonable' values of  marginalX, marginalY, and sample_size that give rise to joint probabilities (e.g. cross-tabs consistent with the marginals) **in which** the resulting range is large.

* * *

**ChatGPT:**

my best guess is that after scanning over a wide range of “reasonable” marginal distributions and sample sizes, the largest range of Pearson’s $r$ (i.e. the difference between the theoretical maximum $r_{\max}$ and minimum $r_{\min}$) is typically achieved when both $X$ and $Y$ have nearly uniform marginal distributions.

**Step-by-step reasoning:**

1. **Variance Matters:**  
    Pearson’s $r$ depends on the covariance relative to the product of the standard deviations. Uniform marginals maximize the variance of an ordinal variable. When the variance is high, the potential spread in $r$ (via both comonotonic and countermonotonic arrangements) is maximized.
    
2. **Theoretical Extremes:**  
    The maximum $r$ is achieved by perfectly aligning the highest values of $X$ with the highest values of $Y$ (comonotonic coupling), while the minimum $r$ is achieved by pairing the highest values of $X$ with the lowest values of $Y$ (anti-comonotonic coupling). For uniform marginals, these extreme pairings can reach values very close to +1 and -1 (subject to the numeric scoring of categories), yielding the largest possible range.
    
3. **Effect of Skewness:**  
    In contrast, when the marginals are highly skewed (for example, when most of the mass is concentrated in one or two categories), the variance is reduced. A lower variance limits the attainable covariance, and both $r_{\max}$ and $r_{\min}$ become more constrained, thus narrowing the range.
    
4. **Number of Categories:**  
    Increasing the number of categories can also enlarge the potential range, provided that the marginals remain balanced. For a fixed number of categories, uniform distributions typically yield the widest range. If the number of categories increases while keeping the marginals uniform, the effect on the range is often more pronounced.
    
5. **Sample Size:**  
    In theory, the theoretical bounds (the Fréchet–Hoeffding bounds) are determined solely by the marginal distributions. However, in simulations, a larger sample size can help you estimate these bounds more precisely (since rounding errors in count generation are minimized). Still, the _potential_ range is driven by the shape of the marginals rather than sample size.
    

**Conclusion:**  
To maximize the range of possible Pearson’s $r$ (i.e. to have a large difference between the simulated lower 2.5% quantile and the simulated upper 97.5% quantile), you should choose marginal distributions for both $X$ and $Y$ that are nearly uniform across their categories. In practice, this means that if you want a wide range of $r$ values in your simulated empirical distributions, use balanced marginals (and consider increasing the number of categories as well), rather than highly skewed or extreme distributions.

Thus, the answer to your abstract question is: **Uniform (or nearly uniform) marginals produce the largest range of Pearson's $r$ for the resulting simulated empirical distributions.**

* * *

**You:**

Show me using simulations in R:

* * *

**ChatGPT:**

my best guess is that we can scan over several candidate marginal distributions (and hold the number of categories and sample size fixed) and then compute both the theoretical range (r_max – r_min) and the empirical range (max(simulated r) – min(simulated r)). In our simulation study the "Uniform" (or nearly uniform) marginals tend to yield the widest range. Here’s an R script that does this:

```r
# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# -------------------------------
# 1. Define functions (same as before)

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
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
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  pX <- countsX / sum(countsX)
  pY <- countsY / sum(countsY)
  muX <- sum(x_levels * pX)
  muY <- sum(y_levels * pY)
  sigmaX <- sqrt(sum(x_levels^2 * pX) - muX^2)
  sigmaY <- sqrt(sum(y_levels^2 * pY) - muY^2)
  
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
      cumX_prev <- currX; i <- i + 1
    } else if (currX > currY) {
      cumY_prev <- currY; j <- j + 1
    } else {
      cumX_prev <- currX; cumY_prev <- currY; i <- i + 1; j <- j + 1
    }
  }
  
  E_XY <- sum(outer(x_levels, y_levels, FUN = "*") * joint)
  r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
  return(r_max)
}

# Function to compute the minimum correlation (anti-comonotonic pairing)
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
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  # For r_min, pair highest X with lowest Y.
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  r_min <- cor(x_sorted, y_sorted)
  return(r_min)
}

# Function to simulate the permutation distribution of Pearson's r
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
    if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
  }
  
  x_levels <- 0:(length(countsX) - 1)
  y_levels <- 0:(length(countsY) - 1)
  
  x_vec <- rep(x_levels, times = countsX)
  y_vec <- rep(y_levels, times = countsY)
  
  r_vals <- numeric(nsim)
  for (i in 1:nsim) {
    x_perm <- sample(x_vec, size = length(x_vec), replace = FALSE)
    y_perm <- sample(y_vec, size = length(y_vec), replace = FALSE)
    r_vals[i] <- cor(x_perm, y_perm)
  }
  return(r_vals)
}

# -------------------------------
# 2. Define candidate marginal distributions for X and Y.
# We assume 5 categories for both. We'll consider several scenarios.
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

# -------------------------------
# 3. Scan over scenarios (with fixed sample_size and nsim) to compute the range.
sample_size <- 10000
nsim <- 1000

results <- data.frame(Scenario = character(), 
                      r_min = numeric(),
                      r_max = numeric(),
                      theo_range = numeric(),
                      emp_range = numeric(),
                      stringsAsFactors = FALSE)

set.seed(123)  # for reproducibility
for (sc in names(scenarios)) {
  margX <- scenarios[[sc]]$marginalX
  margY <- scenarios[[sc]]$marginalY
  
  rmin <- min_corr_sorted(margX, margY, sample_size = sample_size)
  rmax <- max_corr_sorted(margX, margY, sample_size = sample_size)
  r_sim <- simulate_random_corr(margX, margY, nsim = nsim, sample_size = sample_size)
  
  theo_range <- rmax - rmin
  emp_range <- max(r_sim) - min(r_sim)
  
  results <- rbind(results, data.frame(Scenario = sc, 
                                       r_min = rmin,
                                       r_max = rmax,
                                       theo_range = theo_range,
                                       emp_range = emp_range))
}
print(results)

# -------------------------------
# 4. Plot the ranges by scenario.
results_long <- results %>%
  pivot_longer(cols = c("theo_range", "emp_range"), 
               names_to = "Type", 
               values_to = "Range")

ggplot(results_long, aes(x = Scenario, y = Range, fill = Type)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Range of Pearson's r by Marginal Scenario",
       y = "Range (r_max - r_min)", x = "Scenario") +
  scale_fill_manual(values = c("theo_range" = "darkblue", "emp_range" = "orange")) +
  theme_minimal()
```

### Explanation (Step-by-Step)

1. **Functions:**  
    We reuse our functions to compute the theoretical maximum and minimum Pearson’s $r$ (using optimal coupling), and to simulate the permutation distribution.
    
2. **Candidate Scenarios:**  
    We define a list of candidate marginal distributions for $X$ and $Y$. Each scenario is defined for 5 categories:
    
    * _Extreme_: Highly concentrated mass for $X$ and very low mass for $Y$ in early categories.
        
    * _Uniform_: Equal probabilities across all categories.
        
    * _Bimodal_: A bimodal shape.
        
    * _HighlySkewed_: Extremely skewed marginals.
        
    * _Moderate_: Moderately unbalanced but not extreme.
        
3. **Scanning and Calculation:**  
    For each scenario (with a fixed sample_size of 10,000 and 1000 simulations), we compute:
    
    * Theoretical $r_{\min}$ and $r_{\max}$, and thus the theoretical range.
        
    * The empirical range from the simulated distribution (the difference between the maximum and minimum simulated $r$). We store these values in a results data frame.
        
4. **Plotting:**  
    We then reshape the data to a long format and produce a grouped bar chart comparing the theoretical range and empirical range for each scenario.
    

**Expected Outcome:**  
You should see that the _Uniform_ (or nearly uniform) marginals produce the largest range of $r$ (with the theoretical range being close to 1 – (–1) = 2, adjusted for ordinal scoring), while more skewed distributions yield narrower ranges. This simulation demonstrates which marginal distributions give rise to the largest range of Pearson’s $r$.

This script answers the abstract question using simulations in R.

* * *

**You:**

can you please suggest a name for this research project?  So far I have been calling it "Cross-tabs to Correlation" but that is a terrible name.

* * *

**ChatGPT:**

my best guess is "Marginal Extremes: Defining the Limits of Association in Cross-Tabulated Data."

* * *

**You:**

Write a formal mathematical proposition asserting that, given the marginal distribution of two ordinal variables, $X$ and $Y$, the maximal value of the Spearman rank-correlation is obtained by the following joint distribution:  sorting $X$ from largest to smallest, separately sorting $Y$ from largest to smallest.  Provide a proof, using either Witt 1968 or Theorem 368 from the 'Inequalities' book:


* * *

**ChatGPT:**

my best guess is the following proposition and proof capture the result you want:

* * *

**Proposition**
---------------

Let $X$ and $Y$ be two **ordinal** random variables taking values in $\{1, 2, \dots, K\}$. Suppose their **marginal distributions** are fixed (i.e., the probability that $X = i$ and $Y = j$ is prescribed for each $i, j$, but the joint distribution is not). Among all joint distributions consistent with these marginals, the **maximum Spearman rank-correlation** of $X$ and $Y$ is attained by **sorting** both $X$ and $Y$ from largest to smallest and pairing them in that comonotonic fashion. Formally:

* Let $p_X(i) = \Pr(X = i)$ for $i = 1, \ldots, K$, and similarly $p_Y(j) = \Pr(Y = j)$ for $j = 1, \ldots, K$.
    
* Define the _rank_ of $X$ as $\mathrm{rank}(X)$, which maps each level $i$ to its ordinal rank. Likewise, define $\mathrm{rank}(Y)$.
    
* Among all joint distributions $\Pr(X = i, Y = j)$ compatible with the fixed marginals $\{p_X(i)\}$ and $\{p_Y(j)\}$, the **maximum** value of the Spearman correlation
    

$$\rho_S(X, Y) \;=\; \mathrm{corr}\bigl(\mathrm{rank}(X), \mathrm{rank}(Y)\bigr)$$

is attained precisely when the highest value(s) of $X$ are paired with the highest value(s) of $Y$, and so on, in descending order.

* * *

**Proof (Sketch)**
------------------

1. **Spearman Correlation as Pearson Correlation of Ranks.**  
    By definition, the Spearman rank-correlation $\rho_S(X, Y)$ is the Pearson correlation between the _rank_ variables $\mathrm{rank}(X)$ and $\mathrm{rank}(Y)$. Hence, we must show that the _expected product_ of the ranks, $\mathbb{E}[\mathrm{rank}(X)\,\mathrm{rank}(Y)]$, is maximized by pairing the largest ranks of $X$ with the largest ranks of $Y$.
    
2. **Reduction to a Sum of Products.**  
    Let the possible ranks of $X$ be $r_1 < r_2 < \cdots < r_K$, occurring with probabilities $p_X(1), p_X(2), \ldots, p_X(K)$. Similarly, let the ranks of $Y$ be $s_1 < s_2 < \cdots < s_K$, occurring with probabilities $p_Y(1), \ldots, p_Y(K)$. Any joint distribution consistent with these marginals must place a total probability mass of $p_X(i)$ on the event $X = i$ (across all possible $Y$ values), and similarly $p_Y(j)$ on $Y = j$.
    
3. **Applying a Rearrangement Inequality (Hardy–Littlewood–Pólya or Witt 1968).**  
    The classical **rearrangement inequality** states that for two real sequences $\{a_i\}$ and $\{b_j\}$, the sum of products $\sum_{i} a_i b_{\sigma(i)}$ is maximized precisely when the sequences are _similarly ordered_ (both in ascending or both in descending order). Hardy–Littlewood–Pólya’s _Inequalities_ (Theorem 368) formalizes this in an integral sense, and Witt (1968) shows an analogous result for discrete distributions and expected products.
    
4. **Constructing the Comonotonic Arrangement.**  
    To maximize $\mathbb{E}[\mathrm{rank}(X)\,\mathrm{rank}(Y)]$, we must pair the largest rank of $X$ with the largest rank of $Y$, the second-largest rank of $X$ with the second-largest rank of $Y$, etc., thus creating a “comonotonic” coupling. In practical terms, if you list all units (or probability mass elements) with $X$ in descending order of their ranks, and separately list all units for $Y$ in descending order of ranks, then “glue” them together index-by-index, this pairing attains the maximal expected product of ranks.
    
5. **Uniqueness and Ties.**  
    If some ranks appear with identical probabilities (ties), any consistent arrangement that preserves the descending order of “rank blocks” still attains the same maximum. Thus, the construction is unique up to permutations within tied categories.
    

Hence, by the rearrangement principle (or the results in Witt 1968), the joint distribution that **sorts $X$ and $Y$ from largest to smallest** achieves the **maximum Spearman rank-correlation**. This completes the proof.

* * *

**References**

* Witt, E. (1968). _On the arrangement of random variables to maximize or minimize the expectation of their product._ _Zeitschrift für Wahrscheinlichkeitstheorie und Verwandte Gebiete_, 10(3), 279–285.
    
* Hardy, G., Littlewood, J., & Pólya, G. (1952). _Inequalities_ (2nd ed.). Cambridge University Press. (See Theorem 368.)

* * *

**You:**

Please critique the above response, noting that more specific examples and details are required. Then based on the critique, output the full improved response.  note that $X$ and $Y$ may have different number of levels.

* * *

**ChatGPT:**

**Critique of the Above Response**

1. **Insufficient Treatment of Different Numbers of Levels:**  
    The statement and proof mention $X$ and $Y$ each having $K$ categories, but do not explicitly handle the case where $X$ and $Y$ have different numbers of levels (say $K_X \neq K_Y$). This is important because Spearman’s rank-correlation can still be defined for ordinal variables of differing cardinalities.
    
2. **Lack of a Concrete Example:**  
    The proof is correct in outline but would benefit from a small, concrete example (e.g., $X$ has three categories, $Y$ has four categories) to illustrate exactly how one pairs the highest ranks with the highest ranks (comonotonic arrangement) and obtains the maximum rank-correlation.
    
3. **Additional Detail on Rank Assignment:**  
    In practice, for ordinal variables with $K_X$ and $K_Y$ levels, we assign integer ranks $1,2,\dots,K_X$ to $X$ and $1,2,\dots,K_Y$ to $Y$. The proof would be more accessible if it explicitly described how these rank values are used in the rearrangement argument, particularly when $K_X \neq K_Y$.
    
4. **More Explicit Connection to Hardy–Littlewood–Pólya (HLP) or Witt 1968:**  
    Although the rearrangement inequality is referenced, a brief restatement of how the inequality applies to the discrete probability mass function would clarify how the “pairing” argument follows from the inequality. Citing or paraphrasing a theorem number is good, but the proof would be stronger if it spelled out exactly why the “descending vs. descending” arrangement (or “ascending vs. ascending”) maximizes the expected product of ranks.
    
5. **Clarification of Ties and Tied Ranks:**  
    Real data can have ties in the sense of multiple categories being assigned to the same numeric rank or large chunks of probability mass in the same category. A short statement about how ties do not affect the maximal comonotonic arrangement (beyond possibly introducing multiple equally optimal solutions) would be helpful.
    

* * *

**Improved Proposition and Proof**
----------------------------------

### **Proposition**

Let $X$ and $Y$ be two ordinal random variables taking values in

$$\{1, 2, \ldots, K_X\} \quad \text{and} \quad \{1, 2, \ldots, K_Y\},$$

respectively. Suppose the **marginal distributions** of $X$ and $Y$ are given (i.e., $\Pr(X = i)$ is fixed for each $i\in \{1,\dots,K_X\}$, and $\Pr(Y = j)$ is fixed for each $j\in \{1,\dots,K_Y\}$). Among all joint distributions of $(X, Y)$ consistent with these marginals, the **maximum value of Spearman’s rank-correlation** is attained by arranging the highest ranks of $X$ with the highest ranks of $Y$ (comonotonic ordering). Formally, if we define

$$\mathrm{rank}(X) = \begin{cases}  
1 & \text{if } X=1,\\  
2 & \text{if } X=2,\\  
\;\;\vdots\\  
K_X & \text{if } X=K_X,  
\end{cases}  
\quad  
\mathrm{rank}(Y) = \begin{cases}  
1 & \text{if } Y=1,\\  
2 & \text{if } Y=2,\\  
\;\;\vdots\\  
K_Y & \text{if } Y=K_Y,  
\end{cases}$$

then the joint distribution that **sorts** $X$ in descending order and $Y$ in descending order (matching largest with largest, next-largest with next-largest, etc.) maximizes

$$\rho_S(X, Y) \;=\; \mathrm{corr}\bigl(\mathrm{rank}(X), \mathrm{rank}(Y)\bigr).$$

### **Proof**

1. **Spearman’s Correlation as Pearson’s Correlation of Ranks**  
    By definition, Spearman’s rank-correlation $\rho_S(X,Y)$ is the Pearson correlation between $\mathrm{rank}(X)$ and $\mathrm{rank}(Y)$. That is,
    
    $$\rho_S(X, Y) \;=\; \frac{\mathrm{Cov}(\mathrm{rank}(X),\, \mathrm{rank}(Y))}{\sqrt{\mathrm{Var}(\mathrm{rank}(X))\;\mathrm{Var}(\mathrm{rank}(Y))}}.$$
    
    Maximizing $\rho_S$ is equivalent to maximizing the _expected product_ $\mathbb{E}[\mathrm{rank}(X)\,\mathrm{rank}(Y)]$ subject to the fixed marginal distributions of $\mathrm{rank}(X)$ and $\mathrm{rank}(Y)$.
    
2. **Rewriting the Expectation**  
    Let $r_1 < r_2 < \cdots < r_{K_X}$ be the distinct rank values for $X$ and $s_1 < s_2 < \cdots < s_{K_Y}$ be the distinct rank values for $Y$. (Here $r_i = i$ and $s_j = j$ in typical usage.) Any joint distribution $\Pr(X=i, Y=j)$ that respects $\Pr(X=i)$ and $\Pr(Y=j)$ must allocate probability mass in a 2D contingency table, but always summing to $p_X(i)$ in row $i$ and $p_Y(j)$ in column $j$. The quantity to be maximized is
    
    $$\sum_{i=1}^{K_X}\;\sum_{j=1}^{K_Y} \;r_i\,s_j \;\Pr(X = i, Y = j).$$
3. **Application of the Rearrangement Inequality**  
    The **rearrangement inequality** (Hardy–Littlewood–Pólya, Theorem 368) or the discrete analog by Witt (1968) tells us that for two finite sequences $\{a_1,\dots,a_m\}$ and $\{b_1,\dots,b_n\}$ (here, the sequences are effectively the rank values weighted by the probability masses), the sum of products $\sum a_i\,b_{\sigma(i)}$ is maximized precisely when both sequences are sorted in the same order (both ascending or both descending). In the probability setting, “sorting from largest to smallest” means that the highest ranks of $X$ should be paired with the highest ranks of $Y$. Concretely, if $X$ is in descending rank order $(K_X, K_X-1, \ldots)$ and $Y$ is also in descending rank order $(K_Y, K_Y-1, \ldots)$, then the product of ranks $\mathrm{rank}(X)\,\mathrm{rank}(Y)$ is as large as possible in expectation.
    
4. **Different Number of Levels**  
    If $K_X \neq K_Y$, the principle is the same. We let $\mathrm{rank}(X)\in\{1,\dots,K_X\}$ and $\mathrm{rank}(Y)\in\{1,\dots,K_Y\}$. The rearrangement inequality still applies: list all “mass points” of $X$ in descending order of rank, and list all “mass points” of $Y$ in descending order of rank. Pair them index-by-index so that the largest rank in $X$ is matched with the largest rank in $Y$. This arrangement yields the maximal expected product of ranks.
    
5. **Concrete Example (Different Levels)**
    
    * Suppose $K_X = 3$ and $K_Y = 4$. Then $\mathrm{rank}(X)$ takes values $\{1,2,3\}$ and $\mathrm{rank}(Y)$ takes $\{1,2,3,4\}$.
        
    * Let $\Pr(X=3) = 0.2$, $\Pr(X=2)=0.5$, $\Pr(X=1)=0.3$; and $\Pr(Y=4)=0.1$, $\Pr(Y=3)=0.4$, $\Pr(Y=2)=0.3$, $\Pr(Y=1)=0.2$.
        
    * To maximize $\mathbb{E}[\mathrm{rank}(X)\,\mathrm{rank}(Y)]$, we sort $X$ from 3 down to 1 and $Y$ from 4 down to 1. We then fill the contingency table so that the 0.2 probability mass of $X=3$ is paired as much as possible with the 0.1 mass of $Y=4$, the 0.4 mass of $Y=3$, and so on, always aligning the largest rank masses together.
        
    * This yields the comonotonic distribution that achieves the largest $\mathrm{rank}(X)\cdot \mathrm{rank}(Y)$ on average, and thus the maximum Spearman correlation.
        
6. **Conclusion**  
    By the rearrangement argument, the maximal Spearman rank-correlation is obtained via the comonotonic (descending-with-descending) joint distribution. Ties or repeated categories do not affect this principle, other than allowing multiple solutions that achieve the same maximum. Thus, the proposition is proved.
    

* * *

**References**

* Hardy, G., Littlewood, J., & Pólya, G. (1952). _Inequalities_ (2nd ed.). Cambridge University Press (Theorem 368).
    
* Witt, E. (1968). _On the arrangement of random variables to maximize or minimize the expectation of their product._ Zeitschrift für Wahrscheinlichkeitstheorie und Verwandte Gebiete, 10(3), 279–285.

* * *

**You:**

Thank you.  Please do the same for the minimum value of Speaman correlation

* * *

**ChatGPT:**

Below is a **formal proposition** and **proof** showing that, given the marginal distributions of two ordinal variables $X$ and $Y$, the **minimum** value of Spearman’s rank-correlation is obtained by **oppositely ordering** the ranks of $X$ and $Y$ (i.e., pairing the highest rank of $X$ with the lowest rank of $Y$, and so on).

* * *

**Proposition (Minimum Spearman Rank-Correlation)**
---------------------------------------------------

Let $X$ and $Y$ be two ordinal random variables taking values in

$$\{1, 2, \ldots, K_X\} \quad \text{and} \quad \{1, 2, \ldots, K_Y\},$$

respectively, with **fixed marginal distributions** $\Pr(X=i)$ and $\Pr(Y=j)$. Among all joint distributions of $(X, Y)$ consistent with these marginals, the **minimum** value of Spearman’s rank-correlation

$$\rho_S(X, Y) \;=\; \mathrm{corr}\bigl(\mathrm{rank}(X), \mathrm{rank}(Y)\bigr)$$

is achieved by **anti-comonotonic ordering**, that is, by pairing the **largest rank of $X$** with the **smallest rank of $Y$**, the second-largest rank of $X$ with the second-smallest rank of $Y$**, and so on.

Formally, if we define the rank functions as

$$\mathrm{rank}(X) = 1,2,\dots,K_X,  
\quad  
\mathrm{rank}(Y) = 1,2,\dots,K_Y,$$

then the joint distribution that **sorts $X$ in descending order** and **sorts $Y$ in ascending order** (or vice versa) attains the minimum Spearman correlation.

* * *

**Proof**
---------

1. **Spearman’s Correlation as Pearson’s Correlation of Ranks**  
    As in the maximal-correlation case, Spearman’s rank-correlation $\rho_S(X,Y)$ is the Pearson correlation between $\mathrm{rank}(X)$ and $\mathrm{rank}(Y)$. Thus, to **minimize** $\rho_S(X,Y)$, we equivalently seek to **minimize** the expected product $\mathbb{E}[\mathrm{rank}(X)\,\mathrm{rank}(Y)]$, subject to the fixed marginal distributions of $\mathrm{rank}(X)$ and $\mathrm{rank}(Y)$.
    
2. **Sum-of-Products Perspective**  
    Let $\mathrm{rank}(X)$ take values $r_1 < r_2 < \cdots < r_{K_X}$ with probabilities $p_X(1),\dots,p_X(K_X)$, and let $\mathrm{rank}(Y)$ take values $s_1 < s_2 < \cdots < s_{K_Y}$ with probabilities $p_Y(1),\dots,p_Y(K_Y)$. Any joint distribution $\Pr(X=i, Y=j)$ must sum to $p_X(i)$ over each row $i$ and $p_Y(j)$ over each column $j$. The expected product of ranks is
    

$$\sum_{i=1}^{K_X} \sum_{j=1}^{K_Y} r_i \, s_j \;\Pr(X=i, Y=j).$$

3. **Rearrangement Inequality (Hardy–Littlewood–Pólya or Witt 1968)**  
    To **minimize** the sum of products $ \sum r_i\,s_j \,\Pr(X=i, Y=j)$, we apply the rearrangement inequality in its _anti-comonotonic_ form. This states that, for sequences $\{a_i\}$ and $\{b_j\}$, the sum of products $\sum_i a_i\,b_{\sigma(i)}$ is minimized when the sequences are sorted in **opposite** order (largest with smallest, next-largest with next-smallest, etc.). Concretely, if you list the mass points of $X$ in descending order of ranks and the mass points of $Y$ in **ascending** order of ranks, and then pair them index by index, you get the minimal average product.
    
4. **Different Numbers of Levels**  
    The argument still holds if $K_X \neq K_Y$. Suppose $X$ has ranks in $\{1,2,\dots,K_X\}$ and $Y$ in $\{1,2,\dots,K_Y\}$. List out all of $X$’s probability mass in descending rank order, list out all of $Y$’s probability mass in ascending rank order, then “glue” them pairwise. This arrangement yields the smallest expected product of ranks, thereby minimizing Spearman’s correlation.
    
5. **Concrete Example (Different Levels)**
    
    * Suppose $K_X=3$ and $K_Y=4$. Then $\mathrm{rank}(X)\in\{1,2,3\}$ and $\mathrm{rank}(Y)\in\{1,2,3,4\}$.
        
    * Let $\Pr(X=3)=0.2, \Pr(X=2)=0.5, \Pr(X=1)=0.3$; and $\Pr(Y=4)=0.1, \Pr(Y=3)=0.4, \Pr(Y=2)=0.3, \Pr(Y=1)=0.2$.
        
    * To **minimize** $\mathbb{E}[\mathrm{rank}(X)\,\mathrm{rank}(Y)]$, we pair $X$ in descending order (3,2,1) with $Y$ in **ascending** order (1,2,3,4). Thus, the 0.2 probability mass of $X=3$ is paired as much as possible with the 0.2 mass of $Y=1$, etc.
        
    * This “largest-with-smallest” arrangement leads to the minimal product $\mathrm{rank}(X)\cdot \mathrm{rank}(Y)$ on average and hence the minimal Spearman correlation.
        
6. **Conclusion**  
    By the rearrangement principle, the minimal value of the expected product of ranks is achieved by an anti-comonotonic coupling: the largest rank of $X$ is matched with the smallest rank of $Y$, and so on. Consequently, **Spearman’s rank-correlation** is **minimized** under these same conditions. Ties or repeated categories (where multiple levels share the same rank or large probability mass) do not change the principle—only potentially yielding multiple equally optimal solutions.
    

* * *

**References**

* Hardy, G., Littlewood, J., & Pólya, G. (1952). _Inequalities_ (2nd ed.). Cambridge University Press. (See Theorem 368.)
    
* Witt, E. (1968). _On the arrangement of random variables to maximize or minimize the expectation of their product._ _Zeitschrift für Wahrscheinlichkeitstheorie und Verwandte Gebiete_, 10(3), 279–285.

* * *

**You:**

is this 'anti-comonotonic'?  What is the correct term?

* * *

**ChatGPT:**

my best guess is that the standard term is "countermonotonic" rather than "anti-comonotonic."

To elaborate: in the literature, a pair of random variables is said to be countermonotonic if one variable increases as the other decreases, which is precisely the property used in the proof to minimize the expected product of ranks (and hence minimize Spearman’s rank correlation). This coupling is known as the countermonotonic coupling.

* * *

**You:**

Thank you.  What if $X$ and $Y$ have different number of levels?  Is $r_{min}$  the negation of $r_{max}$?  What is the relationship between the min and max correlations in general?

* * *

**ChatGPT:**

my best guess is that when $X$ and $Y$ have different numbers of levels (or more generally different marginal distributions), the maximal and minimal Spearman correlations are not necessarily negatives of each other. Here’s a detailed explanation:

* * *

**1. Fréchet–Hoeffding Bounds and Optimal Coupling**

For any two random variables with given marginals, the maximum and minimum possible values of a correlation measure (or any functional that is monotone with respect to the joint distribution) are given by the Fréchet–Hoeffding bounds. In our context, the maximal Spearman correlation is achieved by the comonotonic (or countermonotonic for the minimum) coupling. That is, one arranges the outcomes of $X$ in descending order and does the same for $Y$ to achieve $r_{\max}$, and arranges $X$ in descending order but $Y$ in ascending order to achieve $r_{\min}$.

* * *

**2. When $$X$$ and $$Y$$ Have Identical (or Symmetric) Marginals**

If the marginal distributions of $X$ and $Y$ are identical (or symmetric in a certain sense) so that their probability mass functions (or cumulative distribution functions) mirror each other, then it can be shown that the maximum Spearman correlation is the negative of the minimum Spearman correlation; in other words,

$$r_{\min} = - r_{\max}.$$

This is because the symmetric structure allows the “best” and “worst” couplings to be exact opposites in terms of their effect on the covariance of the ranks.

* * *

**3. When $$X$$ and $$Y$$ Have Different Numbers of Levels or Differing Marginals**

When the numbers of levels (or the shapes of the marginal distributions) differ, the situation becomes asymmetric. In such cases, the optimal comonotonic coupling still maximizes the expected product of the ranks, and the countermonotonic coupling minimizes it, but their absolute values are not forced to be equal. That is, in general one only has

$$r_{\min} \le \rho_S(X,Y) \le r_{\max},$$

and there is no guarantee that

$$r_{\min} = -r_{\max}.$$

The reason is that the “spread” or variance of the rank variables for $X$ and $Y$ may differ, and the optimal alignment in the countermonotonic case may not symmetrically reflect the comonotonic case. For example, if $X$ has 3 levels and $Y$ has 5 levels, then even if you assign ranks $1, 2, 3$ to $X$ and $1, 2, 3, 4, 5$ to $Y$, the maximal pairing (largest with largest, etc.) and the minimal pairing (largest with smallest, etc.) will yield different absolute magnitudes because the “gaps” between rank values are different.

* * *

**4. Summary**

* **In General:**  
    The theoretical bounds $r_{\min}$ and $r_{\max}$ are determined by solving an optimal transportation problem over all joint distributions consistent with the given marginals. They satisfy
    
    $$r_{\min} \le \rho_S(X,Y) \le r_{\max}.$$
* **Under Symmetry:**  
    If the marginal distributions are symmetric (or identical up to a reversal), then one obtains
    
    $$r_{\min} = - r_{\max}.$$
* **Under Asymmetry (Different Levels or Differing Marginals):**  
    In general, for different numbers of levels or non-symmetric marginals, $r_{\min}$ is not simply the negation of $r_{\max}$. Their relationship depends on the specific shapes of the marginal distributions.
    

* * *

**Conclusion:**  
Thus, while the maximal Spearman rank-correlation is achieved by sorting $X$ and $Y$ in descending order and the minimal by sorting $X$ in descending order and $Y$ in ascending order, if $X$ and $Y$ have different numbers of levels or dissimilar marginal distributions, then in general

$$r_{\min} \neq -r_{\max}.$$

They are linked by the Fréchet–Hoeffding bounds, but symmetry is required for the equality $r_{\min} = -r_{\max}$ to hold.

* * *

This completes the explanation of the relationship between the minimum and maximum Spearman correlations when the variables have differing marginal distributions.

* * *

**You:**

Please critique the above response, noting that more specific proofs and details are required. Then based on the critique, output the full improved response.

* * *

**ChatGPT:**

**Critique of the Previous Response**

1. **Lack of Formal Structure:**  
    The previous answer provided a high‐level explanation using words like “in general” and “if symmetric,” but it did not state a precise theorem or proposition with all necessary assumptions. It did not clearly specify the domains (different numbers of levels) nor formalize the coupling argument.
    
2. **Insufficient Detail in Proof:**  
    The response mentions the rearrangement inequality and the Fréchet–Hoeffding bounds but does not show, with mathematical details, how these results imply that the maximum (or minimum) Spearman correlation is achieved by a comonotonic (or countermonotonic) coupling. In particular, it does not account for how the variances of the rank variables depend on the marginal distributions.
    
3. **Different Numbers of Levels Not Fully Addressed:**  
    While the answer asserts that when the marginals are symmetric one has $r_{\min} = -r_{\max}$ and that this fails in the asymmetric case, it does not provide a concrete demonstration or example. In the case $K_X \neq K_Y$ or when the marginals differ, a more detailed discussion is needed to explain why the negative symmetry fails.
    
4. **Need for Specific Examples:**  
    The explanation would be enhanced by a concrete example—for instance, when $X$ has three levels and $Y$ has four levels—to illustrate how the optimal (comonotonic) pairing and the countermonotonic pairing are constructed and how the resulting correlations differ.
    

* * *

**Improved Response**

Below is a formal proposition with a detailed proof for the general relationship between the maximum and minimum Spearman rank-correlation given fixed marginal distributions, including the case where $X$ and $Y$ have different numbers of levels.

* * *

### **Proposition**

Let $X$ and $Y$ be two ordinal random variables taking values in

$$\{1,2,\dots,K_X\} \quad \text{and} \quad \{1,2,\dots,K_Y\},$$

respectively, with fixed marginal probabilities $\Pr(X=i)=p_X(i)$ and $\Pr(Y=j)=p_Y(j)$. Define the rank functions by

$$\mathrm{rank}(X)=i \quad \text{for } X=i,\quad \mathrm{rank}(Y)=j \quad \text{for } Y=j.$$

Then:

1. The maximum possible Spearman rank-correlation,
    
    $$r_{\max} = \max_{\pi \in \Pi} \; \rho_S(X,Y),$$
    
    is achieved by the **comonotonic coupling** that pairs the highest values (largest ranks) of $X$ with the highest values of $Y$ (i.e. by sorting both in descending order).
    
2. The minimum possible Spearman rank-correlation,
    
    $$r_{\min} = \min_{\pi \in \Pi} \; \rho_S(X,Y),$$
    
    is achieved by the **countermonotonic coupling** that pairs the highest rank of $X$ with the lowest rank of $Y$ (i.e. sorting $X$ in descending order and $Y$ in ascending order).
    

Moreover, if the marginal distributions of $X$ and $Y$ are symmetric (or identical up to a reversal), then

$$r_{\min} = - r_{\max}.$$

In general, when $K_X \neq K_Y$ or the marginals differ, we have

$$r_{\min} < 0 < r_{\max} \quad \text{but typically } r_{\min} \neq -r_{\max}.$$

* * *

### **Proof**

1. **Spearman Correlation as Pearson Correlation of Ranks:**  
    By definition, the Spearman rank-correlation is the Pearson correlation of the rank variables:
    
    $$\rho_S(X,Y) = \frac{\mathbb{E}[(R_X - \mu_X)(R_Y - \mu_Y)]}{\sigma_{R_X}\,\sigma_{R_Y}},$$
    
    where $R_X=\mathrm{rank}(X)$ and $R_Y=\mathrm{rank}(Y)$ take values in $\{1,2,\dots,K_X\}$ and $\{1,2,\dots,K_Y\}$, respectively.
    
2. **Rearrangement Inequality:**  
    Let $a_1 \le a_2 \le \dots \le a_m$ and $b_1 \le b_2 \le \dots \le b_n$ be two sequences. The classical rearrangement inequality states that the sum
    
    $$S(\sigma) = \sum_{i} a_i\,b_{\sigma(i)}$$
    
    is maximized when $\sigma$ is the identity (i.e. when the sequences are similarly ordered) and minimized when the ordering is reversed. In our setting, the “elements” are the ranks weighted by the probability masses. That is, if we imagine “unfolding” the distribution into a list of $N$ values (where $N$ is large, corresponding to the sample size) for $X$ and for $Y$, then maximizing $\mathbb{E}[R_X R_Y]$ is achieved by pairing the largest available $R_X$ with the largest available $R_Y$. This yields the comonotonic coupling.
    
3. **Application to $r_{\max}$:**  
    Under the comonotonic coupling, denote the paired values by $(r_{(i)}, s_{(i)})$ for $i=1,\dots,N$, where $r_{(1)} \ge r_{(2)} \ge \dots \ge r_{(N)}$ and similarly $s_{(1)} \ge s_{(2)} \ge \dots \ge s_{(N)}$. By the rearrangement inequality, this pairing maximizes the sum
    
    $$\sum_{i=1}^{N} r_{(i)} s_{(i)},$$
    
    and hence maximizes $\mathbb{E}[R_X R_Y]$. Since the means and variances of $R_X$ and $R_Y$ are fixed by the marginals, the Pearson correlation (and thus Spearman’s correlation) is maximized.
    
4. **Application to $r_{\min}$:**  
    Similarly, to minimize $\mathbb{E}[R_X R_Y]$, one should pair the largest $R_X$ with the smallest $R_Y$, the second-largest $R_X$ with the second-smallest $R_Y$, etc. This is the countermonotonic (or anti-monotonic) coupling. The rearrangement inequality guarantees that this pairing minimizes the sum, and hence minimizes Spearman’s correlation.
    
5. **Symmetry and the Relationship Between $r_{\min}$ and $r_{\max}$:**  
    Suppose that the marginal distributions of $X$ and $Y$ are identical (or symmetric about a central value). Then the mean and variance of $R_X$ and $R_Y$ are the same. In this case, a standard argument (or symmetry of the rearrangement inequality) shows that the maximum achievable Pearson correlation is the negative of the minimum achievable Pearson correlation; hence, $r_{\min} = -r_{\max}$.  
    However, if $K_X \neq K_Y$ or the distributions $p_X$ and $p_Y$ are not symmetric, then the variances of $R_X$ and $R_Y$ will differ. Consequently, while the comonotonic coupling still maximizes $\mathbb{E}[R_X R_Y]$ and the countermonotonic coupling minimizes it, the scaling by the (different) standard deviations means that in general
    
    $$r_{\min} \neq -r_{\max}.$$
    
    That is, the theoretical Fréchet–Hoeffding bounds for Spearman’s correlation will not be symmetric about zero unless the marginals are symmetric.
    
6. **Conclusion:**  
    Therefore, the maximum Spearman rank-correlation is attained by sorting $X$ and $Y$ in the same order (comonotonic coupling), while the minimum is attained by sorting one in descending order and the other in ascending order (countermonotonic coupling). When the marginal distributions are identical (or symmetric), these extremes are exact negatives of each other; otherwise, they need not be.
    

* * *

**References**

* Hardy, G., Littlewood, J., & Pólya, G. (1952). _Inequalities_ (2nd ed.). Cambridge University Press. (See Theorem 368.)
    
* Witt, E. (1968). _On the arrangement of random variables to maximize or minimize the expectation of their product._ Zeitschrift für Wahrscheinlichkeitstheorie und Verwandte Gebiete, 10(3), 279–285.
    

* * *

This completes the formal improved response addressing the relationship between $r_{\min}$ and $r_{\max}$ when $X$ and $Y$ may have different numbers of levels, including a detailed proof and discussion.

* * *

**You:**

What do you mean 'marginals are symmetric'?  What is $\pi$ in items 1 and 2 (max and min, respectively)?

* * *

**ChatGPT:**

my best guess is:

1. **"Marginals are symmetric"** means that the probability mass function of an ordinal variable is symmetric about a central value. For instance, if $X$ takes values $\{1, 2, \dots, K_X\}$, then $X$ is said to have a symmetric marginal if
    

$$\Pr(X = i) = \Pr\Bigl(X = K_X+1-i\Bigr)$$

for each $i = 1, \dots, K_X$. In other words, the distribution looks the same when reflected around the midpoint. This symmetry ensures that the spread (variance) of the ranks is balanced in a way that the optimal (comonotonic) and countermonotonic couplings yield correlations that are negatives of each other.

2. **The notation $\pi$ in items 1 and 2** refers to an element of the set $\Pi$ of all joint distributions (or couplings) of $X$ and $Y$ that are consistent with the given marginal distributions. In our statements:
    
    * In item 1 (maximization), we write:
        
        $$r_{\max} = \max_{\pi \in \Pi} \; \rho_S(X,Y),$$
        
        which means that $r_{\max}$ is the maximum Spearman rank-correlation achievable by any joint distribution $\pi$ whose marginals are $\Pr(X=i)$ and $\Pr(Y=j)$.
        
    * In item 2 (minimization), similarly,
        
        $$r_{\min} = \min_{\pi \in \Pi} \; \rho_S(X,Y),$$
        
        where $\pi$ again denotes a valid joint distribution (coupling) of $X$ and $Y$.
        

Thus, $\pi$ is a variable ranging over the set of all couplings with the fixed marginals, and the maximum (or minimum) is taken over that set.

* * *

**You:**

You need to be more explicit about $\pi$ and how it relates to the arguments of $\rho_S$.  Also, what if anything does this have to do with Frechet bounds? 

* * *

**ChatGPT:**

my best guess is that we can clarify as follows:

* * *

**Explanation**

Let $\mathcal{P}$ (or $\Pi$) denote the set of all joint probability distributions $\pi$ on the product space

$$\{1,2,\dots,K_X\}\times\{1,2,\dots,K_Y\}$$

that have the prescribed marginals:

$$\pi_X(i) = \sum_{j=1}^{K_Y}\pi(i,j)= p_X(i) \quad\text{for } i=1,\dots,K_X,$$ $$\pi_Y(j) = \sum_{i=1}^{K_X}\pi(i,j)= p_Y(j) \quad\text{for } j=1,\dots,K_Y.$$

For any given $\pi \in \Pi$, we can compute the Spearman rank-correlation

$$\rho_S^\pi(X,Y) = \mathrm{corr}(R_X, R_Y)$$

where $R_X$ and $R_Y$ denote the rank variables corresponding to $X$ and $Y$ (typically $R_X = i$ when $X=i$, and similarly for $Y$). In other words, $\rho_S^\pi(X,Y)$ is a function of the joint distribution $\pi$ (via the joint moments of the ranks), while its marginal moments are fixed by $p_X$ and $p_Y$.

The maximum and minimum Spearman rank correlations are then defined by optimizing over the set $\Pi$:

$$r_{\max} = \max_{\pi \in \Pi} \rho_S^\pi(X,Y),\quad r_{\min} = \min_{\pi \in \Pi} \rho_S^\pi(X,Y).$$

**Relation to Fréchet Bounds**

The Fréchet bounds characterize the extreme possible joint cumulative distribution functions (cdfs) that are consistent with given marginal cdfs. In our discrete setting, these bounds correspond to the extreme couplings in $\Pi$:

* The **upper Fréchet bound** (comonotonic coupling) is the joint distribution where, roughly speaking, the highest outcomes of $X$ are paired with the highest outcomes of $Y$. This coupling maximizes the expected product of the ranks (and hence the Pearson correlation between the ranks) and, therefore, gives the maximum Spearman rank-correlation $r_{\max}$.
    
* The **lower Fréchet bound** (countermonotonic coupling) is the joint distribution where the highest outcomes of $X$ are paired with the lowest outcomes of $Y$ (and vice versa). This minimizes the expected product of the ranks and gives the minimum Spearman rank-correlation $r_{\min}$.
    

Thus, the extreme values $r_{\max}$ and $r_{\min}$ arise from the extreme (Fréchet) couplings in $\Pi$. Note that when $X$ and $Y$ have different numbers of levels or non-symmetric marginals, the Fréchet bounds are not symmetric; that is, in general $r_{\min} \neq -r_{\max}$.

* * *

**Summary**

* $\pi \in \Pi$ denotes a joint probability distribution on $\{1,\dots,K_X\}\times\{1,\dots,K_Y\}$ with the fixed marginals $p_X$ and $p_Y$.
    
* $\rho_S^\pi(X,Y)$ is the Spearman rank-correlation computed from the joint distribution $\pi$.
    
* The extreme values $r_{\max}$ and $r_{\min}$ are obtained by optimizing $\rho_S^\pi(X,Y)$ over all $\pi$ in $\Pi$; these extremes correspond to the comonotonic (upper Fréchet bound) and countermonotonic (lower Fréchet bound) couplings, respectively.
    
* When the marginal distributions are symmetric, we have $r_{\min} = -r_{\max}$; otherwise, in the general case (for example when $K_X \neq K_Y$ or the marginals are asymmetric), the two extremes are not negatives of each other.
    

This more explicit explanation details what $\pi$ is, how it enters into the computation of $\rho_S$, and its connection with the Fréchet bounds.

* * *

**You:**

I still think you can be clearer about $\pi$.  As you have it, it is a joint distribution of $X$ and $Y$ (presumably consistant with the marginals of $X$ and $Y$).   Alternatively, couldn't we think of it as permumtations that give rise to the 'coupling' you refer to?

* * *

**ChatGPT:**

my best guess is:

* * *

**Clarifying the Role of $$\pi$$ and the Coupling Interpretation**

Let $\Pi$ denote the set of all joint probability distributions on the product space

$$\{1, 2, \dots, K_X\} \times \{1, 2, \dots, K_Y\}$$

that have the prescribed marginal distributions

$$\Pr(X = i) = p_X(i) \quad\text{for } i = 1, \dots, K_X,\quad \Pr(Y = j) = p_Y(j) \quad\text{for } j = 1, \dots, K_Y.$$

An element $\pi \in \Pi$ is simply a joint distribution $\pi(i, j) = \Pr(X = i, Y = j)$ that is consistent with these marginals.

Alternatively, one may think of a coupling in a more concrete way when one has a finite sample. Imagine that you have $N$ independent draws from $X$ and $N$ independent draws from $Y$ (with $N$ large enough so that the empirical distributions approximate $p_X$ and $p_Y$). A **coupling** of these two samples is a pairing of the $N$ $X$-values with the $N$ $Y$-values. Every such pairing (which can be represented by a permutation of the indices) induces an empirical joint distribution that is consistent with the marginals. In this context, $\pi$ may be viewed as being determined by a particular permutation that pairs each draw from $X$ with a draw from $Y$.

* For instance, if you pair the samples using the **identity permutation** (i.e. you leave the order unchanged), you obtain one possible joint distribution.
    
* If you pair them by sorting the $X$-values in descending order and independently sorting the $Y$-values in descending order, then pairing them index-by-index, this coupling is the **comonotonic coupling**. This coupling maximizes the expected product of the ranks and thus gives the maximum Spearman correlation.
    
* Conversely, if you sort $X$ in descending order and $Y$ in ascending order before pairing them, you obtain the **countermonotonic (or anti-monotonic)** coupling. This coupling minimizes the expected product of the ranks and gives the minimum Spearman correlation.
    

Thus, in both the abstract and the finite-sample (or permutation) interpretation, $\pi$ represents a particular way of "coupling" the marginals. In the abstract setting, it is any joint distribution with the specified marginals. In the finite-sample setting, every such joint distribution can be generated by a permutation of the sample indices.

**Relation to the Fréchet Bounds**

The Fréchet–Hoeffding bounds provide the theoretical limits on the joint cumulative distribution function (or, in the discrete case, the joint probability mass function) that is consistent with given marginals. The upper bound corresponds to the comonotonic (identity permutation) coupling, which maximizes the correlation between the variables. The lower bound corresponds to the countermonotonic (reversal permutation) coupling, which minimizes the correlation. Hence, the extreme values of Spearman's correlation, $r_{\max}$ and $r_{\min}$, are exactly those obtained by the extreme couplings described above.

In summary:

* $\pi$ represents a joint distribution (or coupling) of $X$ and $Y$ consistent with the given marginals.
    
* In a finite-sample interpretation, each $\pi$ is induced by a permutation that matches draws from $X$ with draws from $Y$.
    
* The Fréchet bounds tell us that the comonotonic (identity/permutation preserving order) and countermonotonic (reverse order) couplings are, respectively, the optimal couplings for maximizing and minimizing the expected product of ranks, and hence the Spearman correlation.
    
* This is why, when the marginals are symmetric, one obtains $r_{\min} = -r_{\max}$; if the marginals differ (or the numbers of levels differ), the extremes are not necessarily negatives of one another.
    

This explanation makes explicit the role of $\pi$ as both a joint distribution and as a coupling induced by a permutation, and it explains the connection to the Fréchet bounds.

* * *

**You:**

Tell me more about 'symmetric marginals'.  Lets fix the marginal for $X$ and lets say it is uniform.  Starting with a uniform distribution for $Y$, how can we quantify how 'different' -- or how un-symmetric -- the marginals become as I change the marginal distribution of $Y$?  Entrepy?

* * *

**ChatGPT:**

my best guess is:

When we say a marginal distribution is “symmetric,” we mean that it is invariant under a reflection about its midpoint. For an ordinal variable $Y$ taking values in $\{1, 2, \dots, K_Y\}$, this means

$$p_Y(j) = p_Y(K_Y+1-j) \quad \text{for all } j.$$

In other words, the distribution “looks the same” when you reverse the order of the categories. For example, if $K_Y = 5$, the distribution is symmetric if

$$p_Y(1) = p_Y(5) \quad \text{and} \quad p_Y(2) = p_Y(4),$$

with $p_Y(3)$ as the center.

Now, suppose we fix the marginal for $X$ as uniform and start with a uniform marginal for $Y$. The uniform distribution is both symmetric and of maximum entropy (i.e. it has the greatest uncertainty). If we now change the marginal for $Y$, we can quantify how “different” or “unsymmetric” it becomes by comparing it to its reflection. Two common measures are:

1. **A Symmetry Index (Total Variation Distance from Reflection):**  
    Define the reflected distribution by
    
    $$p_Y^*(j) = p_Y(K_Y+1-j).$$
    
    Then a natural measure of asymmetry is
    
    $$A(p_Y) = \sum_{j=1}^{K_Y} \bigl| p_Y(j) - p_Y^*(j) \bigr|.$$
    
    Note that $A(p_Y) = 0$ if and only if $p_Y$ is symmetric. The larger $A(p_Y)$ is, the more asymmetric (or unsymmetric) the marginal for $Y$ is.
    
2. **Skewness:**  
    The third standardized moment (skewness) is another measure of asymmetry:
    
    $$\gamma_Y = \frac{\mathbb{E}\big[(Y-\mu_Y)^3\big]}{\sigma_Y^3},$$
    
    where $\mu_Y$ is the mean and $\sigma_Y$ is the standard deviation of $Y$. For a symmetric distribution, $\gamma_Y = 0$. A nonzero skewness indicates asymmetry, with the magnitude indicating how far the distribution deviates from symmetry.
    

While **entropy** quantifies the uncertainty or “spread” of a distribution (the uniform distribution has maximum entropy), it does not directly measure symmetry. A distribution can have high entropy yet be asymmetric. Thus, if your goal is to quantify how far the marginal for $Y$ deviates from being symmetric, the measures above—either the total variation distance from its reflection or the skewness—are more directly appropriate.

In summary:

* A marginal $p_Y$ is symmetric if $p_Y(j)=p_Y(K_Y+1-j)$ for all $j$.
    
* To quantify how unsymmetric $p_Y$ is relative to the uniform (which is symmetric), you can compute:
    
    * The symmetry index: $A(p_Y) = \sum_{j=1}^{K_Y} | p_Y(j)-p_Y(K_Y+1-j)|$.
        
    * The skewness: $\gamma_Y = \frac{\mathbb{E}[(Y-\mu_Y)^3]}{\sigma_Y^3}$.
        
* Entropy measures uncertainty rather than symmetry.
    

This way, as you vary the marginal distribution for $Y$ away from uniformity, you can use these measures to quantify the degree of asymmetry.

* * *

**You:**

But aren't there multiple ways to 'move' probability mass in the distribution for $Y$ to transform it from uniform to more-and-more asymmetric (compared to a uniform $X$, which is fixed)?

* * *

**ChatGPT:**

my best guess is:

Yes, there are indeed many ways to “move” probability mass away from uniformity to create increasing asymmetry in $Y$. In our setting where $X$ is fixed as uniform and $Y$ is varied, different modifications to the distribution of $Y$ can yield different patterns of asymmetry. For example:

1. **Shifting Mass to One Tail:**  
    You might move probability mass from the center toward one end (say, the lower end) so that the distribution becomes increasingly “left‐skewed.” This kind of transformation would change the skewness (the third central moment) in a systematic way.
    
2. **Bimodality or Multi-Modal Shifts:**  
    Alternatively, you could create a bimodal distribution by transferring mass from the middle to the extremes, which may increase the asymmetry relative to the mirror image but might do so in a more complex manner than simple skewness captures.
    
3. **Asymmetric Perturbations:**  
    There are also methods that shift mass in a non-uniform way – for example, by using a transformation that perturbs the uniform distribution by a parameter that weights one side of the mirror more heavily than the other. One could quantify such a perturbation via divergence measures such as the Kullback–Leibler divergence between $p_Y$ and its reflection $p_Y^*$ (where $p_Y^*(j)=p_Y(K_Y+1-j)$).
    

Thus, while measures such as the total variation distance from the reflection or the skewness provide one way to quantify asymmetry, they capture only one aspect of how the distribution might deviate from symmetry. In practice, you might consider multiple indices—such as the $L^1$ distance between $p_Y$ and $p_Y^*$, the skewness, and even a divergence measure like the KL-divergence—to fully characterize the “direction” and “degree” of asymmetry as you transform $p_Y$ from uniform to increasingly asymmetric forms.

In summary:

* There are multiple “paths” from uniformity to asymmetry.
    
* Different ways of moving mass (e.g., shifting from the center to one tail, or creating bimodality) can yield different asymmetry characteristics.
    
* To quantify the change, one might use skewness, total variation distance between $p_Y$ and its mirror $p_Y^*$, or divergence measures such as KL-divergence.
    
* These measures capture different aspects of asymmetry, and the choice among them depends on what facet of “unsymmetry” you wish to emphasize.
    

This answer shows that the transformation from uniformity to asymmetry is not unique and that multiple measures can be used to capture the different ways in which the distribution of $Y$ can deviate from symmetry.

* * *

**You:**

Thank you.  which notion of asymmetry would be most useful for exploring $r_{min}$ and $r_{max}$, and the connection to Frechete-Boole bounds?  I am especially interested in when $r_{min} \ne -r_{max}$.

* * *

**ChatGPT:**

my best guess is that a useful measure is the $L^1$ distance between the marginal distribution $p_Y$ and its reflected version $p_Y^*$, i.e., the total variation distance (up to a factor of 1/2). This measure directly quantifies the deviation from symmetry, which is exactly what affects the difference between $r_{\min}$ and $-r_{\max}$.

Here’s why:

1. **Connection to Extreme Couplings:**  
    The Fréchet–Hoeffding bounds (or Fréchet bounds) determine the extreme possible joint distributions (couplings) for fixed marginals. When the marginals are symmetric (i.e., $p_Y(j) = p_Y(K_Y+1-j)$), the optimal comonotonic and countermonotonic couplings yield Spearman correlations that are negatives of each other. When the marginal $p_Y$ deviates from symmetry, the extreme couplings will not be symmetric, and one typically finds that $r_{\min} \neq -r_{\max}$.
    
2. **Total Variation Distance as a Measure of Asymmetry:**  
    A natural way to quantify this asymmetry is to consider
    
    $$D_{\text{TV}}(p_Y, p_Y^*) = \frac{1}{2} \sum_{j=1}^{K_Y} \left| p_Y(j) - p_Y(K_Y+1-j) \right|,$$
    
    where $p_Y^*(j)=p_Y(K_Y+1-j)$. This measure is zero if and only if $p_Y$ is symmetric. As $D_{\text{TV}}$ increases, the marginal becomes more “unsymmetric” and we expect a corresponding increase in the imbalance between $r_{\max}$ and $-r_{\min}$.
    
3. **Alternative Notions:**  
    While skewness (the third standardized moment) also provides a measure of asymmetry, it is sensitive only to the third moment and may not capture all aspects of how probability mass is redistributed. In contrast, the total variation distance (or $L^1$ norm of the difference between $p_Y$ and its reflection) is more directly tied to the actual “movement” of probability mass that affects the coupling structure—and hence the extreme values $r_{\min}$ and $r_{\max}$.
    
4. **Implications for $r_{\min}$ and $r_{\max}$:**  
    When $D_{\text{TV}}(p_Y, p_Y^*) = 0$, the marginal is symmetric and one obtains $r_{\min} = -r_{\max}$. As $D_{\text{TV}}$ increases, the difference $|r_{\min} + r_{\max}|$ will generally increase, reflecting that the countermonotonic arrangement (which minimizes the expected product of ranks) is no longer the exact negative of the comonotonic arrangement.
    

* * *

**Summary**

For exploring how the extreme Spearman correlations (and thus the Fréchet bounds for the joint distribution) depend on the asymmetry of the marginal for $Y$ (with $X$ fixed as uniform), the total variation distance between $p_Y$ and its reflection

$$D_{\text{TV}}(p_Y, p_Y^*) = \frac{1}{2} \sum_{j=1}^{K_Y} \left| p_Y(j) - p_Y(K_Y+1-j) \right|$$

is especially useful. It quantifies precisely how far $p_Y$ is from being symmetric, which in turn controls the relationship between $r_{\min}$ and $r_{\max}$. When $D_{\text{TV}}$ is zero, we have $r_{\min} = -r_{\max}$; as $D_{\text{TV}}$ increases, the balance between $r_{\min}$ and $r_{\max}$ is lost, and one can empirically observe $r_{\min} \ne -r_{\max}$.

Thus, using the total variation distance (or a related $L^1$ measure) as the notion of asymmetry is most appropriate for studying the connection between marginal asymmetry and the extreme values of Spearman’s $r$ in the context of the Fréchet–Hoeffding bounds.

* * *

**You:**

This is fascinating!  Can you work up some R: commands and code to help me visualize and understand what happens as $Y$ 'moves away' from uniform?

* * *

**ChatGPT:**

my best guess is that one practical approach is to start with a fixed uniform marginal for $X$ (say, for 5 categories, $p_X = (0.2, 0.2, 0.2, 0.2, 0.2)$) and then define a family of marginals for $Y$ that interpolate between uniform and a very asymmetric distribution. For example, let the “extreme” distribution be

$$p_Y^{\text{extreme}} = (0.02,\,0.02,\,0.02,\,0.02,\,0.92),$$

and define for a parameter $t\in[0,1]$ the marginal

$$p_Y(t) = (1-t)\,(0.2,0.2,0.2,0.2,0.2) + t\, (0.02,0.02,0.02,0.02,0.92).$$

Then when $t=0$, $p_Y$ is uniform (and symmetric), and when $t=1$ it is extremely asymmetric. We can quantify the asymmetry by the total variation distance between $p_Y(t)$ and its reflection

$$p_Y^*(t) = (p_Y(t)[5],\,p_Y(t)[4],\,p_Y(t)[3],\,p_Y(t)[2],\,p_Y(t)[1]),$$

that is,

$$D_{TV}(t) = \frac{1}{2}\sum_{j=1}^5 \Bigl| p_Y(t)[j] - p_Y(t)[6-j] \Bigr|.$$

We then compute the extreme Spearman correlations $r_{\max}(t)$ and $r_{\min}(t)$ using our functions (which, as explained earlier, give the comonotonic and countermonotonic couplings, respectively). Finally, we can plot how $r_{\max}$ and $r_{\min}$ (and perhaps their sum $r_{\max} + r_{\min}$) vary as a function of $t$ or $D_{TV}(t)$.

Below is an R script that implements this idea:

```r
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
```

### Explanation

1. **Marginal Distributions:**  
    We fix $X$ to be uniform over 5 categories. For $Y$, we define two anchor distributions: uniform and an extremely asymmetric one.
    
2. **Interpolation:**  
    We create a family $p_Y(t)$ that moves from uniform ($t=0$) to the extreme distribution ($t=1$).
    
3. **Asymmetry Measure:**  
    We quantify asymmetry via the total variation distance between $p_Y(t)$ and its reflection, defined as
    
    $$D_{TV}(p_Y(t), p_Y^*(t)) = \frac{1}{2}\sum_{j=1}^5 \Bigl| p_Y(t)[j] - p_Y(t)[6-j] \Bigr|.$$
4. **Extreme Correlations:**  
    For each $p_Y(t)$, we compute $r_{\max}$ and $r_{\min}$ using our previously defined functions, and store the sum $r_{\max}+r_{\min}$ as an indicator of symmetry (which should be zero if $p_Y$ is symmetric).
    
5. **Visualization:**  
    We then plot:
    
    * The total variation distance $D_{TV}$ versus $t$.
        
    * The values of $r_{\max}$ and $r_{\min}$ versus $t$.
        
    * The sum $r_{\max}+r_{\min}$ versus $t$ as an indicator of how far the extreme couplings deviate from being negatives of each other.
        

These plots help visualize and understand what happens as $Y$ "moves away" from uniformity and becomes more asymmetric, and how that affects the extreme values of Spearman’s $r$ and their symmetry.

This code should provide a good basis for exploring and visualizing the phenomenon.

* * *

**You:**

Thank you.  That is an excelent suggestion! And excellent code!  Thank you!
Next I really want to explore when and under what conditions $r_{max} \ne - r_{min}$

* * *

**ChatGPT:**

my best guess is that the key point is that when both marginals are symmetric—say, when both $X$ and $Y$ are uniform—the optimal (comonotonic) and countermonotonic couplings yield Spearman correlations that are exact opposites, i.e. $r_{\min}=-r_{\max}$. However, if one or both marginals are asymmetric, then the extreme couplings no longer mirror each other exactly and we typically observe

$$r_{\min} \neq -r_{\max}.$$

More precisely, if the marginal distribution for $Y$ deviates from symmetry, the “spread” (or variance) of its ranks will not match that of the reflected (or reversed) distribution. In a coupling, the comonotonic arrangement (which pairs high with high) will then yield a larger correlation in absolute value than the countermonotonic arrangement (which pairs high with low). Equivalently, the Fréchet–Hoeffding bounds for the Spearman correlation become asymmetric.

One natural way to quantify the “unsymmetry” of the $Y$ marginal is by comparing $p_Y$ with its reflection $p_Y^*$ (defined by $p_Y^*(j)=p_Y(K_Y+1-j)$) using, for instance, the total variation distance:

$$D_{\text{TV}}(p_Y, p_Y^*) = \tfrac{1}{2}\sum_{j=1}^{K_Y} \left|p_Y(j) - p_Y^*(j)\right|.$$

When $D_{\text{TV}}=0$, the marginal is symmetric and we expect $r_{\min} = -r_{\max}$. As $D_{\text{TV}}$ increases, the difference between the extreme couplings increases, so that $r_{\max} + r_{\min}$ deviates from zero.

Below is an R script that fixes $X$ to be uniform (over, say, 5 categories) and then defines a family of marginal distributions for $Y$ that interpolates between uniform and a highly asymmetric distribution. The code computes $r_{\max}$ and $r_{\min}$ (using the optimal couplings defined previously), calculates the asymmetry via $D_{\text{TV}}$, and then plots the extreme Spearman correlations as well as the sum $r_{\max}+r_{\min}$ (which is zero under symmetry).

```r
# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(gridExtra)

# -----------------------------------------------------
# Define functions for extreme Spearman correlations

# Maximum Spearman correlation via comonotonic coupling
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
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
  
  pX <- countsX/sum(countsX)
  pY <- countsY/sum(countsY)
  muX <- sum(x_levels * pX)
  muY <- sum(y_levels * pY)
  sigmaX <- sqrt(sum(x_levels^2 * pX)-muX^2)
  sigmaY <- sqrt(sum(y_levels^2 * pY)-muY^2)
  
  # Comonotonic coupling via cumulative probabilities (upper Fréchet bound)
  cum_pX <- cumsum(pX)
  cum_pY <- cumsum(pY)
  joint <- matrix(0, nrow = length(x_levels), ncol = length(y_levels))
  
  i <- 1; j <- 1; cumX_prev <- 0; cumY_prev <- 0
  while(i <= length(x_levels) && j <= length(y_levels)){
    currX <- cum_pX[i]; currY <- cum_pY[j]
    joint[i, j] <- min(currX, currY) - max(cumX_prev, cumY_prev)
    if(currX < currY){
      cumX_prev <- currX; i <- i + 1
    } else if(currX > currY){
      cumY_prev <- currY; j <- j + 1
    } else {
      cumX_prev <- currX; cumY_prev <- currY; i <- i + 1; j <- j + 1
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
  
  # Countermonotonic coupling: sort X in descending order and Y in ascending order.
  x_sorted <- sort(x_vec, decreasing = TRUE)
  y_sorted <- sort(y_vec, decreasing = FALSE)
  
  r_min <- cor(x_sorted, y_sorted)
  return(r_min)
}

# -----------------------------------------------------
# Define a function to compute the total variation distance 
# between a probability vector and its reflection.
TV_distance <- function(p) {
  K <- length(p)
  p_reflect <- p[K:1]
  return(0.5 * sum(abs(p - p_reflect)))
}

# -----------------------------------------------------
# Setup: Fix X as uniform over 5 categories and define a family for Y.

p_X <- rep(1/5, 5)  # uniform marginal for X

# Define anchor distributions for Y:
p_Y_uniform <- rep(1/5, 5)
# Define an extremely asymmetric marginal for Y
p_Y_extreme <- c(0.02, 0.02, 0.02, 0.02, 0.92)

# Create a family of marginals for Y by interpolating between uniform and extreme.
t_seq <- seq(0, 1, length.out = 20)
results <- data.frame(t = t_seq, D_TV = NA, r_max = NA, r_min = NA, diff = NA)

sample_size <- 10000

set.seed(123)  # for reproducibility
for(i in seq_along(t_seq)){
  t <- t_seq[i]
  # Interpolated marginal for Y:
  p_Y <- (1-t)*p_Y_uniform + t*p_Y_extreme
  # Compute asymmetry measure:
  D_TV <- TV_distance(p_Y)
  # Compute extreme Spearman correlations:
  r_max_val <- max_corr_sorted(p_X, p_Y, sample_size = sample_size)
  r_min_val <- min_corr_sorted(p_X, p_Y, sample_size = sample_size)
  
  results$t[i] <- t
  results$D_TV[i] <- D_TV
  results$r_max[i] <- r_max_val
  results$r_min[i] <- r_min_val
  results$diff[i] <- r_max_val + r_min_val  # should be 0 when symmetric
}

print(results)

# -----------------------------------------------------
# Plot results:

# (A) Plot total variation distance vs t.
p1 <- ggplot(results, aes(x = t, y = D_TV)) +
  geom_line(size = 1, color = "blue") +
  geom_point(color = "blue") +
  labs(title = "TV Distance from Symmetry vs. t", x = "t", y = "TV Distance") +
  theme_minimal()

# (B) Plot r_max and r_min vs t.
p2 <- ggplot(results, aes(x = t)) +
  geom_line(aes(y = r_max, color = "r_max"), size = 1) +
  geom_line(aes(y = r_min, color = "r_min"), size = 1) +
  geom_point(aes(y = r_max, color = "r_max"), size = 2) +
  geom_point(aes(y = r_min, color = "r_min"), size = 2) +
  labs(title = "Extreme Spearman Correlations vs. t", x = "t", y = "Correlation") +
  scale_color_manual(name = "Legend", values = c("r_max" = "green", "r_min" = "red")) +
  theme_minimal()

# (C) Plot the sum r_max + r_min vs t (symmetry indicator).
p3 <- ggplot(results, aes(x = t, y = diff)) +
  geom_line(size = 1, color = "purple") +
  geom_point(size = 2, color = "purple") +
  labs(title = "r_max + r_min vs. t (Symmetry Indicator)", x = "t", y = "r_max + r_min") +
  theme_minimal()

grid.arrange(p1, p2, p3, ncol = 1)
```

* * *

### Explanation

1. **Setup:**  
    We fix the marginal for $X$ as uniform over 5 categories. For $Y$, we set up two anchor distributions: one uniform and one highly asymmetric.
    
2. **Family of $Y$ Marginals:**  
    We interpolate between the uniform and extreme $Y$ marginals using a parameter $t$. When $t=0$, $p_Y$ is uniform (and symmetric), so we expect $r_{\max} = -r_{\min}$. As $t$ increases, the asymmetry increases.
    
3. **Asymmetry Measure:**  
    We quantify the asymmetry of $p_Y$ by computing the total variation distance between $p_Y$ and its mirror image $p_Y^*$. This distance is 0 for a symmetric distribution and increases as $p_Y$ becomes more asymmetric.
    
4. **Extreme Couplings and Spearman’s $r$:**  
    For each $p_Y$ in the family, we compute the extreme Spearman correlations: $r_{\max}$ via the comonotonic coupling and $r_{\min}$ via the countermonotonic coupling. The sum $r_{\max}+r_{\min}$ should be zero if the marginal is symmetric; any nonzero value indicates that $r_{\max}$ and $r_{\min}$ are not negatives of each other.
    
5. **Visualization:**  
    The plots show how the asymmetry measure (TV distance) increases with $t$, how $r_{\max}$ and $r_{\min}$ evolve, and how the difference $r_{\max}+r_{\min}$ deviates from zero as the distribution becomes more asymmetric.
    

* * *

This code and explanation provide a practical way to visualize and understand when and under what conditions $r_{\max} \neq - r_{\min}$. It shows that as $Y$ "moves away" from uniformity (increasing asymmetry), the extreme Spearman correlations become unbalanced.