# R Code:

# Load required packages
library(ggplot2)
library(pROC)
library(ggsci)

# Fit logistic regression using the first dataset
fit <- glm(cam_icu_score ~ neurological_disease + ventilator_setting + midazolam_use + sofa + temperature_mean + hemoglobin_min + sodium_max, data = train_cohort, family = binomial)

# Predict on train_cohort
pred_train_cohort <- predict(fit, newdata = train_cohort, type = 'link')
train_cohort$pred_value <- pred_train_cohort

# Compute ROC and AUC for train_cohort
roc_train_cohort <- pROC::roc(train_cohort$cam_icu_score, train_cohort$pred_value, levels = c(0,1))
auc_train_cohort <- pROC::auc(roc_train_cohort)
ci_temp_train_cohort <- tryCatch({ci <- pROC::ci(roc_train_cohort); if (any(is.na(ci))) NA else paste0('(', formatC(ci[1], format='f', digits = 3), '-', formatC(ci[3], format='f', digits = 3), ')')}, error = function(e) NA)
auc_fmt_train_cohort <- formatC(auc_train_cohort, format = 'f', digits = 3)
ci_fmt_train_cohort <- ifelse(is.na(ci_temp_train_cohort), '', ci_temp_train_cohort)
# Create AUC summary data frame
auc_results <- data.frame(
  Dataset = 'train_cohort',
  AUC     = auc_fmt_train_cohort,
  CI      = ci_fmt_train_cohort,
  stringsAsFactors = FALSE
)

# Plot ROC curve for train_cohort
p_train_cohort <- pROC::ggroc(roc_train_cohort, legacy.axes = TRUE, size = 0.7, color = '#E64B35FF') +
  geom_abline(slope = 1, intercept = 0, color = 'grey', size = 1) +
  coord_fixed() +
  scale_x_continuous(limits = c(0,1), expand = c(0.02,0.02)) +
  scale_y_continuous(limits = c(0,1), expand = c(0.02,0.02)) +
  theme(
    panel.background = element_blank(),
    axis.title.x = element_text(size = 18, face = 'bold', margin = margin(t = 15)),
    axis.title.y = element_text(size = 18, face = 'bold', margin = margin(r = 15)),
    panel.border = element_rect(size = 2, fill = NA),
    axis.text.x = element_text(size = 14, face = 'bold'),
    axis.text.y = element_text(size = 14, face = 'bold'),
    plot.margin = margin(10, 10, 20, 10)
  ) +
  labs(x = 'False positive rate (1 − specificity)', y = 'True positive rate (sensitivity)')

label_train_cohort <- paste0('AUC = ', auc_fmt_train_cohort, ifelse(ci_fmt_train_cohort == '', '', paste0(' ', ci_fmt_train_cohort)))
p_train_cohort <- p_train_cohort + annotate('text', x = 0.95, y = 0.05, label = label_train_cohort, color = '#E64B35FF', size = 4.5, hjust = 1)

plot_train_cohort <- p_train_cohort

# Predict on validation_cohort
pred_validation_cohort <- predict(fit, newdata = validation_cohort, type = 'link')
validation_cohort$pred_value <- pred_validation_cohort

# Compute ROC and AUC for validation_cohort
roc_validation_cohort <- pROC::roc(validation_cohort$cam_icu_score, validation_cohort$pred_value, levels = c(0,1))
auc_validation_cohort <- pROC::auc(roc_validation_cohort)
ci_temp_validation_cohort <- tryCatch({ci <- pROC::ci(roc_validation_cohort); if (any(is.na(ci))) NA else paste0('(', formatC(ci[1], format='f', digits = 3), '-', formatC(ci[3], format='f', digits = 3), ')')}, error = function(e) NA)
auc_fmt_validation_cohort <- formatC(auc_validation_cohort, format = 'f', digits = 3)
ci_fmt_validation_cohort <- ifelse(is.na(ci_temp_validation_cohort), '', ci_temp_validation_cohort)
# Append to AUC summary
auc_results <- base::rbind(auc_results, data.frame(
  Dataset = 'validation_cohort',
  AUC     = auc_fmt_validation_cohort,
  CI      = ci_fmt_validation_cohort,
  stringsAsFactors = FALSE
))

# Plot ROC curve for validation_cohort
p_validation_cohort <- pROC::ggroc(roc_validation_cohort, legacy.axes = TRUE, size = 0.7, color = '#4DBBD5FF') +
  geom_abline(slope = 1, intercept = 0, color = 'grey', size = 1) +
  coord_fixed() +
  scale_x_continuous(limits = c(0,1), expand = c(0.02,0.02)) +
  scale_y_continuous(limits = c(0,1), expand = c(0.02,0.02)) +
  theme(
    panel.background = element_blank(),
    axis.title.x = element_text(size = 18, face = 'bold', margin = margin(t = 15)),
    axis.title.y = element_text(size = 18, face = 'bold', margin = margin(r = 15)),
    panel.border = element_rect(size = 2, fill = NA),
    axis.text.x = element_text(size = 14, face = 'bold'),
    axis.text.y = element_text(size = 14, face = 'bold'),
    plot.margin = margin(10, 10, 20, 10)
  ) +
  labs(x = 'False positive rate (1 − specificity)', y = 'True positive rate (sensitivity)')

label_validation_cohort <- paste0('AUC = ', auc_fmt_validation_cohort, ifelse(ci_fmt_validation_cohort == '', '', paste0(' ', ci_fmt_validation_cohort)))
p_validation_cohort <- p_validation_cohort + annotate('text', x = 0.95, y = 0.05, label = label_validation_cohort, color = '#4DBBD5FF', size = 4.5, hjust = 1)

plot_validation_cohort <- p_validation_cohort

# Combine all ROC curves into one plot
roc_list <- list('train_cohort' = roc_train_cohort, 'validation_cohort' = roc_validation_cohort)
p_Combined <- pROC::ggroc(roc_list, legacy.axes = TRUE, size = 0.7) +
  scale_color_manual(values = c('#E64B35FF', '#4DBBD5FF'), labels = c('Training cohort', 'Internal test cohort')) +
  geom_abline(slope = 1, intercept = 0, color = 'grey', size = 1) +
  coord_fixed() +
  scale_x_continuous(limits = c(0,1), expand = c(0.02,0.02)) +
  scale_y_continuous(limits = c(0,1), expand = c(0.02,0.02)) +
  theme(
    panel.background = element_blank(),
    axis.title.x = element_text(size = 18, face = 'bold', margin = margin(t = 15)),
    axis.title.y = element_text(size = 18, face = 'bold', margin = margin(r = 15)),
    panel.border = element_rect(size = 2, fill = NA),
    axis.text.x = element_text(size = 14, face = 'bold'),
    axis.text.y = element_text(size = 14, face = 'bold'),
    legend.text = element_text(size = 12),
    plot.margin = margin(10, 10, 20, 10)
  ) +
  labs(x = 'False positive rate (1 − specificity)', y = 'True positive rate (sensitivity)') +
  theme(legend.position = 'right', legend.title = element_blank())

label_combined_train_cohort <- paste0('AUC = ', auc_results$AUC[1], ifelse(auc_results$CI[1] == '', '', paste0(' ', auc_results$CI[1])))
p_Combined <- p_Combined + annotate('text', x = 0.95, y = 0.25, label = label_combined_train_cohort, color = '#E64B35FF', size = 4.5, hjust = 1)

label_combined_validation_cohort <- paste0('AUC = ', auc_results$AUC[2], ifelse(auc_results$CI[2] == '', '', paste0(' ', auc_results$CI[2])))
p_Combined <- p_Combined + annotate('text', x = 0.95, y = 0.2, label = label_combined_validation_cohort, color = '#4DBBD5FF', size = 4.5, hjust = 1)

plot_Combined <- p_Combined

# Print AUC summary
print(auc_results)

# Export plots into a list
plots <- list('train_cohort' = plot_train_cohort, 'validation_cohort' = plot_validation_cohort, Combined = plot_Combined)



