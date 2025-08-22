
/*------------------------------------------------------------------------------------------------------------------------------

	 Author:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	Created:  2025/04/09
	 Status:  POC draft. R&D ONLY; Not optimized.
	Purpose:  DDL for Table PROCESSED_VERSIONS
			  Allows for processing only new versions of JSON without altering the original ingest table, which will fail 
			  the load collection live feed. 
			  Maintainins data integrity and avoiding the mutating table issue.
   Consider:  Periodically clean up the PROCESSED_VERSIONS table if it grows large, depending on data retention policies.		  
--------------------------------------------------------------------------------------------------------------------------------
Change History

 YYYY/MM/DD:  Name & Email 
	(* / + / -) Change/Add/Remove. A comprehensive description of the changes.

-------------------------------------------------------------------------------------------------------------------------------*/


CREATE TABLE ADMIN.PROCESSED_VERSIONS (
     VERSION VARCHAR2(64) PRIMARY KEY
    ,PROCESSED_TIMESTAMP TIMESTAMP DEFAULT SYSTIMESTAMP
);
	
   COMMENT ON COLUMN "ADMIN"."PROCESSED_VERSIONS"."VERSION"				IS 'UUID from INGEST_W1_ASSET_MO_JSON_COLLECTION';
   COMMENT ON COLUMN "ADMIN"."PROCESSED_VERSIONS"."PROCESSED_TIMESTAMP"	IS 'Timestamp of procedure execution';
-------------------------------------------------------------------------------------------