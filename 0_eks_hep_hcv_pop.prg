/*************************************************************************
 Program Title: Hepatitis C HCV Risk Population
 
 Object name:   0_eks_hep_hcv_pop
 Source file:   0_eks_hep_hcv_pop.prg

 Purpose:       Using Diagnosis determine if diagnosis is in our list of
                coeffs to consider for further processing.

 Tables read:
 
 Executed from: Rules (PC_HEP_HCV_RISK)


 Special Notes:

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 11/21/2023 Michael Mayes        241407 Initial release (TASK4925553)
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0_eks_hep_hcv_pop:dba go
create program 0_eks_hep_hcv_pop:dba


;declare trigger_encntrid = f8 with protect,   constant(0.0)
;declare trigger_personid = f8 with protect,   constant(0.0)
;declare trigger_orderid  = f8 with protect,   constant(0.0)

/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/

;  This should load up our coeffs RS with our values.  We use this later.
/*
record coeffs(
    1 cnt = i4
    1 qual[*]
        2 nomen_id    = f8
        2 ident       = vc
        2 group_ident = vc
        2 string      = vc
        2 coeff       = f8
)
*/
%i cust_script:0_eks_hep_hcv_risk.inc


/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare pos       = i4  with protect, noconstant(0)
declare coeff_pos = i4  with protect, noconstant(0)
declare idx       = i4  with protect, noconstant(0)
declare msg       = vc  with protect, noconstant('')

declare looper    = i4  with protect, noconstant(0)


/*************************************************************
; DVDev Start Coding
**************************************************************/
set retval      = -1  ; initialize to failed
set log_message = "0_eks_hep_hcv_pop failed during execution"




/**********************************************************************
DESCRIPTION:  Get the Dxes
      NOTES:  We just want to see if we've ever had a dx with the 
              nomens, in the last year.  We don't even care if they are
              active or not.
              
              And actually we don't even want to do the year lookback... 
              because things will fall off.
***********************************************************************/
select into 'nl:'
     
  from diagnosis dx
     , nomenclature n
 
 where dx.person_id             =  trigger_personid
   and dx.nomenclature_id       >  0
   ;and dx.diag_dt_tm            >= cnvtlookbehind('1,Y')
   
   and n.nomenclature_id        =  dx.nomenclature_id
   and n.source_vocabulary_cd   =  73005233.00  ; ICD-10-CM
   and n.active_ind             =  1
   and n.end_effective_dt_tm    >= cnvtdatetime(curdate, curtime3)
   and expand(idx, 1, coeffs->cnt, n.source_identifier, coeffs->qual[idx]->ident)

order by dx.person_id, n.source_identifier

head dx.person_id
    null
    
head n.source_identifier
    pos = locateval(idx, 1, coeffs->cnt, n.source_identifier, coeffs->qual[idx]->ident)
    
    if(pos > 0)
        coeff_pos = pos
        
        if(msg = '') msg = cnvtstring(coeffs->qual[coeff_pos]->nomen_id)
        else         msg = notrim(build2(msg, ',', trim(cnvtstring(coeffs->qual[coeff_pos]->nomen_id))))
        endif
    endif
    
with nocounter, expand = 1


if(coeff_pos > 0)
    set retval      = 100
    set log_misc1   = msg
    set log_message = notrim(build2("0_eks_hep_hcv_pop found DX: ", msg))
    
else
    set retval      = 0
    set log_misc1   = msg
    set log_message = notrim(build2("0_eks_hep_hcv_pop didn't find DX: ", msg))

endif



/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;debugging

call echo(build('retval     :', retval     ))
call echo(build('log_misc1  :', log_misc1  ))
call echo(build('log_message:', log_message))

end
go


