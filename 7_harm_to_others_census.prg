/******************************************************************************************************
Program Title:      Potential for Harm to Others Census Report
Object name:        7_harm_to_others_census
Source file:        7_harm_to_others_census.prg
Implementation:     July 2020
MCGA:               219060      (Key Users:  Kimberly Handel and Dr Hussein M Tahan)
SOM Task:           TASK3099969
Purpose:            This Census-like report will be used to capture any patient with any positive indication of being
                    violent.
                    (1) a "Safety Contract Initiated" =  "Yes, see paper form on chart"
                    (2) -  "Concerns regarding staff safety" or "Concerns regarding staff safety - HX" = something other than "none"
                        -   Affect/Behavior something other than "appropriate" or "calm)  -- or--
                        -   Problem in the banner bar that includes
                    (3) Potential for Harm to Others IPOC. ... if the IPOC is initiated.
 
                    The report is available in a spreadsheet format. It can be run from Reporting Portal and
                    Discern Analytics 2, using the below mentioned parameters as desired.
 
NOTES:              This report has been cloned from the following reports:
                    - 7_census_date_range.prg
                    - 7_central_line_days.prg
                    - 7_hapu.prg
                    Prompt Builder includes lots of code for flexing some parameters based on others. Look for the
                    'Form Tools' button, then the 'Edit Code' button, to get to the code that controls the flexing of
                    the parameters.
*******************************************************************************************************
Modification History
-------------------------
#001 07/07/2020   Brian Twardy
Source: cust_script:7_harm_to_others_census.prg
MCGA: 219060
SOM Task: TASK3099969
Inital Implementation.
-------------------------
#002 03/31/2022  Brian Twardy
MCGA: 231250
SOM Task: REQ2699476/RITM2759338/TASK5082113
Requester: Jennifer Mcqueeney
Capacity Management Project: Electronic Location Name Change (ED) 
-------------------------
#003 07/21/2023  Brian Twardy
MCGA: n/a
SNOW Incident: INC0254878
Requester: Alexa Singer
The Interdisciplinary Plan of Care (IPOC) was always suppose to tag a patient as a harm to others by this
report, only if the IPOC is (not was) initiated.  This is now the case.
-------------------------
#004 09/15/2023 David Smith
MCGA: 240717
SOM Task: SCTASK0045301
Requester: Alexa Singer
Removing "ZZZTEST" and other test patient naming conventions
-------------------------
#005 07/03/2023   Brian Twardy
Source: cust_script:7_harm_to_others_census.prg   (no name change)
MCGA: 239441
SOM RITM/Task: RITM0020704 / SCTASK0029542
Requester: Raoul Moran
Added "Safety contract for aggressive behavior"

-------------------------------------------------------------------------------------------------------
999   03/11/2024        Chris Grobbel       MCGA 345903         Add qualify on Affect/Behavior - Norms 
007   06/07/2024        Michael Mayes       MCGA 348254         Adding many Problem codes that also appear on the rule 
                                                                CN_HARM_PROB_ALERT
*******************************************************************************************************/
 
drop program 7_harm_to_others_census go
create program 7_harm_to_others_census
 
prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Leave this as MINE, then you can copy and save the displayed spreadsheet.
    , "Current Patients Only" = 1
    , "Muliple Facilities?" = 0              ;* With multiple facilities, you may not choose specific Nurse Units.
    , "Facility" = 4366129.00
    , "Facilities" = 0
    , "Include Active Units Only?" = 1
    , "Nurse Unit" = VALUE(*             )
    , "Start Date/Time" = "SYSDATE"
    , "End Date/Time" = "SYSDATE"
    , "Report Type" = "S"
 
with OUTDEV, CURRENT_ONLY, MULT_FACS, FAC, FACS, UNIT_ACTV, NURSE_UNIT, START_DT,
    END_DT, REP_TYPE
 
;---------------------------------------------------------------------------------------------------------------------
; Right off the bat, check to see if the user chose to report on multiple facilities, but did not choose any.
; If that's the case... kick the user out.  It's being done here and not in Prompt Builder, because the 'Multiple
; Facilities' option is only "required" if the user checks the "Multiple Facilities?" box. Otherwise, it is not
; required (in fact, it is ignored totally.)
;---------------------------------------------------------------------------------------------------------------------
 
If ($MULT_FACS = 1 and ; 1 means multiple facilities were requested by the user
    substring(1,1,reflect(parameter(5,0))) = "I")  ; The only time an "I__" (for integer) is returned is when nothing was
                                                   ; entered or selected. The integer is a 0.
    select into $OUTDEV
    from dummyt
 
    Detail
        col 001  "Potential for Harm to Others Census Report"
        Row + 2
        col 001  "You checked the 'Multiple Facilities?' box, but you did not chose any facilities."
        Row + 1
        col 001  "You must make a choice. There is no default."
        Row + 2
        col 001  "Try again."
        Row + 1
    with format, separator = " "
 
    GO TO EXIT_PROGRAM
 
endif
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RECORD_STRUCTURE:   facs
;
; This is to hold the requested facilities
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
free record facs
record facs
(
  1 qual[*]
    2 loc_facility_cd       = f8
    2 loc_building_cd       = f8
    2 facs_disp             = vc
    2 facs_desc             = vc
)
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  RECORD_STRUCTURE:   nu
;
;  nu - This is to hold the requested Nursing Units
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
free record nu
record nu
(
  1 ctr = i4
  1 qual[*]
    2 unit_ctr              = i4
    2 nu_cd                 = f8
    2 nu_disp               = vc
    2 nu_desc               = vc
)
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  RECORD_STRUCTURE:   elh_enc
;
; ------  This record structure is used to hold encntr_loc_hist encntr_ids. This
;         will be used when one or several nurse units are requested from the
;         report parameters (rathan than Any(*).  All encntr_ids from
;         elh_loc_hist will be loaded in this record structure. Then, this
;         record structure list of encntr_ids will be used to look for  any
;         other encntr_loc_hist rows for these same enconters... that appear/apply
;         considering the requested date range specified by the $START_DT $END_DT
;         date range.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
free record elh_enc
record elh_enc
(
    1 cnt = i4
    1 qual [*]
        2 loc_facility_cd               = f8
        2 loc_building_cd               = f8
        2 encntr_id                     = f8
)
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  RECORD_STRUCTURE:   elh
;
; ------  This record structure is used to hold encntr_loc_hist data for
;         each patient transfer from unit to unit. One row will exist for each
;         stay on a unit... for each patient.
;
;   This rows will be created with an active_ind = 1. When one row is merged with another one,
;   the row that is melting into another will have it's active_ind set to 0.
;   Since these inactive rows will be ignored as this script continues, take note.  Take a serious note.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
free record elh
record elh
(
    1 cnt = i4
    1 qual [*]
        2 filters                   = vc
        2 active_ind                = i2            ; Used when merging consecutive elh rows.
        2 duplicate_ind             = i2            ; Used when merging consecutive elh rows.
        2 elh_active_ind            = i2            ; Used when getting rid of duplicates. This is the active_ind from the elh table.
        2 begin_unit                = vc
        2 begin_unit_cd             = f8
        2 loc_room_cd               = f8
        2 loc_bed_cd                = f8
        2 begin_trans               = vc
        2 begin_trans_dq8           = dq8
        2 end_unit                  = vc
        2 end_trans_dq8             = dq8
        2 end_trans                 = vc
        2 loc_facility_cd           = f8            ; 06/12/2020  Needed?
        2 loc_building_cd           = f8            ; 06/12/2020  Needed?
        2 encntr_id                 = f8
        2 person_id                 = f8
        2 name_full_formatted       = vc
        2 mrn                       = vc
        2 fin                       = vc
        2 diagnosis                 = vc
        2 reg_dt_tm                 = dq8
        2 disch_dt_tm               = dq8
        2 pass                      = i2
        2 next_transaction_dt_tm    = dq8
        2 Affect_Behavior           = vc
        2 Affect_Behavior_dt_tm     = dq8
        2 Concerns_Staff_Safety     = vc
        2 Concerns_Staff_Safety_dt_tm = dq8
        2 Concerns_Staff_Safety_hx  = vc
        2 Concerns_Staff_Safety_hx_dt_tm = dq8
        2 Safety_contract_impl       = vc
        2 Safety_contract_impl_dt_tm = dq8
        2 ipoc_Harm_to_Others_dt_tm  = dq8
        2 problem_ind                = i2
        2 safety_for_aggr_behav      = vc                           ; 005 07/03/2023 New
        2 safety_for_aggr_behav_dt_tm = dq8                         ; 005 07/03/2023 New
)
 
;-----------------------------------------------------------------------------------------
;;;  Below, we are taking the Building code from $FAC, then translating it to Facility code.
 
declare fsh_cd = f8 with constant(633868.00)        ;   Franklin Square Hospital Center
declare guh_cd = f8 with constant(4366007.00)       ;   Georgetown University Hospital
declare gsh_cd = f8 with constant(4364921.00)       ;   Good Samaritan Hospital
declare hbr_cd = f8 with constant(4365513.00)       ;   Harbor Hospital Center
declare nrh_cd = f8 with constant(4368977.00)       ;   National Rehabilitation Hospital
declare umh_cd = f8 with constant(4365807.00)       ;   Union Memorial Hospital
declare whc_cd = f8 with constant(4366129.00)       ;   Washington Hospital Center
declare mmc_cd = f8 with constant(451799759)        ;   Medstar Montgomery Medical Center
declare smhc_cd = f8 with constant(506811697)       ;   Medstar Southern Maryland Hospital Center
declare smh_cd = f8 with constant(522026385)        ;   Medstar St Mary's Hospital
 
;declare facility_cd = f8
;set facility_cd = (if     ($FAC = fsh_cd)
;                               633867.00
;                   elseif ($FAC = guh_cd)
;                               4363210.00
;                   elseif ($FAC = gsh_cd)
;                               4362818.00
;                   elseif ($FAC = hbr_cd)
;                               4363058.00
;                   elseif ($FAC = nrh_cd)
;                               4364516.00
;                   elseif ($FAC = umh_cd)
;                               4363156.00
;                   elseif ($FAC = whc_cd)
;                               4363216.00
;                   elseif ($FAC = mmc_cd)
;                               446795444
;                   elseif ($FAC = smhc_cd)
;                               465210143
;                   elseif ($FAC = smh_cd)
;                               465209542
;                   endif)
 
 
declare any_nu_flg = c1 with
        Constant(substring(1,1,reflect(parameter(7,0))))   ;#7 is for $NURSE_UNIT
Declare ANY_UNIT_IND = i2
Declare MVC_UNIT_DISP = vc
 
declare any_facs_flg = c1 with
        Constant(substring(1,1,reflect(parameter(5,0))))   ;#5 is for $FACS  (This contains multiple facilities. $FAC... just one)
Declare ANY_FACS_IND = i2
Declare MVC_FACS_DISP = vc
 
declare NRSEUNIT_CD  = f8 with
        constant(uar_get_code_by("MEANING",222,"NURSEUNIT"))
 
Declare UMHCCRU_CD = f8 with constant(uar_get_code_by("DISPLAYKEY", 220, "UMHCCRU"))    ; 4385285.00
 
Declare START_CHART_DT              = vc with noconstant("")
Declare END_CHART_DT                = vc with noconstant("")
 
declare nuCnt                   = i4 with noconstant(0)
declare edCnt                   = i4 with noconstant(0)
declare Cnt                     = i4 with noconstant(0)
declare cnt_last                = i4 with noconstant(0)
declare cnt_w                   = i4 with noconstant(0)
declare idx                     = i4 with noconstant(0)
declare idxn                    = i4 with noconstant(0)
declare idxn1                   = i4 with noconstant(0)
declare idxn2                   = i4 with noconstant(0)
declare cnt_elh                 = i4 with noconstant(0)
declare total_patients          = i4 with noconstant(0)
 
declare nu_id                   = i2 with noconstant(0)
declare message_1               = vc with noconstant('')
declare message_2               = vc with noconstant('')
 
declare INPATIENTREFERRAL_CD = f8
                        with constant(uar_get_code_by("DISPLAYKEY", 71, "INPATIENTREFERRAL")) ; 607971507.00    06/15/2016 new
declare NRHLEAVEOFABSENCE_CD = f8
                        with constant(uar_get_code_by("DISPLAYKEY", 71, "NRHLEAVEOFABSENCE")) ; 607970233.00    07/20/2026 new
declare INTERNATIONALADULT_CD = f8
                        with constant(uar_get_code_by("DISPLAYKEY", 71, "INTERNATIONALADULT")) ; 607970285.00   07/20/2026 new
declare INTERNATIONALCHILD_CD = f8
                        with constant(uar_get_code_by("DISPLAYKEY", 71, "INTERNATIONALCHILD")) ; 607970245.00   07/20/2026 new
 
declare UMH_ER_CD  = f8 with
        constant (8036519.00) ;(uar_get_code_by("DISPLAYKEY",220,"UMHER"))                  ; 03/31/2022
declare FSH_ER_CD  = f8 with
        constant (633869.00) ; (uar_get_code_by("DISPLAYKEY",220,"FSHEMERMDEPT"))           ; 03/31/2022
declare FSH_PED_ER_CD  = f8 with
        constant(uar_get_code_by("DISPLAYKEY",220,"FSHEMERPEDCTR"))
declare GSH_ER_CD  = f8 with
        constant(8035878) ;(uar_get_code_by("DISPLAYKEY",220,"GSHER"))                      ; 03/31/2022
declare GUH_ED2_CD  = f8 with
        constant (8360363.00) ;(uar_get_code_by("DISPLAYKEY",220,"GUHEMR"))                 ; 03/31/2022
declare GUH_EE_CD  = f8 with
        constant(uar_get_code_by("DISPLAYKEY",220,"GUHEMEREXPECTANT"))
declare GUH_EI_CD  = f8 with
        constant(uar_get_code_by("DISPLAYKEY",220,"GUHEMERIMMEDIATE"))
declare GUH_ERM_CD  = f8 with
        constant(uar_get_code_by("DISPLAYKEY",220,"GUHEMERMINOR"))
declare HBR_ES_CD  = f8 with
        constant(8689372.00) ;(uar_get_code_by("DISPLAYKEY",220,"HBRHARBOREMESERVICES"))    ; 03/31/2022
declare WHC_ER_CD  = f8 with
        constant(8689268.00) ;(uar_get_code_by("DISPLAYKEY",220,"WHCEMR"))                  ; 03/31/2022
declare MMC_ED_CD  = f8 WITH
        CONSTANT(451806244.00) ; (uar_get_code_by("DISPLAYKEY",220,"MMMCEMR"))              ; 03/31/2022
declare SMHC_ED_CD  = f8 WITH
        CONSTANT(1569529887.00) ;(uar_get_code_by("DISPLAYKEY",220,"MSMHCEMERGENCYSERVICES")) ;03/31/2022
 
declare WHC_INTERVRAD_CD  = f8 with
        constant(uar_get_code_by("DISPLAYKEY",220,"WHCINTERVRAD"))
declare WHC_CATHLAB_CD  = f8 with
        constant(uar_get_code_by("DISPLAYKEY",220,"WHCCATHLAB"))
 
declare GUH_PACU_CD  = f8 with
        constant(uar_get_code_by("DISPLAYKEY",220,"GUHPACU"))
 
declare prev_encntr_id                  = f8 with noconstant(0.00)
declare prev_begin_unit                 = vc with noconstant("")
declare prev_begin_unit_cd              = f8 with noconstant(0.00)
declare prev_loc_room_cd                = f8 with noconstant(0.00);     = e.loc_room_cd
declare prev_loc_bed_cd                 = f8 with noconstant(0.00);     = e.loc_room_cd
declare prev_unit                       = vc with noconstant("")
declare prev_unit_cd                    = f8 with noconstant(0.00);     = uar_get_code_description(e.loc_nurse_unit_cd)
declare prev_end_trans                  = vc with noconstant("");
declare prev_end_trans_dq8              = dq8 with noconstant(cnvtdatetime("01-JAN-2100 00:00:00"))
declare prev_me_service                 = vc with noconstant ("")
Declare ACTTYPE                         = vc with noconstant(" ")
 
Declare SPREADSHEET_REPORT_TYPE  = vc with constant ("S")
 
Declare Filter1                 = vc    with noconstant("")
Declare Filter2                 = vc    with noconstant("")
Declare Filter3                 = vc    with noconstant("")
Declare Filter4                 = vc    with noconstant("")
Declare Filter5                 = vc    with noconstant("")
Declare Filter6                 = vc    with noconstant("")
Declare Filter7                 = vc    with noconstant("")
Declare Filter8                 = vc    with noconstant("")
 
declare cs72_Affect_Behavior_Norms_cd = f8 with public,constant(uar_get_code_by("DISPLAY_KEY",72,"AFFECTBEHAVIORNORMS")) ;Mod 999
;---------------------------------------------------------------------------------------
;   Email definitions
;---------------------------------------------------------------------------------------
 
DECLARE EMAIL_SUBJECT = VC WITH NOCONSTANT(" ")
 
SET EMAIL_SUBJECT = "Potential for Harm to Others Census Report - Current Patients Only"  ; Only $CURRENT_ONLY = 1 used
 
DECLARE EMAIL_ADDRESSES = VC WITH NOCONSTANT("")
DECLARE EMAIL_BODY = VC WITH NOCONSTANT("")
DECLARE UNICODE = VC WITH NOCONSTANT("")
 
Declare facility_var = vc with constant(cnvtupper(uar_get_code_description($FAC)))    ;facility_cd)))
declare printed_date = vc with
        noconstant(format(cnvtdatetime(curdate,curtime3),"MM/DD/YYYY  hh:mm;;Q"))
 
DECLARE AIX_COMMAND   = VC WITH NOCONSTANT("")
DECLARE AIX_CMDLEN    = I4 WITH NOCONSTANT(0)
DECLARE AIX_CMDSTATUS = I4 WITH NOCONSTANT(0)
 
DECLARE PRODUCTION_DOMAIN = vc with constant("P41")         ; we only want emails to go out from Production
 
Declare EMAIL_ADDRESS   = vc
SET EMAIL_ADDRESS = $OUTDEV             ; Take note that $OUTDEV is moved here, as the email address for the outgoing report
 
SET EMAIL_BODY = concat("potential_harm_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"), ".dat")
 
DECLARE FILENAME = VC
        WITH  NOCONSTANT(CONCAT("potential_harm_",
                              format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q"),
                              trim(substring(3,3,cnvtstring(RAND(0)))),     ;<<<< These 3 digits are random #s
                              ".csv"))
 
;------------------------------------------------------------------------------------------
;; Below, we are creating a file that will hold the email body. The file is named EMAIL_BODY.
;; char(13), char(10)  is a carriage return/Line feed (or maybe it's the other way around.)
 
If ($Rep_type = "E" and ;   We only want to create the file if emails were requested (i.e. when $Rep_type = "E"  -- for email)
    CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.
    Select into (value(EMAIL_BODY))
            build2("The Potential for Harm to Others Census Report is attached to this email.", char(13), char(10), char(13), char(10),
                   "Run date and time: ",
                       format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
                   "For:  ", facility_var, char(13), char(10), char(13), char(10),
                       "This report was run for current patients only")
    from dummyt
    with format, noheading
endif
;----------------------------------------------------------------------------------------
 
/***************************************************************************************
* Build Select Qualifiers from the Prompts                                             *
***************************************************************************************/
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Facilities (When Multiple Facilities was selected by the user.)
; We'll see if the user wants just one Facility or all of them
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
if (any_facs_flg = "C" ) ; A "C" happens when a '*' is present
 
    set ANY_FACS_IND = 1
    set MVC_FACS_DISP = 'All Facilities'
 
else
 
    set ANY_FACS_IND = 0
 
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;Create concatenated list of facilities
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
    select into 'nl:'
        cv.display
    from
        code_value cv
    where
        cv.code_value in ($FACS) and
        cv.code_value > 0
    head report
        cnt = 0
    detail
        cnt = cnt + 1
        if (cnt = 1)
            MVC_FACS_DISP = cv.display
        else
            MVC_FACS_DISP = concat(MVC_FACS_DISP, ', ', cv.display)
        endif
 
    with nocounter
 
endif
 
Set cnt = 0         ; back to where it was... for later processing that may use this counter for other things.
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NURSE UNITS
;
; We'll see if the user wants just one Nurse Unit or all of them. If the user choose multiple facilities,
; then he/she is getting all of them. No choice in that case.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
if ($MULT_FACS = 1) ; 1 means that the user did select from the  multiple facilities drop down parameter. Good!
                    ; We will choose each nurse unit for each of those facities. No choice for the user.
 
    set ANY_UNIT_IND = 1
 
    set MVC_UNIT_DISP = 'All Units - active units only'
 
 
elseif (any_nu_flg = "C" ) ; A "C" happens when a '*' is present
 
    set ANY_UNIT_IND = 1
;   set MVC_UNIT_DISP = 'All Units'                             ; 12/19/2014  Replaced with the below 'if'              ;
 
    set MVC_UNIT_DISP =
                   (if ($UNIT_ACTV = 1)
                        'All Units - active units only'
                    else
                        'All Units - inactive units included'
                    endif)
else
 
    set ANY_UNIT_IND =0
 
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;Create concatenated unit label
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
    select into 'nl:'
        cv.display
    from
        code_value cv
    where
        cnvtint(cv.code_value) in ($NURSE_UNIT) and
        cv.code_value > 0 ;and
;       cv.active_ind = 1                                       ; 12/19/2014  Greened out today.
 
    head report
        cnt = 0
 
    detail
        cnt = cnt + 1
        if (cnt = 1)
            MVC_UNIT_DISP = cv.display
        else
            MVC_UNIT_DISP = concat(MVC_UNIT_DISP, ', ', cv.display)
        endif
 
    with nocounter
 
endif
 
Set cnt = 0         ; back to where it was... for later processing that may use this counter for other things.
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Address the singular or multiple facilities that the user may select.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
If ($MULT_FACS = 1)         ; 1 means the user chose the 'Multiple Facs' drop down, so 1, several, or Any facilities (buildings)
                            ; are being requested.
 
    select
        if (any_facs_flg = "C")
            plan cv
              where cv.cdf_meaning = "BUILDING"  and
                    cv.code_value in
                     (   633868.00,   ; Franklin Square Hospital Center
                        4366007.00,   ; Georgetown University Hospital
                        4364921.00,   ; Good Samaritan Hospital
                        4365513.00,   ; Harbor Hospital
                      522026385.00,   ; MedStar St Mary's Hospital
                      451799759.00,   ; MedStar Montgomery Medical Center
                      506811697.00,   ; MedStar Southern Maryland Hospital Center
                        4368977.00,   ; National Rehabilitation Hospital
                        4365807.00,   ; Union Memorial Hospital
                        4366129.00)   ; Washington Hospital Center
                  and cv.active_ind = 1
                  and cv.begin_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
                  and cv.end_effective_dt_tm  >= cnvtdatetime(curdate,curtime3)
        endif
    into "nl:"
    from code_value cv
    plan cv
          where cv.cdf_meaning = "BUILDING"  and
                cv.code_value = $FACS
    order by  cnvtupper(cv.description)
    head report
        cnt = 0
    detail
        Cnt = Cnt + 1
        stat = alterlist(facs->qual,Cnt)
        facs->qual[Cnt].loc_building_cd  = cv.code_value
        facs->qual[Cnt].facs_disp = cv.display
        facs->qual[Cnt].facs_desc = cv.description
        facs->qual[Cnt].loc_facility_cd  = (if     (cv.code_value = fsh_cd)
                                                        633867.00
                                            elseif (cv.code_value = guh_cd)
                                                        4363210.00
                                            elseif (cv.code_value = gsh_cd)
                                                        4362818.00
                                            elseif (cv.code_value = hbr_cd)
                                                        4363058.00
                                            elseif (cv.code_value = nrh_cd)
                                                        4364516.00
                                            elseif (cv.code_value = umh_cd)
                                                        4363156.00
                                            elseif (cv.code_value = whc_cd)
                                                        4363216.00
                                            elseif (cv.code_value = mmc_cd)
                                                        446795444
                                            elseif (cv.code_value = smhc_cd)
                                                        465210143
                                            elseif (cv.code_value = smh_cd)
                                                        465209542
                                            endif)
;   endif
    with nocounter
 
else        ; The user did not want to choose from the multiple Facilities drop down. One facility was fine, so he/she choose
            ; that facility and it is found on $FAC. We will load the record structure FACS though. later, the CCL will
            ; always look there for the one or multiple selected facilities (buildings).
 
    set stat = alterlist(facs->qual,1)
    set facs->qual[1].loc_building_cd = $FAC
    set facs->qual[1].facs_disp = uar_get_code_display($FAC)
    set facs->qual[1].facs_desc = uar_get_code_description($FAC)
    set facs->qual[1].loc_facility_cd = (if    ($FAC = fsh_cd)
                                                    633867.00
                                        elseif ($FAC = guh_cd)
                                                    4363210.00
                                        elseif ($FAC = gsh_cd)
                                                    4362818.00
                                        elseif ($FAC = hbr_cd)
                                                    4363058.00
                                        elseif ($FAC = nrh_cd)
                                                    4364516.00
                                        elseif ($FAC = umh_cd)
                                                    4363156.00
                                        elseif ($FAC = whc_cd)
                                                    4363216.00
                                        elseif ($FAC = mmc_cd)
                                                    446795444
                                        elseif ($FAC = smhc_cd)
                                                    465210143
                                        elseif ($FAC = smh_cd)
                                                    465209542
                                        endif)
 
endif
 
;GO TO EXIT_PROGRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Address the Nursing Units that will be selected by the user.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
;If ($MULT_FACS = 0)    ; 0 means that the user did not select from the multiple facilities drop down parameter. Good!
;                   ; Otherwise, the user would not even see thsi Nurse Unkts parameter.  Prompt Builder would have hid it.
    select
        if (any_nu_flg = "C" or $MULT_FACS = 1)
;            plan lg where lg.parent_loc_cd = $FAC
             plan lg where expand(idx, 1, size(facs->qual,5), lg.parent_loc_cd, facs->qual[idx].loc_building_cd)
                       and ((( $UNIT_ACTV = 1 or $MULT_FACS = 1) and lg.active_ind = 1) or $UNIT_ACTV = 0 )
                       and  lg.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
                       and ((($UNIT_ACTV = 1 or $MULT_FACS = 1) and lg.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)) or $UNIT_ACTV = 0)
 
 
            join lg1                                                        ;  We are looking for only actives ---or---
                where (lg1.parent_loc_cd = lg.child_loc_cd or               ;      actives and inactives here
                      (lg1.parent_loc_cd = lg.parent_loc_cd and
                       lg1.child_loc_cd in(8689382,                     ;8689382  = FSH Emergency Pediatric CTR
                                           WHC_INTERVRAD_CD,
                                           WHC_CATHLAB_CD)))
 
                  and (lg1.location_group_type_cd = NRSEUNIT_CD or
                       lg1.parent_loc_cd in(UMH_ER_CD, FSH_ER_CD, FSH_PED_ER_CD, GSH_ER_CD, GUH_ED2_CD,
                                            GUH_EE_CD, GUH_EI_CD, GUH_ERM_CD ,HBR_ES_CD, WHC_ER_CD)
                        or lg1.child_loc_cd in( FSH_PED_ER_CD,
                                            WHC_INTERVRAD_CD, WHC_CATHLAB_CD )
                      )
 
                  and lg1.root_loc_cd + 0 = 0.0
                  and ((($UNIT_ACTV = 1 or $MULT_FACS = 1) and lg1.active_ind = 1) or $UNIT_ACTV = 0)
                  and lg1.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
                  and ((($UNIT_ACTV = 1 or $MULT_FACS = 1)  and lg1.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)) or $UNIT_ACTV = 0)
 
        endif
 
        distinct into "nl:"
        loc_key = (if(lg1.child_loc_cd in(8689382.00,
                                          WHC_INTERVRAD_CD,
                                          WHC_CATHLAB_CD))
                                lg1.child_loc_cd                    ; 8689382  = FSH Emergency Pediatric CTR
                    else
                                lg1.parent_loc_cd
                    endif),
        loc_desc = (if(lg1.child_loc_cd in( 8689382,WHC_INTERVRAD_CD, WHC_CATHLAB_CD ))
                                    uar_get_code_description(lg1.child_loc_cd)
                    else uar_get_code_description(lg1.parent_loc_cd)
                    endif)
 
      from
         location_group lg
        ,location_group lg1
 
      plan lg where lg.parent_loc_cd = $FAC
      and lg.child_loc_cd = $NURSE_UNIT
 
    join lg1
        where lg1.parent_loc_cd = lg.child_loc_cd
 
    order by  loc_key
    detail
 
    if (loc_desc != 'Train*' and
        loc_desc != 'vv*')
        nuCnt = nuCnt + 1
        stat = alterlist(nu->qual,nuCnt)
        nu->qual[nuCnt].nu_cd   = loc_key
        nu->qual[nuCnt].nu_disp = uar_get_code_display(loc_key)
        nu->qual[nuCnt].nu_desc = uar_get_code_description(loc_key)
    endif
 
    foot report
          nu->ctr =nucnt
 
    with nocounter
 
;endif
 
; select into $outdev
;;      loc_key,
;     l_cd =nu->qual[d.seq].nu_cd,
;    l_disp = trim(substring(1,80,nu->qual[d.seq].nu_disp)),
;    l_desc = trim(substring(1,80,nu->qual[d.seq].nu_desc))
; from (dummyt d with seq = size(nu->qual,5))
; with format, separator = " "
; go to EXIT_PROGRAM
 
 
;----------------------------------------------------------------------------------------
; BUILD FILTER DISPLAY CONTENT
;----------------------------------------------------------------------------------------
;GO TO EXIT_PROGRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BUILD FILTER DISPLAY CONTENT for the spreadsheet report
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 
    set Filter1 = "Potential for Harm to Others Census Report"
;   set Filter2 = concat("Facility:   ", uar_get_code_description($FAC))
    set Filter2 = (If ($MULT_FACS = 0)          ; 0 means that the user did not request multiple facilities... one was enough.
                        concat("Facility:   ", uar_get_code_description($FAC))
                   else
                        concat("Facilities: ", MVC_FACS_DISP)
                   endif)
    set Filter3 = concat("Run Time:   ", format(cnvtdatetime(curdate, curtime3), "MM/DD/YY hh:mm;;D"))
    set Filter4 = (If ($CURRENT_ONLY = 1)
                        "Only Current Patients"
                   Else
                        concat("Date Range: ",
                               format(cnvtdatetime($START_DT), "MM/DD/YYYY hh:mm;;D"), " - ",
                               format(cnvtdatetime($END_DT), "MM/DD/YYYY hh:mm;;D"))
                    Endif)
    set Filter5 = concat("Unit(s): ", MVC_UNIT_DISP)
 
    set Filter6 = concat("*** NO PATIENTS WERE SELECTED ***")
 
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Select patient and encounter data for a range of patents and encounters.
;
; Immediately below, we are looking for all CURRENT encounters for a specific facility.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;*/
 
If ($CURRENT_ONLY = 1)          ; 1 means that this repprt is being run only for current, inhouse patients
 
    select into "nl:"
    from encntr_domain ed,
         encounter e,
         person p           ;MOD004
    plan ed
;   where ed.loc_facility_cd = facility_cd and
    where expand (idx, 1, size(facs->qual,5), ed.loc_facility_cd, facs->qual[idx].loc_facility_cd) and
          ed.loc_nurse_unit_cd > 0.00
    and
        ed.active_ind +1 -1  = 1            ; encntr_domain rows need be active for us
    and
        ed.end_effective_dt_tm + 1 - 1 > cnvtdatetime(curdate, curtime3)
    and
        ed.encntr_domain_type_cd + 1 - 1 =  1139.00 ;  CENSUS_CD
    and
        ed.active_status_dt_tm + 1 -1  >= cnvtlookbehind ('180,d')
    and
        ed.loc_building_cd + 1 - 1 > 0
    and
        expand(idxn, 1, nu->ctr, ed.loc_nurse_unit_cd, nu->qual[idxn].nu_cd)
 
    join e
        where e.encntr_id = ed.encntr_id  and
              e.encntr_type_cd not in (        0.00,
                                          5045671.00,   ; recurring Outpatient
                                        607971507.00,   ; Inpatient Referral
    ;                                      309309.00,   ; Outpatient
                                          5762781.00)   ; Client
 
    ;MOD004 - Adding Person Join
    join p where p.person_id = e.person_id
        and p.name_last_key not in ('*MEDSTAR*','ZZZ*','CERNERTEST*')
    ;MOD004 END 
    
    
    order by ed.encntr_id
    head report
        cnt = 0; size(elh_enc->qual,5)
    head e.encntr_id
        cnt = cnt + 1
        stat = alterlist(elh->qual, cnt)
        elh->qual[cnt].loc_facility_cd          = e.loc_facility_cd
        elh->qual[cnt].loc_building_cd          = e.loc_building_cd
        elh->qual[cnt].encntr_id                = e.encntr_id
        elh->qual[cnt].begin_unit               = uar_get_code_description(e.loc_nurse_unit_cd)
        elh->qual[cnt].begin_unit_cd            = e.loc_nurse_unit_cd
        elh->qual[cnt].loc_room_cd              = e.loc_room_cd
        elh->qual[cnt].loc_bed_cd               = e.loc_bed_cd
        elh->qual[cnt].begin_trans              = format(e.reg_dt_tm, "MM/DD/YYYY hh:mm:ss;;Q")
        elh->qual[cnt].begin_trans_dq8          = e.reg_dt_tm
        elh->qual[cnt].encntr_id                = e.encntr_id
        elh->qual[cnt].active_ind               = 1
    with nocounter, time = 900
 
    Go to WE_HAVE_OUR_ENCOUNTERS
 
endif
 
 
;***************************************************************************************
; You get this, right?  Let's stop the show if someone is asking for a census in the future. I mean...
; come on!
;
; Plus.... let's see if the requested date is just too much of a good thing... as in.... too much
 
If (cnvtdatetime($START_DT) > cnvtdatetime($END_DT))
 
    set message_1 = "No patients were selected with your parameters. Take note of your requested Start and End dates. "
    set message_2 = "Your requested Start Date falls AFTER your requested End Date. Try again. "
 
Elseif (any_facs_flg = "C" and                          ; "C" means that a "*" came from Prompt Builder for ANY/ALL Facilities.
        datetimediff(cnvtdatetime($END_DT), cnvtdatetime($START_DT),1) >= 8.00)
 
    set message_1 = "No patients were selected with your parameters. "
    set message_2 = "You may not use a date range longer than 1 week when requesting a census of more than one hospital. "
 
Elseif (any_nu_flg = "C" and                            ; "C" means that a "*" came from Prompt Builder for ANY/ALL Nursing Units.
        datetimediff(cnvtdatetime($END_DT), cnvtdatetime($START_DT),1) >= 15.00)
 
    set message_1 = "No patients were selected with your parameters. "
    set message_2 = "You may not use a date range longer than 2 weeks when requesting a census of a whole hospital. "
 
 
Elseif (any_nu_flg = "L" and                            ; "L" means that a list of units came from Prompt Builder
        datetimediff(cnvtdatetime($END_DT), cnvtdatetime($START_DT),1) >= 32.00)
 
    set message_1 = "No patients were selected with your parameters. "
    set message_2 = "You may not use a date range longer than one month when requesting a census of multiple units. "
 
Elseif (datetimediff(cnvtdatetime($END_DT), cnvtdatetime($START_DT),1) >= 62.00)
 
    set message_1 = "No patients were selected with your parameters. "
    set message_2 = "You may not use a date range longer than 2 months when requesting a census of 1 unit. "
 
else
 
    Go to PARAMETERS_PASSED
endif
 
 
select into $OUTDEV
from dummyt
 
Detail
    col 001  Filter1
    Row + 1
    col 001  Filter2
    Row + 1
    col 001  Filter3
    Row + 1
    col 001  Filter4
    Row + 1
    col 001  Filter5
    row + 2
    col 001 message_1
    row + 1
    col 001  message_2
 
with format, separator = " "
 
GO TO EXIT_PROGRAM
 
 
 
#PARAMETERS_PASSED
 
;***************************************************************************************
;***************************************************************************************
 
; If one is NOT looking for any data less than 6 months old, then one need NOT look for elh_encnt_loc rows with a
; end_effective_dt_tm = "31-DEC-2100 00:00:00".
 
declare END_EFFECTIVE_DT_TM = vc with noconstant("")
 
set END_EFFECTIVE_DT_TM =
        (if (DATETIMEDIFF(cnvtdatetime(curdate,curtime3), cnvtdatetime($END_DT),0 ) < 180 )
                "31-DEC-2100 00:00:00"
         else
                format(cnvtdatetime(curdate, curtime3), "DD-MMM-YYYY hh:mm:ss;;Q")
         Endif)
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Select patient and encounter data for a range of patents and encounters.
;
; Immediately below, we are looking for all encounters for a specific facility.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;*/
 
select into "nl:"
from encounter e
    ,person p
Plan E where e.reg_dt_tm   between cnvtlookbehind("1,M", cnvtdatetime($START_DT) ) and cnvtdatetime($END_DT) and
    ((e.disch_dt_tm between cnvtdatetime($START_DT) and cnvtlookahead("1,M", cnvtdatetime($END_DT) )) or
      e.disch_dt_tm = NULL) and
;      e.loc_facility_cd + 4 - 4 = facility_cd and
      expand(idx, 1, size(facs->qual,5), e.loc_facility_cd, facs->qual[idx].loc_facility_cd) and
      e.encntr_type_cd not in (       0.00,
                                5045671.00,         ; recurring Outpatient
                              607971507.00,         ; Inpatient Referral
;                                309309.00,         ; Outpatient
                                5762781.00)  and    ; Client
      e.loc_nurse_unit_cd > 0.00
      
    ;MOD004 - Adding Person Join
    join p where p.person_id = e.person_id
        and p.name_last_key not in ('*MEDSTAR*','ZZZ*','CERNERTEST*')
    ;MOD004 END 
    
order by e.encntr_id
head report
    cnt = 0; size(elh_enc->qual,5)
head e.encntr_id
    cnt = cnt + 1
    stat = alterlist(elh_enc->qual, cnt)
    elh_enc->qual[cnt].encntr_id = e.encntr_id
    elh_enc->qual[cnt].loc_facility_cd  = e.loc_facility_cd
    elh_enc->qual[cnt].loc_building_cd  = e.loc_building_cd
    elh_enc->cnt = cnt
with nocounter, orahintcbo("index (e xie5encounter)"), time = 900
 
 
;select into $OUTDEV
;   encntr_id = elh_enc->qual[d.seq].encntr_id, elh_enc->cnt
;from (dummyt d with seq = size (elh_enc->qual,5)   )
;;order by encntr_id, begin_trans, end_trans
;order by encntr_id
;with format, separator = " "
;go to EXIT_PROGRAM
 
 
 
;********************************************************************************************************************************
;********************************************************************************************************************************
 
#ELH_HERE_WE_COME
;----------------
 
declare idx = i4 with noconstant(0)
 
;declare next_transaction_dt_tm = dq8 with noconstant(cnvtdatetime("31-DEC-2100 00:00:00"))
Declare prev_loc_nurse_unit_cd = f8 with noconstant(0.00)
Declare prev_loc_room_cd = f8 with noconstant(0.00)
Declare prev_loc_bed_cd = f8 with noconstant(0.00)
 
;go to exit_program
 
select into 'nl:'
from encntr_loc_hist elh,
     encounter e
plan elh
    where expand(idx, 1, size(elh_enc->qual,5), elh.encntr_id, elh_enc->qual[idx].encntr_id) and
         (elh.encntr_type_cd + 3 - 3 !=  309313.00 or ; Preadmit
          elh.loc_nurse_unit_cd > 0.0)
join e where e.encntr_id = elh.encntr_id  and
            (e.disch_dt_tm = NULL     or     elh.transaction_dt_tm <= e.disch_dt_tm)
order by elh.encntr_id,  elh.encntr_loc_hist_id
head report
    cnt = 0             ; to number the rows for the whole record structure
head elh.encntr_id
    cnt_e = 0           ; to number the rows for this particular encounter
detail
    if (cnt_e = 0)
        cnt = cnt + 1
        cnt_e = cnt_e + 1
        stat = alterlist(elh->qual, cnt)
        elh->qual[cnt].encntr_id = elh.encntr_id
        elh->qual[cnt].next_transaction_dt_tm = cnvtdatetime("01-JAN-2599 00:00:00")
        prev_loc_nurse_unit_cd = elh.loc_nurse_unit_cd
        prev_loc_room_cd = elh.loc_room_cd
        prev_loc_bed_cd = elh.loc_bed_cd
 
        elh->qual[cnt].begin_unit               = uar_get_code_description(elh.loc_nurse_unit_cd)
        elh->qual[cnt].begin_unit_cd            = elh.loc_nurse_unit_cd
        elh->qual[cnt].loc_room_cd              = elh.loc_room_cd
        elh->qual[cnt].loc_bed_cd               = elh.loc_bed_cd
        elh->qual[cnt].begin_trans              = format(elh.transaction_dt_tm, "MM/DD/YYYY hh:mm:ss;;Q")
        elh->qual[cnt].begin_trans_dq8          = elh.transaction_dt_tm
        elh->qual[cnt].encntr_id                = elh.encntr_id
        elh->qual[cnt].loc_facility_cd          = e.loc_facility_cd
        elh->qual[cnt].loc_building_cd          = e.loc_building_cd
        elh->qual[cnt].active_ind               = 1
 
    elseif (cnt_e > 0)
        if (elh.loc_nurse_unit_cd != prev_loc_nurse_unit_cd or
            elh.loc_room_cd != prev_loc_room_cd or
            elh.loc_bed_cd != prev_loc_bed_cd)
            cnt = cnt + 1
            cnt_e = cnt_e + 1
            stat = alterlist(elh->qual, cnt)
            elh->qual[cnt].encntr_id = elh.encntr_id
            elh->qual[cnt-1].next_transaction_dt_tm = elh.transaction_dt_tm         ; cnt-1 is being used here for the index, not cnt.... bunky!!!
            prev_loc_nurse_unit_cd = elh.loc_nurse_unit_cd
            prev_loc_room_cd = elh.loc_room_cd
            prev_loc_bed_cd = elh.loc_bed_cd
 
            elh->qual[cnt].begin_unit               = uar_get_code_description(elh.loc_nurse_unit_cd)
            elh->qual[cnt].begin_unit_cd            = elh.loc_nurse_unit_cd
            elh->qual[cnt].loc_room_cd              = elh.loc_room_cd
            elh->qual[cnt].loc_bed_cd               = elh.loc_bed_cd
            elh->qual[cnt].begin_trans              = format(elh.transaction_dt_tm, "MM/DD/YYYY hh:mm:ss;;Q")
            elh->qual[cnt].begin_trans_dq8          = elh.transaction_dt_tm
            elh->qual[cnt].encntr_id                = elh.encntr_id
            elh->qual[cnt].loc_facility_cd          = e.loc_facility_cd
            elh->qual[cnt].loc_building_cd          = e.loc_building_cd
            elh->qual[cnt].active_ind               = 1
 
        endif
    endif
 
foot elh.encntr_id
 
    If (e.disch_dt_tm != NULL)      ; Patient has a Discharge Dt/Tm
        elh->qual[cnt].next_transaction_dt_tm = e.disch_dt_tm
    Else
        elh->qual[cnt].next_transaction_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00")
    endif
 
    ; What follows is one of many exceptions that this program /script could have... and this one exception made it in.
    ; Sometimes, the last elh row in the database does not match the loc_nurse_unit, loc_room, and loc bed found in the
    ; encounter table. Why? Because multiple updates brought in from SMS/Invision at the same time may not be applied
    ; to the encntr_loc_hist table in the correct order. If they are applied in a incorrect order, then selecting them
    ; by elh.encntr_loc_hist_id may not be the best order. Many more times than not, selecting them by
    ; elh.encntr_loc_hist_id is the best bet.  The below "if" will help in some instances when elh.encntr_loc_hist_id
    ; is not so swell.
 
    If (elh->qual[cnt].begin_unit_cd != e.loc_nurse_unit_cd)
        elh->qual[cnt].begin_unit =  uar_get_code_description(e.loc_nurse_unit_cd)
        elh->qual[cnt].begin_unit_cd = e.loc_nurse_unit_cd
        elh->qual[cnt].loc_room_cd = e.loc_room_cd
        elh->qual[cnt].loc_bed_cd = e.loc_bed_cd
        elh->qual[cnt].begin_trans = format(elh.updt_dt_tm,  "MM/DD/YYYY hh:mm:ss;;Q")
        elh->qual[cnt].begin_trans_dq8 = elh.updt_dt_tm
    endif
 
with nocounter, expand = 1
 
;------------------------------------------------------------------------------------
; 01/22/2020  This "If" was added today.  Brian Twardy
;------------------------------------------------------------------------------------
 
If (size(elh->qual,5) <= 0)
    go to OUTPUT_PROCESSING_BEGINS
endif
 
;------------------------------------------------------------------------------------
 
; Let's inactivate any row where the Nurse Unit is not one of the units requested.
 
;If (any_nu_flg != "C" )
    select into "nl:"
    from (dummyt d with seq = size(elh->qual,5))
    plan d
;       where elh->qual[d.seq].begin_unit_cd  not in ($NURSE_UNIT)
        where  0 = locateval(idx, 1, size(nu->qual, 5), elh->qual[d.seq].begin_unit_cd, nu->qual[idx].nu_cd)
    detail
        elh->qual[d.seq].active_ind         =  0
    with nocounter
;endif
 
 
; Some unwanted elh->qual rows still fall down to here. Let's spank them with a -1 active_ind.
 
select into "nl:"
from (dummyt d with seq = size(elh->qual,5))
plan d
    where   elh->qual[d.seq].active_ind         !=  1 or
            cnvtdatetime(elh->qual[d.seq].begin_trans_dq8)          > cnvtdatetime ($END_DT) or
            cnvtdatetime(elh->qual[d.seq].next_transaction_dt_tm)   < cnvtdatetime ($START_DT)
detail
        elh->qual[d.seq].active_ind         =  -1   ; Take note... this is -1 (That's negative one.... for you literati out there.)
with nocounter
 
 
 
;***********************************************************************************************************
;***********************************************************************************************************
 
#WE_HAVE_OUR_ENCOUNTERS
 
;***********************************************************************************************************
;***********************************************************************************************************
;   Get the MRNs, FINs, and assorted data.
;
;***********************************************************************************************************
;***********************************************************************************************************
 
#MRNs_and_FINs
 
Declare enc_id = i4 with noconstant (0)
 
Select into "nl:"
    encntr_id   = elh->qual[d.seq].encntr_id,
    mrn         = cnvtalias(eam.alias,eam.alias_pool_cd),
    fin         = cnvtalias(eaf.alias,eaf.alias_pool_cd)
 
from (dummyt d with seq = size(elh->qual,5)),
      encounter e,
      person p,
      encntr_alias eam,
      encntr_alias eaf
plan d
    where elh->qual[d.seq].encntr_id > 0 and
          elh->qual[d.seq].active_ind > 0
join e
    where
        e.encntr_id = elh->qual[d.seq].encntr_id and
          elh->qual[d.seq].encntr_id > 0
 
join p
    where
        p.person_id = e.person_id
 
join eam
    where eam.encntr_id = elh->qual[d.seq].encntr_id  and
          elh->qual[d.seq].encntr_id > 0 and
          eam.encntr_alias_type_cd = 1079.00 and
          eam.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3) and
          eam.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
join eaf
    where eaf.encntr_id = elh->qual[d.seq].encntr_id and
          elh->qual[d.seq].encntr_id > 0 and
          eaf.encntr_alias_type_cd = 1077.00 and
          eaf.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3) and
          eaf.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
 
Detail
    elh->qual[d.seq].mrn = cnvtalias(eam.alias,eam.alias_pool_cd)
    elh->qual[d.seq].fin = cnvtalias(eaf.alias,eaf.alias_pool_cd)
    elh->qual[d.seq].name_full_formatted = p.name_full_formatted
    elh->qual[d.seq].person_id = p.person_id
    elh->qual[d.seq].reg_dt_tm = e.reg_dt_tm
    elh->qual[d.seq].disch_dt_tm = e.disch_dt_tm
 
with nocounter, time = 240
;   go to EXIT_PROGRAM
 
 
;****************************************************************************************************
;  Getting diagnoses for each patient.
;****************************************************************************************************
 
declare priority = i4 with noconstant(0)
 
select distinct into "nl:"
    diagnosis_display = trim(substring(1, 100, dg.diagnosis_display)),
    priority = (if (dg.clinical_diag_priority = 0.00)
                        99.99
                else
                    dg.clinical_diag_priority
                endif)
from
    (dummyt   d  with seq = size(elh->qual,5)),
    diagnosis dg
 
plan d
    where elh->qual[d.seq].encntr_id > 0 and
          elh->qual[d.seq].active_ind > 0
 
join dg
    where dg.encntr_id = elh->qual[d.seq].encntr_id
      and dg.active_ind  = 1
      and dg.beg_effective_dt_tm < cnvtdatetime(curdate, curtime3)
      and dg.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)
 
order by d.seq, priority, diagnosis_display ;dg.diag_priority
 
head d.seq   ;dg.encntr_id
    cnt = 0
 
head priority
    null
 
head diagnosis_display
    cnt = cnt + 1
 
; We are separating diagnoses with semi-colons, so strip them out from any individual diagnosis and replace with commas.
 
    if(cnt = 1)
         elh->qual[d.seq].diagnosis = diagnosis_display
    elseif (cnt <= 15)
         elh->qual[d.seq].diagnosis = build2(elh->qual[d.seq].diagnosis, "; ", diagnosis_display)
    endif
 
with nocounter, format, separator = " ", maxcol = 10000, time = 120
 
 
;****************************************************************************************************
;  Getting clinical_events for each patient.
;       - Concerns Regarding Staff Safety
;       - Concerns Regarding Staff Safety - HX
;       - Safety contract implemented
;****************************************************************************************************
 
select into "nl:"
from
    (dummyt   d  with seq = size(elh->qual,5)),
    clinical_event ce
plan d
    where elh->qual[d.seq].encntr_id > 0 and
          elh->qual[d.seq].active_ind > 0
join ce
    where ce.encntr_id = elh->qual[d.seq].encntr_id and
          ce.person_id = elh->qual[d.seq].person_id and
          ce.event_cd in (1827123915.00,     ;  Concerns Regarding Staff Safety
                          1827121879.00,     ;  Concerns Regarding Staff Safety - HX
                          1346985045.00) and ;  Safety contract implemented
          ce.event_end_dt_tm between cnvtdatetime(elh->qual[d.seq].reg_dt_tm) and
                                     cnvtdatetime(curdate, curtime3) and
          ce.result_status_cd in (25.00, 34.00, 35.00) and
          ce.valid_until_dt_tm >= cnvtdatetime(curdate, curtime3)
order by d.seq, ce.event_end_dt_tm desc
 
head d.seq
    null
 
Detail
    if (ce.event_cd = 1827123915.00 and                          ;  Concerns Regarding Staff Safety
        elh->qual[d.seq].Concerns_Staff_Safety <= " " and
        ce.result_val > " " and
        ce.result_val != "None at this time")
                elh->qual[d.seq].Concerns_Staff_Safety = ce.result_val
                elh->qual[d.seq].Concerns_Staff_Safety_dt_tm = ce.event_end_dt_tm
    elseif (ce.event_cd = 1827121879.00 and                      ;  Concerns Regarding Staff Safety - HX
            elh->qual[d.seq].Concerns_Staff_Safety_hx <= " " and
            ce.result_val > " " and
            ce.result_val != "None at this time")
                elh->qual[d.seq].Concerns_Staff_Safety_hx = ce.result_val
                elh->qual[d.seq].Concerns_Staff_Safety_hx_dt_tm = ce.event_end_dt_tm
    ; 005 07/03/2023 The below "elseif" was replaced by the one immediately below it
;   elseif (ce.event_cd = 1346985045.00 and                      ;  Safety contract implemented
;           elh->qual[d.seq].Safety_contract_impl <= " " and
;           ce.result_val > " " and
;           ce.result_val != "Not indicated at this time")
;               elh->qual[d.seq].Safety_contract_impl = ce.result_val
;               elh->qual[d.seq].Safety_contract_impl_dt_tm = ce.event_end_dt_tm
    elseif (ce.event_cd = 1346985045.00)                     ;  Safety contract implemented (aka Safety contract for aggressive behavior)
        If (elh->qual[d.seq].Safety_contract_impl <= " " and
            ce.result_val > " " and
            ce.result_val != "Not indicated at this time") 
                elh->qual[d.seq].Safety_contract_impl = ce.result_val
                elh->qual[d.seq].Safety_contract_impl_dt_tm = ce.event_end_dt_tm
        endif
        If (elh->qual[d.seq].Safety_for_aggr_behav <= " " and
            ce.result_val > " ")
                elh->qual[d.seq].Safety_for_aggr_behav = ce.result_val
                elh->qual[d.seq].Safety_for_aggr_behav_dt_tm = ce.event_end_dt_tm
        endif   
    endif
 
with nocounter, format, separator = " ", time = 240,
     orahintcbo("index (ce xie9clinical_event)")
 
;****************************************************************************************************
;  Getting clinical_events for each patient.
;****************************************************************************************************
 
select into "nl:"
    descriptor = trim(substring(1,80,cc.descriptor))
from
    (dummyt   d  with seq = size(elh->qual,5)),
    clinical_event ce,
    ce_coded_result cc
plan d
    where elh->qual[d.seq].encntr_id > 0 and
          elh->qual[d.seq].active_ind > 0
join ce
    where ce.encntr_id = elh->qual[d.seq].encntr_id and
          ce.person_id = elh->qual[d.seq].person_id and
          ce.event_cd in(703839.00,cs72_Affect_Behavior_Norms_cd) and ; Affect/Behavior  ; Mod 999
          ce.event_end_dt_tm between cnvtdatetime(elh->qual[d.seq].reg_dt_tm) and
                                     cnvtdatetime(curdate, curtime3) and
          ce.result_status_cd in (25.00, 34.00, 35.00) and
          ce.valid_until_dt_tm >= cnvtdatetime(curdate, curtime3) and
          ce.event_end_dt_tm = (select max(sub.event_end_dt_tm)
                                from clinical_event sub
                                where sub.encntr_id = ce.encntr_id and
                                      sub.person_id = ce.person_id and
                                      sub.event_cd = 703839.00 and           ;  Affect/Behavior
                                      sub.event_end_dt_tm between cnvtdatetime(elh->qual[d.seq].reg_dt_tm) and
                                                                  cnvtdatetime(curdate, curtime3) and
                                      sub.result_status_cd in (25.00, 34.00, 35.00) and
                                      sub.valid_until_dt_tm >= cnvtdatetime(curdate, curtime3)
                                with nocounter)
 
;;;       not exists (select ccr.event_id
;;;                   from ce_coded_result ccr
;;;                   where ccr.event_id = ce.event_id and
;;;                         ccr.valid_until_dt_tm between cnvtdatetime(curdate, curtime3) and
;;;                                                       cnvtdatetime("31-DEC-2100 23:59:59") and
;;;                         ccr.nomenclature_id + 4 - 4 in (965376.00, ; Appropriate
;;;                                                         961723.00, ; Calm
;;;                                                         962052.00) ; Cooperative
;;;                   with nocounter)
join cc
    where cc.event_id = ce.event_id and
          cc.valid_until_dt_tm > cnvtdatetime(curdate, curtime3) and
          cc.nomenclature_id in (44481314.00,   ; Aggressive behavior
                                   961047.00,   ; Agitated
                                   961255.00,   ; Hostile
                                   961243.00)   ; Combative
order by d.seq, ce.event_end_dt_tm desc /* ,ce.event_id,  descriptor  */
 
head d.seq
    just_this_event_end = 1
head ce.event_end_dt_tm
    if (just_this_event_end = 1)
        elh->qual[d.seq].Affect_Behavior_dt_tm = ce.event_end_dt_tm
    endif
;;head ce.event_id
;;  null
;head descriptor
detail
    if (just_this_event_end = 1)
        if (elh->qual[d.seq].Affect_Behavior <= " ")
            elh->qual[d.seq].Affect_Behavior = descriptor ;ce.result_val
        else
            elh->qual[d.seq].Affect_Behavior = build2(elh->qual[d.seq].Affect_Behavior, ", ", descriptor)
        endif
    endif
foot ce.event_end_dt_tm
    just_this_event_end = 0
;   If (elh->qual[d.seq].Affect_Behavior_dt_tm = NULL)
;       elh->qual[d.seq].Affect_Behavior_dt_tm = ce.event_end_dt_tm
;   endif
 
with nocounter, format, separator = " ",  time = 240,
     orahintcbo("index (ce xie9clinical_event)")
 
 
;****************************************************************************************************
;  Getting this IPOC for any patient charted with it....
;           Potential for Harm to Others, Risk Plan of Care
;****************************************************************************************************
 
select into "nl:"
from
    (dummyt   d  with seq = size(elh->qual,5)),
    pathway p
plan d
    where elh->qual[d.seq].encntr_id > 0 and
          elh->qual[d.seq].active_ind > 0
join p
    where p.encntr_id = elh->qual[d.seq].encntr_id and
          p.pathway_catalog_id =  1833818871.00 and  ;  Potential for Harm to Others, Risk Plan of Care
          p.pw_status_cd = 674356.00   ; Initiated                                                          ; 003 07/21/2023 New
detail
    elh->qual[d.seq].ipoc_Harm_to_Others_dt_tm = p.order_dt_tm   ; initiated dt tm = order_dt_tm
with nocounter
 
 
;****************************************************************************************************
;  Getting 'Potential for harm to others' problem from the Problem table
;****************************************************************************************************
 
select into "nl:"
from
    (dummyt   d  with seq = size(elh->qual,5)),
    problem p,
    nomenclature n
plan d
    where elh->qual[d.seq].person_id > 0 and
          elh->qual[d.seq].encntr_id > 0 and
          elh->qual[d.seq].active_ind > 0
join p
    where p.person_id = elh->qual[d.seq].person_id and
          p.active_ind = 1 and
          p.end_effective_dt_tm between cnvtdatetime(curdate, curtime3) and
                                        cnvtdatetime("31-DEC-2100 23:59:59") and
          p.life_cycle_status_cd = 3301.00 and  ; Active
          p.nomenclature_id > 0.0
join n
    ;007-> They are comparing this to an alert... and the alert looks at... more.  Trying a hot fix here.
    ;where n.nomenclature_id = p.nomenclature_id and
    ;      n.source_vocabulary_cd = value(uar_get_code_by("DISPLAY_KEY",400,"IMO")) and
    ;      n.source_identifier_keycap = "30956744" and  ; Potential for harm to others
    ;     n.active_ind = 1
    where n.nomenclature_id = p.nomenclature_id 
      and n.nomenclature_id in ( 17065318.00 ;Potential for harm to others
                               , 50634797.00 ;Potential for harm to others
                               ,  7699966.00 ;At risk of harming others
                               , 32498689.00 ;At risk of harming others
                               , 49282464.00 ;at moderate risk for harming others
                               , 75052893.00 ;at increased risk for harming others
                               , 32497891.00 ;at high risk of harming others.
                               )
    ;007<-
Detail
    elh->qual[d.seq].problem_ind = 1
with nocounter
 
 
;select into $outdev
;       patient = trim(substring(1,120,elh->qual[d.seq].name_full_formatted)),
;       fin = trim(substring(1,120,elh->qual[d.seq].fin)),
;       mrn = trim(substring(1,120,elh->qual[d.seq].mrn)),
;       active_ind = elh->qual[d.seq].active_ind,
;       begin_unit = trim(substring(1,80,elh->qual[d.seq].begin_unit))
;from
;   (dummyt   d  with seq = size(elh->qual,5))
;   where elh->qual[d.seq].person_id > 0 and
;         elh->qual[d.seq].encntr_id > 0 and
;         elh->qual[d.seq].active_ind > 0
;with format, separator = " "
;
;go to exit_program
 
;***********************************************************************************************************
;***********************************************************************************************************
;
;   OUTPUT PROCESSING BEGINS NOW
;
;***********************************************************************************************************
;***********************************************************************************************************
 
#OUTPUT_PROCESSING_BEGINS
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;   Look to see if there is any data in the "elh" record structure
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
Declare Any_data     = vc   with noconstant("NO")
 
 
select into "nl:"
from (dummyt d with seq = size(elh->qual,5))
plan d
    where   elh->qual[d.seq].active_ind =  1
with nocounter
 
If (curqual = 0)
        set  Any_data = "NO"
Else
        set  Any_data = "YES"
Endif
 
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;   Move the Filters over to the record structure where the spreadsheet will be generated from.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
set cnt = size(elh->qual,5)
set stat = alterlist(elh->qual,cnt + 5)
 
set elh->qual[cnt+1].filters = Filter1
set elh->qual[cnt+2].filters = Filter2
set elh->qual[cnt+3].filters = Filter3
set elh->qual[cnt+4].filters = Filter4
set elh->qual[cnt+5].filters = Filter5
 
If( any_data = "NO")
    set stat = alterlist(elh->qual,cnt + 6)
    set elh->qual[cnt+6].filters = Filter6          ; 'No data for you today' message
Endif
 
 
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;If ($CURRENT_ONLY = 1)
    Select
        If ($REP_TYPE = "S")
            into $outdev
            with format, separator = " "
        Elseif  ($REP_TYPE = "E" and
                 CURDOMAIN = PRODUCTION_DOMAIN) ; CURDOMAIN is a system variable.
                                                ; PRODUCTION_DOMAIN is ours, and it's declared above.
            into value(FILENAME)
            with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress
        endif
 
        FILTERS = Trim(substring(1,120,elh->qual[d.seq].Filters)),
        unit =trim(substring(1,60,elh->qual[d.seq].begin_unit)),
;;;   ; Rooms for "East" anything are screwy when the report is placed into Excel. That is
;;;   ; because values such as "2E08" are treated as exponential values and will
;;;   ; be displayed as 2.00E+08. This has been fixed. See the "ROOM = (If (...." below.
;;;;        active_ind = elh->qual[d.seq].active_ind ,   ; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   09/27/2019
;       room = (If (SUBSTRING(1, 1, uar_get_code_display(elh->qual[d.seq].loc_room_cd)) between "1" and "9" and
;                     SUBSTRING(2, 1, uar_get_code_display(elh->qual[d.seq].loc_room_cd)) = "E")
;                   build2(SUBSTRING(1, 2, uar_get_code_display(elh->qual[d.seq].loc_room_cd)),
;                          " ",
;                          trim(SUBSTRING(3, 62, uar_get_code_display(elh->qual[d.seq].loc_room_cd))))
;                 Else
;                   trim(SUBSTRING(1, 64, uar_get_code_display(elh->qual[d.seq].loc_room_cd)))
;                 Endif),
;       bed = trim(substring(1,40,uar_get_code_display(elh->qual[d.seq].loc_bed_cd))),
 
        room_bed =
            build2(trim(SUBSTRING(1, 64, uar_get_code_display(elh->qual[d.seq].loc_room_cd))),
 
                    (If (elh->qual[d.seq].loc_bed_cd > 0.00)
                       build2("; ",
                              trim(substring(1,40,uar_get_code_display(elh->qual[d.seq].loc_bed_cd))))
                     else
                        ""
                     endif)),
 
        patient = trim(substring(1,120,elh->qual[d.seq].name_full_formatted)),
        fin = trim(substring(1,120,elh->qual[d.seq].fin)),
        mrn = trim(substring(1,120,elh->qual[d.seq].mrn)),
        potential_harm_to_others_problem = (If (elh->qual[d.seq].problem_ind = 1)
                                                "    Yes"
                                            else
                                                ''
                                            endif),
        Affect_Behavior = trim(substring(1,120,elh->qual[d.seq].Affect_Behavior)),
        Affect_Behavior_date = format(cnvtdatetime(elh->qual[d.seq].Affect_Behavior_dt_tm), "MM/DD/YYYY hh:mm;;Q"),
        Concerns_Staff_Safety = trim(substring(1,120,elh->qual[d.seq].Concerns_Staff_Safety)),
;;      Concerns_Staff_Safety_date = format(cnvtdatetime(elh->qual[d.seq].Concerns_Staff_Safety_dt_tm), "MM/DD/YYYY hh:mm;;Q"),
        Concerns_Staff_Safety_hx = trim(substring(1,120,elh->qual[d.seq].Concerns_Staff_Safety_hx)),
;;      Concerns_Staff_Safety_hx_date = format(cnvtdatetime(elh->qual[d.seq].Concerns_Staff_Safety_hx_dt_tm), "MM/DD/YYYY hh:mm;;Q"),
        Safety_contract_impl = trim(substring(1,120,elh->qual[d.seq].Safety_contract_impl)),
        Safety_contract_impl_date = format(cnvtdatetime(elh->qual[d.seq].Safety_contract_impl_dt_tm), "MM/DD/YYYY hh:mm;;Q"),
        Safety_contract_for_aggressive_behavior =                                           ; 005 07/03/2023 New
                trim(substring(1,120,elh->qual[d.seq].Safety_for_aggr_behav)),              ; 005 07/03/2023 New
        Safety_contract_for_aggressive_behavior_date = ; 005 07/03/2023 New
                format(cnvtdatetime(elh->qual[d.seq].Safety_for_aggr_behav_dt_tm), "MM/DD/YYYY hh:mm;;Q"),; 005 07/03/2023 New
        IPOC_harm_to_others = format(cnvtdatetime(elh->qual[d.seq].ipoc_Harm_to_Others_dt_tm), "MM/DD/YYYY hh:mm;;Q"),
        admit =format(elh->qual[d.seq].reg_dt_tm,"MM/DD/YYYY hh:mm;;Q"),
        disch =format(elh->qual[d.seq].disch_dt_tm,"MM/DD/YYYY hh:mm;;Q"),
        diag = trim(substring(1,900,elh->qual[d.seq].diagnosis))
;       admit_to_unit =format(elh->qual[d.seq].begin_trans_dq8,"MM/DD/YYYY hh:mm:ss;;Q"),
;       disch_from_unit = (If (cnvtdatetime(elh->qual[d.seq].next_transaction_dt_tm) = cnvtdatetime("31-DEC-2100 00:00:00"))
;                                   ""
;                          else
;                                   format(cnvtdatetime(elh->qual[d.seq].next_transaction_dt_tm),"MM/DD/YYYY hh:mm:ss;;Q")
;                          endif)
 
    from (dummyt d with seq = size (elh->qual,5))
            where (elh->qual[d.seq].active_ind = 1 and
                    (elh->qual[d.seq].problem_ind = 1 or
                     elh->qual[d.seq].Affect_Behavior > " " or
                     elh->qual[d.seq].Concerns_Staff_Safety > " " or
                     elh->qual[d.seq].Concerns_Staff_Safety_hx > " " or
                     elh->qual[d.seq].Safety_contract_impl > " " or
                     elh->qual[d.seq].ipoc_Harm_to_Others_dt_tm != NULL )
                   )
                    or
                   elh->qual[d.seq].filters > " "
;   order by unit, room, bed, patient
    order by unit, room_bed, patient        ; This is the default
 
;;Else ; ($CURRENT_ONLY = 0)  ; A date range was used to run the report. This is NOT just Current patients.
;;
;;  Select
;;      If ($REP_TYPE = "S")
;;          into $outdev
;;          with format, separator = " "
;;      Elseif  ($REP_TYPE = "E" and
;;               CURDOMAIN = PRODUCTION_DOMAIN) ; CURDOMAIN is a system variable.
;;                                              ; PRODUCTION_DOMAIN is ours, and it's declared above.
;;          into value(FILENAME)
;;          with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress
;;      endif
;;
;;      FILTERS = Trim(substring(1,120,elh->qual[d.seq].Filters)),
;;      unit =trim(substring(1,60,elh->qual[d.seq].begin_unit)),
;;;;;     ; Rooms for "East" anything are screwy when the report is placed into Excel. That is
;;;;;     ; because values such as "2E08" are treated as exponential values and will
;;;;;     ; be displayed as 2.00E+08. This has been fixed. See the "ROOM = (If (...." below.
;;;;;;      active_ind = elh->qual[d.seq].active_ind ,   ; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<   09/27/2019
;;;     room = (If (SUBSTRING(1, 1, uar_get_code_display(elh->qual[d.seq].loc_room_cd)) between "1" and "9" and
;;;                   SUBSTRING(2, 1, uar_get_code_display(elh->qual[d.seq].loc_room_cd)) = "E")
;;;                 build2(SUBSTRING(1, 2, uar_get_code_display(elh->qual[d.seq].loc_room_cd)),
;;;                        " ",
;;;                        trim(SUBSTRING(3, 62, uar_get_code_display(elh->qual[d.seq].loc_room_cd))))
;;;               Else
;;;                 trim(SUBSTRING(1, 64, uar_get_code_display(elh->qual[d.seq].loc_room_cd)))
;;;               Endif),
;;;     bed = trim(substring(1,40,uar_get_code_display(elh->qual[d.seq].loc_bed_cd))),
;;
;;      room_bed =
;;          build2(trim(SUBSTRING(1, 64, uar_get_code_display(elh->qual[d.seq].loc_room_cd))),
;;
;;                  (If (elh->qual[d.seq].loc_bed_cd > 0.00)
;;                     build2("; ",
;;                            trim(substring(1,40,uar_get_code_display(elh->qual[d.seq].loc_bed_cd))))
;;                   else
;;                      ""
;;                   endif)),
;;
;;      patient = trim(substring(1,120,elh->qual[d.seq].name_full_formatted)),
;;      fin = trim(substring(1,120,elh->qual[d.seq].fin)),
;;      mrn = trim(substring(1,120,elh->qual[d.seq].mrn)),
;;;     admit_to_unit =format(elh->qual[d.seq].begin_trans_dq8,"MM/DD/YYYY hh:mm:ss;;Q"),
;;;     disch_from_unit = (If (cnvtdatetime(elh->qual[d.seq].next_transaction_dt_tm) = cnvtdatetime("31-DEC-2100 00:00:00"))
;;;                                 ""
;;;                        else
;;;                                 format(cnvtdatetime(elh->qual[d.seq].next_transaction_dt_tm),"MM/DD/YYYY hh:mm:ss;;Q")
;;;                        endif),
;;      potential_harm_to_others_problem = (If (elh->qual[d.seq].problem_ind = 1)
;;                                              "    Yes"
;;                                          else
;;                                              ''
;;                                          endif),
;;      Affect_Behavior = trim(substring(1,120,elh->qual[d.seq].Affect_Behavior)),
;;      Affect_Behavior_date = format(cnvtdatetime(elh->qual[d.seq].Affect_Behavior_dt_tm), "MM/DD/YYYY hh:mm;;Q"),
;;      Concerns_Staff_Safety = trim(substring(1,120,elh->qual[d.seq].Concerns_Staff_Safety)),
;;;     Concerns_Staff_Safety_date = format(cnvtdatetime(elh->qual[d.seq].Concerns_Staff_Safety_dt_tm), "MM/DD/YYYY hh:mm;;Q"),
;;      Concerns_Staff_Safety_hx = trim(substring(1,120,elh->qual[d.seq].Concerns_Staff_Safety_hx)),
;;;     Concerns_Staff_Safety_hx_date = format(cnvtdatetime(elh->qual[d.seq].Concerns_Staff_Safety_hx_dt_tm), "MM/DD/YYYY hh:mm;;Q"),
;;      Safety_contract_impl = trim(substring(1,120,elh->qual[d.seq].Safety_contract_impl)),
;;      Safety_contract_impl_date = format(cnvtdatetime(elh->qual[d.seq].Safety_contract_impl_dt_tm), "MM/DD/YYYY hh:mm;;Q"),
;;      IPOC_harm_to_others = format(cnvtdatetime(elh->qual[d.seq].ipoc_Harm_to_Others_dt_tm), "MM/DD/YYYY hh:mm;;Q"),
;;      admit =format(elh->qual[d.seq].reg_dt_tm,"MM/DD/YYYY hh:mm;;Q"),
;;      disch =format(elh->qual[d.seq].disch_dt_tm,"MM/DD/YYYY hh:mm;;Q"),
;;      diag = trim(substring(1,900,elh->qual[d.seq].diagnosis))
;;
;;  from (dummyt d with seq = size (elh->qual,5))
;;          where (elh->qual[d.seq].active_ind = 1 and
;;                  (elh->qual[d.seq].problem_ind = 1 or
;;                   elh->qual[d.seq].Affect_Behavior > " " or
;;                   elh->qual[d.seq].Concerns_Staff_Safety > " " or
;;                   elh->qual[d.seq].Concerns_Staff_Safety_hx > " " or
;;                   elh->qual[d.seq].Safety_contract_impl > " " or
;;                   elh->qual[d.seq].ipoc_Harm_to_Others_dt_tm != NULL )
;;                 )
;;                  or
;;                 elh->qual[d.seq].filters > " "
;;; order by unit, room, bed, patient
;;  order by unit, room_bed, patient        ; This is the default
;;
;;Endif
 
 
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 002 01/18/2017 The below AIX_COMMAND replaces the one just below it.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
if  ($REP_TYPE = "E")
 
    SET  AIX_COMMAND  =
        build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
               " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS)
 
;   SET  AIX_COMMAND  =
;       build2 ('(cat ', EMAIL_BODY , ';',  "uuencode ",  filename , " " , filename, ')',
;               ' | mailx -s "', value(email_subject) , '" ' ,EMAIL_ADDRESS , ' -- -f report@medstar.net')
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
    SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
    SET AIX_CMDSTATUS = 0
    CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
    call pause(2)   ; Let's slow things down before the clean up immediately below.
 
;   clean up.   (Removing EMAIL_BODY from $CCLUSERDIR does work.)
 
    SET  AIX_COMMAND  =
        CONCAT ('rm -f ' , FILENAME,  ' | rm -f ' , EMAIL_BODY)
 
    SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
    SET AIX_CMDSTATUS = 0
    CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
endif       ; paired with the #REP_TYPE = "E")
 
 
#EXIT_PROGRAM
 
end
go
 
