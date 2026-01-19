# RurIm Escape [Early Stage Research]
*Municipal-scale Demographic Analysis of Rural Spain (1996–2024)*


⚠️  **Project Status:** Core demographic analysis complete. Integration of socioeconomic, service accessibility, and agricultural variables in progress. Land cover analysis awaiting Corine 2024 release.

## 📋 Project Overview
RurIm Escape investigates demographic shifts in Spanish rural municipalities and their potential relationship with land use changes. This repository contains the demographic analysis pipeline for a larger research project examining neo-rural migration patterns accelerated by remote work adoption post-COVID-19.

**Research Design: Two-Scale Temporal Analysis**
**Phase 1 - Macro-temporal Context (1996–2024):**
Establish baseline demographic trends over 28 years to identify long-term patterns of rural depopulation and repopulation.
**Phase 2 - Focal Period Analysis (2018–2024):**
Zoom into recent years to detect neo-rural migration signals potentially linked to COVID-19 pandemic and remote work normalization.

**Current Research Questions**
1. Which Spanish municipalities experienced significant population growth across the full 28-year period (1996–2024)?
2. Do these municipalities show accelerated growth in the recent period (2018–2024) compared to historical trends?
3. What are the demographic characteristics (sex ratio, density, age structure) of repopulation hotspots?
4. [Future] How do demographic shifts correlate with changes in service accessibility, economic conditions, and agricultural structure?
5. [Future] Can land use changes (2018–2024) be detected and linked to these multivariate socioeconomic patterns?


### 🛠️ Technical Stack
| Category | Tools & Libraries |
|----------|------------------|
| **Data Processing** | Pandas, NumPy |
| **Geospatial Analysis** | GeoPandas, Shapely, QGIS (PyQGIS) |
| **Visualization** | Matplotlib, Seaborn, Folium, Plotly *(interactive maps - local development)* |
| **Database** | PostgreSQL/PostGIS *(planned)* |
| **Workflow** | Jupyter Lab, Conda environments, Git/GitHub |


✅ Completed Work
1. Historical Census Data Cleaning
Source: INE (Instituto Nacional de Estadística) - Padrón Municipal
Coverage: 8,131 municipalities × 28 years (1996–2024, excluding 1997)
Output: 01_padron_clean_1996_2024.csv
Key Processing Steps:

Standardization of INE CSV format (semicolon-separated, Latin-1 encoding)
Municipality code extraction with leading zero preservation
Removal of invalid census year (1997)
Handling of 1,860 missing value cases (documented)

Notebook: 01_data_cleaning_padron_historico.ipynb

2. Multi-interval Population Variation Analysis
Methodology: Computed percentage population change for all interval lengths (k=1 to k=28 years)
Formula:
variation(k, t) = ((Pop[t] - Pop[t-k]) / Pop[t-k]) × 100
Output:

Combined dataset: padron_variations_all_k.csv (~230,000 municipality-interval combinations)
Individual CSVs per interval: padron_variations_k_01.csv ... k_28.csv

Key Features:

Robust handling of missing data and division-by-zero cases
Vectorized operations for computational efficiency
Reusable function: compute_multi_interval_variation.py

Notebook: 02_population_variation_analysis.ipynb

3. Demographic Indicators (Sex Ratio & Population Density)
Metrics Computed:

Sex Ratio (Masculinity Ratio): (Male Population / Female Population) × 100
Population Density: Total Population / Area (km²)

Findings (2024):

Mean sex ratio: ~98.5 (slightly more women than men)
Median population density: ~25 hab/km² (highly skewed distribution)
6,000+ municipalities classified as rural (<50 hab/km²)

Outputs:

03_sex_ratio_1996_2024.csv
03_population_density_1996_2024.csv
Visualizations: sex ratio distribution, density rankings

Notebook: 03_sex_ratio_and_density.ipynb

🚧 In Progress
Data Integration (Pending INE Response)
Status: Data request submitted January 2025
Expected Variables (40+) across 4 categories:

Demographic Data:

Age distribution (mean age, % ≥65 years)
Foreign vs. autochthonous population percentages


Economic & Labor Data:

Average household income evolution
Affiliation, unemployment, and retirement rates (per 1,000 inhabitants)


Service Accessibility:

Access times to highways/hospitals
Number of pharmacies and primary schools
Internet coverage (≥30 Mbps, ≥100 Mbps)


Agricultural & Livestock Data:

Farm operation counts (agricultural, livestock)
Utilized Agricultural Area (UAA/SAU) and land use distribution
Livestock numbers by type (cattle, sheep, pigs, poultry)
Farm structure (size, tenure, holder demographics)
CAP subsidies, irrigation, organic farming



Documentation: data_request_ine.md
Integration Plan:

Cleaning and standardization upon data delivery
Join with existing census data via Mun_Code
Exploratory correlation analysis
Feature selection for multivariate models


Land Cover Change Analysis (Awaiting Data Release)
Status: Pending Corine Land Cover 2024 publication (expected Q2 2025)
Planned Approach:

Baseline: CLC 2018 (44 land use classes)
Change detection: Pixel-by-pixel comparison with CLC 2024
Focus municipalities: Those with >15% population growth (2018–2024)
Analysis: Agricultural expansion, urbanization, pasture changes

Data Source: Copernicus Land Monitoring Service

Remote Sensing Validation (Planned Q2 2025)
Objective: Validate land cover changes with multispectral vegetation indices
Proposed Indices:

NDVI: Agricultural activity, vegetation health
NDWI: Irrigation patterns
NDBI: Urban expansion

Platform: Google Earth Engine (Sentinel-2, 2018–2024)

📂 Repository Structure
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

🚀 Reproducibility
Environment Setup
bashgit clone https://github.com/juanzotes/RurIm-Escape.git
cd RurIm-Escape
conda env create -f environment.yml
conda activate rurim-escape
jupyter lab
Data Access

Census data: INE Padrón Histórico
Municipal boundaries: IGN Centro de Descargas


📈 Preliminary Insights
Population Trends (1996–2024)

Total municipalities analyzed: 8,131
Data completeness: 99.7% (1,860 missing values documented)
Temporal span: 28 years (longest historical census series in Spain)

Key Observation:

Certain peri-urban and coastal municipalities show sustained population growth (>20% in 2018–2024), contrasting with traditional rural depopulation narratives. Full spatial analysis pending integration of socioeconomic variables.


🎯 Next Steps (Priority Order)

✅ Complete demographic indicators notebook (sex ratio, density)
📧 Integrate INE socioeconomic variables upon delivery
🗺️ Perform spatial autocorrelation analysis (Moran's I)
📊 Create interactive population change maps (optimize for <50MB)
🗄️ Build PostgreSQL/PostGIS database for efficient spatial queries
🛰️ Integrate Corine Land Cover 2024 upon release


🤝 Potential Applications
This research framework can inform:

Territorial Planning: Evidence-based policies for neo-rural integration
Environmental Monitoring: Land use impacts of demographic shifts
Agricultural Policy: Understanding farm expansion/abandonment drivers
Climate Adaptation: Rural areas as climate migration destinations
👨‍🔬 Author
Juan Zotes
GIS Research Analyst | Environmental Scientist and Geographer
Complutense University of Madrid
Mostrar imagen
Mostrar imagen
Specializing in geospatial analysis, ecosystem restoration, and landscape ecology. Open to opportunities in biodiversity analytics, climate tech, and sustainable finance.

📄 License
MIT License - see LICENSE file for details.

🙏 Acknowledgments

Cristina Herrero Jaúregui
Research Group [ADAPTA (Socio-Ecological Systems, Landscape and Rural Development)](https://www.ucm.es/ecologia/sistemas-socioecologicos,-paisaje-y-desarrollo-local) 
Universidad Complutense de Madrid - Research support
Instituto Nacional de Estadística (INE) - Historical census data
University of Helsinki - Geo-Python & AutoGIS training


Last updated: January 2025 | Project initiated: November 2024
