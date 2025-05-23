CREATE OR REPLACE PROCEDURE ADMIN.GENERATE_MERGE_SCRIPT (

/*-----------------------------------------------------------------------------------------------------------------------------
  Procedure:	ORACLE UTILITIES MERGE SCRIPT GENERATOR
	 Author:	Sheldon Bateman (sheldon@gravityconsultingus.com)
	Created:	2025/04/30
	Version:	v1.0.0
	 Status:	Passed SIT for selected MOs	
	Purpose:	Dynamic generator for Oracle MERGE scripts aligned to Oracle Utilities Application Framework (OUAF) 
				standards, handling Maintenance Object (MO) JSON parsing, key-based ON clauses, and full datatype mappings.
				Execute with parameters (examples):
				  GENERATE_MERGE_SCRIPT(
					p_target_schema   => 'CISADM',
					p_target_table    => 'W1_ACTIVITY',
					p_procedure_name  => 'PROC_MERGE_INTO_W1_ACTIVITY',
					p_maint_obj_name  => 'W1-ASSET'
				  )

MIT License

Copyright (c) 2025 Sheldon Bateman (Gravity Consulting, Github: smbatemanEA)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------------------------------------------------------
Change History

 YYYY/MM/DD:	developer full name  
	(* / + / -) A comprehensive description of the changes.
		
-----------------------------------------------------------------------------------------------------------------------------*/


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
	
BEGIN
    -- Fetch ON clause columns based on W1%P0 index
    SELECT COLUMN_NAME
    BULK COLLECT INTO v_on_columns
    FROM ALL_IND_COLUMNS
    WHERE TABLE_OWNER = UPPER(p_target_schema)
		AND TABLE_NAME = UPPER(p_target_table)
		AND INDEX_NAME IN (
          SELECT INDEX_NAME
          FROM ALL_INDEXES
          WHERE TABLE_OWNER = UPPER(p_target_schema)
			AND TABLE_NAME = UPPER(p_target_table)
            AND INDEX_NAME LIKE 'W1%P0'
            AND UNIQUENESS = 'UNIQUE'
      )
    ORDER BY COLUMN_POSITION;

    -- Find the total number of columns once to control trailing commas in dynamic lists
    SELECT COUNT(*)
		INTO v_total_cols
    FROM ALL_TAB_COLUMNS
    WHERE OWNER = UPPER(p_target_schema)
		AND TABLE_NAME = UPPER(p_target_table)
		
		-- IN set is based on pre-defined staging table 
		AND COLUMN_NAME NOT IN ('OBJ', 'PK1', 'PK2', 'PK3', 'PK4', 'PK5', 'DELETED', 'JSON_DATA', 'EXPORTED_TIMESTAMP', 'MERGED_TIMESTAMP', 'INGEST_ID', 'INGEST_VERSION');

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
    v_sql := v_sql || '            stg.UPDATED_TIMESTAMP,' || CHR(10);

    OPEN v_columns FOR
        SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE, CHAR_USED, CHAR_LENGTH
          FROM ALL_TAB_COLUMNS
         WHERE OWNER = UPPER(p_target_schema)
           AND TABLE_NAME = UPPER(p_target_table)
           AND COLUMN_NAME NOT IN ('OBJ', 'PK1', 'PK2', 'PK3', 'PK4', 'PK5', 'DELETED', 'JSON_DATA', 'EXPORTED_TIMESTAMP', 'MERGED_TIMESTAMP', 'INGEST_ID', 'INGEST_VERSION')
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
                    v_select_cols := v_select_cols || '            CAST(TO_TIMESTAMP_TZ(jt.' || v_col_name || '_STR, ''YYYY-MM-DD"T"HH24:MI:SS.FF3TZR'') AS DATE) AS ' || v_col_name;
                ELSE
                    v_select_cols := v_select_cols || '            TO_TIMESTAMP_TZ(jt.' || v_col_name || '_STR, ''YYYY-MM-DD"T"HH24:MI:SS.FF3TZR'') AS ' || v_col_name;
                END IF;
            END;
        ELSIF v_col_name LIKE '%_DT' THEN
            v_json_table_cols := v_json_table_cols || '            ' || v_col_name || '_STR VARCHAR2(50) PATH ''$.' || v_col_name || '''';
            v_select_cols := v_select_cols || '            CAST(TO_TIMESTAMP_TZ(jt.' || v_col_name || '_STR, ''YYYY-MM-DD"T"HH24:MI:SS.FF3TZR'') AS DATE) AS ' || v_col_name;
        ELSIF v_data_type IN ('VARCHAR2', 'CHAR') THEN
            v_json_table_cols := v_json_table_cols || '            ' || v_col_name || ' VARCHAR2(' || v_char_length || ') PATH ''$.' || v_col_name || '''';
            v_select_cols := v_select_cols || '            jt.' || v_col_name;
        ELSIF v_data_type = 'NUMBER' THEN
            IF v_data_precision IS NOT NULL THEN
                v_json_table_cols := v_json_table_cols || '            ' || v_col_name || ' NUMBER(' || v_data_precision || CASE WHEN v_data_scale IS NOT NULL THEN ',' || v_data_scale ELSE '' END || ') PATH ''$.' || v_col_name || '''';
            ELSE
                v_json_table_cols := v_json_table_cols || '            ' || v_col_name || ' NUMBER PATH ''$.' || v_col_name || '''';
            END IF;
            v_select_cols := v_select_cols || '            jt.' || v_col_name;
        ELSE
            v_json_table_cols := v_json_table_cols || '            ' || v_col_name || ' ' || v_data_type || ' PATH ''$.' || v_col_name || '''';
            v_select_cols := v_select_cols || '            jt.' || v_col_name;
        END IF;
		
		-- Controls the trailing comma in the dynamic list
        IF v_col_index < v_total_cols THEN
            v_json_table_cols := v_json_table_cols || ',' || CHR(10);
            v_select_cols := v_select_cols || ',' || CHR(10);
        ELSE
            v_json_table_cols := v_json_table_cols || CHR(10);
            v_select_cols := v_select_cols || CHR(10);
        END IF;

        -- Build UPDATE SET only if column is NOT in ON clause
        DECLARE
            l_found BOOLEAN := FALSE;
        BEGIN
            FOR i IN 1 .. v_on_columns.COUNT LOOP
                IF v_on_columns(i) = v_col_name THEN
                    l_found := TRUE;
                    EXIT;
                END IF;
            END LOOP;
			
			-- Controls the trailing comma in the dynamic list
            IF NOT l_found THEN
                v_update_set := v_update_set || '    tgt.' || v_col_name || ' = src.' || v_col_name;
                IF v_col_index < v_total_cols THEN
                    v_update_set := v_update_set || ',' || CHR(10);
                ELSE
                    v_update_set := v_update_set || CHR(10);
                END IF;
            END IF;
        END;

        -- Build INSERT columns and values always
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
	-- CTE is not part of the column list loop so a prepended comma is required for it to be appended to the list
    v_sql := v_sql || v_select_cols || '            ,ROW_NUMBER() OVER (PARTITION BY stg.PK1 ORDER BY stg.UPDATED_TIMESTAMP DESC) AS rn' || CHR(10);
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
    v_sql := v_sql || 'WHEN MATCHED THEN UPDATE SET' || CHR(10);
    v_sql := v_sql || v_update_set;
    v_sql := v_sql || 'WHEN NOT MATCHED THEN INSERT (' || CHR(10);
    v_sql := v_sql || v_insert_cols;
    v_sql := v_sql || ') VALUES (' || CHR(10);
    v_sql := v_sql || v_insert_vals;
    v_sql := v_sql || ');' || CHR(10);
    v_sql := v_sql || 'END;';

    DBMS_OUTPUT.PUT_LINE(v_sql);
END;
