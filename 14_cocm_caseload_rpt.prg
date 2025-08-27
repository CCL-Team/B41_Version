/********************************************************************************************************************************
 Program Title:     Collaborative Care Caseload Report
 Object name:       14_cocm_caseload_rpt
 Source file:       14_cocm_caseload_rpt

 Purpose:

 Executed from:
 Programs Executed: DA2
 Special Notes:     This CCL is executed by DA2


*********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
*********************************************************************************************************************************
 Mod  Date        Analyst               MCGA        Comment
 ---  ----------  --------------------  ----------  -----------------------------------------------------------------------------
 001  04/11/2024  Simeon Akinsulie      346606      Initial release
 002  04/27/2025  Michael Mayes         351847      Copied report from 14_care_caseload_rpt_24_1 to make adjustments to prompt...
                                                    and potentially more.
                                                    Now they are sneaking in a change to the scales...
*********************************END OF ALL MODCONTROL BLOCKS*******************************************************************/
drop   program 14_cocm_caseload_rpt:dba go
create program 14_cocm_caseload_rpt:dba

prompt 
	"Output to File/Printer/MINE" = "MINE"
	, "Search PowerForm Author:"  = ""
	;<<hidden>>"Search"           = ""
	, "Powerform Author"          = VALUE(*)
	, "CoCM Treatment Status:"    = ""
	, "Report Type"               = "D" 

with outdev, prsnl_search, prsnl_list, cocmstatus, report_type



/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
%i cust_script:cust_timers_debug.inc

/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
free record forms
record forms(
    1 cnt = i4
    1 qual[*]
        2 per_id    = f8
        2 enc_id    = f8
                    
        2 ref_id    = f8
        2 act_id    = f8
        2 form_name = vc
        2 form_dt   = vc
        
)

free record reply
record reply(
  1 items[*]
    2 person_id                   = f8
    2 encntr_id                   = f8
    2 p_reg_date_dq8              = dq8
    2 fac_desc                    = vc
    2 fin                         = vc
    2 empi                        = vc
    2 pname                       = vc
    2 form_dt_tm                  = dq8
    2 form_dt_tm_vc               = vc
    2 cocm_form_id                = f8
    2 cocm_form_ref_id            = f8
    2 ce_parent_event_id          = f8
    2 physname                    = vc
    2 performed_by                = vc
    2 activity_dt_tm              = vc
    2 form_parent_event_id        = f8
    2 date_of_most_recent_contact = vc
    2 CoCM_treatment_status       = vc; 2 - Relapse prevention 1 - Active; 0 Inactive
    2 frequency_of_cocm_visit     = vc
    2 episodes_of_care_begin      = vc
    2 episodes_of_care_end        = vc
    2 Date_Episode_of_Care_Began  = dq8
    2 Date_Episode_of_Care_Ended  = dq8
    2 date_of_last_psych_consult  = vc
    2 CoCM_status_ind             = i4
    2 CoCM_status_flag            = i2 ;2 - Relapse prevention 1 - Active; 0 Inactive
    2 CoCM_pt_Flag                = vc
    2 next_follow_up_due_date     = vc

    2 status_dt                   = vc
    2 treatmnt_status             = vc
    2 treatmnt_status_date        = vc
    2 flag                        = vc
    2 eps_beg_dt                  = vc
    2 eps_end_dt                  = vc
    2 episode_begin               = dq8
    2 episode_end                 = dq8
    2 episode_begin_pid           = f8
    2 episode_end_pid             = f8
    2 last_physc_cnst             = vc
    2 since_last_physc_cnst       = i4
    2 first_cocm_appt             = vc
    2 last_cocm_appt              = vc
    2 next_cocm_appt              = vc
    2 time_in_treatmnt            = vc
    2 target_scale                = vc
    2 baseline                    = vc
    2 current                     = vc
    2 comp_target                 = vc
    2 outreach                    = vc
    2 s_comment                   = vc
    2 durr_total                  = i4
    2 next_fu_due_date            = vc
    2 next_fu_past_due            = i4
    2 care_manager                = vc
    2 cocm_flag                   = vc
    2 visit_freq                  = vc
    2 visit_freq_lbl              = vc
    2 episode_of_care             = vc
    2 practice_location           = vc
    2 ts_phq                      = i4
    2 ts_gad                      = i4
    2 ts_auditc                   = i4
    ;scores
    2 initial_phq9_score          = vc
    2 last_phq9_score             = vc
    2 initial_phq9_date           = vc
    2 perc_change_phq9_score      = vc
    2 last_phq9_date              = vc
    2 phq9_count                  = i4
    2 phq9_change                 = vc

    2 initial_gad7_score          = vc
    2 last_gad7_score             = vc
    2 initial_gad7_date           = vc
    2 perc_change_gad7_score      = vc
    2 last_gad7_date              = vc
    2 gad7_count                  = i4
    2 gad7_change                 = vc

    2 initial_auditc_score        = vc
    2 last_auditc_score           = vc
    2 initial_auditc_date         = vc
    2 perc_change_auditc_score    = vc
    2 last_auditc_date            = vc
    2 auditc_count                = i4
    2 auditc_change               = vc

    2 initial_gad2_score          = vc
    2 last_gad2_score             = vc
    2 initial_gad2_date           = vc
    2 perc_change_gad2_score      = vc
    2 last_gad2_date              = vc
    2 gad2_count                  = i4
    2 gad2_change                 = vc

    2 form_name                   = vc
    2 form_date                   = vc
)

/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare num                      = i4
declare pos                      = i4
declare sParserPrsnl             = vc with protect, noconstant("1=1")
declare prsnl_txt                = vc
declare status_parser            = vc ;with protect, noconstant("1=1")
declare perc_change_phq9_score   = f8
declare perc_change_gad7_score   = f8
declare perc_change_auditc_score = f8



/*************************************************************
; DVDev Start Coding
**************************************************************/
declare prog_timer = i4
set prog_timer = ctd_add_timer('14_cocm_caseload_rpt')



set status_parser = "1=1"



;Mayes removing because I think they don't want filters now.
;if(   -1.0 in ($PRSNL_LIST)
;   or  0.0 in ($PRSNL_LIST)
;  ) 
;    set sParserPrsnl = '1=1'
;    
;else
;    select into 'nl:'
;      from prsnl p
;     where p.person_id in ($PRSNL_LIST)
;    detail
;        if(prsnl_txt = '') prsnl_txt = trim(cnvtstring(p.person_id, 17, 1)                                , 3)
;        else               prsnl_txt = trim(notrim(build2(prsnl_txt, ',', cnvtstring(p.person_id, 17, 1))), 3)
;        endif
;    with nocounter
;
;    set sParserPrsnl = notrim(build2('dfr.updt_id in (', prsnl_txt, ')'))
;
;endif
;    
;call echo(sParserPrsnl)



/*---------------------------------------------------------------------------------------------------------------------------------
  Get a form population using filters first... then the complex stuff below... or that is the goal.
  
  Notes:
  
  Okay I think I know what Simeon was warning me about in the meeting... 
  The patient might and probably does have multiple forms... This is all person level.
  
  If we are trying to filter against the forms as a whole... we'll filter out potentially newer forms that should have filtered
  the patient away.  So basically we want to make sure that the forms we are considering as population are the latest forms as 
  well... or rather, forms with the latest results.
  
  We'll probably have to do this on the results themselves since forms being modified will throw us for a loop.
  
  Looks like currently we filter on the powerform author... and I could probably just check
  And the status... 

---------------------------------------------------------------------------------------------------------------------------------*/
;select into 'nl:'
;
;  from dcp_forms_activity dfr
; 
; where dfr.dcp_forms_ref_id        in (27852023149.00, 25562326477.00, 25562361699.00)
;   and dfr.active_ind              =  1
;   and dfr.form_status_cd          in (25.00, 34.00, 35.00)
;   and parser(sParserPrsnl)
;
;order by dfr.person_id, dfr.encntr_id
;
;detail
;    forms->cnt = forms->cnt + 1
;    
;    stat = alterlist(forms->qual, forms->cnt)
;    
;    forms->qual[forms->cnt]->per_id    = dfr.person_id
;    forms->qual[forms->cnt]->enc_id    = dfr.encntr_id
;    forms->qual[forms->cnt]->ref_id    = dfr.dcp_forms_ref_id
;    forms->qual[forms->cnt]->act_id    = dfr.dcp_forms_activity_id
;    forms->qual[forms->cnt]->form_name = dfr.description
;    forms->qual[forms->cnt]->form_dt   = format(dfr.beg_activity_dt_tm, "mm/dd/yyyy;;Q")
;
;    
;with nocounter
;
;call echorecord(forms)
;
;go to exit_script

;---------------------------------------------------------------------------------------------------------------------------------
; Main Query
;---------------------------------------------------------------------------------------------------------------------------------
call ctd_add_timer('Pop 1')
select into "nl:"
       eoc       = cnvtreal(ce5.result_val),
       eoc_begin = format(cdrb.result_dt_tm,"mm/dd/yyyy;;Q"),;substring(3,8,epb.result_val),
       eoc_end   = format(cdre.result_dt_tm,"mm/dd/yyyy;;Q");substring(3,8,epe.result_val),
  
  from dcp_forms_activity       d
     , dcp_forms_activity_comp  dfc
     , clinical_event           ce
     , clinical_event           ce2
     , clinical_event           ce3
     , clinical_event           ce4
     , clinical_event           ce5
     , clinical_event           r_fac
     , clinical_event           epb
     , clinical_event           epe
     , ce_date_result           cdrb
     , ce_date_result           cdre
     , person                   p
     , prsnl                    pr
     , encounter                e
  
  plan d
   where d.dcp_forms_ref_id        in (27852023149.00, 25562326477.00, 25562361699.00)
     and d.active_ind              =  1
     and d.form_status_cd          in (25.00, 34.00, 35.00)
     ;Trying to find the most recent form Only.  Should have the other episodes of care on them.
     ;and d.form_dt_tm = (select max(d2.form_dt_tm)
     ;                      from dcp_forms_activity d2
     ;                     where d2.person_id = d.person_id
     ;                       and d2.active_ind       =  1
     ;                       and d2.form_status_cd   in (25.00, 34.00, 35.00)
     ;                       and d2.dcp_forms_ref_id in (27852023149.00, 25562326477.00, 25562361699.00)
     ;                   )
  
  join dfc
   where dfc.dcp_forms_activity_id =  d.dcp_forms_activity_id
     and dfc.parent_entity_name    =  "CLINICAL_EVENT"

  join ce
   where ce.parent_event_id        =  dfc.parent_entity_id
     and ce.valid_until_dt_tm      >= cnvtdatetime(curdate,curtime3)
     and ce.result_status_cd       in (25.00,33.00,35.00)
     and (   (ce.event_cd = 4824728385.00 and d.dcp_forms_ref_id = 25562361699.00)
          or (ce.event_cd = 4824718241.00 and d.dcp_forms_ref_id = 25562326477.00)
          or (ce.event_cd = 11895.00      and d.dcp_forms_ref_id = 27852023149.00)
         )
  
  join ce2
   where ce2.parent_event_id      =  ce.event_id
     and ce2.valid_until_dt_tm    >= cnvtdatetime(curdate,curtime3)
     and ce2.result_status_cd     in (25.00,33.00,35.00)
                                 
  join ce3                       
   where ce3.PARENT_EVENT_id      =  ce2.EVENT_id
     and ce3.valid_until_dt_tm    >= cnvtdatetime(curdate,curtime3)
     and ce3.event_tag            !=  "In Error"
     and ce3.event_title_text     != 'Date\Time Correction'
                                 
  join ce4                       
   where ce4.PARENT_EVENT_id      =  ce3.EVENT_id
     and ce4.valid_until_dt_tm    >= cnvtdatetime(curdate,curtime3)
     and ce4.event_tag            !=  "In Error"
     and ce4.event_title_text     != 'Date\Time Correction'
                                  
  join ce5                        
   where ce5.PARENT_EVENT_id      =  ce4.EVENT_id
     and ce5.valid_until_dt_tm    >= cnvtdatetime(curdate,curtime3)
     and ce5.view_level           =  1    
     and ce5.event_tag            != "In Error"
     and ce5.event_title_text     != 'Date\Time Correction'
     and ce5.event_cd             =  2417618359.00
                                  
  join r_fac                      
   where r_fac.PARENT_EVENT_id    =  outerjoin(ce5.parent_event_id)
     and r_fac.valid_until_dt_tm  >= outerjoin(cnvtdatetime(curdate,curtime3))
     and r_fac.view_level         =  outerjoin(1)
     and r_fac.event_cd           =  outerjoin(5030145475.00);Date Episode of Care begin
                                  
  join epb                        
   where epb.PARENT_EVENT_id      =  outerjoin(ce5.parent_event_id)
     and epb.valid_until_dt_tm    >= outerjoin(cnvtdatetime(curdate,curtime3))
     and epb.view_level           =  outerjoin(1)
     and epb.event_cd             =  outerjoin(2417619091.00);Date Episode of Care begin
                                  
  join cdrb                       
   where cdrb.event_id            =  outerjoin(epb.event_id)
     and cdrb.valid_until_dt_tm   >= outerjoin(cnvtdatetime(curdate,curtime3))
                                  
  join epe                        
   where epe.PARENT_EVENT_id      =  outerjoin(ce5.parent_event_id)
     and epe.valid_until_dt_tm    >= outerjoin(cnvtdatetime(curdate,curtime3))
     and epe.view_level           =  outerjoin(1)
     and epe.event_cd             =  outerjoin(2417621191.00);Date Episode of Care Ended
                                  
  join cdre                       
   where cdre.event_id            =  outerjoin(epe.event_id)
     and cdre.valid_until_dt_tm   >= outerjoin(cnvtdatetime(curdate,curtime3))
                                  
  join e                          
   where e.encntr_id              =  ce5.encntr_id
                                  
  join p                          
   where p.person_id              =  d.person_id
                                  
  join pr                         
   where pr.person_id             =  ce5.updt_id
    

order by p.person_id, eoc desc, ce.event_end_dt_tm desc

head report
   cnt = 0
head ce.person_id
  null
head eoc
    cnt = cnt + 1
    
    if(size(reply->items,5) < cnt)
      stat = alterlist(reply->items,cnt+9)
    endif
    
    reply->items[cnt].person_id          = d.person_id
    reply->items[cnt].encntr_id          = d.encntr_id
    reply->items[cnt].pname              = trim(p.name_full_formatted,3)
    reply->items[cnt].cocm_form_id       = d.dcp_forms_activity_id
    reply->items[cnt].cocm_form_ref_id   = d.dcp_forms_ref_id
    reply->items[cnt].care_manager       = pr.name_full_formatted
    reply->items[cnt].ce_parent_event_id = ce.parent_event_id
    reply->items[cnt].p_reg_date_dq8     = cnvtdatetime(e.reg_dt_tm)
    reply->items[cnt].episode_of_care    = ce5.result_val
    reply->items[cnt].eps_beg_dt         = format(cdrb.result_dt_tm,"mm/dd/yyyy;;Q")
    reply->items[cnt].eps_end_dt         = format(cdre.result_dt_tm,"mm/dd/yyyy;;Q")

    reply->items[cnt].episode_begin      = cnvtdate(cdrb.result_dt_tm)
    reply->items[cnt].episode_begin_pid  = ce5.parent_event_id

    ;reply->items[cnt].eps_end_dt         = format(cdre.result_dt_tm,"MM/DD/YYYY")  ;002 this was set above.
    reply->items[cnt].episode_end        = cdre.result_dt_tm                        ;002 we don't set this?!                                                                                    
    reply->items[cnt].episode_end_pid    = ce5.parent_event_id
    reply->items[cnt].form_name          = d.description
    reply->items[cnt].form_date          = format(d.beg_activity_dt_tm,"mm/dd/yyyy;;Q")
    reply->items[cnt].fac_desc           = r_fac.result_val

foot report
    stat = alterlist(reply->items,cnt)
    
with nocounter, time = 600;krf 12/16/2024 180
call ctd_end_timer(0)



if(size(reply->items,5)>0)
    call ctd_add_timer('DTA Main')
    select into 'nl:'
           ce2.event_cd, ce2.result_val, ce2.event_end_dt_tm,ce.event_cd,ce.event_id,ce4.event_id;, *
      from clinical_event ce
         , clinical_event ce2
         , clinical_event ce3
         , clinical_event ce4
         , clinical_event ce5
         , ce_date_result cdr
      plan ce
       where expand(num,1,size(reply->items,5),ce.parent_event_id ,reply->items[num].ce_parent_event_id)
         and ce.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
         and ce.event_tag != "In Error"
         and ce.event_title_text != 'Date\Time Correction'
         
      join ce2
        where ce2.parent_event_id = ce.event_id
          and ce2.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
          and ce2.event_tag != "In Error"
          and ce2.event_title_text != 'Date\Time Correction'
         
      join ce3
        where ce3.parent_event_id = ce2.event_id
          and ce3.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
          and ce3.event_tag != "In Error"
          and ce3.event_title_text != 'Date\Time Correction'
         
      join ce4
        where ce4.parent_event_id = ce3.event_id
          and ce4.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
          and ce4.event_tag != "In Error"
          and ce4.event_title_text != 'Date\Time Correction'
         
      join ce5
        where ce5.parent_event_id = ce4.event_id
        ;ce2.person_id =    1616525.00;.parent_event_id = 29263847093.00
          and ce5.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
          and ce5.view_level = 1
          and ce5.event_tag != "In Error"
          and ce5.event_title_text != 'Date\Time Correction'
          and ce5.result_status_cd in (25.00,33.00,35.00)
          and ce5.event_cd in (2417619797.00,; CoCM treatment status
                                2417628261.00,;Date of Last Psych Consult
                                2417629549.00,;CoCM Flag
                                3395348155.00,;Frequency of CoCM Visit
                                4986730465.00,;CoCM Team - Care Manager
                                4202997599.00 ;Target Scale
                               )
      
      join cdr
        where cdr.event_id         = outerjoin(ce5.event_id)
          and cdr.valid_until_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))
    
    order by ce.parent_event_id, ce5.event_cd, ce5.event_end_dt_tm desc
  
    head ce.parent_event_id
        pos = locateval(num,1,size(reply->items,5), ce.parent_event_id ,reply->items[num].ce_parent_event_id)
    
    detail ;ce5.event_cd
        case(ce5.event_cd)
        ;CoCM flag
        of 2417629549.00: reply->items[pos].flag                  = ce5.result_val
        ;Date of Last Psych Consult
        of 2417628261.00: reply->items[pos].last_physc_cnst       = format(cdr.result_dt_tm, "MM/DD/YYYY")
                          reply->items[pos].since_last_physc_cnst = floor( datetimediff( cnvtdatetime(curdate, curtime3)
                                                                                       , cnvtdatetime( cnvtdate(cdr.result_dt_tm)
                                                                                                     , 0
                                                                                                     )
                                                                                       , 1
                                                                                       )
                                                                         )
        
        of 2417619797.00: reply->items[pos].treatmnt_status       = ce5.result_val
                          reply->items[pos].treatmnt_status_date  = format(ce.performed_dt_tm, "mm/dd/yyyy")
                          
        of 3395348155.00: reply->items[pos].visit_freq       = cnvtalphanum(ce5.result_val, 1)
                          reply->items[pos].visit_freq_lbl   = ce5.result_val
                          date_lbl                           = build2(trim(reply->items[pos].visit_freq), " W")
                          reply->items[pos].visit_freq       = date_lbl
                          reply->items[pos].next_fu_due_date = format(cnvtlookahead( date_lbl
                                                                                   , cnvtdatetime(reply->items[pos].p_reg_date_dq8))
                                                                                   , "mm/dd/yyyy;;d"
                                                                     )
        of 4986730465.00: reply->items[pos].care_manager          = ce5.result_val
        of 4202997599.00: reply->items[pos].target_scale          = ce5.result_val
        endcase
        
    with nocounter, expand = 1
    call ctd_end_timer(0)

    
    ;002->  She is adding these DTAs to the non-appt form, and is asking me to pull them in in the case where that is the last form
    ;       going to give that a shot.  Just for patients in that case.
    call ctd_add_timer('Non-App Act DTA Catch')
    select into 'nl:'
           
      from clinical_event ce5
         , ce_date_result cdr
         , (dummyt d with seq = value(size(reply->items,5)))
      
      plan d
       where size(reply->items,5)           > 0
         and reply->items[d.seq]->person_id > 0
         and reply->items[d.seq]->form_name = 'CoCM Non-Appointment Activity'
      
      join ce5
        where ce5.person_id         =  reply->items[d.seq]->person_id
          and ce5.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
          and ce5.view_level        =  1
          and ce5.event_tag         != "In Error"
          and ce5.event_title_text  != 'Date\Time Correction'
          and ce5.result_status_cd  in (25.00,33.00,35.00)
          and ce5.event_cd          in ( 3395348155.00,;Frequency of CoCM Visit
                                         4202997599.00 ;Target Scale
                                       )
       
      join cdr
        where cdr.event_id          =  outerjoin(ce5.event_id)
          and cdr.valid_until_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))
    
    order by ce5.event_cd, ce5.event_end_dt_tm desc
  
    head ce5.event_cd
        call echo(ce5.event_cd)
        
        case(ce5.event_cd)
        of 2417628261.00: reply->items[d.seq].last_physc_cnst       = format(cdr.result_dt_tm, "MM/DD/YYYY")
                          reply->items[d.seq].since_last_physc_cnst = floor( datetimediff( cnvtdatetime(curdate, curtime3)
                                                                                       , cnvtdatetime( cnvtdate(cdr.result_dt_tm)
                                                                                                     , 0
                                                                                                     )
                                                                                       , 1
                                                                                       )
                                                                         )
        
                          
        of 3395348155.00: reply->items[d.seq].visit_freq       = cnvtalphanum(ce5.result_val, 1)
                          reply->items[d.seq].visit_freq_lbl   = ce5.result_val
                          date_lbl                             = build2(trim(reply->items[d.seq].visit_freq), " W")
                          reply->items[d.seq].visit_freq       = date_lbl
                          reply->items[d.seq].next_fu_due_date = format(cnvtlookahead( date_lbl
                                                                                , cnvtdatetime(reply->items[d.seq].p_reg_date_dq8))
                                                                                , "mm/dd/yyyy;;d"
                                                                     )
        of 4202997599.00: reply->items[d.seq].target_scale          = ce5.result_val
        endcase
        
    with nocounter, expand = 1
    call ctd_end_timer(0)

    ;002<-
    

    ;---------------------------------------------------------------------------------------------------------------------------
    ;Update Episode of Care end date where it's missing
    ;The idea here is that Episode of care end care will only be document at the end of the eposide and prior documentation may not
    ;have the information documented
    ;---------------------------------------------------------------------------------------------------------------------------
    for(index = 1 to size(reply->items,5))
        if(reply->items[index].episode_end > 0)
            select into "nl:"
              
              from (dummyt d with seq = size(reply->items,5))
              
              plan d
             
             where reply->items[d.seq].person_id       = reply->items[index].person_id
               and reply->items[d.seq].episode_of_care = reply->items[index].episode_of_care
               and reply->items[d.seq].episode_begin   = reply->items[index].episode_begin
               and reply->items[d.seq].episode_end     = 0
            
            order by d.seq
            
            head d.seq
            
                reply->items[d.seq].episode_end        = reply->items[index].episode_end
                reply->items[d.seq].eps_end_dt         = reply->items[index].eps_end_dt
            with nocounter
        endif
    endfor
    
                           
                          


    ;---------------------------------------------------------------------------------------------------------------------------
    ;Get Referral Order
    ;---------------------------------------------------------------------------------------------------------------------------
    call ctd_add_timer('Referral Order')
    select into "nl:"
      
      from (dummyt d with seq = size(reply->items, 5))
         , orders o
         , encounter e
      
      plan d
       where reply->items[d.seq].cocm_form_ref_id =  13047318247.00
      
      join o                                       
       where o.person_id                          =  reply->items[d.seq].person_id
         and o.synonym_id                         =  1535777075.00;.catalog_cd in ( 1466962173.00,1466961443.00,1466954373.00)
         and o.product_id                         =  0.0
         and o.catalog_type_cd                    =  249926603.00
         and o.activity_type_cd                   in (249925330.00, 249925337.00)
         and o.order_status_cd not                in (2542.00,2544.00,2545.00,2552.00,643467.00)
      
      join e
       where e.encntr_id = o.encntr_id
    
    order by d.seq, o.orig_order_dt_tm desc
    
    head d.seq
        reply->items[d.seq].fac_desc = uar_get_code_display(e.loc_facility_cd)
    with uar_code(D)
    call ctd_end_timer(0)

    
    ;---------------------------------------------------------------------------------------------------------------------------
    ;       Get EMPI
    ;---------------------------------------------------------------------------------------------------------------------------
    call ctd_add_timer('EMPI')
    select into "nl:"
      
      from (dummyt d with seq = size(reply->items,5))
         , person_alias empi
      
      plan d
      
      join empi
       where empi.person_id            =  reply->items[d.seq].person_id
         and empi.person_alias_type_cd =  2
         and empi.beg_effective_dt_tm  <= cnvtdatetime(curdate, curtime3)
         and empi.end_effective_dt_tm  >  cnvtdatetime(curdate, curtime3)
    
    order by d.seq
    
    head d.seq
        reply->items[d.seq].empi = cnvtalias(empi.alias, empi.alias_pool_cd)
    with nocounter
    call ctd_end_timer(0)

    ;---------------------------------------------------------------------------------------------------------------------------
    ;       Get Last Appointment info
    ;---------------------------------------------------------------------------------------------------------------------------
    call ctd_add_timer('APP Info')
    ;002-> Trying to speed this up
    ;select into "nl:"
    ;  from (dummyt d with seq = size(reply->items,5))
    ;     , sch_appt a
    ;     , sch_booking sb
    ;     , code_value cvc
    ;     , code_value_group cvg
    ;     , code_value cv
    ;
    ;  plan d
    ;  
    ;  join a
    ;   where a.person_id            =  reply->items[d.seq].person_id
    ;     and a.beg_dt_tm            <  cnvtdatetime(curdate, curtime3)
    ;     and a.sch_role_cd          =  4572.00
    ;     and a.state_meaning        in ("SCHEDULED", "CONFIRMED", "CHECKED IN")
    ;  
    ;  join sb
    ;    where sb.booking_id         = a.booking_id
    ;  
    ;  join cvc
    ;    where cvc.code_value        = sb.appt_type_cd
    ;  
    ;  join cvg
    ;    where cvg.child_code_value  = cvc.code_value
    ;  
    ;  join cv
    ;    where cvg.parent_code_value = cv.code_value
    ;    and cv.code_value           = 5475430039.0
    ;
    ;order by d.seq, a.beg_dt_tm desc
    select into "nl:"
      from (dummyt d with seq = size(reply->items,5))
         , sch_appt a
         , sch_booking sb
    
      plan d
      
      join a
       where a.person_id      =  reply->items[d.seq].person_id
         and a.beg_dt_tm      <  cnvtdatetime(curdate, curtime3)
         and a.sch_role_cd    =  4572.00
         and a.state_meaning  in ("SCHEDULED", "CONFIRMED", "CHECKED IN")
         and a.schedule_seq   =  (select max(sa2.schedule_seq)
                                    from sch_appt sa2
                                   where sa2.sch_event_id = a.sch_event_id
                                 )
      
      join sb
        where sb.booking_id   =  a.booking_id
          and sb.appt_type_cd in (select cvg2.child_code_value
                                    from code_value_group cvg2
                                   where cvg2.parent_code_value = 5475430039.0
                                 )
    
    order by d.seq, a.beg_dt_tm desc
    ;002<-
    
    head d.seq
          reply->items[d.seq].last_cocm_appt = format(a.beg_dt_tm, "mm/dd/yyyy hh:mm;;d")
    
    with nocounter, expand = 1
    call ctd_end_timer(0)


    ;---------------------------------------------------------------------------------------------------------------------------
    ;   Get scores
    ;---------------------------------------------------------------------------------------------------------------------------
    ;002-> We are flipping this to the form check that the ST does now.  A bit more restrictive here, but forcing the results
    ;      to come from a CoCM form.
    ;select into "nl:"
    ;  from (dummyt d with seq = size(reply->items,5))
    ;     , clinical_event ce
    ;  
    ;  plan d
    ;   where reply->items[d.seq].person_id     > 0
    ;     and reply->items[d.seq].episode_begin > 0
    ;  
    ;  join ce
    ;   where ce.person_id          =  reply->items[d.seq].person_id
    ;     and ce.event_cd           in (102264072.00,823726295.00,712404847.00);,1734153589)
    ;     and ce.clinsig_updt_dt_tm >= cnvtdate(reply->items[d.seq].episode_begin)
    ;     and (   (    reply->items[d.seq].episode_end >  0 
    ;              and ce.clinsig_updt_dt_tm           <= cnvtdate(reply->items[d.seq].episode_end)
    ;             ) 
    ;          ;002->
    ;          ;or 1=1   ;We can't just auto success here... we need the case where episode_end is explicitly unfilled.
    ;                    ;Otherwise, we find all CEs for episodes of care that ended... it tells it to ignore the range checking if 
    ;                    ;it doesn't qualify.
    ;          or reply->items[d.seq].episode_end = 0 
    ;          ;002<-
    ;         )
    ;     and ce.valid_until_dt_tm  =  cnvtdatetime(cnvtdate(12312100),0000)
    ;     and ce.view_level         =  1
    ;     and ce.result_status_cd   in (25.00,33.00,35.00)
    ;     and ce.event_tag          != "In Error"
    ;     and ce.event_title_text   != 'Date\Time Correction'
    ;
    ;order by d.seq, ce.event_cd, ce.event_end_dt_tm
    
    call ctd_add_timer('Scales')
    select into 'nl:'
    
    from dcp_forms_activity      dfa
       , dcp_forms_activity_comp dfc
       , clinical_event          ce1
       , clinical_event          ce2
       , clinical_event          ce3
       , (dummyt d with seq = size(reply->items,5))
    
    plan d
       where reply->items[d.seq].person_id     > 0
         and reply->items[d.seq].episode_begin > 0
     
    join dfa
     where dfa.person_id             =  reply->items[d.seq].person_id
       and dfa.active_ind            =  1
       ;PROD
       and dfa.dcp_forms_ref_id      in ( 25562326477.0    ; CoCM Initial Visit
                                        , 17187876873.0    ; COCM Stop Time
                                        , 25562361699.0    ; CoCM Follow Up Visit
                                        , 27852023149.0    ; CoCM Non-Appointment Activity
                                        )
       ;BUILD                        
       ;and dfa.dcp_forms_ref_id      in ( 24202552913.0    ; CoCM Initial Visit
       ;                                 , 17187876873.0    ; COCM Stop Time
       ;                                 , 24202571835.0    ; CoCM Follow Up Visit
       ;                                 , 24216264555.0)   ; CoCM Non-Appointment Activity
       and dfa.form_status_cd        in (25.00, 34.00, 35.00)

    join dfc
     where dfc.dcp_forms_activity_id =  dfa.dcp_forms_activity_id
       and dfc.parent_entity_name    =  'CLINICAL_EVENT'
  
    ;Form
    join ce1
     where ce1.parent_event_id       =  dfc.parent_entity_id
       and ce1.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.00')
    
    ;Section
    join ce2
     where ce2.parent_event_id       =  ce1.event_id
       and ce2.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.00')
       and ce2.event_end_dt_tm between  cnvtdatetime('01-JAN-1970 0000') and cnvtdatetime(curdate,curtime3)
       and ce2.result_status_cd      in (25.00, 33.00, 35.00)
    
    ;Result
    join ce3
     where ce3.parent_event_id       =  ce2.event_id
       and ce3.view_level            =  1
       and ce3.valid_until_dt_tm     >=  cnvtdatetime(curdate,curtime3)
       and ce3.event_tag             != 'In Error'
       and ce3.event_title_text      != 'Date\Time Correction'
       and ce3.event_cd              in (102264072.0, 823726295.0, 712404847.0)
       and ce3.result_status_cd      in (25.00,33.00,35.00) 
       and ce3.clinsig_updt_dt_tm    >= cnvtdate(reply->items[d.seq].episode_begin)
       and (   (    reply->items[d.seq].episode_end >  0 
                and ce3.clinsig_updt_dt_tm          <= cnvtdate(reply->items[d.seq].episode_end)
               ) 
            or reply->items[d.seq].episode_end = 0 
            ;002<-
           )
    
    order by d.seq, ce3.event_cd, ce3.event_end_dt_tm
    ;002<-
    
    head d.seq
        null
    
    head ce3.event_cd
        case(ce3.event_cd)
        of 102264072.00: reply->items[d.seq].initial_phq9_score   = ce3.result_val
                         reply->items[d.seq].initial_phq9_date    = format(ce3.performed_dt_tm, "mm/dd/yyyy")
        of 823726295.00: reply->items[d.seq].initial_gad7_score   = ce3.result_val
                         reply->items[d.seq].initial_gad7_date    = format(ce3.performed_dt_tm, "mm/dd/yyyy")
        of 712404847.00: reply->items[d.seq].initial_auditc_score = ce3.result_val
                         reply->items[d.seq].initial_auditc_date  = format(ce3.performed_dt_tm, "mm/dd/yyyy")
        endcase
    
    foot ce3.event_cd
        case(ce3.event_cd)
        of 102264072.00: reply->items[d.seq].last_phq9_score      = ce3.result_val
                         reply->items[d.seq].last_phq9_date       = format(ce3.performed_dt_tm, "mm/dd/yyyy")
        
        of 823726295.00: reply->items[d.seq].last_gad7_score      = ce3.result_val
                         reply->items[d.seq].last_gad7_date       = format(ce3.performed_dt_tm, "mm/dd/yyyy")
        
        of 712404847.00: reply->items[d.seq].last_auditc_score    = ce3.result_val
                         reply->items[d.seq].last_auditc_date     = format(ce3.performed_dt_tm, "mm/dd/yyyy")
        endcase
        
    with nocounter, orahintcbo("INDEX(CE XIE24CLINICAL_EVENT)")
    call ctd_end_timer(0)

    
    call ctd_end_timer(prog_timer)
    call ctd_print_timers(null)

    ;---------------------------------------------------------------------------------------------------------------------------
    ; Output
    ;---------------------------------------------------------------------------------------------------------------------------
    SELECT into $OUTDEV
          Name                              = substring(1, 120, reply->items[d.seq].pname               )
        , EMPI                              = substring(1,  15, reply->items[d.seq].empi                )
        , Facility                          = substring(1, 100, reply->items[d.seq].fac_desc            )
        , MOST_RECENT_APPT_DATE             = substring(1,  40, reply->items[d.seq].last_cocm_appt      )
        
        , episode_of_care                   = substring(1,  30, reply->items[d.seq].episode_of_care     )
        , date_episodes_of_care_began       = substring(1,  30, reply->items[d.seq].eps_beg_dt          )
        , date_episodes_of_care_ended       = substring(1,  30, reply->items[d.seq].eps_end_dt          )
        , TX_ACTIVE_STATUS                  = substring(1,  30, reply->items[d.seq].treatmnt_status     )
        , TX_ACTIVE_STATUS_DATE             = substring(1,  30, reply->items[d.seq].treatmnt_status_date)
        , FREQUENCY_OF_VISIT                = substring(1,  30, reply->items[d.seq].visit_freq_lbl      )
        , CARE_MANAGER                      = substring(1,  30, reply->items[d.seq].care_manager        )
        , TARGET_SCALE                      = substring(1,  30, reply->items[d.seq].target_scale        )


        ,  initial_phq9_date                = substring(1,  30, reply->items[d.seq].initial_phq9_date   )
        ,  initial_phq9_score               = substring(1,  30, reply->items[d.seq].initial_phq9_score  )
        ,  last_phq9_date                   = substring(1,  30, reply->items[d.seq].last_phq9_date      )
        ,  last_phq9_score                  = substring(1,  30, reply->items[d.seq].last_phq9_score     )
                                                                
        ,  initial_gad7_date                = substring(1,  30, reply->items[d.seq].initial_gad7_date   )
        ,  initial_gad7_score               = substring(1,  30, reply->items[d.seq].initial_gad7_score  )
        ,  last_gad7_date                   = substring(1,  30, reply->items[d.seq].last_gad7_date      )
        ,  last_gad7_score                  = substring(1,  30, reply->items[d.seq].last_gad7_score     )
                                                                
        ,  initial_auditc_date              = substring(1,  30, reply->items[d.seq].initial_auditc_date )
        ,  initial_auditc_score             = substring(1,  30, reply->items[d.seq].initial_auditc_score)
        ,  last_auditc_date                 = substring(1,  30, reply->items[d.seq].last_auditc_date    )
        ,  last_auditc_score                = substring(1,  30, reply->items[d.seq].last_auditc_score   )
                                                                
        ,  LAST_PSYCH_DISCUSSION_DATE       = substring(1,  40, reply->items[d.seq].last_physc_cnst     )
        ,  DISCUSSION_WITH_PSYCH_CONSULTANT = substring(1,  40, reply->items[d.seq].flag                )
        ,  Date_Next_Follow_Up_Due          = substring(1,  40, reply->items[d.seq].next_fu_due_date    )

  from (dummyt d with seq = size(reply->items, 5))
  plan d
  WITH NOCOUNTER, SEPARATOR=" ", FORMAT

endif


#exit_script


call echorecord(reply)


end
go
