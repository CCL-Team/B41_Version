/*************************************************************************
 Program Title: Smart Zone Bone Health Order Check

 Object name:   0_eks_sz_bone_health_ords
 Source file:   0_eks_sz_bone_health_ords.prg

 Purpose:       Disqualify rule if specific order found within one year,
                or a specific order set was _EVER_ on the patient.
 
 Tables read:   

 Executed from: Rules
                PHY_SZ_BONE_HEALTH
 
 Special Notes: 

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 01/10/2024 Michael Mayes        241435 Initial release (SCTASK0063439)
002 05/07/2024 Michael Mayes        347444 Moving the DX check inside the cust script.  (This ended up reverted during validation)
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0_eks_sz_bone_health_ords:dba go
create program 0_eks_sz_bone_health_ords:dba


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
declare order_ind     = i2  with protect, noconstant(0)
declare order_set_ind = i2  with protect, noconstant(0)

/*************************************************************
; DVDev Start Coding
**************************************************************/
set retval      = -1  ; initialize to failed
set log_message = "0_eks_sz_bone_health_ords failed during execution"
set log_misc1   = "0_eks_sz_bone_health_ords failed during execution"


/**********************************************************************
DESCRIPTION:  Check for Bone Health Referral in the last year
***********************************************************************/
select into 'nl:'
  from order_catalog       oc
     , orders              o
 where oc.description          = 'Referral to MedStar Bone Health and Fracture Prevention Program'
   and oc.active_ind           =  1
   
   and o.person_id             =  trigger_personid
   and o.catalog_cd            =  oc.catalog_cd
   and o.order_status_cd       in (2550.000000, 2543.000000)  /*ordered, completed*/
   and o.orig_order_dt_tm      >= cnvtlookbehind('1,Y')
   and o.active_ind            =  1

detail
    ; Just having an order, on an encounter in the last year... is going to exclude here... but setting the ind for now
    ; for code clarity.
    
    order_ind = 1
    call echo(build('ENC:', o.encntr_id))
    call echo(build('ORD:', o.order_id))
with nocounter


/**********************************************************************
DESCRIPTION:  Check for Bone Health Referral in the last year
***********************************************************************/
select into 'nl:'
  from pathway_catalog     pwc
     , pathway             p
     
 where pwc.description         = 'AMB Bone Health/Fracture Prevention Program'
   and pwc.active_ind          =  1
   and pwc.END_EFFECTIVE_DT_TM >= cnvtdatetime(curdate, curtime3)
   
   and p.person_id             =  trigger_personid
   and p.pathway_catalog_id    =  pwc.pathway_catalog_id
   and p.active_ind            =  1
   and p.pw_status_cd   not in (  590785281.00 ;  Held                
                               ,  590785291.00 ;  Skipped             
                               ,     674354.00 ;  Void                
                               ,   56570478.00 ;  Initiated           
                               , 1327555467.00 ;  Future ? Proposed   
                               , 1327555487.00 ;  Planned ? Proposed  
                               , 1327555477.00 ;  Initiated ? Proposed
                               ,    3606219.00 ;  Dropped             
                               ,   56570466.00 ;  Excluded            
                               )

detail
    ; Just having an order set is going to exclude here... but setting the ind for now
    ; for code clarity.
    
    order_set_ind = 1
    
with nocounter


;002-> reworking the logging, because it made no sense.
;Defaulting success at this point.
set retval      = 100  
set log_misc1   = "Pass"
set log_message = notrim("Checks: ")


if(order_ind = 1)
    set retval      = 0  ; Failed due to order
    set log_message = notrim(build2(log_message, "O:F"))
    set log_misc1   = "Fail"
else
    set log_message = notrim(build2(log_message, "O:S"))
endif


if(order_set_ind = 1)
    set retval      = 0  ; Failed due to order
    set log_message = notrim(build2(log_message, "; OS:F"))
    set log_misc1   = "Fail"
else
    set log_message = notrim(build2(log_message, "; OS:S"))
endif

;002<-




/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;debugging
call echo(build('retval     :', retval     ))
call echo(build('log_message:', log_message))
call echo(build('log_misc1  :', log_misc1  ))


end
go


