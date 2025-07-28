
/*-------------------------------------------------------------------------------------------------------------------------------

	 Author:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	Created:  2025/07/10
	  RDBMS:  Oracle 23ai
	 Status:  Ready for QA
	Purpose:  DDL for Table STG_GDE_MO in 23ai
			  Staging table for CLOB JSON records. Table is populated via PARSE_GDE_TO_STG procedure
---------------------------------------------------------------------------------------------------------------------------------
Change History

 YYYY/MM/DD:  Name and Email 
	(* / + / -) Change/Add/Remove. A comprehensive description of the changes.

-------------------------------------------------------------------------------------------------------------------------------*/

CREATE TABLE ADMIN.STG_GDE_MO (
	 OBJ VARCHAR2(128 BYTE)
	,OBJ_TIMESTAMP DATE
	,PK1 VARCHAR2(256 BYTE)
	,PK2 VARCHAR2(256 BYTE)
	,PK3 VARCHAR2(256 BYTE)
	,PK4 VARCHAR2(256 BYTE)
	,PK5 VARCHAR2(256 BYTE)
	,DELETED VARCHAR2(5 BYTE)
	,JSON_DATA CLOB
	,MERGED_DTTM DATE
	,ETAG VARCHAR2(1000)
	,RESID VARCHAR2(1000)
	,FEED_ID VARCHAR2(1000)
)  
DEFAULT COLLATION "USING_NLS_COMP" SEGMENT CREATION DEFERRED 
PCTFREE 10 PCTUSED 40 INITRANS 10 MAXTRANS 255 
NOCOMPRESS LOGGING
TABLESPACE "DATA" 
LOB ("JSON_DATA") STORE AS SECUREFILE (
  TABLESPACE "DATA" ENABLE STORAGE IN ROW CHUNK 8192
  NOCACHE LOGGING NOCOMPRESS KEEP_DUPLICATES
);

COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."OBJ" IS '{"fieldName":"OBJ"} from JSON record';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."OBJ_TIMESTAMP" IS '{"fieldName":"TIMESTAMP"} from JSON record';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."PK1" IS '{"fieldName":"PK1"} from JSON record';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."PK2" IS 'Optional. {"fieldName":"PK2"} from JSON record';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."PK3" IS 'Optional. {"fieldName":"PK3"} from JSON record';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."PK4" IS 'Optional. {"fieldName":"PK4"} from JSON record';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."PK5" IS 'Optional. {"fieldName":"PK5"} from JSON record';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."DELETED" IS 'Optional. {"fieldName":"DELETED"} from JSON record';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."JSON_DATA" IS '{"fieldName":"DATA"} from JSON record';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."MERGED_DTTM" IS 'SYS date/time when CLOB was merged into CISADM tables';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."ETAG" IS 'ETAG from INGEST tbl';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."RESID" IS 'RESID from INGEST tbl';
COMMENT ON COLUMN "ADMIN"."STG_GDE_MO"."FEED_ID" IS '{"fieldName":"_id"} appended to JSON record by Live Feed';

