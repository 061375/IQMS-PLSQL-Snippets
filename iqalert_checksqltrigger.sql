/* 
	QUERY STRUCTURE BOOLEAN SHOULD IQALERT TAKE ACTION
	USE NVL TO MAKE SURE IF A RESULT RETURNS NULL IT WILL DEFAULT TO 0
*/
SELECT NVL(
(
	
	/* 
		QUERY HERE SHOULD RETURN 1 OR 0
	*/

),0) FROM dual

/* 
	EXAMPLE TO DETERMINE IF ANY DOCUMENTS ARE CURRENTLY NOT RELEASED
*/
SELECT nvl(
(
	SELECT CASE WHEN max(ID) is null THEN '0' ELSE '1' END Doc_not_released
		FROM external_doc
	WHERE status != 'Released'
),0) FROM dual