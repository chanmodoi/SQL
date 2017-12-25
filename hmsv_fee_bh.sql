-- View: hmsv_fee_bh

-- DROP VIEW hmsv_fee_bh;

CREATE OR REPLACE VIEW hmsv_fee_bh AS 
 SELECT tbl1.hfe_patientno,
    tbl1.hfe_docno,
    tbl1.hfe_deptid,
        CASE
            WHEN tbl1.hfe_class::text = 'I'::text THEN tbl1.hfe_refidx
            ELSE 0
        END AS hfe_refidx,
    tbl1.hfe_roomid,
    tbl1.hfe_idx,
    tbl1.hfe_type,
    tbl1.hfe_group,
    tbl1.hfe_invoiceno,
    tbl1.hfe_insinvoice,
    tbl1.hfe_status,
    tbl1.hfe_iaccept,
    tbl1.hfe_entrydate,
    tbl1.hfe_itemid,
        CASE
            WHEN length(tbl1.description::text) > 0 THEN (((fee.hfl_name::text || ' ['::text) || tbl1.description::text) || ']'::text)::character varying
            ELSE fee.hfl_name
        END AS hfe_desc,
    fee.hfl_unit AS hfe_unit,
    tbl1.hfe_qty,
    tbl1.hfe_unitprice,
    tbl1.hfe_insprice,
    tbl1.hfe_cost,
    tbl1.hfe_inspaid,
    tbl1.hfe_difcost,
    tbl1.hfe_discount,
    tbl1.hfe_patdebt,
    tbl1.hfe_patpaid,
    tbl1.hfe_difpaid,
    tbl1.hfe_hitech,
    tbl1.hfe_class,
    tbl1.hfe_request,
    tbl1.hfe_hastranfer,
    tbl1.hfe_pdate,
    tbl1.hfe_doctor,
        CASE
            WHEN tbl1.hfe_type::text = 'E'::text AND tbl1.hfe_typexe > 0 THEN ( SELECT sys_sel.ss_vndesc
               FROM sys_sel
              WHERE sys_sel.ss_id::text = 'hms_examtype'::text AND sys_sel.ss_code::text = tbl1.hfe_typexe::text)
            ELSE fee.hfl_regcode
        END AS hfe_regcode,
    tbl1.hfe_ratio,
    0 AS hfe_unpaidqty
   FROM ( SELECT hms_exam.he_patientno AS hfe_patientno,
            hms_exam.he_docno AS hfe_docno,
            hms_exam.he_deptid AS hfe_deptid,
            0 AS hfe_refidx,
            hms_exam.he_roomid AS hfe_roomid,
            hms_exam.he_receptidx AS hfe_idx,
            'E'::character varying(1) AS hfe_type,
            hms_exam.hfe_group,
            hms_exam.hfe_invoiceno,
            hms_exam.hfe_insinvoice,
            hms_exam.hfe_status,
            hms_exam.hfe_iaccept,
            hms_exam.he_examdate AS hfe_entrydate,
            hms_exam.he_examtype AS hfe_itemid,
            1 AS hfe_qty,
            hms_exam.hfe_unitprice,
            hms_exam.hfe_cost - hms_exam.hfe_difcost AS hfe_insprice,
            hms_exam.hfe_cost,
            hms_exam.hfe_inspaid,
            hms_exam.hfe_difcost,
            hms_exam.hfe_discount,
            hms_exam.hfe_patdebt,
            hms_exam.hfe_patpaid,
            hms_exam.hfe_difpaid,
            'N'::character varying AS hfe_hitech,
            'E'::character varying AS hfe_class,
            hms_exam.hfe_request,
            'N'::character varying(1) AS hfe_hastranfer,
            hms_exam.he_examdate AS hfe_pdate,
            hms_exam.he_doctor AS hfe_doctor,
            hms_exam.he_typeid AS hfe_typexe,
            ''::character varying AS description,
            hms_exam.hfe_ratio
           FROM hms_exam
          WHERE hms_exam.hfe_status::text = ANY (ARRAY['O'::character varying::text, 'P'::character varying::text])
        UNION ALL
         SELECT pcms_order.pcmso_patientno AS hfe_patientno,
            pcms_order.pcmso_docno AS hfe_docno,
            pcms_order.pcmso_deptid AS hfe_deptid,
            pcms_order.pcmso_refidx,
            pcms_order.pcmso_roomid AS hfe_roomid,
            pcms_order.pcmso_orderid AS hfe_idx,
            'P'::character varying(1) AS hfe_type,
            pcms_order_line.hfe_group,
            pcms_order_line.hfe_invoiceno,
            pcms_order_line.hfe_insinvoice,
            pcms_order_line.hfe_status,
            pcms_order_line.hfe_iaccept,
            pcms_order.pcmso_orderdate,
            pcms_order_line.pcmsol_itemid AS hfe_itemid,
            pcms_order_line.pcmsol_qty AS hfe_qty,
            pcms_order_line.hfe_unitprice,
            pcms_order_line.hfe_insprice,
            pcms_order_line.hfe_cost,
            pcms_order_line.hfe_inspaid,
            pcms_order_line.hfe_difcost,
            pcms_order_line.hfe_discount,
            pcms_order_line.hfe_patdebt,
            pcms_order_line.hfe_patpaid,
            pcms_order_line.hfe_difpaid,
            pcms_order_line.hfe_hitech,
            pcms_order.pcmso_depttype,
            pcms_order_line.hfe_request,
            'N'::character varying(1) AS hfe_hastranfer,
            pcms_order.pcmso_performdate AS hfe_pdate,
            pcms_order.pcmso_practitioner AS hfe_doctor,
            0 AS hfe_typexe,
                CASE
                    WHEN substr(pcms_order_line.hfe_group::text, 1, 2) <> 'B1'::text THEN pcms_order_line.pcmsol_note
                    ELSE ''::character varying
                END AS description,
            pcms_order_line.hfe_ratio
           FROM pcms_order
             LEFT JOIN pcms_order_line ON pcms_order.pcmso_orderid = pcms_order_line.pcmsol_orderid
          WHERE pcms_order.pcmso_status::text <> 'O'::text
        UNION ALL
         SELECT hms_operation.ho_patientno AS hfe_patientno,
            hms_operation.ho_docno AS hfe_docno,
            hms_operation.ho_deptid AS hfe_deptid,
            hms_operation.ho_refidx,
            hms_operation.ho_roomid AS hfe_roomid,
            hms_operation.ho_idx AS hfe_idx,
            'O'::character varying(1) AS hfe_type,
            hms_operation.hfe_group,
            hms_operation.hfe_invoiceno,
            hms_operation.hfe_insinvoice,
            hms_operation.hfe_status,
            hms_operation.hfe_iaccept,
            hms_operation.ho_orderdate,
            hms_operation.ho_itemid AS hfe_itemid,
            hms_operation.ho_qty AS hfe_qty,
            hms_operation.hfe_unitprice,
            hms_operation.hfe_insprice,
            hms_operation.hfe_cost,
            hms_operation.hfe_inspaid,
            hms_operation.hfe_difcost,
            hms_operation.hfe_discount,
            hms_operation.hfe_patdebt,
            hms_operation.hfe_patpaid,
            hms_operation.hfe_difpaid,
            hms_operation.hfe_hitech,
            hms_operation.ho_depttype,
            hms_operation.hfe_request,
            hms_feelist.hfl_hastranfer AS hfe_hastranfer,
            hms_operation.ho_performdate AS hfe_pdate,
            hms_operation.ho_doctor,
            0 AS hfe_typexe,
            ''::character varying AS "varchar",
            hms_operation.hfe_ratio
           FROM hms_operation
             LEFT JOIN hms_feelist ON hms_feelist.hfl_feeid::text = hms_operation.ho_itemid::text
          WHERE hms_operation.ho_status::text <> 'O'::text) tbl1
     LEFT JOIN hms_feelist fee ON fee.hfl_feeid::text = tbl1.hfe_itemid::text
  WHERE (tbl1.hfe_status::text = ANY (ARRAY['O'::character varying::text, 'C'::character varying::text, 'P'::character varying::text])) AND tbl1.hfe_insprice > 1::numeric
UNION ALL
 SELECT hms_bed.hb_patientno AS hfe_patientno,
    hms_bed.hb_docno AS hfe_docno,
    hms_bed.hb_deptid AS hfe_deptid,
    hms_bed.hb_refidx AS hfe_refidx,
    hms_bed.hb_roomid AS hfe_roomid,
    hms_bed.hb_idx AS hfe_idx,
    'B'::character varying(1) AS hfe_type,
    hms_bed.hfe_group,
    hms_bed.hfe_invoiceno,
    hms_bed.hfe_insinvoice,
    hms_bed.hfe_status,
    hms_bed.hfe_iaccept,
    hms_bed.hb_admitdate AS hfe_entrydate,
    hms_bed.hb_bedid::character varying(13) AS hfe_itemid,
        CASE
            WHEN length(hms_bedlist.hbl_namefee::text) > 10 THEN hms_bedlist.hbl_namefee
            ELSE hms_bedlist.hbl_name
        END AS hfe_desc,
    'Ngày'::character varying AS hfe_unit,
    hms_bed.hb_treatqty AS hfe_qty,
    hms_bed.hfe_unitprice,
        CASE
            WHEN hms_bed.hb_treatqty > 0::numeric THEN (hms_bed.hfe_cost - hms_bed.hfe_difcost) / hms_bed.hb_treatqty
            ELSE hms_bed.hfe_unitprice
        END AS hfe_insprice,
    hms_bed.hfe_cost,
    hms_bed.hfe_inspaid,
    hms_bed.hfe_difcost,
    hms_bed.hfe_discount,
    hms_bed.hfe_patdebt,
    hms_bed.hfe_patpaid,
    hms_bed.hfe_difpaid,
    'N'::character varying AS hfe_hitech,
    'I'::character varying AS hfe_class,
    hms_bed.hfe_request,
    'N'::character varying(1) AS hfe_hastranfer,
    hms_bed.hb_enddate AS hfe_pdate,
    hms_bed.hb_doctor AS hfe_doctor,
    hms_bedlist.hbl_insuranceid AS hfe_regcode,
    hms_bed.hfe_ratio,
    hms_bed.hfe_unpaidqty
   FROM hms_bed
     LEFT JOIN hms_bedlist ON hms_bedlist.hbl_deptid::text = hms_bed.hb_deptid::text AND hms_bedlist.hbl_roomid = hms_bed.hb_roomid AND hms_bedlist.hbl_id = hms_bed.hb_bedid
  WHERE hms_bed.hb_treatqty > 0::numeric AND (hms_bed.hb_dynprice::text <> 'Y'::text OR hms_bed.hb_dynprice IS NULL) AND (hms_bed.hfe_status::text = ANY (ARRAY['O'::character varying::text, 'C'::character varying::text, 'P'::character varying::text]))
UNION ALL
 SELECT hms_bed_items.hbi_patientno AS hfe_patientno,
    hms_bed_items.hbi_docno AS hfe_docno,
    hms_bed_items.hbi_deptid AS hfe_deptid,
    hms_bed_items.hbi_refidx AS hfe_refidx,
    hms_bed_items.hbi_roomid AS hfe_roomid,
    hms_bed_items.hbi_idx AS hfe_idx,
    'B'::character varying(1) AS hfe_type,
    hms_bed_items.hfe_group,
    hms_bed_items.hfe_invoiceno,
    hms_bed_items.hfe_insinvoice,
    hms_bed_items.hfe_status,
    hms_bed_items.hfe_iaccept,
    hms_bed_items.hbi_date AS hfe_entrydate,
    hms_bed_items.hbi_refidx::character varying(13) AS hfe_itemid,
        CASE
            WHEN length(hms_dynbedlist.hdbl_namefee::text) > 0 THEN hms_dynbedlist.hdbl_namefee::text
            ELSE hms_dynbedlist.hdbl_name::text
        END AS hfe_desc,
    'Ngày'::character varying AS hfe_unit,
    hms_bed_items.hbi_qty AS hfe_qty,
    hms_bed_items.hfe_unitprice,
    hms_bed_items.hfe_insprice,
    hms_bed_items.hfe_cost,
    hms_bed_items.hfe_inspaid,
    hms_bed_items.hfe_difcost,
    hms_bed_items.hfe_discount,
    hms_bed_items.hfe_patdebt,
    hms_bed_items.hfe_patpaid,
    hms_bed_items.hfe_difpaid,
    'N'::character varying AS hfe_hitech,
    'I'::character varying AS hfe_class,
    hms_bed_items.hfe_request,
    'D'::character varying(1) AS hfe_hastranfer,
    hms_bed_items.hbi_date AS hfe_pdate,
    hms_bed.hb_doctor AS hfe_doctor,
    hms_dynbedlist.hdbl_insuranceid AS hfe_regcode,
    hms_bed_items.hfe_ratio,
    hms_bed_items.hfe_unpaidqty
   FROM hms_bed_items
     LEFT JOIN hms_dynbedlist ON hms_dynbedlist.hdbl_deptid::text = hms_bed_items.hbi_deptid::text AND hms_dynbedlist.hdbl_idx = hms_bed_items.hbi_priceid
     LEFT JOIN hms_bed ON hms_bed.hb_docno = hms_bed_items.hbi_docno AND hms_bed.hb_idx = hms_bed_items.hbi_refidx
  WHERE (hms_bed_items.hfe_status::text = ANY (ARRAY['O'::character varying::text, 'C'::character varying::text, 'P'::character varying::text])) AND hms_bed_items.hfe_unitprice > 1::numeric
UNION ALL
 SELECT hms_pharmacyorder.hpo_patientno AS hfe_patientno,
    hms_pharmacyorder.hpo_docno AS hfe_docno,
    hms_pharmacyorder.hpo_deptid AS hfe_deptid,
    hms_pharmacyorder.hpo_refidx AS hfe_refidx,
    hms_pharmacyorder.hpo_roomid AS hfe_roomid,
    hms_pharmacyorder_line.hpol_lnidx AS hfe_idx,
    'D'::character varying(1) AS hfe_type,
    hms_pharmacyorder_line.hfe_group,
    hms_pharmacyorder_line.hfe_invoiceno,
    hms_pharmacyorder_line.hfe_insinvoice,
    hms_pharmacyorder_line.hfe_status,
    hms_pharmacyorder_line.hfe_iaccept,
    hms_pharmacyorder.hpo_orderdate AS hfe_entrydate,
    hms_pharmacyorder_line.hpol_itemid AS hfe_itemid,
    pms_items.pmi_name AS hfe_desc,
    pms_items.pmi_unit AS hfe_unit,
    hms_pharmacyorder_line.hpol_issueqty AS hfe_qty,
    hms_pharmacyorder_line.hfe_unitprice,
    hms_pharmacyorder_line.hfe_insprice,
    hms_pharmacyorder_line.hfe_cost,
    hms_pharmacyorder_line.hfe_inspaid,
    hms_pharmacyorder_line.hfe_difcost,
    hms_pharmacyorder_line.hfe_discount,
    hms_pharmacyorder_line.hfe_patdebt,
    hms_pharmacyorder_line.hfe_patpaid,
    hms_pharmacyorder_line.hfe_difpaid,
    'N'::character varying AS hfe_hitech,
    hms_pharmacyorder.hpo_depttype AS hfe_class,
    hms_pharmacyorder_line.hfe_request,
    'N'::character varying(1) AS hfe_hastranfer,
    hms_pharmacyorder.hpo_orderdate AS hfe_pdate,
        CASE
            WHEN hms_pharmacyorder.hpo_doctor::text <> ''::text AND hms_pharmacyorder.hpo_doctor IS NOT NULL THEN hms_pharmacyorder.hpo_doctor
            WHEN pms_stocktransfer.pmst_senderby::text <> ''::text AND pms_stocktransfer.pmst_senderby IS NOT NULL THEN pms_stocktransfer.pmst_senderby
            ELSE ''::character varying(15)
        END AS hfe_doctor,
    pms_items.pmi_insuranceid AS hfe_regcode,
    1 AS hfe_ratio,
    0 AS hfe_unpaidqty
   FROM hms_pharmacyorder
     LEFT JOIN hms_pharmacyorder_line ON hms_pharmacyorder.hpo_orderid = hms_pharmacyorder_line.hpol_orderid
     LEFT JOIN pms_items ON hms_pharmacyorder_line.hpol_itemid::text = pms_items.pmi_id::text
     LEFT JOIN pms_stocktransfer ON hms_pharmacyorder.hpo_sheetidx::text = pms_stocktransfer.pmst_id::text
  WHERE (hms_pharmacyorder.hpo_status::text <> ALL (ARRAY['O'::text, 'C'::text])) AND hms_pharmacyorder_line.hpol_issueqty > 0::numeric AND hms_pharmacyorder.hpo_type::text <> 'M'::text AND hms_pharmacyorder_line.hpol_payment <> 'S'::bpchar AND (hms_pharmacyorder_line.hfe_status::text = ANY (ARRAY['O'::character varying::text, 'C'::character varying::text, 'P'::character varying::text]))
UNION ALL
 SELECT hms_other_fee.hfe_patientno,
    hms_other_fee.hfe_docno,
    hms_other_fee.hfe_deptid,
    hms_other_fee.hfe_refidx,
    hms_other_fee.hfe_roomid,
    hms_other_fee.hfe_idx,
    hms_other_fee.hfe_type,
    hms_other_fee.hfe_group,
    hms_other_fee.hfe_invoiceno,
    hms_other_fee.hfe_insinvoice,
    hms_other_fee.hfe_status,
    hms_other_fee.hfe_iaccept,
    hms_other_fee.hfe_entrydate,
    hms_other_fee.hfe_itemid,
        CASE
            WHEN length(hms_feelist.hfl_name2::text) > 0 THEN hms_feelist.hfl_name2
            ELSE hms_feelist.hfl_name
        END AS hfe_desc,
    hms_feelist.hfl_unit AS hfe_unit,
    hms_other_fee.hfe_qty,
    hms_other_fee.hfe_unitprice,
    hms_other_fee.hfe_insprice,
    hms_other_fee.hfe_cost,
    hms_other_fee.hfe_inspaid,
    hms_other_fee.hfe_difcost,
    hms_other_fee.hfe_discount,
    hms_other_fee.hfe_patdebt,
    hms_other_fee.hfe_patpaid,
    hms_other_fee.hfe_difpaid,
    'N'::character varying AS hfe_hitech,
    hms_other_fee.hfe_depttype AS hfe_class,
    hms_other_fee.hfe_request,
    hms_feelist.hfl_hastranfer AS hfe_hastranfer,
    hms_other_fee.hfe_entrydate AS hfe_pdate,
    hms_other_fee.hfe_createdby AS hfe_doctor,
    ''::character varying AS hfe_regcode,
    1 AS hfe_ratio,
    0 AS hfe_unpaidqty
   FROM hms_other_fee
     LEFT JOIN hms_feelist ON hms_feelist.hfl_feeid::text = hms_other_fee.hfe_itemid::text AND hms_feelist.hfl_groupid::text = hms_other_fee.hfe_group::text
  WHERE (hms_other_fee.hfe_status::text = ANY (ARRAY['O'::character varying::text, 'C'::character varying::text, 'P'::character varying::text])) AND (hms_other_fee.hfe_type::text <> ALL (ARRAY['D'::character varying::text, 'B'::character varying::text]))
UNION ALL
 SELECT ofee.hfe_patientno,
    ofee.hfe_docno,
    ofee.hfe_deptid,
    ofee.hfe_refidx,
    ofee.hfe_roomid,
    ofee.hfe_idx,
    ofee.hfe_type,
    ofee.hfe_group,
    ofee.hfe_invoiceno,
    ofee.hfe_insinvoice,
    ofee.hfe_status,
    ofee.hfe_iaccept,
    ofee.hfe_entrydate,
    ofee.hfe_itemid,
        CASE
            WHEN length(hms_dynbedlist.hdbl_namefee::text) > 0 THEN hms_dynbedlist.hdbl_namefee::text
            ELSE hms_dynbedlist.hdbl_name::text
        END AS hfe_desc,
    ''::character varying AS hfe_unit,
    ofee.hfe_qty,
    ofee.hfe_unitprice,
    ofee.hfe_insprice,
    ofee.hfe_cost,
    ofee.hfe_inspaid,
    ofee.hfe_difcost,
    ofee.hfe_discount,
    ofee.hfe_patdebt,
    ofee.hfe_patpaid,
    ofee.hfe_difpaid,
    'N'::character varying AS hfe_hitech,
    ofee.hfe_depttype AS hfe_class,
    ofee.hfe_request,
    'N'::character varying(1) AS hfe_hastranfer,
    ofee.hfe_entrydate AS hfe_pdate,
    ofee.hfe_createdby AS hfe_doctor,
    ''::character varying AS hfe_regcode,
    1 AS hfe_ratio,
    0 AS hfe_unpaidqty
   FROM hms_other_fee ofee
     LEFT JOIN hms_bed_items ON ofee.hfe_docno = hms_bed_items.hbi_docno AND btrim(ofee.hfe_itemid::text) = hms_bed_items.hbi_idx::text
     LEFT JOIN hms_dynbedlist ON hms_dynbedlist.hdbl_deptid::text = hms_bed_items.hbi_deptid::text AND hms_dynbedlist.hdbl_idx = hms_bed_items.hbi_priceid
  WHERE (ofee.hfe_status::text = ANY (ARRAY['O'::character varying::text, 'C'::character varying::text, 'P'::character varying::text])) AND ofee.hfe_type::text = 'B'::text
UNION ALL
 SELECT ofee.hfe_patientno,
    ofee.hfe_docno,
    ofee.hfe_deptid,
    ofee.hfe_refidx,
    ofee.hfe_roomid,
    ofee.hfe_idx,
    ofee.hfe_type,
    ofee.hfe_group,
    ofee.hfe_invoiceno,
    ofee.hfe_insinvoice,
    ofee.hfe_status,
    ofee.hfe_iaccept,
    ofee.hfe_entrydate,
    ofee.hfe_itemid,
    pms_items.pmi_name AS hfe_desc,
    pms_items.pmi_unit AS hfe_unit,
    ofee.hfe_qty,
    ofee.hfe_unitprice,
    ofee.hfe_insprice,
    ofee.hfe_cost,
    ofee.hfe_inspaid,
    ofee.hfe_difcost,
    ofee.hfe_discount,
    ofee.hfe_patdebt,
    ofee.hfe_patpaid,
    ofee.hfe_difpaid,
    'N'::character varying AS hfe_hitech,
    ofee.hfe_depttype AS hfe_class,
    ofee.hfe_request,
    'N'::character varying(1) AS hfe_hastranfer,
    ofee.hfe_entrydate AS hfe_pdate,
    ofee.hfe_createdby AS hfe_doctor,
    ' '::character varying AS hfe_regcode,
    1 AS hfe_ratio,
    0 AS hfe_unpaidqty
   FROM hms_other_fee ofee
     LEFT JOIN pms_items ON ofee.hfe_itemid::text = pms_items.pmi_id::text
  WHERE (ofee.hfe_status::text = ANY (ARRAY['O'::character varying::text, 'C'::character varying::text, 'P'::character varying::text])) AND ofee.hfe_type::text = 'D'::text;

ALTER TABLE hmsv_fee_bh
  OWNER TO postgres;
GRANT ALL ON TABLE hmsv_fee_bh TO postgres;
