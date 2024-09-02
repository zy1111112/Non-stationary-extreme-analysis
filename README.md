# Non-stationary Extreme Value Analysis Using Wavelet and Point Process Approaches


## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Project Structure](#project-structure)
4. [Usage](#usage)
5. [Features](#features)
6. [Contributing](#contributing)
7. [License](#license)
8. [Contact](#contact)

## Introduction

This project models non-stationary extreme values exhibiting seasonality, using significant wave height data from four stations in the Sargasso Sea. The methodology applies a wavelet transform to detect and quantify seasonal patterns, resulting in a wavelet-filtered time series denoted as $\mu_w(t)$. A point process approach forms the core of the modelling framework, allowing for the incorporation of season- ality through a time-varying threshold and time-dependent parameters, which are Modelled using harmonic functions with an annual period alongside $\mu_w(t)$. Model selection is guided by the Bayesian Information Criterion (BIC), ensur- ing the most effective model is chosen. Additionally, we compute effective and “aggregated” return levels, which not only provide insights into estimation unertainty but also contribute to hazard assessment. 

## Installation

### Prerequisites

- R version x.x.x or higher
- RStudio (optional)
- Required R packages: `package1`, `package2`, `package3`

### Installation Steps

1. Clone the repository:

    ```bash
    git clone https://github.com/yourusername/your-repo-name.git
    ```

2. Open the R project file (.Rproj) in RStudio.

3. Install the required R packages:

    ```R
    install.packages(c("package1", "package2", "package3"))
    ```

4. Install custom package (if applicable):

    ```R
    devtools::install_github("yourusername/your-repo-name/your-package")
    ```

## Project Structure

Below is a brief explanation of the main folders and files in this project:

```plaintext
your-repo-name/
├── data/
│   ├── raw/
│   │   └── dataset.csv
│   ├── processed/
│   │   └── cleaned_data.csv
├── R/
│   ├── functions.R
│   └── analysis_script.R
├── docs/
│   ├── report.md
│   └── figures/
│       └── plot1.png
├── tests/
│   └── testthat/
│       └── test_functions.R
├── .gitignore
├── README.md
└── your-repo-name.Rproj


## Usage

Provide examples of how to use the project, including code snippets and explanations.

### Example

```R
# Load the package
library(yourpackagename)

# Example usage
result <- your_function(input_data)
print(result)





