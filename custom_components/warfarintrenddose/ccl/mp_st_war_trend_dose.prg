/**************************************************************************
 Program Title:   mp_st_war_trend_dose
 
 Object name:     mp_st_war_trend_dose
 Source file:     mp_st_war_trend_dose.prg
 
 Purpose:         Grabs the RS from the ST after execution and returns it to
                  the frontend
 
 Tables read:
 
 Executed from:   MPage
 
 Special Notes:
 
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 03/26/2019 Michael Mayes        214978    Initial release
 
*************END OF ALL MODCONTROL BLOCKS* ********************************/
drop program mp_st_war_trend_dose:dba go
create program mp_st_war_trend_dose:dba
 
prompt
    "Output to File/Printer/MINE:" = "MINE",   ;* Enter or select the printer or file name to send this report to.
    "Encounter_id:"                = 0.0,
    "Person_id:"                   = 0.0
with OUTDEV, enc_id, per_id
 
 
 
/**************************************************************
; DVDev INCLUDES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc
 
 
/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
record dosing(
    1 cnt      = i2
    1 qual [*]
        2 event_id     = f8  
        2 par_event_id = f8  
        2 lcv_dt_tm    = dq8
        2 encntr_id    = f8  
        2 date         = dq8
        2 date_str     = vc
        2 inr          = vc
        2 trans_inr    = vc
        2 dose_str     = vc 
        2 dose_1_tab   = vc 
        2 dose_2_tab   = vc 
        2 sun_dose_str = vc 
        2 sun_1_dose   = vc 
        2 sun_2_dose   = vc 
        2 mon_dose_str = vc 
        2 mon_1_dose   = vc 
        2 mon_2_dose   = vc 
        2 tue_dose_str = vc 
        2 tue_1_dose   = vc 
        2 tue_2_dose   = vc 
        2 wed_dose_str = vc 
        2 wed_1_dose   = vc 
        2 wed_2_dose   = vc 
        2 thu_dose_str = vc 
        2 thu_1_dose   = vc 
        2 thu_2_dose   = vc 
        2 fri_dose_str = vc 
        2 fri_1_dose   = vc 
        2 fri_2_dose   = vc 
        2 sat_dose_str = vc
        2 sat_1_dose   = vc
        2 sat_2_dose   = vc
        2 wk_dose      = f8 
        2 wk_dose_str  = vc
        2 per_chng     = f8
        2 per_chng_str = vc
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare ret_string = vc with protect, noconstant('')
 
/**************************************************************
; DVDev Start Coding
**************************************************************/
;mock a ST request for the smart template
record st_request(
    1 visit[*]
        2 encntr_id = f8
    1 person[*]
        2 person_id = f8
)    

set stat = alterlist(st_request->visit,  1)
set stat = alterlist(st_request->person, 1)

set st_request->visit[1]->encntr_id  = $enc_id
set st_request->person[1]->person_id = $per_id


execute 14_st_war_trend_dose with replace('REQUEST', 'ST_REQUEST')

set ret_string = cnvtrectojson(dosing) 

call echo(ret_string) 
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
 
#exit_script
 
call putStringToFile($OUTDEV, ret_string)
 
end
go
 