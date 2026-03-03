# ADF Activity Design – Metadata-Driven ETL Framework

This document explains the exact Azure Data Factory activity orchestration used in this framework.

The design follows enterprise best practices for scalable ingestion.

---

# 1️⃣ Master Pipeline: pl_master_ingestion

Purpose:
- Control orchestration
- Loop through metadata entries
- Trigger child ingestion pipeline dynamically

---

## Activities Used

### 🔹 1. Lookup Activity – Get Active Config

Activity Name:
`lkp_get_active_entities`

Source:
Azure SQL (control table)

Query:
```sql
SELECT *
FROM dbo.control_ingestion_config
WHERE is_active = 1
