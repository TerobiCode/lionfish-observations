# Lionfish Pipeline 🦁🐠

A data pipeline tracking the global spread of invasive lionfish (*Pterois* genus) using daily citizen science observations from iNaturalist.

## Project Overview

Lionfish are one of the most damaging marine invasive species in history. Native to the Indo-Pacific, they have spread aggressively across the Atlantic, Caribbean, and Mediterranean with no natural predators. This pipeline ingests daily observations from iNaturalist's citizen science platform and transforms them into an analytical dataset for tracking the invasion's geographic spread over time.

## Pipeline Architecture

iNaturalist v2 API

 ↓ Azure Data Factory (daily at 6am)
 
Azure Blob Storage — raw JSON (bronze layer)

 ↓ Snowflake Task (daily at 7am)
 
Snowflake RAW schema (bronze layer)

 ↓ dbt build (daily at 8am)
 
Snowflake STAGING schema — stg_lionfish__bulk, stg_lionfish__incremental (bronze / staging)

Snowflake STAGING schema — int_lionfish__observations (silver / intermediate)

Snowflake MART schema — mart_lionfish__observations (gold layer)

Tableau (visualisation)

## Tools & Technologies

| Tool | Purpose |
|---|---|
| iNaturalist API v2 | Data source — citizen science observations |
| Azure Data Factory | Automated daily ingestion |
| Azure Blob Storage | Raw data landing zone |
| Snowflake | Data warehouse |
| dbt Cloud | Data transformation and testing |
| Tableau | Visualisation |
| Git / GitHub | Version control |

## Data Sources

**Bulk export** — historical CSV export of all research-grade *Pterois* observations from iNaturalist (18,372 observations, exported May 2026).

**Daily incremental** — automated daily ingestion via ADF fetching new research-grade observations submitted to iNaturalist each day.

## Data Model (Medallion Architecture)

### Raw
Raw data stored exactly as received — no modification.
- `RAW.BULK_OBSERVATIONS` — historical CSV data
- `RAW.INCREMENTAL_OBSERVATIONS` — daily JSON from ADF

### Bronze / Staging
Light cleaning — flattening, renaming, type casting, and null filtering only.
- `STAGING.STG_LIONFISH__BULK` — flattened and typed bulk data
- `STAGING.STG_LIONFISH__INCREMENTAL` — flattened JSON, typed incremental data

### Silver / Intermediate
Business logic — union of sources, deduplication, coordinate validation, and quality filters.
- `STAGING.INT_LIONFISH__OBSERVATIONS` — unioned, deduplicated, and validated observations

### Gold / Mart
Aggregated and shaped for analytical consumption.
- `MART.MART_LIONFISH__OBSERVATIONS` — core fact table, one row per observation

## Data Quality

dbt tests are configured across all models including:
- `not_null` on critical fields (observation_id, uuid, observed_on, latin_name)
- `unique` on uuid across all models
- `accepted_values` on ingestion_source

## Automated Pipeline Schedule

| Time (Stockholm) | Step |
|---|---|
| 6:00am | ADF fetches from iNaturalist → writes to Azure Blob Storage |
| 7:00am | Snowflake task loads JSON into RAW schema |
| 8:00am | dbt build transforms RAW → STAGING → MART |

## Known Limitations & Future Improvements

- **Country field** — null for incremental observations as the iNaturalist v2 API does not return a pre-processed country field. Future improvement: add reverse geocoding enrichment step in ADF.
- **Pagination** — ADF handles up to 200 observations per day. If daily volume exceeds this, pagination logic will need to be added.


## Setup

### Prerequisites
- Azure account with student credits
- Snowflake trial account
- dbt Cloud account
- iNaturalist account

### Snowflake Setup
1. Create database `LIONFISH_DB` with schemas `RAW`, `STAGING`, `MART`
2. Create warehouse `LIONFISH_WH`
3. Create external stage pointing at Azure Blob Storage
4. Run bulk load: `COPY INTO LIONFISH_DB.RAW.BULK_OBSERVATIONS`

### dbt Setup
1. Connect dbt Cloud to Snowflake
2. Connect dbt Cloud to this GitHub repository
3. Run `dbt build` to build all models and tests
