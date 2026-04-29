# ══════════════════════════════════════════════════════════════════════════════
# PAPER 1 — PASO 5B: LOGISTIC REGRESSION MODELS
# ══════════════════════════════════════════════════════════════════════════════
# Rural demographic groups: explanatory modelling
# Models: Reverter vs. Decline, Dynamiser vs. Decline × Rural-Remote/Accessible
# Variable selection: stepwise AIC + post-hoc collinearity pruning
# Estimators: MLE (glm) or Firth penalised logistic (logistf) when needed
# ══════════════════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 0: SETUP
# ══════════════════════════════════════════════════════════════════════════════

library(MASS)          # stepAIC
library(logistf)       # Firth penalised logistic regression
library(randomForest)  # Random Forest
library(pROC)          # ROC / AUC
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)

cat("Packages loaded.\n")

# ── 0.1 Paths ─────────────────────────────────────────────────────────────────
ROOT       <- file.path("C:/Users/juanz/OneDrive/Desktop/UCM/RURIM ESCAPE",
                        "GeoSpatial/01_Python Data Analysis",
                        "rural-migration-land-use-spain")
DEMO_DERIV <- file.path(ROOT, "data/demography/derived/paper1")
FIG_DIR    <- file.path(ROOT, "figures/p5b_explanatory_modelling")
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)

INPUT_DATA   <- file.path(DEMO_DERIV, "p5a_rural_analysis_dataset.csv")
INPUT_SELVAR <- file.path(DEMO_DERIV, "p5a_selected_variables.csv")

for (p in c(INPUT_DATA, INPUT_SELVAR)) {
  cat(ifelse(file.exists(p), "  ok  ", "  MISSING  "), basename(p), "\n")
}

# ── 0.2 Constants ─────────────────────────────────────────────────────────────
RURAL_REMOTE     <- "Rural - Remoto"
RURAL_ACCESSIBLE <- "Rural - Accesible"

# Models requiring Firth penalisation (quasi-complete separation)
FIRTH_MODELS <- c("M2", "M4")

# Collinearity threshold
COLLINEARITY_THRESHOLD <- 0.70

# Variables suppressed by INE for small municipalities
SUPPRESSED_VARS <- c(
  "ECONOMIA__RENTAS__Renta neta media por persona",
  "ECONOMIA__RENTAS__Renta neta media por hogar",
  "ECONOMIA__RENTAS__DESIGUALDAD__Indice de Gini (%)",
  "ECONOMIA__RENTAS__DESIGUALDAD__Distribucion de la renta P80/P20"
)

# Collinear variables to drop per model (identified post-hoc from retained
# variable Spearman correlation matrix — see Section 4 comments for rationale)
COLLINEAR_DROP <- list(
  M1 = c(
    # Hogares unipersonales: same household-size dimension as Tamaño medio,
    # entered later with smaller delta
    "VIVIENDA__HOGAR__Hogares unipersonales \n(% s/ total)",
    # P80/P20: Gini is more standard in inequality literature, entered earlier
    "ECONOMIA__RENTAS__DESIGUALDAD__Distribucion de la renta P80/P20",
    # Total Empresas: composite size indicator overlapping with service variables
    "ECONOMIA__EMPRESAS__Total Empresas"
  ),
  M2 = c(
    # Renta por hogar: per-capita income more comparable across household sizes
    # ALSO highly collinear with per-capita in small samples
    "ECONOMIA__RENTAS__Renta neta media por hogar",
    "ECONOMIA__EMPRESAS__Total Empresas"
  ),
  M3 = c(
    "VIVIENDA__HOGAR__Hogares unipersonales \n(% s/ total)",
    "ECONOMIA__RENTAS__Renta neta media por hogar",
    "ECONOMIA__EMPRESAS__Total Empresas"
  ),
  M4 = c(
    "VIVIENDA__HOGAR__Hogares unipersonales \n(% s/ total)",
    "ECONOMIA__RENTAS__Renta neta media por hogar",
    # Densidad: retained Total Empresas correlation resolved by dropping Empresas;
    # Densidad itself correlates with Empresas so also dropped
    "MEDIO FISICO__Densidad (hab/km2)",
    "ECONOMIA__EMPRESAS__Total Empresas",
    # Viviendas no principales: second-residence dimension already in Plazas turisticas
    "VIVIENDA__TIPOS DE VIVIENDAS (familiares)__Viviendas no principales (% s/ total)"
  )
)

# English labels for figures
VAR_LABELS_EN <- c(
  "Renta neta media por persona"                                        = "Net income per capita (EUR)",
  "Renta neta media por hogar"                                          = "Net household income (EUR)",
  "Indice de Gini (%)"                                                  = "Gini index (%)",
  "Distribucion de la renta P80/P20"                                    = "Income ratio P80/P20",
  "Tasa de paro"                                                        = "Unemployment rate (%)",
  "Afiliados Regimen Especial (R. E.) T. Autonomos (% s/ Total)"       = "Self-employed affiliates (%)",
  "Contratos indefinidos (% s/ Total)"                                  = "Permanent contracts (%)",
  "Total Empresas"                                                      = "Total firms",
  "Pension Contributiva Media"                                          = "Mean contributory pension (EUR)",
  "Porcentaje cobertura >= 100 Mbps (condiciones maxima demanda)"       = "Broadband >=100 Mbps (%)",
  "Consultorio de atencion primaria (numero)"                           = "Primary care centres (n)",
  "Oficina de farmacia (numero)"                                        = "Pharmacies (n)",
  "No centros de Educacion Primaria"                                    = "Primary schools (n)",
  "Tiempo municipio 5.000 hab. o mas, mas cercano (minutos)"           = "Time to 5,000-hab. town (min)",
  "Tiempo municipio 20.000 hab. o mas, mas cercano (minutos)"          = "Time to 20,000-hab. town (min)",
  "Sucursal bancaria (numero)"                                          = "Bank branches (n)",
  "Parque de vehiculos x c/ 100 hab."                                  = "Vehicles per 100 inhab.",
  "Viviendas no principales (% s/ total)"                              = "Non-primary dwellings (%)",
  "Tamano medio del hogar"                                              = "Mean household size",
  "Hogares unipersonales (% s/ total)"                                 = "Single-person households (%)",
  "Plazas turisticas x c/ 100 hab."                                    = "Tourist beds per 100 inhab.",
  "Altitud capital (m)"                                                 = "Elevation (m)",
  "Densidad (hab/km2)"                                                  = "Population density (inhab/km2)",
  "Superficie (km2)"                                                    = "Municipal area (km2)",
  "Superficie forestal (% s/ total)"                                    = "Forest cover (%)",
  "Superficie protegida (% s/ total)"                                   = "Protected area (%)"
)

get_label <- function(var_full) {
  # Extract short name after last __ and collapse whitespace
  short <- trimws(gsub("\\s+", " ", sub(".*__", "", var_full)))
  lbl   <- VAR_LABELS_EN[short]
  if (!is.na(lbl)) lbl else short
}

# Model colours
MODEL_COLORS <- c(reverter = "#fdae61", dynamiser = "#d7191c")
FONTSIZE     <- 11

cat("Constants defined.\n")

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1: LOAD DATA
# ══════════════════════════════════════════════════════════════════════════════

# ── 1.1 Load data ─────────────────────────────────────────────────────────────
df <- read_delim(INPUT_DATA, delim = ";", locale = locale(encoding = "UTF-8"),
                 col_types = cols(Mun_Code = col_character()),
                 show_col_types = FALSE)
df$Mun_Code <- formatC(as.integer(df$Mun_Code), width = 5, flag = "0")

cat(sprintf("Loaded: %d municipalities, %d columns\n", nrow(df), ncol(df)))
cat("\nTypology x behavioural group breakdown:\n")
print(table(df$tipo_goerlich, df$behavioural_group))

# ── 1.2 Load selected variables from p5a ──────────────────────────────────────
df_selvar     <- read_delim(INPUT_SELVAR, delim = ";",
                            locale = locale(encoding = "UTF-8"),
                            show_col_types = FALSE)
SELECTED_VARS <- df_selvar$variable[df_selvar$selected == TRUE]
cat(sprintf("\nSelected variables: %d\n", length(SELECTED_VARS)))

# ── 1.3 Missing values audit ──────────────────────────────────────────────────
cat("\nMissing values in selected variables:\n")
cat(sprintf("%-68s %8s %12s\n", "Variable", "Remote", "Accessible"))
cat(strrep("-", 92), "\n")
for (var in SELECTED_VARS) {
  if (!var %in% names(df)) next
  na_rr <- sum(is.na(df[df$tipo_goerlich == RURAL_REMOTE,    var]))
  na_ra <- sum(is.na(df[df$tipo_goerlich == RURAL_ACCESSIBLE, var]))
  if (na_rr > 0 | na_ra > 0) {
    short <- substr(sub(".*__", "", var), 1, 66)
    cat(sprintf("%-68s %8d %12d\n", short, na_rr, na_ra))
  }
}

# ── 1.4 Impute suppressed values ──────────────────────────────────────────────
df_imp        <- df
imputation_log <- list()

for (var in SUPPRESSED_VARS) {
  # Match against actual column names (accents may differ)
  matched <- grep(sub(".*__", "", var), names(df_imp), value = TRUE, fixed = FALSE)
  if (length(matched) == 0) {
    cat(sprintf("  WARNING: %s not found — skipped\n", var)); next
  }
  col <- matched[1]
  
  n_before  <- sum(is.na(df_imp[[col]]))
  
  # Primary: size_group x typology cell median
  df_imp <- df_imp %>%
    group_by(size_group, tipo_goerlich) %>%
    mutate(!!col := ifelse(is.na(.data[[col]]),
                           median(.data[[col]], na.rm = TRUE),
                           .data[[col]])) %>%
    ungroup()
  
  # Fallback: typology-level median
  df_imp <- df_imp %>%
    group_by(tipo_goerlich) %>%
    mutate(!!col := ifelse(is.na(.data[[col]]),
                           median(.data[[col]], na.rm = TRUE),
                           .data[[col]])) %>%
    ungroup()
  
  n_after   <- sum(is.na(df_imp[[col]]))
  n_imputed <- n_before - n_after
  
  imputation_log[[col]] <- data.frame(
    variable         = col,
    n_missing_before = n_before,
    n_imputed        = n_imputed,
    n_missing_after  = n_after,
    method           = "median(size_group x typology) + fallback: median(typology)"
  )
  
  cat(sprintf("  %-60s  before:%5d  imputed:%5d  remaining:%3d\n",
              substr(col, 1, 58), n_before, n_imputed, n_after))
}

df_imputation_log <- bind_rows(imputation_log)
cat("Imputation complete.\n")

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2: MODEL SETUP
# ══════════════════════════════════════════════════════════════════════════════

# ── 2.1 Response flags ────────────────────────────────────────────────────────
df_imp$is_reverter  <- as.integer(df_imp$behavioural_group == "Reverses in B")
df_imp$is_dynamiser <- as.integer(df_imp$behavioural_group == "Grows in both")

# ── 2.2 Model specifications ──────────────────────────────────────────────────
MODEL_SPECS <- list(
  list(model_id = "M1", typology = RURAL_REMOTE,     response = "is_reverter",
       target = "Reverses in B"),
  list(model_id = "M2", typology = RURAL_REMOTE,     response = "is_dynamiser",
       target = "Grows in both"),
  list(model_id = "M3", typology = RURAL_ACCESSIBLE, response = "is_reverter",
       target = "Reverses in B"),
  list(model_id = "M4", typology = RURAL_ACCESSIBLE, response = "is_dynamiser",
       target = "Grows in both")
)

# ── 2.3 Build standardised subsets ────────────────────────────────────────────
model_data <- list()

for (spec in MODEL_SPECS) {
  mid      <- spec$model_id
  typology <- spec$typology
  response <- spec$response
  target   <- spec$target
  
  # Subset: target group + structural decline, correct typology
  subset <- df_imp[
    df_imp$tipo_goerlich == typology &
      df_imp$behavioural_group %in% c(target, "Structural depopulation"), ]
  
  # Keep only selected vars present in subset
  avail_vars <- SELECTED_VARS[SELECTED_VARS %in% names(subset)]
  
  # Drop rows with remaining NA
  n_before  <- nrow(subset)
  subset    <- subset[complete.cases(subset[, avail_vars]), ]
  n_dropped <- n_before - nrow(subset)
  
  # Standardise predictors on this subset
  X_raw <- as.matrix(subset[, avail_vars])
  means <- colMeans(X_raw, na.rm = TRUE)
  sds   <- apply(X_raw, 2, sd, na.rm = TRUE)
  sds[sds == 0] <- 1  # avoid division by zero
  X_std <- scale(X_raw, center = means, scale = sds)
  df_std <- as.data.frame(X_std)
  
  y         <- subset[[response]]
  n_target  <- sum(subset$behavioural_group == target)
  n_ref     <- sum(subset$behavioural_group == "Structural depopulation")
  
  model_data[[mid]] <- list(
    spec           = spec,
    subset         = subset,
    X              = df_std,
    y              = y,
    means          = means,
    sds            = sds,
    avail_vars     = avail_vars,
    n_target       = n_target,
    n_reference    = n_ref,
    n_total        = nrow(subset),
    n_dropped      = n_dropped
  )
  
  typology_short   <- ifelse(typology == RURAL_REMOTE, "Remote", "Accessible")
  comparison_short <- ifelse(response == "is_reverter", "Reverter", "Dynamiser")
  cat(sprintf("%s  %-18s  target: %-20s  n_target=%5d  n_ref=%5d  n_total=%5d  n_dropped=%d\n",
              mid, typology, target, n_target, n_ref, nrow(subset), n_dropped))
}

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3: STEPWISE VARIABLE SELECTION (AIC)
# ══════════════════════════════════════════════════════════════════════════════

aicc <- function(loglik, k, n) {
  # Corrected AIC — Hurvich & Tsai (1989)
  aic <- -2 * loglik + 2 * k
  if (n - k - 1 <= 0) return(aic)
  aic + (2 * k^2 + 2 * k) / (n - k - 1)
}

selection_results <- list()

for (spec in MODEL_SPECS) {
  mid            <- spec$model_id
  mdata          <- model_data[[mid]]
  typology_short <- ifelse(spec$typology == RURAL_REMOTE, "Remote", "Accessible")
  response_short <- ifelse(spec$response == "is_reverter", "Reverter", "Dynamiser")
  
  cat(sprintf("\n%s\n", strrep("=", 75)))
  cat(sprintf("  %s — %s vs. Structural decline  |  %s\n",
              mid, response_short, typology_short))
  cat(sprintf("  n_target=%d  n_reference=%d  n_total=%d\n",
              mdata$n_target, mdata$n_reference, mdata$n_total))
  cat(sprintf("%s\n", strrep("=", 75)))
  
  # Build data frame for modelling
  df_model      <- mdata$X
  df_model$y    <- mdata$y
  
  # Sanitise column names for R formula (replace special chars)
  safe_names <- make.names(mdata$avail_vars)
  names(df_model)[names(df_model) %in% mdata$avail_vars] <- safe_names[
    match(names(df_model)[names(df_model) %in% mdata$avail_vars], mdata$avail_vars)
  ]
  predictor_cols <- names(df_model)[names(df_model) != "y"]
  
  # Null model (intercept only)
  null_formula <- as.formula("y ~ 1")
  null_model   <- glm(null_formula, data = df_model, family = binomial)
  
  # Full model (all predictors)
  full_formula <- as.formula(paste("y ~", paste(predictor_cols, collapse = " + ")))
  full_model   <- glm(full_formula, data = df_model, family = binomial,
                      control = glm.control(maxit = 200))
  
  # Bidirectional stepwise AIC
  step_model <- stepAIC(null_model,
                        scope = list(lower = null_formula, upper = full_formula),
                        direction = "both",
                        trace = 1,
                        k = 2)   # k=2 -> AIC; k=log(n) -> BIC
  
  selected_safe  <- names(coef(step_model))[-1]  # exclude intercept
  # Map back to original variable names
  selected_orig  <- mdata$avail_vars[match(selected_safe,
                                           make.names(mdata$avail_vars))]
  
  # AICc for final stepwise model
  n_obs  <- mdata$n_total
  k_fin  <- length(selected_safe) + 1
  aicc_val <- aicc(logLik(step_model)[1], k_fin, n_obs)
  ratio    <- n_obs / k_fin
  crit_name <- ifelse(ratio < 40, "AICc", "AIC")
  crit_val  <- ifelse(ratio < 40, aicc_val, AIC(step_model))
  
  selection_results[[mid]] <- list(
    selected_safe = selected_safe,
    selected_orig = selected_orig,
    step_model    = step_model,
    aic           = AIC(step_model),
    aicc          = aicc_val,
    crit_name     = crit_name,
    crit_val      = crit_val,
    safe_names    = safe_names,
    orig_names    = mdata$avail_vars,
    df_model      = df_model,
    predictor_cols = predictor_cols
  )
  
  cat(sprintf("\n  -> Final model: %d predictors retained\n", length(selected_safe)))
  cat(sprintf("  -> %s = %.4f\n", crit_name, crit_val))
}

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4: FIT FINAL MODELS (POST-COLLINEARITY PRUNING)
# ══════════════════════════════════════════════════════════════════════════════

fitted_models <- list()
metrics_rows  <- list()

for (spec in MODEL_SPECS) {
  mid            <- spec$model_id
  mdata          <- model_data[[mid]]
  selres         <- selection_results[[mid]]
  typology_short <- ifelse(spec$typology == RURAL_REMOTE, "Remote", "Accessible")
  response_short <- ifelse(spec$response == "is_reverter", "Reverter", "Dynamiser")
  
  df_model      <- selres$df_model
  safe_names    <- selres$safe_names
  orig_names    <- selres$orig_names
  
  # Step 1: variables from stepwise (safe names)
  selected_safe <- selres$selected_safe
  
  # Step 2: drop collinear variables
  drop_orig <- COLLINEAR_DROP[[mid]]
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
  
  # Step 3: prepare data for fitting
  df_fit <- as.data.frame(lapply(
    df_model[, c(selected_safe, "y"), drop = FALSE],
    function(x) if (is.matrix(x)) as.vector(x) else x
  ))
  
  # Sanitise column names for logistf compatibility
  clean_names <- make.names(names(df_fit), unique = TRUE)
  names(df_fit) <- clean_names
  selected_clean <- head(clean_names, -1)  # all except "y"
  formula_fit <- as.formula(paste("y ~", paste(selected_clean, collapse = " + ")))
  use_firth <- mid %in% FIRTH_MODELS
  
  # ═══════════════════════════════════════════════════════════════════════════
  # DIAGNOSTIC BLOCK FOR FIRTH MODELS — COMMENTED OUT TO AVOID ERRORS
  # ═══════════════════════════════════════════════════════════════════════════
  # if (use_firth) {
  #   cat(sprintf("\n=== %s: Checking for separation issues ===\n", mid))
  #   
  #   # Check 1: Perfect separation per predictor (usando índices numéricos)
  #   for (j in seq_along(selected_clean)) {
  #     vname <- selected_clean[j]
  #     cross_tab <- table(df_fit[[j]] > median(df_fit[[j]]), df_fit$y)
  #     if (any(cross_tab == 0)) {
  #       cat(sprintf("  WARNING: Variable %d (%s) has zero cell in crosstab\n", j, vname))
  #     }
  #   }
  #   
  #   # Check 2: Variance check (usando matriz numérica)
  #   var_vals <- apply(df_fit[selected_clean], 2, var)
  #   if (any(var_vals < 1e-10, na.rm = TRUE)) {
  #     low_var_idx <- which(var_vals < 1e-10)
  #     cat(sprintf("  WARNING: Near-zero variance in variable(s): %s\n",
  #                 paste(low_var_idx, collapse=", ")))
  #   }
  #   
  #   # Check 3: Correlation matrix
  #   if (length(selected_clean) >= 2) {
  #     # Forzar conversión a matriz numérica para evitar problemas con nombres
  #     mat_numeric <- as.matrix(df_fit[selected_clean])
  #     cor_mat <- cor(mat_numeric, use = "complete.obs")
  #     diag(cor_mat) <- 0
  #     high_cor <- which(abs(cor_mat) > 0.85, arr.ind = TRUE)
  #     if (nrow(high_cor) > 0) {
  #       # Eliminar duplicados (solo mostrar i < j)
  #       high_cor <- high_cor[high_cor[,1] < high_cor[,2], , drop = FALSE]
  #       if (nrow(high_cor) > 0) {
  #         for (i in 1:nrow(high_cor)) {
  #           cat(sprintf("  WARNING: High correlation (%.3f) between var %d (%s) and var %d (%s)\n",
  #                       cor_mat[high_cor[i,1], high_cor[i,2]],
  #                       high_cor[i,1], selected_clean[high_cor[i,1]],
  #                       high_cor[i,2], selected_clean[high_cor[i,2]]))
  #         }
  #       }
  #     }
  #   }
  # }
  # ═══════════════════════════════════════════════════════════════════════════
  
  # Fit with error handling
  if (use_firth) {
    fit <- tryCatch({
      logistf(formula_fit, data = df_fit,
              control = logistf.control(maxit = 200, maxstep = 5),
              plconf = 0.95)
    }, error = function(e) {
      cat(sprintf("  ERROR in logistf for %s: %s\n", mid, e$message))
      cat("  Attempting fallback to standard glm...\n")
      glm(formula_fit, data = df_fit, family = binomial,
          control = glm.control(maxit = 200))
    })
    
    # Check if we got a proper logistf object
    if (inherits(fit, "logistf")) {
      estimator <- "Firth (logistf)"
    } else {
      estimator <- "MLE (glm) [Firth failed]"
      use_firth <- FALSE  # Switch flag for downstream code
    }
  } else {
    fit <- glm(formula_fit, data = df_fit, family = binomial,
               control = glm.control(maxit = 200))
    estimator <- "MLE (glm)"
  }
  
  # Step 4: evaluation metrics
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
  
  # AUC
  roc_obj <- roc(df_fit$y, y_pred_prob, quiet = TRUE)
  auc_val <- as.numeric(auc(roc_obj))
  
  # Extreme probability check
  n_extreme   <- sum(y_pred_prob < 0.01 | y_pred_prob > 0.99)
  pct_extreme <- n_extreme / mdata$n_total * 100
  
  # Max retained Spearman rho
  if (length(selected_safe) >= 2) {
    corr_mat <- cor(df_model[, selected_safe], method = "spearman")
    diag(corr_mat) <- 0
    max_rho <- max(abs(corr_mat))
  } else {
    max_rho <- NA_real_
  }
  
  # AICc
  n_obs     <- mdata$n_total
  aicc_val  <- aicc(llf, k_final, n_obs)
  ratio     <- n_obs / k_final
  crit_name <- ifelse(ratio < 40, "AICc", "AIC")
  crit_val  <- ifelse(ratio < 40, aicc_val, aic_val)
  
  # Map safe names back to original
  selected_orig <- orig_names[match(selected_safe, safe_names)]
  
  fitted_models[[mid]] <- list(
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
  
  metrics_rows[[mid]] <- data.frame(
    model_id                  = mid,
    typology                  = spec$typology,
    comparison                = sub("is_", "", spec$response),
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
  
  cat(sprintf("%s (%s, %s)  [%s]:  %s=%.4f  McFadden R2=%.4f  AUC=%.4f  n_pred=%d  max_rho=%.3f\n",
              mid, response_short, typology_short, estimator,
              crit_name, crit_val, mcfadden_r2, auc_val,
              length(selected_safe), ifelse(is.na(max_rho), 0, max_rho)))
}

df_metrics <- bind_rows(metrics_rows)
cat("\nModel metrics computed.\n")
print(df_metrics[, c("model_id", "estimator", "n_total", "n_predictors",
                     "mcfadden_r2", "auc", "max_retained_spearman_rho")])

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5: EXTRACT COEFFICIENTS
# ══════════════════════════════════════════════════════════════════════════════

coef_rows <- list()

for (spec in MODEL_SPECS) {
  mid   <- spec$model_id
  fmod  <- fitted_models[[mid]]
  
  # Skip if model fitting failed
  if (is.null(fmod) || is.null(fmod$fit)) {
    cat(sprintf("Skipping coefficient extraction for %s (model fit failed)\n", mid))
    next
  }
  
  fit   <- fmod$fit
  
  if (fmod$use_firth) {
    # logistf: coef, CI, p-values stored directly
    params    <- coef(fit)
    ci_mat    <- confint(fit)       # profile likelihood CI
    pvals     <- fit$prob
    var_names <- names(params)
  } else {
    params    <- coef(fit)
    ci_mat    <- confint.default(fit)  # Wald CI
    pvals     <- coef(summary(fit))[, "Pr(>|z|)"]
    var_names <- names(params)
  }
  
  for (i in seq_along(var_names)) {
    vn <- var_names[i]
    if (vn == "(Intercept)") next
    
    # Map safe name back to original
    orig_var  <- fmod$orig_names[match(vn, fmod$safe_names)]
    if (is.na(orig_var)) orig_var <- vn
    short_var <- trimws(gsub("\\s+", " ", sub(".*__", "", orig_var)))
    
    coef_rows[[length(coef_rows) + 1]] <- data.frame(
      model_id       = mid,
      typology       = spec$typology,
      comparison     = sub("is_", "", spec$response),
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

df_coefs <- bind_rows(coef_rows)
cat(sprintf("\nCoefficients extracted: %d rows (%d models)\n",
            nrow(df_coefs), length(fitted_models)))

if (nrow(df_coefs) > 0) {
  print(df_coefs[, c("model_id", "variable_short", "coef", "or",
                     "or_ci_lo", "or_ci_hi", "p_value")])
}

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 6: EXPORT RESULTS
# ══════════════════════════════════════════════════════════════════════════════

OUTPUT_METRICS <- file.path(DEMO_DERIV, "p5b_model_metrics.csv")
OUTPUT_COEFS   <- file.path(DEMO_DERIV, "p5b_model_coefficients.csv")

write_delim(df_metrics, OUTPUT_METRICS, delim = ";")
write_delim(df_coefs,   OUTPUT_COEFS,   delim = ";")

cat(sprintf("\nExported:\n"))
cat(sprintf("  • %s  (%d rows)\n", basename(OUTPUT_METRICS), nrow(df_metrics)))
cat(sprintf("  • %s  (%d rows)\n", basename(OUTPUT_COEFS), nrow(df_coefs)))

cat("\n=== Script completed ===\n")

# ══════════════════════════════════════════════════════════════════════════════
