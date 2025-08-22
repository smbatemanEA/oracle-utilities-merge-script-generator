CREATE OR REPLACE PROCEDURE ADMIN.GENERATE_MERGE_SCRIPT (

/*--------------------------------------------------------------------------------------------------------------------------------------
  Procedure:  ORACLE UTILITIES MERGE SCRIPT GENERATOR
     Author:  Sheldon Bateman (sheldon@gravityconsultingus.com)
    Created:  2025/08/22
      RDBMS:  Oracle 23ai
    Version:  v23ai.1.0.1
     Status:  Passed SIT for selected MOs  
   Purpose:   Dynamic generator for Oracle MERGE scripts aligned to Oracle Utilities Application Framework (OUAF) 
              standards, handling Maintenance Object (MO) JSON parsing, key-based ON clauses, and full datatype mappings.
              Version is specific to 23ai. For use with 19c, use this version: oracle-utilities-merge-script-generator v19c.1.0.0.sql
              Execute with parameters (examples):
                GENERATE_MERGE_SCRIPT(
                  p_target_schema   => 'CISADM',
                  p_target_table    => 'W1_ASSET',
                  p_procedure_name  => 'PROC_MERGE_INTO_W1_ASSET',
                  p_maint_obj_name  => 'W1-ASSET'
                )
----------------------------------------------------------------------------------------------------------------------------------------
Change History

 YYYY/MM/DD: developer full name  
  (* / + / -) A comprehensive description of the changes.
  
 2025/07/27:  Sheldon Bateman (sheldon@gravityconsultingus.com)
      (*) Changed section, "Build JSON_TABLE COLUMNS and SELECT" to use custom function, ADMIN.GET_NORMALIZED_DATE()
      
 2025/08/22:  Sheldon Bateman (sheldon@gravityconsultingus.com)
      (*) Changed lines to correcct missing forward slash, "/" after 'END'
      (*) changed WHERE clause for section "Fetch ON clause columns based on W1%P0 index" to include control table indexes.
      (*) Corrected trailing comma in generated UPDATE SET clause when last physical column is part of ON key.
--------------------------------------------------------------------------------------------------------------------------------------*/

     p_target_schema   IN VARCHAR2
    ,p_target_table    IN VARCHAR2
    ,p_procedure_name  IN VARCHAR2
    ,p_maint_obj_name  IN VARCHAR2
) IS

    v_sql              CLOB;
    v_columns          SYS_REFCURSOR;
    v_col_name         VARCHAR2(128);
    v_data_type        VARCHAR2(128);
    v_data_length      NUMBER;
    v_data_precision   NUMBER;
    v_data_scale       NUMBER;
    v_char_used        VARCHAR2(3);
    v_char_length      NUMBER;
    v_on_columns       SYS.DBMS_DEBUG_VC2COLL := SYS.DBMS_DEBUG_VC2COLL();
    v_json_table_cols  CLOB;
    v_select_cols      CLOB;
    v_update_set       CLOB;
    v_insert_cols      CLOB;
    v_insert_vals      CLOB;
    v_on_clause        CLOB;
    v_col_index        INTEGER := 0;
    v_total_cols       INTEGER;
    -- Minimal bug-fix controls:
    v_update_index     INTEGER := 0;      -- count of non-key assignments emitted
    l_found            BOOLEAN := FALSE;  -- per-column flag: current col is ON-key?

BEGIN
    -- Fetch ON clause columns based on W1%P0 / XC%P0 / XC%S1 unique index
    SELECT COLUMN_NAME
    BULK COLLECT INTO v_on_columns
    FROM ALL_IND_COLUMNS
    WHERE TABLE_OWNER = UPPER(p_target_schema)
      AND TABLE_NAME  = UPPER(p_target_table)
      AND INDEX_NAME IN (
        SELECT INDEX_NAME
        FROM ALL_INDEXES
        WHERE (1=1)
          AND TABLE_OWNER = UPPER(p_target_schema)
          AND TABLE_NAME  = UPPER(p_target_table)
          AND (
               INDEX_NAME LIKE 'W1%P0'  -- WACS/ODM master tables
            OR INDEX_NAME LIKE 'XC%P0'  -- control tables
            OR INDEX_NAME LIKE 'XC%S1'  -- control tables
          )
          AND UNIQUENESS = 'UNIQUE'
      )
    ORDER BY COLUMN_POSITION;

    -- Total columns considered for SELECT/INSERT/JSON_TABLE lists (excludes staging-only cols)
    SELECT COUNT(*)
      INTO v_total_cols
    FROM ALL_TAB_COLUMNS
    WHERE OWNER = UPPER(p_target_schema)
      AND TABLE_NAME = UPPER(p_target_table)
      AND COLUMN_NAME NOT IN ('OBJ','OBJ_TIMESTAMP','PK1','PK2','PK3','PK4','PK5','DELETED','JSON_DATA','MERGED_DTTM','ETAG','RESID','FEED_ID');

    -- Build the ON clause text
    FOR i IN 1 .. v_on_columns.COUNT LOOP
        IF i > 1 THEN
            v_on_clause := v_on_clause || '    AND ';
        ELSE
            v_on_clause := v_on_clause || 'ON (' || CHR(10) || '    ';
        END IF;
        v_on_clause := v_on_clause || 'tgt.' || v_on_columns(i) || ' = src.' || v_on_columns(i) || CHR(10);
    END LOOP;
    v_on_clause := v_on_clause || ')';

    v_sql := 'CREATE OR REPLACE PROCEDURE ' || p_procedure_name || ' AS' || CHR(10);
    v_sql := v_sql || 'BEGIN' || CHR(10);
    v_sql := v_sql || 'MERGE INTO ' || p_target_schema || '.' || p_target_table || ' tgt' || CHR(10);
    v_sql := v_sql || 'USING (' || CHR(10);
    v_sql := v_sql || '    WITH ranked AS (' || CHR(10);
    v_sql := v_sql || '        SELECT' || CHR(10);
    v_sql := v_sql || '            stg.PK1,' || CHR(10);
    v_sql := v_sql || '            stg.OBJ,' || CHR(10);
    v_sql := v_sql || '            stg.OBJ_TIMESTAMP,' || CHR(10);

    OPEN v_columns FOR
        SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE, CHAR_USED, CHAR_LENGTH
          FROM ALL_TAB_COLUMNS
         WHERE OWNER = UPPER(p_target_schema)
           AND TABLE_NAME = UPPER(p_target_table)
		   
		   -- Exclude columns in STG_GDE_MO table (JSON Record staging table)
           AND COLUMN_NAME NOT IN ('OBJ','OBJ_TIMESTAMP','PK1','PK2','PK3','PK4','PK5','DELETED','JSON_DATA','MERGED_DTTM','ETAG','RESID','FEED_ID')
         ORDER BY COLUMN_ID;

    LOOP
        FETCH v_columns INTO v_col_name, v_data_type, v_data_length, v_data_precision, v_data_scale, v_char_used, v_char_length;
        EXIT WHEN v_columns%NOTFOUND;
        v_col_index := v_col_index + 1;

        -- Build JSON_TABLE COLUMNS and SELECT
        IF v_col_name LIKE '%_DTTM' THEN
            v_json_table_cols := v_json_table_cols || '            ' || v_col_name || '_STR VARCHAR2(50) PATH ''$.' || v_col_name || '''';
            DECLARE
                l_dttm_in_on_clause BOOLEAN := FALSE;
            BEGIN
                FOR i IN 1 .. v_on_columns.COUNT LOOP
                    IF v_on_columns(i) = v_col_name THEN
                        l_dttm_in_on_clause := TRUE;
                        EXIT;
                    END IF;
                END LOOP;
                IF l_dttm_in_on_clause THEN
                    v_select_cols := v_select_cols || '            CAST(ADMIN.GET_NORMALIZED_DATE(jt.' || v_col_name || '_STR) AS DATE) AS ' || v_col_name;
                ELSE
                    v_select_cols := v_select_cols || '            ADMIN.GET_NORMALIZED_DATE(jt.' || v_col_name || '_STR) AS ' || v_col_name;
                END IF;
            END;
        ELSIF v_col_name LIKE '%_DT' THEN
            v_json_table_cols := v_json_table_cols || '            ' || v_col_name || '_STR VARCHAR2(50) PATH ''$.' || v_col_name || '''';
            v_select_cols     := v_select_cols     || '            CAST(ADMIN.GET_NORMALIZED_DATE(jt.' || v_col_name || '_STR) AS DATE) AS ' || v_col_name;
        ELSIF v_data_type IN ('VARCHAR2','CHAR') THEN
            v_json_table_cols := v_json_table_cols || '            ' || v_col_name || ' VARCHAR2(' || v_char_length || ') PATH ''$.' || v_col_name || '''';
            v_select_cols     := v_select_cols     || '            jt.' || v_col_name;
        ELSIF v_data_type = 'NUMBER' THEN
            IF v_data_precision IS NOT NULL THEN
                v_json_table_cols := v_json_table_cols || '            ' || v_col_name || ' NUMBER(' || v_data_precision || CASE WHEN v_data_scale IS NOT NULL THEN ',' || v_data_scale ELSE '' END || ') PATH ''$.' || v_col_name || '''';
            ELSE
                v_json_table_cols := v_json_table_cols || '            ' || v_col_name || ' NUMBER PATH ''$.' || v_col_name || '''';
            END IF;
            v_select_cols := v_select_cols || '            jt.' || v_col_name;
        ELSE
            v_json_table_cols := v_json_table_cols || '            ' || v_col_name || ' ' || v_data_type || ' PATH ''$.' || v_col_name || '''';
            v_select_cols     := v_select_cols     || '            jt.' || v_col_name;
        END IF;

        -- Comma control for JSON_TABLE COLUMNS and SELECT lists (these include ALL eligible columns)
        IF v_col_index < v_total_cols THEN
            v_json_table_cols := v_json_table_cols || ',' || CHR(10);
            v_select_cols     := v_select_cols     || ',' || CHR(10);
        ELSE
            v_json_table_cols := v_json_table_cols || CHR(10);
            v_select_cols     := v_select_cols     || CHR(10);
        END IF;

        -- Determine if current column is part of the ON key
        l_found := FALSE;
        FOR i IN 1 .. v_on_columns.COUNT LOOP
            IF v_on_columns(i) = v_col_name THEN
                l_found := TRUE;
                EXIT;
            END IF;
        END LOOP;

        -- UPDATE list: only non-key columns; prefix comma between items (never trailing at end)
        IF NOT l_found THEN
            IF v_update_index > 0 THEN
                v_update_set := v_update_set || ',' || CHR(10);
            END IF;
            v_update_set := v_update_set || '    tgt.' || v_col_name || ' = src.' || v_col_name;
            v_update_index := v_update_index + 1;
        END IF;

        -- INSERT columns and values (keys + non-keys)
        v_insert_cols := v_insert_cols || '    ' || v_col_name;
        v_insert_vals := v_insert_vals || '    src.' || v_col_name;
        IF v_col_index < v_total_cols THEN
            v_insert_cols := v_insert_cols || ',' || CHR(10);
            v_insert_vals := v_insert_vals || ',' || CHR(10);
        ELSE
            v_insert_cols := v_insert_cols || CHR(10);
            v_insert_vals := v_insert_vals || CHR(10);
        END IF;

    END LOOP;
    CLOSE v_columns;

    -- Assemble full SQL
    -- CTE is not part of the column list loop so a prepended comma is required for ROW_NUMBER
    v_sql := v_sql || v_select_cols || '            ,ROW_NUMBER() OVER (PARTITION BY stg.PK1 ORDER BY stg.OBJ_TIMESTAMP DESC) AS rn' || CHR(10);
    v_sql := v_sql || '        FROM ADMIN.STG_GDE_MO stg,' || CHR(10);
    v_sql := v_sql || '            JSON_TABLE(' || CHR(10);
    v_sql := v_sql || '                stg.JSON_DATA,' || CHR(10);
    v_sql := v_sql || '                ''$.' || p_target_table || '[*]'' COLUMNS (' || CHR(10);
    v_sql := v_sql || v_json_table_cols;
    v_sql := v_sql || '                )' || CHR(10);
    v_sql := v_sql || '            ) jt' || CHR(10);
    v_sql := v_sql || '    )' || CHR(10);
    v_sql := v_sql || '    SELECT r.*' || CHR(10);
    v_sql := v_sql || '    FROM ranked r' || CHR(10);
    v_sql := v_sql || '    WHERE (1=1)' || CHR(10);
    v_sql := v_sql || '      AND r.rn = 1' || CHR(10);
    v_sql := v_sql || '      AND r.OBJ = ''' || p_maint_obj_name || '''' || CHR(10);
    v_sql := v_sql || ') src' || CHR(10);
    v_sql := v_sql || v_on_clause || CHR(10);

    -- Emit UPDATE only if necessary
    IF v_update_index > 0 THEN
        v_sql := v_sql || 'WHEN MATCHED THEN UPDATE SET' || CHR(10);
        v_sql := v_sql || v_update_set || CHR(10);
    END IF;

    v_sql := v_sql || 'WHEN NOT MATCHED THEN INSERT (' || CHR(10);
    v_sql := v_sql || v_insert_cols;
    v_sql := v_sql || ') VALUES (' || CHR(10);
    v_sql := v_sql || v_insert_vals;
    v_sql := v_sql || ');' || CHR(10);
    v_sql := v_sql || 'END;' || CHR(10);
    v_sql := v_sql || '/';

    DBMS_OUTPUT.PUT_LINE(v_sql);
END;
/
