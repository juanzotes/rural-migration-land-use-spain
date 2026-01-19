# RurIm Escape [Early Stage Research]
### *Municipal-scale Demographic Analysis of Rural Spain (1996–2024)*

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![GeoPandas](https://img.shields.io/badge/GeoPandas-Latest-green.svg)](https://geopandas.org/)
[![Status](https://img.shields.io/badge/Status-Active_Development-yellow.svg)]()

> ⚠️ **Project Status:** Core demographic analysis complete. Integration of socioeconomic, service accessibility, and agricultural variables in progress. Land cover analysis awaiting Corine 2024 release.

---

## 📋 Project Overview

**RurIm Escape** investigates demographic shifts in Spanish rural municipalities and their potential relationship with land use changes. This repository contains the **demographic analysis pipeline** for a larger research project examining neo-rural migration patterns accelerated by remote work adoption post-COVID-19.

### Research Design: Two-Scale Temporal Analysis

**Phase 1 - Macro-temporal Context (1996–2024):**  
Establish baseline demographic trends over 28 years to identify long-term patterns of rural depopulation and repopulation.

**Phase 2 - Focal Period Analysis (2018–2024):**  
Zoom into recent years to detect neo-rural migration signals potentially linked to COVID-19 pandemic and remote work normalization.

### Current Research Questions
1. Which Spanish municipalities experienced significant population growth across the full 28-year period (1996–2024)?
2. Do these municipalities show accelerated growth in the recent period (2018–2024) compared to historical trends?
3. What are the demographic characteristics (sex ratio, density, age structure) of repopulation hotspots?
4. *[Future]* How do demographic shifts correlate with changes in service accessibility, economic conditions, and agricultural structure?
5. *[Future]* Can land use changes (2018–2024) be detected and linked to these multivariate socioeconomic patterns?

---

## 🛠️ Technical Stack

| Category | Tools & Libraries |
|----------|------------------|
| **Data Processing** | Pandas, NumPy |
| **Geospatial Analysis** | GeoPandas, Shapely, QGIS (PyQGIS) |
| **Visualization** | Matplotlib, Seaborn, Folium, Plotly *(interactive maps - local development)* |
| **Database** | PostgreSQL/PostGIS *(planned)* |
| **Workflow** | Jupyter Lab, Conda environments, Git/GitHub |
| **Development** | Python 3.11+ (JupyterLab + local scripts for resource-intensive visualizations) |

---

## ✅ Completed Work

### 1. Historical Census Data Cleaning
**Source:** INE ([Instituto Nacional de Estadística](https://www.ine.es/)) - Padrón Municipal  
**Coverage:** 8,131 municipalities × 28 years (1996–2024, excluding 1997)  
**Output:** [`01_padron_clean_1996_2024.csv`](data/processed/)

**Key Processing Steps:**
- Standardization of INE CSV format (semicolon-separated, Latin-1 encoding)
- Municipality code extraction with leading zero preservation
- Removal of invalid census year (1997)
- Handling of 1,860 missing value cases (documented)

**Notebook:** [`01_data_cleaning_padron_historico.ipynb`](notebooks/01_data_cleaning/)

---

### 2. Multi-interval Population Variation Analysis
**Methodology:** Computed percentage population change for all interval lengths (k=1 to k=28 years)

**Formula:**
```
variation(k, t) = ((Pop[t] - Pop[t-k]) / Pop[t-k]) × 100
```

**Output:** 
- Combined dataset: `padron_variations_all_k.csv` (~230,000 municipality-interval combinations)
- Individual CSVs per interval: `padron_variations_k_01.csv` ... `k_28.csv`

**Key Features:**
- Robust handling of missing data and division-by-zero cases
- Vectorized operations for computational efficiency
- Reusable function: [`compute_multi_interval_variation.py`](src/utils/)

**Notebook:** [`02_population_variation_analysis.ipynb`](notebooks/02_population_analysis/)

---

### 3. Demographic Indicators (Sex Ratio & Population Density)
**Metrics Computed:**
- **Sex Ratio (Masculinity Ratio):** `(Male Population / Female Population) × 100`
- **Population Density:** `Total Population / Area (km²)`

**Findings (2024):**
- Mean sex ratio: ~98.5 (slightly more women than men)
- Median population density: ~25 hab/km² (highly skewed distribution)
- 6,000+ municipalities classified as rural (<50 hab/km²)

**Outputs:**
- `03_sex_ratio_1996_2024.csv`
- `03_population_density_1996_2024.csv`
- Visualizations: sex ratio distribution, density rankings

**Notebook:** [`03_sex_ratio_and_density.ipynb`](notebooks/03_demographic_indicators/)

---

## 🚧 In Progress

### Data Integration (Pending INE Response)
**Status:** Data request submitted January 2025  
**Expected Variables (40+) across 4 categories:**

1. **Demographic Data:**
   - Age distribution (mean age, % ≥65 years)
   - Foreign vs. autochthonous population percentages

2. **Economic & Labor Data:**
   - Average household income evolution
   - Affiliation, unemployment, and retirement rates (per 1,000 inhabitants)

3. **Service Accessibility:**
   - Access times to highways/hospitals
   - Number of pharmacies and primary schools
   - Internet coverage (≥30 Mbps, ≥100 Mbps)

4. **Agricultural & Livestock Data:**
   - Farm operation counts (agricultural, livestock)
   - Utilized Agricultural Area (UAA/SAU) and land use distribution
   - Livestock numbers by type (cattle, sheep, pigs, poultry)
   - Farm structure (size, tenure, holder demographics)
   - CAP subsidies, irrigation, organic farming

**Documentation:** [`data_request_ine.md`](docs/data_request_ine.md)

**Integration Plan:**
1. Cleaning and standardization upon data delivery
2. Join with existing census data via `Mun_Code`
3. Exploratory correlation analysis
4. Feature selection for multivariate models

---

### Land Cover Change Analysis (Awaiting Data Release)
**Status:** Pending Corine Land Cover 2024 publication (expected Q2 2025)

**Planned Approach - Focused on Recent Period (2018–2024):**
1. **Baseline:** CLC 2018 (44 land use classes at 100m resolution)
2. **Change Detection:** Pixel-by-pixel comparison with CLC 2024
3. **Spatial Filter:** Municipalities with >15% population growth (2018–2024) identified from macro-temporal analysis
4. **Change Categories:**
   - Agricultural expansion/abandonment (class transitions 211→231, etc.)
   - Urbanization pressure (artificial surfaces 111-112)
   - Pasture/grassland changes (231, 321)
5. **Validation:** Cross-reference with INE agricultural census data (2020)

**Rationale for 2018–2024 focus:**  
This 6-year window captures the neo-rural phenomenon while maintaining sufficient temporal separation for land cover change detection (CLC minimum mapping unit = 5 ha, change detection reliability increases with longer intervals).

**Data Source:** [Copernicus Land Monitoring Service](https://land.copernicus.eu/pan-european/corine-land-cover)

---

### Remote Sensing Validation (Planned Q2 2025)
**Objective:** Validate land cover changes with multispectral vegetation indices for the focal period (2018–2024)

**Proposed Workflow:**
1. **Temporal Compositing:** Median pixel values per growing season (April–September) for years 2018 and 2024
2. **Index Calculation:**
   - **NDVI (Normalized Difference Vegetation Index):** Agricultural activity, vegetation health
   - **NDWI (Normalized Difference Water Index):** Irrigation expansion
   - **NDBI (Normalized Difference Built-up Index):** Urban sprawl detection
3. **Change Detection:** Pixel-level difference maps (NDVI₂₀₂₄ - NDVI₂₀₁₈)
4. **Statistical Analysis:** Correlate index changes with population growth rates and INE agricultural variables

**Platform:** Google Earth Engine (Sentinel-2 L2A imagery, 10m resolution)

**Expected Output:** Validation layer confirming/refuting Corine Land Cover transitions in high population-growth municipalities.

---

## 📂 Repository Structure

```
RurIm-Escape/
├── notebooks/
│   ├── 01_data_cleaning/
│   ├── 02_population_analysis/
│   ├── 03_demographic_indicators/
│   └── 04_visualization/              # WIP
│
├── src/
│   └── utils/
│       └── compute_multi_interval_variation.py
│
├── data/
│   ├── raw/                          # gitignored
│   ├── processed/
│   │   ├── 01_padron_clean_1996_2024.csv
│   │   ├── 02_padron_variations_all_k.csv
│   │   ├── 03_sex_ratio_1996_2024.csv
│   │   └── 03_population_density_1996_2024.csv
│   └── external/                     # Awaiting INE delivery
│
├── outputs/
│   └── figures/
│
└── docs/
    ├── methodology.md
    └── data_request_ine.md
```

---

## 🚀 Reproducibility

### Environment Setup
```bash
git clone https://github.com/juanzotes/RurIm-Escape.git
cd RurIm-Escape
conda env create -f environment.yml
conda activate rurim-escape
jupyter lab
```

### Data Access
- **Census data:** [INE Padrón Histórico](https://www.ine.es/dynt3/inebase/es/index.htm?padre=517)
- **Municipal boundaries:** [IGN Centro de Descargas](https://centrodedescargas.cnig.es/)

---

## 📈 Preliminary Insights

### Macro-temporal Trends (1996–2024)
- **Total municipalities analyzed:** 8,131
- **Data completeness:** 99.7% (1,860 missing values documented)
- **Temporal span:** 28 years (longest historical census series in Spain)

**Key Observation:**  
> Certain peri-urban and coastal municipalities show sustained population growth (>20% cumulative) across the full period, with potential acceleration visible in 2018–2024 interval. Full spatial and statistical analysis pending integration of socioeconomic variables.

### Focal Period Preliminary Findings (2018–2024)
*Analysis in progress. Expected completion: February 2025 upon INE data delivery.*

**Working Hypothesis:**  
Municipalities showing anomalous growth in 2018–2024 (relative to their 1996–2018 trend) may represent neo-rural migration hotspots driven by remote work adoption. These municipalities will be prioritized for land cover change detection.

---

## 🎯 Next Steps (Priority Order)

1. ✅ Complete demographic indicators notebook (sex ratio, density)
2. 📧 Integrate INE socioeconomic variables upon delivery
3. 🗺️ Perform spatial autocorrelation analysis (Moran's I)
4. 📊 Create interactive population change maps (optimize for <50MB)
5. 🗄️ Build PostgreSQL/PostGIS database for efficient spatial queries
6. 🛰️ Integrate Corine Land Cover 2024 upon release

---

## 🤝 Potential Applications

This research framework can inform:
- **Territorial Planning:** Evidence-based policies for neo-rural integration
- **Environmental Monitoring:** Land use impacts of demographic shifts
- **Agricultural Policy:** Understanding farm expansion/abandonment drivers
- **Climate Adaptation:** Rural areas as climate migration destinations

---

## 👨‍🔬 Author

**Juan Zotes**  
GIS Research Analyst | Environmental Scientist  
Complutense University of Madrid

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue)](https://www.linkedin.com/in/juan-zotes-orcajo-88a0a51aa/)
[![Email](https://img.shields.io/badge/Email-Contact-red)](mailto:juanzotes@gmail.com)

*Specializing in geospatial analysis, ecosystem restoration, landscape ecology and biodiversity. Open to opportunities in biodiversity analytics, climate tech, and sustainable finance.*

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Cristina Herrero Jáuregui
- **Research Group:** [ADAPTA (Socio-Ecological Systems, Landscape and Rural Development)](https://www.ucm.es/ecologia/sistemas-socioecologicos,-paisaje-y-desarrollo-local) 
- **Universidad Complutense de Madrid** - Research support
- **Instituto Nacional de Estadística (INE)** - Historical census data
- **University of Helsinki** - Geo-Python &Cristina Herrero Jaúregui

---

*Last updated: January 2025 | Project initiated: November 2024*
