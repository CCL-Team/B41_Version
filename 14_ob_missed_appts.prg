/*********************************************************************************************************************************
 Program Title:     14_ob_missed_appts.prg
 Create Date:       02/19/2020
 Object name:       14_ob_missed_appts
 Source file:       14_ob_missed_appts.prg
 MCGA:              mcga 218307
 OPAS:
 Purpose:           Capture missed OB appointments
 Executed from:     DA2/Report portal
 Special Notes:
 
**********************************************************************************************************************************
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^IMPORTANT^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
**********************************************************************************************************************************
 
This report searches for a "No-Show" appointment in the date range selected, by appointment date, and checks for any "checked-in"
appointments in between the No-show and a future appointment. The report then looks for the last checked in appointment. The EGA
for the patient must be less than 336 days and have an active pregnancy problem code.
 
**********************************************************************************************************************************
**********************************************************************************************************************************
**********************************************************************************************************************************
**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
Mod    Date             Analyst                 MCGA                Comment
---    ----------       --------------------    ------              --------------------------------------------
N/A    02/19/2020       Jeremy Daniel           N/A                 Initial Release
001    05/26/2020       jwd107                  222051              added life cycle status filter/table
002    09/22/2020       jwd107                                      added
003    03/03/2022       Michael Mayes                               Performance investigation for Diedre
004    09/01/2022       Michael Mayes           234553              Several things:
                                                                        1) They want canceled appts too
                                                                        2) OB appts only.  GYN appts should be excluded.
                                                                        3) Want all open preg on report, if they have no future appt
005    02/03/2023       Michael Mayes           PENDING             Another list of stuff...
                                                                        1) We were missing a pregnant patient, due to a historical
                                                                           preg having a higher preg_id on it.  I am trying to use
                                                                           the end date to save us there
                                                                        2) We were seeing a canceled appointment in the next_appt
                                                                           field.  
                                                                        3) They want the next appt location.
006    03/21/2024       Michael Mayes           239118              Moving over to the OBGYN report style EGA calculations.
*************END OF ALL MODCONTROL BLOCKS* ***************************************************************************************/
  drop program 14_ob_missed_appts go
create program 14_ob_missed_appts
 
prompt
      "Output to File/Printer/MINE"      = "MINE"             ;* Enter or select the printer or file name to send this report to.
    , "NS Appointment Date Start Search" = "SYSDATE"
    , "NS Appointment Date End Search"   = "SYSDATE"
    , "Location"                         = 0
with OUTDEV, START_DT, END_DT, Location
 
record rs  (
    1 qual[*]
        2 sch_appt_id          = f8
        2 pt_name              = vc
        2 address              = vc
        2 addr_2               = vc
        2 addr_3               = vc
        2 addr_4               = vc
        2 addr_st              = vc
        2 MRN                  = vc
        2 encntr_id            = f8
        2 person_id            = f8
        2 FIN                  = vc
        2 reg_dt_tm            = dq8
        2 sched_res            = vc
        2 appt_type_cd         = vc
        2 ns_appt_dt_tm        = dq8
        2 prob_appt_dt_tm      = dq8  ;004  Adding this because ns_appt_dt_tm is now conditional on appointment status
        2 candidate_id         = f8
        2 sch_event_id         = f8
        2 sch_appt_id2         = f8
        2 visit_reason         = vc
        2 disch_dt_tm          = dq8
        2 next_appt_dt         = dq8
        2 next_appt_res        = vc
        2 next_appt_clinic     = vc
        2 birth_date           = dq8
        2 hospital_cd          = vc
        2 peds_ind             = i2
        2 user                 = vc
        2 scheduled_state      = vc
        2 org_id               = f8
        2 visit_dt_tm          = dq8
        2 initial_visit_dttm   = dq8
        2 senior_ind           = i2
        2 age                  = i2
        2 zip                  = vc
        2 phone                = vc
        2 active_ip            = i2
        2 EST_ega_DAYS         = i4
        2 EST_ega_weeks        = i4
        2 EST_ega_mod          = i4
        2 PREG_ID              = F8
        2 prob_onset_dt        = dq8
        2 EST_ENTER_DATE       = DQ8
        2 EDD                  = dq8
        2 initial_visit_encntr = f8
        2 APPT_DATE            = vc
        2 appt_status          = vc  ;004
        2 FOL_WITHIN_DAYS      = i4
        2 DAYS_OR_WEEKS        = i4
        2 FOL_WITHIN_RANGE     = vc
        2 REFERRED_TO_PROV     = vc
        2 PROV_PERSON_ID       = f8
        2 CMT_LONG_TEXT_ID     = f8
        2 path_rpt             = vc   ;004
        2 path_rpt_dt          = dq8  ;004
        2 path_rpt_dt_txt      = vc   ;004
        2 deliv_rpt            = vc   ;004
        2 deliv_rpt_dt         = dq8  ;004
        2 deliv_rpt_dt_txt     = vc   ;004
)


declare pos = i4  with protect, noconstant(0)  ;004
declare idx = i4  with protect, noconstant(0)  ;004
 
/****************************************************************************************************
                    APPOINTMENT DATA
*****************************************************************************************************/
 
SELECT into "nl:"

  FROM SCH_APPT            S
     , sch_event           se      ;004
     , encntr_prsnl_reltn  EPR_A
     , encounter           e
     , encntr_alias        ea
     , encntr_alias        ea2
     ;, location           l  ;003 removing
     , ORGANIZATION        O
     ;, PERSON             P
     , PRSNL               PR
     ;, Pregnancy_instance pi  ;003 removing
     ;, pregnancy_estimate pe  ;003 removing
     ;, problem            pb
     ;, ADDRESS            A
     , SCH_BOOKING         SB
     ;, PHONE              PH

  PLAN s 
   where s.active_ind = 1
     and s.sch_appt_id >  0
     and s.sch_role_cd =  4572.00 ;PATIENT
     ;and s.schedule_seq = (select max(s2.schedule_seq);GET MOST RECENT IDX STATUS
     ;                       from SCH_APPT S2
     ;                       where S2.sch_event_id = s.sch_event_id)
     and s.sch_state_cd in (4543.00   ;No Show
                           ,4535.00)  ;004 Canceled
     ;003-> Trying for a better index
     and  (0 in ($Location) or s.appt_location_cd in (select l.location_cd
                                                        from location l
                                                       where l.organization_id in($LOCATION)))
     and s.state_meaning in ('NOSHOW'
                            ,'CANCELED'  ;004
                            )
     ;003<-
     and s.beg_dt_tm between cnvtdatetime($START_DT) and cnvtdatetime($END_DT)
     
     ;004->
     ;Looking for future appointments at any location that are active.  If they exist, this patient doesn't need qualified
     and not exists(
        select 'X'
          from sch_appt  s2
             , sch_event se2
         
         where s2.person_id         = s.person_id
           and s2.active_ind        =  1
           and s2.sch_appt_id       >  0
           and s2.sch_role_cd       =  4572.00 ;PATIENT
           and s2.sch_state_cd not  in ( 4543.00   ;No Show
                                       , 4535.00)  ;004 Canceled
           and s2.state_meaning not in ('NOSHOW'
                                       ,'CANCELED'  ;004
                                       )
           and s2.beg_dt_tm         >  s.beg_dt_tm
           
           and se2.sch_event_id     =  s2.sch_event_id
           and se2.active_ind       =  1
           and se2.appt_type_cd     in ( 1088904487.00, 1093543019.00 ;RETURN OB, NEW PATIENT OBSTETRICS
                                       , 2403667291.00, 1743623967.00 ;Post Partum big-ol-list
                                       , 1091591383.00, 1093492907.00
                                       , 1091595289.00, 1091597373.00
                                       )
     )
     ;004<-

  join sb 
   where sb.encntr_id = outerjoin(s.encntr_id)
     and SB.active_ind = outerjoin(1)
  
  ;004->
  join se
   where se.sch_event_id =  s.sch_event_id
     and se.active_ind   =  1
     and se.appt_type_cd in ( 1088904487.00, 1093543019.00 ;RETURN OB, NEW PATIENT OBSTETRICS
                            , 2403667291.00, 1743623967.00 ;Post Partum big-ol-list
                            , 1091591383.00, 1093492907.00
                            , 1091595289.00, 1091597373.00
                            )
  ;004<-
  
  JOIN EPR_A 
   where epr_a.encntr_id = s.encntr_id
     ;and epr_a.encntr_prsnl_r_cd = attend_doc_cd
     and epr_a.active_ind = 1
     and epr_a.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)

  join e
   where e.encntr_id = s.encntr_id
     and e.encntr_type_cd = 5043178
     and  (0 in ($Location)or e.organization_id in($LOCATION))
     ;and e.reg_dt_tm between cnvtdatetime($START_DT) and cnvtdatetime($END_DT)

  join ea
   where ea.encntr_id = e.encntr_id
     AND EA.encntr_alias_type_cd = 1077.00; FIN
     AND EA.active_ind = 1
     AND EA.beg_effective_dt_tm < cnvtdatetime(curdate,curtime)
     AND EA.end_effective_dt_tm > cnvtdatetime(curdate,curtime)

  join ea2 
   where ea2.encntr_id = e.encntr_id
     AND EA2.encntr_alias_type_cd = 1079.00; MRN
     AND EA2.active_ind = 1
     AND EA2.beg_effective_dt_tm < cnvtdatetime(curdate,curtime)
     AND EA2.end_effective_dt_tm > cnvtdatetime(curdate,curtime)

  ;JOIN L 
    ;WHERE L.location_cd = s.appt_location_cd   ;003 removing this join... we just need the org... we should have it.

  JOIN O 
   WHERE o.organization_id = e.organization_id ;003 changing this for performance.
         ;O.organization_id = l.organization_id
     and o.active_ind = 1

   ;003-> performance of this sucks (Yes really)... I'm going to try and move it below
   ;      I think the complex nature of the query was causing oracle to ignore the PK column... not sure why or how.
   ;JOIN P WHERE P.person_id = s.person_id
   ;and p.active_ind = 1
   ;003<-
   ;       and p.birth_dt_tm < cnvtdatetime(curdate, curtime3) - 23741 ;65 years
   
   ;003-> performance of this sucks... I'm going to try and move it below
   /*
   JOIN PI WHERE PI.person_id = P.person_id and pi.active_ind = 1
   AND Pi.pregnancy_id = (SELECT MAX(pi2.pregnancy_id)
                           from PRegnancy_instance   Pi2
                           where Pi.person_id = pi2.person_id and pi2.active_ind = 1)
   
   join pe where pi.pregnancy_id = pe.pregnancy_id and pe.active_ind = 1
   and pe.pregnancy_estimate_id = (SELECT MAX(pe2.pregnancy_estimate_id)
                           from PRegnancy_estimate  Pe2
                           where Pe.pregnancy_id = pe2.pregnancy_id and pe2.active_ind = 1)
   */

   ;003 do we really need this?  WE don't access the table... just making sure they have an active problem?  
   ;    (WE DO... and it got me in trouble.)
   ;join pb where pb.problem_id = pi.problem_id and pb.active_ind = 1  ;001
   ;and pb.life_cycle_status_cd =        3301.00   ;Active

  join pr 
   where pr.person_id = epr_a.prsnl_person_id

ORDER BY s.person_id, s.schedule_seq

Head Report
    patients = 0
head s.person_id
    patients = patients + 1
    STAT=ALTERLIST(RS->QUAL,PATIENTS)

    rs->QUAL[patients].FIN             = ea.alias
    rs->QUAL[patients].MRN             = ea2.alias
    rs->QUAL[patients].sch_appt_id     = s.sch_appt_id
    rs->QUAL[patients].sch_event_id    = s.sch_event_id
    rs->QUAL[patients].candidate_id    = s.candidate_id
    rs->QUAL[patients].encntr_id       = e.encntr_id
    ;rs->QUAL[patients].visit_dt_tm     = s.beg_dt_tm
    rs->QUAL[patients].REG_DT_TM       = e.reg_dt_tm
    ;004-> They only want this if it is actually a no-show
    if(s.state_meaning = 'NOSHOW')
        rs->QUAL[patients].ns_appt_dt_tm   = s.beg_dt_tm
    endif
    
    rs->QUAL[patients].prob_appt_dt_tm = s.beg_dt_tm
    
    ;rs->QUAL[patients].PT_NAME         = P.name_full_formatted ;003 moved below
    ;rs->QUAL[patients].BIRTH_DATE      = P.birth_dt_tm      ;003 moved below
    rs->QUAL[patients].disch_dt_tm     = e.disch_dt_tm
    rs->QUAL[patients].hospital_cd     = O.org_name
    rs->QUAL[patients].person_id       = e.person_id
    rs->QUAL[patients].org_id          = O.organization_id
    rs->QUAL[patients].scheduled_state = uar_get_code_display(s.sch_state_cd)
    ;rs->qual[patients].age             = cnvtreal(DATETIMEDIFF(cnvtdatetime(curdate, curtime3),P.birth_dt_tm,1)/365.25);003 moved below
    ;rs->qual[patients].zip             = a.zipcode
    ;rs->qual[patients].sched_res       = uar_get_code_display(s.resource_cd)
    rs->qual[patients].visit_reason    = e.reason_for_visit
    rs->qual[patients].appt_type_cd    = uar_get_code_display(sb.appt_type_cd)
    rs->qual[patients].appt_status     = s.state_meaning  ;004
    ;rs->qual[patients].address         = a.street_addr
    ;rs->qual[patients].addr_2          = a.street_addr2
    ;rs->qual[patients].addr_2          = a.street_addr3
    ;rs->qual[patients].addr_2          = a.street_addr4
    ;rs->qual[patients].addr_st         = a.state
    ;rs->qual[patients].phone           = ph.phone_num

    if (e.encntr_type_cd = 309308.00  and e.active_status_cd = 188.00)
        rs->qual[patients].active_ip = 1
    endif

with nocounter, time = 400
   ;003 Person... isn't using the PK... why?!  Trying to use active ind alone and full table scanning.
   , ORAHINTCBO("INDEX( S XIE21SCH_APPT s2 SCH_EVENT_ID) GATHER_PLAN_STATISTICS MONITOR mmm174")
   ,separator = " "
 
 
;004->
/****************************************************************************************************
                    Patients with active pregnancies, with no future appt.
                    They wanted to catch patients that have no appt, but are preg.
                    I have liberties, so I'm looking for patients at the loc in the last 5 years
                    checking for future appointments, and active pregs
*****************************************************************************************************/
;For now I am not going to do this if we don't have a location set.  It does bad things to the query.
if(0 not in ($Location))
    free record persons
    record persons(
        1 cnt = i4
        1 qual[*]
            2 per_id = f8
            2 enc_id = f8
            2 clin_name = vc
            2 mrn = vc
            2 fin = vc
            2 appt_dt = dq8
            2 candidate_id = f8
    )
    
    select into 'nl:'
      from sch_appt     s
         , sch_event    se
         , encounter    e
         , encntr_alias ea
         , encntr_alias ea2
     where s.active_ind  =  1
       and s.sch_appt_id >  0
       and s.sch_role_cd =  4572.00 ;PATIENT
       and s.beg_dt_tm < datetimetrunc(cnvtdatetime(curdate, curtime3), 'DD')
       and s.beg_dt_tm > cnvtlookbehind('1,Y')
       and s.appt_location_cd in (select l.location_cd
                                    from location l
                                   where l.organization_id in($LOCATION))
       
       and se.sch_event_id =  s.sch_event_id
       and se.active_ind   =  1
       and se.appt_type_cd in (1088904487.00, 1093543019.00) ;RETURN OB, NEW PATIENT OBSTETRICS
       
       and not exists(select 'x' 
                        from sch_appt  s1
                           , sch_event se1
                       where s1.person_id        =  s.person_id
                         and s1.active_ind       =  1
                         and s1.sch_appt_id      >  0
                         and s1.sch_role_cd      =  4572.00
                         ;We want to filter out any patients that have a location ANYWHERE...
                         ;and s1.appt_location_cd = s.appt_location_cd
                         and s1.beg_dt_tm        > s.beg_dt_tm
                         and s1.sch_state_cd not in (4535.00, 4540.00, 4543.00 )  ;CANCELED, DELETED, NOSHOW
                         and s1.schedule_seq     = (select max(s2.schedule_seq);GET MOST RECENT IDX STATUS
                                                      from SCH_APPT S2
                                                     where S2.sch_event_id = s1.sch_event_id
                                                   )
       
                         and se1.sch_event_id    =  s1.sch_event_id
                         and se1.active_ind      =  1
                         and se1.appt_type_cd    in ( 1088904487.00, 1093543019.00 ;RETURN OB, NEW PATIENT OBSTETRICS
                                                    , 2403667291.00, 1743623967.00 ;Post Partum big-ol-list
                                                    , 1091591383.00, 1093492907.00
                                                    , 1091595289.00, 1091597373.00
                                                    ) 
                                                                                                  
                     )
    
    
       and e.encntr_id = s.encntr_id  
       
       and ea.encntr_id = e.encntr_id
       and ea.encntr_alias_type_cd = 1077.00; fin
       and ea.active_ind = 1
       and ea.beg_effective_dt_tm < cnvtdatetime(curdate,curtime)
       and ea.end_effective_dt_tm > cnvtdatetime(curdate,curtime)
       
       and ea2.encntr_id = e.encntr_id
       and ea2.encntr_alias_type_cd = 1079.00; mrn
       and ea2.active_ind = 1
       and ea2.beg_effective_dt_tm < cnvtdatetime(curdate,curtime)
       and ea2.end_effective_dt_tm > cnvtdatetime(curdate,curtime)
     
    order by s.person_id
    
    head s.person_id
        persons->cnt = persons->cnt + 1
        
        if(mod(persons->cnt, 10) = 1)
            stat = alterlist(persons->qual, persons->cnt + 9)
        endif
        
        persons->qual[persons->cnt]->per_id       = s.person_id
        persons->qual[persons->cnt]->enc_id       = s.encntr_id
        persons->qual[persons->cnt]->clin_name    = uar_get_code_display(s.appt_location_cd)
        persons->qual[persons->cnt]->mrn          = ea2.alias
        persons->qual[persons->cnt]->fin          = ea.alias
        persons->qual[persons->cnt]->appt_dt      = s.beg_dt_tm
        persons->qual[persons->cnt]->candidate_id = s.candidate_id
        
        
    foot report
        stat = alterlist(persons->qual, persons->cnt)
        
    with nocounter
       , orahintcbo('INDEX(S  XIE21SCH_APPT)')
    
    
    call echorecord(persons)
    
    
    select into 'nl:'
      from Pregnancy_instance   pi
         , PREGNANCY_ESTIMATE   PE
         , problem              pb
         , (dummyt d with seq = persons->cnt)
      plan d
       where persons->cnt > 0
         and persons->qual[d.seq]->per_id > 0
      
      join pi
       where pi.person_id            = persons->qual[d.seq]->per_id
         and pi.active_ind           = 1
          ;and pi.pregnancy_id         = (SELECT MAX(pi2.pregnancy_id)
          and Pi.PREG_END_DT_TM = (SELECT MAX(Pi2.PREG_END_DT_TM)   ;005
                                          from pregnancy_instance   Pi2
                                         where Pi.person_id = pi2.person_id 
                                           and pi2.active_ind = 1
                                       )
      join pe
       where pe.pregnancy_id         = pi.pregnancy_id
         and pe.active_ind           = 1
      
      join pb
       where pe.active_ind           = 1
         and pb.problem_id           = pi.problem_id 
         and pb.active_ind           = 1  ;001
         and pb.life_cycle_status_cd = 3301.00  ;Active
                     
    order by pi.person_id
    
    head report
        patients = size(rs->qual, 5)
        
    head pi.person_id
        call echo('Found patient without appointment, active preg')
        
        ;shouldn't happen, checking anyway.
        pos = locateval(idx, 1, size(rs->qual, 5), pi.person_id, rs->QUAL[idx].person_id)
                        
        if(pos = 0)
            patients = patients + 1
            stat = alterlist(rs->qual, patients)
            
            ;TODO... I need to figure out the joins for this and if the ids are used elsewhere.
            rs->QUAL[patients].FIN             = persons->qual[d.seq]->fin
            rs->QUAL[patients].MRN             = persons->qual[d.seq]->mrn
            
            rs->QUAL[patients].initial_visit_dttm = persons->qual[d.seq]->appt_dt
            
            rs->qual[patients].appt_status      = 'No APPT'
            rs->QUAL[patients].sch_appt_id     = 0  ;s.sch_appt_id
            rs->QUAL[patients].sch_event_id    = 0  ;s.sch_event_id
            rs->QUAL[patients].candidate_id    = persons->qual[d.seq]->candidate_id
            rs->QUAL[patients].scheduled_state = ''  ;uar_get_code_display(s.sch_state_cd)
            ;rs->QUAL[patients].ns_appt_dt_tm   =  s.beg_dt_tm
            
            ;rs->QUAL[patients].encntr_id       = e.encntr_id
            ;rs->QUAL[patients].REG_DT_TM       = e.reg_dt_tm
            ;rs->QUAL[patients].disch_dt_tm     = e.disch_dt_tm
            ;rs->qual[patients].visit_reason    = e.reason_for_visit
            
            rs->QUAL[patients].person_id       = persons->qual[d.seq]->per_id
            rs->QUAL[patients].encntr_id       = persons->qual[d.seq]->enc_id
            rs->qual[patients].initial_visit_encntr = persons->qual[d.seq]->enc_id
            
            rs->QUAL[patients].hospital_cd     = persons->qual[d.seq]->clin_name
            
            ;rs->QUAL[patients].org_id          = O.organization_id
            
            ;rs->qual[patients].appt_type_cd    = uar_get_code_display(sb.appt_type_cd)
            
        endif
        
        
    with nocounter
endif
;004<-

/****************************************************************************************************
                    PERSON Info
                    This sucker would not stop full table scanning above
*****************************************************************************************************/
Select into "nl:"
  FROM person p
     , (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
  plan d1
  join p
   WHERE P.person_id = rs->QUAL[d1.seq].person_id
     and p.active_ind = 1
detail
    rs->QUAL[d1.seq].PT_NAME    = P.name_full_formatted
    rs->QUAL[d1.seq].BIRTH_DATE = P.birth_dt_tm
    rs->qual[d1.seq].age        = cnvtreal(DATETIMEDIFF(cnvtdatetime(curdate, curtime3),P.birth_dt_tm,1)/365.25)
with nocounter
 
 
 
/****************************************************************************************************
                    NEXT/FUTURE IDX APPOINTMENT DATA
*****************************************************************************************************/
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
    ,SCH_APPT S
    ,SCH_APPT S2
 
PLAN D1
    where rs->qual[d1.seq].CANDIDATE_ID != 0  ;004
 
Join S WHERE S.person_id = rs->qual[d1.seq].person_ID
        and s.sch_appt_id >  0
        and s.sch_role_cd =  4572.00 ;PATIENT
        and s.schedule_seq = (select MAX(s2.schedule_seq);GET MOST RECENT IDX STATUS  ;005 This was min... for some reason
                                from SCH_APPT S2
                                where S2.sch_event_id = s.sch_event_id)
        and s.sch_state_cd in (4538.00,4544.00,4545.00,4546.00);confirmed,Pending,Rescheduled,Scheduled
and S.candidate_id != rs->qual[d1.seq].CANDIDATE_ID
and s.beg_dt_tm > cnvtdatetime(curdate, curtime3)
 
JOIN S2 WHERE S2.sch_event_id = s.SCH_EVENT_ID
and S2.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
and S2.role_meaning = "RESOURCE"
and S2.active_ind = 1
 
order by d1.seq, s.beg_dt_tm
 
Head d1.seq
 if (s.beg_dt_tm > cnvtdatetime(curdate, curtime3))
rs->QUAL[d1.seq].next_appt_dt = s.beg_dt_tm
rs->QUAL[d1.seq].next_appt_res = uar_get_code_display(s2.resource_cd)
rs->QUAL[d1.seq].next_appt_clinic = uar_get_code_display(s.appt_location_cd)
rs->QUAL[d1.seq].sch_appt_id2 = s.sch_appt_id
 
else
;rs->QUAL[d1.seq].next_appt_dt = 0
rs->QUAL[d1.seq].next_appt_res = "No result"
rs->QUAL[d1.seq].next_appt_clinic = "No result"
endif
 
with nocounter, time = 400
 
;======================================================================
; GETTING EGA DATA and prob onset (for form limiting later)
;======================================================================
IF (SIZE (RS->QUAL,5) >0)
 
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
 
  , Pregnancy_instance   pi
  , PREGNANCY_ESTIMATE   PE
  , problem              pb
 
PLAN D1
join PI WHERE PI.PERSON_id = rs->qual[d1.seq].PERSON_ID and pi.active_ind = 1
          ;and pi.pregnancy_id         = (SELECT MAX(pi2.pregnancy_id)
          and Pi.PREG_END_DT_TM = (SELECT MAX(Pi2.PREG_END_DT_TM)  ;005
                                from PRegnancy_instance   Pi2
                                where Pi.person_id = pi2.person_id and pi2.active_ind = 1)
 
JOIN PE WHERE PE.pregnancy_id  = pi.pregnancy_id
          AND pe.active_ind = 1
join pb where pb.problem_id = pi.problem_id and pb.active_ind = 1  ;001
          and pb.life_cycle_status_cd =        3301.00  ;Active

 order by d1.seq
 
 DETAIL
    RS->QUAL[d1.seq].PREG_ID        = PI.pregnancy_id
 
 with nocounter, time = 500
 
ENDIF


;testing ->

%i cust_script:14_obgyn_preg_common.inc

declare looper = i4 with protect, noconstant(0)

free set egaReq
record egaReq(
    1 cnt = i4
    1 qual[*]
        2 per_id                  = f8
        2 preg_id                 = f8
        2 ega                     = i4
        2 cur_gest_age            = i4
        2 edd                     = dq8
        2 edd_txt                 = vc
        2 delivered_ind           = i2 
        2 delivered_date          = dq8
        2 delivered_date_txt      = vc
        2 gest_age_at_delivery    = i4 
        2 est_preg_start_date     = dq8
        2 est_preg_start_date_txt = vc
        2 onset_date              = dq8
        2 onset_date_txt          = vc 
        
        2 tri_1_beg               = dq8
        2 tri_1_end               = dq8
        2 tri_2_beg               = dq8
        2 tri_2_end               = dq8
        2 tri_3_beg               = dq8
        2 tri_3_end               = dq8
        
        ;Hooks for this program.
        2 main_rs_index           = i4
)


for(looper = 1 to size(RS->QUAL,5))
    if(rs->qual[looper]->preg_id > 0)
        set egaReq->cnt = egaReq->cnt + 1
        
        set stat = alterlist(egaReq->qual, egaReq->cnt)
    
        set egaReq->qual[egaReq->cnt]->main_rs_index = looper
        
        set egaReq->qual[egaReq->cnt]->per_id = rs->qual[looper].person_id 
        set egaReq->qual[egaReq->cnt]->preg_id = rs->qual[looper].preg_id 
    endif
endfor

call get_preg_data(egaReq)

for(looper = 1 to size(egaReq->QUAL,5))
    set pos = egaReq->qual[looper]->main_rs_index
    
    set rs->qual[pos].edd            = egareq->qual[looper]->edd
    set rs->qual[pos].est_ega_days   = egareq->qual[looper]->ega
    set rs->qual[pos].est_ega_weeks  = rs->qual[pos].est_ega_days / 7
    set rs->qual[pos].est_ega_mod    = mod(rs->qual[pos].est_ega_days, 7)
    
    set rs->qual[pos].prob_onset_dt  = egareq->qual[looper]->onset_date
    
endfor


;testing <-
 
/****************************************************************************************************
                    IDX Checked In APPOINTMENT DATA after the NoShow
*****************************************************************************************************/
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
    ,SCH_APPT S
    ;,SCH_APPT S2
 
 
PLAN D1
    where rs->qual[d1.seq].CANDIDATE_ID != 0  ;004
 
Join S WHERE S.person_id = rs->qual[d1.seq].person_ID
        and s.sch_appt_id >  0
        and s.sch_role_cd =  4572.00 ;PATIENT
        and s.sch_state_cd in (4536.00);checked in
and S.candidate_id != rs->qual[d1.seq].CANDIDATE_ID
and s.beg_dt_tm > cnvtdatetime(rs->qual[d1.seq].prob_appt_dt_tm)
order by d1.seq, s.beg_dt_tm
 
Head d1.seq
rs->QUAL[d1.seq].visit_dt_tm = s.beg_dt_tm
 
with nocounter, time = 400
 
/****************************************************************************************************
                    IDX Checked In APPOINTMENT DATA before the NoShow
*****************************************************************************************************/
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
    ,SCH_APPT S
    ;,SCH_APPT S2
 
 
PLAN D1
    where rs->qual[d1.seq].CANDIDATE_ID != 0  ;004
 
Join S WHERE S.person_id = rs->qual[d1.seq].person_ID
 
        and s.sch_appt_id >  0
        and s.sch_role_cd =  4572.00 ;PATIENT
        and s.sch_state_cd in (4536.00);checked in
        and S.candidate_id != rs->qual[d1.seq].CANDIDATE_ID
        and s.beg_dt_tm < cnvtdatetime(rs->qual[d1.seq].prob_appt_dt_tm)
;       and s.schedule_seq = (select min(s2.schedule_seq);GET MOST RECENT IDX STATUS
;                               from SCH_APPT S2
;                               where S2.sch_event_id = s.sch_event_id)
 
order by d1.seq, s.beg_dt_tm desc
 
Head d1.seq
rs->QUAL[d1.seq].initial_visit_dttm = s.beg_dt_tm
rs->QUAL[d1.seq].initial_visit_encntr = s.encntr_id
 
with nocounter, time = 400
/****************************************************************************************************
                    GETTING CURRENT APPOINTMENT SCHEDULING RESOURCE -MOD034
*****************************************************************************************************/
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
    , SCH_APPT   S
 
PLAN d1
    where rs->qual[d1.seq].SCH_EVENT_ID != 0  ;004
JOIN S WHERE S.sch_event_id = rs->qual[d1.seq].SCH_EVENT_ID
and S.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
and S.role_meaning = "RESOURCE"
and S.active_ind = 1
 
order by d1.seq,s.beg_dt_tm
 
head d1.seq
 
rs->qual[d1.seq].SCHED_RES = uar_get_code_display(s.resource_cd)
with nocounter, time = 400
 
/****************************************************************************************************
                    GETTING ACTIVE INPATIENT INDICATOR
*****************************************************************************************************/
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
    , ENCOUNTER   E
 
PLAN d1
JOIN E WHERE E.person_id = rs->qual[d1.seq].PERSON_ID
and E.encntr_type_cd = 309308.00
and e.active_status_cd = 188.00
AND E.disch_dt_tm = null
 
order by d1.seq
 
head d1.seq
 
rs->qual[D1.SEQ].active_ip = 1
 
with nocounter, time = 400
 
/********************************************************************************************************************************/
; query to retrieve follow up data
 
SELECT DISTINCT into "nl:"
    E.ENCNTR_ID
    , P.PERSON_ID
    , REFERRED_TO_PROV = PE.PROVIDER_NAME
    , APPT_DATE = format(PE.FOL_WITHIN_DT_TM,"MM/DD/YYYY HH:MM;;")
    , FOL_WITHIN_DAYS = PE.FOL_WITHIN_DAYS
    , DAYS_OR_WEEKS = PE.DAYS_OR_WEEKS
    , FOL_WITHIN_RANGE = PE.FOL_WITHIN_RANGE
    , LONG_TEXT = substring(1, 1024, L.LONG_TEXT)
 
FROM
 
    (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
    ,ENCOUNTER E
    , PAT_ED_DOCUMENT P
    , PERSON PER
    , PRSNL PR2
    , PAT_ED_DOC_FOLLOWUP PE
    , LONG_TEXT L
 
plan D1
    where rs->qual[d1.seq].initial_visit_encntr != 0 ;003
join  E WHERE E.ENCNTR_ID = rs->qual[d1.seq].initial_visit_encntr
 
JOIN P WHERE P.ENCNTR_ID = E.ENCNTR_ID
        AND P.PERSON_ID = E.PERSON_ID
JOIN PER WHERE PER.PERSON_ID = E.PERSON_ID
JOIN PR2 WHERE PR2.PERSON_ID = P.SIGNED_ID
JOIN PE WHERE PE.PAT_ED_DOC_ID = P.PAT_ED_DOCUMENT_ID and pe.provider_name != "Follow up*"
JOIN L WHERE L.LONG_TEXT_ID = outerjoin(PE.ADD_LONG_TEXT_ID)
 
detail
    rs->qual[d1.seq].APPT_DATE = format(PE.FOL_WITHIN_DT_TM,"MM/DD/YYYY HH:MM;;");trim(APPT_DATE)
    rs->qual[d1.seq].FOL_WITHIN_DAYS = FOL_WITHIN_DAYS
    rs->qual[d1.seq].DAYS_OR_WEEKS = DAYS_OR_WEEKS
    rs->qual[d1.seq].FOL_WITHIN_RANGE = trim(FOL_WITHIN_RANGE)
    rs->qual[d1.seq].REFERRED_TO_PROV = trim(REFERRED_TO_PROV)
    rs->qual[d1.seq].PROV_PERSON_ID = PE.PROVIDER_ID
    rs->qual[d1.seq].CMT_LONG_TEXT_ID = PE.CMT_LONG_TEXT_ID
 
with
 nocounter
 
;004->
/****************************************************************************************************
                    Looking for forms they are interested in.
*****************************************************************************************************/
select into 'nl:'
  from clinical_event ce
     , (dummyt d with seq = size(rs->qual,5))
  
  plan d
   where size(rs->qual,5)          > 0
     and rs->qual[d.seq].person_id > 0
  
  join ce
   where ce.person_id              =  rs->qual[d.seq].person_id
     and ce.valid_until_dt_tm      >  sysdate
     and ce.event_cd               in ( 4187235    ; Surgical Pathology Report
                                      , 823784657  ; Pathology Report
                                      , 3346986    ; Operative Report
                                      , 69106739   ; Delivery Report
                                      )
                                      
     and ce.event_end_dt_tm        > cnvtdatetime(rs->qual[d.seq].prob_onset_dt)
order by ce.person_id, ce.event_cd, ce.event_end_dt_tm desc

head ce.person_id
    null

head ce.event_cd
    call echo('Found report...')
    call echo(build('rs->qual[d.seq].person_id:', rs->qual[d.seq].person_id                  ))
    call echo(build('ce.event_end_dt_tm       :', format(ce.event_end_dt_tm, '@SHORTDATETIME')))
    call echo(build('ce.event_cd              :', ce.event_cd                                ))
    call echo(build('ce.event_cd              :', uar_get_code_display(ce.event_cd)          ))
    
    
    case(ce.event_cd)
    of 4187235  :
    of 823784657:
    of 3346986  :
        if(ce.event_end_dt_tm > cnvtdatetime(rs->qual[d.seq].path_rpt_dt))
            rs->qual[d.seq].path_rpt         = uar_get_code_display(ce.event_cd)
            rs->qual[d.seq].path_rpt_dt      = cnvtdatetime(ce.event_end_dt_tm)
            rs->qual[d.seq].path_rpt_dt_txt  = format(ce.event_end_dt_tm, '@SHORTDATETIME')
        endif 
    
    of 69106739 :
        rs->qual[d.seq].deliv_rpt        = uar_get_code_display(ce.event_cd)
        rs->qual[d.seq].deliv_rpt_dt     = cnvtdatetime(ce.event_end_dt_tm)
        rs->qual[d.seq].deliv_rpt_dt_txt = format(ce.event_end_dt_tm, '@SHORTDATETIME')
    
    endcase
with nocounter
     

;<-004
 
 
/****************************************************************************************************
                    OUTPUT TO SCREEN
*****************************************************************************************************/
if (size(rs->QUAL,5) > 0); AT LEAST ONE PATIENT FOUND ABOVE
    select into $outdev
     CLINIC_NAME              = trim(substring(1,100,rs->QUAL[d1.seq].hospital_cd))
    ;REG_DT_TM                = format(rs->QUAL[d1.seq].REG_DT_TM, "@SHORTDATETIME")
    ,PT_NAME                  = trim(substring(1,120,rs->QUAL[d1.seq].PT_NAME))
    ,appt_status              = trim(substring(1,120,rs->QUAL[d1.seq].appt_status))   ;004
    ;,CHKIN_APPT_DT           = format(rs->QUAL[d1.seq].visit_dt_tm, "@SHORTDATETIME")
    ;,SCHED_STATE             = trim(substring(1,20,rs->QUAL[d1.seq].scheduled_state))
    ;,APPT_TYPE               = trim(substring(1,100,rs->QUAL[d1.seq].appt_type_cd))
    ;,REASON_FOR_VISIT        = trim(substring(1,120,rs->QUAL[d1.seq].visit_reason))
    ;,SCHEDULED_RESOURCE      = trim(substring(1,120,rs->QUAL[d1.seq].sched_res))
    ;,NEXT_SCHED_APPT_RES     = trim(substring(1,100,rs->QUAL[d1.seq].next_appt_res))
    ;,NEXT_SCHED_APPT_CLIN    = trim(substring(1,100,rs->QUAL[d1.seq].next_appt_clinic))
    ;,sched_appt2             = rs->QUAL[d1.seq].sch_appt_id2
    ;,AGE                     = rs->QUAL[d1.seq].age
    ,BIRTH_DATE               = format(rs->QUAL[d1.seq].BIRTH_DATE, "MM/DD/YYYY;;q")
    ,MRN                      = trim(substring(1,20,rs->QUAL[d1.seq].MRN))
    ,FIN                      = trim(substring(1,20,rs->QUAL[d1.seq].FIN))
    ,EDD                      = format(rs->QUAL[d1.seq].edd, "MM/DD/YYYY;;q")
    ,EGA                      = concat(trim(cnvtstring(rs->qual[d1.seq].EST_ega_weeks)),
                              "W"," ",trim(cnvtstring(rs->qual[d1.seq].EST_ega_mod)), "D")
    ,LAST_APPT                = format(rs->QUAL[d1.seq].initial_visit_dttm, "@SHORTDATETIME")
    ,NS_APPT_DT_TM            = format(rs->QUAL[d1.seq].NS_APPT_DT_TM, "@SHORTDATETIME")
    ,NEXT_SCHED_APPT          = format(rs->QUAL[d1.seq].next_appt_dt, "@SHORTDATETIME")
    ,NEXT_SCHED_APPT_CLIN    = trim(substring(1,100,rs->QUAL[d1.seq].next_appt_clinic))  ;005 She is after this again.  Pulling down
    ,FOLLOW_UP_INSTRUCTIONS   = trim(substring(1,500,rs->QUAL[d1.seq].REFERRED_TO_PROV))
    ,FOLLOW_UP_TIMEFRAME      = trim(substring(1,30,rs->QUAL[d1.seq].FOL_WITHIN_RANGE))
    ,RETURN_TO_CLINIC         = trim(substring(1,30,rs->QUAL[d1.seq].APPT_DATE))
                              
    ;,ADDRESS                 = concat(trim(rs->QUAL[d1.seq].address),trim(rs->QUAL[d1.seq].addr_2),
    ;                         trim(rs->QUAL[d1.seq].addr_3),trim(rs->QUAL[d1.seq].addr_4))
    ;,STATE                   = trim(substring(1,20,rs->QUAL[d1.seq].addr_st))
    ;,ZIP                     = trim(substring(1,20,rs->QUAL[d1.seq].zip))
    ;,PHONE_NUMBER            = trim(substring(1,20,rs->QUAL[d1.seq].phone))
    ,ACTIVE_INPATIENT         = (if (RS->QUAL[d1.seq].ACTIVE_IP > 0) "YES" else "NO" endif)
    ,LAST_PATH_OR_OP_REP      = trim(substring(1,40,rs->QUAL[d1.seq].path_rpt        ))  ;004
    ,LAST_PATH_OR_OP_REP_DATE = trim(substring(1,20,rs->QUAL[d1.seq].path_rpt_dt_txt ))  ;004
    ,LAST_DELIVERY_REP        = trim(substring(1,40,rs->QUAL[d1.seq].deliv_rpt       ))  ;004
    ,LAST_DELIVERY_REP_DATE   = trim(substring(1,20,rs->QUAL[d1.seq].deliv_rpt_dt_txt))  ;004
    ;,init_visit = rs->QUAL[d1.seq].initial_visit_encntr
 
    FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
 
    plan d1
 
    ;where rs->QUAL[d1.seq].PT_NAME != "*ZZZ*"          ;MOD001
    ;where rs->QUAL[d1.seq].med_service_cd !=   950461507.00 ;cancelled
    where rs->qual[d1.seq].EST_ega_DAYS < 336 and rs->QUAL[d1.seq].visit_dt_tm  = null
      and rs->qual[d1.seq].PREG_ID > 0
 
 
    Order by  PT_NAME ;REG_DT_TM DESC
 
    with nocounter, time = 120, format, separator = " "
 
    else
 
 
    select into $OUTDEV
        from dummyt
        Detail
            row + 1
            col 001 "There were no results for your filter selections.."
            col 025
            row + 1
            col 001  "Please Try Your Search Again"
            row + 1
        with format, separator = " "
endif
 
/****************************************************************************************************
                    END OF PROGRAM
*****************************************************************************************************/
#EXIT_PROGRAM
;call echorecord(rs)


end
go
 