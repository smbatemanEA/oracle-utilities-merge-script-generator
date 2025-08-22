
/*------------------------------------------------------------------------------------------------------------------------------

	 Author:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	Created:  2025/07/10
	  RDBMS:  Oracle 23ai	
	 Status:  Ready for QA
	Purpose:  DDL for Table INGEST_GDE_JSON_COLLECTION in 23ai version of OCI ATP Workload DB
			  Target table from ATP's live feed process. Live feed consumes JSON file from Object Storage and
			  writes the JSON record as a collection.
--------------------------------------------------------------------------------------------------------------------------------
Change History

 YYYY/MM/DD:  Name and Email 
	(* / + / -) Change/Add/Remove. A comprehensive description of the changes.

-------------------------------------------------------------------------------------------------------------------------------*/


CREATE JSON COLLECTION TABLE "ADMIN"."INGEST_GDE_JSON_COLLECTION" 
	DEFAULT COLLATION "USING_NLS_COMP" SEGMENT CREATION IMMEDIATE 
	PCTFREE 10 PCTUSED 40 INITRANS 10 MAXTRANS 255 
	NOCOMPRESS LOGGING
	STORAGE(
		INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
		PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
		BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT
		)
TABLESPACE "DATA" 
JSON ("DATA") STORE AS (
	TABLESPACE "DATA"  CHUNK 8192 RETENTION MIN 1800
	STORAGE(
		INITIAL 262144 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
		PCTINCREASE 0
		BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT
		)
	)
;
--------------------------------------------------------
--  DDL for Index CM_GDE00001
--------------------------------------------------------

CREATE UNIQUE INDEX "ADMIN"."CM_GDE00001" ON "ADMIN"."INGEST_GDE_JSON_COLLECTION" (
	JSON_VALUE("DATA" FORMAT OSON , '$._id' RETURNING ANY ORA_RAWCOMPARE(2000) NO ARRAY ERROR ON ERROR TYPE(LAX) )
	)
	PCTFREE 10 INITRANS 2 MAXTRANS 255 
	STORAGE(
		INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
		PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
		BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT
		)
	TABLESPACE "DATA"
;

