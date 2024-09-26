;~DB~*****************************************************************************************************************************
;    *                      GENERATED MODIFICATION CONTROL LOG                                                                   *
;    *****************************************************************************************************************************
;    *                                                                                                                           *
;    *Mod Date          Engineer    Comment                                                                                      *
;    *--- ----------    --------    ---------------------------------------------------------------------------------------------*
;     001 11/07/2019    saa126      Initial Release     
;     002 06/30/2022    Kim Frazier INC14321993 - rebuild form grid made change necessary   
;     003 01/30/2023    Kim Frazier TASK5666039 - Change to most recent episode of care  
;     004 09/21/2023    KRF         mcga 240088 - Add Scale to CoCM Smart Template      CKI.CODEVALUE!2472183875                 
;     005 07/25/2024    mmm174      MCGA348958  - Flipping this to a encntr type lookback... not the episode of care duration before
;                                   As part of this, I might need to flip this to an encounter level template?
;     006 08/16/2024    mmm174      Prod move adjustments... they said encounter level... but they didn't mean it... 
;                                   they want just COCM form related values... 
;*********************************************************************************************************************************
  drop program 14_st_cocm_target_scale:dba go  ;005 Added dba to these guys... checked prod and build and they were already grp0.
create program 14_st_cocm_target_scale:dba
 
 
/****************************************************************************
*   Includes
****************************************************************************/
 
%i cust_script:0_rtf_template_format.inc



declare set_row(col1_txt = vc, col2_txt = vc, col3_txt = vc, col4_txt = vc) = vc ;003 added
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare tdss_72cd = f8 with protect,constant(102264072.00)
declare gad7s_72cd = f8 with protect,constant(823726295.00)
declare target_scale_72cd = f8 with protect,constant( 712404847.00  ) ;004  712404847.00             72     AUDIT-C Score

declare  rtf_table = vc with protect, noconstant('');003 added
 
;005 I don't think we need this anymore, going to use the 
;declare personId =  f8 with protect,constant(request->person[1]->person_id) ; constant(157127788)
declare rtf_output = vc with protect, noconstant('')
declare cnt = i4
declare num = i4 with noconstant(0),public
declare start = i4 with noconstant(1),public
 
record cells(
    1 cells[*]
        2 size = i4
)

if(validate(reply->text) = 0)
    record reply(
       1 text = vc
          1 status_data
             2 status = c1
             2 subeventstatus[1]
                3 OperationName = c25
                3 OperationStatus = c1
                3 TargetObjectName = c25
                3 TargetObjectValue = vc
    )
endif

free record cocm
record cocm (
    1 eps_beg_dt = dq8
    1 GAD
        2 present_ind = i2
        2 event_cd = f8
        2 baseline = f8
        2 base_dt = vc
        2 base_disp = vc
        2 current = f8
        2 curr_dt = vc
        2 curr_disp = vc
        2 perc_chng = f8
    1 PHQ
        2 present_ind = i2
        2 event_cd = f8
        2 baseline = f8
        2 base_dt = vc
        2 base_disp = vc
        2 current = f8
        2 curr_dt = vc
        2 curr_disp = vc
        2 perc_chng = f8
    1 AudC
        2 present_ind = i2
        2 event_cd = f8
        2 baseline = f8
        2 base_dt = vc
        2 base_disp = vc
        2 current = f8
        2 curr_dt = vc
        2 curr_disp = vc
        2 perc_chng = f8
)





;003 move below declare set_row(col1_txt = vc, col2_txt = vc, col3_txt = vc, col4_txt = vc) = vc
;003 move below declare  rtf_table = vc with protect, noconstant('')
 
;------------------------------------------------------------------------------------------------------------------
;   Get Episode of Care Began Date
;------------------------------------------------------------------------------------------------------------------

;;003 new select
 declare eoc_begin_cd = f8 with protect,constant(2417619091.00)
 declare begin_episode_dt = dq8 with public,protect

 
select into "nl:"
    from clinical_event ce
    , (left join ce_date_result cdr
        on cdr.event_id = ce.event_id
        and cdr.valid_until_dt_tm > cnvtdatetime(curdate,curtime)) 
    plan ce
    where ce.person_id = p_id
    and ce.event_cd = eoc_begin_cd
    and ce.result_status_cd in (25,34,35)
    and ce.valid_until_dt_tm > sysdate
    and ce.event_tag != "In Error"
    AND ce.event_tag != "Date\Time Correction"
        and ce.event_end_dt_tm = (select max(event_end_dt_tm)
                                    from clinical_event 
                                where person_id = ce.person_id
                                and event_cd = eoc_begin_cd
                                and result_status_cd in (25,34,35)
                                and valid_until_dt_tm > sysdate
                                and event_tag != "In Error"
                                AND event_tag != "Date\Time Correction"
                                )
 join cdr
 order by cdr.result_dt_tm ;last/max one found 
 detail
  cocm->eps_beg_dt = cnvtdatetime(cdr.result_dt_tm)
 with nocounter


;------------------------------------------------------------------------------------------------------------------
;   Get Baseline scores
;------------------------------------------------------------------------------------------------------------------
select into "nl:"

  from clinical_event ce

 where ce.person_id         =  p_id
   and ce.event_cd          in (gad7s_72cd, tdss_72cd, target_scale_72cd)
   and ce.valid_until_dt_tm >= cnvtdatetime(curdate, curtime3)
   and ce.event_tag         != 'In Error'
   ;We only want results from the day of the EOC visit.
   and ce.event_end_dt_tm   >= cnvtdatetime(cocm->eps_beg_dt)

order by ce.event_cd, ce.event_end_dt_tm
head ce.event_cd
    
    case(ce.event_cd)
        of gad7s_72cd:
            cocm->GAD.present_ind  = 1
            cocm->GAD.event_cd     = ce.event_cd
            cocm->GAD.baseline     = cnvtreal(ce.result_val)
            cocm->GAD.base_dt      = format(ce.event_end_dt_tm,"MM/DD/YY")
            cocm->GAD.base_disp    = build2(trim(format(cocm->GAD.baseline,"#####.##"), 3)
                                           ," (", trim(cocm->GAD.base_dt,3), ")")
        
        of tdss_72cd:
            cocm->PHQ.present_ind  = 1
            cocm->PHQ.event_cd     = ce.event_cd
            cocm->PHQ.baseline     = cnvtreal(ce.result_val)
            cocm->PHQ.base_dt      = format(ce.event_end_dt_tm,"MM/DD/YY")
            cocm->PHQ.base_disp    = build2(trim(format(cocm->PHQ.baseline,"#####.##"), 3)
                                           ," (", trim(cocm->PHQ.base_dt,3), ")")
        
        of target_scale_72cd:
            cocm->AudC.present_ind = 1
            cocm->AudC.event_cd    = ce.event_cd
            cocm->AudC.baseline    = cnvtreal(ce.result_val)
            cocm->AudC.base_dt     = format(ce.event_end_dt_tm,"MM/DD/YY")
            cocm->AudC.base_disp   = build2(trim(format(cocm->AudC.baseline,"#####.##"), 3)
                                           ," (", trim(cocm->AudC.base_dt,3), ")")

    endcase

with nocounter
 
;------------------------------------------------------------------------------------------------------------------
;   Get scores
;------------------------------------------------------------------------------------------------------------------
select into 'nl:'

  from dcp_forms_activity      d
     , dcp_forms_activity_comp dfc
     , clinical_event          ce1
     , clinical_event          ce2
     , clinical_event          ce3

  plan d
   where d.person_id               =  p_id
     and d.active_ind              =  1
     ;PROD
     and d.dcp_forms_ref_id        in ( 25562326477.0    ; CoCM Initial Visit
                                      , 17187876873.0    ; COCM Stop Time
                                      , 25562361699.0    ; CoCM Follow Up Visit
                                      , 27852023149.0    ; CoCM Non-Appointment Activity
                                      )
     ;BUILD
     ;and d.dcp_forms_ref_id        in ( 24202552913.0    ; CoCM Initial Visit
     ;                                 , 17187876873.0    ; COCM Stop Time
     ;                                 , 24202571835.0    ; CoCM Follow Up Visit
     ;                                 , 24216264555.0)   ; CoCM Non-Appointment Activity
     and d.form_status_cd          in (25.00, 34.00, 35.00)

  join dfc
   where dfc.dcp_forms_activity_id =  d.dcp_forms_activity_id; ( 6560997569.00,6560490443.00)
     and dfc.parent_entity_name    =  'CLINICAL_EVENT'
  
  ;Form
  join ce1
   where ce1.parent_event_id       =  dfc.parent_entity_id
     and ce1.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.00')

  ;Section
  join ce2
   where ce2.parent_event_id       =  ce1.event_id
     and ce2.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.00')
     and ce2.event_end_dt_tm between  cnvtdatetime('01-JAN-1970 0000') and cnvtdatetime(curdate,curtime3)
     and ce2.result_status_cd      in (25.00, 33.00, 35.00)

  ;Result
  join ce3
   where ce3.parent_event_id       =  ce2.event_id
     and ce3.view_level            =  1
     and ce3.valid_until_dt_tm     >=  cnvtdatetime(curdate,curtime3)
     and ce3.event_tag             != 'In Error'
     and ce3.event_cd              in (gad7s_72cd, tdss_72cd, target_scale_72cd)
     and ce3.event_end_dt_tm       >= cnvtdatetime(cocm->eps_beg_dt)

order by ce3.event_cd, ce3.event_end_dt_tm desc
head ce3.event_cd
    
    case(ce3.event_cd)
        of gad7s_72cd:
            cocm->GAD.present_ind = 1
            cocm->GAD.current     = cnvtreal(ce3.result_val)
            cocm->GAD.curr_dt     = format(ce3.event_end_dt_tm,"MM/DD/YY")
            cocm->GAD.curr_disp   = build2(trim(format(cocm->GAD.current,"#####.##"), 3)
                                          ," (", trim(cocm->GAD.curr_dt,3), ")")
            
            if(cocm->GAD.baseline > 0)
                cocm->GAD.perc_chng = (((cocm->GAD.current - cocm->GAD.baseline)
                                         / cocm->GAD.baseline 
                                        ) * 100
                                       )
            endif
        
        of tdss_72cd:
            cocm->PHQ.present_ind = 1
            cocm->PHQ.current     = cnvtreal(ce3.result_val)
            cocm->PHQ.curr_dt     = format(ce3.event_end_dt_tm,"MM/DD/YY")
            cocm->PHQ.curr_disp   = build2(trim(format(cocm->PHQ.current,"#####.##"), 3)
                                          ," (", trim(cocm->PHQ.curr_dt,3), ")")
            
            if(cocm->PHQ.baseline > 0)
                cocm->PHQ.perc_chng = (((cocm->PHQ.current - cocm->PHQ.baseline)
                                         / cocm->PHQ.baseline 
                                        ) * 100
                                       )
            endif
        
        of target_scale_72cd:
            cocm->AudC.present_ind = 1
            cocm->AudC.current     = cnvtreal(ce3.result_val)
            cocm->AudC.curr_dt     = format(ce3.event_end_dt_tm,"MM/DD/YY")
            cocm->AudC.curr_disp   = build2(trim(format(cocm->AudC.current,"#####.##"), 3)
                                           ," (", trim(cocm->AudC.curr_dt,3), ")")
            
            if(cocm->AudC.baseline > 0)
                cocm->AudC.perc_chng = (((cocm->AudC.current - cocm->AudC.baseline)
                                         / cocm->AudC.baseline 
                                        ) * 100
                                       )
            endif

    endcase

with nocounter



if(   cocm->PHQ.present_ind = 1
   or cocm->GAD.present_ind = 1
   or cocm->AudC.present_ind = 1
  )
    call echorecord(cocm)
    set stat = alterlist(cells->cells,4)
    set cells->cells[1]->size = 870
    set cells->cells[2]->size = 2850
    set cells->cells[3]->size = 4600
    set cells->cells[4]->size = 5990

    set rtf_table = build2(rh2b, set_row(" Scale"," Baseline", " Current"," Change (%)"))
    set rtf_table = build2(rtf_table, wr)

    set rtf_table = notrim(build2(rtf_table,set_row( "PHQ-9", cocm->PHQ.base_disp, cocm->PHQ.curr_disp,
                                                              trim(build2(trim(format(cocm->PHQ.perc_chng,"#####.##"),3)),3)
                                                   )
                                 )
                          )

    set rtf_table = notrim(build2(rtf_table,set_row( "GAD-7", cocm->GAD.base_disp, cocm->GAD.curr_disp,
                                                              trim(build2(trim(format(cocm->GAD.perc_chng,"#####.##"),3)),3)
                                                   )
                                 )
                          )

    set rtf_table = notrim(build2(rtf_table,set_row( "Audit-C", cocm->AudC.base_disp, cocm->AudC.curr_disp,
                                                                trim(build2(trim(format(cocm->AudC.perc_chng,"#####.##"),3)),3)
                                                   )
                                 )
                          )
    
    
    set rtf_table= build2(rhead,rtf_table,rtfeof)
    call echo(rtf_table)
    set reply->text = rtf_table
else
    set reply->text = build2(rhead,build2("No Qualifying data to display ",cocm->eps_beg_dt),rtfeof)
endif
;005 Don't need these either.
;else
;    set reply->text = build2(rhead,"No Qualifying data to display",rtfeof)
;endif
 
set drec->status_data->status = "S"
set reply->status_data->status = "S"
 
subroutine set_row(col1_txt, col2_txt, col3_txt, col4_txt)
    declare row_str = vc
    set row_str = concat(
        rtf_row(cells, 1),
        rtf_cell(col1_txt, 0),
        rtf_cell(col2_txt, 0),
        rtf_cell(col3_txt, 0),
        rtf_cell(col4_txt, 1)
    )
    ;call echo(row_str)
    return (row_str)
end
 
 
end
go
 
;execute 14_st_cocm_target_scale go