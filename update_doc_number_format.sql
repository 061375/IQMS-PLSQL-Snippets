/* 
 	Find and format documents that meet the criteria for correct formatting
	@author Jeremy Heminger <jheminger@tstwater.com>, <contact @jeremyheminger.com>
	@version 1.0.2

	find any documents that don't have a document number or the document number is not formatted
	if the description matches the pattern AA_####-#### OR AAA_####-#### 
		Example: HR_1000-0001 This is a test.pdf 
				 OR 
				 ENG_1000-0001 This is a test.pdf
	then set the document number to the prefix of the document title

	@todo: I need to be able to handle these formats as well:
			HR_1000-0001_A
			ENG_1000-0001_B
*/
BEGIN
	FOR n IN (SELECT * FROM external_doc 
		-- find documents that aren't formatted
		WHERE (
			DOC_LIBRARY_ID = ''
			OR 
			REGEXP_LIKE(DOC_LIBRARY_ID,'(\d+)')
		)
		-- make sure the document isn't checked out and isn't New
		AND STATUS != 'Checked Out'  
		AND STATUS != 'New')
	-- loop what you found
		LOOP
			-- if criteria of the file name IS met then
			IF REGEXP_LIKE(n.DESCRIP,'([A-Z][A-Z]_(\d{4})-(\d{4}))') -- AA_####-####
				OR 
				REGEXP_LIKE(n.DESCRIP,'([A-Z][A-Z][A-Z]_(\d{4})-(\d{4}))') -- AAA_####-####
				THEN
					-- update with the file name
					UPDATE external_doc SET DOCNO = substr(n.DESCRIP,0,13) where id = n.id;
			END IF;
		END LOOP;
END;