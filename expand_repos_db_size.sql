/* 
 	Expand REPOS database size
	@author Jeremy Heminger <jheminger@tstwater.com>, <contact @jeremyheminger.com>
	@version 1.0.1

	This can be run in plsql (cmd) or in Data Dictionary
*/
DECLARE 
	-- init variables
	size varchar2(5);
	filepath text;
BEGIN
	-- a string representing the size of the DBF file ( the amount to expand the database overall )
	size := '2000M';	
	-- file path to teh DBF file
	-- the number should increment by one based on the hiest number in the REPOS directory
	filepath := 'C:\ORACLE\ORADATA\REPOS\IQUSERS07.DBF';

	-- this is the actual query that does the work
	ALTER TABLESPACE "USERS" ADD DATAFILE filepath SIZE size REUSE;
 END;
