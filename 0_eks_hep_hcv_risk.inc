/*************************************************************************
 Program Title: Hepatitis HCV Risk Calculation

 Object name:   0_eks_hep_hcv_risk
 Source file:   0_eks_hep_hcv_risk.inc

 Purpose:       Using Diagnosis over the last year, computes a P value
                using some fancy coefficients from some machine learning
                thing out there somewhere.

 Tables read:

 Executed from: 

 Special Notes:  This should be in use in 99_hep_hcv_tst and 0_eks_hep_hcv_risk, 
                 and 0_eks_hep_hcv_pop.
                 
                 If changes here occur, please recompile all those.

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 11/21/2023 Michael Mayes        241407 Initial release (TASK4925553)
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/



/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/

record coeffs(
    1 cnt = i4
    1 qual[*]
        2 nomen_id    = f8
        2 ident       = vc
        2 group_ident = vc
        2 string      = vc
        2 coeff       = f8
)


/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare ehhr_pos     = i4  with protect, noconstant(0)



/*************************************************************
; DVDev Start Coding
**************************************************************/
; First we need our constant value in here.  They call it the intercept.
set ehhr_pos    = coeffs->cnt + 1
set coeffs->cnt = ehhr_pos
set stat        = alterlist(coeffs->qual, ehhr_pos)

set coeffs->qual[ehhr_pos]->nomen_id    = -1
set coeffs->qual[ehhr_pos]->ident       = 'Intercept'
set coeffs->qual[ehhr_pos]->group_ident = 'Intercept'
set coeffs->qual[ehhr_pos]->string      = 'Intercept'
set coeffs->qual[ehhr_pos]->coeff       = -2.3727


; Now we need to grab all the nomens.  Cross your fingers this doesn't blow up too much.
/**********************************************************************
DESCRIPTION:  Find Dx Nomens and Coefficients
       NOTE:  I imagine that eventually we'd want someway to build this out
              like we do for some code_value extensions etc.

              Right now, they told me to push ahead with hard coding.
***********************************************************************/ 
select into 'nl:'
  from nomenclature n
 where n.source_vocabulary_cd =  73005233.00  ; ICD-10-CM
   and n.active_ind           =  1
   and n.end_effective_dt_tm  >= cnvtdatetime(curdate, curtime3)
   and (   n.source_identifier = 'A53.9*'
        or n.source_identifier = 'A54.6*'
        or n.source_identifier = 'A56.3*'
        or n.source_identifier = 'A58*'
        or n.source_identifier = 'B00*'
        or n.source_identifier = 'B18.1*'
        or n.source_identifier = 'B19.1*'
        or n.source_identifier = 'B20*'
        or n.source_identifier = 'F11*'
        or n.source_identifier = 'F14*'
        or n.source_identifier = 'F19.2*'
        or n.source_identifier = 'K62.89*'
        or n.source_identifier = 'K70*'
        or n.source_identifier = 'K72*'
        or n.source_identifier = 'K74*'
        or n.source_identifier = 'K75*'
        or n.source_identifier = 'K76.0*'
        or n.source_identifier = 'L81.8*'
        or n.source_identifier = 'N18.6*'
        or n.source_identifier = 'R74.01*'
        or n.source_identifier = 'R94.5*'
        or n.source_identifier = 'W46.0*'
        or n.source_identifier = 'Z01.812*'
        or n.source_identifier = 'Z11.3*'
        or n.source_identifier = 'Z11.4*'
        or n.source_identifier = 'Z11.59*'
        or n.source_identifier = 'Z20.2*'
        or n.source_identifier = 'Z20.5*'
        or n.source_identifier = 'Z20.6*'
        or n.source_identifier = 'Z41.3*'
        or n.source_identifier = 'Z72.5*'
        or n.source_identifier = 'Z72.89*'
        or n.source_identifier = 'Z76.82*'
        or n.source_identifier = 'Z77.21*'
        or n.source_identifier = 'Z79.899*'
        or n.source_identifier = 'Z86.59*'
        or n.source_identifier = 'Z94*'
        or n.source_identifier = 'Z99.2*'
        or n.source_identifier = 'Z3*'
        or n.source_identifier = 'O*'
       )
order by n.source_identifier

detail
    ehhr_pos    = coeffs->cnt + 1
    coeffs->cnt = ehhr_pos
    stat        = alterlist(coeffs->qual, ehhr_pos)

    coeffs->qual[ehhr_pos]->nomen_id = n.nomenclature_id
    coeffs->qual[ehhr_pos]->ident    = n.source_identifier
    coeffs->qual[ehhr_pos]->string   = n.source_string

    ; Right now, they told me to push ahead with hard coding.
    ; This might be "buildified" in the future.
    case(n.source_identifier)
    of 'A53.9*'  :  coeffs->qual[ehhr_pos]->coeff       = - 0.7573
                    coeffs->qual[ehhr_pos]->group_ident = 'A53.9*'

    of 'A54.6*'  :  coeffs->qual[ehhr_pos]->coeff       = - 0.0262
                    coeffs->qual[ehhr_pos]->group_ident = 'A54.6*'
    
    of 'A56.3*'  :  coeffs->qual[ehhr_pos]->coeff       = - 0.0262
                    coeffs->qual[ehhr_pos]->group_ident = 'A56.3*'
    
    of 'A58*'    :  coeffs->qual[ehhr_pos]->coeff       = - 0.2514
                    coeffs->qual[ehhr_pos]->group_ident = 'A58*'
    
    of 'B00*'    :  coeffs->qual[ehhr_pos]->coeff       =   0.2735
                    coeffs->qual[ehhr_pos]->group_ident = 'B00*'
    
    of 'B18.1*'  :  coeffs->qual[ehhr_pos]->coeff       = - 1.0252
                    coeffs->qual[ehhr_pos]->group_ident = 'B18.1*'
    
    of 'B19.1*'  :  coeffs->qual[ehhr_pos]->coeff       = - 1.9029
                    coeffs->qual[ehhr_pos]->group_ident = 'B19.1*'
    
    of 'B20*'    :  coeffs->qual[ehhr_pos]->coeff       =   0.6975
                    coeffs->qual[ehhr_pos]->group_ident = 'B20*'
    
    of 'F11*'    :  coeffs->qual[ehhr_pos]->coeff       =   3.3357
                    coeffs->qual[ehhr_pos]->group_ident = 'F11*'
    
    of 'F14*'    :  coeffs->qual[ehhr_pos]->coeff       =   2.3092
                    coeffs->qual[ehhr_pos]->group_ident = 'F14*'
    
    of 'F19.2*'  :  coeffs->qual[ehhr_pos]->coeff       =   1.8418
                    coeffs->qual[ehhr_pos]->group_ident = 'F19.2*'
    
    of 'K62.89*' :  coeffs->qual[ehhr_pos]->coeff       =   0.6586
                    coeffs->qual[ehhr_pos]->group_ident = 'K62.89*'
    
    of 'K70*'    :  coeffs->qual[ehhr_pos]->coeff       = - 0.8919
                    coeffs->qual[ehhr_pos]->group_ident = 'K70*'
    
    of 'K72*'    :  coeffs->qual[ehhr_pos]->coeff       =   0.6269
                    coeffs->qual[ehhr_pos]->group_ident = 'K72*'
    
    of 'K74*'    :  coeffs->qual[ehhr_pos]->coeff       = -99.0000
                    coeffs->qual[ehhr_pos]->group_ident = 'K74*'
    
    of 'K75*'    :  coeffs->qual[ehhr_pos]->coeff       = -99.0000
                    coeffs->qual[ehhr_pos]->group_ident = 'K75*'
    
    of 'K76.0*'  :  coeffs->qual[ehhr_pos]->coeff       = -99.0000
                    coeffs->qual[ehhr_pos]->group_ident = 'K76.0*'
    
    of 'L81.8*'  :  coeffs->qual[ehhr_pos]->coeff       = - 0.3535
                    coeffs->qual[ehhr_pos]->group_ident = 'L81.8*'
    
    of 'N18.6*'  :  coeffs->qual[ehhr_pos]->coeff       =   2.1393
                    coeffs->qual[ehhr_pos]->group_ident = 'N18.6*'
    
    of 'R74.01*' :  coeffs->qual[ehhr_pos]->coeff       = -99.0000
                    coeffs->qual[ehhr_pos]->group_ident = 'R74.01*'
    
    of 'R94.5*'  :  coeffs->qual[ehhr_pos]->coeff       =   0.3805
                    coeffs->qual[ehhr_pos]->group_ident = 'R94.5*'
    
    of 'W46.0*'  :  coeffs->qual[ehhr_pos]->coeff       = - 0.3683
                    coeffs->qual[ehhr_pos]->group_ident = 'W46.0*'
    
    of 'Z01.812*':  coeffs->qual[ehhr_pos]->coeff       =   1.9166
                    coeffs->qual[ehhr_pos]->group_ident = 'Z01.812*'
    
    of 'Z11.3*'  :  coeffs->qual[ehhr_pos]->coeff       = - 1.6757
                    coeffs->qual[ehhr_pos]->group_ident = 'Z11.3*'
    
    of 'Z11.4*'  :  coeffs->qual[ehhr_pos]->coeff       = - 0.7103
                    coeffs->qual[ehhr_pos]->group_ident = 'Z11.4*'
    
    of 'Z11.59*' :  coeffs->qual[ehhr_pos]->coeff       = - 0.7209
                    coeffs->qual[ehhr_pos]->group_ident = 'Z11.59*'
    
    of 'Z20.2*'  :  coeffs->qual[ehhr_pos]->coeff       = - 1.1000
                    coeffs->qual[ehhr_pos]->group_ident = 'Z20.2*'
    
    of 'Z20.5*'  :  coeffs->qual[ehhr_pos]->coeff       = - 1.6606
                    coeffs->qual[ehhr_pos]->group_ident = 'Z20.5*'
    
    of 'Z20.6*'  :  coeffs->qual[ehhr_pos]->coeff       = - 0.4039
                    coeffs->qual[ehhr_pos]->group_ident = 'Z20.6*'
    
    of 'Z41.3*'  :  coeffs->qual[ehhr_pos]->coeff       = - 0.5236
                    coeffs->qual[ehhr_pos]->group_ident = 'Z41.3*'
    
    of 'Z72.5*'  :  coeffs->qual[ehhr_pos]->coeff       = - 0.2220
                    coeffs->qual[ehhr_pos]->group_ident = 'Z72.5*'
    
    of 'Z72.89*' :  coeffs->qual[ehhr_pos]->coeff       =   1.5695
                    coeffs->qual[ehhr_pos]->group_ident = 'Z72.89*'
    
    of 'Z76.82*' :  coeffs->qual[ehhr_pos]->coeff       = -99.0000
                    coeffs->qual[ehhr_pos]->group_ident = 'Z76.82*'
    
    of 'Z77.21*' :  coeffs->qual[ehhr_pos]->coeff       = - 0.0205
                    coeffs->qual[ehhr_pos]->group_ident = 'Z77.21*'
    
    of 'Z79.899*':  coeffs->qual[ehhr_pos]->coeff       = - 0.5155
                    coeffs->qual[ehhr_pos]->group_ident = 'Z79.899*'
    
    of 'Z86.59*' :  coeffs->qual[ehhr_pos]->coeff       = - 0.1171
                    coeffs->qual[ehhr_pos]->group_ident = 'Z86.59*'
    
    of 'Z94*'    :  coeffs->qual[ehhr_pos]->coeff       = -99.0000
                    coeffs->qual[ehhr_pos]->group_ident = 'Z94*'
    
    of 'Z99.2*'  :  coeffs->qual[ehhr_pos]->coeff       = - 0.5566
                    coeffs->qual[ehhr_pos]->group_ident = 'Z99.2*'
    
    of 'Z3*'     :  coeffs->qual[ehhr_pos]->coeff       = - 1.0146
                    coeffs->qual[ehhr_pos]->group_ident = 'Z3*'
    
    of 'O*'      :  coeffs->qual[ehhr_pos]->coeff       = - 0.3004
                    coeffs->qual[ehhr_pos]->group_ident = 'O*'
    endcase

with nocounter