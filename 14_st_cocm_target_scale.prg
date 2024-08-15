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
;*********************************************************************************************************************************
  drop program 14_st_cocm_target_scale:dba go  ;005 Added dba to these guys... checked prod and build and they were already grp0.
create program 14_st_cocm_target_scale:dba
 
 
/****************************************************************************
*   Includes
****************************************************************************/
 
%i cust_script:0_rtf_template_format.inc
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare tdss_72cd = f8 with protect,constant(102264072.00)
declare gad7s_72cd = f8 with protect,constant(823726295.00)
declare target_scale_72cd = f8 with protect,constant( 712404847.00  ) ;004  712404847.00             72     AUDIT-C Score

 
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
free record cocm
record cocm (
    1 eps_beg_dt = dq8
    1 scales[*]
        2 event_cd = f8
        2 name = vc
        2 baseline = f8
        2 base_dt = vc
        2 current = f8
        2 curr_dt = vc
        2 perc_chng = f8
    )
 
 
;003 move below declare set_row(col1_txt = vc, col2_txt = vc, col3_txt = vc, col4_txt = vc) = vc
;003 move below declare  rtf_table = vc with protect, noconstant('')
 
;------------------------------------------------------------------------------------------------------------------
;   Get Episode of Care Began Date
;------------------------------------------------------------------------------------------------------------------

;005-> Now we don't even need a select eh?
;
;;003 new select
; declare eoc_begin_cd = f8 with protect,constant(2417619091.00)
; declare begin_episode_dt = dq8 with public,protect
;
; 
;select into "nl:"
;    from clinical_event ce
;    , (left join ce_date_result cdr
;        on cdr.event_id = ce.event_id
;        and cdr.valid_until_dt_tm > cnvtdatetime(curdate,curtime)) 
;    plan ce
;    where ce.person_id =personId
;    and ce.event_cd = eoc_begin_cd
;    and ce.result_status_cd in (25,34,35)
;    and ce.valid_until_dt_tm > sysdate
;    and ce.event_tag != "In Error"
;    AND ce.event_tag != "Date\Time Correction"
;        and ce.event_end_dt_tm = (select max(event_end_dt_tm)
;                                    from clinical_event 
;                                where person_id = ce.person_id
;                                and event_cd = eoc_begin_cd
;                                and result_status_cd in (25,34,35)
;                                and valid_until_dt_tm > sysdate
;                                and event_tag != "In Error"
;                                AND event_tag != "Date\Time Correction"
;                                )
; join cdr
; order by cdr.result_dt_tm ;last/max one found 
; detail
;  cocm->eps_beg_dt = cdr.result_dt_tm
; with nocounter
;005<-

/* ;003 replaced with above
select into "nl:"
     dttm = cnvtdate(cdr.result_dt_tm)
        from dcp_forms_activity d
            ,dcp_forms_activity_comp dfc
            ,clinical_event ce1
            ,clinical_event ce2
            ,clinical_event ce2a ;002 new level
            ,clinical_event ce3
            ,ce_date_result cdr
        plan d
            where d.person_id = personId
            and d.active_ind = 1
            and d.dcp_forms_ref_id =  13047318247.00;in (8160096133)
            and d.form_status_cd in(25.00, 34.00, 35.00)
            and d.dcp_forms_activity_id = (
                select max(dfa2.dcp_forms_activity_id)
                from  dcp_forms_activity dfa2
                where dfa2.person_id = d.person_id
                and dfa2.dcp_forms_ref_id = d.dcp_forms_ref_id
                and dfa2.active_ind = 1
                and dfa2.form_status_cd in (25.00,34.00, 35.00);002 missing 34.00
            )
        join dfc
            where dfc.dcp_forms_activity_id = d.dcp_forms_activity_id
            and dfc.parent_entity_name = "CLINICAL_EVENT"
        join ce1
            where ce1.parent_event_id = dfc.parent_entity_id
            and ce1.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
            and ce1.result_status_cd in (25.00,33.00,34,35.00);added 34 to all ce selects
        join ce2
            where ce2.parent_event_id = ce1.event_id
            and ce2.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
            and ce2.result_status_cd in (25.00,33.00,34,35.00)
        join ce2a ;002 new level
            where ce2a.parent_event_id = ce2.event_id
            and ce2a.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
            and ce2a.result_status_cd in (25.00,33.00,34,35.00)         
        join ce3
            where ce3.PARENT_EVENT_id = ce2a.EVENT_id ;002 
            and ce3.view_level = 1
            and ce3.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
            and ce3.event_tag != "In Error"
            and ce3.result_status_cd in (25.00,33.00,34,35.00)
            and ce3.event_cd = 2417619091.00;1889693299; in (;1888614847,1888194333,
;               1888194283,1888196051)
        join cdr
            where cdr.event_id = ce3.event_id
        order by d.person_id, ce3.event_cd
        head d.person_id
            cocm->eps_beg_dt = dttm
        foot d.person_id
            null
        with nocounter
*/


 
;if(curqual)  ;005 Don't need

declare set_row(col1_txt = vc, col2_txt = vc, col3_txt = vc, col4_txt = vc) = vc ;003 added
declare  rtf_table = vc with protect, noconstant('');003 added
 
;------------------------------------------------------------------------------------------------------------------
;   Get scores
;------------------------------------------------------------------------------------------------------------------
select into "nl:"
from clinical_event ce
;where ce.person_id = personId;27430417 ; ce.person_id = personId ;157127788   ;005 this is moving to encounter level.
where ce.encntr_id = e_id
and ce.event_cd in (tdss_72cd,gad7s_72cd)
;and ce.event_end_dt_tm >= cnvtdate(cocm->eps_beg_dt)  ;005 don't need this any more.
order by ce.event_cd, ce.event_end_dt_tm
head report
    cnt = 0
    head ce.event_cd
        cnt = cnt + 1
        stat = alterlist(cocm->scales, cnt)
        cocm->scales[cnt].event_cd = ce.event_cd
        cocm->scales[cnt].baseline = cnvtreal(ce.result_val)
        cocm->scales[cnt].base_dt = format(ce.event_end_dt_tm,"MM/DD/YY")
        case(ce.event_cd)
            of tdss_72cd:
                cocm->scales[cnt].name = "PHQ-9"
            of gad7s_72cd:
                cocm->scales[cnt].name = "GAD-7"

        endcase
    foot ce.event_cd
        pos = locateval(num, start, size(cocm->scales,5), ce.event_cd, cocm->scales[num].event_cd)
        cocm->scales[pos].current = cnvtreal(ce.result_val)
        cocm->scales[pos].curr_dt = format(ce.event_end_dt_tm,"MM/DD/YY")
        cocm->scales[pos].perc_chng =(((cocm->scales[pos].current - cocm->scales[pos].baseline)/cocm->scales[pos].baseline)*100)
with nocounter

;004 added to end of list
select into "nl:"
from clinical_event ce
;where ce.person_id = personId;27430417 ; ce.person_id = personId ;157127788   ;005 this is moving to encounter level.
where ce.encntr_id = e_id
and ce.event_cd in (target_scale_72cd)
;and ce.event_end_dt_tm >= cnvtdate(cocm->eps_beg_dt)  ;005 Don't need this anymore.
order by ce.event_cd, ce.event_end_dt_tm
head report
    cnt = size(cocm->scales,5) 
    head ce.event_cd
        cnt = cnt + 1
        stat = alterlist(cocm->scales, cnt)
        cocm->scales[cnt].event_cd = ce.event_cd
        cocm->scales[cnt].baseline = cnvtreal(ce.result_val)
        cocm->scales[cnt].base_dt = format(ce.event_end_dt_tm,"MM/DD/YY")
        cocm->scales[cnt].name = "Audit-C"

    foot ce.event_cd
        pos = locateval(num, start, size(cocm->scales,5), ce.event_cd, cocm->scales[num].event_cd)
        cocm->scales[pos].current = cnvtreal(ce.result_val)
        cocm->scales[pos].curr_dt = format(ce.event_end_dt_tm,"MM/DD/YY")
        cocm->scales[pos].perc_chng =(((cocm->scales[pos].current - cocm->scales[pos].baseline)/cocm->scales[pos].baseline)*100)
with nocounter



if(size(cocm->scales,5) >0)
    call echorecord(cocm)
    set stat = alterlist(cells->cells,4)
    set cells->cells[1]->size = 870
    set cells->cells[2]->size = 2850
    set cells->cells[3]->size = 4600
    set cells->cells[4]->size = 5990

    set rtf_table = build2(rh2b, set_row(" Scale"," Baseline", " Current"," Change (%)"))
    set rtf_table = build2(rtf_table, wr)

    for(cnt = 1 to size(cocm->scales,5))
        set rtf_table = notrim(build2(rtf_table,set_row(
            trim(build2(trim(cocm->scales[cnt].name,3)),3),
            trim(build2(trim(format(cocm->scales[cnt].baseline,"#####.##"),3)," (",trim(cocm->scales[cnt].base_dt,3),")"),3),
            trim(build2(trim(format(cocm->scales[cnt].current,"#####.##"),3)," (",trim(cocm->scales[cnt].curr_dt,3),")"),3),
            trim(build2(trim(format(cocm->scales[cnt].perc_chng,"#####.##"),3)),3))))
    endfor

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