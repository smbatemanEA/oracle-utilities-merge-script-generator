
/*------------------------------------------------------------------------------------------------------------------------------

	 Author:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	Created:  2025/04/09
	 Status:  POC draft. R&D ONLY; Not optimized.
	Purpose:  DDL for Table STG_GDE_MO
			  Staging table for CLOB JSON records. Table is populated via PARSE_W1_ASSET_JSON_TO_STG procedure
--------------------------------------------------------------------------------------------------------------------------------
Change History

 2025/04/22:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	(*) Renamed table to be agnostic to MOs.
		OLD NAME:  STG_W1_ASSET_MO

-------------------------------------------------------------------------------------------------------------------------------*/


CREATE TABLE ADMIN.STG_GDE_MO (
	 OBJ VARCHAR2(128 BYTE) COLLATE USING_NLS_COMP
	,PK1 VARCHAR2(256 BYTE) COLLATE USING_NLS_COMP
	,PK2 VARCHAR2(256 BYTE) COLLATE USING_NLS_COMP
	,PK3 VARCHAR2(256 BYTE) COLLATE USING_NLS_COMP
	,PK4 VARCHAR2(256 BYTE) COLLATE USING_NLS_COMP
	,PK5 VARCHAR2(256 BYTE) COLLATE USING_NLS_COMP
	,DELETED VARCHAR2(5 BYTE) COLLATE USING_NLS_COMP
	,JSON_DATA CLOB COLLATE USING_NLS_COMP
	,EXPORTED_TIMESTAMP TIMESTAMP (6) WITH TIME ZONE
	,UPDATED_TIMESTAMP TIMESTAMP (6) WITH TIME ZONE
	,MERGED_TIMESTAMP TIMESTAMP (6) WITH TIME ZONE
	,INGEST_ID      VARCHAR2(64)
	,INGEST_VERSION VARCHAR2(64)
   )  
DEFAULT COLLATION "USING_NLS_COMP" SEGMENT CREATION DEFERRED 
PCTFREE 10 PCTUSED 40 INITRANS 10 MAXTRANS 255 
NOCOMPRESS LOGGING
TABLESPACE "DATA" 
LOB ("JSON_DATA") STORE AS SECUREFILE (
  TABLESPACE "DATA" ENABLE STORAGE IN ROW CHUNK 8192
  NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES ) ;

   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."OBJ" 				IS '{"fieldName":"OBJ"}';
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."PK1" 				IS '{"fieldName":"PK1"}';
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."PK2" 				IS 'Optional. {"fieldName":"PK2"}';   
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."PK3" 				IS 'Optional. {"fieldName":"PK3"}';   
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."PK4" 				IS 'Optional. {"fieldName":"PK4"}';   
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."PK5" 				IS 'Optional. {"fieldName":"PK5"}';   
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."DELETED" 			IS 'Optional. {"fieldName":"DELETED"}';
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."JSON_DATA" 			IS '{"fieldName":"DATA"}';
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."EXPORTED_TIMESTAMP" IS '{"fieldName":"TIMESTAMP"}';
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."UPDATED_TIMESTAMP" 	IS '{"fieldName":"SYSTIMESTAMP","columnExpression":"SYSTIMESTAMP"}';
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."MERGED_TIMESTAMP" 	IS 'TS when CLOB was merged into CISADM tables';
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."INGEST_ID" 			IS 'UUID from INGEST tbl';
   COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."INGEST_VERSION" 	IS 'UUID from INGEST tbl';
-------------------------------------------------------------------------------------------







