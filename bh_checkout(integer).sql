-- Function: bh_checkout(integer)

-- DROP FUNCTION bh_checkout(integer);

CREATE OR REPLACE FUNCTION bh_checkout(docno integer)
  RETURNS integer AS
$BODY$
  DECLARE
    v_ma_lk TEXT;
    tmpInt INTEGER;
    tmpPercent INTEGER;
    tmpRec RECORD;
    xRec RECORD;
    m_doctor VARCHAR(20);
    v_TypePatient TEXT;
    v_mabv VARCHAR(15);
    v_Object varchar(1);
    v_statusDoc varchar(1);
    v_insline varchar(1);
    v_insoffline integer;
  BEGIN
    --
    --
    -- lay tham so trai tuyen duoc huong bao nhieu phan tram
    SELECT hms_insoffline INTO v_insoffline from hms_config  ;
    SELECT sc_id INTO v_mabv FROM sys_company limit 1;
    ---          LAY MA LIEN KET---
    --select  bh_checkout(17006863);
    
    SELECT TO_CHAR(hd_docno,'FM99999999') AS MA_LK,
      CASE
        WHEN hd_status     ='T'
        AND hd_suggestion ='A' and hd_outpatient <>'Y'
        THEN 'I'
        WHEN   hd_suggestion ='A' and hd_outpatient ='Y' THEN 'O'
        ELSE 'E'
      END AS TypePatient,
      ho_type as Objecttype
    FROM hms_doc
    LEFT JOIN hms_object ON (hd_object =ho_id)
    WHERE hd_docno=docno
    INTO v_ma_lk,
      v_TypePatient,
      v_Object;
   --  raise notice '%,%',v_TypePatient,v_ma_lk;

      IF(v_Object not in ('I','C')) THEN
		RETURN 20;
	END IF;
    IF(v_TypePatient IN ('I','O')) THEN
		SELECT hcr_status INTO v_statusDoc from hms_clinical_record where hcr_docno=docno;
		IF(v_statusDoc <> 'T') THEN
			return 30;
		END IF;
	END IF; 
  
     IF(v_TypePatient IN ('E')) THEN
	SELECT * INTO tmpRec from hms_doc where hd_docno=docno;
	IF(tmpRec.hd_status <> 'T') THEN
		return 31;
	END IF;
	v_insline:= tmpRec.hd_insline;
	IF(tmpRec.hd_insline='Y') THEN
		return 32;
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
		case
			when hcr_result in ('1') or hd_result in ('1') then 1
			when hcr_result in ('2') or hd_result in ('2') then 2
			when hcr_result in ('3') or hcr_result in ('3') then 3
			when hcr_result in ('4') or hcr_result in ('4') then 4
			when hcr_result in ('5', '6') or hd_result in ('5', '6') then 5
			else 2
			end  as ketqua, 
		case
			when hcr_suggestion = 'T' or hd_suggestion = 'T' then 2
			when hcr_result in ('8') or hd_result in ('8') then 3
			when hcr_result in ('7') or hd_result in ('7') then 4
			when hcr_result in ('1', '2', '3', '4', '5', '6') or hd_result in ('1', '2', '3', '4', '5', '6') then 1
			else 1
			end  as tinhtrang,
		CASE
		  WHEN hd_suggestion <>'A'
		  THEN hd_icd
		  ELSE hcr_mainicd
		END AS CHANDOAN,
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
	      WHERE hd_docno  = docno
	LOOP
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
    SELECT
      hd_docno                         AS docno1,
      hhtd_numbertrans                 AS sochuyentuyen,
      case when hd_suggestion ='T' then hd_tohosid
	else hcr_hospitalid
      end  AS mabvchuyendi,
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
      END                                       AS chandoan,
      hhtd_suggestion                           AS ppdieutri,
      -- CAST(hhtd_reason AS INTEGER)  
      hhtd_patstate                             AS tinhtrangbenhnhan,
      1            AS lydochuyentuyen,
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
    AND hhtd_docno  > 0
    LOOP
    
   
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
      SELECT
      hd_transplaceid                  AS mabv,
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
SELECT
  hh_id                            AS mabv,
  CASE
    WHEN hh_type='1'
    THEN 'A'
    WHEN hh_type='2'
    THEN 'B'
    WHEN hh_type='3'
    THEN 'C'
    ELSE NULL
  END                                 AS tuyen,
  to_date(to_char(hd_createddate, 'YYYY/MM/DD'), 'YYYY/MM/DD') as tungay,
  case when hd_suggestion <>'A' 
	then to_date(to_char(hd_enddate, 'YYYY/MM/DD'), 'YYYY/MM/DD') 
	else to_date(to_char(hcr_dischargedate, 'YYYY/MM/DD'), 'YYYY/MM/DD')   end AS denngay
FROM hms_doc
LEFT JOIN hms_clinical_record  ON (hcr_docno=hd_docno)
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
  SELECT 
  hhtd_hospitalid                  AS mabv,
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
SELECT COUNT(*)
FROM bh_thongtinchitiet_tonghop
WHERE ma_lk=v_ma_lk
INTO tmpInt;
IF(tmpInt >0) THEN
  DELETE FROM bh_thongtinchitiet_tonghop WHERE ma_lk=v_ma_lk;
END IF;
--
tmpInt := 0;
--
 IF(v_TypePatient in ('E','O','I')) THEN
	FOR tmpRec IN
		SELECT
		  hd_docno AS ma_bn,
		  trim(hp_surname
		  ||' '
		  ||hp_midname
		  ||' '
		  ||hp_firstname)                  AS ho_ten,
		  CASE 
			WHEN hp_yearofbirth='Y' THEN TO_CHAR(hp_birthdate,'YYYY')
			ELSE TO_CHAR(hp_birthdate,'YYYYMMDD') 
			END AS ngay_sinh,
		  CASE
		    WHEN hp_sex='M'
		    THEN 1
		    ELSE 2
		  END AS gioi_tinh,
		  CASE
		    WHEN LENGTH(hp_workplace)>2
		    THEN hp_workplace
		    WHEN length(hp_dtladdr)>0 THEN
		     hp_dtladdr
		      || ','
		      ||hms_getaddress(hp_provid, hp_distid, hp_villid)
		      ELSE hms_getaddress(hp_provid, hp_distid, hp_villid)
		  END AS dia_chi,
		  CASE
		    WHEN LENGTH(hc_cardno) > 15
		    THEN SUBSTR(hc_cardno,1,15)
		    ELSE hc_cardno
		  END                            AS ma_the,
		  hc_regcode                     AS ma_dkbd,
		  TO_CHAR(hc_regdate,'YYYYMMDD') AS gt_the_tu,
		  TO_CHAR(hc_expdate,'YYYYMMDD') AS gt_the_den,
		  CASE
		    WHEN LENGTH(hcr_mainicd)>1
		    THEN hcr_mainicd
		    ELSE hd_icd
		  END AS ma_benh,
		  hod_diagnostics  AS ma_benhkhac,
		  CASE
		    WHEN hd_suggestion <>'A'
		    THEN hd_diagnostic
		    ELSE hcr_maindisease
		  END AS ten_benh,
		  CASE
		  --h: sua trai tuyen cap cuu
		    WHEN (hd_emergency ='Y') AND (hd_insline='N')
		    THEN 2
		    WHEN hd_insline='Y'
		    THEN 3
		    ELSE 1
		  END           AS ma_lydo_vvien,
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
		    THEN GREATEST(DATE(hcr_dischargedate)-DATE(hcr_admitdate) +1 ,1)
		    ELSE GREATEST(DATE(hd_enddate)       - DATE(hd_createddate) ,1)
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
		  END                         AS tinh_trang_rv,
		  TO_CHAR(ngaytt,'YYYYMMDDHH24MI')  AS ngay_ttoan,
		  CASE WHEN hd_insline ='Y' then CAST((hd_disrate*hc_discount/100) AS INTEGER)
			else cast(hd_disrate as integer) end AS muc_huong,
		  SUM(hfe_inspaid)               AS t_tongchi,
		  SUM(hfe_inspaid) - SUM(hfe_discount)   AS t_bntt,
		  SUM(hfe_discount)           AS t_bhtt ,
		  0                           AS t_nguonkhac,
		  0                           AS t_ngoaids,
		  round(sum(t_thuoc),2) as t_thuoc,
		  round(sum(t_vtyt),2) as t_vtyt,
		  extract(YEAR FROM ngaytt)   AS nam_qt,
		  extract(MONTH FROM ngaytt)  AS thang_qt,
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
		  (select max(he_weight) from hms_exam where he_docno=docno and he_weight <8) as can_nang
		FROM
		  (
		    SELECT
		      (
			SELECT
			  MAX(hfi_recvdate)
			FROM
			  hms_fee_invoice
			WHERE
			  hfi_docno=tbla.hfi_docno and hfi_type='P' and hfi_discount >0
		      ) AS ngaytt,
		      hfi_docno,
		      hfi_deptid,
		      ROUND(hfe_inspaid,2) as hfe_inspaid,
		      ROUND(hfe_cost,2)     AS hfe_cost,
		      ROUND(hfe_patpaid,2)  AS hfe_patpaid,
		      ROUND(hfe_discount,2) AS hfe_discount,
		      case when substring(hfe_group,1,2) not in ('A9','A4') and hfe_type='D' then ROUND(hfe_inspaid,2)  else 0 end as t_thuoc,
			case when substring(hfe_group,1,2) in ('A9','A4') then ROUND(hfe_inspaid,2)  else 0 end as t_vtyt
		    FROM
		      hms_fee_invoice AS tbla
		    LEFT JOIN hmsv_fee_bh
		    ON
		      (
			hfe_invoiceno=hfi_invoiceno
		      AND hfe_docno  =hfi_docno
		      )
		    WHERE
		      hfe_status     ='P'
		    AND hfi_docno    =docno
		    AND hfi_type     ='P'
		    AND hfe_discount > 0
		  ) AS tbl
		LEFT JOIN hms_doc
		ON
		  (
		    hfi_docno=hd_docno
		  )
		LEFT JOIN hms_clinical_record
		ON
		  (
		    hcr_docno=hd_docno
		  )
		LEFT JOIN hms_patient
		ON
		  (
		    hd_patientno=hp_patientno
		  )
		LEFT JOIN hms_card
		ON
		  (
		    hc_patientno=hp_patientno
		  AND hc_idx    =hd_cardidx
		  AND hc_cardno =hd_cardno
		  )
		LEFT JOIN hms_object
		ON
		  (
		    ho_id=hd_object
		  )
		LEFT JOIN sys_dept
		ON
		  (
		    sd_id=hfi_deptid
		  )
		LEFT JOIN hms_accident
		ON
		  (
		    hd_docno =ha_docno
		  )
		  LEFT JOIN hms_other_diagnostic
		  ON 
		  (
			hod_docno=hd_docno
		  )
		GROUP BY
		  ma_bn,
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
		  sd_name,hd_relative,
		  hd_transplaceid,
		  hd_createddate,
		  hc_discount,
		  hod_diagnostics
  LOOP
  --raise notice '%',tmpRec;
  --    tmpRec.T_TONGCHI,
  --    tmpRec.T_BNTT,
   --   tmpRec.T_BHTT;
   tmpPercent:=tmpRec.muc_huong;
   IF(v_insline='Y' and tmpRec.t_tongchi < 195000) THEN
	tmpPercent:= v_insoffline;
   END IF; 
   IF(tmpRec.t_bntt = 0) THEN
	tmpPercent:=100;
   END IF;
  tmpInt := tmpInt+1;
		INSERT INTO bh_thongtinchitiet_tonghop(
			    ma_lk, stt, ho_ten, ngay_sinh, gioi_tinh, dia_chi, ma_the, ma_dkbd, 
			    gt_the_tu, gt_the_den, ma_benh, ma_benhkhac, ten_benh, ma_lydo_vvien, 
			    ma_noi_chuyen, ma_tai_nan, ngay_vao, ngay_ra, so_ngay_dtri, ket_qua_dtri, 
			    tinh_trang_rv, ngay_ttoan, muc_huong, t_tongchi, t_bntt, t_bhtt, 
			    t_nguonkhac, t_ngoaids, nam_qt, thang_qt, ma_loai_kcb, ma_cskcb, 
			    ma_khuvuc, ma_pttt_qt, trangthaigui, so_phieu, ma_bn, ngay_quyettoan, 
			    ma_khoa, ma_khoabv, ten_khoabv, nguoi_lien_he, loai_giayto_dikem, 
			    ten_loai_giayto,t_thuoc,t_vtyt,can_nang,time_process)
		    VALUES (v_ma_lk, tmpInt, tmpRec.ho_ten, tmpRec.ngay_sinh, tmpRec.gioi_tinh, tmpRec.dia_chi, tmpRec.ma_the, tmpRec.ma_dkbd, 
			    tmpRec.gt_the_tu, tmpRec.gt_the_den, tmpRec.ma_benh, tmpRec.ma_benhkhac, tmpRec.ten_benh, tmpRec.ma_lydo_vvien, 
			    tmpRec.ma_noi_chuyen, tmpRec.ma_tai_nan, tmpRec.ngay_vao, tmpRec.ngay_ra, tmpRec.so_ngay_dtri, tmpRec.ket_qua_dtri, 
			    tmpRec.tinh_trang_rv, tmpRec.ngay_ttoan, tmpPercent, tmpRec.t_tongchi, tmpRec.t_bntt, tmpRec.t_bhtt, 
			    tmpRec.t_nguonkhac, tmpRec.t_ngoaids, tmpRec.nam_qt, tmpRec.thang_qt, tmpRec.ma_loai_kcb, v_mabv, 
			    tmpRec.ma_khuvuc, tmpRec.ma_pttt_qt, 'Y', tmpRec.so_phieu, tmpRec.ma_bn, tmpRec.ngay_quyettoan, 
			    tmpRec.ma_khoa, tmpRec.ma_khoabv, tmpRec.ten_khoabv, tmpRec.nguoi_lien_he, tmpRec.loai_giayto_dikem, 
			    tmpRec.ten_loai_giayto,tmpRec.t_thuoc,tmpRec.t_vtyt,tmpRec.can_nang,current_timestamp);
    END LOOP;
  END IF;
    


---------- THONG TIN THUOC CUA BENH NHAN ---------------
SELECT COUNT(*)
FROM bh_bang_ctthuoc
WHERE ma_lk=v_ma_lk
INTO tmpInt;
--raise notice '%', tmpInt;
IF(tmpInt >0) THEN
  DELETE FROM bh_bang_ctthuoc WHERE ma_lk=v_ma_lk;
  FOR xRec IN
	  SELECT hpo_orderid,
	    hpo_deptid,
	    hpo_roomid
	  FROM hms_pharmacyorder
	  WHERE hpo_docno = docno
	  AND hpo_status  ='A'
	  AND hpo_doctor IS NULL 
  LOOP
	  SELECT hb_doctor
	  INTO m_doctor
	  FROM hms_bed
	  WHERE hb_docno = docno
	  AND hb_deptid  = xRec.hpo_deptid
	  AND hb_roomid  = xRec.hpo_roomid;
	  UPDATE hms_pharmacyorder
	  SET hpo_doctor    =m_doctor
	  WHERE hpo_orderid = xRec.hpo_orderid;
END LOOP;
END IF;
--
--tmpInt :
tmpInt := 0;
FOR tmpRec IN
SELECT 
  case when length(pmc_mathuoc)>0 then  pmc_mathuoc
 when length(pmsi_regcode)> 0 then pmsi_regcode
 when length(pmi_regcode) >0 then pmi_regcode
when length(pmi_insuranceid)>0 then pmi_insuranceid
 else pmi_id end                      AS itemid,
  CASE
    WHEN substring(hfe_group,1,2) NOT IN ('A9','A4','A2')
    AND (pmi_insdisrate                 =0 or pmi_insdisrate is null)
    THEN 4
    WHEN substring(hfe_group,1,2) IN ('A2')
    AND (pmi_insdisrate             =0 or pmi_insdisrate is null)
    THEN 7
    WHEN substring(hfe_group,1,2) IN ('A9','A4')
    AND (pmi_insdisrate             =0 or pmi_insdisrate is null)
    THEN 10
    WHEN substring(hfe_group,1,2) NOT IN ('A9','A4','A2')
    AND pmi_insdisrate                 >0
    THEN 6
    WHEN substring(hfe_group,1,2) IN ('A9','A4')
    AND pmi_insdisrate             > 0
    THEN 9
    ELSE NULL
  END         AS ma_nhom,
  case when pmc_tenbietduoc is not null then pmc_tenbietduoc else pmi_name   end AS namedrug,
  hpol_unit   AS unit,
  case when length(pmc_hamluong) >0 then pmc_hamluong
  when length(pmi_content)>0 then pmi_content
  else '' end as hamluong,
   case when length(pmc_maduongdung) >0 then pmc_maduongdung
	when length(pmi_dosage)>0 then pmi_dosage
  else '' end as duongdung,
  case when length(pmc_sodangky) >0 then  pmc_sodangky
	WHEN length(pmsi_regcode) >0 then pmsi_regcode
	when length(pmi_regcode) >0 then pmi_regcode
	else '' end as regcode,

  SUM(hpol_issueqty) AS qty,
   case when pmi_insdisrate >0 then  hfe_insprice*(100/pmi_insdisrate) else hfe_insprice    end AS price,
  CASE
    WHEN pmi_insdisrate >0
    THEN pmi_insdisrate
    ELSE 100
  END AS type_tt,
  CASE
    WHEN pmi_insdisrate >0
     THEN SUM(round(hpol_issueqty*hfe_insprice, 2))
    ELSE SUM(round(hpol_issueqty *hfe_insprice, 2))
  END            AS amout,
  sd_insuranceid AS deptid,
 (select su_certificate from sys_user where su_userid =hpo_doctor)    AS doctor,
  CASE
    WHEN hd_suggestion <>'A'
    THEN hd_icd
    ELSE hcr_mainicd
  END                                      AS mainicd,
  TO_CHAR(hpo_orderdate, 'YYYYMMDDHH24MI') AS orderdate,
  sd_name as ten_khoabv,
  hfe_unitprice     AS don_gia_bv,
  0 as t_nguon_khac,
  hpol_itemid as ma_thuoc_cs,
  sum(round((hfe_inspaid -hfe_discount),2)) as t_bntt,
  sum(round(hfe_discount, 2)) as t_bhtt,
  hpol_usage as lieu_dung,
  1 as ma_pttt
FROM hms_pharmacyorder
LEFT JOIN hms_pharmacyorder_line
ON (hpo_orderid=hpol_orderid)
LEFT JOIN pms_stockitems
ON (pmsi_id=hpol_sitemid)
LEFT JOIN pms_items
ON (pmi_id=hpol_itemid)
LEFT JOIN pms_contractorlist
ON (pmc_id=pmsi_itemid) AND (pmc_uid =pmsi_contractlist_uid OR (pmsi_contractlist_uid=0 AND pmc_uid=(SELECT MIN(pmc_uid) FROM pms_contractorlist WHERE pmc_id=pmsi_itemid)))
LEFT JOIN hms_doc
ON (hd_docno=hpo_docno)
LEFT JOIN hms_clinical_record
ON (hcr_docno=hpo_docno)
LEFT JOIN sys_dept
ON (sd_id        =hpo_deptid)
WHERE hpo_docno  =docno and hpo_type not in ('M','B')  and hpo_status not in ('O','C')
AND hfe_discount >0 and  hfe_invoiceno >0 
and substring(pmi_typeid,1,2) not in ('A9','A4')
GROUP BY hpo_docno,
  orderdate,
  hpo_deptid,
  hpol_itemid,
  hpol_name,
  hfe_group,
  hpol_unit,
  hfe_insprice,
  hpo_patientno,
  hpo_docno,
  regcode,
  hamluong,
  duongdung,
  hpo_doctor,
  hd_suggestion,
  hd_icd,
  hcr_mainicd,
  hd_disrate,
  pmi_insdisrate,
  sd_insuranceid,
   hd_patientno,
  hd_docno,sd_name,hfe_unitprice,hpol_usage,pmc_sodangky,pmsi_regcode,pmi_regcode,pmi_id,pmc_mathuoc,pmi_insuranceid,pmc_tenbietduoc,pmi_name
ORDER BY orderdate,
  hpo_deptid,
  ma_nhom,
  itemid LOOP tmpInt := tmpInt+1;
 --raise notice '%',tmpRec.qty;
 --raise notice '%',tmpRec;
 --select  bh_checkout(16206703);
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
    t_nguon_khac,
    ma_thuoc_cs,
    t_bntt,
    t_bhtt,
    lieu_dung,
    ma_pttt
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
    tmpRec.type_tt,
    tmpRec.amout,
    tmpRec.deptid,
    tmpRec.doctor,
    tmpRec.mainicd,
    tmpRec.orderdate,
    'Y',
    tmpRec.ten_khoabv,
    tmpRec.don_gia_bv,
    tmpRec.t_nguon_khac,
    tmpRec.ma_thuoc_cs,
    tmpRec.t_bntt,
    tmpRec.t_bhtt,
    tmpRec.lieu_dung,
    tmpRec.ma_pttt
  );
 
  
END LOOP;

---  DICH VU KY THUAT VA  VT T  THANH TOAN BHYT----
SELECT COUNT(*)
FROM bh_bang_ctdv
WHERE ma_lk=v_ma_lk
INTO tmpInt;
--raise notice '%', tmpInt;
IF(tmpInt >0) THEN
  DELETE FROM bh_bang_ctdv WHERE ma_lk=v_ma_lk;
END IF;
--
tmpInt := 0;
FOR tmpRec IN
SELECT 
  case when substring(hfe_group,1,2) in ('A9','A4')  then null
  when hfe_hastranfer='Y' and hfe_group ='F0000' then hms_feelist.hfl_regcode
  when length(hfe_regcode) > 0 then hfe_regcode 
  when length(hfl_insuranceid) >0 then hfl_insuranceid   
  else hfe_itemid end    AS madichvu,
  case when  substring(hfe_group,1,2) not in ('A9','A4') then  null
		when  substring(hfe_group,1,2) in ('A9','A4') and length(pmc_mathuoc)>0  then  pmc_mathuoc 		
		else hfe_itemid end  AS mavattu,
  case 	when substring(hfe_group,1,2) in ('A9','A4') then '10' 
	when substring(hfe_group,1,2)='B1' then '1'
	when substring(hfe_group,1,2)='B2' and substring(hfe_group,1,3) not in ('B24','B25') then '2'
	when substring(hfe_group,1,2)='B3' or substring(hfe_group,1,3)  in ('B24','B25') then '3'
	when (hfe_type='E' ) then '13'
	when (hfe_regcode IN ('11.1900','05.1900','04.1900','14.1900','10.1900','03.1900','02.1900','07.1900','13.1900','17.1900','16.1900','15.1900','06.1900','12.1900','08.1900','11.1896','05.1896','04.1896','14.1896','10.1896','03.1896','02.1896','07.1896','13.1896','17.1896','16.1896','15.1896','06.1896','12.1896','08.1896')) then '13'
	when substring(hfe_group,1,2) in ('B4','B5') then '8'	
	when hfe_hastranfer='Y' and hfe_group ='F0000' then '12'
	when hfe_group='C0000' or hfe_type='B' then '15'
	else null end as manhom,
  case when length(pmc_tenbietduoc)>0 then pmc_tenbietduoc 
	when length(hfl_name2)>0 then hfl_name2 	
	else hfe_desc end          AS tendv,
  CASE
    WHEN hfe_type = 'B'
    THEN 'Ngày'
    ELSE hfl_unit
  END                         AS donvi,
  hfe_qty                    AS soluong,
  --(hfe_inspaid/hfe_insprice)                    AS soluong,
  hfe_insprice                AS dongia,
 --case when hfe_type='D' then 0 else 100 end      AS tyle_tt,
 case when hfe_type='D' then 100 else 100 end      AS tyle_tt,
  round(hfe_inspaid, 2) AS thanhtien,
  sd_insuranceid              AS deptid,
  (select su_certificate from sys_user where su_userid =hfe_doctor )  AS bacsychidinh,
  CASE
    WHEN hd_suggestion <>'A'
    THEN hd_icd
    ELSE hcr_mainicd
  END                                     AS MA_BENH,
  TO_CHAR(hfe_entrydate,'YYYYMMDDHH24MI') AS ngay_yl,
  case when hfe_pdate='1752-09-14 00:00:00' then  TO_CHAR(hfe_entrydate,'YYYYMMDDHH24MI')
 else TO_CHAR(hfe_pdate,'YYYYMMDDHH24MI')  end    AS ngay_kq,
    sd_name as ten_khoabv,
  hfe_unitprice     AS don_gia_bv,
  0 as t_nguon_khac,
    CASE
    WHEN hfe_type = 'B'
    THEN hfe_deptid
      ||'.'
      ||hfe_roomid
      ||'.'
      ||hfe_idx
    ELSE hfl_feeid
  END    as ma_dich_vu_cs,
    case when substring(hfe_group,1,2) in ('A9','A4')  then hfe_itemid else null end   as ma_vat_tu_cs,
  sum(round((hfe_inspaid -hfe_discount),2)) as t_bntt,
  sum(round(hfe_discount,2)) as t_bhtt,
  1 as ma_pttt
FROM  hmsv_fee_bh
LEFT JOIN (SELECT DISTINCT ON (pmc_id) * FROM  pms_contractorlist) AS pms_contractorlist2 ON (pmc_id=hfe_itemid)
LEFT JOIN hms_feelist
ON (hfl_feeid=hfe_itemid)
LEFT JOIN hms_doc
ON (hfe_docno=hd_docno)
LEFT JOIN hms_clinical_record
ON (hcr_docno=hfe_docno)
LEFT JOIN sys_dept
ON (hfe_deptid    =sd_id)
WHERE hfe_docno   =docno AND hfe_inspaid >0
AND hfe_invoiceno >0 
AND hfe_discount >0
AND (hfe_type NOT IN ('D') OR substr(hfe_group,1,2) in ('A9','A4') )
GROUP BY hfe_type,hfe_deptid,hfe_roomid,hfe_idx,hfl_feeid,
hfe_group,hfe_itemid,hfe_hastranfer,hfe_desc,hfe_qty,hfe_insprice,
sd_insuranceid,hfe_doctor,hd_suggestion,hd_icd,hcr_mainicd,hfe_entrydate,hfe_pdate,
sd_name,hfe_unitprice,hfl_unit,hfe_regcode,pmc_mathuoc,hfe_itemid,hfl_insuranceid,hfe_inspaid,pmc_tenbietduoc
ORDER BY hfe_deptid,
  manhom,
  hfe_entrydate 
  LOOP 
	
	 tmpInt := tmpInt+1;	 
	 --H:Sai đơn giá, số lượng
	 IF tmpRec.thanhtien<>tmpRec.soluong*tmpRec.dongia
	 THEN
		raise notice '%', tmpRec.thanhtien;
		raise notice '%', tmpRec.soluong;
		raise notice '%', tmpRec.dongia;
		IF tmpRec.thanhtien%tmpRec.dongia =0 THEN tmpRec.soluong=tmpRec.thanhtien/tmpRec.dongia;
			ELSE IF tmpRec.thanhtien%tmpRec.soluong =0 THEN tmpRec.dongia=tmpRec.thanhtien/tmpRec.soluong;
			ELSE IF tmpRec.thanhtien%(tmpRec.dongia*0.5) =0 THEN tmpRec.soluong=tmpRec.thanhtien/tmpRec.dongia; END IF;
			END IF;
		END IF;
	 END IF;	
	--H:Khám nhiều phòng khám
	 IF tmpRec.manhom='13' AND tmpRec.dongia=11700 
	 THEN 
		tmpRec.manhom:='13'; 
		tmpRec.dongia=39000;
		tmpRec.tyle_tt=30;		
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
		    t_nguon_khac,
		    ma_dich_vu_cs,
		    ma_vat_tu_cs,
		    t_bntt,
		    t_bhtt,
		    ma_pttt
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
		    tmpRec.t_nguon_khac,
		    tmpRec.ma_dich_vu_cs,
		    tmpRec.ma_vat_tu_cs,
		    tmpRec.t_bntt,
		    tmpRec.t_bhtt,
		    tmpRec.ma_pttt
		  );

END LOOP;
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
  1                                   AS stt,
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
ON (hfl_feeid    =pcmsol_itemid)
WHERE pcmso_docno=docno --and hfe_discount >0
   AND pcmso_status ='T'
AND LENGTH(trim(hfl_name)) > 0
ORDER BY hfl_groupid,
  pcmso_orderdate LOOP tmpInt := tmpInt+1;  

raise notice '%',    tmpInt ;

--SELECT bh_checkout(17006863);
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
    'N'
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
	||TO_CHAR(he_docno,'FM99999999')  AS ma_lk,
	1                                   AS stt,
	case when length(he_examine) > 0 then  he_examine 
	 when length(he_prediagnostic) >0  then he_prediagnostic 
	 when length(he_diagnostic) >0  then he_diagnostic       
	 else hd_diagnostic  end   AS DIEN_BIEN,
	' '                                 AS HOI_CHAN,
	hfl_name                            AS PHAUTHUAT,
	TO_CHAR(he_examdate,'YYYYMMDDHH24MI') AS NGAY_YL
  FROM hms_exam
  LEFT JOIN hms_doc ON (hd_docno=he_docno)
  LEFT JOIN hms_operation ON (ho_docno = he_docno AND ho_roomid=he_roomid AND ho_pdeptid='KB')
  LEFT JOIN hms_feelist ON (hfl_feeid  = ho_itemid)
  WHERE  he_docno=docno
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
ON (hfl_feeid                   =ho_itemid)
WHERE hsie_docno                =docno
 LOOP tmpInt := tmpInt+1;
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
    'N'
  );
END LOOP;


--UPDATE NGAY Y LENH 
UPDATE bh_bang_ctthuoc
SET ngay_yl=bh_thongtinchitiet_tonghop.ngay_ra
FROM bh_thongtinchitiet_tonghop
WHERE bh_bang_ctthuoc.ngay_yl >bh_thongtinchitiet_tonghop.ngay_ra AND bh_bang_ctthuoc.ma_lk=bh_thongtinchitiet_tonghop.ma_lk AND bh_bang_ctthuoc.ma_lk=docno::text;
UPDATE bh_bang_ctdv
SET ngay_yl=bh_thongtinchitiet_tonghop.ngay_ra 
FROM bh_thongtinchitiet_tonghop
WHERE bh_bang_ctdv.ngay_yl >bh_thongtinchitiet_tonghop.ngay_ra AND bh_bang_ctdv.ma_lk=bh_thongtinchitiet_tonghop.ma_lk AND bh_bang_ctdv.ma_lk=docno::text;
--UPDATE ngay_kq>now
UPDATE bh_bang_ctdv SET ngay_kq =ngay_yl WHERE ngay_kq> TO_CHAR(NOW(),'YYYYMMDDHH24MI') AND ma_lk=docno::text;
--END


RETURN 1;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION bh_checkout(integer)
  OWNER TO vimes;
