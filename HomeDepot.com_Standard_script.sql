--============================================================================--
-------------------------------- HomeDepot.Com ---------------------------------
--============================================================================--
declare
  v_PC number := 0;          v_release_version varchar2(10):= 'v1.00.12'; 
  v_amount_left number;       v_arid number;
  v_eplantid number;          v_invtotal number;
  v_total number;             v_interchange_code varchar2(30);


  v_FOB     varchar2(80);         v_st_id_code     varchar2(20);
  v_arn     number;               v_scac           freight.scac_iata_code%type;
  v_pono    varchar2(30);         v_per_id         number; 
  v_ptid    number;               v_freight_id     number;
  v_id      number;               v_ship_to_id     number;
  v_bgn_id  number;               v_oid_id         number;
  v_n1ca_id number;               v_l11_id         number;
  v_tp_flag varchar2(1);          v_n1_st          number;
  v_n1      number;               v_id_code        edi_partners_ship_to.id_code%type;
  v_n2      number;               v_count_n4       number;
  v_n3      number;               v_count_n3       number;
  v_n4      number;               v_country_id     number;
  v_Attn    ship_to.attn%type;    v_subdivision_id number;
  v_Attn2   ship_to.attn%type;    v_eplant_id      number;
  v_Addr1   ship_to.addr1%type;   v_ep_ship_to_Id  number;
  v_Addr2   ship_to.addr2%type;   v_country        ship_to.country%type; 
  v_Addr3   ship_to.addr3%type;   v_City           ship_to.city%type;      
  v_State   ship_to.state%type;   v_zip            ship_to.zip%type;
  v_ep_id   number;               v_in_filedate    date;               
  v_EOL_ID  number;               v_Error          varchar2(200);
  v_epid    number;               v_carrier_id     number;
  v_descrip varchar2(50);         v_phone          varchar2(30);
  v_n1_SO   number;               v_shipped        varchar2(30);
  v_picked  varchar2(30);         v_conversion     number;
  v_ep_bill_to_id number;
  v_bill_to_id number;
  v_calc_shipdate date;
  
    -- Commerce Hub told us they would be sending Lowes.com as UNSP "Unspecified" but never said they would end that for HD.com
    -- But we received UNSP ...at least a year later ( that was noticed ).
    -- I'll just copy the Lowes.com fix over here
    -- version v1.00.11
  v_default_scac varchar2(4) := 'UPSN';
  v_reject_scac  varchar2(35) := 'UNSP%';
  v_scac_id number;
  v_default_scac_descrip varchar2(60) := 'UPS Ground';
begin
  v_PC:=v_PC+1;
  insert into edi_Errors (EDI_FIle_Id,EDI_Error, Error_Type, Parse_Convert)
    Values (:ID,lpad(v_PC,3,'0') ||' - Begin HomeDepot.Com '||v_release_version, 'I', 'P');
  commit;

--------------------------------------------------------------------------------
-- HomeDepot.Com - Check_Script_Setup
-- Check if script has been installed correctly.
--------------------------------------------------------------------------------
  v_pc := v_pc+1;
  insert into edi_Errors (EDI_FIle_Id,EDI_Error, Error_Type, Parse_Convert)
  values (:ID,lpad(v_pc,3,'0') ||' - HomeDepot.Com - Check_Script_Setup ', 'I', 'P');
  commit;
  
  for v in (
    select eih.id as eihid,
           decode(instr(nvl(iqsys.edi_sql_script_file, 'N'), v_release_version), 0, 0, 1) is_on_ap,
           decode(instr(upper(nvl(iqsys.edi_sql_script_file, 'N')), 'STANDARD_SCRIPT'), 0, 0, 1) is_on_ap2,
           decode(instr(nvl(iqsys2.edi_sql_after_conv, 'N'), v_release_version), 0, 0, 1) is_on_ac,
           decode(instr(upper(nvl(iqsys2.edi_sql_after_conv, 'N')), 'STANDARD_SCRIPT'), 0, 0, 1) is_on_ac2,
           decode(instr(nvl(epts.unc_custom_sql_file, substr(nvl(epts.custom_sql_clob, 'N'), 1, 1000)), v_release_version), 0, 0, 1) is_on_ts
    from edi_isa_header eih,
         edi_partners_ts epts,
         iqsys,
         iqsys2
    where eih.edi_file_id = :ID
      and eih.edi_partners_id = epts.edi_partners_id
      and epts.transaction_set_unique_id is not null
      and instr(upper(epts.transaction_set_unique_id), 'GENERIC') = 0
      and upper(trim(epts.in_out_bound)) = 'INBOUND'
      )
  loop
    if ((v.is_on_ap = 1) or (v.is_on_ap2 = 1) or (v.is_on_ac2 = 1) or (v.is_on_ac2 = 1)) then
      insert into edi_errors (EDI_File_ID, Error_Type, EDI_Error)
      values (:ID, 'F', 'ERROR - STANDARD SCRIPT INCORRECTLY ASSIGNED AS AFTER-PARSE SCRIPT. VERIFY SETUP AGAINST EDI BUSINESS PROCESS MANUAL OR CONTACT EDI FOR ASSISTANCE.');
      delete from edi_isa_header
      where id = v.eihid;
    end if;
    if (v.is_on_ts = 0) then
      insert into edi_errors (EDI_File_ID, Error_Type, EDI_Error)
      values (:ID, 'F', 'ERROR - MISMATCH OR MISSING CUSTOM SQL SCRIPT IN TRADING PARTNER SETUP. VERIFY SETUP AGAINST EDI BUSINESS PROCESS MANUAL OR CONTACT EDI FOR ASSISTANCE.');
      delete from edi_isa_header
      where id = v.eihid;
    end if;
  end loop;
  
--------------------------------------------------------------------------------
-- HomeDepot.Com - Pull_Interchange_Code
-- Pull interchange code from ISA Header.
--------------------------------------------------------------------------------
  v_pc := v_pc+1;
  insert into edi_Errors (EDI_FIle_Id,EDI_Error, Error_Type, Parse_Convert)
  values (:ID,lpad(v_pc,3,'0') ||' - HomeDepot.Com - Pull_Interchange_Code ', 'I', 'P');
  commit;

  begin
    select max(trim(interchange_code)) into v_interchange_code
    from edi_isa_header
    where edi_file_id = :ID;
    exception when others then null;
  end;

--------------------------------------------------------------------------------
-- HomeDepot.Com - Combine_Orders_850
--------------------------------------------------------------------------------
  v_PC:=v_PC+1;
  insert into edi_Errors (EDI_FIle_Id,EDI_Error, Error_Type, Parse_Convert)
    Values (:ID,lpad(v_PC,3,'0')||' - HomeDepot.Com - Combine_Orders_850', 'I', 'P');
  commit;

  edi_in.Combine_Orders_850(:ID, v_interchange_code);


--------------------------------------------------------------------------------
-- HomeDepot.com - Create_Ship_To (v16)
-- Check for ship to and create one if it does not exist
-- Requires inventory item match for EPlant
--------------------------------------------------------------------------------
  v_PC:=v_PC+1;
  insert into edi_Errors (EDI_FIle_Id,EDI_Error, Error_Type, Parse_Convert)
    Values (:ID,lpad(v_PC,3,'0') ||' - HomeDepot.com - Create_Ship_To', 'I', 'P');
  commit;

  for s in
    (select eod.id as eodid, eih.arcusto_id as arcustoid, 
            trim(EIH.interchange_code) as icode,
            eod.arinvt_id as arinvt_id
       from edi_ord_detail eod, edi_ts_hdr eth, edi_isa_header eih
       where eod.edi_ts_hdr_id = eth.id
         and eth.edi_isa_header_id = eih.id
         and eth.transaction_set_id in ('850')
         and trim(eih.interchange_code) = v_interchange_code
         --and nvl(eod.st_id_code, 'N') = 'N'
         and nvl(eod.arinvt_id, 0) <> 0
         and eih.edi_file_id = :ID)
  loop
    v_n1 := 0;         v_count_n3 := 0;   v_ep_ship_to_Id := 0;
    v_count_n4 := 0;   v_n2 := 0;         v_n3 := 0;
    v_n4 := 0;         v_Attn := null;    v_subdivision_id := 0;
    v_Addr1 := null;   v_Addr2 := null;   v_ep_id := 0;
    v_Addr3 := null;   v_City := null;    v_phone := '';
    v_State := null;   v_zip := null;     v_scac := null;
    v_country := null; v_country_id := 0; v_freight_id :='';
    v_eplant_id := 0;  v_ship_to_Id := 0;
    v_scac := null;    v_scac_id := null; -- @version 1.00.10
    begin
      begin
        select id into v_n1 
          from edi_ord_seg eos 
          where eos.edi_ord_detail_id = s.eodid 
            and eos.seg = 'N1'
            and EDI_IN.Get_Recorded_Release_Element(EOS.ID, 1, 'N') = 'ST';
        exception when others then v_n1 := null;
      end;
     -- If BT and ST are the same we only record 1 N3 and N4
     -- Verify if this is the case
      begin
        select count(id) into v_count_n3 
          from edi_ord_seg where edi_ord_detail_id = s.eodid and seg = 'N3';
        select count(id) into v_count_n4 
          from edi_ord_seg where edi_ord_detail_id = s.eodid and seg = 'N4';
        exception when others then null;
      end;
      -- @version 1.00.11
      begin
        select min(id) into v_scac_id from edi_ord_seg 
          where edi_ord_detail_id = s.eodid 
            and seg = 'TD5';
        exception when others then v_scac_id := null;
      end;
      begin
        select min(id) into v_n2 from edi_ord_seg 
          where edi_ord_detail_id = s.eodid 
            and seg = 'N2'
            and id > v_n1;
        exception when others then v_n2 := null;
      end;

      if nvl(v_count_n3,0) = 1 then
        begin
          select min(id) into v_n3 from edi_ord_seg
            where edi_ord_detail_id = s.eodid
            and seg = 'N3';
          exception when others then v_n3 := null;
        end;
      else
        begin
          select min(id) into v_n3 from edi_ord_seg 
            where edi_ord_detail_id = s.eodid 
               and seg = 'N3'
               and id > v_n1;
          exception when others then v_n3 := null;
        end;
      end if;
      
      if nvl(v_count_n4,0) = 1 then     
        begin
          select min(id) into v_n4 from edi_ord_seg 
            where edi_ord_detail_id = s.eodid 
              and seg = 'N4';
          exception when others then v_n4 := null;
        end;
      else
        begin
          select min(id) into v_n4 from edi_ord_seg 
            where edi_ord_detail_id = s.eodid 
              and seg = 'N4'
              and id > v_n1;
          exception when others then v_n4 := null;
        end;
      end if;
    end;
     
    --Now Get the recorded elements
    begin
      -- @version 1.00.11
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_scac_id, 5, 'N')) into v_scac from dual;
        exception when others then v_scac := v_default_scac;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n1, 2, 'N')) into v_Attn from dual;
        exception when others then v_Attn := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n2, 1, 'N')) into v_Attn2 from dual;
        exception when others then v_Addr1 := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n3, 1, 'N')) into v_Addr1 from dual;
        exception when others then v_Addr1 := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n3, 2, 'N')) into v_Addr2 from dual;
        exception when others then v_Addr2 := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n2, 2, 'N')) into v_Addr3 from dual;
        exception when others then v_Addr1 := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n4, 1, 'N')) into v_City from dual;
        exception when others then v_City := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n4, 2, 'N')) into v_State from dual;
        exception when others then v_State := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n4, 3, 'N')) into v_zip from dual;
        exception when others then v_zip := null;
      end;
    end;
    begin
      select max(regexp_replace(trim(EDI_IN.Get_Recorded_Release_Element(id, 0, 'TE')),'[^0-9]')) into v_phone
        from edi_ord_seg
        where seg = 'PER'
          and edi_ord_detail_id = s.eodid;
      exception when others then null;
    end;

    -- @version 1.00.11
    begin
      if v_scac LIKE v_reject_scac then 
        v_scac := v_default_scac;
      end if; 
    end;
    begin
    
        --select id into v_freight_id from freight where trim(scac_iata_code) = 'UPSN';
        --select id into v_freight_id from freight where trim(descrip) = 'UPS Ground';

        -- @version 1.00.11 
        --select id into v_freight_id from freight where trim(scac_iata_code) = v_scac;
        -- add the descrip with the SCAC as all UPS SCACs are UPSN and the TD5 for HD4 does not contain the service code
        -- so we will only ship GROUND
        select id into v_freight_id from freight where trim(descrip) = v_default_scac_descrip and trim(scac_iata_code) = v_scac;
        exception 
          when NO_DATA_FOUND then    
            insert into edi_Errors (EDI_FIle_Id,Edi_Ord_Detail_Id, EDI_Error, Error_Type, Parse_Convert)
              Values (:ID, s.EODID, 'No Freight match with SCAC code: '||v_scac||' v_scac_id: '||v_scac_id||' v_default_scac_descrip:'||v_default_scac_descrip, 'E', 'P');   
            commit;
          when TOO_MANY_ROWS then
            insert into edi_Errors (EDI_FIle_Id,Edi_Ord_Detail_Id, EDI_Error, Error_Type, Parse_Convert)
              Values (:ID, s.EODID, 'No Freight match with SCAC code: '||v_scac||' v_scac_id: '||v_scac_id||' v_default_scac_descrip:'||v_default_scac_descrip, 'E', 'P');    
            commit;
      end;

    begin
      select nvl(trim(EDI_IN.Get_Recorded_Release_Element(v_n4, 4, 'N')), 'US') into v_country from dual;
      exception when others then null;
    end;
    begin
      select s.id, c.id into v_subdivision_id, v_country_id
        from locale_country c, locale_subdivision s
        where c.id = s.locale_country_id
          and nvl(c.default_spelling,'N') = 'Y'
          and (trim(upper(c.name)) = trim(upper(v_country))
               or trim(upper(c.chr2)) = trim(upper(v_country))
               or trim(upper(c.chr3)) = trim(upper(v_country)))
          and trim(upper(s.name)) = trim(upper(v_state));
      exception when others then
        begin
          select s.id, c.id into v_subdivision_id, v_country_id
            from locale_country c, locale_subdivision s
            where c.id = s.locale_country_id
              and nvl(c.default_spelling,'N') = 'Y'
              and trim(upper(s.name)) = trim(upper(v_state));
          exception when others then
            insert into edi_Errors (EDI_FIle_Id,EDI_Error, Error_Type, Parse_Convert,edi_ord_detail_id)
              Values (:ID,'Unable to Locate Country/State: '||
                      trim(v_country)||'/'||trim(v_state), 'E', 'P', s.eodid);
        end;
    end;
   
   -- See if the Ship To address is already setup
     begin
       select id into v_ship_to_id
         from ship_to
         where arcusto_id = s.arcustoid
           and trim(upper(nvl(attn,'N')))= trim(upper(nvl(v_attn,'N')))
           and trim(upper(nvl(addr1,'N')))= trim(upper(nvl(v_addr1,'N')))
           and trim(upper(nvl(addr2,'N')))= trim(upper(nvl(v_addr2,'N')))
           and trim(upper(nvl(addr3,'N')))= trim(upper(nvl(v_addr3,'N')))
           and trim(upper(nvl(city,'N')))= trim(upper(nvl(v_city,'N')))
           and nvl(state_id,'0') = nvl(v_subdivision_id,'0')
           and trim(upper(nvl(zip,'N')))= trim(upper(nvl(v_zip,'N')));
       exception
         when too_many_rows then
           insert into edi_Errors (EDI_FIle_Id, EDI_Error, Error_Type, Parse_Convert, Edi_Ord_Detail_ID)
             Values (:ID,'Duplicate Ship To found '||v_attn||', '|| v_addr1 ||', '||v_addr2 ||', '|| v_city, 'E', 'P', s.EODID);
           v_ship_to_id := -1;
         when no_data_found then v_ship_to_id := 0;
         when others then v_ship_to_id := -1;
     end;

    -- If not setup yet create new Ship To record on TPPM Default Customer
     if nvl(v_ship_to_id, 0) = 0 then
       select s_ship_to.nextval into v_ship_to_Id from dual;
       select S_EDI_PARTNERS_SHIP_TO.nextval into v_ep_ship_to_Id from dual;
     -- Get the EDI Partner ID
       begin 
         select ep.id into v_ep_id 
           from edi_partners ep
           where trim(ep.tp_interchange_code) = trim(s.Icode)
             and  ep.arcusto_id = s.arcustoid;
         exception when others then null;
       end;
      
     -- Insert the Ship To address on the customer 
       insert into ship_to (id, arcusto_id, attn, addr1, addr2, city, zip, 
                            eplant_id, country_id, state_id, phone_number, fob, fob_third_party_id, freight_id)
         values (v_ship_to_id, s.arcustoid, v_attn, v_addr1, v_addr2, v_city, v_zip,
                 v_eplant_id, v_country_id, v_subdivision_id, v_phone, 'THIRD PARTY', 5, v_freight_id);

     -- Insert carrier accounts on ship to
       for shipman in --account numbers setup per company & carrier in Sys Param -> Lists -> BOL -> Third Party Billing -> Edit drop down -> Account Numbers
         (select distinct fcl.carrier_id, a.account_number
            from fob_third_party ftp, fob_third_party_account a, freight_carrier fc, freight_carrier_link fcl
            where instr(upper(ftp.attn),'Home Depot USA')>'0'
              and a.fob_third_party_id = ftp.id
              and fc.type = a.carrier_type
              and fcl.carrier_id = fc.id)
       loop
         begin
           insert into ship_to_carrier_account(ship_to_id, carrier_id, account_number)
             values(v_ship_to_id, shipman.carrier_id, shipman.account_number);
           exception when others then
             insert into edi_Errors (EDI_FIle_Id,Edi_Ord_Detail_Id, EDI_Error, Error_Type, Parse_Convert)
               Values (:ID, s.EODID, 'Error assigning Carrier Account for Hoem Depot Standard ', 'W', 'P');
         end;
       end loop;
       commit;

     -- Insert the  Ship To address on the EDI Partner
       insert into edi_partners_ship_to (id, edi_partners_id, ship_to_id)
         values (v_ep_ship_to_Id, v_ep_id, v_ship_to_Id);

     -- Update the EDI Order Details entry
       update edi_ord_detail 
         set ship_to_id = v_ship_to_id
         where id = s.eodid;
   
    elsif v_ship_to_id > 0 then --verify match is setup on TPPM
        -- @version 1.00.11
        begin 
            update ship_to set freight_id = v_freight_id where id = v_ship_to_id;
        end;
      begin
        select nvl(epst.id_code, 'NONE') into v_id_code 
          from edi_partners_ship_to epst, edi_partners ep
          where epst.edi_partners_id = ep.id
            and trim(ep.tp_interchange_code) = s.icode
            and ep.arcusto_id = s.arcustoid
            and epst.ship_to_id = v_ship_to_id;
        exception
          when no_data_found then v_id_code := 'NONE';
          when others then null;
      end;
      if trim(v_id_code) = 'NONE' then
        select S_EDI_PARTNERS_SHIP_TO.nextval into v_ep_ship_to_Id from dual;
        begin 
          select ep.id into v_ep_id 
            from edi_partners ep
            where trim(ep.tp_interchange_code) = trim(s.Icode)
              and  ep.arcusto_id = s.arcustoid;
          exception when others then null;
        end;
        insert into edi_partners_ship_to (id, edi_partners_id, ship_to_id)
          values (v_ep_ship_to_Id, v_ep_id, v_ship_to_Id);

        update edi_ord_detail 
          set ship_to_id = v_ship_to_id
          where id = s.eodid;
      else
        update edi_ord_detail
          set ship_to_id = v_ship_to_id
          where id = s.eodid;
      end if;           

    elsif nvl(v_ship_to_id, 0) = -1 then
      insert into edi_errors(edi_file_id, edi_ord_detail_id, error_type, parse_convert, edi_error)
        values (:ID, s.eodid, 'E', 'P', 'Unable to assign Ship To for ATTN: ' || v_attn ||
                ', ISA CODE: ' || s.icode || '. PLEASE CHECK ERROR LOG, CORRECT AND REPARSE.');
       
      update edi_ord_detail
        set ship_to_id = 0
        where id = s.eodid;
    end if;
  end loop;
commit;

-- version 1.00.09 -> Jeremy
--------------------------------------------------------------------------------
-- Populate_DTM038_to_ShipDate
--------------------------------------------------------------------------------
  v_pc:=v_pc+1;
  insert into edi_errors (edi_file_id, edi_error, error_type, parse_convert)
  values (:ID,lpad(v_PC,3,'0') ||' -Populate_DTM038_to_ShipDate', 'I', 'P');
  commit;

  for v in (select eod.id as eodid, edi_in.get_recorded_release_element(eos.id, 2, '038') as udate, es.id as esid
              from edi_ord_detail eod,
                   edi_isa_header eih,
                   edi_ts_hdr eth, 
                   edi_ord_seg eos,
                   edi_ship es
             where eod.edi_ts_hdr_id = eth.id
               and eos.edi_ord_detail_id = eod.id
               and eth.transaction_set_id = ('850')
               and eth.edi_isa_header_id = eih.id
               and es.edi_ord_detail_id = eod.id
               and trim(eih.interchange_code) = v_interchange_code
               and eos.seg = 'DTM'
               and substr(eos.seg_string, 5, 3) = '038'
               and eih.edi_file_id = :ID)
  loop
  -- version 1.00.10 -> Jeremy
  -- version 1.00.12 -> Jeremy
  -- only update ship date if it is greater than today ... I can't believe I have to add this
    v_calc_shipdate := to_date(v.udate, 'YYYYMMDD') - interval '3' day;
    if sysdate < v_calc_shipdate then
      update edi_ship
      set user_date = to_date(v.udate, 'YYYYMMDD') + interval '4' day,
          promise_date = to_date(v.udate, 'YYYYMMDD') + interval '4' day,
          deldate = to_date(v.udate, 'YYYYMMDD') + interval '4' day
      where id = v.esid;
    end if;
  end loop;
  commit;

--------------------------------------------------------------------------------
-- HomeDepot.com - Create_Bill_To (v16)
-- Check for bill to and create one if it does not exist
-- Requires inventory item match for EPlant
--------------------------------------------------------------------------------
/*  v_PC:=v_PC+1;
  insert into edi_Errors (EDI_FIle_Id,EDI_Error, Error_Type, Parse_Convert)
    Values (:ID,lpad(v_PC,3,'0') ||' - HomeDepot.com - Create_Bill_To', 'I', 'P');
  commit;

  for s in (
    select eod.id as eodid, eih.arcusto_id as arcustoid, 
            trim(EIH.interchange_code) as icode,
            eod.arinvt_id as arinvt_id,
            eod.ship_to_id as st_id
    from edi_ord_detail eod, 
         edi_ts_hdr eth, 
         edi_isa_header eih,
         edi_ord_seg eos
    where eod.edi_ts_hdr_id = eth.id
      and eth.edi_isa_header_id = eih.id
      and eos.edi_ord_detail_id = eod.id
      and eth.transaction_set_id in ('850')
      and trim(eih.interchange_code) = v_interchange_code
      and nvl(eod.arinvt_id, 0) <> 0
      and trim(eos.seg) = ('N1')
      and trim(edi_in.Get_Recorded_Release_Element(eos.id, 1)) = 'BT'
      and trim(edi_in.Get_Recorded_Release_Element(eos.id, 4)) is null
      and eih.edi_file_id = :ID)
  loop
    v_n1 := 0;         v_count_n3 := 0;   v_ep_ship_to_Id := 0;
    v_count_n4 := 0;   v_n2 := 0;         v_n3 := 0;
    v_n4 := 0;         v_Attn := null;    v_subdivision_id := 0;
    v_Addr1 := null;   v_Addr2 := null;   v_ep_id := 0;
    v_Addr3 := null;   v_City := null;    v_phone := '';
    v_State := null;   v_zip := null;     v_scac := null;
    v_country := null; v_country_id := 0; v_freight_id :='';
    v_eplant_id := 0;  v_ship_to_Id := 0;

    begin
      begin
        select id into v_n1 
          from edi_ord_seg eos 
          where eos.edi_ord_detail_id = s.eodid 
            and eos.seg = 'N1'
            and EDI_IN.Get_Recorded_Release_Element(EOS.ID, 1, 'N') = 'BT';
        exception when others then v_n1 := null;
      end;
     -- If BT and ST are the same we only record 1 N3 and N4
     -- Verify if this is the case
      begin
        select count(id) into v_count_n3 
          from edi_ord_seg where edi_ord_detail_id = s.eodid and seg = 'N3';
        select count(id) into v_count_n4 
          from edi_ord_seg where edi_ord_detail_id = s.eodid and seg = 'N4';
        exception when others then null;
      end;
      
      begin
        select min(id) into v_n2 from edi_ord_seg 
          where edi_ord_detail_id = s.eodid 
            and seg = 'N2'
            and id > v_n1;
        exception when others then v_n2 := null;
      end;

      if nvl(v_count_n3,0) = 1 then
        begin
          select min(id) into v_n3 from edi_ord_seg
            where edi_ord_detail_id = s.eodid
            and seg = 'N3';
          exception when others then v_n3 := null;
        end;
      else
        begin
          select min(id) into v_n3 from edi_ord_seg 
            where edi_ord_detail_id = s.eodid 
               and seg = 'N3'
               and id > v_n1;
          exception when others then v_n3 := null;
        end;
      end if;
      
      if nvl(v_count_n4,0) = 1 then     
        begin
          select min(id) into v_n4 from edi_ord_seg 
            where edi_ord_detail_id = s.eodid 
              and seg = 'N4';
          exception when others then v_n4 := null;
        end;
      else
        begin
          select min(id) into v_n4 from edi_ord_seg 
            where edi_ord_detail_id = s.eodid 
              and seg = 'N4'
              and id > v_n1;
          exception when others then v_n4 := null;
        end;
      end if;
    end;
     
    --Now Get the recorded elements
    begin
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n1, 2, 'N')) into v_Attn from dual;
        exception when others then v_Attn := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n2, 1, 'N')) into v_Attn2 from dual;
        exception when others then v_Addr1 := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n3, 1, 'N')) into v_Addr1 from dual;
        exception when others then v_Addr1 := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n3, 2, 'N')) into v_Addr2 from dual;
        exception when others then v_Addr2 := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n2, 2, 'N')) into v_Addr3 from dual;
        exception when others then v_Addr1 := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n4, 1, 'N')) into v_City from dual;
        exception when others then v_City := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n4, 2, 'N')) into v_State from dual;
        exception when others then v_State := null;
      end;
      begin
        select trim(EDI_IN.Get_Recorded_Release_Element(v_n4, 3, 'N')) into v_zip from dual;
        exception when others then v_zip := null;
      end;
    end;
    begin
      select max(regexp_replace(trim(EDI_IN.Get_Recorded_Release_Element(id, 0, 'TE')),'[^0-9]')) into v_phone
        from edi_ord_seg
        where seg = 'PER'
          and edi_ord_detail_id = s.eodid;
      exception when others then null;
    end;
    begin
      select nvl(trim(EDI_IN.Get_Recorded_Release_Element(v_n4, 4, 'N')), 'US') into v_country from dual;
      exception when others then null;
    end;
    
    begin
      select s.id, c.id into v_subdivision_id, v_country_id
        from locale_country c, locale_subdivision s
        where c.id = s.locale_country_id
          and nvl(c.default_spelling,'N') = 'Y'
          and (trim(upper(c.name)) = trim(upper(v_country))
               or trim(upper(c.chr2)) = trim(upper(v_country))
               or trim(upper(c.chr3)) = trim(upper(v_country)))
          and trim(upper(s.name)) = trim(upper(v_state));
      exception when others then
        begin
          select s.id, c.id into v_subdivision_id, v_country_id
            from locale_country c, locale_subdivision s
            where c.id = s.locale_country_id
              and nvl(c.default_spelling,'N') = 'Y'
              and trim(upper(s.name)) = trim(upper(v_state));
          exception when others then
            insert into edi_Errors (EDI_FIle_Id,EDI_Error, Error_Type, Parse_Convert,edi_ord_detail_id)
              Values (:ID,'Unable to Locate Country/State: '||
                      trim(v_country)||'/'||trim(v_state), 'E', 'P', s.eodid);
        end;
    end;
   
   -- See if the Bill To address is already setup
     begin
       select id into v_bill_to_id
         from bill_to
         where arcusto_id = s.arcustoid
           and trim(upper(nvl(attn,'N')))= trim(upper(nvl(v_attn,'N')))
           and trim(upper(nvl(addr1,'N')))= trim(upper(nvl(v_addr1,'N')))
           and trim(upper(nvl(addr2,'N')))= trim(upper(nvl(v_addr2,'N')))
           and trim(upper(nvl(addr3,'N')))= trim(upper(nvl(v_addr3,'N')))
           and trim(upper(nvl(city,'N')))= trim(upper(nvl(v_city,'N')))
           and nvl(state_id,'0') = nvl(v_subdivision_id,'0')
           and trim(upper(nvl(zip,'N')))= trim(upper(nvl(v_zip,'N')));
       exception
         when too_many_rows then
           insert into edi_Errors (EDI_FIle_Id, EDI_Error, Error_Type, Parse_Convert, Edi_Ord_Detail_ID)
           values (:ID,'Duplicate Ship To found '||v_attn||', '|| v_addr1 ||', '||v_addr2 ||', '|| v_city, 'E', 'P', s.EODID);
           v_bill_to_id := -1;
         when no_data_found then v_bill_to_id := 0;
         when others then v_bill_to_id := -1;
     end;

    -- If not setup yet create new Bill To record on TPPM Default Customer
     if nvl(v_bill_to_id, 0) = 0 then
       select s_bill_to.nextval into v_bill_to_id from dual;
       select S_EDI_PARTNERS_bill_TO.nextval into v_ep_bill_to_Id from dual;
     -- Get the EDI Partner ID
       begin 
         select ep.id into v_ep_id 
           from edi_partners ep
           where trim(ep.tp_interchange_code) = trim(s.Icode)
             and  ep.arcusto_id = s.arcustoid;
         exception when others then null;
       end;
      
     -- Insert the Bill To address on the customer 
       insert into bill_to (id, arcusto_id, attn, addr1, addr2, city, zip, 
                            country_id, state_id, phone_number)
         values (v_bill_to_id, s.arcustoid, v_attn, v_addr1, v_addr2, v_city, v_zip,
                 v_country_id, v_subdivision_id, v_phone);

     -- Insert new Bill To as default on Ship To record            
       update ship_to
       set bill_to_id = v_bill_to_id
       where id = s.st_id
         and bill_to_id is null;
       
     -- Insert the Bill To address on the EDI Partner
       insert into edi_partners_bill_to (id, edi_partners_id, bill_to_id)
         values (v_ep_bill_to_Id, v_ep_id, v_bill_to_id);

     -- Update the EDI Order Details entry
       update edi_ord_detail 
         set bill_to_id = v_bill_to_id
         where id = s.eodid;
   
    elsif v_bill_to_id > 0 then --verify match is setup on TPPM
      begin
        select nvl(epbt.id_code, 'NONE') into v_id_code 
          from edi_partners_bill_to epbt, edi_partners ep
          where epbt.edi_partners_id = ep.id
            and trim(ep.tp_interchange_code) = s.icode
            and ep.arcusto_id = s.arcustoid
            and epbt.bill_to_id = v_bill_to_id;
        exception
          when no_data_found then v_id_code := 'NONE';
          when others then null;
      end;
      if trim(v_id_code) = 'NONE' then
        select S_EDI_PARTNERS_BILL_TO.nextval into v_ep_bill_to_Id from dual;
        begin 
          select ep.id into v_ep_id 
            from edi_partners ep
            where trim(ep.tp_interchange_code) = trim(s.Icode)
              and  ep.arcusto_id = s.arcustoid;
          exception when others then null;
        end;
        insert into edi_partners_bill_to (id, edi_partners_id, bill_to_id)
          values (v_ep_bill_to_Id, v_ep_id, v_bill_to_id);

        update edi_ord_detail 
          set bill_to_id = v_bill_to_id
          where id = s.eodid;
      else
        update edi_ord_detail
          set bill_to_id = v_bill_to_id
          where id = s.eodid;
      end if;           

    elsif nvl(v_bill_to_id, 0) = -1 then
      insert into edi_errors(edi_file_id, edi_ord_detail_id, error_type, parse_convert, edi_error)
        values (:ID, s.eodid, 'E', 'P', 'Unable to assign Bill To for ATTN: ' || v_attn ||
                ', ISA CODE: ' || s.icode || '. PLEASE CHECK ERROR LOG, CORRECT AND REPARSE.');
       
      update edi_ord_detail
        set bill_to_id = 0
        where id = s.eodid;
    end if;
  end loop;
commit;

  edi_in.match_orders(:ID, v_interchange_code, '850');
*/
--------------------------------------------------------------------------------
-- Hoem Depot.com - Validate_Price
--------------------------------------------------------------------------------
-- Validate_Price
/*
v_PC:=v_PC+1;
  insert into edi_Errors (EDI_FIle_Id,EDI_Error, Error_Type, Parse_Convert)
  Values (:ID,lpad(v_PC,3,'0')||' - Home Depot.com - Validate_Price', 'I', 'P');
  commit;
  
  edi_in.validate_price(:ID, v_interchange_code,'850, 860',4);
*/  
--------------------------------------------------------------------------------
-- HomeDepot.Com - Match_Invoice
--------------------------------------------------------------------------------
  v_pc:=v_pc+1;
  insert into edi_errors(edi_file_id, edi_error, error_type, parse_convert)
    values (:ID, lpad(v_PC,3,'0')||' - HomeDepot.Com - Match_Invoice', 'I', 'P');
  commit;
    
  for v in
    (select eod.id as eodid, eos.id as eosid, cd.id as cdid,
            edi_in.get_recorded_release_element(eos.id, 2, 'N') as ref
       from edi_ord_seg eos, edi_ord_detail eod, edi_ts_hdr eth, 
            edi_isa_header eih, crprepost_detail cd
       where eos.edi_ord_detail_id = eod.id
         and eod.edi_ts_hdr_id = eth.id
         and eth.edi_isa_header_id = eih.id
         and eod.crprepost_detail_id = cd.id
         and eth.transaction_set_id in ('820')
         and eos.seg = 'RMR'
         and eih.edi_file_id = :ID)
  loop
    v_arid:= 0;
    v_eplantid:= null;
  
    begin --match by invoice number
      select distinct ar.id, ar.eplant_id into v_arid, v_eplantid
        from arinvoice ar
        where trim(ar.invoice_no) = trim(v.ref);
      exception when others then null;
    end;

    if nvl(v_arid,0) = 0 then
      begin --match by pick ticket id
        select distinct ar.id, ar.eplant_id into v_arid, v_eplantid
          from arinvoice ar, arinvoice_detail ard, shipments s, shipment_dtl sd
          where ard.arinvoice_id = ar.id
            and ard.shipment_dtl_id = sd.id
            and sd.shipments_id = s.id
            and to_char(ps_ticket_id) = trim(v.ref);
        exception when others then null;
      end;
    end if;
    
    if nvl(v_arid,0) = 0 then
      begin --match by bol number
        select distinct ar.id, ar.eplant_id into v_arid, v_eplantid
          from arinvoice ar, arinvoice_detail ard, c_ship_hist c, bol
          where ard.arinvoice_id = ar.id
            and ard.shipment_dtl_id = c.shipment_dtl_id
            and c.bol_id = bol.id
            and bol.bolno = trim(v.ref);
        exception when others then null;
      end;
    end if;

    if nvl(v_arid,0) = 0 then
      begin --match by packing slip number
        select distinct ar.id, ar.eplant_id into v_arid, v_eplantid
          from arinvoice ar, arinvoice_detail ard, shipments s, shipment_dtl sd
          where ard.arinvoice_id = ar.id
            and ard.shipment_dtl_id = sd.id
            and sd.shipments_id = s.id
            and trim(s.packslipno) = trim(v.ref);
        exception when others then null;
      end;
    end if;
    
    if nvl(v_arid,0) = 0 then
      insert into edi_errors (edi_file_id, edi_error, error_type, edi_ord_detail_id)
        values (:ID,'HomeDepot.Com - 820 Cash Rec - Unable to match invoice using reference value: '||trim(v.ref), 'E', v.eodid);
    end if;
    
    begin
      update crprepost_detail 
        set arinvoice_id = v_arid, eplant_id = v_eplantid
        where id = v.cdid;
      exception when others then null;
    end;

    begin
      update edi_ord_detail
        set pono = nvl((select invoice_no from arinvoice where id = v_arid),'NO Invoice MATCH'),
            st_eplant_id = v_eplantid
        where id = v.eodid;
      exception when others then null;
    end;
  end loop;

--------------------------------------------------------------------------------
-- HomeDepot.Com - Evaluate_820_Totals
--------------------------------------------------------------------------------
  v_pc:=v_pc+1;
  insert into edi_errors(edi_file_id, edi_error, error_type, parse_convert)
    values (:ID, lpad(v_PC,3,'0')||' - HomeDepot.Com - Evaluate_820_Totals', 'I', 'P');
  commit;
    
  for v in
    (select eod.id as eodid, cd.id as cdid, eod.st_eplant_id as eplantid, 
            cd.arinvoice_id as arid, ar.invoice_no as invno, eod.fab_qty as chkamt
       from edi_ord_detail eod, edi_ts_hdr eth, edi_isa_header eih, 
            crprepost_detail cd, arinvoice ar
       where eod.edi_ts_hdr_id = eth.id
         and eth.edi_isa_header_id = eih.id
         and eod.crprepost_detail_id = cd.id
         and cd.arinvoice_id = ar.id(+)
         and eth.transaction_set_id in ('820')
         and eih.edi_file_id = :ID)
  loop
    v_amount_left:= 0; v_total:= 0; v_invtotal:= 0;
  
    if nvl(v.arid,0) <> 0 then
      begin -- get the amount left to be paid
        select nvl(vadt.total,0)- nvl(vcdt.amount_applied,0), a.invoicetotal
          into v_amount_left, v_invtotal
          from arinvoice a, v_cashrec_dtl_total vcdt, v_arinvoice_detail_total vadt
          where a.id = vadt.arinvoice_id 
            and vcdt.arinvoice_id (+) = vadt.arinvoice_id
            and a.id = v.arid
            and trim(a.eplant_id) = nvl(v.eplantid,0);
        exception when others then v_amount_left := -1;
      end;
      
      begin -- lets see how much the invoice is for
        select total into v_total
          from v_arinvoice_detail_total
          where arinvoice_id = v.arid;
        exception when others then null;
      end;
         
      if v_amount_left = -1 then 
        v_amount_left := v_total;
      end if;
       
      if nvl(v_amount_left,0) = 0 then
        begin
          update crprepost_detail
            set comment1 = 'Invoice '||v.invno||' Paid in FULL'
            where id = v.cdid;
          exception when others then null;
        end;
      else
        if nvl(v.chkamt,0) < 0 then
          if nvl(v.invno, 'INVOICE NUMBER NOT FOUND') = 'INVOICE NUMBER NOT FOUND' then
            begin
              update crprepost_detail
                set comment1 = 'Negative Amount for Invoice: '||v.invno
                where id = v.cdid;
              exception when others then null;
            end;
          else
            begin
              update crprepost_detail
                set comment1 = 'Negative Amount for Invoice: '||v.invno
                where id = v.cdid;
              exception when others then null;
            end;
          end if;
        elsif nvl(v.chkamt,0) > 0 and nvl(v_amount_left,-2)= -2 then
          begin
            update crprepost_detail
              set comment1 = 'Invoice Not Found for Reference: '||v.invno
              where id = v.cdid;    
            exception when others then null;
          end;
        elsif nvl(v.chkamt,0) < nvl(v_amount_left,0) then
          begin
            update crprepost_detail
              set comment1 = 'Under payment'
              where id = v.cdid;    
            exception when others then null;
          end;              
        elsif nvl(v.chkamt,0) > nvl(v_amount_left,0)  then
          begin
            update crprepost_detail
              set comment1 = 'Over payment'
              where id = v.cdid;    
            exception when others then null;
          end;            
        end if; -- if nvl(v_invtotal,0) < 0 then
      end if;  -- if nvl(v_amount_left,0) = 0 then

    elsif nvl(v.arid,0) = 0 then -- if nvl(v.arid,0) <> 0 then
      begin
        update crprepost_detail
          set comment1 = 'Invoice not found'
          where id = v.cdid;
        exception when others then null;
      end;
    end if; -- if nvl(v.arid,0) <> 0 then
  end loop;

-----------------------------End HomeDepot.Com------------------------------
  v_PC:=v_PC+1;
  insert into edi_Errors (EDI_FIle_Id,EDI_Error, Error_Type, Parse_Convert)
    Values (:ID,lpad(v_PC,3,'0') ||' - END HomeDepot.Com '||v_release_version, 'I', 'P');
  commit;
end;
