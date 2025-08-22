CREATE OR REPLACE FUNCTION iqms.bomrevparents_by_itemno (
    v_itemno IN varchar2
) RETURN SYS_REFCURSOR
AS
    rc SYS_REFCURSOR;
BEGIN
    OPEN rc FOR
        WITH parent_links (
            child_arinvt_id, child_itemno, child_rev, child_class,
            child_descrip, parent_mfgno, lvl
        ) AS (
            -- base: direct parents of the changed component
            SELECT
                a.id,
                a.itemno,
                a.rev,
                a.class,
                a.descrip,
                bom.mfgno,
                1
            FROM standard bom
            JOIN partno     p  ON p.standard_id = bom.id
            JOIN bom_depend b  ON b.partno_id   = p.id
            JOIN opmat      o  ON o.sndop_id    = b.sndop_id
            JOIN arinvt     a  ON a.id          = b.opmat_arinvt_id
            WHERE a.itemno = v_itemno
              AND NVL(bom.pk_hide,'N') = 'N'

            UNION ALL

            -- recursive: treat each parent as a child to find its parents
            SELECT
                a2.id,
                a2.itemno,
                a2.rev,
                a2.class,
                a2.descrip,
                bom2.mfgno,
                pl.lvl + 1
            FROM parent_links pl,
                 standard bom2,
                 partno   p2,
                 bom_depend b2,
                 opmat    o2,
                 arinvt   a2
            WHERE p2.standard_id = bom2.id
              AND b2.partno_id   = p2.id
              AND o2.sndop_id    = b2.sndop_id
              AND a2.id          = b2.opmat_arinvt_id
              AND a2.itemno      = pl.parent_mfgno
              AND NVL(bom2.pk_hide,'N') = 'N'
        )
        SELECT DISTINCT
            child_arinvt_id AS arinvt_id,
            child_itemno    AS itemno,
            child_rev       AS rev,
            child_class     AS class,
            parent_mfgno    AS mfgno,
            child_descrip   AS descrip,
            SYSDATE         AS time_stamp
        FROM parent_links
        WHERE parent_mfgno IS NOT NULL;

    RETURN rc;
END bomrevparents_by_itemno;
/
