/*********************************************************************************************************************************
 Date Written:   September 19, 2017
 Source file:    jdm13_st_meas_enc.prg
 Directory:      CUST_SCRIPT:
 Purpose:        To retrieve Measurement and Vital Sign result data for the specified encntr_id
                 Provide kg to pound conversion, cm to ft/in conversion, deg C to deg F conversion
 Tables updated: NONE
 Executed from:  note template
 
**********************************************************************************************************************************
MODIFICATION CONTROL LOG
**********************************************************************************************************************************
Mod   Date        Engineer              OPAS           Comment
----  ----------- -------------------   ----           ----------------------------------------------------------------------
001   04/03/2018  Simeon Akinsulie          MCGA-210467    Initial release
--------------------
002 06/21/2019  Brian Twardy
MCGA: n/a
SOM Incident: INC7621500   (Customers: Johana Hernandez  from MedStar Medical Group Pediatrics at Olney and Krystal Thousand)
Source CCL:cust_script:14_st_vitals_meas_enc.prg   (no name changes)
Just like 14_meas_enc_comp.prg, the problem was that once the vital signs are entered from the intake form and transfered to the
doctor's note, that conversion from cm/kg changed.
--------------------
003 07/10/2019  Brian Twardy
MCGA: n/a
SOM Incident: INC7864641   (Customers: Theresa Gibson - Washington Physician Partners and
                                       Johana Hernandez from MedStar Medical Group Pediatrics at Olney
Source CCL:cust_script:14_st_vitals_meas_enc.prg   (no name changes)
A rounding error occured for a few KG to pounds and ounces weights. These weights were not caught in the earlier revision made
in June 2019.
--------------------
--------------------
004 06/18/2024  Michael Mayes
MCGA: 347232
Source CCL:cust_script:14_st_vitals_meas_enc.prg   (no name changes)
BMI is being requested to be removed for patients under 2 years of age... in a couple of STs.  This one... and a new one of Vasmis
called 14_amb_growth_cdc_who_st.  He is handling that... Im handling this one.
--------------------
*********************************************************************************************************************************/
drop program 14_st_vitals_meas_enc:dba go
create program 14_st_vitals_meas_enc:dba
 
prompt
    "Output to File/Printer/MINE" = "MINE"
 
with OUTDEV
 
FREE RECORD DATA_REC
RECORD DATA_REC (
  1 PERSON_ID = f8
  1 ENCNTR_ID = f8
  1 DATA_CNT = i4
  1 DATA_LIST [*]
    2 PERFORMED_DT_TM = vc
    2 VS_CNT = i4
    2 VS_LIST [*]
        3 EVENT_CD = f8
        3 EVENT_ID = f8
        3 DISPLAY_KEY = vc
        3 EVENT_DISP = vc
        3 RESULT_VAL = vc
        3 RESULT_UNITS = vc
        3 NORMALCY = vc
        3 NORMAL_LOW = vc
        3 NORMAL_HIGH = vc
        3 EVENT_END_DT_TM = vc
        3 RESULT_STATUS = vc
        3 RESULT_STATUS_CD = f8
        3 RESULT_UNITS_CD = f8
        3 NORMALCY_CD = f8
        3 WEIGHT_IMP = vc
        3 HEIGHT_IMP = vc
        3 DEG_F = vc
        3 MEAS_WT_IND = i2
        3 MEAS_HT_IND = i2
        3 MEAS_BMI_IND = i2
        3 SORT_NUM = i2
)
SET DATA_REC->DATA_CNT = 0
SET stat = alterlist(DATA_REC->DATA_LIST, 2)
 
FREE RECORD VS_REC
RECORD VS_REC (
    1 LMP = vc
    1 DATA_IND = i2
    1 PAT_AGE = i4  ;004
    1 VS_CNT = i4
    1 VS_LIST [*]
        2 DISPLAY_IND = i2
        2 PERFORMED_DT_TM = vc
        2 TEMP = vc
        2 HR = vc
        2 P = vc
        2 RR = vc
        2 SBP = vc
        2 DBP = vc
        2 SPO2 = vc
        2 HT = vc
        2 WT = vc
        2 BMI = vc
        2 BMIPerc = vc
)
SET VS_REC->DATA_IND = 0
SET VS_REC->VS_CNT = 0
SET stat = alterlist(VS_REC->VS_LIST, 2)
 
;(23.0,25.0,34.0,35.0)
FREE SET MF8_ACTIVE
DECLARE MF8_ACTIVE = F8 WITH CONSTANT(UAR_GET_CODE_BY("MEANING", 8, "ACTIVE")), PROTECT
FREE SET MF8_AUTH
DECLARE MF8_AUTH = F8 WITH CONSTANT(UAR_GET_CODE_BY("MEANING", 8, "AUTH")), PROTECT
FREE SET MF8_ALTERED
DECLARE MF8_ALTERED = F8 WITH CONSTANT(UAR_GET_CODE_BY("MEANING", 8, "ALTERED")), PROTECT
FREE SET MF8_MODIFIED
DECLARE MF8_MODIFIED = F8 WITH CONSTANT(UAR_GET_CODE_BY("MEANING", 8, "MODIFIED")), PROTECT
 
FREE SET STR
DECLARE STR = vc
 
FREE SET HT_IN
DECLARE HT_IN = f8 with noconstant (0.00),public
FREE SET HT_FT
DECLARE HT_FT = f8 with noconstant (0.00),public
FREE SET REM_IN
DECLARE REM_IN = f8 with noconstant (0.00),public
 
FREE SET WT_OZ
DECLARE WT_OZ = f8 with noconstant (0.00),public
FREE SET WT_LBS
DECLARE WT_LBS = f8 with noconstant (0.00),public
FREE SET REM_OZ
DECLARE REM_OZ = f8 with noconstant (0.00),public


 
; get VS data for specified encntr_id
select distinct into "nl:"
    C.ENCNTR_ID
    , PERFORMED_DT_TM = format(C.PERFORMED_DT_TM,"MM/DD/YYYY HH:MM;;")
    , C.EVENT_ID
    , C.PERSON_ID
    , C.EVENT_CD
    , EVENT_DISP = UAR_GET_CODE_DISPLAY(VE.EVENT_CD)
    , C.RESULT_VAL
    , RESULT_UNITS = UAR_GET_CODE_DISPLAY(C.RESULT_UNITS_CD)
    , NORMALCY = UAR_GET_CODE_DISPLAY(C.NORMALCY_CD)
    , C.NORMAL_LOW
    , C.NORMAL_HIGH
    , EVENT_END_DT_TM = format(C.EVENT_END_DT_TM,"MM/DD/YYYY HH:MM;;")
    , RESULT_STATUS = UAR_GET_CODE_DISPLAY(C.RESULT_STATUS_CD)
    , C.RESULT_STATUS_CD
    , C.RESULT_UNITS_CD
    , C.NORMALCY_CD
    , CV1.DISPLAY_KEY
    , SORT_NUM =
        if (C.RESULT_UNITS_CD = 252.00) ;DegC
            if (findstring(" RECTAL",cnvtupper(UAR_GET_CODE_DISPLAY(VE.EVENT_CD))) != 0)
                1
            elseif (findstring(" ORAL",cnvtupper(UAR_GET_CODE_DISPLAY(VE.EVENT_CD))) != 0)
                2
            elseif (findstring(" TEMPORAL",cnvtupper(UAR_GET_CODE_DISPLAY(VE.EVENT_CD))) != 0)
                3
            elseif (findstring(" AXILLARY",cnvtupper(UAR_GET_CODE_DISPLAY(VE.EVENT_CD))) != 0)
                4
            elseif (findstring(" TYMPANIC",cnvtupper(UAR_GET_CODE_DISPLAY(VE.EVENT_CD))) != 0)
                5
            elseif (findstring(" SKIN",cnvtupper(UAR_GET_CODE_DISPLAY(VE.EVENT_CD))) != 0)
                6
            else
                0
            endif
        elseif (findstring("HEARTRATE",cnvtupper(CV1.DISPLAY_KEY)) != 0)
            if (findstring("APICAL",cnvtupper(CV1.DISPLAY_KEY)) != 0)
                7
            elseif (findstring("PERIPHERAL",cnvtupper(CV1.DISPLAY_KEY)) != 0)
                8
            elseif (findstring("MONITOR",cnvtupper(CV1.DISPLAY_KEY)) != 0)
                9
            else
                0
            endif
        else
            0
        endif
 
FROM
    V500_EVENT_SET_CANON   V
    , V500_EVENT_SET_EXPLODE   VE
    , CLINICAL_EVENT   C
    , CODE_VALUE   CV1
 
PLAN V WHERE V.PARENT_EVENT_SET_CD in (3995586.00,4173597.00)
JOIN VE WHERE VE.EVENT_SET_CD = V.EVENT_SET_CD
JOIN C WHERE C.ENCNTR_ID = request->visit[1].encntr_id
    AND C.RESULT_STATUS_CD IN (MF8_ACTIVE,MF8_AUTH,MF8_ALTERED,MF8_MODIFIED) ;(23.0,25.0,34.0,35.0)
    AND C.valid_until_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00.00")
    AND C.EVENT_CD = VE.EVENT_CD
JOIN CV1 WHERE CV1.CODE_VALUE = C.EVENT_CD
 
ORDER BY
    C.ENCNTR_ID
    , PERFORMED_DT_TM
    , SORT_NUM
    , C.EVENT_ID
 
head C.ENCNTR_ID
    DATA_REC->ENCNTR_ID = C.ENCNTR_ID
 
head PERFORMED_DT_TM
    DATA_REC->DATA_CNT = DATA_REC->DATA_CNT + 1
    if(mod(DATA_REC->DATA_CNT,2) = 1 and DATA_REC->DATA_CNT > 2)
        stat = alterlist(DATA_REC->DATA_LIST, DATA_REC->DATA_CNT + 1)
    endif
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT = 0
    stat = alterlist(DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST, 10)
 
head C.EVENT_ID
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT = DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT + 1
    if(mod(DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT,10) = 1 and DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT > 10)
        stat = alterlist(DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST, DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT + 9)
    endif
 
foot C.EVENT_ID
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].EVENT_CD = C.EVENT_CD
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].EVENT_DISP = trim(EVENT_DISP)
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].EVENT_END_DT_TM = trim(
    EVENT_END_DT_TM)
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].EVENT_ID = C.EVENT_ID
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].DISPLAY_KEY = trim(CV1.
    DISPLAY_KEY)
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].NORMAL_HIGH = trim(C.
    NORMAL_HIGH)
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].NORMAL_LOW = trim(C.NORMAL_LOW
    )
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].NORMALCY = trim(NORMALCY)
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].NORMALCY_CD = C.NORMALCY_CD
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].RESULT_STATUS = trim(
    RESULT_STATUS)
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].RESULT_STATUS_CD = C.
    RESULT_STATUS_CD
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].RESULT_UNITS = trim(
    RESULT_UNITS)
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].RESULT_UNITS_CD = C.
    RESULT_UNITS_CD
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].RESULT_VAL  = trim(C.
    RESULT_VAL)
 
    if (C.RESULT_UNITS_CD = 271.00) ;kg
 
    ;   wt_oz = round(cnvtreal(c.result_val) * 2.2 * 16.00, 1)          ; 002 06/21/2019  Replaced. See below.
;       wt_oz = round(cnvtreal(c.result_val) * 2.205 * 16.00, 1)        ; 002 06/21/2019  Replacement.   003 07/10/2019 Replaced below
        wt_oz = floor(round(cnvtreal(c.result_val) * 2.205 * 16.00, 1)) ; 003 07/10/2019  Replacement.
 
;       wt_lbs = round(floor(wt_oz / 16.00),0)                          ; 003 07/10/2019  Replaced below
        wt_lbs = floor(wt_oz / 16.00)                                   ; 003 07/10/2019  Replacement.
 
;;      rem_oz = mod(cnvtint(wt_oz),16)                                 ; 002 06/21/2019  Replaced. See below.
;       rem_oz = round((cnvtreal(c.result_val) * 2.205 * 16.00) -       ; 002 06/21/2019  Replacement.   003 07/10/2019 Replaced below
;                  (floor(cnvtreal(c.result_val) * 2.205) *16 ),0)      ; 002 06/21/2019  Replacement.   003 07/10/2019 Replaced below
        rem_oz = floor(round((cnvtreal(c.result_val) * 2.205 * 16.00),1)) -         ; 003 07/10/2019  Replacement.
                (floor(floor(round(cnvtreal(c.result_val) * 2.205 * 16.00, 1)) /    ; 003 07/10/2019  Replacement.
                                                       16.00) * 16.00)              ; 003 07/10/2019  Replacement.
 
        STR = ""
        if (WT_LBS > 0.00)
            STR = trim(cnvtstring(WT_LBS))
            if (REM_OZ > 0.00)
                STR = concat(STR, ' lbs ', trim(cnvtstring(REM_OZ)), ' oz')
            else
                STR = concat(STR, ' lbs ')
            endif
        else
            STR = trim(cnvtstring(WT_OZ))
            STR = concat(STR, ' oz')
        endif
        DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].WEIGHT_IMP = trim(STR)
    else
        DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].WEIGHT_IMP = ""
    endif
 
    if (C.RESULT_UNITS_CD = 246.00) ;cm
        HT_IN = round((cnvtreal(C.RESULT_VAL) / 2.54),0)
        HT_FT = round(floor(HT_IN / 12.00),0)
        REM_IN = mod(cnvtint(HT_IN),12)
        STR = ""
        if (HT_FT > 0.00)
            STR = trim(cnvtstring(HT_FT))
            STR = concat(STR, ' ft ', trim(cnvtstring(REM_IN)), ' in')
        else
            STR = trim(cnvtstring(HT_IN))
            STR = concat(STR, ' in')
        endif
        DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].HEIGHT_IMP = trim(STR)
    else
        DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].HEIGHT_IMP = ""
    endif
 
    if (C.RESULT_UNITS_CD = 252.00) ;DegC
        STR = format(round(((9.00 / 5.00) * cnvtreal(C.RESULT_VAL)) + 32.00,1),"###.#;;F")
        if (findstring(".0",STR) != 0)
            STR = replace(STR,".0","")
        endif
        STR = replace(STR," ","")
        DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].DEG_F = trim(STR)
    endif
 
    if (C.EVENT_CD = 4154120.00)
        DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].MEAS_WT_IND = 1
    elseif (C.EVENT_CD = 4154126.00)
        DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].MEAS_HT_IND = 1
    elseif (C.EVENT_CD = 4154132.00)
        DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST[DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT].MEAS_BMI_IND = 1
    endif
 
foot PERFORMED_DT_TM
    DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].PERFORMED_DT_TM = trim(PERFORMED_DT_TM)
    stat = alterlist(DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_LIST, DATA_REC->DATA_LIST[DATA_REC->DATA_CNT].VS_CNT)
 
foot C.ENCNTR_ID
    DATA_REC->PERSON_ID = C.PERSON_ID
 
with
    nocounter
    , separator=" "
    , format
    , time=60
 
/* free any extra memory allocated to record structure */
set stat = alterlist(DATA_REC->DATA_LIST, DATA_REC->DATA_CNT)
 
; get LMP
FREE SET STR
DECLARE STR = vc
 
select into "nl:"
    C.ENCNTR_ID
    , C.RESULT_VAL
 
FROM
    CLINICAL_EVENT   C
 
PLAN C WHERE C.ENCNTR_ID = request->visit[1].encntr_id
    AND C.RESULT_STATUS_CD IN (MF8_ACTIVE,MF8_AUTH,MF8_ALTERED,MF8_MODIFIED) ;(23.0,25.0,34.0,35.0)
    AND C.valid_until_dt_tm = cnvtdatetime("31-DEC-2100 00:00:00.00")
    AND C.EVENT_CD = 711255.00
    AND C.EVENT_END_DT_TM = (
        SELECT
             MAX(CX.EVENT_END_DT_TM)
        FROM
             CLINICAL_EVENT CX
        WHERE CX.ENCNTR_ID = C.ENCNTR_ID
            AND CX.RESULT_STATUS_CD IN (MF8_ACTIVE,MF8_AUTH,MF8_ALTERED,MF8_MODIFIED) ;(23.0,25.0,34.0,35.0)
            AND CX.EVENT_CD = C.EVENT_CD
            AND CX.VALID_UNTIL_DT_TM > cnvtdatetime(curdate,curtime3)
            with nocounter, orahintcbo("INDEX(CX XIE19CLINICAL_EVENT)"))
    AND C.VALID_UNTIL_DT_TM > cnvtdatetime(curdate,curtime3)
 
ORDER BY
    C.ENCNTR_ID
    , C.EVENT_CD
 
detail
    if (trim(C.RESULT_VAL) != "" and textlen(trim(C.RESULT_VAL)) > 11)
        STR = substring(7,2,C.RESULT_VAL)
        STR = concat(STR, '/', substring(9,2,C.RESULT_VAL))
        STR = concat(STR, '/', substring(3,4,C.RESULT_VAL))
        VS_REC->LMP = STR
    endif
 
with
    nocounter
    , orahintcbo("INDEX(C XIE19CLINICAL_EVENT)")
    , separator=" "
    , format
    , time=60
 
 




;004-> Age work needs done
declare age_str = vc with protect, noconstant

;I don't think we need to be so complex here, I hope.  Outside this weird cnvtage trump card from uCern
set modify cnvtage(0,0,0,12)  ;Make it so we use default strings for everything up to a year... then we use years.
select into 'nl:'
 
  from encounter e
     , person p
 
 where e.encntr_id = request->visit[1].encntr_id
   
   and p.person_id = e.person_id
   
detail
    age_str = cnvtage(p.birth_dt_tm)

    if(findstring("Years", age_str) > 0) VS_REC->PAT_AGE = cnvtint(replace(age_str, 'Years', ''))
    else                                 VS_REC->PAT_AGE = 0
    endif
    
with nocounter



;004<-


FREE SET STR
DECLARE STR = vc
free set i
declare i = i4 with noconstant (0),public
free set j
declare j = i4 with noconstant (0),public

for (i = 1 to DATA_REC->DATA_CNT)
    set VS_REC->VS_CNT = VS_REC->VS_CNT + 1
    if(mod(VS_REC->VS_CNT,2) = 1 and VS_REC->VS_CNT > 2)
        set stat = alterlist(VS_REC->VS_LIST, VS_REC->VS_CNT + 1)
    endif
    set VS_REC->VS_LIST[VS_REC->VS_CNT].PERFORMED_DT_TM = trim(DATA_REC->DATA_LIST[i].PERFORMED_DT_TM)
    set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 0
 
    for (j = 1 to DATA_REC->DATA_LIST[i].VS_CNT)
        ;Temp
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DEG_F) != "")
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
            set STR = trim(DATA_REC->DATA_LIST[i].VS_LIST[j].EVENT_DISP)
            set STR = replace(STR,"Temperature ","")
            set VS_REC->VS_LIST[VS_REC->VS_CNT].TEMP = concat(VS_REC->VS_LIST[VS_REC->VS_CNT].TEMP, ' ',STR, ' - '
                , trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL), ' ', "\'b0"
                , 'C (', trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DEG_F), ' ', "\'b0", 'F); ')
            if (j > 1 and j + 1 < DATA_REC->DATA_LIST[i].VS_CNT)
                set VS_REC->VS_LIST[VS_REC->VS_CNT].TEMP = concat(VS_REC->VS_LIST[VS_REC->VS_CNT].TEMP, ',', char(160))
            endif
        endif
 
        ;WT
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DISPLAY_KEY) in ("WEIGHTDOSING*","WEIGHTMEASURED*"))
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
            set VS_REC->VS_LIST[VS_REC->VS_CNT].WT = concat(VS_REC->VS_LIST[VS_REC->VS_CNT].WT
            , trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL)
            , ' kg (', trim(DATA_REC->DATA_LIST[i].VS_LIST[j].WEIGHT_IMP), ')')
        endif
 
        ;HT
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DISPLAY_KEY) in ("HEIGHTLENGTHDOSING*","HEIGHTLENGTHMEASURED*"))
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
            set VS_REC->VS_LIST[VS_REC->VS_CNT].HT = concat(VS_REC->VS_LIST[VS_REC->VS_CNT].HT
            , trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL)
            , ' cm (', trim(DATA_REC->DATA_LIST[i].VS_LIST[j].HEIGHT_IMP), ')')
        endif
 
        ;BMI
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DISPLAY_KEY) in ("BODYMASSINDEXDOSING","BODYMASSINDEXMEASURED"))
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
            set VS_REC->VS_LIST[VS_REC->VS_CNT].BMI = concat(VS_REC->VS_LIST[VS_REC->VS_CNT].BMI
            , trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL)
            , ' ', trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_UNITS))
        endif
 
        ;BMIPerc
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DISPLAY_KEY) in ("BMIPERCENTILE"))
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
            set VS_REC->VS_LIST[VS_REC->VS_CNT].BMIPerc = concat(VS_REC->VS_LIST[VS_REC->VS_CNT].BMIPerc
            , trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL)
            , ' ', trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_UNITS))
        endif
 
 
        ;HR
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DISPLAY_KEY) like "*HEARTRATE*")
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
            set VS_REC->VS_LIST[VS_REC->VS_CNT].HR = trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL)
            if (j > 1 and j + 1 < DATA_REC->DATA_LIST[i].VS_CNT)
                set VS_REC->VS_LIST[VS_REC->VS_CNT].HR = concat(VS_REC->VS_LIST[VS_REC->VS_CNT].HR, ',', char(160))
            endif
        endif
 
        ;P
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DISPLAY_KEY) like "*PULSE*")
            set VS_REC->VS_LIST[VS_REC->VS_CNT].P = trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL)
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
        endif
 
        ;RR
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DISPLAY_KEY) like "*RESPIRATORYRATE*")
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
            set VS_REC->VS_LIST[VS_REC->VS_CNT].RR = trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL)
        endif
 
        ;SpO2
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DISPLAY_KEY) like "*SPO2*")
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
            set VS_REC->VS_LIST[VS_REC->VS_CNT].SPO2 = trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL)
        endif
 
        ;SBP
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DISPLAY_KEY) like "*SYSTOLIC*")
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
            set VS_REC->VS_LIST[VS_REC->VS_CNT].SBP = trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL)
        endif
 
        ;DBP
        if (trim(DATA_REC->DATA_LIST[i].VS_LIST[j].DISPLAY_KEY) like "*DIASTOLIC*")
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1
            set VS_REC->VS_LIST[VS_REC->VS_CNT].DBP = trim(DATA_REC->DATA_LIST[i].VS_LIST[j].RESULT_VAL)
        endif
 
    endfor
 
    if (VS_REC->VS_LIST[VS_REC->VS_CNT].DISPLAY_IND = 1)
        set VS_REC->DATA_IND = 1
    endif
endfor
 
set stat = alterlist(VS_REC->VS_LIST, VS_REC->VS_CNT)
;call echoxml(DATA_REC)
;call echoxml(VS_REC)
call echorecord(VS_REC)  ;004
 
 
; RTF and other constants
free set rtfStr
declare rtfStr = vc
free set tempStr
declare tempStr = vc
free set num
declare num = i4 with noconstant (0),public
free set cnt
declare cnt = i4 with noconstant (0),public
free set i
declare i = i4 with noconstant (0),public
free set lmp_ind
declare lmp_ind = i2 with noconstant (0),public
free set line1_ind
declare line1_ind = i2 with noconstant (0),public
free set line2_ind
declare line2_ind = i2 with noconstant (0),public
 
declare rhead = vc with protect, constant(concat("{\rtf1\ansi \deff0",
                                                 "{\fonttbl",
                                                 "{\f0\fmodern\Courier New;}{\f1 Arial;}}",
                                                 "{\colortbl;",
                                                 "\red0\green0\blue0;",
                                                 "\red255\green255\blue255;",
                                                 "\red0\green0\blue255;",
                                                 "\red0\green255\blue0;",
                                                 "\red255\green0\blue0;}\deftab2520 "))
set rh2b = "\plain \f0 \fs20 \b \cf0 "      ;bold
set rh2r = "\plain \f0 \fs20 \cf0 "         ;regular
set rh2ru = "\plain \f0 \fs20 \ul \cf0 "    ;regular, underline
set reol = "\par "
set rtfeof = "}"
set rtab = "\tab "
set rtfpcnt = "\'25"
set rtfdeg = "\'b0"
 
if (VS_REC->DATA_IND = 0 and VS_REC->LMP = "")
    set rtfStr = build2(rhead,rh2r)
    ;set tempStr = concat(rtfStr, rtfeof)
    set reply->text = concat(rtfStr, rtfeof)
else
    set rtfStr = build2(rhead)
    set tempStr = rtfStr
 
    for (i = 1 to VS_REC->VS_CNT)
    set line1_ind = 0
    set line2_ind = 0
 
    if (VS_REC->VS_LIST[i].DISPLAY_IND = 1)
 
        if (VS_REC->VS_LIST[i].PERFORMED_DT_TM != "")
            if (i > 1)
                set rtfStr = build2(reol)
                set tempStr = concat(tempStr, rtfStr)
            endif
            set rtfStr = build2(rh2b, VS_REC->VS_LIST[i].PERFORMED_DT_TM)
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, char(160))
            set tempStr = concat(tempStr, ' ', rtfStr,reol)
        endif
 
        if (VS_REC->VS_LIST[i].TEMP != "")
            set rtfStr = build2(rh2b,'Temperature:')
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, VS_REC->VS_LIST[i].TEMP)
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, char(160))
            set tempStr = concat(tempStr, ' ', rtfStr,reol)
            set line1_ind = 1
        endif
 
        if (VS_REC->VS_LIST[i].HR != "")
            set rtfStr = build2(rh2b,'Heart Rate:')
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, VS_REC->VS_LIST[i].HR)
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, char(160))
            set tempStr = concat(tempStr, ' ', rtfStr,reol)
            set line1_ind = 1
        endif
 
        if (VS_REC->VS_LIST[i].P != "")
            set rtfStr = build2(rh2b,'Pulse:')
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, VS_REC->VS_LIST[i].P)
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, char(160))
            set tempStr = concat(tempStr, ' ', rtfStr,reol)
            set line1_ind = 1
        endif
 
        if (VS_REC->VS_LIST[i].RR != "")
            set rtfStr = build2(rh2b,'Respiratory Rate:')
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, VS_REC->VS_LIST[i].RR)
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, char(160))
            set tempStr = concat(tempStr, ' ', rtfStr,reol)
            set line1_ind = 1
        endif
 
        if (VS_REC->VS_LIST[i].SBP != "" and VS_REC->VS_LIST[i].DBP != "")
            set rtfStr = build2(rh2b,'Blood Pressure:')
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, VS_REC->VS_LIST[i].SBP, '/', VS_REC->VS_LIST[i].DBP)
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, char(160))
            set tempStr = concat(tempStr, ' ', rtfStr,reol)
            set line1_ind = 1
        endif
 
        if (VS_REC->VS_LIST[i].SPO2 != "")
            set rtfStr = build2(rh2b,'Oxygen Level:')
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, VS_REC->VS_LIST[i].SPO2, rtfpcnt)
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, char(160))
            set tempStr = concat(tempStr, ' ', rtfStr,reol)
            set line1_ind = 1
        endif
 
        if (line1_ind = 1)
            set rtfStr = build2(reol)
            set tempStr = concat(tempStr, rtfStr)
        endif
 
        if (VS_REC->VS_LIST[i].HT != "")
            set rtfStr = build2(rh2b,'Height:')
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, VS_REC->VS_LIST[i].HT)
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, char(160))
            set tempStr = concat(tempStr, ' ', rtfStr,reol)
            set line2_ind = 1
        endif
 
        if (VS_REC->VS_LIST[i].WT != "")
            set rtfStr = build2(rh2b,'Weight:')
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, VS_REC->VS_LIST[i].WT)
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, char(160))
            set tempStr = concat(tempStr, ' ', rtfStr,reol)
            set line2_ind = 1
        endif
        
        ;004-> I could have done this collection time.  But probably should just do that here so we still gather things normally.
        if(VS_REC->PAT_AGE >= 2)
        ;004<-
            if (VS_REC->VS_LIST[i].BMI != "")
                set rtfStr = build2(rh2b,'Body Mass Index (BMI):')
                set tempStr = concat(tempStr, ' ', rtfStr)
                set rtfStr = build2(rh2r, VS_REC->VS_LIST[i].BMI)
                set tempStr = concat(tempStr, ' ', rtfStr)
                set rtfStr = build2(rh2r, char(160))
                set tempStr = concat(tempStr, ' ', rtfStr,reol)
                set line2_ind = 1
            endif
        
        endif ;004
     
        if (VS_REC->VS_LIST[i].BMIPerc != "")
            set rtfStr = build2(rh2b,'Body Mass Index Percentile:')
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, VS_REC->VS_LIST[i].BMIPerc)
            set tempStr = concat(tempStr, ' ', rtfStr)
            set rtfStr = build2(rh2r, char(160))
            set tempStr = concat(tempStr, ' ', rtfStr,reol)
            set line2_ind = 1
        endif
 
        if (line2_ind = 1)
            set rtfStr = build2(reol)
            set tempStr = concat(tempStr, rtfStr)
        endif
    endif
    endfor
 
    if (VS_REC->LMP != "" and lmp_ind = 0)
        set rtfStr = build2(rh2b,'Last Menstrual Period:')
        set tempStr = concat(tempStr, ' ', rtfStr)
        set rtfStr = build2(rh2r, VS_REC->LMP)
        set tempStr = concat(tempStr, ' ', rtfStr)
        set rtfStr = build2(rh2r, char(160))
        set tempStr = concat(tempStr, ' ', rtfStr)
        set lmp_ind = 1
    endif
 
    set rtfStr = tempStr
    ;set tempStr = concat(rtfStr, rtfeof)
    set reply->text = concat(rtfStr, rtfeof)
 
endif
;call echo(tempStr)
 
end
go