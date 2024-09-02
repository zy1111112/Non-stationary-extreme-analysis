# Non-stationary Extreme Value Analysis Using Wavelet and Point Process Approaches


## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Project Structure](#project-structure)
4. [Contact](#contact)

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
Non-stationary-extreme-analysis/
├── Data/
│   ├── #41043/
│   ├── #41044/
│   ├── #41047/
│   ├── #41049/
│   ├── Processes_data/
│   │   ├── data_41043.csv
│   │   ├── data_41044.csv
│   │   ├── data_41047.csv
│   │   └── data_41049.csv
├── R/
│   ├── Data_analysis/
│   │   ├── EDA.R
│   │   ├── choose_block_on_2023.R
│   │   ├── check_of_block.R
│   │   ├── overall_72-h maxima.R
│   ├── Wavelet_anallysis/
│   └── Modelling/
│       ├── threshold_finding.R
│       ├── Model_fitting_and_return.R
│       ├── Model_fitting_reconstruct/
│       └── Analysis_based_on_best_model/
│               ├── z_w_statistics.R
│               └── return_best_fitted.R
└── README.md
```
## Folder and File Descriptions

Here is an explanation of the main folders and files in this project:

- **Data/**: Contains raw and processed data files.
  - **#41043/**, **#41044/**, **#41047/**, **#41049/**: These folders store raw data specific to different stations.
  - **Processes_data/**: Contains processed data files ready for analysis.
    - **data_41043.csv**, **data_41044.csv**, **data_41047.csv**, **data_41049.csv**: Processed versions of the 72-hour maxima datasets for each station, including scaled time, reconstructed data, and threshold values for each 72-hour maxima observation.

- **R/**: Contains R scripts related to data analysis and modeling.
  - **Data_analysis/**: A sub-directory within `R/` that includes scripts for various stages of data analysis.
    - **EDA.R**: Script for performing exploratory data analysis on the dataset.
    - **choose_block_on_2023.R**: Script focused on selecting data blocks by examining the serial correlation of internal structures for station 41049 in the year 2023. 
    - **check_of_block.R**: Script used to validate 72-hour data blocks by examining the first-order dependence of extreme value occurrences.
    - **overall_72-h maxima.R**: Script for calculating or analyzing the 72-hour maxima across datasets.
  - **Wavelet_analysis/**: A sub-directory within `R/` containing scripts related to wavelet analysis. These scripts are used to generate the wavelet power spectrum, compute the global power spectrum, detect significant periods, and perform data reconstruction based on the wavelet analysis.
  - **Modelling/**: A sub-directory within `R/` that includes scripts related to the modeling phase.
    - **threshold_finding.R**: Script used to determine time-varying thresholds.
    - **Model_fitting_and_return.R**: Script for model fitting and return level estimation based on the models without reconstruction term. 
    - **Model_fitting_reconstruct/**: A directory dedicated to scripts for fitting models and estimating return levels based on the models with reconstruction term. 
    - **Analysis_based_on_best_model/**: Contains scripts for identifying and using the best-fitting models.
      - **z_w_statistics.R**: Script for computing or analyzing Z-statistics and W-statistics relevant to the best model fits.
      - **return_best_fitted.R**: Script to make effective and aggregated return level estimation based on the best model.

- **README.md**: This file, providing an overview and instructions for the project.

## Step-by-Step Guide

To help you navigate and work with this project, here is a step-by-step guide:

1. **Data Preparation**:
   - Place raw data in the appropriate folders under `Data/` (e.g., `#41043/`, `#41044/`).
   - Process raw data as necessary and store the results in `Data/Processes_data/`.

2. **Data Analysis**:
   - Navigate to the `R/Data_analysis/` directory.
   - Use `EDA.R` to explore and understand the data.
   - Validate blocks of data with `check_of_block.R`.
   - If analyzing data from 2023, use `choose_block_on_2023.R`.
   - Calculate 72-hour maxima using `overall_72-h maxima.R`.

3. **Modelling**:
   - Start with `R/Data_analysis/Modelling/Analysis_based_on_best_model/` to identify and use the best models.
   - Use `Model_fitting_and_return.R` for model fitting and result generation.
   - Apply `threshold_finding.R` for determining necessary thresholds.
   - Explore `Wavelet_analysis/` for wavelet-based analysis if needed.

4. **Model Fitting and Reconstruction**:
   - Use the scripts in `R/Data_analysis/Modelling/Model_fitting_reconstruct/` to focus on model fitting and reconstruction tasks.


## Contact

For any questions, please feel free to reach out:

- **Your Name**
- Email: [zy1723@ic.ac.uk](mailto:zy1723@ic.ac.uk)






