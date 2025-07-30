/** 
 * @title aq_trigger_bi_ps_ticket
 * @about Automatically add a note when new pick ticket is added for specified customer(s)
 * @author Jeremy Heminger
 * @date May 7, 2025
 * @last_update July 11, 2025
 * 
 * @version 2.0.0.1
 *   remove line breaks and discard duplicates and add hyphen in between entries
 * @version 2.0.0.0
 *  Allow users to set the NOTE for line item and customer as an option
 * @version 1.0.0.1
 *  get the note from aq_generic_settings so that is can be edited in Nautilus
 * @version 1.0.0.0
 *
 * @live true
 * */
create or replace TRIGGER iqms.aq_trigger_bi_ps_ticket
BEFORE INSERT ON ps_ticket_dtl
FOR EACH ROW
DECLARE
  v_note    ps_ticket.note%TYPE;
  v_exnote  VARCHAR2(4000);
  v_custno  arcusto.custno%TYPE;
  v_clean   VARCHAR2(4000);
  v_out     VARCHAR2(4000);
BEGIN
  BEGIN
    SELECT p.note,
           a.custno
      INTO v_note,
           v_custno
      FROM ps_ticket p
      JOIN arcusto a
        ON p.arcusto_id = a.id
     WHERE p.id = :NEW.ps_ticket_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_note   := NULL;
      v_custno := NULL;
  END;
  BEGIN
    SELECT 
      TRIM(
        LTRIM(
          RTRIM( 
            REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE(
                  REPLACE(
                    REPLACE(
                          UTL_RAW.CAST_TO_VARCHAR2(
                            DBMS_LOB.SUBSTR(b.doc_blob, 4000, 1)
                          ),
                          '{',''
                        ),
                        '}',''
                      ),
                      '\\pard?[[:space:]]*', ''
                    ),
                    '\\\w+|\{.*?\}|}', ''
                  ),
                  '(Segoe UI;|;;)', ''
                )
        , ' |')  -- trim trailing space or pipe
      , '| '))    -- trim leading space or pipe
      INTO v_exnote
      FROM arinvt_docs ad
      JOIN iq_docs      b
        ON b.id = ad.iq_docs_id
     WHERE ad.arinvt_id = :NEW.arinvt_id
       AND b.descrip    LIKE 'PT NOTE%'
       AND b.descrip    LIKE '%' || v_custno || '%'
     ORDER BY ad.docseq
     FETCH FIRST 1 ROWS ONLY;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END;
  IF v_exnote IS NULL THEN
    BEGIN
      SELECT TRIM(LTRIM(
        RTRIM( REGEXP_REPLACE(
                    REGEXP_REPLACE(
                      REGEXP_REPLACE(
                        REPLACE(
                          REPLACE(
                            UTL_RAW.CAST_TO_VARCHAR2(
                              DBMS_LOB.SUBSTR(b.doc_blob, 4000, 1)
                            ),
                            '{',''
                          ),
                          '}',''
                        ),
                        '\\pard?[[:space:]]*', ''
                      ),
                      '\\\w+|\{.*?\}|}', ''
                    ),
                    '(Segoe UI;|;;)', ''
                  )
            , ' |')  -- trim trailing space or pipe
      , '| '))    -- trim leading space or pipe
        INTO v_exnote
        FROM arinvt_docs ad
        JOIN iq_docs      b
          ON b.id = ad.iq_docs_id
       WHERE ad.arinvt_id = :NEW.arinvt_id
         AND b.descrip    LIKE 'PT NOTE%'
       ORDER BY ad.docseq
       FETCH FIRST 1 ROWS ONLY;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  END IF;
  IF v_exnote IS NOT NULL THEN
    -- collapse any runs of whitespace into one space, trim ends
    v_exnote := REGEXP_REPLACE(v_exnote, '[\r\n\t]+', ' ');
    v_exnote := REGEXP_REPLACE(v_exnote, '[^[:print:]]+', '');
    v_clean := REGEXP_REPLACE( TRIM(v_exnote), '\s+', ' ' );

    -- if this is the first entry then leave it alone 
    if v_note IS NULL then
      v_out := v_clean;
    else 
      -- otherwise concat with -
      v_out := NVL(v_note,'') || ' - ' || v_clean;
    end if;

    -- only append if it isn't already in the parent note
    -- IF INSTR(NVL(v_note,''), v_clean) = 0 THEN
      UPDATE ps_ticket
         SET note = v_out
       WHERE id   = :NEW.ps_ticket_id;
    -- END IF;
  END IF;
END;
