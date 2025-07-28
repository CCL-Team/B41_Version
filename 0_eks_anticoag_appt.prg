/*************************************************************************
 Program Title: Future Anticoag Appt

 Object name:   0_eks_anticoag_appt
 Source file:   0_eks_anticoag_appt.prg

 Purpose:       
 
 Tables read:   

 Executed from: Rules
                CN_DIS_DOAC_REFERRAL
                *scratch that*
                pp_discharge_warfarin
                pp_discharge_doac
                
                Dawn took over the project and made her own rules.
 
 Special Notes: 

******************************************************************************************************************
                  MODIFICATION CONTROL LOG                           
******************************************************************************************************************
Mod Date       Analyst              MCGA   Comment                   
--- ---------- -------------------- ------ -----------------------------------------------------------------------
001 03/10/2022 Michael Mayes        231859 Initial release (TASK5127445)
002 03/04/2025 Michael Mayes        351313 Change to find previous encounters as well (SCTASK0137581)
*************END OF ALL MODCONTROL BLOCKS* ***********************************************************************/
drop   program 0_eks_anticoag_appt:dba go
create program 0_eks_anticoag_appt:dba


;declare trigger_encntrid = f8 with protect,   constant(0.0)
;declare trigger_personid = f8 with protect,   constant(0.0)
;declare trigger_orderid  = f8 with protect,   constant(0.0)

/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/



/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare fut_found_ind  = i2 with protect, noconstant(0)   ;002 renaming to make clear
declare past_found_ind = i2 with protect, noconstant(0)   ;002
declare temp_log       = vc with protect, noconstant(' ')  ;002


/*************************************************************
; DVDev Start Coding
**************************************************************/
set retval      = -1  ; initialize to failed
set log_message = "0_eks_anticoag_appt failed during execution"



/**********************************************************************
DESCRIPTION:  Find Anticoag Appt if it exists
***********************************************************************/
select into 'nl:'
  from sch_appt sa
 where sa.person_id        =  trigger_personid
   and sa.encntr_id        != trigger_encntrid  ;Not sure if I need this... but it might help and wont hurt
   and sa.appt_location_cd in (select cv.code_value
                                 from code_value cv
                                where cv.code_set    = 220  ; Location
                                  and cv.display_key = '*ANTICOAG*'
                                  and cv.cdf_meaning = 'AMBULATORY'
                              ) 
   and sa.beg_dt_tm        >  cnvtdatetime(curdate, curtime3)   ;In the future.
   and sa.state_meaning    != 'CANCELED'
   and sa.role_meaning     =  'PATIENT' 
   and sa.schedule_seq     =  ( select max(sa2.schedule_seq)
                                  from sch_appt sa2
                                 where sa2.sch_event_id = sa.sch_event_id
                              )
detail
    fut_found_ind = 1  ;002 renaming to make clear
with nocounter


;002->
/**********************************************************************
DESCRIPTION:  Find Previous Anticoag Appt

      NOTES:  The logic they have for this is a bit different.
              They want me to go back and look for previous appts with
              with specific encounter types.  Not sure if that is 
              much different than above... but going that route.
***********************************************************************/
select into 'nl:'
  
  from sch_appt  sa
     , sch_event se
 
 where sa.person_id        =  trigger_personid
   and sa.encntr_id        != trigger_encntrid  ;Not sure if I need this... but it might help and wont hurt
   and sa.beg_dt_tm        <  cnvtdatetime(curdate, curtime3)   ;In the past.
   and sa.state_meaning    != 'CANCELED'
   and sa.role_meaning     =  'PATIENT' 
   and sa.schedule_seq     =  ( select max(sa2.schedule_seq)
                                  from sch_appt sa2
                                 where sa2.sch_event_id = sa.sch_event_id
                              )
   
   and se.sch_event_id     = sa.sch_event_id
   and se.appt_type_cd     in ( 4555684447.00  ; DOAC NEW APPT                 
                              , 4555690505.00  ; DOAC RETURN APPT              
                              )
detail
    past_found_ind = 1
with nocounter


;002 Changing this to better tell the log what is going on down here.
if(fut_found_ind  = 1) set temp_log = '0_eks_anticoag_appt found a future DOAC appointment'
endif

if(past_found_ind = 1)
    if(temp_log = ' ') set temp_log = '0_eks_anticoag_appt found a past DOAC appointment'
    else               set temp_log = notrim(build2( temp_log, '; '
                                                   , '0_eks_anticoag_appt found a past DOAC appointment'
                                                   )
                                            )
    endif
endif

if(temp_log = ' ')
    
    set retval      = 0
    set log_message = "0_eks_anticoag_appt found no appt"
    
else

    set retval      = 100
    set log_message = temp_log

endif 
;002<-




    


/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;debugging
call echo(build('retval     :', retval     ))
call echo(build('log_message:', log_message    ))


end
go


