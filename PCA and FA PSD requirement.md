PCA and FA PSD requirement

**You:**

does  factor analysis or PCA require positive semidefinite (PSD) matrixies?  

* * *

**ChatGPT:**

my best guess is:

**Step 1 – Recall what matrices we are working with**

* In _principal‑components analysis (PCA)_ we usually decompose a _sample_ covariance (or correlation) matrix  
    $\mathbf{S}=n^{-1}\mathbf{X}^{\top}\mathbf{X}$.
    
* In _common factor analysis (FA)_ we try to reproduce that same covariance matrix with the model  
    $\boldsymbol\Sigma \;=\; \boldsymbol\Lambda\boldsymbol\Lambda^{\top}+\boldsymbol\Psi$  
    where $\boldsymbol\Lambda$ is a $p\times k$ loading matrix and $\boldsymbol\Psi$ is a diagonal matrix of unique variances.
    

**Step 2 – Population theory says these matrices _are_ PSD**

* A covariance (or correlation) matrix is, by definition, symmetric and _positive‑semidefinite_ (PSD); if every variable has finite, non‑zero variance it is actually _positive‑definite_ (PD).  
    _Proof sketch:_ for any vector $\mathbf{a}$, $\mathbf{a}^{\top}\boldsymbol\Sigma\mathbf{a}=\operatorname{Var}(\mathbf{a}^{\top}\mathbf{X})\ge 0$.
    

**Step 3 – Sample reality: PSD can be lost numerically**

* Finite‑sample estimates $\mathbf{S}$ are theoretically PSD too, but rounding or listwise deletion can introduce tiny negative eigenvalues (e.g., $-10^{-10}$).  
    _PCA_ software nearly always eigen‑decomposes $\mathbf{S}$. If $\mathbf{S}$ is not PSD the eigenvectors are still real, but negative eigenvalues make the “variance explained” interpretation nonsense.
    

**Step 4 – Consequences for PCA**

* _Mathematical requirement:_ The decomposition works for **any** symmetric matrix, but the usual PCA interpretation (non‑negative variances along orthogonal directions) needs $\mathbf{S}$ to be PSD.
    
* _Practical fixes:_
    
    1. Treat tiny negative eigenvalues as zero.
        
    2. “Nearest‑correlation” adjustment (e.g., Higham 2002 algorithm) to make $\mathbf{S}$ PSD.
        
    3. Work directly with the data matrix and perform an SVD; this bypasses an ill‑behaved $\mathbf{S}$.
        

**Step 5 – Consequences for factor analysis**

* _Maximum‑likelihood FA_ and most other estimators assume the input covariance matrix is PD; otherwise the log‑likelihood (which contains $\log\det\boldsymbol\Sigma$) is undefined.
    
* The _implied_ covariance \widehat{\boldsymbol\Sigma}=\widehat{\boldsymbol\Lambda}}\widehat{\boldsymbol\Lambda}^{\top}+\widehat{\boldsymbol\Psi} must also be PD. Estimation algorithms enforce $\widehat{\boldsymbol\Psi}\succ 0$; if the starting $\mathbf{S}$ is not PSD they will typically refuse to run or converge to nonsense.
    
* As with PCA, numerically adjusting a near‑PSD matrix, or adding a small ridge term ($\mathbf{S}+\epsilon\mathbf{I}$), is the standard cure.
    

**Step 6 – Bottom line**

* **PCA**: strictly speaking the algebra works on any symmetric matrix, but for the usual variance‑explanation interpretation you want a PSD covariance/correlation matrix—and the sample version already provides that unless numerical glitches creep in.
    
* **Factor analysis**: both theory and software _require_ a positive‑definite covariance matrix; if the empirical one is not, you must repair it first.
    

So, while you _ought_ to have a PSD matrix in both procedures, PCA can limp along (mathematically) without it, whereas factor analysis really cannot.

* * *

**You:**

Are you sure?  Suppose I used a symmetric and invertable matrix that is not PSD as an 'input' into FA or PCA.  What would happen?

* * *

**ChatGPT:**

my best guess is:

**Step 1 — Set up an explicit “illegal” example**

Take the symmetric, full‑rank matrix

$$\mathbf{A}\;=\;  
\begin{bmatrix}  
1 & 2\\  
2 & 1  
\end{bmatrix},  
\qquad  
\det(\mathbf{A})=-3\neq 0 .$$

Its eigenvalues are $3$ and $-1$. Because of the negative eigenvalue $\mathbf{A}$ is _indefinite_—symmetric and invertible, but **not** positive‑semidefinite (PSD).

* * *

### Part A What happens if you feed $\mathbf{A}$ to _PCA_?

**Step 2 — The algebra still works**

* The PCA algorithm for a _given_ square matrix simply performs an eigendecomposition  
    $\mathbf{A}= \mathbf{Q}\,\text{diag}(\lambda_1,\lambda_2)\,\mathbf{Q}^{\top}$.
    
* That yields real eigenvectors and eigenvalues even if some $\lambda_j<0$.
    

**Step 3 — But the _interpretation_ breaks**

| Ordinary PCA story | What goes wrong with $\lambda_j<0$ |
| --- | --- |
| Each $\lambda_j$ is the variance explained by component $j$. | “Variance” cannot be negative, so the moment you see $\lambda_2=-1$ the story collapses. |
| Cumulative variance explained is $\sum_{j\le k}\lambda_j / \sum_{j}\lambda_j$. | The denominator can even be _zero_ or _negative_, producing undefined or nonsensical percentages. |
| Loadings $\sqrt{\lambda_j}\,\mathbf{q}_j$ are real numbers. | $\sqrt{\lambda_j}$ is imaginary if $\lambda_j<0$; most software therefore either: (i) simply drops the negative‑eigenvalue components, (ii) emits a warning, or (iii) refuses to continue. |

**Step 4 — What real software does**

* **R — `eigen()`**: happily returns the pair $(\lambda_j,\mathbf{q}_j)$. If you try to treat the result as a covariance decomposition you, not the function, bear the error.
    
* **R — `psych::principal()` or `stats::prcomp()`**: first check the matrix is a valid correlation/covariance matrix; they stop with _“matrix is not positive definite”_.
    
* **Python scikit‑learn — `PCA`**: expects the raw data matrix, not your hand‑crafted $\mathbf{A}$; if you bypass that and feed an indefinite covariance, the internal SVD step still runs, but any negative singular values (they arise numerically from the negative eigenvalues) trigger a runtime warning and the explained‑variance outputs become garbage.
    

* * *

### Part B What happens if you feed $\mathbf{A}$ to _factor analysis_?

**Step 5 — Maximum‑likelihood FA immediately hits the wall**

The ML log‑likelihood for _p_ variables is

$$\log L(\boldsymbol\Lambda,\boldsymbol\Psi)  
=\text{const}-\tfrac12\Bigl(  
\log\det\boldsymbol\Sigma  
+\operatorname{tr}(\boldsymbol\Sigma^{-1}\mathbf{A})  
\Bigr),$$

where $\boldsymbol\Sigma=\boldsymbol\Lambda\boldsymbol\Lambda^{\top}+\boldsymbol\Psi$.

* If $\mathbf{A}$ has even one negative eigenvalue its determinant is negative whenever that count is odd; $\log\det\mathbf{A}$ is then the logarithm of a negative number—**undefined in ℝ**.
    
* Every mainstream FA package therefore starts with a Cholesky or eigen‑test; failure yields an error such as _“Observed covariance matrix is not positive definite”_ and the optimisation halts.
    

**Step 6 — Principal‑axis or image FA fares no better**

These methods rely on iteratively estimating communalities and solving $\mathbf{A}-\boldsymbol\Psi$. For an indefinite $\mathbf{A}$:

* The first communalities update can require taking $\sqrt{\lambda_j}$ of negative numbers.
    
* Even if you force the arithmetic, the next step usually tries to compute a Cholesky factorisation of $\mathbf{A}-\boldsymbol\Psi$; if that matrix is not PSD the factorisation fails.
    

* * *

### Part C General lessons**

**Step 7 — Why the PSD assumption is _really_ inescapable**

1. _Statistical meaning_: Covariance and correlation matrices arise from second moments of real‑valued random variables and are therefore PSD by definition. Supplying an indefinite matrix means you are no longer analysing a feasible random vector.
    
2. _Numerical stability_: Many steps (log‑determinant, Cholesky, square‑roots of eigenvalues) require non‑negative eigenvalues to stay in the reals.
    
3. _Software expectations_: Library code is written for legitimate covariance matrices; feeding an invalid one triggers exceptions or silent nonsense.
    

**Step 8 — If you _really_ must proceed**

* **Repair the matrix**: Project it onto the nearest PSD matrix (Higham 2002 algorithm; available in R `Matrix::nearPD`, Python `cvxpy`, etc.).
    
* **Use raw data + SVD for PCA**: Computing PCA directly from the data matrix sidesteps the need to supply your own covariance.
    
* **Add a ridge term**: $\mathbf{A}_{\text{ridge}}=\mathbf{A}+\varepsilon\mathbf{I}$ with $\varepsilon > |\lambda_\text{most negative}|$ guarantees PSD, though it alters the scale.
    

* * *

### Bottom line

_For PCA_: the eigen‑math still executes on an indefinite symmetric matrix, but the core variance‑explanation story evaporates and software may warn or drop components.

_For factor analysis_: virtually every estimation routine aborts, because the required log‑determinant, inverses, or Cholesky factors do not exist in the real numbers for a non‑PSD input. In practice the run either fails outright or, if forced, converges to meaningless (often complex‑valued) quantities.

* * *

**You:**

Thank you.  This is an excellent explaination.  What about the same question, but applied to Structural Equation Modeling (SEM)?

* * *

**ChatGPT:**

my best guess is:

**Step 1 — Recall the basic SEM machinery**  
* Observed information* You typically supply a _p × p_ sample covariance (or correlation) matrix $\mathbf{S}$.  
* Model side* The parameters $\boldsymbol\theta$ imply a model covariance

$$\boldsymbol\Sigma(\boldsymbol\theta)=\mathbf{T}(\boldsymbol\theta)\mathbf{T}(\boldsymbol\theta)^{\!\top}+\mathbf{D}(\boldsymbol\theta),$$

where $\mathbf{T}$ collects the structural and measurement paths and $\mathbf{D}$ is (block‑)diagonal with residual variances.

**Step 2 — The mainstream fit functions assume PSD/PD matrices**

| Estimator | Fit function $F(\boldsymbol\theta)$ (simplified) | Needs $\mathbf{S}\succ 0$? | Needs $\boldsymbol\Sigma(\boldsymbol\theta)\succ 0$? |
| --- | --- | --- | --- |
| Maximum‑Likelihood (ML) | (\displaystyle \log | \boldsymbol\Sigma | +\operatorname{tr}!\bigl(\mathbf{S}\boldsymbol\Sigma^{-1}\bigr)-\log |
| Generalised Least Squares (GLS) | $\displaystyle \tfrac12\|\mathbf{S}-\boldsymbol\Sigma\|_{\boldsymbol\Sigma^{-1}\otimes\boldsymbol\Sigma^{-1}}^{2}$ | Yes (needs $\mathbf{S}^{-1}$) | Yes |
| Weighted LS (WLS) / DWLS | $ \bigl(\operatorname{vec}(\mathbf{S}-\boldsymbol\Sigma)\bigr)^{\!\top} \mathbf{W}^{-1}\bigl(\operatorname{vec}(\mathbf{S}-\boldsymbol\Sigma)\bigr)$ | Only indirectly† | Yes |
| Unweighted LS (ULS) | $ \|\mathbf{S}-\boldsymbol\Sigma\|_{F}^{2}$ | Not strictly‡ | Yes |

† The asymptotic weight matrix $\mathbf{W}$ is itself based on $\mathbf{S}$ and is invertible only if $\mathbf{S}$ is PD.  
‡ ULS can start from an indefinite $\mathbf{S}$ but any test statistic you compute afterwards (e.g., χ²) again needs $\mathbf{S}^{-1}$.

**Step 3 — What actually happens if $$\mathbf{S}$$ is symmetric, full‑rank, but _not_ PSD?**

1. **Numerical checks fail early**. Every SEM package (lavaan, Mplus, Amos, LISREL, OpenMx, …) first tries a Cholesky or eigen‑test; a negative eigenvalue triggers an error such as “sample covariance matrix is not positive definite”.
    
2. **Log‑likelihood undefined** (ML & GLS): $\log|\mathbf{S}|=\log(\text{negative})$ is not real.
    
3. **Weight matrix inversion fails** (WLS/DWLS): $\mathbf{W}$ inherits indefiniteness and is not invertible or produces negative variances in test statistics.
    
4. **Estimation cannot proceed** unless the software silently smooths the matrix (lavaan has an `orthonormalize` option; LISREL’s _re_ command does similar).
    

**Step 4 — Suppose you somehow bypass that gatekeeping**  
Even if you force optimisation to start, at the first step the program needs $\boldsymbol\Sigma^{-1}$ and $\log|\boldsymbol\Sigma|$. The search instantly steps into a complex number space or returns NaNs, so convergence is impossible.

**Step 5 — What if the _implied_ covariance becomes non‑PSD during the search?**  
That can happen with extreme starting values or Heywood cases (negative residual variances). Packages handle it by

* applying _boundary constraints_ (residual variances ≥ $10^{-6}$), or
    
* stepping back and reducing the line‑search step size, or
    
* moving to the nearest PD matrix (barrier or trust‑region methods).
    

If the optimiser repeatedly hits the boundary you end up with “not admissible” or “solution not found” messages.

**Step 6 — Does any SEM estimator truly tolerate an indefinite $$\mathbf{S}$$?**

* **Bayesian SEM** with a Wishart or inverse‑Wishart data likelihood still needs $\mathbf{S}\succ 0$ (the Wishart density is zero otherwise).
    
* **Pairwise‑present (raw data) ML / FIML** sidesteps the _matrix_ issue by maximising casewise log‑likelihoods, but internally it still evaluates pattern‑specific covariance matrices and those must be PSD.
    
* **PLS‑SEM** (partial least squares paths) works on correlations of composites and therefore inherits the same PSD requirement—although software often repairs the matrix in the background.
    

**Step 7 — How practitioners deal with near‑ill‑conditioned or indefinite matrices**

1. **“Nearest positive‑definite” smoothing** (Higham 2002 algorithm; R `Matrix::nearPD`, Python `numpy.linalg` + `scipy.linalg` scripts).
    
2. **Add a small ridge**: $\mathbf{S}_{\text{ridge}}=\mathbf{S}+\varepsilon \mathbf{I}$ with $\varepsilon>| \lambda_{\min}(\mathbf{S}) |$.
    
3. **Analyse the raw data** instead of a hand‑edited covariance table.
    
4. **Check the source**: rounding a published correlation matrix to two decimals is the classic culprit for tiny negative eigenvalues.
    

**Step 8 — Bottom line for SEM**

* _Observed matrix:_ Every classical SEM fit function is derived under the assumption that the sample covariance is **positive definite**; giving it an indefinite but invertible matrix will cause an immediate failure or yield meaningless (complex/NaN) results.
    
* _Implied matrix during estimation:_ The optimiser enforces PD either by constraints or by rejecting steps that leave the admissible parameter space.
    
* _So_—just as with factor analysis but even more so than with PCA—SEM is inseparable from the PSD requirement. If your input matrix violates it, _repair or replace it first_; otherwise the model cannot be estimated.