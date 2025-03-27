/*************************************************************************
 Program Title: ED Bariatric OS Procedure check

 Object name:   0_eks_bari_proc_check
 Source file:   0_eks_bari_proc_check.prg

 Purpose:       Identify the most recent Bariatric Procedure for a couple 
                of Bariatric rules.
 
 Tables read:   

 Executed from: Rules
                CUST_BARI_OS_RESULT
                CUST_BARI_OS_SZ_NOTIFY
                CUST_ED_BARI_OS_PROC_DAYS
                
 Special Notes: 

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 12/11/2024 Michael Mayes        347124 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0_eks_bari_proc_check:dba go
create program 0_eks_bari_proc_check:dba


;declare trigger_encntrid = f8 with protect,   constant(0.0)
;declare trigger_personid = f8 with protect,   constant(0.0)
;declare trigger_orderid  = f8 with protect,   constant(0.0)
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
declare bari_found_ind = i2  with protect, noconstant(0)
declare bari_30d_ind   = i2  with protect, noconstant(0)
declare bari_30d_dt_tm = dq8 with protect, noconstant(0)

/*************************************************************
; DVDev Start Coding
**************************************************************/
set retval      = -1  ; initialize to failed
set log_message = "0_eks_bari_proc_check failed during execution"



/**********************************************************************
DESCRIPTION:  Find last Bariatric Procedure... for our date check.
      NOTES:  
***********************************************************************/
; Temp or Permanently removing this.  If SN is the scheduler... it comes in with no CPT code on it... but I found a happy
; table to fix this for me.
;select into 'nl:'
;  
;  from surgical_case       sc
;     , surg_case_procedure scp
;     , orders              o
;     , order_detail        od
;  
; where sc.person_id         =  trigger_personid
;   and sc.cancel_dt_tm      =  null
;   and sc.checkin_dt_tm     != null
;   and sc.surg_start_dt_tm  != null
;   and sc.surg_stop_dt_tm   != null
;   and sc.active_ind        =  1
;
;   and scp.surg_case_id = sc.surg_case_id
;   and scp.active_ind = 1
;   and scp.surg_proc_cd  >  0
;
;   and o.order_id = scp.order_id
;
;   and od.order_id        = o.order_id
;   and od.oe_field_id     = 683615.0;3644439611.00 
;   and od.action_sequence = (select max(od2.action_sequence)
;                               from order_detail od2
;                              where od2.order_id     = od.order_id
;                               and  od2.oe_field_id = 683615.0;3644439611.00
;                            )
;   and (   od.oe_field_display_value = '*43775*'
;        or od.oe_field_display_value = '*43644*'
;        or od.oe_field_display_value = '*43645*'
;        or od.oe_field_display_value = '*43659*'
;        or od.oe_field_display_value = '*43846*'
;        or od.oe_field_display_value = '*43847*'
;        or od.oe_field_display_value = '*43633*'
;        or od.oe_field_display_value = '*43843*'
;        or od.oe_field_display_value = '*43842*'
;        or od.oe_field_display_value = '*43770*'
;        or od.oe_field_display_value = '*43771*'
;        or od.oe_field_display_value = '*43772*'
;        or od.oe_field_display_value = '*43773*'
;        or od.oe_field_display_value = '*43774*'
;        or od.oe_field_display_value = '*43886*'
;        or od.oe_field_display_value = '*43887*'
;        or od.oe_field_display_value = '*43888*'
;       )
;
;order by sc.person_id, sc.surg_start_dt_tm desc
;
;head sc.person_id
;    bari_found_ind = 1
;
;    if(sc.surg_start_dt_tm > cnvtlookbehind('30,D')) bari_30d_ind = 1
;    else                                             bari_30d_ind = 0
;    endif
;    
;    bari_30d_dt_tm = sc.surg_start_dt_tm
;    
;with nocounter

select into 'nl:'
  
  from surgical_case       sc
     , surg_case_procedure scp
     , sn_proc_cpt_r       spcr
     , nomenclature        n
  
 where sc.person_id         =  trigger_personid
   and sc.cancel_dt_tm      =  null
   and sc.checkin_dt_tm     != null
   and sc.surg_start_dt_tm  != null
   and sc.surg_stop_dt_tm   != null
   and sc.active_ind        =  1

   and scp.surg_case_id = sc.surg_case_id
   and scp.active_ind   = 1
   and scp.surg_proc_cd > 0

   and spcr.procedure_cd = scp.surg_proc_cd
   
   and n.nomenclature_id = spcr.nomenclature_id
   and (   n.source_identifier = '43775'
        or n.source_identifier = '43644'
        or n.source_identifier = '43645'
        or n.source_identifier = '43659'
        or n.source_identifier = '43846'
        or n.source_identifier = '43847'
        or n.source_identifier = '43633'
        or n.source_identifier = '43843'
        or n.source_identifier = '43842'
        or n.source_identifier = '43770'
        or n.source_identifier = '43771'
        or n.source_identifier = '43772'
        or n.source_identifier = '43773'
        or n.source_identifier = '43774'
        or n.source_identifier = '43886'
        or n.source_identifier = '43887'
        or n.source_identifier = '43888'
       )

order by sc.person_id, sc.surg_start_dt_tm desc

head sc.person_id
    bari_found_ind = 1

    if(sc.surg_start_dt_tm > cnvtlookbehind('30,D')) bari_30d_ind = 1
    else                                             bari_30d_ind = 0
    endif
    
    bari_30d_dt_tm = sc.surg_start_dt_tm
    
with nocounter


;Debugging here eventually.
;set bari_found_ind = 1
;set bari_30d_ind = 1


; Build out a datamessage for the rules
set log_misc1 = notrim(build2(     'PROCFOUND', '|', cnvtstring(bari_found_ind, 1, 0)
                             ,'|', 'PROC<30D' , '|', cnvtstring(bari_30d_ind  , 1, 0)
                             ,'|', 'PROCDATE' , '|', trim(format(bari_30d_dt_tm, '@SHORTDATETIME'), 3)
                             )
                      )

    
if(bari_found_ind = 1)
    set retval      =  100
    set log_message =  "0_eks_bari_proc_check found Bariatric Procedure"
    
else
    set retval      = 0
    set log_message = "0_eks_bari_proc_check found no Bariatric Procedure" 
    
endif
    


/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;debugging
call echo(build('retval     :', retval         ))
call echo(build('log_message:', log_message    ))
call echo(build('log_misc1  :', log_misc1      ))


end
go


