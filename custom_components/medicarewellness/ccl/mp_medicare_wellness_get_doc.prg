/**************************************************************************
 Program Title:   mp_medicare_wellness_get_doc
 
 Object name:     mp_medicare_wellness_get_doc
 Source file:     mp_medicare_wellness_get_doc.prg
 
 Purpose:         Returns Documented PowerForm, or form_ref for
                  new launch.
 
 Tables read:     
 
 Executed from:   MPage
 
 Special Notes:   
 
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 04/02/2019 Michael Mayes        215865    Initial release
002 05/27/2020 Michael Mayes        221347    Changing form name hard coding
 
*************END OF ALL MODCONTROL BLOCKS* ********************************/
drop program mp_medicare_wellness_get_doc:dba go
create program mp_medicare_wellness_get_doc:dba

prompt
      'Output to File/Printer/MINE' = 'MINE'   ;* Enter or select the printer or file name to send this report to.
    , 'person_id'                   = 0.0
    , 'encounter_id'                = 0.0
with OUTDEV, per_id, enc_id



/**************************************************************
; DVDev INCLUDES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc


/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
free record doc_info
record doc_info(
    1 per_id          = f8
    1 enc_id          = f8 
    1 form_ref_id     = f8 
    1 form_name       = vc
    1 activity_id     = f8
    1 event_end_dt_tm = vc
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/

 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
;Build
;declare form_ref_id      = f8 with protect, constant(8113034055.00) ;Magic number (I don't know if I can query for this)

;Prod
declare form_ref_id      = f8 with protect, constant(9086789283.00) ;Magic number (I don't know if I can query for this)

declare prim_evnt_cd     = f8 with protect, constant(uar_get_code_by('DISPLAY_KEY', 18189, 'PRIMARYEVENTID'))
declare root_ce_reltn_cd = f8 with protect, constant(uar_get_code_by(    'MEANING',    24, 'ROOT'))
declare chld_ce_reltn_cd = f8 with protect, constant(uar_get_code_by(    'MEANING',    24, 'CHILD'))

declare act_cd           = f8 with protect, constant(uar_get_code_by(    'MEANING',     8, 'ACTIVE'))
declare auth_cd          = f8 with protect, constant(uar_get_code_by(    'MEANING',     8, 'AUTH'))
declare mod_cd           = f8 with protect, constant(uar_get_code_by(    'MEANING',     8, 'MODIFIED'))
declare alt_cd           = f8 with protect, constant(uar_get_code_by(    'MEANING',     8, 'ALTERED'))


/**************************************************************
; DVDev Start Coding
**************************************************************/

;I know I have access to per and enc on the frontend and don't need this, but 
;I'm doing this for the moment so I don't have to look up how to get the JS context.
set doc_info->per_id      = $per_id
set doc_info->enc_id      = $enc_id
set doc_info->form_ref_id = form_ref_id


/**********************************************************************
DESCRIPTION:  Get the form name for the frontend
***********************************************************************/
select into 'nl:'
  from dcp_forms_ref dfr
 where dfr.dcp_forms_ref_id    =  form_ref_id
   and dfr.end_effective_dt_tm >  sysdate 
detail
    doc_info->form_name = trim(dfr.description, 3)
with nocounter


/**********************************************************************
DESCRIPTION:  Get the Latest General Info if it exists
***********************************************************************/
select into 'nl:'
from dcp_forms_activity d
   , dcp_forms_activity_comp df
   , clinical_event c
   , clinical_event ce
   , clinical_event ce3
where d.person_id              =  $per_id
  and d.encntr_id              =  $enc_id
  and d.dcp_forms_ref_id       =  form_ref_id
  and d.version_dt_tm          =  (
                                      select max(dx.version_dt_tm)
                                        from dcp_forms_activity dx
                                       where dx.person_id = d.person_id
                                         and dx.encntr_id = d.encntr_id
                                         and dx.dcp_forms_ref_id = d.dcp_forms_ref_id
                                  )
  and df.dcp_forms_activity_id =  d.dcp_forms_activity_id
  and df.component_cd          =  prim_evnt_cd
  and df.parent_entity_name    =  'CLINICAL_EVENT'
  and c.event_id               =  df.parent_entity_id
  and c.valid_until_dt_tm      =  cnvtdatetime('31-DEC-2100 00:00:00.00')
  and c.event_reltn_cd         =  root_ce_reltn_cd
  and c.result_status_cd       in (act_cd, auth_cd, mod_cd, alt_cd) 
  and ce.parent_event_id       =  c.event_id
  and ce.valid_until_dt_tm     =  cnvtdatetime('31-DEC-2100 00:00:00.00')
  and ce.event_reltn_cd        =  chld_ce_reltn_cd
  and ce.result_status_cd      in (act_cd, auth_cd, mod_cd, alt_cd) 
  and ce3.parent_event_id      =  ce.event_id
  and ce3.valid_until_dt_tm    =  cnvtdatetime('31-DEC-2100 00:00:00.00')
  and ce3.event_reltn_cd       =  chld_ce_reltn_cd
  and ce3.result_status_cd     in (act_cd, auth_cd, mod_cd, alt_cd) 
order by d.person_id, ce3.collating_seq, ce3.event_id
detail
    doc_info->activity_id     = d.dcp_forms_activity_id
    doc_info->event_end_dt_tm = format(d.last_activity_dt_tm,'MM/DD/YYYY HH:MM;;')
with nocounter

                                       
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/

 
#exit_script

call echorecord(doc_info)

call putRSToFile($OUTDEV, doc_info)

end
go
 