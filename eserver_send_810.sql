-- wrap this so I can limit the number of rows
select * from (
    select 
        distinct
            a.id
    from 
        arinvoice a,
        arinvoice_detail ad,
        c_ship_hist c,
        ord_detail_seg o 
    where 
        a.id = ad.arinvoice_id
        and ad.shipment_dtl_id = c.shipment_dtl_id
        and a.invoice_no <> 'ONACCT' 

        -- only run on invoices with qty that have not had an EDI file sent previously
        and a.invoicetotal > 0                                
        and nvl(a.edi_created, 'N') <> 'Y'

        -- make sure this is an EDI customer and that this is an 810
        and a.arcusto_id IN (
            SELECT arcusto_id
                FROM 
                    edi_partners ep,
                    edi_partners_ts ept
                WHERE 
                    ept.edi_partners_id = ep.id
                AND ept.in_out_bound = 'OUTBOUND'
                AND ept.transaction_set_code = '810'

                -- make sure this only runs in the evening
                AND (
                    CASE
                      WHEN TO_CHAR(SYSDATE, 'HH24:MI:SS') >= '19:00:00' THEN 'Y'
                      WHEN TO_CHAR(SYSDATE, 'HH24:MI:SS') < '04:00:00' THEN 'Y'
                      ELSE 'N'
                    END = 'Y'
        )

        -- ensures that the order arrived via 850 
        -- this is critical if a customer was NOT EDI for a time and then has EDI added as it can cause the eServer to get stuck
        and c.ord_detail_id = o.ord_detail_id                          
    )     
) -- limit the number of runs as this is resource intensive
where rownum < 500