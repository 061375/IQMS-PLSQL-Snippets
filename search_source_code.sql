/**
	Search Procedures, Triggers, etc for sorce code
	NOTE - This appears to search revisions as well so the results found may not contain the code searched
*/
SELECT *
FROM dba_source
WHERE upper(text) LIKE upper('%my_search_query%')