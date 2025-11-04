/** 
 * @title v_aq_bom_recurs_6
 * @about dig down six levels into a BOM
 * @author Jeremy Heminger
 * @date October 30, 2025
 * @last_update November 4, 2025 
 * 
 * @version 1.0.0.0
 * @live true
 * */
create or replace view v_aq_bom_recurs_6 as
    SELECT * FROM (
        SELECT DISTINCT
	         (select itemno from arinvt where id = v.parent_arinvt_id) as mfgno,
	         v.standard_id,
	         (select itemno from arinvt where id = v.arinvt_id) as itemno,
	         v.parent_arinvt_id,
	         v.arinvt_id,
	         v.opmat_id,
	         v.partno_id,
	         v.sndop_id,
	         (select itemno from arinvt where id = vv.arinvt_id) as child_level_one_itemno,
             vv.arinvt_id as child_level_one_arinvt_id,
             vv.opmat_id as child_level_one_opmat_id,
	         (select itemno from arinvt where id = vvv.arinvt_id) as child_level_two_itemno,
	         vvv.arinvt_id as child_level_two_arinvt_id,
	         vv.opmat_id as child_level_two_opmat_id,
	         (select itemno from arinvt where id = vvvv.arinvt_id) as child_level_three_itemno,
             vvvv.arinvt_id as child_level_three_arinvt_id,
             vvvv.opmat_id as child_level_three_opmat_id,
	         (select itemno from arinvt where id = vvvvv.arinvt_id) as child_level_four_itemno,
	         vvvvv.arinvt_id as child_level_four_arinvt_id,
	         vvvvv.opmat_id as child_level_four_opmat_id,
	         (select itemno from arinvt where id = vvvvvv.arinvt_id) as child_level_five_itemno,
	         vvvvvv.arinvt_id as child_level_five_arinvt_id,
	         vvvvvv.opmat_id as child_level_five_opmat_id,
	         (select itemno from arinvt where id = vvvvvvv.arinvt_id) as child_level_six_itemno,
	         vvvvvvv.arinvt_id as child_level_six_arinvt_id,
	         vvvvvvv.opmat_id as child_level_six_opmat_id
	FROM 
	    v_aq_bom_lookup v,
	    v_aq_bom_lookup vv,
	    v_aq_bom_lookup vvv,
	    v_aq_bom_lookup vvvv,
	    v_aq_bom_lookup vvvvv,
	    v_aq_bom_lookup vvvvvv,
	    v_aq_bom_lookup vvvvvvv
	where 
	    v.arinvt_id = vv.parent_arinvt_id(+)
	    and vv.arinvt_id = vvv.parent_arinvt_id(+)
	    and vvv.arinvt_id = vvvv.parent_arinvt_id(+)
	    and vvvv.arinvt_id = vvvvv.parent_arinvt_id(+)
	    and vvvvv.arinvt_id = vvvvvv.parent_arinvt_id(+)
	    and vvvvvv.arinvt_id = vvvvvvv.parent_arinvt_id(+)
	) order by 
		parent_arinvt_id,
        child_level_one_arinvt_id,
        child_level_two_arinvt_id,
        child_level_three_arinvt_id,
        child_level_four_arinvt_id,
        child_level_five_arinvt_id,
        child_level_six_arinvt_id
