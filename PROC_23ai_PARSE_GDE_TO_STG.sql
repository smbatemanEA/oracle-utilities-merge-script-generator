CREATE OR REPLACE PROCEDURE PARSE_GDE_TO_STG AS
/*------------------------------------------------------------------------------------------------------------------------------
  Procedure:  PARSE_GDE_TO_STG
	 Author:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	Created:  2025/07/10
	  RDBMS:  Oracle 23ai
	 Status:  Ready for QA
	Purpose:  Parses records to extract MO header and convert OSON record to CLOB.
			  Preserves UUID values from Collection for traceability.
			  Source - INGEST_GDE_JSON_COLLECTION
			  Target - STG_GDE_MO
--------------------------------------------------------------------------------------------------------------------------------
Change History

 YYYY/MM/DD:  Name and Email 
	(* / + / -) Change/Add/Remove. A comprehensive description of the changes.
	

-------------------------------------------------------------------------------------------------------------------------------*/

BEGIN
   INSERT INTO ADMIN.STG_GDE_MO
      (
         OBJ
		,OBJ_TIMESTAMP
        ,PK1
        ,PK2
        ,PK3
        ,PK4
        ,PK5
        ,DELETED
        ,JSON_DATA
        ,FEED_ID		
        ,ETAG
        ,RESID
        ,MERGED_DTTM
      )
   SELECT
         jt.OBJ
		,CAST(
		   TO_TIMESTAMP_TZ(jt.TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS.FF6TZR') AT TIME ZONE 'UTC'
		   AS DATE
		 ) AS OBJ_TIMESTAMP
        ,jt.PK1
        ,jt.PK2
        ,jt.PK3
        ,jt.PK4
        ,jt.PK5
        ,jt.DELETED
        ,jt.DATA_CLOB
        ,jt.FEED_ID		
        ,ing.ETAG
        ,ing.RESID	
        ,NULL AS MERGED_DTTM -- Insures TS is null for future merge procedure
    FROM (  -- Subquery acts only on new ingest records
        SELECT src.DATA, src.ETAG, src.RESID
        FROM INGEST_GDE_JSON_COLLECTION src
        LEFT JOIN PROCESSED_VERSIONS pv
           ON src.ETAG = pv.ETAG
        WHERE pv.ETAG IS NULL
    ) ing
      JOIN JSON_TABLE(
            JSON_SERIALIZE(ing.DATA RETURNING CLOB),
            '$'
            COLUMNS (
                 OBJ          VARCHAR2(128) PATH '$.OBJ'
				,TIMESTAMP	  VARCHAR2(50)  PATH '$.TIMESTAMP'
                ,PK1          VARCHAR2(256) PATH '$.PK1'
                ,PK2          VARCHAR2(256) PATH '$.PK2'
                ,PK3          VARCHAR2(256) PATH '$.PK3'
                ,PK4          VARCHAR2(256) PATH '$.PK4'
                ,PK5          VARCHAR2(256) PATH '$.PK5'
                ,DELETED      VARCHAR2(5)   PATH '$.DELETED'
                ,DATA_CLOB    CLOB          FORMAT JSON PATH '$.DATA'
                ,FEED_ID      VARCHAR2(1000) PATH '$._id'
            )
      ) jt
   ON NOT EXISTS ( 
         SELECT 1
         FROM ADMIN.PROCESSED_VERSIONS pv
         WHERE pv.FEED_ID = jt.FEED_ID
           AND NVL(pv.ETAG, '~NULL~') = NVL(ing.ETAG, '~NULL~')
      );
      
   -- Record newly processed documents into the tracking table
   INSERT INTO ADMIN.PROCESSED_VERSIONS (FEED_ID, ETAG)
   SELECT DISTINCT
         jt.FEED_ID
        ,ing.ETAG
   FROM ADMIN.INGEST_GDE_JSON_COLLECTION ing
      JOIN JSON_TABLE(
            JSON_SERIALIZE(ing.DATA RETURNING CLOB),
            '$'
            COLUMNS (
                 FEED_ID VARCHAR2(1000) PATH '$._id'
            )
      ) jt
   ON NOT EXISTS ( 
         SELECT 1
         FROM ADMIN.PROCESSED_VERSIONS pv
         WHERE pv.FEED_ID = jt.FEED_ID
      );
END;
/
