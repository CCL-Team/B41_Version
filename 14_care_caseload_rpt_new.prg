/********************************************************************************************************************************
 Program Title:     Collaborative Care Caseload Report
 Object name:       14_care_caseload_rpt
 Source file:		14_care_caseload_rpt

 Purpose:

 Prompts:
 #1 Display:        Output to File/Printer/MINE
    Name:           OutDev
    Control Type:   Output Device
    Type:           String
    Description:    Enter or select the printer or file name to send this report to.
    Default:        MINE

 Executed from:
 Programs Executed: DA2
 Special Notes:     This CCL is executed by DA2


*********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
*********************************************************************************************************************************
 Mod  Date        Analyst               MCGA         Comment
 ---  ----------  --------------------  ----------  -----------------------------------------------------------------------------
 001  04/11/2022  German Perez 			230562		Initial release

*********************************END OF ALL MODCONTROL BLOCKS*******************************************************************/
drop program 14_care_caseload_rpt_new:dba go
create program 14_care_caseload_rpt_new:dba

prompt 
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Search PowerForm Author:" = ""
	;<<hidden>>"Search" = ""
	, "Powerform Author" = VALUE(*)
	, " CoCM Treatment Status:" = ""
	, "Report Type" = "D" 

with OUTDEV, PRSNL_SEARCH, PRSNL_LIST, cocmStatus, report_type

/**************************************************************
; DVDev INCLUDE Files
**************************************************************/
%i cust_script:14_cps_get_prompt_list.inc
%i cust_script:14_sc_cps_parse_date_subs.inc

/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/

declare num = i4
declare pos = i4
declare sParserPrsnl = vc with protect, noconstant("1=1")
declare status_parser = vc ;with protect, noconstant("1=1")
declare perc_change_phq9_score = f8
declare perc_change_gad7_score = f8
declare perc_change_auditc_score = f8

set status_parser = "1=1"

if(IsPromptAny(parameter2($cocmStatus)) OR IsPromptEmpty(parameter2($cocmStatus)))
  set status_parser = '1=1'
else
  set status_parser = trim(GetPromptList(parameter2($cocmStatus), " ce3.result_val"), 3)
endif

if(IsPromptAny(parameter2($PRSNL_LIST)) OR IsPromptEmpty(parameter2($PRSNL_LIST)))
  set sParserPrsnl = '1=1'
else
  set sParserPrsnl = trim(GetPromptList(parameter2($PRSNL_LIST), " pr.person_id"), 3)
endif


free record reply
record reply(
  1 total_number_of_pts_on_caseload = f8 ;active_relapse_prevention
  1 total_number_of_inactive_pts = f8  ;does_not_include_past_tx_episodes_for_currently_active_pts  
	1 number_of_pts_flagged  = f8  ;for_discussion_w_psychiatric_consultant
	1 number_of_pts_w_at_least_1_psychiatric_case_review_date_recorded = f8
	1 number_of_pts_w_1_followup_contacts = f8	
	1 number_of_inactive_pts_w_1_followup_contacts = f8	
	1 number_of_active_pts_in_relapse_prevention = f8	
	1 mean_number_of_followup_contacts = f8 ;.Number_of_Pts_w_1_Followup_Contacts/ Total_Number_of_Pts_on_Caseload
	
	1 mean_initial_phq9 = f8
	1 mean_final_phq9 = f8
	1 total_initial_phq9 = f8
	1 total_final_phq9 = f8
	1 count_initial_phq9 = f8
	1 count_final_phq9 = f8
	1 count_phq_w_fu = f8
	1 count_no_phq_gt30d = f8
	1 count_not_in_range_phq = f8
	
	1 mean_initial_gad7 = f8
	1 mean_final_gad7 = f8
	1 total_initial_gad7 = f8
	1 total_final_gad7 = f8
	1 count_initial_gad7 = f8
	1 count_final_gad7 = f8
	1 count_gad7_w_fu = f8
	1 count_no_gad7_gt30d = f8
	1 count_not_in_range_gad7 = f8 
	
	1 mean_initial_auditc = f8
	1 mean_final_auditc = f8
	1 total_initial_auditc = f8
	1 total_final_auditc = f8
	1 count_initial_auditc = f8
	1 count_final_auditc = f8
	1 count_auditc_w_fu = f8
	1 count_no_auditc_gt30d = f8
	1 count_not_in_range_auditc = f8 
;---------------Inactive Status---------------------------------------------------------------------------------------------------
	1 mean_number_of_inactive_followup_contacts = f8
	1 mean_inactive_initial_phq9 = f8
	1 mean_inactive_final_phq9 = f8
	1 total_inactive_initial_phq9 = f8
	1 total_inactive_final_phq9 = f8
	1 count_inactive_initial_phq9 = f8
	1 count_inactive_final_phq9 = f8
	1 count_inactive_phq_w_fu = f8
	1 count_inactive_no_phq_gt30d = f8
	1 count_inactive_not_in_range_phq = f8
	
	1 mean_inactive_initial_gad7 = f8
	1 mean_inactive_final_gad7 = f8
	1 total_inactive_initial_gad7 = f8
	1 total_inactive_final_gad7 = f8
	1 count_inactive_initial_gad7 = f8
	1 count_inactive_final_gad7 = f8
	1 count_inactive_gad7_w_fu = f8
	1 count_inactive_no_gad7_gt30d = f8
	1 count_inactive_not_in_range_gad7 = f8 
	
	1 mean_inactive_initial_auditc = f8
	1 mean_inactive_final_auditc = f8
	1 total_inactive_initial_auditc = f8
	1 total_inactive_final_auditc = f8
	1 count_inactive_initial_auditc = f8
	1 count_inactive_final_auditc = f8
	1 count_inactive_auditc_w_fu = f8
	1 count_inactive_no_auditc_gt30d = f8
	1 count_inactive_not_in_range_auditc = f8
	
	1 number_of_pts_not_improving_and_wo_a_psychiatric_case_review_date_recorded = vc 
	
	

	
	1 percent_of_followup_contacts_labeled_in_person_at_clinic = vc
	1 percent_of_followup_contacts_labeled_phone = vc
	1 percent_of_followup_contacts_labeled_video = vc ;new
	1 percent_of_all_contacts_w_a_phq9_score_recorded = vc
	1 mean_initial_phq9_score = vc
	1 mean_last_available_phq9_score = vc
	1 number_of_pts_w_an_initial_phq9_score_recorded = vc
	1 number_of_pts_w_1_followup_phq9_scores_recorded = vc
	1 number_of_pts_w_no_phq9_score_recorded_in_last_30_days = vc
	1 number_of_pts_w_phq9  = vc  ;_score_<5_or_=50%_improvement_from_initial_score
	
	1 mean_initial_gad7_score = vc
	1 mean_last_available_gad7_score = vc
	
	1 number_of_pts_w_an_initial_gad7_score_recorded = vc
	1 number_of_pts_w_1_followup_gad7_scores_recorded = vc
	1 number_of_pts_w_no_gad7_score_recorded_in_last_30_days = vc
	1 number_of_pts_w_gad7_score  = vc  ;<10_or_=50%_improvement_from_initial_score
	1 pts_w_an_initial_gad7_score_recorded = vc
	
	1 mean_initial_auditc_score = vc
	1 mean_last_available_auditc_score = vc
	1 number_of_pts_w_auditc = vc
	1 pts_w_an_initial_auditc_score_recorded = vc
	1 pts_w_1_followup_auditc_scores_recorded = vc
	1 number_of_pts_w_auditc_less_5 = vc  ;_<5_or_=50%_improvement_from_initial_score
 
	
	1 number_of_pts_w_1_followup_contacts_inactive = vc
	1 mean_number_of_followup_contacts_inactive = vc
	1 percent_of_followup_contacts_labeled_in_person_at_clinic_inactive = vc
	1 percent_of_followup_contacts_labeled_phone_inactive = vc
	1 percent_of_followup_contacts_labeled_video_inactive = vc ;new
	1 percent_of_all_contacts_w_a_phq9_score_recorded_inactive = vc
	1 mean_initial_phq9_score_inactive = vc
	1 mean_last_available_phq9_score_inactive = vc
	1 number_of_pts_w_an_initial_phq9_score_recorded_inactive = vc
	1 number_of_pts_w_1_followup_phq9_scores_recorded_inactive = vc
	1 number_of_pts_w_no_phq9_score_recorded_in_last_30_days_inactive = vc
	1 number_of_pts_w_phq9_inactive  = vc  ;score<5_or_=50%_improvement_from_initial_score
	1 mean_initial_gad7_score_inactive = vc
	1 mean_last_available_gad7_score_inactive = vc
	1 number_of_pts_w_an_initial_gad7_score_recorded_inactive = vc
	1 number_of_pts_w_1_followup_gad7_scores_recorded_inactive = vc
	
	1 number_of_pts_w_no_gad7_score_recorded_in_last_30_days_inactive = vc
	
	1 number_of_pts_w_gad7_inactive = vc   ;score_<10_or_=50%_improvement_from_initial_score
	1 number_of_pts_w_gad7_score_inactive	= vc
	1 mean_initial_auditc_score_inactive = vc
	1 mean_last_available_auditc_score_inactive = vc
		
	1 mean_initial_score_inactive = vc
	1 mean_last_available_score_inactive = vc
	1 pts_w_an_initial_auditc_score_recorded_inactive = vc
	1 pts_w_1_followup_auditc_scores_recorded_inactive = vc	
	1 pts_w_an_initial_gad7_score_recorded_inactive = vc
	1 pts_w_1_followup_scores_recorded_inactive = vc
	1 number_of_pts_w_auditc_less_5_inactive  = vc  ;<5_or_=50%_improvement_from_initial_score
	1 summary[*]
    2 header = vc
    2 content1 = vc	 
    2 content2 = vc	 
    2 content3 = vc	     
  1 items[*]
    2 person_id = f8
    2 encntr_id = f8
    2 fac_desc = vc
    2 fin = vc
    2 empi = vc
    2 pname = vc
    2 form_dt_tm = dq8
    2 physname = vc
    2 performed_by = vc
    2 activity_dt_tm = vc
    2 form_parent_event_id = f8
    2 date_of_most_recent_contact = vc
    2 CoCM_treatment_status = vc; 2 - Relapse prevention 1 - Active; 0 Inactive
    2 frequency_of_cocm_visit = vc
    2 episodes_of_care_begin = vc
    2 episodes_of_care_end = vc
    2 Date_Episode_of_Care_Began = dq8
    2 Date_Episode_of_Care_Ended = dq8
    2 date_of_last_psych_consult = vc
    2 cocm_flag = vc
    2 target_scale = vc
    2 CoCM_status_ind = i4
    2 CoCM_status_flag = i2 ;2 - Relapse prevention 1 - Active; 0 Inactive
    2 CoCM_pt_Flag = vc
    2 next_follow_up_due_date = vc
    
    2 ts_phq = i4
    2 ts_gad = i4
    2 ts_auditc = i4
    ;scores
    2 initial_phq9_score = vc
    2 last_phq9_score = vc
    2 initial_phq9_date = vc
    2 perc_change_phq9_score = vc
    2 last_phq9_date = vc
    2 phq9_count = i4
    2 phq9_change = vc
    
    2 initial_gad7_score = vc
    2 last_gad7_score = vc
    2 initial_gad7_date = vc
    2 perc_change_gad7_score = vc
    2 last_gad7_date = vc
    2 gad7_count = i4
    2 gad7_change = vc
    
    2 initial_auditc_score = vc
    2 last_auditc_score = vc
    2 initial_auditc_date = vc
    2 perc_change_auditc_score = vc
    2 last_auditc_date = vc
    2 auditc_count = i4
    2 auditc_change = vc
    
    2 initial_gad2_score = vc
    2 last_gad2_score = vc
    2 initial_gad2_date = vc
    2 perc_change_gad2_score = vc
    2 last_gad2_date = vc
    2 gad2_count = i4
    2 gad2_change = vc
)





/**************************************************************
; Main Query
**************************************************************/
select into "nl:"
 d.dcp_forms_activity_id,
  FORM_DATE = format(d.form_dt_tm,"MM/DD/YYYY hh:mm:ss")
  ,document_type = D.description
  ,ENCNTR_ID = d.encntr_id
  ,person_id = d.person_id
  ,activity_id = dfc.dcp_forms_activity_id
  ,ce.event_cd
  ,ce3.event_cd
  ,ce3.result_val
from dcp_forms_activity   d
  ,dcp_forms_activity_comp dfc
  ,clinical_event ce
  ,clinical_event ce2
  ,clinical_event ce3
  ,person p
  ,encounter e
  ,prsnl pr
plan d
  where d.active_ind  = 1
  and d.dcp_forms_ref_id = 13047318247
  and d.form_status_cd in(25.00, 34.00, 35.00)
join dfc
  where dfc.dcp_forms_activity_id = d.dcp_forms_activity_id
  and dfc.parent_entity_name = "CLINICAL_EVENT"
join ce
  where ce.parent_event_id = dfc.parent_entity_id
  and ce.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
  and ce.result_status_cd in (25.00,33.00,35.00)
  and ce.event_cd =  2417652201.00
join ce2
  where ce2.parent_event_id = ce.event_id
  and ce2.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
  and ce2.event_end_dt_tm between cnvtdatetime("01-JAN-1970 0000")
  and cnvtdatetime(curdate,curtime3)
  and ce2.result_status_cd in (25.00,33.00,35.00)
join ce3
  where ce3.PARENT_EVENT_id = ce2.EVENT_id
  and ce3.view_level = 1
  and ce3.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
  and ce3.event_tag != "In Error"
  and ce3.event_cd = 2417619797
join p
  where p.person_id = d.person_id
join e
  where e.encntr_id = d.encntr_id
join pr
  where pr.person_id = d.updt_id
  and parser(sParserPrsnl)
order by d.person_id, ce.event_end_dt_tm desc
head report
   cnt = 0
head d.person_id
  if(parser(status_parser))
    cnt = cnt + 1
    if(size(reply->items,5) < cnt)
      stat = alterlist(reply->items,cnt+9)
    endif  
    reply->items[cnt].encntr_id = d.encntr_id
    reply->items[cnt].person_id  = d.person_id
    reply->items[cnt].form_dt_tm   = d.beg_activity_dt_tm
    reply->items[cnt].activity_dt_tm  = format(d.form_dt_tm, "mm/dd/yyyy")
    reply->items[cnt].CoCM_treatment_status = ce3.result_val
    reply->items[cnt].form_parent_event_id = ce3.parent_event_id
    reply->items[cnt].pname = p.name_full_formatted
    reply->items[cnt].date_of_most_recent_contact = format(e.reg_dt_tm, "mm/dd/yyyy")
    reply->items[cnt].fac_desc = uar_get_code_display(e.loc_facility_cd)
    reply->items[cnt].performed_by = trim(pr.name_full_formatted)
    reply->items[cnt].date_episode_of_care_ended = cnvtdate(CURDATE)
    if(ce3.result_val in ("Active", "Relapse prevention"))
      reply->total_number_of_pts_on_caseload = reply->total_number_of_pts_on_caseload + 1
    else
      reply->total_number_of_inactive_pts = reply->total_number_of_inactive_pts + 1
    endif
    if(ce3.result_val = "Relapse prevention")
    	reply->number_of_active_pts_in_relapse_prevention = reply->number_of_active_pts_in_relapse_prevention + 1
    endif      
  endif     
foot report
  reply->count_no_phq_gt30d = cnt
  reply->count_no_gad7_gt30d = cnt
  reply->count_no_auditc_gt30d = cnt
  
  reply->count_inactive_no_phq_gt30d = cnt
  reply->count_inactive_no_gad7_gt30d = cnt
  reply->count_inactive_no_auditc_gt30d = cnt
  stat = alterlist(reply->items,cnt)
with nocounter, time = 180

if(size(reply->items,5)>0)
;---------------------------------------------------------------------------------------------------------------------------------
;Get Referral Order
;---------------------------------------------------------------------------------------------------------------------------------
  select into "nl:" 
  e.loc_facility_cd, o.catalog_type_cd,o.activity_type_cd, o.order_status_cd, o.encntr_id, o.catalog_cd,*
  from orders o,
    encounter e
  plan o
    where expand(num,1,size(reply->items,5), o.person_id, reply->items[num].person_id)
    ;o.person_id = reply->items[dm.seq].pid
    and o.synonym_id =  1535777075.00;.catalog_cd in ( 1466962173.00,1466961443.00,1466954373.00)
    and o.product_id = 0.0
    and o.catalog_type_cd = 249926603.00
    and o.activity_type_cd in (249925330, 249925337)
    and o.order_status_cd not in (2542,2544,2545,2552,643467.00)
  join e
    where e.encntr_id = o.encntr_id
  order by o.person_id, o.orig_order_dt_tm desc
  head o.person_id
    pos = locateval(num,1,size(reply->items,5), o.person_id, reply->items[num].person_id)
    reply->items[pos].fac_desc = uar_get_code_display(e.loc_facility_cd)
  with uar_code(D)
;---------------------------------------------------------------------------------------------------------------------------------
;		Get EMPI
;---------------------------------------------------------------------------------------------------------------------------------
  
  select into "nl:"
  from person_alias empi
  where expand(num,1,size(reply->items,5), empi.person_id, reply->items[num].person_id)
  and empi.person_alias_type_cd = 2
  and empi.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
  and empi.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
  order by empi.person_id
  head empi.person_id
    pos = locateval(num,1,size(reply->items,5), empi.person_id, reply->items[num].person_id)
    reply->items[pos].empi = cnvtalias(empi.alias, empi.alias_pool_cd)
  with nocounter, expand = 2

;---------------------------------------------------------------------------------------------------------------------------------
;		Get other detail from Powerform
;---------------------------------------------------------------------------------------------------------------------------------
  select into "nl:"
   datestring = build2(substring(5,2,substring(3,8,ce.result_val)),"/",substring(7,2,substring(3,8,ce.result_val))
  ,"/",substring(1,4,substring(3,8,ce.result_val)))
  from clinical_event ce,
    ce_date_result cdr
  plan ce
    where expand(num,1,size(reply->items,5), ce.parent_event_id, reply->items[num].form_parent_event_id)
    and ce.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)    
    and ce.result_status_cd in (25.00,33.00,35.00)    
    and ce.event_cd in(3395348155,2417628261,2417629549,4202997599,2417619091,2417621191)
  join cdr
    where cdr.event_id = outerjoin(ce.event_id)
    and cdr.valid_until_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))
  order by ce.person_id, ce.event_cd
  head ce.person_id
    pos = locateval(num,1,size(reply->items,5), ce.parent_event_id, reply->items[num].form_parent_event_id)                    
  head ce.event_cd
    case(ce.event_cd)
      of 3395348155: reply->items[pos].frequency_of_cocm_visit = trim(ce.result_val,3)
      of 2417628261: 
        reply->items[pos].date_of_last_psych_consult = datestring
        reply->Number_of_Pts_w_at_least_1_Psychiatric_Case_Review_Date_Recorded = 
        reply->Number_of_Pts_w_at_least_1_Psychiatric_Case_Review_Date_Recorded + 1
      of 2417629549: 
        reply->items[pos].cocm_flag = trim(ce.result_val,3)
        if(trim(ce.result_val,3) = "Needs Psych Consult")
        	reply->number_of_pts_flagged = reply->number_of_pts_flagged + 1
        endif
      of 4202997599: reply->items[pos].target_scale = trim(ce.result_val,3)
      of 2417619091: 
        reply->items[pos].episodes_of_care_begin = format(cdr.result_dt_tm,"mm/dd/yyyy")
        reply->items[pos].date_episode_of_care_began = cnvtdate(cdr.result_dt_tm)
      of 2417621191: 
        reply->items[pos].episodes_of_care_end = format(cdr.result_dt_tm,"mm/dd/yyyy")
        reply->items[pos].date_episode_of_care_ended = cnvtdate(cdr.result_dt_tm)
    endcase
  foot ce.person_id
    if(textlen(trim(reply->items[pos].target_scale,3)) > 0)
      if(findstring("PHQ-9",reply->items[pos].target_scale,1,1) > 0)
        reply->items[pos].ts_phq = 1
      endif
      if(findstring("GAD-7",reply->items[pos].target_scale,1,1) > 0)
        reply->items[pos].ts_gad = 1
      endif
      if(findstring("Audit-C",reply->items[pos].target_scale,1,1) > 0)
        reply->items[pos].ts_auditc = 1
      endif
    endif
  with expand = 2
;---------------------------------------------------------------------------------------------------------------------------------
;		Get Episode of Care Begin
;---------------------------------------------------------------------------------------------------------------------------------
  select into "nl:"
  from clinical_event ce,
    clinical_event ce2,	   
    clinical_event ce3,
    ce_date_result cdr
  plan ce
    where expand(num,1,size(reply->items,5), ce.parent_event_id, reply->items[num].form_parent_event_id)
    and ce.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)    
    and ce.result_status_cd in (25.00,33.00,35.00)        
  join ce2
    where ce2.parent_event_id = ce.event_id
    and ce2.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
  join ce3
    where ce3.PARENT_EVENT_id = ce2.EVENT_id
    and ce3.view_level = 1
    and ce3.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
  join cdr
    where cdr.event_id = ce3.event_id
    and cdr.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
    and ce3.event_cd in(2417619091,2417621191)
  order by ce.person_id, ce3.event_cd
  head ce.person_id
    pos = locateval(num,1,size(reply->items,5), ce.parent_event_id, reply->items[num].form_parent_event_id)                    
  head ce3.event_cd
    case(ce3.event_cd)    
      of 2417619091: 
        reply->items[pos].episodes_of_care_begin = format(cdr.result_dt_tm,"mm/dd/yyyy")
        reply->items[pos].date_episode_of_care_began = cnvtdate(cdr.result_dt_tm)
      of 2417621191: 
        reply->items[pos].episodes_of_care_end = format(cdr.result_dt_tm,"mm/dd/yyyy")
        reply->items[pos].date_episode_of_care_ended = cnvtdate(cdr.result_dt_tm)
    endcase
  with expand = 2  
;---------------------------------------------------------------------------------------------------------------------------------
;		Get Next Appointment info
;---------------------------------------------------------------------------------------------------------------------------------
  select into "nl:"
  from sch_appt a
    ,sch_event se
  plan a
    where expand(num,1,size(reply->items,5), a.person_id, reply->items[num].person_id)
    and a.beg_dt_tm > cnvtdatetime(curdate, curtime3)
    and a.sch_role_cd = 4572.00
    and a.state_meaning in ("SCHEDULED", "CONFIRMED", "CHECKED IN")
  join se
    where se.sch_event_id = a.sch_event_id
    and se.appt_type_cd in (1710956145.00;  IN PERSON COLLABORATIVE CARE
                  , 2336441091.00  ;NEW COCM VIDEO VISIT
                  , 1541034873.00  ;New Patient Collaborative Care
                  , 2336444691.00  ;RETURN COCM VIDEO VISIT
                  , 1710958511.00  ;TELEPHONE COLLABORATIVE CARE
                  , 2576688103.00  ;TELEPHONE NEW PT COCM
    )
  order by a.person_id, a.beg_dt_tm, a.schedule_seq desc
  head a.person_id
    pos = locateval(num,1,size(reply->items,5), a.person_id, reply->items[num].person_id)
    reply->items[pos].next_follow_up_due_date = format(a.beg_dt_tm, "mm/dd/yyyy hh:mm;;d")
    if(reply->items[pos].CoCM_treatment_status in("Active", "Relapse prevention"))
      reply->Number_of_Pts_w_1_Followup_Contacts = reply->Number_of_Pts_w_1_Followup_Contacts + 1
    else
      reply->number_of_inactive_pts_w_1_followup_contacts = reply->number_of_inactive_pts_w_1_followup_contacts + 1
    endif      
  foot report
    reply->mean_number_of_followup_contacts =(reply->Number_of_Pts_w_1_Followup_Contacts / reply->Total_Number_of_Pts_on_Caseload)
    reply->mean_number_of_inactive_followup_contacts =(reply->number_of_inactive_pts_w_1_followup_contacts / reply->Total_Number_of_Pts_on_Caseload)
  with nocounter, expand = 2
  
;---------------------------------------------------------------------------------------------------------------------------------
;	Get scores
;---------------------------------------------------------------------------------------------------------------------------------
  ;declare tdss_72cd = f8 with protect,constant(102264072.00)
	;declare gad7s_72cd = f8 with protect,constant(823726295.00)
	
	
;	1 mean_initial_gad7 = f8
;	1 mean_final_gad7 = f8
;	1 total_initial_gad7 = f8
;	1 total_final_gad7 = f8
;	1 count_initial_gad7 = f8
;	1 count_final_gad7 = f8
;	1 count_gad7_w_fu = f8
;	1 count_no_phq_gad7 = f8
;	1 count_not_in_range_gad7 = f8 
;	
	select into "nl:"
	from (dummyt d with seq = size(reply->items,5)),
	 clinical_event ce
	plan d
	 where reply->items[d.seq].person_id > 0
   and reply->items[d.seq].date_episode_of_care_began > 0
	join ce
		where ce.person_id = reply->items[d.seq].person_id
		and ce.event_cd in (102264072,823726295,712404847,1734153589)
		and ce.clinsig_updt_dt_tm >= cnvtdate(reply->items[d.seq].date_episode_of_care_began)
		and ce.clinsig_updt_dt_tm <= cnvtdate(reply->items[d.seq].Date_Episode_of_Care_Ended)
		and ce.valid_until_dt_tm = cnvtdatetime(cnvtdate(12312100),0000)
		and ce.view_level = 1
    and ce.result_status_cd in (25.00,33.00,35.00)
	order by d.seq, ce.event_cd, ce.event_end_dt_tm
	head d.seq
    null
  head ce.event_cd
    case(ce.event_cd)
		  of 102264072:
		    if(reply->items[d.seq].ts_phq = 1 or reply->items[d.seq].CoCM_treatment_status = 'Inactive')
          reply->items[d.seq].initial_phq9_score = ce.result_val
          reply->items[d.seq].initial_phq9_date = format(ce.performed_dt_tm, "mm/dd/yyyy")
          if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
            reply->count_initial_phq9 = reply->count_initial_phq9 + 1
            reply->total_initial_phq9 = reply->total_initial_phq9 + cnvtreal(ce.result_val)
          else
            reply->count_inactive_initial_phq9 = reply->count_inactive_initial_phq9 + 1
            reply->total_inactive_initial_phq9 = reply->total_inactive_initial_phq9 + cnvtreal(ce.result_val)
          endif            
        endif
      of 823726295:
        if(reply->items[d.seq].ts_gad = 1 or reply->items[d.seq].CoCM_treatment_status = 'Inactive')
          reply->items[d.seq].initial_gad7_score = ce.result_val
          reply->items[d.seq].initial_gad7_date = format(ce.performed_dt_tm, "mm/dd/yyyy")
          if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
            reply->count_initial_gad7 = reply->count_initial_gad7 + 1
            reply->total_initial_gad7 = reply->total_initial_gad7 + cnvtreal(ce.result_val)
          else
            reply->count_inactive_initial_gad7 = reply->count_inactive_initial_gad7 + 1
            reply->total_inactive_initial_gad7 = reply->total_inactive_initial_gad7 + cnvtreal(ce.result_val)
          endif            
        endif
      of 712404847:
        if(reply->items[d.seq].ts_auditc = 1 or reply->items[d.seq].CoCM_treatment_status = 'Inactive')
          reply->items[d.seq].initial_auditc_score = ce.result_val	
          reply->items[d.seq].initial_auditc_date = format(ce.performed_dt_tm, "mm/dd/yyyy")
          if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
            reply->count_initial_auditc = reply->count_initial_auditc + 1
            reply->total_initial_auditc = reply->total_initial_auditc + cnvtreal(ce.result_val)	   					
          else
            reply->count_inactive_initial_auditc = reply->count_inactive_initial_auditc + 1
            reply->total_inactive_initial_auditc = reply->total_inactive_initial_auditc + cnvtreal(ce.result_val)	   					
          endif
        endif
      of 1734153589:
        reply->items[d.seq].initial_gad2_score = ce.result_val	
        reply->items[d.seq].initial_gad2_date = format(ce.performed_dt_tm, "mm/dd/yyyy")	   					                
    endcase
  foot ce.event_cd
		case(ce.event_cd)
		  of 102264072:
		    if(reply->items[d.seq].ts_phq = 1 or reply->items[d.seq].CoCM_treatment_status = 'Inactive')
          reply->items[d.seq].last_phq9_score = ce.result_val
          reply->items[d.seq].last_phq9_date = format(ce.performed_dt_tm, "mm/dd/yyyy")
          if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
            reply->count_final_phq9 = reply->count_final_phq9 + 1
            reply->total_final_phq9 = reply->total_final_phq9 + cnvtreal(ce.result_val)
          else
            reply->count_inactive_final_phq9 = reply->count_inactive_final_phq9 + 1
            reply->total_inactive_final_phq9 = reply->total_inactive_final_phq9 + cnvtreal(ce.result_val)
          endif            
          if(ce.event_end_dt_tm > cnvtlookbehind("30,D"))
;reply->count_no_phq_gt30d was initially set to total count of patient, remove 1 from that number          
            reply->count_no_phq_gt30d = reply->count_no_phq_gt30d - 1
          endif
        endif
      of 823726295:
        if(reply->items[d.seq].ts_gad = 1 or reply->items[d.seq].CoCM_treatment_status = 'Inactive')
          reply->items[d.seq].last_gad7_score = ce.result_val
          reply->items[d.seq].last_gad7_date = format(ce.performed_dt_tm, "mm/dd/yyyy")
          if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
            reply->count_final_gad7 = reply->count_final_gad7 + 1
            reply->total_final_gad7 = reply->total_final_gad7 + cnvtreal(ce.result_val)
          else
            reply->count_inactive_final_gad7 = reply->count_inactive_final_gad7 + 1
            reply->total_inactive_final_gad7 = reply->total_inactive_final_gad7 + cnvtreal(ce.result_val)
          endif            
          if(ce.event_end_dt_tm > cnvtlookbehind("30,D"))
;reply->count_no_phq_gt30d was initially set to total count of patient, remove 1 from that number          
            reply->count_no_gad7_gt30d = reply->count_no_gad7_gt30d - 1
          endif
        endif
      of 712404847:
        if(reply->items[d.seq].ts_auditc = 1 or reply->items[d.seq].CoCM_treatment_status = 'Inactive')
          reply->items[d.seq].last_auditc_score = ce.result_val	
          reply->items[d.seq].last_auditc_date = format(ce.performed_dt_tm, "mm/dd/yyyy")	
          if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
            reply->count_final_auditc = reply->count_final_auditc + 1
            reply->total_final_auditc = reply->total_final_auditc + cnvtreal(ce.result_val) 
          else            
            reply->count_inactive_final_auditc = reply->count_inactive_final_auditc + 1
            reply->total_inactive_final_auditc = reply->total_final_auditc + cnvtreal(ce.result_val) 
          endif  
          
          if(ce.event_end_dt_tm > cnvtlookbehind("30,D"))
;reply->count_no_phq_gt30d was initially set to total count of patient, remove 1 from that number          
            reply->count_no_auditc_gt30d = reply->count_no_auditc_gt30d - 1
          endif  					
        endif
      of 1734153589:
        reply->items[d.seq].last_gad2_score = ce.result_val	
        reply->items[d.seq].last_gad2_date = format(ce.performed_dt_tm, "mm/dd/yyyy")        
    endcase
  foot d.seq
;-----------------------------------PHQ-9-----------------------------------------------------------------------------------------  
    if(reply->items[d.seq].initial_phq9_date = reply->items[d.seq].last_phq9_date)    
      reply->items[d.seq].phq9_change = "99"
      reply->items[d.seq].perc_change_phq9_score = "99%"
    else
      reply->items[d.seq].phq9_change = 
      cnvtstring(cnvtreal(reply->items[d.seq].last_phq9_score) - cnvtreal(reply->items[d.seq].initial_phq9_score))
      reply->items[d.seq].perc_change_phq9_score = 
      trim(build2((cnvtreal(reply->items[d.seq].phq9_change)/cnvtreal(reply->items[d.seq].initial_phq9_score)*100),"%"),3)
      perc_change_phq9_score = cnvtreal(reply->items[d.seq].phq9_change)/cnvtreal(reply->items[d.seq].initial_phq9_score)
      if(perc_change_phq9_score < 0.05 or perc_change_phq9_score>=0.5)
        if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
          reply->count_not_in_range_phq = reply->count_not_in_range_phq + 1
        else
          reply->count_inactive_not_in_range_phq = reply->count_inactive_not_in_range_phq + 1
        endif
      endif
    endif
    
    if(reply->items[d.seq].next_follow_up_due_date > " " and reply->items[d.seq].phq9_change > " ")
      if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
        reply->count_phq_w_fu = reply->count_phq_w_fu + 1
      else
        reply->count_inactive_phq_w_fu = reply->count_inactive_phq_w_fu + 1
      endif
    endif
;-----------------------------------GAD-7-----------------------------------------------------------------------------------------    
    if(reply->items[d.seq].initial_gad7_date = reply->items[d.seq].last_gad7_date)    
      reply->items[d.seq].gad7_change = "99"
      reply->items[d.seq].perc_change_gad7_score = "99%"
    else
      reply->items[d.seq].gad7_change = 
      cnvtstring(cnvtreal(reply->items[d.seq].last_gad7_score) - cnvtreal(reply->items[d.seq].initial_gad7_score))
      reply->items[d.seq].perc_change_gad7_score = 
      trim(build2((cnvtreal(reply->items[d.seq].gad7_change)/cnvtreal(reply->items[d.seq].initial_gad7_score)*100),"%"),3)
      
      perc_change_gad7_score = cnvtreal(reply->items[d.seq].gad7_change)/cnvtreal(reply->items[d.seq].initial_gad7_score)
      if(perc_change_gad7_score < 0.10 or perc_change_gad7_score>=0.5)
        if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
          reply->count_not_in_range_gad7 = reply->count_not_in_range_gad7 + 1
        else
          reply->count_inactive_not_in_range_gad7 = reply->count_inactive_not_in_range_gad7 + 1
        endif
      endif      
    endif
    
    if(reply->items[d.seq].next_follow_up_due_date > " " and reply->items[d.seq].gad7_change > " ")
      if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
        reply->count_gad7_w_fu = reply->count_gad7_w_fu + 1
      else
        reply->count_inactive_gad7_w_fu = reply->count_inactive_gad7_w_fu + 1
      endif
    endif
;-----------------------------------Audit-C---------------------------------------------------------------------------------------
    if(reply->items[d.seq].last_auditc_date = reply->items[d.seq].initial_auditc_date)    
      reply->items[d.seq].auditc_change = "99"
      reply->items[d.seq].perc_change_auditc_score = "99%"
    else
      reply->items[d.seq].auditc_change = 
      cnvtstring(cnvtreal(reply->items[d.seq].last_auditc_score) - cnvtreal(reply->items[d.seq].initial_auditc_score))
      reply->items[d.seq].perc_change_auditc_score = 
      trim(build2((cnvtreal(reply->items[d.seq].auditc_change)/cnvtreal(reply->items[d.seq].initial_auditc_score)*100),"%"),3)
      
      perc_change_auditc_score = cnvtreal(reply->items[d.seq].auditc_change)/cnvtreal(reply->items[d.seq].initial_auditc_score)
      if(perc_change_auditc_score < 0.05 or perc_change_auditc_score>=0.5)
        if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
          reply->count_not_in_range_auditc = reply->count_not_in_range_auditc + 1
        else
          reply->count_inactive_not_in_range_auditc = reply->count_inactive_not_in_range_auditc + 1
        endif
      endif
    endif
    if(reply->items[d.seq].next_follow_up_due_date > " " and reply->items[d.seq].auditc_change > " ")
      if(reply->items[d.seq].CoCM_treatment_status in("Active", "Relapse prevention"))
        reply->count_auditc_w_fu = reply->count_auditc_w_fu + 1
      else
        reply->count_inactive_auditc_w_fu = reply->count_inactive_auditc_w_fu + 1
      endif
    endif
  foot report
    reply->mean_initial_phq9 = (reply->total_initial_phq9 / reply->count_initial_phq9)
    reply->mean_final_phq9 = (reply->total_final_phq9 / reply->count_final_phq9)    
    reply->mean_inactive_initial_phq9 = (reply->total_inactive_initial_phq9 / reply->count_inactive_initial_phq9)
    reply->mean_inactive_final_phq9 = (reply->total_inactive_final_phq9 / reply->count_inactive_final_phq9)
    
    reply->mean_initial_gad7 = (reply->total_initial_gad7 / reply->count_initial_gad7)
    reply->mean_final_gad7 = (reply->total_final_gad7 / reply->count_final_gad7)
    reply->mean_inactive_initial_gad7 = (reply->total_inactive_initial_gad7 / reply->count_inactive_initial_gad7)
    reply->mean_inactive_final_gad7 = (reply->total_inactive_final_gad7 / reply->count_inactive_final_gad7)
    
    reply->mean_initial_auditc = (reply->total_initial_auditc / reply->count_initial_auditc)
    reply->mean_final_auditc = (reply->total_final_auditc / reply->count_final_auditc)
    reply->mean_inactive_initial_auditc = (reply->total_inactive_initial_auditc / reply->count_inactive_initial_auditc)
    reply->mean_inactive_final_auditc = (reply->total_inactive_final_auditc / reply->count_inactive_final_auditc)
	with nocounter, orahintcbo("INDEX(CE XIE24CLINICAL_EVENT)")

;---------------------------------------------------------------------------------------------------------------------------------
; Output
;---------------------------------------------------------------------------------------------------------------------------------
  if($report_type = "D")
    SELECT into $OUTDEV
      Facility = substring(1,100,reply->items[d.seq].fac_desc),
      EMPI = substring(1, 15,reply->items[d.seq].empi),
      Name = substring(1, 120,reply->items[d.seq].pname),
      AUTHOR_NAME = substring(1,120,reply->items[d.seq].performed_by),
      form_date = substring(1,12,reply->items[d.seq].activity_dt_tm),
      date_episodes_of_care_began = substring(1,30,reply->items[d.seq].episodes_of_care_begin),
      date_episodes_of_care_ended = substring(1,30,reply->items[d.seq].episodes_of_care_end),
      cocm_treatment_status = substring(1,30,reply->items[d.seq].cocm_treatment_status),
      Discussion_w_Psych_Consultant = substring(1,30,reply->items[d.seq].cocm_flag),
      last_psych_consult_date = substring(1,30,reply->items[d.seq].date_of_last_psych_consult),
      date_next_follow_up_due = substring(1,30,reply->items[d.seq].next_follow_up_due_date),
      
      ;form_parent_event_id = reply->items[d.seq].form_parent_event_id,
      ;activity_dt_tm = substring(1, 16, reply->items[d.seq].activity_dt_tm),
      target_scale = substring(1,30,reply->items[d.seq].target_scale),
      
      
      initial_phq9_score = substring(1,30,reply->items[d.seq].initial_phq9_score),
      initial_phq9_date = substring(1,30,reply->items[d.seq].initial_phq9_date),
      last_phq9_score = substring(1,30,reply->items[d.seq].last_phq9_score),
      last_phq9_date = substring(1,30,reply->items[d.seq].last_phq9_date),
      change_in_phq9_during_active = substring(1,30,reply->items[d.seq].phq9_change),
      Percent_Change_PHQ9 = substring(1,30,reply->items[d.seq].perc_change_phq9_score),
      
;      initial_gad2_score = substring(1,30,reply->items[d.seq].initial_gad2_score),
;      initial_gad2_date = substring(1,30,reply->items[d.seq].initial_gad2_date),
;      last_gad2_score = substring(1,30,reply->items[d.seq].last_gad2_score),
;      last_gad2_date = substring(1,30,reply->items[d.seq].last_gad2_date),
      
      initial_gad7_score = substring(1,30,reply->items[d.seq].initial_gad7_score),
      initial_gad7_date = substring(1,30,reply->items[d.seq].initial_gad7_date),
      last_gad7_score = substring(1,30,reply->items[d.seq].last_gad7_score),
      last_gad7_date = substring(1,30,reply->items[d.seq].last_gad7_date),
      change_in_gad7_during_active = substring(1,30,reply->items[d.seq].gad7_change),
      Percent_Change_GAD7 = substring(1,30,reply->items[d.seq].perc_change_gad7_score),
      
      initial_auditc_score = substring(1,30,reply->items[d.seq].initial_auditc_score),
      initial_auditc_date = substring(1,30,reply->items[d.seq].initial_auditc_date),
      last_auditc_score = substring(1,30,reply->items[d.seq].last_auditc_score),
      last_auditc_date = substring(1,30,reply->items[d.seq].last_auditc_date),
      change_in_auditc_during_active = substring(1,30,reply->items[d.seq].auditc_change),
      Percent_Change_AUDITC = substring(1,30,reply->items[d.seq].perc_change_auditc_score),
      
      date_of_most_recent_contact = substring(1,30,reply->items[d.seq].date_of_most_recent_contact),  
      frequence_of_visit = substring(1,30,reply->items[d.seq].frequency_of_cocm_visit)
    
    from (dummyt d with seq = size(reply->items, 5))
    plan d
    ;where detail_rec->pat_list[d1.seq].CoCM_status_flag in ($cocmStatus)
    ; ORDER BY FACILITY
    WITH NOCOUNTER, SEPARATOR=" ", FORMAT
  else
    call summaryHeaders(0)
    SELECT into $OUTDEV
      A = substring(1,300,reply->summary[d.seq].header),
      B = substring(1,300,reply->summary[d.seq].content1),
      B = substring(1,300,reply->summary[d.seq].content2),
      B = substring(1,300,reply->summary[d.seq].content3)
    from (dummyt d with seq = size(reply->summary, 5)) 
    with nocounter, separator=" ", format
 
    
  endif
endif

subroutine summaryHeaders(null)
  set stat = alterlist(reply->summary,24)
  set reply->summary[1].header = "Total Number of Pts. on Caseload(Active + Relapse Prevention)"
  set reply->summary[1].content1 = cnvtstring(reply->total_number_of_pts_on_caseload)
  set reply->summary[2].header = "Number of Active Pts. in Relapse Prevention"
  set reply->summary[2].content1 = cnvtstring(reply->number_of_active_pts_in_relapse_prevention)
  set reply->summary[3].header = "Number of Pts. Flagged for Discussion w/ Psychiatric Consultant"
  set reply->summary[3].content1 = cnvtstring(reply->number_of_pts_flagged)
  set reply->summary[4].header = "Number of Pts. w/ at least 1 Psychiatric Case Review Date Recorded"
  set reply->summary[4].content1 = cnvtstring(reply->number_of_pts_w_at_least_1_psychiatric_case_review_date_recorded)
  ;set reply->summary[5].header = "Number of Pts. Not Improving and w/o a Psychiatric Case Review Date Recorded"
  
  set reply->summary[5].header = "Number of Pts. w/ 1+ Follow-up Contacts"
  set reply->summary[5].content1 = cnvtstring(reply->number_of_pts_w_1_followup_contacts)
  
  set reply->summary[7].header = "Mean Number of Follow-up Contacts"
  set reply->summary[7].content1 = cnvtstring(reply->mean_number_of_followup_contacts)
  
  set reply->summary[8].header = "Caseload Statistics (Active)"
  set reply->summary[8].content1 = "PHQ-9"
  set reply->summary[8].content2 = "GAD-7"
  set reply->summary[8].content3 = "Audit C"
  
  set reply->summary[9].header = "Mean Initial Score"
  set reply->summary[9].content1 = cnvtstring(reply->mean_initial_phq9)
  set reply->summary[9].content2 = cnvtstring(reply->mean_initial_gad7)
  set reply->summary[9].content3 = cnvtstring(reply->mean_initial_auditc)  
  
  set reply->summary[10].header = "Mean Last Available Score"
  set reply->summary[10].content1 = cnvtstring(reply->mean_final_phq9)
  set reply->summary[10].content2 = cnvtstring(reply->mean_final_gad7)
  set reply->summary[10].content3 = cnvtstring(reply->mean_final_auditc)
  
  set reply->summary[11].header = "Number of Pts. w/ an Initial Score Recorded"
  set reply->summary[11].content1 = cnvtstring(reply->count_initial_phq9)
  set reply->summary[11].content2 = cnvtstring(reply->count_initial_gad7)
  set reply->summary[11].content3 = cnvtstring(reply->count_initial_auditc)
  
  set reply->summary[12].header = "Number of Pts. w/ 1+ Follow-up Scores Recorded"
  set reply->summary[12].content1 = cnvtstring(reply->count_phq_w_fu)
  set reply->summary[12].content2 = cnvtstring(reply->count_gad7_w_fu)
  set reply->summary[12].content3 = cnvtstring(reply->count_auditc_w_fu)
  
  set reply->summary[13].header = "Number of Pts. w/ No Score Recorded in Last 30 Days"
  set reply->summary[13].content1 = cnvtstring(reply->count_no_phq_gt30d)
  set reply->summary[13].content2 = cnvtstring(reply->count_no_gad7_gt30d)
  set reply->summary[13].content3 = cnvtstring(reply->count_no_auditc_gt30d)
  
  set reply->summary[14].header = "Number of Pts. w/ Score Improvement from Initial Score (PHQ-9 and Audit-C <5% or >=50%. GAD-7 <10% or >=50%)" 
  set reply->summary[14].content1 = cnvtstring(reply->count_not_in_range_phq)
  set reply->summary[14].content2 = cnvtstring(reply->count_not_in_range_gad7)
  set reply->summary[14].content3 = cnvtstring(reply->count_not_in_range_auditc)
  
  set reply->summary[16].header = "Caseload Statistics (Inactive/Discharged)"
  set reply->summary[16].content1 = "PHQ-9"
  set reply->summary[16].content2 = "GAD-7"
  set reply->summary[16].content3 = "Audit C"
  
  set reply->summary[17].header = "Mean Initial Score"
  set reply->summary[17].content1 = cnvtstring(reply->mean_inactive_initial_phq9)
  set reply->summary[17].content2 = cnvtstring(reply->mean_inactive_initial_gad7)
  set reply->summary[17].content3 = cnvtstring(reply->mean_inactive_initial_auditc)  
  
  set reply->summary[18].header = "Mean Last Available Score"
  set reply->summary[18].content1 = cnvtstring(reply->mean_inactive_final_phq9)
  set reply->summary[18].content2 = cnvtstring(reply->mean_inactive_final_gad7)
  set reply->summary[18].content3 = cnvtstring(reply->mean_inactive_final_auditc)
  
  set reply->summary[19].header = "Number of Pts. w/ an Initial Score Recorded"
  set reply->summary[19].content1 = cnvtstring(reply->count_inactive_initial_phq9)
  set reply->summary[19].content2 = cnvtstring(reply->count_inactive_initial_gad7)
  set reply->summary[19].content3 = cnvtstring(reply->count_inactive_initial_auditc)
  
  set reply->summary[20].header = "Number of Pts. w/ 1+ Follow-up Scores Recorded"
  set reply->summary[20].content1 = cnvtstring(reply->count_inactive_phq_w_fu)
  set reply->summary[20].content2 = cnvtstring(reply->count_inactive_gad7_w_fu)
  set reply->summary[20].content3 = cnvtstring(reply->count_inactive_auditc_w_fu)
  
  set reply->summary[21].header = "Number of Pts. w/ No Score Recorded in Last 30 Days"
  set reply->summary[21].content1 = cnvtstring(reply->count_inactive_no_phq_gt30d)
  set reply->summary[21].content2 = cnvtstring(reply->count_inactive_no_gad7_gt30d)
  set reply->summary[21].content3 = cnvtstring(reply->count_inactive_no_auditc_gt30d)
  
  set reply->summary[22].header = "Number of Pts. w/ Score Improvement from Initial Score (PHQ-9 and Audit-C <5% or >=50%. GAD-7 <10% or >=50%)" 
  set reply->summary[22].content1 = cnvtstring(reply->count_inactive_not_in_range_phq)
  set reply->summary[22].content2 = cnvtstring(reply->count_inactive_not_in_range_gad7)
  set reply->summary[22].content3 = cnvtstring(reply->count_inactive_not_in_range_auditc)
  
  
  ;set reply->summary[17].header = "Number of Pts. w/ PHQ-9 Score <5 or ?50% Improvement from Initial Score"
  ;set reply->summary[17].content = cnvtstring(reply->count_not_in_range_phq)
  
  
  ;set reply->summary[5].content = reply->number_of_pts_w_at_least_1_psychiatric_case_review_date_recorded
end


	
end
go
