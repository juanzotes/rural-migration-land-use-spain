# Data Request to INE (Instituto Nacional de Estadística)

## Status
- **Submitted:** January 2025
- **Current Status:** ⏳ Awaiting response
- **Reference:** Request IDs 234405 → 234397, 234398, 234399, 234400
- **Institution:** Universidad Complutense de Madrid

---

## Request Summary

Municipal-level socioeconomic and agricultural data for territorial and demographic analysis.

**Temporal Coverage:** Year 2000 onwards (or earliest available) to most recent data  
**Spatial Resolution:** Municipality (8,131 municipalities)  
**Format Requested:** CSV

---

## Requested Variables (4 Categories)

### 1. Demographic Data
- Average age
- % Population ≥65 years
- % Foreign population
- % Autochthonous population
- ~~Sex ratio~~ *(already computed from Padrón Municipal)*

### 2. Economic & Labor Data
- Average household income evolution
- Social security affiliation rate (per 1,000 inhabitants)
- Unemployment rate (per 1,000 inhabitants)
- Retirement rate (per 1,000 inhabitants)

### 3. Service Accessibility
**INE Response:** Data not available

| Variable | INE Status | Alternative Source |
|----------|-----------|-------------------|
| Time to highway/motorway | ❌ Not available | [MITMA](https://www.mitma.gob.es/) - Road network + isochrone analysis |
| Time to hospital | ❌ Not available | [Ministry of Health](https://www.sanidad.gob.es/) / OpenStreetMap |
| Number of pharmacies | ❌ Not available | [General Council of Pharmaceutical Colleges](https://www.portalfarma.com/) |
| Number of primary schools | ❌ Not available | [Ministry of Education](https://www.educacion.gob.es/) |
| Internet coverage ≥30 Mbps | ❌ Not available | [Ministry of Digital Transformation](https://avancedigital.mineco.gob.es/banda-ancha/cobertura/Paginas/informes-cobertura.aspx) |
| Internet coverage ≥100 Mbps | ❌ Not available | [Ministry of Digital Transformation](https://avancedigital.mineco.gob.es/banda-ancha/cobertura/Paginas/informes-cobertura.aspx) |

**Follow-up:** Will request data from indicated sources. OpenStreetMap (OSM) as fallback for spatial data.


**Follow-up:** Awaiting official INE response to determine correct ministry contacts before submitting new requests.

### 4. Agricultural & Livestock Data
- Number of agricultural operations (temporal evolution)
- Number of livestock operations (temporal evolution)
- Total Utilized Agricultural Area (UAA/SAU) and distribution by use
- Mean UAA per operation
- UAA by size strata (small/medium/large farms)
- Operations by land tenure regime (ownership, lease, etc.)
- Operations by production type (agricultural, livestock, mixed)
- Total livestock heads by type (cattle, sheep, pigs, poultry)
- Farm holder demographics (age, sex, distribution)
- Operations with family vs. hired labor
- Operations with CAP subsidies, irrigation, organic certification

**Note:** Many agricultural variables from Census Agrario (2009, 2020) - sparse temporal coverage expected.

---

## Data Integration Plan

### Upon INE Delivery (Expected February 2025)
1. **Cleaning:** Standardize municipality codes, handle missing values
2. **Validation:** Cross-check temporal consistency
3. **Integration:** Join with existing census data via `Mun_Code`
4. **Analysis:** Correlation matrix, spatial autocorrelation, multivariate modeling

### Service Data Alternative Approach
If official sources unavailable after clarification:
- **OpenStreetMap** (OSM) for pharmacies, hospitals, schools
- **Ministry of Digital Transformation** for internet coverage data
- **MITMA road network** + OSMnx for access time calculations (isochrones)

---

## Expected Outputs

**Datasets:**
- `04_ine_demographics.csv`
- `04_ine_economics.csv`
- `04_ine_agriculture.csv`

**Analysis Notebooks:**
- `04_ine_data_integration.ipynb`
- `05_multivariate_analysis.ipynb`

**Timeline:**
- **Feb 2025:** INE data delivery
- **Mar 2025:** Data cleaning & integration
- **Apr 2025:** Multivariate analysis complete

---

## Contact

**Requestor:** Juan Zotes  
**Institution:** Universidad Complutense de Madrid  
**Email:** jzotes01@ucm.es / juanzotes@gmail.com  
**Project:** RurIm Escape - Neo-rural migration and land use change analysis

---

*Document updated: January 2025*
