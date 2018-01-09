select htr_tdeptid,sys_dept.sd_name, count(htr_docno)
from hms_treatment_record left join sys_dept on  htr_tdeptid=sys_dept.sd_id
where  htr_deptid ='CC' and htr_admitdate>='2017-10-01' and htr_admitdate<'2018-01-01' and htr_idx=1 and htr_suggestion='M'
group by htr_tdeptid,sys_dept.sd_name
order by count(htr_docno) desc

select * from hms_exam where he_roomid=39
select * from hms_doc where hms_doc.hd_docno=18003857


he_docno=18003857 