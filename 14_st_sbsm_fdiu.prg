/*************************************************************************
 Program Title:   SBSM Fetal Death In Utero
 
 Object name:     14_st_sbsm_fdiu
 Source file:     14_st_sbsm_fdiu.prg
 
 Purpose:         Show a FDIU information for the current patient.
 
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
  drop program 14_st_sbsm_fdiu:dba go
create program 14_st_sbsm_fdiu:dba

%i cust_script:0_rtf_template_format.inc
 

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
    1 per_id       = f8
                   
    1 preg_cnt     = i4
    1 qual[*]      
        2 preg_id  = f8
        2 ega      = i4
        2 ega_nice = vc
        2 date     = dq8
        2 date_txt = vc    
)
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare get_week_str_ega(ega = i4) = vc

 
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
set data->per_id = p_id




/**********************************************************************
DESCRIPTION:  Get historical delivered pregnancies with less than 24 
              weeks ega
***********************************************************************/
select into 'nl:'

  from pregnancy_instance pi
     , pregnancy_estimate pe
     , pregnancy_child    pc
  
 where pi.person_id           =  p_id
   and pi.preg_end_dt_tm      <= cnvtdatetime(curdate, curtime3)
   and pi.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)

   and pe.pregnancy_id        =  outerjoin(pi.pregnancy_id)
   and pe.entered_dt_tm       != outerjoin(null)
   and pe.active_ind          =  outerjoin(1)
   
   and pc.pregnancy_id        =  pi.pregnancy_id
   and pc.active_ind          =  1

order by pc.delivery_dt_tm, pi.pregnancy_id, pe.status_flag desc
  
head pi.pregnancy_id
    
    if(pc.neonate_outcome_cd = 56659704.00)  ;Fetal Death
        data->preg_cnt = data->preg_cnt + 1
                
        stat = alterlist(data->qual, data->preg_cnt)
        
        
        data->qual[data->preg_cnt]->preg_id  = pi.pregnancy_id
        
        data->qual[data->preg_cnt]->date     = pc.delivery_dt_tm
        
        case(pc.delivery_date_precision_flag)
        of 1: data->qual[data->preg_cnt]->date_txt = format(pc.delivery_dt_tm, 'MM-YYYY')
        of 2: data->qual[data->preg_cnt]->date_txt = format(pc.delivery_dt_tm, 'YYYY')
                                                   
        of 0:                                      
        of 3:                                      
            data->qual[data->preg_cnt]->date_txt   = format(pc.delivery_dt_tm, '@SHORTDATE')
        
        endcase
        
        
        if(pe.pregnancy_estimate_id = null)

            if(pc.gestation_age > 0)
                data->qual[data->preg_cnt]->ega      = pc.gestation_age
                data->qual[data->preg_cnt]->ega_nice = get_week_str_ega(pc.gestation_age)
            else
                data->qual[data->preg_cnt]->ega      = 0
                data->qual[data->preg_cnt]->ega_nice = 'Unknown'
            endif
        
        elseif(pe.est_gest_age_days < 168)  ;24 wks * 7 days

            data->qual[data->preg_cnt]->ega      = pe.est_gest_age_days
            data->qual[data->preg_cnt]->ega_nice = get_week_str_ega(pe.est_gest_age_days)
            
        endif
    endif
    
    
with nocounter



;Presentation

 
;RTF header
set header = notrim(build2(rhead))
 
if(data->preg_cnt > 0)
    set tmp_str = notrim(build2(wb, 'Fetal Death < 24wks EGA - ', wr, trim(cnvtstring(data->preg_cnt), 3), reol))

    for(looper = 1 to data->preg_cnt)
        set tmp_str = notrim(build2(tmp_str, 'Fetal Death: ', data->qual[looper]->date_txt
                                           , ' (EGA: '      , data->qual[looper]->ega_nice, ')', reol
                                   )
                            )
    endfor

endif


 
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


/* get_week_str_ega
   Change a integer ega days count, into a "x weeks, y day" string

   Input:
        ega (i4): Integer representing an EGA in days
   
   Output:
        ega_string (vc): String with weeks and days
  
*/
subroutine get_week_str_ega(ega)
    if    ( ega        <= 0) return("0 Days")
    elseif( ega        <= 7) return(build2(trim(cnvtstring(ega)), " Days"))
    elseif(mod(ega, 7) =  0) return(build2(trim(cnvtstring(ega / 7)), " Weeks"))
    else
        return(build2( trim(cnvtstring((ega / 7)))
                     , " Weeks, "
                     , trim(cnvtstring(mod(ega, 7)))
                     , " Days"
                     )
               
              )
    endif
end




#exit_script

call echorecord(data)
call echorecord(reply)
call echorecord(drec)
 
call echo(reply->text)

end
go
 