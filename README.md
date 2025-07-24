# Sepsis Delirium Prediction Model

This project builds a logistic regression model to predict delirium risk in sepsis patients based on the MIMIC-IV database. The workflow covers data extraction, preprocessing, univariate analysis, model building, calibration, decision curve analysis, and nomogram construction, aiming to provide a useful clinical risk assessment tool.

## Table of Contents
- [Project Overview](#project-overview)  
- [File Descriptions](#file-descriptions)  
- [Environment Setup](#environment-setup)  
- [Usage Instructions](#usage-instructions)  
- [Contributing](#contributing)  
- [License](#license)  

## Project Overview

Delirium is a common and serious complication in sepsis patients. Early risk assessment can improve clinical interventions and outcomes. This project uses logistic regression modeling on MIMIC-IV data to estimate delirium risk and provides calibration curves, decision curve analysis, and nomograms as practical tools for clinicians.


## File Descriptions

| Filename                                   | Description                                         |
|--------------------------------------------|----------------------------------------------------|
| `MIMIC-IV Code.SQL`                        | SQL script for extracting data from MIMIC-IV using Navicat |
| `Data preprocessing and univariate analysis.R` | Data preprocessing and univariate analysis          |
| `Training set and internal validation set split.R` | Splitting data into training and internal validation sets |
| `Build the model-multimodel.R`             | Building multivariable logistic regression models  |
| `Calibration code.R`                       | Model calibration and calibration curve plotting   |
| `dca code.R`                              | Decision Curve Analysis (DCA)                       |
| `multiroc code.R`                         | Plotting and comparing ROC curves for multiple models |
| `nomogram_code.R`                         | Constructing the predictive nomogram                |
| `LICENSE`                                | MIT Open Source License                             |


## Environment Setup

Use R programming environment with the following recommended packages:
install.packages(c("tidyverse", "survival", "rms", "pROC", "rmda"))

Usage Instructions
Data Extraction
Run the SQL script in Navicat to extract clinical data from the MIMIC-IV database:
Run MIMIC-IV Code.SQL in Navicat

Data Preprocessing and Univariate Analysis
Load and run in R:
source("Data preprocessing and univariate analysis.R")

Split Training and Validation Sets
source("Training set and internal validation set split.R")

Build Logistic Regression Model
source("Build the model-multimodel.R")

Model Calibration
source("Calibration code.R")

Decision Curve Analysis (DCA)
source("dca code.R")

Plot ROC Curves for Multiple Models
source("multiroc code.R")

Construct Nomogram
source("nomogram_code.R")

License
This project is licensed under the MIT License.
