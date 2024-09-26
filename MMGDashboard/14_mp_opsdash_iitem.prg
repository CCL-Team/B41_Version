drop program   14_mp_opsdash_IItem:dba go
create program 14_mp_opsdash_IItem:dba
 
prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Begin Date" = "CURDATE"
    , "End Date" = "CURDATE"
    , "Forwarded Notes:" = 1
    , "In-Progress Notes:" = 1
    , "Endorsements:" = 1
    , "Rx Refills" = 1
    , "Documents:" = 0
    , "Results:" = 0
    , "Messages:" = 0
    , "Proposed Orders:" = 0
    , "Cosign Orders" = 0
    , "Facility" = 818277419.00
    , "Select Provider(s):" = 0
 
with OUTDEV, BEG_DT, END_DT, forwardnotes, inprogressnotes, endorsements,
    rxrefills, documents, results, messages, proposedords, cosignords, facility, Physicians
 
;execute 14_amb_incomplete_note_rpt4:dba "MINE", "01-FEB-2018", "07-FEB-2018",0,0,0,0,0,1,0,0,0,0,23270225.00 go
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
%i cust_script:sc_cps_parse_date_subs.inc
%i cust_script:ccps_ld_security.inc
%i cust_script:sc_cps_get_prompt_list.inc
%i cust_script:cust_timers_debug.inc
;%i cust_script:14_amb_incomplete_items_rpt.inc
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
DECLARE RUN_DT           = DQ8 WITH CONSTANT(CNVTDATETIME(CURDATE, CURTIME3)), PROTECT
DECLARE START_DT_TM      = DQ8 WITH CONSTANT(PARSEDATEPROMPT($BEG_DT, CURDATE-1, 0)), PROTECT
DECLARE END_DT_TM        = DQ8 WITH CONSTANT(PARSEDATEPROMPT($END_DT, CURDATE, 235959)), PROTECT
DECLARE 71_CLINIC_CD     = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!3959")), PROTECT
DECLARE 14233_CHKDIN_CD  = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!6157")), PROTECT
DECLARE 14230_NURSE_CD   = F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAYKEY", 14230, "NURSEAPPOINTMENT")), PROTECT
DECLARE 14230_INJ_CD     = F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAYKEY", 14230, "INJECTIONAPPOINTMENT")), PROTECT
DECLARE 14230_LAB_CD     = F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAYKEY", 14230, "WHCEPLAB")), PROTECT
DECLARE 333_ATTEN_CD     = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!4024")), PROTECT
DECLARE 333_NURSE_CD     = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!4596")), PROTECT
DECLARE 333_RESDNT_CD    = F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAYKEY", 333, "RESIDENT")), PROTECT
DECLARE 333_MEDAS_CD     = F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAYKEY", 333, "MEDICALASSISTANT")), PROTECT
DECLARE 333_PRIMR_CD     = F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAYKEY", 333, "PRIMARYTEAMRESIDENT")), PROTECT
DECLARE 333_CONSR_CD     = F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAYKEY", 333, "CONSULTINGTEAMRESIDENT")), PROTECT
declare CS319_MRN_ALIAS_TYPE_CD   = f8 with constant(uar_get_code_by_cki("CKI.CODEVALUE!8021")),protect
 
declare CS320_NPI = f8 with constant(uar_get_code_by_cki("CKI.CODEVALUE!2160654021")), protect
DECLARE CS319_FIN_ALIAS_TYPE_CD       = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!2930")), PROTECT
DECLARE 8_IP_CD          = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!2637")), PROTECT
DECLARE 6026_PH_CD       = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!3246")), PROTECT
DECLARE 6026_PERS_CD     = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!4102549460")), PROTECT
DECLARE 6026_ERX_CD      = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!12807095")), PROTECT
DECLARE 6026_ERXUN_CD    = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!12807869")), PROTECT
DECLARE 6026_ERXSUS_CD   = F8 WITH CONSTANT(UAR_GET_CODE_BY_CKI("CKI.CODEVALUE!12807870")), PROTECT
 
declare facility_parser = vc
declare facility_parser2 = vc
 
declare phys_parser1 = vc
declare phys_parser2 = vc
declare phys_parser3 = vc
declare phys_parser4 = vc
declare phys_parser5 = vc
declare phys_parser6 = vc
declare phys_parser7 = vc
 
declare prog_timer       = i4  with protect,   constant(ctd_add_timer_seq('14_mp_opsdash_IItem', 100))

declare time1= dq8
declare time2 = dq8
 
declare cnt              = i4 with noconstant(0), protect
declare cnt2             = i4 with noconstant(0), protect
declare idx              = i4 with noconstant(0), protect
declare resp_user = vc with noconstant(''), protect
declare admit_disch = vc with noconstant(''), protect
 
declare index              = i4 with noconstant(0), protect
declare index2              = i4 with noconstant(0), protect
declare num              = i4 with noconstant(0), protect
declare num2              = i4 with noconstant(0), protect
declare num3              = i4 with noconstant(0), protect
 
declare endrs_cnt = i4 with noconstant(0), protect
 
;---------------------------------------------------------------------------------------------------------------------------------
; DVDev DECLARED SUBROUTINES
;---------------------------------------------------------------------------------------------------------------------------------
declare get_endorse_event_cd(null) = null
declare get_enc_pop(NULL) = Null
declare Get_Notes_Not_Started(NULL) = Null
declare Get_In_Progress_Notes(NULL) = Null
declare Get_Forwarded_Notes(NULL) = NULL
declare Get_RX_Refills(NULL) = NULL
declare Get_Endorsements(NULL) = NULL
declare Get_Documents(NULL) = NULL
declare Get_Results(NULL) = NULL
declare Get_Proposed_Orders(NULL) = NULL
declare Get_Cosign_Orders(NULL) = NULL
declare Get_Last_Login(NULL) = NULL
declare Get_Patient_Info(NULL) = NULL
declare Get_MRN(NULL) = NULL
declare Get_FIN(NULL) = NULL
declare Get_NPI(NULL) = NULL
declare Build_Output(NULL) = NULL
 
 
;---------------------------------------------------------------------------------------------------------------------------------
; DVDev DECLARED Record Structures
;---------------------------------------------------------------------------------------------------------------------------------
free record noteTypes
record noteTypes
(
    1 specialties[*]
        2 note_name = vc
        2 code_value = f8
)
 
free record endorse_event_cd
record endorse_event_cd
(
    1 qual [*]
        2 event_cd = f8
        2 result = vc
)
 
free record items
record items
(
    1 qual_cnt              = i4
    1 cosign_orders_cnt     = i4
    1 documents_cnt         = i4
    1 endorsements_cnt      = i4
    1 notes_cnt             = i4
    1 messages_cnt          = i4
    1 proposed_ord_cnt      = i4
    1 results_cnt           = i4
    1 rx_refills_cnt        = i4
    1 rx_daysLag_cnt        = i4
    1 prsnl_qual[*]
        2 prsnl_id          = f8
        2 last_logon        = dq8
        2 username          = vc
        2 NPI               = vc
        2 position          = vc
        2 resp_user_name    = vc
        2 cosign_orders_cnt = i4
        2 documents_cnt     = i4
        2 endorsements_cnt  = i4
        2 notes_cnt         = i4
        2 messages_cnt      = i4
        2 proposed_ord_cnt  = i4
        2 results_cnt       = i4
        2 rx_refills_cnt    = i4
        2 Note_Not_Started  = i4
        2 In_Progress_Note  = i4
        2 Forwarded_Note    = i4
        2 Need_endorsements = i4
        2 Documents_Count   = i4
        2 Rst_Pend_Endors   = i4
        2 Rst_Pend          = i4
        2 Prop_Ord_Count    = i4
        2 Cosign_Ord_Count  = i4
        2 Message_Count     = i4
        2 Rx_Refils_Count   = i4
        2 pDetail[*]
            3 person_id     = f8
            3 encntr_id    = f8
            3 pt_name      = vc
            3 mrn          = vc
            3 fin          = vc
            3 organization = vc
            3 admit_discharge = vc
            3 arrive_dt = dq8
            3 disch_dt      = dq8
            3 facility     = vc
            3 attend_phys  = vc
            3 nurse        = vc
            3 resident     = vc
            3 resp_user_name = vc
            3 prsnl_id      = f8
            3 last_logon    = dq8
            3 username      = vc
            3 NPI           = vc
            3 position      = vc
            3 task_id      = f8
            3 task_activity = vc
            3 task_status   = vc
            3 note_type = vc
            3 inc_item_vc = vc
            3 inc_item     = vc
            3 inc_item_dt_tm    = dq8
            3 inc_item_days = i4
            3 result_dt_tm  = dq8
            3 lab_name      = vc
            3 lab_normalcy  = vc
            3 report_subject = vc
            3 order_name    = vc
            3 order_proposal_id = f8
            3 order_id      = f8
            3 unique_id = f8
    1 qual[*]
        2 person_id         = f8
        2 encntr_id         = f8
        2 pt_name           = vc
        2 mrn               = vc
        2 fin               = vc
        2 organization      = vc
        2 arrive_dt         = dq8
        2 disch_dt          = dq8
        2 facility          = vc
        2 attend_phys       = vc
        2 nurse             = vc
        2 resident          = vc
        2 resp_user_name    = vc
        2 prsnl_id          = f8
        2 last_logon        = dq8
        2 username          = vc
        2 NPI               = vc
        2 position          = vc
        2 task_id           = f8
        2 task_activity     = vc
        2 task_status       = vc
        2 note_type         = vc
        2 inc_item          = vc
        2 inc_item_dt_tm    = dq8
        2 inc_item_days     = i4
        2 result_dt_tm      = dq8 ;added for documents
        2 lab_name          = vc
        2 lab_normalcy      = vc
        2 report_subject    = vc
        2 order_name        = vc
        2 order_proposal_id = f8
        2 order_id          = f8
        2 unique_id         = f8
)with protect

;I've had some success saving off expensive encounter lists and then dummyting across them for performance sake.  Or expanding.
;I know dummyts suck performance wise... but if we can get a list of the encounters we want to check, no need to gather them
;in all the queries.
free record enc_pop
record enc_pop(
    1 cnt = i4
    1 qual[*]
        2 per_id = f8
        2 enc_id = f8
        2 arr_time_ind = i2
)


free record Facilities
record Facilities(
    1 fac_qual [*]
        2 fac_cd = f8
        2 display = vc
)
 
if(1=1)
    declare output_dest = vc with constant(concat(
                      "CCLUSERDIR:"
                      ,"incompletenotereport_"
                      ,FORMAT(RUN_DT, "YYYYMMDDhhmmss;;q")
                      ,".csv"))
else
    if (cnvtdatetime(START_DT_TM)> cnvtdatetime(END_DT_TM))
        select into $outdev
        from
            (dummyt  d with seq = 1)
        plan d
        head report
            "{CPI/9}{FONT/12}"
            row 0, col 0, call print(build2("ERROR: End Date Cannot Be Before Start Date!"))
        with nocounter
      go to exit_script
    endif
   set output_dest = value($OUTDEV)
endif
 
set facility_parser = trim(GetPromptList(parameter2($FACILITY), " e.loc_facility_cd"), 3)
set facility_parser2 = trim(GetPromptList(parameter2($FACILITY), " e.loc_facility_cd"), 3)
set facility_parser = trim(GetPromptList(parameter2($FACILITY), " e.loc_nurse_unit_cd"), 3)
set facility_parser2 = trim(GetPromptList(parameter2($FACILITY), " e.loc_nurse_unit_cd"), 3)
 
if(value($Physicians)!=0)
    set facility_parser = "1=1"
    set facility_parser2 = "1=1"
    set encntr_type_parser = "1=1"
else
    set encntr_type_parser = "e.encntr_type_cd = 71_CLINIC_CD"
endif
 
if(IsPromptAny(parameter2($Physicians)) OR IsPromptEmpty(parameter2($Physicians)))
    SET phys_parser1 = "1=1"
    SET phys_parser2 = "1=1"
    SET phys_parser3 = "1=1"
    SET phys_parser4 = "1=1"
    SET phys_parser5 = "1=1"
    SET phys_parser6 = "1=1"
    SET phys_parser7 = "1=1"
else
    SET phys_parser1 = trim(GetPromptList(parameter2($Physicians), " ce.performed_prsnl_id"), 3)
    SET phys_parser2 = trim(GetPromptList(parameter2($Physicians), " cea.action_prsnl_id"), 3)
 
    SET phys_parser3 = trim(GetPromptList(parameter2($Physicians), " cp.action_prsnl_id"), 3)
    SET phys_parser4 = trim(GetPromptList(parameter2($Physicians), " pr.person_id"), 3)
    SET phys_parser5 = trim(GetPromptList(parameter2($Physicians), " taa.assign_prsnl_id"), 3)
    SET phys_parser6 = trim(GetPromptList(parameter2($Physicians), " op.responsible_prsnl_id"), 3)
    SET phys_parser7 = trim(GetPromptList(parameter2($Physicians), " on1.to_prsnl_id"), 3)
 endif
 
call echo(build2("here is the value of Facility_Parser: ", FACILITY_PARSER))
call echo(build2("here is the value of phys_parser2: ", phys_parser2))
 
call get_endorse_event_cd(null)
;If(value($notesnotstarted)=1)
;   call Get_Notes_Not_Started(NULL)
;endif

if(   value($documents      ) = 1
   or value($results        ) = 1
   or value($cosignords     ) = 1
   or value($messages       ) = 1
   or value($proposedords   ) = 1
   or value($inprogressnotes) = 1
   or value($forwardnotes   ) = 1
   or value($rxrefills      ) = 1
   or value($endorsements   ) = 1
  )
    call get_enc_pop(NULL)
endif

If(value($inprogressnotes)=1)
    call Get_In_Progress_Notes(NULL)
endif
If(value($forwardnotes)=1)
    call Get_Forwarded_Notes(NULL)
endif
If(value($rxrefills)=1)
    call Get_RX_Refills(NULL)
endif
If(value($endorsements)=1)
    call Get_Endorsements(NULL)
endif
 
If(value($documents)=1)
    call Get_Documents(NULL)
endif
If(value($results)=1)
    call echo("We're goning to run Get_Results")
    call Get_Results ( NULL )
endif
If(value($messages)=1)
    call Get_Messages ( NULL )
endif
If(value($proposedords)=1)
    call Get_Proposed_Orders ( NULL )
endif
If(value($cosignords)=1)
    call Get_Cosign_Orders(NULL)
endif
 
 
if(size(items->qual,5)>0)
    call Get_Patient_Info(NULL)
    ;call Get_Last_Login(NULL)
    call Get_NPI(NULL)
    call Get_MRN(NULL)
    call Get_FIN(NULL)
    call echorecord(items)
endif



;if(size(items->qual,5)>0)
    call Build_Output(NULL)
;endif

call ctd_end_timer(prog_timer)
call ctd_print_timers(null)

go to Exit_Script
 
;---------------------------------------------------------------------------------------------------------------------------------
; DEFINED SUBROUTINES
;---------------------------------------------------------------------------------------------------------------------------------
 
;Get encounter populations
subroutine get_enc_pop(null)
    call ctd_add_timer('get_enc_pop')
    select into 'nl:' 
      from ENCOUNTER E 
       
     where parser(encntr_type_parser) ;e.encntr_type_cd            = 71_CLINIC_CD
       and parser(facility_parser)
       and E.BEG_EFFECTIVE_DT_TM  <= cnvtdatetime(curdate, curtime3)
       and E.END_EFFECTIVE_DT_TM  >  cnvtdatetime(curdate, curtime3)  
       and E.ACTIVE_IND =    1 
    
    detail
        enc_pop->cnt = enc_pop->cnt + 1
        
        if(mod(enc_pop->cnt, 10) = 1)
            stat = alterlist(enc_pop->qual, enc_pop->cnt + 9)
        endif
        
        enc_pop->qual[enc_pop->cnt]->per_id = e.person_id
        enc_pop->qual[enc_pop->cnt]->enc_id = e.encntr_id
        
        if(e.arrive_dt_tm between cnvtdatetime(START_DT_TM) and cnvtdatetime(END_DT_TM))
            enc_pop->qual[enc_pop->cnt]->arr_time_ind = 1
        endif
    
    foot report
        stat = alterlist(enc_pop->qual, enc_pop->cnt)
    
    with nocounter
    call ctd_end_timer(0)
end
 
 
; Get get_endorse_event_cd
;---------------------------------------------------------------------------------------------------------------------------------
subroutine get_endorse_event_cd(null)
    call ctd_add_timer('get_endorse_event_cd')
    select into ("NL:")
        x.event_cd,
        result=uar_get_code_display(x.event_cd)
    from
        v500_event_set_code s
        ,v500_event_set_explode x
        ,v500_event_code c
    plan s where s.event_set_name_key in ( "LABORATORY", "RADIOLOGY")
    join x where x.event_set_cd = s.event_set_cd
    join c where c.event_cd = x.event_cd
    order by x.event_cd
    head report
        endrs_cnt = 0
        head x.event_cd
            endrs_cnt = endrs_cnt + 1
            if(mod(endrs_cnt,10) = 1)
                stat=alterlist(endorse_event_cd->qual,endrs_cnt+9)
            endif
            endorse_event_cd->qual[endrs_cnt].event_cd = x.event_cd
            endorse_event_cd->qual[endrs_cnt].result = result
    foot report
        stat=alterlist(endorse_event_cd->qual,endrs_cnt)
    with nocounter
    call ctd_end_timer(0)
end
 
 
;---------------------------------------------------------------------------------------------------------------------------------
; Notes Not Started
;---------------------------------------------------------------------------------------------------------------------------------
subroutine Get_Notes_Not_Started(NULL)
    call echo("begin Get_Notes_Not_Started")
    call ctd_add_timer('Get_Notes_Not_Started')
    set time1=sysdate
    select into 'nl:'
    from
        encounter e
        ,person p
        ,clinical_event ce
        ,prsnl pr
        ,dummyt d
        ,clinical_event ce2
    plan e
        where e.reg_dt_tm between cnvtdatetime(START_DT_TM) and cnvtdatetime(END_DT_TM)
        and e.encntr_type_cd = 71_CLINIC_CD
        and parser(facility_parser)
        and e.beg_effective_dt_tm  <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm  > cnvtdatetime(curdate, curtime3)
        and e.active_ind = 1
    join p
        where p.person_id = e.person_id
        and p.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
        and p.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and p.active_ind = 1
    join ce
        where ce.encntr_id = e.encntr_id
        and parser(phys_parser1)
        and ce.event_cd != 704668.00    ;chief complaint
        and ce.entry_mode_cd = 252831933.00 ;workflow doc
        and ce.view_level = 1
        and ce.publish_flag = 1
        and ce.result_status_cd not in (26.00 ;cancelled
                     ,28.00 ;In Error
                     ,29.00 ;In Error
                     ,30.00 ;In Error
                     ,31.00 ;In Error
                     ,5473380.00)
        and ce.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
    join pr
        where pr.person_id = ce.performed_prsnl_id
        and pr.active_ind = 1
    join d
    join ce2
        where ce2.encntr_id = e.encntr_id
        and ce2.entry_mode_cd = 66762423.00  ;dyn doc
    order by e.encntr_id
    head report
        cnt = 0
        head e.encntr_id
        cnt = cnt + 1
        if(size(items->qual,5)<cnt)
            stat = alterlist(items->qual, cnt + 99)
        endif
        pos = locateval(num, 1, size(items->prsnl_qual,5), pr.person_id, items->prsnl_qual[num].prsnl_id)
        if(pos = 0)
            pos = size(items->prsnl_qual,5) + 1
            stat = alterlist(items->prsnl_qual, pos)
            items->prsnl_qual[pos].resp_user_name = trim(pr.name_full_formatted, 3)
            items->prsnl_qual[pos].prsnl_id = pr.person_id
            items->prsnl_qual[pos].username = pr.username
            items->prsnl_qual[pos].position = uar_get_code_display(pr.position_cd)
        endif
        items->prsnl_qual[pos].Note_Not_Started = items->prsnl_qual[pos].Note_Not_Started + 1
        cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
        stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
        items->prsnl_qual[pos].pDetail[cnt2].person_id = p.person_id
        items->prsnl_qual[pos].pDetail[cnt2].pt_name = p.name_full_formatted
        items->prsnl_qual[pos].pDetail[cnt2].encntr_id = e.encntr_id
        items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
        admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
        items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
        items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
        items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
        items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = "Note Not Started"
        items->prsnl_qual[pos].pDetail[cnt2].inc_item = "Note Not Started"
        items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = ce.clinsig_updt_dt_tm
        items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ce.clinsig_updt_dt_tm, 1)
        items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(pr.name_full_formatted, 3)
        items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = pr.person_id
        items->prsnl_qual[pos].pDetail[cnt2].username = pr.username
        items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(pr.position_cd)
        items->prsnl_qual[pos].pDetail[cnt2].unique_id = ce.clinical_event_id
 
        items->qual[cnt].person_id = p.person_id
        items->qual[cnt].encntr_id = e.encntr_id
        items->qual[cnt].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
        items->qual[cnt].arrive_dt = e.arrive_dt_tm
        items->qual[cnt].disch_dt = e.disch_dt_tm
        items->qual[cnt].inc_item = "Note Not Started"
        items->qual[cnt].inc_item_dt_tm = ce.clinsig_updt_dt_tm
        items->qual[cnt].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ce.clinsig_updt_dt_tm, 1)
        items->qual[cnt].resp_user_name = trim(pr.name_full_formatted, 3)
        items->qual[cnt].prsnl_id = pr.person_id
        items->qual[cnt].username = pr.username
        items->qual[cnt].position = uar_get_code_display(pr.position_cd)
        items->qual[cnt].unique_id = ce.clinical_event_id
    foot report
        items->qual_cnt = cnt
        stat = alterlist(items->qual,cnt)
    with nocounter, outerjoin = D, dontexist, time=600
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_Notes_Not_Started")
    call ctd_end_timer(0)
end
 
 
;---------------------------------------------------------------------------------------------------------------------------------
; In-Progess Notes
;---------------------------------------------------------------------------------------------------------------------------------
subroutine Get_In_Progress_Notes(null)
    call echo("begin Get_In_Progress_Notes")
    set time1 = sysdate
    call ctd_add_timer('Get_In_Progress_Notes')
    /* MMM174 We started getting pretty bad performance here... retrying with a new query below.
    select into 'nl:'
    from
        encounter e
        ,person p
        ,clinical_event ce
        ,prsnl pr
    plan e
        where e.arrive_dt_tm between cnvtdatetime(START_DT_TM) and cnvtdatetime(END_DT_TM)
        and e.encntr_type_cd = 71_CLINIC_CD
        and parser(facility_parser)
        and e.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and e.active_ind = 1
    join p
        where p.person_id = e.person_id
        and p.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
        and p.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and p.active_ind = 1
    join ce
        where ce.encntr_id = e.encntr_id
        and ce.event_cd != 704668.00    ;chief complaint
        and ce.entry_mode_cd = 66762423.00  ;dyn doc
        and ce.view_level = 1
        and ce.publish_flag = 1 ;lets us know that we can see it in Powerchart
        and ce.result_status_cd = 33.00        ;not completed
        and ce.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
    join pr
        where pr.person_id = ce.performed_prsnl_id
        and pr.active_ind = 1
        and parser(phys_parser4)
    MMM174 end*/
    select into 'nl:'
    from encounter e
       , person p
       , clinical_event ce
       , prsnl pr
    
    where expand(idx, 1, enc_pop->cnt, e.person_id, enc_pop->qual[idx]->per_id
                                     , e.encntr_id, enc_pop->qual[idx]->enc_id
                                     ,           1, enc_pop->qual[idx]->arr_time_ind
                )
      
      
      and p.person_id = e.person_id
      and p.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
      and p.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
      and p.active_ind = 1
    
      and ce.encntr_id = e.encntr_id
      and ce.event_cd != 704668.00    ;chief complaint
      and ce.entry_mode_cd = 66762423.00  ;dyn doc
      and ce.view_level = 1
      and ce.publish_flag = 1 ;lets us know that we can see it in Powerchart
      and ce.result_status_cd = 33.00        ;not completed
      and ce.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
    
      and pr.person_id = ce.performed_prsnl_id
      and pr.active_ind = 1
      and parser(phys_parser4)
      ;and 1=1
    order by e.encntr_id, ce.event_id
    head e.encntr_id
        null
        head ce.event_id
            cnt = cnt + 1
            if(size(items->qual,5)<cnt)
                stat = alterlist(items->qual, cnt + 99)
            endif
            pos = locateval(num, 1, size(items->prsnl_qual,5), pr.person_id, items->prsnl_qual[num].prsnl_id)
            if(pos = 0)
                pos = size(items->prsnl_qual,5) + 1
                stat = alterlist(items->prsnl_qual, pos)
                items->prsnl_qual[pos].resp_user_name = trim(pr.name_full_formatted, 3)
                items->prsnl_qual[pos].prsnl_id = pr.person_id
                items->prsnl_qual[pos].username = pr.username
                items->prsnl_qual[pos].position = uar_get_code_display(pr.position_cd)
            endif
            items->notes_cnt = items->notes_cnt + 1
            items->prsnl_qual[pos].notes_cnt = items->prsnl_qual[pos].notes_cnt + 1
            items->prsnl_qual[pos].In_Progress_Note = items->prsnl_qual[pos].In_Progress_Note + 1
            cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
            stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
            items->prsnl_qual[pos].pDetail[cnt2].person_id = p.person_id
            items->prsnl_qual[pos].pDetail[cnt2].pt_name = p.name_full_formatted
            items->prsnl_qual[pos].pDetail[cnt2].encntr_id = e.encntr_id
            items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
            admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
            items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
            items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = build2("In Progress Note (",uar_get_code_display(ce.event_cd),")")
            items->prsnl_qual[pos].pDetail[cnt2].note_type = uar_get_code_display(ce.event_cd)
            items->prsnl_qual[pos].pDetail[cnt2].inc_item = "In Progress Note"
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = ce.clinsig_updt_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ce.clinsig_updt_dt_tm, 1)
            items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(pr.name_full_formatted, 3)
            items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = pr.person_id
            items->prsnl_qual[pos].pDetail[cnt2].username = pr.username
            items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(pr.position_cd)
            items->prsnl_qual[pos].pDetail[cnt2].unique_id = ce.clinical_event_id
 
            items->qual[cnt].person_id = p.person_id
            items->qual[cnt].encntr_id = e.encntr_id
            items->qual[cnt].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
            items->qual[cnt].arrive_dt = e.arrive_dt_tm
            items->qual[cnt].disch_dt = e.disch_dt_tm
            items->qual[cnt].note_type = uar_get_code_display(ce.event_cd)
            items->qual[cnt].inc_item = "In Progress Note"
            items->qual[cnt].inc_item_dt_tm = ce.clinsig_updt_dt_tm
            items->qual[cnt].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ce.clinsig_updt_dt_tm, 1)
            items->qual[cnt].resp_user_name = trim(pr.name_full_formatted, 3)
            items->qual[cnt].prsnl_id = pr.person_id
            items->qual[cnt].username = pr.username
            items->qual[cnt].position = uar_get_code_display(pr.position_cd)
            items->qual[cnt].unique_id = ce.clinical_event_id
    foot report
        items->qual_cnt = cnt
        stat = alterlist(items->qual,cnt)
    with nocounter, expand=2;, time=600
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_In_Progress_Notes")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
; Forwarded Notes
;---------------------------------------------------------------------------------------------------------------------------------
subroutine Get_Forwarded_Notes(NULL)
    set time1 = sysdate
    call echo("begin Get_Forwarded_Notes")
    call ctd_add_timer('Get_Forwarded_Notes')
    /* MMM174 We started getting pretty bad performance here... retrying with a new query below.
    select into 'nl:'
    from
        encounter e
        ,person p
        ,clinical_event ce
        ,task_activity ta
        ,ce_event_prsnl cp
        ,task_activity_assignment taa
        ,prsnl pr
    plan e
        where e.arrive_dt_tm between cnvtdatetime(START_DT_TM) and cnvtdatetime(END_DT_TM)
        and e.encntr_type_cd = 71_CLINIC_CD
        and parser(facility_parser)
        and e.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and e.active_ind = 1
    join p
        where p.person_id = e.person_id
        and p.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
        and p.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and p.active_ind = 1
    join ce
        where ce.encntr_id = e.encntr_id
        and ce.event_cd != 704668.00    ;chief complaint
        ;and expand(index, 1, size(noteTypes->specialties,5),ce.event_cd,noteTypes->specialties[index].code_value)
        and ce.entry_mode_cd = 66762423.00  ;dyn doc
        and ce.view_level = 1
        and ce.result_status_cd in (23.00, 25.00, 39.00) ;not completed
        and ce.publish_flag  = 1 ;can be seen in Powerchart
        and ce.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
    join cp
        where cp.event_id = ce.event_id
        and cp.action_type_cd in (107.00); removed review, 106.00)
        and cp.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
        and cp.action_dt_tm is NULL
        and cp.action_status_cd = 657.00
        and parser(phys_parser3)
    join ta
        where ta.event_id = ce.event_id
        and ta.task_status_cd != 419.00
        and ta.task_activity_cd != 2704.00
    join taa
        where taa.task_id = ta.task_id
        and taa.active_ind = 1
        and taa.task_status_cd in (421.00, 425, 427, 429)
    join pr
        where pr.person_id = cp.action_prsnl_id
    MMM174 end*/
    select into 'nl:'
    from encounter e
       , person p
       , clinical_event ce
       , task_activity ta
       , ce_event_prsnl cp
       , task_activity_assignment taa
       , prsnl pr
    
    where expand(idx, 1, enc_pop->cnt, e.person_id, enc_pop->qual[idx]->per_id
                                     , e.encntr_id, enc_pop->qual[idx]->enc_id
                                     ,           1, enc_pop->qual[idx]->arr_time_ind
                )
      
      and p.person_id = e.person_id
      and p.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
      and p.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
      and p.active_ind = 1
      
      and ce.encntr_id = e.encntr_id
      and ce.event_cd != 704668.00    ;chief complaint
      and ce.entry_mode_cd = 66762423.00  ;dyn doc
      and ce.view_level = 1
      and ce.result_status_cd in (23.00, 25.00, 39.00) ;not completed
      and ce.publish_flag  = 1 ;can be seen in Powerchart
      and ce.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
      
      and cp.event_id = ce.event_id
      and cp.action_type_cd in (107.00); removed review, 106.00)
      and cp.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
      and cp.action_dt_tm is NULL
      and cp.action_status_cd = 657.00
      and parser(phys_parser3)
      ;and 1=1
      
      and ta.encntr_id  =    e.encntr_id
      and ta.person_id   =    e.person_id
      and ta.updt_dt_tm  >=   ce.event_end_dt_tm
      and ta.event_id = ce.event_id
      and ta.task_status_cd != 419.00
      and ta.task_activity_cd != 2704.00
      
      and taa.task_id = ta.task_id
      and taa.active_ind = 1
      and taa.task_status_cd in (421.00, 425, 427, 429)
    
      and pr.person_id = cp.action_prsnl_id
    
    order by ce.event_id, pr.person_id
    head ce.event_id
        null
        head pr.person_id
            cnt = cnt + 1
            if(size(items->qual,5)<cnt)
                stat = alterlist(items->qual, cnt + 99)
            endif
            pos = locateval(num, 1, size(items->prsnl_qual,5), pr.person_id, items->prsnl_qual[num].prsnl_id)
            if(pos = 0)
                pos = size(items->prsnl_qual,5) + 1
                stat = alterlist(items->prsnl_qual, pos)
                items->prsnl_qual[pos].resp_user_name = trim(pr.name_full_formatted, 3)
                items->prsnl_qual[pos].prsnl_id = pr.person_id
                items->prsnl_qual[pos].username = pr.username
                items->prsnl_qual[pos].position = uar_get_code_display(pr.position_cd)
            endif
            items->notes_cnt = items->notes_cnt + 1
            items->prsnl_qual[pos].notes_cnt = items->prsnl_qual[pos].notes_cnt + 1
            items->prsnl_qual[pos].Forwarded_Note = items->prsnl_qual[pos].Forwarded_Note + 1
            cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
            stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
            items->prsnl_qual[pos].pDetail[cnt2].person_id = p.person_id
            items->prsnl_qual[pos].pDetail[cnt2].pt_name = p.name_full_formatted
            items->prsnl_qual[pos].pDetail[cnt2].encntr_id = e.encntr_id
            items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
            admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
            items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
            items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = build2("Forwarded Note (",uar_get_code_display(ce.event_cd)," - ",
            trim(uar_get_code_description(ta.task_activity_cd),3),trim(uar_get_code_description(taa.task_status_cd),3),")")
            items->prsnl_qual[pos].pDetail[cnt2].inc_item = "Forwarded Note"
            items->prsnl_qual[pos].pDetail[cnt2].task_activity = uar_get_code_description(ta.task_activity_cd)
            items->prsnl_qual[pos].pDetail[cnt2].task_status = uar_get_code_description(taa.task_status_cd)
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = ce.clinsig_updt_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ce.clinsig_updt_dt_tm, 1)
            items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(pr.name_full_formatted, 3)
            items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = pr.person_id
            items->prsnl_qual[pos].pDetail[cnt2].username = pr.username
            items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(pr.position_cd)
            items->prsnl_qual[pos].pDetail[cnt2].unique_id = ce.clinical_event_id
 
            items->qual[cnt].person_id          = p.person_id
            items->qual[cnt].encntr_id          = e.encntr_id
            items->qual[cnt].facility           = trim(uar_get_code_display(e.loc_facility_cd), 3)
            items->qual[cnt].arrive_dt           = e.arrive_dt_tm
            items->qual[cnt].disch_dt            = e.disch_dt_tm
            items->qual[cnt].note_type           = uar_get_code_display(ce.event_cd)
            items->qual[cnt].inc_item           = "Forwarded Note"
            items->qual[cnt].task_activity       = uar_get_code_description(ta.task_activity_cd)
            items->qual[cnt].task_status         = uar_get_code_description(taa.task_status_cd)
            items->qual[cnt].inc_item_dt_tm     = ce.clinsig_updt_dt_tm
            items->qual[cnt].inc_item_days      = datetimediff(cnvtdatetime(curdate, 0), ce.clinsig_updt_dt_tm, 1)
            items->qual[cnt].resp_user_name     = trim(pr.name_full_formatted, 3)
            items->qual[cnt].prsnl_id            = pr.person_id
            items->qual[cnt].username            = pr.username
            items->qual[cnt].position            = uar_get_code_display(pr.position_cd)
            items->qual[cnt].unique_id           = ce.clinical_event_id
    foot report
        items->qual_cnt = cnt
        stat = alterlist(items->qual,cnt)
    with nocounter , expand=2;, time=600
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_Forwarded_Notes")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
; need endorsements:
;---------------------------------------------------------------------------------------------------------------------------------
subroutine Get_Endorsements(NULL)
    set time1 = sysdate
    call echo("begin Get_Endorsements")
    call ctd_add_timer('Get_Endorsements')
 
    /* MMM174 We started getting pretty bad performance here... retrying with a new query below.
    select into ("NL:")
    from
        ce_event_action cea,
        ce_event_prsnl cep,
        prsnl p,
        person pt,
        encounter e,
        clinical_event ce,
        orders o
    plan cea where cea.updt_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
        ;expand(index,1,size(endorse_event_cd->qual,5),cea.event_cd, endorse_event_cd->qual[index].event_cd)
        and parser(phys_parser2)
    join cep
        where cep.event_id = cea.event_id
        and cep.valid_until_dt_tm > sysdate
        and cep.action_status_cd not in (656.00,653.00)
    join p where p.person_id = cep.action_prsnl_id
        and (textlen(trim(p.username)) > 0)
        and p.person_id not in (20428402.00,19411980.00)
    join e where e.encntr_id = cea.encntr_id
        and e.person_id = cea.person_id
        and parser(encntr_type_parser) ;e.encntr_type_cd            = 71_CLINIC_CD
        and parser(facility_parser)
        and e.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and e.active_ind = 1
    join pt where pt.person_id = e.person_id
    join ce where ce.event_id = cea.event_id
        and ce.valid_until_dt_tm > sysdate
    join o where o.order_id = outerjoin(ce.order_id)
    
    MMM174 end*/
    select into ("NL:")
    from encounter e
       , clinical_event ce
       , ce_event_action cea
       , ce_event_prsnl cep
       , prsnl p
       , person pt
       , orders o
    
    where expand(idx, 1, enc_pop->cnt, e.person_id, enc_pop->qual[idx]->per_id
                                     , e.encntr_id, enc_pop->qual[idx]->enc_id
                )
      
      and ce.valid_until_dt_tm > sysdate
      
      and cea.event_id = ce.event_id
      and cea.encntr_id = e.encntr_id
      and cea.updt_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
      ;and cea.updt_dt_tm BETWEEN  cnvtdatetime('29-AUG-2024')    and  cnvtdatetime(^04-Sep-2024 23:59:59^)
      and parser(phys_parser2)
      ;and 1=1
      
      and cep.event_id = cea.event_id
      and cep.valid_until_dt_tm > sysdate
      and cep.action_status_cd not in (656.00,653.00)
      
      and p.person_id = cep.action_prsnl_id
      and (textlen(trim(p.username)) > 0)
      and p.person_id not in (20428402.00,19411980.00)
   
      and pt.person_id = e.person_id
      
      and o.order_id = outerjoin(ce.order_id)
    Order by cea.action_prsnl_id, e.encntr_id, cea.ce_event_action_id
    head report
        cnt = items->qual_cnt
        head cea.action_prsnl_id
            null
            head e.encntr_id
            if(textlen(trim(p.username)) > 0)
                cnt = cnt + 1
                if(size(items->qual,5)<cnt)
                    stat = alterlist(items->qual, cnt + 99)
                endif
                pos = locateval(num, 1, size(items->prsnl_qual,5), p.person_id, items->prsnl_qual[num].prsnl_id)
                if(pos = 0)
                    pos = size(items->prsnl_qual,5) + 1
                    stat = alterlist(items->prsnl_qual, pos)
                    items->prsnl_qual[pos].resp_user_name = trim(p.name_full_formatted, 3)
                    items->prsnl_qual[pos].prsnl_id = p.person_id
                    items->prsnl_qual[pos].username = p.username
                    items->prsnl_qual[pos].position = uar_get_code_display(p.position_cd)
                endif
                items->endorsements_cnt = items->endorsements_cnt + 1
                items->prsnl_qual[pos].endorsements_cnt = items->prsnl_qual[pos].endorsements_cnt + 1
                items->prsnl_qual[pos].Need_endorsements = items->prsnl_qual[pos].Need_endorsements + 1
                cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
                stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
                items->prsnl_qual[pos].pDetail[cnt2].person_id = pt.person_id
                items->prsnl_qual[pos].pDetail[cnt2].pt_name = pt.name_full_formatted
                items->prsnl_qual[pos].pDetail[cnt2].encntr_id = e.encntr_id
                items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
                admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
                items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
                items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
                items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
                items->prsnl_qual[pos].pDetail[cnt2].note_type = uar_get_code_display(o.catalog_type_cd)
                items->prsnl_qual[pos].pDetail[cnt2].task_activity = uar_get_code_description(cep.action_type_cd)
                items->prsnl_qual[pos].pDetail[cnt2].task_status = uar_get_code_description(cea.endorse_status_cd)
                items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = build2(trim(uar_get_code_display(o.catalog_type_cd),3), " Result(s) - ",
                trim(uar_get_code_display(o.catalog_type_cd),3),trim(uar_get_code_description(cep.action_type_cd),3)," ",
                uar_get_code_description(cea.endorse_status_cd),")")
                items->prsnl_qual[pos].pDetail[cnt2].inc_item = build2(trim(uar_get_code_display(o.catalog_type_cd),3), " Result(s)")
                items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = cea.updt_dt_tm;
                items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), cea.updt_dt_tm, 1)
                items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(p.name_full_formatted, 3)
                items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = p.person_id
                items->prsnl_qual[pos].pDetail[cnt2].username = p.username
                items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(p.position_cd)
                items->prsnl_qual[pos].pDetail[cnt2].unique_id = cea.ce_event_action_id
 
                items->qual[cnt].person_id = e.person_id
                items->qual[cnt].encntr_id = e.encntr_id
                items->qual[cnt].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
                items->qual[cnt].arrive_dt = e.arrive_dt_tm
                items->qual[cnt].disch_dt = e.disch_dt_tm
                items->qual[cnt].note_type = uar_get_code_display(o.catalog_type_cd)
                items->qual[cnt].task_activity = uar_get_code_description(cep.action_type_cd)
                items->qual[cnt].task_status = uar_get_code_description(cea.endorse_status_cd)
                items->qual[cnt].inc_item = build2(trim(uar_get_code_display(o.catalog_type_cd),3), " Result(s)")
                items->qual[cnt].inc_item_dt_tm = cea.updt_dt_tm;
                items->qual[cnt].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), cea.updt_dt_tm, 1)
                items->qual[cnt].resp_user_name = trim(p.name_full_formatted, 3)
                items->qual[cnt].prsnl_id = p.person_id
                items->qual[cnt].username = p.username
                items->qual[cnt].position = uar_get_code_display(p.position_cd)
                items->qual[cnt].unique_id = cea.ce_event_action_id
            endif
    foot report
 
        items->qual_cnt = cnt
        stat = alterlist(items->qual,cnt)
    with nocounter , expand=2;, time=300
 
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_Endorsements")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
;Get_Documents
;---------------------------------------------------------------------------------------------------------------------------------
Subroutine Get_Documents(null)
    set time1 = sysdate
    call echo("begin Get_Documents")
    call ctd_add_timer('Get_Documents')
    /* MMM174 We started getting pretty bad performance here... retrying with a new query below.
    Select into "NL:"
        pt.name_full_formatted,
        ta.msg_subject,
        ta_update_dt = format(ta.updt_dt_tm, "mm/dd/yyyy hh:mm:ss;;D"),
        ta_update_dt = format(taa.updt_dt_tm, "mm/dd/yyyy hh:mm:ss;;D"),
        status=uar_get_code_display(ta.task_status_cd),
        task_activity=uar_get_code_display(ta.task_activity_cd),
        ta.encntr_id
    from
        task_activity_assignment taa,
        task_activity ta,
        task_activity_assignment taa2,  ;MMM not sure we are doing anything with this... maybe don't need?
        clinical_event ce,
        prsnl psl,
        person pt,
        encounter e
    plan taa where taa.active_ind = 1
        and taa.task_status_cd in(427.00    ;Opened
                                  ,429.00   ;Pending
                                  )
;           418.00  ;Canceled
;,          419.00  ;Complete
;,          420.00  ;Deleted
;,          421.00  ;Delivered
;,          422.00  ;Discontinued
;,          423.00  ;Dropped
;,          424.00  ;In Error
;,          425.00  ;InProcess
;,          426.00  ;OnHold
;,          428.00  ;Overdue
;,          430.00  ;Read
;,      3538794.00  ;Read Awaiting Signature
;,      4045110.00  ;Recalled
;,       614379.00  ;Refused
;,          431.00  ;Rework
;,          432.00  ;Suspended
;,       679985.00  ;Pending Validation
        and taa.rejection_ind = 0
        and taa.end_eff_dt_tm > sysdate
    ;   and taa.assign_prsnl_id = 1347258.00
        and parser(phys_parser5)
    join ta where ta.task_id = taa.task_id
        and ta.task_activity_cd != 666527.00
        and ta.event_class_cd = 231.00
    join taa2 where taa2.task_id = ta.task_id
    join ce where ce.event_id = ta.event_id
        and ce.valid_until_dt_tm > sysdate
        and ce.event_end_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm) ;kh
    join psl ;Get Ordering Physician name
        where psl.person_id = taa.assign_prsnl_id
        and (textlen(trim(psl.username)) > 0)
    join pt where pt.person_id = ta.person_id
    join e
        where e.encntr_id = ta.encntr_id
        and parser(encntr_type_parser) ;e.encntr_type_cd            = 71_CLINIC_CD
        and parser(facility_parser)
        and e.beg_effective_dt_tm      <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm       > cnvtdatetime(curdate, curtime3)
        and e.active_ind                = 1
    MMM174 end*/
    select into 'nl:' 
      from ENCOUNTER E 
         , CLINICAL_EVENT CE 
         , TASK_ACTIVITY TA
         , TASK_ACTIVITY_ASSIGNMENT TAA 
         , PERSON PT 
         , PRSNL PSL 
    
    where expand(idx, 1, enc_pop->cnt, e.person_id, enc_pop->qual[idx]->per_id
                                     , e.encntr_id, enc_pop->qual[idx]->enc_id
                )
       
       and ce.encntr_id = e.encntr_id
       and CE.VALID_UNTIL_DT_TM > sysdate
       and ce.event_end_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm) ;kh
       ;and CE.EVENT_END_DT_TM BETWEEN  cnvtdatetime('29-AUG-2024')    and  cnvtdatetime(^04-Sep-2024 23:59:59^)
       
       and TA.ENCNTR_ID  =    E.ENCNTR_ID
       and TA.PERSON_ID   =    E.PERSON_ID
       and TA.UPDT_DT_TM  >=   CE.EVENT_END_DT_TM
       and ta.event_id = ce.event_id
       and TA.TASK_ACTIVITY_CD !=    666527.000000 
       and TA.EVENT_CLASS_CD =    231.000000 
       
       and TAA.TASK_ID  =  TA.TASK_ID
       and TAA.ACTIVE_IND =    1 
       and TAA.TASK_STATUS_CD IN ( 427.000000, 429.000000)  
       and TAA.REJECTION_IND =    0 
       and TAA.END_EFF_DT_TM > cnvtdatetime(curdate, curtime3)
       and parser(phys_parser5)
       
       and PT.PERSON_ID =    TA.PERSON_ID 
       
       and PSL.PERSON_ID =    TAA.ASSIGN_PRSNL_ID 
       and (TEXTLEN(TRIM(PSL.USERNAME)) > 0)
    order by taa.assign_prsnl_id, ta.encntr_id, ce.event_id, ce.performed_dt_tm desc
    head report
        cnt = size(items->qual,5)
        head taa.assign_prsnl_id
            null
            head ta.encntr_id
                null
                head ce.event_id
                    if(textlen(trim(psl.username)) > 0)
                        cnt = cnt + 1
                        if(size(items->qual,5)<cnt)
                            stat = alterlist(items->qual, cnt + 99)
                        endif
                        pos = locateval(num, 1, size(items->prsnl_qual,5), psl.person_id, items->prsnl_qual[num].prsnl_id)
                        if(pos = 0)
                            pos = size(items->prsnl_qual,5) + 1
                            stat = alterlist(items->prsnl_qual, pos)
                            items->prsnl_qual[pos].resp_user_name = trim(psl.name_full_formatted, 3)
                            items->prsnl_qual[pos].prsnl_id = psl.person_id
                            items->prsnl_qual[pos].username = psl.username
                            items->prsnl_qual[pos].position = uar_get_code_display(psl.position_cd)
                        endif
                        items->documents_cnt = items->documents_cnt + 1
                        items->prsnl_qual[pos].documents_cnt = items->prsnl_qual[pos].documents_cnt + 1
                        items->prsnl_qual[pos].Documents_Count = items->prsnl_qual[pos].Documents_Count + 1
                        cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
                        stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
                        items->prsnl_qual[pos].pDetail[cnt2].person_id = e.person_id
                        items->prsnl_qual[pos].pDetail[cnt2].pt_name = pt.name_full_formatted
                        items->prsnl_qual[pos].pDetail[cnt2].encntr_id = e.encntr_id
                        items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
                        admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
                        items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
                        items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
                        items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
                        items->prsnl_qual[pos].pDetail[cnt2].note_type = "Documents"
                        items->prsnl_qual[pos].pDetail[cnt2].task_activity = uar_get_code_display(ta.task_activity_cd)
                        items->prsnl_qual[pos].pDetail[cnt2].task_status = uar_get_code_description(ta.task_status_cd)
                        items->prsnl_qual[pos].pDetail[cnt2].inc_item = replace(ta.msg_subject, char(10), " ")
                        items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = build2(trim(replace(ta.msg_subject, char(10), " "),3
                        ), "  - (Documents ",trim(uar_get_code_display(ta.task_activity_cd),3)," ",trim(uar_get_code_description(
                        ta.task_status_cd),3),")")
                        items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = ta.task_create_dt_tm;
                        items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ta.task_create_dt_tm, 1)
                        items->prsnl_qual[pos].pDetail[cnt2].result_dt_tm = ce.event_end_dt_tm ;kh
                        items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(psl.name_full_formatted, 3)
                        items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = psl.person_id
                        items->prsnl_qual[pos].pDetail[cnt2].username = psl.username
                        items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(psl.position_cd)
                        items->prsnl_qual[pos].pDetail[cnt2].unique_id = ta.event_id
 
                        items->qual[cnt].person_id = e.person_id
                        items->qual[cnt].encntr_id = e.encntr_id
                        items->qual[cnt].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
                        items->qual[cnt].arrive_dt = e.arrive_dt_tm
                        items->qual[cnt].disch_dt = e.disch_dt_tm
                        items->qual[cnt].note_type = "Documents"
                        items->qual[cnt].task_activity = uar_get_code_display(ta.task_activity_cd)
                        items->qual[cnt].task_status = uar_get_code_description(ta.task_status_cd)
                        items->qual[cnt].inc_item = replace(ta.msg_subject, char(10), " ")
                        items->qual[cnt].inc_item_dt_tm = ta.task_create_dt_tm;
                        items->qual[cnt].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ta.task_create_dt_tm, 1)
                        items->qual[cnt].result_dt_tm = ce.event_end_dt_tm ;kh
                        items->qual[cnt].resp_user_name = trim(psl.name_full_formatted, 3)
                        items->qual[cnt].prsnl_id = psl.person_id
                        items->qual[cnt].username = psl.username
                        items->qual[cnt].position = uar_get_code_display(psl.position_cd)
                        items->qual[cnt].unique_id = ta.event_id
                    endif
    foot report
        stat = alterlist(items->qual,cnt)
    with nocounter, time = 600, expand = 2
 
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_Documents")
    call ctd_end_timer(0)
end
 
 
;---------------------------------------------------------------------------------------------------------------------------------
;Get_Results
;---------------------------------------------------------------------------------------------------------------------------------
Subroutine Get_Results(null)
    set time1 = sysdate
    call echo("begin Get_Results")
    call ctd_add_timer('Get_Results 1')
 
;--------------------------------results that are event actions-------------------------------------------------------------------
    /* MMM174 We started getting pretty bad performance here... retrying with a new query below.
    select into "nl:"
    from ce_event_action cea,
         v500_event_set_explode ese,
         v500_event_set_code esc,
         clinical_event ce,
         clinical_event ce1, ;kh
         orders o,
         ce_dynamic_label dl,
         prsnl psl,
         v500_event_code ec,
         v500_event_set_code esc2,
         person pt,
         encounter e
    plan cea ;Get all endorsable results
        where cea.updt_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
        and cea.action_type_cd = 103.00 ;ACTION_TYPE_ORDER
        and cea.event_class_cd not in (232.00    ;MED
                                        ,228.00 ;Immunization
                                                )
        and PARSER(phys_parser2)
    ;We don't seem to join to ESE or ESC at all here... doesn't join to table, doesn't get referenced in report writer... I'm going
    ; to remove it.
    join ese ;Get the event_sets in the hierachy for cea.event_cd
        where ese.event_cd = cea.event_cd
    join esc ;Qualify only if cea.event_cd is under the "ALL RESULT SECTIONS" event_set
        where esc.event_set_cd = ese.event_set_cd
        and trim(esc.event_set_name) = "ALL RESULT SECTIONS"
    join ce ;Get result details
        where ce.event_id = cea.event_id
        and ce.valid_until_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00.00")  ;Load only current versions
    join ce1 where ce1.event_id = ce.parent_event_id
        and ce1.valid_until_dt_tm > sysdate
        and ce1.event_class_cd not in (226.00) ;GRP
    join o ;Get order to group results
        where o.order_id = outerjoin(ce.order_id)
        and o.catalog_type_cd != outerjoin(2516.00)
    join dl
        where dl.ce_dynamic_label_id = ce.ce_dynamic_label_id
    join psl ;Get Ordering Physician name
        where psl.person_id = cea.action_prsnl_id
        and trim( psl.username, 3) > ""
        and psl.person_id > 1.00
    join ec
        where ec.event_cd = ce.event_cd
    join esc2 ;Get the event_set_name for each result
        where cnvtupper(esc2.event_set_name) = cnvtupper(ec.event_set_name)
    join pt
        where pt.person_id = cea.person_id
    join e
        where e.encntr_id = cea.encntr_id
        and e.encntr_type_cd in (     309309.00, 5043178.00) ;71_CLINIC_CD
        and parser(facility_parser)
        and e.beg_effective_dt_tm      <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm       > cnvtdatetime(curdate, curtime3)
        and e.active_ind                = 1
    MMM174 end*/
    select into "nl:"
    from encounter e
       , ce_event_action cea
       , clinical_event ce
       , clinical_event ce1 ;kh
       , orders o
       , ce_dynamic_label dl
       , prsnl psl
       , person pt
       
    where expand(idx, 1, enc_pop->cnt, e.person_id, enc_pop->qual[idx]->per_id
                                     , e.encntr_id, enc_pop->qual[idx]->enc_id
                )
      
      and cea.encntr_id = e.encntr_id
      and cea.updt_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
      ;and cea.updt_dt_tm BETWEEN  cnvtdatetime('29-AUG-2024')    and  cnvtdatetime(^04-Sep-2024 23:59:59^)
      and cea.action_type_cd = 103.00 ;ACTION_TYPE_ORDER
      and cea.event_class_cd not in (232.00    ;MED
                                      ,228.00 ;Immunization
                                              )
      and PARSER(phys_parser2)
      ;and 1=1

      and ce.event_id = cea.event_id
      and ce.valid_until_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00.00")  ;Load only current versions
      
      and ce1.event_id = ce.parent_event_id
      and ce1.valid_until_dt_tm > sysdate
      and ce1.event_class_cd not in (226.00) ;GRP
    
      and o.order_id = outerjoin(ce.order_id)
      and o.catalog_type_cd != outerjoin(2516.00)
      
      and dl.ce_dynamic_label_id = ce.ce_dynamic_label_id
      
      and psl.person_id = cea.action_prsnl_id
      and trim( psl.username, 3) > ""
      and psl.person_id > 1.00
      
      and pt.person_id = cea.person_id

    order by cea.action_prsnl_id, cea.encntr_id
    head report
        cnt = size(items->qual,5)
        head cea.action_prsnl_id
            null
            head cea.encntr_id
                if(textlen(trim(psl.username)) > 0)
                    cnt = cnt + 1
                    if(size(items->qual,5)<cnt)
                        stat = alterlist(items->qual, cnt + 99)
                    endif
                    pos = locateval(num, 1, size(items->prsnl_qual,5), psl.person_id, items->prsnl_qual[num].prsnl_id)
                    if(pos = 0)
                        pos = size(items->prsnl_qual,5) + 1
                        stat = alterlist(items->prsnl_qual, pos)
                        items->prsnl_qual[pos].resp_user_name = trim(psl.name_full_formatted, 3)
                        items->prsnl_qual[pos].prsnl_id = psl.person_id
                        items->prsnl_qual[pos].username = psl.username
                        items->prsnl_qual[pos].position = uar_get_code_display(psl.position_cd)
                    endif
                    items->results_cnt = items->results_cnt + 1
                    items->prsnl_qual[pos].results_cnt = items->prsnl_qual[pos].results_cnt + 1
                    items->prsnl_qual[pos].Rst_Pend = items->prsnl_qual[pos].Rst_Pend + 1
                    cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
                    stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
                    items->prsnl_qual[pos].pDetail[cnt2].person_id = cea.person_id
                    items->prsnl_qual[pos].pDetail[cnt2].pt_name = pt.name_full_formatted
                    items->prsnl_qual[pos].pDetail[cnt2].encntr_id              = cea.encntr_id
                    If(e.loc_facility_cd = 0)
                        items->prsnl_qual[pos].pDetail[cnt2].facility = "EMRLINK"
                    else
                        items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
                    endif
                    admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
                    items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
                    items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
                    items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
                    items->prsnl_qual[pos].pDetail[cnt2].task_activity = uar_get_code_description(cea.action_type_cd)
                    items->prsnl_qual[pos].pDetail[cnt2].task_status = uar_get_code_description(cea.endorse_status_cd)
                    items->prsnl_qual[pos].pDetail[cnt2].note_type = uar_get_code_display(ce.catalog_cd)
                    items->prsnl_qual[pos].pDetail[cnt2].inc_item  = uar_get_code_description(ce.event_cd)
 
                    items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = build2(trim(uar_get_code_description(ce.event_cd),3),
                    "  - (",trim(uar_get_code_display(ce.catalog_cd),3)," ",trim(uar_get_code_description(cea.action_type_cd),3),
                    " ",trim(uar_get_code_description(cea.endorse_status_cd),3),")")
 
                    items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = cea.updt_dt_tm;
                    items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), cea.updt_dt_tm, 1)
                    items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(psl.name_full_formatted, 3)
                    items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = psl.person_id
                    items->prsnl_qual[pos].pDetail[cnt2].username = psl.username
                    items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(psl.position_cd)
                    items->prsnl_qual[pos].pDetail[cnt2].unique_id= cea.ce_event_action_id
 
 
                    items->qual[cnt].person_id              = cea.person_id
                    items->qual[cnt].encntr_id              = cea.encntr_id
                    If(e.loc_facility_cd = 0)
                        items->qual[cnt].facility               = "EMRLINK"
                    else
                        items->qual[cnt].facility               = trim(uar_get_code_display(e.loc_facility_cd), 3)
                    endif
                    items->qual[cnt].arrive_dt = e.arrive_dt_tm
                    items->qual[cnt].disch_dt = e.disch_dt_tm
                    items->qual[cnt].task_activity = uar_get_code_description(cea.action_type_cd)
                    items->qual[cnt].task_status = uar_get_code_description(cea.endorse_status_cd)
                    items->qual[cnt].note_type = uar_get_code_display(ce.catalog_cd)
                    items->qual[cnt].inc_item  = uar_get_code_description(ce.event_cd)
                    items->qual[cnt].inc_item_dt_tm = cea.updt_dt_tm;
                    items->qual[cnt].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), cea.updt_dt_tm, 1)
                    items->qual[cnt].resp_user_name = trim(psl.name_full_formatted, 3)
                    items->qual[cnt].prsnl_id = psl.person_id
                    items->qual[cnt].username = psl.username
                    items->qual[cnt].position = uar_get_code_display(psl.position_cd)
                    items->qual[cnt].unique_id= cea.ce_event_action_id
                endif
    foot report
        items->qual_cnt = cnt
        stat = alterlist(items->qual,cnt)
    with nocounter, time = 600, expand=2
    call ctd_end_timer(0)
 
;------------------------results that are endorsements required-------------------------------------------------------------------
 
    call ctd_add_timer('Get_Results 2')
    /* MMM174 We started getting pretty bad performance here... retrying with a new query below.
    Select into "nl:"
        pt.name_full_formatted,
        ta_task_type = uar_get_code_display(ta.task_type_cd),
        ta_task_activity = uar_get_code_display(ta.task_activity_cd),
        ta.msg_subject,
        event = uar_get_code_display(ta.event_cd),
        ta.event_cd
    from
        task_activity_assignment taa,
        task_activity ta,
        task_activity_assignment taa2,  ;Again... do we even use this one, I hope not because I'm removing it.
        clinical_event ce,
        v500_event_set_explode ese,
        v500_event_set_code esc,
        prsnl psl,
        person pt,
        encounter e
    plan taa
        where taa.active_ind = 1
        and taa.rejection_ind = 0
        and taa.end_eff_dt_tm > sysdate
        ;and taa.assign_prsnl_id = 1347258.00
        and taa.task_status_cd in ( 429.00 , 427.00)
        and parser(phys_parser5)
    join ta
        where ta.task_id = taa.task_id
        and ta.task_activity_cd in (2704.00)    ;Review Result
        and ta.task_create_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
    join taa2
        where taa2.task_id = ta.task_id
    join pt
        where pt.person_id = ta.person_id
    join ce ;Get result details
        where ce.event_id = ta.event_id
        and ce.event_reltn_cd != 132 ;child
        and ce.valid_until_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00.00")  ;Load only current versions
    join ese ;Get the event_sets in the hierachy for cea.event_cd
        where ese.event_cd = ce.event_cd
    join esc ;Qualify only if cea.event_cd is under the "ALL SERVICE SECTIONS" event_set
        where esc.event_set_cd = ese.event_set_cd
        and trim(esc.event_set_name) = "ALL SERVICE SECTIONS"
    join e
        where e.encntr_id = ta.encntr_id
        and parser(encntr_type_parser) ;e.encntr_type_cd            = 71_CLINIC_CD
        ;and e.encntr_type_cd in ( 71_CLINIC_CD )    ;309309.00, 5043178.00) ;
        and parser(facility_parser)
        and e.beg_effective_dt_tm      <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm       > cnvtdatetime(curdate, curtime3)
        and e.active_ind                = 1
    join psl ;Get Ordering Physician name
        where psl.person_id = taa.assign_prsnl_id
        and trim( psl.username, 3) > ""
        and psl.person_id > 1.00
    MMM174 end*/
    Select into "nl:"
        ;pt.name_full_formatted,
        ;ta_task_type = uar_get_code_display(ta.task_type_cd),
        ;ta_task_activity = uar_get_code_display(ta.task_activity_cd),
        ;ta.msg_subject,
        ;event = uar_get_code_display(ta.event_cd),
        ;ta.event_cd
     from encounter e
        , clinical_event ce
        , task_activity ta
        , task_activity_assignment taa
        , prsnl psl
        , person pt 
       
    where expand(idx, 1, enc_pop->cnt, e.person_id, enc_pop->qual[idx]->per_id
                                     , e.encntr_id, enc_pop->qual[idx]->enc_id
                )
      
      and ce.encntr_id      = e.encntr_id
      and ce.person_id      = e.person_id
      and ce.event_reltn_cd != 132 ;child
      and ce.valid_until_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00.00")  ;Load only current versions
      ;I hope I can get away with moving this up here... hopefully the results task and CE time filters sort of are the same?
      and ce.event_end_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm) ;kh
      ;and CE.EVENT_END_DT_TM BETWEEN  cnvtdatetime('29-AUG-2024')    and  cnvtdatetime(^04-Sep-2024 23:59:59^)
      and ce.event_cd in ( select ese.event_cd
                             from v500_event_set_code esc
                                , v500_event_set_explode ese
                            where trim(esc.event_set_name) = "ALL SERVICE SECTIONS"
                              and ese.event_set_cd = esc.event_set_cd
      )
      
      and ta.encntr_id  =    e.encntr_id
      and TA.PERSON_ID   =    E.PERSON_ID
      and ta.task_activity_cd in (2704.00)    ;Review Result
      and TA.UPDT_DT_TM  >=   CE.EVENT_END_DT_TM
      and ta.event_id = ce.event_id
      ;and ta.task_create_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
      ;and ta.task_create_dt_tm BETWEEN  cnvtdatetime('29-AUG-2024')    and  cnvtdatetime(^04-Sep-2024 23:59:59^)
      
      and taa.task_id = ta.task_id
      and taa.active_ind = 1
      and taa.rejection_ind = 0
      and taa.end_eff_dt_tm > sysdate
      ;and taa.assign_prsnl_id = 1347258.00
      and taa.task_status_cd in ( 429.00 , 427.00)
      and parser(phys_parser5)
      
      and pt.person_id = ta.person_id
      
      and psl.person_id = taa.assign_prsnl_id
      and trim( psl.username, 3) > ""
      and psl.person_id > 1.00

    order by taa.assign_prsnl_id, ta.encntr_id, ta.task_id, ce.performed_dt_tm desc
    head report
        cnt = items->qual_cnt
        head ta.task_id
            cnt = cnt + 1
            if(size(items->qual,5)<cnt)
                stat = alterlist(items->qual, cnt + 99)
            endif
            pos = locateval(num, 1, size(items->prsnl_qual,5), psl.person_id, items->prsnl_qual[num].prsnl_id)
            if(pos = 0)
                pos = size(items->prsnl_qual,5) + 1
                stat = alterlist(items->prsnl_qual, pos)
                items->prsnl_qual[pos].resp_user_name = trim(psl.name_full_formatted, 3)
                items->prsnl_qual[pos].prsnl_id = psl.person_id
                items->prsnl_qual[pos].username = psl.username
                items->prsnl_qual[pos].position = uar_get_code_display(psl.position_cd)
            endif
            items->results_cnt = items->results_cnt + 1
            items->prsnl_qual[pos].results_cnt = items->prsnl_qual[pos].results_cnt + 1
            items->prsnl_qual[pos].Rst_Pend_Endors = items->prsnl_qual[pos].Rst_Pend_Endors + 1
            cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
            stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
            items->prsnl_qual[pos].pDetail[cnt2].person_id = ta.person_id
            items->prsnl_qual[pos].pDetail[cnt2].pt_name = pt.name_full_formatted
            items->prsnl_qual[pos].pDetail[cnt2].encntr_id = ta.encntr_id
            items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
            admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
            items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
            items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].note_type = uar_get_code_description(ta.TASK_TYPE_CD)
            items->prsnl_qual[pos].pDetail[cnt2].task_activity = uar_get_code_description(ta.task_activity_cd)
            items->prsnl_qual[pos].pDetail[cnt2].task_status = uar_get_code_description(taa.task_status_cd)
            items->prsnl_qual[pos].pDetail[cnt2].inc_item = ta.msg_subject
 
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = build2(trim(ta.msg_subject,3),"  - (",
            trim(uar_get_code_description(ta.task_type_cd),3)," ",trim(uar_get_code_description(ta.task_activity_cd),3)," ",
            trim(uar_get_code_description(taa.task_status_cd),3),")")
 
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = ta.task_create_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ta.task_create_dt_tm, 1)
            items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(psl.name_full_formatted, 3)
            items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = psl.person_id
            items->prsnl_qual[pos].pDetail[cnt2].username = psl.username
            items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(psl.position_cd)
            items->prsnl_qual[pos].pDetail[cnt2].unique_id = ta.task_id; kh ce.clinical_event_id
 
 
            items->qual[cnt].person_id = ta.person_id
            items->qual[cnt].encntr_id = ta.encntr_id
            items->qual[cnt].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
            items->qual[cnt].arrive_dt = e.arrive_dt_tm
            items->qual[cnt].disch_dt = e.disch_dt_tm
            items->qual[cnt].note_type = uar_get_code_description(ta.TASK_TYPE_CD)
            items->qual[cnt].task_activity = uar_get_code_description(ta.task_activity_cd)
            items->qual[cnt].task_status = uar_get_code_description(taa.task_status_cd)
            items->qual[cnt].inc_item = ta.msg_subject
            items->qual[cnt].inc_item_dt_tm = ta.task_create_dt_tm
            items->qual[cnt].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ta.task_create_dt_tm, 1)
            items->qual[cnt].resp_user_name = trim(psl.name_full_formatted, 3)
            items->qual[cnt].prsnl_id = psl.person_id
            items->qual[cnt].username = psl.username
            items->qual[cnt].position = uar_get_code_display(psl.position_cd)
            items->qual[cnt].unique_id = ta.task_id; kh ce.clinical_event_id
    foot report
        items->qual_cnt = cnt
        stat = alterlist(items->qual,cnt)
    with nocounter, expand=2, time=600
 
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_Results")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
;Get_Proposed_Orders
;---------------------------------------------------------------------------------------------------------------------------------
Subroutine Get_Proposed_Orders(NULL)
    set time1 = sysdate
    call echo("begin Get_Proposed_Orders")
    call ctd_add_timer('Get_Proposed_Orders')
    /* MMM174 We started getting pretty bad performance here... retrying with a new query below.
    select into "NL:"
    from
        order_proposal op,
        prsnl psl,
        person pt,
        encounter e
    plan op
        where
        ;op.responsible_prsnl_id = 1347258.00
        parser(phys_parser6)
        and op.order_id = 0
        and op.proposal_status_cd = 4054156.00
        ;and op.proposal_source_type_cd = 56514982.00
        and op.created_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
    join pt
        where pt.person_id = op.person_id
    join e
        where e.encntr_id = op.originating_encntr_id
        and e.encntr_type_cd = 71_CLINIC_CD
        and parser(facility_parser)
        and e.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and e.active_ind = 1
    join psl ;Get Ordering Physician name
        where psl.person_id = op.responsible_prsnl_id
        and trim( psl.username, 3) > ""
        and psl.person_id > 1.00
    MMM174 end*/
    select into "NL:"
    from encounter e
       , order_proposal op
       
       , prsnl psl
       , person pt
       
    where expand(idx, 1, enc_pop->cnt, e.person_id, enc_pop->qual[idx]->per_id
                                     , e.encntr_id, enc_pop->qual[idx]->enc_id
                )
    
      and op.originating_encntr_id = e.encntr_id
      and op.originating_encntr_id = e.person_id
      and parser(phys_parser6)
          ;1=1
      and op.order_id = 0
      and op.proposal_status_cd = 4054156.00
      and op.created_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
      ;and op.created_dt_tm BETWEEN  cnvtdatetime('19-AUG-2024')    and  cnvtdatetime(^26-Sep-2024 23:59:59^)
    
      and pt.person_id = op.person_id
    
      and psl.person_id = op.responsible_prsnl_id
      and trim( psl.username, 3) > ""
      and psl.person_id > 1.00
    
    order by op.responsible_prsnl_id, op.originating_encntr_id, op.projected_order_id
    head report
        cnt = size(items->qual,5)
        head op.responsible_prsnl_id
            null
            head op.originating_encntr_id
                null
                head op.projected_order_id
                    if(textlen(trim(psl.username)) > 0)
                        cnt = cnt + 1
                        if(size(items->qual,5)<cnt)
                            stat = alterlist(items->qual, cnt + 99)
                        endif
                        pos = locateval(num, 1, size(items->prsnl_qual,5), psl.person_id, items->prsnl_qual[num].prsnl_id)
                        if(pos = 0)
                            pos = size(items->prsnl_qual,5) + 1
                            stat = alterlist(items->prsnl_qual, pos)
                            items->prsnl_qual[pos].resp_user_name = trim(psl.name_full_formatted, 3)
                            items->prsnl_qual[pos].prsnl_id = psl.person_id
                            items->prsnl_qual[pos].username = psl.username
                            items->prsnl_qual[pos].position = uar_get_code_display(psl.position_cd)
                        endif
                        items->proposed_ord_cnt = items->proposed_ord_cnt + 1
                        items->prsnl_qual[pos].proposed_ord_cnt = items->prsnl_qual[pos].proposed_ord_cnt + 1
                        items->prsnl_qual[pos].Prop_Ord_Count = items->prsnl_qual[pos].Prop_Ord_Count + 1
                        cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
                        stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
                        items->prsnl_qual[pos].pDetail[cnt2].person_id = op.person_id
                        items->prsnl_qual[pos].pDetail[cnt2].pt_name = pt.name_full_formatted
                        items->prsnl_qual[pos].pDetail[cnt2].encntr_id = op.originating_encntr_id
                        items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
                        admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
                        items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
                        items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
                        items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
                        items->prsnl_qual[pos].pDetail[cnt2].task_activity = "Proposed Order"
                        items->prsnl_qual[pos].pDetail[cnt2].task_status = "Pending"
                        items->prsnl_qual[pos].pDetail[cnt2].inc_item = uar_get_code_display(op.catalog_cd)
 
                        items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = build2(trim(uar_get_code_display(op.catalog_cd),3),
                        "  - (Proposed Order Pending)")
 
                        items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = op.created_dt_tm;
                        items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), op.created_dt_tm, 1)
                        items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(psl.name_full_formatted, 3)
                        items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = psl.person_id
                        items->prsnl_qual[pos].pDetail[cnt2].username = psl.username
                        items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(psl.position_cd)
                        items->prsnl_qual[pos].pDetail[cnt2].unique_id = op.projected_order_id
 
                        items->qual[cnt].person_id = op.person_id
                        items->qual[cnt].encntr_id = op.originating_encntr_id
                        items->qual[cnt].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
                        items->qual[cnt].arrive_dt = e.arrive_dt_tm
                        items->qual[cnt].disch_dt = e.disch_dt_tm
                        items->qual[cnt].task_activity = "Proposed Order"
                        items->qual[cnt].task_status = "Pending"
                        items->qual[cnt].inc_item = uar_get_code_display(op.catalog_cd)
                        items->qual[cnt].inc_item_dt_tm = op.created_dt_tm;
                        items->qual[cnt].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), op.created_dt_tm, 1)
                        items->qual[cnt].resp_user_name = trim(psl.name_full_formatted, 3)
                        items->qual[cnt].prsnl_id = psl.person_id
                        items->qual[cnt].username = psl.username
                        items->qual[cnt].position = uar_get_code_display(psl.position_cd)
                        items->qual[cnt].unique_id = op.projected_order_id
                    endif
    foot report
        stat = alterlist(items->qual,cnt)
    with nocounter, time = 600, expand=2
 
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_Proposed_Orders")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
;Get_CoSign_Orders
;---------------------------------------------------------------------------------------------------------------------------------
Subroutine Get_CoSign_Orders(NULL)
    set time1 = sysdate
    call echo("begin Get_CoSign_Orders")
    call ctd_add_timer('Get_CoSign_Orders')
    
    /* MMM174 We started getting pretty bad performance here... retrying with a new query below.
    Select into ("NL:")
        o.activity_type_cd,
        activity_type = uar_get_code_display(o.activity_type_cd),
        o.order_status_cd,
        order_status = uar_get_code_display(o.order_status_cd),
        on1.notification_status_flag,
        on1.notification_type_flag,
        on1.notification_reason_cd,
        notification_reason = uar_get_code_display(on1.notification_reason_cd),
        item = uar_get_code_display(o.catalog_cd),
        type = uar_get_code_display(o.catalog_type_cd)
    from
        orders o,
        order_notification on1,
        prsnl psl,
        person pt,
        encounter e
    plan on1
        where on1.notification_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
        and on1.notification_status_flag = 1
        and on1.notification_type_flag in ( 2)
        and parser(phys_parser7)
    join o
        where o.order_id = on1.order_id
        and o.need_doctor_cosign_ind = 1
    join pt
        where pt.person_id = o.person_id
    join e
        where e.encntr_id = o.encntr_id
        and parser(encntr_type_parser) ;e.encntr_type_cd            = 71_CLINIC_CD
        and parser(facility_parser)
        and e.beg_effective_dt_tm      <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm       > cnvtdatetime(curdate, curtime3)
        and e.active_ind                = 1
    join psl ;Get Ordering Physician name
        where psl.person_id = on1.to_prsnl_id
        and trim( psl.username, 3) > ""
        and psl.person_id > 1.00
    MMM174 end*/
    Select into ("NL:")
        ;o.activity_type_cd,
        ;activity_type = uar_get_code_display(o.activity_type_cd),
        ;o.order_status_cd,
        ;order_status = uar_get_code_display(o.order_status_cd),
        ;on1.notification_status_flag,
        ;on1.notification_type_flag,
        ;on1.notification_reason_cd,
        ;notification_reason = uar_get_code_display(on1.notification_reason_cd),
        ;item = uar_get_code_display(o.catalog_cd),
        ;type = uar_get_code_display(o.catalog_type_cd)
    from encounter e
       , orders o
       , order_notification on1
       , person pt
       , prsnl psl
        
    where expand(idx, 1, enc_pop->cnt, e.person_id, enc_pop->qual[idx]->per_id
                                     , e.encntr_id, enc_pop->qual[idx]->enc_id
               )
               
      and o.encntr_id = e.encntr_id
      and o.need_doctor_cosign_ind = 1
      
      and on1.order_id = o.order_id
      and on1.notification_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
      ;and on1.notification_dt_tm BETWEEN  cnvtdatetime('29-AUG-2024')    and  cnvtdatetime(^04-Sep-2024 23:59:59^)
      and on1.notification_status_flag = 1
      and on1.notification_type_flag in ( 2)
      and parser(phys_parser7)
      ;and 1=1
      
      and pt.person_id = o.person_id
      
      and psl.person_id = on1.to_prsnl_id
      and trim( psl.username, 3) > ""
      and psl.person_id > 1.00
    order by on1.to_prsnl_id, o.encntr_id, o.order_id
    head report
        cnt = size(items->qual,5)
        head on1.to_prsnl_id
            null
            head o.encntr_id
                null
                head o.order_id
                    null
                    detail
                        ;call echo(build2("here is the order_id: ", o.order_id))
                        if(textlen(trim(psl.username)) > 0)
                            cnt = cnt + 1
                            if(size(items->qual,5)<cnt)
                                stat = alterlist(items->qual, cnt + 99)
                            endif
                            pos = locateval(num, 1, size(items->prsnl_qual,5), psl.person_id, items->prsnl_qual[num].prsnl_id)
                            if(pos = 0)
                                pos = size(items->prsnl_qual,5) + 1
                                stat = alterlist(items->prsnl_qual, pos)
                                items->prsnl_qual[pos].resp_user_name = trim(psl.name_full_formatted, 3)
                                items->prsnl_qual[pos].prsnl_id = psl.person_id
                                items->prsnl_qual[pos].username = psl.username
                                items->prsnl_qual[pos].position = uar_get_code_display(psl.position_cd)
                            endif
                            items->cosign_orders_cnt = items->cosign_orders_cnt + 1
                            items->prsnl_qual[pos].cosign_orders_cnt = items->prsnl_qual[pos].cosign_orders_cnt + 1
                            items->prsnl_qual[pos].Cosign_Ord_Count = items->prsnl_qual[pos].Cosign_Ord_Count + 1
                            cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
                            stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
                            items->prsnl_qual[pos].pDetail[cnt2].person_id = o.person_id
                            items->prsnl_qual[pos].pDetail[cnt2].pt_name = pt.name_full_formatted
                            items->prsnl_qual[pos].pDetail[cnt2].encntr_id = o.encntr_id
                            items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
                            admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
                            items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
                            items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
                            items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
                            items->prsnl_qual[pos].pDetail[cnt2].task_activity = "Order for Cosign"
                            items->prsnl_qual[pos].pDetail[cnt2].task_status = "Pending"
                            items->prsnl_qual[pos].pDetail[cnt2].inc_item = uar_get_code_display(o.catalog_cd)
                            items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = build2(trim(uar_get_code_display(o.catalog_cd),3),
                            "  - (Order for Cosign Pending)")
 
                            items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = on1.updt_dt_tm;
                            items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), on1.updt_dt_tm, 1)
                            items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(psl.name_full_formatted, 3)
                            items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = psl.person_id
                            items->prsnl_qual[pos].pDetail[cnt2].username = psl.username
                            items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(psl.position_cd)
                            items->prsnl_qual[pos].pDetail[cnt2].unique_id = o.order_id
 
 
                            items->qual[cnt].person_id = o.person_id
                            items->qual[cnt].encntr_id = o.encntr_id
                            items->qual[cnt].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
                            items->qual[cnt].arrive_dt = e.arrive_dt_tm
                            items->qual[cnt].disch_dt = e.disch_dt_tm
                            items->qual[cnt].task_activity = "Order for Cosign"
                            items->qual[cnt].task_status = "Pending"
                            items->qual[cnt].inc_item = uar_get_code_display(o.catalog_cd)
                            items->qual[cnt].inc_item_dt_tm = on1.updt_dt_tm;
                            items->qual[cnt].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), on1.updt_dt_tm, 1)
                            items->qual[cnt].resp_user_name = trim(psl.name_full_formatted, 3)
                            items->qual[cnt].prsnl_id = psl.person_id
                            items->qual[cnt].username = psl.username
                            items->qual[cnt].position = uar_get_code_display(psl.position_cd)
                            items->qual[cnt].unique_id = o.order_id
                        endif
    foot report
        stat = alterlist(items->qual,cnt)
    with nocounter, time = 600, expand=2
    
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_CoSign_Orders")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
;Get_Messages
;---------------------------------------------------------------------------------------------------------------------------------
subroutine Get_Messages(NULL)
    set time1 = sysdate
    call echo("begin Get_Messages")
    call ctd_add_timer('Get_Messages')
    /* MMM174 We started getting pretty bad performance here... retrying with a new query below.
    Select into "nl:"
        pt.name_full_formatted,
        ta_task_type = uar_get_code_display(ta.task_type_cd),
        ta_task_activity = uar_get_code_display(ta.task_activity_cd),
        ta.msg_subject,
        event = uar_get_code_display(ta.event_cd),
        ta.event_cd
    from
        task_activity_assignment taa,
        task_activity ta,
        task_activity_assignment taa2,
        clinical_event ce,
        prsnl psl,
        person pt,
        encounter e
    plan taa
        where taa.active_ind = 1
        and taa.rejection_ind = 0
        and taa.end_eff_dt_tm > sysdate
        and taa.task_status_cd in ( 429.00 , 427.00)
        and parser(phys_parser5)
    join ta
        where ta.task_id = taa.task_id
        and ta.task_activity_cd in (
                                 2699.00        ;Complete Personal
                                ,2677.00        ;Personal
                                ,2678.00        ;Phone Msg
                                ,4054150.00     ;Saved Message
                                ,252562493.00   ;Secure Messages
                                )
        and ta.task_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
    join taa2
        where taa2.task_id = ta.task_id  ;We don't use this I don't think.
    join pt
        where pt.person_id = ta.person_id
    join ce ;Get result details
        where ce.event_id = ta.event_id
        and ce.valid_until_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00.00")  ;Load only current versions
    join e
        where e.encntr_id = ta.encntr_id
        and parser(encntr_type_parser) ;e.encntr_type_cd            = 71_CLINIC_CD
        ;and e.encntr_type_cd in ( 71_CLINIC_CD )    ;309309.00, 5043178.00) ;
        and parser(facility_parser)
        and e.beg_effective_dt_tm      <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm       > cnvtdatetime(curdate, curtime3)
        and e.active_ind                = 1
    join psl ;Get Ordering Physician name
        where psl.person_id = taa.assign_prsnl_id
        and trim( psl.username, 3) > ""
        and psl.person_id > 1.00
    
    MMM174 end*/
    Select into "nl:"
          pt.name_full_formatted,
          ta_task_type = uar_get_code_display(ta.task_type_cd),
          ta_task_activity = uar_get_code_display(ta.task_activity_cd),
          ta.msg_subject,
          event = uar_get_code_display(ta.event_cd),
          ta.event_cd
      from encounter e
         , task_activity_assignment taa
         , task_activity ta
         , clinical_event ce
         , prsnl psl
         , person pt
      
         
     where expand(idx, 1, enc_pop->cnt, e.person_id, enc_pop->qual[idx]->per_id
                                      , e.encntr_id, enc_pop->qual[idx]->enc_id
                 )
       
       and ta.encntr_id  =    e.encntr_id
       and ta.person_id  =    e.person_id
       and ta.updt_dt_tm >= cnvtdatetime(start_dt_tm)
       ;and ta.updt_dt_tm >= cnvtdatetime('29-AUG-2024')
       and ta.task_activity_cd in ( 2699.00       ;Complete Personal
                                  , 2677.00       ;Personal
                                  , 2678.00       ;Phone Msg
                                  , 4054150.00    ;Saved Message
                                  , 252562493.00  ;Secure Messages
                                  )
       and ta.task_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
       ;and ta.task_dt_tm BETWEEN  cnvtdatetime('29-AUG-2024')    and  cnvtdatetime(^04-Sep-2024 23:59:59^)
      
       and taa.task_id = ta.task_id
       and taa.active_ind = 1
       and taa.rejection_ind = 0
       and taa.end_eff_dt_tm > sysdate
       and taa.task_status_cd in ( 429.00 , 427.00)
       and parser(phys_parser5)
       ;and 1=1
      
       and pt.person_id = ta.person_id
       
       and ce.event_id = ta.event_id
       and ce.valid_until_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00.00") ;Load only current versions
      
       and psl.person_id = taa.assign_prsnl_id
       and trim( psl.username, 3) > ""
       and psl.person_id > 1.00
      
     order by taa.assign_prsnl_id, ta.encntr_id, ce.event_id, ce.performed_dt_tm DESC
head report
    cnt = items->qual_cnt
    head ta.task_id
        cnt = cnt + 1
        if(size(items->qual,5)<cnt)
            stat = alterlist(items->qual, cnt + 99)
        endif
        pos = locateval(num, 1, size(items->prsnl_qual,5), psl.person_id, items->prsnl_qual[num].prsnl_id)
        if(pos = 0)
            pos = size(items->prsnl_qual,5) + 1
            stat = alterlist(items->prsnl_qual, pos)
            items->prsnl_qual[pos].resp_user_name = trim(psl.name_full_formatted, 3)
            items->prsnl_qual[pos].prsnl_id = psl.person_id
            items->prsnl_qual[pos].username = psl.username
            items->prsnl_qual[pos].position = uar_get_code_display(psl.position_cd)
        endif
        items->messages_cnt = items->messages_cnt + 1
        items->prsnl_qual[pos].messages_cnt = items->prsnl_qual[pos].messages_cnt + 1
        items->prsnl_qual[pos].Message_Count = items->prsnl_qual[pos].Message_Count + 1
        cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
        stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
        items->prsnl_qual[pos].pDetail[cnt2].person_id = ta.person_id
        items->prsnl_qual[pos].pDetail[cnt2].pt_name = pt.name_full_formatted
        items->prsnl_qual[pos].pDetail[cnt2].encntr_id = ta.encntr_id
        items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
        admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
        items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
        items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
        items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
        items->prsnl_qual[pos].pDetail[cnt2].note_type = uar_get_code_description(ta.TASK_TYPE_CD)
        items->prsnl_qual[pos].pDetail[cnt2].task_activity = uar_get_code_description(ta.task_activity_cd)
        items->prsnl_qual[pos].pDetail[cnt2].task_status = uar_get_code_description(taa.task_status_cd)
        items->prsnl_qual[pos].pDetail[cnt2].inc_item = ta.msg_subject
        items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = build2(trim(ta.msg_subject,3),"  - (",
        trim(uar_get_code_description(ta.task_type_cd),3)," ",trim(uar_get_code_description(ta.task_activity_cd),3)," ",trim(
        uar_get_code_description(taa.task_status_cd),3),")")
 
        items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = ta.task_create_dt_tm
        items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ta.task_create_dt_tm, 1)
        items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(psl.name_full_formatted, 3)
        items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = psl.person_id
        items->prsnl_qual[pos].pDetail[cnt2].username = psl.username
        items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(psl.position_cd)
        items->prsnl_qual[pos].pDetail[cnt2].unique_id = ce.clinical_event_id
 
        items->qual[cnt].person_id = ta.person_id
        items->qual[cnt].encntr_id = ta.encntr_id
        items->qual[cnt].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
        items->qual[cnt].arrive_dt = e.arrive_dt_tm
        items->qual[cnt].disch_dt = e.disch_dt_tm
        items->qual[cnt].note_type = uar_get_code_description(ta.TASK_TYPE_CD)
        items->qual[cnt].task_activity = uar_get_code_description(ta.task_activity_cd)
        items->qual[cnt].task_status = uar_get_code_description(taa.task_status_cd)
        items->qual[cnt].inc_item = ta.msg_subject
        items->qual[cnt].inc_item_dt_tm = ta.task_create_dt_tm
        items->qual[cnt].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ta.task_create_dt_tm, 1)
        items->qual[cnt].resp_user_name = trim(psl.name_full_formatted, 3)
        items->qual[cnt].prsnl_id = psl.person_id
        items->qual[cnt].username = psl.username
        items->qual[cnt].position = uar_get_code_display(psl.position_cd)
        items->qual[cnt].unique_id = ce.clinical_event_id
    foot report
        items->qual_cnt = cnt
        stat = alterlist(items->qual,cnt)
    with nocounter, expand=2, time=600
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_Messages")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
; Prescription
;---------------------------------------------------------------------------------------------------------------------------------
subroutine Get_RX_Refills(NULL)
    set time1 = sysdate
    call echo("begin Get_RX_Refills")
    call ctd_add_timer('Get_RX_Refills')
    /* MMM174 We started getting pretty bad performance here... retrying with a new query below.
    select into "NL:" ;p.name_full_formatted, ta.*, tsa.*, taa.* ;ib.*
    from task_activity_assignment taa,
        task_activity ta,
        task_subactivity tsa,
        ib_rx_req_action ib,
        task_activity_assignment taa2,
        clinical_event ce,
        person p,
        prsnl pr,
        encounter e
    plan taa where taa.active_ind = 1
        and taa.task_status_cd in (427.00, 429.00)
        and taa.rejection_ind = 0
        and taa.end_eff_dt_tm > sysdate
        and parser(phys_parser5)
        ;and taa.updt_dt_tm
    join ta where ta.task_id = taa.task_id
        and ta.task_status_cd in (        427.00, 429.00)
        and ta.task_activity_cd in (
                                 2699.00    ;Complete Personal
                                ,4054150.00 ;Saved Message)
                                )
        and ta.task_type_cd in (
            1327531447.00   ;eRx Change
            ,4054145.00     ;Rx Message
            ,4309700.00     ;eRx Renewal Unmatched
            ,4309701.00     ;eRx Renewal
            ,4309702.00     ;eRx Renewal Suspect Match
            )
        and ta.task_create_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
        and ta.active_ind = 1
    join taa2 where taa2.task_id = ta.task_id
    join tsa where tsa.task_id = ta.task_id
        and tsa.updt_id > 1
    join ib where ib.ib_rx_req_id = tsa.ib_rx_req_id
        and ib.req_status_cd =     4309597.00
        and ib.end_effective_dt_tm > sysdate
    join ce
        where ce.event_id = ta.event_id
        and ce.authentic_flag = 1
        and ce.valid_until_dt_tm > sysdate
    join p    where p.person_id = ta.person_id
    join pr where pr.person_id = taa.assign_prsnl_id
    join e where e.encntr_id = ta.encntr_id
        and parser(encntr_type_parser) ;e.encntr_type_cd            = 71_CLINIC_CD
        and parser(facility_parser)
        and e.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
        and e.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
        and e.active_ind = 1
        
    MMM174 end*/
    select into "NL:" ;p.name_full_formatted, ta.*, tsa.*, taa.* ;ib.*
    from encounter e
       , task_activity ta
       , task_activity_assignment taa
       , task_subactivity tsa
       , ib_rx_req_action ib
       , clinical_event ce
       , person p
       , prsnl pr
    
    where expand(idx, 1, enc_pop->cnt, e.person_id, enc_pop->qual[idx]->per_id
                                      , e.encntr_id, enc_pop->qual[idx]->enc_id
                 )
    
      
      and ta.encntr_id  =    e.encntr_id
      and ta.person_id  =    e.person_id
      ;and ta.updt_dt_tm >= cnvtdatetime(start_dt_tm)
      and ta.updt_dt_tm >= cnvtdatetime('29-AUG-2024')
      and ta.task_status_cd in (        427.00, 429.00)
      and ta.task_activity_cd in (
                               2699.00    ;Complete Personal
                              ,4054150.00 ;Saved Message)
                              )
      and ta.task_type_cd in (
          1327531447.00   ;eRx Change
          ,4054145.00     ;Rx Message
          ,4309700.00     ;eRx Renewal Unmatched
          ,4309701.00     ;eRx Renewal
          ,4309702.00     ;eRx Renewal Suspect Match
          )
      and ta.task_create_dt_tm between cnvtdatetime(start_dt_tm) and cnvtdatetime(end_dt_tm)
      ;and ta.task_create_dt_tm BETWEEN  cnvtdatetime('29-AUG-2024')    and  cnvtdatetime(^04-Sep-2024 23:59:59^)
      and ta.active_ind = 1
    
      and taa.task_id = ta.task_id
      and taa.active_ind = 1
      and taa.task_status_cd in (427.00, 429.00)
      and taa.rejection_ind = 0
      and taa.end_eff_dt_tm > sysdate
      and parser(phys_parser5)
      ;and 1=1
      
      and tsa.task_id = ta.task_id
      and tsa.updt_id > 1
    
      and ib.ib_rx_req_id = tsa.ib_rx_req_id
      and ib.req_status_cd =     4309597.00
      and ib.begin_effective_dt_tm <= sysdate
      and ib.end_effective_dt_tm >= sysdate
      
      and ce.event_id = ta.event_id
      and ce.authentic_flag = 1
      and ce.valid_until_dt_tm > sysdate
      
      and p.person_id = ta.person_id
      
      and pr.person_id = taa.assign_prsnl_id
    head report
        cnt = items->qual_cnt
        head ta.task_id
            cnt = cnt + 1
            if(size(items->qual,5)<cnt)
                stat = alterlist(items->qual, cnt + 99)
            endif
            pos = locateval(num, 1, size(items->prsnl_qual,5), pr.person_id, items->prsnl_qual[num].prsnl_id)
            if(pos = 0)
                pos = size(items->prsnl_qual,5) + 1
                stat = alterlist(items->prsnl_qual, pos)
                items->prsnl_qual[pos].resp_user_name = trim(pr.name_full_formatted, 3)
                items->prsnl_qual[pos].prsnl_id = pr.person_id
                items->prsnl_qual[pos].username = pr.username
                items->prsnl_qual[pos].position = uar_get_code_display(pr.position_cd)
            endif
            items->rx_refills_cnt = items->rx_refills_cnt + 1
            items->rx_daysLag_cnt = items->rx_daysLag_cnt + datetimediff(cnvtdatetime(curdate, 0), ta.task_create_dt_tm, 1)
            items->prsnl_qual[pos].rx_refills_cnt = items->prsnl_qual[pos].rx_refills_cnt + 1
            items->prsnl_qual[pos].Rx_Refils_Count = items->prsnl_qual[pos].Rx_Refils_Count + 1
            cnt2 = size(items->prsnl_qual[pos].pDetail,5) + 1
            stat = alterlist(items->prsnl_qual[pos].pDetail, cnt2)
            items->prsnl_qual[pos].pDetail[cnt2].person_id = ta.person_id
            items->prsnl_qual[pos].pDetail[cnt2].pt_name = p.name_full_formatted
            items->prsnl_qual[pos].pDetail[cnt2].encntr_id = ta.encntr_id
            items->prsnl_qual[pos].pDetail[cnt2].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
            admit_disch = build2(format(e.arrive_dt_tm, "MM-DD-YY;;Q"), " - ",format(e.disch_dt_tm, "MM-DD-YY;;Q"))
            items->prsnl_qual[pos].pDetail[cnt2].admit_discharge = admit_disch
            items->prsnl_qual[pos].pDetail[cnt2].arrive_dt = e.arrive_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].disch_dt = e.disch_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].note_type = uar_get_code_description(ta.TASK_TYPE_CD)
            items->prsnl_qual[pos].pDetail[cnt2].task_activity = uar_get_code_description(ta.task_activity_cd)
            items->prsnl_qual[pos].pDetail[cnt2].task_status = uar_get_code_description(taa.task_status_cd)
            items->prsnl_qual[pos].pDetail[cnt2].inc_item = ta.msg_subject
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_vc = build2(trim(ta.msg_subject,3),"  - (",
            trim(uar_get_code_description(ta.task_type_cd),3)," ",trim(uar_get_code_description(ta.task_activity_cd),3)," ",trim(
            uar_get_code_description(taa.task_status_cd),3),")")
 
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_dt_tm = ta.task_create_dt_tm
            items->prsnl_qual[pos].pDetail[cnt2].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ta.task_create_dt_tm, 1)
            items->prsnl_qual[pos].pDetail[cnt2].resp_user_name = trim(pr.name_full_formatted, 3)
            items->prsnl_qual[pos].pDetail[cnt2].prsnl_id = pr.person_id
            items->prsnl_qual[pos].pDetail[cnt2].username = pr.username
            items->prsnl_qual[pos].pDetail[cnt2].position = uar_get_code_display(pr.position_cd)
            items->prsnl_qual[pos].pDetail[cnt2].unique_id = ce.clinical_event_id
 
            items->qual[cnt].person_id = ta.person_id
            items->qual[cnt].encntr_id = ta.encntr_id
            items->qual[cnt].facility = trim(uar_get_code_display(e.loc_facility_cd), 3)
            items->qual[cnt].arrive_dt = e.arrive_dt_tm
            items->qual[cnt].disch_dt = e.disch_dt_tm
            items->qual[cnt].note_type = uar_get_code_description(ta.TASK_TYPE_CD)
            items->qual[cnt].task_activity = uar_get_code_description(ta.task_activity_cd)
            items->qual[cnt].task_status = uar_get_code_description(taa.task_status_cd)
            items->qual[cnt].inc_item = ta.msg_subject
            items->qual[cnt].inc_item_dt_tm = ta.task_create_dt_tm
            items->qual[cnt].inc_item_days = datetimediff(cnvtdatetime(curdate, 0), ta.task_create_dt_tm, 1)
            items->qual[cnt].resp_user_name = trim(pr.name_full_formatted, 3)
            items->qual[cnt].prsnl_id = pr.person_id
            items->qual[cnt].username = pr.username
            items->qual[cnt].position = uar_get_code_display(pr.position_cd)
            items->qual[cnt].unique_id = ce.clinical_event_id
    foot report
        items->qual_cnt = cnt
        stat = alterlist(items->qual,cnt)
    with nocounter, expand=2, time=600
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_RX_Refills")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
; Get Patient Info
;---------------------------------------------------------------------------------------------------------------------------------
Subroutine Get_Patient_Info(NULL)
    set time1 = sysdate
    call echo("begin Get_Patient_Info")
    call ctd_add_timer('Get_Patient_Info')
    select into "NL:"
    from
        person p
    plan p where expand(index, 1, size(items->qual,5), p.person_id, items->qual[index].person_id)
    order by p.person_id
    head report
        pos = 0
        head p.person_id
            pos = locateval(num, 1, size(items->qual,5), p.person_id, items->qual[num].person_id )
            items->qual[pos].pt_name = trim(p.name_full_formatted, 3)
    foot p.person_id
        pos1=pos ; storing previous pos
        while(pos > 0 )
             items->qual[pos].pt_name = items->qual[pos1].pt_name
             pos = locateval(num2, pos+1,  size(items->qual,5), p.person_id , items->qual[num2].person_id)
        endwhile
    with nocounter, expand=2
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_Patient_Info")
    call ctd_end_timer(0)
end
 
 
;---------------------------------------------------------------------------------------------------------------------------------
; Last Login
;---------------------------------------------------------------------------------------------------------------------------------
Subroutine Get_Last_Login(NULL)
    call echo("begin Get_Last_Login")
    call ctd_add_timer('Get_Last_Login')
    set time1 = sysdate
    select distinct into "nl:"
    from OMF_APP_CTX_DAY_ST   O
        where expand(index, 1, size(items->qual,5), o.person_id, items->qual[index].prsnl_id)
    order by o.person_id,cnvtdatetime(o.start_day) desc
    head report
        pos = 0
        head o.person_id
            pos = locateval(num, 1, size(items->qual,5), o.person_id, items->qual[num].prsnl_id )
            items->qual[num].last_logon = o.start_day
    foot o.person_id
        pos1=pos ; storing previous pos
        while(pos > 0 )
             items->qual[pos].last_logon = items->qual[pos1].last_logon
             pos = locateval(num2, pos+1,  size(items->qual,5), o.person_id , items->qual[num2].prsnl_id)
        endwhile
    with nocounter, expand=2
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("end Get_Last_Login")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
; Get NPI
;---------------------------------------------------------------------------------------------------------------------------------
 
subroutine Get_NPI(NULL)
    call echo("Begin Get_NPI")
    call ctd_add_timer('Get_NPI')
    set time1 = sysdate
    select into "nl:"
    from prsnl_alias pa
        where expand(index, 1, size(items->qual,5), pa.person_id, items->qual[index].prsnl_id)
        and pa.prsnl_alias_type_cd = CS320_NPI
    order by pa.person_id
    head report
        pos = 0
        pos2 = 0
        head pa.person_id
            pos = locateval(num, 1, size(items->qual,5), pa.person_id, items->qual[num].prsnl_id )
            items->qual[pos].NPI = trim(pa.alias)
            pos2 = locateval(num, 1, size(items->prsnl_qual,5), pa.person_id, items->prsnl_qual[num].prsnl_id )
            resp_user = build2(items->prsnl_qual[pos2].resp_user_name, " (",trim(pa.alias),")")
            call echo(build2("NPI POS: ",pos2))
            items->prsnl_qual[pos2].NPI = trim(pa.alias)
            items->prsnl_qual[pos2].resp_user_name = resp_user
    foot pa.person_id
        pos1=pos ; storing previous pos
        while(pos > 0 )
             items->qual[pos].NPI = items->qual[pos1].NPI
             pos = locateval(num2, pos+1,  size(items->qual,5), pa.person_id , items->qual[num2].prsnl_id)
        endwhile
    with nocounter, expand=2
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("Finish Get_NPI")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
 
; Get Fin
;---------------------------------------------------------------------------------------------------------------------------------
subroutine Get_FIN(NULL)
    call echo("Begin Get_FIN")
    set time1= sysdate
    call ctd_add_timer('Get_FIN')
    select into "nl:"
    from encntr_alias ea
        where expand(index, 1, size(items->qual,5), ea.encntr_id, items->qual[index].encntr_id)
        and ea.encntr_alias_type_cd in (CS319_FIN_ALIAS_TYPE_CD)
        and ea.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
        and ea.active_ind = 1
    order by ea.encntr_id
    head report
        pos=0
        head ea.encntr_id
            pos = locateval(num, 1, size(items->qual,5), ea.encntr_id, items->qual[num].encntr_id)
            if(pos > 0)
                items->qual[pos].FIN = ea.alias
            endif
    foot ea.encntr_id
        pos1=pos ; storing previous pos
        while(pos > 0 )
               ;copying MRN to same encounter id
             items->qual[pos].FIN = items->qual[pos1].FIN
             pos = locateval(num2, pos+1,  size(items->qual,5), ea.encntr_id, items->qual[num2].encntr_id)
        endwhile
    with expand = 2, nocounter
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("End Get_FIN")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
; Get MRN
;---------------------------------------------------------------------------------------------------------------------------------
subroutine Get_MRN(NULL)
    call echo("Begin Get_MRN")
    set time1 = sysdate
    call ctd_add_timer('Get_MRN')
    select into "nl:"
    from encntr_alias ea
        where expand(index, 1, size(items->qual,5), ea.encntr_id, items->qual[index].encntr_id)
        and ea.encntr_alias_type_cd in (CS319_MRN_ALIAS_TYPE_CD);CS319_FIN_ALIAS_TYPE_CD
        and ea.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
        and ea.active_ind = 1
    order by ea.encntr_id
    head report
        pos=0
        head ea.encntr_id
            pos = locateval(num, 1, size(items->qual,5), ea.encntr_id, items->qual[num].encntr_id)
            if(pos > 0)
                items->qual[pos].MRN = ea.alias
            endif
    foot ea.encntr_id
        pos1=pos ; storing previous pos
        while(pos > 0 )
               ;copying MRN to same encounter id
             items->qual[pos].MRN = items->qual[pos1].MRN
             pos = locateval(num2, pos+1,  size(items->qual,5), ea.encntr_id, items->qual[num2].encntr_id)
        endwhile
    with expand = 2, nocounter
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("End Get_MRN")
    call ctd_end_timer(0)
end
 
;---------------------------------------------------------------------------------------------------------------------------------
; Build Output
;---------------------------------------------------------------------------------------------------------------------------------
;call echorecord(items)
;call echo(output_dest)
subroutine Build_Output(NULL)
    call echo("Finish Build_Output")
    set time1 = sysdate
    free record putREQUEST
    record putREQUEST (
        1 source_dir = vc
        1 source_filename = vc
        1 nbrlines = i4
        1 line [*]
            2 lineData = vc
        1 OverFlowPage [*]
            2 ofr_qual [*]
                3 ofr_line = vc
        1 IsBlob = c1
        1 document_size = i4
        1 document = gvc
    )
 
    set putREQUEST->source_dir = $OUTDEV
    set putREQUEST->IsBlob = "1"
     
    set putREQUEST->document = cnvtrectojson(items)
    set putREQUEST->document_size = size(putRequest->document)
    execute eks_put_source with replace(request,"PUTREQUEST"),replace(items,"PUTREPLY")
     
    call echoJSON(items)
 
;   select into $OUTDEV
;       Facility = trim(substring(1,100,items->qual[d.seq].facility),3),
;       Responsible_User = trim(substring(1,100,items->qual[d.seq].resp_user_name),3),
;       UserName = trim(substring(1,25,items->qual[d.seq].username),3),
;       NPI = trim(substring(1,25,items->qual[d.seq].npi),3),
;       LastLogin_DT = format(items->qual[d.seq].last_logon, "MM/DD/YYYY;;D"),
;       Note_Type = trim(substring(1,100,items->qual[d.seq].note_type),3),
;       Incomplete_Item = trim(substring(1,100,items->qual[d.seq].inc_item),3),
;       Task_activity = trim(substring(1,100,items->qual[d.seq].task_activity),3),
;       Task_Status_TAA = trim(substring(1,100,items->qual[d.seq].task_status),3),
;       Result_dt_tm = format(items->qual[d.seq].result_dt_tm, "MM/DD/YYYY;;D"), ;kh
;       Incomplete_DT_TM = format(items->qual[d.seq].inc_item_dt_tm, "MM/DD/YYYY;;D"),
;       Incomplete_Days = trim(substring(1,100,cnvtstring(items->qual[d.seq].inc_item_days)),3),
;       Patient_Name = trim(substring(1,100,items->qual[d.seq].pt_name),3),
;       Arrive_DT_TM = format(items->qual[d.seq].arrive_dt, "MM/DD/YYYY HH:MM;;D"),
;       Disch_DT_TM = format(items->qual[d.seq].disch_dt, "MM/DD/YYYY HH:MM;;D"),
;       MRN = trim(substring(1,100,items->qual[d.seq].mrn),3),
;       FIN = trim(substring(1,100,items->qual[d.seq].fin),3),
;       encntr_id = items->qual[d.seq].encntr_id,
;       unique_id = items->qual[d.seq].unique_id
;   from
;       (dummyt d with seq = value(size(items->qual,5)))
;   plan d
;       ;where items->qual[d.seq].inc_item_days > 0
;   order by Note_Type, UserName, Incomplete_Days
;   with nocounter, format, heading, format=stream, separator=" ";, pcformat('"', ',',1)
;
    set time2 = sysdate
    call echo(build2(datetimediff(time2,time1,4), " minutes"))
    call echo("Finish Build_Output")
    
end
 
#exit_script
set last_mod = "000 ek052880"
end
go
 
 