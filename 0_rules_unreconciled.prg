/*************************************************************************
 Program Title: Discern Rules - Unreconciled

 Object name:   0_rules_unreconciled
 Source file:   0_rules_unreconciled.prg

 Purpose:       Identifies rules that are in need of reconciliation or re-initializiation.

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
drop   program 0_rules_unreconciled:dba go
create program 0_rules_unreconciled:dba

prompt 
	"Output to File/Printer/MINE" = "MINE" 

with OUTDEV



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
        2 reconcile_flag    = vc
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
select em.module_name
     , last_update_by    = pl.name_full_formatted
     , em.updt_dt_tm
     , dm_reconcile_flag = dm.description

FROM eks_module em
   , prsnl pl
   , dm_flags dm

WHERE em.active_flag           =  "A"
  AND em.maint_dur_begin_dt_tm <  sysdate
  AND em.maint_dur_end_dt_tm   >  sysdate
  AND em.maint_validation      =  "PRODUCTION"
  AND em.reconcile_flag        =  2 ;issues with instantiation

  AND pl.person_id             =  em.updt_id

  AND dm.flag_value            =  em.reconcile_flag
  AND dm.table_name            =  "EKS_MODULE"
  AND dm.column_name           =  "RECONCILE_FLAG"

ORDER BY em.module_name

detail
    results->cnt = results->cnt + 1

    stat = alterlist(results->qual, results->cnt)

    results->qual[results->cnt]->module_name       = trim(em.module_name, 3)
    results->qual[results->cnt]->last_mod_by       = last_update_by
    results->qual[results->cnt]->last_mod_date     = format(em.updt_dt_tm, '@SHORTDATETIME')
    results->qual[results->cnt]->reconcile_flag    = dm_reconcile_flag

with nocounter



if (results->cnt > 0)

    select into $outdev
          module_name        =  trim(substring(1,  40, results->qual[d.seq].module_name   ))
        , last_mod_by        =  trim(substring(1, 100, results->qual[d.seq].last_mod_by   ))
        , last_mod_date      =  trim(substring(1,  40, results->qual[d.seq].last_mod_date ))
        , reconcile_flag     =  trim(substring(1, 100, results->qual[d.seq].reconcile_flag))
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




