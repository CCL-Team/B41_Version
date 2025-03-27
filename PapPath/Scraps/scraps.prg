select cmd.*
  from cust_mpage_data cmd,
       code_value cv
   where cv.code_set    = 100705
     and cv.cdf_meaning in ("OBGYNLOCDD", "OBGYNHRLOCDD")
     and cv.active_ind  = 1
  
     and cmd.prsnl_id = 24117701.00
     and cmd.data_cd  = cv.code_value
order by cmd.prsnl_id, cv.cdf_meaning
with nocounter go


OBGYNFILT
OBGYNHRFILT

select cmd.*
  from cust_mpage_data cmd,
       code_value cv
   where cv.code_set    = 100705
     and cv.cdf_meaning in ("OBGYNFILT", "OBGYNHRFILT")
     and cv.active_ind  = 1
  
     ;and cmd.prsnl_id = mpage_data->prsnl_id
     and cmd.data_cd  = cv.code_value
order by cmd.prsnl_id, cv.cdf_meaning
with nocounter go


delete from cust_mpage_data where cust_mpage_data_id in (39471.00.00) go



set trace rdbbind go
set trace rdbdebug go
cust_mp_high_risk_obgyn_test ^MINE^,value(3991888997),2 go

Case 1                                :  0 Days 00:00:18
Case 2                                :  0 Days 00:00:32
Case 3 First                          :  0 Days 00:00:01
Case 3 Second                         :  0 Days 00:00:28
Case 3 Colo Check                     :  0 Days 00:00:02
Case 4                                :  0 Days 00:00:07
Looper                                :  0 Days 00:00:00
Gather patient information            :  0 Days 00:00:01
Gather OBGYN Person level             :  0 Days 00:00:00
Gather OBGYN Encounter level          :  0 Days 00:00:00
Gather Prev Appointment information   :  0 Days 00:00:04
Gather Next Appointment information   :  0 Days 00:00:00
Gather Previous Comments and Due Dates:  0 Days 00:00:00
Gather Additional order information   :  0 Days 00:00:01
Cerv Cyto High Risk                   :  0 Days 00:01:35


set debug_ind =1 go
cust_obgyn_providers_test 'MINE' go


set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
mp_get_obgyn_pats_test ^MINE^,value(6186675),^01-Aug-2024 00:00:00^,^31-Aug-2024 23:59:99^,value(0) go



set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
cust_mp_high_risk_obgyn_test ^MINE^,value(6186675),1 go

set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
cust_mp_high_risk_obgyn_test ^MINE^,value(6186675),1,value(0),'','' GO

set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
cust_mp_high_risk_obgyn_test ^MINE^,value(6186675),1,value(5126325,1368495),'','' go


set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
cust_mp_high_risk_obgyn_test ^MINE^,value(6186675),1,value(1368495),'','' go



; case 1 HPV positive, no repeat HPV testing or cytology within 1 year
; case 2 HPV positive AND cytology shows ASCUS-H, LGSIL, HGSIL AND AGUS no follow up appointment or referral to GYN
; case 3 Needs Colposcopy
; case 4 Tissue Pathology Outstanding.



set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
cust_mp_high_risk_obgyn_test ^MINE^,value(6186675),1,value(1368495),'01-SEP-2024 00:00:00','30-SEP-2024 23:59:99' go



set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
cust_mp_amb_orgs 'MINE' go



set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
cust_mp_hr_obgyn_comment_test ^MINE^,16464238,77917886,^Testing^,^06-Sep-2024^ go




select sa.person_id
     , sa.sch_appt_id
     , sort = if(per.position_cd in (915338723, 2229780007, 1842502051)) 0
              else                                                       1
              endif
     , sa.beg_dt_tm
       
  from sch_appt  sa
     , sch_event se
     , person    p
     , sch_appt  ap
     , prsnl     per
  plan sa
   where sa.person_id                  =  1610110.0
     and sa.sch_role_cd                =  4572.000000                                 ;TODO codify?
     and sa.sch_state_cd               not in (4535.00, 4540.00) ;canceled deleted    ;TODO codify?
     and sa.beg_dt_tm                  >= cnvtdatetime(curdate, curtime3)
     and sa.schedule_seq               =  (select max(sa2.schedule_seq)
                                             from sch_appt sa2
                                            where sa2.sch_event_id = sa.sch_event_id
                                          )

  join se
   where se.sch_event_id              =  sa.sch_event_id
  
  join p
   where p.person_id                  =  sa.person_id
  
  join ap
   where ap.sch_event_id              =  sa.sch_event_id
     and ap.sch_role_cd               =  4574.000000  ;TODO codify?
   
  join per
   where per.person_id                =  ap.person_id
order by sa.person_id, sort, sa.beg_dt_tm

with nocounter, format(date,';;q'), uar_code(D) go

set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
cust_mp_high_risk_obgyn_test ^MINE^,value(6186675),1,value(0),'','' go

set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
cust_mp_high_risk_obgyn_test ^MINE^,value(0.0),1,value(1368495),'01-DEC-2024 00:00:00','31-DEC-2024 23:59:99' go

cust_mp_br_health_coord_driver 'MINE'




set debug_ind =1 go
set trace rdbbind go
set trace rdbdebug go
cust_mp_high_risk_obgyn_test ^MINE^,value(6186675.0),3,value(0.0),'','' go


Family Medicine at Fort Lincoln
Medstar Franklin Square Family Health Center



Current repo version needs marked for potential future reversion.


Case 1                                :  0 Days 00:00:33
Case 2                                :  0 Days 00:00:04
Case 3 First                          :  0 Days 00:00:02
Case 3 Second                         :  0 Days 00:11:54
Case 3 Colo Check                     :  0 Days 00:00:01
Case 4                                :  0 Days 00:00:08
Looper                                :  0 Days 00:00:00
Gather patient information            :  0 Days 00:00:02
Gather OBGYN Person level             :  0 Days 00:00:00
Gather OBGYN Encounter level          :  0 Days 00:00:01
Gather Prev Appointment information   :  0 Days 00:00:13
Gather Next Appointment information   :  0 Days 00:00:00
Gather Previous Comments and Due Dates:  0 Days 00:00:01
Gather Additional order information   :  0 Days 00:00:02
Cerv Cyto High Risk                   :  0 Days 00:14:00



select sq.child_number, sq.sql_id, sq.* from v$sql sq where sq.sql_text = '*mmm174*' go

rdb SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR(('3sus17u3p3d6x'),0,'ALLSTATS')) go
