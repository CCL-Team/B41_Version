/*************************************************************************
 Program Title: Hepatitis C HCV Risk Testing script.

 Object name:   99_hep_hcv_tst
 Source file:   99_hep_hcv_tst.prg

 Purpose:       Created this to test the maths involved in this rule against
                multiple patients.
                
                Should identify and calculate and report on the various
                things that go into computing the risk probability score.

 Tables read:

 Executed from:

 Special Notes:



******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 11/22/2023 Michael Mayes        220793 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 99_hep_hcv_tst:dba go
create program 99_hep_hcv_tst:dba



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
    1 cnt = i4
    1 qual[*]
        2 per_id          = f8
        2 enc_id          = f8
        2 diag_id         = f8
        2 diag_cnt        = i4
        2 diag[*]
            3 cnt         = i4
            3 ident       = vc
            3 group_ident = vc
            3 coeff       = f8
        2 intercept       = f8
        2 super_string    = vc
        2 exp_super       = f8
        2 exp             = f8
        2 denom           = f8
        2 p_value         = f8
)

/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare pos       = i4  with protect, noconstant(0)
declare coeff_pos = i4  with protect, noconstant(0)
declare idx       = i4  with protect, noconstant(0)
declare looper    = i4  with protect, noconstant(0)


/*************************************************************
; DVDev Start Coding
**************************************************************/


/**********************************************************************
DESCRIPTION:  Find us some test patients
      NOTES:  RIght now this is pointed at dxes on the encounter... not
              dxes across the year.  I don't think this matters because
              we are just testing here.
***********************************************************************/
select into 'nl:'
  from encounter e
     , diagnosis d
 where e.reg_dt_tm           >  sysdate - 1
   and d.encntr_id           =  e.encntr_id
   and d.active_ind          =  1
   and d.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
   and d.diag_dt_tm          >= cnvtlookbehind('1,Y')
   and exists (select 'x'
                 from nomenclature n
                where n.nomenclature_id      =  d.nomenclature_id
                  and n.source_vocabulary_cd =  73005233.00  ; ICD-10-CM
                  and n.active_ind           =  1
                  and n.end_effective_dt_tm  >= cnvtdatetime(curdate, curtime3)
                  and expand(idx, 1, coeffs->cnt, n.source_identifier, coeffs->qual[idx]->ident)
              )
order by e.person_id
head e.person_id
    data->cnt = data->cnt + 1

    stat = alterlist(data->qual, data->cnt)

    data->qual[data->cnt]->per_id  = e.person_id
    data->qual[data->cnt]->enc_id  = e.encntr_id
    data->qual[data->cnt]->diag_id = d.diagnosis_id

with nocounter, expand=1


;Just kidding... I don't want that many:
set data->cnt = 20
set stat = alterlist(data->qual, data->cnt)


/**********************************************************************
DESCRIPTION:  Get the Dxes
      NOTES:
***********************************************************************/
for(looper = 1 to data->cnt)
    select into 'nl:'
     
      from diagnosis dx
         , nomenclature n
     
     where dx.person_id             =  data->qual[looper]->per_id
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
            pos = locateval(idx, 1, data->qual[looper]->diag_cnt
                               , coeffs->qual[coeff_pos]->group_ident, data->qual[looper]->diag[idx].group_ident)
            
            if(pos > 0)
                call echo(notrim(build2('Group + 1: ', n.source_identifier)))

                data->qual[looper]->diag[pos].cnt = data->qual[looper]->diag[pos].cnt + 1
            else
                call echo(notrim(build2('New group:  ', coeffs->qual[coeff_pos]->group_ident, ' ', n.source_identifier)))

                pos = data->qual[looper]->diag_cnt + 1
                data->qual[looper]->diag_cnt = pos
                
                stat = alterlist(data->qual[looper]->diag, pos)
            
                data->qual[looper]->diag[pos]->cnt         = 1
                data->qual[looper]->diag[pos]->ident       = n.source_identifier
                data->qual[looper]->diag[pos]->group_ident = coeffs->qual[coeff_pos]->group_ident
                data->qual[looper]->diag[pos]->coeff       = coeffs->qual[coeff_pos]->coeff
            endif
        endif
        
    with nocounter, expand = 1
endfor

/*
    Turning this equation into a comment is going to suck.
    What we are trying to compute here is this:
    
                                                  1
                        P =   --------------------------------------------
                                    - (Intecept + Coeff1 + Coeff2 + [...])
                              1 + e^
    
    Only if the dxes tied to the coeffs are on the patient in the last year.  
    
    Each Dx has a coeff as defined in the RS.
    
    If we have multiple in a group... we count the group once.
    

*/
for(looper = 1 to data->cnt)
    ;Pull our intercept out.
    set data->qual[looper]->intercept = coeffs->qual[1]->coeff
    
    ;start computing the e exponent... starting with the intercept.
    set data->qual[looper]->exp_super = data->qual[looper]->intercept

    ;add each coeff
    for(pos = 1 to data->qual[looper]->diag_cnt)
        set data->qual[looper]->exp_super = data->qual[looper]->exp_super + data->qual[looper]->diag[pos]->coeff
    
        set data->qual[looper]->super_string = concat( data->qual[looper]->super_string, ' ' 
                                                  , cnvtstring(data->qual[looper]->diag[pos]->coeff, 11, 4)
                                                  )
    endfor
    
    ;-1 times all that.
    set data->qual[looper]->exp_super = -1 * data->qual[looper]->exp_super

    ;take the exponent.
    set data->qual[looper]->exp = exp(data->qual[looper]->exp_super)

    ;Now 1 + that.
    set data->qual[looper]->denom = 1 + data->qual[looper]->exp

    ;and inverse that whole thing.
    set data->qual[looper]->p_value = 1 / data->qual[looper]->denom

endfor





;Presentation time
if (data->cnt > 0)

    select into 'MINE'
           P_ID    =                         data->qual[d.seq].per_id    
         , E_ID    =                         data->qual[d.seq].enc_id    
         , INT     =                         data->qual[d.seq].intercept 
         , SUPER   = trim(substring(1,   50, data->qual[d.seq].super_string ))
         , SUP_TOT =                         data->qual[d.seq].exp_super
         , EXP     =                         data->qual[d.seq].exp      
         , DENOM   =                         data->qual[d.seq].denom    
         , P       =                         data->qual[d.seq].p_value

      from (dummyt d with SEQ = data->cnt)
    with format, separator = " ", time = 300

endif



/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;DEBUGGING
call echorecord(data)
;call echorecord(coeffs)

end
go

