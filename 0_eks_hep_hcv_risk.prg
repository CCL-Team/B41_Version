/*************************************************************************
 Program Title: Hepatitis C HCV Risk Calculation

 Object name:   0_eks_hep_hcv_risk
 Source file:   0_eks_hep_hcv_risk.prg

 Purpose:       Using Diagnosis over the last year, computes a P value
                using some fancy coefficients from some machine learning
                thing out there somewhere.

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
drop   program 0_eks_hep_hcv_risk:dba go
create program 0_eks_hep_hcv_risk:dba


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


record data(
    1 per_id          = f8
    1 enc_id          = f8
    1 diag_id         = f8
    1 diag_cnt        = i4
    1 diag[*]
        3 cnt         = i4
        3 ident       = vc
        3 group_ident = vc
        3 coeff       = f8
    1 intercept       = f8
    1 super_string    = vc
    1 rule_comment    = vc
    1 exp_super       = f8
    1 exp             = f8
    1 denom           = f8
    1 p_value         = f8
)


/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare pos       = i4  with protect, noconstant(0)
declare coeff_pos = i4  with protect, noconstant(0)
declare idx       = i4  with protect, noconstant(0)


/*************************************************************
; DVDev Start Coding
**************************************************************/
set retval      = -1  ; initialize to failed
set log_message = "0_eks_hep_hcv_risk failed during execution"


/**********************************************************************
DESCRIPTION:  Get the Dxes
      NOTES:
***********************************************************************/
select into 'nl:'
     
  from diagnosis dx
     , nomenclature n
 
 where dx.person_id             =  trigger_personid
   and dx.nomenclature_id       >  0
   and dx.active_ind            =  1
   and dx.end_effective_dt_tm   >= cnvtdatetime(curdate, curtime3)
   and dx.diag_dt_tm            >= cnvtlookbehind('1,Y')
   
   and n.nomenclature_id        =  dx.nomenclature_id
   and n.source_vocabulary_cd   =  73005233.00  ; ICD-10-CM
   and n.active_ind             =  1
   and n.end_effective_dt_tm    >= cnvtdatetime(curdate, curtime3)
   and expand(idx, 1, coeffs->cnt, n.source_identifier, coeffs->qual[idx]->ident)

order by dx.person_id, n.source_identifier

head dx.person_id
    ;null
    call echo('-----------')
    call echo(build('dx.person_id:', dx.person_id))

head n.source_identifier
    coeff_pos = locateval(idx, 1, coeffs->cnt, n.source_identifier, coeffs->qual[idx]->ident)
    
    if(coeff_pos > 0)
        pos = locateval(idx, 1, data->diag_cnt
                           , coeffs->qual[coeff_pos]->group_ident, data->diag[idx].group_ident)
        
        if(pos > 0)
            call echo(notrim(build2('Group + 1: ', n.source_identifier)))

            data->diag[pos].cnt = data->diag[pos].cnt + 1
        else
            call echo(notrim(build2('New group:  ', coeffs->qual[coeff_pos]->group_ident, ' ', n.source_identifier)))

            pos = data->diag_cnt + 1
            data->diag_cnt = pos
            
            stat = alterlist(data->diag, pos)
        
            data->diag[pos]->cnt         = 1
            data->diag[pos]->ident       = n.source_identifier
            data->diag[pos]->group_ident = coeffs->qual[coeff_pos]->group_ident
            data->diag[pos]->coeff       = coeffs->qual[coeff_pos]->coeff
        endif
    endif
    
with nocounter, expand = 1




; Maths

;Pull our intercept out.
set data->intercept = coeffs->qual[1]->coeff

;start computing the e exponent... starting with the intercept.
set data->exp_super = data->intercept

;add each coeff
for(pos = 1 to data->diag_cnt)
    set data->exp_super = data->exp_super + data->diag[pos]->coeff

    set data->super_string = concat( data->super_string, ' ' 
                                   , cnvtstring(data->diag[pos]->coeff, 11, 4)
                                   )

    if(data->rule_comment > ' ')  set data->rule_comment = concat(data->rule_comment, '|' , data->diag[pos]->ident)
    else                          set data->rule_comment = data->diag[pos]->ident
    endif
endfor

;-1 times all that.
set data->exp_super = -1 * data->exp_super

;take the exponent.
set data->exp = exp(data->exp_super)

;Now 1 + that.
set data->denom = 1 + data->exp

;and inverse that whole thing.
set data->p_value = 1 / data->denom



;Add the score to the message we are building, might be used for reporting later
set data->rule_comment = concat('score:', trim(cnvtstring(data->p_value, 11, 6), 3), '|' , data->rule_comment)


if(data->p_value != null)
    set retval      =  100
    set log_misc1   =  data->rule_comment
    set log_message =  notrim(build2("0_eks_hep_hcv_risk computed P successfully: ", cnvtstring(data->p_value, 11, 9)))

else
    set retval      = 0
    set log_message = "0_eks_hep_hcv_risk didn't compute P successfully." 
endif




/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;debugging
call echorecord(data)

call echo(build('retval     :', retval     ))
call echo(build('log_misc1  :', log_misc1  ))
call echo(build('log_message:', log_message))

end
go


