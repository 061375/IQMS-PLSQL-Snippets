/** 
 * @title v_aq_bom_lookup
 * @about parent child standard_id and arinvt_id and partno_id
 * @author Jeremy Heminger
 * @date october 1, 2025
 * @last_update october 7, 2025
 * 
 * @version 1.0.0.1
 *
 * @live false
 * */
create or replace view v_aq_bom_lookup as
	select 
    	distinct 
            s.id as standard_id,a.id as arinvt_id,bd.partno_id,sd.id as sndop_id,p.arinvt_id as parent_arinvt_id
	from 
	    standard s,
	    partno p,
	    bom_depend bd,
	    sndop sd,
	    opmat op,
	    arinvt a 
	where p.standard_id = s.id 
	    and p.id = bd.partno_id 
	    and bd.sndop_id = sd.id 
	    and sd.id = op.sndop_id
	    and op.arinvt_id = a.id
