/* =========================================================
   CONTROL TABLES (Metadata + Watermark)
   Target: Azure SQL DB / Synapse (Dedicated SQL Pool works too)
   ========================================================= */

-- 1) Ingestion configuration table (metadata-driven)
IF OBJECT_ID('dbo.control_ingestion_config', 'U') IS NOT NULL
    DROP TABLE dbo.control_ingestion_config;
GO

CREATE TABLE dbo.control_ingestion_config (
    config_id            INT IDENTITY(1,1) PRIMARY KEY,
    entity_name          VARCHAR(100) NOT NULL,   -- e.g., customers, orders
    source_type          VARCHAR(30)  NOT NULL,   -- SQL | FILE | API (future)
    source_schema        VARCHAR(50)  NULL,
    source_table         VARCHAR(100) NULL,       -- for SQL
    source_path          VARCHAR(400) NULL,       -- for FILE
    target_schema        VARCHAR(50)  NOT NULL DEFAULT 'dbo',
    target_table         VARCHAR(100) NOT NULL,
    load_type            VARCHAR(20)  NOT NULL,   -- FULL | INCREMENTAL
    watermark_column     VARCHAR(100) NULL,       -- e.g., LastModifiedDate / updated_at
    last_watermark_value DATETIME2    NULL,       -- last successful watermark
    is_active            BIT          NOT NULL DEFAULT 1,
    created_at           DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
    updated_at           DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- Helpful index for fast lookup
CREATE INDEX IX_control_ingestion_config_active
ON dbo.control_ingestion_config(is_active, entity_name);
GO


-- 2) Optional: Watermark history (audit)
IF OBJECT_ID('dbo.control_watermark_history', 'U') IS NOT NULL
    DROP TABLE dbo.control_watermark_history;
GO

CREATE TABLE dbo.control_watermark_history (
    history_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
    entity_name     VARCHAR(100) NOT NULL,
    old_watermark   DATETIME2 NULL,
    new_watermark   DATETIME2 NULL,
    updated_by_run  VARCHAR(100) NULL,           -- pipeline run id
    updated_at      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE INDEX IX_control_watermark_history_entity
ON dbo.control_watermark_history(entity_name, updated_at);
GO


/* =========================================================
   SAMPLE SEED DATA (Edit as needed)
   NOTE: for FILE sources, fill source_path; for SQL sources,
   fill source_schema + source_table.
   ========================================================= */

INSERT INTO dbo.control_ingestion_config
(entity_name, source_type, source_schema, source_table, source_path,
 target_schema, target_table, load_type, watermark_column, last_watermark_value, is_active)
VALUES
('customers', 'SQL',  'dbo', 'Customers', NULL, 'dbo', 'stg_customers', 'INCREMENTAL', 'LastModifiedDate', '2026-01-01', 1),
('orders',    'SQL',  'dbo', 'Orders',    NULL, 'dbo', 'stg_orders',    'INCREMENTAL', 'LastModifiedDate', '2026-01-01', 1),
('products',  'FILE', NULL,  NULL,        '/landing/products/', 'dbo', 'stg_products', 'FULL', NULL, NULL, 1);
GO
