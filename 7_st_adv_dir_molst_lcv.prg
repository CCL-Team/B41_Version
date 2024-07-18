/*************************************************************************
 Program Title:   Advance Directive/MO(L)ST Most Recent Documented ST
 
 Object name:     7_st_adv_dir_molst_lcv
 Source file:     7_st_adv_dir_molst_lcv.prg
 
 Purpose:
 
 Tables read:
 
 Executed from:
 
 Special Notes:   
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2024-02-29 Michael Mayes        346158 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 7_st_adv_dir_molst_lcv:dba go
create program 7_st_adv_dir_molst_lcv:dba

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
    1 doc_dt_tm    = f8
    1 doc_dt_txt   = vc
    
    1 ad_sect_cnt       = i4
    1 ad_sect[*]
        2 event_id = f8
        2 title    = vc
        2 value    = vc
    
    1 molst_sect_cnt    = i4
    1 molst_sect[*]
        2 event_id = f8
        2 title    = vc
        2 value    = vc
    
    1 decision1_cnt    = i4
    1 decision1[*]
        2 event_id = f8
        2 title    = vc
        2 value    = vc
    
    1 decision2_cnt    = i4
    1 decision2[*]
        2 event_id = f8
        2 title    = vc
        2 value    = vc
    
    1 final_cnt    = i4
    1 final[*]
        2 event_id = f8
        2 title    = vc
        2 value    = vc
)
 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header           = vc  with protect, noconstant(' ')
declare tmp_str          = vc  with protect, noconstant(' ')

declare pri_evnt_id      = f8  with protect,   constant(uar_get_code_by('DISPLAY_KEY', 18189, 'PRIMARYEVENTID'      ))
declare root_cd          = f8  with protect,   constant(uar_get_code_by(   'MEANING',  24, 'ROOT'                   ))
declare child_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',  24, 'CHILD'                  ))

declare ad_event_cd      = f8  with protect,  noconstant(uar_get_code_by('DISPLAYKEY',  72, 'ADVANCEDIRECTIVES'      ))

;Prod hot fix
if(ad_event_cd = -1)
    set ad_event_cd      = 704644.00
endif

declare ad_form_cd       = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',  72, 'ADVANCEDIRECTIVEFORM'   ))
declare ad_form_grid_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',  72, 'ADVANCEDIRECTIVELOCGRID'))
declare ad_loc_grid_ind  = i2  with protect, noconstant(0)

declare old_loc_form_element = vc  with protect, noconstant('')
declare old_loc_event_tag    = vc  with protect, noconstant('') 
declare old_loc_event_id     = f8  with protect, noconstant(0)

declare trig_event_id    = f8  with protect, noconstant(0.0)
declare form_event_id    = f8  with protect, noconstant(0.0)  ;006
declare trig_event_dt_tm = f8  with protect, noconstant(0.0)  ;006
declare form_event_dt_tm = f8  with protect, noconstant(0.0)  ;006

declare trig_form = vc
declare form_form = vc


declare act_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',   8, 'ACTIVE'                 ))
declare mod_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',   8, 'MODIFIED'               ))
declare auth_cd          = f8  with protect,   constant(uar_get_code_by(   'MEANING',   8, 'AUTH'                   ))
declare alt_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',   8, 'ALTERED'                ))
                                                                              
declare lcv_dt_tm        = dq8 with protect
declare looper           = i4  with protect
 
;debugging


declare temp_ad_loc    = vc  with protect, noconstant('')
declare temp_molst_loc = vc  with protect, noconstant('')

declare ad_loc_pos     = i4  with protect, noconstant(0)
declare molst_loc_pos  = i4  with protect, noconstant(0)

/**************************************************************
; DVDev Start Coding
**************************************************************/

;Find the most recent AD event doc
/*Some thought here is required... I think I'm going to get away with this however...  The ce might be on
  an older form doc, but we want to link to the latest form.
*/
select into 'nl:'
  from clinical_event ce
 where ce.person_id             =  p_id
   and ce.event_cd              =  ad_event_cd
   and ce.event_reltn_cd        =  child_cd
   and ce.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.000')
   and ce.result_status_cd      in (act_cd,auth_cd,alt_cd,mod_cd)
order by ce.event_end_dt_tm desc
head report
    trig_event_id    = ce.event_id
    trig_event_dt_tm = ce.event_end_dt_tm  ;006 We need this because the other form doesn't have a trigger question.
    trig_form        = uar_get_code_display(ce.event_cd)
    
with nocounter


select into 'nl:'
  from clinical_event event
     , clinical_event sect
     , clinical_event form
 
 where event.event_id              =  trig_event_id
   and event.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.000')
   and event.result_status_cd      in (act_cd,auth_cd,alt_cd,mod_cd)
   
   and sect.event_id              =  event.parent_event_id
   and sect.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.000')
   and sect.result_status_cd      in (act_cd,auth_cd,alt_cd,mod_cd)
   
   and form.event_id              =  sect.parent_event_id
   and form.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.000')
   and form.result_status_cd      in (act_cd,auth_cd,alt_cd,mod_cd)
detail
    trig_event_id = form.event_id 
with nocounter


;006->
;Now we got to see if we have a more recent version of the new form.
select into 'nl:'
  from clinical_event ce
 where ce.person_id             =  p_id
   and ce.event_cd              =  ad_form_cd
   and ce.event_reltn_cd        =  root_cd
   and ce.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.000')
   and ce.result_status_cd      in (act_cd,auth_cd,alt_cd,mod_cd)
order by ce.event_end_dt_tm desc
head report
    form_event_id    = ce.event_id
    form_event_dt_tm = ce.event_end_dt_tm  ;006 We need this because the other form doesn't have a trigger question.
    form_form        = uar_get_code_display(ce.event_cd)
with nocounter
;006<-

call echo(build('trig_form       :', trig_form                      ))
call echo(build('trig_event_id   :', trig_event_id                  ))
call echo(build('trig_event_dt_tm:', format(trig_event_dt_tm, ';;q')))
call echo(build('form_form       :', form_form                      ))
call echo(build('form_event_id   :', form_event_id                  ))
call echo(build('form_event_dt_tm:', format(form_event_dt_tm, ';;q')))


declare find_this_form = f8

if(trig_event_dt_tm > form_event_dt_tm)
    set find_this_form = trig_event_id
else
    set find_this_form = form_event_id
endif


/***********************************************************************
DESCRIPTION: 
***********************************************************************/
select into 'nl:'
       ;Build
       ;SORT = if    (ce3.event_cd = 4562131147.0) 1    ; AD Documents
       ;       elseif(ce3.event_cd = 704644.0    ) 1    ; AD Documents again?
       ;       elseif(ce3.event_cd = 4562131125.0) 2    ; Pat declines
       ;       elseif(ce3.event_cd = 704647.0    ) 3    ; AD Type
       ;       elseif(ce3.event_cd = 704662.0    ) 4    ; AD Date
       ;       
       ;       elseif(ce3.event_cd = 2188783197.0) 4    ; MOLST Date
       ;                                              
       ;       elseif(ce3.event_cd = 4562131247.0) 21   ; Decision1 Maker
       ;       elseif(ce3.event_cd = 4562131267.0) 22   ; Decision1 Type
       ;       elseif(ce3.event_cd = 4562131257.0) 23   ; Decision1 Phone
       ;                                              
       ;       elseif(ce3.event_cd = 4562131277.0) 31   ; Decision2 Maker
       ;       elseif(ce3.event_cd = 4562131297.0) 32   ; Decision2 Type
       ;       elseif(ce3.event_cd = 4562131287.0) 33   ; Decision2 Phone
       ;       
       ;       elseif(ce3.event_cd = 4562131307.0) 41   ; Validation decision
       ;       elseif(ce3.event_cd = 823733389.0 ) 42   ; Comments
       ;       elseif(ce3.event_cd = 704656.0    ) 43   ; Further info
       ;       
       ;       ;I think we luck out on the locations and they can just be at the end of their respective sections.
       ;       elseif(ce4.event_cd = 4562131347.0) 51   ; Scanned EMR
       ;       elseif(ce4.event_cd = 4562131429.0) 52   ; Paper Copy
       ;       elseif(ce4.event_cd = 4562131397.0) 53   ; CRISP
       ;       elseif(ce4.event_cd = 4562131407.0) 54   ; Copy Prev Records
       ;       
       ;       else                              100
       ;       endif
       ;Prod
       SORT = if    (ce3.event_cd = 5473905453.0) 1    ; AD Documents
              elseif(ce3.event_cd = 704644.0    ) 1    ; AD Documents again?
              elseif(ce3.event_cd = 5473924419.0) 2    ; Pat declines
              elseif(ce3.event_cd = 704647.0    ) 3    ; AD Type
              elseif(ce3.event_cd = 704662.0    ) 4    ; AD Date
              
              elseif(ce3.event_cd = 2188783197.0) 4    ; MOLST Date
                                                     
              elseif(ce3.event_cd = 5473924845.0) 21   ; Decision1 Maker
              elseif(ce3.event_cd = 5473925103.0) 22   ; Decision1 Type
              elseif(ce3.event_cd = 5473905567.0) 23   ; Decision1 Phone
                                                     
              elseif(ce3.event_cd = 5473925397.0) 31   ; Decision2 Maker
              elseif(ce3.event_cd = 5473926121.0) 32   ; Decision2 Type
              elseif(ce3.event_cd = 5473925587.0) 33   ; Decision2 Phone
              
              elseif(ce3.event_cd = 5473927121.0) 41   ; Validation decision
              elseif(ce3.event_cd = 823733389.0 ) 42   ; Comments
              elseif(ce3.event_cd = 704656.0    ) 43   ; Further info
              
              ;I think we luck out on the locations and they can just be at the end of their respective sections.
              elseif(ce4.event_cd = 5473931779.0) 51   ; Scanned EMR
              elseif(ce4.event_cd = 5473932615.0) 52   ; Paper Copy
              elseif(ce4.event_cd = 5473928159.0) 53   ; CRISP
              elseif(ce4.event_cd = 5473932561.0) 54   ; Copy Prev Records
              
              else                              100
              endif
              
  from clinical_event          ce  ;triggering ce
     , clinical_event          ce2 ;form
     , clinical_event          ce3 ;form children
     , clinical_event          ce4 ;data grid if present.
     , dcp_forms_activity_comp df
     , dcp_forms_activity      d   ;the activity where our event dropped.
     , dcp_forms_activity      d2  ;the most recent activity on the form.

  plan ce ;form
   ;where ce.event_id              =  form_event_id
   where ce.event_id              =  find_this_form
     and ce.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.000')
     and ce.result_status_cd      in (act_cd,auth_cd,alt_cd,mod_cd)
  
  join ce2 ;section
   where ce2.parent_event_id      =  ce.event_id
     and ce2.event_title_text     in ('*Advance*', '*MOLST*', '*MO(L)ST*')
     and ce2.valid_until_dt_tm    =  cnvtdatetime('31-DEC-2100 00:00:00.000')
     and ce2.event_reltn_cd       =  child_cd
     and ce2.result_status_cd     in (act_cd,auth_cd,alt_cd,mod_cd)
  
  join ce3 ;dtas
   where ce3.parent_event_id      =  ce2.event_id
     and ce3.valid_until_dt_tm    =  cnvtdatetime('31-DEC-2100 00:00:00.000')
     and ce3.event_reltn_cd       =  child_cd
     and ce3.event_cd             != 677460393.00  ;Advance Directive RTF  ;Not sure if this actually holds any info
     and ce3.result_status_cd     in (act_cd,auth_cd,alt_cd,mod_cd)
  
  join ce4 ;dtas
   where ce4.parent_event_id      =  outerjoin(ce3.event_id)
     and ce4.valid_until_dt_tm    =  outerjoin(cnvtdatetime('31-DEC-2100 00:00:00.000'))
     and ce4.event_reltn_cd       =  outerjoin(child_cd)
     and ce4.event_cd             != outerjoin(677460393.00)  ;Advance Directive RTF  ;Not sure if this actually holds any info
     and (   ce4.result_status_cd =  outerjoin(act_cd)
          or ce4.result_status_cd =  outerjoin(auth_cd)
          or ce4.result_status_cd =  outerjoin(alt_cd)
          or ce4.result_status_cd =  outerjoin(mod_cd)
         )
  
  join df
   where df.parent_entity_id      =  ce.event_id
     and df.parent_entity_name    =  'CLINICAL_EVENT'
     and df.component_cd          =  pri_evnt_id
  
  join d  ;our ce activity
   where d.dcp_forms_activity_id  =  df.dcp_forms_activity_id
  
  join d2 ;most recent activity on the same type of form
   where d2.dcp_forms_ref_id      = d.dcp_forms_ref_id
     and d2.person_id             =  d.person_id  ;008
     and d2.version_dt_tm    = (
           select max(dx.version_dt_tm)
             from dcp_forms_activity dx
            where dx.person_id        = d.person_id
              and dx.dcp_forms_ref_id = d.dcp_forms_ref_id
          )

order by SORT, ce3.event_cd, ce3.event_end_dt_tm desc

head ce3.event_cd
    ;if(ce3.event_cd != ad_form_grid_cd)
    if(ce3.event_cd != 704650)
        
        case(ce3.event_cd)
        ;Build
        ;of 4562131147.0:  ; AD Documents
        ;of 704644.0    :  ; AD Documents
        ;Prod
        of 5473905453.0:  ; AD Documents
        of 704644.0    :  ; AD Documents
            data->ad_sect_cnt = data->ad_sect_cnt + 1
 
            stat = alterlist(data->ad_sect, data->ad_sect_cnt)
     
            data->ad_sect[data->ad_sect_cnt]->title    = "Healthcare Decision Making Documents"
            data->ad_sect[data->ad_sect_cnt]->value    = trim(ce3.result_val, 3)
            data->ad_sect[data->ad_sect_cnt]->event_id = ce3.event_id
            
        ;Build
        ;of 4562131125.0:  ; AD Type
        ;of 704647.0    :  ; AD Type
        ;of 704662.0    :  ; AD Date
        ;Prod
        of 5473924419.0:  ; AD Type
        of 704647.0    :  ; AD Type
        of 704662.0    :  ; AD Date
            data->ad_sect_cnt = data->ad_sect_cnt + 1
 
            stat = alterlist(data->ad_sect, data->ad_sect_cnt)
     
            data->ad_sect[data->ad_sect_cnt]->title    = trim(uar_get_code_display(ce3.event_cd), 3)
            data->ad_sect[data->ad_sect_cnt]->value    = trim(ce3.result_val, 3)
            data->ad_sect[data->ad_sect_cnt]->event_id = ce3.event_id
        
        of 2188783197.0:  ; MOLST Date
        
            data->molst_sect_cnt = data->molst_sect_cnt + 1
 
            stat = alterlist(data->molst_sect, data->molst_sect_cnt)
     
            data->molst_sect[data->molst_sect_cnt]->title    = trim(uar_get_code_display(ce3.event_cd), 3)
            data->molst_sect[data->molst_sect_cnt]->value    = trim(ce3.result_val, 3)
            data->molst_sect[data->molst_sect_cnt]->event_id = ce3.event_id
        
        
        ;Build
        ;of 4562131247.0:  ; Decision1 Maker
        ;of 4562131267.0:  ; Decision1 Type
        ;of 4562131257.0:  ; Decision1 Phone
        ;Prod
        of 5473924845.0:  ; Decision1 Maker
        of 5473925103.0:  ; Decision1 Type
        of 5473905567.0:  ; Decision1 Phone
        
            data->decision1_cnt = data->decision1_cnt + 1
 
            stat = alterlist(data->decision1, data->decision1_cnt)
     
            data->decision1[data->decision1_cnt]->title    = trim(uar_get_code_display(ce3.event_cd), 3)
            data->decision1[data->decision1_cnt]->value    = trim(ce3.result_val, 3)
            data->decision1[data->decision1_cnt]->event_id = ce3.event_id
        
        ;Build
        ;of 4562131277.0:  ; Decision2 Maker
        ;of 4562131297.0:  ; Decision2 Type
        ;of 4562131287.0:  ; Decision2 Phone
        ;Prod
        of 5473925397.0:  ; Decision2 Maker
        of 5473926121.0:  ; Decision2 Type
        of 5473925587.0:  ; Decision2 Phone
        
            data->decision2_cnt = data->decision2_cnt + 1
 
            stat = alterlist(data->decision2, data->decision2_cnt)
     
            data->decision2[data->decision2_cnt]->title    = trim(uar_get_code_display(ce3.event_cd), 3)
            data->decision2[data->decision2_cnt]->value    = trim(ce3.result_val, 3)
            data->decision2[data->decision2_cnt]->event_id = ce3.event_id
        
        ;Build
        ;of 4562131307.0:  ; Validation decision
        ;of 823733389.0 :  ; Comments
        ;of 704656.0    :  ; Further info
        ;Prod
        of 5473927121.0:  ; Validation decision
        of 823733389.0 :  ; Comments
        of 704656.0    :  ; Further info
        
            data->final_cnt = data->final_cnt + 1
 
            stat = alterlist(data->final, data->final_cnt)
     
            data->final[data->final_cnt]->title    = trim(uar_get_code_display(ce3.event_cd), 3)
            data->final[data->final_cnt]->value    = trim(ce3.result_val, 3)
            data->final[data->final_cnt]->event_id = ce3.event_id
        
        else
            
            data->ad_sect_cnt = data->ad_sect_cnt + 1
 
            stat = alterlist(data->ad_sect, data->ad_sect_cnt)
     
            data->ad_sect[data->ad_sect_cnt]->title    = trim(uar_get_code_display(ce3.event_cd), 3)
            data->ad_sect[data->ad_sect_cnt]->value    = trim(ce3.result_val, 3)
            data->ad_sect[data->ad_sect_cnt]->event_id = ce3.event_id
            
        endcase
    else
        old_loc_form_element = trim(uar_get_code_display(ce3.event_cd), 3)
        old_loc_event_tag    = trim(ce3.event_tag)
        old_loc_event_id     = ce3.event_id
    endif

head ce4.event_cd
    
    ;if(ce3.event_cd = ad_form_grid_cd)
    if(ce3.event_cd = 704650.00 and ce4.event_id > 0)
        ad_loc_grid_ind = 1
        
        ;This is in a pivot table sort of thing... we need to undo that to get what they want in the ST.
        if(findstring('Advance Directive', ce4.result_val) > 0)
            if(temp_ad_loc = '') temp_ad_loc = trim(uar_get_code_display(ce4.event_cd), 3)
            else                 temp_ad_loc = notrim(build2( temp_ad_loc, '; '
                                                            , trim(uar_get_code_display(ce4.event_cd), 3)))
            endif
        endif
        
        if(findstring('MO(L)ST', ce4.result_val) > 0)
            if(temp_molst_loc = '') temp_molst_loc = trim(uar_get_code_display(ce4.event_cd), 3)
            else                    temp_molst_loc = notrim(build2( temp_molst_loc, '; '
                                                                  , trim(uar_get_code_display(ce4.event_cd), 3)))
            endif
            
        endif
        
        
        
    endif
foot report
    if(temp_ad_loc > ' ')
            
            data->ad_sect_cnt = data->ad_sect_cnt + 1
 
            stat = alterlist(data->ad_sect, data->ad_sect_cnt)
     
            data->ad_sect[data->ad_sect_cnt]->title    = 'Advance Directive Location'
            data->ad_sect[data->ad_sect_cnt]->value    = temp_ad_loc
        
    endif
    
    
    if(temp_molst_loc > ' ')
            
            data->molst_sect_cnt = data->molst_sect_cnt + 1
 
            stat = alterlist(data->molst_sect, data->molst_sect_cnt)
     
            data->molst_sect[data->molst_sect_cnt]->title    = 'MO(L)ST Location'
            data->molst_sect[data->molst_sect_cnt]->value    = temp_molst_loc
        
    endif
    
    if(ad_loc_grid_ind = 0 and old_loc_event_tag > ' ')
        pos = data->ad_sect_cnt + 1
        
        data->ad_sect_cnt = pos

        stat = alterlist(data->ad_sect, pos)
        
        data->ad_sect[pos].title        = 'Advance Directive Location'
        data->ad_sect[pos].value        = old_loc_event_tag
    endif
    
with nocounter
 
 
 
 
;Presentation
 
;RTF header
set header = notrim(build2(rhead))
 
if(   data->ad_sect_cnt    > 0 
   or data->molst_sect_cnt > 0
   or data->decision1_cnt  > 0
   or data->decision2_cnt  > 0
   or data->final_cnt      > 0
  )
    set tmp_str = notrim(build2(rh2b, 'Advance Directive/MO(L)ST Most Recent Documented', wr, reol))
 
    if(data->ad_sect_cnt > 0)
    
        for(looper = 1 to data->ad_sect_cnt)
            set tmp_str = notrim(build2(tmp_str, data->ad_sect[looper]->title, ': ', data->ad_sect[looper]->value, reol))
        endfor

        set tmp_str = notrim(build2(tmp_str, reol))
    
    endif
 
    if(data->molst_sect_cnt > 0)
    
        for(looper = 1 to data->molst_sect_cnt)
            set tmp_str = notrim(build2(tmp_str, data->molst_sect[looper]->title, ': ', data->molst_sect[looper]->value, reol))
        endfor

        set tmp_str = notrim(build2(tmp_str, reol))
    
    endif
 
    if(data->decision1_cnt > 0)
    
        for(looper = 1 to data->decision1_cnt)
            set tmp_str = notrim(build2(tmp_str, data->decision1[looper]->title, ': ', data->decision1[looper]->value, reol))
        endfor

        set tmp_str = notrim(build2(tmp_str, reol))
    
    endif
 
    if(data->decision2_cnt > 0)
    
        for(looper = 1 to data->decision2_cnt)
            set tmp_str = notrim(build2(tmp_str, data->decision2[looper]->title, ': ', data->decision2[looper]->value, reol))
        endfor

        set tmp_str = notrim(build2(tmp_str, reol))
    
    endif
 
    if(data->final_cnt > 0)
    
        for(looper = 1 to data->final_cnt)
            set tmp_str = notrim(build2(tmp_str, data->final[looper]->title, ': ', data->final[looper]->value, reol))
        endfor

        set tmp_str = notrim(build2(tmp_str, reol))
    
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
 
