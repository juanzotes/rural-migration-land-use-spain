# RurIm Escape
**Geospatial analysis of rural migration and land use change in Spain**

![Python](https://img.shields.io/badge/python-3.11+-blue.svg) ![R](https://img.shields.io/badge/R-4.0+-276DC3.svg) ![Status](https://img.shields.io/badge/status-active-brightgreen.svg)

---

## 📋 Project Summary

**RurIm Escape** investigates demographic change in Spanish municipalities, with a special focus on rural recovery and recent migration patterns.

The project integrates INE municipal registry data with administrative hierarchies, functional typologies and spatial analysis to:

- download, parse and harmonize the historical INE Padrón Municipal series (1996–2025) via the INE JSON API, resolving code changes, ghost municipality codes and year coverage issues;
- compute municipality-year demographic attributes including total population, population density and sex ratio using official boundary geometries and area calculations;
- estimate annual net register variation and derive migration balance from Natural Population Movement (MNP) statistics to identify the demographic turning point around 2018;
- define symmetric pre/post periods (2010–2017 and 2018–2025), classify rural municipalities into behavioural groups, and compare Rural-Accessible versus Rural-Remote trajectories;
- detect spatial hotspots and local outliers through Local Moran's I, and characterise socioeconomic structure with SIDAMUN database (MITERD, 2023) variables, PCA, PERMANOVA and logistic regression within the Goerlich rural–urban typology framework.

---

## 📁 Current Repository Structure

```
rural-migration-land-use-spain/
├── data/
│   ├── agriculture_livestock/
│   │   ├── derived/
│   │   ├── processed/
│   │   └── raw/
│   ├── demography/
│   │   ├── derived/
│   │   │   ├── 02_population_density_1996_2025.csv
│   │   │   ├── demography_sex_ratio_1996_2025.csv
│   │   │   ├── nan/
│   │   │   ├── padron-variations/
│   │   │   ├── paper1/
│   │   │   │   ├── discussion_HL_dynamiser.csv
│   │   │   │   ├── discussion_HL_reverter.csv
│   │   │   │   ├── discussion_LH.csv
│   │   │   │   ├── p1b_annual_mig_balance_by_size.csv
│   │   │   │   ├── p1b_annual_mig_balance_by_typology.csv
│   │   │   │   ├── p1b_annual_mig_balance_national.csv
│   │   │   │   ├── p1b_mnp_vegetative_balance_raw.csv
│   │   │   │   ├── p1_annual_net_change_by_size.csv
│   │   │   │   ├── p1_annual_net_change_by_typology.csv
│   │   │   │   ├── p1_annual_net_change_national.csv
│   │   │   │   ├── p2_admin_agg_ccaa.csv
│   │   │   │   ├── p2_admin_agg_comarca.csv
│   │   │   │   ├── p2_admin_agg_prov.csv
│   │   │   │   ├── p2_periods_AB_combined.csv
│   │   │   │   ├── p2_period_A_2010_2017.csv
│   │   │   │   ├── p2_period_B_2018_2025.csv
│   │   │   │   ├── p3_behavioural_matrix.csv
│   │   │   │   ├── p3_matrix_summary.csv
│   │   │   │   ├── p3_top_growing_rural.csv
│   │   │   │   ├── p4_cluster_summary.csv
│   │   │   │   ├── p4_dynamisers_classified.csv
│   │   │   │   ├── p4_reverters_classified.csv
│   │   │   │   ├── p5a_descriptive_stats.csv
│   │   │   │   ├── p5a_dunn_results.csv
│   │   │   │   ├── p5a_kruskal_wallis_results.csv
│   │   │   │   ├── p5a_lisa_descriptive_stats.csv
│   │   │   │   ├── p5a_lisa_dunn_results.csv
│   │   │   │   ├── p5a_lisa_kw_results.csv
│   │   │   │   ├── p5a_master_dataset.csv
│   │   │   │   ├── p5a_rural_analysis_dataset.csv
│   │   │   │   ├── p5a_selected_variables.csv
│   │   │   │   ├── p5a_spearman_correlations.csv
│   │   │   │   ├── p5b_lisa_exploratory_metrics.csv
│   │   │   │   ├── p5b_lisa_model_coefficients.csv
│   │   │   │   ├── p5b_lisa_model_metrics.csv
│   │   │   │   ├── p5b_model_coefficients.csv
│   │   │   │   ├── p5b_model_metrics.csv
│   │   │   │   ├── p5b_summary_tables.docx
│   │   │   │   ├── p5b_summary_tables.pdf
│   │   │   │   ├── p5c_pca_metadata.rds
│   │   │   │   ├── p5c_pca_scores.csv
│   │   │   │   ├── p5d_hl_dynamisers_profile.csv
│   │   │   │   ├── p5d_hl_dynamisers_summary.csv
│   │   │   │   ├── p5d_hl_vs_nonhl_reverters.csv
│   │   │   │   ├── p5d_lisa_behavioural_composition.csv
│   │   │   │   └── p5d_lisa_kruskal_wallis.csv
│   │   │   └── paper2/
│   │   ├── processed/
│   │   │   ├── 01_padron_clean_1996_2025.csv
│   │   │   ├── demography_sex_ratio_1996_2025.csv
│   │   │   └── p0_padron_goerlich_1996_2025.csv
│   │   └── raw/
│   │       ├── 00_raw_padron_1996_2024.csv
│   │       ├── diccionario26.xlsx
│   │       └── mnp/
│   ├── landuse/
│   │   ├── derived/
│   │   ├── processed/
│   │   └── raw/
│   ├── maps/
│   ├── remote_sensing/
│   │   ├── derived/
│   │   ├── processed/
│   │   └── raw/
│   ├── services/
│   │   ├── derived/
│   │   ├── processed/
│   │   └── raw/
│   ├── spatial/
│   │   ├── derived/
│   │   │   ├── mun_geographic_administrative_hierarchy.csv
│   │   │   ├── mun_geographic_administrative_hierarchy.gpkg
│   │   │   ├── territorial_anomalies.csv
│   │   │   └── territorial_anomalies.gpkg
│   │   ├── processed/
│   │   └── raw/
│   └── typology/
├── docs/
│   ├── data_sources.md
│   └── ine_request_doc-01_2026.md
├── figures/
├── notebooks/
│   ├── paper 1/
│   │   ├── p0_goerlich_typology_integration.ipynb
│   │   ├── p1a_rural_population_recovery_analysis.ipynb
│   │   ├── p1b_estimated_migratory_balance.ipynb
│   │   ├── p1c_comparison_padron_vs_migratory.ipynb
│   │   ├── p2_period_analysis.ipynb
│   │   ├── p3_demographic_characterization.ipynb
│   │   ├── p4_spatial_hotspots.ipynb
│   │   ├── p5a_lisa_spatial_outliers.ipynb
│   │   ├── p5a_socioeconomic_characterization.ipynb
│   │   ├── p5b_explanatory_modelling.R
│   │   ├── p5b_forest_plot.R
│   │   ├── p5b_lisa_exploratory.R
│   │   ├── p5b_tables.R
│   │   ├── p5c_pca.R
│   │   └── p5d_permanova.R
│   ├── paper 2/
│   │   └── s0_study_area_definition.ipynb
│   └── shared/
│       ├── 000_environment_check.ipynb
│       ├── 00_geographic_administrative_hierarchy.ipynb
│       ├── 01_data_cleaning_padron_historico.ipynb
│       ├── 02_demography_population_density.ipynb
│       ├── 03_demography_sex_ratio.ipynb
│       ├── 04_population_variation_analysis.ipynb
│       ├── covid_mortality_analysis.ipynb
│       ├── v1_pop_variation_accessibility_buffer_maps.ipynb
│       └── v2_interactive_density_pop_folium.ipynb
├── outputs/
│   └── gis_exercise_maps/
│       └── summary_statistics.csv
├── scripts/
│   └── compute_multi_interval_variation.py
├── requirements.txt
├── LICENSE
└── README.md
```

---

## 📌 Key Data

**Raw sources:**
- `data/demography/raw/00_raw_padron_1996_2024.csv` — INE Padrón Municipal registry (1996–2024)
- `data/demography/raw/diccionario26.xlsx` — Code dictionary for Padrón codes
- `data/demography/raw/mnp/` — Natural Population Movement (MNP) data

**Processed data:**
- `data/demography/processed/01_padron_clean_1996_2025.csv` — Harmonized Padrón (1996–2025)
- `data/demography/processed/p0_padron_goerlich_1996_2025.csv` — Padrón with Goerlich typology classification
- `data/demography/processed/demography_sex_ratio_1996_2025.csv` — Sex ratio by municipality-year

**Derived indicators:**
- `data/demography/derived/02_population_density_1996_2025.csv` — Population density (inh/km²)
- `data/demography/derived/demography_sex_ratio_1996_2025.csv` — Sex ratio statistics
- `data/demography/derived/paper1/` — Paper 1 derived datasets and analysis tables
- `data/demography/derived/paper2/` — Paper 2 derived datasets
- `data/demography/derived/padron-variations/` — Population variation metrics
- `data/demography/derived/nan/` — Missing data documentation

**Spatial data:**
- `data/spatial/derived/mun_geographic_administrative_hierarchy.csv` and `.gpkg` — Municipal administrative hierarchy with geometry
- `data/spatial/derived/territorial_anomalies.csv` and `.gpkg` — Territorial boundary changes and anomalies

**Outputs and maps:**
- `outputs/gis_exercise_maps/` — Generated map visualizations (PNG) and `summary_statistics.csv`
- `data/maps/interactive_density_folium.html` — Interactive population density map

---

## ✅ Current Status

- **Data preparation:** Complete for demography, spatial, and typology workflows (`notebooks/shared/`)
- **Paper 1 analyses:** All 5 sections complete with analysis notebooks and R statistical models
  - Rural recovery, migration balance, demographic characterization, spatial hotspots, socioeconomic analysis
  - Derived datasets in `data/demography/derived/paper1/`
  - Maps and figures in `figures/` and `outputs/gis_exercise_maps/`
- **Paper 2:** Study area definition workflow initialized
- **Future data domains:** `data/landuse/`, `data/remote_sensing/`, `data/services/`, `data/agriculture_livestock/` structures reserved for planned integrations
- **Documentation:** `docs/` contains data sources and INE API request documentation

---

## 🚀 How to use

```bash
pip install -r requirements.txt
```

**Recommended workflow:**

1. **Data preparation** (if reprocessing from raw INE data):
   - Start with `notebooks/shared/000_environment_check.ipynb` to verify your setup
   - Run `notebooks/shared/00_geographic_administrative_hierarchy.ipynb` to establish spatial reference
   - Execute `notebooks/shared/01_data_cleaning_padron_historico.ipynb` to harmonize raw Padrón data
   - Generate indicators with `02_demography_population_density.ipynb`, `03_demography_sex_ratio.ipynb`, and `04_population_variation_analysis.ipynb`

2. **Paper 1 analyses:**
   - Start with `notebooks/paper 1/p0_goerlich_typology_integration.ipynb` to integrate typology classifications
   - Follow thematic sections: p1a (rural recovery), p1b (migration balance), p1c (comparison), p2 (periods), p3 (demographics), p4 (hotspots), p5a (local outliers/socioeconomics)
   - Statistical models in R: `notebooks/paper 1/p5b_explanatory_modelling.R`, `notebooks/paper 1/p5b_forest_plot.R`, `notebooks/paper 1/p5b_lisa_exploratory.R`, `notebooks/paper 1/p5b_tables.R`, `notebooks/paper 1/p5c_pca.R`, `notebooks/paper 1/p5d_permanova.R`

3. **Paper 2:**
   - Review study area definition in `notebooks/paper 2/s0_study_area_definition.ipynb`

4. **Outputs:**
   - Check `figures/` for manuscript figures organized by analysis theme
   - Review `outputs/gis_exercise_maps/` for map visualizations and summary statistics

---

## 📎 Additional Notes

- **Geospatial files:** `data/spatial/derived/` contains administrative geometries in both CSV (attribute tables) and GeoPackage (vector) formats
- **Interactive maps:** `data/maps/interactive_density_folium.html` provides web-based exploratory visualizations
- **Map outputs:** `outputs/gis_exercise_maps/` includes PNG maps for periods 2011–2017, 2018–2021, and 2021–2024 with fixed projections
- **Paper 1 derived data:** Extensive dataset collection in `data/demography/derived/paper1/` includes:
  - Behavioral matrices and classifications (dynamisers, reverters, stable)
  - LISA-based spatial outlier analysis outputs
  - PCA scores and statistical test results (Kruskal–Wallis, Dunn post-hoc, Spearman correlations)
  - Logistic regression model coefficients and metrics
- **Reproducibility:** Use `scripts/compute_multi_interval_variation.py` for multi-period demographic calculations
- **Statistical models:** R models (`.R` files) handle PERMANOVA, PCA, forest plots, and exploratory LISA analysis
