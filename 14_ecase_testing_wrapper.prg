/*********************************************************************************************************************************
 Program Title:		14_ecase_testing_wrapper.prg
 Create Date:		07/16/2022
 Object name:		14_ecase_testing_wrapper
 Source file:		14_ecase_testing_wrapper.prg
 MCGA:
 OPAS:
 Purpose:
 Executed from:		Explorer Menu
 Special Notes:
 
**********************************************************************************************************************************
**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
Mod    Date             Analyst                 OPAS          			Comment
---    ----------       --------------------    ------        		--------------------------------------------
N/A    07/16/2022		Jeremy Daniel         	N/A	          		Initial Release
001    02/20/2025       Michael Mayes                               Removing emails now that we have archiving set up.
*************END OF ALL MODCONTROL BLOCKS* ***************************************************************************************/
 
drop program 14_ecase_testing_wrapper go
create program 14_ecase_testing_wrapper
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "FREQUENCY" = ""
 
with OUTDEV, FREQUENCY
 
 
;=====================================================================
; VARIABLE DECLARATIONS
;=====================================================================
declare start_dt_tm			= dq8 with noconstant
declare end_dt_tm			= dq8 with noconstant
declare start_dt_tm_vc		= vc with noconstant
declare end_dt_tm_vc		= vc with noconstant
 
; BASED ON PROMPT SELECTION GET THE DQ8 DATA PARAMETERS
IF ( $FREQUENCY = "DAILY" )
	set start_dt_tm = cnvtdatetime((curdate-1), 000000)
	set end_dt_tm =   cnvtdatetime((curdate-1), 235959)
 
elseif ( $FREQUENCY = "WEEKEND" )
	set start_dt_tm = cnvtdatetime((curdate-3), 000000)
	set end_dt_tm =   cnvtdatetime((curdate-1), 235959)
 
elseif ( $FREQUENCY = "WEEKLY" )
	set	start_dt_tm = cnvtlookbehind("7,D",cnvtdatetime((curdate-1), 000000))
	set	end_dt_tm = cnvtdatetime((curdate-1), 235959)
 
elseif ( $FREQUENCY = "BIWEEKLY" )
	set	start_dt_tm = DATETIMEFIND(cnvtlookbehind("2,W"),"W","B","B")
	set	end_dt_tm = DATETIMEFIND(cnvtlookbehind("1,W"),"W","E","E")
	
elseif ( $FREQUENCY = "MONTHLY" )
	set	start_dt_tm = DATETIMEFIND(cnvtlookbehind("1,M"),"M","B","B")
	set	end_dt_tm = DATETIMEFIND(cnvtlookbehind("1,M"),"M","E","E")
 
elseif ( $FREQUENCY = "HALFYEAR" )
	set	start_dt_tm = cnvtlookbehind("180,D",cnvtdatetime((curdate-2), 000000))
	set	end_dt_tm = cnvtdatetime((curdate-2), 235959)
 
elseif ( $FREQUENCY = "FISCALYEAR" )
	set	end_dt_tm = DATETIMEFIND(cnvtlookbehind("1,W"),"W","E","E")
Endif
 
;FORMAT THE DQ8 DATA IN PROMPT FRIENDLY FORMATTING
if ($FREQUENCY != "FISCALYEAR")
	set start_dt_tm_vc = trim(format(start_dt_tm, "DD-MMM-YYYY hh:mm:ss;;Q"))
	set end_dt_tm_vc   = trim(format(end_dt_tm,  "DD-MMM-YYYY hh:mm:ss;;Q"))
elseif ($FREQUENCY = "FISCALYEAR")
	set start_dt_tm_vc = "07-NOV-2016 00:00:00"
	set end_dt_tm_vc   = trim(format(end_dt_tm,  "DD-MMM-YYYY hh:mm:ss;;Q"))
endif
 
;=====================================================================
; BEGIN THE STRING OF EXECUTIONS
;=====================================================================
 
;execute 14_ecase_testing_48hr_pdc "MINE", start_dt_tm_vc, end_dt_tm_vc, 2 ;file
 
execute 14_ecase_testing_48hr_pdc "418fb3d8.medstar.net@amer.teams.ms",  start_dt_tm_vc, end_dt_tm_vc, 3 ;EMAIL  ;001

execute 14_ecase_testing_48hr_pdc_va "andrea.winter@medstar.net,418fb3d8.medstar.net@amer.teams.ms",  start_dt_tm_vc, end_dt_tm_vc, 3 ;EMAIL    ;001

execute 14_ecase_testing_48hr_pdc_md "418fb3d8.medstar.net@amer.teams.ms",  start_dt_tm_vc, end_dt_tm_vc, 3 ;EMAIL  ;001
 
;execute 14_covid19_appts_results_wb2 "MINE", start_dt_tm_vc , end_dt_tm_vc, 2 ;file asymmetrik noshow and cxl file


execute ecase_RR_rpt "418fb3d8.medstar.net@amer.teams.ms",  start_dt_tm_vc, end_dt_tm_vc, 3 ;EMAIL    ;001
 
 
select into $OUTDEV MSG="COMPLETED" from dummyt with nocounter
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
end
go
 