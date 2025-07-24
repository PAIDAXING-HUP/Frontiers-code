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
