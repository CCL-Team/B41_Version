/***********************************************************************************************************
 Program Title:     3_mp_results_dc_ip.prg
 Create Date:       08/11/2022
 Object name:       3_mp_results_dc_ip
 Source file:       3_mp_results_dc_ip.prg
 MCGA:
 OPAS:
 Purpose:https:
 Executed from:     Explorer Menu
 Special Notes:
 
*************************************************************************************************************
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^IMPORTANT^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*************************************************************************************************************
wrapper: doh_covid19_case_wrapper

Unsolicited results - results not linked to their Lab orders
Result values continue to expand beyond positive/negative - especially from different labs
Results for Patients without Lab orders
 
**************************************************************************************************************
**************************************************************************************************************
**************************************************************************************************************
**************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**************************************************************************************************************
Mod    Date             Analyst                 SOM/MCGA                    Comment
---    ----------       --------------------    ------              ------------------------------------------
N/A    08/11/2022       Jeremy Daniel           N/A                 Initial Release
002    02/02/2024       glp110                  344896              add new Result  POC Rapid COVID-19 PCR  
003    06/08/2024       Michael Mayes           239759              Changing our look back logic, since we can
                                                                    endorse in the same day.
*************END OF ALL MODCONTROL BLOCKS* *******************************************************************/
drop program 3_mp_results_dc_ip go
create program 3_mp_results_dc_ip
 
prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Result Start Date" = "SYSDATE"
    , "Result End Date" = "SYSDATE"
    , "Report Type" = 1
 
with OUTDEV, Start_Dt, End_Dt, Type
 
 
declare componentCd = f8 with constant(uar_get_code_by("DISPLAY_KEY", 18189,"PRIMARYEVENTID")),protect
declare blobout = vc with protect, noconstant(" ")
declare blobnortf = vc with protect, noconstant(" ")
declare lb_seg = vc with protect, noconstant(" ")
declare bsize = i4
declare uncompsize = i4
declare lenblob = i4
DECLARE AUTHVER_CD  =  F8  WITH  CONSTANT ( UAR_GET_CODE_BY ("MEANING" , 8 , "AUTH" )), PROTECT
declare ocfcomp_cd = f8 with Constant(uar_get_code_by("MEANING",120,"OCFCOMP")),protect
declare performloc = vc
declare prcnt = i4
 
DECLARE FILENAME = vc
 
DECLARE dataDate = vc
 
SET dataDate = TRIM(FORMAT(CNVTDATETIME(curdate,curtime3),"mmddyyyyhhmm;;d"),3)


;003->  We need these for the weird result check we do now.
declare fuzzyrange_beg = dq8
declare fuzzyrange_end = dq8
;003<-
 

SET FILE_NAME =  concat("/cerner/d_p41/cust_output_2/doh_covid_results/medstar_dc_mp_results_"
,format(cnvtdatetime(curdate,curtime3),"YYYYMMDDhhmmss;;Q"), ".csv")
    ;build2("medstar_DC_mp_results_msh_pos_mpx_result_", dataDate,".csv");medstar_dc-caseip-"
 

set start_dt_tm = cnvtdatetime((curdate-1), 000000)
set end_dt_tm =   cnvtdatetime((curdate-1), 235959)set end_dt_tm =   cnvtdatetime((curdate-1), 235959)


;003->
set fuzzyrange_beg = cnvtlookbehind('1,M', cnvtdatetime($START_DT))
set fuzzyrange_end = cnvtdatetime($END_DT)

call echo(build('fuzzyrange_beg:', format(fuzzyrange_beg, ';;q')))
call echo(build('fuzzyrange_end:', format(fuzzyrange_end, ';;q')))
;003<-


;***** Set Print Record Structure
record rs
(   1 PRINTCNT = i4
    1 Qual[*]
        2 HeaderCol = vc
        2 EncntrId = f8
        2 PersonId = f8
        2 OrderId = f8
        2 containerid = f8
        2 ResultId = f8
        2 OrderDocId = f8
        2 Encntr_Type = vc
        2 e_location = vc
        2 Clinic_Name = vc
        2 FirstName =  vc
        2 LastName = vc
        2 MRN = vc
        2 FIN = vc
        2 SSN = vc
        2 DOB = vc
        2 age = vc
        2 PREGNANCY_IND = VC
        2 edd = vc
        2 weeks_preg = i2
        2 est_ega_days = i2
        2 Gender = vc
        2 Race = vc
        2 ethnic_cd = vc ; me
        2 StreetAddr = vc
        2 StreetAddr2 = vc
        2 City = vc
        2 County = vc
        2 State = vc
        2 Zip = vc
        2 Phone = vc
        2 Phone_cd = vc
        2 phone2 = vc
        2 phone2_cd = vc
        2 dta = f8
        2 OrderOrgId = f8
        2 OrderNumber = vc
        2 OrderDesc = vc
        2 OrderDtTm = vc
        2 Order_PROVIDER = VC
        2 npi = vc
        2 OrderDocStreetAddr = vc
        2 OrderDocCityStateZip = vc
        2 OrderDocPhone = vc
        2 OrderStatus = vc
        2 AttendDocName = vc
        2 Specimen = vc
        2 ACCESSION = VC
        2 specimenp = f8
        2 ORG_ID = F8
        2 FacCd = vc
        2 FAC_PHONE = VC
        2 fac_ZIP= vc
        2 fac_County = vc
        2 fac_City = vc
        2 fac_State = vc
        2 fac_StreetAddr = vc
        2 fac_StreetAddr2 = vc
        2 OrderingCLIA = vc
        2 PerformingCLIA = vc
        2 PerformOrgId = f8
        2 PerformOrgName = vc
        2 PerformDtTm = vc
        2 CollectionDtTm = vc
        2 PerformResultId = f8
        2 Result = vc
        2 ResultUnit = vc
        2 ResultCmt = vc
        2 ResultCmt2 = vc
        2 RESULT_DT = VC
        2 refRange = vc
        2 Perform_Location = vc
        2 Clinic = vc
        2 ip_status = vc
        2 IP_DTTM = VC
        2 med_name = vc
        2 service_resource = vc
        2 EVENT = VC
        2 ENCNTR_CD = F8
        2 clinical_evt_id = f8
        2 CMRN = VC
        2 pt_phone = vc
        2 bus_phone = vc
        2 onset_dt = vc
        2 LOINC = VC
        2 cough_cd2 = VC
        2 sore_throat_cd2 = VC
        2 st_flu_cd2 = VC
        2 fever_cd2 = VC
        2 RHINO_cd = VC
        2 SOB_cd = VC
        2 ARD_cd = VC
        2 VENT = VC
        2 visit_reason = VC
        2 oc_stat = VC
        2 occupation = VC
        2 homeless  = vc
        2 reg_dt = VC
        2 deceased = vc
        2 disch_dt = VC
        2 HL = VC
        2 LTC = VC
        2 vent_order = vc
        2 VENT_ORDER_NAME = VC
        2 admit_from = f8
        2 jail = vc
        2 UNDER_COND = VC
        2 DIABETES = vc
        2 OBESITY = vc
        2 HYPERTENSION = vc
        2 service_resource = vc
        2 nurse_unit = vc
        2 death_dt = vc
        2 disch_disp = vc
        2 pen = vc
        2 email = vc
        2 vent_order_dttm = vc
        2 PNEUMONIA = VC
        2 acute_resp_disease = vc
        2 MIDDLENAME = VC
        2 problem_id = f8
        2 prob_cd = vc
        2 problem = vc
        2 contactName = VC
        2 contactHomePhone = VC
        2 HYPOXIC = VC
        2 headache = vc
        2 CHILLS = VC
        2 CONGESTION = VC
        2 COLDSWEAT = VC
        2 LOSSAPP = VC
        2 LOSSTASTE = VC
        2 LOSSSMELL = VC
        2 diarrhea = VC
        2 MUSCLEACHE = VC
        2 JOINTPAIN = VC
        2 NECKSTIFF = VC
        2 SWOLLENNECK = VC
        2 WEAKNESS = VC
        2 BRUISING = VC
        2 BLEEDING = VC
        2 PINKEYE = VC
        2 JAUNDICE = VC
        2 RASH = VC
        2 POSITION = VC
        2 ASTHMA = VC
        2 COPD = VC
        2 flu_result = VC
        2 flu_coll_dt = VC
        2 FLU_DESC = VC
        2 strep_result = VC
        2 strep_coll_dt = VC
        2 STREP_DESC = VC
        2 travel = vc
        2 event_id = f8
        2 os_result = vc
        2 direct_care = vc
        2 admit_dx = vc
        2 admit_dx2 = vc
        2 admit_dx3 = vc
        2 admit_dx4 = vc
        2 diag_id = f8
        2 diag_id2 = f8
        2 diag_id3 = f8
        2 cc_result = vc
        2 cc_RESULT_DT = dq8
        2 ORDER_NAME = VC
        2 action_event = vc
 
)
 
 ;*********************************************************************************************************************
;                               VARIABLE DECLARATIONS / EMAIL DEFINITIONS
;*********************************************************************************************************************
IF($TYPE = 3);EMAILING OF REPORT
    DECLARE EMAIL_SUBJECT = VC WITH NOCONSTANT(" ")
    SET EMAIL_SUBJECT = build2("MedStar DC DOH Monkeypox Positive Result Report")
    DECLARE EMAIL_ADDRESSES = VC WITH NOCONSTANT("")
    DECLARE EMAIL_BODY = VC WITH NOCONSTANT("")
    DECLARE UNICODE = VC WITH NOCONSTANT("")
    DECLARE AIX_COMMAND   = VC WITH NOCONSTANT("")
    DECLARE AIX_CMDLEN    = I4 WITH NOCONSTANT(0)
    DECLARE AIX_CMDSTATUS = I4 WITH NOCONSTANT(0)
    DECLARE PRODUCTION_DOMAIN = vc with constant("P41");FOR TESTING ONLY
 
    Declare EMAIL_ADDRESS   = vc
    SET EMAIL_ADDRESS = $OUTDEV
 
    SET EMAIL_BODY = concat("msh_pos_mpx_result_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"), ".dat")
 
    DECLARE FILENAME = VC
            WITH  NOCONSTANT(CONCAT("msh_pos_mpx_result_",
                                  format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q"),
                                  trim(substring(3,3,cnvtstring(RAND(0)))),     ;<<<< These 3 digits are random #s
                                  ".csv"))
 
    IF ($TYPE = 3 and CURDOMAIN = PRODUCTION_DOMAIN)
        Select into (value(EMAIL_BODY))
            build2(
                "The MedStar DC DOH Monkeypox Positive Results Report ",
                "is attached to this email."                                  , char(13), char(10), char(13), char(10),
                "Date Range: ", $START_DT , " to ", $END_DT                   , char(13), char(10), char(13), char(10),
                "Run date and time: ",
                format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q") , char(13), char(10), char(13), char(10)
            )
 
        from dummyt
        with format, noheading
    endif
endif
;*****************************************************************************************************
;                               main select
;*****************************************************************************************************
 
select into "nl:"
 
from
 
Person p
, clinical_event c3
, ce_event_note cen  ;003
 
 
plan c3 where c3.event_cd in (
 3689960967.00
, 3691931613.00
, 3711256891.00
, 3691941627.00
, 3766088351.00
;, 5015944927.00    ;POC Rapid COVID-19 PCR
    )
 
    and c3.valid_until_dt_tm  >= cnvtdatetime(curdate,curtime3)
    and c3.event_class_cd = 236.00
    and c3.valid_from_dt_tm between cnvtdatetime(fuzzyrange_beg) and cnvtdatetime(fuzzyrange_end)
    and c3.result_status_cd in (25,34,35)
    and c3.authentic_flag = 1

;003->  
join cen  
   where cen.event_id = c3.event_id
    and cen.note_dt_tm between CNVTDATETIME($START_DT)AND CNVTDATETIME($END_DT)
;003<-   

join p where p.person_id = c3.person_id
                                AND P.NAME_LAST_KEY not like "ZZ*"
                                AND P.NAME_LAST_KEY != "CAREMOBILE"
                                AND P.NAME_LAST_KEY != "REGRESSION"
                                AND P.NAME_LAST_KEY != "TEST"
                                AND P.NAME_LAST_KEY != "CERNERTEST"
                                AND P.NAME_LAST_KEY != "*PATIENT*"
                                AND not OPERATOR(P.NAME_LAST_KEY,"REGEXPLIKE","[0-9]")
                                and p.active_ind = 1
                                and p.end_effective_dt_tm > cnvtdatetime(sysdate)
 
order by C3.event_id
 
 
head report
    patients = 0
 
head C3.event_id
 
patients = patients + 1
STAT=ALTERLIST(RS->QUAL,PATIENTS)
 
    rs->QUAL[patients]->FirstName = p.name_first
    rs->QUAL[patients]->LastName = p.name_last
    rs->QUAL[patients]->MIDDLEName = p.name_middle
    rs->QUAL[patients]->AGE = CNVTAGE(P.birth_dt_tm)
    rs->QUAL[patients]->DOB = format(p.birth_dt_tm, "MM/DD/YYYY;;D")
    rs->QUAL[patients]->Gender = uar_get_code_display(p.sex_cd)
    rs->QUAL[patients]->Race = uar_get_code_display(p.race_cd)
    rs->QUAL[patients]->ethnic_cd = UAR_GET_CODE_DISPLAY(P.ethnic_grp_cd)
    rs->QUAL[patients]->deceased = uar_get_code_display(p.deceased_cd)
    rs->QUAL[patients]->death_dt = format(p.deceased_dt_tm, "MM/DD/YYYY;;D")
    
    rs->QUAL[patients]->PersonId = c3.person_id
    rs->QUAL[patients]->EncntrId = c3.encntr_id
    rs->QUAL[patients]->OrderId = c3.order_id
    rs->QUAL[patients]->clinical_evt_id = c3.clinical_event_id
    rs->QUAL[patients]->event_id = c3.event_id
    rs->QUAL[patients]->service_resource = uar_get_code_display(c3.resource_cd)
    rs->QUAL[patients]->dta = c3.task_assay_cd
    rs->QUAL[patients]->ACCESSION = C3.accession_nbr
    
 ;   rs->QUAL[patients]->CMRN = PA.alias
 ;  rs->QUAL[patients]->ORG_ID = E.organization_id

;   rs->QUAL[patients]->pen = PH.parent_entity_name
;   rs->QUAL[patients]->pt_phone = ph.phone_num
;   rs->QUAL[patients]->bus_phone = ph3.phone_num
 ;  rs->QUAL[patients]->loinc = cvo.alias

 ;  rs->QUAL[patients]->disch_disp = uar_get_code_display(e.disch_disposition_cd)
;   rs->QUAL[patients]->email = ph2.phone_num
 
 
;       if (rs->QUAL[patients]->ORG_ID in (
;                                     12920488 ;OCC Health locations
;                                   ,12917535
;                                   ,12931572
;                                   ,12917543
;                                   ,12917576
;                                   ,12920513
;                                   ,12917632
;                                   ,12919164
;                                   ,12919157
;                                   ,12917568
;                                   ,12897236
;                                   ,13500062
;                                   ,13497282
;                                   ,13497021
;                                   ,13500524
;                                   ,13498999
;                                   ))
;       rs->QUAL[patients]->oc_stat = "Y"
;       endif
; 
;       if(c3.event_cd = 2404008691)
;       rs->QUAL[patients]->Specimen = "Nasal"
;       rs->QUAL[patients]->service_resource = "BD Veritor Plus"
;       rs->QUAL[patients]->loinc = "94558-4"
;       endif
; 
;       if(c3.event_cd = 2276648185)
;       rs->QUAL[patients]->Specimen = "NP Swab"
;       rs->QUAL[patients]->service_resource = "POC Abbott ID NOW"
;       ;rs->QUAL[patients]->loinc = "94534-5"
;       endif
 
 
with nocounter, time = 1000;, ORAHINTCBO("INDEX( E XIE17ENCOUNTER)")
 
/****************************************************************************************************
                ;results
*****************************************************************************************************/
IF (SIZE (RS->QUAL,5)=0)
go to EXITPROGRAM
ENDIF
;**********************************************************************************************
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
    , CLINICAL_EVENT C
    , encounter e
    , organization org
    , long_blob lb
    , ce_event_note cen
    , order_comment ocm
    , long_text lt
    ,orders o
 
PLAN d
JOIN c where c.event_id = rs->qual[d.seq].event_id
 
and c.event_cd in (
 3689960967.00
, 3691931613.00
, 3711256891.00
, 3691941627.00
, 3766088351.00
    )
 
join o where o.order_id = outerjoin(c.order_id)
 
join cen where cen.event_id = outerjoin(c.event_id)
 
join ocm where ocm.order_id = outerjoin(c.order_id)
 
join lt where lt.long_text_id = outerjoin(ocm.long_text_id)
    and lt.active_ind = outerjoin(1)
    ;and cnvtupper(lt.parent_entity_name)= outerjoin ("RESULT_COMMENT" )
 
join lb
    where lb.parent_entity_id = outerjoin(cen.ce_event_note_id)
 
join e where e.encntr_id = outerjoin(c.encntr_id)
 
join org where org.organization_id = OUTERJOIN(e.organization_id)
 
order by d.seq
 
head d.seq
 
    rs->QUAL[d.seq]->PerformDtTm = format(c.performed_dt_tm, "MM/DD/YYYY hh:mm:ss;;D")
    rs->QUAL[d.seq]->SpecimenP = c.event_cd
    rs->QUAL[d.seq]->event = uar_get_code_display(c.event_cd)
    rs->QUAL[d.seq]->CollectionDtTm = format(c.event_end_dt_tm, "MM/DD/YYYY hh:mm:ss;;D")
    rs->QUAL[d.seq]->Result = cnvtupper(c.result_val);uar_get_code_description(mrr.response_cd)
    rs->QUAL[d.seq].ResultUnit = uar_get_code_display(c.result_units_cd)
    rs->QUAL[d.seq].RESULT_DT = format(C.valid_from_dt_tm, "MM/DD/YYYY hh:mm:ss;;D")
 
 
        if(rs->QUAL[d.seq]->SpecimenP = 2282079581.00) ;COVID-19/Coronavirus - Transcribed Lab
            rs->QUAL[d.seq]->os_result = "Y"
            endif
 
                    ;if(cen.compression_cd = 728.00);ocfcomp_cd)
                if((rs->QUAL[d.seq]->Result) != " ")
 
                blobout = notrim(fillstring(32767," "))
                blobnortf = notrim(fillstring(32767," "))
                if(cen.compression_cd = 728.00);ocfcomp_cd)
                    uncompsize = 0
 
                    blob_un = UAR_OCF_UNCOMPRESS(lb.long_blob, size(Lb.LONG_BLOB),;lenblob,
                                                 blobout, SIZE(blobout), uncompsize)
 
                    stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
 
 
                else
 
                        blobout = trim(substring(1,10000, lb.long_blob))
                        if(cen.note_format_cd = 125.00 )  ; RTF_CD
                            stat = uar_rtf2(blobout,10000,blobnortf,size(blobnortf),bsize,0)
                            blobnortf = substring(1,bsize,blobnortf)
                        else
                            blobnortf = replace(blobout, "ocf_blob", "")
                            bsize = lenblob
                        endif
                endif
 
                    rs->QUAL[d.seq].ResultCmt = replace(replace(replace(
                            trim(substring(1,2000,blobnortf)),char(10),""),char(13),""),char(44),"") ;.blob1 1200
 
                    blobnortf = performloc
 
 
                endif
                fndStrng = findstring("Performing location:",rs->QUAL[d.seq]->ResultCmt,0);
                if (fndStrng > 0)
                rs->QUAL[d.seq]->Perform_location = ;rs->QUAL[PATIENTS]->ResultCmt
                  substring(38 + fndStrng,57,rs->QUAL[d.seq]->ResultCmt)
                else
                rs->QUAL[d.seq]->Perform_location = org.org_name
                endif
 
 
with nocounter, time = 500
; 
;/*********************************************************************************************
;                   GETTING encounter info
;**********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
 
        ,encounter      e
        ,organization   org
        ,encntr_alias   ea
        ,encntr_alias   ea2
 
 
PLAN d
 
 
    join e WHERE e.encntr_id = outerjoin(rs->qual[d.seq].EncntrId)
    join org where org.organization_id = outerjoin(e.organization_id)
 
    join ea where ea.encntr_id = outerjoin(e.encntr_id);)
    AND EA.encntr_alias_type_cd = outerjoin(1077.00); FIN
    AND EA.active_ind = outerjoin(1)
;    ;AND EA.beg_effective_dt_tm < cnvtdatetime(curdate,curtime)
;    ;AND EA.end_effective_dt_tm > cnvtdatetime(curdate,curtime)
;
    join ea2 where ea2.encntr_id =outerjoin(e.encntr_id)
    AND EA2.encntr_alias_type_cd = outerjoin(1079.00); MRN
    AND EA2.active_ind = outerjoin(1)
 
detail
 
    rs->QUAL[d.seq]->ENCNTR_CD = E.encntr_type_cd
    rs->QUAL[d.seq]->Encntr_Type = uar_get_code_display(e.encntr_type_cd)
    rs->QUAL[d.seq]->Clinic_Name = uar_get_code_display(e.loc_facility_cd)
    rs->QUAL[d.seq]->fin = ea.alias
    rs->QUAL[d.seq]->mrn = ea2.alias
    rs->QUAL[d.seq]->e_location = org.org_name
    RS->QUAL[d.seq]->reg_dt = FORMAT(e.reg_dt_tm, "MM/DD/YYYY hh:mm:ss;;D")
    RS->QUAL[d.seq]->visit_reason = e.reason_for_visit
    RS->QUAL[d.seq]->admit_from = e.admit_src_cd
    RS->QUAL[d.seq]->disch_dt = FORMAT(e.disch_dt_tm, "MM/DD/YYYY hh:mm:ss;;D")
    RS->QUAL[d.seq]->nurse_unit = uar_get_code_display(e.loc_nurse_unit_cd)
    RS->QUAL[d.seq]->ORG_ID = e.organization_id
    rs->QUAL[d.seq]->disch_disp = uar_get_code_display(e.disch_disposition_cd)
 
    if(RS->QUAL[d.seq].admit_from in(5070292.00,    5044615.00 ,    309193.00))
    RS->QUAL[d.seq].jail = "Y"
    elseif (RS->QUAL[d.seq].admit_from in(  423346946.00));   56494552.00   Transfer from SNF??
    RS->QUAL[d.seq].ltc = "Y"
    endif
 
with nocounter, time = 200
;/********************************************************************************************
;                   GETTING DIAGNOSIS info
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
        ,diagnosis      dX
        ,nomenclature   n
 
 PLAN D1
 JOIN DX WHERE dX.encntr_id = rs->qual[d1.seq].EncntrId
                 AND DX.diagnosis_id != 0.00
                AND DX.confirmation_status_cd in( 3305.00) ;CONFIRMED, complaint of
                AND DX.classification_cd = 674232.00
                and dx.diag_type_cd = 87.00
                AND DX.active_status_cd = 188.00
                AND DX.END_EFFECTIVE_DT_TM > cnvtdatetime(curdate,curtime3)
 join n where n.nomenclature_id = DX.nomenclature_id
        AND N.active_ind = 1
        AND N.active_status_cd = 188 ; ACTIVE
;       and n.source_identifier_keycap in (
 
detail
 
    RS->QUAL[D1.SEQ].admit_dx = n.source_string
    RS->QUAL[D1.SEQ].diag_id = dx.diagnosis_id
 
with nocounter, time = 400
;/********************************************************************************************
;                   GETTING DIAGNOSIS info
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
        ,diagnosis      dX
        ,nomenclature   n
 
 PLAN D1
 JOIN DX WHERE dX.encntr_id = rs->qual[d1.seq].EncntrId
                ;AND DX.diagnosis_id != 0.00
                 and dx.diagnosis_id not in (
                 rs->qual[d1.seq].diag_id,
                 ;rs->qual[d1.seq].diag_id2,
                 ;rs->qual[d1.seq].diag_id3,
                  0.00
                 )
                AND DX.confirmation_status_cd in( 3305.00) ;CONFIRMED, complaint of
                AND DX.classification_cd = 674232.00
                and dx.diag_type_cd = 87.00
                AND DX.active_status_cd = 188.00
                AND DX.END_EFFECTIVE_DT_TM > cnvtdatetime(curdate,curtime3)
 join n where n.nomenclature_id = DX.nomenclature_id
        AND N.active_ind = 1
        AND N.active_status_cd = 188 ; ACTIVE
;       and n.source_identifier_keycap in (
 
detail
 
    RS->QUAL[D1.SEQ].admit_dx2 = n.source_string
    RS->QUAL[D1.SEQ].diag_id2 = dx.diagnosis_id
 
with nocounter, time = 400
;/********************************************************************************************
;                   GETTING DIAGNOSIS info
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
        ,diagnosis      dX
        ,nomenclature   n
 
 PLAN D1
 JOIN DX WHERE dX.encntr_id = rs->qual[d1.seq].EncntrId
                ;AND DX.diagnosis_id != 0.00
                 and dx.diagnosis_id not in (
                 rs->qual[d1.seq].diag_id,
                 rs->qual[d1.seq].diag_id2,
                 ;rs->qual[d1.seq].diag_id3,
                  0.00
                 )
                AND DX.confirmation_status_cd in( 3305.00) ;CONFIRMED, complaint of
                AND DX.classification_cd = 674232.00
                and dx.diag_type_cd = 87.00
                AND DX.active_status_cd = 188.00
                AND DX.END_EFFECTIVE_DT_TM > cnvtdatetime(curdate,curtime3)
 join n where n.nomenclature_id = DX.nomenclature_id
        AND N.active_ind = 1
        AND N.active_status_cd = 188 ; ACTIVE
;       and n.source_identifier_keycap in (
 
detail
 
    RS->QUAL[D1.SEQ].admit_dx3 = n.source_string
    RS->QUAL[D1.SEQ].diag_id3 = dx.diagnosis_id
 
with nocounter, time = 400
;/********************************************************************************************
;                   GETTING DIAGNOSIS info
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
        ,diagnosis      dX
        ,nomenclature   n
 
 PLAN D1
 JOIN DX WHERE dX.encntr_id = rs->qual[d1.seq].EncntrId
                 ;AND DX.diagnosis_id != 0.00
                 and dx.diagnosis_id not in (
                 rs->qual[d1.seq].diag_id,
                 rs->qual[d1.seq].diag_id2,
                 rs->qual[d1.seq].diag_id3, 0.00
                 )
                AND DX.confirmation_status_cd in( 3305.00) ;CONFIRMED, complaint of
                AND DX.classification_cd = 674232.00
                and dx.diag_type_cd = 87.00
                AND DX.active_status_cd = 188.00
                AND DX.END_EFFECTIVE_DT_TM > cnvtdatetime(curdate,curtime3)
 join n where n.nomenclature_id = DX.nomenclature_id
        AND N.active_ind = 1
        AND N.active_status_cd = 188 ; ACTIVE
;       and n.source_identifier_keycap in (
 
detail
 
    RS->QUAL[D1.SEQ].admit_dx4 = n.source_string
 
 
with nocounter, time = 400
;;/************************************************************************************
;;                  GETTING Chief Complaint INFO -
;;*************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
        ,clinical_event cE
        ;,SCH_APPT S
 
PLAN d
JOIN cE WHERE cE.encntr_id = RS->QUAL[D.SEQ].EncntrId
 
        and ce.event_cd IN(704668.00)  ;chief complaint
        and cE.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
        and cE.result_status_cd in (25,34,35)
 
detail
; IF(DATETIMEDIFF(rs->QUAL[D.SEQ]->appt_begin,CE.event_end_dt_tm) < 0.5 AND DATETIMEDIFF(rs->QUAL[D.SEQ]->appt_begin,CE.
; event_end_dt_tm) > (-0.5))
    ;rs->QUAL[d.seq]->event_cd = uar_get_code_display(ce.event_cd)
    rs->QUAL[d.seq]->cc_result = replace(replace(replace(
                            trim(substring(1,500,ce.result_val)),char(10),""),char(13),""),char(44),"")
    rs->QUAL[d.seq]->cc_RESULT_DT = CE.event_end_dt_tm
   ; rs->QUAL[d.seq]->DATE_DIFF = DATETIMEDIFF(rs->QUAL[D.SEQ]->appt_begin,CE.event_end_dt_tm)
; ENDIF
 
with nocounter, time = 300
;;;/*******************************************************************************************
;;;                     GETTING cmrn
;;;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
        ,person_alias pa
 
PLAN d
 
join pa where pa.person_id = rs->qual[d.seq].PersonId
    and pa.person_alias_type_cd = 2 ; CMRN
    and pa.active_ind = 1
    and pa.end_effective_dt_tm > cnvtdatetime(sysdate)
 
order by d.seq
 
detail
rs->QUAL[D.SEQ].CMRN = pa.alias

with nocounter, time = 400
;/********************************************************************************************
;                   GETTING EMERGENCY CONTACT info
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
    ,ENCNTR_PERSON_RELTN EPR
    ,person p
    ,phone ph
 
 
 plan d
 
join EPR where EPR.encntr_id = rs->qual[d.seq].EncntrId
and EPR.person_reltn_type_cd=        1152.00    ;Emergency Contact
AND EPR.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
join p
    where p.person_id = epr.related_person_id
        and p.active_ind = 1
 
join ph
    where ph.parent_entity_id = outerjoin(p.person_id)
        and ph.phone_type_cd = outerjoin(170.00);home
        and ph.active_ind = outerjoin(1)
 
detail
 
        rs->QUAL[d.seq].contactName = p.name_full_formatted
        rs->QUAL[d.seq].contactHomePhone = ph.phone_num
 
with nocounter, time = 400
 ;/********************************************************************************************
;                   GETTING onset date info
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
    ,clinical_event ce
    ,ce_date_result cdr
 
 plan d
 
join ce where ce.person_id = rs->qual[d.seq].PersonId
and ce.encntr_id = rs->qual[d.seq].ENCNTRid
and ce.event_cd in( 2273998547.00, 2273998843.00,2230980383.00,2385366457.00,2384922167.00,2384924885.00)
 
join cdr where cdr.event_id = outerjoin(ce.event_id)
 
detail
 
 if(ce.event_cd = 2273998547.00)
rs->QUAL[d.seq].onset_dt = format(cdr.result_dt_tm, "MM/DD/YYYY;;D");FORMAT(CDR.result_dt_tm, "MM/DD/YYYY;;Q");
 
;elseif(ce.event_cd = 2273998843.00 and ce.result_val != "*Asympomatic*")
;rs->QUAL[d.seq].symptoms = "Y"
;
;elseif(ce.event_cd = 2273998843.00 and ce.result_val = "*Asympomatic*")
;rs->QUAL[d.seq].symptoms = "N"
;
;elseif(ce.event_cd = 2230980383.00 and ce.result_val in ("None*"))
;rs->QUAL[d.seq].symptoms = "N"
;
;elseif(ce.event_cd = 2230980383.00 and ce.result_val not in ("None*","*Unable*"))
;rs->QUAL[d.seq].symptoms = "Y"
 
elseif(ce.event_cd = 2385366457.00 and ce.result_val in ("Yes"))
rs->QUAL[d.seq].oc_stat = "Y"
 
elseif(ce.event_cd = 2385366457.00 and ce.result_val in ("No"))
rs->QUAL[d.seq].oc_stat = "N"
 
elseif(ce.event_cd = 2385366457.00 and ce.result_val in ("Unknown"))
rs->QUAL[d.seq].oc_stat = "UNK"
 
elseif(ce.event_cd = 2384922167.00 and ce.result_val in ("Yes"))
rs->QUAL[d.seq].ltc = "Y"
 
elseif(ce.event_cd = 2384922167.00 and ce.result_val in ("No"))
rs->QUAL[d.seq].ltc= "N"
 
elseif(ce.event_cd = 2384922167.00 and ce.result_val in ("Unknown"))
rs->QUAL[d.seq].ltc = "UNK"
 
;elseif(ce.event_cd = 2384924885.00 and ce.result_val in ("Yes"))
;rs->QUAL[d.seq].preg_ind = "Y"
;
;elseif(ce.event_cd = 2384924885.00 and ce.result_val in ("No"))
;rs->QUAL[d.seq].preg_ind = "N"
;
;elseif(ce.event_cd = 2384924885.00 and ce.result_val in ("Unknown"))
;rs->QUAL[d.seq].preg_ind = "UNK"
 
endif
 
;if(rs->QUAL[d.seq].symptoms not in ("Y","N"))
;rs->QUAL[d.seq].symptoms = "UNK"
;endif
 
with nocounter, time = 200
;/********************************************************************************************
;                   GETTING onset date info
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
    ,clinical_event ce
    ,ce_date_result cdr

 plan d

join ce where ce.person_id = rs->qual[d.seq].PersonId
and ce.encntr_id = rs->qual[d.seq].ENCNTRid
and ce.event_cd =   3781639041.00;2273998547.00

join cdr where cdr.event_id = ce.event_id

detail

rs->QUAL[d.seq].onset_dt = FORMAT(CDR.result_dt_tm, "MM/DD/YYYY;;Q");cnvtdatetime(ce.result_val, "MM/DD/YYYY hh:mm:ss;;D")


with nocounter, time = 400

;/********************************************************************************************
;                   GETTING order info
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
    ,order_detail od
 
 plan d
 
join od where od.order_id = rs->qual[d.seq].OrderId
and od.oe_field_id =       12584.00
detail
 
rs->QUAL[d.seq].Specimen = OD.oe_field_display_value
 
with nocounter, time = 400
/********************************************************************************************
                    GETTING order info - onset date
*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
    ,order_detail od
 
 plan d
 
join od where od.order_id = rs->qual[d.seq].OrderId
and od.oe_field_id in(4066329299.00, 4066396285.00)
detail
 
rs->QUAL[d.seq].onset_dt = OD.oe_field_display_value
 
with nocounter, time = 400
;/*******************************************************************************************
;                   GETTING ORDERING PROVIDER info
;********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
        ,orders o
        ,order_action oa
        ,encounter e
        ;,cust_future_order_info cfoi
        ,organization org
        ,encntr_alias   ea
        ,encntr_alias   ea2
        ,prsnl pr
        ,prsnl_alias pra
;       ,perform_result      pres
;       ,result             r
;       ,accession_order_r  aor
;       ,CONTAINER C
 
 
PLAN d
 
    join o where o.order_id = rs->qual[d.seq].orderid
 
    join oa where oa.order_id = o.order_id
 
    join pr where pr.person_id = oa.order_provider_id
 
    join pra where pra.person_id = pr.person_id and pra.prsnl_alias_type_cd = 4038127.00 ;npi
 
    ;join cfoi where cfoi.order_id = o.order_id
 
    join e WHERE e.encntr_id = o.originating_encntr_id
 
    join org where org.organization_id = e.organization_id
 
    join ea where ea.encntr_id = outerjoin(e.encntr_id);)
    AND EA.encntr_alias_type_cd = outerjoin(1077.00); FIN
    AND EA.active_ind = outerjoin(1)
 
    join ea2 where ea2.encntr_id =outerjoin(e.encntr_id)
    AND EA2.encntr_alias_type_cd = outerjoin(1079.00); MRN
    AND EA2.active_ind = outerjoin(1)
 
 
order by d.seq
 
detail
 
rs->QUAL[d.seq].Order_PROVIDER = pr.name_full_formatted
rs->QUAL[d.seq].npi = pra.alias
rs->QUAL[d.seq].ORDER_NAME = O.order_mnemonic
 
with nocounter, time = 400

;;/*******************************************************************************************
;;                  GETTING pt address
;;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
        ,ADDRESS A
 
PLAN d
 
    join A WHERE A.parent_entity_id = rs->qual[d.seq].PERSONID
    and a.address_type_cd =         756.00; Home
    and a.active_ind = 1
    and a.end_effective_dt_tm > cnvtdatetime(sysdate)
 
order by d.seq
 
detail
rs->QUAL[D.SEQ].Zip = A.zipcode
rs->QUAL[D.SEQ].County = UAR_GET_CODE_DISPLAY(A.county_cd)
rs->QUAL[D.SEQ].City = A.CITY
rs->QUAL[D.SEQ].State = A.state
RS->QUAL[D.SEQ].StreetAddr = A.street_addr
RS->QUAL[D.SEQ].StreetAddr2 = A.street_addr2
 
if (RS->QUAL[D.SEQ].StreetAddr = "UNKNOWN")
rs->QUAL[D.SEQ].homeless = "Y"
ENDIF
with nocounter, time = 400
;;/********************************************************************************************
;;                  GETTING zip OF ORG
;;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
        ,ADDRESS A
        ,PHONE PH
 
PLAN d
 
    join A WHERE A.parent_entity_id = rs->qual[d.seq].org_id
    and a.address_type_cd = 754.00
    and a.active_ind = 1
    and a.end_effective_dt_tm > cnvtdatetime(sysdate)
 
    JOIN PH WHERE PH.parent_entity_id =outerjoin( A.parent_entity_id)
    AND PH.active_ind = outerjoin(1)
    and ph.beg_effective_dt_tm < outerjoin(cnvtdatetime(curdate,curtime))
    and ph.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime))
    and ph.phone_type_cd =         outerjoin(163.00)
    ;AND PH.parent_entity_name = "ORGANIZATION"
 
order by d.seq
 
detail
rs->QUAL[D.SEQ].FAC_PHONE = PH.phone_num
rs->QUAL[D.SEQ].fac_ZIP= A.zipcode
rs->QUAL[D.SEQ].fac_County = A.county
rs->QUAL[D.SEQ].fac_City = A.CITY
rs->QUAL[D.SEQ].fac_State = A.state
RS->QUAL[D.SEQ].fac_StreetAddr = A.street_addr
RS->QUAL[D.SEQ].fac_StreetAddr2 = A.street_addr2
 
with nocounter, time = 400
;;;/************************************************************************************
;;;                     GETTING Phone mod001
;;;*************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
        ,phone ph
 
PLAN d
 
    join ph where ph.parent_entity_id = rs->qual[d.seq].PersonId
    and ph.active_ind = 1
    and ph.phone_type_cd = 170.00   ;Home(       84428725.00,
    and ph.beg_effective_dt_tm < cnvtdatetime(curdate,curtime)
    and ph.end_effective_dt_tm > cnvtdatetime(curdate,curtime)
    AND PH.parent_entity_name = "PERSON"
 
detail
 
rs->QUAL[d.seq]->phone = ph.phone_num
 
with nocounter, time = 300
;;;/************************************************************************************
;;;                     GETTING email mod001
;;;*************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
 
        ,phone ph2
PLAN d
 
    join ph2 where ph2.parent_entity_id = rs->qual[d.seq].PersonId
    and ph2.active_ind = OUTERJOIN(1)
    and ph2.phone_type_cd = OUTERJOIN(170.00)   ;Home
    and ph2.beg_effective_dt_tm < OUTERJOIN(cnvtdatetime(curdate,curtime))
    and ph2.end_effective_dt_tm > OUTERJOIN(cnvtdatetime(curdate,curtime))
    AND PH2.parent_entity_name = OUTERJOIN("PERSON_PATIENT")
 
detail
 
rs->QUAL[d.seq]->email = ph2.phone_num
 
with nocounter, time = 300
;;;/************************************************************************************
;;;                     GETTING business phone 
;;;*************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
 
        ,phone ph2
PLAN d
 
    join ph2 where ph2.parent_entity_id = rs->qual[d.seq].PersonId
    and ph2.active_ind = OUTERJOIN(1)
    and ph2.phone_type_cd = OUTERJOIN(163.00)   ;business
    and ph2.beg_effective_dt_tm < OUTERJOIN(cnvtdatetime(curdate,curtime))
    and ph2.end_effective_dt_tm > OUTERJOIN(cnvtdatetime(curdate,curtime))
    AND PH2.parent_entity_name = OUTERJOIN("PERSON")
 
detail
 
rs->QUAL[d.seq]->bus_phone = ph2.phone_num
 
with nocounter, time = 300
 
;***************************************************************************
;                       Travel Internationally
;***************************************************************************
 
Select into "nl:"
 
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
    , clinical_event   c3
 
PLAN d
 
    join c3 where c3.encntr_id = rs->qual[d.seq].encntrid ;c3.parent_event_id = dfac.parent_entity_id
              and c3.event_cd in(448367533.00   ;Recent Travel Internationally
                            )
          and c3.result_val in ("Yes");, "China", "Coronavirus")
 
order by d.seq
 
detail;
 
rs->qual[d.seq].travel = "Y"
 
with nocounter, time = 400
;;/************************************************************************************
;;                  GETTING ACTION EVENT RESULT INFO
;;*************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
        , ce_event_prsnl cep
PLAN d
 
    ;join cE WHERE cE.event_id = rs->qual[d.seq].event_id
    join cep where cep.event_id = rs->qual[d.seq].event_id
    ;and (cep.action_type_cd =     OUTERJOIN(103.00) ; order
    ;or cep.action_type_cd =     OUTERJOIN(98.00)) ; correct
 
    ORDER BY CEP.action_dt_tm
 
detail
 
rs->QUAL[d.seq]->action_event = uar_get_code_display(cep.action_type_cd)
 
with nocounter, time = 300
 
 #EXITPROGRAM
/********************************************************************************************
               OUTPUT DATA TO $OUTDEV/EMAILING
*********************************************************************************************/
If($Type = 2)
;#exit_program
; if (size(rs->QUAL,5) > 0); AT LEAST ONE PATIENT FOUND ABOVE
  select into value(FILE_NAME)

      RESULT            = " "
    , SPECIMEN          = " "
    , RESULT_DATE       = " "
    , COLLECTION_DATE   = " "
    , ONSET_DATE        = " "
    , TEST_NAME         = " "
    , ORDER_NAME        = " "
    , FIRSTNAME         = " "
    , MIDDLENAME        = " "
    , LASTNAME          = " "
    , DOB               = " "
    , CMRN              = " "
    , GENDER            = " "
    , RACE              = " "
    , ETHNICITY         = " "
    , STREETADDR        = " "
    , CITY              = " "
    , STATE             = " "
    , ZIP               = " "
    , PT_PHONE          = " "
    , PT_PHONE2         = " "
    , PT_EMAIL          = " "
    , EMERGENCY_CONTACT = " "
    , EMERGENCY_PHONE   = " "
    , NURSE_UNIT        = " "
    , ADMISSION_DATE    = " "
    , DISCHARGE_DATE    = " "
    , DISCHARGE_DISP    = " "
    , DECEASED_DATE     = " "
    , TRAVEL_INTERNATIONAL  = " "
    , ORDERING_FACILITY = " "
    , ORDER_PROVIDER    = " "
    , NPI               = " "
    , DESCRIBE_SYMPTOMS = " "
    , ADMITTING_DIAGNOSIS = " "
    , ADMITTING_DIAGNOSIS_2 = " "
    , ADMITTING_DIAGNOSIS_3 = " "
    , ADMITTING_DIAGNOSIS_4 = " "
    , CHIEF_COMPLAINT = " "
    , PERFORM_LOCATION = " "
 
    FROM DUMMYT D1 ;WITH SEQ = SIZE(0))
 
    plan d1
 
;   where rs->QUAL[d1.seq].fac_State = "DC"
;   and (rs->QUAL[d1.seq].Result = "DETECTED"
;   or rs->QUAL[d1.seq].Result = "POSITIVE" )
;   and rs->QUAL[d1.seq].action_event != "Endorse"
    
 
    with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter, append
    
 SELECT INTO VALUE(FILE_NAME)
      RESULT            = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Result))
    , SPECIMEN          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
    , RESULT_DATE       = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].RESULT_DT))
    , COLLECTION_DATE   = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].CollectionDtTm))
    , ONSET_DATE        = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].onset_dt))
    , TEST_NAME         = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].EVENT))
    , ORDER_NAME        = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].ORDER_NAME))
    , FIRSTNAME         = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FirstName))
    , MIDDLENAME        = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].MIDDLEName))
    , LASTNAME          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LastName))
    , DOB               = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].DOB))
    , CMRN              = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].CMRN))
    , GENDER            = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Gender))
    , RACE              = TRIM(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Race))
    , ETHNICITY         = TRIM(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ETHNIC_CD))
    , STREETADDR        = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr))
    , CITY              = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].City))
    , STATE             = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].State))
    , ZIP               = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Zip))
    , PT_PHONE          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].PHONE))
    , PT_PHONE2         = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].BUS_PHONE))
    , PT_EMAIL          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].EMAIL))
    , EMERGENCY_CONTACT = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].contactName))
    , EMERGENCY_PHONE   = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].contactHomePhone))
    , NURSE_UNIT        = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].nurse_unit))
    , ADMISSION_DATE    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].reg_dt))
    , DISCHARGE_DATE    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].disch_dt))
    , DISCHARGE_DISP    = trim(SUBSTRING(1, 130, rs->QUAL[D1.SEQ].DISCH_DISP))
    , DECEASED_DATE     = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].DEATH_DT))
    , TRAVEL_INTERNATIONAL  = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].travel))
    , ORDERING_FACILITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
    , ORDER_PROVIDER    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Order_PROVIDER))
    , NPI               = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].npi))
    , DESCRIBE_SYMPTOMS = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].visit_reason))
    , ADMITTING_DIAGNOSIS = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx))
    , ADMITTING_DIAGNOSIS_2 = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx2))
    , ADMITTING_DIAGNOSIS_3 = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx3))
    , ADMITTING_DIAGNOSIS_4 = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx4))
    , CHIEF_COMPLAINT = trim(substring(1,430,RS->QUAL[d1.seq].cc_result))
    , PERFORM_LOCATION = trim(substring(1,130,RS->QUAL[d1.seq].Perform_Location))
 
    FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
 
 
    plan d1
 
    where rs->QUAL[d1.seq].fac_State = "DC"
    and (rs->QUAL[d1.seq].Result = "DETECTED"
    or rs->QUAL[d1.seq].Result = "POSITIVE" )
    
    ;   rs->QUAL[d1.seq].ENCNTR_CD not IN (
;                                          309309.00    ;Outpatient
;                                        ,5043178.00    ;Clinic
;                                        ,309314.00     ;Recurring Clinic
;                                        ,3012539.00    ;Outpatient Message
;                                        ,5048254.00    ;HOSPICE Outpt
;                                        ,0.0
;                                   )
    ;and rs->QUAL[d1.seq].State not in( "MD","VA" )
    ;and 
 
    order by LASTNAME,FIRSTNAME
 
    with noHeading, PCFormat('"', ',',1), format=STREAM, compress, nocounter, format, append
 
 
    select into $outdev
        msg="success"
        from dummyt
        with nocounter
 
 elseif($type = 1)
 
 if (size(rs->QUAL,5) > 0)
 
    select into $outdev
      RESULT            = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Result))
    , SPECIMEN          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
    , RESULT_DATE       = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].RESULT_DT))
    , COLLECTION_DATE   = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].CollectionDtTm))
    , ONSET_DATE        = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].onset_dt))
    , TEST_NAME         = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].EVENT))
    , ORDER_NAME        = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].ORDER_NAME))
    , FIRSTNAME         = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FirstName))
    , MIDDLENAME        = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].MIDDLEName))
    , LASTNAME          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LastName))
    , DOB               = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].DOB))
    , CMRN              = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].CMRN))
    , GENDER            = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Gender))
    , RACE              = TRIM(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Race))
    , ETHNICITY         = TRIM(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ETHNIC_CD))
    , STREETADDR        = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr))
    , CITY              = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].City))
    , STATE             = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].State))
    , ZIP               = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Zip))
    , PT_PHONE          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].PHONE))
    , PT_PHONE2         = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].BUS_PHONE))
    , PT_EMAIL          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].EMAIL))
    , EMERGENCY_CONTACT = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].contactName))
    , EMERGENCY_PHONE   = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].contactHomePhone))
    , NURSE_UNIT        = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].nurse_unit))
    , ADMISSION_DATE    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].reg_dt))
    , DISCHARGE_DATE    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].disch_dt))
    , DISCHARGE_DISP    = trim(SUBSTRING(1, 130, rs->QUAL[D1.SEQ].DISCH_DISP))
    , DECEASED_DATE     = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].DEATH_DT))
    , TRAVEL_INTERNATIONAL  = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].travel))
    , ORDERING_FACILITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
    , ORDER_PROVIDER    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Order_PROVIDER))
    , NPI               = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].npi))
    , DESCRIBE_SYMPTOMS = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].visit_reason))
    , ADMITTING_DIAGNOSIS = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx))
    , ADMITTING_DIAGNOSIS_2 = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx2))
    , ADMITTING_DIAGNOSIS_3 = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx3))
    , ADMITTING_DIAGNOSIS_4 = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx4))
    , CHIEF_COMPLAINT = trim(substring(1,430,RS->QUAL[d1.seq].cc_result))
    , PERFORM_LOCATION = trim(substring(1,130,RS->QUAL[d1.seq].Perform_Location))
 
    FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
 
 
    plan d1
 
    where rs->QUAL[d1.seq].fac_State = "DC"
    and 
    (rs->QUAL[d1.seq].Result = "DETECTED"
    or rs->QUAL[d1.seq].Result = "POSITIVE" )
    
    ;   rs->QUAL[d1.seq].ENCNTR_CD not IN (
;                                          309309.00    ;Outpatient
;                                        ,5043178.00    ;Clinic
;                                        ,309314.00     ;Recurring Clinic
;                                        ,3012539.00    ;Outpatient Message
;                                        ,5048254.00    ;HOSPICE Outpt
;                                        ,0.0
;                                   )
    ;and rs->QUAL[d1.seq].State not in( "MD","VA" )
    ;and 
 
    order by LASTNAME,FIRSTNAME
 
    with nocounter, time = 1000, format, separator = " "
 
else
 
 
    select into $OUTDEV
        from dummyt
        Detail
            row + 1
            col 001 "There were no results for your filter selections.."
            col 025
            row + 1
            col 001  "Please Try Your Search Again"
            row + 1
        with format, separator = " "
endif
 
elseif($type = 3)
if (size(rs->QUAL,5) > 0)
 ;EMAIL
 select into value(FILENAME)

      RESULT            = " "
    , SPECIMEN          = " "
    , RESULT_DATE       = " "
    , COLLECTION_DATE   = " "
    , ONSET_DATE        = " "
    , TEST_NAME         = " "
    , ORDER_NAME        = " "
    , FIRSTNAME         = " "
    , MIDDLENAME        = " "
    , LASTNAME          = " "
    , DOB               = " "
    , CMRN              = " "
    , GENDER            = " "
    , RACE              = " "
    , ETHNICITY         = " "
    , STREETADDR        = " "
    , CITY              = " "
    , STATE             = " "
    , ZIP               = " "
    , PT_PHONE          = " "
    , PT_PHONE2         = " "
    , PT_EMAIL          = " "
    , EMERGENCY_CONTACT = " "
    , EMERGENCY_PHONE   = " "
    , NURSE_UNIT        = " "
    , ADMISSION_DATE    = " "
    , DISCHARGE_DATE    = " "
    , DISCHARGE_DISP    = " "
    , DECEASED_DATE     = " "
    , TRAVEL_INTERNATIONAL  = " "
    , ORDERING_FACILITY = " "
    , ORDER_PROVIDER    = " "
    , NPI               = " "
    , DESCRIBE_SYMPTOMS = " "
    , ADMITTING_DIAGNOSIS = " "
    , ADMITTING_DIAGNOSIS_2 = " "
    , ADMITTING_DIAGNOSIS_3 = " "
    , ADMITTING_DIAGNOSIS_4 = " "
    , CHIEF_COMPLAINT = " "
    , PERFORM_LOCATION = " "
 
    FROM DUMMYT D1 ;WITH SEQ = SIZE(0))
 
    plan d1
 
;   where rs->QUAL[d1.seq].fac_State = "DC"
;   and (rs->QUAL[d1.seq].Result = "DETECTED"
;   or rs->QUAL[d1.seq].Result = "POSITIVE" )
    
 
    with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter, append
    
select into value(FILENAME)

      RESULT            = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Result))
    , SPECIMEN          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
    , RESULT_DATE       = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].RESULT_DT))
    , COLLECTION_DATE   = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].CollectionDtTm))
    , ONSET_DATE        = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].onset_dt))
    , TEST_NAME         = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].EVENT))
    , ORDER_NAME        = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].ORDER_NAME))
    , FIRSTNAME         = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FirstName))
    , MIDDLENAME        = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].MIDDLEName))
    , LASTNAME          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LastName))
    , DOB               = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].DOB))
    , CMRN              = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].CMRN))
    , GENDER            = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Gender))
    , RACE              = TRIM(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Race))
    , ETHNICITY         = TRIM(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ETHNIC_CD))
    , STREETADDR        = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr))
    , CITY              = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].City))
    , STATE             = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].State))
    , ZIP               = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Zip))
    , PT_PHONE          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].PHONE))
    , PT_PHONE2         = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].BUS_PHONE))
    , PT_EMAIL          = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].EMAIL))
    , EMERGENCY_CONTACT = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].contactName))
    , EMERGENCY_PHONE   = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].contactHomePhone))
    , NURSE_UNIT        = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].nurse_unit))
    , ADMISSION_DATE    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].reg_dt))
    , DISCHARGE_DATE    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].disch_dt))
    , DISCHARGE_DISP    = trim(SUBSTRING(1, 130, rs->QUAL[D1.SEQ].DISCH_DISP))
    , DECEASED_DATE     = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].DEATH_DT))
    , TRAVEL_INTERNATIONAL  = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].travel))
    , ORDERING_FACILITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
    , ORDER_PROVIDER    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Order_PROVIDER))
    , NPI               = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].npi))
    , DESCRIBE_SYMPTOMS = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].visit_reason))
    , ADMITTING_DIAGNOSIS = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx))
    , ADMITTING_DIAGNOSIS_2 = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx2))
    , ADMITTING_DIAGNOSIS_3 = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx3))
    , ADMITTING_DIAGNOSIS_4 = trim(substring(1,130,RS->QUAL[d1.seq].admit_dx4))
    , CHIEF_COMPLAINT = trim(substring(1,430,RS->QUAL[d1.seq].cc_result))
    , PERFORM_LOCATION = trim(substring(1,130,RS->QUAL[d1.seq].Perform_Location))
 
    FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
 
    plan d1
 
    where rs->QUAL[d1.seq].fac_State = "DC"
    and (rs->QUAL[d1.seq].Result = "DETECTED"
    or rs->QUAL[d1.seq].Result = "POSITIVE" )
    
 
    with noHeading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter, append
 
 
    ;***********EMAIL THE ACTUAL ZIPPED FILE**************************** ;MOD004
        if(CURDOMAIN = PRODUCTION_DOMAIN);ONLY EMAIL OUT OF P41
;;          SET  AIX_COMMAND  =  Build2 ('zip ', filename_zip, ' ', filename)
;;          SET  AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
;;          SET  AIX_CMDSTATUS = 0
;;          CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
            SET  AIX_COMMAND  =
                build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
                       " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS)
 
            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
            call pause(2);LETS SLOW THINGS DOWN
 
            SET  AIX_COMMAND  =
                CONCAT ('rm -f ' , FILENAME,  ' | rm -f ' , EMAIL_BODY)
 
            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
        endif
        
    else
 
        select into value(FILENAME)
 
        Report_value        = "No data found"
 
        from (dummyt d1 with seq = size(1))
        
        WITH HEADING,PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter ;, compress
 
        set EMAIL_SUBJECT = "The MedStar DC DOH Monkeypox Positive Result Report -No accounts found"
 
 
    ;***********EMAIL THE ACTUAL ZIPPED FILE**************************** ;MOD004
        if(CURDOMAIN = PRODUCTION_DOMAIN);ONLY EMAIL OUT OF P41
;;          SET  AIX_COMMAND  =  Build2 ('zip ', filename_zip, ' ', filename)
;;          SET  AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
;;          SET  AIX_CMDSTATUS = 0
;;          CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
            SET  AIX_COMMAND  =
                build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
                       " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS)
 
            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
            call pause(2);LETS SLOW THINGS DOWN
 
            SET  AIX_COMMAND  =
                CONCAT ('rm -f ' , FILENAME,  ' | rm -f ' , EMAIL_BODY)
 
            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
        endif
    endif
 
endif


call echorecord(rs)


end
go
 
 