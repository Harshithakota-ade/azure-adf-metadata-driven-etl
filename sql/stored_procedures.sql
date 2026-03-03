/* =========================================================
   STORED PROCEDURES USED BY ADF
   - Get watermark
   - Start log
   - Complete log
   - Fail log
   - Update watermark
   ========================================================= */

-- Get watermark value for an entity
IF OBJECT_ID('dbo.usp_get_watermark', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_get_watermark;
GO
CREATE PROCEDURE dbo.usp_get_watermark
    @entity_name VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        entity_name,
        load_type,
        watermark_column,
        last_watermark_value
    FROM dbo.control_ingestion_config
    WHERE entity_name = @entity_name
      AND is_active = 1;
END
GO


-- Start run logging (insert RUNNING row)
IF OBJECT_ID('dbo.usp_log_run_start', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_log_run_start;
GO
CREATE PROCEDURE dbo.usp_log_run_start
    @pipeline_name    VARCHAR(200),
    @pipeline_run_id  VARCHAR(100),
    @entity_name      VARCHAR(100),
    @load_type        VARCHAR(20),
    @watermark_before DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.etl_run_log
    (pipeline_name, pipeline_run_id, entity_name, load_type, start_time_utc, status, watermark_before)
    VALUES
    (@pipeline_name, @pipeline_run_id, @entity_name, @load_type, SYSUTCDATETIME(), 'RUNNING', @watermark_before);

    -- Return log_id
    SELECT SCOPE_IDENTITY() AS log_id;
END
GO


-- Complete run logging (SUCCESS)
IF OBJECT_ID('dbo.usp_log_run_success', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_log_run_success;
GO
CREATE PROCEDURE dbo.usp_log_run_success
    @pipeline_run_id  VARCHAR(100),
    @entity_name      VARCHAR(100),
    @rows_read        BIGINT = NULL,
    @rows_written     BIGINT = NULL,
    @watermark_after  DATETIME2 = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.etl_run_log
    SET
        end_time_utc    = SYSUTCDATETIME(),
        status          = 'SUCCESS',
        rows_read       = @rows_read,
        rows_written    = @rows_written,
        watermark_after = @watermark_after
    WHERE pipeline_run_id = @pipeline_run_id
      AND entity_name     = @entity_name
      AND status          = 'RUNNING';
END
GO


-- Fail run logging (FAILED)
IF OBJECT_ID('dbo.usp_log_run_failed', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_log_run_failed;
GO
CREATE PROCEDURE dbo.usp_log_run_failed
    @pipeline_run_id  VARCHAR(100),
    @entity_name      VARCHAR(100),
    @error_message    NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.etl_run_log
    SET
        end_time_utc  = SYSUTCDATETIME(),
        status        = 'FAILED',
        error_message = @error_message
    WHERE pipeline_run_id = @pipeline_run_id
      AND entity_name     = @entity_name
      AND status          = 'RUNNING';
END
GO


-- Update watermark (after successful load)
IF OBJECT_ID('dbo.usp_update_watermark', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_update_watermark;
GO
CREATE PROCEDURE dbo.usp_update_watermark
    @entity_name     VARCHAR(100),
    @new_watermark   DATETIME2,
    @pipeline_run_id VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @old DATETIME2;

    SELECT @old = last_watermark_value
    FROM dbo.control_ingestion_config
    WHERE entity_name = @entity_name;

    -- Update control table watermark
    UPDATE dbo.control_ingestion_config
    SET
        last_watermark_value = @new_watermark,
        updated_at = SYSUTCDATETIME()
    WHERE entity_name = @entity_name;

    -- Insert history audit
    INSERT INTO dbo.control_watermark_history
    (entity_name, old_watermark, new_watermark, updated_by_run, updated_at)
    VALUES
    (@entity_name, @old, @new_watermark, @pipeline_run_id, SYSUTCDATETIME());
END
GO


-- Optional: activity-level error log
IF OBJECT_ID('dbo.usp_log_activity_error', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_log_activity_error;
GO
CREATE PROCEDURE dbo.usp_log_activity_error
    @pipeline_run_id  VARCHAR(100),
    @pipeline_name    VARCHAR(200),
    @entity_name      VARCHAR(100),
    @activity_name    VARCHAR(200),
    @error_message    NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.etl_error_log
    (pipeline_run_id, pipeline_name, entity_name, activity_name, error_time_utc, error_message)
    VALUES
    (@pipeline_run_id, @pipeline_name, @entity_name, @activity_name, SYSUTCDATETIME(), @error_message);
END
GO
