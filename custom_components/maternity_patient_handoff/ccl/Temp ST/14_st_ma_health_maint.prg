  drop program 14_st_ma_health_maint:dba go
create program 14_st_ma_health_maint:dba
 
/**********************************************************************************************
 Program Title:   Maternity Patient Health Recommendations
 
 Object name:     14_st_ma_health_maint
 Source file:     14_st_ma_health_maint.prg
 
 Purpose:         To gather up health recommendations addressed on the
                  current encounter. Able to be executed as smart template or
                  as a driver script for an mPage component, etc.
 
 Tables read:     HM_RECOMMENDATION
                  HM_EXPECT
                  HM_RECOMMENDATION_ACTION
                  HM_EXPECT_SAT
                  DM_FLAGS
                  CLINICAL_EVENT
                  ORDERS
 
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
 
declare ERR_MSG    = vc  with protect, noconstant("")
declare EXEC_DT_TM = dq8 with protect, constant(cnvtdatetime(CURDATE, CURTIME))
 
 
if (validate(DEBUG_IND, 0) != 1)
    set DEBUG_IND = 0
endif

 
if (validate(COMP_ONLY_IND, 0) != 1)
    set COMP_ONLY_IND = 0
endif

 
if (not(validate(REPLY, 0)))
record REPLY(
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
 
 
set REPLY->status_data->status = "F"
set REPLY->status_data->subeventstatus[1]->targetobjectvalue = "14_ST_MA_HEALTH_MAINT"
 
;***************************************************************************
; CONSTANT VARIABLE DECLARATIONS
;***************************************************************************
if (not(validate(TEMP, 0)))
    record TEMP(
    1 qual_cnt          = i4
    1 qual[*]
        2 recom_id      = f8
        2 recom_name    = vc
        2 due_date      = vc
        2 due_status    = vc
        2 satis_date    = vc
        2 status        = vc
    )
endif
 
;***************************************************************************
; TEMPLATE VARIABLE DECLARATIONS
;***************************************************************************
declare TMPLT_ENCNTR_ID     = f8 with protect, noconstant(0.0)
declare TMPLT_PERSON_ID     = f8 with protect, noconstant(0.0)
declare TMPLT_VISIT_DATE    = vc with protect, noconstant("")

 
;***************************************************************************
; LOCAL VARIABLE DECLARATIONS
;***************************************************************************
declare HM_BREAST_CANCER_SCREEN     = f8 with protect, noconstant(0.0)
declare HM_CERVICAL_CANCER_SCREEN   = f8 with protect, noconstant(0.0)
declare HM_TDAP_VACCINE             = f8 with protect, noconstant(0.0)
declare HM_INFLUENZA_VACCINE        = f8 with protect, noconstant(0.0)

 
;***************************************************************************
; LOCAL VARIABLE DECLARATIONS
;***************************************************************************
declare series_cnt  = i4 with protect, noconstant(0)
declare qual_cnt    = i4 with protect, noconstant(0)
declare max_length  = i4 with protect, noconstant(0)
 
 
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
    TMPLT_VISIT_DATE    = trim(format(e.reg_dt_tm, "DD-MMM-YYYY;;Q"), 3)
with NOCOUNTER, TIME=300
 
if (error(ERR_MSG, 0) > 0)
    call LogMSG("*** THE ENCOUNTER QUERY HAS FAILED ***", 1)
    go to EXIT_PROGRAM
endif
 
if (TMPLT_ENCNTR_ID = 0.0)
    call LogMSG("*** THE ENCOUNTER ID IS ZERO ***", 1)
    go to EXIT_PROGRAM
endif
 
 
;***************************************************************************
; GET THE Health Maint Expect Series Ids
;***************************************************************************
select into 'nl:'
  from hm_expect_series hes
 where hes.expect_series_name in ('Influenza Vaccine'
                                 ,'Tdap Vaccine'
                                 ,'Breast Cancer Screening (2 yrs)'
                                 ,'Cervical Cancer Screening'
                                 )
   and hes.active_ind         =  1
detail
    case(hes.expect_series_name)
    of 'Influenza Vaccine':               HM_INFLUENZA_VACCINE      = hes.expect_series_id
    of 'Tdap Vaccine':                    HM_TDAP_VACCINE           = hes.expect_series_id
    of 'Breast Cancer Screening (2 yrs)': HM_BREAST_CANCER_SCREEN   = hes.expect_series_id
    of 'Cervical Cancer Screening':       HM_CERVICAL_CANCER_SCREEN = hes.expect_series_id
    endcase
with nocounter


call echo(build('HM_INFLUENZA_VACCINE      :',HM_INFLUENZA_VACCINE      ))
call echo(build('HM_TDAP_VACCINE           :',HM_TDAP_VACCINE           ))
call echo(build('HM_BREAST_CANCER_SCREEN   :',HM_BREAST_CANCER_SCREEN   ))
call echo(build('HM_CERVICAL_CANCER_SCREEN :',HM_CERVICAL_CANCER_SCREEN ))


set stat = initrec(TEMP) ;MAKE SAFE FOR RE-USE
 
;***************************************************************************
; GET THE HEALTH RECOMMENDATIONS FOR THIS EXECUTION
;***************************************************************************
select distinct into "nl:"
       hr.due_dt_tm
     , hra.action_dt_tm
     , hra.satisfaction_dt_tm
     , msg1 = if     (hr.status_flag = 0) "Unknown"
              elseif (hr.status_flag = 1) "Pending"
              elseif (hr.status_flag = 2) "Postponed"
              elseif (hr.status_flag = 3) "Declined"
              elseif (hr.status_flag = 4) "Expired"
              elseif (hr.status_flag = 5) "Cancelled"
              elseif (hr.status_flag = 6) "Satisfied"
              elseif (hr.status_flag = 7) "System Canceled"
              elseif (hr.status_flag = 8) "Satisfied Pending"
              endif
     , msg2 = build2(trim((if (he.expect_id != 0) he.expect_name 
                          else hr.expectation_ftdesc 
                          endif), 3), ": ",
                     trim((if     (hr.status_flag = 2) "Postponed"
                           elseif (hr.status_flag = 3) "Declined"
                           elseif (hr.status_flag = 5) "Cancelled permanently"
                           elseif (hr.status_flag = 7) "System Canceled"
                           elseif (hes.entry_type_cd = 679587.0) 
                                            build2("Satisfied by Clinical Note: ", trim(hes.expect_sat_name), " ")
                           
                           elseif (hra.satisfaction_source = "CLINICAL_EVENT")
                                            build2(trim(ce.result_val, 3), 
                                                   trim(uar_get_code_display(ce.result_units_cd)),
                                                   " - ", trim(hes.expect_sat_name, 3), ", Documented ")
                           
                           elseif (hra.satisfaction_source = "PROCEDURE")
                                            build2("Satisfied by Procedure: ", trim(hes.expect_sat_name, 3), " ")
                           
                           elseif (hra.satisfaction_source = "ORDERS")
                                            build2("Order given: ", trim(hes.expect_sat_name, 3), " ")
                           
                           elseif (hra.satisfaction_source = "HM_RECOMMENDATION_ACTION")
                                            if (not(hra.reason_cd = 0.0)) build2(trim(uar_get_code_display(hra.reason_cd), 3), " ")
                                            else "Documented "
                                            endif
                           else hra.satisfaction_source
                           endif), 3), 
                     (if    (hra.action_dt_tm = null) ""
                      elseif(cnvtint(datetimediff(EXEC_DT_TM,HRA.action_dt_tm,10))>= 2)
                                            build2(" ",trim(cnvtstring(cnvtint(datetimediff(EXEC_DT_TM,HRA.action_dt_tm,10))),3),
                                                   " years ago")
                      elseif(cnvtint(datetimediff(EXEC_DT_TM,HRA.action_dt_tm,11))>=2)
                                            build2(" ",trim(cnvtstring(cnvtint(datetimediff(EXEC_DT_TM,HRA.action_dt_tm,11))),3),
                                                   " months ago")
                      elseif(cnvtint(datetimediff(EXEC_DT_TM,HRA.action_dt_tm,2)) >=2)
                                            build2(" ",trim(cnvtstring(cnvtint(datetimediff(EXEC_DT_TM,HRA.action_dt_tm,2))),3),
                                                   " weeks ago")
                      elseif(    cnvtint(datetimediff(EXEC_DT_TM,HRA.action_dt_tm,1))>=1 
                             and cnvtint(datetimediff(EXEC_DT_TM,HRA.action_dt_tm,1))<2)
                                                   " Yesterday"
                      elseif(cnvtint(datetimediff(EXEC_DT_TM,HRA.action_dt_tm,1))>=2)
                                             build2(" ",trim(cnvtstring(cnvtint(datetimediff(EXEC_DT_TM,HRA.action_dt_tm,1))),3),
                                                   " day(s) ago")
                      else
                                             build2(" Today")
                      endif),
                      trim((if (hr.status_flag = 2 
                            OR hr.status_flag = 3
                            OR hr.status_flag = 5 
                            OR hr.due_dt_tm= NULL) ""
                            else build2(", Next Due ", trim(format(hr.due_dt_tm, "@LONGDATE"),3))
                            endif ),3))
  from hm_recommendation hr
     , hm_expect                he
     , hm_recommendation_action hra
     , hm_expect_sat            hes
     , dm_flags                 dm
     , clinical_event           ce
     , orders                   o
  plan hr 
   where hr.person_id          =  TMPLT_PERSON_ID
  join he 
   where he.expect_id          =  hr.expect_id
     and he.expect_series_id   in (HM_BREAST_CANCER_SCREEN, HM_CERVICAL_CANCER_SCREEN, HM_TDAP_VACCINE, HM_INFLUENZA_VACCINE)
  join hra 
   where hra.recommendation_id =  HR.recommendation_id
     and hra.action_dt_tm      >= cnvtlookbehind("2,D", cnvtdatetime(TMPLT_VISIT_DATE))
     and hra.action_dt_tm      <= cnvtlookahead("2,D", cnvtdatetime(TMPLT_VISIT_DATE))
     and hra.action_flag       in (2, 3 ,4, 5, 6)
  join hes 
   where hes.expect_sat_id     =  outerjoin(hra.expect_sat_id)
     and hes.active_ind        =  outerjoin(1)
  join dm 
   where dm.table_name         =  outerjoin("HM_RECOMMENDATION_ACTION")
     and dm.column_name        =  outerjoin("ACTION_FLAG")
     and dm.flag_value         =  outerjoin(hra.action_flag)
  join ce 
   where ce.event_id           =  outerjoin(hra.satisfaction_id)
     and ce.valid_until_dt_tm  =  outerjoin(cnvtdatetime("31-DEC-2100"))
     and ce.encntr_id          =  outerjoin(hra.encntr_id)
     and ce.result_status_cd   =  outerjoin(25.0)
  join o 
   where o.order_id            =  outerjoin(hra.satisfaction_id)
     and o.encntr_id           =  outerjoin(hra.encntr_id)
order by he.expect_id, format(hra.action_dt_tm, "@SHORTDATETIME") desc
HEAD REPORT
    qual_cnt = 0
    
head hr.expect_id
    qual_cnt = qual_cnt + 1
    
    if (mod(qual_cnt, 10) = 1)
        stat = alterlist(TEMP->qual, (qual_cnt + 9))
    endif
    
    TEMP->qual[qual_cnt]->recom_id      = hr.recommendation_id
    TEMP->qual[qual_cnt]->recom_name    = trim(msg2, 3)
    TEMP->qual[qual_cnt]->due_date      = format(hr.due_dt_tm, "MM/DD/YYYY;;D")
    TEMP->qual[qual_cnt]->satis_date    = format(hr.last_satisfaction_dt_tm, "MM/DD/YYYY;;D")
    TEMP->qual[qual_cnt]->due_status    = "Not Due"
    
    if (hr.due_dt_tm > cnvtlookahead("4,M"))
        TEMP->qual[qual_cnt]->due_status = "Not Due"
    elseif ((hr.due_dt_tm >= cnvtdatetime(EXEC_DT_TM)) and (hr.due_dt_tm <= cnvtlookahead("4,M")))
        TEMP->qual[qual_cnt]->due_status = "Due"
    else
        TEMP->qual[qual_cnt]->due_status = "Overdue"
    endif
    
    case (hr.status_flag)
        of 0: TEMP->qual[qual_cnt]->status = "Unknown"
        of 1: TEMP->qual[qual_cnt]->status = "Pending"
        of 2: TEMP->qual[qual_cnt]->status = "Postponed",   TEMP->qual[qual_cnt]->due_status = "Postponed"
        of 3: TEMP->qual[qual_cnt]->status = "Refused",     TEMP->qual[qual_cnt]->due_status = "Refused"
        of 4: TEMP->qual[qual_cnt]->status = "Expired",     TEMP->qual[qual_cnt]->due_status = "Expired"
        of 5: TEMP->qual[qual_cnt]->status = "Cancelled",   TEMP->qual[qual_cnt]->due_status = "Cancelled"
        of 6: TEMP->qual[qual_cnt]->status = "Satisfied"
        of 7: TEMP->qual[qual_cnt]->status = "System Canceled"
        of 8: TEMP->qual[qual_cnt]->status = "Satisfied Pending"
    endcase
    
FOOT REPORT
    TEMP->qual_cnt = qual_cnt
    stat = alterlist(TEMP->qual, TEMP->qual_cnt)
    
with nocounter, time=300
 
if (error(ERR_MSG, 0) > 0)
    call LogMSG("*** THE RECOMMENDATIONS QUERY HAS FAILED ***", 1)
    go to EXIT_PROGRAM
endif
 
if (COMP_ONLY_IND = 1)
    set REPLY->status_data->status = evaluate(TEMP->qual_cnt, 0, "Z", "S")
    go to EXIT_PROGRAM
endif
 
;***************************************************************************
; BUILD THE RTF OUTPUT FOR THE SMART TEMPLATE VERSION
;***************************************************************************
if (TEMP->qual_cnt = 0)
    set REPLY->text = concat(RHEAD, REOL, "No recommendations addressed today", RTFEOF)
    
else
    set REPLY->text = build2("\plain\f1\fs20\b\ul\cb2\pard\sl0?$@rtf@$?", "Recommendations Addressed Today", REOL)
    
    for (qual_cnt = 1 TO TEMP->qual_cnt)
        set REPLY->text = build2(REPLY->text, "\plain\f1\fs20\cb2?$@rtf@$?", TEMP->qual[qual_cnt]->recom_name, REOL)
    endfor
    
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
call echorecord(reply)
 
 
end
go