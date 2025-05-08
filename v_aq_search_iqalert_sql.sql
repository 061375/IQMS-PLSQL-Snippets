create or replace view v_aq_search_iqalert_sql as
	select * from (
		select 
			distinct 
				nvl(g.descrip,'NONE') as group_name,
				a.description,
				d.e_subject as email_subject,
				a.sched_type,
				a.days_of_week,
				a.time_of_day,
				d.type as alert_type,
				d.e_to as email_to,
				s.text as detail_sql,
				ss.text as sql
		from 
			mon_run r, mon_act a, mon_act_detail d,
			mon_act_detail_sql s,mon_act_sql ss, mon_group g
		where 
			a.id = r.mon_act_id
			and a.id = d.act_mon_id
			and d.id = s.mon_act_detail_id
			and a.id = ss.mon_act_id(+)
            and r.mon_group_id = g.id(+)
	)