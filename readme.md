# RurIm Escape [Early Stage Research]
**Geospatial Analysis of Neo-Rural Migration and Land Use Change in Spain (1996–2024)**

![Python](https://img.shields.io/badge/python-3.11+-blue.svg) ![GeoPandas](https://img.shields.io/badge/geospatial-GeoPandas-green.svg) ![Status](https://img.shields.io/badge/status-in%20progress-yellow.svg)

⚠️ **Project Status:** Core demographic analysis complete. Integration of socioeconomic, service accessibility, and agricultural variables in progress. Land cover analysis awaiting Corine 2024 release.

---

## 📋 Project Overview
RurIm Escape investigates demographic shifts in Spanish rural municipalities and their potential relationship with land use changes. This repository contains the demographic analysis pipeline for a larger research project examining neo-rural migration patterns accelerated by remote work adoption post-COVID-19.

### Research Design: Two-Scale Temporal Analysis
**Phase 1 - Macro-temporal Context (1996–2024):**  
Establish baseline demographic trends over 28 years to identify long-term patterns of rural depopulation and repopulation.

**Phase 2 - Focal Period Analysis (2018–2024):**  
Zoom into recent years to detect neo-rural migration signals potentially linked to COVID-19 pandemic and remote work normalization.

### Current Research Questions
- Which Spanish municipalities experienced significant population growth across the full 28-year period (1996–2024)?
- Do these municipalities show accelerated growth in the recent period (2018–2024) compared to historical trends?
- What are the demographic characteristics (sex ratio, density, age structure) of repopulation hotspots?
- **[Future]** How do demographic shifts correlate with changes in service accessibility, economic conditions, and agricultural structure?
- **[Future]** Can land use changes (2018–2024) be detected and linked to these multivariate socioeconomic patterns?

---

## 🛠️ Technical Stack
| Category | Tools & Libraries |
|----------|------------------|
| **Data Processing** | Pandas, NumPy |
| **Geospatial Analysis** | GeoPandas, Shapely, QGIS (PyQGIS) |
| **Visualization** | Matplotlib, Seaborn, Folium, Plotly (interactive maps - local development) |
| **Database** | PostgreSQL/PostGIS (planned) |
| **Workflow** | Jupyter Lab, Conda environments, Git/GitHub |
| **Development** | Python 3.11+ (JupyterLab + local scripts for resource-intensive visualizations) |

---

## ✅ Completed Work

### 1. Historical Census Data Cleaning
**Source:** INE (Instituto Nacional de Estadística) - Padrón Municipal  
**Coverage:** 8,131 municipalities × 28 years (1996–2024, excluding 1997)  
**Output:** `01_padron_clean_1996_2024.csv`

**Key Processing Steps:**
- Standardization of INE CSV format (semicolon-separated, Latin-1 encoding)
- Municipality code extraction with leading zero preservation
- Removal of invalid census year (1997)
- Handling of 1,860 missing value cases (documented)

**Notebook:** `01_data_cleaning_padron_historico.ipynb`

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
- Reusable function: `compute_multi_interval_variation.py`

**Notebook:** `02_population_variation_analysis.ipynb`

### 3. Demographic Indicators (Sex Ratio & Population Density)
**Metrics Computed:**
- **Sex Ratio (Masculinity Ratio):** (Male Population / Female Population) × 100
- **Population Density:** Total Population / Area (km²)

**Findings (2024):**
- Mean sex ratio: ~98.5 (slightly more women than men)
- Median population density: ~25 hab/km² (highly skewed distribution)
- 6,000+ municipalities classified as rural (<50 hab/km²)

**Outputs:**
- `03_sex_ratio_1996_2024.csv`
- `03_population_density_1996_2024.csv`
- Visualizations: sex ratio distribution, density rankings

**Notebook:** `03_sex_ratio_and_density.ipynb`

### 4. Agricultural and Livestock Farm Density (2020)
**Source:** INE - Censo Agrario 2020  
**Metrics Computed:**
- Municipal area in hectares (ha)
- Agricultural farm density: farms/ha
- Livestock operation density: operations/ha

**Processing:**
- Layer reprojection to ETRS89/UTM 30N (EPSG:25830) for accurate area calculation
- Density computation with null value handling
- Integration with original geodatabase layers (EPSG:4258)

**Output Fields:**
- `ha`: Municipal area in hectares
- `dens_agr`: Agricultural farm density
- `dens_gan`: Livestock operation density

**Notebook:** `03_calculate_agricultural_density_2020.ipynb`

---

## 🚧 In Progress

### Data Integration (Pending INE Response)
**Status:** Data request submitted January 2025  
**Expected Variables (40+)** across 4 categories:

**Demographic Data:**
- Age distribution (mean age, % ≥65 years)
- Foreign vs. autochthonous population percentages

**Economic & Labor Data:**
- Average household income evolution
- Affiliation, unemployment, and retirement rates (per 1,000 inhabitants)

**Service Accessibility:**
- Access times to highways/hospitals
- Number of pharmacies and primary schools
- Internet coverage (≥30 Mbps, ≥100 Mbps)

**Agricultural & Livestock Data:**
- Farm operation counts (agricultural, livestock)
- Utilized Agricultural Area (UAA/SAU) and land use distribution
- Livestock numbers by type (cattle, sheep, pigs, poultry)
- Farm structure (size, tenure, holder demographics)
- CAP subsidies, irrigation, organic farming

**Documentation:** `data_request_ine.md`

**Integration Plan:**
1. Cleaning and standardization upon data delivery
2. Join with existing census data via `Mun_Code`
3. Exploratory correlation analysis
4. Feature selection for multivariate models

### Land Cover Change Analysis (Awaiting Data Release)
**Status:** Pending Corine Land Cover 2024 publication (expected Q2 2025)

**Planned Approach - Focused on Recent Period (2018–2024):**
- **Baseline:** CLC 2018 (44 land use classes at 100m resolution)
- **Change Detection:** Pixel-by-pixel comparison with CLC 2024
- **Spatial Filter:** Municipalities with >15% population growth (2018–2024) identified from macro-temporal analysis
- **Change Categories:**
  - Agricultural expansion/abandonment (class transitions 211→231, etc.)
  - Urbanization pressure (artificial surfaces 111-112)
  - Pasture/grassland changes (231, 321)
- **Validation:** Cross-reference with INE agricultural census data (2020)

**Rationale for 2018–2024 focus:**  
This 6-year window captures the neo-rural phenomenon while maintaining sufficient temporal separation for land cover change detection (CLC minimum mapping unit = 5 ha, change detection reliability increases with longer intervals).

**Data Source:** Copernicus Land Monitoring Service

### Remote Sensing Validation (Planned Q2 2025)
**Objective:** Validate land cover changes with multispectral vegetation indices for the focal period (2018–2024)

**Proposed Workflow:**
1. **Temporal Compositing:** Median pixel values per growing season (April–September) for years 2018 and 2024
2. **Index Calculation:**
   - NDVI (Normalized Difference Vegetation Index): Agricultural activity, vegetation health
   - NDWI (Normalized Difference Water Index): Irrigation expansion
   - NDBI (Normalized Difference Built-up Index): Urban sprawl detection
3. **Change Detection:** Pixel-level difference maps (NDVI₂₀₂₄ - NDVI₂₀₁₈)
4. **Statistical Analysis:** Correlate index changes with population growth rates and INE agricultural variables

**Platform:** Google Earth Engine (Sentinel-2 L2A imagery, 10m resolution)

**Expected Output:** Validation layer confirming/refuting Corine Land Cover transitions in high population-growth municipalities.

---

## 📂 Repository Structure
```
RurIm-Escape/
├── notebooks/
│   ├── 01_data_cleaning_padron_historico.ipynb
│   ├── 02_population_variation_analysis.ipynb
│   ├── 03_sex_ratio_and_density.ipynb
│   └── 04_calculate_agricultural_density_2020.ipynb
│
├── scripts/
│   └── compute_multi_interval_variation.py
│
├── docs/
│   ├── methodology.md
│   ├── data_request_ine.md
│   └── data_sources.md              # Instructions to download required datasets
│
├── requirements.txt
├── .gitignore
└── README.md
```

**Note:** Data files are excluded from the repository due to GitHub size limitations. See `docs/data_sources.md` for download instructions and expected local folder structure.

---

## 🚀 Reproducibility

### Environment Setup
```bash
git clone https://github.com/juanzotes/RurIm-Escape.git
cd RurIm-Escape
pip install -r requirements.txt
jupyter lab
```

### Data Access
⚠️ **Important:** Data files are NOT included in this repository due to GitHub size limitations.

**Required datasets:**
- **Census data:** [INE Padrón Histórico](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177012&menu=resultados&idp=1254734710990)
- **Agricultural census:** [INE Censo Agrario 2020](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176851&menu=resultados&idp=1254735727106)
- **Municipal boundaries:** [IGN Centro de Descargas](https://centrodedescargas.cnig.es/)

See `docs/data_sources.md` for detailed download instructions and expected local folder structure.

---

## 📈 Preliminary Insights

### Macro-temporal Trends (1996–2024)
- **Total municipalities analyzed:** 8,220
- **Data completeness:** 99.7% (1,860 missing values documented)
- **Temporal span:** 28 years (longest historical census series in Spain)

**Key Observation:**  
Certain peri-urban and coastal municipalities show sustained population growth (>20% cumulative) across the full period, with potential acceleration visible in 2018–2024 interval. Full spatial and statistical analysis pending integration of socioeconomic variables.

### Focal Period Preliminary Findings (2018–2024)
**Analysis in progress.** Expected completion: February 2025 upon INE data delivery.

**Working Hypothesis:**  
Municipalities showing anomalous growth in 2018–2024 (relative to their 1996–2018 trend) may represent neo-rural migration hotspots driven by remote work adoption. These municipalities will be prioritized for land cover change detection.

---

## 🎯 Next Steps (Priority Order)
- [x] Complete demographic indicators notebook (sex ratio, density)
- [x] Calculate agricultural and livestock farm densities (2020)
- [ ] 📧 Integrate INE socioeconomic variables upon delivery
- [ ] 🗺️ Perform spatial autocorrelation analysis (Moran's I)
- [ ] 📊 Create interactive population change maps (optimize for <50MB)
- [ ] 🗄️ Build PostgreSQL/PostGIS database for efficient spatial queries
- [ ] 🛰️ Integrate Corine Land Cover 2024 upon release

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

[LinkedIn](https://www.linkedin.com/in/juan-zotes) | [Email (Work)](mailto:jzotes01@ucm.es) | [Email (Personal)](mailto:juanzotes@gmail.es)

*Specializing in geospatial analysis, ecosystem restoration, landscape ecology and biodiversity. Open to opportunities in biodiversity analytics, climate tech, and sustainable finance.*

---

## 📄 License
MIT License - see LICENSE file for details.

---

## 🙏 Acknowledgments
- **Cristina Herrero Jáuregui** - Research Group: ADAPTA (Socio-Ecological Systems, Landscape and Rural Development)
- **Universidad Complutense de Madrid** - Research support
- **Instituto Nacional de Estadística (INE)** - Historical census data
- **University of Helsinki** - Geo-Python & Automating GIS Processes

---

*Last updated: January 2026 | Project initiated: December 2025*
