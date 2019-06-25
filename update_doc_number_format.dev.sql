DECLARE 
	-- init variables
	b_update boolean;
	n_len smallint(2) := 0;
BEGIN
	FOR n IN (SELECT * FROM external_doc 
		WHERE (
			DOC_LIBRARY_ID = ''
			OR 
			REGEXP_LIKE(DOC_LIBRARY_ID,'(\d+)')
		)
		AND STATUS != 'Checked Out'  
		AND STATUS != 'New')
		LOOP
			-- reset for each loop
			b_update := FALSE;

			-- check if criteria is met 

			IF REGEXP_LIKE(n.DESCRIP,'([A-Z][A-Z][A-Z]_(\d{4})-(\d{4}))_[A-Z]') THEN 				 -- AA_####-####_A
				b_update := TRUE;
				n_len := 15;
			END IF;
			IF b_update = FALSE AND REGEXP_LIKE(n.DESCRIP,'([A-Z][A-Z]_(\d{4})-(\d{4}))_[A-Z]') THEN -- AAA_####-####_A
				b_update := TRUE;
				n_len := 14;
			END IF;
			IF b_update = FALSE AND REGEXP_LIKE(n.DESCRIP,'([A-Z][A-Z][A-Z]_(\d{4})-(\d{4}))') THEN  -- AAA_####-####
				b_update := TRUE;
				n_len := 13;
			END IF;
			IF b_update = FALSE AND REGEXP_LIKE(n.DESCRIP,'([A-Z][A-Z]_(\d{4})-(\d{4}))') THEN       -- AA_####-####
				b_update := TRUE;
				n_len := 12;
			END IF;


			-- if criteria is met 
			IF b_update = TRUE THEN
				-- update
				UPDATE external_doc SET DOCNO = substr(n.DESCRIP,0,n_len) where id = n.id;
			END IF;
		END LOOP;
END;