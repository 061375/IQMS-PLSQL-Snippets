
# v_aq_bom_lookup
## Very useful lookup table for the parent child relationship of the BOMs
## Jeremy Heminger <contact@jeremyheminger.com>

                                                ᓚᘏᗢ

## Usage example

    select 
    distinct
        p.workorder_id,
        s.mfgno,
        pr.rel_quan,
        a.itemno as components
    from ptorder p,ptorder_rel pr,v_aq_bom_lookup v,standard s,arinvt a
    where p.id = pr.ptorder_id
    and p.partno_id = v.partno_id
    and v.standard_id = s.id
    and v.arinvt_id = a.id
    and p.workorder_id = :workorder_id;

# Versions

## 📅 October 1, 2025
## ⬆️📅 November 4, 2025

* ## 1.0.0.3
*   🐱 Added: opmat_id
* ## 1.0.0.1
*   🐱 Added: sndop_id and parent_arinvt_id
* ## 1.0.0.0
