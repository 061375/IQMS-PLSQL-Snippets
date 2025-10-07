/** 
 * @title v_aq_bom_schedule
 * @about 
 * @author Jeremy Heminger
 * @date october 3, 2025
 * @last_update october 7, 2025
 * 
 * @dependencies
 * v_aq_finite_sched
 * v_aq_bom_lookup
 * 
 * @version 1.0.0.0
 *
 * @live false
 * */
create or replace view v_aq_bom_schedule as
	select 
		distinct 
		* 
			from (
			select 
				(case when y.test is null or staging_location is null then 'STAGING MISSING' else 'STAGING OK'  end) as "COMPONENT STAGING STATUS",
				y."STAGING_LOCATION",
				y."QUANTITY STATUS",
				y."REQUIRED",
				y."LOC_ONHAND",
				y."PTSPER",
				y."CYCLES_REQ",
				y."CYCLES_PLANNED",
				y."CNTR_SEQ",
				y."WORKORDER",
				y."MFGNO",
				y."ITEMNO",
				y."ITEM_ONHAND",
				y."DESCRIP",
				y."DESCRIP2",
				y."NON_MATERIAL",
				y."REV",
				y."UNIT",
				y."OPNO",
				y."OPDESC",
				y."SCEHDULE_STAGING_LOCATION",
				y."BUILDING",
				y."PARENT_ARINVT_ID"
				from (
					select 
	                    x.test,
				        (select distinct loc_desc from locations where id in( x.locations_id,x.locations_id_in ) and rownum = 1) as staging_location,
					    (case when nvl(required,0) > nvl(loc_onhand,0) OR (nvl(required,0) + nvl(loc_onhand,0) = 0) then 'LOW QUANTITY' else 'QUANTITY OK' end) as "QUANTITY STATUS",
					    x.required,
					    nvl(x.loc_onhand,0) as loc_onhand,
					    x.cntr_seq,
					    x.id as workorder,
					    x.mfgno,
					    x.itemno,
					    x.onhand item_onhand,
					    x.cycles_req,
					    x.cycles_planned,
					    x.ptsper,
					    x.descrip,
					    x.descrip2,
					    x.non_material,
					    x.rev,
					    x.unit,
					    x.opno,
					    x.opdesc,
					    x.scehdule_staging_location,
					    x.building,
					    x.parent_arinvt_id
				    from (
					    select distinct
					        (decode( a.hard_alloc_round_precision, null ,nvl(w.cycles_req,0), round(nvl(w.cycles_req,0), a.hard_alloc_round_precision) ) * nvl(o.ptsper,0)) as required,
					        (SELECT
					              SUM(nvl(ff.onhand,0))
					          FROM fgmulti ff
					          JOIN locations ll ON ll.id = ff.loc_id
					          WHERE 
					          -- ll.loc_desc LIKE '%STAGING%' 
					          	ff.arinvt_id = a.id 
					          	and ll.id = f.locations_id_in
					          )  AS loc_onhand,
	                        (SELECT
					              SUM(case when ff.id is null then 0 else 1 end)
					          FROM fgmulti ff
					          JOIN locations ll ON ll.id = ff.loc_id
					          WHERE 
					          -- ll.loc_desc LIKE '%STAGING%' 
					          	ff.arinvt_id = a.id 
					          	and ll.id = f.locations_id_in
					          )  AS test,
					        
					        f.cntr_seq,
					        w.id,w.cycles_req,w.cycles_planned,s.mfgno,a.itemno,o.ptsper,
					        a.descrip,
					        a.descrip2,
					        a.non_material,
					        a.rev,
					        a.unit,
					        a.onhand,snd.opno,snd.opdesc,
					        f.eqno as scehdule_staging_location,
					    	f.mfg_type as building
				            ,v.parent_arinvt_id,
				            f.locations_id_in,
				            f.locations_id
					    from 
					        workorder w,v_aq_bom_lookup v,arinvt a,standard s,opmat o,
					        v_aq_finite_sched f,sndop snd
					    where
					        f.workorder = w.id
					        and w.standard_id = v.standard_id
					        and v.arinvt_id = a.id
					        and v.standard_id = s.id
					        and v.arinvt_id = o.arinvt_id
					        and v.sndop_id = o.sndop_id
					        and v.sndop_id = snd.id(+)
					        and f.workorder is not null
				) x
			) y
		) z
	where staging_location is not null
	order by workorder,mfgno,itemno
;
