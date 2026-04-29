# ══════════════════════════════════════════════════════════════════════════════
# PAPER 1 — PASO 5B (FINAL): LISA LOGISTIC REGRESSION MODELS (M5 & M6)
# ══════════════════════════════════════════════════════════════════════════════
# M5a: HL vs LL | Rural-Remote
# M5b: HL vs LL | Rural-Accessible
# M6a: HH vs LH | Rural-Remote
# M6b: HH vs LH | Rural-Accessible
# Same rigorous pipeline as M1-M4: stepAIC + post-hoc pruning + Firth if needed
# ══════════════════════════════════════════════════════════════════════════════

library(MASS)
library(logistf)
library(pROC)
library(dplyr)
library(readr)

cat("Packages loaded.\n")

# ── Paths ─────────────────────────────────────────────────────────────────────
ROOT       <- file.path("C:/Users/juanz/OneDrive/Desktop/UCM/RURIM ESCAPE",
                        "GeoSpatial/01_Python Data Analysis",
                        "rural-migration-land-use-spain")
DEMO_DERIV <- file.path(ROOT, "data/demography/derived/paper1")

INPUT_DATA   <- file.path(DEMO_DERIV, "p5a_rural_analysis_dataset.csv")
INPUT_SELVAR <- file.path(DEMO_DERIV, "p5a_selected_variables.csv")

# ── Constants ─────────────────────────────────────────────────────────────────
RURAL_REMOTE     <- "Rural - Remoto"
RURAL_ACCESSIBLE <- "Rural - Accesible"

# Models requiring Firth (to be determined after stepAIC)
FIRTH_MODELS_LISA <- c()  # Will populate if separation detected

SUPPRESSED_VARS <- c(
  "ECONOMIA__RENTAS__Renta neta media por persona",
  "ECONOMIA__RENTAS__Renta neta media por hogar",
  "ECONOMIA__RENTAS__DESIGUALDAD__Indice de Gini (%)",
  "ECONOMIA__RENTAS__DESIGUALDAD__Distribucion de la renta P80/P20"
)

# Post-hoc collinearity drops (based on exploratory max ρ values)
# Will be refined after seeing stepAIC-selected correlation matrices
COLLINEAR_DROP_LISA <- list(
  M5a = c(
    # Hogares unipersonales: rho with Tamaño medio = high
    "VIVIENDA__HOGAR__Hogares unipersonales \n(% s/ total)"
  ),
  M5b = c(
    # Hogares unipersonales: rho with Tamaño medio = high
    "VIVIENDA__HOGAR__Hogares unipersonales \n(% s/ total)"
  ),
  M6a = c(
    # Hogares unipersonales: rho with Tamaño medio = high
    "VIVIENDA__HOGAR__Hogares unipersonales \n(% s/ total)"
  ),
  M6b = c(
    # Hogares unipersonales: rho with Tamaño medio = high
    "VIVIENDA__HOGAR__Hogares unipersonales \n(% s/ total)"
  )
)

cat("Constants defined.\n")

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1: LOAD DATA
# ══════════════════════════════════════════════════════════════════════════════

df <- read_delim(INPUT_DATA, delim = ";", locale = locale(encoding = "UTF-8"),
                 col_types = cols(Mun_Code = col_character()),
                 show_col_types = FALSE)
df$Mun_Code <- formatC(as.integer(df$Mun_Code), width = 5, flag = "0")

cat(sprintf("Loaded: %d municipalities\n", nrow(df)))

df_selvar <- read_delim(INPUT_SELVAR, delim = ";",
                        locale = locale(encoding = "UTF-8"),
                        show_col_types = FALSE)
SELECTED_VARS <- df_selvar$variable[df_selvar$selected == TRUE]
cat(sprintf("Selected variables: %d\n", length(SELECTED_VARS)))

# Impute suppressed values
df_imp <- df
for (var in SUPPRESSED_VARS) {
  matched <- grep(sub(".*__", "", var), names(df_imp), value = TRUE, fixed = FALSE)
  if (length(matched) == 0) next
  col <- matched[1]
  
  df_imp <- df_imp %>%
    group_by(size_group, tipo_goerlich) %>%
    mutate(!!col := ifelse(is.na(.data[[col]]),
                           median(.data[[col]], na.rm = TRUE),
                           .data[[col]])) %>%
    ungroup() %>%
    group_by(tipo_goerlich) %>%
    mutate(!!col := ifelse(is.na(.data[[col]]),
                           median(.data[[col]], na.rm = TRUE),
                           .data[[col]])) %>%
    ungroup()
}

cat("Imputation complete.\n")

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2: MODEL SETUP
# ══════════════════════════════════════════════════════════════════════════════

# Create response flags
df_imp$is_HL <- as.integer(df_imp$lisa_sig_quad == "HL")
df_imp$is_LL <- as.integer(df_imp$lisa_sig_quad == "LL")
df_imp$is_LH <- as.integer(df_imp$lisa_sig_quad == "LH")
df_imp$is_HH <- as.integer(df_imp$lisa_sig_quad == "HH")

# Model specifications
LISA_MODEL_SPECS <- list(
  list(model_id = "M5a", typology = RURAL_REMOTE,     response = "is_HL",
       reference = "is_LL", target = "HL", ref_label = "LL"),
  list(model_id = "M5b", typology = RURAL_ACCESSIBLE, response = "is_HL",
       reference = "is_LL", target = "HL", ref_label = "LL"),
  list(model_id = "M6a", typology = RURAL_REMOTE,     response = "is_HH",
       reference = "is_LH", target = "HH", ref_label = "LH"),
  list(model_id = "M6b", typology = RURAL_ACCESSIBLE, response = "is_HH",
       reference = "is_LH", target = "HH", ref_label = "LH")
)

# Build standardised subsets
lisa_model_data <- list()

for (spec in LISA_MODEL_SPECS) {
  mid      <- spec$model_id
  typology <- spec$typology
  response <- spec$response
  ref_resp <- spec$reference
  
  subset <- df_imp[
    df_imp$tipo_goerlich == typology &
      (df_imp[[response]] == 1 | df_imp[[ref_resp]] == 1), ]
  
  avail_vars <- SELECTED_VARS[SELECTED_VARS %in% names(subset)]
  
  n_before <- nrow(subset)
  subset <- subset[complete.cases(subset[, avail_vars]), ]
  n_dropped <- n_before - nrow(subset)
  
  X_raw <- as.matrix(subset[, avail_vars])
  means <- colMeans(X_raw, na.rm = TRUE)
  sds   <- apply(X_raw, 2, sd, na.rm = TRUE)
  sds[sds == 0] <- 1
  X_std <- scale(X_raw, center = means, scale = sds)
  df_std <- as.data.frame(X_std)
  
  y <- subset[[response]]
  
  lisa_model_data[[mid]] <- list(
    spec        = spec,
    subset      = subset,
    X           = df_std,
    y           = y,
    means       = means,
    sds         = sds,
    avail_vars  = avail_vars,
    n_target    = sum(y == 1),
    n_reference = sum(y == 0),
    n_total     = nrow(subset),
    n_dropped   = n_dropped
  )
  
  cat(sprintf("%s  %s vs %s  n_target=%3d  n_ref=%3d  n_total=%3d\n",
              mid, spec$target, spec$ref_label,
              sum(y == 1), sum(y == 0), nrow(subset)))
}

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3: STEPWISE VARIABLE SELECTION
# ══════════════════════════════════════════════════════════════════════════════

aicc <- function(loglik, k, n) {
  aic <- -2 * loglik + 2 * k
  if (n - k - 1 <= 0) return(aic)
  aic + (2 * k^2 + 2 * k) / (n - k - 1)
}

lisa_selection_results <- list()

for (spec in LISA_MODEL_SPECS) {
  mid   <- spec$model_id
  mdata <- lisa_model_data[[mid]]
  
  cat(sprintf("\n%s — %s vs %s\n", mid, spec$target, spec$ref_label))
  
  df_model <- mdata$X
  df_model$y <- mdata$y
  
  safe_names <- make.names(mdata$avail_vars)
  names(df_model)[names(df_model) %in% mdata$avail_vars] <- safe_names[
    match(names(df_model)[names(df_model) %in% mdata$avail_vars], mdata$avail_vars)
  ]
  predictor_cols <- names(df_model)[names(df_model) != "y"]
  
  null_formula <- as.formula("y ~ 1")
  null_model   <- glm(null_formula, data = df_model, family = binomial)
  
  full_formula <- as.formula(paste("y ~", paste(predictor_cols, collapse = " + ")))
  full_model   <- glm(full_formula, data = df_model, family = binomial,
                      control = glm.control(maxit = 200))
  
  step_model <- stepAIC(null_model,
                        scope = list(lower = null_formula, upper = full_formula),
                        direction = "both",
                        trace = 0,
                        k = 2)
  
  selected_safe <- names(coef(step_model))[-1]
  selected_orig <- mdata$avail_vars[match(selected_safe,
                                          make.names(mdata$avail_vars))]
  
  n_obs <- mdata$n_total
  k_fin <- length(selected_safe) + 1
  aicc_val <- aicc(logLik(step_model)[1], k_fin, n_obs)
  ratio <- n_obs / k_fin
  crit_name <- ifelse(ratio < 40, "AICc", "AIC")
  crit_val <- ifelse(ratio < 40, aicc_val, AIC(step_model))
  
  lisa_selection_results[[mid]] <- list(
    selected_safe  = selected_safe,
    selected_orig  = selected_orig,
    step_model     = step_model,
    aic            = AIC(step_model),
    aicc           = aicc_val,
    crit_name      = crit_name,
    crit_val       = crit_val,
    safe_names     = safe_names,
    orig_names     = mdata$avail_vars,
    df_model       = df_model,
    predictor_cols = predictor_cols
  )
  
  cat(sprintf("  -> %d predictors, %s = %.2f\n",
              length(selected_safe), crit_name, crit_val))
}

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4: FIT FINAL MODELS (WITH POST-HOC PRUNING)
# ══════════════════════════════════════════════════════════════════════════════

lisa_fitted_models <- list()
lisa_metrics_rows  <- list()

for (spec in LISA_MODEL_SPECS) {
  mid    <- spec$model_id
  mdata  <- lisa_model_data[[mid]]
  selres <- lisa_selection_results[[mid]]
  
  df_model      <- selres$df_model
  safe_names    <- selres$safe_names
  orig_names    <- selres$orig_names
  selected_safe <- selres$selected_safe
  
  # Post-hoc collinearity pruning
  drop_orig <- COLLINEAR_DROP_LISA[[mid]]
  if (is.null(drop_orig)) drop_orig <- character(0)
  drop_safe <- safe_names[match(drop_orig, orig_names)]
  drop_safe <- drop_safe[!is.na(drop_safe)]
  
  pruned_safe  <- selected_safe[!selected_safe %in% drop_safe]
  dropped_safe <- selected_safe[selected_safe %in% drop_safe]
  
  if (length(dropped_safe) > 0) {
    cat(sprintf("%s: pruned %d -> %d  (dropped: %s)\n",
                mid, length(selected_safe), length(pruned_safe),
                paste(dropped_safe, collapse = ", ")))
  }
  selected_safe <- pruned_safe
  
  if (length(selected_safe) == 0) {
    cat(sprintf("%s: No predictors after pruning — skipping\n", mid))
    next
  }
  
  # Prepare data
  df_fit <- as.data.frame(lapply(
    df_model[, c(selected_safe, "y"), drop = FALSE],
    function(x) if (is.matrix(x)) as.vector(x) else x
  ))
  
  clean_names <- make.names(names(df_fit), unique = TRUE)
  names(df_fit) <- clean_names
  selected_clean <- head(clean_names, -1)
  formula_fit <- as.formula(paste("y ~", paste(selected_clean, collapse = " + ")))
  
  use_firth <- mid %in% FIRTH_MODELS_LISA
  
  # Fit model
  if (use_firth) {
    fit <- tryCatch({
      logistf(formula_fit, data = df_fit,
              control = logistf.control(maxit = 200, maxstep = 5),
              plconf = 0.95)
    }, error = function(e) {
      cat(sprintf("  ERROR in logistf for %s: %s\n", mid, e$message))
      glm(formula_fit, data = df_fit, family = binomial,
          control = glm.control(maxit = 200))
    })
    
    if (inherits(fit, "logistf")) {
      estimator <- "Firth (logistf)"
    } else {
      estimator <- "MLE (glm) [Firth failed]"
      use_firth <- FALSE
    }
  } else {
    fit <- glm(formula_fit, data = df_fit, family = binomial,
               control = glm.control(maxit = 200))
    estimator <- "MLE (glm)"
  }
  
  # Evaluation metrics
  if (use_firth) {
    y_pred_prob <- fit$predict
    llf         <- fit$loglik[2]
    llf_null    <- fit$loglik[1]
    mcfadden_r2 <- 1 - llf / llf_null
    k_final     <- length(selected_safe) + 1
    aic_val     <- -2 * llf + 2 * k_final
  } else {
    y_pred_prob <- fitted(fit)
    llf         <- logLik(fit)[1]
    null_fit    <- glm(y ~ 1, data = df_fit, family = binomial,
                       control = glm.control(maxit = 200))
    llf_null    <- logLik(null_fit)[1]
    mcfadden_r2 <- 1 - llf / llf_null
    k_final     <- length(selected_safe) + 1
    aic_val     <- AIC(fit)
  }
  
  roc_obj <- roc(df_fit$y, y_pred_prob, quiet = TRUE)
  auc_val <- as.numeric(auc(roc_obj))
  
  n_extreme   <- sum(y_pred_prob < 0.01 | y_pred_prob > 0.99)
  pct_extreme <- n_extreme / mdata$n_total * 100
  
  if (length(selected_safe) >= 2) {
    corr_mat <- cor(df_model[, selected_safe], method = "spearman")
    diag(corr_mat) <- 0
    max_rho <- max(abs(corr_mat))
  } else {
    max_rho <- NA_real_
  }
  
  n_obs     <- mdata$n_total
  aicc_val  <- aicc(llf, k_final, n_obs)
  ratio     <- n_obs / k_final
  crit_name <- ifelse(ratio < 40, "AICc", "AIC")
  crit_val  <- ifelse(ratio < 40, aicc_val, aic_val)
  
  selected_orig <- orig_names[match(selected_safe, safe_names)]
  
  lisa_fitted_models[[mid]] <- list(
    fit           = fit,
    selected_safe = selected_safe,
    selected_orig = selected_orig,
    y_pred_prob   = y_pred_prob,
    mcfadden_r2   = mcfadden_r2,
    auc           = auc_val,
    crit_name     = crit_name,
    crit_val      = crit_val,
    aic           = aic_val,
    estimator     = estimator,
    use_firth     = use_firth,
    df_fit        = df_fit,
    safe_names    = safe_names,
    orig_names    = orig_names
  )
  
  lisa_metrics_rows[[mid]] <- data.frame(
    model_id                  = mid,
    typology                  = spec$typology,
    comparison                = paste(spec$target, "vs", spec$ref_label),
    estimator                 = estimator,
    n_target                  = mdata$n_target,
    n_reference               = mdata$n_reference,
    n_total                   = mdata$n_total,
    n_predictors              = length(selected_safe),
    criterion_name            = crit_name,
    criterion_value           = round(crit_val, 4),
    mcfadden_r2               = round(mcfadden_r2, 4),
    auc                       = round(auc_val, 4),
    n_extreme_probs           = n_extreme,
    pct_extreme_probs         = round(pct_extreme, 2),
    max_retained_spearman_rho = round(max_rho, 3),
    stringsAsFactors          = FALSE
  )
  
  cat(sprintf("%s: %s=%.2f  R2=%.3f  AUC=%.3f  n_pred=%d  max_rho=%.3f\n",
              mid, crit_name, crit_val, mcfadden_r2, auc_val,
              length(selected_safe), ifelse(is.na(max_rho), 0, max_rho)))
}

df_lisa_metrics <- bind_rows(lisa_metrics_rows)

cat("\n")
cat(strrep("=", 80))
cat("\nLISA MODEL METRICS\n")
cat(strrep("=", 80))
cat("\n")
print(df_lisa_metrics)

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5: EXTRACT COEFFICIENTS
# ══════════════════════════════════════════════════════════════════════════════

lisa_coef_rows <- list()

for (spec in LISA_MODEL_SPECS) {
  mid  <- spec$model_id
  fmod <- lisa_fitted_models[[mid]]
  
  if (is.null(fmod) || is.null(fmod$fit)) {
    cat(sprintf("Skipping coefficient extraction for %s\n", mid))
    next
  }
  
  fit <- fmod$fit
  
  if (fmod$use_firth) {
    params    <- coef(fit)
    ci_mat    <- confint(fit)
    pvals     <- fit$prob
    var_names <- names(params)
  } else {
    params    <- coef(fit)
    ci_mat    <- confint.default(fit)
    pvals     <- coef(summary(fit))[, "Pr(>|z|)"]
    var_names <- names(params)
  }
  
  for (i in seq_along(var_names)) {
    vn <- var_names[i]
    if (vn == "(Intercept)") next
    
    orig_var  <- fmod$orig_names[match(vn, fmod$safe_names)]
    if (is.na(orig_var)) orig_var <- vn
    short_var <- trimws(gsub("\\s+", " ", sub(".*__", "", orig_var)))
    
    lisa_coef_rows[[length(lisa_coef_rows) + 1]] <- data.frame(
      model_id       = mid,
      typology       = spec$typology,
      comparison     = paste(spec$target, "vs", spec$ref_label),
      estimator      = fmod$estimator,
      variable       = orig_var,
      variable_short = short_var,
      coef           = round(params[i], 4),
      or             = round(exp(params[i]), 4),
      or_ci_lo       = round(exp(ci_mat[i, 1]), 4),
      or_ci_hi       = round(exp(ci_mat[i, 2]), 4),
      p_value        = round(pvals[i], 4),
      significant_05 = pvals[i] < 0.05,
      stringsAsFactors = FALSE
    )
  }
}

df_lisa_coefs <- bind_rows(lisa_coef_rows)

cat("\n")
cat(sprintf("Coefficients extracted: %d rows from %d models\n",
            nrow(df_lisa_coefs), length(lisa_fitted_models)))

if (nrow(df_lisa_coefs) > 0) {
  print(df_lisa_coefs[, c("model_id", "variable_short", "coef", "or",
                          "or_ci_lo", "or_ci_hi", "p_value")])
}

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 6: EXPORT RESULTS
# ══════════════════════════════════════════════════════════════════════════════

OUTPUT_METRICS <- file.path(DEMO_DERIV, "p5b_lisa_model_metrics.csv")
OUTPUT_COEFS   <- file.path(DEMO_DERIV, "p5b_lisa_model_coefficients.csv")

write_delim(df_lisa_metrics, OUTPUT_METRICS, delim = ";")
write_delim(df_lisa_coefs,   OUTPUT_COEFS,   delim = ";")

cat("\n")
cat(sprintf("Exported:\n"))
cat(sprintf("  • %s  (%d rows)\n", basename(OUTPUT_METRICS), nrow(df_lisa_metrics)))
cat(sprintf("  • %s  (%d rows)\n", basename(OUTPUT_COEFS), nrow(df_lisa_coefs)))

cat("\n")
cat(strrep("=", 80))
cat("\nLISA MODELS COMPLETE\n")
cat(strrep("=", 80))
cat("\n")

