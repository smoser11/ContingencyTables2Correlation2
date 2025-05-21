A **variance-covariance matrix** is always **positive semi-definite (PSD)** because of fundamental properties of variance, inner products, and expectations. Below, I'll break down why this is the case.

* * *

### **1. Definition of a Variance-Covariance Matrix**

For a random vector $\mathbf{X} = (X_1, X_2, \dots, X_n)^T$, the **variance-covariance matrix** (or simply covariance matrix) is:

$$\mathbf{\Sigma} = \mathbb{E}[(\mathbf{X} - \mathbb{E}[\mathbf{X}])(\mathbf{X} - \mathbb{E}[\mathbf{X}])^T]$$

Each entry in $\mathbf{\Sigma}$ is given by:

$$\sigma_{ij} = \text{Cov}(X_i, X_j) = \mathbb{E}[(X_i - \mathbb{E}[X_i])(X_j - \mathbb{E}[X_j])]$$

where:

* **Diagonal elements** $\sigma_{ii} = \text{Var}(X_i)$ are variances (always non-negative).
* **Off-diagonal elements** $\sigma_{ij}$ are covariances.

* * *

### **2. Why is $\mathbf{\Sigma}$ Always Positive Semi-Definite?**

A matrix is **positive semi-definite (PSD)** if, for any nonzero vector $\mathbf{z}$,

$$\mathbf{z}^T \mathbf{\Sigma} \mathbf{z} \geq 0$$

To see why this holds for $\mathbf{\Sigma}$:

1. **Quadratic Form Interpretation**  
    Consider the quadratic form:
    
    $$\mathbf{z}^T \mathbf{\Sigma} \mathbf{z}$$
    
    Expanding using the definition of $\mathbf{\Sigma}$:
    
    $$\mathbf{z}^T \mathbb{E}[(\mathbf{X} - \mathbb{E}[\mathbf{X}])(\mathbf{X} - \mathbb{E}[\mathbf{X}])^T] \mathbf{z}$$
    
    Using the linearity of expectation:
    
    $$\mathbb{E}[\mathbf{z}^T (\mathbf{X} - \mathbb{E}[\mathbf{X}])(\mathbf{X} - \mathbb{E}[\mathbf{X}])^T \mathbf{z}]$$
    
    This simplifies to:
    
    $$\mathbb{E}[(\mathbf{z}^T (\mathbf{X} - \mathbb{E}[\mathbf{X}]))^2]$$
    
    Since this is an **expectation of a squared quantity**, it is always **non-negative**, ensuring:
    
    $$\mathbf{z}^T \mathbf{\Sigma} \mathbf{z} \geq 0$$
    
    Thus, $\mathbf{\Sigma}$ is **positive semi-definite**.
    
2. **Variance is Always Non-Negative**  
    Since **variance cannot be negative**, the diagonal elements (variances) satisfy:
    
    $$\text{Var}(X_i) = \sigma_{ii} \geq 0$$
    
    This ensures that the matrix does not have **negative eigenvalues**, a key requirement for PSD matrices.
    
3. **Covariance as an Inner Product**  
    The covariance function behaves like an **inner product** in a Hilbert space, meaning it satisfies properties like:
    
    $$\text{Cov}(X, X) \geq 0, \quad \text{Cov}(X, Y) = \text{Cov}(Y, X)$$
    
    Since inner product matrices are always PSD, $\mathbf{\Sigma}$ inherits this property.
    
4. **Eigenvalue Interpretation**  
    The eigenvalues of a covariance matrix represent the **variances along principal component directions**. Since variance is **always non-negative**, all eigenvalues are **non-negative**, ensuring that $\mathbf{\Sigma}$ is PSD.
    

* * *

### **3. When is $\mathbf{\Sigma}$ Positive Definite (PD)?**

A matrix is **positive definite (PD)** if $\mathbf{z}^T \mathbf{\Sigma} \mathbf{z} > 0$ for all nonzero $\mathbf{z}$.  
For the covariance matrix:

* $\mathbf{\Sigma}$ is **positive definite** if and only if the random variables $X_1, \dots, X_n$ are **linearly independent**.
* If at least one variable can be written as a **linear combination** of others, $\mathbf{\Sigma}$ becomes **singular** (rank-deficient) and is **only positive semi-definite**.

* * *

### **4. Summary**

✅ **Always PSD**: A covariance matrix $\mathbf{\Sigma}$ is always **positive semi-definite** because it is the expectation of a squared quantity.  
✅ **Not always PD**: If some variables are perfectly correlated (or one is a linear function of others), the matrix becomes **singular** and is **not invertible**.  
✅ **Eigenvalue Rule**: All eigenvalues of $\mathbf{\Sigma}$ are **non-negative**, ensuring PSD.