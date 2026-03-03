/* =========================================================
   LOGGING / AUDIT TABLES
   ========================================================= */

-- 1) Pipeline run log (one row per entity per run)
IF OBJECT_ID('dbo.etl_run_log', 'U') IS NOT NULL
    DROP TABLE dbo.etl_run_log;
GO

CREATE TABLE dbo.etl_run_log (
    log_id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    pipeline_name     VARCHAR(200) NOT NULL,
    pipeline_run_id   VARCHAR(100) NOT NULL,
    entity_name       VARCHAR(100) NOT NULL,
    load_type         VARCHAR(20)  NOT NULL,
    start_time_utc    DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    end_time_utc      DATETIME2    NULL,
    status            VARCHAR(20)  NOT NULL DEFAULT 'RUNNING',  -- RUNNING/SUCCESS/FAILED
    rows_read         BIGINT       NULL,
    rows_written      BIGINT       NULL,
    watermark_before  DATETIME2    NULL,
    watermark_after   DATETIME2    NULL,
    error_message     NVARCHAR(4000) NULL
);
GO

CREATE INDEX IX_etl_run_log_run
ON dbo.etl_run_log(pipeline_run_id, entity_name);
GO

CREATE INDEX IX_etl_run_log_status
ON dbo.etl_run_log(status, start_time_utc);
GO


-- 2) Optional: Error log (store activity-level error details)
IF OBJECT_ID('dbo.etl_error_log', 'U') IS NOT NULL
    DROP TABLE dbo.etl_error_log;
GO

CREATE TABLE dbo.etl_error_log (
    error_id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    pipeline_run_id   VARCHAR(100) NOT NULL,
    pipeline_name     VARCHAR(200) NOT NULL,
    entity_name       VARCHAR(100) NOT NULL,
    activity_name     VARCHAR(200) NOT NULL,
    error_time_utc    DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    error_message     NVARCHAR(4000) NULL
);
GO

CREATE INDEX IX_etl_error_log_run
ON dbo.etl_error_log(pipeline_run_id, entity_name, error_time_utc);
GO
