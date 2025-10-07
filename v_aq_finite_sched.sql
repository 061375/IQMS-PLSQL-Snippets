/** 
 * @title v_aq_finite_sched
 * @about 
 * @author Jeremy Heminger
 * @date March 5, 2025
 * @last_update October 7, 2025
 * 
 * @version 1.0.0.2
 *  Added: vl(w.is_xcpt_mat,'N') as exception,
          wc.locations_id,
          wc.locations_id_in
 * @version 1.0.0.1
 *  prod_start_time,prod_end_time,prodhrs,down_idle,setuphrs,force_source
 * @version 1.0.0.0

 * @live true
 * */
create or replace view v_aq_finite_sched as
	select 
        c.cntr_seq,
        w.id as workorder,
        nvl(s.mfgno,'DOWN TIME') as mfgno,
        s.descrip,
        w.bucket,
        w.cycles_req as cycles_to_go,
        w.prodhrs as hours_to_go,
        to_char(w.start_time,'DD-MON-YY HH:MI AM') as start_time,
        to_char(w.end_time,'DD-MON-YY HH:MI AM') as end_time,
        c.priority_note,
        to_char(w.calc_start_time,'DD-MON-YY HH:MI AM') as must_start_time,
        c.force_reason as down_time_reason,
        ceil(sysdate - w.calc_start_time) as days_late,
        (case when w.firm = 'Y' then 'FIRM' else '' end) as wo_type,
        w.origin,
        'TO DO: LABOR' as labor,
        'TO DO: PRIORITY' as priority,
        'TO DO: AUTO REMOVE' as auto_remove,
        'TO DO: PRIORITY LEVEL' as priority_level,
        c.priority_note2,
        'TO DO: QUALITY ISSUES' as quality_issues,
        'TO DO: GROUP ID' as group_id,
        c.userid,
        wc.eqno,
        wc.mfg_type,
        to_char(c.prod_start_time,'DD-MON-YY HH:MI AM') as prod_start_time,
        to_char(c.prod_end_time,'DD-MON-YY HH:MI AM') as prod_end_time,
        c.prodhrs,
        c.down_idle,
        c.setuphrs,
        c.force_source,
        nvl(w.is_xcpt_mat,'N') as exception,
        wc.locations_id,
        wc.locations_id_in
    from 
        cntr_sched c, work_center wc, workorder w, standard s
    where 
        c.work_center_id = wc.id 
        and c.workorder_id = w.id(+)
        and w.standard_id = s.id(+)
