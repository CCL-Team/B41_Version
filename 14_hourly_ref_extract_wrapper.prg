/*********************************************************************************************************************************
 Program Title:     14_referral_extract_wrapper.prg
 Create Date:       04/15/2021
 Object name:       14_referral_extract_wrapper
 Source file:       14_referral_extract_wrapper.prg
 MCGA:
 OPAS:
 Purpose:           This is an infection control wrapper used to email out the 3_corona_symp report.
 Executed from:     Explorer Menu
 Special Notes:

**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ ---------------------------------------------------------------------------------------
N/A 06/03/2024 Simeon Akinsulie     346022 Initial Release
001 09/18/2024 Michael Mayes        349910 Adding locations and fields in subscripts
*************END OF ALL MODCONTROL BLOCKS* **************************************************************************************/

  drop program 14_hourly_ref_extract_wrapper go
create program 14_hourly_ref_extract_wrapper

prompt
      "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "FREQUENCY"                   = ""

with OUTDEV, FREQUENCY


;=====================================================================
; VARIABLE DECLARATIONS
;=====================================================================
declare output_file = vc
set output_file     = build2( "/cerner/d_P41/cust_output_2/referral_extract/"
                            , "ref_reminders_hourly_",format(cnvtdatetime(curdate,curtime3),"MMDDYYYY_HHMM;;Q")
                            , ".csv"
                            )

;=====================================================================
; BEGIN THE STRING OF EXECUTIONS
;=====================================================================

execute 14_referral_uc_extract      output_file, '', '', 2
execute 14_referral_mrn_rad_extract output_file, '', '', 2

select into $OUTDEV 
    MSG="COMPLETED" 
  from dummyt 
with nocounter

/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/

end
go
