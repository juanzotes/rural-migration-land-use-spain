# ══════════════════════════════════════════════════════════════════════════════
# p5d_permanova.R  — DEFINITIVE VERSION
# RURIMESCAPE — Paper 1, Step 5d
# PERMANOVA — multivariate significance of behavioural group separation
#
# Author  : Juan Zotes
# Created : 2026-06
#
# Purpose:
#   Formal non-parametric multivariate test (PERMANOVA / adonis2) of whether
#   the four rural demographic behavioural groups occupy significantly different
#   positions in the socioeconomic variable space. Run separately for:
#     (1) Rural-Remote
#     (2) Rural-Accessible
#     (3) Combined rural (both typologies)
#
#   METHODOLOGICAL NOTE:
#   Input to PERMANOVA is the matrix of PC scores from p5c (first N PCs
#   capturing >= 80% of cumulative variance), NOT the raw standardised
#   variable matrix. This is the methodologically correct pipeline:
#     p5c PCA: 44 variables -> 16 orthogonal PCs (80% variance)
#     p5d PERMANOVA: Euclidean distances on 16 PC scores
#   Using PC scores rather than X_scaled avoids redundancy, reduces
#   computational cost by ~3x, and is standard practice in multivariate
#   ecology (Legendre & Legendre, 2012).
#
#   Post-hoc pairwise PERMANOVA with Bonferroni correction (6 pairs).
#
# Requires:
#   data/demography/derived/paper1/p5c_pca_metadata.rds  (from p5c_pca.R)
#   data/demography/derived/paper1/p5c_pca_scores.csv    (from p5c_pca.R)
#
# Outputs — figures (figures/p5d_permanova/):
#   p5d_fig1_R2_barplot.png
#   p5d_fig2_pairwise_heatmap.png
#   p5d_fig3_dispersion_boxplot.png
#   p5d_fig4_pca_centroids.png
#
# Outputs — tables/CSV (figures/p5d_permanova/tables/):
#   p5d_tab1_permanova_global.csv
#   p5d_tab2_pairwise_permanova.csv
#   p5d_tab3_betadisper_results.csv
#   p5d_tab4_group_centroids_pc.csv
#
# Outputs — Word (figures/p5d_permanova/tables/):
#   p5d_permanova_tables.docx
# ══════════════════════════════════════════════════════════════════════════════


# ── 0. Libraries ───────────────────────────────────────────────────────────────
suppressPackageStartupMessages({
  library(tidyverse)
  library(vegan)
  library(ggplot2)
  library(ggrepel)
  library(patchwork)
  library(scales)
  library(flextable)
  library(officer)
})

if (!requireNamespace("vegan", quietly = TRUE))
  stop("Package 'vegan' required. Install with: install.packages('vegan')")


# ── 1. Paths ───────────────────────────────────────────────────────────────────
ROOT    <- file.path("C:/Users/juanz/OneDrive/Desktop/UCM/RURIM ESCAPE/GeoSpatial",
                     "01_Python Data Analysis/rural-migration-land-use-spain")

RDS_IN  <- file.path(ROOT, "data/demography/derived/paper1/p5c_pca_metadata.rds")
CSV_IN  <- file.path(ROOT, "data/demography/derived/paper1/p5c_pca_scores.csv")
FIG_DIR <- file.path(ROOT, "figures/p5d_permanova")
TAB_DIR <- file.path(FIG_DIR, "tables")

for (d in c(FIG_DIR, TAB_DIR)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(RDS_IN)) stop("p5c_pca_metadata.rds not found. Run p5c_pca.R first.")
if (!file.exists(CSV_IN)) stop("p5c_pca_scores.csv not found. Run p5c_pca.R first.")
cat("Inputs found\n")


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
PAIRS      <- combn(GROUP_ORDER, 2, simplify = FALSE)
ALPHA_BONF <- 0.05 / length(PAIRS)
N_PERM     <- 999


# ── 3. Load p5c objects and build PERMANOVA input ──────────────────────────────
cat("\n-- Loading p5c outputs --\n")

pca_meta  <- readRDS(RDS_IN)
scores_df <- pca_meta$scores
var_pct   <- pca_meta$var_pct
var_cum   <- pca_meta$var_cum
var_labels <- pca_meta$var_labels

# Select PCs capturing >= 80% cumulative variance
# This is the methodologically correct input: orthogonal, low-dimensional,
# avoids redundancy of 44 correlated raw variables.
n_pcs_80 <- which(var_cum >= 80)[1]
pc_cols  <- paste0("PC", 1:n_pcs_80)
X_perm   <- as.matrix(scores_df[, pc_cols])

cat(sprintf("PERMANOVA input: %d municipalities x %d PCs (%.1f%% cumulative variance)\n",
            nrow(X_perm), n_pcs_80, var_cum[n_pcs_80]))
cat(sprintf("Permutations: %d | Bonferroni alpha: %.4f (6 pairwise comparisons)\n",
            N_PERM, ALPHA_BONF))
cat("Group distribution:\n")
print(table(scores_df$behavioural_group))


# ── 4. Shared theme ────────────────────────────────────────────────────────────
theme_rurimescape <- function(base_size = 16) {
  theme_minimal(base_size = base_size) +
    theme(
      text             = element_text(size = base_size),
      axis.title       = element_text(size = base_size, face = "bold"),
      axis.text        = element_text(size = base_size - 1),
      legend.title     = element_text(size = base_size, face = "bold"),
      legend.text      = element_text(size = base_size - 1),
      plot.title       = element_text(size = base_size + 1, face = "bold"),
      plot.subtitle    = element_text(size = base_size - 1, colour = "#555555"),
      plot.caption     = element_text(size = 14, colour = "#555555", hjust = 0),
      panel.grid.minor = element_blank(),
      strip.text       = element_text(size = base_size, face = "bold")
    )
}


# ── 5. Helper functions ────────────────────────────────────────────────────────

# Global PERMANOVA + betadisper
run_permanova <- function(X, groups, label, n_perm = N_PERM) {

  groups   <- factor(groups, levels = GROUP_ORDER)
  dist_mat <- dist(X, method = "euclidean")

  set.seed(42)
  perm_result <- adonis2(dist_mat ~ groups, permutations = n_perm, by = "margin")

  R2 <- perm_result$R2[1]
  F_ <- perm_result$F[1]
  p_ <- perm_result$`Pr(>F)`[1]

  cat(sprintf("  %-22s R2 = %.4f | F = %.2f | p = %.4f\n", label, R2, F_, p_))

  set.seed(42)
  bd      <- betadisper(dist_mat, groups)
  bd_test <- permutest(bd, permutations = n_perm)

  list(label = label, n = nrow(X),
       R2 = R2, F_stat = F_, p_value = p_,
       betadisper = bd, bd_test = bd_test,
       dist_mat = dist_mat, groups = groups)
}

# Pairwise PERMANOVA with Bonferroni correction
run_pairwise <- function(X, groups, label, n_perm = N_PERM) {

  results <- vector("list", length(PAIRS))

  for (i in seq_along(PAIRS)) {
    g1  <- PAIRS[[i]][1]
    g2  <- PAIRS[[i]][2]
    idx <- which(groups %in% c(g1, g2))

    if (length(idx) < 4) {
      results[[i]] <- data.frame(
        subset = label, group1 = g1, group2 = g2,
        n1 = sum(groups == g1), n2 = sum(groups == g2),
        R2 = NA, F_stat = NA, p_raw = NA, p_bonf = NA,
        sig = "insufficient n"
      )
      next
    }

    X_sub    <- X[idx, , drop = FALSE]
    grp_sub  <- factor(groups[idx], levels = c(g1, g2))
    dist_sub <- dist(X_sub, method = "euclidean")

    set.seed(42 + i)
    res    <- adonis2(dist_sub ~ grp_sub, permutations = n_perm, by = "margin")
    p_raw  <- res$`Pr(>F)`[1]
    p_bonf <- min(p_raw * length(PAIRS), 1.0)

    results[[i]] <- data.frame(
      subset = label, group1 = g1, group2 = g2,
      n1     = sum(groups == g1),
      n2     = sum(groups == g2),
      R2     = round(res$R2[1], 4),
      F_stat = round(res$F[1],  3),
      p_raw  = round(p_raw,     4),
      p_bonf = round(p_bonf,    4),
      sig    = ifelse(p_bonf < ALPHA_BONF, "***", "ns")
    )
  }

  do.call(rbind, results)
}


# ── 6. Run PERMANOVA ───────────────────────────────────────────────────────────
cat("\n-- Running PERMANOVA --\n")
cat("(With 16 PCs this should complete in ~5-10 minutes)\n\n")

idx_rr <- scores_df$tipo_goerlich == "Rural - Remoto"
idx_ra <- scores_df$tipo_goerlich == "Rural - Accesible"

grp_all <- scores_df$behavioural_group
grp_rr  <- scores_df$behavioural_group[idx_rr]
grp_ra  <- scores_df$behavioural_group[idx_ra]

X_all <- X_perm
X_rr  <- X_perm[idx_rr, ]
X_ra  <- X_perm[idx_ra, ]

cat("-- Global PERMANOVA --\n")
perm_all <- run_permanova(X_all, grp_all, "Combined rural")
perm_rr  <- run_permanova(X_rr,  grp_rr,  "Rural-Remote")
perm_ra  <- run_permanova(X_ra,  grp_ra,  "Rural-Accessible")

cat("\n-- Pairwise PERMANOVA --\n")
cat("  Combined rural...\n")
pw_all <- run_pairwise(X_all, grp_all, "Combined rural")
cat("  Rural-Remote...\n")
pw_rr  <- run_pairwise(X_rr,  grp_rr,  "Rural-Remote")
cat("  Rural-Accessible...\n")
pw_ra  <- run_pairwise(X_ra,  grp_ra,  "Rural-Accessible")

cat("\nPairwise PERMANOVA complete\n")


# ── 7. Tables (CSV) ────────────────────────────────────────────────────────────
cat("\n-- Building tables --\n")

# Table 1: Global PERMANOVA
tab1 <- data.frame(
  Subset   = c("Combined rural", "Rural-Remote", "Rural-Accessible"),
  n        = c(perm_all$n,      perm_rr$n,      perm_ra$n),
  n_PCs    = n_pcs_80,
  R2       = round(c(perm_all$R2,     perm_rr$R2,     perm_ra$R2),     4),
  F_stat   = round(c(perm_all$F_stat, perm_rr$F_stat, perm_ra$F_stat), 3),
  p_value  = c(perm_all$p_value, perm_rr$p_value, perm_ra$p_value),
  n_perm   = N_PERM,
  distance = "Euclidean (PC scores)",
  note     = paste0("4 groups; Bonferroni alpha = ", round(ALPHA_BONF, 4))
)
write.csv(tab1, file.path(TAB_DIR, "p5d_tab1_permanova_global.csv"), row.names = FALSE)
cat("Table 1 saved\n")

# Table 2: Pairwise PERMANOVA
tab2 <- bind_rows(pw_all, pw_rr, pw_ra) %>%
  mutate(group1 = recode(group1, !!!GROUP_LABELS),
         group2 = recode(group2, !!!GROUP_LABELS))
write.csv(tab2, file.path(TAB_DIR, "p5d_tab2_pairwise_permanova.csv"), row.names = FALSE)
cat("Table 2 saved\n")

# Table 3: Betadisper
extract_bd <- function(perm_obj) {
  bd   <- perm_obj$betadisper
  test <- perm_obj$bd_test
  disp <- tapply(bd$distances, bd$group, median)
  data.frame(
    Subset      = perm_obj$label,
    group       = names(disp),
    median_dist = round(as.numeric(disp), 4),
    F_stat      = round(test$statistic["F"], 3),
    p_value     = round(test$tab[1, "Pr(>F)"], 4)
  )
}
tab3 <- bind_rows(extract_bd(perm_all), extract_bd(perm_rr), extract_bd(perm_ra)) %>%
  mutate(group = recode(group, !!!GROUP_LABELS))
write.csv(tab3, file.path(TAB_DIR, "p5d_tab3_betadisper_results.csv"), row.names = FALSE)
cat("Table 3 saved\n")

# Table 4: Group centroids in PC space
n_pcs_tab <- min(6, length(pc_cols))
tab4 <- scores_df %>%
  group_by(tipo_goerlich, behavioural_group) %>%
  summarise(n = n(),
            across(paste0("PC", 1:n_pcs_tab), ~ round(median(.), 3),
                   .names = "median_{.col}"),
            .groups = "drop") %>%
  arrange(tipo_goerlich, behavioural_group) %>%
  mutate(behavioural_group = recode(behavioural_group, !!!GROUP_LABELS))
write.csv(tab4, file.path(TAB_DIR, "p5d_tab4_group_centroids_pc.csv"), row.names = FALSE)
cat("Table 4 saved\n")


# ── 8. Figures ─────────────────────────────────────────────────────────────────
cat("\n-- Generating figures --\n")

# Figure 1: R2 barplot
r2_df <- tab1 %>%
  mutate(
    R2_pct    = R2 * 100,
    sig_label = paste0("R2 = ", round(R2, 3),
                       "\nF = ", round(F_stat, 2),
                       "\np ", ifelse(p_value < 0.001, "< 0.001",
                                      paste("=", round(p_value, 3))))
  )

p_r2 <- ggplot(r2_df, aes(x = Subset, y = R2_pct, fill = Subset)) +
  geom_col(width = 0.55, alpha = 0.88) +
  geom_text(aes(label = sig_label), vjust = -0.3, size = 4, lineheight = 1.1) +
  scale_fill_manual(values = c(
    "Combined rural"   = "#555555",
    "Rural-Remote"     = "#d73027",
    "Rural-Accessible" = "#4575b4"
  ), guide = "none") +
  scale_y_continuous(limits = c(0, max(r2_df$R2_pct) * 1.6),
                     labels = label_number(suffix = "%")) +
  labs(title    = "PERMANOVA - Variance explained by behavioural group",
       subtitle = sprintf("%d PCs input (%d permutations) | Euclidean distance",
                          n_pcs_80, N_PERM),
       x = NULL, y = "R2 (%)",
       caption = "Source: INE, Padron Municipal (1996-2025); SIDAMUN (MITERD, 2023).") +
  theme_rurimescape()

ggsave(file.path(FIG_DIR, "p5d_fig1_R2_barplot.png"),
       p_r2, width = 7, height = 5, dpi = 300)
cat("Figure 1 saved\n")


# Figure 2: Pairwise heatmap
make_heatmap <- function(pw_df, title_str) {
  all_grps <- unname(GROUP_LABELS)

  mat_df <- pw_df %>%
    select(group1, group2, p_bonf, sig) %>%
    mutate(
      group1  = recode(group1, !!!GROUP_LABELS),
      group2  = recode(group2, !!!GROUP_LABELS),
      p_label = ifelse(sig == "***",
                       sprintf("p=%.4f\n***", p_bonf),
                       sprintf("p=%.4f\nns",  p_bonf))
    )

  sym_df <- bind_rows(mat_df, mat_df %>% rename(group1 = group2, group2 = group1)) %>%
    filter(group1 != group2) %>%
    mutate(group1 = factor(group1, levels = all_grps),
           group2 = factor(group2, levels = rev(all_grps)))

  ggplot(sym_df, aes(x = group1, y = group2, fill = p_bonf)) +
    geom_tile(colour = "white", linewidth = 0.6) +
    geom_text(aes(label = p_label), size = 3.5, lineheight = 1.2) +
    scale_fill_gradient2(low = "#d73027", mid = "#ffffbf", high = "#eeeeee",
                         midpoint = ALPHA_BONF, limits = c(0, 1),
                         name = "p (Bonferroni)") +
    labs(title = title_str, x = NULL, y = NULL) +
    theme_rurimescape(base_size = 12) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
}

p_heat_rr <- make_heatmap(pw_rr, "Rural-Remote")
p_heat_ra <- make_heatmap(pw_ra, "Rural-Accessible")

p_heat_combined <- p_heat_rr + p_heat_ra +
  plot_annotation(
    title   = "Pairwise PERMANOVA — post-hoc comparisons",
    caption = sprintf("Bonferroni alpha = %.4f (6 comparisons). Red = significant. Source: INE; SIDAMUN (MITERD, 2023).",
                      ALPHA_BONF)
  )

ggsave(file.path(FIG_DIR, "p5d_fig2_pairwise_heatmap.png"),
       p_heat_combined, width = 14, height = 6, dpi = 300)
cat("Figure 2 saved\n")


# Figure 3: Betadisper boxplot
disp_df <- data.frame(
  distance = c(perm_rr$betadisper$distances, perm_ra$betadisper$distances),
  group    = c(as.character(perm_rr$betadisper$group),
               as.character(perm_ra$betadisper$group)),
  typology = c(rep("Rural-Remote",     length(perm_rr$betadisper$distances)),
               rep("Rural-Accessible", length(perm_ra$betadisper$distances)))
) %>%
  mutate(group    = recode(group, !!!GROUP_LABELS),
         group    = factor(group, levels = unname(GROUP_LABELS)),
         typology = factor(typology, levels = c("Rural-Remote", "Rural-Accessible")))

p_disp <- ggplot(disp_df, aes(x = group, y = distance, fill = group)) +
  geom_boxplot(outlier.size = 0.5, outlier.alpha = 0.4, width = 0.55, alpha = 0.8) +
  facet_wrap(~ typology) +
  scale_fill_manual(values = setNames(GROUP_COLORS, unname(GROUP_LABELS)), guide = "none") +
  labs(title    = "Within-group multivariate dispersion (betadisper)",
       subtitle = "Distance to group centroid in PC score space",
       x = NULL, y = "Distance to centroid",
       caption = "Lower = more internally homogeneous group. Source: INE; SIDAMUN (MITERD, 2023).") +
  theme_rurimescape() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))

ggsave(file.path(FIG_DIR, "p5d_fig3_dispersion_boxplot.png"),
       p_disp, width = 10, height = 5, dpi = 300)
cat("Figure 3 saved\n")


# Figure 4: Group centroids in PC1 x PC2 with ellipses
centroids_df <- scores_df %>%
  group_by(behavioural_group, tipo_goerlich) %>%
  summarise(PC1 = median(PC1), PC2 = median(PC2), n = n(), .groups = "drop") %>%
  mutate(label = paste0(recode(behavioural_group, !!!GROUP_LABELS), "\n(n=", n, ")"))

p_centroids <- ggplot() +
  stat_ellipse(data = scores_df,
               aes(x = PC1, y = PC2, colour = behavioural_group,
                   fill = behavioural_group),
               type = "norm", level = 0.68,
               geom = "polygon", alpha = 0.08, linewidth = 0.4) +
  geom_point(data = centroids_df,
             aes(x = PC1, y = PC2, fill = behavioural_group),
             shape = 23, size = 5, stroke = 0.8, colour = "white") +
  geom_text_repel(data = centroids_df,
                  aes(x = PC1, y = PC2, label = label,
                      colour = behavioural_group),
                  size = 3.5, fontface = "bold", max.overlaps = 10,
                  segment.size = 0.3) +
  facet_wrap(~ tipo_goerlich, labeller = labeller(tipo_goerlich = c(
    "Rural - Remoto"    = "Rural-Remote",
    "Rural - Accesible" = "Rural-Accessible"))) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#bbbbbb", linewidth = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#bbbbbb", linewidth = 0.4) +
  scale_colour_manual(values = GROUP_COLORS, guide = "none") +
  scale_fill_manual(values   = GROUP_COLORS, guide = "none") +
  labs(title    = "Group centroids in PCA space (PC1 x PC2)",
       subtitle = sprintf("Remote: R2 = %.3f, p < 0.001 | Accessible: R2 = %.3f, p < 0.001",
                          perm_rr$R2, perm_ra$R2),
       x       = sprintf("PC1 (%.1f%% variance)", var_pct[1]),
       y       = sprintf("PC2 (%.1f%% variance)", var_pct[2]),
       caption = "Ellipses = 68% normal confidence ellipse. Diamonds = group medians.\nSource: INE, Padron Municipal (1996-2025); SIDAMUN (MITERD, 2023).") +
  theme_rurimescape()

ggsave(file.path(FIG_DIR, "p5d_fig4_pca_centroids.png"),
       p_centroids, width = 12, height = 6, dpi = 300)
cat("Figure 4 saved\n")


# ── 9. Word export ─────────────────────────────────────────────────────────────
cat("\n-- Exporting Word tables --\n")

OUTPUT_WORD <- file.path(TAB_DIR, "p5d_permanova_tables.docx")

fmt_ft <- function(ft, caption_text) {
  ft %>%
    bold(part = "header") %>%
    fontsize(size = 10, part = "all") %>%
    font(fontname = "Calibri", part = "all") %>%
    theme_booktabs() %>%
    autofit() %>%
    set_caption(caption_text)
}

# Word Table 1: Global PERMANOVA
wt1 <- tab1 %>% select(Subset, n, n_PCs, R2, F_stat, p_value, n_perm, distance)
ft_wt1 <- flextable(wt1) %>%
  set_header_labels(
    Subset = "Subset", n = "n", n_PCs = "PCs",
    R2 = "R2", F_stat = "F", p_value = "p-value",
    n_perm = "Permutations", distance = "Distance"
  ) %>%
  fmt_ft(sprintf(
    "Table 1. Global PERMANOVA results. Input: %d PC scores (%.1f%% cumulative variance). 4 behavioural groups. Euclidean distance.",
    n_pcs_80, var_cum[n_pcs_80]
  ))

# Word Table 2: Pairwise PERMANOVA
ft_wt2 <- flextable(tab2) %>%
  set_header_labels(
    subset = "Subset", group1 = "Group 1", group2 = "Group 2",
    n1 = "n1", n2 = "n2", R2 = "R2", F_stat = "F",
    p_raw = "p (raw)", p_bonf = "p (Bonferroni)", sig = ""
  ) %>%
  bold(j = "sig") %>%
  color(i = ~ sig == "***", j = "sig", color = "#c00000") %>%
  fmt_ft(sprintf(
    "Table 2. Pairwise PERMANOVA with Bonferroni correction (alpha = %.4f, 6 comparisons). *** = significant after correction.",
    ALPHA_BONF
  ))

# Word Table 3: Betadisper
ft_wt3 <- flextable(tab3) %>%
  set_header_labels(
    Subset = "Subset", group = "Group",
    median_dist = "Median distance to centroid",
    F_stat = "F (betadisper)", p_value = "p-value"
  ) %>%
  fmt_ft("Table 3. Homogeneity of multivariate dispersion (betadisper). Significant p < 0.05 indicates heterogeneous within-group dispersion; interpret PERMANOVA results with caution.")

# Word Table 4: Centroids
ft_wt4 <- flextable(tab4) %>%
  fmt_ft("Table 4. Median PC scores by behavioural group and typology. Higher PC1 = more aged demographic profile.")

doc <- read_docx() %>%
  body_add_par("Step 5d - PERMANOVA: Summary Tables", style = "heading 1") %>%
  body_add_par(sprintf(
    "PERMANOVA on %d PC scores (%d PCs, %.1f%% cumulative variance). n = %d municipalities. %d permutations. Euclidean distance. Bonferroni alpha = %.4f.",
    n_pcs_80, n_pcs_80, var_cum[n_pcs_80], nrow(X_perm), N_PERM, ALPHA_BONF),
    style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("Table 1. Global PERMANOVA", style = "heading 2") %>%
  body_add_flextable(ft_wt1) %>%
  body_add_par("", style = "Normal") %>%
  body_add_break() %>%
  body_add_par("Table 2. Pairwise PERMANOVA", style = "heading 2") %>%
  body_add_flextable(ft_wt2) %>%
  body_add_par("", style = "Normal") %>%
  body_add_break() %>%
  body_add_par("Table 3. Betadisper", style = "heading 2") %>%
  body_add_flextable(ft_wt3) %>%
  body_add_par("", style = "Normal") %>%
  body_add_break() %>%
  body_add_par("Table 4. Group centroids", style = "heading 2") %>%
  body_add_flextable(ft_wt4) %>%
  body_add_par("", style = "Normal")

print(doc, target = OUTPUT_WORD)
cat(sprintf("Word tables exported -> %s\n", basename(OUTPUT_WORD)))


# ── 10. Summary ────────────────────────────────────────────────────────────────
cat("\n==================================================\n")
cat("p5d PERMANOVA complete.\n\n")
cat("PERMANOVA INPUT\n")
cat(sprintf("  %d PCs | %.1f%% cumulative variance | %d municipalities\n",
            n_pcs_80, var_cum[n_pcs_80], nrow(X_perm)))
cat("\nGLOBAL RESULTS\n")
for (perm in list(perm_all, perm_rr, perm_ra)) {
  cat(sprintf("  %-22s R2 = %.4f  F = %.2f  p = %.4f\n",
              perm$label, perm$R2, perm$F_stat, perm$p_value))
}
cat("\nBETADISPER\n")
for (perm in list(perm_all, perm_rr, perm_ra)) {
  bd_p <- perm$bd_test$tab[1, "Pr(>F)"]
  cat(sprintf("  %-22s p = %.4f  %s\n",
              perm$label, bd_p,
              ifelse(bd_p < 0.05,
                     "WARNING: heterogeneous dispersion",
                     "OK: homogeneous dispersion")))
}
cat(sprintf("\nPAIRWISE (Bonferroni alpha = %.4f)\n", ALPHA_BONF))
for (pw in list(pw_rr, pw_ra)) {
  cat(sprintf("  %s:\n", pw$subset[1]))
  for (i in 1:nrow(pw)) {
    cat(sprintf("    %-25s vs %-25s R2=%.4f p_bonf=%.4f %s\n",
                pw$group1[i], pw$group2[i],
                pw$R2[i], pw$p_bonf[i], pw$sig[i]))
  }
}
cat("\nOutputs:\n")
cat("  Figures ->", FIG_DIR, "\n")
cat("  Tables  ->", TAB_DIR, "\n")
cat("==================================================\n")

# ══════════════════════════════════════════════════════════════════════════════
# FIGURAS EN CASTELLANO — p5d
# Pegar al final del script. Requiere que todos los objetos anteriores
# (perm_rr, perm_ra, scores_df, disp_df, tab2, var_pct, etc.) estén en memoria.
# ══════════════════════════════════════════════════════════════════════════════

GROUP_LABELS_ES <- c(
  "Grows in both"           = "Dinamizadores",
  "Reverses in B"           = "Reversores",
  "Loses in B"              = "Pérdida en B",
  "Structural depopulation" = "Despoblación estructural"
)

TYPOLOGY_LABELS_ES <- c(
  "Rural-Remote"      = "Rural-Remoto",
  "Rural-Accessible"  = "Rural-Accesible"
)

SOURCE_ES <- "Fuente: elaboración propia a partir del Padrón Municipal de Habitantes (INE, 1996–2025) y SIDAMUN (MITERD, 2023)."

# ── Fig 3 ES: Boxplot betadisper ─────────────────────────────────────────────
disp_df_es <- disp_df %>%
  mutate(
    group    = recode(group,
                      "Dynamisers"         = "Dinamizadores",
                      "Reverters"          = "Reversores",
                      "Loses in B"         = "Pérdida en B",
                      "Structural decline" = "Despoblación estructural"),
    group    = factor(group, levels = unname(GROUP_LABELS_ES)),
    typology = recode(typology, !!!TYPOLOGY_LABELS_ES),
    typology = factor(typology, levels = c("Rural-Remoto", "Rural-Accesible"))
  )

p_disp_es <- ggplot(disp_df_es,
                    aes(x = group, y = distance, fill = group)) +
  geom_boxplot(outlier.size = 0.5, outlier.alpha = 0.4,
               width = 0.55, alpha = 0.8) +
  facet_wrap(~ typology) +
  scale_fill_manual(
    values = setNames(GROUP_COLORS, unname(GROUP_LABELS_ES)),
    guide  = "none"
  ) +
  labs(title    = "Dispersión multivariante intragrupo (betadisper)",
       subtitle = "Distancia al centroide del grupo en el espacio de puntuaciones de CP",
       x = NULL, y = "Distancia al centroide",
       caption  = paste0("Valores menores indican mayor homogeneidad interna del grupo. ",
                         SOURCE_ES)) +
  theme_rurimescape() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))

ggsave(file.path(FIG_DIR, "p5d_fig3_dispersion_boxplot_es.png"),
       p_disp_es, width = 10, height = 5, dpi = 300)
cat("Fig 3 ES guardada\n")


# ── Fig 4 ES: Centroides en espacio ACP con elipses ──────────────────────────
centroids_df_es <- scores_df %>%
  group_by(behavioural_group, tipo_goerlich) %>%
  summarise(PC1 = median(PC1), PC2 = median(PC2), n = n(), .groups = "drop") %>%
  mutate(label = paste0(recode(behavioural_group, !!!GROUP_LABELS_ES),
                        "\n(n=", n, ")"))

p_centroids_es <- ggplot() +
  stat_ellipse(data = scores_df,
               aes(x = PC1, y = PC2,
                   colour = behavioural_group,
                   fill   = behavioural_group),
               type = "norm", level = 0.68,
               geom = "polygon", alpha = 0.08, linewidth = 0.4) +
  geom_point(data = centroids_df_es,
             aes(x = PC1, y = PC2, fill = behavioural_group),
             shape = 23, size = 5, stroke = 0.8, colour = "white") +
  geom_text_repel(data = centroids_df_es,
                  aes(x = PC1, y = PC2, label = label,
                      colour = behavioural_group),
                  size = 3.5, fontface = "bold",
                  max.overlaps = 10, segment.size = 0.3) +
  facet_wrap(~ tipo_goerlich,
             labeller = labeller(tipo_goerlich = c(
               "Rural - Remoto"    = "Rural-Remoto",
               "Rural - Accesible" = "Rural-Accesible"))) +
  geom_hline(yintercept = 0, linetype = "dashed",
             colour = "#bbbbbb", linewidth = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed",
             colour = "#bbbbbb", linewidth = 0.4) +
  scale_colour_manual(values = GROUP_COLORS, guide = "none") +
  scale_fill_manual(values   = GROUP_COLORS, guide = "none") +
  labs(title    = "Centroides de grupo en el espacio del ACP (CP1 × CP2)",
       subtitle = sprintf("Rural-Remoto: R² = %.3f, p < 0,001 | Rural-Accesible: R² = %.3f, p < 0,001",
                          perm_rr$R2, perm_ra$R2),
       x       = sprintf("CP1 (%.1f%% de varianza)", var_pct[1]),
       y       = sprintf("CP2 (%.1f%% de varianza)", var_pct[2]),
       caption = paste0("Elipses = elipse de confianza normal al 68%. ",
                        "Los rombos indican las medianas de grupo.\n",
                        SOURCE_ES)) +
  theme_rurimescape()

ggsave(file.path(FIG_DIR, "p5d_fig4_pca_centroids_es.png"),
       p_centroids_es, width = 12, height = 6, dpi = 300)
cat("Fig 4 ES guardada\n")

cat("\n-- Figuras en castellano (p5d) guardadas en:", FIG_DIR, "--\n")
