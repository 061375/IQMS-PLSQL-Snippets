create global temporary table aq_temp_trigger_data (
    id number,
    new_value varchar2(35)
) on commit delete rows;


create or replace trigger aq_tr_add_supplier_before
before insert or update on edi_partners_ship_to
for each row
declare
    v_supplier_code varchar2(30);
    v_count number;
begin
    begin
        select count(*) into v_count from (
            select distinct
                s.supplier_code
            from 
                edi_partners ep,ship_to s,arcusto a,orders o
            where 
                ep.arcusto_id = a.id 
                and o.arcusto_id = a.id
                and o.ship_to_id = s.id
                and s.supplier_code is not null
                and ep.id = :new.edi_partners_id
        );
    end;
    begin 
        if v_count = 1 then -- EDI customers will typically only have 1 supplier code discard others
            select distinct
                s.supplier_code into v_supplier_code
            from 
                edi_partners ep,ship_to s,arcusto a,orders o
            where 
                ep.arcusto_id = a.id 
                and o.arcusto_id = a.id
                and o.ship_to_id = s.id
                and s.supplier_code is not null
                and ep.id = :new.edi_partners_id;
        end if;
    end;
    if v_supplier_code is not null then
        insert into aq_temp_trigger_data (id, new_value) values (:new.ship_to_id,v_supplier_code);
    end if;
exception
    when no_data_found then
        null; -- no action, as there's no matching supplier_code
    when others then
        -- error handling code here
        raise;
end;

create or replace trigger aq_tr_add_supplier_after
after insert or update on edi_partners_ship_to
declare
    cursor c_temp is select * from aq_temp_trigger_data;
    rec_temp c_temp%rowtype;
begin
    open c_temp;
    loop
        fetch c_temp into rec_temp;
        exit when c_temp%notfound;
        -- perform update or other operations using rec_temp values
        update ship_to set supplier_code = rec_temp.new_value where id = rec_temp.id;
    end loop;
    close c_temp;
end;