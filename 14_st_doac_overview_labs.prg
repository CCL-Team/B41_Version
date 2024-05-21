/*************************************************************************
 Program Title:   DOAC Overview Labs
 
 Object name:     14_st_doac_overview_labs
 Source file:     14_st_doac_overview_labs.prg
 
 Purpose:
 
 Tables read:
 
 Executed from:
 
 Special Notes:   Told to emulate 14_st_war_pat_assess for this.  Going 
                  that route.
                  
                  Also same work effort as the Anticoagulation Therapy Management ST
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA     Comment
--- ---------- -------------------- -------- -----------------------------
001 04/27/2023 Michael Mayes        236959   (SCTASK0010959) Initial release
002 01/30/2024 Michael Mayes        344980   (SCTASK0067089) Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_doac_overview_labs:dba go
create program 14_st_doac_overview_labs:dba 

%i cust_script:0_rtf_template_format.inc
 
/*record request(
   1 visit[*]
      2 encntr_id = f8
   1 person[*]
      2 person_id = f8
)*/
 
 
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
 
record cells(
    1 cells[*]
        2 size = i4
)
 
record results(
    1 hgb_cnt                 = i4
    1 hgb[4]
        2 result              = vc
        2 result_unit         = vc
        2 result_dt_txt       = vc
        2 result_normalcy_ind = i2
        2 result_normalcy     = vc
        2 result_rtf          = vc
    
    1 hct_cnt                 = i4
    1 hct[4]
        2 result              = vc
        2 result_unit         = vc
        2 result_dt_txt       = vc
        2 result_normalcy_ind = i2
        2 result_normalcy     = vc
        2 result_rtf          = vc
    
    1 plate_cnt               = i4
    1 plate[4]
        2 result              = vc
        2 result_unit         = vc
        2 result_dt_txt       = vc
        2 result_normalcy_ind = i2
        2 result_normalcy     = vc
        2 result_rtf          = vc
    
    1 creat_cnt               = i4
    1 creat[4]
        2 result              = vc
        2 result_unit         = vc
        2 result_dt_txt       = vc
        2 result_normalcy_ind = i2
        2 result_normalcy     = vc
        2 result_rtf          = vc
    
    1 creat_clear_cnt         = i4
    1 creat_clear[4]
        2 result              = vc
        2 result_unit         = vc
        2 result_dt_txt       = vc
        2 result_normalcy_ind = i2
        2 result_normalcy     = vc
        2 result_rtf          = vc
    
    1 bili_cnt                = i4
    1 bili[4]
        2 result              = vc
        2 result_unit         = vc
        2 result_dt_txt       = vc
        2 result_normalcy_ind = i2
        2 result_normalcy     = vc
        2 result_rtf          = vc
    
    1 alt_cnt                 = i4
    1 alt[4]
        2 result              = vc
        2 result_unit         = vc
        2 result_dt_txt       = vc
        2 result_normalcy_ind = i2
        2 result_normalcy     = vc
        2 result_rtf          = vc
    
    1 ast_cnt                 = i4
    1 ast[4]
        2 result              = vc
        2 result_unit         = vc
        2 result_dt_txt       = vc
        2 result_normalcy_ind = i2
        2 result_normalcy     = vc
        2 result_rtf          = vc
    
    1 dosing_weight           = vc
    1 dosing_weight_unit      = vc
    1 dosing_weight_dt_tm     = dq8
    1 dosing_weight_dt_tm_txt = vc
        
)
 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare doac_row (rs = vc(ref), cell1 = vc, cell2 = vc, cell3 = vc, cell4 = vc) = vc
declare doac_head_row (rs = vc(ref), cell1 = vc, cell2 = vc, cell3 = vc, cell4 = vc) = vc
declare result_to_rtf(result = vc, unit = vc, date = vc, norm = vc, norm_ind = i2) = vc
 
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header   = vc  with protect, noconstant(' ')
declare tmp_str  = vc  with protect, noconstant(' ')
                 
declare act_cd   = f8  with protect, constant(uar_get_code_by(    'MEANING',  8, 'ACTIVE'   ))
declare mod_cd   = f8  with protect, constant(uar_get_code_by(    'MEANING',  8, 'MODIFIED' ))
declare auth_cd  = f8  with protect, constant(uar_get_code_by(    'MEANING',  8, 'AUTH'     ))
declare alt_cd   = f8  with protect, constant(uar_get_code_by(    'MEANING',  8, 'ALTERED'  ))
                                                                             

declare hgb1_cd         = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'HGB'                            ))
declare hbg2_cd         = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'HEMOGLOBIN'                     ))
declare hgb3_cd         = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'HEMOGLOBINTRANSCRIBED'          ))

declare hct1_cd         = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'HCT'                            ))
declare hct2_cd         = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'HEMATOCRIT'                     ))
declare hct3_cd         = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'HEMATOCRITTRANSCRIBED'          ))

declare plate1_cd       = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'PLATELET'                       ))
declare plate2_cd       = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'PLATELETSTRANSCRIBED'           ))

declare creat1_cd       = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'CREATININE'                     ))
declare creat2_cd       = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'CREATININELEVEL'                ))
declare creat3_cd       = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'CREATININELEVELTRANSCRIBED'     ))  ;002

declare creat_clear1_cd = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'ESTIMATEDCREATININECLEARANCE'   ))
declare creat_clear2_cd = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'ESTCRCL'                        ))

declare bili1_cd        = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'BILITOTAL'                      ))
declare bili2_cd        = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'TOTALBILIRUBIN'                 ))
declare bili3_cd        = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'BILIRUBINTOTALTRANSCRIBED'      ))  ;002

declare alt1_cd         = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'ALT'                            ))
declare alt2_cd         = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'ALTSGPTTRANSCRIBED'             ))

declare ast1_cd         = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'AST'                            ))
declare ast2_cd         = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'ASTSGOTTRANSCRIBED'             ))

declare dose_weight_cd  = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'WEIGHTDOSING'                   ))


;declare looper       = i4  with protect
 
/**************************************************************
; DVDev Start Coding
**************************************************************/
call echo(build('hgb1_cd        :', hgb1_cd        ))
call echo(build('hbg2_cd        :', hbg2_cd        ))
call echo(build('hgb3_cd        :', hgb3_cd        ))
call echo(build('hct1_cd        :', hct1_cd        ))
call echo(build('hct2_cd        :', hct2_cd        ))
call echo(build('hct3_cd        :', hct3_cd        ))
call echo(build('plate1_cd      :', plate1_cd      ))
call echo(build('plate2_cd      :', plate2_cd      ))
call echo(build('creat1_cd      :', creat1_cd      ))
call echo(build('creat2_cd      :', creat2_cd      ))
call echo(build('creat3_cd      :', creat3_cd      ))  ;002
call echo(build('creat_clear1_cd:', creat_clear1_cd))
call echo(build('creat_clear2_cd:', creat_clear2_cd))
call echo(build('bili1_cd       :', bili1_cd       ))
call echo(build('bili2_cd       :', bili2_cd       ))
call echo(build('bili3_cd       :', bili3_cd       ))  ;002
call echo(build('alt1_cd        :', alt1_cd        ))
call echo(build('alt2_cd        :', alt2_cd        ))
call echo(build('ast1_cd        :', ast1_cd        ))
call echo(build('ast2_cd        :', ast2_cd        ))
call echo(build('dose_weight_cd :', dose_weight_cd ))




/***********************************************************************
DESCRIPTION: Find most recent results
***********************************************************************/
select into 'nl:'
  from clinical_event ce
 where ce.person_id         =  p_id
   and ce.event_class_cd    =  233.00  ;NUM
   and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, alt_cd)
   and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
   and ce.event_cd          in ( hgb1_cd        , hbg2_cd        , hgb3_cd    
                               , hct1_cd        , hct2_cd        , hct3_cd    
                               , plate1_cd      , plate2_cd      
                               , creat1_cd      , creat2_cd      , creat3_cd  ;002
                               , creat_clear1_cd, creat_clear2_cd
                               , bili1_cd       , bili2_cd       , bili3_cd  ;002
                               , alt1_cd        , alt2_cd            
                               , ast1_cd        , ast2_cd        
                               , dose_weight_cd
                               )
order by ce.event_cd, ce.event_end_dt_tm desc
detail
    case(ce.event_cd)
    
    of hgb1_cd        :
    of hbg2_cd        :
    of hgb3_cd        :
        
        if(results->hgb_cnt < 4)
            results->hgb_cnt = results->hgb_cnt + 1
            
            results->hgb[results->hgb_cnt]->result              = trim(ce.result_val, 3)
            results->hgb[results->hgb_cnt]->result_unit         = uar_get_code_display(ce.result_units_cd)
            results->hgb[results->hgb_cnt]->result_dt_txt       = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm")
            results->hgb[results->hgb_cnt]->result_normalcy     = uar_get_code_display(ce.normalcy_cd)
            
            if(results->hgb[results->hgb_cnt]->result_normalcy > ' ')
                results->hgb[results->hgb_cnt]->result_normalcy_ind = 1
            endif
            
        endif
    
    of hct1_cd        :
    of hct2_cd        :
    of hct3_cd        :
        if(results->hct_cnt < 4)
            results->hct_cnt = results->hct_cnt + 1
            
            results->hct[results->hct_cnt]->result              = trim(ce.result_val, 3)
            results->hct[results->hct_cnt]->result_unit         = uar_get_code_display(ce.result_units_cd)
            results->hct[results->hct_cnt]->result_dt_txt       = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm")
            results->hct[results->hct_cnt]->result_normalcy     = uar_get_code_display(ce.normalcy_cd)
            
            if(results->hct[results->hct_cnt]->result_normalcy > ' ')
                results->hct[results->hct_cnt]->result_normalcy_ind = 1
            endif
        
        endif
    
    of plate1_cd      :
    of plate2_cd      :
        if(results->plate_cnt < 4)
            results->plate_cnt = results->plate_cnt + 1
            
            results->plate[results->plate_cnt]->result              = trim(ce.result_val, 3)
            results->plate[results->plate_cnt]->result_unit         = uar_get_code_display(ce.result_units_cd)
            results->plate[results->plate_cnt]->result_dt_txt       = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm")
            results->plate[results->plate_cnt]->result_normalcy     = uar_get_code_display(ce.normalcy_cd)
            
            if(results->plate[results->plate_cnt]->result_normalcy > ' ')
                results->plate[results->plate_cnt]->result_normalcy_ind = 1
            endif
        
        endif
    
    of creat1_cd      :
    of creat2_cd      :
    of creat3_cd      :
        if(results->creat_cnt < 4)
            results->creat_cnt = results->creat_cnt + 1
            
            results->creat[results->creat_cnt]->result              = trim(ce.result_val, 3)
            results->creat[results->creat_cnt]->result_unit         = uar_get_code_display(ce.result_units_cd)
            results->creat[results->creat_cnt]->result_dt_txt       = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm")
            results->creat[results->creat_cnt]->result_normalcy     = uar_get_code_display(ce.normalcy_cd)
            
            if(results->creat[results->creat_cnt]->result_normalcy > ' ')
                results->creat[results->creat_cnt]->result_normalcy_ind = 1
            endif
        
        endif
    
    of creat_clear1_cd:
    of creat_clear2_cd:
        if(results->creat_clear_cnt < 4)
            results->creat_clear_cnt = results->creat_clear_cnt + 1
        
            results->creat_clear[results->creat_clear_cnt]->result              = trim(ce.result_val, 3)
            results->creat_clear[results->creat_clear_cnt]->result_unit         = uar_get_code_display(ce.result_units_cd)
            results->creat_clear[results->creat_clear_cnt]->result_dt_txt       = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm")
            results->creat_clear[results->creat_clear_cnt]->result_normalcy     = uar_get_code_display(ce.normalcy_cd)
            
            if(results->creat_clear[results->creat_clear_cnt]->result_normalcy > ' ')
                results->creat_clear[results->creat_clear_cnt]->result_normalcy_ind = 1
            endif
        
        endif
    
    of bili1_cd       :
    of bili2_cd       :
    of bili3_cd       :
        if(results->bili_cnt < 4)
            results->bili_cnt = results->bili_cnt + 1
        
            results->bili[results->bili_cnt]->result              = trim(ce.result_val, 3)
            results->bili[results->bili_cnt]->result_unit         = uar_get_code_display(ce.result_units_cd)
            results->bili[results->bili_cnt]->result_dt_txt       = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm")
            results->bili[results->bili_cnt]->result_normalcy     = uar_get_code_display(ce.normalcy_cd)
            
            if(results->bili[results->bili_cnt]->result_normalcy > ' ')
                results->bili[results->bili_cnt]->result_normalcy_ind = 1
            endif
        
        endif
        
    of alt1_cd        :
    of alt2_cd        :
        if(results->alt_cnt < 4)
            results->alt_cnt = results->alt_cnt + 1
        
            results->alt[results->alt_cnt]->result              = trim(ce.result_val, 3)
            results->alt[results->alt_cnt]->result_unit         = uar_get_code_display(ce.result_units_cd)
            results->alt[results->alt_cnt]->result_dt_txt       = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm")
            results->alt[results->alt_cnt]->result_normalcy     = uar_get_code_display(ce.normalcy_cd)
            
            if(results->alt[results->alt_cnt]->result_normalcy > ' ')
                results->alt[results->alt_cnt]->result_normalcy_ind = 1
            endif
        
        endif
    
    of ast1_cd        :
    of ast2_cd        :
        if(results->ast_cnt < 4)
            results->ast_cnt = results->ast_cnt + 1
        
            results->ast[results->ast_cnt]->result              = trim(ce.result_val, 3)
            results->ast[results->ast_cnt]->result_unit         = uar_get_code_display(ce.result_units_cd)
            results->ast[results->ast_cnt]->result_dt_txt       = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm")
            results->ast[results->ast_cnt]->result_normalcy     = uar_get_code_display(ce.normalcy_cd)
            
            if(results->ast[results->ast_cnt]->result_normalcy > ' ')
                results->ast[results->ast_cnt]->result_normalcy_ind = 1
            endif
        
        endif
    
    of dose_weight_cd:
        if(results->dosing_weight = '')
            results->dosing_weight              = trim(ce.result_val, 3)
            results->dosing_weight_unit         = uar_get_code_display(ce.result_units_cd)
            results->dosing_weight_dt_tm        = ce.event_end_dt_tm
            results->dosing_weight_dt_tm_txt    = format(ce.event_end_dt_tm, "mm/dd/yyyy hh:mm")

        endif
        
    endcase

with nocounter


;prebuilding the RTF
for(looper = 1 to 4)
    set results->hgb[looper]->result_rtf = notrim(result_to_rtf( results->hgb[looper]->result
                                                               , results->hgb[looper]->result_unit
                                                               , results->hgb[looper]->result_dt_txt
                                                               , results->hgb[looper]->result_normalcy
                                                               , results->hgb[looper]->result_normalcy_ind
                                                               )
                                                 )             
                                                        
    set results->hct[looper]->result_rtf = notrim(result_to_rtf( results->hct[looper]->result
                                                               , results->hct[looper]->result_unit
                                                               , results->hct[looper]->result_dt_txt
                                                               , results->hct[looper]->result_normalcy
                                                               , results->hct[looper]->result_normalcy_ind
                                                               )
                                                 )             
                                                        
    set results->plate[looper]->result_rtf = notrim(result_to_rtf( results->plate[looper]->result
                                                                 , results->plate[looper]->result_unit
                                                                 , results->plate[looper]->result_dt_txt
                                                                 , results->plate[looper]->result_normalcy
                                                                 , results->plate[looper]->result_normalcy_ind
                                                                 )
                                                   )           
                                                        
    set results->creat[looper]->result_rtf = notrim(result_to_rtf( results->creat[looper]->result
                                                                 , results->creat[looper]->result_unit
                                                                 , results->creat[looper]->result_dt_txt
                                                                 , results->creat[looper]->result_normalcy
                                                                 , results->creat[looper]->result_normalcy_ind
                                                                 )
                                                   )           
                                                        
    set results->creat_clear[looper]->result_rtf = notrim(result_to_rtf( results->creat_clear[looper]->result
                                                                , results->creat_clear[looper]->result_unit
                                                                , results->creat_clear[looper]->result_dt_txt
                                                                , results->creat_clear[looper]->result_normalcy
                                                                , results->creat_clear[looper]->result_normalcy_ind
                                                                )
                                                         )
                                                        
                                                        
    set results->bili[looper]->result_rtf = notrim(result_to_rtf( results->bili[looper]->result
                                                                , results->bili[looper]->result_unit
                                                                , results->bili[looper]->result_dt_txt
                                                                , results->bili[looper]->result_normalcy
                                                                , results->bili[looper]->result_normalcy_ind
                                                                )
                                                  )            
                                                        
    set results->alt[looper]->result_rtf = notrim(result_to_rtf( results->alt[looper]->result
                                                               , results->alt[looper]->result_unit
                                                               , results->alt[looper]->result_dt_txt
                                                               , results->alt[looper]->result_normalcy
                                                               , results->alt[looper]->result_normalcy_ind
                                                               )
                                                 )             
                                                        
    set results->ast[looper]->result_rtf = notrim(result_to_rtf( results->ast[looper]->result
                                                               , results->ast[looper]->result_unit
                                                               , results->ast[looper]->result_dt_txt
                                                               , results->ast[looper]->result_normalcy
                                                               , results->ast[looper]->result_normalcy_ind
                                                               )
                                                 )
endfor





 
;Presentation
;Set up table information
 
set stat = alterlist(cells->cells, 4)
 
set cells->cells[ 1]->size =  4000
set cells->cells[ 2]->size =  8000
set cells->cells[ 3]->size = 12000
set cells->cells[ 4]->size = 16000
 
 
;RTF header
set header = notrim(build2(rhead, wr))
 
set tmp_str = doac_head_row(cells, ' HGB', ' HCT', ' Platelets', ' Creatinine')
for(looper = 1 to 4)
    set tmp_str = notrim(build2( tmp_str
                               , doac_row(cells, results->hgb[looper]->result_rtf
                                               , results->hct[looper]->result_rtf
                                               , results->plate[looper]->result_rtf
                                               , results->creat[looper]->result_rtf
                                               )
                               )
                        )
endfor

set tmp_str = notrim(build2( tmp_str, '\pard', reol, reol))

set tmp_str =  notrim(build2( tmp_str,doac_head_row(cells, ' Est. CrCl', ' Bilirubin', ' ALT', ' AST')))
for(looper = 1 to 4)
    set tmp_str = notrim(build2( tmp_str
                               , doac_row(cells, results->creat_clear[looper]->result_rtf
                                               , results->bili[looper]->result_rtf
                                               , results->alt[looper]->result_rtf
                                               , results->ast[looper]->result_rtf
                                               )
                               )
                        )
endfor


set tmp_str = notrim(build2( tmp_str, '\pard', reol, reol))


if(results->dosing_weight != '')
    set tmp_str = notrim(build2( tmp_str
                               , 'Dosing Weight: '
                               , results->dosing_weight          , ' '
                               , results->dosing_weight_unit     , ' ('
                               , results->dosing_weight_dt_tm_txt, ')'
                               )
                        )
else
    set tmp_str = notrim(build2( tmp_str
                               , 'Dosing Weight: No result found.'
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
subroutine doac_row(rs, cell1, cell2, cell3, cell4)
    declare dr_ret_string = vc
 
    set dr_ret_str = concat(
            rtf_row(rs, 1),
                    rtf_cell(cell1, 0),
                    rtf_cell(cell2, 0),
                    rtf_cell(cell3, 0),
                    rtf_cell(cell4, 1)
 
    )
 
    return (dr_ret_str)
end


subroutine doac_head_row(rs, cell1, cell2, cell3, cell4)
    declare dr_ret_string = vc
 
    set dr_ret_str = concat(
            rtf_row(rs, 1),
                    rtf_cell(notrim(build2(wb,cell1,wr)), 0),
                    rtf_cell(notrim(build2(wb,cell2,wr)), 0),
                    rtf_cell(notrim(build2(wb,cell3,wr)), 0),
                    rtf_cell(notrim(build2(wb,cell4,wr)), 1)
 
    )
 
    return (dr_ret_str)
end


subroutine result_to_rtf(result, unit, date, norm, norm_ind)
    declare rtr_ret   = vc
    declare nospacred = vc  with protect, constant(notrim('\cf5 '))
    
    if(result <= ' ')
        set rtr_ret = notrim(' ')
        
        return(rtr_ret)
    endif
    
    
    if(norm_ind = 1)
        set rtr_ret = notrim(build2( ' '
                                   , nospacred , result   , ' '
                                               , unit     , ' '
                                   , wblack    , norm     , ' ('
                                               , date     , ')'
                                   )
                            )
                                   
    else
        set rtr_ret = notrim(build2( ' '
                                   , result   , ' '
                                   , unit     , ' '
                                   , norm     , ' ('
                                   , date     , ')'
                                   )
                            )
    endif
    
    return(rtr_ret)
    
end


#exit_program
 
call echorecord(results)
call echorecord(reply)
call echorecord(drec)
 
call echo(reply->text)
 
end
go
 