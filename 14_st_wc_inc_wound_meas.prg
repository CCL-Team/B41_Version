/*************************************************************************
 Program Title:   WC Incision Wound Measurements
 
 Object name:     14_st_wc_inc_wound_meas
 Source file:     14_st_wc_inc_wound_meas.prg
 
 Purpose:         Pull several documentation points in bands from iView
                  and display in an autotext/dyndoc so that further 
                  note documentation can be done.
 
 Tables read:
 
 Executed from:
 
 Special Notes:   
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2024-05-08 Michael Mayes        346636 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_wc_inc_wound_meas:dba go
create program 14_st_wc_inc_wound_meas:dba

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
    1 cnt = i4
    1 qual[*]
        2 ce_dynamic_label_id = f8
        2 label_name          = vc
        
        2 results_ind         = i2
        2 res_dt_tm           = dq8
        2 incis_length        = vc
        2 incis_width         = vc
        2 incis_depth         = vc
        2 incis_area          = vc
)


 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header          = vc  with protect, noconstant(' ')
declare tmp_str         = vc  with protect, noconstant(' ')
                 
declare act_cd          = f8  with protect,   constant(uar_get_code_by(    'MEANING',      8, 'ACTIVE'                            ))
declare mod_cd          = f8  with protect,   constant(uar_get_code_by(    'MEANING',      8, 'MODIFIED'                          ))
declare auth_cd         = f8  with protect,   constant(uar_get_code_by(    'MEANING',      8, 'AUTH'                              ))
declare alt_cd          = f8  with protect,   constant(uar_get_code_by(    'MEANING',      8, 'ALTERED'                           ))
                                              
declare wc_loc_cd     = f8  with protect,   constant(uar_get_code_by('DESCRIPTION', 72, 'WC Incision, Wound Laterality:'          ))          
declare wc_lat_cd     = f8  with protect,   constant(uar_get_code_by('DESCRIPTION', 72, 'WC Incision, Wound Location:'            ))            
declare wc_desc_cd    = f8  with protect,   constant(uar_get_code_by('DESCRIPTION', 72, 'WC Incision, Wound Location Description:'))
                                              
declare incis_length_cd = f8  with protect,   constant(uar_get_code_by('DESCRIPTION',     72, 'Incision, Wound Length:'           ))
declare incis_width_cd  = f8  with protect,   constant(uar_get_code_by('DESCRIPTION',     72, 'Incision, Wound Width:'            ))
declare incis_depth_cd  = f8  with protect,   constant(uar_get_code_by('DESCRIPTION',     72, 'Incision, Wound Depth:'            ))
declare incis_area_cd   = f8  with protect,   constant(uar_get_code_by('DESCRIPTION',     72, 'WC Incision, Wound Area cm2:'      ))
                                              
declare cdl_inact_cd    = f8  with protect,   constant(uar_get_code_by(    'MEANING', 4002015, 'INACTIVE'                         ))

declare lookback        = dq8 with protect,   constant(datetimefind(cnvtdatetime(curdate, curtime3), "D", "S", "S"))

declare looper          = i4  with protect, noconstant(0)

declare temp_res_str    = vc  with protect, noconstant('')


/**************************************************************
; DVDev Start Coding
**************************************************************/
call echo(build('act_cd         :', act_cd         ))
call echo(build('mod_cd         :', mod_cd         ))
call echo(build('auth_cd        :', auth_cd        ))
call echo(build('alt_cd         :', alt_cd         ))

call echo(build('wc_loc_cd      :', wc_loc_cd      ))
call echo(build('wc_lat_cd      :', wc_lat_cd      ))
call echo(build('wc_desc_cd     :', wc_desc_cd     ))

call echo(build('incis_length_cd:', incis_length_cd))
call echo(build('incis_width_cd :', incis_width_cd ))
call echo(build('incis_depth_cd :', incis_depth_cd ))
call echo(build('incis_area_cd  :', incis_area_cd  ))

call echo(build('cdl_inact_cd   :', cdl_inact_cd   ))


/***********************************************************************
DESCRIPTION: Find dynamic label groups
***********************************************************************/
select into 'nl:'

  from clinical_event   ce
     , ce_dynamic_label cdl

 where ce.encntr_id            =  e_id
   and ce.result_status_cd     in (act_cd, mod_cd, auth_cd, alt_cd)
   and ce.valid_until_dt_tm    >  cnvtdatetime(curdate, curtime3)
   and ce.event_cd             in (wc_loc_cd, wc_lat_cd, wc_desc_cd)
   
   and cdl.ce_dynamic_label_id =  ce.ce_dynamic_label_id
   and cdl.valid_until_dt_tm   >  cnvtdatetime(curdate, curtime3)
   and cdl.label_status_cd     != cdl_inact_cd
   
order by cdl.label_seq_nbr, ce.ce_dynamic_label_id, ce.event_end_dt_tm desc

head ce.ce_dynamic_label_id

    data->cnt = data->cnt + 1
    stat = alterlist(data->qual, data->cnt)
    
    data->qual[data->cnt]->ce_dynamic_label_id = ce.ce_dynamic_label_id
    data->qual[data->cnt]->label_name          = trim(cdl.label_name, 3)
with nocounter



/***********************************************************************
DESCRIPTION: Find LCV Results under the dynamic label group
      
      NOTES: After an initial stab, I got told we just want the LCV for the
             whole group
***********************************************************************/
select into 'nl:'

  from clinical_event   ce
     , (dummyt d with seq = data->cnt)
 
  plan d
   where data->cnt                              >  0
     and data->qual[d.seq]->ce_dynamic_label_id >  0
 
  join ce
   where ce.ce_dynamic_label_id  =  data->qual[d.seq]->ce_dynamic_label_id
     and ce.result_status_cd     in (act_cd, mod_cd, auth_cd, alt_cd)
     and ce.valid_until_dt_tm    >  cnvtdatetime(curdate, curtime3)
     and ce.event_cd             in (incis_length_cd, incis_width_cd, incis_depth_cd, incis_area_cd)
     and ce.event_end_dt_tm      >= cnvtdatetime(lookback)
   
order by ce.ce_dynamic_label_id, ce.event_end_dt_tm desc, ce.event_cd

head ce.ce_dynamic_label_id
    data->qual[d.seq]->res_dt_tm = ce.event_end_dt_tm
    ;call echo('-------')
    ;call echo(data->qual[d.seq]->label_name)
    
head ce.event_cd
    
    ;call echo(notrim(build2( trim(uar_get_code_display(ce.event_cd), 3), ' '
    ;                       , '[', format(ce.event_end_dt_tm, ';;q'), '] '
    ;                       , trim(ce.result_val, 3), ' ' , trim(uar_get_code_display(ce.result_units_cd), 3)
    ;                       , '(', ce.event_id , ')'
    ;                       )
    ;                )
    ;         )
    ;
    ;call echo(format(ce.event_end_dt_tm, ';;q'))
    ;call echo(format(data->qual[d.seq]->res_dt_tm, ';;q'))
    
    if(ce.event_end_dt_tm = data->qual[d.seq]->res_dt_tm)
    ;    call echo('in')
    
        if(ce.result_units_cd > 0) temp_res_str = notrim(build2( trim(ce.result_val, 3), ' '
                                                               , uar_get_code_display(ce.result_units_cd)
                                                               )
                                                        )
        else                       temp_res_str =               trim(ce.result_val, 3)
        endif
        
        case(ce.event_cd)
        of incis_length_cd: data->qual[d.seq]->incis_length = temp_res_str
        of incis_width_cd : data->qual[d.seq]->incis_width  = temp_res_str
        of incis_depth_cd : data->qual[d.seq]->incis_depth  = temp_res_str
        of incis_area_cd  : data->qual[d.seq]->incis_area   = temp_res_str
        endcase
        
        data->qual[d.seq]->results_ind = 1
    endif
    
with nocounter
 
 
 
 
;Presentation

;RTF header
set header = notrim(build2(rhead))
 
if(data->cnt > 0)
    for(looper = 1 to data->cnt)
        if(tmp_str > ' ')
            set tmp_str = notrim(build2(tmp_str, reol))
            
            set tmp_str = notrim(build2(tmp_str, wb, data->qual[looper]->label_name, reol))
        
        else
            set tmp_str = notrim(build2(         wb, data->qual[looper]->label_name, reol))
        
        endif
        
        
        if(data->qual[looper]->results_ind = 1)

            set tmp_str = notrim(build2(tmp_str, wu, 'Measurements', wr, ': '))
        
            if(data->qual[looper]->incis_length > ' ') 
                set tmp_str = notrim(build2(tmp_str, wb, data->qual[looper]->incis_length               ))
            else                                       
                set tmp_str = notrim(build2(tmp_str, wb, '[Length]'                                     ))
            endif
            
            if(data->qual[looper]->incis_width  > ' ') 
                set tmp_str = notrim(build2(tmp_str, wb, ' X ', data->qual[looper]->incis_width         ))
            else                                       
                set tmp_str = notrim(build2(tmp_str, wb, ' X ', '[Width]'                               ))
            endif
            
            ;We get a little special here, they don't want depth placeholders if we don't have the result.
            if(data->qual[looper]->incis_depth  > ' ') 
                set tmp_str = notrim(build2(tmp_str, wb, ' X ', data->qual[looper]->incis_depth , reol ))
            else
                set tmp_str = notrim(build2(tmp_str                                             , reol ))
            endif
            
            if(data->qual[looper]->incis_area > ' ')
                set tmp_str = notrim(build2(tmp_str, wu, 'Area cm2', wr, ': '))
            
                set tmp_str = notrim(build2(tmp_str, wb, data->qual[looper]->incis_area         , reol))
            endif
        ;else
        ;
        ;    set tmp_str = notrim(build2(tmp_str                                                 , reol))
        endif
    
    endfor

else
    set tmp_str = notrim(build2(wb, 'No wounds documented', wr))

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
 
