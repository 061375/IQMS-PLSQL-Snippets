create or replace view v_aq_getedi_pricediff as
    SELECT 
        distinct 
            ef.parse_date_time,
            ef.parse_date_time as "DATE",
            eod.pono as "PURCHASE ORDER",
            (select orderno from orders where id = eod.orders_id) as "SALES ORDER NUMBER",
            a.itemno AS "ITEM NUMBER",
            eod.aka_ptno as "CUSTOMER NUMBER",
            eod.pt_descrip as "DESCRIPTION",
            ar.company,
            ar.custno,
            nvl(eod.unit_price,0) as "EDI PRICE",
            nvl(ab.qprice,0) as "AKA PRICE",
            nvl(a.std_price,0) as "STD PRICE"
        FROM 
                edi_file ef,
                edi_isa_header eih, 
                edi_ts_hdr eth, 
                edi_ord_detail eod,
                arinvt a,
                aka,
                aka_breaks ab,
                arcusto ar
        WHERE 
            eih.edi_file_id = ef.id(+)
            AND eth.edi_isa_header_id = eih.id
            AND eod.edi_ts_hdr_id = eth.id
            and eod.arinvt_id = a.id 
            and eih.arcusto_id = aka.arcusto_id
            and a.id = aka.arinvt_id
            and aka.id = ab.aka_id(+)
            and (nvl(eod.unit_price,0) != nvl(ab.qprice,0) and nvl(eod.unit_price,0) != nvl(a.std_price,0))
            and nvl(a.std_price,0) != 0
            and aka.arcusto_id = ar.id