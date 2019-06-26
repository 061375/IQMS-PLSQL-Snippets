/* 
 	Find and format documents that meet the criteria for correct formatting
	@author Jeremy Heminger <jheminger@tstwater.com>, <contact @jeremyheminger.com>
	@version 1.0.5

	When setting a document to 'Released' status set the Document # to an ISO standard
	if the description matches the pattern AA_####-#### OR AAA_####-#### 
		Example: HR_1000-0001 This is a test.pdf 
				 OR 
				 ENG_1000-0001 This is a test.pdf
	then set the document number to the prefix of the document title

	@ver 1.0.5 - finally realized the error was in the datatype for n_len



	@broken - TRUE
			  @ver 1.0.5 still fails at line 76 for some reason
			  	   despite setting the data type to number
*/
CREATE OR REPLACE TRIGGER tst_set_doc_number
BEFORE UPDATE ON external_doc
FOR EACH ROW
WHEN (
	new.STATUS = 'Released'
	-- current document# is either '' or is ONLY a number
	AND (
			new.DOC_LIBRARY_ID = ''
			OR 				
			REGEXP_LIKE(new.DOC_LIBRARY_ID,'(\d+)')
		)
	)
DECLARE 
	-- init variables
	b_update boolean;
	n_len number := 1;
BEGIN
	-- reset for each loop
	b_update := FALSE;

	-- check if criteria is met 

	-- AAA_####-####_AA
	IF b_update = FALSE AND REGEXP_LIKE(:new.DESCRIP,'([A-Z][A-Z][A-Z])_(\d{4})-(\d{4})_([A-Z])') THEN 
		b_update := TRUE;
		n_len := 15;
	END IF;
	-- AA_####-####_AA
	IF b_update = FALSE AND REGEXP_LIKE(:new.DESCRIP,'([A-Z][A-Z])_(\d{4})-(\d{4})_([A-Z])') THEN 
		b_update := TRUE;
		n_len := 14;
	END IF;
	-- AAA_####-####_A
	IF b_update = FALSE AND REGEXP_LIKE(:new.DESCRIP,'([A-Z][A-Z][A-Z])_(\d{4})-(\d{4})_([A-Z])') THEN 
		b_update := TRUE;
		n_len := 15;
	END IF;
	-- AA_####-####_A
	IF b_update = FALSE AND REGEXP_LIKE(:new.DESCRIP,'([A-Z][A-Z])_(\d{4})-(\d{4})_([A-Z])') THEN 
		b_update := TRUE;
		n_len := 14;
	END IF;
	-- AAA_####-####
	IF b_update = FALSE AND REGEXP_LIKE(:new.DESCRIP,'([A-Z][A-Z][A-Z])_(\d{4})-(\d{4}))') THEN  
		b_update := TRUE;
		n_len := 13;
	END IF;
	-- AA_####-####
	IF b_update = FALSE AND REGEXP_LIKE(:new.DESCRIP,'([A-Z][A-Z])_(\d{4})-(\d{4}))') THEN       
		b_update := TRUE;
		n_len := 12;
	END IF;

	-- can we update?
	IF b_update = TRUE THEN
		-- update
		:new.DOCNO := substr(:new.DESCRIP,0,n_len);
	END IF;
END;