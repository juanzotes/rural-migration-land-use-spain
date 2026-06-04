# ══════════════════════════════════════════════════════════════════════════════
# PAPER 1 — PASO 5B: LOGISTIC REGRESSION MODELS  [CORRECTED VERSION]
# ══════════════════════════════════════════════════════════════════════════════

library(MASS)
library(logistf)
library(randomForest)
library(pROC)
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

FIRTH_MODELS <- c("M2", "M4")
COLLINEARITY_THRESHOLD <- 0.70

SUPPRESSED_VARS <- c(
  "ECONOMIA__RENTAS__Renta neta media por persona",
  "ECONOMIA__RENTAS__Renta neta media por hogar",
  "ECONOMIA__RENTAS__DESIGUALDAD__Indice de Gini (%)",
  "ECONOMIA__RENTAS__DESIGUALDAD__Distribucion de la renta P80/P20"
)

# ── 0.3 COLLINEAR_DROP (expanded) ─────────────────────────────────────────────
# Rationale for additions vs. v1:
#
# DEMOGRAPHIC REDUNDANCY CLUSTERS (all models):
#   • Edad.media / Indice.envejecimiento / Pct_65_plus / Pct_Mujeres_65_plus
#     form a near-perfect cluster. Rule: keep Indice.envejecimiento (most
#     discriminating in stepwise); drop Edad.media + Pct_65_plus + Pct_Mujeres_65_plus
#     EXCEPTION: M1 retains Pct_Mujeres_65_plus (entered first in stepwise, Edad.media
#     adds independently — keep both, drop Pct_65_plus only)
#   • Pct_0_14 / Pct_Mujeres_0_14 / Pct_Hombres_0_14: keep total (Pct_0_14),
#     drop sex-disaggregated
#   • Pct_30_64 / Pct_Mujeres_30_64 / Pct_Hombres_30_64: keep Pct_Mujeres_30_64
#     (better signal in M2, M4), drop total and male
#
# INCOME REDUNDANCY:
#   • Renta.per.persona and Renta.hogar: ρ typically 0.85-0.95.
#     In M1 both enter with opposite signs (income vs. household income proxy
#     for household size effect) — retain both for M1.
#     In M2/M3/M4 drop Renta.hogar (stepwise already attempted this but rho stays
#     high due to remaining age + income correlations).
#
# M2/M4 SPECIFIC (Firth models — small positive class, need parsimony):
#   • Drop Mujeres (% total): aliased with demographic structure
#   • Drop Parque.vehiculos (p=0.43 in M2 final)
#   • Drop Hogares.unipersonales (high rho with Tamano.hogar, ρ > 0.80)
#   • Drop Superficie.km2 (p=0.45 in M4)
#   • Drop Centros.Infantil (p=0.22 in M4)

COLLINEAR_DROP <- list(
  
  M1 = c(
    # Age structure: keep Pct_Mujeres_65_plus + Edad.media (both significant),
    # drop Pct_65_plus (redundant with Pct_Mujeres_65_plus)
    "DEMOGRAFIA__Pct_65_plus",
    "DEMOGRAFIA__Pct_30_64",
    # Sex-disaggregated age: drop all male sub-vars, keep female/total
    "DEMOGRAFIA__Pct_Hombres_0_14",
    "DEMOGRAFIA__Pct_Hombres_15_29",
    "DEMOGRAFIA__Pct_Hombres_30_64",
    "DEMOGRAFIA__Pct_Hombres_65_plus",
    # Income: keep both (they interact meaningfully in M1)
    # Service counts: keep only number variants, not SI/NO
    "ECONOMIA__EMPRESAS__Total Empresas",
    "ECONOMIA__RENTAS__Renta neta media por persona"
  ),
  
  M2 = c(
    # Age: keep Indice.envejecimiento (best discriminator for dynamisers),
    # drop all individual age-group pcts except Pct_Mujeres_0_14 (strongest)
    "DEMOGRAFIA__Pct_65_plus",
    "DEMOGRAFIA__Pct_Mujeres_65_plus",
    "DEMOGRAFIA__Pct_30_64",
    "DEMOGRAFIA__Pct_0_14",
    "DEMOGRAFIA__Pct_Mujeres_0_14",
    "DEMOGRAFIA__Pct_Hombres_0_14",
    "DEMOGRAFIA__Pct_Hombres_15_29",
    "DEMOGRAFIA__Pct_Hombres_30_64",
    "DEMOGRAFIA__Pct_Hombres_65_plus",
    "DEMOGRAFIA__RATIOS__Índice envejecimiento\n(%)",
    "DEMOGRAFIA__POBLACIÓN POR SEXO__Mujeres \n(% hab. s/ total)",
    # Income: keep Renta.per.persona (cleaner for small class), drop hogar
    "ECONOMIA__RENTAS__Renta neta media por hogar",
    # Housing: Hogares.unipersonales correlates with Tamano.hogar (ρ ≈ 0.82)
    "VIVIENDA__HOGAR__Hogares unipersonales \n(% s/ total)",
    # Firms (count variable, noisy for small positive class)
    "ECONOMIA__EMPRESAS__Total Empresas",
    # Non-significant predictors from previous run (p > 0.40)
    "SERVICIOS__TRANSPORTE__Parque de vehículos x c/ 100 hab.",  # p=0.43
    # Sex ratio: aliased with demographic structure vars
    "DEMOGRAFIA__POBLACIÓN POR SEXO__Mujeres (% hab. s/ total)"  # ← NEW
  ),
  
  M3 = c(
    # Age: drop male sub-vars + total 65 (redundant with female 65 + Ind.env.)
    "DEMOGRAFIA__Pct_65_plus",
    "DEMOGRAFIA__Pct_30_64",
    "DEMOGRAFIA__Pct_Hombres_0_14",
    "DEMOGRAFIA__Pct_Hombres_15_29",
    "DEMOGRAFIA__Pct_Hombres_30_64",
    "DEMOGRAFIA__Pct_Hombres_65_plus",
    "DEMOGRAFIA__RATIOS__Índice envejecimiento\n(%)",
    # Income: in M3 stepwise shows Renta.per.persona >> Renta.hogar; keep both
    # but drop hogar to reduce rho (ρ = 0.977 is too high)
    "ECONOMIA__RENTAS__Renta neta media por hogar",        # ← NEW
    # Housing: drop unipersonales (ρ with Tamano.hogar)
    "VIVIENDA__HOGAR__Hogares unipersonales \n(% s/ total)",  # ← NEW
    # Firms: count, noisy
    "ECONOMIA__EMPRESAS__Total Empresas",                  # ← NEW
    # Non-significant (p > 0.20 in previous run)
    "SERVICIOS__DISTANCIAS A LOS SERVICIOS MÁS CERCANOS__Tiempo municipio 5.000 hab. o más, más cercano (minutos)",  # p=0.228 in M3 final
    "ECONOMIA__RENTAS__DESIGUALDAD__Distribución de la renta P80/P20"  # p=0.899 ← NEW
  ),
  
  M4 = c(
    # Age: keep Indice.envejecimiento + Edad.media (both critical for M4);
    # drop all individual pct groups
    "DEMOGRAFIA__Pct_65_plus",
    "DEMOGRAFIA__Pct_Mujeres_65_plus",
    "DEMOGRAFIA__Pct_30_64",
    "DEMOGRAFIA__Pct_Mujeres_30_64",
    "DEMOGRAFIA__Pct_Hombres_0_14",
    "DEMOGRAFIA__Pct_Hombres_15_29",
    "DEMOGRAFIA__Pct_Hombres_30_64",
    "DEMOGRAFIA__Pct_Hombres_65_plus",
    "DEMOGRAFIA__RATIOS__Índice envejecimiento\n(%)",
    # Income: keep per.persona only (ρ with hogar > 0.85)
    "ECONOMIA__RENTAS__Renta neta media por hogar",        # ← NEW
    # Housing
    "VIVIENDA__HOGAR__Hogares unipersonales \n(% s/ total)",
    "MEDIO FISICO__Densidad (hab/km2)",                   # keep Superficie instead
    # Non-significant (p > 0.22 in previous run)
    "VIVIENDA__TIPOS DE VIVIENDAS (familiares)__Viviendas no principales (% s/ total)",
    "ECONOMIA__EMPRESAS__Total Empresas",
    "SERVICIOS__CENTROS DE EDUCACIÓN__Nº centros de Educación Infantil Segundo Ciclo",  # p=0.22
    "MEDIO FISICO__Superficie (km2)"                       # p=0.45 ← NEW
  )
)

# ── 0.4 English labels (unchanged) ────────────────────────────────────────────
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
  "Tamano medio del hogar"                                             = "Mean household size",
  "Hogares unipersonales (% s/ total)"                                 = "Single-person households (%)",
  "Plazas turisticas x c/ 100 hab."                                    = "Tourist beds per 100 inhab.",
  "Altitud capital (m)"                                                 = "Elevation (m)",
  "Densidad (hab/km2)"                                                  = "Population density (inhab/km2)",
  "Superficie (km2)"                                                    = "Municipal area (km2)",
  "Superficie forestal (% s/ total)"                                    = "Forest cover (%)",
  "Superficie protegida (% s/ total)"                                   = "Protected area (%)",
  "Poblacion Nacionalidad Extranjera (% hab. s/ total)" = "Foreign nationals (% total population)",
  "Pct_0_14"            = "Children 0-14 years (%)",
  "Pct_15_29"           = "Youth 15-29 years (%)",
  "Pct_30_64"           = "Adults 30-64 years (%)",
  "Pct_65_plus"         = "Seniors >=65 years (%)",
  "Pct_Mujeres_0_14"    = "Women 0-14 years (%)",
  "Pct_Hombres_0_14"    = "Men 0-14 years (%)",
  "Pct_Mujeres_15_29"   = "Women 15-29 years (%)",
  "Pct_Hombres_15_29"   = "Men 15-29 years (%)",
  "Pct_Mujeres_30_64"   = "Women 30-64 years (%)",
  "Pct_Hombres_30_64"   = "Men 30-64 years (%)",
  "Pct_Mujeres_65_plus" = "Women >=65 years (%)",
  "Pct_Hombres_65_plus" = "Men >=65 years (%)",
  "Edad media poblacion" = "Mean age (years)",
  "Indice envejecimiento (%)" = "Aging index (%)",
  "Tasa dependencia (%)" = "Dependency ratio (%)",
  "Mujeres (% hab. s/ total)" = "Women (% total population)"
)

get_label <- function(var_full) {
  short <- trimws(gsub("\\s+", " ", sub(".*__", "", var_full)))
  lbl   <- VAR_LABELS_EN[short]
  if (!is.na(lbl)) lbl else short
}

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
# SECTION 4: FIT FINAL MODELS — CORRECTED
# ══════════════════════════════════════════════════════════════════════════════

fitted_models <- list()
metrics_rows  <- list()

for (spec in MODEL_SPECS) {
  mid            <- spec$model_id
  mdata          <- model_data[[mid]]
  selres         <- selection_results[[mid]]
  typology_short <- ifelse(spec$typology == RURAL_REMOTE, "Remote", "Accessible")
  response_short <- ifelse(spec$response == "is_reverter", "Reverter", "Dynamiser")
  
  df_model   <- selres$df_model
  safe_names <- selres$safe_names
  orig_names <- selres$orig_names
  
  selected_safe <- selres$selected_safe
  
  # ── Step 2: drop collinear variables ──────────────────────────────────────
  drop_orig <- COLLINEAR_DROP[[mid]]
  if (is.null(drop_orig)) drop_orig <- character(0)
  
  # Match original names → safe names (partial/fuzzy match to handle encoding)
  drop_safe <- c()
  for (do_orig in drop_orig) {
    # Try exact match first
    idx_exact <- match(do_orig, orig_names)
    if (!is.na(idx_exact)) {
      drop_safe <- c(drop_safe, safe_names[idx_exact])
      next
    }
    # Try substring match (handles accented chars / newlines in original names)
    short_do <- trimws(gsub("\\s+", " ", sub(".*__", "", do_orig)))
    idx_sub  <- which(sapply(orig_names, function(n) {
      grepl(short_do, n, fixed = TRUE) ||
        grepl(gsub("[áéíóúüñ]", ".", short_do), n, perl = FALSE)
    }))
    if (length(idx_sub) > 0) {
      drop_safe <- c(drop_safe, safe_names[idx_sub])
    } else {
      cat(sprintf("  WARN: could not match drop var '%s' for %s\n", do_orig, mid))
    }
  }
  drop_safe <- unique(drop_safe[!is.na(drop_safe)])
  
  pruned_safe  <- selected_safe[!selected_safe %in% drop_safe]
  dropped_safe <- selected_safe[selected_safe %in% drop_safe]
  
  if (length(dropped_safe) > 0) {
    cat(sprintf("%s: pruned %d -> %d  (dropped: %s)\n",
                mid, length(selected_safe), length(pruned_safe),
                paste(dropped_safe, collapse = ", ")))
  }
  selected_safe <- pruned_safe

  # Guard: need at least 1 predictor
  if (length(selected_safe) == 0) {
    cat(sprintf("  ERROR: %s has 0 predictors after pruning. Skipping.\n", mid))
    next
  }
  
  # ── Step 3: prepare fitting data ──────────────────────────────────────────
  df_fit <- df_model[, c(selected_safe, "y"), drop = FALSE]
  df_fit <- as.data.frame(lapply(df_fit,
                                 function(x) if (is.matrix(x)) as.vector(x) else x))
  
  # Para logistf: renombrar columnas a v1, v2, ... (evita chars especiales)
  col_map        <- setNames(paste0("v", seq_along(selected_safe)), selected_safe)
  df_fit_clean   <- df_fit
  names(df_fit_clean) <- c(unname(col_map[selected_safe]), "y")
  selected_clean <- unname(col_map[selected_safe])
  
  use_firth <- mid %in% FIRTH_MODELS
  
  # ── Step 4: separation check + fit ────────────────────────────────────────
  if (use_firth) {
    formula_fit <- as.formula(paste("y ~", paste(selected_clean, collapse = " + ")))
    
    ratio_nk <- mdata$n_total / (length(selected_clean) + 1)
    cat(sprintf("  %s Firth: %d predictors, n/K = %.1f\n",
                mid, length(selected_clean), ratio_nk))
    
    fit <- tryCatch({
      logistf(formula_fit, data = df_fit_clean,
              pl      = FALSE,
              control = logistf.control(maxit = 500, maxstep = 5))
    }, error = function(e) {
      cat(sprintf("  logistf ERROR for %s: %s\n  → fallback to glm\n",
                  mid, e$message))
      glm(formula_fit, data = df_fit_clean, family = binomial,
          control = glm.control(maxit = 200))
    })
    
    estimator <- if (inherits(fit, "logistf")) "Firth (logistf)" else
      "MLE (glm) [Firth fallback]"
    if (!inherits(fit, "logistf")) use_firth <- FALSE
    
  } else {
    selected_clean <- selected_safe
    formula_fit    <- as.formula(paste("y ~",
                                       paste(paste0("`", selected_clean, "`"), collapse = " + ")))
    fit            <- glm(formula_fit, data = df_fit, family = binomial,
                          control = glm.control(maxit = 200))
    estimator      <- "MLE (glm)"
  }
  
  # ── Step 5: evaluation metrics ────────────────────────────────────────────
  if (use_firth) {
    y_pred_prob <- fit$predict
    llf         <- fit$loglik[2]
    null_firth  <- logistf(y ~ 1, data = df_fit_clean, pl = FALSE,
                           control = logistf.control(maxit = 500))
    llf_null    <- null_firth$loglik[2]
    mcfadden_r2 <- 1 - llf / llf_null
    k_final     <- length(selected_clean) + 1
    aic_val     <- -2 * llf + 2 * k_final
  } else {
    y_pred_prob <- fitted(fit)
    llf         <- logLik(fit)[1]
    null_fit    <- glm(y ~ 1, data = df_fit, family = binomial,
                       control = glm.control(maxit = 200))
    llf_null    <- logLik(null_fit)[1]
    mcfadden_r2 <- 1 - llf / llf_null
    k_final     <- length(selected_clean) + 1
    aic_val     <- AIC(fit)
  }
  
  y_obs     <- if (use_firth) fit$y else as.numeric(df_fit$y)
  roc_obj   <- roc(y_obs, y_pred_prob, quiet = TRUE)
  auc_val   <- as.numeric(auc(roc_obj))
  n_extreme <- sum(y_pred_prob < 0.01 | y_pred_prob > 0.99)
  
  if (length(selected_safe) >= 2) {
    corr_mat <- cor(df_model[, selected_safe, drop = FALSE], method = "spearman")
    diag(corr_mat) <- 0
    max_rho <- max(abs(corr_mat))
  } else {
    max_rho <- NA_real_
  }
  
  n_obs     <- mdata$n_total
  aicc_val  <- aic_val + (2 * k_final^2 + 2 * k_final) / max(1, n_obs - k_final - 1)
  ratio_nk  <- n_obs / k_final
  crit_name <- ifelse(ratio_nk < 40, "AICc", "AIC")
  crit_val  <- ifelse(ratio_nk < 40, aicc_val, aic_val)
  
  selected_orig <- orig_names[match(selected_safe, safe_names)]
  
  # Guardar col_map en fitted_models para recuperar nombres en Section 5
  fitted_models[[mid]] <- list(
    fit            = fit,
    selected_safe  = selected_safe,
    selected_orig  = selected_orig,
    selected_clean = selected_clean,
    col_map        = col_map,
    y_pred_prob    = y_pred_prob,
    mcfadden_r2    = mcfadden_r2,
    auc            = auc_val,
    crit_name      = crit_name,
    crit_val       = crit_val,
    aic            = aic_val,
    estimator      = estimator,
    use_firth      = use_firth,
    df_fit         = df_fit,
    df_fit_clean   = df_fit_clean,
    safe_names     = safe_names,
    orig_names     = orig_names,
    roc_obj        = roc_obj
  )
  
  metrics_rows[[mid]] <- data.frame(
    model_id                  = mid,
    typology                  = spec$typology,
    comparison                = sub("is_", "", spec$response),
    estimator                 = estimator,
    n_target                  = mdata$n_target,
    n_reference               = mdata$n_reference,
    n_total                   = mdata$n_total,
    n_predictors              = length(selected_clean),
    criterion_name            = crit_name,
    criterion_value           = round(crit_val, 4),
    mcfadden_r2               = round(mcfadden_r2, 4),
    auc                       = round(auc_val, 4),
    n_extreme_probs           = n_extreme,
    pct_extreme_probs         = round(n_extreme / mdata$n_total * 100, 2),
    max_retained_spearman_rho = round(max_rho, 3),
    stringsAsFactors          = FALSE
  )
  
  cat(sprintf(
    "%s (%s, %s)  [%s]:\n  %s=%.4f  McFadden R2=%.4f  AUC=%.4f  n_pred=%d  max_rho=%.3f\n",
    mid, response_short, typology_short, estimator,
    crit_name, crit_val, mcfadden_r2, auc_val,
    length(selected_clean), ifelse(is.na(max_rho), 0, max_rho)
  ))
}

df_metrics <- bind_rows(metrics_rows)
cat("\nModel metrics computed.\n")
print(df_metrics[, c("model_id", "estimator", "n_predictors",
                     "mcfadden_r2", "auc", "max_retained_spearman_rho")])

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5: EXTRACT COEFFICIENTS — CORRECTED
# Uses fitted_models[[mid]]$selected_clean (post-separation-check names)
# ══════════════════════════════════════════════════════════════════════════════

coef_rows <- list()

for (spec in MODEL_SPECS) {
  mid  <- spec$model_id
  fmod <- fitted_models[[mid]]
  if (is.null(fmod) || is.null(fmod$fit)) next
  
  fit <- fmod$fit
  
  if (fmod$use_firth) {
    params    <- coef(fit)
    ci_lo     <- fit$ci.lower
    ci_hi     <- fit$ci.upper
    pvals     <- fit$prob
    var_names <- names(params)
    # Mapear v1,v2,... → selected_safe → orig_names
    vmap <- setNames(fmod$selected_safe,
                     paste0("v", seq_along(fmod$selected_safe)))
  } else {
    params    <- coef(fit)
    ci_mat    <- confint.default(fit)
    pvals     <- coef(summary(fit))[, "Pr(>|z|)"]
    var_names <- names(params)
    vmap      <- setNames(fmod$selected_safe, fmod$selected_safe)
  }
  
  for (i in seq_along(var_names)) {
    vn <- var_names[i]
    if (vn == "(Intercept)") next
    
    safe_v   <- vmap[vn]
    orig_var <- if (!is.na(safe_v)) {
      fmod$orig_names[match(safe_v, fmod$safe_names)]
    } else vn
    if (is.na(orig_var)) orig_var <- vn
    
    short_var <- trimws(gsub("\\s+", " ", sub(".*__", "", orig_var)))
    
    or_lo <- if (fmod$use_firth) exp(ci_lo[i]) else exp(ci_mat[i, 1])
    or_hi <- if (fmod$use_firth) exp(ci_hi[i]) else exp(ci_mat[i, 2])
    
    coef_rows[[length(coef_rows) + 1]] <- data.frame(
      model_id       = mid,
      typology       = spec$typology,
      comparison     = sub("is_", "", spec$response),
      estimator      = fmod$estimator,
      variable       = orig_var,
      variable_short = short_var,
      variable_label = get_label(orig_var),
      coef           = round(params[i], 4),
      or             = round(exp(params[i]), 4),
      or_ci_lo       = round(or_lo, 4),
      or_ci_hi       = round(or_hi, 4),
      p_value        = round(pvals[i], 4),
      significant_05 = pvals[i] < 0.05,
      significant_10 = pvals[i] < 0.10,
      stringsAsFactors = FALSE
    )
  }
}

df_coefs <- bind_rows(coef_rows)
cat(sprintf("\nCoefficients extracted: %d rows\n", nrow(df_coefs)))

# ══════════════════════════════════════════════════════════════════════════════
# SECTION 6: EXPORT
# ══════════════════════════════════════════════════════════════════════════════

OUTPUT_METRICS <- file.path(DEMO_DERIV, "p5b_model_metrics.csv")
OUTPUT_COEFS   <- file.path(DEMO_DERIV, "p5b_model_coefficients.csv")

write_delim(df_metrics, OUTPUT_METRICS, delim = ";")
write_delim(df_coefs,   OUTPUT_COEFS,   delim = ";")

cat(sprintf("Exported:\n  • %s  (%d rows)\n  • %s  (%d rows)\n",
            basename(OUTPUT_METRICS), nrow(df_metrics),
            basename(OUTPUT_COEFS),   nrow(df_coefs)))

# ── VIF diagnostic (runs only if car package available) ───────────────────────
if (requireNamespace("car", quietly = TRUE)) {
  cat("\n=== VIF diagnostics (final models) ===\n")
  for (mid in names(fitted_models)) {
    fmod <- fitted_models[[mid]]
    if (fmod$use_firth) {
      cat(sprintf("%s — VIF not applicable (Firth estimator)\n", mid))
      next
    }
    if (!inherits(fmod$fit, "glm")) next
    tryCatch({
      vif_vals <- car::vif(fmod$fit)
      high_vif <- vif_vals[vif_vals > 10]
      if (length(high_vif) > 0) {
        cat(sprintf("%s — VIF > 10: %s\n", mid,
                    paste(names(high_vif), round(high_vif, 1), sep = "=", collapse = ", ")))
      } else {
        cat(sprintf("%s — all VIF <= 10 (max = %.2f)\n", mid, max(vif_vals)))
      }
    }, error = function(e) cat(sprintf("%s — VIF error: %s\n", mid, e$message)))
  }
}

cat("\n=== Script completed ===\n")