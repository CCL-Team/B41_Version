  drop program 14_st_ma_last_lmp:dba go
create program 14_st_ma_last_lmp:dba
 
/**********************************************************************************************
 Program Title:   Maternity Patient Last LMP
 
 Object name:     14_st_ma_last_lmp
 Source file:     14_st_ma_last_lmp.prg
 
 Purpose:         To gather the most recent LMP documented on the
                  current encounter. Able to be executed as smart template or
                  as a driver script for an mPage component, etc.
 
 Tables read:     CLINICAL_EVENT
 
 Executed from:   This is used in the Maternity Patient Handoff component
 
 Special Notes:   N/A
 
***********************************************************************************************
                  MODIFICATION CONTROL LOG
***********************************************************************************************
Mod Date        Analyst                 MCGA   Comment
--- ----------  ----------------------- ------ ------------------------------------------------
001 03/03/2020  Clayton Wooldridge      220155 Initial release
                                               Michael Mayes took this over for him
*************END OF ALL MODCONTROL BLOCKS* ***************************************************/
 
declare ERR_MSG = vc with protect, noconstant("")
declare EXEC_DT_TM = dq8 with protect, constant(cnvtdatetime(CURDATE, CURTIME))
 
 
if (validate(DEBUG_IND, 0) != 1)
    set DEBUG_IND = 0
endif
 
 
if (validate(COMP_ONLY_IND, 0) != 1)
    set COMP_ONLY_IND = 0
endif
 
 
if (not(validate(REPLY, 0)))
    record REPLY(
    1 text              = vc
    1 status_data
        2 status            = c1
        2 subeventstatus[1]
            3 operationname     = c15
            3 operationstatus   = c1
            3 targetobjectname  = c15
            3 targetobjectvalue = c100
    1 large_text_qual[*]
        2 text_segment      = vc
    )
endif

 
set REPLY->status_data->status = "F"
set REPLY->status_data->subeventstatus[1]->targetobjectvalue = "14_ST_MA_LAST_LMP"

 
;***************************************************************************
; CONSTANT VARIABLE DECLARATIONS
;***************************************************************************
if (not(validate(TEMP, 0)))
    record TEMP(
        1 clinical_event_id = f8
        1 event_id          = f8
        1 last_lmp          = vc
        1 last_lmp_dt       = vc
        1 last_lmp_dt2      = vc
    )
endif

 
;***************************************************************************
; TEMPLATE VARIABLE DECLARATIONS
;***************************************************************************
declare TMPLT_ENCNTR_ID = f8 with protect, noconstant(0.0)
declare TMPLT_PERSON_ID = f8 with protect, noconstant(0.0)

 
;***************************************************************************
; CONSTANT VARIABLE DECLARATIONS
;***************************************************************************
declare CV_LMP      = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 72, "LASTMENSTRUALPERIOD"))
declare CV_MENSES   = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 72, "DATEOFMENSESPRIORTOLMP"))
declare CV_INERROR1 = f8 with protect, constant(28.0)
declare CV_INERROR2 = f8 with protect, constant(29.0)
declare CV_INERROR3 = f8 with protect, constant(30.0)
declare CV_INERROR4 = f8 with protect, constant(31.0)

 
;***************************************************************************
; LOCAL VARIABLE DECLARATIONS
;***************************************************************************
declare qual_cnt = i4 with protect, noconstant(0)

 
;***************************************************************************
; RTF CONSTANT VARIABLE DECLARATIONS
;***************************************************************************
declare RHEAD   = vc with protect,  constant(concat("{\rtf1\ansi\deff0","{\fonttbl",
                                                    "{\f0\fmodern\Courier New;}{\f1 Arial;}}",
                                                    "{\colortbl;","\red0\green0\blue0;",
                                                    "\red255\green255\blue255;",
                                                    "\red0\green0\blue255;",
                                                    "\red0\green255\blue0;",
                                                    "\red255\green0\blue0;}\deftab2520?$@rtf@$?"))
declare REOL    = vc with protect,  constant("\par?$@rtf@$?")
declare RTFEOF  = vc with protect,  constant("}")

 
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
; GET THE ENCOUNTER INFO FOR THIS EXECUTION
;***************************************************************************
select into "nl:"
  from encounter e
  plan e 
   where e.encntr_id = REQUEST->visit[1]->encntr_id
detail
    TMPLT_ENCNTR_ID     = e.encntr_id
    TMPLT_PERSON_ID     = e.person_id
with NOCOUNTER, TIME=300
 
if (error(ERR_MSG, 0) > 0)
    call LogMSG("*** THE ENCOUNTER QUERY HAS FAILED ***", 1)
    go to EXIT_PROGRAM
endif
 
if (TMPLT_ENCNTR_ID = 0.0)
    call LogMSG("*** THE ENCOUNTER ID IS ZERO ***", 1)
    go to EXIT_PROGRAM
endif
 
 
set stat = initrec(TEMP) ;MAKE SAFE FOR RE-USE
 
;***************************************************************************
; GET TODAY'S ORDERS FOR THIS EXECUTION
;***************************************************************************
select into "nl:"
  from clinical_event ce
     , ce_date_result cdr
  plan ce 
   where ce.encntr_id         =  TMPLT_ENCNTR_ID
     and ce.person_id         =  TMPLT_PERSON_ID
     and ce.event_cd          in (CV_LMP, CV_MENSES)
     and ce.valid_until_dt_tm =  cnvtdatetime("31-DEC-2100")
     and ce.result_status_cd  not in (CV_INERROR1, CV_INERROR2, CV_INERROR3, CV_INERROR4)
     and ce.view_level        =  1
   join cdr
    where cdr.event_id        = outerjoin(ce.event_id)
order by ce.event_end_dt_tm desc, ce.event_id
head report
    TEMP->clinical_event_id = ce.clinical_event_id
    TEMP->event_id          = ce.event_id
    TEMP->last_lmp          = trim(ce.result_val, 3)
    TEMP->last_lmp_dt       = trim(format(ce.event_end_dt_tm, "MM/DD/YYYY HH:MM;;Q"), 3)
    TEMP->last_lmp_dt2      = trim(format(ce.event_end_dt_tm, "MM/DD/YYYY;;Q"), 3)
    
    if(cdr.event_id is not null)
        TEMP->last_lmp      = trim(format(cdr.result_dt_tm, '@SHORTDATE'), 3)
    endif
    
with nocounter, time=300
 
if (error(ERR_MSG, 0) > 0)
    call LogMSG("*** THE CLINICAL EVENT QUERY HAS FAILED ***", 1)
    go to EXIT_PROGRAM
endif
 
if (COMP_ONLY_IND = 1)
    set REPLY->status_data->status = evaluate(TEMP->event_id, 0.0, "Z", "S")
    go to EXIT_PROGRAM
endif
 
 
;***************************************************************************
; BUILD THE RTF OUTPUT FOR THE SMART TEMPLATE VERSION
;***************************************************************************
if (TEMP->event_id = 0.0)
    set REPLY->text = concat(RHEAD, REOL, "No LMP documented on this encounter", RTFEOF)

else
    set REPLY->text = build2("\plain\f1\fs20\b\ul\cb2\pard\sl0?$@rtf@$?", "Most Recent LMP", REOL)
    set REPLY->text = build2(REPLY->text, "\plain\f1\fs20\cb2?$@rtf@$?", TEMP->last_lmp, REOL)
    set REPLY->text = build2(RHEAD, REPLY->text, RTFEOF)

endif
 
if (error(ERR_MSG, 0) = 0)
    set REPLY->status_data->status = "S"
endif
 
#EXIT_PROGRAM
 
if ((COMP_ONLY_IND = 0) and (REPLY->status_data->status = "F"))
    set REPLY->text = concat(RHEAD, REOL, "An error has occured. Please contact the help desk", RTFEOF)
endif
 
set REPLY->text = replace(REPLY->text, "?$@rtf@$?", " ", 0)

call echorecord(TEMP)
call echorecord(REPLY)
 
end
go
