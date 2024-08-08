/***************************************************************************************************
 Program Title:     Social Needs Screening Report by Hospital and DC Date
 Object name:       7_SOCIAL_NEEDS_SCRN_RPT
 Source file:       7_SOCIAL_NEEDS_SCRN_RPT.prg
 Purpose:           To measure productivity and gather metrics of social  determinance of health
 Executed from:     DA2 / Reporting Portal
 Special Notes:     Requested by Nancy Oaks (Ancillaries)
****************************************************************************************************
                                  MODIFICATION CONTROL LOG
****************************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ ----------------------------------------------------
000 03/04/2020 David Smith          220698 Initial Release
001 06/10/2020 David Smith          222247 Adding Additional Search Option
                                           Adding Detailed Version
002 12/22/2020 David Smith          225046 Adding MRN to Output
003 03/09/2021 David Smith          226231 Adding File Creation Option
004 08/02/2021 Michael Mayes        228460 New demographics columns and formatting work.
!!!NOTE!!!  There was a hard collision here between Asha Patil(230997) and I Michael Mayes(228460)...
            I spent some time trying to merge the two changes... but it's intense...
            Instead I'm going to separate this out into an extract verison... if there are changes here... or there...
            we might need to review the other script as well.  If this is problematic... blame me and force me to
            reconcile the merge conflict.
            Extract Script: 7_SOCIAL_NEEDS_SCRN_EXT
            Report Script : 7_SOCIAL_NEEDS_SCRN_RPT
007 10/25/2023 Michael Mayes        240357 Work to pull in new forms.
*****************************************************************************************************/
  drop program 7_SOCIAL_NEEDS_SCRN_EXT go
create program 7_SOCIAL_NEEDS_SCRN_EXT

prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Search Mode"               = 1
    , "Between:"                  = "SYSDATE"
    , "and:"                      = "SYSDATE"
    , "Location(s):"              = 0
    , "Output"                    = 2

with OUTDEV, searchMode, START_DT, END_DT, FAC, output


;***********************************************************************************************
;                           VARIABLE DECLARATIONS
;***********************************************************************************************
declare modifiedCd   = f8 with public, noconstant(uar_get_code_by("MEANING",8,"MODIFIED"               ))
declare alteredCd    = f8 with public, noconstant(uar_get_code_by("MEANING",8,"ALTERED"                ))
declare authverifyCd = f8 with public, noconstant(uar_get_code_by("MEANING",8,"AUTH"                   ))
declare componentCd  = f8 with           constant(uar_get_code_by("DISPLAY_KEY", 18189,"PRIMARYEVENTID"))

if($OUTPUT = 3);File Creation
    DECLARE FILE_NAME = VC WITH NOCONSTANT("")

    ;TESTING DIRECTORY
    ;;;SET FILE_NAME = CONCAT( "/cerner/d_p41/cust_output_2/crisp_social_needs/testing/social_needs_screen_rpt"
    ;;;                      , format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q")
    ;;;                      , trim(substring(3,3,cnvtstring(RAND(0))))     ;<<<< These 3 digits are random #s
    ;;;                      , ".csv")

    ;PRODUCTION DIRECTORY
    SET FILE_NAME = CONCAT( "/cerner/d_p41/cust_output_2/crisp_social_needs/social_needs_screen_rpt"
                          , format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q")
                          , trim(substring(3,3,cnvtstring(RAND(0))))     ;<<<< These 3 digits are random #s
                          ,  ".csv")

endif


/****************************************************************************************************
                            SUBROUTINES
*****************************************************************************************************/
DECLARE quote_sub(csv_str = vc) = vc
subroutine quote_sub(csv_str)
    declare ret_str = vc with protect, noconstant(csv_str)

    if(textlen(ret_str) >= 1)
        set ret_str = build2('"',trim(ret_str),'"')
    else
        set ret_str = null
    endif

    return(ret_str)
end

;This is a monster, and I'm putting it at the bottom of the script.
declare org_source_translate(org_id = f8) = vc


;***********************************************************************************************
;                           RECORD STRUCTURE
;***********************************************************************************************
free record pts
record pts(
    1 qual[*]
        2 per_id           = f8  ;004
        2 enc_id           = f8  ;004
        2 form_act_id      = f8  ;004
        2 form             = vc  ;007 Debugging
        2 form_dt_tm       = dq8
        2 dc_dt_tm         = dq8
        2 facility         = vc
        2 org_id           = f8  ;004 This is a validation change... wanted codified location.
        2 org_name         = vc  ;004 debugging
        2 org_source_code  = vc  ;004 This is a validation change... wanted codified location.
        2 name             = vc
        2 fin              = vc
        2 mrn              = vc

        2 bene_first_name  = vc  ;004
        2 bene_last_name   = vc  ;004
        2 bene_phone       = vc  ;004
        2 bene_dob         = vc  ;004
        2 bene_add         = vc  ;004
        2 bene_city        = vc  ;004
        2 bene_state       = vc  ;004
        2 bene_zip         = vc  ;004
        2 screen_perf_prov = vc  ;004

        2 trigger_question = vc
        2 hard_to_pay      = vc
        2 worried_food     = vc
        2 food_didnt_last  = vc
        2 unable_pay_rent  = vc
        2 no_place_to_live = vc
        2 no_transport     = vc
        2 hard_to_get_job  = vc
        2 threats_utility  = vc
        2 risk_level       = vc
)

free record det
record det(
    1 qual[*]
        2 event_cd   = vc
        2 result_val = vc
        2 form       = vc  ;007 Debugging
        2 form_dt_tm = dq8
        2 dc_dt_tm   = dq8
        2 facility   = vc
        2 name       = vc
        2 fin        = vc
        2 mrn        = vc
)


/****************************************************************************************************
                    GETTING ALL INSTANCES OF POWERFORM THAT WERE CHARTED
*****************************************************************************************************/
if($output in(2, 3));Summary Version, Summary Version Extract

    if($searchMode = 1);By Discharge Date
        select into 'nl:'
          from ENCOUNTER               E
             , dcp_forms_activity      dfa
             , dcp_forms_ref           dfr  ;DEBUGGING
             , PERSON                  P
             , dcp_forms_activity_comp dfac
             , clinical_event          ce1 ;FORM
             , clinical_event          ce2 ;FORM EVENT CODES
             , ENCNTR_ALIAS            EA  ;MOD002
             , prsnl                   per ;004

          PLAN E
           Where E.disch_dt_tm between cnvtdatetime($START_DT) and cnvtdatetime($END_DT)
             and (   0 in($FAC)
                  or e.organization_id in($FAC))

          JOIN DFA
           where dfa.encntr_id              =  e.encntr_id
             ;007 Big time work here.
             and dfa.dcp_forms_ref_id in (  6293764555.00  ;Social Needs Screening Questionnaire
                                         , 20622604823.00  ;Community Health Advocate Forms
                                         , 20254663993.00  ;MDPCP Social Needs Screening Questionnaire
                                         , 13548485485.00  ;MDPCP Social Needs Assessment and Work Report
                                         , 10315593293.00  ;HIV/STD Intake and Testing Services
                                         ;,  4478902169.00  ;Post Discharge Follow-Up Phone Call
                                         , 11920359457.00  ;Supporting Families During COVID
                                         , 19676314995.00  ;Initial Discharge Planning Assess Form
                                         ,  2666480733.00  ;CIR CM Initial Evaluation P3+
                                         ) 
             and dfa.active_ind             =  1
             and dfa.form_status_cd         in (modifiedCd, alteredCd, authverifyCd)
           
          join dfr 
           where dfa.dcp_forms_ref_id = dfr.dcp_forms_ref_id
             and dfr.active_ind       = 1

          JOIN P
           WHERE P.person_id                =  dfa.person_id

          JOIN dfac
           where dfac.dcp_forms_activity_id =  dfa.dcp_forms_activity_id
             and dfac.component_cd          =  componentCd
             and dfac.parent_entity_name    =  'CLINICAL_EVENT'

          join ce1
           where ce1.parent_event_id        =  dfac.parent_entity_id
             and ce1.parent_event_id        != ce1.event_id
             and ce1.result_status_cd       in (modifiedCd, alteredCd, authverifyCd)
             and ce1.valid_until_dt_tm      >  cnvtdatetime(curdate, curtime3)

          join ce2
           where ce2.parent_event_id        =  ce1.event_id
             and ce2.result_status_cd       in (modifiedCd, alteredCd, authverifyCd)
             and ce2.valid_until_dt_tm      >  cnvtdatetime(curdate, curtime3)

          join ea
           where ea.encntr_id               =  e.encntr_id
             and ea.encntr_alias_type_cd    =  1079.00 ; MRN
             and ea.active_ind              =  1
             and ea.end_effective_dt_tm     >  cnvtdatetime(curdate, curtime3)

          join per                                                                ;004
           where per.person_id              =  outerjoin(ce1.performed_prsnl_id)  ;004

        order by dfa.dcp_forms_activity_id

        Head Report
            count = 0

        Head dfa.dcp_forms_activity_id
            count = count + 1
            STAT = ALTERLIST(PTS->QUAL,COUNT)

            PTS->QUAL[COUNT].per_id           = p.person_id                       ;004
            PTS->QUAL[COUNT].enc_id           = e.encntr_id                       ;004
            PTS->QUAL[COUNT].form_act_id      = dfac.dcp_forms_activity_id        ;004
            ;004->
            if(ce1.performed_prsnl_id > 0)
                PTS->QUAL[COUNT].screen_perf_prov = trim(per.name_full_formatted, 3)
            else
                PTS->QUAL[COUNT].screen_perf_prov = 'UNKNOWN' ;don't think this actually happens.  But it is speced.
            endif
            ;004<-

            PTS->QUAL[COUNT].name             = P.name_full_formatted
            PTS->QUAL[COUNT].dc_dt_tm         = e.disch_dt_tm
            PTS->QUAL[COUNT].form_dt_tm       = dfa.form_dt_tm
            PTS->QUAL[COUNT].form             = dfr.description  ;007
            PTS->QUAL[COUNT].facility         = uar_get_code_Display(e.loc_building_cd)
            PTS->QUAL[COUNT].mrn              = CNVTALIAS(ea.alias, ea.alias_pool_cd) ;MOD002

            PTS->QUAL[COUNT].org_id           = e.organization_id  ;004

        Detail
            
            if(    ce2.event_cd = 1674073889.00) PTS->QUAL[COUNT].food_didnt_last  = ce2.result_val ; Food didn't last
            elseif(ce2.event_cd = 1674074235.00) PTS->QUAL[COUNT].hard_to_get_job  = ce2.result_val ; Hard to get/keep job
            elseif(ce2.event_cd = 1674073835.00) PTS->QUAL[COUNT].worried_food     = ce2.result_val ; Worried food would run out
            elseif(ce2.event_cd = 1674073779.00) PTS->QUAL[COUNT].hard_to_pay      = ce2.result_val ; Hard to pay for basics
            elseif(ce2.event_cd = 1674074175.00) PTS->QUAL[COUNT].no_transport     = ce2.result_val ; No access to transportation
            elseif(ce2.event_cd = 1693023911.00) PTS->QUAL[COUNT].risk_level       = ce2.result_val ; Risk Level
            elseif(ce2.event_cd = 1674074101.00) PTS->QUAL[COUNT].no_place_to_live = ce2.result_val ; No place to live/live w fam
            elseif(ce2.event_cd = 1674074289.00) PTS->QUAL[COUNT].threats_utility  = ce2.result_val ; Threats of utility shutoffs
            elseif(ce2.event_cd = 1674073695.00) PTS->QUAL[COUNT].trigger_question = ce2.result_val ; Trigger Question
            elseif(ce2.event_cd = 1674073945.00) PTS->QUAL[COUNT].unable_pay_rent  = ce2.result_val ; Unable to pay Rent/Mortgage
            endif

        with nocounter

    elseif($searchMode = 2);By Form Date

        select into 'nl:'
          from ENCOUNTER               E
             , dcp_forms_activity      dfa
             , dcp_forms_ref           dfr  ;DEBUGGING
             , PERSON                  P
             , dcp_forms_activity_comp dfac
             , clinical_event          ce1 ;FORM
             , clinical_event          ce2 ;FORM EVENT CODES
             , ENCNTR_ALIAS            EA  ;MOD002
             , prsnl                   per ;004

          PLAN DFA
           ;007 Big time work here.
           where dfa.dcp_forms_ref_id in (  6293764555.00  ;Social Needs Screening Questionnaire
                                         , 20622604823.00  ;Community Health Advocate Forms
                                         , 20254663993.00  ;MDPCP Social Needs Screening Questionnaire
                                         , 13548485485.00  ;MDPCP Social Needs Assessment and Work Report
                                         , 10315593293.00  ;HIV/STD Intake and Testing Services
                                         ;,  4478902169.00  ;Post Discharge Follow-Up Phone Call
                                         , 11920359457.00  ;Supporting Families During COVID
                                         , 19676314995.00  ;Initial Discharge Planning Assess Form
                                         ,  2666480733.00  ;CIR CM Initial Evaluation P3+
                                         ) 
             and dfa.form_dt_tm between cnvtdatetime($START_DT) and cnvtdatetime($END_DT)
             and dfa.active_ind = 1
             and dfa.form_status_cd in (modifiedCd, alteredCd, authverifyCd)
           
          join dfr 
           where dfa.dcp_forms_ref_id = dfr.dcp_forms_ref_id
             and dfr.active_ind       = 1

          JOIN E
           Where e.encntr_id = dfa.encntr_id
             and (   0 in($FAC)
                  or e.organization_id in($FAC))

          JOIN P
           WHERE P.person_id = e.person_id

          JOIN dfac
           where dfac.dcp_forms_activity_id =  dfa.dcp_forms_activity_id
             and dfac.component_cd          =  componentCd
             and dfac.parent_entity_name    =  'CLINICAL_EVENT'

          join ce1
           where ce1.parent_event_id        =  dfac.parent_entity_id
             and ce1.parent_event_id        != ce1.event_id
             and ce1.result_status_cd       in (modifiedCd, alteredCd, authverifyCd)
             and ce1.valid_until_dt_tm      >  cnvtdatetime(curdate, curtime3)

          join ce2
           where ce2.parent_event_id        =  ce1.event_id
             and ce2.result_status_cd       in (modifiedCd, alteredCd, authverifyCd)
             and ce2.valid_until_dt_tm      >  cnvtdatetime(curdate, curtime3)

          join ea
           where ea.encntr_id               =  e.encntr_id
             and ea.encntr_alias_type_cd    =  1079.00 ; MRN
             and ea.active_ind              =  1
             and ea.end_effective_dt_tm     >  cnvtdatetime(curdate, curtime3)

          join per                                                                ;004
           where per.person_id              =  outerjoin(ce1.performed_prsnl_id)  ;004

        order by dfa.dcp_forms_activity_id

        Head Report
            count = 0

        Head dfa.dcp_forms_activity_id
            count = count + 1
            STAT=ALTERLIST(PTS->QUAL,COUNT)

            PTS->QUAL[COUNT].per_id           = p.person_id                       ;004
            PTS->QUAL[COUNT].enc_id           = e.encntr_id                       ;004
            PTS->QUAL[COUNT].form_act_id      = dfac.dcp_forms_activity_id        ;004
            ;004->
            if(ce1.performed_prsnl_id > 0)
                PTS->QUAL[COUNT].screen_perf_prov = trim(per.name_full_formatted, 3)
            else
                PTS->QUAL[COUNT].screen_perf_prov = 'UNKNOWN' ;don't think this actually happens.  But it is speced.
            endif
            ;004<-

            PTS->QUAL[COUNT].name             = P.name_full_formatted
            PTS->QUAL[COUNT].dc_dt_tm         = e.disch_dt_tm
            PTS->QUAL[COUNT].form_dt_tm       = dfa.form_dt_tm
            PTS->QUAL[COUNT].form             = dfr.description  ;007
            PTS->QUAL[COUNT].facility         = uar_get_code_Display(e.loc_building_cd)  ;004 This is going to not be sent.
            PTS->QUAL[COUNT].mrn              = CNVTALIAS(ea.alias, ea.alias_pool_cd) ;MOD002

            PTS->QUAL[COUNT].org_id           = e.organization_id  ;004

        Detail
            
            if(    ce2.event_cd = 1674073889.00) PTS->QUAL[COUNT].food_didnt_last  = ce2.result_val ; Food didn't last
            elseif(ce2.event_cd = 1674074235.00) PTS->QUAL[COUNT].hard_to_get_job  = ce2.result_val ; Hard to get/keep job
            elseif(ce2.event_cd = 1674073835.00) PTS->QUAL[COUNT].worried_food     = ce2.result_val ; Worried food would run out
            elseif(ce2.event_cd = 1674073779.00) PTS->QUAL[COUNT].hard_to_pay      = ce2.result_val ; Hard to pay for basics
            elseif(ce2.event_cd = 1674074175.00) PTS->QUAL[COUNT].no_transport     = ce2.result_val ; No access to transportation
            elseif(ce2.event_cd = 1693023911.00) PTS->QUAL[COUNT].risk_level       = ce2.result_val ; Risk Level
            elseif(ce2.event_cd = 1674074101.00) PTS->QUAL[COUNT].no_place_to_live = ce2.result_val ; No place to live/live w fam
            elseif(ce2.event_cd = 1674074289.00) PTS->QUAL[COUNT].threats_utility  = ce2.result_val ; Threats of utility shutoffs
            elseif(ce2.event_cd = 1674073695.00) PTS->QUAL[COUNT].trigger_question = ce2.result_val ; Trigger Question
            elseif(ce2.event_cd = 1674073945.00) PTS->QUAL[COUNT].unable_pay_rent  = ce2.result_val ; Unable to pay Rent/Mortgage
            endif

        with nocounter

    endif

    ;004->
    /* We now want a few changes...  New demographics columns, as well as CSV formatting changes.
       This is the first part of that work.
    */
    select into 'nl:'
      from person  p
         , phone   ph
         , address a
         , (dummyt d with seq = value(size(pts->qual, 5)))

      plan d
       where size(pts->qual, 5)           >  0
         and pts->qual[d.seq]->per_id     >  0

      join p
       where p.person_id                  =  pts->qual[d.seq]->per_id
         and p.active_ind                 =  1

      join ph
       where ph.parent_entity_name        =  outerjoin('PERSON')
         and ph.parent_entity_id          =  outerjoin(p.person_id)
         and ph.phone_type_seq            =  outerjoin(1)
         and ph.active_ind                =  outerjoin(1)
         and ph.end_effective_dt_tm       >= outerjoin(cnvtdatetime(curdate, curtime3))

      join a
       where a.parent_entity_name        =  outerjoin('PERSON')
         and a.parent_entity_id          =  outerjoin(p.person_id)
         and a.address_type_seq          =  outerjoin(1)
         and a.active_ind                =  outerjoin(1)
         ;Emails popped through... they have a address type seq = 1 too.
         and a.address_type_cd           != 755    ;uar_get_code_by('MEANING', 212, 'EMAIL')
         and a.end_effective_dt_tm       >= outerjoin(cnvtdatetime(curdate, curtime3))

    detail
        pts->qual[d.seq]->bene_first_name =  trim(p.name_first, 3)
        pts->qual[d.seq]->bene_last_name  =  trim(p.name_last , 3)
        pts->qual[d.seq]->bene_dob        =  format(p.birth_dt_tm, 'YYYY-MM-DD')

        ;PHONE_NUM_KEY (9999999999) ;PHONE_NUM ((999)999-9999)
        pts->qual[d.seq]->bene_phone      =  format(trim(ph.phone_num_key, 3), '###-###-####')

        pts->qual[d.seq]->bene_add        =  trim(a.street_addr             , 3)
        pts->qual[d.seq]->bene_city       =  trim(a.city                    , 3)
        pts->qual[d.seq]->bene_state      =  trim(a.state                   , 3)
        pts->qual[d.seq]->bene_zip        =  trim(substring(1, 5, a.zipcode), 3)

    with nocounter


    ;004->
    select into 'nl:'
      from organization o
         , (dummyt d with seq = value(size(pts->qual, 5)))

      plan d
       where size(pts->qual, 5)           >  0
         and pts->qual[d.seq]->org_id     >  0

      join o
       where o.organization_id            =  pts->qual[d.seq]->org_id
         and o.active_ind                 =  1
    detail
        pts->qual[d.seq]->org_source_code = org_source_translate(o.organization_id)

        pts->qual[d.seq]->org_name = o.ORG_NAME
    with nocounter

    ;004<-

elseif($output = 1);Detailed Version

    if($searchMode = 1);By Discharge Date

        select into 'nl:'
          from ENCOUNTER               E
             , dcp_forms_activity      dfa
             , dcp_forms_ref           dfr  ;DEBUGGING
             , PERSON                  P
             , dcp_forms_activity_comp dfac
             , clinical_event          ce1 ;FORM
             , clinical_event          ce2 ;FORM EVENT CODES
             , ENCNTR_ALIAS            EA  ;MOD002

          PLAN E
           Where E.disch_dt_tm between cnvtdatetime($START_DT) and cnvtdatetime($END_DT)
             and (   0 in($FAC)
                  or e.organization_id in($FAC))

          JOIN DFA
           where dfa.encntr_id              =  e.encntr_id
             ;007 Big time work here.
             and dfa.dcp_forms_ref_id       in (  6293764555.00  ;Social Needs Screening Questionnaire
                                               , 20622604823.00  ;Community Health Advocate Forms
                                               , 20254663993.00  ;MDPCP Social Needs Screening Questionnaire
                                               , 13548485485.00  ;MDPCP Social Needs Assessment and Work Report
                                               , 10315593293.00  ;HIV/STD Intake and Testing Services
                                               ;,  4478902169.00  ;Post Discharge Follow-Up Phone Call
                                               , 11920359457.00  ;Supporting Families During COVID
                                               , 19676314995.00  ;Initial Discharge Planning Assess Form
                                               ,  2666480733.00  ;CIR CM Initial Evaluation P3+
                                               ) 
             and dfa.active_ind             =  1
             and dfa.form_status_cd         in (modifiedCd, alteredCd, authverifyCd)
           
          join dfr 
           where dfa.dcp_forms_ref_id = dfr.dcp_forms_ref_id
             and dfr.active_ind       = 1
          JOIN P
           WHERE P.person_id                = dfa.person_id
          JOIN dfac
           where dfac.dcp_forms_activity_id = dfa.dcp_forms_activity_id
             and dfac.component_cd          = componentCd
             and dfac.parent_entity_name    = 'CLINICAL_EVENT'
          join ce1
           where ce1.parent_event_id       =  dfac.parent_entity_id
             and ce1.parent_event_id       != ce1.event_id
             and ce1.result_status_cd      in (modifiedCd, alteredCd, authverifyCd)
             and ce1.valid_until_dt_tm     >  cnvtdatetime(curdate, curtime3)
          join ce2
           where ce2.parent_event_id       =  ce1.event_id
             and ce2.result_status_cd      in (modifiedCd, alteredCd, authverifyCd)
             and ce2.valid_until_dt_tm     >  cnvtdatetime(curdate, curtime3)
             and ce2.event_cd              in (1674073889.00   ; Food didn't last
                                              ,1674074235.00   ; Hard to get/keep job
                                              ,1674073835.00   ; Worried food would run out
                                              ,1674073779.00   ; Hard to pay for basics
                                              ,1674074175.00   ; No access to transportation
                                              ,1693023911.00   ; Risk Level
                                              ,1674074101.00   ; No place to live/live w fam
                                              ,1674074289.00   ; Threats of utility shutoffs
                                              ,1674073695.00   ; Trigger Question
                                              ,1674073945.00)  ; Unable to pay Rent/Mortgage

          join ea
           where ea.encntr_id               =  e.encntr_id
             and ea.encntr_alias_type_cd    =  1079.00 ; MRN
             and ea.active_ind              =  1
             and ea.end_effective_dt_tm     >  cnvtdatetime(curdate, curtime3)
        Head Report
            count = 0

        Detail
            count = count + 1
            STAT=ALTERLIST(det->QUAL,COUNT)

            det->QUAL[COUNT].name       = P.name_full_formatted
            det->QUAL[COUNT].dc_dt_tm   = e.disch_dt_tm
            PTS->QUAL[COUNT].form       = dfr.description  ;007
            det->QUAL[COUNT].form_dt_tm = dfa.form_dt_tm
            det->QUAL[COUNT].facility   = uar_get_code_Display(e.loc_building_cd)
            det->QUAL[COUNT].event_cd   = trim(uar_get_code_description(ce2.event_cd))
            det->QUAL[COUNT].result_val = trim(ce2.result_val)
            det->QUAL[COUNT].mrn        = CNVTALIAS(ea.alias, ea.alias_pool_cd) ;MOD002

        with nocounter

    elseif($searchMode = 2);By Form Date

        select into 'nl:'
          from ENCOUNTER               E
             , dcp_forms_activity      dfa
             , dcp_forms_ref           dfr  ;DEBUGGING
             , PERSON                  P
             , dcp_forms_activity_comp dfac
             , clinical_event          ce1 ;FORM
             , clinical_event          ce2 ;FORM EVENT CODES
             , ENCNTR_ALIAS            EA  ;MOD002

          PLAN DFA
           where dfa.form_dt_tm             between cnvtdatetime($START_DT) and cnvtdatetime($END_DT)
             ;007 Big time work here.
             and dfa.dcp_forms_ref_id in (  6293764555.00  ;Social Needs Screening Questionnaire
                                         , 20622604823.00  ;Community Health Advocate Forms
                                         , 20254663993.00  ;MDPCP Social Needs Screening Questionnaire
                                         , 13548485485.00  ;MDPCP Social Needs Assessment and Work Report
                                         , 10315593293.00  ;HIV/STD Intake and Testing Services
                                         ;,  4478902169.00  ;Post Discharge Follow-Up Phone Call
                                         , 11920359457.00  ;Supporting Families During COVID
                                         , 19676314995.00  ;Initial Discharge Planning Assess Form
                                         ,  2666480733.00  ;CIR CM Initial Evaluation P3+
                                         ) 
             and dfa.active_ind             =  1
             and dfa.form_status_cd         in (modifiedCd, alteredCd, authverifyCd)
           
          join dfr 
           where dfa.dcp_forms_ref_id = dfr.dcp_forms_ref_id
             and dfr.active_ind       = 1

          JOIN E
           Where e.encntr_id                =  dfa.encntr_id
             and (   0 in($FAC)
                  or e.organization_id in($FAC))

          JOIN P
           WHERE P.person_id                =  e.person_id

          JOIN dfac
           where dfac.dcp_forms_activity_id = dfa.dcp_forms_activity_id
             and dfac.component_cd          = componentCd
             and dfac.parent_entity_name    = 'CLINICAL_EVENT'

          join ce1
           where ce1.parent_event_id        =  dfac.parent_entity_id
             and ce1.parent_event_id        != ce1.event_id
             and ce1.result_status_cd       in (modifiedCd, alteredCd, authverifyCd)
             and ce1.valid_until_dt_tm      >  cnvtdatetime(curdate, curtime3)

          join ce2
           where ce2.parent_event_id        =  ce1.event_id
             and ce2.result_status_cd       in (modifiedCd, alteredCd, authverifyCd)
             and ce2.valid_until_dt_tm      >  cnvtdatetime(curdate, curtime3)
             and ce2.event_cd               in( 1674073889.00   ; Food didn't last
                                              , 1674074235.00   ; Hard to get/keep job
                                              , 1674073835.00   ; Worried food would run out
                                              , 1674073779.00   ; Hard to pay for basics
                                              , 1674074175.00   ; No access to transportation
                                              , 1693023911.00   ; Risk Level
                                              , 1674074101.00   ; No place to live/live w fam
                                              , 1674074289.00   ; Threats of utility shutoffs
                                              , 1674073695.00   ; Trigger Question
                                              , 1674073945.00)  ; Unable to pay Rent/Mortgage

          join ea
           where ea.encntr_id               =  e.encntr_id
             and ea.encntr_alias_type_cd    =  1079.00 ; MRN
             and ea.active_ind              =  1
             and ea.end_effective_dt_tm     >  cnvtdatetime(curdate, curtime3)
        Head Report
            count = 0

        Detail
            count = count + 1
            STAT=ALTERLIST(det->QUAL,COUNT)

            det->QUAL[COUNT].name       = P.name_full_formatted
            det->QUAL[COUNT].dc_dt_tm   = e.disch_dt_tm
            det->QUAL[COUNT].form       = dfr.description  ;007
            det->QUAL[COUNT].form_dt_tm = dfa.form_dt_tm
            det->QUAL[COUNT].facility   = uar_get_code_Display(e.loc_building_cd)
            det->QUAL[COUNT].event_cd   = trim(uar_get_code_description(ce2.event_cd))
            det->QUAL[COUNT].result_val = trim(ce2.result_val)
            det->QUAL[COUNT].mrn        = CNVTALIAS(ea.alias, ea.alias_pool_cd) ;MOD002

        with nocounter

    endif

endif
;***********************************************************************************************
;                           OUTPUT DATA TO SCREEN
;***********************************************************************************************
if(size(PTS->QUAL,5) > 0 or size(DET->QUAL,5) > 0)

    if($output = 2);Summary Version
        Select into $OUTDEV
         NAME                       = trim(substring(1, 100,PTS->QUAL[D1.SEQ].name            ))
        ,FACILITY                   = trim(substring(1, 100,PTS->QUAL[D1.SEQ].facility        ))
        ,MRN                        = trim(substring(1,  25,PTS->QUAL[D1.SEQ].MRN              ));MOD002
        ,DISCHARGE_DT_TM            = format(PTS->QUAL[D1.SEQ].dc_dt_tm  ,"@SHORTDATETIME"     )
        ,FORM_DT_TM                 = format(PTS->QUAL[D1.SEQ].form_dt_tm,"@SHORTDATETIME"     )
        ,TRIGGER_QUESTION           = trim(substring(1, 25,PTS->QUAL[D1.SEQ].trigger_question  ))
        ,HARD_TO_PAY_FOR_BASICS     = trim(substring(1, 25,PTS->QUAL[D1.SEQ].hard_to_pay       ))
        ,WORRIED_FOOD_RUN_OUT       = trim(substring(1, 25,PTS->QUAL[D1.SEQ].worried_food      ))
        ,FOOD_DIDNT_LAST            = trim(substring(1, 25,PTS->QUAL[D1.SEQ].food_didnt_last   ))
        ,UNABLE_PAY_RENT_MORTGAGE   = trim(substring(1, 25,PTS->QUAL[D1.SEQ].unable_pay_rent   ))
        ,NO_PLACE_TO_LIVE           = trim(substring(1, 25,PTS->QUAL[D1.SEQ].no_place_to_live  ))
        ,NO_ACCESS_TRANSPORTATION   = trim(substring(1, 25,PTS->QUAL[D1.SEQ].no_transport      ))
        ,HARD_TO_GET_KEEP_JOB       = trim(substring(1, 25,PTS->QUAL[D1.SEQ].hard_to_get_job   ))
        ,THREATS_UTILITY_SHUTOFF    = trim(substring(1, 25,PTS->QUAL[D1.SEQ].threats_utility   ))
        ,RISK_LEVEL                 = trim(substring(1, 25,PTS->QUAL[D1.SEQ].risk_level        ))

        from (DUMMYT D1 with SEQ=SIZE(PTS->QUAL,5))
        PLAN D1
        with nocounter, time=60, format, separator=" "

    elseif($output = 1);Detailed Version

        Select into $OUTDEV

         NAME            = trim(substring(1, 100,det->QUAL[D1.SEQ].name        ))
        ,FACILITY        = trim(substring(1, 100,det->QUAL[D1.SEQ].facility    ))
        ,MRN             = trim(substring(1,  25,det->QUAL[D1.SEQ].MRN         ));MOD002
        ,DISCHARGE_DT_TM = format(det->QUAL[D1.SEQ].dc_dt_tm  ,"@SHORTDATETIME")
        ,FORM_DT_TM      = format(det->QUAL[D1.SEQ].form_dt_tm,"@SHORTDATETIME")
        ,FORM_FIELD      = trim(substring(1, 100,det->QUAL[D1.SEQ].event_cd    ))
        ,RESULT          = trim(substring(1, 100,det->QUAL[D1.SEQ].result_val  ))

        from (DUMMYT D1 with SEQ=SIZE(det->QUAL,5))
        PLAN D1
        ORDER BY NAME, FORM_DT_TM, FORM_FIELD
        with nocounter, time=60, format, separator=" "

    elseif($output = 3);Summary Version (File Creation)
        set modify filestream  ;004 Setting this is important to actually get CRLF instead of LF
        SELECT INTO value(FILE_NAME)
        ;SELECT INTO $OUTDEV

        ;004->
        ;LOCATION_SOURCE              = trim(substring(1, 100, PTS->QUAL[D1.SEQ].facility            ))  ;004 We don't need this now
        ; ORG                          = trim(substring(1, 100, PTS->QUAL[D1.SEQ].org_name            ))
         LOCATION_SOURCE              = trim(substring(1, 100, PTS->QUAL[D1.SEQ].org_source_code     ))
        ;004<-

        ,FORM                         = trim(substring(1,  75, PTS->QUAL[D1.SEQ].form                ))  ;004

        ,MRN                          = trim(substring(1,  25, PTS->QUAL[D1.SEQ].mrn                 ))
        ,SCREENING_RESPONSE_DATE_TIME = format(PTS->QUAL[D1.SEQ].form_dt_tm,"@SHORTDATETIME"         )

        ,BENE_FIRST_NAME              = trim(substring(1,  50, PTS->QUAL[D1.SEQ].bene_first_name     ))  ;004
        ,BENE_LAST_NAME               = trim(substring(1,  50, PTS->QUAL[D1.SEQ].bene_last_name      ))  ;004
        ,BENE_PRIMARY_PHONE           = trim(substring(1,  15, PTS->QUAL[D1.SEQ].bene_phone          ))  ;004
        ,BENE_BIRTH_DT                = trim(substring(1,  10, PTS->QUAL[D1.SEQ].bene_dob            ))  ;004
        ,BENE_ADD_LINE_1              = trim(substring(1,  75, PTS->QUAL[D1.SEQ].bene_add            ))  ;004
        ,BENE_CITY                    = trim(substring(1,  50, PTS->QUAL[D1.SEQ].bene_city           ))  ;004
        ,BENE_STATE                   = trim(substring(1,  50, PTS->QUAL[D1.SEQ].bene_state          ))  ;004
        ,BENE_ZIP                     = trim(substring(1,  15, PTS->QUAL[D1.SEQ].bene_zip            ))  ;004
        ,SCREEN_PERF_PROV             = trim(substring(1, 100, PTS->QUAL[D1.SEQ].screen_perf_prov    ))  ;004

        ,MEDSTARREGIONAL1             = trim(substring(1,  25, PTS->QUAL[D1.SEQ].hard_to_pay         ))
        ,MEDSTARREGIONAL2             = trim(substring(1,  25, PTS->QUAL[D1.SEQ].worried_food        ))
        ,MEDSTARREGIONAL3             = trim(substring(1,  25, PTS->QUAL[D1.SEQ].food_didnt_last     ))
        ,MEDSTARREGIONAL4             = trim(substring(1,  25, PTS->QUAL[D1.SEQ].unable_pay_rent     ))
        ,MEDSTARREGIONAL5             = trim(substring(1,  25, PTS->QUAL[D1.SEQ].no_place_to_live    ))
        ,MEDSTARREGIONAL6             = trim(substring(1,  25, PTS->QUAL[D1.SEQ].no_transport        ))
        ,MEDSTARREGIONAL7             = trim(substring(1,  25, PTS->QUAL[D1.SEQ].hard_to_get_job     ))
        ,MEDSTARREGIONAL8             = trim(substring(1,  25, PTS->QUAL[D1.SEQ].threats_utility     ))

        from (DUMMYT D1 with SEQ=SIZE(PTS->QUAL,5))
        PLAN D1
        ORDER BY SCREENING_RESPONSE_DATE_TIME
        ;with TIME=20,format,separator=" "
        ;004 flipping this to pipe.
        ;with Heading, PCFormat('', ',', 1, 1), format=STREAM, compress, nocounter, format, time=2000, append
        with Heading, PCFormat('', '|', 1, 1), format=STREAM, compress, nocounter, format, time=2000, append

    endif
else
    Select into $OUTDEV
        MESSAGE = "No Powerforms Found for Selected Date Range"
    from DUMMYT
    with nocounter,time=60,separator=" ",format

endif



subroutine org_source_translate(org_id)

    case(org_id)
    ;  Single guys
    of     589723:    return('MEDSTAR_FSH')         ;Medstar Franklin Square Medical Center
    of     627889:    return('MEDSTAR_GSH')         ;MedStar Good Samaritan Hospital
    of     628009:    return('MEDSTAR_HHC')         ;Medstar Harbor Hospital
    of     628058:    return('MEDSTAR_UMH')         ;Medstar Union Memorial Hospital
    of     628085:    return('MEDSTAR_GUH')         ;Medstar Georgetown University Hospital
    of     628088:    return('MEDSTAR_WHC')         ;Medstar Washington Hospital Center
    of     628738:    return('MS_NRH')              ;National Rehabilitation Hospital
    of    3440653:    return('STMH')                ;Medstar St. Mary's Hospital
    of    3763758:    return('MGH')                 ;Medstar Montgomery Medical Center
    of    3837372:    return('SMH')                 ;MedStar Southern Maryland Hospital Center
    of    6109801:    return('ENS_MHPCFH')          ;MedStar Harbor Primary Care- Federal Hill
    of    6186678:    return('ENS_FHCCMFS')         ;Family Health Center at Medstar Franklin Square
    of    6186678:    return('MEDSTAR_FHC')         ;Family Health Center
    of    6187639:    return('ENS_PCCMFSMC')        ;Primary Care Center at MedStar Franklin Square Medical Center
    of    6187656:    return('ENS_MHPC')            ;MedStar Harbor Primary Care
    of    6212408:    return('ENS_MGSINS')          ;MedStar Good Samaritan Internal Medicine Specialists
    of    6212409:    return('ENS_MGSMFP')          ;MedStar Good Samaritan Medical Faculty Practice
    of    6212433:    return('ENS_MUMHAMS')         ;MedStar Union Memorial Hospital Adult Medicine Specialist
    of    6220558:    return('ENS_MMGSM')           ;MedStar Medical Group at St. Mary's
    of    6233171:    return('ENS_MMGSV')           ;Medstar Medical Group - Spring Valley
    of    6276595:    return('ENS_MMGFH')           ;MedStar Medical Group at Forest Hill
    of    6276601:    return('ENS_MMGL')            ;Medstar Medical Group at Laurel
    of    6277228:    return('ENS_MMGCS')           ;MedStar Medical Group Family Practice at Camp Springs
    of    6277235:    return('ENS_MMGOPP')          ;MedStar Medical Group Olney Professional Park
    of    6277238:    return('ENS_MMGSS')           ;MedStar Medical Group at Silver Spring
    of    6455028:    return('ENS_MTEC_B')          ;MedStar House Call Program - Baltimore
    of    6583023:    return('MEDSTAR_FC_HR')       ;MedStar Family Choice (Sandpiper) - HR
    of    7906071:    return('WHCGER')              ;MedStar House Call Program - Washington DC
    of    8359089:    return('ENS_MHBPC')           ;MedStar Health at Brandywine Primary Care
    of    8359661:    return('ENS_MMGUP')           ;MedStar Medical Group at Upper Marlboro
    of    8359765:    return('ENS_MMGWP')           ;MedStar Medical Group at White Plains
    of    9412332:    return('ENS_MUMAMSB')         ;MedStar Union Memorial Adult Medicine Specialists at Bauernschmidt
    of   11352032:    return('ENS_MSFTLIN')         ;Medstar Medical Group Fort Lincoln Family Medicine
    of   11652352:    return('ENS_GHCCHFCL')        ;Good Health Center- CHF Clinic
    of   12034314:    return('SHAH')                ;Shah Associates
    of    9739743:    return('ENS_GAMG')            ;MedStar Medical Group - Greater Annapolis
    

    ;  Multi Guys
    of    6753372:    
    of   12746449:
    of   12890909:    return('ENS_MMGHV')           ;MedStar Medical Group at Hyattsville

    of    6213413:    
    of    6212432:    return('ENS_MUMAMC')          ;MedStar Union Memorial Adult Medicine Center

    of    6220555:    
    of   12203156:    return('ENS_MMGLT')           ;MedStar Medical Group at Leonardtown

    of    6245830:    
    of    6245828:
    of    6245829:
    of    6245806:
    of    6246289:
    of    7718925:
    of    6246285:
    of    6246287:
    of    6246288:
    of    6246286:
    of    9457313:
    of   14338654:
    of   11421380:
    of   10761078:
    of   14047378:
    of    8973134:    return('ENS_MHLW')            ;MedStar Health at Leisure World

    of    6271125:    
    of   13527805:    return('ENS_MMGM')            ;MedStar Medical Group at Mitchellville

    of    6628933:    
    of   14115768:
    of   13011363:
    of    6277231:    return('ENS_MMGD')            ;Medstar Medical Group at Dundalk

    of    6724502:    
    of   13650883:
    of    7969564:
    of   14208732:
    of    6355436:
    of    7936323:
    of    6355432:
    of    6355430:
    of    6355433:
    of    9562270:
    of    6355435:
    of    6839473:
    of   15893743:
    of   12437236:
    of   12435329:
    of   15203462:
    of   12435613:
    of   11898961:
    of    6355431:
    of    7193906:
    of    6355437:
    of    6355439:
    of   13384447:
    of    7781838:
    of    7785778:
    of    6355434:
    of   10295664:
    of    6114270:
    of    7067101:    return('ENS_MHBAMC')          ;MedStar Health at the Bel Air Medical Campus

    of  841057957:    
    of 2135452971:
    of 2349406865:
    of    4366003:    return('ENS_MMGB')            ;MedStar Medical Group at Bethesda

    of   10781775:    
    of    6277234:    return('ENS_MMHNPHC')         ;MedStar Medical Group at North Parkville Health Center

    of   13455375:    
    of    6212404:    return('ENS_MCSAB')           ;MedStar Center for Successful Aging - Baltimore

    of   14337354:    
    of   12574700:
    of    6277240:
    of    6276605:    return('ENS_MMGWMC')          ;MedStar Medical Group at Wilkens Medical Center

    of   14389925:    
    of    6583023:    return('ENS_MMGRR')           ;MedStar Medical Group at Ridge Rd

    of   14458669:    
    of    6276596:    return('ENS_MMGG')            ;MedStar Medical Group at Gaithersburg

    of   14623901:                                  ;MedStar Medical Group Primary Care at Clinton
    of    8359281:    return('ENS_MMGPCC')

    of   15562054:                                  ;Medstar Medical group Olney Family Practice
    of    6110171:
    of   14285675:
    of    6246296:
    of    6277235:    return('ENS_MMGOFP')

    of    6220729:    
    of    6220728:    return('ENS_MWPS')            ;Medstar Washington Hospital Center Pulmonary Services

    of    6276604:    
    of    6628928:
    of    6277232:    return('ENS_MMGH')            ;Medstar Medical Group at Honeygo

    of    7913937:    
    of    8663980:
    of    6276594:
    of    7109301:    return('ENS_MMGDH')           ;MedStar Medical Group at Dorsey Hall

    ;  Guys I couldn't identify
    ;Smaldore Family Practice                                                        ENS_SMALDORE
    ;Smaldore Family Practice                                                        ENS_SFP
    ;MedStar Evolent - Intermed                                                      ENS_MSEVOL3
    ;MedStar Family Choice DC - Case Management                                      MSFCDCCM
    ;MedStar Family Choice DC - Other Outreach                                       MSFCDCOO
    ;MedStar Family Choice DC - OMS                                                  MSFCDCOMS
    ;ENS Group - MedStar Evolent MSSP                                                ENS_MSEVOL2
    ;Medstar Evolent                                                                 MEDSTAR_EVOL
    ;MedStar Family Choice DC                                                        MSFCDCGEN
    ;Medstar Family Choice Referrals                                                 ENS_MSFCREF_AS
    ;MedStar Community Health                                                        MED_CH
    ;MedStar Franklin Hospital Cancer Registry                                       MEDSTAR_HHC_Cancer
    ;MedStar Washington Hospital Center - Community Violence Intervention Program    ENS_WHC_CVIP
    ;MedStar Accountable Care                                                        ENS_MACLC
    ;ENS Stephanie Bruce - Medstar Washington Hospital Center                        WHCBRUCE
    ;Medstar Aetna Attribution Panel                                                 ENS_MSAETNA
    ;Medstar Cigna Attribution Panel                                                 ENS_MDSTRCIG
    ;Medstar Harbor Infusion Center                                                  ENS_MEHIC_AS
    ;MedStar Medical Group at Prince Philip                                          ENS_MMGPP
    ;MedStar Health Primary Care East Run Center                                     ENS_MHPCERC
    endcase


    ;  In the case we didn't identify a code... they want me to send nothing... might tip us off
    ;  if there is a problem.
    ;  Haha just kidding they want a place holder now... we were using MEDSTAR_VNA under a
    ;  previous version of source codes, which should be a medstar generic outpatient.
    return('MEDSTAR_VNA')

end


;***********************************************************************************************
;                           END OF PROGRAM
;***********************************************************************************************

;call echorecord(PTS)
;call echorecord(det)


if($OUTPUT = 3);File Creation
    call echo(build('File created at:', FILE_NAME))
endif



;;;record test_forms(
;;;    1 cnt = i4
;;;    1 form[*]
;;;        2 name        = vc
;;;        2 cnt         = i4
;;;        2 trigger_cnt = i4
;;;)
;;;
;;;declare idx    = i4 with protect, noconstant(0)
;;;declare pos    = i4 with protect, noconstant(0)
;;;declare looper = i4 with protect, noconstant(0)
;;;
;;;for(looper = 1 to SIZE(PTS->QUAL,5))
;;;    set pos = locateval(idx, 1, test_forms->cnt, PTS->QUAL[looper]->form, test_forms->form[idx]->name)
;;;
;;;    if(pos = 0)
;;;        set test_forms->cnt = test_forms->cnt + 1
;;;        
;;;        set pos = test_forms->cnt
;;;        
;;;        set stat = alterlist(test_forms->form, pos)
;;;        
;;;        set test_forms->form[pos]->name = PTS->QUAL[looper]->form
;;;    endif
;;;
;;;    set test_forms->form[pos]->cnt = test_forms->form[pos]->cnt + 1
;;;
;;;    if(PTS->QUAL[looper].trigger_question > ' ')
;;;        set test_forms->form[pos]->trigger_cnt = test_forms->form[pos]->trigger_cnt + 1
;;;    endif
;;;
;;;
;;;endfor
;;;
;;;
;;;for(looper = 1 to test_forms->cnt)  call echo(notrim(build2( test_forms->form[looper]->name, ': '
;;;                                                           , test_forms->form[looper]->cnt , ': '
;;;                                                           , test_forms->form[looper]->trigger_cnt
;;;                                                           )
;;;                                                    )
;;;                                             )
;;;endfor





end
go
