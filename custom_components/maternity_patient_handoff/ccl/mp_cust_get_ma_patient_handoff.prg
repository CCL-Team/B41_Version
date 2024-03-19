  drop program mp_cust_get_ma_patient_handoff:dba go
create program mp_cust_get_ma_patient_handoff:dba
 
/**********************************************************************************************
 Program Title:   MP_CUST_GET_MA_PATIENT_HANDOFF
 
 Object name:     mp_cust_get_ma_patient_handoff
 Source file:     mp_cust_get_ma_patient_handoff.prg
 
 Purpose:         This script calls three smart templates and returns to a
                  front end component for Maternity Patient Handoff.
 
 Tables read:     N/A
 
 Executed from:   mPage
 
 Special Notes:   N/A
 
***********************************************************************************************
                  MODIFICATION CONTROL LOG
***********************************************************************************************
Mod Date        Analyst                 MCGA   Comment
--- ----------  ----------------------- ------ ------------------------------------------------
001 03/03/2020  Clayton Wooldridge      220155 Initial release
                                               Michael Mayes took this over for him
*************END OF ALL MODCONTROL BLOCKS* ***************************************************/
 
prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Person ID:" = 0
    , "Encounter ID:" = 0
with OUTDEV, PERSON_ID, ENCNTR_ID
 
 
declare ERR_MSG = vc with protect, noconstant("")
declare EXEC_DT_TM = dq8 with protect, constant(cnvtdatetime(CURDATE, CURTIME))
 
 
if (validate(DEBUG_IND, 0) != 1)
    set DEBUG_IND = 0
endif
 
if (not(validate(REPLY, 0)))
    record REPLY(
%i cust_script:status_block.inc
    )
endif
 
 
set REPLY->status_data->status = "F"
set REPLY->status_data->subeventstatus[1]->targetobjectvalue = "MP_CUST_GET_MA_PATIENT_HANDOFF"
 
 
;***************************************************************************
; EKS_PUT_SOURCE REQUEST RECORD DEFINITION
;***************************************************************************
free record EKSREQUEST
record EKSREQUEST(
    1 source_dir        = vc
    1 source_filename   = vc
    1 nbrlines          = i4
    1 line[*]
        2 linedata      = vc
    1 overflowpage[*]
        2 ofr_qual[*]
            3 ofr_line  = vc
    1 isblob            = c1
    1 document_size     = i4
    1 document          = gvc
)
 
 
;***************************************************************************
; GENERIC DCP_RPT_DRIVER REQUEST RECORD DEFINITION
;***************************************************************************
if (not(validate(TEMPREQ, 0)))
    record TEMPREQ(
        1 visit_cnt         = i4
        1 visit[*]
            2 encntr_id     = f8
    )
endif
 
 
;***************************************************************************
; GENERIC DCP_RPT_DRIVER REPLY RECORD DEFINITION
;***************************************************************************
if (not(validate(TEMPREP, 0)))
    record TEMPREP(
        1 text                      = vc
        1 status_data
            2 status                = c1
            2 subeventstatus[1]
                3 operationname     = c15
                3 operationstatus   = c1
                3 targetobjectname  = c15
                3 targetobjectvalue = c100
        1 large_text_qual[*]
            2 text_segment          = vc
    )
endif
 
 
;***************************************************************************
; 14_ST_MA_HEALTH_MAINT DATA RECORD DEFINITION
;***************************************************************************
if (not(validate(TEMPREC, 0)))
    record TEMPREC(
        1 qual_cnt       = i4
        1 qual[*]
            2 recom_id   = f8
            2 recom_name = vc
            2 due_date   = vc
            2 due_status = vc
            2 satis_date = vc
            2 status     = vc
        1 max_length     = i4
    )
endif
 
 
;***************************************************************************
; 14_ST_MA_HANDOFF_ORDERS DATA RECORD DEFINITION
;***************************************************************************
if (not(validate(TEMPORD, 0)))
    record TEMPORD(
    1 qual_cnt          = i4
    1 qual[*]
        2 order_id      = f8
        2 order_name    = vc
        2 order_status  = vc
    )
endif
 
 
;***************************************************************************
; 14_ST_MA_LAST_LMP DATA RECORD DEFINITION
;***************************************************************************
if (not(validate(TEMPLMP, 0)))
    record TEMPLMP(
        1 clinical_event_id = f8
        1 event_id          = f8
        1 last_lmp          = vc
        1 last_lmp_dt       = vc
        1 last_lmp_dt2      = vc
    )
endif
 
 
;***************************************************************************
; CONSTANT VARIABLE DECLARATIONS
;***************************************************************************
if (not(validate(COMP_REPLY, 0)))
    record COMP_REPLY(
        1 health_recom      = vc
        1 handoff_orders    = vc
        1 last_lmp          = vc
        1 handoff           = vc
        1 handoff_cd        = f8
        1 handoff_dt        = vc
        1 handoff_dt2       = vc
        1 data_ind          = i2
        1 encntr_id         = f8
        1 person_id         = f8
    )
endif
 
 
;***************************************************************************
; GLOBAL VARIABLE DECLARATIONS
;***************************************************************************
declare COMP_ONLY_MODE = i2 with public, noconstant(0)

 
;***************************************************************************
; CONSTANT CODE VARIABLE DECLARATIONS
;***************************************************************************
declare CV_HANDOFF  = f8 with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'MATERNITYPATIENTHANDOFFDOCUMENTATION'))
declare CV_INERROR1 = f8 with protect, constant(28.0)
declare CV_INERROR2 = f8 with protect, constant(29.0)
declare CV_INERROR3 = f8 with protect, constant(30.0)
declare CV_INERROR4 = f8 with protect, constant(31.0)

 
;***************************************************************************
; LOCAL VARIABLE DECLARATIONS
;***************************************************************************
declare sHTML = vc with protect, noconstant("")

 
;***************************************************************************
; SUBROUTINE TO DISPLAY RUNTIME MESSAGES IF NECESSARY
;***************************************************************************
subroutine (LogMSG(msg = vc, mode = i2(value, 0)) = null with protect)
 
    set msg = trim(msg, 3)
    if ((msg > "") and ((DEBUG_IND = 1) or (mode = 1)))
        call echo(trim(msg, 3))
    endif
 
end ;LogMSG
 
 
;***************************************************************************
; SUBROUTINE TO CONVERT THE RECORD STRUCTURE TO A JSON FILE
;***************************************************************************
subroutine (SendJSON(dest = vc, comp_data = vc(ref)) = null with protect)
 
    free record EKSREQUEST
    record EKSREQUEST(
        1 source_dir       = vc
        1 source_filename  = vc
        1 nbrlines         = i4
        1 line[*]
            2 linedata     = vc
        1 overflowpage[*]
            2 ofr_qual[*]
                3 ofr_line = vc
        1 isblob           = c1
        1 document_size    = i4
        1 document         = gvc
    )

 
    set EKSREQUEST->source_dir = dest
    set EKSREQUEST->isblob = '1'
    set EKSREQUEST->document = cnvtrectojson(comp_data)
    set EKSREQUEST->document_size = size(EKSREQUEST->document)
     
    execute eks_put_source with replace(REQUEST, EKSREQUEST);, replace(REPLY, EKSREPLY)
 
end ;SendJSON
 

set COMP_REPLY->handoff_cd = CV_HANDOFF

 
;***************************************************************************
; GET THE ENCOUNTER INFO FOR THIS EXECUTION
;***************************************************************************
select into "nl:"
  from encounter e
  plan e 
   where e.encntr_id = $ENCNTR_ID
detail
    COMP_REPLY->encntr_id = e.encntr_id
    COMP_REPLY->person_id = e.person_id
with NOCOUNTER, TIME=300
 
 
if (error(ERR_MSG, 0) > 0)
    call LogMSG("*** THE ENCOUNTER QUERY HAS FAILED ***", 1)
    go to EXIT_PROGRAM
endif
 
 
if (COMP_REPLY->encntr_id = 0.0)
    call LogMSG("*** THE ENCOUNTER ID IS ZERO ***", 1)
    go to EXIT_PROGRAM
endif
 

set stat = alterlist(TEMPREQ->visit, 1)
set TEMPREQ->visit[1]->encntr_id = COMP_REPLY->encntr_id
 
 
;***************************************************************************
; POPULATE THE PATIENT HANDOFF TODAY'S ORDERS
;***************************************************************************
set stat = initrec(TEMPREP) ;MAKE SAFE FOR RE-USE

execute 14_st_ma_handoff_orders:dba with replace(REQUEST, TEMPREQ), replace(REPLY, TEMPREP), replace(TEMP, TEMPORD)

if (TEMPREP->status_data->status = "F")
    go to EXIT_PROGRAM
endif

 
set sHTML = ^<p><span class="mmatph_title">Today's Orders</span><br/>^

 
if (TEMPORD->qual_cnt = 0)
    set sHTML = concat(sHTML, ^No orders found on this encounter^)
else
    set COMP_REPLY->data_ind = 1
    for (qual_cnt = 1 to TEMPORD->qual_cnt)
        if (qual_cnt != TEMPORD->qual_cnt)
            set sHTML = concat(sHTML, trim(TEMPORD->qual[qual_cnt]->order_name, 3), ^ - <span class="mmatph_title">^,
                                      trim(TEMPORD->qual[qual_cnt]->order_status, 3), ^</span></br>^)
        else
            set sHTML = concat(sHTML, trim(TEMPORD->qual[qual_cnt]->order_name, 3), ^ - <span class="mmatph_title">^,
                                      trim(TEMPORD->qual[qual_cnt]->order_status, 3), ^</span>^)
        endif
    endfor
endif

 
set sHTML = concat(sHTML, ^</p>^)
set COMP_REPLY->handoff_orders = trim(sHTML, 3)
 
 
;***************************************************************************
; POPULATE THE HEALTH RECOMMENDATIONS REQUESTED BY MATERNITY
;***************************************************************************
set stat = initrec(TEMPREP) ;MAKE SAFE FOR RE-USE

execute 14_st_ma_health_maint:dba with replace(REQUEST, TEMPREQ), replace(REPLY, TEMPREP), replace(TEMP, TEMPREC)

if (TEMPREP->status_data->status = "F")
    go to EXIT_PROGRAM
endif

 
set sHTML = ^<p><span class="mmatph_title">Recommendations Addressed Today</span><br/>^

 
if (TEMPREC->qual_cnt = 0)
    set sHTML = concat(sHTML, ^No recommendations addressed today^)
else
    set COMP_REPLY->data_ind = 1
    for (qual_cnt = 1 to TEMPREC->qual_cnt)
        if (qual_cnt != TEMPREC->qual_cnt)
            set sHTML = concat(sHTML, trim(TEMPREC->qual[qual_cnt]->recom_name, 3),^</br>^)
        else
            set sHTML = concat(sHTML, trim(TEMPREC->qual[qual_cnt]->recom_name, 3))
        endif
    endfor
endif
 
 
set sHTML = concat(sHTML, ^</p>^)
set COMP_REPLY->health_recom = trim(sHTML, 3)
 
;***************************************************************************
; POPULATE THE LATEST LMP CHARTED ON THIS ENCOUNTER
;***************************************************************************
set stat = initrec(TEMPREP) ;MAKE SAFE FOR RE-USE

execute 14_st_ma_last_lmp:dba with replace(REQUEST, TEMPREQ), replace(REPLY, TEMPREP), replace(TEMP, TEMPLMP)

if (TEMPREP->status_data->status = "F")
    go to EXIT_PROGRAM
endif
 
 
set sHTML = ^<p><span class="mmatph_title">Most Recent LMP</span><br/>^
 
 
if (TEMPLMP->event_id = 0.0)
    set sHTML = concat(sHTML, ^No LMP charted on this encounter^)
else
    set COMP_REPLY->data_ind = 1
    set sHTML = concat(sHTML, TEMPLMP->last_lmp)
endif

call echorecord(TEMPLMP)
 
 
set sHTML = concat(sHTML, ^</p>^)
set COMP_REPLY->last_lmp = trim(sHTML, 3)
 
 
;***************************************************************************
; POPULATE THE LAST PATIENT HANDOFF COMMUNICATION FOR THIS ENCOUNTER
;***************************************************************************
select into "nl:"
  from clinical_event ce
plan ce 
 where ce.encntr_id            =  COMP_REPLY->encntr_id
   and ce.person_id            =  COMP_REPLY->person_id
   and ce.event_cd             =  CV_HANDOFF
   and ce.valid_until_dt_tm    =  cnvtdatetime("31-DEC-2100")
   and ce.result_status_cd not in (CV_INERROR1, CV_INERROR2, CV_INERROR3, CV_INERROR4)
order by cnvtdatetime(ce.event_end_dt_tm) desc, ce.event_id
head report
    COMP_REPLY->handoff     = trim(ce.result_val, 3)
    COMP_REPLY->handoff_dt  = format(ce.event_end_dt_tm, "MM/DD/YYYY HH:MM;;Q")
    COMP_REPLY->handoff_dt2 = format(ce.event_end_dt_tm, "MM/DD/YYYY;;Q")
    COMP_REPLY->data_ind    = 1
with NOCOUNTER, TIME=300
 
 
if (error(ERR_MSG, 0) > 0)
    call LogMSG("*** THE LAST PATIENT HANDOFF QUERY HAS FAILED ***", 1)
    go to EXIT_PROGRAM
endif
 
 
#EXIT_PROGRAM
 
if (DEBUG_IND = 1)
    call echojson(COMP_REPLY)
endif
 
call SendJSON($OUTDEV, COMP_REPLY)
 
end
go