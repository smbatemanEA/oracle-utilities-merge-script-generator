CREATE OR REPLACE FUNCTION ADMIN.GET_NORMALIZED_DATE (
   p_str IN VARCHAR2
) RETURN DATE IS
/*------------------------------------------------------------------------------------------------------------------------------

	 Author:  Sheldon Bateman (sheldon@gravityconsultingus.com)
	Created:  2025/07/24
	  RDBMS:  Oracle 23ai
	 Status:  Ready for QA
	Purpose:  Function for normalizing inconsistent date formats
			  GDE JSON payloads generally follow ISO 8601 with T and Z in the timestamp. However tests indicate that not all 
			  date values explicitly follow this format, which leads to issues during downstream merge scripting into CISADM.
			  This is a reusable function that takes a VARCHAR2 input (your *_DTTM_STR or *_DT_STR values) and returns a 
			  normalized DATE, regardless of whether the input is:
				- ISO 8601 with T and Z
				- Oracle verbose with fractional seconds and time zone
				- Just a date like YYYY-MM-DD
--------------------------------------------------------------------------------------------------------------------------------
Change History

 YYYY/MM/DD:  Name and Email 
	(* / + / -) Change/Add/Remove. A comprehensive description of the changes.

-------------------------------------------------------------------------------------------------------------------------------*/

BEGIN
   IF p_str IS NULL OR TRIM(p_str) = '' THEN
      RETURN NULL;

   ELSIF INSTR(p_str, 'T') > 0 THEN
      
	  -- Format B: 2025-01-23T13:11:29Z
      RETURN CAST(
         TO_TIMESTAMP_TZ(REPLACE(p_str, 'Z', ' UTC'), 'YYYY-MM-DD"T"HH24:MI:SS TZR')
         AT TIME ZONE 'UTC' AS DATE
      );

   ELSIF REGEXP_LIKE(p_str, '^[0-9]{2}-[A-Z]{3}-[0-9]{2}') THEN
      
	  -- Format A: 14-MAR-25 01.03.03.000673000 AM GMT
      RETURN CAST(
         TO_TIMESTAMP_TZ(p_str, 'DD-MON-RR HH.MI.SS.FF9 AM TZR')
         AT TIME ZONE 'UTC' AS DATE
      );

   ELSIF LENGTH(TRIM(p_str)) = 10 THEN
      
	  -- Format C: 2024-10-29
      RETURN TO_DATE(p_str, 'YYYY-MM-DD');

   ELSE
      RETURN NULL;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RETURN NULL; -- Fail-safe fallback
END;
/


