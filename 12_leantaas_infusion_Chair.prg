drop program 12_leantaas_infusion_Chair:dba go
create program 12_leantaas_infusion_Chair:dba

prompt
        "Output to File/Printer/MINE" = "MINE"
        , "Full" = "0"
 
with OUTDEV, Full

declare datename1 = vc
SET datename1 = format (cnvtdatetime (curdate ,curtime ) ,"yyyymmdd;;d" )
declare filename  = vc
declare file = vc
/*
	[ A ]	B
1	2184546405.00	MedStar BMT Infusion at MGUH
2	2182779655.00	MedStar Hem Onc and Inf at MFSCCLR
3	2183960659.00	MedStar Hem Onc and Inf at MSMH
4	2182278381.00	MedStar Hem Onc and Inf at MSMHC
5	2183731625.00	MedStar Infusion at MBel Air
6	2183700221.00	MedStar Infusion at MFSH
7	2184449263.00	MedStar Infusion at MGUH Pediatric
8	2182748905.00	MedStar Infusion at MWHC
9	1627301475.00	MedStar Infusion Center at MMMC
10	2184482593.00	MedStar Infusion at GUH Research
11	2182719209.00	MedStar Onc Specialty Center at MWHC
12	2777828531.00	MedStar Ctr for Successful Aging at
13	1183584707.00	MGUH Infusion Center at Tenleytown
14	2184803191.00	MedStar Infusion at MGUH Adult



*/
/*===============================================================================================================
start timer logic
===============================================================================================================*/
declare timerfilename = vc set timerfilename="ccluserdir:leantaas_timer.txt"
;no constant in case timer called recursively
call echo(build("Timer File name: ", timerfilename))
declare outmsg = vc with protect, noconstant("")
declare log_time((msg = vc))= vc with copy
subroutine log_time(msg)
  set section_timer->counter = section_timer->counter + 1
  set stat = alterlist(section_timer->list, section_timer->counter)
  set section_timer->list[section_timer->counter].section = msg
  set section_timer->list[section_timer->counter].time = format(cnvtdatetime(curdate,curtime3), "@SHORTDATETIME")
  call echo(msg)
  ;Attempt to log out the data:
  if (section_timer->counter > 0)
    select into value(timerfilename)
    from (dummyt d1 with seq = value(section_timer->counter))
    plan d1
    order by d1.seq
    detail
      outmsg = substring(1,950,section_timer->list[d1.seq].section)
      ,section_timer->list[d1.seq].time,col 20,outmsg, row + 1 ;writes everything
      ;cnvtstring(section_timer->list[d1.seq].qualifiers),row + 1;if logging out qualifiers is needed
      "----------------------------------", row + 1
    with nocounter, maxcol = 1000
  endif
return(msg)end;subroutine

;Timer Record structure
free record section_timer
record section_timer (
  1 counter = i4
  1 list[*]
    2 section     = vc
    2 time        = vc
   ;2 qualifiers  = i4
)
declare log = vc
set log = log_time("Start")
/*===============================================================================================================
End timer logic
===============================================================================================================*/

record order_qual (
  1 qual_knt = i4
  1 qual[*]
          2 encntr_id = f8
          2 order_mnemonic = vc
          2 ordering_provider = vc
          2 order_status = vc
          2 last_updt_dt_Tm = dq8
          2 ordered_dt_Tm = dq8
          2 display_line = vc
          2 dept_status = vc
          2 catalog_type = vc
          )

;for treatment plan, we need
record appointments (
                 1 qual_knt = i4
                 1 qual [*]
                        2 sch_event_id = f8
 						2 person_id = f8
 						2 person_name = vc
 						2 encntr_id = f8
 						2 beg_dt_tm = dq8
 						2 end_dt_tm = dq8
                        2 appoinment_name  = vc
                        2 med_start = dq8
                        2 med_stop = dq8
                        2 med_name = vc
                        2 day_beg = dq8
                        2 day_end = dq8
                        2 resource = vc
                        2 location = vc
                        2 state_meaning = vc
                        2 bucket = vc
                        2 vitals_time = dq8
 					  )
 
record apts (
                1 qual_knt = i4
                1 qual [*]
                      2 apt_id = f8
                      2 person_name = vc
                      2 sch_event_id = f8
                      2 person_id = f8
                      2 booking_id = f8
                      2 encntr_id = f8
                      2 appt_type = vc
                      2 beg_dt_tm = dq8
                      2 end_dt_tm = dq8
                      2 med_start = dq8
                      2 med_end = dq8
                      2 checkin_dt_tm = dq8
                      2 checkout_dt_Tm = dq8
                      2 provider_name = vc
 					  2 provide_id = f8
 					  2 resource = vc
                      2 bucket = vc
 					  2 visit_type = vc
                      2 duration = i4
                      2 appt_location = vc
                      2 comments = vc
                      2 attending_phys = vc
                      2 treatment = vc
                      2 vitals_time = dq8
                      2 day_beg = dq8
                      2 day_end = dq8
                      2 chair_time = dq8
                      2 apt_state = vc
                      2 slot_name = vc
				)

record meds (
 
                1 qual_knt = i4
                1 qual [*]
                	2 encntr_id = f8
                	2 med_Name = vc
                	2 route = vc
 	                2 start_time = dq8
 	                2 stop_time = dq8
    	            2 med_event_id = f8
                 )
 
record actions (
                1 qual_knt = i4
                1 qual [*]
                     2 sch_event_id = f8
                     2 action_dt_tm = dq8
                     2 action_meaning = vc
                     2 action_prsnl = vc
                     2 action_reason = vc
 				)
 
 
select
 
from 
	sch_appt sa, 
	sch_appt sa2, 
	;sch_booking sb, 
	person p
plan sa 
	where sa.appt_location_cd in (2184546405.00
,2182779655.00
,2183960659.00
,2182278381.00
,2183731625.00	
,2183700221.00
,2184449263.00
,2182748905.00	
,1627301475.00	
,2184482593.00	
,2182719209.00	
,2777828531.00	
,1183584707.00	
,2184803191.00	)      ; # Please enter the department code here)
 		and sa.beg_dt_tm > cnvtdatetime(curdate - 7,000000)              ; 2/8/22 per iQueue data requirements
 		and sa.beg_dt_tm < cnvtdatetime(curdate + 7,235959)             ; 2/8/22 per iQueue data requirements
 ;and sa.beg_dt_tm > cnvtdatetime(curdate - 14,000000)            ; testing with Cerner
 ;and sa.beg_dt_tm < cnvtdatetime(curdate + 14,235959)                ; testing with Cerner
 ;and sa.beg_dt_tm > cnvtdatetime(curdate - 365,000000)           ; 2/7/22 backload requested by iQueue
 ;and sa.beg_dt_tm < cnvtdatetime(curdate - 1,235959)             ; 2/7/22 backload requested by iQueue
 
 
;;and sa.end_dt_tm <= cnvtdatetime(curdate + 60,235959)
/*and sa.resource_cd in (
1492026989,        ;UMC Infusion Chair 2
1492026993,        ;UMC Infusion Chair 15
1492026999,        ;UMC Infusion Chair 10
1492027939,        ;UMC Infusion Chair 6
1492026029,        ;UMC Infusion Chair 5
1492026033,        ;UMC Infusion Chair 3
1492026035,        ;UMC Infusion Chair 14
1492025811,        ;UMC Infusion Chair 12
1492025815,        ;UMC Infusion Chair 11
1492026965,        ;UMC Infusion Chair 4
1492026931,        ;UMC Infusion Chair 9
1492026937,        ;UMC Infusion Chair 8
1492026961,        ;UMC Infusion Chair 7
1492028295,        ;UMC Infusion Chair 1
1492026245,        ;UMC Infusion Chair 13
1849095595)        ;UMC Infusion Chair 16  # Please enter the resource code here )  11/9/21 - Luke (Cerner) commented out
*/
 
;and sa.sch_event_id != 0
	and sa.time_type_flag = 1   ; Held Time
	;and sa.state_meaning not in ("RESCHEDULED")
join sa2 where sa2.schedule_id = sa.schedule_id
  		and sa2.schedule_id > 0
  		and sa2.active_ind = 1
  		and sa2.sch_appt_id != sa.sch_appt_id
  		and sa2.role_meaning = "PATIENT"
;join sb where sb.booking_id = sa2.booking_id
join p where p.person_id = sa2.person_id

order by sa2.sch_event_id, sa2.person_id desc
 
head report
	cnt = 0
	trip = 0
HEAD sa2.sch_event_id
	trip = 0
    if(sa2.person_id > 0)
       	cnt = cnt + 1
       	trip = 1
 	   	stat = alterlist(appointments->qual,cnt)
 	   	appointments->qual[cnt].sch_event_id = sa.sch_event_id
       	appointments->qual[cnt].location = uar_get_code_display(sa.appt_location_cd)
		appointments->qual[cnt].person_id = sa2.person_id
		appointments->qual[cnt].person_name = p.name_full_formatted
		appointments->qual[cnt].encntr_id = sa2.encntr_id
		appointments->qual[cnt].beg_dt_tm = sa.beg_dt_tm
		appointments->qual[cnt].end_dt_tm = sa.end_dt_tm
		appointments->qual[cnt].resource = uar_get_code_display(sa.resource_cd)
		appointments->qual[cnt].bucket = sa.role_description
 		appointments->qual[cnt].state_meaning = sa2.state_meaning
		appointments->qual[cnt].day_beg = cnvtdatetime(cnvtdate(sa.beg_dt_tm),000000)
		appointments->qual[cnt].day_end = cnvtdatetime(cnvtdate(sa.beg_dt_tm),235959)
    endif
 
detail
	if(sa.person_id = 0 and trip = 1)
		appointments->qual[cnt].resource = uar_get_code_display(sa.resource_cd)
	endif
foot report
	appointments->qual_knt = cnt
with nocounter
call echorecord(appointments)
 
select
from (dummyt d1 with seq = value(appointments->qual_knt)),
 	sch_appt sa, 
 	sch_appt sa2
plan d1
join sa where sa.person_id = appointments->qual[d1.seq].person_id
		;and sa.person_id > 0
        and sa.beg_dt_tm > cnvtdatetime(appointments->qual[d1.seq].day_beg)
        and sa.end_dt_tm < cnvtdatetime(appointments->qual[d1.seq].day_end)
        and sa.state_meaning not in ("RESCHEDULED","REMOVED")
join sa2 where sa2.schedule_id = sa.schedule_id
                 ;and sa2.sch_event_id > 0
order by sa2.sch_event_id
head report
	cnt = 0
head sa2.sch_event_id
 	null
detail
 	if(sa2.role_meaning != "PATIENT" and sa2.state_meaning != "RESCHEDULED")
 		cnt = cnt + 1
 		stat = alterlist(apts->qual,cnt)
 		apts->qual[cnt].person_id = sa.person_id
 		apts->qual[cnt].person_name = appointments->qual[d1.seq].person_name
 		apts->qual[cnt].encntr_id = sa.encntr_id
 		apts->qual[cnt].apt_id = sa.sch_appt_id
 		apts->qual[cnt].booking_id = sa.booking_id
 		apts->qual[cnt].sch_event_id = sa.sch_event_id
 		;apts->qual[cnt].appt_type = uar_get_code_display(sb.appt_type_cd)
 		apts->qual[cnt].beg_dt_tm = sa2.beg_dt_tm
 		apts->qual[cnt].duration = sa2.duration
 		apts->qual[cnt].appt_location = uar_get_code_display(sa2.appt_location_cd)
        apts->qual[cnt].resource = uar_get_code_display(sa2.resource_cd)
        apts->qual[cnt].bucket = sa2.role_description
        apts->qual[cnt].day_beg = cnvtdatetime(cnvtdate(sa2.beg_dt_tm),000000)
        apts->qual[cnt].apt_state = sa2.state_meaning
        apts->qual[cnt].slot_name = sa2.slot_mnemonic
     	apts->qual[cnt].day_end = cnvtdatetime(cnvtdate(sa2.beg_dt_tm),235959)
 	endif
foot report
	apts->qual_knt = cnt
with nocounter;, ORAHINTCBO("&INDEX( sa xie97sch_appt)")
call echorecord(apts)
 
select
from (dummyt d1 with seq = value(apts->qual_knt)), sch_event se
plan d1
join se where se.sch_event_id = apts->qual[d1.seq].sch_event_id
order by se.sch_event_id

detail
	apts->qual[d1.seq].appt_type = replace(se.appt_synonym_free,"\"," ")
with nocounter
 
select
	encntr_id = e.encntr_id,
	event =  uar_get_code_display(e.event_cd),
	documented_dt_tm = format(e.event_end_dt_tm, "@SHORTDATETIMENOSEC"),
 	result =  e.result_val,
 	tag =  e.event_tag,
 	title =  e.event_title_text
from (dummyt d1 with seq = value(appointments->qual_knt)),clinical_event e
plan d1 where apts->qual[d1.seq].encntr_id > 0
			and apts->qual[d1.seq].person_id > 0
join e where e.encntr_id = apts->qual[d1.seq].encntr_id
            and e.person_id = apts->qual[d1.seq].person_id
            and e.event_end_dt_tm > cnvtdatetime(apts->qual[d1.seq].day_beg)
            and e.event_end_dt_tm < cnvtdatetime(apts->qual[d1.seq].day_end)
            and e.event_cd  in (4154120.00,4154123.00,4154126.00,4154129.00,  101724444.00, 
  101724448.00,   82338457.00,  954077981.00)
;Weight Measured (Non-Dosing)
;Weight Dosing
;Height/Length Measured (Non-Dosing)
;Height/Length Dosing
;Systolic Blood Pressure
;Diastolic Blood Pressure
;Heart Rate Resting
;Port Accessed Date/Time:
        ;;and e.event_cd in (select e.event_cd from v500_event_set_explode e where e.event_set_cd = 5873604.00 ;Vital Signs Time Taken
         ;;and e.event_cd in (703501,703516,703558,703511,703540,703306))  ;please add vital sign event codes here )
order by e.encntr_id, e.event_end_dt_tm

head e.encntr_id
        apts->qual[d1.seq].vitals_time = e.event_end_dt_tm
with format, pcformat(^"^,^,^,1),format=stream
 

select distinct
from (dummyt d1 with seq = value(apts->qual_knt)),
	clinical_event ce,
	ce_med_result cm
plan d1 where apts->qual[d1.seq].encntr_id > 0
           	and apts->qual[d1.seq].person_id > 0
join ce where ce.encntr_id = apts->qual[d1.seq].encntr_id
           	and ce.person_id = apts->qual[d1.seq].person_id
			and ce.encntr_id > 0
 			and ce.event_end_dt_tm < cnvtdatetime(apts->qual[d1.seq].day_end)
			and ce.event_end_dt_tm > cnvtdatetime(apts->qual[d1.seq].day_beg)
join cm where cm.event_id = ce.event_id
order by ce.encntr_id,ce.event_title_text, cm.admin_start_dt_tm desc
 
head report
null
cnt = 0
head ce.encntr_id
null
head ce.event_title_text
	cnt = cnt + 1
	stat = alterlist(meds->qual,cnt)
	meds->qual[cnt].encntr_id = ce.encntr_id
 	meds->qual[cnt].med_Name = replace(ce.event_title_text,"\"," ")
 	meds->qual[cnt].start_time = cm.admin_start_dt_tm
 	meds->qual[cnt].stop_time = cm.admin_end_dt_tm
 	meds->qual[cnt].route = uar_get_code_display(cm.admin_route_cd)
	meds->qual[cnt].med_event_id = cm.event_id
foot report
 	meds->qual_knt = cnt
with nocounter
 
select
from (dummyt d1 with seq = value(apts->qual_knt)),
	sch_event_action sea, 
	prsnl p
plan d1
join sea where sea.sch_event_id = apts->qual[d1.seq].sch_event_id
        and sea.action_meaning != "VIEW"
join p where sea.action_prsnl_id = p.person_id
order by sea.sch_event_id
 
head report
cnt = 0
head sea.sch_event_id
null
detail
	cnt = cnt + 1
	stat = alterlist(actions->qual,cnt)
	actions->qual[cnt].action_dt_tm = sea.action_dt_tm
	actions->qual[cnt].action_meaning = sea.action_meaning
 	actions->qual[cnt].sch_event_id = sea.sch_event_id
	actions->qual[cnt].action_prsnl = replace(p.name_full_formatted,"\"," ")
	actions->qual[cnt].action_reason = uar_get_code_display(sea.sch_reason_cd)
	actions->qual[cnt].action_reason = replace(actions->qual[cnt].action_reason,"\"," ")
foot report
actions->qual_knt = cnt
with nocounter
 
select
from (dummyt d1 with seq = value(apts->qual_knt)),
	sch_event_detail sed
plan d1
join sed where sed.sch_event_id = apts->qual[d1.seq].sch_event_id
order by sed.sch_event_id

head report
null
detail
case(sed.OE_FIELD_ID)
 of 663838.00:  apts->qual[d1.seq].attending_phys = sed.oe_field_display_value
endcase
/*
case(sed.oe_field_id)
 
    of  # Please enter the code for attendtion physician:         apts->qual[d1.seq].attending_phys = sed.oe_field_display_value
   of  # Please enter the code for scheduling comments:       apts->qual[d1.seq].comments = sed.oe_field_display_value
 
 of # Please enter the code for treatment information from scheduling:            apts->qual[d1.seq].treatment = sed.oe_field_display_value
 
 
endcase
*/
foot report
null
with nocounter
 
 ;when changeing these for the 1 time historical run, please put the word historical in the file instead of the datename
 
set file = build2("unitname_infusion_meds_",trim(datename1,3),".csv")
set filename = build2("/cerner/d_p41/cust_output_nfs/inf_leantaas/",trim(file,3))
;SET file_name = ;"cipher_test_0104.csv" 
;
;CONCAT("/cerner/d_p41/cust_output_nfs/cipher_health/","cipher_discharge_",format(cnvtdatetime(curdate, curtime), "MMDDYY;;Q"),".csv")
; 
select distinct into  value(filename);$outdev;
	encntr_id = meds->qual[d1.seq].encntr_id
 	,med_name = substring(1,100,meds->qual[d1.seq].med_Name)
 	;,med_start_time = format(meds->qual[d1.seq].start_time,"@SHORTDATETIMENOSEC")
	,med_start_time = format(meds->qual[d1.seq].start_time,"YYYY-MM-DD HH:MM:SS;;Q")   ; 2/1/22 added seconds per iQueue request
 	;,med_end_time = format(meds->qual[d1.seq].stop_time,"@SHORTDATETIMENOSEC")
	,med_end_time = format(meds->qual[d1.seq].stop_time,"YYYY-MM-DD HH:MM:SS;;Q")      ; 2/1/22 added seconds per iQueue request
 	,med_route = substring(1,60,meds->qual[d1.seq].route)
	,med_event_id = meds->qual[d1.seq].med_event_id
from (dummyt d1 with seq = value(meds->qual_knt))
plan d1
order by meds->qual[d1.seq].encntr_id, meds->qual[d1.seq].med_event_id
;with format, pcformat(^"^,^,^,1),format=stream
WITH format(date,"@SHORTDATETIME"),NOCOUNTER, SEPARATOR=" ", FORMAT, TIME = 300 
;set file = build2("unitname_infusion_actions_",trim(datename1,3),".csv")
;set filename = build2("/cerner/d_p41/cust_output_nfs/inf_leantaas/",trim(file,3))
;
select distinct into value(filename)
	sch_event_id = actions->qual[d1.seq].sch_event_id
	,action = substring(1,30,actions->qual[d1.seq].action_meaning)
 	,action_date_time = format(actions->qual[d1.seq].action_dt_tm,"YYYY-MM-DD HH:MM:SS;;Q")
 	,action_prsnl = substring(1,100,actions->qual[d1.seq].action_prsnl)
	,action_reason = substring(1,60,actions->qual[d1.seq].action_reason)
from (dummyt d1 with seq = value(actions->qual_knt))
plan d1
order by sch_event_id, action, action_date_time, action_prsnl,action_reason
with format, pcformat(^"^,^,^,1),format=stream
 
;when running as historical, we will need historical in the name
set file = build2("unitname_infusion_appts",trim(datename1,3),".csv")
set filename = build2("/cerner/d_p41/cust_output_nfs/inf_leantaas/",trim(file,3))

select into value(filename); $outdev ;
	appt_type = substring(1,100,apts->qual[d1.seq].appt_type)
	,patient_id = apts->qual[d1.seq].person_id
	, patient_name = substring(1,60,apts->qual[d1.seq].person_name)
	,appt_date_time = format(apts->qual[d1.seq].beg_dt_tm,"YYYY-MM-DD HH:MM:SS;;Q")
	,exp_duration = apts->qual[d1.seq].duration
	;;,vitals_time = format(apts->qual[d1.seq].vitals_time,"YYYY-MM-DD HH:MM:SS:SSS;;Q")
	,vitals_time = format(apts->qual[d1.seq].vitals_time,"YYYY-MM-DD HH:MM:SS;;Q")
	,chair_time = apts->qual[d1.seq].chair_time "@SHORTDATETIME"
	,sch_event_id = apts->qual[d1.seq].sch_event_id
	,encntr_id = apts->qual[d1.seq].encntr_id
	,department = apts->qual[d1.seq].appt_location
	,resource = substring(1,60,apts->qual[d1.seq].resource)
	,resource_2 = substring(1,60,apts->qual[d1.seq].bucket)
	,treament = substring(1,60,apts->qual[d1.seq].treatment)
	,attending_phys = substring(1,100,apts->qual[d1.seq].attending_phys)
	,appt_comments = substring(1,100,apts->qual[d1.seq].comments)
	,appt_status = substring(1,60,apts->qual[d1.seq].apt_state)
	,slot_booked = substring(1,60,apts->qual[d1.seq].slot_name)
from (dummyt d1 with seq = value(apts->qual_knt))
plan d1
order by apts->qual[d1.seq].person_id, apts->qual[d1.seq].sch_event_id
with format, pcformat(^"^,^,^,1),format=stream  ;, time =300
;WITH format(date,"@SHORTDATETIME"),NOCOUNTER, SEPARATOR=" ", FORMAT, TIME = 300
end
go
