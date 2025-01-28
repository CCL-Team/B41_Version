/*************************************************************************
 Program Title: Ambulatory hours to signed clinic note/release bill
 
 Object name:   2_him_clin_note_hrs_to_sign
 Source file:   2_him_clin_note_hrs_to_sign.prg
 
 Purpose:       Show all clinic visits where the clinic visit note is incomplete past 96
                hours of DOS
 
 Tables read:
 
 Executed from:
 
 Special Notes: Location processing for appt query stolen from 14_mdpcp_sbirt_rpt.
 
 
******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 02/16/2022 Michael Mayes        230344 Initial release
002 07/28/2022 Michael Mayes               (TASK5543017) Change to pull first sign... not subsequent.
003 12/05/2024 Michael Mayes        350165 Adding Otolaryn Consult to notes we look for.
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 2_him_clin_note_hrs_to_sign:dba go
create program 2_him_clin_note_hrs_to_sign:dba
 
prompt
      "Output to File/Printer/MINE" = "MINE"
    , "Result Start Date:"          = "SYSDATE"
    , "Result End Date:"            = "SYSDATE"
    , "Location"                    = 0
with OUTDEV, BEG_DT, END_DT, LOCATION
 
 
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
free record loc
record loc(
    1 cnt          = i4
    1 qual[*]
        2 org_name = vc
        2 loc_name = vc
        2 loc_cd   = f8
)
 
free record notes
record notes(
    1 cnt           = i4
    1 qual[*]
        2 note_name = vc
        2 note_cd   = f8
)
 
 
free record candidate_appts
record candidate_appts(
    1 cnt = i4
    1 qual[*]
        2 appt_id       = f8
        2 appt_event_id = f8
        2 per_id        = f8
        2 enc_id        = f8
        2 appt_dt       = dq8
        2 provider      = vc
)
 
free record data
record data(
    1 cnt = i4
    1 qual[*]
        2 add_reason    = vc  ;mainly debugging
        2 per_id        = f8
        2 enc_id        = f8
        2 event_id      = f8
        2 pat_name      = vc
        2 pat_dob       = vc
        2 pat_mrn       = vc
        2 pat_fin       = vc
        2 provider      = vc
        2 doc_type      = vc
        2 fac_name      = vc
        2 appt_dt       = dq8
        2 appt_dt_txt   = vc
        2 signed_dt     = dq8
        2 signed_dt_txt = vc
        2 num_hrs       = vc
)
 
 
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare flex_care_appt  = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY", 14230, "FLEXCARE" ))
declare serv_cancel_cd  = f8  with protect,   constant(uar_get_code_by("DISPLAYKEY",    34, "CANCELLED"))
 
declare patient_cd      = f8  with protect,   constant(uar_get_code_by(   'MEANING', 14250, 'PATIENT'  ))
 
declare act_cd          = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'   ))
declare mod_cd          = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED' ))
declare auth_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'     ))
declare altr_cd         = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'  ))
 
declare hr_holder =  vc with protect, noconstant('')
 
declare idx             = i4  with protect, noconstant(0)
 
/*************************************************************
; DVDev Start Coding
**************************************************************/
 
if(0 not in ($location))
   /**********************************************************************
    DESCRIPTION:  Get Locations under Org
    ***********************************************************************/
    select distinct
      into "nl:"
           l.location_cd
      from organization o
         , location     l
      plan o
       where o.organization_id     in ($location)
         and o.active_ind          =  1
         and o.end_effective_dt_tm >  cnvtdatetime(curdate,curtime3)
 
      join l
       where l.organization_id     =  o.organization_id
         and l.location_type_cd    =  772.00 ; ambulatory   ;TODO CHECK THIS... PROMPT HAS MEDSTAR FACS
         and l.active_ind          =  1
         and l.end_effective_dt_tm >  cnvtdatetime(curdate,curtime3)
    order by l.location_cd
    head report
        loc->cnt = 0
 
    head l.location_cd
        loc->cnt = loc->cnt + 1
        stat = alterlist(loc->qual, loc->cnt)
 
        loc->qual[loc->cnt].org_name = trim(o.org_name                         , 3)
        loc->qual[loc->cnt].loc_name = trim(uar_get_code_display(l.location_cd), 3)
        loc->qual[loc->cnt].loc_cd   = l.location_cd
    with nocounter
 
else
 
    /**********************************************************************
    DESCRIPTION:  Get all AMB locations
    ***********************************************************************/
    select distinct
      into "nl:"
           l.location_cd
      from location l
      plan l
       where l.location_type_cd    =  772.00 ; ambulatory  ;TODO CHECK THIS... PROMPT HAS MEDSTAR FACS
         and l.active_ind          =  1
         and l.end_effective_dt_tm >  cnvtdatetime(curdate,curtime3)
    order by l.location_cd
    head report
        loc->cnt = 0
 
    head l.location_cd
        loc->cnt = loc->cnt + 1
        stat = alterlist(loc->qual, loc->cnt)
 
        loc->qual[loc->cnt].loc_name = trim(uar_get_code_display(l.location_cd), 3)
        loc->qual[loc->cnt].loc_cd   = l.location_cd
    with nocounter
endif
 
 
/**********************************************************************
DESCRIPTION:  Find Notes
***********************************************************************/
select into 'nl:'
  from v500_event_set_explode vese
 where vese.event_set_cd in ( 2445671167.00 ; Both office/clinic note groupers
                            , 4002474.00    ; Both office/clinic note groupers
                            , 825835507.00  ; Otolaryngology Consultation       ;003
                            )  
order by vese.event_cd
head vese.event_cd
 
    notes->cnt = notes->cnt + 1
 
    if(mod(notes->cnt, 10) = 1)
        stat = alterlist(notes->qual, notes->cnt + 9)
    endif
 
    notes->qual[notes->cnt]->note_name = uar_get_code_display(vese.event_cd)
    notes->qual[notes->cnt]->note_cd   = vese.event_cd
 
foot report
    stat = alterlist(notes->qual, notes->cnt)
 
with nocounter
 
 
/**********************************************************************
DESCRIPTION:  Find candidate appointments to check later
***********************************************************************/
select into "nl:"
  from sch_appt  a1 ;Patient
     , sch_appt  a2 ;Resource
     , prsnl     p
     , encounter e
     , sch_event se
  plan a1
   where a1.state_meaning not in ("NOSHOW", "RESCHEDULED", "CANCELED")
     and a1.role_meaning      =  'PATIENT'
     and a1.encntr_id         >  0
     and a1.beg_dt_tm         >= cnvtdatetime($beg_dt)
     and a1.beg_dt_tm         <= cnvtdatetime($end_dt)
     and (expand(idx, 1, loc->cnt, a1.appt_location_cd, loc->qual[idx].loc_cd))
     and a1.schedule_seq      =  (select max(s1.schedule_seq)
                                    from SCH_APPT S1
                                   where S1.sch_event_id = a1.sch_event_id)
 
  join a2
   where a2.sch_event_id      =  outerjoin(a1.sch_event_id)
     and a2.sch_role_cd       != outerjoin(patient_cd)
     and a2.person_id         != outerjoin(0)
     and a2.schedule_seq      =  outerjoin(a1.schedule_seq)
 
  join p
   where p.person_id          =  a2.person_id
 
  join e
   where a1.encntr_id         =  e.encntr_id
     and e.med_service_cd not in (;0,             ; I guess we want these now.
                                  serv_cancel_cd) ; but not these still.
     and e.active_ind         =  1
 
  join se
   where se.sch_event_id = a1.sch_event_id
     and se.appt_type_cd != flex_care_appt
 
order by a1.beg_dt_tm
detail
 
    candidate_appts->cnt = candidate_appts->cnt + 1
 
    if(mod(candidate_appts->cnt, 10) = 1)
        stat = alterlist(candidate_appts->qual, candidate_appts->cnt + 9)
    endif
 
 
    candidate_appts->qual[candidate_appts->cnt]->appt_id       = a1.sch_appt_id
    candidate_appts->qual[candidate_appts->cnt]->appt_event_id = a1.sch_event_id
    candidate_appts->qual[candidate_appts->cnt]->per_id        = a1.person_id
    candidate_appts->qual[candidate_appts->cnt]->enc_id        = a1.encntr_id
    candidate_appts->qual[candidate_appts->cnt]->appt_dt       = a1.beg_dt_tm
    candidate_appts->qual[candidate_appts->cnt]->provider      = trim(p.name_full_formatted, 3)
 
foot report
    stat = alterlist(candidate_appts->qual, candidate_appts->cnt)
 
with nocounter
 
 
/**********************************************************************
DESCRIPTION:  Find encounters that have no note, and are over 96 hours
              past.
***********************************************************************/
select into 'nl:'
  from encounter    e
     , person       p
     , encntr_alias ea
     , encntr_alias ea2
     , (dummyt d with seq = candidate_appts->cnt)
 
  plan d
   where candidate_appts->cnt                 >  0
     and candidate_appts->qual[d.seq]->enc_id >  0
     and datetimediff(cnvtdatetime(curdate, curtime3), candidate_appts->qual[d.seq]->appt_dt) > 4
 
  join e
   where e.encntr_id =  candidate_appts->qual[d.seq]->enc_id
     and not exists( select 'x'
                       from clinical_event ce
                      where ce.encntr_id         =  e.encntr_id
                        and ce.valid_until_dt_tm >= cnvtdatetime(curdate, curtime3)
                        and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, altr_cd)
                        and expand(idx, 1, notes->cnt, ce.event_cd, notes->qual[idx]->note_cd)
                   )
 
  join p
   where p.person_id = e.person_id
 
  join ea
   where ea.encntr_id             = outerjoin(e.encntr_id)
     and ea.encntr_alias_type_cd  = outerjoin(       1077.00);fin
     and ea.end_effective_dt_tm   > outerjoin(cnvtdatetime(curdate,curtime3))
     and ea.active_ind            = outerjoin(1)
 
  join ea2
   where ea2.encntr_id            = outerjoin(e.encntr_id)
     and ea2.encntr_alias_type_cd = outerjoin(       1079.00);MRN
     and ea2.end_effective_dt_tm  > outerjoin(cnvtdatetime(curdate,curtime3))
     and ea2.active_ind           = outerjoin(1)
 
detail
    data->cnt = data->cnt + 1
 
    if(mod(data->cnt, 10) = 1)
        stat = alterlist(data->qual, data->cnt + 9)
    endif
 
    data->qual[data->cnt]->add_reason    = "Old Appt, No Note"
    data->qual[data->cnt]->enc_id        = e.encntr_id
    data->qual[data->cnt]->per_id        = e.person_id
    ;data->qual[data->cnt]->event_id      =
    data->qual[data->cnt]->pat_name      = trim(p.name_full_formatted, 3)
    data->qual[data->cnt]->pat_dob       = format(p.birth_dt_tm, "MM/DD/YYYY;;Q")
    data->qual[data->cnt]->pat_mrn       = trim(ea2.alias , 3)
    data->qual[data->cnt]->pat_fin       = trim(ea.alias, 3)
    data->qual[data->cnt]->provider      = candidate_appts->qual[d.seq]->provider
    ;data->qual[data->cnt]->doc_type      =
    data->qual[data->cnt]->fac_name      = uar_get_code_display(e.loc_facility_cd)
    data->qual[data->cnt]->appt_dt       = candidate_appts->qual[d.seq]->appt_dt
    data->qual[data->cnt]->appt_dt_txt   = format(candidate_appts->qual[d.seq]->appt_dt, "@SHORTDATETIME")
    ;data->qual[data->cnt]->signed_dt     =
    ;data->qual[data->cnt]->signed_dt_txt =
 
 
    ;This is going to be number of hours since the appointment
    hr_holder = trim(cnvtstring(datetimediff( cnvtdatetime(curdate, curtime3)
                                            , candidate_appts->qual[d.seq]->appt_dt
                                            , 3
                                            )
                                )
                    , 3
                    )
 
    data->qual[data->cnt]->num_hrs       =  concat('NO NOTE ', '(', hr_holder, ' hrs)')
 
with nocounter, expand = 1
 
 
/**********************************************************************
DESCRIPTION:  Find encounters that have a note that wasn't signed within
              96 hours of the appointment
***********************************************************************/
select into 'nl:'
  from encounter      e
     , person         p
     , encntr_alias   ea
     , encntr_alias   ea2
     , clinical_event ce
     , ce_event_prsnl cep  ;002
     , (dummyt d with seq = candidate_appts->cnt)
 
  plan d
   where candidate_appts->cnt                 >  0
     and candidate_appts->qual[d.seq]->enc_id >  0
 
  join e
   where e.encntr_id =  candidate_appts->qual[d.seq]->enc_id
 
  join p
   where p.person_id = e.person_id
 
  join ea
   where ea.encntr_id             = outerjoin(e.encntr_id)
     and ea.encntr_alias_type_cd  = outerjoin(       1077.00);fin
     and ea.end_effective_dt_tm   > outerjoin(cnvtdatetime(curdate,curtime3))
     and ea.active_ind            = outerjoin(1)
 
  join ea2
   where ea2.encntr_id            = outerjoin(e.encntr_id)
     and ea2.encntr_alias_type_cd = outerjoin(       1079.00);MRN
     and ea2.end_effective_dt_tm  > outerjoin(cnvtdatetime(curdate,curtime3))
     and ea2.active_ind           = outerjoin(1)
 
  join ce
   where ce.encntr_id             =  e.encntr_id
     and ce.event_class_cd        =  231.00  ;MDOC
     and ce.result_status_cd      in (act_cd, mod_cd, auth_cd, altr_cd)
     and ce.valid_until_dt_tm     >= cnvtdatetime(curdate, curtime3)
     and expand(idx, 1, notes->cnt, ce.event_cd, notes->qual[idx]->note_cd)
     ;002 removing
     ;and datetimediff(ce.verified_dt_tm, cnvtdatetime(candidate_appts->qual[d.seq]->appt_dt)) > 4
  
  ;002->
  join cep
   where cep.event_id             =  ce.event_id
     and cep.action_type_cd       =  107.00  ;sign
     and cep.valid_until_dt_tm    >= cnvtdatetime(curdate, curtime3)
     and cep.action_dt_tm = (
        select min(cep2.action_dt_tm)
          from ce_event_prsnl cep2
         where cep2.event_id          =  ce.event_id
           and cep2.action_type_cd    =  107.00  ;sign
           and cep2.valid_until_dt_tm >= cnvtdatetime(curdate, curtime3)
     )
     and datetimediff(cep.action_dt_tm, cnvtdatetime(candidate_appts->qual[d.seq]->appt_dt)) > 4
  ;002<-
detail
    data->cnt = data->cnt + 1
 
    if(mod(data->cnt, 10) = 1)
        stat = alterlist(data->qual, data->cnt + 9)
    endif
 
    data->qual[data->cnt]->add_reason    = "Note signed > 96 hours from appt"
    data->qual[data->cnt]->enc_id        = e.encntr_id
    data->qual[data->cnt]->per_id        = e.person_id
    data->qual[data->cnt]->event_id      = ce.event_id
    data->qual[data->cnt]->pat_name      = trim(p.name_full_formatted, 3)
    data->qual[data->cnt]->pat_dob       = format(p.birth_dt_tm, "MM/DD/YYYY;;Q")
    data->qual[data->cnt]->pat_mrn       = trim(ea2.alias , 3)
    data->qual[data->cnt]->pat_fin       = trim(ea.alias, 3)
    data->qual[data->cnt]->provider      = candidate_appts->qual[d.seq]->provider
    data->qual[data->cnt]->doc_type      = uar_get_code_display(ce.event_cd)
    data->qual[data->cnt]->fac_name      = uar_get_code_display(e.loc_facility_cd)
    data->qual[data->cnt]->appt_dt       = candidate_appts->qual[d.seq]->appt_dt
    data->qual[data->cnt]->appt_dt_txt   = format(candidate_appts->qual[d.seq]->appt_dt, "@SHORTDATETIME")
    data->qual[data->cnt]->signed_dt     = cep.action_dt_tm
    data->qual[data->cnt]->signed_dt_txt = format(cep.action_dt_tm, "@SHORTDATETIME")
 
 
    ;This is going to be number of hours since the appointment
    hr_holder = trim(cnvtstring(datetimediff( ce.verified_dt_tm
                                            , candidate_appts->qual[d.seq]->appt_dt
                                            , 3
                                            )
                               )
                   , 3
                   )
 
    data->qual[data->cnt]->num_hrs       =  concat(hr_holder, ' hrs')
 
with nocounter, expand = 1
 
 
set stat = alterlist(data->qual, data->cnt)
 
 
;Presentation time
if(data->cnt > 0)
    select into $outdev
          PATIENT_NAME    = trim(substring(1, 100, data->qual[d.seq].pat_name     ))
        , DOB             = trim(substring(1,  12, data->qual[d.seq].pat_dob      ))
        , MRN             = trim(substring(1,  20, data->qual[d.seq].pat_mrn      ))
        , FIN             = trim(substring(1,  20, data->qual[d.seq].pat_fin      ))
        , APPT_PROVIDER   = trim(substring(1, 100, data->qual[d.seq].provider     ))
        , DOCUMENT_TYPE   = trim(substring(1,  40, data->qual[d.seq].doc_type     ))
        , FAC_NAME        = trim(substring(1, 100, data->qual[d.seq].fac_name     ))
        , APPT_DATE       = trim(substring(1,  30, data->qual[d.seq].appt_dt_txt  ))
        , SIGN_DATE       = trim(substring(1,  30, data->qual[d.seq].signed_dt_txt))
        , NUMBER_OF_HOURS = trim(substring(1,  20, data->qual[d.seq].num_hrs      ))
 
      from (dummyt d with SEQ = data->cnt)
    with format, separator = " ", time = 300
 
else
   select into $OUTDEV
     from dummyt
    detail
        row + 1
        col 1 "There were no results for your filter selections.."
        col 25
        row + 1
        col 1  "Please Try Your Search Again"
        row + 1
    with format, separator = " "
endif

 
/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
 
 
#exit_script
;DEBUGGING
;call echorecord(loc)
;call echorecord(notes)
;call echorecord(candidate_appts)
call echorecord(data)
 
end
go
 
 
 
 
