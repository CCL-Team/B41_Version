/*************************************************************************
 Program Title:   Pain Catastrophizing Scale (PCS) Responses
 
 Object name:     14_st_pain_cata_scale_res
 Source file:     14_st_pain_cata_scale_res.prg
 
 Purpose:
 
 Tables read:
 
 Executed from:
 
 Special Notes:   
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2024-09-19 Michael Mayes        345442 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_pain_cata_scale_res:dba go
create program 14_st_pain_cata_scale_res:dba

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
    1 form_dt_tm           = dq8
    1 form_dt_tm_txt       = vc
    
    1 res_cnt              = i2
    1 res[*]
        2 event_id         = f8
        2 result_title_txt = vc
        2 result_txt       = vc
)

record cells(
    1 cells[*]
        2 size = i4
)


 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare pcsr_row(rs = vc(ref), cell1 = vc, cell2 = vc) = vc
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header            = vc  with protect, noconstant(' ')
declare tmp_str           = vc  with protect, noconstant(' ')
                          
declare grp_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING', 53, 'GRP'     ))
declare act_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ACTIVE'  ))
declare mod_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'MODIFIED'))
declare auth_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'AUTH'    ))
declare alt_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',  8, 'ALTERED' ))
                          
declare pcs_es_cd         = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 93, 'PAINCATASTROPHIZINGSCALEPCS' ))

declare pcs_tot_score_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSTOTAL' ))
declare pcs_rum_score_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSRUMINATIONSCORE' ))
declare pcs_mag_score_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSMAGNIFICATIONSCORE' ))
declare pcs_hlp_score_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSHELPLESSNESSSCORE' ))

declare worry_cd   = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSIWORRYALLTHETIME'           ))
declare goon_cd    = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSIFEELICANTGOON'             ))
declare terr_cd    = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSITSTERRIBLE'                ))
declare awe_cd     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSITSAWFUL'                   ))
declare stand_cd   = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSIFEELICANTSTANDIT'          ))
declare afraid_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSIBECOMEAFRAIDTHEPAIN'       ))
declare think_cd   = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSIKEEPTHINKING'              ))
declare anx_cd     = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSIANXIOUSLYWANTTHEPAINTOGO'  ))
declare mind_cd    = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSICANTSEEMTOKEEPITOUT'       ))
declare hurt_cd    = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSIKEEPTHINKINGHOWMUCHITHURTS'))
declare stop_cd    = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSIKEEPTHINKINGABOUTHOWBADLY' ))
declare intens_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSTHEREISNOTHINGICANDO'       ))
declare serious_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY', 72, 'PCSIWONDER'                    ))

declare temp_score = i4  with protect, noconstant(0)
declare pos        = i4  with protect, noconstant(0)
declare looper     = i4  with protect, noconstant(0)

 
declare lcv_dt_tm    = dq8 with protect
;declare looper       = i4  with protect
 

/**************************************************************
; DVDev Start Coding
**************************************************************/


/***********************************************************************
DESCRIPTION:  Find LCV results
***********************************************************************/
select into 'nl:'
  from dcp_forms_ref           dfr
     , dcp_forms_activity      dfa
     , dcp_forms_activity_comp dfac
     , clinical_event          ce    ;Doc
     , clinical_event          ce2   ;form
     , clinical_event          ce3   ;values

 where dfr.description            =  'Pain Catastrophizing Scale (PCS)'
   and dfr.active_ind             =  1
   and dfr.beg_effective_dt_tm    <= cnvtdatetime(curdate, curtime3)
   and dfr.end_effective_dt_tm    >= cnvtdatetime(curdate, curtime3)

   and dfa.encntr_id              =  e_id
   and dfa.dcp_forms_ref_id       =  dfr.dcp_forms_ref_id
   and dfa.form_status_cd         in (act_cd, mod_cd, auth_cd, alt_cd)
   and dfa.active_ind             =  1

   and dfac.dcp_forms_activity_id = dfa.dcp_forms_activity_id

   and ce.event_id                =  dfac.parent_entity_id
   and ce.result_status_cd        in (act_cd, mod_cd, auth_cd, alt_cd)
   and ce.valid_until_dt_tm       >= cnvtdatetime(curdate, curtime3)

   and ce2.parent_event_id        =  ce.event_id
   and ce2.result_status_cd       in (act_cd, mod_cd, auth_cd, alt_cd)
   and ce2.valid_until_dt_tm      >= cnvtdatetime(curdate, curtime3)

   and ce3.parent_event_id        =  ce2.event_id
   and ce3.result_status_cd       in (act_cd, mod_cd, auth_cd, alt_cd)
   and ce3.valid_until_dt_tm      >= cnvtdatetime(curdate, curtime3)
   and ce3.event_cd               in ( worry_cd  , goon_cd   
                                     , terr_cd   , awe_cd    , stand_cd  , afraid_cd 
                                     , think_cd  , anx_cd    , mind_cd   , hurt_cd   
                                     , stop_cd   , intens_cd , serious_cd
                                     )

order by dfa.form_dt_tm desc, ce3.collating_seq, ce3.event_cd 
head report
    data->form_dt_tm     = dfa.form_dt_tm
    data->form_dt_tm_txt = format(dfa.form_dt_tm, 'MM/DD/YYYY HH:MM;;q')
    
    lcv_dt_tm = ce3.event_end_dt_tm
    
    stat = alterlist(data->res, 13)
    
    for(looper = 1 to size(data->res, 5))
        data->res[looper]->result_title_txt = format(cnvtstring(looper),'##.;R;')
    endfor

head ce3.event_cd 

    if(ce3.event_end_dt_tm = lcv_dt_tm)
        
        case(ce3.event_cd)
        of worry_cd  : pos = 1
        of goon_cd   : pos = 2
        of terr_cd   : pos = 3
        of awe_cd    : pos = 4
        of stand_cd  : pos = 5
        of afraid_cd : pos = 6
        of think_cd  : pos = 7
        of anx_cd    : pos = 8
        of mind_cd   : pos = 9
        of hurt_cd   : pos = 10
        of stop_cd   : pos = 11
        of intens_cd : pos = 12
        of serious_cd: pos = 13
         endcase
        
        data->res[pos]->result_title_txt = concat( data->res[pos]->result_title_txt, ' '
                                                 , replace(trim(ce3.event_title_text, 3), 'PCS ', '')
                                                 )
        
        data->res[pos]->event_id         = ce3.event_id
        data->res[pos]->result_txt       = trim(ce3.result_val, 3)
        
    endif
    
with nocounter
 
;Presentation
 
 

;RTF header
set header = notrim(build2(rhead))

;Set up table information
 
set stat = alterlist(cells->cells, 2)
 
set cells->cells[ 1]->size =  3500
set cells->cells[ 2]->size =  6000


if(data->form_dt_tm_txt > ' ')
    set tmp_str = notrim(build2(rh2bu, 'Pain Catastrophizing Scale (PCS)', wr, ' (', data->form_dt_tm_txt, ')', reol))
    
    for(looper = 1 to size(data->res, 5))
        call echo(looper)
        set tmp_str = concat(tmp_str, pcsr_row(cells, data->res[looper]->result_title_txt,
                                                      data->res[looper]->result_txt
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
subroutine pcsr_row(rs, cell1, cell2)
    declare pcsr_ret_string = vc
 
    set pcsr_ret_str = concat(
            rtf_row(cells, 0),
                    rtf_cell(cell1, 0),
                    rtf_cell(cell2, 1)
 
    )
 
    return (pcsr_ret_str)
end


#exit_script
call echorecord(data)
call echorecord(reply)
call echorecord(drec)
 
call echo(reply->text)
 
end
go
 
