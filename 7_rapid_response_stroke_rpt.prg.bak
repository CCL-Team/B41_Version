/***************************************************************************************************
 Program Title:     GSH UMH Rapid Response/Code Stroke Report
 Object name:       7_rapid_response_stroke_rpt
 Source file:       7_rapid_response_stroke_rpt.prg
 Purpose:           New PF created for ease of documentation and for pulling reports 
 					and gathering data of said rapid responses more efficiently
 Executed from:     DA2 / Reporting Portal
 Special Notes:     Requested by Ashley Shelter (CareNet Reporting WG)
****************************************************************************************************
                                  MODIFICATION CONTROL LOG
****************************************************************************************************
Mod    Date             Analyst                 MCGA            Comment
---    ----------       --------------------    ------          ------------------------------------
000    12/21/2023       David Smith             345238         Initial Release
*****************************************************************************************************/
drop program 7_rapid_response_stroke_rpt go
create program 7_rapid_response_stroke_rpt

prompt 
	"Output to File/Printer/MINE" = "MINE"      ;* Enter or select the printer or file name to send this report to.
	, "Facility:" = 0
	, "Include Active Units Only?" = 1
	, "Unit(s) at Time of Call:" = VALUE(123)
	, "Powerforms Dated Between:" = "SYSDATE"
	, "and:" = "SYSDATE" 

with OUTDEV, FAC, UNIT_ACTV, UNITS, START_DT, END_DT
;***********************************************************************************************
;                           VARIABLE DECLARATIONS
;***********************************************************************************************
declare modifiedCd = f8 with public, noconstant(uar_get_code_by("MEANING",8,"MODIFIED"))
declare alteredCd = f8 with public, noconstant(uar_get_code_by("MEANING",8,"ALTERED"))
declare authverifyCd = f8 with public, noconstant(uar_get_code_by("MEANING",8,"AUTH"))
declare componentCd = f8 with constant(uar_get_code_by("DISPLAY_KEY", 18189,"PRIMARYEVENTID"))
;***********************************************************************************************
;                           RECORD STRUCTURE
;***********************************************************************************************
free record pts
record pts(
        1 qual[*]
            2 dcp_forms_ref_id = f8
            2 dcp_forms_activity_id = f8 
            2 form_dt_tm = dq8
            2 facility = vc
            2 name = vc
            2 fin = vc
            2 mrn = vc
            2 person_id = f8
            2 encntr_id = f8
            2 age = vc
            2 gender = vc
            2 time_of_call = vc
            2 time_of_call_dq8 = dq8
            2 reason_for_call = vc
            2 rrt_arrival = vc
            2 rrt_event_ended = vc
            2 type_of_call = vc
            2 rrt_activated_by = vc
            2 pt_received_from = vc
            2 unit_pt_received_from = vc
            2 team_members_utilized = vc
            2 provider_arrival_time = vc
            2 airway_breathing = vc
            2 circulation = vc
            2 diag_tests = vc
            2 meds = vc
            2 outcome = vc
            2 progressed_to_code = vc
            2 transferred_to = vc
            2 stroke_dttm_eval = vc
            2 stroke_last_normal = vc
            2 neuro_eval_dttm = vc
            2 unit_at_time_of_call = vc
            2 unit_at_time_of_call_f8 = f8
            2 display_ind = i2
)           
/****************************************************************************************************
                    GETTING ALL INSTANCES OF POWERFORM THAT WERE CHARTED
*****************************************************************************************************/
select into 'nl:'
from dcp_forms_activity dfa
	,encounter e
	,person p
	,encntr_alias ea

Plan dfa where dfa.dcp_forms_ref_id = 25527219867.00 ;GSH UMH Code Stroke/Rapid Response
	and dfa.form_dt_tm between cnvtdatetime($START_DT) and cnvtdatetime($END_DT)
	and dfa.active_ind = 1
	and dfa.form_status_cd in(modifiedCd,alteredCd,authverifyCd)
join e where e.encntr_id = dfa.encntr_id
	and e.loc_building_cd = $FAC
join p where p.person_id = e.person_id
join ea where ea.encntr_id = outerjoin(dfa.encntr_id)
	and ea.active_ind = outerjoin(1)
	and ea.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime3))
	and ea.encntr_alias_type_cd = outerjoin(1077); FIN
	
head report
forms=0
Head dfa.dcp_forms_activity_id
forms=forms+1
STAT=ALTERLIST(PTS->QUAL,forms)

PTS->QUAL[forms].encntr_id = dfa.encntr_id
PTS->QUAL[forms].person_id = dfa.person_id
PTS->QUAL[forms].form_dt_tm = dfa.form_dt_tm
PTS->QUAL[forms].dcp_forms_activity_id = dfa.dcp_forms_activity_id
PTS->QUAL[forms].dcp_forms_ref_id = dfa.dcp_forms_ref_id
PTS->QUAL[forms].facility = trim(uar_get_code_display(e.loc_facility_cd))
PTS->QUAL[forms].name = trim(p.name_full_formatted)
PTS->QUAL[forms].gender = trim(uar_get_code_display(p.sex_cd))
PTS->QUAL[forms].age = trim(cnvtage(p.birth_dt_tm,dfa.form_dt_tm,0))
PTS->QUAL[forms].fin = trim(cnvtalias(ea.alias, ea.alias_pool_cd))
	
with nocounter,time=400
/****************************************************************************************************
 					CHECK ARRAY SIZE
*****************************************************************************************************/
if(size(PTS->QUAL,5)=0)
	    select into $OUTDEV
		from dummyt
		Detail
		row + 1
		col 001 "GSH UMH Rapid Response/Code Stroke Report"
		row + 1
		col 001 "You requested: "
		col 016 $START_DT
		col 040 "TO"
		col 045 $END_DT
		row + 1
		col 001 "No Qualifying Powerforms were found for that Data Range"
		row + 1
		col 001 "Please Search Again"
		row + 2
		with format, separator = " "
 go to EXIT_PROGRAM
endif
/****************************************************************************************************
 					GETTING ADDITIONAL POWERFORM FIELDS
*****************************************************************************************************/
select into 'nl:'
from (DUMMYT D1 with SEQ=SIZE(PTS->QUAL,5))
	,dcp_forms_activity_comp dfac
	,clinical_event ce1
	,clinical_event ce2
	,ce_date_result cdr

PlAN D1
JOIN DFAC where dfac.dcp_forms_activity_id = PTS->QUAL[D1.seq].dcp_forms_activity_id
			and dfac.component_cd = componentCd
			and dfac.parent_entity_name = 'CLINICAL_EVENT'
join ce1 where ce1.parent_event_id = dfac.parent_entity_id
			and ce1.parent_event_id != ce1.event_id
			and ce1.result_status_cd in(modifiedCd,alteredCd,authverifyCd)
			and ce1.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
join ce2 where ce2.parent_event_id = ce1.event_id
			and ce2.result_status_cd in(modifiedCd,alteredCd,authverifyCd)
			and ce2.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)
join cdr where cdr.event_id = outerjoin(ce2.event_id)
	and cdr.valid_until_dt_tm > outerjoin(cnvtdatetime(curdate,curtime3))
	 
order by d1.seq
 
head d1.seq
null
detail

if(ce2.event_cd = 2426389111.00)			;Date/Time of Call
	PTS->QUAL[D1.seq].time_of_call = format(cdr.result_dt_tm,"MM/DD/YYYY hh:mm;;Q")
	PTS->QUAL[D1.seq].time_of_call_dq8 = cdr.result_dt_tm
elseif(ce2.event_cd = 2426389141.00)		;RRT Arrival Time
	PTS->QUAL[D1.seq].rrt_arrival= format(cdr.result_dt_tm,"MM/DD/YYYY hh:mm;;Q")
elseif(ce2.event_cd = 2426389171.00)		;RRT Event Ended
	PTS->QUAL[D1.seq].rrt_event_ended = format(cdr.result_dt_tm,"MM/DD/YYYY hh:mm;;Q")
elseif(ce2.event_cd = 2506025395.00)		;Reason for RRT Call
	PTS->QUAL[D1.seq].reason_for_call = trim(replace(replace(ce2.result_val,char(10),""),char(13),""))
elseif(ce2.event_cd = 2426389333.00)		;RRT Activated By
	PTS->QUAL[D1.seq].rrt_activated_by = trim(ce2.result_val)
elseif(ce2.event_cd = 4802158211.00)		;Type of Rapid Response Call
	PTS->QUAL[D1.seq].type_of_call = trim(ce2.result_val)
elseif(ce2.event_cd =  2426389363.00)		;Patient Received From (Last 24 hours)
	PTS->QUAL[D1.seq].pt_received_from = trim(ce2.result_val)
elseif(ce2.event_cd =  2426389393.00)		;Unit Patient Received From
	PTS->QUAL[D1.seq].unit_pt_received_from = trim(ce2.result_val)
elseif(ce2.event_cd =  2426389453.00)		;MD Arrival Time
	PTS->QUAL[D1.seq].provider_arrival_time = format(cdr.result_dt_tm,"MM/DD/YYYY hh:mm;;Q")
elseif(ce2.event_cd =  2426381855.00)		;Airway/Breathing
	PTS->QUAL[D1.seq].airway_breathing = trim(ce2.result_val)
elseif(ce2.event_cd = 2506038453.00)		;Circulatory
	PTS->QUAL[D1.seq].circulation = trim(ce2.result_val)
elseif(ce2.event_cd = 3238581653.00)		;Resource Tests
	PTS->QUAL[D1.seq].diag_tests = trim(ce2.result_val)
elseif(ce2.event_cd = 2503275069.00)		;RR Medications
	PTS->QUAL[D1.seq].meds = trim(ce2.result_val)
elseif(ce2.event_cd = 2506047739.00)		;Patient Outcome
	PTS->QUAL[D1.seq].outcome = trim(ce2.result_val)
elseif(ce2.event_cd = 2506048289.00)		;Condition progressed to Code
	PTS->QUAL[D1.seq].progressed_to_code = trim(ce2.result_val)
elseif(ce2.event_cd = 4795169349.00)		;RRT in Attendance
	PTS->QUAL[D1.seq].team_members_utilized = trim(ce2.result_val)
elseif(ce2.event_cd = 4795191051.00)		;RRT Transfer Location
	PTS->QUAL[D1.seq].transferred_to = trim(ce2.result_val)
elseif(ce2.event_cd = 4805516493.00)		;Neurologist Evaluation Date/Time
	PTS->QUAL[D1.seq].neuro_eval_dttm = format(cdr.result_dt_tm,"MM/DD/YYYY hh:mm;;Q")
elseif(ce2.event_cd = 102262972.00)			;Last Seen Normal
	PTS->QUAL[D1.seq].stroke_last_normal = format(cdr.result_dt_tm,"MM/DD/YYYY hh:mm;;Q")
elseif(ce2.event_cd = 4250120.00)			;Date/Time of Evaluation
	PTS->QUAL[D1.seq].stroke_dttm_eval = format(cdr.result_dt_tm,"MM/DD/YYYY hh:mm;;Q")
	
endif
 
with nocounter,time=400
/****************************************************************************************************
 					GETTING PT LOCATION AT TIME OF CALL
*****************************************************************************************************/
select into 'nl:'
from (DUMMYT D1 with SEQ=SIZE(PTS->QUAL,5))
	,ENCNTR_LOC_HIST ELH

PlAN D1
JOIN ELH where ELH.encntr_id = PTS->QUAL[D1.seq].encntr_id
	and ELH.beg_effective_dt_tm < cnvtdatetime(PTS->QUAL[D1.seq].time_of_call_dq8)
	and ELH.transaction_dt_tm < cnvtdatetime(PTS->QUAL[D1.seq].time_of_call_dq8)
	and ELH.loc_nurse_unit_cd != 0.00
	and ELH.active_ind = 1
	 
order by d1.seq, elh.transaction_dt_tm desc
 
head d1.seq
PTS->QUAL[D1.seq].unit_at_time_of_call = trim(uar_get_code_display(elh.loc_nurse_unit_cd))
PTS->QUAL[D1.seq].unit_at_time_of_call_f8 = elh.loc_nurse_unit_cd
 
with nocounter,time=400
/****************************************************************************************************
 					FILTERING WHICH TO OUTPUT
*****************************************************************************************************/
select into 'nl:'
from (DUMMYT D1 with SEQ=SIZE(PTS->QUAL,5))
Plan D1

order by d1.seq
 
head d1.seq

if($UNITS = 123) 	;All
	PTS->QUAL[D1.seq].display_ind = 1
else
	if(PTS->QUAL[D1.seq].unit_at_time_of_call_f8 in($UNITS))
		PTS->QUAL[D1.seq].display_ind = 1
	endif
endif

with nocounter,time=400
;***********************************************************************************************
;                           OUTPUT DATA TO SCREEN
;***********************************************************************************************
Select into $OUTDEV
 UNIT_AT_TIME_OF_CALL = trim(substring(1,100,PTS->QUAL[D1.SEQ].unit_at_time_of_call))
,NAME = trim(substring(1,100,PTS->QUAL[D1.SEQ].name))
,FACILITY = trim(substring(1,100,PTS->QUAL[D1.SEQ].facility))
,FIN = trim(substring(1,100,PTS->QUAL[D1.SEQ].fin))
,AGE = trim(substring(1,100,PTS->QUAL[D1.SEQ].age))
,GENDER = trim(substring(1,100,PTS->QUAL[D1.SEQ].gender))
,TIME_OF_CALL = trim(substring(1,100,PTS->QUAL[D1.SEQ].time_of_call))
,REASON_FOR_CALL = trim(substring(1,255,PTS->QUAL[D1.SEQ].reason_for_call))
,RRT_ARRIVAL_TIME = trim(substring(1,100,PTS->QUAL[D1.SEQ].rrt_arrival))
,RRT_EVENT_ENDED = trim(substring(1,100,PTS->QUAL[D1.SEQ].rrt_event_ended))
,TYPE_OF_CALL = trim(substring(1,100,PTS->QUAL[D1.SEQ].type_of_call))
,RRT_ACTIVATED_BY = trim(substring(1,100,PTS->QUAL[D1.SEQ].rrt_activated_by))
,PT_RECEIVED_FROM = trim(substring(1,100,PTS->QUAL[D1.SEQ].pt_received_from))
,UNIT_PT_RECEIVED_FROM = trim(substring(1,100,PTS->QUAL[D1.SEQ].unit_pt_received_from))
,TEAM_MEMBERS_UTILIZED = trim(substring(1,255,PTS->QUAL[D1.SEQ].team_members_utilized))
,PROVIDER_ARRIVAL_TIME = trim(substring(1,100,PTS->QUAL[D1.SEQ].provider_arrival_time))
,AIRWAY_BREATHING = trim(substring(1,255,PTS->QUAL[D1.SEQ].airway_breathing))
,CIRCULATION = trim(substring(1,255,PTS->QUAL[D1.SEQ].circulation))
,DIAG_TESTS_ORDERED = trim(substring(1,255,PTS->QUAL[D1.SEQ].diag_tests))
,MED_ORDERS = trim(substring(1,255,PTS->QUAL[D1.SEQ].meds))
,OUTCOME = trim(substring(1,255,PTS->QUAL[D1.SEQ].outcome))
,PROGRESSED_TO_CODE = trim(substring(1,100,PTS->QUAL[D1.SEQ].progressed_to_code))
,TRANSFERRED_TO = trim(substring(1,100,PTS->QUAL[D1.SEQ].transferred_to))
,STROKE_DTTM_OF_EVAL = trim(substring(1,100,PTS->QUAL[D1.SEQ].stroke_dttm_eval))
,STROKE_LAST_SEEN_NORMAL = trim(substring(1,100,PTS->QUAL[D1.SEQ].stroke_last_normal))
,NEUROLOGIST_EVAL_DTTM = trim(substring(1,100,PTS->QUAL[D1.SEQ].neuro_eval_dttm))
,FORM_DT_TM = format(PTS->QUAL[D1.SEQ].form_dt_tm,"@SHORTDATETIME")
,ACTIVITY_ID = PTS->QUAL[D1.SEQ].dcp_forms_activity_id
        
from (DUMMYT D1 with SEQ=SIZE(PTS->QUAL,5))
PLAN D1 where PTS->QUAL[D1.SEQ].display_ind = 1
Order by NAME,FORM_DT_TM
with nocounter,time=60,format,separator=" "    
;***********************************************************************************************
;                           END OF PROGRAM
;***********************************************************************************************
#EXIT_PROGRAM

end
go


