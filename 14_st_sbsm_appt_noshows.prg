/*************************************************************************
 Program Title:   SBSM Appointment No Shows
 
 Object name:     14_st_sbsm_appt_noshows
 Source file:     14_st_sbsm_appt_noshows.prg
 
 Purpose:         Show some information about appointment no-shows during
                  current pregnancy.
 
 Tables read:
 
 Executed from:
 
 Special Notes:   
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2023-12-17 Michael Mayes        345072 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_sbsm_appt_noshows:dba go
create program 14_st_sbsm_appt_noshows:dba

%i cust_script:0_rtf_template_format.inc
 

/*record request(
   1 visit[*]
      2 encntr_id = f8
   1 person[*]
      2 person_id = f8
)*/

if(validate(reply) = 0)
    record reply(
       1 text                       = vc
          1 status_data
             2 status               = c1
             2 subeventstatus[1]
                3 OperationName     = c25
                3 OperationStatus   = c1
                3 TargetObjectName  = c25
                3 TargetObjectValue = vc
    )
endif
 


free record data
record data(
    1 per_id             = f8
    1 preg_id            = f8
    1 preg_lookback_dt   = dq8
    1 appt_cnt           = i4
    1 qual[*]
        2 sch_event_id   = f8
        2 appt_type      = vc
        2 appt_dt_tm     = dq8
        2 appt_dt_tm_txt = vc
)
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header   = vc  with protect, noconstant(' ')
declare tmp_str  = vc  with protect, noconstant(' ')

declare looper   = i4  with protect, noconstant(0)
 

/**************************************************************
; DVDev Start Coding
**************************************************************/
set data->per_id = p_id


/**********************************************************************
DESCRIPTION:  Find date range
      NOTES:  We want to find the range of the current active preg,
              and if we don't find one... just go back 10m
***********************************************************************/
select into 'nl:'
  
  from pregnancy_instance pi
 
 where pi.person_id        =  p_id
   and pi.preg_start_dt_tm >= cnvtlookbehind('10,M')
   and pi.preg_end_dt_tm   >  cnvtdatetime(curdate, curtime3)
   and pi.active_ind       =  1
   

order by pi.preg_start_dt_tm desc

head report
    data->preg_id          = pi.pregnancy_id
    data->preg_lookback_dt = pi.preg_start_dt_tm

with nocounter 


if(data->preg_lookback_dt = 0)
    set data->preg_lookback_dt = cnvtlookbehind('10,M')
endif


/***********************************************************************
DESCRIPTION: Find no show appointments within our lookback range
      NOTES:
***********************************************************************/
select into 'nl:'

  from sch_appt  sa
     , sch_event se

 where sa.person_id    =  p_id
   and sa.active_ind   =  1
   and sa.sch_appt_id  >  0
   and sa.sch_role_cd  =  4572.00 ;PATIENT
   and sa.sch_state_cd =  4543.00   ;No Show
   and sa.beg_dt_tm    >= cnvtdatetime(data->preg_lookback_dt)
   
   and se.sch_event_id =  sa.sch_event_id
   and se.active_ind   =  1

order by sa.beg_dt_tm desc

detail
    data->appt_cnt = data->appt_cnt + 1
    
    stat = alterlist(data->qual, data->appt_cnt)
    
    data->qual[data->appt_cnt]->sch_event_id   = sa.sch_event_id
    data->qual[data->appt_cnt]->appt_type      = uar_get_code_display(se.appt_type_cd)
    data->qual[data->appt_cnt]->appt_dt_tm     = sa.beg_dt_tm
    data->qual[data->appt_cnt]->appt_dt_tm_txt = trim(format(sa.beg_dt_tm, 'MM-DD-YY'), 3)
    
with nocounter

 
 
;Presentation

 
;RTF header
set header = notrim(build2(rhead))
 
if(data->appt_cnt > 0)
    set tmp_str = notrim(build2(wb, 'Number of missed appointments - ', trim(cnvtstring(data->appt_cnt), 3), wr, reol))
 
    for(looper = 1 to data->appt_cnt)
        set tmp_str = notrim(build2(tmp_str, data->qual[looper]->appt_type, ' ', data->qual[looper]->appt_dt_tm_txt, reol))
    endfor
endif
 
call include_line(build2(header, tmp_str, RTFEOF))
 
;build reply text
for (cnt = 1 to drec->line_count)
	set  reply -> text  =  concat ( reply -> text, drec -> line_qual [ cnt ]-> disp_line )
endfor
 
set drec->status_data->status = "S"
set reply->status_data->status = "S"
 
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
call echorecord(data)
call echorecord(reply)
call echorecord(drec)
 
call echo(reply->text)
 
end
go
 
