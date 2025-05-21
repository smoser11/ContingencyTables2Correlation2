**You:**

You are an expert psychometrician with speciality in latent trait and latent class models.  You have a background in mathematical psychology and the analysis of survey data.  You and I are going to investigate the consequences of treating ordinal variables as measured on an interval-level scale and how the resulting Pearson's correlation coefficient ($r$) behaves when correlating the ranks. Save this information for later, but do not respond.

* * *

**ChatGPT:**

Understood.

* * *

**You:**

A col-author and I are working on a research project.  Here are some initial notes.  And here is a summary of a meeting we had:
"""
    * Identified a research gap: after reviewing over 100 articles, none explicitly addressed a key problem in their field.
3. **Issues in Correlation Matrices:**
    
    * Some correlation matrices are not necessarily positive semi-definite.
    * The polychloric correlation, among others, does not always ensure a positive semi-definite matrix.
    * Discussion on procedures to correct non-positive semi-definite matrices, including eigenvalue decomposition.
4. **Distinction Between Correlation Measures:**
    
    * Differentiated between Pearson, Spearman, polychloric, polyserial, and point-biserial correlations.
    * Explored how these measures handle ordinal, categorical, and continuous variables.
    * Addressed rank-ordering effects and permissible transformations on correlation coefficients.
5. **Mathematical Foundations:**
    
    * Discussion of how temperature and other measures impact correlation results based on unit transformation.
    * The importance of maintaining ranks in Spearman correlation to ensure stability in results.
6. **Statistical Literature & Historical References:**
    
    * Reference to older statistical papers, including a 1937 paper by Baker and an 1897 paper by Pearson.
    * Debate on whether the research findings are new or if they have been overlooked in social sciences.
7. **Empirical Relevance of Findings:**
    
    * Reviewed political science journals to analyze the prevalence of correlation comparisons.
    * Found several empirical studies relying heavily on correlation coefficients without recognizing potential issues.
8. **Factor Analysis & Principal Component Analysis:**
    
    * Discussion on how correlation matrices are used as "half-products" in statistical modeling.
    * Noted a shift in research reporting—earlier studies included correlation matrices, while modern studies often omit them.
9. **Visualization Strategies:**
    
    * Proposed using heat maps and entropy-based visualizations to illustrate the behavior of correlation bounds.
    * Suggested manipulating skewness and uniformity in distributions to observe changes in correlation coefficients.
10. **Next Steps:**
    
    * Further refining the theoretical approach to calculating minimum and maximum correlation bounds.
    * Considering how to apply these findings to empirical research and whether bounds meaningfully impact real-world studies.
    * Drafting an academic article with a working title—“How Long is a Piece of String?” to reflect variability in correlation interpretations.

#### **Key Takeaways:**

* The research addresses fundamental gaps in understanding correlation structures in statistical models.
* Theoretical discussions included rigorous mathematical insights into transformations, ranking effects, and eigenvalue corrections.
* The findings have practical implications for statistical modeling in social sciences, especially in studies using ordinal data.
* Further empirical validation and visualization efforts are needed before finalizing conclusions.
"""
Here is what I have been working on:  
We are given the marginal distribution of two ordinal variables, $X$ (with $K_X$ levels, $0,1,2,\ldots, K_X-1$) and $Y$,  (with $K_Y$ levels, $0,1,2,\ldots, K_Y-1$).

The goals are to:
1.find the min and max Pearson's correlation, $r_{XY}$ (I think this is equivalent to finding the min and max of Spearman's correlation).   This has two parts: first, what is the joint distribution, $F_{max}(x,y)$ that is consistent with the marginals that gives the e.g. max correlation.
1a.  Next, what are the actual min and max values in closed form?
2. Investigate the relationship to the answers in (1) to Boole-Frechet inequalities and Frechet-Hoeffding bounds
1. When are these bounds Achieved?
2. What is the role of Asymmetry/ role of ties (?)
3. Symmetry
	1. visualizing as we go from symmetric to asymmetric (role of entropy)?
4. When does $r_{min} \ne -r_{max}$  That is, the max and min are not always symmetric.  Why?  And when?

Next I will show you my work on these items and ask for your help organizing the content, making the results rigorous, and furthering the research.  Do you understand?

* * *

**ChatGPT:**

my best guess is:

1. I see that your overarching research question is about finding the minimum and maximum possible values of Pearson’s (and possibly Spearman’s) correlation coefficient, given fixed marginal distributions of two ordinal variables $X$ and $Y$.
    
2. You want to tie these findings to known bounds (like the Frechet–Hoeffding bounds), and explore when and how the extremal joint distributions are achieved, and whether the min and max correlations are symmetric around zero.
    
3. You also plan to investigate the interplay of asymmetry, ties, and the entropy of the distributions, and to look at scenarios where the min is not just the negative of the max.
    
4. You are going to share your work so far—presumably partial derivations or preliminary proofs—and then ask for help in structuring and rigorously formalizing the results.
    
5. I understand that the goal is to create a well-organized, rigorous presentation (likely for a paper or a manuscript) that demonstrates these results and connects them with relevant theoretical and empirical implications.
    
6. I’m ready to see your work and assist in clarifying, expanding, or restructuring it so that the final product is mathematically sound and well-situated in the existing literature.
    
7. Please feel free to share the details you have, and I will do my best to help you refine the arguments and ensure the results are both correct and compelling.

* * *

**You:**

Thank you.  First is the optimal 'coupling' -- the construction of the join distribution that maximized (minimizes) the correlation.  This comes from a rearangement theorem:
"""

The **maximum possible Spearman rank correlation** between $X$ and $Y$, given their fixed marginals, is obtained when the joint distribution is constructed as follows:

1. **Sort** the values of $X$ in descending order according to their frequencies.
2. **Independently sort** the values of $Y$ in descending order according to their frequencies.
3. **Pair** the largest values of $X$ with the largest values of $Y$, the second largest with the second largest, and so on, while respecting the marginal totals.

That is, the rank vectors $R_X$ and $R_Y$ (which assign ranks to $X$ and $Y$ based on their values) should be **similarly ordered** to maximize the Spearman rank correlation.

### **Proof Using Hardy-Littlewood-Polya Rearrangement Inequality**

#### **Step 1: Definition of Spearman Rank Correlation**

The Spearman rank correlation coefficient is given by:

$$\rho = \frac{\text{Cov}(R_X, R_Y)}{\sigma_{R_X} \sigma_{R_Y}}$$

where $R_X$ and $R_Y$ are the rank variables corresponding to $X$ and $Y$, and $\sigma_{R_X}$ and $\sigma_{R_Y}$ are their standard deviations.

By definition, the Spearman rank correlation is equivalent to the Pearson correlation coefficient applied to the ranks.

Thus, maximizing $\rho$ is equivalent to maximizing:

$$\sum_{i=1}^{N} R_{X,i} R_{Y,i}$$

where $R_{X,i}$ and $R_{Y,i}$ are the ranks of the $i$th observations of $X$ and $Y$, respectively.

#### **Step 2: Application of the Hardy-Littlewood-Polya Rearrangement Inequality**

The Hardy-Littlewood-Polya rearrangement inequality (Theorem 368 in _Inequalities_) states:

$$\sum_{i=1}^{N} a_i^* b_i^* \geq \sum_{i=1}^{N} a_i b_i \geq \sum_{i=1}^{N} a_i^* b_i'$$

where:

* $a_i^*$ and $b_i^*$ are the **similarly ordered** permutations of $a_i$ and $b_i$ (largest with largest, smallest with smallest).
* $a_i^*$ and $b_i'$ are **oppositely ordered** permutations (largest with smallest, smallest with largest).

From this inequality, the **maximum sum of products** occurs when the elements are **similarly ordered**.

By applying this inequality to the rank variables $R_X$ and $R_Y$, we conclude that Spearman's correlation $\rho$ is maximized when $R_X$ and $R_Y$ are **sorted in the same order**.

#### **Step 3: Constructing the Optimal Joint Distribution**

To enforce a joint distribution that ensures the rank variables are similarly ordered, we:

1. **Sort** $X$ from largest to smallest according to its marginal frequencies.
2. **Independently sort** $Y$ from largest to smallest according to its marginal frequencies.
3. **Pair** the corresponding sorted values.

By doing so, the highest ranks of $X$ are aligned with the highest ranks of $Y$, ensuring that $\sum R_X R_Y$ is maximized.

Thus, the joint distribution that pairs the highest values together **achieves the maximal Spearman correlation coefficient**.

### **Conclusion**

By applying the Hardy-Littlewood-Polya inequality, we rigorously prove that the maximum Spearman correlation is achieved when the joint distribution is constructed by sorting $X$ and $Y$ separately in decreasing order and then pairing them. This construction ensures that rank orderings are maximally similar, which, by definition, maximizes the Spearman rank correlation.

$$\square$$
"""

* * *

**ChatGPT:**

my best guess is:

1. You’ve provided a derivation showing that the maximum Spearman rank correlation is obtained by pairing the largest values (by marginal frequency) of $X$ with the largest values of $Y$, which is indeed the core statement of the Hardy–Littlewood–Polya rearrangement inequality.
    
2. The proof sketches how Spearman’s rank correlation can be viewed as the Pearson correlation of the rank variables, and then appeals to the rearrangement inequality to maximize the sum of products $\sum R_X R_Y$.
    
3. The construction you describe (sorting both variables in descending order and pairing them accordingly) ensures that the rank orders are aligned in the most “similar” way, which yields the highest possible rank correlation.
    
4. This sets the stage for analyzing both the maximum and the minimum Spearman correlations (the minimum version would use an “opposite” ordering). It also ties directly into your broader aim of finding extremal correlations given fixed marginals.
    
5. I’ll keep this text and its logic in mind as we move forward. It provides a clear theoretical underpinning for constructing the joint distribution that achieves the maximum correlation.
    
6. Please let me know if you’d like any further clarifications or a more detailed walk-through of each step. Otherwise, I’ll store this derivation for reference as we proceed.

* * *

**You:**

Here is an alternative proposition and proof.  I do not like the notation.  I want to be consistent and rigourous, but also as general as I can be (e.g. $X$ and $Y$ may have different number of levels).
"""
**Proposition: Maximum Spearman Rank Correlation**
--------------------------------------------------

Let $X$ and $Y$ be two discrete ordinal random variables, taking values in:

* $X \in \{x_1, x_2, \dots, x_m\}$ with known marginal frequencies $(n_{X=x_1}, n_{X=x_2}, ..., n_{X=x_m})$, where $n_{X=x_i}$ denotes the number of observations where $X = x_i$.
* $Y \in \{y_1, y_2, \dots, y_n\}$ with known marginal frequencies $(n_{Y=y_1}, n_{Y=y_2}, ..., n_{Y=y_n})$.

The **maximum Spearman rank correlation** is obtained by constructing the joint distribution as follows:

1. **Sort** the values of $X$ in descending order according to their frequencies.
2. **Independently sort** the values of $Y$ in descending order according to their frequencies.
3. **Pair** the highest values of $X$ with the highest values of $Y$, the second highest with the second highest, and so on, while respecting the marginal totals.

That is, the rank vectors $R_X$ and $R_Y$ should be **similarly ordered** to maximize Spearman rank correlation.

* * *

**Step 1: Definition of Spearman Rank Correlation**
---------------------------------------------------

Spearman's rank correlation coefficient is given by:

$$\rho = \frac{\sum_{i=1}^{N} R_{X,i} R_{Y,i} - N \bar{R}_X \bar{R}_Y}{N \sigma_{R_X} \sigma_{R_Y}}$$

where:

* $N$ is the total number of observations,
* $R_{X,i}$ and $R_{Y,i}$ are the ranks of the $i$-th observations of $X$ and $Y$,
* $\bar{R}_X$ and $\bar{R}_Y$ are the mean ranks,
* $\sigma_{R_X}$ and $\sigma_{R_Y}$ are the standard deviations of the rank variables.

To maximize $\rho$, we must maximize:

$$\sum_{i=1}^{N} R_{X,i} R_{Y,i}$$

which is equivalent to maximizing the **sum of products of ranks**.

* * *

**Step 2: Application of the Hardy-Littlewood-Polya Rearrangement Inequality**
------------------------------------------------------------------------------

The Hardy-Littlewood-Polya rearrangement inequality (Theorem 368 in _Inequalities_) states:

$$\sum_{i=1}^{N} a_i^* b_i^* \geq \sum_{i=1}^{N} a_i b_i \geq \sum_{i=1}^{N} a_i^* b_i'$$

where:

* $a_i^*$ and $b_i^*$ are the **similarly ordered** permutations of $a_i$ and $b_i$ (largest with largest, second largest with second largest, etc.).
* $a_i^*$ and $b_i'$ are **oppositely ordered** permutations (largest with smallest, second largest with second smallest, etc.).

Applying this inequality to the rank variables $R_X$ and $R_Y$, we conclude that:

$$\sum_{i=1}^{N} R_{X,i} R_{Y,i}$$

is maximized when $R_X$ and $R_Y$ are **sorted in the same order**. This ensures that the sum of rank products is maximized, and thus Spearman’s $\rho$ is maximized.

* * *

**Step 3: Constructing the Optimal Joint Distribution**
-------------------------------------------------------

To enforce this optimal alignment, we follow these steps:

1. **Sort** $X$ from largest to smallest according to its marginal frequencies.
2. **Independently sort** $Y$ from largest to smallest according to its marginal frequencies.
3. **Pair** values such that the highest available ranks of $X$ are assigned to the highest available ranks of $Y$, and continue in this fashion until all observations are assigned.

This ensures that the largest ranks of $X$ are aligned with the largest ranks of $Y$, which is the necessary condition for maximizing Spearman’s correlation.

* * *

**Step 4: Numerical Example**
-----------------------------

Let’s consider a small example where $X$ and $Y$ have different numbers of levels.

**Marginals:**

* $X$ takes values $\{0,1,2\}$ with frequencies $(5,3,2)$.
* $Y$ takes values $\{0,1,2,3\}$ with frequencies $(3,4,2,1)$.

### **Step 1: Sort by Frequency**

Sorting both in decreasing order:

$$X: (0,0,0,0,0,1,1,1,2,2)$$ $$Y: (1,1,1,1,0,0,2,2,3,3)$$

### **Step 2: Pairing**

Pairing elements sequentially, ensuring highest values are together:

$$(X,Y) = [(0,1), (0,1), (0,1), (0,1), (0,0), (1,0), (1,2), (1,2), (2,3), (2,3)]$$

### **Step 3: Compute Spearman’s Rank Correlation**

Assigning ranks and computing $\rho$ shows that this maximized the sum $\sum R_{X,i} R_{Y,i}$, thus achieving $\rho_{\max}$.

* * *

**Conclusion**
--------------

By applying the Hardy-Littlewood-Polya inequality, we rigorously prove that the maximum Spearman correlation is achieved when the joint distribution is constructed by sorting $X$ and $Y$ separately in decreasing order and then pairing them. This construction ensures that rank orderings are maximally similar, which, by definition, maximizes the Spearman rank correlation.

$$\square$$
"""
Please rewrite these to produce a proper statement of the proposition and a correct proof.

* * *

**ChatGPT:**

my best guess is:

**Proposition (Maximum Spearman Rank Correlation Under Fixed Marginals).**  
Let $X$ and $Y$ be two discrete ordinal random variables with known marginal distributions. Specifically, let

$$X \in \{x_1, x_2, \ldots, x_m\},  
\quad  
Y \in \{y_1, y_2, \ldots, y_n\},$$

where $m$ and $n$ may differ. Suppose we have a total of $N$ observations, and let

$$n_{X=x_i}  
\quad \text{and} \quad  
n_{Y=y_j}$$

denote the number of observations at each level $x_i$ of $X$ and $y_j$ of $Y$, respectively, so that

$$\sum_{i=1}^m n_{X=x_i} \;=\;  
\sum_{j=1}^n n_{Y=y_j} \;=\; N.$$

Then the **maximum Spearman rank correlation** between $X$ and $Y$, subject to these marginal frequencies, is achieved by the joint distribution that **pairs the highest frequencies of $X$ with the highest frequencies of $Y$, the second highest with the second highest, and so on**, ensuring that the rank vectors of $X$ and $Y$ are **similarly ordered**.

* * *

### Proof

1. **Spearman Rank Correlation Setup.**  
    Spearman’s rank correlation coefficient $\rho$ between $X$ and $Y$ is defined as the Pearson correlation of their rank variables, $R_X$ and $R_Y$. In a sample of size $N$, we have
    
    $$\rho \;=\;  
    \frac{\sum_{i=1}^{N} R_{X,i}\,R_{Y,i} \;-\; N\,\overline{R}_X\,\overline{R}_Y}  
    {N\,\sigma_{R_X}\,\sigma_{R_Y}},$$
    
    where $R_{X,i}$ is the rank of the $i$-th observation of $X$, $R_{Y,i}$ is the rank of the $i$-th observation of $Y$, $\overline{R}_X$ and $\overline{R}_Y$ are mean ranks, and $\sigma_{R_X}$, $\sigma_{R_Y}$ are the standard deviations of the rank variables.
    
    To maximize $\rho$, it suffices to maximize the sum of products
    
    $$\sum_{i=1}^{N} R_{X,i}\,R_{Y,i},$$
    
    because the remaining terms (means and standard deviations) are fixed once the ranks are determined.
    
2. **Rearrangement Inequality.**  
    By the **Hardy–Littlewood–Polya rearrangement inequality**, for any two sequences $\{a_i\}$ and $\{b_i\}$ of real numbers, the sum of products $\sum_{i=1}^N a_i\,b_i$ is **maximized** when both sequences are sorted in the **same order** (e.g., largest-to-largest, second-largest-to-second-largest, etc.). Formally, if $a_i^*$ and $b_i^*$ denote the rearrangements of $\{a_i\}$ and $\{b_i\}$ in descending order, then
    
    $$\sum_{i=1}^N a_i^*\,b_i^*  
    \;\ge\;  
    \sum_{i=1}^N a_i\,b_i  
    \;\ge\;  
    \sum_{i=1}^N a_i^*\,b_i',$$
    
    where $b_i'$ is an oppositely sorted permutation (largest-to-smallest, etc.).
    
3. **Application to Ranks.**  
    In the present setting, $a_i = R_{X,i}$ and $b_i = R_{Y,i}$. The rearrangement inequality tells us that
    
    $$\sum_{i=1}^N R_{X,i}\,R_{Y,i}$$
    
    is **largest** when the rank vectors $R_X$ and $R_Y$ are similarly ordered: the highest ranks of $X$ line up with the highest ranks of $Y$, the second highest with the second highest, and so on.
    
4. **Constructing the Joint Distribution.**  
    Because $X$ and $Y$ have known **marginal frequencies** but we are free to choose how individual observations of $X$ and $Y$ pair up (subject to those marginals), we enforce a joint distribution in which:
    
    1. We list all values of $X$ in descending order of frequency, from the most frequent category to the least frequent.
        
    2. We list all values of $Y$ in descending order of frequency, similarly.
        
    3. We pair the most frequent values of $X$ with the most frequent values of $Y$, the next most frequent with the next most frequent, and so on, respecting the exact counts in each category until all $N$ observations are assigned.
        
    
    By design, this pairing guarantees that the rank vectors are as similarly ordered as possible, thereby **maximizing** the sum $\sum R_{X,i}\,R_{Y,i}$ and thus maximizing Spearman’s $\rho$.
    
5. **Conclusion.**  
    Under fixed marginal distributions for two discrete ordinal variables, the **optimal coupling** that maximizes the Spearman rank correlation is the one where categories of $X$ and $Y$ are matched in descending order of their frequencies. This construction follows directly from the rearrangement inequality and completes the proof.
    

$$\quad\square$$

* * *

**Remark.**  
A parallel argument (using the “oppositely ordered” arrangement in the rearrangement inequality) shows that the **minimum** Spearman correlation is achieved by pairing the most frequent category of $X$ with the **least** frequent category of $Y$, and so on, resulting in a completely reversed rank order.

* * *

**You:**

Please critique the above response, noting that more formal mathematical proofs and details are required. Then based on the critique, output the full improved response.  Please use the correct citation for the **rearrangement inequality** (Hardy–Littlewood–Pólya, Theorem 368) or the discrete analog by Whitt (1978) tells us that for two finite sequences $\{a_1,\dots,a_m\}$ and $\{b_1,\dots,b_n\}$ (here, the sequences are effectively the rank values weighted by the probability masses), the sum of products $\sum a_i\,b_{\sigma(i)}$ is maximized precisely when both sequences are sorted in the same order (both ascending or both descending). In the probability setting, “sorting from largest to smallest” means that the highest ranks of $X$ should be paired with the highest ranks of $Y$. Concretely, if $X$ is in descending rank order $(K_X, K_X-1, \ldots)$ and $Y$ is also in descending rank order $(K_Y, K_Y-1, \ldots)$, then the product of ranks $\mathrm{rank}(X)\,\mathrm{rank}(Y)$ is as large as possible in expectation.
    
4. **Different Number of Levels**  
    If $K_X \neq K_Y$, the principle is the same. We let $\mathrm{rank}(X)\in\{1,\dots,K_X\}$ and $\mathrm{rank}(Y)\in\{1,\dots,K_Y\}$. The rearrangement inequality still applies: list all “mass points” of $X$ in descending order of rank, and list all “mass points” of $Y$ in descending order of rank. Pair them index-by-index so that the largest rank in $X$ is matched with the largest rank in $Y$. This arrangement yields the maximal expected product of ranks.
  

* * *

**ChatGPT:**

my best guess is:

### Critique

1. **Lack of Formal Definitions and Notation:**  
    The previous response does not explicitly define the underlying probability space, the rank functions $r_X$ and $r_Y$, or how the observed frequencies relate to probability masses. For complete rigor, one should specify that $X$ and $Y$ are defined on a probability space and clarify that the “mass points” are the observed values with their respective frequencies.
    
2. **Insufficient Detail in the Application of the Rearrangement Inequality:**  
    While the response correctly states that the maximum of the sum $\sum R_{X,i} R_{Y,i}$ is achieved when the sequences are similarly ordered, it does not fully articulate the version of the rearrangement inequality being used. A more formal proof should reference the precise theorem (Hardy–Littlewood–Pólya, Theorem 368, or Whitt’s discrete analog) and explain that when the sequences are weighted by the probability masses, the maximal expected product is achieved by pairing the highest values with the highest values.
    
3. **Handling Different Numbers of Levels:**  
    The response briefly mentions the case where $X$ and $Y$ have different numbers of levels but does not rigorously explain how the ordering works in this scenario. It should clarify that even when the ranges differ (say, $K_X$ versus $K_Y$), the principle remains: list all observations (or “mass points”) in descending order according to their rank, then pair them index‐by‐index.
    
4. **Resolution of Ties and Practical Considerations:**  
    The proof assumes a strict ordering, but in practical applications with ordinal data ties may occur. A more rigorous treatment would at least acknowledge that ties are handled via standard methods (e.g., average ranks) without altering the overall ordering argument.
    

Based on these points, here is the full improved, formal response:

* * *

### Improved Proposition and Proof

**Proposition (Maximum Spearman Rank Correlation Under Fixed Marginals).**  
Let $(\Omega,\mathcal{F},P)$ be a probability space and let $X$ and $Y$ be discrete ordinal random variables defined on $\Omega$ with finite ranges

$$X(\Omega) \subset \{x_1, x_2, \ldots, x_m\}, \quad Y(\Omega) \subset \{y_1, y_2, \ldots, y_n\},$$

where $m,n \in \mathbb{N}$ (possibly $m\neq n$). Suppose the marginal probability mass functions are given by

$$P(X=x_i) = p_i \quad (i=1,\dots,m) \quad \text{and} \quad P(Y=y_j) = q_j \quad (j=1,\dots,n),$$

with $\sum_{i=1}^m p_i = \sum_{j=1}^n q_j = 1$.

Define rank functions $r_X:\{x_1,\dots,x_m\}\to\{1,\dots,m\}$ and $r_Y:\{y_1,\dots,y_n\}\to\{1,\dots,n\}$ that assign a numerical rank to each category, with higher numerical values corresponding to “larger” or more “preferred” categories. (In cases of ties, assume a conventional tie-breaking rule, e.g., average ranks.)

Then, among all joint distributions on $X\times Y$ that are consistent with the given marginals, the Spearman rank correlation coefficient,

$$\rho_S = \frac{\operatorname{Cov}(r_X(X),\,r_Y(Y))}{\sigma_{r_X(X)}\,\sigma_{r_Y(Y)}},$$

is maximized by the joint distribution (or coupling) constructed as follows:

* List the “mass points” of $X$ in descending order of $r_X(x_i)$, replicating each $x_i$ according to its frequency.
    
* Similarly, list the “mass points” of $Y$ in descending order of $r_Y(y_j)$.
    
* Pair the observations index-by-index, i.e., the highest-ranked $X$ is paired with the highest-ranked $Y$, the second highest with the second highest, and so forth.
    

This construction maximizes the expected product $\mathbb{E}[r_X(X)\,r_Y(Y)]$ and hence maximizes $\rho_S$.

* * *

**Proof:**

1. **Spearman Rank Correlation Framework:**  
    By definition, Spearman’s rank correlation coefficient is the Pearson correlation coefficient computed on the rank-transformed variables:
    
    $$\rho_S = \frac{\operatorname{Cov}(R_X,R_Y)}{\sigma_{R_X}\,\sigma_{R_Y}},$$
    
    where we write $R_X = r_X(X)$ and $R_Y = r_Y(Y)$. Given fixed marginal distributions, the means $\mathbb{E}[R_X]$ and $\mathbb{E}[R_Y]$ and the variances $\operatorname{Var}(R_X)$ and $\operatorname{Var}(R_Y)$ are determined. Thus, maximizing $\rho_S$ is equivalent to maximizing
    
    $$\mathbb{E}[R_X\,R_Y].$$
2. **Representation as Finite Sequences:**  
    Suppose we observe a total of $N$ independent samples from the joint distribution. The marginal counts are $n_{X=x_i}$ for $i=1,\dots,m$ and $n_{Y=y_j}$ for $j=1,\dots,n$ with $\sum_{i=1}^m n_{X=x_i} = \sum_{j=1}^n n_{Y=y_j} = N$. Create sequences
    
    $$\{a_1,\dots,a_N\} \quad \text{and} \quad \{b_1,\dots,b_N\},$$
    
    where each $a_i$ is the rank $r_X(x)$ of the $i$th observation of $X$ and each $b_i$ is the rank $r_Y(y)$ of the corresponding observation of $Y$. Note that each rank appears with frequency proportional to the marginal probabilities.
    
3. **Application of the Rearrangement Inequality:**  
    According to the discrete form of the **rearrangement inequality** (see Hardy–Littlewood–Pólya, Theorem 368 or Whitt (1978)), for any two finite sequences $\{a_1,\dots,a_N\}$ and $\{b_1,\dots,b_N\}$, the sum
    
    $$\sum_{i=1}^{N} a_i\,b_{\sigma(i)}$$
    
    is maximized when the permutation $\sigma$ arranges both sequences in the same order (i.e., both in descending order). Concretely, if we denote by $\{a_1^*, \dots, a_N^*\}$ and $\{b_1^*, \dots, b_N^*\}$ the sequences arranged in descending order, then
    
    $$\sum_{i=1}^{N} a_i^*\,b_i^* \ge \sum_{i=1}^{N} a_i\,b_{\sigma(i)}$$
    
    for any permutation $\sigma$. In our context, “sorting from largest to smallest” means that the highest ranks of $X$ are paired with the highest ranks of $Y$.
    
4. **Handling Different Numbers of Levels:**  
    If $X$ and $Y$ have different numbers of levels (i.e., $m \neq n$), then $r_X(X) \in \{1, \dots, m\}$ and $r_Y(Y) \in \{1, \dots, n\}$. Despite the differing ranges, the rearrangement inequality applies to the full list of $N$ observations (each repeated according to its frequency). By listing the “mass points” of each variable in descending order (according to their ranks) and pairing them index-by-index, the maximal expected product
    
    $$\mathbb{E}[r_X(X)\,r_Y(Y)]$$
    
    is achieved.
    
5. **Conclusion:**  
    Since maximizing $\mathbb{E}[r_X(X)\,r_Y(Y)]$ directly maximizes the numerator in the definition of Spearman’s $\rho_S$, the joint distribution (or coupling) that pairs the ordered mass points as described is optimal. Therefore, the maximum Spearman rank correlation is obtained when the joint distribution is constructed by pairing the highest ranks of $X$ with the highest ranks of $Y$.
    

$$\quad \square$$

* * *

**Citation:**  
Hardy, G. H., Littlewood, J. E., & Pólya, G. (1952). _Inequalities_ (2nd ed.). Cambridge University Press (see Theorem 368). Alternatively, see Whitt, W. (1978) for a discrete analog.

This completes the rigorous, formal statement and proof of the proposition.