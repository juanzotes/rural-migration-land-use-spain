# RurIm Escape
**Geospatial analysis of rural migration and land use change in Spain**

![Python](https://img.shields.io/badge/python-3.11+-blue.svg) ![GeoPandas](https://img.shields.io/badge/geospatial-GeoPandas-green.svg) ![Status](https://img.shields.io/badge/status-active-brightgreen.svg)

---

## 📋 Project Overview

**RurIm Escape** studies demographic change in Spanish municipalities, with a focus on rural population recovery and recent migration patterns. The project combines municipal registry data with administrative hierarchies and spatial analysis.

### Main focus

- Cleaning and standardizing historical INE municipal registry data.
- Calculating demographic indicators: population density and sex ratio.
- Analyzing population variation across multiple time intervals.
- Integrating administrative municipal hierarchy and territorial anomalies.

### Data and scope

- Main raw source: `data/demography/raw/00_raw_padron_1996_2024.csv`
- Processed outputs: `data/demography/processed/01_padron_clean_1996_2025.csv`
- Derived indicators: density and sex ratio 1996–2025
- Administrative hierarchy: `data/spatial/derived/mun_geographic_administrative_hierarchy.*`

---

## 📁 Repository Structure

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
│   │   │   └── paper1/
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
│   ├── remote_sensing/
│   │   ├── derived/
│   │   ├── processed/
│   │   └── raw/
│   ├── services/
│   │   ├── derived/
│   │   ├── processed/
│   │   └── raw/
│   └── spatial/
│       ├── derived/
│       │   ├── mun_geographic_administrative_hierarchy.csv
│       │   ├── mun_geographic_administrative_hierarchy.gpkg
│       │   ├── territorial_anomalies.csv
│       │   └── territorial_anomalies.gpkg
│       ├── processed/
│       └── raw/
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
│   │   └── p5b_lisa_exploratory.R
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
├── docs/
│   ├── data_sources.md
│   └── ine_request_doc-01_2026.md
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

## ✅ Current status

- `data/demography/raw/` contains the original INE municipal registry source.
- `data/demography/processed/` contains cleaned data ready for analysis.
- `data/demography/derived/` includes density and sex ratio indicators, as well as interval analysis and `paper1` outputs.
- `data/spatial/derived/` includes administrative municipal hierarchy and territorial anomaly files.
- `notebooks/shared/` contains the cleaning and indicator calculation workflow.
- `notebooks/paper 1/` contains manuscript-oriented analysis notebooks.

---

## 🚀 How to start

```bash
pip install -r requirements.txt
```

- Open Jupyter Lab or VS Code.
- Run the notebooks in `notebooks/shared/` first.
- Review `notebooks/paper 1/` for the final analysis.

---

## ℹ️ Notes

- The folders `data/landuse/`, `data/remote_sensing/`, and `data/services/` exist as project structure but do not yet contain processed data.
- Project documentation is available in `docs/data_sources.md` and `docs/ine_request_doc-01_2026.md`.
