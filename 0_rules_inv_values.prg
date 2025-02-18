/*************************************************************************
 Program Title: Discern Rules - Invalid Values

 Object name:   0_rules_inv_values
 Source file:   0_rules_inv_values.prg

 Purpose:       Identify Rules containing invalid values, pointing them out for correction.  
                After correction, they should run as intended, reducing the risk of rule 
                failure or unsuccessful runs.

                Looking for runs of the rule within the last 30 days, by prompt default.

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
drop   program 0_rules_inv_values:dba go
create program 0_rules_inv_values:dba

prompt
      "Output to File/Printer/MINE" = "MINE"
    , "Lookforward Date"            = "SYSDATE"

with OUTDEV, START_DT



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
        2 updt_by           = vc
        2 updt_dt           = vc
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
  from eks_module em
     , prsnl p
 where em.active_flag      =  "A"
   and em.maint_validation in ("PRODUCTION", "TESTING")
   and em.reconcile_flag   =  2
   and em.updt_dt_tm       >= cnvtdatetime($START_DT)
   
   and p.person_id = em.updt_id

detail
    results->cnt = results->cnt + 1

    stat = alterlist(results->qual, results->cnt)

    results->qual[results->cnt]->module_name = em.module_name
    results->qual[results->cnt]->updt_by     = trim(p.name_full_formatted, 3)
    results->qual[results->cnt]->updt_dt     = format(em.updt_dt_tm, '@SHORTDATETIME')

with nocounter




if (results->cnt > 0)

    select into $outdev
          module_name       =  trim(substring(1,   50, results->qual[d.seq].module_name  ))
        , updt_by           =  trim(substring(1,   50, results->qual[d.seq].updt_by  ))
        , updt_dt           =  trim(substring(1,   40, results->qual[d.seq].updt_dt  ))

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





