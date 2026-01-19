# Data Request to INE (Instituto Nacional de Estadística)

## Status
- **Submitted:** January 2025
- **Status:** ⏳ Pending response
- **Contact:** INE Customer Service (reference: 234405 → 234397, 234398, 234399, 234400)

---

## Request Context

Submitted from **Universidad Complutense de Madrid** as part of a territorial and demographic study at municipal scale. All data requested at **municipality level** for maximum spatial resolution.

### Temporal Coverage Requested
- **From:** Year 2000 (or earliest available date thereafter)
- **To:** Most recent available data
- **Note:** Temporal misalignment between variables accepted (e.g., Census Agrario vs. annual data)

---

## Requested Variables

### 1. Demographic Data
| Variable | Description |
|----------|-------------|
| Average age | Mean age of population |
| % Population ≥65 years | Elderly population proportion |
| % Foreign population | Non-Spanish nationals |
| % Autochthonous population | Spanish nationals |
| Sex ratio | Already computed from Padrón Municipal (Males/Females × 100) |

---

### 2. Economic & Labor Data
| Variable | Description |
|----------|-------------|
| Average household income | Temporal evolution of mean income per household |
| Affiliation rate | Number of social security affiliates per 1,000 inhabitants |
| Unemployment rate | Number of unemployed persons per 1,000 inhabitants |
| Retirement rate | Number of pensioners per 1,000 inhabitants |

---

### 3. Service Accessibility *(INE response: Not available - referred to MITERD)*
| Variable | Description | Status |
|----------|-------------|--------|
| Time to highway/motorway | Access time evolution | ❌ Not available |
| Time to hospital | Access time evolution | ❌ Not available |
| Number of pharmacies | Count evolution | ❌ Not available |
| Number of primary schools | Count evolution | ❌ Not available |
| Internet coverage ≥30 Mbps | % households with access | ❌ Not available |
| Internet coverage ≥100 Mbps | % households with access | ❌ Not available |

**Follow-up action:** Contact MITERD (Ministry for Ecological Transition) for infrastructure/services data.

---

### 4. Agricultural & Livestock Data *(Primary focus for land use analysis)*

#### 4.1 Farm Operations
| Variable | Description |
|----------|-------------|
| Number of agricultural operations | Temporal evolution |
| Number of livestock operations | Temporal evolution |
| Total Utilized Agricultural Area (UAA/SAU) | Hectares, disaggregated by crop/livestock if available |
| Mean UAA per operation | Average farm size |
| UAA distribution by use | Cropland, Permanent crops, Permanent pastures, etc. |
| Operations by UAA size strata | Small (<5 ha), Medium (5-50 ha), Large (>50 ha) |

#### 4.2 Land Tenure
| Variable | Description |
|----------|-------------|
| Operations by tenure regime | Ownership, Lease, Sharecropping, Other |

#### 4.3 Production Orientation
| Variable | Description |
|----------|-------------|
| Operations by technical-economic orientation | Cereals, Vineyards, Livestock, Mixed, etc. |
| Operations by production type | Agricultural, Livestock, Mixed |

#### 4.4 Livestock Metrics
| Variable | Description |
|----------|-------------|
| Total livestock heads | All species combined |
| Heads by livestock type | Cattle, Sheep, Goats, Pigs, Poultry, etc. |
| Operations with livestock | Count |
| Mean size of livestock operations | Heads per operation |

#### 4.5 Human Structure of Operations
| Variable | Description |
|----------|-------------|
| Number of farm holders | Count |
| Average age of holder | Mean age |
| Holders by age group | <35, 35-54, 55-64, ≥65 years |
| Holders by sex | Male/Female distribution |
| Operations with family labor | Count |
| Operations with hired labor | Count |
| Annual Work Units (AWU) | If available |

#### 4.6 Structural Aspects
| Variable | Description |
|----------|-------------|
| Operations with complementary activities | Agrotourism, processing, etc. |
| Organic farming operations | If available |
| Operations receiving CAP subsidies | Common Agricultural Policy support |
| Irrigated operations | Count and irrigated area |

---

## Data Source Notes

### Frequency Limitations
Many variables derive from **Census Agrario** (structural survey conducted every ~10 years):
- **Recent censuses:** 2009, 2020
- **Next expected:** 2030

Therefore, most agricultural variables will have **sparse temporal coverage** (2-3 observations rather than annual series).

### Spatial Aggregation
If municipal-level data unavailable, **comarca agraria** (agricultural district) level accepted as fallback.

---

## Rationale for Request

These variables enable multivariate analysis of factors associated with:
1. **Neo-rural migration patterns:** Correlating demographic shifts with economic/service conditions
2. **Land use change drivers:** Linking agricultural restructuring (farm size, tenure, livestock) with population dynamics
3. **Rural sustainability indicators:** Assessing aging, service accessibility, economic vitality

---

## Integration Plan Upon Data Delivery

### Phase 1: Data Cleaning
1. Standardize municipality codes (`Mun_Code` as 5-digit string with leading zeros)
2. Handle missing values (imputation vs. exclusion based on variable)
3. Document temporal gaps (e.g., 2009 vs. 2020 Census Agrario)

### Phase 2: Exploratory Analysis
1. Descriptive statistics per variable
2. Correlation matrix (demographic, economic, agricultural variables)
3. Spatial autocorrelation (Moran's I) for clustering detection

### Phase 3: Integration with Existing Data
1. Join with population variation data (`02_padron_variations_all_k.csv`)
2. Join with sex ratio and density data (`03_sex_ratio_and_density.csv`)
3. Create unified analytical database (PostgreSQL/PostGIS)

### Phase 4: Multivariate Modeling
1. Principal Component Analysis (PCA) for dimensionality reduction
2. Cluster analysis (k-means, hierarchical) for municipality typology
3. Regression models: Population change ~ [demographics + economics + agriculture]

---

## Expected Outputs

1. **Cleaned datasets:** `04_ine_demographics.csv`, `04_ine_economics.csv`, `04_ine_agriculture.csv`
2. **Merged database:** `05_rurim_master_database.csv` (or PostgreSQL tables)
3. **Analytical notebooks:**
   - `04_ine_data_integration.ipynb`
   - `05_exploratory_multivariate_analysis.ipynb`
4. **Reports:** Summary statistics, correlation heatmaps, cluster maps

---

## Timeline (Estimated)

- **January 2025:** Data request submitted
- **February 2025:** Expected INE response & data delivery
- **March 2025:** Data cleaning and integration
- **April 2025:** Multivariate analysis complete
- **May 2025:** Corine Land Cover 2024 integration begins

---

## Contact Information

**Requestor:** Juan Zotes  
**Institution:** Universidad Complutense de Madrid  
**Email:** juanzotes@gmail.com  
**Project:** RurIm Escape - Neo-rural migration and land use change analysis

---

*This document will be updated upon INE response with actual delivery details and variable availability.*