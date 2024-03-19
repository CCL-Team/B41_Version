/**************************************************************************
 Program Title:   mp_get_adv_dir

 Object name:     mp_get_adv_dir
 Source file:     mp_get_adv_dir.prg

 Purpose:         Gather documented forms and documents and send to the
                  front end to display

 Tables read:

 Executed from:   MPage (Advanced Directives Component)

 Special Notes:
                  DCP_FORMS_REF_ID    DESCRIPTION
                  1185674.00          Advance Directive
                  548286737.00        Adult Patient Database Form
                  1923497409.00       Advance Directive Follow Up
                  2463183145.00       Advance Directives
                  ;TODO there are more forms involved here

                  Returns:            If DATATYPE = 0 or blank then JSON string data are returned, anything else returns XML
                  Logic borrowed from jdm13_mp_adv_dir_summ_jx

***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 09/25/2019 Michael Mayes        216298    Initial release (copied and cleaned from jdm13_mp_adv_dir_summ_jx)
002 06/19/2020 Michael Mayes        217132    Adding additional forms for Advanced Planning Documents
003 06/19/2020 Michael Mayes        222020    Adding event_set to Advanced Planning Documents for Swethas DC MOST, MD MOST PDFs.
                                              (Just a note, this was totally reverted.  They didnt want the text side, just the pdf
                                              which is landing in the MOLST/POLST event_cd)
004 06/24/2020 Michael Mayes        217132    Reworking query to be based on result rather than dcp_forms_ref
                                              We were up to 4 forms, but it looks like more than 20 are present now
005 10/21/2020 Michael Mayes        223712    Adding ADVault section for forms.
006 08/10/2023 Mihcael Mayes                  SCTASK0038991 Correcting issue where the wrong form link can appear if forms on two 
                                                            patients are documented at the same time.
*************END OF ALL MODCONTROL BLOCKS* ********************************/
drop   program mp_get_adv_dir:dba go
create program mp_get_adv_dir:dba


prompt
    'Output to File/Printer/MINE' = 'MINE'
    , 'Encntr Id:' = 0.0
    , 'Person Id:' = 0.0
    , 'Data Type:' = 0

with outdev, encntrid, personid, datatype


/**************************************************************
; DVDev INCLUDES
**************************************************************/


/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
free record rec
record rec (
    1 encntr_id                 = f8
    1 person_id                 = f8
    1 patient                   = vc
    1 encntr_type               = vc
    1 dcp_forms_ref_id          = f8
    1 dcp_forms_activity_id     = f8
    1 adv_dir_form_name         = vc
    1 version_dt_tm             = vc
    1 amb_ad_form_ref_id        = f8
    1 amb_ad_form_name          = vc
    1 inpat_ad_form_ref_id      = f8
    1 inpat_ad_form_name        = vc
    1 adv_dir_cnt               = i2
    1 adv_dir_list [*]
        2 form_element          = vc
        2 event_tag             = vc
    1 doc_cnt                   = i2
    1 doc_list [*]
        2 event_set             = vc
        2 event_disp            = vc
        2 event_title_text      = vc
        2 person_id             = f8
        2 encntr_id             = f8
        2 event_id              = f8
        2 parent_event_id       = f8
        2 event_class_cd        = f8
        2 event_end_dt_tm       = vc
        2 result_status         = vc
        2 result_status_cd      = f8
        2 view_level            = i4
    ;1 md_dc_flag                = vc  ;This is going to be intended to be 'MD' 'DC',
    ;                                  ;other cases will have to have some sort of logic
    1 md_form_ref_id            = f8
    1 md_form_name              = vc
    1 dc_form_ref_id            = f8
    1 dc_form_name              = vc
    1 ad_vault_cnt              = i2
    1 ad_vault[*]
        2 dcp_forms_activity_id = f8
        2 dcp_forms_ref_id      = f8
        2 powerform             = vc
        2 form_status           = vc
        2 form_date             = vc
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare mrn_cd        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    319, 'MRN'                 ))
declare fin_cd        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    319, 'FINNBR'              ))
declare ern_cd        = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',    263, 'EADENROLLEENUMBER'   ))

declare pri_evnt_id   = f8  with protect,   constant(uar_get_code_by('DISPLAY_KEY', 18189, 'PRIMARYEVENTID'      ))
declare root_cd       = f8  with protect,   constant(uar_get_code_by(    'MEANING',    24, 'ROOT'                ))
declare child_cd      = f8  with protect,   constant(uar_get_code_by(    'MEANING',    24, 'CHILD'               ))

declare act_cd        = f8  with protect,   constant(uar_get_code_by(   'MEANING',      8, 'ACTIVE'              ))
declare auth_cd       = f8  with protect,   constant(uar_get_code_by(   'MEANING',      8, 'AUTH'                ))
declare alt_cd        = f8  with protect,   constant(uar_get_code_by(   'MEANING',      8, 'ALTERED'             ))
declare mod_cd        = f8  with protect,   constant(uar_get_code_by(   'MEANING',      8, 'MODIFIED'            ))

declare err_cd        = f8  with protect,   constant(uar_get_code_by(   'MEANING',      8, 'INERROR'             ))


declare ad_event_cd   = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',     72, 'ADVANCEDIRECTIVES'   ))

declare ad_event_id   = f8  with protect, noconstant(0.0)

declare md_outcome_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',     72, 'MDMOLSTREVIEWOUTCOME'))
declare dc_outcome_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',     72, 'DCMOSTREVIEWOUTCOME' ))
declare grp_cd        = f8  with protect, noconstant(uar_get_code_by(   'MEANING',     53, 'GRP'                 ))

declare reply_txt     = vc  with protect, noconstant('')

declare pos           = i4  with protect, noconstant(0)
declare idx           = i4  with protect, noconstant(0)


/**************************************************************
; DVDev Start Coding
**************************************************************/
;Determine the forms_ref_ids for the MOLST MOST forms
select into 'nl:'
  from dcp_forms_ref dfr
 where dfr.active_ind = 1
   and dfr.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
   and dfr.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
   and dfr.description in('MD Medical Orders for Life-Sustaining Treatment (MOLST)'
                         ,'DC Medical Orders for Scope of Treatment (MOST)'
                         , 'Advance Directive'
                         , 'Advance Directives')
detail
    case(dfr.description)
    of 'Advance Directive' : rec->inpat_ad_form_ref_id = dfr.dcp_forms_ref_id
                             rec->inpat_ad_form_name   = dfr.description
    of 'Advance Directives': rec->amb_ad_form_ref_id   = dfr.dcp_forms_ref_id
                             rec->amb_ad_form_name     = dfr.description
    of '*(MOLST)'          : rec->md_form_ref_id       = dfr.dcp_forms_ref_id
                             rec->md_form_name         = dfr.description
    of '*(MOST)'           : rec->dc_form_ref_id       = dfr.dcp_forms_ref_id
                             rec->dc_form_name         = dfr.description
    endcase
with nocounter


; get the encounter and person specific details
select
  into 'nl:'
       e.encntr_id
     , p.person_id
     , patient       = trim(p.name_full_formatted)
     , encntr_type   = uar_get_code_display(e.encntr_type_cd)
  from person p
     , encounter e
 where p.person_id   =  cnvtreal($personid)
   and e.encntr_id   =  cnvtreal($encntrid)
   and e.person_id   =  p.person_id
detail
    rec->encntr_type = trim(encntr_type)
    rec->encntr_id   = e.encntr_id
    rec->person_id   = p.person_id

with nocounter
   , separator = ' '
   , format
   , time      = 30


;Find the most recent AD event doc
/*Some thought here is required... I think I'm going to get away with this however...  The ce might be on
  an older form doc, but we want to link to the latest form.
*/
select into 'nl:'
  from clinical_event ce
 where ce.person_id             =  cnvtreal($personid)
   and ce.event_cd              =  ad_event_cd
   and ce.event_reltn_cd        =  child_cd
   and ce.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.000')
   and ce.result_status_cd      in (act_cd,auth_cd,alt_cd,mod_cd)
order by event_end_dt_tm desc
head report
    ad_event_id = ce.event_id
with nocounter


; get Advanced Directives form content from ad doc, and most recent information on that form.
select into 'nl:'
      d2.dcp_forms_ref_id
    , d2.dcp_forms_activity_id
    , ce.encntr_id
    , ce.person_id
    , form_element    = uar_get_code_display(ce3.event_cd)
    , ce3.event_cd
    , ce3.event_tag
    , event_end_dt_tm = format(ce3.event_end_dt_tm,'MM/DD/YYYY HH:MM;;')
  from  clinical_event          ce  ;triggering ce
      , clinical_event          ce2 ;form
      , clinical_event          ce3 ;form children
      , clinical_event          ce4 ;form parent  I don't think we actually need this join however.  Added this for information.
      , dcp_forms_activity_comp df
      , dcp_forms_activity      d   ;the activity where our event dropped.
      , dcp_forms_activity      d2  ;the most recent activity on the form.
  plan ce ;triggering ce
   where ce.event_id              =  ad_event_id
  join ce2 ;form
   where ce2.event_id             =  ce.parent_event_id
     and ce2.valid_until_dt_tm    =  cnvtdatetime('31-DEC-2100 00:00:00.000')
     and ce2.event_reltn_cd       =  child_cd
     and ce2.result_status_cd     in (act_cd,auth_cd,alt_cd,mod_cd)
  join ce3 ;form children
   where ce3.parent_event_id      =  ce2.event_id
     and ce3.valid_until_dt_tm    =  cnvtdatetime('31-DEC-2100 00:00:00.000')
     and ce3.event_reltn_cd       =  child_cd
     and ce3.result_status_cd     in (act_cd,auth_cd,alt_cd,mod_cd)
  join ce4 ;form parent
   where ce4.event_id             =  ce2.parent_event_id
     and ce4.valid_until_dt_tm    =  cnvtdatetime('31-DEC-2100 00:00:00.000')
     and ce4.event_reltn_cd       =  root_cd
     and ce4.result_status_cd     in (act_cd,auth_cd,alt_cd,mod_cd)
  join df
   where df.parent_entity_id      =  ce4.event_id
     and df.parent_entity_name    =  'CLINICAL_EVENT'
     and df.component_cd          =  pri_evnt_id
  join d  ;our ce activity
   where d.dcp_forms_activity_id  =  df.dcp_forms_activity_id
  join d2 ;most recent activity on the same type of form
   where d2.dcp_forms_ref_id      =  d.dcp_forms_ref_id
     and d2.person_id             =  d.person_id;006
     and d2.version_dt_tm    = (
           select max(dx.version_dt_tm)
             from dcp_forms_activity dx
            where dx.person_id        = d.person_id
              and dx.dcp_forms_ref_id = d.dcp_forms_ref_id
          )
order by d.person_id
       , ce3.event_cd
       , ce3.event_end_dt_tm
       , ce3.collating_seq

head d.person_id
    stat = alterlist(rec->adv_dir_list, 50)

    rec->adv_dir_cnt                         = 0

    rec->dcp_forms_ref_id      = d2.dcp_forms_ref_id
    rec->dcp_forms_activity_id = d2.dcp_forms_activity_id
    rec->adv_dir_form_name     = d2.description
    rec->version_dt_tm         = trim(format(d2.version_dt_tm,'MM/DD/YYYY HH:MM;;'), 3)

head ce3.event_cd
    rec->adv_dir_cnt = rec->adv_dir_cnt + 1

    if(mod(rec->adv_dir_cnt,50) = 1 and rec->adv_dir_cnt > 50)
        stat = alterlist(rec->adv_dir_list, rec->adv_dir_cnt + 49)
    endif

foot ce3.event_cd
    rec->adv_dir_list[rec->adv_dir_cnt].form_element          = trim(uar_get_code_display(ce3.event_cd), 3)
    rec->adv_dir_list[rec->adv_dir_cnt].event_tag             = trim(ce3.event_tag)

foot d.person_id
    stat = alterlist(rec->adv_dir_list, rec->adv_dir_cnt)

with nocounter
   , separator = ' '
   , format
   , time      = 30


; Advanced Planning Documents
set stat         = alterlist(rec->doc_list, 10)
set rec->doc_cnt = 0


select
  into 'nl:'
      event_set          = uar_get_code_display(v.parent_event_set_cd)
    , event_disp         = uar_get_code_display(ve.event_cd)
    , result_status      = uar_get_code_display(c.result_status_cd)
    , event_end_dt_tm    = format(c.event_end_dt_tm,'mm/dd/yyyy hh:mm;;')
    , c.event_title_text
    , c.person_id
    , c.event_id
    , c.parent_event_id
    , c.event_class_cd
    , c.result_status_cd
    , c.view_level
    , c.*
from v500_event_set_canon   v
   , v500_event_set_explode ve
   , code_value             cv  ;003
   , clinical_event         c
plan v
 where v.parent_event_set_cd  in (825835479.00   ; Advance Directive Documents
                                                 ; Family Meeting Note
                                                 ; Advanced Care Planning Note
                                                 ; MOLST/POLST
                                                 ; Living Will
                                 ;,1888608217.00  ; Advanced Care Planning Forms - Text (new swetha pdfs) ;003
                                 ,1794730107.00) ; Power Of Attorney
join ve
 where ve.event_set_cd        =  v.event_set_cd
join cv
 where cv.code_value          =  ve.event_cd                    ; 003 Had to pull out the events they added to AD docs event set
   and cv.active_ind          =  1                              ; 003 They don't want these textual renditions
   and cv.display_key         not in('ADVANCECAREPLANNINGTEXT'  ; 003
                                    ,'DCMOSTTEXT'               ; 003
                                    ,'MDMOLSTTEXT'              ; 003
                                    )                           ; 003
join c
 where c.person_id            =  cnvtreal($personid)
   and c.event_cd             =  ve.event_cd
   and c.event_end_dt_tm      <= cnvtdatetime(curdate,curtime3)
   and c.valid_until_dt_tm    =  cnvtdatetime('31-dec-2100 00:00:00.000')
   and c.result_status_cd     in (act_cd, auth_cd, alt_cd, mod_cd)
   and c.view_level           != 0
order by event_disp, c.event_end_dt_tm desc
head event_disp ;For now we are just pulling the latest from each note title.  This might change.
    rec->doc_cnt = rec->doc_cnt + 1

    stat = alterlist(rec->doc_list, rec->doc_cnt)

    rec->doc_list[rec->doc_cnt].event_set        = trim(event_set)
    rec->doc_list[rec->doc_cnt].event_disp       = trim(event_disp)
    rec->doc_list[rec->doc_cnt].event_title_text = trim(c.event_title_text)
    rec->doc_list[rec->doc_cnt].person_id        = c.person_id
    rec->doc_list[rec->doc_cnt].encntr_id        = c.encntr_id
    rec->doc_list[rec->doc_cnt].event_id         = c.event_id
    rec->doc_list[rec->doc_cnt].parent_event_id  = c.parent_event_id
    rec->doc_list[rec->doc_cnt].event_class_cd   = c.event_class_cd
    rec->doc_list[rec->doc_cnt].event_end_dt_tm  = trim(event_end_dt_tm)
    rec->doc_list[rec->doc_cnt].result_status    = trim(result_status)
    rec->doc_list[rec->doc_cnt].result_status_cd = c.result_status_cd
    rec->doc_list[rec->doc_cnt].view_level       = c.view_level

with nocounter
   , separator = ' '
   , format
   , time      = 30

set stat = alterlist(rec->doc_list, rec->doc_cnt)


/* I don't think this is needed now that they have changed the specs to have me show new links for both, and LCV for both.  
   No more fancy stuff.

;Determine the state that we are dealing with for this encounter.
;Specs suggest that this should be based on performing location (I'm just going to read that as enc location)
select
  into 'nl:'
  from encounter  e
     , address    a
     , code_value cv
 where e.encntr_id = rec->encntr_id

   and a.parent_entity_id    in ( e.location_cd            ;This is heavy handed, but should handle amb and inpatient
                                , e.loc_facility_cd        ;They should be the same state anyway (I hope)
                                , e.loc_building_cd
                                , e.loc_nurse_unit_cd)
   and a.parent_entity_name  =  'LOCATION'
   and a.active_ind          =  1
   and a.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
   and a.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)

   and cv.code_value         =  outerjoin(a.state_cd)
   and cv.active_ind         =  outerjoin(1)
   and cv.display            in ('DC', 'MD')
detail
    ;We have a potential problem if the location doesn't have a code_value for state.  So... we have to do a bunch of logic here.
    if(cv.display is not null)
        rec->md_dc_flag = cv.display
    elseif(a.state > ' ' and a.state in ('District of Columbia'
                                        ,'DC'
                                        ,'MD')
          )
        case(a.state)
        of 'District of Columbia':
        of 'DC':
            rec->md_dc_flag = 'DC'
        of 'MD':
            rec->md_dc_flag = 'MD'
        endcase
    ;else
    ;    Stopping this for now... probably not needed I hope but we might be able to do this by location zip as well.
    endif
with nocounter

*/

; get latest MOLST MOST forms
select
  into 'nl:'
      d.dcp_forms_ref_id
    , d.encntr_id
    , d.person_id
    , powerform       = d.description
    , form_status     = uar_get_code_display(d.form_status_cd)
  from dcp_forms_activity   d
     , dcp_forms_activity_comp dfac
     , clinical_event          ce
     , clinical_event          ce2
 where d.person_id              =  cnvtreal($personid)
   and d.dcp_forms_ref_id       in (rec->md_form_ref_id
                                   ,rec->dc_form_ref_id
                                   )
    and d.form_status_cd        != err_cd
    
    and d.dcp_forms_activity_id =  dfac.dcp_forms_activity_id

    and dfac.parent_entity_id   =  ce.parent_event_id
    and ce.event_class_cd       =  grp_cd
    and ce.event_reltn_cd       =  child_cd
    and ce.result_status_cd     in (act_cd,auth_cd,alt_cd,mod_cd)
    and ce.valid_until_dt_tm    >= cnvtdatetime(curdate, curtime3)

    and ce2.parent_event_id     =  outerjoin(ce.event_id)
    and ce2.valid_until_dt_tm   >= outerjoin(cnvtdatetime(curdate, curtime3))
    and (   ce2.event_cd = outerjoin(md_outcome_cd)
         or ce2.event_cd = outerjoin(dc_outcome_cd))
order by d.version_dt_tm desc
;head d.dcp_forms_ref_id
detail
    /*Okay this got complicated so here is what is up
        1) We want to pull out any Form voided results, and that is stored as a result in the form.
        2) This means the query had to switch to a order by where we handle most recent doc in the report writer
        3) The result itself might be not documented, so that last join to CE2 is an outer join
        4) That means below we want to include any forms that have a result that isn't form voided, or have nothing documented.
        5) But we want the most recent from both forms here...

        I think I've handled those cases, as long as a null passes the form voided check below.
    */
    ;scratch that... we probably want to show voided now.
    ;if(ce2.result_val != "Form voided")
        pos = locateval(idx, 1, rec->ad_vault_cnt, d.dcp_forms_ref_id, rec->ad_vault[idx].dcp_forms_ref_id)

        if(pos = 0)
            rec->ad_vault_cnt = rec->ad_vault_cnt + 1

            stat = alterlist(rec->ad_vault, rec->ad_vault_cnt)

            rec->ad_vault[rec->ad_vault_cnt].dcp_forms_activity_id = d.dcp_forms_activity_id
            rec->ad_vault[rec->ad_vault_cnt].dcp_forms_ref_id      = d.dcp_forms_ref_id
            rec->ad_vault[rec->ad_vault_cnt].powerform             = trim(powerform)
            rec->ad_vault[rec->ad_vault_cnt].form_status           = trim(form_status)
            rec->ad_vault[rec->ad_vault_cnt].form_date             = trim(format(d.version_dt_tm,'MM/DD/YYYY HH:MM;;'), 3)
        endif
    ;endif
with nocounter
   , separator = ' '
   , format
   , time      = 30


/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


#exit_script

; send back recordset data as JSON or XML
if (cnvtint($datatype) = 0)
    call echojson(rec) ;for debugging
    set reply_txt            = cnvtrectojson(rec)
    set _MEMORY_REPLY_STRING = reply_txt
else
    call echoxml(rec) ;for debugging
    set reply_txt            = cnvtrectoxml(rec)
    set _MEMORY_REPLY_STRING = reply_txt
endif

end
go
