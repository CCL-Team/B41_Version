/*************************************************************************
 Program Title: Discern Rules - Runs/Successes/failures

 Object name:   0_rules_runs_succ_fail
 Source file:   0_rules_runs_succ_fail.prg

 Purpose:       Examine Rules looking for run count, success and failure count
                over a specified time range.
                
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
drop   program 0_rules_runs_succ_fail:dba go
create program 0_rules_runs_succ_fail:dba

prompt 
	"Output to File/Printer/MINE" = "MINE"                  ;* Enter or select the printer or file name to send this report to.
	, "Start Date"                = "SYSDATE"
	, "End Date"                  = "SYSDATE"
	, "Rule Name"                 = "*"
	;<<hidden>>"(case INsensative, Wildcards: *  ?)" = "" 

with OUTDEV, START_DT, END_DT, RULE_NAME



/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/


/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record results(
    1 cnt = i4
    1 qual[*]
        2 module_name       = vc
        2 last_mod_by       = vc
        2 last_mod_date     = vc
        2 runs              = i4
        2 count_logic_false = i4
        2 count_logic_true  = i4
        2 count_success     = i4
        2 count_fail        = i4
)

/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/

/*************************************************************
; DVDev Start Coding
**************************************************************/

/**********************************************************************
DESCRIPTION:  Gather rule data using parameters
      NOTES:  This query was provided by Opinion
***********************************************************************/
select into 'nl:'
       em.module_name
     , last_modified_by   = p.name_full_formatted
     , last_modified_date = em.updt_dt_tm
     , runs               = t.records
     , count_logic_false  = evaluate(t.conclude, 0, (t.records), 0)
     , count_logic_true   = evaluate(t.conclude, 1, (t.records), 0)
     , count_success      = evaluate(t.conclude, 2, (t.records), 0)
     , count_fail         = evaluate(t.conclude, 3, (t.records), 0)

 from eks_module   em
    , prsnl p
    , (( select records = count(*)
              , e2.module_name
              , e2.conclude

           from EKS_MODULE_AUDIT e2

          where e2.begin_dt_tm BETWEEN cnvtdatetime($START_DT) and cnvtdatetime($END_DT)
            and e2.module_name = patstring(cnvtupper($RULE_NAME))

        group by e2.module_name
               , e2.conclude
        with sqltype("f8", "vc", "i4"), time = 1
      ) T)

 where cnvtupper(em.module_name) =  patstring(cnvtupper($RULE_NAME))
   and em.active_flag            =  "A"
   and em.maint_validation       =  "PRODUCTION"
   and em.maint_dur_begin_dt_tm  <  sysdate
   and em.maint_dur_end_dt_tm    >  sysdate
 
   and p.person_id               =  em.updt_id
   
   and t.module_name             =  em.module_name

order by em.module_name

detail
    results->cnt = results->cnt + 1

    stat = alterlist(results->qual, results->cnt)

    results->qual[results->cnt]->module_name       = em.module_name
    results->qual[results->cnt]->last_mod_by       = last_modified_by
    results->qual[results->cnt]->last_mod_date     = format(last_modified_date, '@SHORTDATETIME')
    results->qual[results->cnt]->runs              = runs
    results->qual[results->cnt]->count_logic_false = count_logic_false
    results->qual[results->cnt]->count_logic_true  = count_logic_true
    results->qual[results->cnt]->count_success     = count_success
    results->qual[results->cnt]->count_fail        = count_fail

with nocounter



if (results->cnt > 0)

    select into $outdev
          module_name       =  trim(substring(1,   40, results->qual[d.seq].module_name  ))
        , last_mod_by       =  trim(substring(1,  140, results->qual[d.seq].last_mod_by  ))
        , last_mod_date     =  trim(substring(1,  140, results->qual[d.seq].last_mod_date))
        , runs              =  results->qual[d.seq].runs
        , count_logic_false =  results->qual[d.seq].count_logic_false
        , count_logic_true  =  results->qual[d.seq].count_logic_true
        , count_success     =  results->qual[d.seq].count_success
        , count_fail        =  results->qual[d.seq].count_fail

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




