# Azure ADF Metadata-Driven ETL Framework (Pure ADF)

End-to-end, production-style **metadata-driven ingestion framework** built using **Azure Data Factory only** (no Databricks / no Python).
This framework dynamically ingests multiple sources into ADLS Gen2 and loads curated data into Azure SQL / Synapse using configuration-driven pipelines.

## Tech Stack
- Azure Data Factory (ADF)
- ADLS Gen2 (Landing / Raw / Curated)
- Azure SQL Database or Synapse (target)
- ADF Activities: Lookup, ForEach, Copy, Stored Procedure, If Condition, Set Variable, Web (optional for alerting)
- Triggers: Schedule trigger

## Key Features
✅ Metadata-driven loads (add a new table/file via config)  
✅ Incremental loads using watermark (LastModifiedDate / HighWatermark)  
✅ Full load & incremental supported  
✅ Reusable pipelines with parameters  
✅ Logging framework (run status, rows copied, error message)  
✅ Retry + failure handling + notifications pattern  
✅ Environment separation (dev/test/prod-ready pattern)

---

## Architecture (High Level)

**Source** → **ADF Ingestion (Dynamic Copy)** → **ADLS Landing/Raw** → **Curated Load (Copy / Stored Proc)** → **SQL/Synapse**  
Plus: **Control tables + logging tables** to track status and watermark.

See: `docs/architecture.md`
---

## Repo Structure
azure-adf-metadata-driven-etl/
├── adf/ # ADF ARM templates / JSON exports (placeholders)
│ ├── pipelines/
│ ├── datasets/
│ ├── linked_services/
│ ├── triggers/
│ └── factory/
├── config/
│ └── ingestion_config.json # example metadata/config
├── sql/
│ ├── control_tables.sql # control + watermark tables
│ ├── logging_tables.sql # audit/log tables
│ └── stored_procedures.sql # watermark update + logging procedures
└── docs/
├── architecture.md
├── pipeline_flow.md
└── parameterization.md


---

## How to Run (Conceptual)
1. Deploy control + logging tables using `sql/*.sql`
2. Update `config/ingestion_config.json` (or control tables) with table/file entries
3. Trigger the master pipeline (conceptual name: `pl_master_ingestion`)
4. ADF:
   - reads metadata entries
   - loops through each entry (ForEach)
   - performs copy to ADLS
   - writes logs + watermark updates

---

## Interview Talking Points (Use These)
- “This is a reusable ingestion framework. Instead of building 1 pipeline per table, I created a metadata-driven design.”
- “It supports incremental loads using watermark logic, and stores state in a control table.”
- “It has a logging layer to track each run, failures, and rows processed.”
- “It’s production-ready because I used parameterization, retry policies, and separation of config from code.”

---

## Next Enhancements (Optional)
- Add Key Vault integration for secrets
- Add webhook/email notifications
- Add schema drift handling pattern
- Add CI/CD (ADF publish branch) pattern
