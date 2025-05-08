
/** 
 * @title v_aq_itempoavg_remzeros
 * @about get the avg cost from the receiving purchase orders group by itemno
 * @author Jeremy Heminger
 * @date January 24, 2023
 * @last_update January 25, 2023
 * 
 * @version 1.0.0.3
 * 	@bugfix complete overhaul
 * @version 1.0.0.2
 * 	@feature avg using the sum(unit_price / amount)
 * @version 1.0.0.1
 * 	@bugfix sum y.avg_price
 * @version 1.0.0.0
 * @live true
 * */
create or replace view v_aq_itempoavg_remzeros as
select
	arinvt_id, 
	itemno,
	class,
    std_cost,
    qty_received,
    total_cost,
    avg_cost,
    pct_diff
from (
	select 
            q.arinvt_id,
            q.itemno,
            q.class,
	        q.std_cost,
	        q.qty_received,
	        q.unit_price as total_cost,
	        q.avg_cost,
	        (
				case 
					when std_cost= '0' then 100
					when avg_cost = '0' then 100
		            when std_cost = '0' and avg_cost = '0' then 0
				else
					round(100 * (avg_cost / std_cost), 6)
				end
			) as pct_diff
	from (
		select 
			w.arinvt_id,
			w.itemno,
			w.class,
	        w.std_cost,
	        w.qty_received,
	        w.unit_price,
	        round((unit_price / qty_received), 6) as avg_cost
		from (
		    select 
		    	z.arinvt_id,
		        z.itemno,
		        z.class,
		        z.std_cost,
		        z.qty_received,
		        z.unit_price
		    from (
		        select
		        	y.arinvt_id,
		            y.itemno,
		            y.class,
		            y.std_cost,
		            sum(y.e_qty_received) as qty_received,
		            sum(y.e_unit_price * e_qty_received) as unit_price
		        from (
		            select 
		            	x.arinvt_id,
		                x.itemno,
		                x.class,
		                x.std_cost,
		                x.unit_price,
		                x.total_qty_ord,
		                x.qty_received,
		                x.pr_unit_price,
		                (case when nvl(x.qty_received,0) = 0 then nvl(x.total_qty_ord,0) else x.qty_received end) as e_qty_received,
		                (case when nvl(x.pr_unit_price,0) = 0 then nvl(x.unit_price,0) else x.pr_unit_price end) as e_unit_price
		            from (
		                    select distinct
		                    	a.id as arinvt_id,
		                        a.itemno,
		                        nvl(a.std_cost,0) as std_cost,
		                        pd.unit_price,
		                        pd.total_qty_ord,
		                        pr.qty_received,
		                        pr.unit_price as pr_unit_price,
		                        a.class
		                    from 
		                        po p, 
		                        po_detail pd,
		                        po_receipts pr, 
		                        V_PO_NET_RECEIVED v,
		                        po_releases pre,
		                        arinvt a
		                    where
		                        p.id = pd.po_id
		                        and pd.arinvt_id = a.id
		                        and pd.id = pre.po_detail_id
		                        and pd.id = pr.po_detail_id(+)
		                        and pr.id = v.po_receipts_id(+)
		                    union
		                    select distinct
		                    	a.id as arinvt_id,
		                        a.itemno,
		                        nvl(a.std_cost,0) as std_cost,
		                        pd.unit_price,
		                        pd.total_qty_ord,
		                        pr.qty_received,
		                        pr.unit_price as pr_unit_price,
		                        a.class
		                    from 
		                        po_hist p, 
		                        po_detail_hist pd,
		                        po_receipts pr, 
		                        V_PO_NET_RECEIVED v,
		                        po_releases pre,
		                        arinvt a
		                    where
		                        p.id = pd.po_id
		                        and pd.arinvt_id = a.id
		                        and pd.id = pre.po_detail_id
		                        and pd.id = pr.po_detail_id(+)
		                        and pr.id = v.po_receipts_id(+)
		            ) x where x.std_cost > 0
		        ) y 
		        group by
		        	y.arinvt_id,
		            y.itemno,
		            y.class,
		            y.std_cost
		    ) z
		    group by
		    	z.arinvt_id,
		        z.itemno,
		        z.class,
		        z.std_cost,
		        z.qty_received,
		        z.unit_price
		) w
		group by 
			w.arinvt_id,
			w.itemno,
			w.class,
	        w.std_cost,
	        w.qty_received,
	        w.unit_price
	) q
) 
--where itemno = '802310'
order by pct_diff desc
;
