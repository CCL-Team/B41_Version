/*********************************************************************************************************************************
 Program Title:		3_mp_results_report_wrapper.prg
 Create Date:		06/08/2024
 Object name:		3_mp_results_report_wrapper
 Source file:		3_mp_results_report_wrapper.prg
 MCGA:
 OPAS:
 Purpose: 			Wraps the scripts to find results for the mpox result scripts.
 Executed from:		Explorer Menu
 Special Notes:
 
**********************************************************************************************************************************
**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
Mod    Date             Analyst                 OPAS          			Comment
---    ----------       --------------------    ------        		--------------------------------------------
001    06/08/2024       Michael Mayes           239759              Creating report to find the mPox results.
*************END OF ALL MODCONTROL BLOCKS* ***************************************************************************************/
 
  drop program 3_mp_results_report_wrapper go
create program 3_mp_results_report_wrapper
 
prompt
	  "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Result Start Date"           = "SYSDATE"
    , "Result End Date"             = "SYSDATE"
    , "State"                       = ''
 
with outdev, start_dt, end_dt, state_flag

free record temprs
record temprs
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



 
;=====================================================================
; VARIABLE DECLARATIONS
;=====================================================================
declare start_dt_tm			= dq8 with noconstant
declare end_dt_tm			= dq8 with noconstant
declare start_dt_tm_vc		= vc with noconstant
declare end_dt_tm_vc		= vc with noconstant
 
set start_dt_tm = cnvtdatetime($start_dt)
set end_dt_tm =   cnvtdatetime($end_dt)
 
 
set start_dt_tm_vc = trim(format(start_dt_tm, "DD-MMM-YYYY hh:mm:ss;;Q"))
set end_dt_tm_vc   = trim(format(end_dt_tm,  "DD-MMM-YYYY hh:mm:ss;;Q"))
 
;=====================================================================
; BEGIN THE STRING OF EXECUTIONS
;=====================================================================
if($state_flag = 'MD') execute 3_mp_results_md_ip "MINE", start_dt_tm_vc, end_dt_tm_vc, 1 with replace(rs, temprs)
else                   execute 3_mp_results_dc_ip "MINE", start_dt_tm_vc, end_dt_tm_vc, 1 with replace(rs, temprs)
endif


call echorecord(temprs)


if (size(temprs->QUAL,5) > 0)

    select into $outdev
                RESULT                = trim(substring(1, 100,  temprs->qual[d1.seq].result          ))
              , SPECIMEN              = trim(substring(1,  30,  temprs->qual[d1.seq].specimen        ))
              , RESULT_DATE           = trim(substring(1,  30,  temprs->qual[d1.seq].result_dt       ))
              , COLLECTION_DATE       = trim(substring(1,  50,  temprs->qual[d1.seq].collectiondttm  ))
              , ONSET_DATE            = trim(substring(1,  50,  temprs->qual[d1.seq].onset_dt        ))
              , TEST_NAME             = trim(substring(1,  40,  temprs->qual[d1.seq].event           ))
              , ORDER_NAME            = trim(substring(1,  40,  temprs->qual[d1.seq].order_name      ))
              , FIRSTNAME             = trim(substring(1,  30,  temprs->qual[d1.seq].firstname       ))
              , MIDDLENAME            = trim(substring(1,  30,  temprs->qual[d1.seq].middlename      ))
              , LASTNAME              = trim(substring(1,  30,  temprs->qual[d1.seq].lastname        ))
              , DOB                   = trim(substring(1,  20,  temprs->qual[d1.seq].dob             ))
              , CMRN                  = trim(substring(1,  30,  temprs->qual[d1.seq].cmrn            ))
              , GENDER                = trim(substring(1,  30,  temprs->qual[d1.seq].gender          ))
              , RACE                  = trim(substring(1,  30,  temprs->qual[d1.seq].race            ))
              , ETHNICITY             = trim(substring(1,  30,  temprs->qual[d1.seq].ethnic_cd       ))
              , STREETADDR            = trim(substring(1,  30,  temprs->qual[d1.seq].streetaddr      ))
              , CITY                  = trim(substring(1,  30,  temprs->qual[d1.seq].city            ))
              , STATE                 = trim(substring(1,  30,  temprs->qual[d1.seq].state           ))
              , ZIP                   = trim(substring(1,  30,  temprs->qual[d1.seq].zip             ))
              , PT_PHONE              = trim(substring(1,  30,  temprs->qual[d1.seq].phone           ))
              , PT_PHONE2             = trim(substring(1,  30,  temprs->qual[d1.seq].bus_phone       ))
              , PT_EMAIL              = trim(substring(1,  30,  temprs->qual[d1.seq].email           ))
              , EMERGENCY_CONTACT     = trim(substring(1,  30,  temprs->qual[d1.seq].contactname     ))
              , EMERGENCY_PHONE       = trim(substring(1,  30,  temprs->qual[d1.seq].contacthomephone))
              , NURSE_UNIT            = trim(substring(1,  30,  temprs->qual[d1.seq].nurse_unit      ))
              , ADMISSION_DATE        = trim(substring(1,  30,  temprs->qual[d1.seq].reg_dt          ))
              , DISCHARGE_DATE        = trim(substring(1,  30,  temprs->qual[d1.seq].disch_dt        ))
              , DISCHARGE_DISP        = trim(substring(1, 130,  temprs->qual[d1.seq].disch_disp      ))
              , DECEASED_DATE         = trim(substring(1,  30,  temprs->qual[d1.seq].death_dt        ))
              , TRAVEL_INTERNATIONAL  = trim(substring(1,  30,  temprs->qual[d1.seq].travel          ))
              , ORDERING_FACILITY     = trim(substring(1, 100,  temprs->qual[d1.seq].clinic_name     ))
              , ORDER_PROVIDER        = trim(substring(1,  30,  temprs->qual[d1.seq].order_provider  ))
              , NPI                   = trim(substring(1,  30,  temprs->qual[d1.seq].npi             ))
              , DESCRIBE_SYMPTOMS     = trim(substring(1, 100,  temprs->qual[d1.seq].visit_reason    ))
              , ADMITTING_DIAGNOSIS   = trim(substring(1, 130,  temprs->qual[d1.seq].admit_dx        ))
              , ADMITTING_DIAGNOSIS_2 = trim(substring(1, 130,  temprs->qual[d1.seq].admit_dx2       ))
              , ADMITTING_DIAGNOSIS_3 = trim(substring(1, 130,  temprs->qual[d1.seq].admit_dx3       ))
              , ADMITTING_DIAGNOSIS_4 = trim(substring(1, 130,  temprs->qual[d1.seq].admit_dx4       ))
              , CHIEF_COMPLAINT       = trim(substring(1, 430,  temprs->qual[d1.seq].cc_result       ))
      
      FROM (DUMMYT D1 WITH SEQ = SIZE(temprs->QUAL,5))
    plan d1
     where temprs->QUAL[d1.seq].fac_State = $state_flag
       and (   temprs->QUAL[d1.seq].Result = "DETECTED"
            or temprs->QUAL[d1.seq].Result = "POSITIVE" )
     
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

 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
end
go
 