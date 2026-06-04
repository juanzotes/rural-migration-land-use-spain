# ══════════════════════════════════════════════════════════════════════════════
# p5c_pca.R  — DEFINITIVE VERSION
# RURIMESCAPE — Paper 1, Step 5c
# Principal Component Analysis of rural demographic behavioural groups
#
# Author  : Juan Zotes
# Created : 2026-06
#
# Purpose:
#   Independent multivariate ordination of Spanish rural municipalities using
#   PCA on all 44 candidate variables — no pre-filtering — letting PCA loadings
#   determine discriminating information. Quality-control check on the
#   univariate selection made in p5a (Kruskal-Wallis).
#
#   NOTE on column names: read.csv2() converts spaces, parentheses and special
#   characters to dots. VAR_COLS_CSV uses the actual dot-encoded names as they
#   appear after reading p5a_rural_analysis_dataset.csv.
#
# Input:
#   data/demography/derived/paper1/p5a_rural_analysis_dataset.csv
#
# Outputs — figures (figures/p5c_pca/):
#   p5c_fig1_screeplot.png
#   p5c_fig2_biplot_PC1_PC2.png
#   p5c_fig2b_biplot_PC1_PC2_by_typology.png
#   p5c_fig3_biplot_PC1_PC3.png
#   p5c_fig4_loadings_heatmap.png
#   p5c_fig5_scores_density_PC1.png
#
# Outputs — tables/CSV (figures/p5c_pca/tables/):
#   p5c_tab0_missingness_audit.csv
#   p5c_tab1_variance_explained.csv
#   p5c_tab2_loadings_top.csv
#   p5c_tab3_median_scores_by_group.csv
#   p5c_tab4_variable_contribution_pct.csv
#
# Exports for p5d:
#   data/demography/derived/paper1/p5c_pca_scores.csv
#   data/demography/derived/paper1/p5c_pca_metadata.rds
# ==============================================================================


# ── 0. Libraries ───────────────────────────────────────────────────────────────
suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(ggrepel)
  library(patchwork)
  library(RColorBrewer)
  library(viridis)
  library(scales)
  library(writexl)
})


# ── 1. Paths ───────────────────────────────────────────────────────────────────
ROOT    <- file.path("C:/Users/juanz/OneDrive/Desktop/UCM/RURIM ESCAPE/GeoSpatial",
                     "01_Python Data Analysis/rural-migration-land-use-spain")

IN_CSV  <- file.path(ROOT, "data/demography/derived/paper1/p5a_rural_analysis_dataset.csv")
FIG_DIR <- file.path(ROOT, "figures/p5c_pca")
TAB_DIR <- file.path(FIG_DIR, "tables")
DER_DIR <- file.path(ROOT, "data/demography/derived/paper1")

for (d in c(FIG_DIR, TAB_DIR, DER_DIR)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

cat("Paths set.\n")
cat("Input  :", IN_CSV,  "\n")
cat("Figures:", FIG_DIR, "\n")


# ── 2. Constants ───────────────────────────────────────────────────────────────

GROUP_ORDER <- c("Grows in both", "Reverses in B", "Loses in B", "Structural depopulation")

GROUP_COLORS <- c(
  "Grows in both"           = "#d7191c",
  "Reverses in B"           = "#fdae61",
  "Loses in B"              = "#abd9e9",
  "Structural depopulation" = "#2c7bb6"
)

GROUP_LABELS <- c(
  "Grows in both"           = "Dynamisers",
  "Reverses in B"           = "Reverters",
  "Loses in B"              = "Loses in B",
  "Structural depopulation" = "Structural decline"
)

TYPOLOGIES <- c("Rural - Remoto", "Rural - Accesible")

BLOCK_COLORS <- c(
  "Demographic"  = "#4575b4",
  "Economic"     = "#d73027",
  "Services"     = "#1a9850",
  "Housing"      = "#f46d43",
  "Physical"     = "#74add1",
  "Environment"  = "#a6d96a"
)

# Variable names as they appear after read.csv2() dot-encoding
VAR_COLS_CSV <- c(
  # Demographic (17)
  "DEMOGRAFIA__POBLACI\u00d3N.POR.SEXO__Mujeres.....hab..s..total.",
  "DEMOGRAFIA__Pct_0_14",
  "DEMOGRAFIA__Pct_15_29",
  "DEMOGRAFIA__Pct_30_64",
  "DEMOGRAFIA__Pct_65_plus",
  "DEMOGRAFIA__Pct_Mujeres_0_14",
  "DEMOGRAFIA__Pct_Hombres_0_14",
  "DEMOGRAFIA__Pct_Mujeres_15_29",
  "DEMOGRAFIA__Pct_Hombres_15_29",
  "DEMOGRAFIA__Pct_Mujeres_30_64",
  "DEMOGRAFIA__Pct_Hombres_30_64",
  "DEMOGRAFIA__Pct_Mujeres_65_plus",
  "DEMOGRAFIA__Pct_Hombres_65_plus",
  "DEMOGRAFIA__EDAD.MEDIA__Edad.media.poblaci\u00f3n",
  "DEMOGRAFIA__RATIOS__\u00cdndice.envejecimiento....",
  "DEMOGRAFIA__RATIOS__Tasa.dependencia.....",
  "DEMOGRAFIA__NACIONALIDAD__Poblaci\u00f3n.Nacionalidad.Extranjera.....hab..s..total.",
  # Economic (9)
  "ECONOMIA__RENTAS__Renta.neta.media.por.persona",
  "ECONOMIA__RENTAS__Renta.neta.media.por.hogar",
  "ECONOMIA__RENTAS__DESIGUALDAD__\u00cdndice.de.Gini....",
  "ECONOMIA__RENTAS__DESIGUALDAD__Distribuci\u00f3n.de.la.renta.P80.P20",
  "ECONOMIA__PARADOS__POR.SEXO__Tasa.de.paro",
  "ECONOMIA__AFILIADOS__POR.SECTOR__Afiliados.R\u00e9gimen.Especial..R..E...T..Aut\u00f3nomos.....s..Total.",
  "ECONOMIA__CONTRATOS__POR.DURACI\u00d3N__Contratos.indefinidos.....s..Total.",
  "ECONOMIA__EMPRESAS__Total.Empresas",
  "ECONOMIA__PENSIONES.CONTRIBUTIVAS__Pensi\u00f3n.Contributiva.Media",
  # Services (9)
  "SERVICIOS__INTERNET__Porcentaje.cobertura...100.Mbps..condiciones.m\u00e1xima.demanda.",
  "SERVICIOS__CENTROS.SANITARIOS__Consultorio.de.atenci\u00f3n.primaria..n\u00famero.",
  "SERVICIOS__ESTABLECIMIENTOS.SANITARIOS__Oficina.de.farmacia..n\u00famero.",
  "SERVICIOS__CENTROS.DE.EDUCACI\u00d3N__N\u00ba.centros.de.Educaci\u00f3n.Infantil.Segundo.Ciclo",
  "SERVICIOS__CENTROS.DE.EDUCACI\u00d3N__N\u00ba.centros.de.Educaci\u00f3n.Primaria",
  "SERVICIOS__DISTANCIAS.A.LOS.SERVICIOS.M\u00c1S.CERCANOS__Tiempo.municipio.5.000.hab..o.m\u00e1s..m\u00e1s.cercano..minutos.",
  "SERVICIOS__DISTANCIAS.A.LOS.SERVICIOS.M\u00c1S.CERCANOS__Tiempo.municipio.20.000.hab..o.m\u00e1s..m\u00e1s.cercano..minutos.",
  "SERVICIOS__OTROS.SERVICIOS__SUCURSAL.BANCARIA__Sucursal.bancaria..n\u00famero.",
  "SERVICIOS__TRANSPORTE__Parque.de.veh\u00edculos.x.c..100.hab.",
  # Housing (4)
  "VIVIENDA__TIPOS.DE.VIVIENDAS..familiares.__Viviendas.no.principales....s..total.",
  "VIVIENDA__HOGAR__Tama\u00f1o.medio.del.hogar",
  "VIVIENDA__HOGAR__Hogares.unipersonales.....s..total.",
  "VIVIENDA__VIVIENDAS.TUR\u00cdSTICAS__Plazas.tur\u00edsticas.x.c..100.hab.",
  # Physical (3)
  "MEDIO.F\u00cdSICO__Altitud.capital...m.",
  "MEDIO.F\u00cdSICO__Densidad..hab.km2.",
  "MEDIO.F\u00cdSICO__Superficie..km2.",
  # Environment (2)
  "MEDIOAMBIENTE__CAPITAL.NATURAL__FORESTAL__Superficie.forestal.....s..total.",
  "MEDIOAMBIENTE__CAPITAL.NATURAL__ESPACIOS.PROTEGIDOS__Superficie.protegida.....s..total."
)

# Short labels for plots (order matches VAR_COLS_CSV)
VAR_LABELS <- c(
  "% Women",
  "% 0-14", "% 15-29", "% 30-64", "% 65+",
  "% Women 0-14", "% Men 0-14",
  "% Women 15-29", "% Men 15-29",
  "% Women 30-64", "% Men 30-64",
  "% Women 65+", "% Men 65+",
  "Mean age", "Ageing index", "Dependency rate",
  "% Foreign nationals",
  "Net income/person", "Net income/household",
  "Gini index", "P80/P20",
  "Unemployment rate", "% Self-employed",
  "% Permanent contracts", "Total firms",
  "Mean pension",
  "% 100Mbps coverage",
  "Primary care offices", "Pharmacies",
  "Preschool centres", "Primary schools",
  "Time to 5k-town (min)", "Time to 20k-town (min)",
  "Bank branches", "Vehicles/100 pop.",
  "% Non-primary housing", "Household size",
  "% Single-person HH", "Tourist beds/100 pop.",
  "Altitude (m)", "Density (hab/km2)", "Area (km2)",
  "% Forest cover", "% Protected area"
)

# Block membership (order matches VAR_COLS_CSV)
VAR_BLOCKS <- c(
  rep("Demographic",  17),
  rep("Economic",      9),
  rep("Services",      9),
  rep("Housing",       4),
  rep("Physical",      3),
  rep("Environment",   2)
)


# ── 3. Shared theme (p5a aesthetic) ────────────────────────────────────────────
theme_rurimescape <- function(base_size = 14) {
  theme_minimal(base_size = base_size) +
    theme(
      text             = element_text(size = base_size),
      axis.title       = element_text(size = base_size, face = "bold"),
      axis.text        = element_text(size = base_size - 1),
      legend.title     = element_text(size = base_size, face = "bold"),
      legend.text      = element_text(size = base_size - 1),
      plot.title       = element_text(size = base_size + 1, face = "bold"),
      plot.subtitle    = element_text(size = base_size - 1, colour = "#555555"),
      plot.caption     = element_text(size = 12, colour = "#555555", hjust = 0),
      panel.grid.minor = element_blank(),
      strip.text       = element_text(size = base_size, face = "bold")
    )
}


# ── 4. Data loading ─────────────────────────────────────────────────────────────
cat("\n-- Loading data --\n")

df_raw <- read.csv2(IN_CSV, encoding = "UTF-8", stringsAsFactors = FALSE)
cat("Loaded:", nrow(df_raw), "rows x", ncol(df_raw), "cols\n")

df <- df_raw %>%
  filter(tipo_goerlich %in% TYPOLOGIES,
         behavioural_group %in% GROUP_ORDER) %>%
  mutate(
    behavioural_group = factor(behavioural_group, levels = GROUP_ORDER),
    tipo_goerlich     = factor(tipo_goerlich,     levels = TYPOLOGIES)
  )

cat("After filter:", nrow(df), "municipalities\n")
print(table(df$behavioural_group))


# ── 5. Build analysis matrix ────────────────────────────────────────────────────
cat("\n-- Building analysis matrix --\n")

# Verify all variables present
present_check <- VAR_COLS_CSV %in% colnames(df)
cat("Variables found:", sum(present_check), "/", length(VAR_COLS_CSV), "\n")
if (any(!present_check)) {
  cat("WARNING - Missing columns:\n")
  for (v in VAR_COLS_CSV[!present_check]) cat("  -", v, "\n")
  stop("Fix column names in VAR_COLS_CSV before continuing.")
}

# Extract and convert to numeric
X_raw <- df[, VAR_COLS_CSV, drop = FALSE]
X_raw <- as.data.frame(lapply(X_raw, as.numeric))

# Missing value audit (threshold 40%)
miss_pct   <- colMeans(is.na(X_raw)) * 100
miss_audit <- data.frame(
  csv_column  = VAR_COLS_CSV,
  short_label = VAR_LABELS,
  block       = VAR_BLOCKS,
  missing_pct = round(miss_pct, 2),
  keep        = miss_pct < 40
)
write.csv(miss_audit, file.path(TAB_DIR, "p5c_tab0_missingness_audit.csv"), row.names = FALSE)

n_drop <- sum(!miss_audit$keep)
if (n_drop > 0) {
  cat("WARNING - Variables dropped (>40% NAs):", n_drop, "\n")
  for (i in which(!miss_audit$keep))
    cat(sprintf("  - %s (%.1f%% NAs)\n", VAR_LABELS[i], miss_pct[i]))
  keep_idx    <- which(miss_audit$keep)
  X_raw       <- X_raw[, keep_idx, drop = FALSE]
  keep_labels <- VAR_LABELS[keep_idx]
  keep_blocks <- VAR_BLOCKS[keep_idx]
} else {
  cat("All", length(VAR_COLS_CSV), "variables pass missingness filter\n")
  keep_labels <- VAR_LABELS
  keep_blocks <- VAR_BLOCKS
}

# Impute residual NAs by column median
for (col in colnames(X_raw)) {
  if (anyNA(X_raw[[col]]))
    X_raw[[col]][is.na(X_raw[[col]])] <- median(X_raw[[col]], na.rm = TRUE)
}

# Remove any rows still incomplete (safeguard)
complete_rows <- complete.cases(X_raw)
if (!all(complete_rows)) {
  cat("Removing", sum(!complete_rows), "rows with residual NAs\n")
  X_raw <- X_raw[complete_rows, ]
  df    <- df[complete_rows, ]
}

cat("Analysis matrix:", nrow(X_raw), "rows x", ncol(X_raw), "variables\n")

# Z-score standardisation
X_scaled <- scale(X_raw)
colnames(X_scaled) <- keep_labels
cat("Standardisation: z-score (mean=0, sd=1)\n")


# ── 6. PCA ──────────────────────────────────────────────────────────────────────
cat("\n-- Running PCA --\n")

pca_result   <- prcomp(X_scaled, center = FALSE, scale. = FALSE)
var_exp      <- pca_result$sdev^2
var_pct      <- var_exp / sum(var_exp) * 100
var_cum      <- cumsum(var_pct)
n_comps_80   <- which(var_cum >= 80)[1]
n_comps_plot <- min(10, ncol(X_scaled))

cat(sprintf("PC1: %.1f%%  PC2: %.1f%%  PC3: %.1f%%\n", var_pct[1], var_pct[2], var_pct[3]))
cat(sprintf("PCs to reach 80%% cumulative variance: %d\n", n_comps_80))

# Scores
scores <- as.data.frame(pca_result$x)
scores$Mun_Code          <- df$Mun_Code
scores$behavioural_group <- df$behavioural_group
scores$tipo_goerlich     <- df$tipo_goerlich

# Loadings (first 10 PCs)
loadings_df <- as.data.frame(pca_result$rotation[, 1:min(10, ncol(pca_result$rotation))])
loadings_df$variable    <- keep_labels
loadings_df$short_label <- keep_labels
loadings_df$block       <- keep_blocks


# ── 7. Tables ───────────────────────────────────────────────────────────────────
cat("\n-- Building tables --\n")

# Table 1: Variance explained
tab1 <- data.frame(
  Component           = paste0("PC", seq_len(n_comps_plot)),
  Eigenvalue          = round(var_exp[1:n_comps_plot], 3),
  Variance_explained  = round(var_pct[1:n_comps_plot], 2),
  Cumulative_variance = round(var_cum[1:n_comps_plot], 2)
)
write.csv(tab1, file.path(TAB_DIR, "p5c_tab1_variance_explained.csv"), row.names = FALSE)
cat("Table 1 saved\n")

# Table 2: Loadings sorted by |PC1|
tab2 <- loadings_df %>%
  select(short_label, block, PC1, PC2, PC3) %>%
  arrange(desc(abs(PC1))) %>%
  mutate(across(c(PC1, PC2, PC3), ~ round(., 3)))
write.csv(tab2, file.path(TAB_DIR, "p5c_tab2_loadings_top.csv"), row.names = FALSE)
cat("Table 2 saved\n")

# Table 3: Median PC scores by group x typology
tab3 <- scores %>%
  group_by(behavioural_group, tipo_goerlich) %>%
  summarise(n       = n(),
            PC1_med = round(median(PC1), 3),
            PC2_med = round(median(PC2), 3),
            PC3_med = round(median(PC3), 3),
            .groups = "drop") %>%
  arrange(tipo_goerlich, behavioural_group)
write.csv(tab3, file.path(TAB_DIR, "p5c_tab3_median_scores_by_group.csv"), row.names = FALSE)
cat("Table 3 saved\n")

# Table 4: Variable contribution (%) to PC1, PC2, PC3
tab4 <- loadings_df %>%
  select(short_label, block, PC1, PC2, PC3) %>%
  mutate(
    contrib_PC1 = round(PC1^2 / sum(PC1^2) * 100, 2),
    contrib_PC2 = round(PC2^2 / sum(PC2^2) * 100, 2),
    contrib_PC3 = round(PC3^2 / sum(PC3^2) * 100, 2),
    PC1 = round(PC1, 3), PC2 = round(PC2, 3), PC3 = round(PC3, 3)
  ) %>%
  arrange(desc(contrib_PC1))
write.csv(tab4, file.path(TAB_DIR, "p5c_tab4_variable_contribution_pct.csv"), row.names = FALSE)
cat("Table 4 saved\n")


# ── 8. Figures ──────────────────────────────────────────────────────────────────
cat("\n-- Generating figures --\n")

# Subsample for readability in biplots
set.seed(42)
scores_plot <- scores %>%
  group_by(behavioural_group) %>%
  slice_sample(prop = 0.5) %>%
  ungroup()

arrow_scale <- max(abs(scores_plot[, c("PC1", "PC2")])) * 0.45

# Figure 1: Scree plot
scree_df <- data.frame(
  PC  = seq_len(n_comps_plot),
  pct = var_pct[1:n_comps_plot],
  cum = var_cum[1:n_comps_plot]
)

p_scree <- ggplot(scree_df, aes(x = PC)) +
  geom_col(aes(y = pct), fill = "#4575b4", alpha = 0.8, width = 0.7) +
  geom_line(aes(y = cum), colour = "#d73027", linewidth = 0.8) +
  geom_point(aes(y = cum), colour = "#d73027", size = 2.5) +
  geom_hline(yintercept = 80, linetype = "dashed", colour = "#555555", linewidth = 0.6) +
  annotate("text", x = n_comps_plot - 0.3, y = 82,
           label = "80% threshold", size = 3.5, colour = "#555555", hjust = 1) +
  scale_x_continuous(breaks = seq_len(n_comps_plot)) +
  scale_y_continuous(name     = "Variance explained (%)",
                     sec.axis = sec_axis(~ ., name = "Cumulative variance (%)")) +
  labs(title    = "Scree plot - PCA of rural municipalities",
       subtitle = sprintf("n = %d municipalities | %d variables", nrow(X_raw), ncol(X_raw)),
       x        = "Principal component",
       caption  = "Source: INE, Padron Municipal (1996-2025); SIDAMUN (MITERD, 2023).") +
  theme_rurimescape()

ggsave(file.path(FIG_DIR, "p5c_fig1_screeplot.png"), p_scree, width = 8, height = 5, dpi = 300)
cat("Figure 1 saved\n")


# Figure 2: Biplot PC1 x PC2 (combined typologies)
arrow_scale <- 6.5  # fixed scale independent of score range

load_arrows <- loadings_df %>%
  mutate(xend = PC1 * arrow_scale, yend = PC2 * arrow_scale) %>%
  filter(abs(PC1) > 0.2 | abs(PC2) > 0.2)
load_arrows$arrow_colour <- BLOCK_COLORS[load_arrows$block]

centroids12 <- scores %>%
  group_by(behavioural_group) %>%
  summarise(PC1 = median(PC1), PC2 = median(PC2), .groups = "drop")

p_biplot12 <- ggplot() +
  geom_point(data = scores_plot,
             aes(x = PC1, y = PC2, colour = behavioural_group),
             alpha = 0.3, size = 1.0) +
  geom_point(data = centroids12,
             aes(x = PC1, y = PC2, fill = behavioural_group),
             shape = 23, size = 5, stroke = 0.8, colour = "white") +
  geom_segment(data = load_arrows,
               aes(x = 0, y = 0, xend = xend, yend = yend),
               colour = load_arrows$arrow_colour,
               arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
               linewidth = 0.8) +
  geom_text_repel(data = load_arrows,
                  aes(x = xend * 1.15, y = yend * 1.15, label = short_label),
                  size = 4.0, max.overlaps = 50,
                  force = 6, force_pull = 0.2,
                  box.padding = 0.8, point.padding = 0.3,
                  min.segment.length = 0,
                  segment.size = 0.3, segment.colour = "#888888") +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#bbbbbb", linewidth = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#bbbbbb", linewidth = 0.4) +
  scale_colour_manual(values = GROUP_COLORS, breaks = GROUP_ORDER,
                      labels = GROUP_LABELS, name = "Behavioural group",
                      guide = guide_legend(override.aes = list(size = 4, alpha = 1))) +
  scale_fill_manual(values = GROUP_COLORS, breaks = GROUP_ORDER,
                    labels = GROUP_LABELS, name = "Behavioural group") +
  labs(title    = "PCA biplot - PC1 x PC2",
       subtitle = sprintf("Rural-Remote + Rural-Accessible | n = %d | %d variables",
                          nrow(scores), ncol(X_scaled)),
       x        = sprintf("PC1 (%.1f%% variance)", var_pct[1]),
       y        = sprintf("PC2 (%.1f%% variance)", var_pct[2]),
       caption  = "Diamonds = group medians. Arrows = variable loadings (|loading| > 0.2).\nSource: INE, Padron Municipal (1996-2025); SIDAMUN (MITERD, 2023).") +
  theme_rurimescape() + theme(legend.position = "right")

ggsave(file.path(FIG_DIR, "p5c_fig2_biplot_PC1_PC2.png"), p_biplot12, width = 12, height = 9, dpi = 300)
cat("Figure 2 saved\n")


# Figure 2b: Biplot PC1 x PC2 faceted by typology
centroids12t <- scores %>%
  group_by(behavioural_group, tipo_goerlich) %>%
  summarise(PC1 = median(PC1), PC2 = median(PC2), .groups = "drop")

p_biplot12_facet <- ggplot() +
  geom_point(data = scores_plot,
             aes(x = PC1, y = PC2, colour = behavioural_group),
             alpha = 0.3, size = 0.9) +
  geom_point(data = centroids12t,
             aes(x = PC1, y = PC2, fill = behavioural_group),
             shape = 23, size = 4.5, stroke = 0.7, colour = "white") +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#bbbbbb", linewidth = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#bbbbbb", linewidth = 0.4) +
  facet_wrap(~ tipo_goerlich, labeller = labeller(tipo_goerlich = c(
    "Rural - Remoto"    = "Rural-Remote",
    "Rural - Accesible" = "Rural-Accessible"))) +
  scale_colour_manual(values = GROUP_COLORS, breaks = GROUP_ORDER,
                      labels = GROUP_LABELS, name = "Behavioural group") +
  scale_fill_manual(values   = GROUP_COLORS, breaks = GROUP_ORDER,
                    labels   = GROUP_LABELS, name = "Behavioural group") +
  labs(title   = "PCA scores - PC1 x PC2 by typology",
       x       = sprintf("PC1 (%.1f%%)", var_pct[1]),
       y       = sprintf("PC2 (%.1f%%)", var_pct[2]),
       caption = "Diamonds = group medians. Source: INE; SIDAMUN (MITERD, 2023).") +
  theme_rurimescape() + theme(legend.position = "bottom")

ggsave(file.path(FIG_DIR, "p5c_fig2b_biplot_PC1_PC2_by_typology.png"),
       p_biplot12_facet, width = 12, height = 6, dpi = 300)
cat("Figure 2b saved\n")


# Figure 3: Biplot PC1 x PC3
load_arrows3 <- loadings_df %>%
  mutate(xend = PC1 * arrow_scale, yend = PC3 * arrow_scale) %>%
  filter(abs(PC1) > 0.2 | abs(PC3) > 0.2)
load_arrows3$arrow_colour <- BLOCK_COLORS[load_arrows3$block]

centroids13 <- scores %>%
  group_by(behavioural_group) %>%
  summarise(PC1 = median(PC1), PC3 = median(PC3), .groups = "drop")

p_biplot13 <- ggplot() +
  geom_point(data = scores_plot,
             aes(x = PC1, y = PC3, colour = behavioural_group),
             alpha = 0.3, size = 1.0) +
  geom_point(data = centroids13,
             aes(x = PC1, y = PC3, fill = behavioural_group),
             shape = 23, size = 5, stroke = 0.8, colour = "white") +
  geom_segment(data = load_arrows3,
               aes(x = 0, y = 0, xend = xend, yend = yend),
               colour = load_arrows3$arrow_colour,
               arrow = arrow(length = unit(0.25, "cm"), type = "closed"),
               linewidth = 0.8) +
  geom_text_repel(data = load_arrows3,
                  aes(x = xend * 1.15, y = yend * 1.15, label = short_label),
                  size = 4.0, max.overlaps = 50,
                  force = 6, force_pull = 0.2,
                  box.padding = 0.8, point.padding = 0.3,
                  min.segment.length = 0,
                  segment.size = 0.3, segment.colour = "#888888") +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#bbbbbb", linewidth = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#bbbbbb", linewidth = 0.4) +
  scale_colour_manual(values = GROUP_COLORS, breaks = GROUP_ORDER,
                      labels = GROUP_LABELS, name = "Behavioural group") +
  scale_fill_manual(values   = GROUP_COLORS, breaks = GROUP_ORDER,
                    labels   = GROUP_LABELS, name = "Behavioural group") +
  labs(title   = "PCA biplot - PC1 x PC3",
       x       = sprintf("PC1 (%.1f%% variance)", var_pct[1]),
       y       = sprintf("PC3 (%.1f%% variance)", var_pct[3]),
       caption = "Diamonds = group medians. Source: INE; SIDAMUN (MITERD, 2023).") +
  theme_rurimescape()

ggsave(file.path(FIG_DIR, "p5c_fig3_biplot_PC1_PC3.png"), p_biplot13, width = 12, height = 9, dpi = 300)
cat("Figure 3 saved\n")


# Figure 4: Loadings heatmap (PC1-PC6)
n_pcs_heat <- min(6, ncol(pca_result$rotation))

load_long <- loadings_df %>%
  select(short_label, block, all_of(paste0("PC", 1:n_pcs_heat))) %>%
  pivot_longer(cols = starts_with("PC"), names_to = "Component", values_to = "Loading") %>%
  mutate(short_label = factor(short_label, levels = rev(keep_labels)),
         Component   = factor(Component,   levels = paste0("PC", 1:n_pcs_heat)))

p_heatmap <- ggplot(load_long, aes(x = Component, y = short_label, fill = Loading)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  geom_text(aes(label = ifelse(abs(Loading) > 0.25, sprintf("%.2f", Loading), "")),
            size = 3.8, colour = "black", fontface = "bold") +
  scale_fill_gradient2(low = "#2c7bb6", mid = "white", high = "#d7191c",
                       midpoint = 0, limits = c(-1, 1), name = "Loading") +
  facet_grid(block ~ ., scales = "free_y", space = "free_y") +
  labs(title    = "PCA loadings heatmap (PC1-PC6)",
       subtitle = "Values shown where |loading| > 0.25",
       x        = "Principal component", y = NULL,
       caption  = "Source: INE; SIDAMUN (MITERD, 2023).") +
  theme_rurimescape(base_size = 11) +
  theme(axis.text.y   = element_text(size = 10),
        strip.text.y  = element_text(angle = 0, size = 9, face = "bold"),
        panel.spacing = unit(0.15, "lines"))

ggsave(file.path(FIG_DIR, "p5c_fig4_loadings_heatmap.png"),
       p_heatmap, width = 10, height = 13, dpi = 300)
cat("Figure 4 saved\n")


# Figure 5: PC1 density by group x typology
medians_pc1 <- scores %>%
  group_by(behavioural_group) %>%
  summarise(med = median(PC1), .groups = "drop")

p_density <- ggplot(scores, aes(x = PC1, fill = behavioural_group,
                                colour = behavioural_group)) +
  geom_density(alpha = 0.35, linewidth = 0.7) +
  geom_vline(data = medians_pc1,
             aes(xintercept = med, colour = behavioural_group),
             linetype = "dashed", linewidth = 0.8) +
  facet_wrap(~ tipo_goerlich, ncol = 1, labeller = labeller(tipo_goerlich = c(
    "Rural - Remoto"    = "Rural-Remote",
    "Rural - Accesible" = "Rural-Accessible"))) +
  scale_fill_manual(values   = GROUP_COLORS, breaks = GROUP_ORDER,
                    labels   = GROUP_LABELS, name = "Behavioural group") +
  scale_colour_manual(values = GROUP_COLORS, breaks = GROUP_ORDER,
                      labels = GROUP_LABELS, name = "Behavioural group") +
  labs(title    = "PC1 score distribution by behavioural group",
       subtitle = "Dashed lines = group medians",
       x        = sprintf("PC1 (%.1f%% variance)", var_pct[1]),
       y        = "Density",
       caption  = "Source: INE; SIDAMUN (MITERD, 2023).") +
  theme_rurimescape()

ggsave(file.path(FIG_DIR, "p5c_fig5_scores_density_PC1.png"),
       p_density, width = 9, height = 8, dpi = 300)
cat("Figure 5 saved\n")


# ── 9. Export for p5d ───────────────────────────────────────────────────────────
cat("\n-- Exporting objects for p5d --\n")

scores_export <- scores %>%
  select(Mun_Code, behavioural_group, tipo_goerlich, everything())
write.csv(scores_export, file.path(DER_DIR, "p5c_pca_scores.csv"), row.names = FALSE)
cat("Scores CSV saved\n")

pca_meta <- list(
  pca_result  = pca_result,
  X_scaled    = X_scaled,
  var_labels  = keep_labels,
  var_blocks  = keep_blocks,
  var_pct     = var_pct,
  var_cum     = var_cum,
  scores      = scores,
  df_meta     = df[, c("Mun_Code", "Mun_Name", "behavioural_group",
                       "tipo_goerlich", "Prov_Code", "Prov_Name",
                       "CCAA_Code", "CCAA_Name")]
)
saveRDS(pca_meta, file.path(DER_DIR, "p5c_pca_metadata.rds"))
cat("PCA metadata RDS saved\n")


# ── 10. Summary ─────────────────────────────────────────────────────────────────
cat("\n==================================================\n")
cat("p5c PCA complete.\n")
cat("Variables in PCA :", ncol(X_raw), "\n")
cat("Municipalities   :", nrow(X_raw), "\n")
cat(sprintf("PC1: %.1f%%  PC2: %.1f%%  PC3: %.1f%%\n", var_pct[1], var_pct[2], var_pct[3]))
cat(sprintf("PCs to 80%% variance: %d\n", n_comps_80))
cat("\nTop 5 variables on PC1 (by |loading|):\n")
top5 <- head(tab4[order(abs(tab4$PC1), decreasing = TRUE), ], 5)
for (i in 1:5) cat(sprintf("  %d. %s (loading = %.3f)\n", i, top5$short_label[i], top5$PC1[i]))
cat("\nOutputs:\n")
cat("  Figures ->", FIG_DIR, "\n")
cat("  Tables  ->", TAB_DIR, "\n")
cat("  p5d RDS ->", file.path(DER_DIR, "p5c_pca_metadata.rds"), "\n")
cat("==================================================\n")


# ── 11. Word export (scientific format) ────────────────────────────────────────
# Uses flextable + officer, matching p5b_tables.R style:
# Calibri 10pt, theme_booktabs(), captions, page breaks between tables.

suppressPackageStartupMessages({
  library(flextable)
  library(officer)
})

OUTPUT_WORD <- file.path(TAB_DIR, "p5c_pca_tables.docx")

# ── Shared flextable style helper ─────────────────────────────────────────────
fmt_ft <- function(ft, caption_text) {
  ft %>%
    bold(part = "header") %>%
    fontsize(size = 10, part = "all") %>%
    font(fontname = "Calibri", part = "all") %>%
    theme_booktabs() %>%
    autofit() %>%
    set_caption(caption_text)
}

# ── Word Table 1: Variance explained ──────────────────────────────────────────
# Show all PCs up to 80% + 2 extra for context
n_tab_rows <- min(n_comps_80 + 2, ncol(X_scaled))

wt1 <- data.frame(
  Component           = paste0("PC", seq_len(n_tab_rows)),
  Eigenvalue          = round(var_exp[1:n_tab_rows], 3),
  Variance_pct        = round(var_pct[1:n_tab_rows], 2),
  Cumulative_pct      = round(var_cum[1:n_tab_rows], 2)
)

ft_wt1 <- flextable(wt1) %>%
  set_header_labels(
    Component      = "Component",
    Eigenvalue     = "Eigenvalue",
    Variance_pct   = "Variance (%)",
    Cumulative_pct = "Cumulative variance (%)"
  ) %>%
  align(j = c("Eigenvalue", "Variance_pct", "Cumulative_pct"),
        align = "right", part = "all") %>%
  # Highlight the row reaching 80%
  bg(i = which(wt1$Cumulative_pct >= 80)[1],
     bg = "#e8f4f8", part = "body") %>%
  fmt_ft(sprintf(
    "Table 1. Variance explained by principal components (PCA, n = %d municipalities, %d variables). Highlighted row = first component reaching 80%% cumulative variance.",
    nrow(X_raw), ncol(X_raw)
  ))

# ── Word Table 2: Loadings on PC1, PC2, PC3 ───────────────────────────────────
# All variables sorted by |PC1|, with block column for readability
wt2 <- loadings_df %>%
  select(short_label, block, PC1, PC2, PC3) %>%
  arrange(desc(abs(PC1))) %>%
  mutate(
    PC1 = round(PC1, 3),
    PC2 = round(PC2, 3),
    PC3 = round(PC3, 3)
  ) %>%
  rename(Variable = short_label, Block = block)

ft_wt2 <- flextable(wt2) %>%
  set_header_labels(
    Variable = "Variable",
    Block    = "Thematic block",
    PC1      = "PC1",
    PC2      = "PC2",
    PC3      = "PC3"
  ) %>%
  # Highlight loadings > |0.25| in PC1
  color(i = ~ abs(PC1) > 0.25, j = "PC1", color = "#c00000", part = "body") %>%
  color(i = ~ abs(PC2) > 0.25, j = "PC2", color = "#c00000", part = "body") %>%
  color(i = ~ abs(PC3) > 0.25, j = "PC3", color = "#c00000", part = "body") %>%
  bold(i = ~ abs(PC1) > 0.25, j = "PC1", part = "body") %>%
  align(j = c("PC1", "PC2", "PC3"), align = "right", part = "all") %>%
  fmt_ft(sprintf(
    "Table 2. PCA variable loadings on PC1, PC2 and PC3 (sorted by |PC1|). PC1 = %.1f%% variance; PC2 = %.1f%%; PC3 = %.1f%%. Values in red bold indicate |loading| > 0.25.",
    var_pct[1], var_pct[2], var_pct[3]
  ))

# ── Word Table 3: Variable contributions (%) to PC1, PC2, PC3 ─────────────────
wt3 <- tab4 %>%
  select(short_label, block, PC1, PC2, PC3, contrib_PC1, contrib_PC2, contrib_PC3) %>%
  rename(
    Variable    = short_label,
    Block       = block,
    Loading_PC1 = PC1,
    Loading_PC2 = PC2,
    Loading_PC3 = PC3,
    Contrib_PC1 = contrib_PC1,
    Contrib_PC2 = contrib_PC2,
    Contrib_PC3 = contrib_PC3
  )

ft_wt3 <- flextable(wt3) %>%
  set_header_labels(
    Variable    = "Variable",
    Block       = "Block",
    Loading_PC1 = "Loading\nPC1",
    Loading_PC2 = "Loading\nPC2",
    Loading_PC3 = "Loading\nPC3",
    Contrib_PC1 = "Contrib.\nPC1 (%)",
    Contrib_PC2 = "Contrib.\nPC2 (%)",
    Contrib_PC3 = "Contrib.\nPC3 (%)"
  ) %>%
  align(j = c("Loading_PC1","Loading_PC2","Loading_PC3",
              "Contrib_PC1","Contrib_PC2","Contrib_PC3"),
        align = "right", part = "all") %>%
  # Top 5 contributors to PC1 highlighted
  bg(i = 1:5, bg = "#fff2cc", part = "body") %>%
  fmt_ft("Table 3. Variable contributions (%) to PC1, PC2 and PC3. Sorted by contribution to PC1 (descending). Yellow rows = top 5 contributors to PC1.")

# ── Word Table 4: Median PC scores by group × typology ────────────────────────
wt4 <- tab3 %>%
  mutate(
    behavioural_group = recode(behavioural_group,
                               "Grows in both"           = "Dynamisers",
                               "Reverses in B"           = "Reverters",
                               "Loses in B"              = "Loses in B",
                               "Structural depopulation" = "Structural decline"
    ),
    tipo_goerlich = recode(tipo_goerlich,
                           "Rural - Remoto"    = "Rural-Remote",
                           "Rural - Accesible" = "Rural-Accessible"
    )
  ) %>%
  rename(
    Group    = behavioural_group,
    Typology = tipo_goerlich,
    N        = n,
    PC1_med  = PC1_med,
    PC2_med  = PC2_med,
    PC3_med  = PC3_med
  )

ft_wt4 <- flextable(wt4) %>%
  set_header_labels(
    Group    = "Behavioural group",
    Typology = "Typology",
    N        = "n",
    PC1_med  = "Median PC1",
    PC2_med  = "Median PC2",
    PC3_med  = "Median PC3"
  ) %>%
  align(j = c("N", "PC1_med", "PC2_med", "PC3_med"),
        align = "right", part = "all") %>%
  # Colour rows by typology
  bg(i = ~ Typology == "Rural-Remote",     bg = "#f2f2f2", part = "body") %>%
  bg(i = ~ Typology == "Rural-Accessible", bg = "#ffffff", part = "body") %>%
  fmt_ft(sprintf(
    "Table 4. Median PC scores by behavioural group and typology (n = %d municipalities total). Higher PC1 = more aged socioeconomic profile.",
    nrow(X_raw)
  ))

# ── Assemble Word document ─────────────────────────────────────────────────────
doc <- read_docx() %>%
  # Title
  body_add_par("Step 5c — PCA: Summary Tables", style = "heading 1") %>%
  body_add_par(
    sprintf("PCA on %d variables, %d rural municipalities (Rural-Remote + Rural-Accessible). PC1: %.1f%% | PC2: %.1f%% | PC3: %.1f%%. PCs to 80%% variance: %d.",
            ncol(X_raw), nrow(X_raw), var_pct[1], var_pct[2], var_pct[3], n_comps_80),
    style = "Normal"
  ) %>%
  body_add_par("", style = "Normal") %>%
  
  # Table 1
  body_add_par("Table 1. Variance explained", style = "heading 2") %>%
  body_add_flextable(ft_wt1) %>%
  body_add_par("", style = "Normal") %>%
  body_add_break() %>%
  
  # Table 2
  body_add_par("Table 2. Variable loadings (PC1–PC3)", style = "heading 2") %>%
  body_add_flextable(ft_wt2) %>%
  body_add_par("", style = "Normal") %>%
  body_add_break() %>%
  
  # Table 3
  body_add_par("Table 3. Variable contributions (%)", style = "heading 2") %>%
  body_add_flextable(ft_wt3) %>%
  body_add_par("", style = "Normal") %>%
  body_add_break() %>%
  
  # Table 4
  body_add_par("Table 4. Median PC scores by group and typology", style = "heading 2") %>%
  body_add_flextable(ft_wt4) %>%
  body_add_par("", style = "Normal")

print(doc, target = OUTPUT_WORD)
cat(sprintf("\nWord tables exported -> %s\n", basename(OUTPUT_WORD)))