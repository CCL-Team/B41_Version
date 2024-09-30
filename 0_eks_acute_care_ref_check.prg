/*************************************************************************
 Program Title: DCed Acute Care Order Check

 Object name:   0_eks_acute_care_ref_check
 Source file:   0_eks_acute_care_ref_check.prg

 Purpose:       
 
 Tables read:   

 Executed from: Rules
                PHY_REORDER_DISPATCH_REF
                
 Special Notes: 

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 07/26/2024 Michael Mayes        347217 Initial release (SCTASK0094554)
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0_eks_acute_care_ref_check:dba go
create program 0_eks_acute_care_ref_check:dba


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
declare found_ind = i2 with protect, noconstant(0)


/*************************************************************
; DVDev Start Coding
**************************************************************/
set retval      = -1  ; initialize to failed
set log_message = "0_eks_acute_care_ref_check failed during execution"



/**********************************************************************
DESCRIPTION:  Find canceled acute care referrals and check order comments
      NOTES:  This project wants to see if a patient had a discharge
              order placed on the pat (done in the rule) and then look
              for referrals to acute care at home (dispatch health).
              
              If one of those is canceled/discontinued with an order
              comment of "PATIENT DID NOT ANSWER THEIR PHONE".  The 
              rule has to do stuff.
              
              
              I had to do this in a script because I don't know how to 
              deal with order lists coming from templates... and patients
              can have more than one referral in this status.  Otherwise
              this would have been very easy.  I mean still is, but now
              more involved.
***********************************************************************/
select into 'nl:'
  from order_catalog oc
     , orders        o
     , order_comment cmt
     , long_text     lt
 where oc.description          =  'Referral to Acute Care at Home (DispatchHealth)'
 
   and o.encntr_id             =  trigger_encntrid
   and o.catalog_cd            =  oc.catalog_cd
   and o.order_status_cd       in ( 2545.00  ;Discontinued
                                  , 2542.00  ;Canceled
                                  )
                               
   and cmt.order_id            =  o.order_id
                               
   and lt.long_text_id         =  cmt.long_text_id

order o.orig_order_dt_tm desc, cmt.updt_dt_tm desc

head report

    if(cnvtupper(lt.long_text) =  '*PATIENT DID NOT ANSWER THEIR PHONE')
        found_ind = 1
    endif
    
with nocounter


if(found_ind = 1)
    set retval      = 100
    set log_message = "0_eks_acute_care_ref_check found can/dc referral with comment" 
    
else
    set retval      =  0
    set log_message =  "0_eks_acute_care_ref_check found NO can/dc referral with comment"
endif
    


/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;debugging
call echo(build('retval     :', retval     ))
call echo(build('log_message:', log_message    ))


end
go


