/*************************************************************************
 Program Title: Discern Rules - Low Volume

 Object name:   0_rules_low_vol
 Source file:   0_rules_low_vol.prg

 Purpose:       Identifies rules that have not been run within the last
                180 days, to identify production level rules that are
                potentially no longer utilized.

                At the moment, it looks for rule runs within the last
                180 days, and if a rule is missing that, it qualifies.

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
drop   program 0_rules_low_vol:dba go
create program 0_rules_low_vol:dba

prompt
      "Output to File/Printer/MINE" = "MINE"    ;* Enter or select the printer or file name to send this report to.
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
        2 module_name      = vc
        2 maint_validation = vc
        2 maint_date       = vc
        2 updt_id          = f8
        2 updt_prsnl       = vc
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
       e.module_name
     , e.maint_validation
     , e.maint_date
     , e.updt_id
     , updt_prsnl = p.name_full_formatted

  from eks_module e
     , prsnl p

  plan e
   where e.active_flag      =  "A"
     and e.maint_validation =  "PRODUCTION"
     and e.maint_dur_begin_dt_tm  <  sysdate
     and e.maint_dur_end_dt_tm    >  sysdate

     and not exists (select em.module_name
                       from eks_module_audit em
                      where em.module_name =  e.module_name
                        and em.begin_dt_tm >  cnvtdatetime($START_DT)
                        and em.end_dt_tm   <  cnvtdatetime(curdate, curtime3)
                    )

  join p
   where p.person_id        =  e.updt_id

order by e.module_name

detail
    results->cnt = results->cnt + 1

    stat = alterlist(results->qual, results->cnt)

    results->qual[results->cnt]->module_name       = e.module_name
    results->qual[results->cnt]->maint_validation  = e.maint_validation
    results->qual[results->cnt]->maint_date        = format(e.maint_date, '@SHORTDATETIME')
    results->qual[results->cnt]->updt_id           = e.updt_id
    results->qual[results->cnt]->updt_prsnl        = updt_prsnl

with nocounter



if (results->cnt > 0)

    select into $outdev
          module_name       =  trim(substring(1,   40, results->qual[d.seq].module_name       ))
        , maint_validation  =  trim(substring(1,   40, results->qual[d.seq].maint_validation  ))
        , maint_date        =  trim(substring(1,   40, results->qual[d.seq].maint_date        ))
        , updt_id           =  results->qual[d.seq].updt_id
        , updt_prsnl        =  trim(substring(1,  140, results->qual[d.seq].updt_prsnl        ))

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




