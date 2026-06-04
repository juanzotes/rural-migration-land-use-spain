# RurIm Escape
**Geospatial analysis of rural migration and land use change in Spain**

![Python](https://img.shields.io/badge/python-3.11+-blue.svg) ![GeoPandas](https://img.shields.io/badge/geospatial-GeoPandas-green.svg) ![Status](https://img.shields.io/badge/status-active-brightgreen.svg)

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
│   │   ├── p5b_explanatory_modelling.ipynb
│   │   ├── p5b_explanatory_modelling.R
│   │   ├── p5b_forest_plot.R
│   │   ├── p5b_lisa_exploratory.R
│   │   └── p5b_tables.R
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

- Raw INE source: `data/demography/raw/00_raw_padron_1996_2024.csv`
- Processed data: `data/demography/processed/01_padron_clean_1996_2025.csv`
- Derived indicators: `data/demography/derived/02_population_density_1996_2025.csv` and `data/demography/derived/demography_sex_ratio_1996_2025.csv`
- Administrative hierarchy and territorial anomalies:
  - `data/spatial/derived/mun_geographic_administrative_hierarchy.*`
  - `data/spatial/derived/territorial_anomalies.*`

---

## ✅ Current Status

- Notebooks and scripts are organized to reproduce data cleaning and analysis.
- `notebooks/shared/` contains the data preparation and indicator calculation workflow.
- `notebooks/paper 1/` contains thematic analysis for the final manuscript.
- `notebooks/paper 2/` includes the additional study area definition.
- `data/landuse/`, `data/remote_sensing/`, `data/services/`, and `data/agriculture_livestock/` preserve the structure for future work.
- `docs/` documents sources and INE-related data requests.

---

## 🚀 How to use

```bash
pip install -r requirements.txt
```

Recommended steps:

1. Open the repository in Jupyter Lab or VS Code.
2. Run the notebooks in `notebooks/shared/`.
3. Review `notebooks/paper 1/` for the main results.
4. Refer to `notebooks/paper 2/` for the study area process.

---

## 📎 Additional Notes

- `data/maps/` is available for geospatial files and map outputs.
- `outputs/gis_exercise_maps/summary_statistics.csv` contains map-derived summary statistics.
- The current structure supports demographic, spatial, and municipal typology analysis.
