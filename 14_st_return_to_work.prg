/*************************************************************************
 Program Title:   Return to Work PF ST  
 
 Object name:     14_st_return_to_work
 Source file:     14_st_return_to_work.prg
 
 Purpose:
 
 Tables read:
 
 Executed from:
 
 Special Notes:   
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2025-08-02 Michael Mayes        352465 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_return_to_work:dba go
create program 14_st_return_to_work:dba

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
    1 form_event_id = f8
    
    1 employer                 = vc
    1 injury_dt_tm             = dq8
    1 injury_dt_tm_txt         = vc
    1 work_injury              = vc
    1 work_status              = vc
    1 ret_work_dt              = dq8
    1 ret_work_dt_txt          = vc
                               
    1 rest_work_start_dt       = dq8
    1 rest_work_start_dt_txt   = vc
    1 rest_work_stop_dt        = dq8
    1 rest_work_stop_dt_txt    = vc
    1 rest_work_stop_tbd       = vc
                               
    1 grid_event_id            = f8
    
    1 grid_cnt                 = i4
    1 grid[*]
        2 disp                 = vc
        2 res                  = vc
        2 ce_event_note_id     = f8
        2 compression          = vc
        2 comment              = vc
                               
    1 weight_lift_cap          = vc
    
    1 spec_work_inst           = vc
    1 further_follow_up        = vc
    1 further_follow_up_dt     = dq8
    1 further_follow_up_dt_txt = vc
    1 further_follow_up_tbd    = vc
    1 further_follow_phys      = vc
    
    1 work_status_comment      = vc
    
    1 otc_meds_rec             = vc
    
)


record cells(
    1 cells[*]
        2 size = i4
)


record uc_locs(
    1 cnt = i4
    1 qual[*]
        2 loc    = vc
        2 loc_cd = f8
)
 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare rtw_row1    (rs = vc(ref), cell1 = vc                                                ) = vc
declare rtw_row2    (rs = vc(ref), cell1 = vc, cell2 = vc                                    ) = vc
declare rtw_row3bord(rs = vc(ref), cell1 = vc, cell2 = vc, cell3 = vc                        ) = vc
declare rtw_row7    (rs = vc(ref), cell1 = vc, cell2 = vc, cell3 = vc, cell4 = vc, cell5 = vc
                                 , cell6 = vc, cell7 = vc                                    ) = vc
declare rtw_row9    (rs = vc(ref), cell1 = vc, cell2 = vc, cell3 = vc, cell4 = vc, cell5 = vc
                                 , cell6 = vc, cell7 = vc, cell8 = vc, cell9 = vc            ) = vc

 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header      = vc  with protect, noconstant(' ')
declare tmp_str     = vc  with protect, noconstant(' ')
                    
declare act_cd      = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'ACTIVE'   ))
declare mod_cd      = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'MODIFIED' ))
declare auth_cd     = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'AUTH'     ))
declare alt_cd      = f8  with protect,   constant(uar_get_code_by(    'MEANING',  8, 'ALTERED'  ))

declare comp_cd     = f8  with protect,   constant(uar_get_code_by('MEANING'   ,   120, 'OCFCOMP'        ))
declare uncomp_blob = vc  with protect, noconstant(notrim(fillstring(32767," "))) 
declare final_blob  = vc  with protect, noconstant(notrim(fillstring(32767," ")))
declare uncomp_size = w8  
                                                                             

declare looper       = i4  with protect
declare idx          = i4  with protect


/**************************************************************
; DVDev Start Coding
**************************************************************/

/**********************************************************************
DESCRIPTION:  Gather UC locations
      NOTES:
***********************************************************************/
select into 'nl:'
       cv.code_value
     , cv.display

  from code_value cv

 where cv.code_set            = 220
   and cv.active_ind          = 1
   and cv.cdf_meaning         = 'AMBULATORY'

   and (   cnvtlower(cv.display) = 'medstar health uc*'
        or cnvtlower(cv.display) = 'medstar health urgent*'
        or cnvtlower(cv.display) = 'medstar hlth urgent*'
        or cnvtlower(cv.display) = '*medstar uc*'
        or cnvtlower(cv.display) = 'medstar urgent care*')

detail
    uc_locs->cnt = uc_locs->cnt + 1
    stat         = alterlist(uc_locs->qual, uc_locs->cnt)


    uc_locs->qual[uc_locs->cnt]->loc    = cv.display
    uc_locs->qual[uc_locs->cnt]->loc_cd = cv.code_value

with nocounter


/***********************************************************************
DESCRIPTION: Find most recent form
***********************************************************************/
select into 'nl:'
    
  from dcp_forms_ref           dfr
     , dcp_forms_activity      dfa
     , encounter               e
     , dcp_forms_activity_comp dfac
     
 where dfr.description            =  'UC Return to Work Status'
   and dfr.active_ind             =  1
   and dfr.beg_effective_dt_tm    <= cnvtdatetime(curdate, curtime3)
   and dfr.end_effective_dt_tm    >= cnvtdatetime(curdate, curtime3)

   and dfa.encntr_id              =  e_id
   and dfa.dcp_forms_ref_id       =  dfr.dcp_forms_ref_id
   and dfa.form_status_cd         in (act_cd, mod_cd, auth_cd, alt_cd)
   and dfa.active_ind             =   1
   
   ;We are using this to force only finding forms on UC encounters, which
   ;should skip the St if we are not UC.
   and e.encntr_id                = dfa.encntr_id
   and expand(idx, 1, uc_locs->cnt, e.loc_nurse_unit_cd, uc_locs->qual[idx]->loc_cd)
   
   and dfac.dcp_forms_activity_id =  dfa.dcp_forms_activity_id
   and dfac.parent_entity_name    =  'CLINICAL_EVENT'
   and dfac.component_cd          =  10891.00  ;Primary Event Id
   
order by dfa.encntr_id, dfa.form_dt_tm desc
head dfa.encntr_id
    
    data->form_event_id = dfac.parent_entity_id
    
with nocounter


/***********************************************************************
DESCRIPTION: Find top level results
***********************************************************************/
select into 'nl:'
    
  from clinical_event form
     , clinical_event res
     , ce_date_result cdr
 
 where form.parent_event_id         =  data->form_event_id
   and form.valid_until_dt_tm       >= cnvtdatetime(curdate, curtime3)
   and form.result_status_cd        in (act_cd, mod_cd, auth_cd, alt_cd)

   and res.parent_event_id          =  form.event_id
   and res.valid_until_dt_tm        >= cnvtdatetime(curdate, curtime3)
   and res.result_status_cd         in (act_cd, mod_cd, auth_cd, alt_cd)
  
   and cdr.event_id                 =  outerjoin(res.event_id)

detail

    case(res.event_cd)
    ;Employer
    of 2478508.00   :  data->employer                 = trim(res.result_val, 3)
                                                   
    ;Injury Date Time                              
    of 2480509.00   :  data->injury_dt_tm             =        cdr.result_dt_tm
                       data->injury_dt_tm_txt         = format(cdr.result_dt_tm, '@SHORTDATETIME')
                                                   
    ;Injured at work                               
    of 3320128.00   :  data->work_injury              = trim(res.result_val, 3)
                                                   
    ;Work Status                                   
    of 2524508.00   :  data->work_status              = trim(res.result_val, 3)
                                                   
    ;Return to Work Start Date                     
    of 2484509.00   :  data->ret_work_dt              =        cdr.result_dt_tm
                       data->ret_work_dt_txt          = format(cdr.result_dt_tm, '@SHORTDATE')
                                                   
    ;Restricted Work Start Date                    
    of 2488509.00   :  data->rest_work_start_dt       =        cdr.result_dt_tm
                       data->rest_work_start_dt_txt   = format(cdr.result_dt_tm, '@SHORTDATE')
                                                   
    ;Restricted Work Stop Date                     
    of 2486509.00   :  data->rest_work_stop_dt        =        cdr.result_dt_tm
                       data->rest_work_stop_dt_txt    = format(cdr.result_dt_tm, '@SHORTDATE')
                                                   
    ;Work Restrictions Grid                        
    of 2532507.00   :  data->grid_event_id            =        res.event_id
                                                   
    ;Weightlifting Capabilities                    
    of 2512509.00   :  data->weight_lift_cap          = trim(res.result_val, 3)
    
    ;Special Work Instructions
    ;of 2512509.00  :  ;This is going to be handled in the multiselect query
    
    ;Further Follow-Up Needed                      
    of 3320164.00   :  data->further_follow_up        = trim(res.result_val, 3)
    
    ;Date to Follow Up with Physician
    of 3320170.00   :  data->further_follow_up_dt     =        cdr.result_dt_tm
                       data->further_follow_up_dt_txt = format(cdr.result_dt_tm, '@SHORTDATE')
    
    ;Follow-Up Physician
    of 3320167.00   :  data->further_follow_phys      = trim(res.result_val, 3)
    
    ;Work Status Comment
    of 2526509.00   :  data->work_status_comment      = trim(res.result_val, 3)
    
    ;UC Restricted Work Stop Date TBD
    of 6240906501.00:  data->rest_work_stop_tbd       = trim(res.result_val, 3)
    
    ;UC Date to Follow-Up TBD     
    of 6240906545.00:  data->further_follow_up_tbd    = trim(res.result_val, 3)
    
    
    endcase

with nocounter


/***********************************************************************
DESCRIPTION:  Find grid results
      NOTES:  
***********************************************************************/
select into 'nl:'
       
       sort = cnvtint(res.collating_seq)
    
  from clinical_event  res
     , ce_event_note   cen
 
 where data->grid_event_id > 0

   and res.parent_event_id          =  data->grid_event_id
   and res.valid_until_dt_tm        >= cnvtdatetime(curdate, curtime3)
   and res.result_status_cd         in (act_cd, mod_cd, auth_cd, alt_cd)
   
   and cen.event_id                 =  outerjoin(res.event_id)
   and cen.valid_until_dt_tm        >  outerjoin(cnvtdatetime(curdate, curtime3))

order by sort, res.event_cd, res.event_end_dt_tm desc

head res.event_cd
    data->grid_cnt = data->grid_cnt + 1
    
    stat = alterlist(data->grid, data->grid_cnt)
    
    data->grid[data->grid_cnt]->disp              = trim(res.event_title_text, 3)
    data->grid[data->grid_cnt]->res               = trim(res.result_val      , 3)
    
    data->grid[data->grid_cnt]->ce_event_note_id  = cen.ce_event_note_id
    
with nocounter 


/***********************************************************************
DESCRIPTION:  Find grid comments
      NOTES:  
***********************************************************************/
select into 'nl:'
    
  from ce_event_note cen
     , long_blob lb
     , (dummyt d with seq = data->grid_cnt)
     
  plan d
   where data->grid_cnt                      > 0
     and data->grid[d.seq]->ce_event_note_id > 0
  
  join cen
   where cen.ce_event_note_id  =  data->grid[d.seq]->ce_event_note_id
  
  join lb
   where lb.parent_entity_name =  'CE_EVENT_NOTE'
     and lb.parent_entity_id   =  cen.ce_event_note_id

detail
    uncomp_blob = notrim(fillstring(32767," "))
    final_blob  = notrim(fillstring(32767," "))
    
    ;Pretty sure through testing that this is limited in the PF at 256 chars, and will likely never be compressed...
    ;but went through the motions anyway... hopefully... it's unused.  Because it surely isn't tested.
    if(cen.compression_cd = comp_cd)
        call uar_ocf_uncompress(lb.long_blob, size(lb.long_blob), uncomp_blob, size(uncomp_blob), uncomp_size)    ;002
    else
        uncomp_blob = substring(1, findstring("ocf_blob", lb.long_blob) - 1, lb.long_blob)
    endif
    
    final_blob = uncomp_blob
    
    data->grid[d.seq]->compression = uar_get_code_display(cen.compression_cd)
    data->grid[d.seq]->comment     = final_blob
    
with nocounter 


/***********************************************************************
DESCRIPTION:  Find multiselect DTA Results
      NOTES:  Multiselects are overrunning the result_val field.  I
              found a way to counteract that but requires a different
              query structure to do correctly.  Handling that here.
***********************************************************************/
select into 'nl:'
    
  from clinical_event  form
     , clinical_event  res
     , ce_coded_result ccr
 
 where data->form_event_id          > 0
   and form.parent_event_id         =  data->form_event_id
   and form.valid_until_dt_tm       >= cnvtdatetime(curdate, curtime3)
   and form.result_status_cd        in (act_cd, mod_cd, auth_cd, alt_cd)

   and res.parent_event_id          =  form.event_id
   and res.valid_until_dt_tm        >= cnvtdatetime(curdate, curtime3)
   and res.result_status_cd         in (act_cd, mod_cd, auth_cd, alt_cd)
   
   and ccr.event_id                 =  res.event_id
   and ccr.valid_until_dt_tm        >= cnvtdatetime(curdate, curtime3)

order by ccr.event_id, ccr.sequence_nbr

detail

    case(res.event_cd)
    
    ;Special Work Instructions
    of 2514509.00:
        if(data->spec_work_inst = '')
            data->spec_work_inst      = trim(ccr.descriptor, 3)
        else
            data->spec_work_inst      = concat( data->spec_work_inst, ' ', reol
                                              , trim(ccr.descriptor, 3))
        endif
    
    ;UC OTC Medications Recommended
    ;of 6240906571.00:  ;BUILD
    of 6445880639.00:  ;PROD
        if(data->otc_meds_rec = '')
            data->otc_meds_rec        = trim(ccr.descriptor, 3)
        else
            data->otc_meds_rec        = concat( data->otc_meds_rec, ' ', reol
                                              , trim(ccr.descriptor, 3))
        endif
    
    endcase

with nocounter


/***********************************************************************
DESCRIPTION:  Check for other: string result
      NOTES:  
***********************************************************************/
select into 'nl:'
    
  from clinical_event   form
     , clinical_event   res
     , ce_string_result csr
 
 where data->form_event_id          > 0
   
   and form.parent_event_id         =  data->form_event_id
   and form.valid_until_dt_tm       >= cnvtdatetime(curdate, curtime3)
   and form.result_status_cd        in (act_cd, mod_cd, auth_cd, alt_cd)

   and res.parent_event_id          =  form.event_id
   and res.valid_until_dt_tm        >= cnvtdatetime(curdate, curtime3)
   and res.result_status_cd         in (act_cd, mod_cd, auth_cd, alt_cd)
   
   and csr.event_id                 =  res.event_id
   and csr.valid_until_dt_tm        >= cnvtdatetime(curdate, curtime3)

detail

    case(res.event_cd)
    
    ;Only case for now, but I'll be handling more here later maybe.
    ;Special Work Instructions
    of 2514509.00:
        if(data->spec_work_inst = '')
            data->spec_work_inst      = trim(csr.string_result_text, 3)
        else
            data->spec_work_inst      = concat( data->spec_work_inst, ' ', reol
                                              , trim(csr.string_result_text, 3))
        endif
    
    ;UC OTC Medications Recommended
    ;of 6240906571.00:  ;BUILD
    of 6445880639.00:  ;PROD
        if(data->otc_meds_rec = '')
            data->otc_meds_rec        = trim(csr.string_result_text, 3)
        else
            data->otc_meds_rec        = concat( data->otc_meds_rec, ' ', reol
                                              , trim(csr.string_result_text, 3))
        endif
    
    endcase

with nocounter


;We have some special stuff to do work weight lifting cap now.  We want to push it INTO the restricted work table.
if(data->weight_lift_cap > ' ')
    set data->grid_cnt = data->grid_cnt + 1
    
    set stat = alterlist(data->grid, data->grid_cnt)
    
    set data->grid[data->grid_cnt]->disp              = 'Weightlifting Capabilities'
    
    
    ;Even more special stuff... if we have Other: as the answer here... we want to pull the text off and place it in the comment 
    ;column
    if(findstring('Other:', data->weight_lift_cap) > 0)
        set data->grid[data->grid_cnt]->res               = 'Other'
        set data->grid[data->grid_cnt]->comment           = replace(data->weight_lift_cap, 'Other: ', '')
    else
        set data->grid[data->grid_cnt]->res               = data->weight_lift_cap
    endif
    
endif


;We have something special for special work instructions too.  If there is no data, we want a None message.
if(data->spec_work_inst = '')
    set data->spec_work_inst = 'None'
endif


;We have something special for otc meds too.  If there is no data, we want a "As directed" message.
if(data->otc_meds_rec = '')
    set data->otc_meds_rec = 'As directed'
endif


;We have something special for further_follow_phys too.  If there is no data, we want a None message.
if(data->further_follow_phys = '')
    set data->further_follow_phys = 'Patient to schedule appointment with PCP, or Specialist'
endif

;We have something special for tbds too.  If the TBD is set, we overwrite the corrisponding date.
if(data->rest_work_stop_tbd    > ' ')
    set data->rest_work_stop_dt_txt    = data->rest_work_stop_tbd
endif

if(data->further_follow_up_tbd > ' ')
    set data->further_follow_up_dt_txt = data->rest_work_stop_tbd
endif



;Presentation
/* Okay... this is going to be table heaven.  Makes sense that one of my first projects at MedStar was coming up with RTF tables, 
   and one of my last ones at MedStar under Cerner would be to push the limits of it.  Prey for us under Epic.
   
   This is the view we are envisioning, trying to match the form as much as possible:
   
   -----------------------------------------------------------------------------------------------------------------------------
   |Employer                           |Date Time of Injury    |Work Injury       | Work Status |    Return to work start date |
   -----------------------------------------------------------------------------------------------------------------------------
   |Restricted Work Start              |Restricted Work Stop                                                                   |
   -----------------------------------------------------------------------------------------------------------------------------
   |GRID RES                                   |Comments                                                                       |
   |GRID RES2                                  |Comments2                                                                      |
   |[...]                                                                                                                      |
   -----------------------------------------------------------------------------------------------------------------------------
   |Special work instructions      |Further Followup               |Date to follow up        |Follow up Physician              |
   -----------------------------------------------------------------------------------------------------------------------------
   |Work Status Comment                                                                                                        |
   -----------------------------------------------------------------------------------------------------------------------------
   |OTCs                                                                                                                       |
   -----------------------------------------------------------------------------------------------------------------------------

*/  



;RTF header
set header = notrim(build2(rhead))

;if there is no form at all, we don't want to display
if(data->form_event_id = 0)
    set tmp_str = ' '
else

    ;Set up table information for row 1

    set stat = alterlist(cells->cells, 9)
     
    set cells->cells[ 1]->size =  2500
    set cells->cells[ 2]->size =  2600
    set cells->cells[ 3]->size =  5000
    set cells->cells[ 4]->size =  5100
    set cells->cells[ 5]->size =  7500
    set cells->cells[ 6]->size =  7600
    set cells->cells[ 7]->size = 12000
    set cells->cells[ 8]->size = 12100
    set cells->cells[ 9]->size = 15000

    set tmp_str = rtw_row9( cells                          
                          , notrim(build2(wb, 'Employer'                 , wr))
                          , ' '
                          , notrim(build2(wb, 'Date/Time of Injury'      , wr))
                          , ' '
                          , notrim(build2(wb, 'Work Injury'              , wr))
                          , ' '
                          , notrim(build2(wb, 'Work Status'              , wr))
                          , ' '
                          , notrim(build2(wb, 'Return to Work Start Date', wr))
                          )

    set tmp_str = notrim(build2( tmp_str
                               , rtw_row9( cells
                                         , data->employer
                                         , ' '
                                         , data->injury_dt_tm_txt
                                         , ' '
                                         , data->work_injury
                                         , ' '
                                         , data->work_status
                                         , ' '
                                         , data->ret_work_dt_txt
                                         )
                               )
                        )


    ;Set up table information for row 2

    set stat = alterlist(cells->cells, 2)
     
    set cells->cells[ 1]->size =  2500
    set cells->cells[ 2]->size =  5000

    set tmp_str = notrim(build2( tmp_str
                               , '\pard ', reol
                               )
                        )
                        

    set tmp_str = notrim(build2( tmp_str
                               , rtw_row2( cells
                                         , notrim(build2(wb, 'Restricted Work Start Date', wr))
                                         , notrim(build2(wb, 'Restricted Work Stop Date' , wr))
                                         )
                               )
                        )

    set tmp_str = notrim(build2( tmp_str
                               , rtw_row2( cells
                                         , data->rest_work_start_dt_txt
                                         , data->rest_work_stop_dt_txt
                                         )
                               )
                        )


    ;Set up table information grid rows (row3... kinda, but it could be multiple.)

    set stat = alterlist(cells->cells, 3)
     
    set cells->cells[ 1]->size =  3500
    set cells->cells[ 2]->size =  6000
    set cells->cells[ 3]->size = 15000

    set tmp_str = notrim(build2( tmp_str
                               , '\pard ', reol
                               )
                        )
                        
    set tmp_str = notrim(build2( tmp_str
                               , rtw_row3bord( cells
                                         , notrim(build2(wb, 'Work Restriction'          , wr))
                                         , notrim(build2(wb, 'Recommendation'            , wr))
                                         , notrim(build2(wb, 'Comment'                   , wr))
                                         )
                               )
                        )

    ;If we have no data at all, we default a row in here... but I guess that is okay.
    if(data->grid_cnt = 0)

        set tmp_str = notrim(build2( tmp_str
                               , rtw_row3bord( cells
                                             , ' '
                                             , ' '
                                             , ' '
                                             )
                               )
                        )
                        
    else
        for(looper = 1 to data->grid_cnt)
            set tmp_str = notrim(build2( tmp_str
                                       , rtw_row3bord( cells
                                                 , data->grid[looper]->disp
                                                 , data->grid[looper]->res
                                                 , data->grid[looper]->comment
                                                 )
                                       )
                                )
           
        endfor

    endif


    ;Set up table information row4 (kinda, but it row3 could be multiple.)


    set stat = alterlist(cells->cells, 7)
     
    set cells->cells[ 1]->size =  4000
    set cells->cells[ 2]->size =  4100
    set cells->cells[ 3]->size =  8000
    set cells->cells[ 4]->size =  8100
    set cells->cells[ 5]->size = 11000
    set cells->cells[ 6]->size = 11100
    set cells->cells[ 7]->size = 15000

    set tmp_str = notrim(build2( tmp_str
                               , '\pard ', reol
                               )
                        )

    ;We want to flex here and not show things in the last columns if we don't have Yes for further_follow_up
    if(data->further_follow_up = 'Yes')
        set tmp_str = notrim(build2( tmp_str
                                   , rtw_row7( cells
                                             , notrim(build2(wb, 'Special Work Instructions', wr))
                                             , ' '
                                             , notrim(build2(wb, 'Further Follow-Up'        , wr))
                                             , ' '
                                             , notrim(build2(wb, 'Date to Follow-Up'        , wr))
                                             , ' '
                                             , notrim(build2(wb, 'Follow-Up Physician'      , wr))
                                             )
                                   )
                            )
                        
        set tmp_str = notrim(build2( tmp_str
                                   , rtw_row7( cells
                                             , data->spec_work_inst
                                             , ' '
                                             , data->further_follow_up
                                             , ' '
                                             , data->further_follow_up_dt_txt
                                             , ' '
                                             , data->further_follow_phys
                                             )
                                   )
                            )
    else
        set tmp_str = notrim(build2( tmp_str
                                   , rtw_row7( cells
                                             , notrim(build2(wb, 'Special Work Instructions', wr))
                                             , ' '
                                             , notrim(build2(wb, 'Further Follow-Up'        , wr))
                                             , ' '
                                             , ' '
                                             , ' '
                                             , ' '
                                             )
                                   )
                            )
                        
        set tmp_str = notrim(build2( tmp_str
                                   , rtw_row7( cells
                                             , data->spec_work_inst
                                             , ' '
                                             , data->further_follow_up
                                             , ' '
                                             , ' '
                                             , ' '
                                             , ' '
                                             )
                                   )
                            )

    endif


    ;Set up table information row5 (kinda, but it row3 could be multiple. so who knows at this point.)
    if(data->work_status_comment > ' ')
        set stat = alterlist(cells->cells, 1)
         
        set cells->cells[ 1]->size =  15000

        set tmp_str = notrim(build2( tmp_str
                                   , '\pard ', reol
                                   )
                            )
                            

        set tmp_str = notrim(build2( tmp_str
                                   , rtw_row1( cells
                                             , notrim(build2(wb, 'Work Status Comment' , wr))
                                             )
                                   )
                            )

        set tmp_str = notrim(build2( tmp_str
                                   , rtw_row1( cells
                                             , data->work_status_comment
                                             )
                                   )
                            )
    endif


    ;Set up table information row6 (kinda, but it row3 could be multiple and row 5 could be missing. so who knows at this point.)
    set stat = alterlist(cells->cells, 1)
     
    set cells->cells[ 1]->size =  15000

    set tmp_str = notrim(build2( tmp_str
                               , '\pard ', reol
                               )
                        )
                        

    set tmp_str = notrim(build2( tmp_str
                               , rtw_row1( cells
                                         , notrim(build2(wb, 'Over the Counter Medications Recommended for Your Injury' , wr))
                                         )
                               )
                        )

    set tmp_str = notrim(build2( tmp_str
                               , rtw_row1( cells
                                         , data->otc_meds_rec
                                         )
                               )
                        )
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
subroutine rtw_row1(rs, cell1)
    declare dr_ret_string = vc
 
    set dr_ret_str = concat(
            rtf_row(cells, 0),
                    rtf_cell(cell1, 1)
 
    )
 
    return (dr_ret_str)
end

subroutine rtw_row2(rs, cell1, cell2)
    declare dr_ret_string = vc
 
    set dr_ret_str = concat(
            rtf_row(cells, 0),
                    rtf_cell(cell1, 0),
                    rtf_cell(cell2, 1)
 
    )
 
    return (dr_ret_str)
end

subroutine rtw_row3bord(rs, cell1, cell2, cell3)
    declare dr_ret_string = vc
 
    set dr_ret_str = concat(
            rtf_row(cells, 1),  
                    rtf_cell(cell1, 0),
                    rtf_cell(cell2, 0),
                    rtf_cell(cell3, 1)
 
    )
 
    return (dr_ret_str)
end

subroutine rtw_row7(rs, cell1, cell2, cell3, cell4, cell5, cell6, cell7)
    declare dr_ret_string = vc
 
    set dr_ret_str = concat(
            rtf_row(cells, 0),
                    rtf_cell(cell1, 0),
                    rtf_cell(cell2, 0),
                    rtf_cell(cell3, 0),
                    rtf_cell(cell4, 0),
                    rtf_cell(cell5, 0),
                    rtf_cell(cell6, 0),
                    rtf_cell(cell7, 1)
 
    )
 
    return (dr_ret_str)
end

subroutine rtw_row9(rs, cell1, cell2, cell3, cell4, cell5, cell6, cell7, cell8, cell9)
    declare dr_ret_string = vc
 
    set dr_ret_str = concat(
            rtf_row(cells, 0),
                    rtf_cell(cell1, 0),
                    rtf_cell(cell2, 0),
                    rtf_cell(cell3, 0),
                    rtf_cell(cell4, 0),
                    rtf_cell(cell5, 0),
                    rtf_cell(cell6, 0),
                    rtf_cell(cell7, 0),
                    rtf_cell(cell8, 0),
                    rtf_cell(cell9, 1)
 
    )
 
    return (dr_ret_str)
end



 
call echorecord(data)
call echorecord(reply)
call echorecord(drec)
 
call echo(reply->text)
 
end
go
 
