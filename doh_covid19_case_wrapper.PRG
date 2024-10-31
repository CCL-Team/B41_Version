/*********************************************************************************************************************************
 Program Title:		doh_covid19_case_wrapper.prg
 Create Date:		03/06/2020
 Object name:		doh_covid19_case_wrapper
 Source file:		doh_covid19_case_wrapper.prg
 MCGA:
 OPAS:
 Purpose: 			This is an infection control wrapper used to email out the 3_corona_symp report.
 Executed from:		Explorer Menu
 Special Notes:
 
**********************************************************************************************************************************
**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
Mod    Date             Analyst                 OPAS          			Comment
---    ----------       --------------------    ------        		--------------------------------------------
N/A    03/06/2020		Jeremy Daniel         	N/A	          		Initial Release
001    09/08/2020		jwd107					223436				add Rahsaan.J.Holley@medstar.net to DC IP and AMB case emails
002	   03/01/2021		jwd107					n/a					remove Sunil from STM email
003	   08/22/2022		jwd107					n/a					add monkey pox emailed reports
004    03/08/2023		jwd107					n.a					remove JS from mp MD email
 
*************END OF ALL MODCONTROL BLOCKS* ***************************************************************************************/
 
drop program doh_covid19_case_wrapper go
create program doh_covid19_case_wrapper
 
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
 
elseif ( $FREQUENCY = "WEEKLY" )
	set	start_dt_tm = cnvtlookbehind("7,D",cnvtdatetime((curdate-1), 000000))
	set	end_dt_tm = cnvtdatetime((curdate-1), 235959)
 
elseif ( $FREQUENCY = "BIWEEKLY" )
	set	start_dt_tm = DATETIMEFIND(cnvtlookbehind("2,W"),"W","B","B")
	set	end_dt_tm = DATETIMEFIND(cnvtlookbehind("1,W"),"W","E","E")
 
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
 
execute DOH_COVID19_RESULTS_DC_CASE "Jennifer.N.Evans@Medstar.net"
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute DOH_COVID19_RESULTS_DC_CASE "418fb3d8.medstar.net@amer.teams.ms"
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute DOH_COVID19_RESULTS_DC_IP "julia.m.gardner@medstar.net,andrea.winter@medstar.net,Sarah.A.Seidman@gunet.georgetown.edu,MaryDawn.E.Mojica@medstar.net"
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute DOH_COVID19_RESULTS_DC_IP "Holly.P.White@gunet.georgetown.edu,Rahsaan.J.Holley@medstar.net";001
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute DOH_COVID19_RESULTS_DC_IP "418fb3d8.medstar.net@amer.teams.ms"
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute DOH_COVID19_RESULTS_DC_IP "WHC-InfectionControlandPreventionDepartment@medstar.net,jeremy.w.daniel@medstar.net"
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute DOH_COVID19_RESULTS_DC_IP "Ti-Hesia.L.Jackson@medstar.net"
, start_dt_tm_vc , end_dt_tm_vc, 3
 
;;execute 3_crisp_covid_rdv "Jennifer.N.Evans@Medstar.net"  ;418fb3d8.medstar.net@amer.teams.ms
;;,0, start_dt_tm_vc , end_dt_tm_vc, 2
 
 
execute doh_covid19_results_test "jeremy.w.daniel@medstar.net";MD email
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute doh_covid19_results "418fb3d8.medstar.net@amer.teams.ms"   ;MD email
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute doh_covid19_results_elr "418fb3d8.medstar.net@amer.teams.ms"   ;MD email
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute doh_covid19_results_elr_test "418fb3d8.medstar.net@amer.teams.ms"   ;MD preop email
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute doh_covid19_results_dc_test "418fb3d8.medstar.net@amer.teams.ms" ;DC email preop
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute doh_covid19_results_dc "418fb3d8.medstar.net@amer.teams.ms" ;DC email
, start_dt_tm_vc , end_dt_tm_vc, 3
 
;execute doh_covid19resva_poc_test  "jeremy.w.daniel@medstar.net" ;VA email
;, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute doh_covid19_results_va_poc "418fb3d8.medstar.net@amer.teams.ms" ;VA email
, start_dt_tm_vc , end_dt_tm_vc, 3
 
 
 
execute doh_covid19_results_ns2 "Justin.W.Salz@Medstar.net,Ed.Bonner@Medstar.net" ;Invalid Result email
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute doh_covid19_results_ns3 "Justin.W.Salz@Medstar.net,Ed.Bonner@Medstar.net" ;Non-Standard Result email
, start_dt_tm_vc , end_dt_tm_vc, 3
 
execute doh_covid19_results_ns  "Justin.W.Salz@Medstar.net,Ed.Bonner@Medstar.net,Olakorede.F.Akintelure@medstar.net" ;Missing CLIA email
, start_dt_tm_vc , end_dt_tm_vc, 3

execute 3_mp_results_dc_ip_orders "Jennifer.N.Evans@Medstar.net,andrea.winter@medstar.net,418fb3d8.medstar.net@amer.teams.ms"
, start_dt_tm_vc , end_dt_tm_vc, 3
;
execute 3_mp_results_dc_ip "Jennifer.N.Evans@Medstar.net,andrea.winter@medstar.net,418fb3d8.medstar.net@amer.teams.ms"
, start_dt_tm_vc , end_dt_tm_vc, 3

execute 3_mp_results_md_ip "418fb3d8.medstar.net@amer.teams.ms"
, start_dt_tm_vc , end_dt_tm_vc, 3

execute doh_covid19resva_poc_test "jeremy.w.daniel@medstar.net"
, start_dt_tm_vc , end_dt_tm_vc, 3

execute doh_sti_results_va_poc "418fb3d8.medstar.net@amer.teams.ms" ;sti va poc results
, start_dt_tm_vc , end_dt_tm_vc, 3
 
select into $OUTDEV MSG="COMPLETED" from dummyt with nocounter
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
end
go
 