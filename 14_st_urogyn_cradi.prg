/*************************************************************************
 Program Title:   Uro Gyn CRADI8 Symptoms
 
 Object name:     14_st_urogyn_cradi
 Source file:     14_st_urogyn_cradi.prg
 
 Purpose:
 
 Tables read:
 
 Executed from:
 
 Special Notes:   
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2024-01-29 Michael Mayes        240271 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_urogyn_cradi:dba go
create program 14_st_urogyn_cradi:dba

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
    1 low_cnt = i4
    1 low[*]
        2 title_txt = vc
    1 high_cnt = i4
    1 high[*]
        2 title_txt = vc
)


 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header   = vc  with protect, noconstant(' ')
declare tmp_str  = vc  with protect, noconstant(' ')
                 
declare act_cd   = f8  with protect, constant(uar_get_code_by(   'MEANING',  8, 'ACTIVE'                      ))
declare mod_cd   = f8  with protect, constant(uar_get_code_by(   'MEANING',  8, 'MODIFIED'                    ))
declare auth_cd  = f8  with protect, constant(uar_get_code_by(   'MEANING',  8, 'AUTH'                        ))
declare alt_cd   = f8  with protect, constant(uar_get_code_by(   'MEANING',  8, 'ALTERED'                     ))
                                                                             

declare grid_cd  = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'UGYNCRADI8'           ))

 
declare lcv_dt_tm    = dq8 with protect
declare hold_str     = vc  with protect
declare low_str      = vc  with protect
declare high_str     = vc  with protect
;declare looper       = i4  with protect
 

/**************************************************************
; DVDev Start Coding
**************************************************************/


/***********************************************************************
DESCRIPTION: 
***********************************************************************/
select into 'nl:'
      sequence = cnvtint(res.collating_seq)
  from clinical_event grid
     , clinical_event res
 where grid.encntr_id         =  e_id
   and grid.result_status_cd  in (act_cd, mod_cd, auth_cd, alt_cd)
   and grid.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
   and grid.event_cd          =  grid_cd
   and res.parent_event_id    =  grid.event_id
   and res.result_status_cd   in (act_cd, mod_cd, auth_cd, alt_cd)
   and res.valid_until_dt_tm  >  cnvtdatetime(curdate,curtime3)
order by res.event_end_dt_tm desc, sequence
head report
    lcv_dt_tm = res.event_end_dt_tm
detail
    if(res.event_end_dt_tm = lcv_dt_tm)
        case(res.result_val)
        of '0*':
        of '1*':
            data->low_cnt = data->low_cnt + 1
            
            stat = alterlist(data->low, data->low_cnt)
            
            data->low[data->low_cnt]->title_txt = trim(res.event_title_text, 3)
        
        of '2*':
        of '3*':
        of '4*':
            data->high_cnt = data->high_cnt + 1
            
            stat = alterlist(data->high, data->high_cnt)
            
            data->high[data->high_cnt]->title_txt = trim(res.event_title_text, 3)
        
        endcase
    endif
with nocounter
 
 
 
 
;Presentation
 
 
;RTF header
set header = notrim(build2(rhead))

if(data->low_cnt > 0)
    set hold_str = ''
    
    
    for(looper = 1 to data->low_cnt)
        if(hold_str = '') set hold_str = data->low[looper]->title_txt
        else              set hold_str = notrim(build2(hold_str, ', ', data->low[looper]->title_txt))
        endif
    endfor
    
    
    if(data->low_cnt = 1) set low_str = notrim(build2('Patient denies bothersome symptoms of:   ', hold_str))
    else                  set low_str = notrim(build2('Patient denies bothersome symptoms from: ', hold_str))
    endif
    
endif
 
if(data->high_cnt > 0)
    set hold_str = ''
    
    
    for(looper = 1 to data->high_cnt)
        if(hold_str = '') set hold_str = data->high[looper]->title_txt
        else              set hold_str = notrim(build2(hold_str, ', ', data->high[looper]->title_txt))
        endif
    endfor
    
    
    if(data->high_cnt = 1) set high_str = notrim(build2(tmp_str, 'Patient reports bothersome symptoms of:   ', hold_str))
    else                   set high_str = notrim(build2(tmp_str, 'Patient reports bothersome symptoms from: ', hold_str))
    endif
    
endif

set tmp_str = ' '

if(low_str > ' ')  
    set tmp_str  = low_str
endif

if(high_str > ' ') 
    if(tmp_str = ' ') set tmp_str = high_str
    else              set tmp_str = notrim(build2(tmp_str  ,  reol
                                                 , high_str
                                                 )
                                          )
    endif
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
call echorecord(data)
call echorecord(reply)
call echorecord(drec)
 
call echo(reply->text)
 
end
go