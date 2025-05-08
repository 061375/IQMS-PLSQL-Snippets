/* * 
 * 
 * BASIC USAGE EXAMPLE:
 * 
begin
   iqms.aq_create_backups('arinvt');
end;
 * 
 * */
CREATE OR REPLACE PROCEDURE aq_create_backups(p_table_name VARCHAR2, p_where varchar2 default null)
AS
    v_table_name     VARCHAR2(128);
    v_bk_table_name  VARCHAR2(128);
    v_count          NUMBER;
    v_sql_insert     varchar2(1000);
BEGIN
    -- Convert table names to uppercase and validate
    v_table_name := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(p_table_name));
    v_bk_table_name := v_table_name || '_BK';

    -- Check if the source table exists
    SELECT COUNT(*)
    INTO   v_count
    FROM   all_tables
    WHERE  owner = USER
    AND    table_name = v_table_name;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Table "' || v_table_name || '" does not exist.');
    END IF;

    -- Check if the backup table exists and drop it if it does
    SELECT COUNT(*)
    INTO   v_count
    FROM   all_tables
    WHERE  owner = USER
    AND    table_name = v_bk_table_name;

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE ' || v_bk_table_name;
    END IF;

    -- Create backup table
    EXECUTE IMMEDIATE 'CREATE TABLE ' || v_bk_table_name || ' AS SELECT * FROM ' || v_table_name || ' WHERE 1=0';

    BEGIN
	    IF p_where IS NOT NULL THEN
	        v_sql_insert := 'INSERT INTO ' || v_bk_table_name || ' SELECT * FROM ' || v_table_name || ' WHERE ' || p_where;
	    ELSE
	        v_sql_insert := 'INSERT INTO ' || v_bk_table_name || ' SELECT * FROM ' || v_table_name;
	    END IF;

	    EXECUTE IMMEDIATE v_sql_insert;
	END;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Backup table "' || v_bk_table_name || '" created successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
        RAISE;
END;
/
