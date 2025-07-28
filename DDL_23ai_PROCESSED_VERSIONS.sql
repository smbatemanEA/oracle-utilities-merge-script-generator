
/*------------------------------------------------------------------------------------------------------------------------------

	 Author:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	Created:  2025/07/10
	  RDBMS:  Oracle 23ai
	 Status:  Ready for QA
	Purpose:  DDL for Table PROCESSED_VERSIONS
			  Allows for processing only new versions of JSON without altering the original ingest table, which will fail 
			  the load collection live feed. 
			  Maintainins data integrity and avoiding the mutating table issue.
   Consider:  Periodically clean up the PROCESSED_VERSIONS table if it grows large, depending on data retention policies.		  
--------------------------------------------------------------------------------------------------------------------------------
Change History

 YYYY/MM/DD:  Name and Email 
	(* / + / -) Change/Add/Remove. A comprehensive description of the changes.

-------------------------------------------------------------------------------------------------------------------------------*/


CREATE TABLE ADMIN.PROCESSED_VERSIONS (
   FEED_ID VARCHAR2(1000) PRIMARY KEY, 
   ETAG VARCHAR2(1000),
   PROCESSED_DTTM DATE DEFAULT SYSDATE
);

COMMENT ON COLUMN "ADMIN"."PROCESSED_VERSIONS"."FEED_ID" IS '{"fieldName":"_id"} appended to JSON record by Live Feed';
COMMENT ON COLUMN "ADMIN"."PROCESSED_VERSIONS"."ETAG" IS 'ETAG from INGEST tbl';
COMMENT ON COLUMN "ADMIN"."PROCESSED_VERSIONS"."PROCESSED_DTTM" IS 'Date/time of procedure execution (UTC normalized)';

