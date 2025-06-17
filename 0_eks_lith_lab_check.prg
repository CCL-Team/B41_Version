/*************************************************************************
 Program Title: Lithium Order Lab Check

 Object name:   0_eks_lith_lab_check
 Source file:   0_eks_lith_lab_check.prg

 Purpose:       When ordering/prescribing lithium, several labs need to be
                in place and within range.  There is a rule that checks 
                this and displays an alert if something is out of order.
 
 Tables read:   

 Executed from: Rules
                PHA_SYN_LITHIUM_MONITORIN
                
 Special Notes: 

******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 05/24/2022 Michael Mayes        238092 Initial release
002 10/25/2023 Michael Mayes        239410 Correction to range and change to alert.
003 05/09/2025 Michael Mayes        352954 Creat doesn't want the lower bound on the range now.
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0_eks_lith_lab_check:dba go
create program 0_eks_lith_lab_check:dba


;declare trigger_encntrid = f8 with protect,   constant(0.0)
;declare trigger_personid = f8 with protect,   constant(0.0)
;declare trigger_orderid  = f8 with protect,   constant(0.0)

/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record results(
    1 lith_pass_ind  = i2
    1 renal_pass_ind = i2
    1 tsh_pass_ind   = i2
    1 pass_fail_ind  = i2  ;Debugging for the most part
    
    1 lcv_renal      = dq8

    ;Results are mostly for debugging
    1 lith
        2 event_id   = f8
        2 result     = vc
        2 res_dt_tm  = dq8
        2 range_chk  = vc
    1 creat
        2 event_id   = f8
        2 result     = vc
        2 res_dt_tm  = dq8
        2 pass_ind   = i2
        2 range_chk  = vc
    1 crcl
        2 event_id   = f8
        2 result     = vc
        2 res_dt_tm  = dq8
        2 pass_ind   = i2
        2 range_chk  = vc
    1 gfr
        2 event_id   = f8
        2 result     = vc
        2 res_dt_tm  = dq8
        2 pass_ind   = i2
        2 range_chk  = vc
    1 tsh
        2 event_id   = f8
        2 result     = vc
        2 res_dt_tm  = dq8
        2 range_chk  = vc
)
    

/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare act_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ACTIVE'  ))
declare mod_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'MODIFIED'))
declare auth_cd        = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'AUTH'    ))
declare alt_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ALTERED' ))

declare lith_cd      = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY', 72, 'LITHIUMLVL'                    ))
declare lith_t_cd    = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY', 72, 'LITHIUMLEVELTRANSCRIBED'       ))

declare creat_cd     = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY', 72, 'CREATININE'                    ))
declare creat_lvl_cd = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY', 72, 'CREATININELVL'                 ))
declare creat_t_cd   = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY', 72, 'CREATININELEVELTRANSCRIBED'    ))

declare crcl_cd      = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY', 72, 'CREATININECLEARANCE'           ))
declare crcl2_cd     = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY', 72, 'CREATCLEARANCE'                ))
declare crcl_t_cd    = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY', 72, 'CREATININECLEARANCETRANSCRIBED'))

;They did a weird versioning thing in build here.
;declare gfr_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'GFRUNIVERSAL'                  ))
declare gfr_cd       = f8  with protect,   constant(uar_get_code_by( 'DESCRIPTION', 72, 'GFR Universal'                ))
declare gfr_cy_cd    = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY' , 72, 'GFRUNIVWITHCYSTATINC'         ))
declare egfr_cd      = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY' , 72, 'EGFR'                         ))
declare egfr_t_cd    = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY' , 72, 'EGFRTRANSCRIBED'              ))


declare tsh_cd       = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY', 72, 'TSH'                           ))
declare tsh_t_cd     = f8  with protect,   constant(uar_get_code_by( 'DISPLAYKEY', 72, 'TSHTRANSCRIBED'                ))

declare female_ind   = i2  with protect, noconstant(0)

declare lookback_6m  = dq8 with protect,   constant(cnvtlookbehind( '6,M'))
declare lookback_12m = dq8 with protect,   constant(cnvtlookbehind('12,M'))

declare value_str    = vc  with protect, noconstant('')
declare value_float  = f8  with protect, noconstant(0.0)


/*************************************************************
; DVDev Start Coding
**************************************************************/
;Debugging the constants
call echo(build('act_cd :', act_cd ))
call echo(build('mod_cd :', mod_cd ))
call echo(build('auth_cd:', auth_cd))
call echo(build('alt_cd :', alt_cd ))

call echo(build('lith_cd     :', lith_cd     ))
call echo(build('lith_t_cd   :', lith_t_cd   ))

call echo(build('creat_cd    :', creat_cd    ))
call echo(build('creat_lvl_cd:', creat_lvl_cd ))
call echo(build('creat_t_cd  :', creat_t_cd  ))

call echo(build('crcl_cd     :', crcl_cd     ))
call echo(build('crcl2_cd    :', crcl2_cd    ))
call echo(build('crcl_t_cd   :', crcl_t_cd   ))

call echo(build('gfr_cd      :', gfr_cd      ))
call echo(build('gfr_cy_cd   :', gfr_cy_cd   ))
call echo(build('egfr_cd     :', egfr_cd     ))
call echo(build('egfr_t_cd   :', egfr_t_cd   ))

call echo(build('tsh_cd      :', tsh_cd      ))
call echo(build('tsh_t_cd    :', tsh_t_cd    ))


call echo(build('lookback_6m :', format(lookback_6m , '@SHORTDATETIME')))
call echo(build('lookback_12m:', format(lookback_12m, '@SHORTDATETIME')))



set retval      = -1  ; initialize to failed
set log_message = "0_eks_lith_lab_check failed during execution"


/**********************************************************************
DESCRIPTION:  Find related lab information
      NOTES:  To keep the result set down, using the big lookback in the
              query to pull all results.  Further filtering in the detail
              section.
              
              This will only pull qualifying labs in range.
***********************************************************************/
select into 'nl:'
       ;Sort is being used to combine the logic groups so we can be dumber in the report writer section.
       sort = if    (ce.event_cd in (lith_cd , lith_t_cd                          )) 'LITH'
              elseif(ce.event_cd in (creat_cd, creat_t_cd, creat_lvl_cd           )) 'RENALCreat'
              elseif(ce.event_cd in (crcl_cd , crcl_t_cd , crcl2_cd               )) 'RENALCrCl'
              elseif(ce.event_cd in (gfr_cd  , gfr_cy_cd , egfr_cd     , egfr_t_cd)) 'RENALGFR'
              elseif(ce.event_cd in (tsh_cd  , tsh_t_cd                           )) 'TSH'
              endif
              
  from clinical_event ce
     , person         p 
 
 where ce.person_id         =  trigger_personid
   and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, alt_cd)
   and ce.valid_until_dt_tm >  cnvtdatetime(curdate, curtime3)
   and ce.event_cd          in ( lith_cd     , lith_t_cd   
                               , creat_cd    , creat_t_cd, creat_lvl_cd 
                               , crcl_cd     , crcl_t_cd , crcl2_cd     
                               , gfr_cd      , gfr_cy_cd , egfr_cd     , egfr_t_cd      
                               , tsh_cd      , tsh_t_cd
                               )
   and ce.event_end_dt_tm   >  cnvtdatetime(lookback_12m)
   and ce.event_class_cd    != 226.00  ;Group
   
   and ce.person_id         =  p.person_id
order by sort, ce.event_end_dt_tm desc
head report
    if(p.sex_cd = 362.00)  ;Female
        female_ind = 1
    endif
    
head sort
    /* Some investigation here because I don't trust the results and I want to document what I found
       so I have it here as an explanation.  I pulled three years of data for each result... to 
       find odd ones.  These will be in order of frequency.  Ignoring numerics, we expect those
            LITH    - <0.1 <0.2 <0.3 >3.0 "See Comment" "SEE COMMENT" "QNSTST" >9.0 "TNP Contamin" <0.10 "0.8 mmoll/L"
            LITH T  - All numeric
            
            CREAT   - "TNP" <0.30 "See Comment" <0.10 <0.40 <0.20 >15.00 NA "see comment" "SEE COMMENT" <0.14 "XQNSTS" "INTPRO" 
                      "QNSTST" "tnp" "NSERUM" "See comment" <0.15 "." "N/A" "INTREP" "OLDAGE" "n/a" "XLOST1" "QNS" "XNSERU" "na" 
                      "COMMENT" "NOADD5" "XLA11" "NSER" "INTEDT" (we are down to less than 8 instances now... so stopping.)
            CREAT T - All numeric
            
            CRCL    - ... none.
            CRCL T  - All numeric
            ECRCL   - All numeric.
            
            GFR     - >60 "See Comment" "see comment" "NA" "TNP" "SEE COMMENT" "tnp" "See Comment" "." "Corrected" "Not performed"
                      "Cancel" "Corrected" "N/A" <2 "x"
            
            TSH     -  <0.005 "DUPPRG" <0.008 >150.000 "See Comment" <0.01 <0.006 "REFERT" "NSERUM" "INTPRO" "QNSTST" "TNP"
                       "XNOSR1" "XLOST1" "XNSERU" we are pretty low now, I'm stopping.
            TSH T   -  <0.01 <0.015 <0.008 some weird ones down in the single instances... 
                       but basically all numeric besides what is listed first.
    
    
        Here are the values that are "good"
            LITH  - 0.6 - 1.2
            CREAT - 0.6 - 1.10
            CRCL  - 80 - 110
            GFR   - >60 I think.
            TSH   - .550 - 4.780
    */
    call echo(sort)
    case(sort)
    of 'LITH':  
        ;We need date checks... this has to be in the last 6 months.
        if(ce.event_end_dt_tm > cnvtdatetime(lookback_6m))
            ;Range checking.  Looks like we want to be .6 - 1.2.  I'm going to filter non-numerics, and strip lt gt signs because 
            ;I think stripped they are still out of range.
            
            value_str = replace(replace(ce.result_val, '<', ''), '>', '')
            
            if(isnumeric(value_str) != 0)
                value_float = cnvtreal(value_str)
                
                if(    value_float > 0.6
                   and value_float < 1.2)
                
                    results->lith_pass_ind = 1
                    results->lith->range_chk = 'Happy'
                else
                    results->lith->range_chk = 'Out of Range'
                endif
            else
                results->lith->range_chk = 'Non Numeric'
            endif
            
        endif
        
    of 'RENALCreat':  
        if(ce.event_end_dt_tm > cnvtdatetime(lookback_6m))
            if(results->lcv_renal <= ce.event_end_dt_tm) results->lcv_renal = ce.event_end_dt_tm
            endif
            
            value_str = replace(replace(ce.result_val, '<', ''), '>', '')
            
            if(isnumeric(value_str) != 0)
                value_float = cnvtreal(value_str)
                
                if(female_ind = 1)
                    call echo('got here')
                    ;003 We don't want the lowerbound on the range now.
                    ;if(    value_float > 0.5
                    ;   and value_float < 0.8)  ;002 
                    if(    value_float < 0.8) 
                    
                        results->creat->pass_ind  = 1
                        results->creat->range_chk = 'Female Happy'
                    else
                        results->creat->range_chk = 'Female Out of Range'
                    endif
                
                
                else
                    ;003 We don't want the lowerbound on the range now.
                    ;if(    value_float > 0.6
                    ;   and value_float < 1.1)
                    if(    value_float < 1.1)
                    
                        results->creat->pass_ind  = 1
                        results->creat->range_chk = 'Male/Other Happy'
                    else
                        results->creat->range_chk = 'Male/Other Out of Range'
                    endif
                endif

            else
                results->creat->range_chk = 'Non Numeric'
            endif
        endif
        
    of 'RENALCrCl':  
        if(ce.event_end_dt_tm > cnvtdatetime(lookback_6m))
            if(results->lcv_renal <= ce.event_end_dt_tm) results->lcv_renal = ce.event_end_dt_tm
            endif
            
            
            value_str = ce.result_val
            
            if(isnumeric(value_str) != 0)
                value_float = cnvtreal(value_str)
                
                if(    value_float > 80
                   and value_float < 110)
                
                    results->crcl->pass_ind = 1
                    results->crcl->range_chk = 'Happy'
                else
                    results->crcl->range_chk = 'Out of Range'
                endif
                
            else
                results->crcl->range_chk = 'Non Numeric'
            endif
        endif
        
    of 'RENALGFR':  
        ;We need date checks... this has to be in the last 6 months.
        if(ce.event_end_dt_tm > cnvtdatetime(lookback_6m))
            if(results->lcv_renal <= ce.event_end_dt_tm) results->lcv_renal = ce.event_end_dt_tm
            endif
            
            
            ;We can be quite dumb here... They never have a number above 60.  
            if(trim(ce.result_val, 3) = '>60')
                results->gfr->pass_ind = 1
                results->gfr->range_chk = 'Happy'
            else
                if(isnumeric(value_str) != 0)
                    value_str = replace(replace(ce.result_val, '<', ''), '>', '')
                    
                    value_float = cnvtreal(value_str)
                    
                    call echo(value_str)
                    call echo(value_float)
                
                    if(    value_float > 60)
                        results->gfr->pass_ind  = 1
                        results->gfr->range_chk = 'Happy'
                    else
                        results->gfr->range_chk = 'Out of Range'
                    endif
                else
                    results->gfr->range_chk = 'Non Numeric'
                endif
                
            endif
            
        endif
        
    of 'TSH':  
        ;We need DO NOT need date checks... this has to be in the last 12 months, which we do in the query.
        
        value_str = replace(replace(ce.result_val, '<', ''), '>', '')

        if(isnumeric(value_str) != 0)
            value_float = cnvtreal(value_str)
            
            if(    value_float > 0.550
               and value_float < 4.780)
            
                results->tsh_pass_ind = 1
                results->tsh->range_chk = 'Happy'
            else
                results->tsh->range_chk = 'Out of Range'
            endif
            
        else
            results->tsh->range_chk = 'Non Numeric'
        endif
        
    endcase

detail

    ;Now we are just grabbing latest values from everything... for debugging.
    ;We should already be sorted by date... so... we can just grab the first we encounter.
    case(ce.event_cd)
    of lith_cd:
    of lith_t_cd:
        if(results->lith->event_id = 0)
            ;We need date checks... this has to be in the last 6 months.
            if(ce.event_end_dt_tm > cnvtdatetime(lookback_6m))
                results->lith->event_id  = ce.event_id
                results->lith->result    = trim(ce.result_val, 3)
                results->lith->res_dt_tm = ce.event_end_dt_tm
            endif
        endif
    
    of creat_cd:
    of creat_t_cd:
    of creat_lvl_cd:
        if(results->creat->event_id = 0)
            ;We need date checks... this has to be in the last 6 months.
            if(ce.event_end_dt_tm > cnvtdatetime(lookback_6m))
                results->creat->event_id   = ce.event_id
                results->creat->result    = trim(ce.result_val, 3)
                results->creat->res_dt_tm = ce.event_end_dt_tm
            endif
        endif
        
    of crcl_cd:
    of crcl_t_cd:
    of crcl2_cd: 
        if(results->crcl->event_id = 0)
            ;We need date checks... this has to be in the last 6 months.
            if(ce.event_end_dt_tm > cnvtdatetime(lookback_6m))
                results->crcl->event_id  = ce.event_id
                results->crcl->result    = trim(ce.result_val, 3)
                results->crcl->res_dt_tm = ce.event_end_dt_tm
            endif
        endif
    
    of gfr_cd:
    of gfr_cy_cd:
    of egfr_cd:
    of egfr_t_cd:
        if(results->gfr->event_id = 0)
            ;We need date checks... this has to be in the last 6 months.
            if(ce.event_end_dt_tm > cnvtdatetime(lookback_6m))
                results->gfr->event_id  = ce.event_id
                results->gfr->result    = trim(ce.result_val, 3)
                results->gfr->res_dt_tm = ce.event_end_dt_tm
            endif
        endif
        
    of tsh_cd:
    of tsh_t_cd:
        if(results->tsh->event_id = 0)
            ;We need DO NOT need date checks... this has to be in the last 12 months, which we do in the query.
            results->tsh->event_id  = ce.event_id
            results->tsh->result    = trim(ce.result_val, 3)
            results->tsh->res_dt_tm = ce.event_end_dt_tm
        endif
    endcase

with nocounter


set results->renal_pass_ind = 1

;We want to fail if ANY of the most recent Renals are out of range
if(    results->lcv_renal = results->creat->res_dt_tm
   and results->creat->pass_ind = 0)
    set results->renal_pass_ind = 0
endif


if(    results->lcv_renal = results->crcl->res_dt_tm
   and results->crcl->pass_ind = 0)
    set results->renal_pass_ind = 0
endif


if(    results->lcv_renal = results->gfr->res_dt_tm
   and results->gfr->pass_ind = 0)
    set results->renal_pass_ind = 0
endif



;This looks like it mostly tests out... maybe.
;Lets finish this out.

if(    results->lith_pass_ind  = 1
   and results->renal_pass_ind = 1
   and results->tsh_pass_ind   = 1
  )
    set results->pass_fail_ind = 1
endif

    
if(results->pass_fail_ind = 1)
    set retval      = 0
    set log_message = "0_eks_lith_lab_check wants NO alert" 
    
else
    set retval      =  100
    set log_message =  "0_eks_lith_lab_check wants an ALERT"
endif
    


/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script
;debugging
call echorecord(results)
call echo(build('retval     :', retval     ))
call echo(build('log_message:', log_message    ))


end
go


