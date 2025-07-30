/** 
 * @title aq_trigger_addnegwo_loc.sql
 * @about When a user moves the center schedule position this adds a zero location for the work order
 * @author Jeremy Heminger
 * @last_update May 17, 2022
 * 
 * @version 1.0.0.6
 *  @bugfix use cntr_seq column on cntr_sched table in order to avoid conflict with update schedule feature
 * @version 1.0.0.5
 *  @bugfix date comparison method was incorrect
 * @version 1.0.0.4
 *  @bugfix handle daily Update Schedule conflict
 * @version 1.0.0.3
 *  @feature filter by building 1
 * @version 1.0.0.2
 *  @bugfix make sure the first select is only using FG
 * @version 1.0.0.1
 *  @feature allow multiple batches 
 * @version 1.0.0.0
 *
 * @live true
 * */
create or replace trigger "IQMS".aq_trigger_addnegwo_loc
before update of cntr_seq on cntr_sched
for each row
declare
	v_count number := 0;
    v_log number := 1;
begin
-- only work on the first job ont the list
    if :new.cntr_seq = '1' then
            for s in (
                select distinct 
                    wc.eqno,            -- work center
                    l.loc_desc,         -- dispo location
                    l.id as loc_id,     -- loc_id
                    s.mfgno,            -- mfg #
                    w.id as lotno,      -- lotno
                    a.id as arinvt_id,  -- arinvt_id
                    l.division_id       -- division_id
                from
                    work_center wc,
                    workorder w,
                    standard s,
                    locations l,
                    arinvt a
                where 
                    wc.id = :new.work_center_id
                and w.id = :new.workorder_id
                and wc.locations_id_in = l.id
                and w.standard_id = s.id
                and a.itemno = s.mfgno
                and a.class = 'FG'
                and l.division_id = 12
            ) loop 
                -- check if this already exists
                begin 
                    v_count := 0;
                    select count(*) into v_count 
                    from fgmulti 
                    where division_id = s.division_id 
                    and loc_id = s.loc_id 
                    and arinvt_id = s.arinvt_id
                    and lotno = s.lotno; 
                end;
                -- if false then insert
                if v_count < 1 then
                    begin 
                        insert into fgmulti 
                            (arinvt_id,loc_id,lotno,onhand,act_cost,in_date,division_id) 
                        values 
                            (s.arinvt_id,s.loc_id,s.lotno,'0','0',sysdate,s.division_id);
                    end;
                    -- log
                    if v_log = 1 then
                        begin
                            insert into aq_nautilus_log (event,userid,notes,date_created,gid)
                            values 
                            ('CH_CENTER_SCH','IQMS','{"arinvt_id":"' || s.arinvt_id || '","loc_id":"' || s.loc_id || '","lotno":"' || s.lotno || '"}',sysdate,'0');
                        end;
                    end if;
                end if;
            end loop;
    end if;	
end;
