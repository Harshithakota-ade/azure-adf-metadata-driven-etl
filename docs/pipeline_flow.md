# Pipeline Flow – Step by Step

## pl_master_ingestion

1. Lookup Activity
   - Reads active rows from control table
   - Query:
     SELECT * FROM dbo.control_ingestion_config WHERE is_active = 1

2. ForEach Activity
   - Items: @activity('Lookup').output.value
   - Calls child pipeline pl_dynamic_copy
   - Pass parameters dynamically

---

## pl_dynamic_copy

### Step 1 – Get Watermark
Stored Procedure:
  usp_get_watermark

### Step 2 – Set Variable
Build dynamic source query based on load type.

Full Load:
  SELECT * FROM source_table

Incremental:
  SELECT * FROM source_table
  WHERE LastModifiedDate > @Watermark

### Step 3 – Copy Activity
Source: Parameterized dataset  
Sink: ADLS raw folder  

### Step 4 – Load to Target
Stored Procedure:
  usp_load_to_target

### Step 5 – Update Watermark
Stored Procedure:
  usp_update_watermark

### Step 6 – Log Status
Insert into log table

---

## Failure Handling

If Copy fails:
- Execute Fail activity
- Log error message
- Stop execution

Retry policy:
- 3 retries
- 30 second interval
