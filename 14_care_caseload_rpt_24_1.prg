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
 001  04/11/2024  Simeon Akinsulie 			346606		Initial release
*********************************END OF ALL MODCONTROL BLOCKS*******************************************************************/
drop program 14_care_caseload_rpt_24_1:dba go
create program 14_care_caseload_rpt_24_1:dba

prompt 
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to. 

with OUTDEV


/**************************************************************
; DVDev INCLUDE Files
**************************************************************/
;%i cust_script:14_cps_get_prompt_list.inc
;%i cust_script:14_sc_cps_parse_date_subs.inc

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
;
;if(IsPromptAny(parameter2($cocmStatus)) OR IsPromptEmpty(parameter2($cocmStatus)))
;  set status_parser = '1=1'
;else
;  set status_parser = trim(GetPromptList(parameter2($cocmStatus), " ce3.result_val"), 3)
;endif
;
;if(IsPromptAny(parameter2($PRSNL_LIST)) OR IsPromptEmpty(parameter2($PRSNL_LIST)))
;  set sParserPrsnl = '1=1'
;else
;  set sParserPrsnl = trim(GetPromptList(parameter2($PRSNL_LIST), " pr.person_id"), 3)
;endif
;

free record reply
record reply(
  1 items[*]
    2 person_id = f8
    2 encntr_id = f8
    2 p_reg_date_dq8 = dq8
    2 fac_desc = vc
    2 fin = vc
    2 empi = vc
    2 pname = vc
    2 form_dt_tm = dq8
    2 form_dt_tm_vc = vc
    2 cocm_form_id = f8
    2 cocm_form_ref_id = f8
    2 ce_parent_event_id = f8
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
    2 CoCM_status_ind = i4
    2 CoCM_status_flag = i2 ;2 - Relapse prevention 1 - Active; 0 Inactive
    2 CoCM_pt_Flag = vc
    2 next_follow_up_due_date = vc
    
    2 status_dt = vc
    2 treatmnt_status = vc
    2 treatmnt_status_date = vc
    2 flag = vc
    2 eps_beg_dt = vc
    2 eps_end_dt = vc
    2 episode_begin = dq8
    2 episode_end = dq8
    2 episode_begin_pid = f8
    2 episode_end_pid = f8
    2 last_physc_cnst = vc
    2 since_last_physc_cnst = i4
    2 first_cocm_appt = vc
    2 last_cocm_appt = vc
    2 next_cocm_appt = vc
    2 time_in_treatmnt = vc
    2 target_scale = vc
    2 baseline = vc
    2 current = vc
    2 comp_target = vc
    2 outreach = vc
    2 s_comment = vc
    2 durr_total = i4
    2 next_fu_due_date = vc
    2 next_fu_past_due = i4
    2 care_manager = vc
    2 cocm_flag = vc
    2 visit_freq = vc
    2 visit_freq_lbl = vc
    2 episode_of_care = vc
    2 practice_location = vc
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
    
    2 form_name = vc
    2 form_date = vc
)

;---------------------------------------------------------------------------------------------------------------------------------
; Main Query
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"     
  eoc = cnvtreal(ce5.result_val), 
  eoc_begin = format(cdrb.result_dt_tm,"mm/dd/yyyy;;Q"),;substring(3,8,epb.result_val),
  eoc_end = format(cdre.result_dt_tm,"mm/dd/yyyy;;Q");substring(3,8,epe.result_val),
from dcp_forms_activity   d        
  ,dcp_forms_activity_comp dfc        
  ,clinical_event ce       
  ,clinical_event ce2    
  ,clinical_event ce3    
  ,clinical_event ce4    
  ,clinical_event ce5    
  ,clinical_event r_fac
  ,clinical_event epb    
  ,clinical_event epe    
  ,ce_date_result cdrb
  ,ce_date_result cdre
  ,person p    
  ,prsnl pr    
  ,encounter e  
plan d        
  where d.dcp_forms_ref_id in (27852023149.00,25562326477.00, 25562361699.00)
  and  d.active_ind  = 1    
  and d.form_status_cd in(25.00, 34.00, 35.00)    
  ;and d.person_id = 2280439
join dfc        
  where dfc.dcp_forms_activity_id = d.dcp_forms_activity_id        
  and dfc.parent_entity_name = "CLINICAL_EVENT"    
join ce        
  where ce.parent_event_id = dfc.parent_entity_id        
  and ce.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)        
  and ce.result_status_cd in (25.00,33.00,35.00)       
  and ((ce.event_cd = 4824728385.00 and d.dcp_forms_ref_id = 25562361699.00) 
      or (ce.event_cd = 4824718241.00 and d.dcp_forms_ref_id =25562326477.00)
      or (ce.event_cd = 11895.00 and d.dcp_forms_ref_id =27852023149.00))  
join ce2    
  where ce2.parent_event_id = ce.event_id        
  and ce2.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)    
  ;and ce2.event_end_dt_tm between cnvtdatetime("01-JAN-1970 0000")    
  ;and cnvtdatetime(curdate,curtime3)    
  and ce2.result_status_cd in (25.00,33.00,35.00)  
join ce3    
  where ce3.PARENT_EVENT_id = ce2.EVENT_id    
  and ce3.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)    
  and ce3.event_tag != "In Error"  
join ce4    
  where ce4.PARENT_EVENT_id = ce3.EVENT_id    
  and ce4.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)    
  and ce4.event_tag != "In Error"       
join ce5    
  where ce5.PARENT_EVENT_id = ce4.EVENT_id    
  and ce5.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)    
  and ce5.view_level = 1    and ce5.event_tag != "In Error"               
  and ce5.event_cd  = 2417618359.00  
;  and ce5.result_val != '1'
join r_fac
  where r_fac.PARENT_EVENT_id = outerjoin(ce5.parent_event_id)
  and r_fac.valid_until_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))
  and r_fac.view_level = outerjoin(1)
  ;and epb.event_tag != "In Error"               
  and r_fac.event_cd  = outerjoin(5030145475.00);Date Episode of Care begin  
join epb
  where epb.PARENT_EVENT_id = outerjoin(ce5.parent_event_id)
  and epb.valid_until_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))
  and epb.view_level = outerjoin(1)
  ;and epb.event_tag != "In Error"               
  and epb.event_cd  = outerjoin(2417619091.00);Date Episode of Care begin   
join cdrb
  where cdrb.event_id = outerjoin(epb.event_id)
  and cdrb.valid_until_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))    
join epe
  where epe.PARENT_EVENT_id = outerjoin(ce5.parent_event_id)
  and epe.valid_until_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))
  and epe.view_level = outerjoin(1)
  ;and epb.event_tag != "In Error"               
  and epe.event_cd  = outerjoin(2417621191.00);Date Episode of Care Ended      
join cdre
  where cdre.event_id = outerjoin(epe.event_id)
  and cdre.valid_until_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))        
join e    
  where e.encntr_id = ce5.encntr_id      
join p    
  where p.person_id = d.person_id  
join pr    
  where pr.person_id = ce5.updt_id          
order by p.person_id, eoc desc, ce.event_end_dt_tm desc  
head report
   cnt = 0
head ce.person_id
  null
head eoc  
  ;if(parser(status_parser))
    cnt = cnt + 1
    if(size(reply->items,5) < cnt)
      stat = alterlist(reply->items,cnt+9)
    endif  
    reply->items[cnt].person_id = d.person_id
    reply->items[cnt].encntr_id = d.encntr_id
    reply->items[cnt].pname= trim(p.name_full_formatted,3)
    reply->items[cnt].cocm_form_id = d.dcp_forms_activity_id
    reply->items[cnt].cocm_form_ref_id = d.dcp_forms_ref_id
    reply->items[cnt].care_manager = pr.name_full_formatted
    reply->items[cnt].ce_parent_event_id = ce.parent_event_id
    reply->items[cnt].p_reg_date_dq8  = cnvtdatetime(e.reg_dt_tm)
    reply->items[cnt].episode_of_care = ce5.result_val
    reply->items[cnt].eps_beg_dt =  format(cdrb.result_dt_tm,"mm/dd/yyyy;;Q")  
    reply->items[cnt].eps_end_dt = format(cdre.result_dt_tm,"mm/dd/yyyy;;Q")
    
    reply->items[cnt].episode_begin = cnvtdate(cdrb.result_dt_tm)
    reply->items[cnt].episode_begin_pid = ce5.parent_event_id
    
    reply->items[cnt].eps_end_dt = format(cdre.result_dt_tm,"MM/DD/YYYY")
    reply->items[cnt].episode_end_pid = ce5.parent_event_id
    reply->items[cnt].form_name = d.description
    reply->items[cnt].form_date = format(d.beg_activity_dt_tm,"mm/dd/yyyy;;Q")  
    reply->items[cnt].fac_desc = r_fac.result_val
 ;  endif     
foot report
  stat = alterlist(reply->items,cnt)
with nocounter, time = 600;krf 12/16/2024 180

if(size(reply->items,5)>0)
  select ce2.event_cd, ce2.result_val, ce2.event_end_dt_tm,ce.event_cd,ce.event_id,ce4.event_id;, *
  from clinical_event ce
    ,clinical_event ce2
    ,clinical_event ce3
    ,clinical_event ce4
    ,clinical_event ce5
    ,ce_date_result cdr
  plan ce
    where expand(num,1,size(reply->items,5),ce.parent_event_id ,reply->items[num].ce_parent_event_id)
    and ce.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)    
    and ce.event_tag != "In Error"   
  join ce2
    where ce2.parent_event_id = ce.event_id
    and ce2.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)    
    and ce2.event_tag != "In Error"       
  join ce3
    where ce3.parent_event_id = ce2.event_id
    and ce3.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)    
    and ce3.event_tag != "In Error"           
  join ce4
    where ce4.parent_event_id = ce3.event_id
    and ce4.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)    
    and ce4.event_tag != "In Error"               
  join ce5
    where ce5.parent_event_id = ce4.event_id
    ;ce2.person_id =    1616525.00;.parent_event_id = 29263847093.00
    and ce5.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
    and ce5.view_level = 1
    and ce5.event_tag != "In Error" 
    and ce5.result_status_cd in (25.00,33.00,35.00)
    and ce5.event_cd in (2417619797.00,; CoCM treatment status   
                          2417628261.00,;Date of Last Psych Consult   
                          2417629549.00,;CoCM Flag   
                          3395348155.00,;Frequency of CoCM Visit   
                          4986730465.00,;CoCM Team - Care Manager   
;                          2417619091,;Date Episode of Care Began
;                          2417621191,;Date Episode of Care Ended
                          4202997599.00);,;Target Scale    
                          ;2417618359,;Episode of Care
                          ;5030145475.00);Practice Location 
  join cdr
    where cdr.event_id = outerjoin(ce5.event_id)
    and cdr.valid_until_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))
  order by ce.parent_event_id, ce5.event_cd, ce5.event_end_dt_tm desc
  head ce.parent_event_id
    pos = locateval(num,1,size(reply->items,5), ce.parent_event_id ,reply->items[num].ce_parent_event_id)
  detail ;ce5.event_cd
    case(ce5.event_cd)
      of 2417629549.00: ;CoCM flag
        reply->items[pos].flag = ce5.result_val
      of 2417628261.00: ;Date of Last Psych Consult
        reply->items[pos].last_physc_cnst = format(cdr.result_dt_tm,"MM/DD/YYYY")
        reply->items[pos].since_last_physc_cnst = floor(datetimediff(cnvtdatetime(curdate,curtime3), 
        cnvtdatetime(cnvtdate(cdr.result_dt_tm),0), 1))
      of 2417619797.00:
        reply->items[pos].treatmnt_status = ce5.result_val
        reply->items[pos].treatmnt_status_date = format(ce.performed_dt_tm, "mm/dd/yyyy")
;      of 2417619091:
;        reply->items[pos].eps_beg_dt = format(cdr.result_dt_tm,"MM/DD/YYYY")
;        reply->items[pos].episode_begin = cnvtdate(cdr.result_dt_tm)
;        reply->items[pos].episode_begin_pid = ce5.parent_event_id
;      of 2417621191:          
;        reply->items[pos].episode_end = cnvtdate(cdr.result_dt_tm)
;        reply->items[pos].eps_end_dt = format(cdr.result_dt_tm,"MM/DD/YYYY")
;        reply->items[pos].episode_end_pid = ce5.parent_event_id
      of 3395348155.00:
        reply->items[pos].visit_freq = cnvtalphanum(ce5.result_val,1)
        reply->items[pos].visit_freq_lbl = ce5.result_val
        date_lbl = build2(trim(reply->items[pos].visit_freq)," W")
        reply->items[pos].visit_freq = date_lbl
        reply->items[pos].next_fu_due_date = 
        format(cnvtlookahead(date_lbl, CNVTDATETIME(reply->items[pos].p_reg_date_dq8)),"mm/dd/yyyy;;d")
      of 4986730465.00:
        reply->items[pos].care_manager = ce5.result_val
      of 4202997599.00:
        reply->items[pos].target_scale = ce5.result_val
      ;of 2417618359:reply->items[pos].episode_of_care = ce5.result_val
      ;of 5030145475.00:reply->items[pos].fac_desc = ce5.result_val
    endcase
  with nocounter, expand = 1
  call echo("End Powerform DTAs")
  call echo(format(sysdate,"hh:mm:ss;;D")) 
;---------------------------------------------------------------------------------------------------------------------------------
;Update Episode of Care end date where it's missing
;The idea here is that Episode of care end care will only be document at the end of the eposide and prior documentation may not 
;have the information documented
;---------------------------------------------------------------------------------------------------------------------------------  
for(index = 1 to size(reply->items,5)) 
  if(reply->items[index].episode_end > 0)
    select into "nl:"
    from (dummyt d with seq = size(reply->items,5))
    plan d
    where reply->items[d.seq].person_id = reply->items[index].person_id
    and reply->items[d.seq].episode_of_care = reply->items[index].episode_of_care
    and reply->items[d.seq].episode_begin = reply->items[index].episode_begin
    and reply->items[d.seq].episode_end = 0
    order by d.seq
    head d.seq
      reply->items[d.seq].episode_end = reply->items[index].episode_end
      reply->items[d.seq].eps_end_dt = reply->items[index].eps_end_dt
    with nocounter
  endif
endfor 

;---------------------------------------------------------------------------------------------------------------------------------
;Get Referral Order
;---------------------------------------------------------------------------------------------------------------------------------
  select into "nl:"     
  from (dummyt d with seq = size(reply->items,5)),
    orders o,
    encounter e
  plan d
    where reply->items[d.seq].cocm_form_ref_id = 13047318247.00
  join o
    where o.person_id = reply->items[d.seq].person_id
    and o.synonym_id = 1535777075.00;.catalog_cd in ( 1466962173.00,1466961443.00,1466954373.00)
    and o.product_id = 0.0
    and o.catalog_type_cd = 249926603.00
    and o.activity_type_cd in (249925330.00, 249925337.00)
    and o.order_status_cd not in (2542.00,2544.00,2545.00,2552.00,643467.00)
  join e
    where e.encntr_id = o.encntr_id
  order by d.seq, o.orig_order_dt_tm desc
  head d.seq
    reply->items[d.seq].fac_desc = uar_get_code_display(e.loc_facility_cd)
  with uar_code(D)
;---------------------------------------------------------------------------------------------------------------------------------
;		Get EMPI
;---------------------------------------------------------------------------------------------------------------------------------
  
  select into "nl:"
  from (dummyt d with seq = size(reply->items,5)),
    person_alias empi
  plan d
  join empi    
    where empi.person_id = reply->items[d.seq].person_id
    and empi.person_alias_type_cd = 2
    and empi.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
    and empi.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
  order by d.seq
  head d.seq
    reply->items[d.seq].empi = cnvtalias(empi.alias, empi.alias_pool_cd)
  with nocounter
  
;---------------------------------------------------------------------------------------------------------------------------------
;		Get Last Appointment info
;---------------------------------------------------------------------------------------------------------------------------------
  select into "nl:"
  from (dummyt d with seq = size(reply->items,5))
    ,sch_appt a
    ,sch_booking sb
    ,code_value cvc
    ,code_value_group cvg
    ,code_value cv
  plan d
  join a
    where a.person_id = reply->items[d.seq].person_id
    and a.beg_dt_tm < cnvtdatetime(curdate, curtime3)
    and a.sch_role_cd = 4572.00
    and a.state_meaning in ("SCHEDULED", "CONFIRMED", "CHECKED IN")
  join sb
    where sb.booking_id = a.booking_id
  join cvc
    where cvc.code_value = sb.appt_type_cd
  join cvg
    where cvg.child_code_value = cvc.code_value  
  join cv
    where cvg.parent_code_value = cv.code_value  
    and cv.code_value = 5475430039    
;    and sb.appt_type_cd in (1710956145.00;  IN PERSON COLLABORATIVE CARE
;                  , 2336441091.00  ;NEW COCM VIDEO VISIT
;                  , 1541034873.00  ;New Patient Collaborative Care
;                  , 2336444691.00  ;RETURN COCM VIDEO VISIT
;                  , 1710958511.00  ;TELEPHONE COLLABORATIVE CARE
;                  , 2576688103.00  ;TELEPHONE NEW PT COCM
;    )
  order by d.seq, a.beg_dt_tm desc
  head d.seq
    reply->items[d.seq].last_cocm_appt = format(a.beg_dt_tm, "mm/dd/yyyy hh:mm;;d")
  with nocounter, expand = 1

;---------------------------------------------------------------------------------------------------------------------------------
;	Get scores
;---------------------------------------------------------------------------------------------------------------------------------
	select into "nl:"
	from (dummyt d with seq = size(reply->items,5)),
	 clinical_event ce
	plan d
	 where reply->items[d.seq].person_id > 0
   and reply->items[d.seq].episode_begin > 0
	join ce
		where ce.person_id = reply->items[d.seq].person_id
		and ce.event_cd in (102264072.00,823726295.00,712404847.00);,1734153589)
		and ce.clinsig_updt_dt_tm >= cnvtdate(reply->items[d.seq].episode_begin)
		and ((reply->items[d.seq].episode_end > 0 and ce.clinsig_updt_dt_tm <= cnvtdate(reply->items[d.seq].episode_end)) or 
		1=1)
		and ce.valid_until_dt_tm = cnvtdatetime(cnvtdate(12312100),0000)
		and ce.view_level = 1
    and ce.result_status_cd in (25.00,33.00,35.00)
	order by d.seq, ce.event_cd, ce.event_end_dt_tm
	head d.seq
    null
  head ce.event_cd
    case(ce.event_cd)
		  of 102264072.00:
		    reply->items[d.seq].initial_phq9_score = ce.result_val
        reply->items[d.seq].initial_phq9_date = format(ce.performed_dt_tm, "mm/dd/yyyy")        
      of 823726295.00:
        reply->items[d.seq].initial_gad7_score = ce.result_val
        reply->items[d.seq].initial_gad7_date = format(ce.performed_dt_tm, "mm/dd/yyyy")        
      of 712404847.00:
        reply->items[d.seq].initial_auditc_score = ce.result_val	
        reply->items[d.seq].initial_auditc_date = format(ce.performed_dt_tm, "mm/dd/yyyy")
;      of 1734153589:
;        reply->items[d.seq].initial_gad2_score = ce.result_val	
;        reply->items[d.seq].initial_gad2_date = format(ce.performed_dt_tm, "mm/dd/yyyy")	   					                
    endcase
  foot ce.event_cd
		case(ce.event_cd)
		  of 102264072.00:
        reply->items[d.seq].last_phq9_score = ce.result_val
        reply->items[d.seq].last_phq9_date = format(ce.performed_dt_tm, "mm/dd/yyyy")
      of 823726295.00:
        reply->items[d.seq].last_gad7_score = ce.result_val
        reply->items[d.seq].last_gad7_date = format(ce.performed_dt_tm, "mm/dd/yyyy")
      of 712404847.00:
        reply->items[d.seq].last_auditc_score = ce.result_val	
        reply->items[d.seq].last_auditc_date = format(ce.performed_dt_tm, "mm/dd/yyyy")	
;      of 1734153589:
;        reply->items[d.seq].last_gad2_score = ce.result_val	
;        reply->items[d.seq].last_gad2_date = format(ce.performed_dt_tm, "mm/dd/yyyy")        
    endcase
	with nocounter, orahintcbo("INDEX(CE XIE24CLINICAL_EVENT)")

;---------------------------------------------------------------------------------------------------------------------------------
; Output
;---------------------------------------------------------------------------------------------------------------------------------
  SELECT into $OUTDEV      
    ;reply->items[d.seq].person_id,
    ;reply->items[d.seq].ce_parent_event_id,
    ;form_dt_tm_vc = substring(1,20,reply->items[d.seq].form_dt_tm_vc),
    ;reply->items[d.seq].episode_end,
    Name = substring(1, 120,reply->items[d.seq].pname),
    EMPI = substring(1, 15,reply->items[d.seq].empi),
    Facility = substring(1,100,reply->items[d.seq].fac_desc),
    MOST_RECENT_APPT_DATE = substring(1,40,reply->items[d.seq].last_cocm_appt),
    episode_of_care = substring(1,30,reply->items[d.seq].episode_of_care),
    date_episodes_of_care_began = substring(1,30,reply->items[d.seq].eps_beg_dt),
    date_episodes_of_care_ended = substring(1,30,reply->items[d.seq].eps_end_dt),
    TX_ACTIVE_STATUS = substring(1,30,reply->items[d.seq].treatmnt_status),
    TX_ACTIVE_STATUS_DATE = substring(1,30,reply->items[d.seq].treatmnt_status_date),
    FREQUENCY_OF_VISIT = substring(1,30,reply->items[d.seq].visit_freq_lbl),
    CARE_MANAGER = substring(1,30,reply->items[d.seq].care_manager),  
    TARGET_SCALE = substring(1,30,reply->items[d.seq].target_scale),
    
    ;cocm_treatment_status = substring(1,30,reply->items[d.seq].treatmnt_status),
    ;date_next_follow_up_due = substring(1,30,reply->items[d.seq].next_follow_up_due_date),
    
    
    initial_phq9_date = substring(1,30,reply->items[d.seq].initial_phq9_date),
    initial_phq9_score = substring(1,30,reply->items[d.seq].initial_phq9_score),
    last_phq9_date = substring(1,30,reply->items[d.seq].last_phq9_date),
    last_phq9_score = substring(1,30,reply->items[d.seq].last_phq9_score),
    
    initial_gad7_date = substring(1,30,reply->items[d.seq].initial_gad7_date),
    initial_gad7_score = substring(1,30,reply->items[d.seq].initial_gad7_score),
    last_gad7_date = substring(1,30,reply->items[d.seq].last_gad7_date),
    last_gad7_score = substring(1,30,reply->items[d.seq].last_gad7_score),
    
    initial_auditc_date = substring(1,30,reply->items[d.seq].initial_auditc_date),
    initial_auditc_score = substring(1,30,reply->items[d.seq].initial_auditc_score),
    last_auditc_date = substring(1,30,reply->items[d.seq].last_auditc_date),
    last_auditc_score = substring(1,30,reply->items[d.seq].last_auditc_score),
    
    LAST_PSYCH_DISCUSSION_DATE = substring(1,40,reply->items[d.seq].last_physc_cnst),
    DISCUSSION_WITH_PSYCH_CONSULTANT = substring(1,40,reply->items[d.seq].flag),
    Date_Next_Follow_Up_Due = substring(1,40,reply->items[d.seq].next_fu_due_date)
;      
;      date_of_most_recent_contact = substring(1,30,reply->items[d.seq].date_of_most_recent_contact),  
;      frequence_of_visit = substring(1,30,reply->items[d.seq].frequency_of_cocm_visit)
  
  from (dummyt d with seq = size(reply->items, 5))
  plan d
  ;where detail_rec->pat_list[d1.seq].CoCM_status_flag in ($cocmStatus)
  ; ORDER BY FACILITY
  WITH NOCOUNTER, SEPARATOR=" ", FORMAT
  
endif
	
end
go
