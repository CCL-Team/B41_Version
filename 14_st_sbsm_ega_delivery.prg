/*************************************************************************
 Program Title:   SBSM EGA at Delivery
 
 Object name:     14_st_sbsm_ega_delivery
 Source file:     14_st_sbsm_ega_delivery.prg
 
 Purpose:         Show a EGA at delivery if present in the current pregnancy.
 
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
  drop program 14_st_sbsm_ega_delivery:dba go
create program 14_st_sbsm_ega_delivery:dba


%i cust_script:0_rtf_template_format.inc
%i cust_script:14_obgyn_preg_common.inc


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
    1 per_id                   = f8
    1 preg_id                  = f8
    1 preg_lookback_dt         = dq8
    
    ;This part of the RS is coming from a different project (My OBGYN reports), so it is pretty static.
    ;Co-opting a bit to force it to pull data for the current patient, rather than a patient list though.
    1 cnt = i4
    1 qual[*]
        2 per_id                  = f8
        2 preg_id                 = f8
        2 ega                     = i4
        2 cur_gest_age            = i4
        2 edd                     = dq8
        2 edd_txt                 = vc
        2 delivered_ind           = i2 
        2 delivered_date          = dq8
        2 delivered_date_txt      = vc
        2 gest_age_at_delivery    = i4 
        2 est_preg_start_date     = dq8
        2 est_preg_start_date_txt = vc
        2 onset_date              = dq8
        2 onset_date_txt          = vc 
        
        2 tri_1_beg               = dq8
        2 tri_1_end               = dq8
        2 tri_2_beg               = dq8
        2 tri_2_end               = dq8
        2 tri_3_beg               = dq8
        2 tri_3_end               = dq8
)
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/

 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/

declare act_cd                 = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'  ))
declare mod_cd                 = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd                = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'    ))
declare unauth_cd              = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'UNAUTH'  ))
declare altr_cd                = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED' ))

declare standard_preg_duration = i4  with protect, noconstant(280)

declare header                 = vc  with protect, noconstant(' ')
declare tmp_str                = vc  with protect, noconstant(' ')

declare looper                 = i4  with protect, noconstant(0)
 

/**************************************************************
; DVDev Start Coding
**************************************************************/


/**********************************************************************
DESCRIPTION:  Find date range
      NOTES:  We want to find the range of the current active preg,
              and if we don't find one... just go back 10m
***********************************************************************/
select into 'nl:'
  
  from pregnancy_instance pi
 
 where pi.person_id        =  p_id
   and pi.preg_end_dt_tm   <  cnvtdatetime(curdate, curtime3)
   and pi.active_ind       =  1
   
order by pi.preg_end_dt_tm

detail
    data->cnt = data->cnt + 1
    stat = alterlist(data->qual, data->cnt)
    
    data->qual[data->cnt]->preg_id = pi.pregnancy_id
    data->qual[data->cnt]->per_id  = p_id
    
with nocounter 


; Get ega data
call get_pat_preg_data(data)


;Presentation

 
;RTF header
set header = notrim(build2(rhead))


for(looper = 1 to data->cnt)
    if(data->qual[looper]->delivered_ind = 1
      )
        
        if(data->qual[looper]->gest_age_at_delivery > 0)
        
            if(tmp_str = ' ')
                set tmp_str = notrim(build2( wb
                                           , 'Delivery (', data->qual[looper]->delivered_date_txt, ')'
                                           , ' - EGA: '
                                           , wr, get_week_str_ega(data->qual[looper]->gest_age_at_delivery), reol)
                                    )
            else
                set tmp_str = notrim(build2( tmp_str
                                           , wb
                                           , 'Delivery (', data->qual[looper]->delivered_date_txt, ')'
                                           , ' - EGA: '
                                           , wr, get_week_str_ega(data->qual[looper]->gest_age_at_delivery), reol)
                                    )
                
            endif
        else
        
            if(tmp_str = ' ')
                set tmp_str = notrim(build2( wb
                                           , 'Delivery (', data->qual[looper]->delivered_date_txt, ')'
                                           , ' - EGA: '
                                           , wr, 'Unknown', reol)
                                    )
            else
                set tmp_str = notrim(build2( tmp_str
                                           , wb
                                           , 'Delivery (', data->qual[looper]->delivered_date_txt, ')'
                                           , ' - EGA: '
                                           , wr, 'Unknown', reol)
                                    )
                
            endif
        
        endif
        
    endif
    
    
    
endfor

 
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



#exit_script

call echorecord(data)
call echorecord(reply)
call echorecord(drec)
 
call echo(reply->text)

end
go
 