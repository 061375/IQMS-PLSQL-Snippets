/* 
 	Recursively set Document # in the Document Library to ISO format 
	@author Jeremy Heminger <jheminger@tstwater.com>, <contact @jeremyheminger.com>
	@version 1.0.2

	This can be run in plsql (cmd) or in Data Dictionary

	Pulls the ISO number from a well structured file name

	Example:

	HR_1000-0001 Test File.pdf

	Will add:

	HR_1000-0001

	@notes

	-- version 1.0.2 
		ISO must be 13 characters long. This can include a space at the end.
*/
DECLARE 
	-- init variables
	doc_lib_id varchar(2) := 18;

BEGIN	
	-- loop the requested library
  	FOR n IN (SELECT * FROM external_doc WHERE DOC_LIBRARY_ID = doc_lib_id)
    LOOP
        UPDATE external_doc SET DOCNO = substr(n.DESCRIP,0,13) where id = n.id;
    END LOOP;
 END;