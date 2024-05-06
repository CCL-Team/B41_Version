/*************************************************************************
 Program Title: Authorization Documentation Report

 Object name:   14_whc_ins_auth_doc_rep
 Source file:   14_whc_ins_auth_doc_rep.prg

 Purpose:       Provide insight into obtained autorizations for services and will 
                allow us to better analyze pitfalls to improve our financial performance.

 Tables read:

 Executed from:

 Special Notes:



******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 01/05/2023 Michael Mayes        234996 Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 14_whc_ins_auth_doc_rep:dba go
create program 14_whc_ins_auth_doc_rep:dba

prompt
       "Output to File/Printer/MINE" = "MINE"
     , "Start Date"                  = "CURDATE"
     , "End Date"                    = "CURDATE"
     , "Locations"                   = 0.0

with OUTDEV, BEG_DT_TM, END_DT_TM, LOCS




/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record pat_data(
    1 cnt = i4
    1 qual[*]
        2 per_id        = f8
        2 enc_id        = f8
        2 sch_event_id  = f8
        2 event_id      = f8
        2 ord_id        = f8
        2 ord_enc_id    = f8
        2 ord_dt        = dq8
        2 org_id        = f8

        2 name          = vc
        2 dob           = vc
        2 mrn           = vc
        2 fin           = vc
        2 loc_cd        = f8
        2 loc           = vc
        2 ord_name      = vc
        2 proc_loc      = f8
        2 proc_loc_txt  = vc
        2 surg_ind      = i2
        2 surg_prov     = vc
        2 surg_dt       = dq8
        2 surg_dt_txt   = vc
        2 appt_type     = vc
        2 dos           = vc

        2 auth_doc_flag = vc

        2 doc_title     = vc
        2 doc_subtitle  = vc
        2 auth_scan_dt  = vc
)

record locs(
    1 cnt          = i4
    1 qual[*]
        2 loc_name = vc
        2 loc_cd   = f8
        2 org_id   = f8
)


/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/

declare act_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'))
declare mod_cd             = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED'))
declare auth_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'))
declare altr_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'))

/*
declare pos                = i4  with protect, noconstant(0)
*/


declare idx                = i4  with protect, noconstant(0)
declare looper             = i4  with protect, noconstant(0)

declare bill_auth_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',   72, 'BILLINGAUTHORIZATIONS'))
declare pat_port_cd  = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',   72, 'PATIENTPORTALMESSAGE' ))
declare phone_msg_cd = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',   72, 'PHONEMESSAGECALL'     ))

declare clinic_enc   = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',   71, 'CLINIC'               ))
declare outpat_enc   = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',   71, 'OUTPATIENTMESSAGE'    ))
declare recurr_enc   = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',   71, 'RECURRINGCLINIC'      ))
declare amb_surg_enc = f8  with protect,   constant(uar_get_code_by('DISPLAYKEY',   71, 'AMBULATORYSURGERY'    ))

/*************************************************************
; DVDev Start Coding
**************************************************************/

;Org work first
if (0 in ($LOCS))
    select into 'nl:'

      from org_set   os
         , org_set_org_r   osor
         , organization   o
         , location   l
         , code_value cv

     where os.active_ind =  1
       and os.org_set_id  in (6954406.00)
       
       and osor.org_set_id = os.org_set_id
       and osor.active_ind = 1
       
       and o.organization_id = osor.organization_id
       and o.active_ind = 1 
       and l.organization_id = o.organization_id
       and cnvtupper(o.org_name) = '*VASCULAR*'
       and l.location_type_cd = (select cv.code_value 
                                   from code_value cv 
                                  where cv.code_set = 222 
                                    and CDF_MEANING = "AMBULATORY"
                                )
       and l.beg_effective_dt_tm < cnvtdatetime(curdate, curtime3)
       and l.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
       and l.active_ind = 1
       
       and cv.code_value = l.location_cd
    detail 

            locs->cnt = locs->cnt + 1

            stat = alterlist(locs->qual, locs->cnt)

            locs->qual[locs->cnt]->loc_name = cv.display
            locs->qual[locs->cnt]->loc_cd   = l.location_cd
            locs->qual[locs->cnt]->org_id   = l.organization_id
            
    with nocounter
    
    
else
    select into 'nl:'

      from location   l
         , code_value cv
    
     where l.location_cd in ($LOCS)
       
       and cv.code_value = l.location_cd
    
    detail 
            locs->cnt = locs->cnt + 1

            stat = alterlist(locs->qual, locs->cnt)

            locs->qual[locs->cnt]->loc_name = cv.display
            locs->qual[locs->cnt]->loc_cd   = l.location_cd
            locs->qual[locs->cnt]->org_id   = l.organization_id
    with nocounter
    

endif



/**********************************************************************
DESCRIPTION:  Find Appts using filters
      NOTES:
***********************************************************************/
select into 'nl:'
  from encounter        e
     , sch_appt         sa
     ;, sch_appt         res  ;resource
     , sch_event        se
     , orders           o 
     , person           p
     , encntr_alias     ea
     , encntr_alias     ea2
 
 where e.reg_dt_tm between cnvtdatetime($BEG_DT_TM) and cnvtdatetime($END_DT_TM)
   and expand(idx, 1, locs->cnt, e.organization_id, locs->qual[idx].org_id)
   and e.active_ind =  1
   and e.encntr_id > 0
 
   and sa.encntr_id =  e.encntr_id
   and sa.schedule_seq = (select max(sa2.schedule_seq)
                           from sch_appt sa2
                          where sa2.sch_event_id = sa.sch_event_id
                         )
   and sa.sch_role_cd          =  4572.00  ;Patient
   and sa.sch_state_cd         != 4535     ;Canceled
   
   and se.sch_event_id         =  sa.sch_event_id
   
   and p.person_id             =  e.person_id
   and p.active_ind            =  1
   
   and (   (o.originating_encntr_id > 0 and e.encntr_id = o.originating_encntr_id)
        or (o.originating_encntr_id = 0 and e.encntr_id = o.encntr_id)
       )
   and o.person_id              =  e.person_id
   and o.activity_type_cd       =  720.00  ;SURGERY
   and o.order_status_cd   not in (2542.00, 2544.00, 2545.00)  ;Canceled, Voided, Discontinued.

   and ea.encntr_id             =  e.encntr_id
   and ea.encntr_alias_type_cd  =  1079.00   ;MRN
   and ea.active_ind            =  1
   and ea.end_effective_dt_tm   >  cnvtdatetime(curdate, curtime3)

   and ea2.encntr_id            =  e.encntr_id
   and ea2.encntr_alias_type_cd =  1077.00  ;FIN
   and ea2.active_ind           =  1
   and ea2.end_effective_dt_tm  >  cnvtdatetime(curdate, curtime3)

order by e.loc_facility_cd, sa.beg_dt_tm, p.name_full_formatted, sa.sch_event_id

head sa.sch_event_id

    pat_data->cnt = pat_data->cnt + 1

    if(mod(pat_data->cnt, 10) = 1)
        stat = alterlist(pat_data->qual, pat_data->cnt + 9)
    endif

    pat_data->qual[pat_data->cnt]->per_id        = p.person_id
    pat_data->qual[pat_data->cnt]->enc_id        = e.encntr_id
    pat_data->qual[pat_data->cnt]->sch_event_id  = sa.sch_event_id
                                                 
    pat_data->qual[pat_data->cnt]->ord_id        = o.order_id
    pat_data->qual[pat_data->cnt]->ord_enc_id    = o.encntr_id
    pat_data->qual[pat_data->cnt]->ord_dt        = o.orig_order_dt_tm
    pat_data->qual[pat_data->cnt]->ord_name      = trim(o.order_mnemonic, 3)
                                                 
    pat_data->qual[pat_data->cnt]->org_id        = e.organization_id
                                                 
    pat_data->qual[pat_data->cnt]->name          = trim(p.name_full_formatted, 3)
    pat_data->qual[pat_data->cnt]->mrn           = trim(cnvtalias(ea.alias , ea.alias_pool_cd ), 3)
    pat_data->qual[pat_data->cnt]->fin           = trim(cnvtalias(ea2.alias, ea2.alias_pool_cd), 3)
    pat_data->qual[pat_data->cnt]->dob           = format(p.birth_dt_tm, '@SHORTDATE')
    pat_data->qual[pat_data->cnt]->dos           = format(sa.beg_dt_tm, '@SHORTDATE')
                                                 
    pat_data->qual[pat_data->cnt]->appt_type     = uar_get_code_display(se.appt_type_cd)
                                                 
    pat_data->qual[pat_data->cnt]->loc_cd        = e.loc_facility_cd
    pat_data->qual[pat_data->cnt]->loc           = uar_get_code_display(sa.appt_location_cd)
    
    pat_data->qual[pat_data->cnt]->auth_doc_flag = 'N'


foot report
    stat = alterlist(pat_data->qual, pat_data->cnt)

with nocounter, orahintcbo('LEADING(E SA)')


/***********************************************************************
DESCRIPTION:  Retrieve the procedure information
       NOTE:  
***********************************************************************/
select into 'nl:'
  from surg_case_procedure scp
     , surgical_case       sc
     , encounter           e
     , prsnl               name1
     , prsnl               name2
     , (dummyt d with seq = pat_data->cnt)
  
  plan d
   where pat_data->cnt > 0
     and pat_data->qual[d.seq]->ord_id > 0
  
  join scp
   where scp.order_id    =  pat_data->qual[d.seq]->ord_id
  
  join sc
   where sc.surg_case_id =  scp.surg_case_id
   
  join e
   where sc.encntr_id    =  e.encntr_id
   
  join name1
   where name1.person_id =  outerjoin(scp.primary_surgeon_id)
     and name1.person_id != 0
  
  join name2
   where name2.person_id =  outerjoin(scp.sched_primary_surgeon_id)
     and name2.person_id != 0

detail
    
    pat_data->qual[d.seq]->surg_ind     = 1
    pat_data->qual[d.seq]->surg_dt      = sc.surg_start_dt_tm
    pat_data->qual[d.seq]->surg_dt_txt  = format(sc.surg_start_dt_tm, '@SHORTDATE')
    
    if(scp.primary_surgeon_id > 0)      pat_data->qual[d.seq]->surg_prov = trim(name1.name_full_formatted, 3)
    else                                pat_data->qual[d.seq]->surg_prov = trim(name2.name_full_formatted, 3)
    endif
    
    pat_data->qual[d.seq]->proc_loc     = sc.dept_cd
    pat_data->qual[d.seq]->proc_loc_txt = trim(uar_get_code_display(sc.dept_cd), 3)
    
with nocounter



    
/**********************************************************************
DESCRIPTION:  Find Specified Documentation
      NOTES:
***********************************************************************/
select into 'nl:'
  from clinical_event  ce
     , encounter       e
     , ce_event_prsnl  cep
     , (dummyt d with seq = pat_data->cnt)

plan d
 where pat_data->qual[d.seq]->per_id  > 0
   and pat_data->qual[d.seq]->surg_dt > 0
   and pat_data->qual[d.seq]->loc_cd  > 0
   and pat_data->cnt                  > 0

join ce
 where ce.person_id                        =  pat_data->qual[d.seq]->per_id
   and ce.valid_until_dt_tm                >= cnvtdatetime(curdate,curtime3)
   and ce.result_status_cd                 in (act_cd, mod_cd, auth_cd, altr_cd)
   and ce.view_level                       =  1
   and ce.event_end_dt_tm                  >  cnvtdatetime(pat_data->qual[d.seq]->ord_dt)
   and (   pat_data->qual[d.seq]->surg_ind = 0
        or ce.event_end_dt_tm              <  cnvtdatetime(pat_data->qual[d.seq]->surg_dt)
       )
   and ce.event_cd                         in (bill_auth_cd, pat_port_cd, phone_msg_cd)
   and (   cnvtupper(ce.event_title_text) = '*AUTHORIZATION APPROVED*'
        or cnvtupper(ce.event_title_text) = '*PRE*CERTIFICATION*'
        or cnvtupper(ce.event_title_text) = '*APPROVED AUTHORIZATION*'
        or cnvtupper(ce.event_title_text) = '*BILLING INQUIRY*VASCULAR*'
        or cnvtupper(ce.event_title_text) = '*VASCULAR PRE*AUTHORIZATION*'
       )

join e
 where e.encntr_id                    =  ce.encntr_id
   and e.organization_id              =  pat_data->qual[d.seq]->org_id

join cep
 where cep.event_id                   =  ce.event_id
   and cep.action_type_cd             =  104.00  ;Perform
   and cep.valid_until_dt_tm          >= cnvtdatetime(curdate, curtime3)
   and cep.action_dt_tm               = ( select min(cep2.action_dt_tm)
                                             from ce_event_prsnl cep2
                                            where cep2.event_id          =  ce.event_id
                                              and cep2.action_type_cd    =  104.00  ;Perform
                                              and cep2.valid_until_dt_tm >= cnvtdatetime(curdate, curtime3)
                                        )

order by ce.person_id, ce.event_end_dt_tm desc

head ce.person_id

    pat_data->qual[d.seq]->event_id      = ce.event_id 

    pat_data->qual[d.seq]->auth_doc_flag = 'Y'

    pat_data->qual[d.seq]->doc_title     = uar_get_code_display(ce.event_cd)
    pat_data->qual[d.seq]->doc_subtitle  = trim(ce.event_title_text, 3)

    pat_data->qual[d.seq]->auth_scan_dt  = format(cep.action_dt_tm, '@SHORTDATETIME')

with nocounter



;Presentation time
if (pat_data->cnt > 0)

    select into $outdev
         ;debugging
         PER_ID       = pat_data->qual[d.seq]->per_id      ,
         ENC_ID       = pat_data->qual[d.seq]->enc_id      ,
         ORD_ID       = pat_data->qual[d.seq]->ord_id      ,
         EVENT_ID     = pat_data->qual[d.seq]->event_id    ,

           PAT_NAME     = trim(substring(1,   75, pat_data->qual[d.seq].name         ))
         , DOB          = trim(substring(1,   10, pat_data->qual[d.seq].dob          ))
         , MRN          = trim(substring(1,   20, pat_data->qual[d.seq].mrn          ))
         , FIN          = trim(substring(1,   20, pat_data->qual[d.seq].fin          ))
         , LOC          = trim(substring(1,   75, pat_data->qual[d.seq].loc          ))
         , APPT_TYPE    = trim(substring(1,   75, pat_data->qual[d.seq].appt_type    ))
         , LOC_ORDER    = trim(substring(1,   75, pat_data->qual[d.seq].ord_name     ))
         , DOS          = trim(substring(1,   10, pat_data->qual[d.seq].dos          ))
         , PROC_LOC     = trim(substring(1,   75, pat_data->qual[d.seq].proc_loc_txt ))
         , PROC_DT      = trim(substring(1,   10, pat_data->qual[d.seq].surg_dt_txt  ))
         , SURG_PROV    = trim(substring(1,   75, pat_data->qual[d.seq].surg_prov    ))
         , AUTH_DOC     = trim(substring(1,    5, pat_data->qual[d.seq].auth_doc_flag))
         , DOC_TITLE    = trim(substring(1,   50, pat_data->qual[d.seq].doc_title    ))
         , DOC_SUBTITLE = trim(substring(1,   50, pat_data->qual[d.seq].doc_subtitle ))
         , auth_scan_dt = trim(substring(1,   20, pat_data->qual[d.seq].auth_scan_dt ))


      from (dummyt d with seq = pat_data->cnt)
    order by pat_data->qual[d.seq]->surg_dt
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
call echorecord(pat_data)

end
go



