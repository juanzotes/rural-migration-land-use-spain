# ══════════════════════════════════════════════════════════════════════════════
# PAPER 1 — PASO 5B: SUMMARY TABLES FOR WORD
# ══════════════════════════════════════════════════════════════════════════════

library(dplyr)
library(readr)
library(tidyr)
library(flextable)
library(officer)

# ── Paths ─────────────────────────────────────────────────────────────────────
ROOT       <- file.path("C:/Users/juanz/OneDrive/Desktop/UCM/RURIM ESCAPE",
                        "GeoSpatial/01_Python Data Analysis",
                        "rural-migration-land-use-spain")
DEMO_DERIV <- file.path(ROOT, "data/demography/derived/paper1")

INPUT_METRICS <- file.path(DEMO_DERIV, "p5b_model_metrics.csv")
INPUT_COEFS   <- file.path(DEMO_DERIV, "p5b_model_coefficients.csv")
OUTPUT_TABLES <- file.path(DEMO_DERIV, "p5b_summary_tables.docx")

df_metrics <- read_delim(INPUT_METRICS, delim = ";", show_col_types = FALSE)
df_coefs   <- read_delim(INPUT_COEFS,   delim = ";", show_col_types = FALSE)

# ── English labels ─────────────────────────────────────────────────────────────
VAR_LABELS_EN <- c(
  "Renta neta media por persona"                                      = "Net income per capita (EUR)",
  "Renta neta media por hogar"                                        = "Net household income (EUR)",
  "Índice de Gini (%)"                                                = "Gini index (%)",
  "Indice de Gini (%)"                                                = "Gini index (%)",
  "Distribución de la renta P80/P20"                                  = "Income ratio P80/P20",
  "Tasa de paro"                                                      = "Unemployment rate (%)",
  "Afiliados Régimen Especial (R. E.) T. Autónomos (% s/ Total)"     = "Self-employed affiliates (%)",
  "Contratos indefinidos (% s/ Total)"                               = "Permanent contracts (%)",
  "Total Empresas"                                                    = "Total firms",
  "Pensión Contributiva Media"                                        = "Mean contributory pension (EUR)",
  "Porcentaje cobertura >= 100 Mbps (condiciones maxima demanda)"    = "Broadband >=100 Mbps (%)",
  "Porcentaje cobertura >= 100 Mbps (condiciones máxima demanda)"    = "Broadband >=100 Mbps (%)",
  "Consultorio de atención primaria (número)"                        = "Primary care centres (n)",
  "Oficina de farmacia (número)"                                     = "Pharmacies (n)",
  "Nº centros de Educación Primaria"                                 = "Primary schools (n)",
  "No centros de Educación Primaria"                                 = "Primary schools (n)",
  "Tiempo municipio 5.000 hab. o más, más cercano (minutos)"        = "Time to 5,000-inhab. town (min)",
  "Tiempo municipio 20.000 hab. o más, más cercano (minutos)"       = "Time to 20,000-inhab. town (min)",
  "Sucursal bancaria (número)"                                       = "Bank branches (n)",
  "Parque de vehículos x c/ 100 hab."                               = "Vehicles per 100 inhab.",
  "Viviendas no principales (% s/ total)"                           = "Non-primary dwellings (%)",
  "Tamaño medio del hogar"                                          = "Mean household size",
  "Hogares unipersonales (% s/ total)"                              = "Single-person households (%)",
  "Plazas turísticas x c/ 100 hab."                                 = "Tourist beds per 100 inhab.",
  "Altitud capital (m)"                                             = "Elevation (m)",
  "Densidad (hab/km2)"                                              = "Population density (inhab/km²)",
  "Superficie (km2)"                                                = "Municipal area (km²)",
  "Superficie forestal (% s/ total)"                               = "Forest cover (%)",
  "Superficie protegida (% s/ total)"                              = "Protected area (%)",
  "Población Nacionalidad Extranjera (% hab. s/ total)"            = "Foreign nationals (% total pop.)",
  "Pct_0_14"            = "Children 0–14 years (%)",
  "Pct_15_29"           = "Youth 15–29 years (%)",
  "Pct_30_64"           = "Adults 30–64 years (%)",
  "Pct_65_plus"         = "Seniors ≥65 years (%)",
  "Pct_Mujeres_0_14"    = "Women 0–14 years (%)",
  "Pct_Mujeres_15_29"   = "Women 15–29 years (%)",
  "Pct_Mujeres_30_64"   = "Women 30–64 years (%)",
  "Pct_Mujeres_65_plus" = "Women ≥65 years (%)",
  "Pct_Hombres_0_14"    = "Men 0–14 years (%)",
  "Pct_Hombres_15_29"   = "Men 15–29 years (%)",
  "Pct_Hombres_30_64"   = "Men 30–64 years (%)",
  "Pct_Hombres_65_plus" = "Men ≥65 years (%)",
  "Edad media población"      = "Mean age (years)",
  "Índice envejecimiento (%)" = "Ageing index (%)",
  "Tasa dependencia (%)"      = "Dependency ratio (%)",
  "Mujeres (% hab. s/ total)" = "Women (% total pop.)",
  "Nº centros de Educación Infantil Segundo Ciclo" = "Early childhood education centres (n)"
)

get_en <- function(short) {
  lbl <- VAR_LABELS_EN[trimws(gsub("\\s+", " ", short))]
  ifelse(is.na(lbl), short, lbl)
}

df_coefs$variable_en <- sapply(df_coefs$variable_short, get_en)

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 1 — MODEL METRICS
# ══════════════════════════════════════════════════════════════════════════════

tbl1 <- df_metrics %>%
  mutate(
    Model      = model_id,
    Typology   = ifelse(typology == "Rural - Remoto", "Remote", "Accessible"),
    Comparison = ifelse(comparison == "reverter",
                        "Reverter vs. Structural decline",
                        "Dynamiser vs. Structural decline"),
    Estimator  = estimator,
    N_target   = n_target,
    N_ref      = n_reference,
    N_total    = n_total,
    Predictors = n_predictors,
    Criterion  = paste0(criterion_name, " = ", round(criterion_value, 2)),
    McFadden   = round(mcfadden_r2, 3),
    AUC        = round(auc, 3),
    Max_rho    = round(max_retained_spearman_rho, 3)
  ) %>%
  select(Model, Typology, Comparison, Estimator, N_target, N_ref,
         N_total, Predictors, Criterion, McFadden, AUC, Max_rho)

ft1 <- flextable(tbl1) %>%
  set_header_labels(
    Model      = "Model",
    Typology   = "Typology",
    Comparison = "Comparison",
    Estimator  = "Estimator",
    N_target   = "n (target)",
    N_ref      = "n (reference)",
    N_total    = "n (total)",
    Predictors = "Predictors",
    Criterion  = "Selection criterion",
    McFadden   = "McFadden R²",
    AUC        = "AUC",
    Max_rho    = "Max ρ"
  ) %>%
  bold(part = "header") %>%
  fontsize(size = 10, part = "all") %>%
  font(fontname = "Calibri", part = "all") %>%
  autofit() %>%
  theme_booktabs() %>%
  set_caption("Table S1. Logistic regression model metrics")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 2 — COEFFICIENTS
# ══════════════════════════════════════════════════════════════════════════════

tbl2 <- df_coefs %>%
  mutate(
    Model      = model_id,
    Typology   = ifelse(typology == "Rural - Remoto", "Remote", "Accessible"),
    Comparison = ifelse(comparison == "reverter", "Reverter", "Dynamiser"),
    Variable   = variable_en,
    OR         = round(or, 3),
    CI_95      = paste0("[", round(or_ci_lo, 3), ", ", round(or_ci_hi, 3), "]"),
    p_val      = ifelse(p_value < 0.001, "<0.001",
                        as.character(round(p_value, 3))),
    Sig        = ifelse(p_value < 0.001, "***",
                        ifelse(p_value < 0.01,  "**",
                               ifelse(p_value < 0.05,  "*",
                                      ifelse(p_value < 0.10,  "†", ""))))
  ) %>%
  select(Model, Typology, Comparison, Variable, OR, CI_95, p_val, Sig) %>%
  arrange(Model, desc(abs(log(OR))))

ft2 <- flextable(tbl2) %>%
  set_header_labels(
    Model      = "Model",
    Typology   = "Typology",
    Comparison = "Comparison",
    Variable   = "Predictor",
    OR         = "OR",
    CI_95      = "95% CI",
    p_val      = "p-value",
    Sig        = ""
  ) %>%
  bold(part = "header") %>%
  bold(j = "Sig") %>%
  fontsize(size = 10, part = "all") %>%
  font(fontname = "Calibri", part = "all") %>%
  autofit() %>%
  theme_booktabs() %>%
  add_footer_lines("*** p<0.001; ** p<0.01; * p<0.05; † p<0.10") %>%
  set_caption("Table S2. Logistic regression coefficients (odds ratios and 95% CI)")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 3 — VARIABLE SELECTION MATRIX
# ══════════════════════════════════════════════════════════════════════════════

tbl3 <- df_coefs %>%
  mutate(
    present  = ifelse(significant_05, "✓*", "✓"),
    Variable = variable_en
  ) %>%
  select(Variable, model_id, present) %>%
  pivot_wider(
    names_from  = model_id,
    values_from = present,
    values_fn   = function(x) x[1],
    values_fill = "–"
  ) %>%
  arrange(Variable) %>%
  select(Variable, any_of(c("M1", "M2", "M3", "M4")))

ft3 <- flextable(tbl3) %>%
  set_header_labels(
    Variable = "Predictor",
    M1 = "M1\nReverter\nRemote",
    M2 = "M2\nDynamiser\nRemote",
    M3 = "M3\nReverter\nAccessible",
    M4 = "M4\nDynamiser\nAccessible"
  ) %>%
  bold(part = "header") %>%
  align(j = c("M1","M2","M3","M4"), align = "center", part = "all") %>%
  fontsize(size = 10, part = "all") %>%
  font(fontname = "Calibri", part = "all") %>%
  autofit() %>%
  theme_booktabs() %>%
  add_footer_lines("✓* = selected and significant (p < 0.05); ✓ = selected, not significant; – = not selected") %>%
  set_caption("Table S3. Variable selection matrix across models")

# ══════════════════════════════════════════════════════════════════════════════
# TABLE 4 — COLLINEAR_DROP JUSTIFICATION
# ══════════════════════════════════════════════════════════════════════════════

tbl4 <- tribble(
  ~Variable_dropped, ~Models, ~Collinear_with, ~Rationale,
  
  "Seniors ≥65 years (%)",         "M1–M4", "Women ≥65 years (%); Mean age (years)",        "Redundant with sex-disaggregated and mean age measures",
  "Women ≥65 years (%)",           "M2, M4", "Ageing index (%)",                             "Redundant with ageing index in dynamiser models",
  "Adults 30–64 years (%)",        "M1–M4", "Women 30–64 years (%)",                         "Total age group redundant with female disaggregation",
  "Men 0–14 years (%)",            "M1–M4", "Women 0–14 years (%); Children 0–14 years (%)", "Sex-disaggregated male vars redundant with female/total",
  "Men 15–29 years (%)",           "M1–M4", "Youth 15–29 years (%)",                         "Sex-disaggregated male vars redundant with total",
  "Men 30–64 years (%)",           "M1–M4", "Women 30–64 years (%)",                         "Sex-disaggregated male vars redundant with female",
  "Men ≥65 years (%)",             "M1–M4", "Women ≥65 years (%); Seniors ≥65 years (%)",   "Sex-disaggregated male vars redundant with female/total",
  "Ageing index (%)",              "M2–M4", "Mean age (years)",                               "ρ > 0.90 with mean age; mean age preferred for interpretability",
  "Net household income (EUR)",    "M2–M4", "Net income per capita (EUR)",                    "ρ > 0.85 with per-capita income; per-capita preferred",
  "Net income per capita (EUR)",   "M1",    "Net household income (EUR)",                     "ρ > 0.85 with household income; household income preferred for M1",
  "Single-person households (%)",  "M2–M4", "Mean household size",                            "ρ > 0.80 with household size (inverse relationship)",
  "Total firms",                   "M2–M4", "Bank branches (n)",                              "Noisy count variable; bank branches more informative for services",
  "Women (% total pop.)",          "M2",    "Age structure variables",                        "Aliased with demographic structure; adds no independent information",
  "Children 0–14 years (%)",       "M2",    "Women 0–14 years (%); Mean age (years)",         "ρ > 0.91 with women 0–14 and mean age",
  "Women 0–14 years (%)",          "M2",    "Women 30–64 years (%); Mean age (years)",        "After removing children 0–14, women 30–64 preferred as active age proxy",
  "Population density (inhab/km²)","M4",    "Municipal area (km²)",                           "Collinear with area; area retained as more direct measure",
  "Non-primary dwellings (%)",     "M4",    "Tourist beds per 100 inhab.",                    "p > 0.22 in previous run; low independent contribution",
  "Early childhood education centres (n)", "M4", "Primary schools (n)",                       "ρ = 0.998 with primary schools; primary schools retained",
  "Municipal area (km²)",          "M4",    "Population density (inhab/km²)",                 "p > 0.45; dropped in favour of density",
  "Time to 5,000-inhab. town (min)","M3",   "Time to 20,000-inhab. town (min)",               "p > 0.23 in M3; time to larger centre more discriminating",
  "Income ratio P80/P20",          "M3",    "Net income per capita (EUR)",                    "p > 0.90 in M3; inequality measure redundant given income controls"
) %>%
  arrange(Variable_dropped)

ft4 <- flextable(tbl4) %>%
  set_header_labels(
    Variable_dropped = "Variable dropped",
    Models           = "Dropped from",
    Collinear_with   = "Collinear/redundant with",
    Rationale        = "Rationale"
  ) %>%
  bold(part = "header") %>%
  fontsize(size = 10, part = "all") %>%
  font(fontname = "Calibri", part = "all") %>%
  width(j = "Variable_dropped", width = 1.8) %>%
  width(j = "Models",           width = 0.8) %>%
  width(j = "Collinear_with",   width = 2.0) %>%
  width(j = "Rationale",        width = 3.2) %>%
  theme_booktabs() %>%
  set_caption("Table S4. Variables excluded during collinearity screening (COLLINEAR_DROP)")

# ══════════════════════════════════════════════════════════════════════════════
# EXPORT TO WORD
# ══════════════════════════════════════════════════════════════════════════════

doc <- read_docx() %>%
  body_add_par("Step 5b — Logistic Regression Models: Summary Tables",
               style = "heading 1") %>%
  body_add_par("Table 1. Model metrics", style = "heading 2") %>%
  body_add_flextable(ft1) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("Table 2. Model coefficients", style = "heading 2") %>%
  body_add_flextable(ft2) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("Table 3. Variable selection matrix", style = "heading 2") %>%
  body_add_flextable(ft3) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("Table 4. Collinearity exclusions", style = "heading 2") %>%
  body_add_flextable(ft4)

print(doc, target = OUTPUT_TABLES)
cat(sprintf("\nExported: %s\n", basename(OUTPUT_TABLES)))