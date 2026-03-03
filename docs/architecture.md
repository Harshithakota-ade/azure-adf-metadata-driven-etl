# Architecture - Azure ADF Metadata-Driven ETL Framework

## Objective
Design a reusable, scalable Azure Data Factory ingestion framework that dynamically loads multiple source tables/files into ADLS and Azure SQL/Synapse using metadata-driven configuration.

No Databricks. No Python. Pure ADF orchestration.

---

## High-Level Architecture

Source Systems (SQL / Files / APIs)
        ↓
Azure Data Factory (Master Pipeline)
        ↓
Lookup (Read Control Table Metadata)
        ↓
ForEach (Loop Through Config Rows)
        ↓
Dynamic Copy Activity
        ↓
ADLS Gen2 (Landing → Raw)
        ↓
Stored Procedure Activity (Load to SQL/Synapse)
        ↓
Logging + Watermark Update

---

## Core Components

### 1️⃣ Control Table (Metadata Driven)
Stores configuration for each table/file:
- Source type
- Source query
- Load type (Full / Incremental)
- Watermark column
- Target table
- Active flag

This allows onboarding a new table without building new pipelines.

---

### 2️⃣ Master Pipeline (`pl_master_ingestion`)
- Lookup activity reads control table
- ForEach loops through active entries
- Executes child ingestion pipeline dynamically

---

### 3️⃣ Child Pipeline (`pl_dynamic_copy`)
- Parameterized source
- Parameterized sink
- Incremental filter logic
- Error handling
- Logging calls

---

### 4️⃣ Watermark Logic

For incremental loads:
- Read last watermark value from control table
- Apply filter in source query:
  WHERE LastModifiedDate > @Watermark
- After successful load:
  Update watermark to MAX(LastModifiedDate)

---

### 5️⃣ Logging Framework

Each pipeline execution logs:
- Run ID
- Table name
- Load type
- Start time
- End time
- Rows copied
- Status (Success/Failed)
- Error message

---

## Storage Layers (ADLS)

- landing/
- raw/
- curated/

---

## Production-Ready Features

- Retry policies
- Timeout configuration
- Fail activity for structured error handling
- Parameterized linked services
- Environment separation ready (Dev/Test/Prod)

---

## Why This Design?

Instead of:
❌ 1 pipeline per table

We built:
✅ 1 reusable framework that scales to 100+ tables

Enterprise pattern used in real Azure Data Engineering projects.
