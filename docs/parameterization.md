# Parameterization Strategy

## Pipeline Parameters

pl_dynamic_copy parameters:
- p_source_table
- p_target_table
- p_load_type
- p_watermark_column
- p_source_query

---

## Dataset Parameters

Source dataset parameters:
- tableName
- query

Sink dataset parameters:
- folderPath
- fileName

---

## Linked Service Parameterization

Connection strings use:
- Azure Key Vault (recommended in real production)
- Or global parameters

---

## Dynamic Content Examples

Source Query:
@concat('SELECT * FROM ', pipeline().parameters.p_source_table)

Incremental Query:
@concat(
   'SELECT * FROM ',
   pipeline().parameters.p_source_table,
   ' WHERE ',
   pipeline().parameters.p_watermark_column,
   ' > ''',
   variables('v_watermark'),
   ''''
)

---

This makes the pipeline reusable for any table.
