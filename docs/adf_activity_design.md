ADF Activity Design – Metadata-Driven ETL Framework

This document describes the detailed Azure Data Factory (ADF) activity orchestration used in this metadata-driven ingestion framework.

The objective of this design is to build a reusable, scalable, and production-ready ingestion framework without creating one pipeline per table.

1. Master Pipeline – pl_master_ingestion

The master pipeline is responsible for orchestration.

Purpose

Read ingestion configuration from control table

Loop through active entities

Execute child ingestion pipeline dynamically

Step 1 – Lookup Activity

The pipeline starts with a Lookup activity that reads active ingestion configurations from the control table.

Query executed:

SELECT *
FROM dbo.control_ingestion_config
WHERE is_active = 1

This returns metadata such as:

entity_name

source_table

target_table

load_type (FULL / INCREMENTAL)

watermark_column

The output of the Lookup is an array.

Step 2 – ForEach Activity

The ForEach activity loops through each metadata row returned by the Lookup activity.

Items expression:

@activity('lkp_get_active_entities').output.value

Inside the ForEach loop, the pipeline calls a child pipeline (pl_dynamic_copy) and passes parameters dynamically:

entity_name

source_table

target_table

load_type

watermark_column

This enables processing multiple tables using a single reusable pipeline.

Parallelism can be controlled using the batch count (recommended: 5–10).

2. Child Pipeline – pl_dynamic_copy

The child pipeline performs ingestion for one entity at a time.

Step 1 – Get Watermark (Stored Procedure Activity)

A stored procedure is executed to retrieve:

last_watermark_value

load_type

watermark_column

This value is stored in a pipeline variable.

For incremental loads, this watermark value is used to filter source data.

Step 2 – Build Dynamic Source Query

If load type is FULL:

SELECT * FROM source_table

If load type is INCREMENTAL:

SELECT * FROM source_table
WHERE LastModifiedDate > @Watermark

Dynamic expressions are used to construct the SQL query inside ADF.

This allows the same pipeline to support both full and incremental loads.

Step 3 – Copy Activity

The Copy activity performs the actual data movement.

Source:

Parameterized dataset (SQL / File)

Sink:

ADLS Gen2 Raw folder

File path pattern:

/raw/entity_name/

Retry policy:

3 retries

30-second interval

Timeout:

1 hour (configurable)

Step 4 – Load to Target (Stored Procedure)

After copying to ADLS, a stored procedure loads data into the target staging or curated table.

This may include:

Insert into staging table

Merge into final table

Transformation logic

Step 5 – Update Watermark

After successful load, the watermark is updated in the control table.

New watermark value:

MAX(watermark_column) from loaded dataset

This ensures next run only loads new or changed records.

Step 6 – Logging (Success Path)

On successful completion:

Rows read

Rows written

Start time

End time

Watermark before

Watermark after

Status = SUCCESS

are logged into the ETL run log table.

Step 7 – Error Handling (Failure Path)

If any activity fails:

Failure is logged in log table

Error message is captured

Pipeline execution is stopped using Fail activity

Retry policies are applied to critical activities.

3. Variables Used

Common pipeline variables:

v_watermark

v_source_query

v_rows_copied

v_status

These help in dynamic execution and logging.

4. Trigger Design

The pipeline is executed using:

Schedule Trigger (e.g., daily at 2:00 AM UTC)

Future enhancement:

Event-based trigger (Blob created event)

5. Enterprise Best Practices Implemented

Metadata-driven architecture

Incremental watermark loading

Centralized logging framework

Parameterized datasets

Retry and timeout configuration

Failure handling with structured logging

Scalable design (supports 100+ tables)
WHERE is_active = 1
