select * from (
    select 
        itemno,
        class,
        descrip,
        std_cost,
        std_cost_future,
        budgetcost,
        forecastcost,
        cost1000,
        (case when std_cost_future > 0 then (std_cost - std_cost_future) else 0 end) as std_cost_comparison
        from (
        select 
            itemno,
            class,
            descrip,
            nvl(std_cost,0) as std_cost,
            nvl(std_cost_future,0) as std_cost_future,
            nvl(budgetcost,0) as budgetcost,
            nvl(forecastcost,0) as forecastcost,
            nvl(cost1000,0) as cost1000
        from (
            SELECT 
                    itemno,
                    class,
                    descrip,
                    std_cost,
                   (SELECT SUM(std_cost) + inv_misc.get_nonremovable_elements_cost('arinvt_cost_tmp', arinvt.id)
                      FROM arinvt_cost_tmp
                     WHERE arinvt_id = arinvt.id)
                      AS std_cost_future,
                   (SELECT SUM(std_cost) + inv_misc.get_nonremovable_elements_cost('arinvt_elem_budget', arinvt.id)
                      FROM arinvt_elem_budget
                     WHERE arinvt_id = arinvt.id)
                      AS budgetcost,
                   (SELECT SUM(std_cost) + inv_misc.get_nonremovable_elements_cost('arinvt_elem_forecast', arinvt.id)
                      FROM arinvt_elem_forecast
                     WHERE arinvt_id = arinvt.id)
                      AS forecastcost,
                   (arinvt.std_cost * 1000) AS cost1000
             FROM arinvt where nvl(pk_hide,'N') = 'N'
        )
    )
) order by std_cost_comparison desc;
