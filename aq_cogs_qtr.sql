create or replace function aq_cogs_qtr(v_year varchar2) return SYS_REFCURSOR 
is 
 	l_cursor SYS_REFCURSOR;
begin
	open l_cursor for
		select 
			'1' as qtr,
		    sum(invoiced_sold) as invoiced_sold,
		    sum(invoiced_cogs) as invoiced_cogs,
		    round(sum(invoiced_cogs)/sum(invoiced_sold)*100,6) as cogs
		from (
		    select
		        sum(nvl(c.invoiced_qty,0) * nvl(c.unit_price,0)) as invoiced_sold,
		        sum((nvl(c.invoiced_qty,0) * nvl(c.uom_factor,0)) * nvl(c.std_cost,0)) as invoiced_cogs
		    from c_ship_hist c, arinvt a where
		        c.SHIPMENT_TYPE<>'CUM SHIP ADJUSTMENT'
		        and c.arinvt_id = a.id
		        and c.shipdate between '01-Jan-' || v_year and '30-Mar-' || v_year
		) 
		union
		select 
			'2' as qtr,
		    sum(invoiced_sold) as invoiced_sold,
		    sum(invoiced_cogs) as invoiced_cogs,
		    round(sum(invoiced_cogs)/sum(invoiced_sold)*100,6) as cogs
		from (
		    select
		        sum(nvl(c.invoiced_qty,0) * nvl(c.unit_price,0)) as invoiced_sold,
		        sum((nvl(c.invoiced_qty,0) * nvl(c.uom_factor,0)) * nvl(c.std_cost,0)) as invoiced_cogs
		    from c_ship_hist c, arinvt a where
		        c.SHIPMENT_TYPE<>'CUM SHIP ADJUSTMENT'
		        and c.arinvt_id = a.id
		        and c.shipdate between '01-Apr-' || v_year and '30-Jun-' || v_year
		)
		union
		select 
			'3' as qtr,
		    sum(invoiced_sold) as invoiced_sold,
		    sum(invoiced_cogs) as invoiced_cogs,
		    round(sum(invoiced_cogs)/sum(invoiced_sold)*100,6) as cogs
		from (
		    select
		        sum(nvl(c.invoiced_qty,0) * nvl(c.unit_price,0)) as invoiced_sold,
		        sum((nvl(c.invoiced_qty,0) * nvl(c.uom_factor,0)) * nvl(c.std_cost,0)) as invoiced_cogs
		    from c_ship_hist c, arinvt a where
		        c.SHIPMENT_TYPE<>'CUM SHIP ADJUSTMENT'
		        and c.arinvt_id = a.id
		        and c.shipdate between '01-Jul-' || v_year and '30-Sep-' || v_year
		)
		union
		select 
			'4' as qtr,
		    sum(invoiced_sold) as invoiced_sold,
		    sum(invoiced_cogs) as invoiced_cogs,
		    round(sum(invoiced_cogs)/sum(invoiced_sold)*100,6) as cogs
		from (
		    select
		        sum(nvl(c.invoiced_qty,0) * nvl(c.unit_price,0)) as invoiced_sold,
		        sum((nvl(c.invoiced_qty,0) * nvl(c.uom_factor,0)) * nvl(c.std_cost,0)) as invoiced_cogs
		    from c_ship_hist c, arinvt a where
		        c.SHIPMENT_TYPE<>'CUM SHIP ADJUSTMENT'
		        and c.arinvt_id = a.id
		        and c.shipdate between '01-Oct-' || v_year and '31-Dec-' || v_year
		);
	return l_cursor;
end aq_cogs_qtr;