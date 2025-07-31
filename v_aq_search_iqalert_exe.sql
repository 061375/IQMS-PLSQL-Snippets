/** 
 * @title v_aq_search_iqalert_exe
 * @about quickly search IQALERT tables for EXE tasks
 * @author Jeremy Heminger
 * @date January 12, 2024
 * @last_update July 31, 2025
 * 
 * @version 1.0.0.0
 *
 * @live true
 * */
create or replace view v_aq_search_iqalert_exe as
    select 
        distinct 
            nvl(g.descrip,'NONE') as group_name,
            a.description,
            a.sched_type,
            a.days_of_week,
            a.time_of_day,
            d.type as alert_type,
            d.repdef_app_id,
            d.exp_exe_name
        from 
            mon_run r, mon_act a, mon_act_detail d, mon_group g
        where a.id = r.mon_act_id
        and a.id = d.act_mon_id
        and r.mon_group_id = g.id(+)
        and d.type = 'RUN EXE';
