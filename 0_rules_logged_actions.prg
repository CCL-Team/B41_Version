/*************************************************************************
 Program Title: Discern Rules - Logging Actions

 Object name:   0_rules_logged_actions
 Source file:   0_rules_logged_actions.prg

 Purpose:       Identify rules that fired within the lookback window that
                logged an action using EKS_LOG_ACTION_A.
                
                Default lookforward window of 4day to current.

 Tables read:

 Executed from:

 Special Notes:



******************************************************************************************
                  MODIFICATION CONTROL LOG
******************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -----------------------------------------------
001 02/13/2025 Michael Mayes               (SCTASK0138668) Initial release
*************END OF ALL MODCONTROL BLOCKS* ***********************************************/
drop   program 0_rules_logged_actions:dba go
create program 0_rules_logged_actions:dba

prompt
      "Output to File/Printer/MINE"                  = "MINE"    ;* Enter or select the printer or file name to send this report to.
    , "Lookforward Date"                             = "SYSDATE"
    , "Action Name"                                  = "*"
    ;<<hidden>>"(case INsensative, Wildcards: *  ?)" = ""
    , "FIN"                                          = "*"

with OUTDEV, START_DT, ACTION_NAME, FIN



/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record results(
    1 cnt = i4
    1 qual[*]
        2 patient_name    = vc
        2 facility        = vc
        2 fin             = vc
        2 modify_dlg_name = vc
        2 person_id       = f8
        2 triggered_by    = vc
        2 triggered_at    = vc
)

/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare pos               = i4 with protect, noconstant(0)
declare tmp_str           = vc with protect, noconstant('')
declare computed_dlg_name = vc with protect, noconstant('')


/*************************************************************
; DVDev Start Coding
**************************************************************/

; This is crazy... but I think dlg_name pulls apart the used action name... expecting us to use something like
; ONC_PHARM_PRIOR_AUTH or NON_VIOLENT_RESTRAINT_A... and does some sort of build to make it:
; ONC_EKM!ACTION_NAME
; NON_EKM!ACTION_NAME
; Examples include:
;     ABBOTT_EKM!ABBOTT_INPATIENT_HF
;     ABBOT_EKM!ABBOT_INPATIENT_CARD_MESS
;     ADE_EKM!ADE_SYN_DRUGHIGHK_3
;     ALERT_EKM!ALERT_OPEN_CHART_FORM_V2
;     AMB_EKM!AMB_ALLERGY_PHONE_MESSAGE
;     AMB_EKM!AMB_ATTEND_PROV_PRECEPTOR
;     AMB_EKM!AMB_CANDIDA_AURIS_OC_ALER
;     AMB_EKM!AMB_CARDIAC_REHAB_ALERT
;     Looks like it might default in a MUL_ if there is no underscore in the action name.  So MUL_EKS!ACTION_NAME
;     
; I was/am worried if I wild card the first part, we'll kill our index we are using, pretty sure that its in the index.
; Going to try it just wild carded first though.
;
; TEST NOTES
;    I think performance does suffer going to try a two-fer because it looks like it lands naked too sometimes.

set pos = findstring('_', $ACTION_NAME)

if(pos > 0)
    ;call echo(substring(1, pos, $ACTION_NAME))
    
    set computed_dlg_name = notrim(build2(substring(1, pos, $ACTION_NAME), 'EKM!', $ACTION_NAME))
endif

call echo(build('computed_dlg_name:', computed_dlg_name))





/**********************************************************************
DESCRIPTION:  Gather rule data using parameters
      NOTES:  This query was provided by Opinion
***********************************************************************/
select into 'nl:'
       ede.dlg_name
     , patient_name = p.name_full_formatted
     , facility     = uar_get_code_display( e.loc_facility_cd)
     , fin          = ea.alias
     , ede.modify_dlg_name
     , person_id    = p.person_id
     , triggered_by = pr.name_full_formatted
     , triggered_at = ede.updt_dt_tm

  from eks_dlg_event ede
     , encounter e
     , encntr_alias ea              ;fin
     , person p
     , prsnl pr

  plan ede
   where ede.dlg_dt_tm >  cnvtdatetime($START_DT)
     and (   ede.dlg_name  =  patstring(computed_dlg_name)
          or ede.dlg_name  =  patstring($ACTION_NAME)
         )

  join e
   where e.encntr_id   =  ede.encntr_id

  JOIN EA
   WHERE EA.ENCNTR_ID            =  E.ENCNTR_ID
     AND EA.ACTIVE_IND           =  1
     AND EA.ENCNTR_ALIAS_TYPE_CD =  1077.00 ;ONLY LOOKING AT FINS
     AND EA.ALIAS                =  patstring($FIN)

  join p
   where p.PERSON_ID             =  e.PERSON_ID

  join pr
   where pr.PERSON_ID            =  ede.UPDT_ID

order by ede.updt_dt_tm desc

detail
    results->cnt = results->cnt + 1

    stat = alterlist(results->qual, results->cnt)

    results->qual[results->cnt]->patient_name    = patient_name
    results->qual[results->cnt]->facility        = facility
    results->qual[results->cnt]->fin             = fin
    results->qual[results->cnt]->modify_dlg_name = trim(ede.modify_dlg_name, 3)
    results->qual[results->cnt]->person_id       = person_id
    results->qual[results->cnt]->triggered_by    = triggered_by
    results->qual[results->cnt]->triggered_at    = format(triggered_at, '@SHORTDATETIME')

with nocounter


if (results->cnt > 0)

    select into $outdev
          PATIENT_NAME      =  trim(substring(1, 100, results->qual[d.seq].patient_name     ))
        , FACILITY          =  trim(substring(1, 100, results->qual[d.seq].facility         ))
        , FIN               =  trim(substring(1,  50, results->qual[d.seq].fin              ))
        , MODIFY_DLG_NAME   =  trim(substring(1,  50, results->qual[d.seq].modify_dlg_name  ))
        , PERSON_ID         =                         results->qual[d.seq].person_id
        , TRIGGERED_BY      =  trim(substring(1, 100, results->qual[d.seq].triggered_by     ))
        , TRIGGERED_AT      =  trim(substring(1,  40, results->qual[d.seq].triggered_at     ))

      from (dummyt d with SEQ = results->cnt)
    plan d
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

end
go




