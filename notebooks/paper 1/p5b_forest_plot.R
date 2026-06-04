# ══════════════════════════════════════════════════════════════════════════════
# PAPER 1 — PASO 5B: FOREST PLOT (Odds Ratios with 95% CI)
# ══════════════════════════════════════════════════════════════════════════════
# Forest plot showing odds ratios and confidence intervals for all predictors
# across the 4 logistic regression models
# ══════════════════════════════════════════════════════════════════════════════

library(ggplot2)
library(dplyr)
library(readr)
library(forcats)

# ── Paths ─────────────────────────────────────────────────────────────────────
ROOT       <- file.path("C:/Users/juanz/OneDrive/Desktop/UCM/RURIM ESCAPE",
                        "GeoSpatial/01_Python Data Analysis",
                        "rural-migration-land-use-spain")
DEMO_DERIV <- file.path(ROOT, "data/demography/derived/paper1")
FIG_DIR    <- file.path(ROOT, "figures/p5b_explanatory_modelling")
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)

INPUT_COEFS <- file.path(DEMO_DERIV, "p5b_model_coefficients.csv")

# ── Load data ─────────────────────────────────────────────────────────────────
df_coefs <- read_delim(INPUT_COEFS, delim = ";", locale = locale(encoding = "UTF-8"),
                       show_col_types = FALSE)

cat(sprintf("Loaded: %d coefficients from %d models\n",
            nrow(df_coefs), length(unique(df_coefs$model_id))))

# ── English labels ────────────────────────────────────────────────────────────
VAR_LABELS_EN <- c(
  # Economy
  "Renta neta media por persona"                                     = "Net income per capita (EUR)",
  "Renta neta media por hogar"                                       = "Net household income (EUR)",
  "Índice de Gini (%)"                                               = "Gini index (%)",
  "Indice de Gini (%)"                                               = "Gini index (%)",
  "Distribución de la renta P80/P20"                                 = "Income ratio P80/P20",
  "Distribucion de la renta P80/P20"                                 = "Income ratio P80/P20",
  "Tasa de paro"                                                     = "Unemployment rate (%)",
  "Afiliados Régimen Especial (R. E.) T. Autónomos (% s/ Total)"    = "Self-employed affiliates (%)",
  "Contratos indefinidos (% s/ Total)"                              = "Permanent contracts (%)",
  "Total Empresas"                                                   = "Total firms",
  "Pensión Contributiva Media"                                       = "Mean contributory pension (EUR)",
  # Connectivity
  "Porcentaje cobertura >= 100 Mbps (condiciones maxima demanda)"   = "Broadband >=100 Mbps (%)",
  "Porcentaje cobertura >= 100 Mbps (condiciones máxima demanda)"   = "Broadband >=100 Mbps (%)",
  # Services
  "Consultorio de atención primaria (número)"                       = "Primary care centres (n)",
  "Oficina de farmacia (número)"                                    = "Pharmacies (n)",
  "Nº centros de Educación Primaria"                                = "Primary schools (n)",
  "No centros de Educación Primaria"                                = "Primary schools (n)",
  "Nº centros de Educación Infantil Segundo Ciclo"                  = "Early childhood education centres (n)",
  "Tiempo municipio 5.000 hab. o más, más cercano (minutos)"        = "Time to 5,000-inhab. town (min)",
  "Tiempo municipio 20.000 hab. o más, más cercano (minutos)"       = "Time to 20,000-inhab. town (min)",
  "Sucursal bancaria (número)"                                      = "Bank branches (n)",
  "Parque de vehículos x c/ 100 hab."                               = "Vehicles per 100 inhab.",
  # Housing
  "Viviendas no principales (% s/ total)"                           = "Non-primary dwellings (%)",
  "Tamaño medio del hogar"                                          = "Mean household size",
  "Hogares unipersonales (% s/ total)"                              = "Single-person households (%)",
  "Plazas turísticas x c/ 100 hab."                                 = "Tourist beds per 100 inhab.",
  # Physical environment
  "Altitud capital (m)"                                             = "Elevation (m)",
  "Densidad (hab/km2)"                                              = "Population density (inhab/km²)",
  "Superficie (km2)"                                                = "Municipal area (km²)",
  "Superficie forestal (% s/ total)"                               = "Forest cover (%)",
  "Superficie protegida (% s/ total)"                              = "Protected area (%)",
  # Demographics — population
  "Población Nacionalidad Extranjera (% hab. s/ total)"            = "Foreign nationals (% total pop.)",
  "Poblacion Nacionalidad Extranjera (% hab. s/ total)"            = "Foreign nationals (% total pop.)",
  "Mujeres (% hab. s/ total)"                                      = "Women (% total pop.)",
  # Demographics — age groups
  "Pct_0_14"            = "Children 0-14 (%)",
  "Pct_15_29"           = "Youth 15-29 (%)",
  "Pct_30_64"           = "Adults 30-64 (%)",
  "Pct_65_plus"         = "Seniors ≥65 (%)",
  "Pct_Mujeres_0_14"    = "Women 0-14 (%)",
  "Pct_Mujeres_15_29"   = "Women 15-29 (%)",
  "Pct_Mujeres_30_64"   = "Women 30-64 (%)",
  "Pct_Mujeres_65_plus" = "Women ≥65 (%)",
  "Pct_Hombres_0_14"    = "Men 0-14 (%)",
  "Pct_Hombres_15_29"   = "Men 15-29 (%)",
  "Pct_Hombres_30_64"   = "Men 30-64 (%)",
  "Pct_Hombres_65_plus" = "Men ≥65 (%)",
  # Demographics — ratios
  "Edad media población"       = "Mean age (years)",
  "Índice envejecimiento (%)"  = "Ageing index (%)",
  "Tasa dependencia (%)"       = "Dependency ratio (%)"
)

# Map to English
df_coefs$variable_en <- VAR_LABELS_EN[df_coefs$variable_short]
# If no match, use original
df_coefs$variable_en <- ifelse(is.na(df_coefs$variable_en),
                               df_coefs$variable_short,
                               df_coefs$variable_en)

# ── Model labels ──────────────────────────────────────────────────────────────
df_coefs$model_label <- paste0(
  df_coefs$model_id, ": ",
  ifelse(df_coefs$comparison == "reverter", "Reverter", "Dynamiser"),
  " vs. Decline\n",
  ifelse(df_coefs$typology == "Rural - Remoto", "Remote", "Accessible")
)

# Order models: M1, M2, M3, M4
df_coefs$model_label <- factor(df_coefs$model_label,
                                levels = c("M1: Reverter vs. Decline\nRemote",
                                          "M2: Dynamiser vs. Decline\nRemote",
                                          "M3: Reverter vs. Decline\nAccessible",
                                          "M4: Dynamiser vs. Decline\nAccessible"))

# ── Prepare plot data ─────────────────────────────────────────────────────────
# Within each model, order variables by OR magnitude (descending)
df_coefs <- df_coefs %>%
  group_by(model_id) %>%
  mutate(or_abs = abs(log(or)),
         var_order = rank(-or_abs, ties.method = "first")) %>%
  ungroup()

# Significance markers
df_coefs$sig_marker <- ifelse(df_coefs$p_value < 0.001, "***",
                       ifelse(df_coefs$p_value < 0.01, "**",
                       ifelse(df_coefs$p_value < 0.05, "*", "")))

# Color by significance
df_coefs$sig_color <- ifelse(df_coefs$p_value < 0.05, "sig", "ns")

# ══════════════════════════════════════════════════════════════════════════════
# FIGURE: FOREST PLOT (4 panels, one per model)
# ══════════════════════════════════════════════════════════════════════════════

# Theme
FONTSIZE <- 12
theme_forest <- theme_minimal(base_size = FONTSIZE) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "gray90", linewidth = 0.3),
    axis.text.y = element_text(size = FONTSIZE - 1, hjust = 1),
    axis.title.x = element_text(size = FONTSIZE, margin = margin(t = 8)),
    strip.text = element_text(size = FONTSIZE, face = "bold", hjust = 0),
    strip.background = element_rect(fill = "gray95", color = NA),
    legend.position = "bottom",
    plot.margin = margin(10, 10, 10, 10)
  )

# Create plot
p <- ggplot(df_coefs, aes(x = or, y = reorder(variable_en, or_abs),
                          color = sig_color)) +
  # Vertical line at OR = 1 (no effect)
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray40", linewidth = 0.5) +
  
  # Error bars (95% CI)
  geom_errorbar(aes(xmin = or_ci_lo, xmax = or_ci_hi),
                orientation = "y", width = 0.3, linewidth = 0.6, alpha = 0.8) +
  
  # Point estimates
  geom_point(size = 2.5, alpha = 0.9) +
  
  # Facet by model
  facet_wrap(~ model_label, ncol = 2, scales = "free_y") +
  
  # Scales
  scale_x_log10(breaks = c(0.5, 1, 2, 4, 8),
                labels = c("0.5", "1", "2", "4", "8")) +
  scale_color_manual(values = c(sig = "#2166ac", ns = "gray60"),
                     labels = c(sig = "p < 0.05", ns = "p ≥ 0.05"),
                     name = "") +
  
  # Labels
  labs(x = "Odds Ratio (95% CI, log scale)",
       y = NULL,
       title = "Explanatory models: Odds ratios for reversal and growth vs. structural decline",
       subtitle = "Positive associations shown for OR > 1; negative for OR < 1") +
  
  theme_forest

# Save
ggsave(file.path(FIG_DIR, "fig_forest_plot_OR_4models_en.png"),
       p, width = 12, height = 10, dpi = 300, bg = "white")

cat("\nFigure saved: fig_forest_plot_OR_4models_en.png\n")

# ══════════════════════════════════════════════════════════════════════════════
# ALTERNATIVE: SINGLE COMBINED PLOT (all models in one y-axis)
# ══════════════════════════════════════════════════════════════════════════════
# This version shows all variables on one axis, with models as colors/shapes
# Useful if you want to compare effect sizes across models directly

# Prepare data: keep only variables present in at least 2 models
var_counts <- df_coefs %>%
  group_by(variable_en) %>%
  summarize(n_models = n_distinct(model_id)) %>%
  filter(n_models >= 2)

df_common <- df_coefs %>%
  filter(variable_en %in% var_counts$variable_en)

# Compute mean OR across models for ordering
var_mean_or <- df_common %>%
  group_by(variable_en) %>%
  summarize(mean_or_abs = mean(abs(log(or)))) %>%
  arrange(desc(mean_or_abs))

df_common$variable_en <- factor(df_common$variable_en,
                                levels = var_mean_or$variable_en)

# Create combined plot
p_combined <- ggplot(df_common, aes(x = or, y = variable_en,
                                    color = model_label, shape = sig_color)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray40", linewidth = 0.5) +
  
  geom_errorbar(aes(xmin = or_ci_lo, xmax = or_ci_hi),
                orientation = "y", width = 0, linewidth = 0.5, alpha = 0.7,
                position = position_dodge(width = 0.6)) +
  
  geom_point(size = 2.5, alpha = 0.9,
             position = position_dodge(width = 0.6)) +
  
  scale_x_log10(breaks = c(0.5, 1, 2, 4, 8),
                labels = c("0.5", "1", "2", "4", "8")) +
  
  scale_color_manual(values = c("#e66101", "#fdb863", "#5e3c99", "#b2abd2"),
                     name = "Model") +
  
  scale_shape_manual(values = c(sig = 19, ns = 1),
                     labels = c(sig = "p < 0.05", ns = "p ≥ 0.05"),
                     name = "Significance") +
  
  labs(x = "Odds Ratio (95% CI, log scale)",
       y = NULL,
       title = "Common predictors across models",
       subtitle = "Variables appearing in 2+ models") +
  
  theme_forest +
  theme(legend.position = "right",
        legend.box = "vertical")

ggsave(file.path(FIG_DIR, "fig_forest_plot_OR_combined_en.png"),
       p_combined, width = 10, height = 8, dpi = 300, bg = "white")

cat("Figure saved: fig_forest_plot_OR_combined_en.png\n")

# ══════════════════════════════════════════════════════════════════════════════
# SPANISH VERSION (for internal review)
# ══════════════════════════════════════════════════════════════════════════════

df_coefs$model_label_es <- paste0(
  df_coefs$model_id, ": ",
  ifelse(df_coefs$comparison == "reverter", "Reversión", "Dinamización"),
  " vs. Declive\n",
  ifelse(df_coefs$typology == "Rural - Remoto", "Remoto", "Accesible")
)

df_coefs$model_label_es <- factor(df_coefs$model_label_es,
                                   levels = c("M1: Reversión vs. Declive\nRemoto",
                                             "M2: Dinamización vs. Declive\nRemoto",
                                             "M3: Reversión vs. Declive\nAccesible",
                                             "M4: Dinamización vs. Declive\nAccesible"))

p_es <- ggplot(df_coefs, aes(x = or, y = reorder(variable_short, or_abs),
                             color = sig_color)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray40", linewidth = 0.5) +
  geom_errorbar(aes(xmin = or_ci_lo, xmax = or_ci_hi),
                orientation = "y", width = 0.3, linewidth = 0.6, alpha = 0.8) +
  geom_point(size = 2.5, alpha = 0.9) +
  facet_wrap(~ model_label_es, ncol = 2, scales = "free_y") +
  scale_x_log10(breaks = c(0.5, 1, 2, 4, 8),
                labels = c("0,5", "1", "2", "4", "8")) +
  scale_color_manual(values = c(sig = "#2166ac", ns = "gray60"),
                     labels = c(sig = "p < 0,05", ns = "p ≥ 0,05"),
                     name = "") +
  labs(x = "Odds Ratio (IC 95%, escala logarítmica)",
       y = NULL,
       title = "Modelos explicativos: Odds ratios para reversión y dinamización vs. declive estructural",
       subtitle = "Asociaciones positivas mostradas para OR > 1; negativas para OR < 1") +
  theme_forest

ggsave(file.path(FIG_DIR, "fig_forest_plot_OR_4models_es.png"),
       p_es, width = 12, height = 10, dpi = 300, bg = "white")

cat("Figure saved: fig_forest_plot_OR_4models_es.png\n")

cat("\n=== Forest plots generated ===\n")
cat("Files created:\n")
cat("  • fig_forest_plot_OR_4models_en.png (main figure, 4 panels)\n")
cat("  • fig_forest_plot_OR_combined_en.png (alternative, common vars)\n")
cat("  • fig_forest_plot_OR_4models_es.png (Spanish version)\n")

