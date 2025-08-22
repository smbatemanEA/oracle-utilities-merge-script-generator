
CREATE OR REPLACE PROCEDURE PARSE_GDE_TO_STG AS
/*------------------------------------------------------------------------------------------------------------------------------
  Procedure:  PARSE_GDE_TO_STG (version for 19c)
	 Author:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	Created:  2025/04/22
	 Status:  Ready for QA
	Purpose:  Parses records to extract MO header and convert BLOB (OSON) to CLOB.
			  Preserves UUID values from Collection for traceability.
			  Source - INGEST_GDE_JSON_COLLECTION
			  Target - STG_GDE_MO
			  
   Consider:  Error Handling: Implement robust error handling within the procedure to manage any exceptions during processing.
--------------------------------------------------------------------------------------------------------------------------------
Change History

 YYYY/MM/DD:  Name & Email 
	(* / + / -) Change/Add/Remove. A comprehensive description of the changes.
	
 2025/04/10:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	(*)	Update to process only those records whose VERSION is not present 
		in the PROCESSED_VERSIONS table.
        
 2025/04/22:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	(+)	Based on PARSE_W1_ASSET_JSON_TO_STG procedure. This version assumes multiple MOs in GDE payload so as to make it work
		for all versions of GDE, not just Asset.

-------------------------------------------------------------------------------------------------------------------------------*/

BEGIN
  INSERT INTO ADMIN.STG_GDE_MO (
     INGEST_ID
    ,INGEST_VERSION
    ,OBJ
    ,PK1
    ,PK2
    ,PK3
    ,PK4
    ,PK5
    ,DELETED
    ,JSON_DATA
    ,EXPORTED_TIMESTAMP
    ,UPDATED_TIMESTAMP
    ,MERGED_TIMESTAMP
  )
  SELECT
     ing.ID AS INGEST_ID
    ,ing.VERSION AS INGEST_VERSION
    ,jt.OBJ
    ,jt.PK1
    ,jt.PK2
    ,jt.PK3
    ,jt.PK4
    ,jt.PK5
    ,jt.DELETED
    ,jt.DATA_CLOB
    ,TO_TIMESTAMP_TZ(jt.JSON_TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF6TZR') AS EXPORTED_TIMESTAMP
    ,SYSTIMESTAMP AS UPDATED_TIMESTAMP -- Increments TS from Live Feed to execution of this procedure
    ,NULL AS MERGED_TIMESTAMP -- Insures TS is null for future merge procedure
  FROM ADMIN.INGEST_GDE_JSON_COLLECTION ing
  JOIN JSON_TABLE(
         JSON_SERIALIZE(ing.JSON_DOCUMENT RETURNING CLOB),
         '$'
         COLUMNS (
            OBJ            VARCHAR2(128) PATH '$.OBJ'
           ,PK1            VARCHAR2(256) PATH '$.PK1'
           ,PK2            VARCHAR2(256) PATH '$.PK2'
           ,PK3            VARCHAR2(256) PATH '$.PK3'
           ,PK4            VARCHAR2(256) PATH '$.PK4'
           ,PK5            VARCHAR2(256) PATH '$.PK5'
           ,DELETED        VARCHAR2(5)   PATH '$.DELETED'
           ,DATA_CLOB      CLOB          FORMAT JSON PATH '$.DATA'
           ,JSON_TIMESTAMP VARCHAR2(50)  PATH '$.TIMESTAMP'
         )
       ) jt
ON NOT EXISTS (
	SELECT 1 
	FROM ADMIN.PROCESSED_VERSIONS pv 
	WHERE pv.VERSION = ing.VERSION
	);	   

-- After processing, insert the new versions into the tracking table
INSERT INTO ADMIN.PROCESSED_VERSIONS (VERSION)
  SELECT DISTINCT ing.VERSION
  FROM ADMIN.INGEST_GDE_JSON_COLLECTION ing
  WHERE NOT EXISTS (
    SELECT 1 FROM ADMIN.PROCESSED_VERSIONS pv WHERE pv.VERSION = ing.VERSION
  );	   
END;
/