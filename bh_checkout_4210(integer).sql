-- Function: bh_checkout_4210(integer)

-- DROP FUNCTION bh_checkout_4210(integer);

CREATE OR REPLACE FUNCTION bh_checkout_4210(docno integer)
  RETURNS integer AS
$BODY$
    DECLARE
      v_ma_lk TEXT;
      tmpInt INTEGER;
      tmpIndex INTEGER;
      tmpRec RECORD;
      xRec RECORD;
      xCard RECORD;
      m_doctor VARCHAR(20);
      v_TypePatient TEXT;
      v_mabv      VARCHAR(15);
      v_Object    VARCHAR(1);
      v_statusDoc VARCHAR(1);
      tmpPercent  INTEGER;
      tmp_t_thuoc NUMERIC(15,2);
      tmp_t_dvkt  NUMERIC(15,2);
      tmp_t_vtyt  NUMERIC(15,2);
      tmp_bhtt     NUMERIC(15,2);
      tmp_bntt     NUMERIC(15,2);
      tmp_bhtt1 NUMERIC(15,2);
      tmp_bhtt2 NUMERIC(15,2);
      tmp_bncct NUMERIC(15,2);
      tmp_bncct1 NUMERIC(15,2);
	  tmp_bncct2 NUMERIC(15,2);
      tmp_nguon_khac NUMERIC(15,2);
      tmp_tong_chi NUMERIC(15,2);
      v_insline    VARCHAR(1);
      v_insoffline INTEGER;
      v_soluong   INTEGER;
      v_bntt      NUMERIC(15,2);
      v_bhtt      NUMERIC(15,2);
      v_ngayylenh VARCHAR(20);
      v_ngay_ra    VARCHAR(20);
      v_ngay_vao VARCHAR(20);
      v_Card_RegDate VARCHAR(50);
     v_Ngaydieutri integer;
	tmp_t_ndx NUMERIC(15,2);
      tmp_t_ndxTNT NUMERIC(15,2);
      tmp_t_ndxVT NUMERIC(15,2);
      v_benhkem TEXT;
      v_icd TEXT;
      v_hasxcard VARCHAR(1);
      v_deptTNT VARCHAR(20);
      t_ly_do_vao_vien text; 
    BEGIN
     
      --
      -- Khai bao ma khoa TNT

      
      v_Ngaydieutri:=0;
      -- lay tham so trai tuyen duoc huong bao nhieu phan tram
      SELECT hms_insoffline
      INTO v_insoffline
      FROM hms_config ;
      SELECT sc_id INTO v_mabv FROM sys_company limit 1;
      ---          LAY MA LIEN KET---
      --select  bh_checkout(15003047);
      SELECT TO_CHAR(hd_docno,'FM99999999') AS MA_LK,
        CASE
          WHEN hd_status     ='T'
          AND hd_suggestion  ='A'
          AND hd_outpatient <>'Y'
          THEN 'I'
          WHEN hd_suggestion ='A'
          AND hd_outpatient  ='Y'
          THEN 'O'
          ELSE 'E'
        END     AS TypePatient,
        ho_type AS Objecttype,
        hd_hasxcard as hasxcard
      FROM hms_doc
      LEFT JOIN hms_object
      ON (hd_object =ho_id)
      WHERE hd_docno=docno
      INTO v_ma_lk,
        v_TypePatient,
        v_Object,
        v_hasxcard;
     -- IF(v_hasxcard='Y') THEN

     SELECT * INTO tmpRec FROM hms_doc WHERE hd_docno=docno;

     IF(tmpRec.hd_insline='Y') THEN
	v_insline:='Y';
     ELSE 
	v_insline:='N';
     END IF;
	
	SELECT to_char(hc_regdate,'YYYYMMDD') as regdate,
		to_char(hc_expdate,'YYYYMMDD') as expdate,
		hc_regcode as regcode
		INTO xCard 
	 from hms_doc
	LEFT JOIN hms_card on (hc_patientno=hd_patientno and hc_cardno= hd_xcardno and hc_idx= hd_xcardidx) 
	 where hd_docno=docno and hd_hasxcard='Y';	
    --  END IF;
      
      --  raise notice '%,%',v_TypePatient,v_ma_lk;
      IF(v_Object NOT IN ('I','C')) THEN
        RETURN 20;
      END IF;
      IF(v_TypePatient IN ('I','O')) THEN
        SELECT hcr_status
        INTO v_statusDoc
        FROM hms_clinical_record
        WHERE hcr_docno =docno;
        IF(v_statusDoc <> 'T') THEN
          RETURN 30;
        END IF;
      END IF;
      IF(v_TypePatient IN ('E')) THEN
        SELECT * INTO tmpRec FROM hms_doc WHERE hd_docno=docno;
        IF(tmpRec.hd_status <> 'T') THEN
          RETURN 31;
        END IF;
        v_insline          := tmpRec.hd_insline;
        IF(tmpRec.hd_insline='Y') THEN
          RETURN 32;
        END IF;
      END IF;
      --- THEM THONG TIN BENH NHAN    ------
      -- Kiem tra thong tin neu co thi xoa di
      SELECT COUNT(*)
      FROM bh_thongtinbenhnhan
      WHERE ma_lk=v_ma_lk
      INTO tmpInt;
      IF(tmpInt >0) THEN
        DELETE FROM bh_thongtinbenhnhan WHERE ma_lk=v_ma_lk;
      END IF;
      FOR tmpRec IN
      SELECT hd_docno,
        TO_CHAR(hd_createddate, 'YYYYMMDDHH24MI') AS NGAYGIOVAO,
        CASE
          WHEN hd_suggestion <>'A'
          THEN TO_CHAR(hd_enddate, 'YYYYMMDDHH24MI')
          ELSE TO_CHAR(hcr_dischargedate, 'YYYYMMDDHH24MI')
        END AS NGAYGIORA,
        (SELECT sc_id FROM sys_company
        ) AS MABENHVIEN,
        CASE
          WHEN hcr_result IN ('1')
          OR hd_result    IN ('1')
          THEN 1
          WHEN hcr_result IN ('2')
          OR hd_result    IN ('2')
          THEN 2
          WHEN hcr_result IN ('3')
          OR hcr_result   IN ('3')
          THEN 3
          WHEN hcr_result IN ('4')
          OR hcr_result   IN ('4')
          THEN 4
          WHEN hcr_result IN ('5', '6')
          OR hd_result    IN ('5', '6')
          THEN 5
          ELSE 2
        END AS ketqua,
        CASE
          WHEN hcr_suggestion = 'T'
          OR hd_suggestion    = 'T'
          THEN 2
          WHEN hcr_result IN ('8')
          OR hd_result    IN ('8')
          THEN 3
          WHEN hcr_result IN ('7')
          OR hd_result    IN ('7')
          THEN 4
          WHEN hcr_result IN ('1', '2', '3', '4', '5', '6')
          OR hd_result    IN ('1', '2', '3', '4', '5', '6')
          THEN 1
          ELSE 1
        END AS tinhtrang,
        CASE
          WHEN hd_suggestion <>'A'
          THEN hd_icd
          ELSE hcr_mainicd
        END           AS CHANDOAN,
        hd_contacttel AS SODIENTHOAI_LH,
        hd_relative   AS NGUOILIENHE
      FROM hms_doc
      LEFT JOIN hms_patient
      ON (hp_patientno = hd_patientno)
      LEFT JOIN hms_clinical_record
      ON (hd_docno = hcr_docno)
      LEFT JOIN hms_card
      ON (hc_patientno=hd_patientno
      AND hc_idx      =hd_cardidx
      AND hd_cardno   = hc_cardno)
      WHERE hd_docno  = docno LOOP
      INSERT
      INTO bh_thongtinbenhnhan
        (
          ma_lk,
          ngaygiovao,
          ngaygiora,
          mabenhvien,
          chandoan,
          trangthai,
          ketqua,
          sodienthoai_lh,
          nguoilienhe,
          trangthaigui
        )
        VALUES
        (
          v_ma_lk,
          tmpRec.NGAYGIOVAO,
          tmpRec.NGAYGIORA,
          tmpRec.MABENHVIEN,
          tmpRec.CHANDOAN,
          tmpRec.tinhtrang,
          tmpRec.ketqua,
          tmpRec.SODIENTHOAI_LH,
          tmpRec.NGUOILIENHE,
          'Y'
        );
    END LOOP;
    ----- THONG TIN CHUYEN TUYEN -----------------
    SELECT COUNT(*)
    FROM bh_chuyentuyen
    WHERE ma_lk=v_ma_lk
    INTO tmpInt;
    IF(tmpInt >0) THEN
      DELETE FROM bh_chuyentuyen WHERE ma_lk=v_ma_lk;
    END IF;
    FOR tmpRec IN
    SELECT hd_docno    AS docno1,
      hhtd_numbertrans AS sochuyentuyen,
      CASE
        WHEN hd_suggestion ='T'
        THEN hd_tohosid
        ELSE hcr_hospitalid
      END AS mabvchuyendi,
      (SELECT sc_id FROM sys_company
      ) AS ma_bv_khambenh,
      (SELECT sc_name FROM sys_company
      ) AS ten_bv_khambenh,
      (SELECT ss_desc
      FROM sys_sel
      WHERE ss_id                  ='sys_occupation'
      AND CAST(ss_code AS INTEGER) =hp_occupation
      )             AS nghenghiep,
      hp_workplace  AS noilamviec,
      hhtd_clinical AS lamsang,
      hhtd_tests    AS kqxetnghiem,
      CASE
        WHEN hd_suggestion <>'A'
        THEN hd_diagnostic
        ELSE hcr_maindisease
      END             AS chandoan,
      hhtd_suggestion AS ppdieutri,
      -- CAST(hhtd_reason AS INTEGER)
      hhtd_patstate                             AS tinhtrangbenhnhan,
      1                                         AS lydochuyentuyen,
      hhtd_suggestion                           AS huongdieutri,
      TO_CHAR(hhtd_transdate, 'YYYYMMDDHH24MI') AS ngaychuyen,
      (SELECT ss_desc
      FROM sys_sel
      WHERE ss_id                  ='hms_transport_type'
      AND CAST(ss_code AS INTEGER) =hhtd_transport
      )             AS phuongtien,
      hhtd_attender AS nguoi_hotong,
      'VN'          AS quoctich,
      hp_ethnic     AS dantoc
    FROM hms_doc    AS tbl
    LEFT JOIN hms_clinical_record
    ON (hcr_docno=hd_docno)
    LEFT JOIN hms_htdoc
    ON (hd_docno=hhtd_docno )
    LEFT JOIN hms_patient
    ON (hp_patientno=hd_patientno)
    WHERE hd_docno  =docno
    AND hhtd_docno  > 0 LOOP
    INSERT
    INTO bh_chuyentuyen
      (
        ma_lk,
        sohoso,
        sochuyentuyen,
        ma_bv_chuyenden,
        ma_bv_khambenh,
        ten_cs_khambenh,
        nghenghiep,
        noilamviec,
        lamsang,
        ketquanxetnghiem,
        chandoan,
        phuongphapdieutri,
        tinhtrangnguoibenh,
        lydo_chuyentuyen,
        huongdieutri,
        thoigian_chuyen,
        phuongtien,
        nguoi_hotong,
        ma_quoctich,
        ma_dantoc
      )
      VALUES
      (
        v_ma_lk,
        docno,
        tmpRec.sochuyentuyen,
        tmpRec.mabvchuyendi,
        tmpRec.ma_bv_khambenh,
        tmpRec.ten_bv_khambenh,
        tmpRec.nghenghiep,
        tmpRec.noilamviec,
        tmpRec.lamsang,
        tmpRec.kqxetnghiem,
        tmpRec.chandoan,
        tmpRec.ppdieutri,
        tmpRec.tinhtrangbenhnhan,
        tmpRec.lydochuyentuyen,
        tmpRec.huongdieutri,
        tmpRec.ngaychuyen,
        tmpRec.phuongtien,
        tmpRec.nguoi_hotong,
        tmpRec.quoctich,
        tmpRec.dantoc
      );
  END LOOP;
  -- return 8000;
  -- DANH SACH CHUYEN VIEN  ----
  ----- THONG TIN CHUYEN TUYEN -----------------
  SELECT COUNT(*)
  FROM bh_dschuyenvien
  WHERE ma_lk=v_ma_lk
  INTO tmpInt;
  IF(tmpInt >0) THEN
    DELETE FROM bh_dschuyenvien WHERE ma_lk=v_ma_lk;
  END IF;
  --Benh vien chuyen den
  FOR tmpRec IN
  SELECT hd_transplaceid AS mabv,
    CASE
      WHEN hh_type='1'
      THEN 'A'
      WHEN hh_type='2'
      THEN 'B'
      WHEN hh_type='3'
      THEN 'C'
      ELSE NULL
    END                                 AS tuyen,
    TO_DATE('1752-09-14', 'YYYY-MM-DD') AS tungay,
    TO_DATE('1752-09-14', 'YYYY-MM-DD') AS denngay
  FROM hms_doc
  LEFT JOIN hms_hospital
  ON (hh_id                   =hd_transplaceid)
  WHERE hd_docno              =docno
  AND LENGTH(hd_transplaceid) >0 LOOP
  INSERT
  INTO bh_dschuyenvien
    (
      ma_lk,
      mabv,
      tuyen,
      tungay,
      denngay
    )
    VALUES
    (
      v_ma_lk,
      tmpRec.mabv,
      tmpRec.tuyen,
      tmpRec.tungay,
      tmpRec.denngay
    );
END LOOP;
--
--
--Benh vien dieu tri
FOR tmpRec IN
SELECT hh_id AS mabv,
  CASE
    WHEN hh_type='1'
    THEN 'A'
    WHEN hh_type='2'
    THEN 'B'
    WHEN hh_type='3'
    THEN 'C'
    ELSE NULL
  END                                                          AS tuyen,
  to_date(TO_CHAR(hd_createddate, 'YYYY/MM/DD'), 'YYYY/MM/DD') AS tungay,
  CASE
    WHEN hd_suggestion <>'A'
    THEN to_date(TO_CHAR(hd_enddate, 'YYYY/MM/DD'), 'YYYY/MM/DD')
    ELSE to_date(TO_CHAR(hcr_dischargedate, 'YYYY/MM/DD'), 'YYYY/MM/DD')
  END AS denngay
FROM hms_doc
LEFT JOIN hms_clinical_record
ON (hcr_docno=hd_docno)
LEFT JOIN hms_hospital
ON (hh_id      =v_mabv)
WHERE hd_docno =docno LOOP
INSERT
INTO bh_dschuyenvien
  (
    ma_lk,
    mabv,
    tuyen,
    tungay,
    denngay
  )
  VALUES
  (
    v_ma_lk,
    tmpRec.mabv,
    tmpRec.tuyen,
    tmpRec.tungay,
    tmpRec.denngay
  );
END LOOP;
--
--Benh vien chuyen di
FOR tmpRec IN
SELECT hhtd_hospitalid AS mabv,
  CASE
    WHEN hh_type='1'
    THEN 'A'
    WHEN hh_type='2'
    THEN 'B'
    WHEN hh_type='3'
    THEN 'C'
    ELSE NULL
  END                                 AS tuyen,
  TO_DATE('1752-09-14', 'YYYY-MM-DD') AS tungay,
  TO_DATE('1752-09-14', 'YYYY-MM-DD') AS denngay
FROM hms_doc
LEFT JOIN hms_htdoc
ON(hhtd_docno = hd_docno)
LEFT JOIN hms_hospital
ON (hh_id                   =hhtd_hospitalid)
WHERE hd_docno              =docno
AND LENGTH(hhtd_hospitalid) >0 LOOP
INSERT
INTO bh_dschuyenvien
  (
    ma_lk,
    mabv,
    tuyen,
    tungay,
    denngay
  )
  VALUES
  (
    v_ma_lk,
    tmpRec.mabv,
    tmpRec.tuyen,
    tmpRec.tungay,
    tmpRec.denngay
  );
END LOOP;
----- THONG TIN HANH CHINH TONG HOP ----------------------------------------------
DELETE
FROM bh_thongtinchitiet_tonghop
WHERE ma_lk=v_ma_lk;
--
tmpInt := 0;
  FOR tmpRec     IN
  SELECT hd_docno AS ma_bn,
  get_patientname1(hd_docno)       AS ho_ten,
   case when hp_yearofbirth='Y' then TO_CHAR(hp_birthdate,'YYYY')||'0101' 
		else TO_CHAR(hp_birthdate,'YYYYMMDD') end  AS ngay_sinh,
    CASE
      WHEN hp_sex='M'
      THEN 1
      WHEN hp_sex='F'
      THEN 2
      ELSE 3
    END AS gioi_tinh,
    CASE
      WHEN LENGTH(hp_workplace)>2
      THEN hp_workplace
      WHEN LENGTH(hp_dtladdr)>0
      THEN hp_dtladdr
        || ','
        ||hms_getaddress(hp_provid, hp_distid, hp_villid)
      ELSE hms_getaddress(hp_provid, hp_distid, hp_villid)
    END AS dia_chi,
    CASE
	WHEN hd_hasxcard='Y'  
	THEN  SUBSTR(hd_cardno,1,15)||';'||SUBSTR(hms_card2.hc_cardno,1,15)
      ELSE  SUBSTR(hd_cardno,1,15)
    END                            AS ma_the,
    CASE 
    WHEN hd_hasxcard='Y' and SUBSTR(hd_xcardno,16,5) <> SUBSTR(hms_card2.hc_cardno,16,5)
	then SUBSTR(hms_card.hc_cardno,16,5)||';'||SUBSTR(hms_card2.hc_cardno,16,5)
	else SUBSTR(hms_card.hc_cardno,16,5)    END AS ma_dkbd,
    CASE 
	when hd_hasxcard='Y' 
	then TO_CHAR(hms_card.hc_regdate,'YYYYMMDD')||';'||TO_CHAR(hms_card2.hc_regdate,'YYYYMMDD')
	ELSE TO_CHAR(hms_card.hc_regdate,'YYYYMMDD') 
	END AS gt_the_tu,
    CASE 
	when hd_hasxcard='Y' 
	THEN TO_CHAR(hms_card.hc_expdate,'YYYYMMDD')||';'||TO_CHAR(hms_card2.hc_expdate,'YYYYMMDD')
	ELSE TO_CHAR(hms_card.hc_expdate,'YYYYMMDD') 
	END AS gt_the_den,
    CASE 
	WHEN hd_over5year ='Y'
	THEN TO_CHAR(hd_datediscountall,'YYYYMMDD')
	ELSE NULL
	END AS MIEN_CUNG_CT,
    CASE
      WHEN hd_suggestion <>'A'
      THEN hd_diagnostic
      ELSE hcr_maindisease
    END AS ten_benh,
    CASE
      WHEN LENGTH(hcr_mainicd)>1
      THEN hcr_mainicd
      ELSE hd_icd
    END AS ma_benh,
    replace(hod_diagnostics,' ','') AS ma_benhkhac,
    CASE
      WHEN hd_emergency ='Y'
      THEN 2
      WHEN hd_insline='Y'
      THEN 3
      WHEN hd_insline='N' and substr(hd_cardno,16,5) <> v_mabv
      THEN 4
      ELSE 1
    END                   AS ma_lydo_vvien,
    trim(hd_transplaceid) AS ma_noi_chuyen,
    CASE
      WHEN hd_admitstate IN ('A','B')
      THEN 0
      WHEN hd_admitstate NOT IN ('A','B')
      AND ha_reason           =1
      THEN 1
      WHEN hd_admitstate NOT IN ('A','B')
      AND ha_reason           =2
      THEN 2
      WHEN hd_admitstate NOT IN ('A','B')
      AND ha_reason           =5
      THEN 3
      WHEN hd_admitstate NOT IN ('A','B')
      AND ha_reason           =6
      THEN 4
      WHEN hd_admitstate NOT IN ('A','B')
      AND ha_reason           = 8
      THEN 5
      WHEN hd_admitstate NOT IN ('A','B')
      AND ha_reason           =7
      THEN 6
      WHEN hd_admitstate NOT IN ('A','B')
      AND ha_reason           =10
      THEN 7
      ELSE 8
    END AS ma_tai_nan,
    CASE
      WHEN LENGTH(hd_indept)>0
      AND hd_suggestion     ='A'
      THEN TO_CHAR(hcr_admitdate,'YYYYMMDDHH24MI')
      ELSE TO_CHAR(hd_createddate,'YYYYMMDDHH24MI')
    END AS ngay_vao,
    CASE
      WHEN LENGTH(hcr_dischargedept)>0
      THEN TO_CHAR(hcr_dischargedate,'YYYYMMDDHH24MI')
      ELSE TO_CHAR(hd_enddate,'YYYYMMDDHH24MI')
    END AS ngay_ra,
    CASE
      WHEN hd_suggestion='A'
      THEN GREATEST(DATE(hcr_dischargedate)-DATE(hcr_admitdate) + 1,1)
      ELSE 0
      --GREATEST(DATE(hd_enddate)       - DATE(hd_createddate),1)
    END AS so_ngay_dtri,
    CASE
      WHEN hcr_result IN ('1')
      OR hd_result    IN ('1')
      THEN 1
      WHEN hcr_result IN ('2')
      OR hd_result    IN ('2')
      THEN 2
      WHEN hcr_result IN ('3')
      OR hcr_result   IN ('3')
      THEN 3
      WHEN hcr_result IN ('4')
      OR hcr_result   IN ('4')
      THEN 4
      WHEN hcr_result IN ('5', '6')
      OR hd_result    IN ('5', '6')
      THEN 5
      ELSE 2
    END AS ket_qua_dtri,
    CASE
      WHEN hcr_suggestion = 'T'
      OR hd_suggestion    = 'T'
      THEN 2
      WHEN hcr_result IN ('8')
      OR hd_result    IN ('8')
      THEN 3
      WHEN hcr_result IN ('7')
      OR hd_result    IN ('7')
      THEN 4
      ELSE 1
    END                              AS tinh_trang_rv,
    TO_CHAR(ngaytt,'YYYYMMDDHH24MI') AS ngay_ttoan,
    CASE
      WHEN hd_insline ='Y'
      THEN CAST((hd_disrate*hc_discount/100) AS INTEGER)
      ELSE CAST(hd_disrate AS                   INTEGER)
    END                                  AS muc_huong,
    SUM(hfe_inspaid)                     AS t_tongchi,
    SUM(hfe_inspaid) - SUM(hfe_discount) AS t_bntt,
    SUM(hfe_discount)                    AS t_bhtt ,
    0                                    AS t_nguonkhac,
    0                                    AS t_ngoaids,
    ROUND(SUM(t_thuoc),2)                AS t_thuoc,
    ROUND(SUM(t_vtyt),2)                 AS t_vtyt,
    extract(YEAR FROM ngaytt)            AS nam_qt,
    extract(MONTH FROM ngaytt)           AS thang_qt,
    CASE
      WHEN hd_suggestion <>'A'
      THEN 1
      WHEN hd_suggestion='A'
      AND hd_outpatient ='Y'
      THEN 2
      ELSE 3
    END     AS ma_loai_kcb,
    '22027' AS ma_cskcb,
    CASE
      WHEN hc_regarea=4
      THEN NULL
      WHEN hc_regarea=5
      THEN 'K1'
      WHEN hc_regarea=6
      THEN 'K2'
      WHEN hc_regarea=7
      THEN 'K3'
      ELSE NULL
    END                        AS ma_khuvuc,
    ' '                        AS ma_pttt_qt,
    hd_docno                   AS so_phieu,
    TO_CHAR(ngaytt,'YYYYMMDD') AS ngay_quyettoan,
    sd_insuranceid             AS ma_khoa,
    sd_id                      AS ma_khoabv,
    sd_name                    AS ten_khoabv,
    hd_relative                AS nguoi_lien_he,
    0                          AS loai_giayto_dikem,
    CAST(' ' AS text)          AS ten_loai_giayto,
    (SELECT MAX(he_weight) FROM hms_exam WHERE he_docno=docno AND he_weight <8
    ) AS can_nang
  FROM
    (SELECT
      (SELECT MAX(hfi_recvdate)
      FROM hms_fee_invoice
      WHERE hfi_docno  =tbla.hfi_docno
      AND hfi_type     ='P'
      AND hfi_discount >0
      ) AS ngaytt,
      hfi_docno,
      hfi_deptid,
      ROUND(hfe_inspaid,2)  AS hfe_inspaid,
      ROUND(hfe_cost,2)     AS hfe_cost,
      ROUND(hfe_patpaid,2)  AS hfe_patpaid,
      ROUND(hfe_discount,2) AS hfe_discount,
      CASE
      WHEN (substring(hfe_group,1,2) NOT IN ('A9','A4')
      AND hfe_type                       ='D') OR hfe_hastranfer='M'
        THEN ROUND(hfe_inspaid,2)
        ELSE 0
      END AS t_thuoc,
      CASE
        WHEN substring(hfe_group,1,2) IN ('A9','A4')
        THEN ROUND(hfe_inspaid,2)
        ELSE 0
      END                AS t_vtyt
    FROM hms_fee_invoice AS tbla
    LEFT JOIN hmsv_fee_bh
    ON ( hfe_invoiceno=hfi_invoiceno
    AND hfe_docno     =hfi_docno )
    WHERE hfe_status  ='P'
    AND hfi_docno     =docno
    AND hfi_type      ='P'
    AND hfe_discount  > 0
    ) AS tbl
  LEFT JOIN hms_doc
  ON ( hfi_docno=hd_docno )
  LEFT JOIN hms_clinical_record
  ON ( hcr_docno=hd_docno )
  LEFT JOIN hms_patient
  ON ( hd_patientno=hp_patientno )
  LEFT JOIN hms_card
  ON ( hc_patientno=hp_patientno
  AND hc_idx       =hd_cardidx
  AND hc_cardno    =hd_cardno )
  LEFT JOIN hms_object
  ON ( ho_id=hd_object )
  LEFT JOIN sys_dept
  ON ( sd_id=hfi_deptid )
  LEFT JOIN hms_accident
  ON ( hd_docno =ha_docno )
  LEFT JOIN hms_other_diagnostic
  ON ( hod_docno=hd_docno and hod_patientno= hd_patientno)
  left join (select hms_card.hc_cardno, hms_card.hc_regdate, hms_card.hc_expdate, hms_xcard.hxc_docno
  				from hms_xcard join hms_card on hms_xcard.hxc_cardidx=hms_card.hc_idx) as hms_card2
  				on hms_card2.hxc_docno=hd_docno
  GROUP BY ma_bn,
    ho_ten,
    ngay_sinh,
    gioi_tinh,
    ma_the,
    ma_dkbd,
    dia_chi,
    gt_the_tu,
    gt_the_den,
    hcr_maindisease,
    ha_reason,
    hd_suggestion,
    hcr_status,
    sd_id,
    hcr_mainicd,
    hcr_reldisease,
    hcr_admitdate,
    hcr_dischargedept,
    hcr_dischargedate,
    hcr_result,
    hcr_suggestion,
    sd_insuranceid,
    hc_regarea,
    hd_icd,
    hd_reldisease,
    hd_emergency,
    hd_insline,
    hd_admitdate,
    hd_result,
    hd_outpatient,
    ngaytt,
    hd_diagnostic,
    hd_admitstate,
    hd_indept,
    hd_enddate,
    hd_disrate,
    sd_name,
    hd_relative,
    hd_transplaceid,
    hd_createddate,
	  hc_discount,
	hod_diagnostics
 LOOP

 tmpPercent:= tmpRec.muc_huong;
 v_benhkem= tmpRec.ma_benhkhac;
 t_ly_do_vao_vien := tmpRec.ma_lydo_vvien;
 v_icd= tmpRec.ma_benh;
  IF(v_insline ='Y' AND tmpRec.t_tongchi < 195000) THEN
    tmpPercent:= v_insoffline;
  END IF;
  IF(tmpRec.t_bntt              = 0) THEN
    tmpPercent                 :=100;
  END IF;
  tmpInt := tmpInt+1;
   v_ngay_ra:= tmpRec.ngay_ra;
   v_ngay_vao:=tmpRec.ngay_vao;
   v_Card_RegDate:= tmpRec.gt_the_tu;
   if (substring(tmpRec.gt_the_tu,10,8)<substring(tmpRec.gt_the_tu,1,8))then
   		v_Card_RegDate=substring(tmpRec.gt_the_tu,10,8);
   else v_Card_RegDate=substring(tmpRec.gt_the_tu,1,8);
   end if;
   
   v_Ngaydieutri:= tmpRec.so_ngay_dtri;
   --raise notice '%, %,%',to_date(v_Card_RegDate,'YYYYMMDD'),to_date(v_ngay_vao,'YYYYMMDDHH24MI'),to_date(v_ngay_ra,'YYYYMMDDHH24MI');
   IF(to_date(v_Card_RegDate,'YYYYMMDD') between  to_date(v_ngay_vao,'YYYYMMDDHH24MI') and  to_date(v_ngay_ra,'YYYYMMDDHH24MI')) THEN
	v_ngay_vao:=v_Card_RegDate||'0000';
	v_Ngaydieutri:= to_date(v_ngay_ra,'YYYYMMDDHH24MI')-to_date(v_Card_RegDate,'YYYYMMDD') ;
	raise notice 'vao';
	
   END IF;
   --raise notice '%',tmpRec;

  INSERT
  INTO bh_thongtinchitiet_tonghop
    (
      ma_lk,
      stt,
      ho_ten,
      ngay_sinh,
      gioi_tinh,
      dia_chi,
      ma_the,
      ma_dkbd,
      gt_the_tu,
      gt_the_den,
      ma_benh,
      ma_benhkhac,
      ten_benh,
      ma_lydo_vvien,
      ma_noi_chuyen,
      ma_tai_nan,
      ngay_vao,
      ngay_ra,
      so_ngay_dtri,
      ket_qua_dtri,
      tinh_trang_rv,
      ngay_ttoan,
      muc_huong,
      t_tongchi,
      t_bntt,
      t_bhtt,
      t_nguonkhac,
      t_ngoaids,
      nam_qt,
      thang_qt,
      ma_loai_kcb,
      ma_cskcb,
      ma_khuvuc,
      ma_pttt_qt,
      trangthaigui,
      so_phieu,
      ma_bn,
      ngay_quyettoan,
      ma_khoa,
      ma_khoabv,
      ten_khoabv,
      nguoi_lien_he,
      loai_giayto_dikem,
      ten_loai_giayto,
      t_thuoc,
      t_vtyt,
      can_nang,
      time_process,
      MIEN_CUNG_CT
    )
    VALUES
    (
      v_ma_lk,
      tmpInt,
      tmpRec.ho_ten,
      tmpRec.ngay_sinh,
      tmpRec.gioi_tinh,
      tmpRec.dia_chi,
      tmpRec.ma_the,
      tmpRec.ma_dkbd,
      tmpRec.gt_the_tu,
      tmpRec.gt_the_den,
      tmpRec.ma_benh,
      tmpRec.ma_benhkhac,
      tmpRec.ten_benh,
      tmpRec.ma_lydo_vvien,
      tmpRec.ma_noi_chuyen,
      tmpRec.ma_tai_nan,
      v_ngay_vao,
      tmpRec.ngay_ra,
     -- tmpRec.so_ngay_dtri,
     v_Ngaydieutri,
      tmpRec.ket_qua_dtri,
      tmpRec.tinh_trang_rv,
      tmpRec.ngay_ttoan,
      tmpPercent,
      tmpRec.t_tongchi,
      tmpRec.t_bntt,
      tmpRec.t_bhtt,
      tmpRec.t_nguonkhac,
      tmpRec.t_ngoaids,
      tmpRec.nam_qt,
      tmpRec.thang_qt,
      tmpRec.ma_loai_kcb,
      v_mabv,
      tmpRec.ma_khuvuc,
      tmpRec.ma_pttt_qt,
      'Y',
      tmpRec.so_phieu,
      tmpRec.ma_bn,
      tmpRec.ngay_quyettoan,
      tmpRec.ma_khoa,
      tmpRec.ma_khoabv,
      tmpRec.ten_khoabv,
      tmpRec.nguoi_lien_he,
      tmpRec.loai_giayto_dikem,
      tmpRec.ten_loai_giayto,
      tmpRec.t_thuoc,
      tmpRec.t_vtyt,
      tmpRec.can_nang,
      CURRENT_TIMESTAMP,
      tmpRec.MIEN_CUNG_CT
    );
get diagnostics tmpInt = row_count;
IF(tmpInt             <=0) THEN
  RETURN -100;
END IF;
END LOOP;
---------- THONG TIN THUOC CUA BENH NHAN ---------------
DELETE
FROM bh_bang_ctthuoc
WHERE ma_lk=v_ma_lk;
tmpInt := 0;
FOR tmpRec IN
SELECT
  CASE
    WHEN substring(hfe_group,1,2) =('A2')
    AND LENGTH(pbl_id)            >0
    THEN pbl_id
    WHEN LENGTH(pmc_mathuoc) >0
    THEN pmc_mathuoc
    ELSE hpol_itemid
  END AS itemid,
  CASE
    WHEN substring(hfe_group,1,2) NOT IN ('A9','A4','A2')
    AND (pmi_insdisrate                =0
    OR pmi_insdisrate                 IS NULL)
    THEN 4
    WHEN substring(hfe_group,1,2) IN ('A2')
    AND (pmi_insdisrate            =0
    OR pmi_insdisrate             IS NULL)
    THEN 7
    WHEN substring(hfe_group,1,2) IN ('A9','A4')
    AND (pmi_insdisrate            =0
    OR pmi_insdisrate             IS NULL)
    THEN 10
    WHEN substring(hfe_group,1,2) NOT IN ('A9','A4','A2')
    AND pmi_insdisrate                 >0
    THEN 6
    WHEN substring(hfe_group,1,2) IN ('A9','A4')
    AND pmi_insdisrate             > 0
    THEN 9
    ELSE NULL
  END AS ma_nhom,
  CASE
    WHEN substring(hfe_group,1,2) =('A2')
    AND LENGTH(pbl_name)          >0
    THEN pbl_name
    WHEN LENGTH (trim(pmc_tenbietduoc)) >0
    THEN pmc_tenbietduoc
    ELSE pmi_name
  END                AS namedrug,
  hpol_unit          AS unit,
  pmc_hamluong       AS hamluong,
  pmc_maduongdung    AS duongdung,
  pmc_sodangky       AS regcode,
  case WHEN substring(hfe_group,1,2) =('A2')
    OR pmsi_contractlist_uid      =0 then NULL
    else 
 coalesce(pcs_contractor_name,'')||';'||coalesce(pmc_package,'')||';'||coalesce(pmc_group,'') end as tt_thau,
  case when hfe_discount >0 then 1 else 2 end as pham_vi,
  round(SUM(round(hpol_issueqty,2)),2) AS qty,
  CASE
    WHEN substring(hfe_group,1,2) =('A2')
    OR pmsi_contractlist_uid      =0
    THEN hfe_insprice
    ELSE pmc_unitprice
  END AS price,
  CASE
    WHEN pmi_insdisrate >0
    THEN pmi_insdisrate
	WHEN hfe_discount=0 THEN 0
    ELSE 100
  END AS tyle_tt,
  CASE
    WHEN substring(hfe_group,1,2) =('A2')
    OR pmsi_contractlist_uid   =0
    THEN SUM(ROUND(hpol_issueqty*hfe_insprice, 2))
    ELSE SUM(ROUND(round(hpol_issueqty,2) *pmc_unitprice, 2))
  END            AS amout,
  hms_pharmacyorder_line.hfe_disrate as muc_huong,
  sd_insuranceid AS deptid, 
  case
  	when (SELECT su_certificate FROM sys_user WHERE su_userid =trim(hpo_doctor)) is null then '('||trim(hpo_doctor)||')' 
  	when trim((SELECT su_certificate FROM sys_user WHERE su_userid =trim(hpo_doctor)))='' then '('||trim(hpo_doctor)||')'
  	else (SELECT su_certificate FROM sys_user WHERE su_userid =trim(hpo_doctor))
  end AS doctor,
  CASE
    WHEN hd_suggestion <>'A'
    THEN hd_icd
    ELSE hcr_mainicd
  END                                      AS mainicd,
  TO_CHAR(hpo_orderdate, 'YYYYMMDDHH24MI') AS orderdate,
  sd_name                                  AS ten_khoabv,
  hfe_insprice                             AS don_gia_bv,
  0                                        AS t_nguonkhac,
  hpol_itemid                              AS ma_thuoc_cs,
  CASE
    WHEN pmi_insdisrate >0 
    THEN ROUND(SUM ((round(hpol_issueqty,2) *pmc_unitprice*(100-hms_pharmacyorder_line.hfe_disrate)/100)),2)
    ELSE 0
  END AS t_bntt,
  ROUND(hpol_issueqty*pmc_unitprice*hms_pharmacyorder_line.hfe_disrate/100,2) as t_bhtt,
  ROUND(hpol_issueqty*pmc_unitprice*(100-hms_pharmacyorder_line.hfe_disrate)/100,2) as t_bncct,
  CASE
    WHEN hpol_usage='' OR hpol_usage IS NULL THEN 'Theo chỉ định của bác sỹ'
    ELSE hpol_usage
  END AS lieu_dung,
  1          AS ma_pttt,
  0 as t_ngoaids
FROM hms_pharmacyorder
LEFT JOIN hms_pharmacyorder_line
ON (hpo_orderid=hpol_orderid)
LEFT JOIN pms_stockitems
ON (pmsi_id=hpol_sitemid)
LEFT JOIN pms_items
ON (pmi_id=hpol_itemid)
LEFT JOIN pms_contractorlist
ON (pmc_uid=pmsi_contractlist_uid)
LEFT JOIN pms_contractor_setup
ON (pcs_idx=pmc_contract_id)
LEFT JOIN pms_bloodlist
ON (pbl_id=pmi_insuranceid)
LEFT JOIN hms_doc
ON (hd_docno=hpo_docno)
LEFT JOIN hms_clinical_record
ON (hcr_docno=hpo_docno)
LEFT JOIN sys_dept
ON (sd_id                          =hpo_deptid)
WHERE hpo_docno                    =docno
AND hpo_type NOT                  IN ('M','B')
AND hpo_status NOT                IN ('O','C')
AND hfe_discount                   >0
AND hfe_invoiceno                  >0
AND substring(pmi_typeid,1,2) NOT IN('A9','A4')
GROUP BY hpo_docno,
  pmc_mathuoc,
  hfe_group,
  pmi_insdisrate,
  pmc_tenbietduoc,
  pmi_unit,
  hpol_unit,
  pmc_hamluong,
  pmc_maduongdung,
  pmc_sodangky,
  pmc_unitprice,
  sd_insuranceid,
  hpo_doctor,
  hd_suggestion,
  hd_icd,
  hcr_mainicd,
  hpo_orderdate,
  sd_name,
  hfe_insprice,
  hpol_itemid,
  hpol_usage,
  hpo_deptid,
  pbl_id,
  pbl_name,
  pmi_name,
  pmsi_contractlist_uid,pmc_quyetdinh,pmc_package,pmc_group,hfe_discount,pcs_contractor_id,
  hms_pharmacyorder_line.hfe_disrate,
  hpol_issueqty
ORDER BY orderdate,
  hpo_deptid,
  ma_nhom,
  itemid LOOP tmpInt := tmpInt+1;
--raise notice '%',tmpRec.qty;
INSERT
INTO bh_bang_ctthuoc
  (
    ma_lk,
    stt,
    ma_thuoc,
    ma_nhom,
    ten_thuoc,
    don_vi_tinh,
    ham_luong,
    duong_dung,
    so_dang_ky,
    so_luong,
    don_gia,
    tyle_tt,
    thanh_tien,
    ma_khoa,
    ma_bac_si,
    ma_benh,
    ngay_yl,
    trangthaigui,
    ten_khoabv,
    don_gia_bv,
    ma_thuoc_cs,
    t_bntt,
    t_bhtt,
    t_bncct,
    lieu_dung,
    ma_pttt,
    tt_thau,
    muc_huong,
    pham_vi,
    t_nguonkhac,
    t_ngoaids
  )
  VALUES
  (
    v_ma_lk,
    tmpInt,
    tmpRec.itemid,
    tmpRec.ma_nhom,
    tmpRec.namedrug,
    tmpRec.unit,
    tmpRec.hamluong,
    tmpRec.duongdung,
    tmpRec.regcode,
    tmpRec.qty,
    tmpRec.price,
    tmpRec.tyle_tt,
    tmpRec.amout,
    tmpRec.deptid,
    tmpRec.doctor,
    tmpRec.mainicd,
    tmpRec.orderdate,
    'Y',
    tmpRec.ten_khoabv,
    tmpRec.don_gia_bv,
    tmpRec.ma_thuoc_cs,
    tmpRec.t_bntt,
    tmpRec.t_bhtt,
    tmpRec.t_bncct,
    tmpRec.lieu_dung,
    tmpRec.ma_pttt,
    tmpRec.tt_thau,
    tmpRec.muc_huong,
    tmpRec.pham_vi,
    tmpRec.t_nguonkhac,
    tmpRec.t_ngoaids
  );

END LOOP;
raise notice 'vao den day';
---  DICH VU KY THUAT VA  VT T  THANH TOAN BHYT----
--raise notice '%', tmpInt;
DELETE
FROM bh_bang_ctdv
WHERE ma_lk=v_ma_lk;
--
tmpInt := 0;
FOR tmpRec IN
SELECT
  CASE
    WHEN substring(tbl1.hfe_group,1,2) IN ('A9','A4')
    THEN NULL
    WHEN LENGTH(hfe_regcode) > 0
    THEN hfe_regcode
    WHEN LENGTH(hfl_regcode) >0
    THEN hfl_regcode
    ELSE hfe_itemid
  END  AS madichvu,
  NULL AS mavattu,
  case  	
    WHEN substring(tbl1.hfe_group,1,2) IN ('A9','A4')
    THEN '10'
    WHEN substring(tbl1.hfe_group,1,2)='B1'
    THEN '1'
    WHEN substring(tbl1.hfe_group,1,2)     ='B2'
    THEN '2'
    WHEN substring(tbl1.hfe_group,1,2)='B3'
    THEN '3'
    WHEN substring(tbl1.hfe_group,1,2) IN ('B4','B5')
    AND (hfe_hastranfer           <> 'Y'
    OR hfe_hastranfer             IS NULL)
    THEN '8'
    WHEN (hfe_type='E' )
    THEN '13'
    WHEN hfe_hastranfer='Y'
    THEN '12'
    WHEN tbl1.hfe_group='C0000'
    OR hfe_type   ='B'
    THEN '15'
    WHEN tbl1.hfe_hastranfer='M' then '7'    
    when (hfl_regcode IN ('11.1900','05.1900','04.1900','14.1900','10.1900','03.1900','02.1900','07.1900','13.1900','17.1900','16.1900','15.1900','06.1900','12.1900','08.1900','11.1896','05.1896','04.1896','14.1896','10.1896','03.1896','02.1896','07.1896','13.1896','17.1896','16.1896','15.1896','06.1896','12.1896','08.1896')) then '13'
    ELSE NULL
  END      AS manhom,
  NULL as goi_vtyt,
  hfe_desc AS tendv,
  CASE
    WHEN hfe_type = 'B'
    THEN 'Ngày'
    ELSE hfl_unit
  END                        AS donvi,
  case when tbl1.hfe_discount >0 then 1 else  2 end as pham_vi,
  case when tbl1.hfe_unpaidqty >0 then  tbl1.hfe_qty - tbl1.hfe_unpaidqty else tbl1.hfe_qty END AS soluong,
  tbl1.hfe_insprice AS dongia,
  NULL as tt_thau,
  CASE
    WHEN hfe_type='D'
    THEN 100
    ELSE CAST(ss_desc AS INTEGER)
  END                   AS tyle_tt,  
  ROUND(
  	(case when tbl1.hfe_unpaidqty >0 then  tbl1.hfe_qty - tbl1.hfe_unpaidqty else tbl1.hfe_qty END)*
  	tbl1.hfe_insprice , 2) AS thanhtien,
  0 as t_trantt,
  tbl1.hfe_disrate as muc_huong,
  sd_insuranceid             AS deptid,
  case
  	when (SELECT su_certificate FROM sys_user WHERE su_userid =trim(hfe_doctor)) is null then '('||trim(hfe_doctor)||')' 
  	when trim((SELECT su_certificate FROM sys_user WHERE su_userid =trim(hfe_doctor)))='' then '('||trim(hfe_doctor)||')'
  	else (SELECT su_certificate FROM sys_user WHERE su_userid =trim(hfe_doctor))
  end AS bacsychidinh,
  CASE
    WHEN hd_suggestion <>'A'
    THEN hd_icd
    ELSE hcr_mainicd
  END                                     AS MA_BENH,
  TO_CHAR(hfe_entrydate,'YYYYMMDDHH24MI') AS ngay_yl,
  CASE
    WHEN hfe_pdate='1752-09-14 00:00:00'
    THEN TO_CHAR(hfe_entrydate,'YYYYMMDDHH24MI')
    ELSE TO_CHAR(hfe_pdate,'YYYYMMDDHH24MI')
  END           AS ngay_kq,
  sd_name       AS ten_khoabv,
  tbl1.hfe_unitprice AS don_gia_bv,
  0             AS t_nguonkhac,
  CASE
    WHEN hfe_type = 'B'
    THEN hfe_deptid
      ||'.'
      ||hfe_roomid
      ||'.'
      ||hfe_idx
    ELSE hfl_feeid
  END                                       AS ma_dich_vu_cs,
  NULL                                      AS ma_vat_tu_cs,
 ROUND((tbl1.hfe_inspaid -tbl1.hfe_discount),2) AS t_bncct,
 ROUND(tbl1.hfe_discount,2)               AS t_bhtt,
 0 as t_bntt,
 CASE WHEN tbl1.hfe_type='B' and tbl1.hfe_hastranfer='D' then hms_get_bedid('D', docno,tbl1.hfe_deptid,tbl1.hfe_idx)
 when tbl1.hfe_type='B' and tbl1.hfe_hastranfer <>'D' then hms_get_bedid('B', docno,tbl1.hfe_deptid,tbl1.hfe_idx)
end as ma_giuong,
  1       AS ma_pttt
FROM hmsv_fee_bh as tbl1
LEFT JOIN sys_sel
ON (ss_id  ='hms_bedratio'
AND ss_code=CAST(hfe_ratio AS text))
LEFT JOIN hms_feelist
ON (hfl_feeid=hfe_itemid)
LEFT JOIN hms_doc
ON (hfe_docno=hd_docno)
LEFT JOIN hms_clinical_record
ON (hcr_docno=hfe_docno)
LEFT JOIN sys_dept
ON (hfe_deptid    =sd_id)
WHERE hfe_docno   =docno
AND tbl1.hfe_inspaid           >0
AND tbl1.hfe_invoiceno         >0
AND tbl1.hfe_discount          >0
AND hfe_type NOT IN ('D')
GROUP BY hfe_type,
  hfe_deptid,
  hfe_roomid,
  hfe_idx,
  hfl_feeid,
  tbl1.hfe_group,
  hfe_itemid,
  hfe_hastranfer,
  hfe_desc,
  hfe_qty,
  tbl1.hfe_insprice,
  sd_insuranceid,
  hfe_doctor,
  hd_suggestion,
  hd_icd,
  hcr_mainicd,
  hfe_entrydate,
  hfe_pdate,
  hd_disrate,
  sd_name,
  tbl1.hfe_unitprice,
  hfl_unit,
  hfe_regcode,
  hfe_itemid,
  hfl_insuranceid,
   tbl1.hfe_inspaid,
  hfl_regcode,  ss_desc,tbl1.hfe_ratio,
  tbl1.hfe_discount,tbl1.hfe_unpaidqty,
  tbl1.hfe_disrate
ORDER BY hfe_deptid,
  manhom,
  hfe_entrydate 
LOOP 

  IF(tmpRec.manhom='7') THEN
	
  SELECT max(stt) INTO tmpIndex from bh_bang_ctthuoc  where ma_lk=v_ma_lk;
	INSERT
	INTO bh_bang_ctthuoc
	  (
	    ma_lk,
	    stt,
	    ma_thuoc,
	    ma_nhom,
	    ten_thuoc,
	    don_vi_tinh,
	    ham_luong,
	    duong_dung,
	    so_dang_ky,
	    so_luong,
	    don_gia,
	    tyle_tt,
	    thanh_tien,
	    ma_khoa,
	    ma_bac_si,
	    ma_benh,
	    ngay_yl,
	    trangthaigui,
	    ten_khoabv,
	    don_gia_bv,
	    t_nguonkhac,
	    ma_thuoc_cs,
	    t_bntt,
	    t_bhtt,
	    lieu_dung,
	    ma_pttt,
	    muc_huong,
	    pham_vi
	  )
	  VALUES
	  (
	    v_ma_lk,
	    tmpIndex,
	    tmpRec.madichvu,
	    tmpRec.manhom,
	    tmpRec.tendv,
	    tmpRec.donvi,
	    null,
	    null,
	    null,
	    tmpRec.soluong,
	    tmpRec.dongia,
	    tmpRec.tyle_tt,
	    tmpRec.thanhtien,
	    tmpRec.deptid,
	    tmpRec.bacsychidinh,
	    tmpRec.MA_BENH,
	    tmpRec.ngay_yl,
	    'Y',
	    tmpRec.ten_khoabv,
	    tmpRec.don_gia_bv,
	    tmpRec.t_nguonkhac,
	    tmpRec.ma_dich_vu_cs,
	    tmpRec.t_bntt,
	    tmpRec.t_bhtt,
	    null,
	    tmpRec.ma_pttt,
	    tmpRec.muc_huong,
	    tmpRec.pham_vi
	    
	  );

  ELSE IF(tmpRec.manhom                ='15' AND tmpRec.soluong <0 ) THEN
  v_ngayylenh                  :=tmpRec.ngay_yl;

  FOR i IN 1..CAST(tmpRec.soluong AS INTEGER)
  LOOP
    tmpInt      := tmpInt+1;
    IF(i         >1) THEN
      v_ngayylenh= TO_CHAR((TO_DATE(v_ngayylenh,'YYYYMMDDHH24MI') +1),'YYYYMMDDHH24MI');
      IF( TO_DATE(v_ngayylenh,'YYYYMMDDHH24MI') > TO_DATE(v_ngay_ra,'YYYYMMDDHH24MI') ) THEN
        v_ngayylenh                            :=v_ngay_ra;
      END IF;


END IF;
INSERT
INTO bh_bang_ctdv
  (
    ma_lk,
    stt,
    ma_dich_vu,
    ma_vat_tu,
    ma_nhom,
    ten_dich_vu,
    don_vi_tinh,
    so_luong,
    don_gia,
    tyle_tt,
    thanh_tien,
    ma_khoa,
    ma_bac_si,
    ma_benh,
    ngay_yl,
    ngay_kq,
    trangthaigui,
    ten_khoabv,
    don_gia_bv,
    t_nguonkhac,
    ma_dich_vu_cs,
    ma_vat_tu_cs,
    t_bntt,
    t_bhtt,
    ma_pttt,
    ma_giuong,
    t_bncct,
    muc_huong,
    pham_vi,
    t_trantt
  )
  VALUES
  (
    v_ma_lk,
    tmpInt,
    tmpRec.madichvu,
    tmpRec.mavattu,
    tmpRec.manhom,
    tmpRec.tendv,
    tmpRec.donvi,
    1,
    tmpRec.dongia,
    tmpRec.tyle_tt,
    tmpRec.dongia*tmpRec.tyle_tt/100,
    tmpRec.deptid,
    tmpRec.bacsychidinh,
    tmpRec.MA_BENH,
    v_ngayylenh,
    v_ngayylenh,
    'Y',
    tmpRec.ten_khoabv,
    tmpRec.don_gia_bv,
    tmpRec.t_nguonkhac,
    tmpRec.ma_dich_vu_cs,
    tmpRec.ma_vat_tu_cs,
    v_bntt,
    v_bhtt,
    tmpRec.ma_pttt,
    tmpRec.ma_giuong,
    tmpRec.t_bncct,
    tmpRec.muc_huong,
    tmpRec.pham_vi,
    tmpRec.t_trantt );
  END LOOP;
ELSE
	--H	
  if((tmpRec.manhom='15' and (tmpRec.tyle_tt=50 or tmpRec.tyle_tt=30))
			or (tmpRec.manhom='13' and (tmpRec.tyle_tt=30 or tmpRec.tyle_tt=10))
			or (tmpRec.manhom='8' and (tmpRec.tyle_tt=50 or tmpRec.tyle_tt=80))) then
				tmpRec.thanhtien:=tmpRec.thanhtien*tmpRec.tyle_tt/100;
  end if;

  tmpInt := tmpInt+1;
  INSERT
  INTO bh_bang_ctdv
    (
      ma_lk,
      stt,
      ma_dich_vu,
      ma_vat_tu,
      ma_nhom,
      ten_dich_vu,
      don_vi_tinh,
      so_luong,
      don_gia,
      tyle_tt,
      thanh_tien,
      ma_khoa,
      ma_bac_si,
      ma_benh,
      ngay_yl,
      ngay_kq,
      trangthaigui,
      ten_khoabv,
      don_gia_bv,
      t_nguonkhac,
      ma_dich_vu_cs,
      ma_vat_tu_cs,
      t_bntt,
      t_bhtt,
      ma_pttt,
      ma_giuong,
      t_bncct,
      muc_huong,
      pham_vi,
      t_trantt
    )
    VALUES
    (
      v_ma_lk,
      tmpInt,
      tmpRec.madichvu,
      tmpRec.mavattu,
      tmpRec.manhom,
      tmpRec.tendv,
      tmpRec.donvi,
    tmpRec.soluong,
    tmpRec.dongia,
    tmpRec.tyle_tt,
    tmpRec.thanhtien,
    tmpRec.deptid,
    tmpRec.bacsychidinh,
    tmpRec.MA_BENH,
    tmpRec.ngay_yl,
    tmpRec.ngay_kq,
    'Y',
    tmpRec.ten_khoabv,
    tmpRec.don_gia_bv,
    tmpRec.t_nguonkhac,
    tmpRec.ma_dich_vu_cs,
    tmpRec.ma_vat_tu_cs,
    tmpRec.t_bntt,
    tmpRec.t_bhtt,
    tmpRec.ma_pttt,
    tmpRec.ma_giuong,
    tmpRec.t_bncct,
    tmpRec.muc_huong,
    tmpRec.pham_vi,
    tmpRec.t_trantt
  );
END IF;
END IF;
END LOOP;

-- Vat tu tieu hao
FOR tmpRec IN
SELECT 
  null    AS madichvu,
  CASE
    WHEN LENGTH(pmc_mathuoc) >0
    THEN pmc_mathuoc
    WHEN LENGTH(pmi_insuranceid) >0 
	THEN pmi_insuranceid
    ELSE hpol_itemid
  END AS mavattu,
  '10' as manhom,
  '' as goi_vtyt,
  case 
  	when pcs_publishdate is null then '0000.00.0'
  	else to_char(pcs_publishdate,'YYYY')||'.'||pmc_package||'.'||pcs_contractor_name 
  end as tt_thau,
  CASE
    WHEN LENGTH(pmc_tenbietduoc)>0
    THEN pmc_tenbietduoc
    ELSE pmi_name
  END                AS tenvt,
  NULL as tendv,
  pmi_unit          AS donvi,
  SUM(hpol_issueqty) AS soluong,
  CASE
    WHEN pmsi_contractlist_uid=0
    THEN hfe_insprice
    ELSE pmc_unitprice
  END AS dongia,
  CASE
    WHEN pmi_insdisrate >0
    THEN pmi_insdisrate
    ELSE 100
  END AS tyle_tt,
  0 as t_trantt,
  case when hfe_discount >0 then 1 else 2 end as pham_vi,
  tmpPercent  as muc_huong,
  CASE
    WHEN pmsi_contractlist_uid=0
    THEN SUM(ROUND(hpol_issueqty *hfe_insprice, 2))
    WHEN pmi_insdisrate >0
    THEN SUM(ROUND(hpol_issueqty *pmc_unitprice*pmi_insdisrate/100, 2))
    ELSE SUM(ROUND(hpol_issueqty *pmc_unitprice, 2))
  END            AS thanhtien,
  sd_insuranceid AS deptid,
  case
  	when (SELECT su_certificate FROM sys_user WHERE su_userid =trim(hpo_doctor)) is null then '('||trim(hpo_doctor)||')' 
  	when trim((SELECT su_certificate FROM sys_user WHERE su_userid =trim(hpo_doctor)))='' then '('||trim(hpo_doctor)||')'
  	else (SELECT su_certificate FROM sys_user WHERE su_userid =trim(hpo_doctor))
  end AS bacsychidinh,
  CASE
    WHEN hd_suggestion <>'A'
    THEN hd_icd
    ELSE hcr_mainicd
  END                                      AS MA_BENH,
  TO_CHAR(hpo_orderdate, 'YYYYMMDDHH24MI') AS ngay_yl,
  TO_CHAR(hpo_orderdate, 'YYYYMMDDHH24MI') AS ngay_kq,
  sd_name                                  AS ten_khoabv,
  hfe_insprice                             AS don_gia_bv,
  0                                        AS t_nguonkhac,
  NULL                                     AS ma_dich_vu_cs,
  hpol_itemid                              AS ma_vat_tu_cs,
  CASE
    WHEN pmsi_contractlist_uid=0
    THEN ROUND(SUM(hpol_issueqty * hfe_insprice*(100-tmpPercent)/100),2)
    WHEN pmi_insdisrate >0
    THEN ROUND(SUM ((hpol_issueqty*pmc_unitprice*pmi_insdisrate/100) * (100-tmpPercent)/100),2)
    ELSE ROUND(SUM(hpol_issueqty  *pmc_unitprice*(100-tmpPercent)/100),2)
  END AS t_bncct ,
  0 as t_bntt,
  CASE
    WHEN pmsi_contractlist_uid=0
    THEN ROUND(SUM(hpol_issueqty *hfe_insprice*tmpPercent/100),2)
    WHEN pmi_insdisrate >0
    THEN ROUND(SUM ((hpol_issueqty*pmc_unitprice*pmi_insdisrate/100) * tmpPercent/100),2)
    ELSE ROUND(SUM(hpol_issueqty  *pmc_unitprice*tmpPercent/100),2)
  END AS t_bhtt,
  1   AS ma_pttt
FROM hms_pharmacyorder
LEFT JOIN hms_pharmacyorder_line
ON (hpo_orderid=hpol_orderid)
LEFT JOIN pms_stockitems
ON (pmsi_id=hpol_sitemid)
LEFT JOIN pms_items
ON (pmi_id=hpol_itemid)
LEFT JOIN pms_contractorlist
ON (pmc_uid=pmsi_contractlist_uid)
LEFT JOIN pms_contractor_setup ON (pcs_idx=pmc_contract_id)
LEFT JOIN hms_doc
ON (hd_docno=hpo_docno)
LEFT JOIN hms_clinical_record
ON (hcr_docno=hpo_docno)
LEFT JOIN sys_dept
ON (sd_id                      =hpo_deptid)
WHERE hpo_docno                =docno
AND hpo_type NOT              IN ('M','B')
AND hpo_status NOT            IN ('O','C')
AND hfe_discount               >0
AND hfe_invoiceno              >0
AND substring(pmi_typeid,1,2) IN('A9','A4')
GROUP BY hpo_docno,
  pmc_mathuoc,
  hfe_group,
  pmi_insdisrate,
  pmc_tenbietduoc,
  hpol_unit,pmi_unit,
  pmc_hamluong,
  pmc_maduongdung,
  pmc_sodangky,
  pmc_unitprice,
  sd_insuranceid,
  hpo_doctor,
  hd_suggestion,
  hd_icd,
  hcr_mainicd,
  hpo_orderdate,
  sd_name,
  hfe_insprice,
  hpol_itemid,
  hpol_usage,
  hpo_deptid,
  pmi_name,
  pmsi_contractlist_uid,pmi_insuranceid,hfe_discount,
  pcs_publishdate,
  pmc_package,
  pcs_contractor_id
ORDER BY ngay_yl,
  hpo_deptid,
  manhom,
  mavattu LOOP tmpInt := tmpInt     +1;
  
INSERT
INTO bh_bang_ctdv
  (
    ma_lk,
    stt,
    ma_dich_vu,
    ma_vat_tu,
    ma_nhom,
    ten_dich_vu,
    don_vi_tinh,
    so_luong,
    don_gia,
    tyle_tt,
    thanh_tien,
    ma_khoa,
    ma_bac_si,
    ma_benh,
    ngay_yl,
    ngay_kq,
    trangthaigui,
    ten_khoabv,
    don_gia_bv,
    t_nguonkhac,
    ma_dich_vu_cs,
    ma_vat_tu_cs,
    t_bntt,
    t_bhtt,
    ma_pttt,
    ma_giuong,
    t_bncct,
    muc_huong,
    goi_vtyt,
    pham_vi,
    tt_thau,
    ten_vat_tu,
    t_trantt
  )
  VALUES
  (
    v_ma_lk,
    tmpInt,
    tmpRec.madichvu,
    tmpRec.mavattu,
    tmpRec.manhom,
    tmpRec.tendv,
    tmpRec.donvi,
    tmpRec.soluong,
    tmpRec.dongia,
    tmpRec.tyle_tt,
    tmpRec.thanhtien,
    tmpRec.deptid,
    tmpRec.bacsychidinh,
    tmpRec.MA_BENH,
    tmpRec.ngay_yl,
    tmpRec.ngay_kq,
    'Y',
    tmpRec.ten_khoabv,
    tmpRec.don_gia_bv,
    tmpRec.t_nguonkhac,
    tmpRec.ma_dich_vu_cs,
    tmpRec.ma_vat_tu_cs,
    tmpRec.t_bntt,
    tmpRec.t_bhtt,
    tmpRec.ma_pttt,
    NULL,
    tmpRec.t_bncct,
    tmpRec.muc_huong,
    tmpRec.goi_vtyt,
    tmpRec.pham_vi,
    tmpRec.tt_thau,
    tmpRec.tenvt,
    tmpRec.t_trantt
  );
END LOOP;
-- UPDATE LAI mã bệnh kèm theo trong trường hợp bệnh nhân khám  2 phòng trở lên mà mã bệnh kèm ko có
IF(v_TypePatient='E' AND 0=1) THEN
	v_benhkem = bh_update_benhkem(docno,v_icd, v_benhkem);
	Update bh_thongtinchitiet_tonghop SET ma_benhkhac= v_benhkem;
END IF;

-- UPDATE LAI TIEN NONG TRONG CHI TIET TONG HOP
tmp_t_thuoc :=0;
tmp_t_dvkt  :=0;
tmp_t_vtyt  :=0;
tmp_bhtt    :=0;
tmp_bntt    :=0;
tmp_bhtt1:=0;
tmp_bhtt2:=0;
tmp_bncct:=0;
tmp_bncct1:=0;
tmp_bncct2:=0;
tmp_nguon_khac:=0;

--SELECT coalesce( sum(thanh_tien),0) INTO tmp_tong_chi from bh_view  where ma_lk=v_ma_lk;
-- tmp_tong_chi= round(tmp_tong_chi,0);
-- SELECT coalesce(sum(thanh_tien),0) INTO tmp_bhtt1 from bh_view    where ma_lk=v_ma_lk and ma_nhom<>'12';
-- SELECT coalesce(sum(thanh_tien),0) INTO tmp_bhtt2 from bh_view    where ma_lk=v_ma_lk and ma_nhom='12';
-- tmp_bhtt= round(((tmp_bhtt1/100)*tmpPercent + tmp_bhtt2),0);
-- tmp_bntt=tmp_tong_chi-tmp_bhtt;

SELECT coalesce(sum(thanh_tien),0) INTO tmp_tong_chi from bh_view    where ma_lk=v_ma_lk;
SELECT coalesce(sum(t_bhtt),0) INTO tmp_bhtt from bh_view    where ma_lk=v_ma_lk;
SELECT coalesce(sum(t_bncct),0) INTO tmp_bncct from bh_view    where ma_lk=v_ma_lk;
SELECT coalesce(sum(t_bntt),0) INTO tmp_bntt from bh_view    where ma_lk=v_ma_lk;
SELECT coalesce(sum(t_nguon_khac),0) INTO tmp_nguon_khac from bh_view    where ma_lk=v_ma_lk;

SELECT coalesce( sum(thanh_tien),0) INTO tmp_t_thuoc from bh_bang_ctthuoc  where ma_lk=v_ma_lk;
SELECT coalesce(sum(thanh_tien),0) INTO tmp_t_vtyt from bh_bang_ctdv where ma_lk=v_ma_lk and ma_nhom in ('10','11');


UPDATE bh_thongtinchitiet_tonghop
SET t_tongchi =tmp_tong_chi,
  t_bhtt      = tmp_bhtt,
  t_bncct      = tmp_bncct,
  t_bntt      = tmp_bntt,
  t_thuoc     = tmp_t_thuoc,
  t_vtyt      = tmp_t_vtyt
WHERE ma_lk   =v_ma_lk;

-- Tinh lai tien ngoai dinh xuat

    update bh_bang_ctdv set t_ngoaids =0 where ma_lk=v_ma_lk;
       tmp_t_ndx:=0;
      tmp_t_ndxTNT :=0;
      tmp_t_ndxVT :=0;
 --- ma khoa TNT
      v_deptTNT:='TNT';
      select sd_insuranceid INTO v_deptTNT from sys_dept where sd_id=v_deptTNT;
-- phi van chuyen
      update bh_bang_ctdv  set t_ngoaids =t_bhtt where ma_lk=v_ma_lk and ma_nhom='12';
  -- khoa TNT thiet lap ma khoa di nhe  
      update bh_bang_ctdv set t_ngoaids =t_bhtt where ma_lk=v_ma_lk and ma_khoa= v_deptTNT;
      update bh_bang_ctthuoc set t_ngoaids =t_bhtt where ma_lk=v_ma_lk and ma_khoa= v_deptTNT;
 -- tinh theo benh ung thu      
	if(get_ngoaidinhsuat(cast(v_ma_lk as integer)) =1 ) THEN
		update bh_bang_ctdv set t_ngoaids =t_bhtt where ma_lk=v_ma_lk;
		update bh_bang_ctthuoc set t_ngoaids =t_bhtt where ma_lk=v_ma_lk;

	END IF;


	select coalesce(sum(t_ngoaids),0) INTO tmp_t_ndx from bh_view where ma_lk=v_ma_lk;
	if(tmp_t_ndx>0) THEN
		update bh_thongtinchitiet_tonghop set t_ngoaids= tmp_t_ndx where ma_lk= v_ma_lk;

	END IF;	
     
	

----- CHI TIET KET QUA CLS -----
SELECT COUNT(*)
FROM bh_bang_ct_cls
WHERE ma_lk=v_ma_lk
INTO tmpInt;
--raise notice '%', tmpInt;
IF(tmpInt >0) THEN
  DELETE FROM bh_bang_ct_cls WHERE ma_lk=v_ma_lk;
END IF;
--
tmpInt := 0;
--
FOR tmpRec IN
SELECT TO_CHAR(pcmso_docno,'FM99999999') AS MA_LK,
  1                                      AS stt,
  CASE
    WHEN hfl_subitem = 'Y'
    THEN pcmsol_itemid
    ELSE
      CASE
        WHEN LENGTH(hfl_subitem) <> 0
        THEN hfl_subitem
        ELSE hfl_feeid
      END
  END       AS MA_DICHVU,
  hfl_feeid AS MA_CHISO,
  hfl_name  AS TEN_CHISO,
  CASE
    WHEN (SELECT COUNT(*) FROM hms_pacs_layout WHERE hpl_id=pcmsol_result) >0
    THEN NULL
    ELSE pcmsol_result
  END AS GIA_TRI,
  ' ' AS MA_MAY,
  (SELECT hpr_desc
  FROM hms_pacs_result
  WHERE hpr_orderid=pcmsol_orderid
  AND hpr_name     ='1' limit 1
  ) AS MO_TA,
  (SELECT hpr_desc
  FROM hms_pacs_result
  WHERE hpr_orderid=pcmsol_orderid
  AND hpr_name     ='Conclusion' limit 1
  )                                           AS KET_LUAN,
  TO_CHAR(pcmso_performdate,'YYYYMMDDHH24MI') AS NGAY_KQ
FROM pcms_order
LEFT JOIN pcms_order_line
ON (pcmsol_orderid=pcmso_orderid)
LEFT JOIN hms_feelist
ON (hfl_feeid              =pcmsol_itemid)
WHERE pcmso_docno          =docno --and hfe_discount >0
AND pcmso_status           ='T'
AND LENGTH(trim(hfl_name)) > 0
ORDER BY hfl_groupid,
  pcmso_orderdate LOOP tmpInt := tmpInt+1;
INSERT
INTO bh_bang_ct_cls
  (
    ma_lk,
    stt,
    ma_dich_vu,
    ma_chi_so,
    ten_chi_so,
    gia_tri,
    ma_may,
    mo_ta,
    ket_luan,
    ngay_kq,
    trangthaigui
  )
  VALUES
  (
    v_ma_lk,
    tmpInt,
    tmpRec.MA_DICHVU,
    tmpRec.MA_CHISO,
    tmpRec.TEN_CHISO,
    tmpRec.GIA_TRI,
    tmpRec.MA_MAY,
    tmpRec.MO_TA,
    tmpRec.KET_LUAN,
    tmpRec.NGAY_KQ,
    'Y'
  );
END LOOP;
--- ------------------------------DIEN BIEN BENH -------------------------------------
SELECT COUNT(*)
FROM bh_bang_dienbienbenh
WHERE ma_lk=v_ma_lk
INTO tmpInt;
--raise notice '%', tmpInt;
IF(tmpInt >0) THEN
  DELETE FROM bh_bang_dienbienbenh WHERE ma_lk=v_ma_lk;
END IF;
--
tmpInt := 0;
--

FOR tmpRec IN
SELECT TO_CHAR(he_patientno,'FM99999999')
  ||TO_CHAR(he_docno,'FM99999999') AS ma_lk,
  1                                AS stt,
  CASE
    WHEN LENGTH(he_examine) > 0
    THEN he_examine
    WHEN LENGTH(he_prediagnostic) >0
    THEN he_prediagnostic
    WHEN LENGTH(he_diagnostic) >0
    THEN he_diagnostic
    ELSE hd_diagnostic
  END                                   AS DIEN_BIEN,
  ' '                                   AS HOI_CHAN,
  hfl_name                              AS PHAUTHUAT,
  TO_CHAR(he_examdate,'YYYYMMDDHH24MI') AS NGAY_YL
FROM hms_exam
LEFT JOIN hms_doc
ON (hd_docno=he_docno)
LEFT JOIN hms_operation
ON (ho_docno  = he_docno
AND ho_roomid =he_roomid
AND ho_pdeptid='KB')
LEFT JOIN hms_feelist
ON (hfl_feeid = ho_itemid)
WHERE he_docno=docno
UNION ALL
SELECT TO_CHAR(hsie_patientno,'FM99999999')
  ||TO_CHAR(hsie_docno,'FM99999999')  AS MA_LK,
  1                                   AS stt,
  hsie_desc                           AS DIEN_BIEN,
  ' '                                 AS HOI_CHAN,
  hfl_name                            AS PHAUTHUAT,
  TO_CHAR(hsie_date,'YYYYMMDDHH24MI') AS NGAY_YL
FROM hms_siexam
LEFT JOIN hms_operation
ON (ho_docno            =hsie_docno
AND DATE(ho_performdate)=DATE(hsie_date))
LEFT JOIN hms_feelist
ON (hfl_feeid    =ho_itemid)
WHERE hsie_docno =docno LOOP tmpInt := tmpInt+1;
/*
INSERT
INTO bh_bang_dienbienbenh
(
ma_lk,
stt,
dien_bien,
hoi_chan,
phau_thuat,
ngay_yl,
trangthaigui
)
VALUES
(
v_ma_lk,
tmpInt,
tmpRec.DIEN_BIEN,
tmpRec.HOI_CHAN,
tmpRec.PHAUTHUAT,
tmpRec.NGAY_YL,
'Y'
);
*/
END LOOP;
--raise notice 'vao den day 000';

if (t_ly_do_vao_vien = '3') then
 --SELECT sum(t_bntt) from bh_bang_ctthuoc where ma_lk = v_ma_lk;
 UPDATE bh_bang_ctthuoc set t_bntt = t_bncct where ma_lk = v_ma_lk;
 UPDATE bh_bang_ctthuoc set t_bncct ='0' where ma_lk = v_ma_lk;
 --SELECT * from bh_thongtinchitiet_tonghop where ma_lk = v_ma_lk;
 UPDATE bh_thongtinchitiet_tonghop  set t_bntt = t_bncct where ma_lk = v_ma_lk;
 UPDATE bh_thongtinchitiet_tonghop  set t_bncct ='0' where ma_lk = v_ma_lk;
 --SELECT sum(t_bntt) from bh_bang_ctdv where ma_lk = v_ma_lk;
 UPDATE bh_bang_ctdv  set t_bntt = t_bncct where ma_lk = v_ma_lk;
 UPDATE bh_bang_ctdv set t_bncct ='0' where ma_lk = v_ma_lk;
end if;
RETURN 1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION bh_checkout_4210(integer)
  OWNER TO vimes;
