/***********************************************************************************************************
 Program Title:		doh_covid19_results_va_poc.prg
 Create Date:		03/11/2020
 Object name:		doh_covid19_results_va_poc
 Source file:		doh_covid19_results_va_poc.prg
 MCGA:
 OPAS:
 Purpose:https:
 Executed from:		Explorer Menu
 Special Notes:
 
*************************************************************************************************************
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^IMPORTANT^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*************************************************************************************************************
 Clone from jwd_PALLIATIVE_CARE_METRICS.prg
 
 VA DOH COVID 19 RESULTS FOR POC ORDERS
 
 This report looks for DTAs:
 
 2276648185 ; NEW POC ORDER
 
 by RESULT date on the prompt.
 
 This report is only looking for VA residents seen at a VA Medstar location.
 
Disclaimers:
Multiple rows/orders per patient as multiple orders for labs are placed on each encounter - rare but will
																					likely continue to grow
Unsolicited results - results not linked to their Lab orders will be missing information in the row
Result values continue to expand beyond positive/negative - especially from different labs
Results for Patients without Lab orders
 
**************************************************************************************************************
**************************************************************************************************************
**************************************************************************************************************
**************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**************************************************************************************************************
Mod    Date             Analyst                 SOM/MCGA          			Comment
---    ----------       --------------------    ------        		------------------------------------------
N/A    03/11/2020		Jeremy Daniel         	N/A	          		Initial Release
001	   09/28/2020		jwd107					222812				Add HHS/AOE questions
002	   10/21/2021		jwd107					230184				remove Invalid POC results
003	   09/08/2022		jwd107					??????				remove pt state of VA filter logic
004	   02/02/2024		glp110					344896				add new Result  POC Rapid COVID-19 PCR  
005    10/24/2024       Michael Mayes           239760              Adding new clinic
*************END OF ALL MODCONTROL BLOCKS* *******************************************************************/
drop program doh_covid19_results_va_poc go
create program doh_covid19_results_va_poc
 
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
declare ptcnt = i4
declare subroutine_get_blob(f8) = vc
 
DECLARE fileName = vc
 
DECLARE dataDate = vc
 
SET dataDate = TRIM(FORMAT(CNVTDATETIME(curdate,curtime3),"mmddyyyyhhmm;;d"),3)
 
SET FILE_NAME =  concat("/cerner/d_p41/cust_output_2/doh_covid_results/medstar_va_",format(cnvtdatetime(curdate,curtime3),"YYYYMMDDhhmmss;;Q"), ".txt")
	;build2("medstar_va_test", dataDate,".csv")
 
 
set start_dt_tm = cnvtdatetime((curdate-1), 000000)
set end_dt_tm =   cnvtdatetime((curdate-1), 235959)
 
;****************************************************************************************************
;                            	VARIABLE DECLARATIONS / EMAIL DEFINITIONS
;****************************************************************************************************
IF($TYPE = 3);EMAILING OF REPORT
	DECLARE EMAIL_SUBJECT = VC WITH NOCONSTANT(" ")
	SET EMAIL_SUBJECT = build2("[ENCRYPT]MedStar VA ELR POC Report")
	DECLARE EMAIL_ADDRESSES = VC WITH NOCONSTANT("")
	DECLARE EMAIL_BODY = VC WITH NOCONSTANT("")
	DECLARE UNICODE = VC WITH NOCONSTANT("")
	DECLARE AIX_COMMAND	  = VC WITH NOCONSTANT("")
	DECLARE AIX_CMDLEN	  = I4 WITH NOCONSTANT(0)
	DECLARE AIX_CMDSTATUS = I4 WITH NOCONSTANT(0)
	DECLARE PRODUCTION_DOMAIN = vc with constant("P41");FOR TESTING ONLY
 
	Declare EMAIL_ADDRESS 	= vc
	SET EMAIL_ADDRESS = $OUTDEV
 
	SET EMAIL_BODY = concat("medstar_vaelr_poc_",
	format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"), ".dat")
 
	DECLARE FILENAME = VC
			WITH  NOCONSTANT(CONCAT("medstar_vaelr_poc_",
								  format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q"),
								  trim(substring(3,3,cnvtstring(RAND(0)))),	;<<<< 3 random #s
								  ".csv"))
 
	IF ($TYPE = 3 and CURDOMAIN = PRODUCTION_DOMAIN)
		Select into (value(EMAIL_BODY))
	build2("The MedStar VA ELR POC report is attached to this email.",
	 char(13), char(10), char(13), char(10),
	"Date Range: ", $START_DT , " to ", $END_DT , char(13), char(10),
	 char(13), char(10),
	"Run date and time: ",format(cnvtdatetime(curdate, curtime3),
	"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13),char(10))
 
		from dummyt
		with format, noheading
	endif
endif
 
 
;*****************************************************************************************************
;                           Set Print Record Structure
;*****************************************************************************************************
 
free record rs
record rs
(	1 PRINTCNT = i4
	1 Qual[*]
		2 HeaderCol	= vc
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
		2 MiddleName = vc
		2 MRN = vc
		2 FIN = vc
		2 SSN = vc
		2 DOB = vc
		2 age = i4
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
		2 specimenp = vc
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
		2 result_status = vc
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
 		2 reg_dt = dq8
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
	 	2 event_id = f8
	 	2 int_result = vc
	 	2 SYSTEM_DATE = DQ8
	 	2 PROVIDER_FNAME = VC
	 	2 PROVIDER_LNAME = VC
	    2 perform_addr = vc
		2 perform_addr2 = vc
		2 perform_city = vc
		2 perform_state = vc
		2 perform_zip = vc
		2 perform_county = vc
		2 TEST_RESULT_STATUS = vc
		2 symptoms = vc
		2 preg_ind = vc
		2 FIRST_TEST = vc
		2 occupation = vc
		2 order_dttm = dq8
		2 age_unit = vc
		2 result_ns = vc
		2 result_sc = vc
		2 CHRONIC_KID = VC
		2 IMMUNO_DISEASE = VC
 	 	2 CARDIO_DISEASE = VC
 	 	2 bmi = vc
 	 	2 EAU_TEST_KIT = vc
 	 	2 Specimen_type = vc
 	 	2 Specimen_ns = vc
 	 	2 org_id_2 = f8
)
 
;*****************************************************************************************************
;                            	main select
;*****************************************************************************************************
 
select into "nl:"
 
from
 
Person p
, encounter e
, clinical_event c3
, organization org
, organization_alias orga
, PERSON_ALIAS PA
, phone ph
, code_value_outbound cvo
 
 
plan c3 where c3.event_cd in (
 
;				2258265897	;CoVID19-SARS-CoV-2 by PCR
;				,2254653289	;COVID 19 (DH/CDC)
;				,2259614555	;COVID-19/Coronavirus RNA PCR
;				,2258239523	;COVID-19 (SARS-CoV-2, NAA)
;				,2265151661	;CoVID_19 (SARS-CoV2, NAA)
;				,2258239523	;COVID-19 (SARS-CoV-2, NAA)
;				,2270692929	;CoVID 19-SARS-CoV-2 Overall Result
;				,2258265897	;CoVID 19-SARS-CoV-2 by PCR
;				,2270688963	;CoVID 19-PAN-SARS-CoV-2 by PCR
;				,2259601949	;COVID19(SARS-CoV-2)
				2276648185 ; NEW POC ORDER
				,2404008691 ;POC Ag
				,5015944927.00	;POC Rapid COVID-19 PCR
;				,2291914727
;				,2291907909
;					,2282064783
;					,2287776717
;					,2290710033
;					,2290710049
;					,2290713753
;					,2290713803
;					,2290718387
	)
 
	;between cnvtdatetime($start_dt)and cnvtdatetime($end_dt)
	;AND C3.normalcy_cd = 201.00
	;and c3.result_val != "Invalid"
	and c3.event_end_dt_tm > cnvtlookbehind("14,D")
	and c3.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
 	and c3.event_class_cd = 236.00
 	and c3.valid_from_dt_tm between CNVTDATETIME($START_DT)AND CNVTDATETIME($END_DT)
 	;and c3.valid_from_dt_tm between cnvtdatetime((curdate-1), 000000)and cnvtdatetime((curdate-1), 235959)
  	and c3.result_status_cd in (25,34,35)
 	and c3.authentic_flag = 1
 
 
join cvo where cvo.code_value = outerjoin(c3.event_cd) and cvo.contributor_source_cd = outerjoin(56496061.00)	;LOINC
 
join e where e.encntr_id = outerjoin(c3.encntr_id)
 
join org where org.organization_id = e.organization_id 
           and org.organization_id in (6114269.00,6276591,18933272.00)   ;005
 
 
join orga where orga.organization_id = outerjoin(org.organization_id) and orga.org_alias_type_cd = outerjoin(653405.00);	CLIA
 
join p where p.person_id = OUTERJOIN(c3.person_id)
									AND P.NAME_LAST_KEY != outerjoin("ZZ*")
	                                AND P.NAME_LAST_KEY != outerjoin("CAREMOBILE")
	                                AND P.NAME_LAST_KEY != outerjoin("REGRESSION")
	                                AND P.NAME_LAST_KEY != outerjoin("TEST")
	                                AND P.NAME_LAST_KEY != outerjoin("CERNERTEST")
	                                AND P.NAME_LAST_KEY != outerjoin("*PATIENT*")
	                                AND not OPERATOR(P.NAME_LAST_KEY,"REGEXPLIKE","[0-9]")
	                                and p.active_ind = outerjoin(1)
	                                and p.end_effective_dt_tm > outerjoin(cnvtdatetime(sysdate))
 
join pa where pa.person_id = OUTERJOIN(p.person_id) and pa.person_alias_type_cd = OUTERJOIN(2) ; CMRN
		and pa.active_ind = outerjoin(1)
 
		and pa.end_effective_dt_tm > outerjoin(cnvtdatetime(sysdate))
join ph where ph.parent_entity_id = outerjoin(p.person_id)
		and ph.active_ind = outerjoin(1)
		and ph.phone_type_cd = outerjoin(170)	;Home
		and ph.beg_effective_dt_tm < outerjoin(cnvtdatetime(curdate,curtime))
		and ph.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime))
		AND PH.parent_entity_name = outerjoin("PERSON")
 
 
order by C3.clinical_event_id
 
 
 
head report
	patients = 0
 
head C3.clinical_event_id
 
 
patients = patients + 1
STAT=ALTERLIST(RS->QUAL,PATIENTS)
 
    rs->QUAL[patients]->FirstName = p.name_first
    rs->QUAL[patients]->middlename = p.name_middle
    rs->QUAL[patients]->LastName = p.name_last
    ;rs->QUAL[patients]->AGE = datetimediff(e.reg_dt_tm, p.birth_dt_tm)/365
    rs->QUAL[patients]->DOB = format(p.birth_dt_tm, "yyyymmdd;;D")
    rs->QUAL[patients]->Gender = uar_get_code_display(p.sex_cd)
    rs->QUAL[patients]->Race = uar_get_code_display(p.race_cd)
    rs->QUAL[patients]->PersonId = c3.person_id
    rs->QUAL[patients]->EncntrId = c3.encntr_id
    rs->QUAL[patients]->OrderId = c3.order_id
    rs->QUAL[patients]->clinical_evt_id = c3.clinical_event_id
    rs->QUAL[patients]->ethnic_cd = UAR_GET_CODE_DISPLAY(P.ethnic_grp_cd)
    rs->QUAL[patients]->CMRN = PA.alias
 	rs->QUAL[patients]->ORG_ID = E.organization_id
 	rs->QUAL[patients]->dta = c3.task_assay_cd
 	rs->QUAL[patients]->ACCESSION = C3.accession_nbr
 	rs->QUAL[patients]->pt_phone = REPLACE(replace(replace(
							trim(substring(1,15,ph.phone_num)),char(40),""),char(41),""),char(45),"") ;ph.phone_num
 	rs->QUAL[patients]->loinc = cvo.alias
  	rs->QUAL[patients]->service_resource = uar_get_code_display(c3.resource_cd)
  	rs->QUAL[patients]->event_id = c3.event_id
  	rs->QUAL[patients]->OrderingCLIA = orga.alias
  	rs->QUAL[patients]->SYSTEM_DATE = SYSDATE
  	;RS->QUAL[patients]->symptoms = "Unknown"
 	;RS->QUAL[patients]->preg_ind = "Unknown"
 	;RS->QUAL[patients]->oc_stat = "Unknown"
 
 
 
  	 	if (rs->QUAL[patients]->ORG_ID in (
									  12920488 ;OCC Health locations
									,12917535
									,12931572
									,12917543
									,12917576
									,12920513
									,12917632
									,12919164
									,12919157
									,12917568
									,12897236
									))
		rs->QUAL[patients]->oc_stat = "Yes"
		endif
 
		if(rs->QUAL[patients]->ethnic_cd in (
		"Central American"
		,"Cuban"
		,"Dominican"
		,"Latin American"
		,"Mexican"
		,"Puerto Rican"
		,"South American"
		,"Spaniard"
		,"Hispanic"))
		rs->QUAL[patients]->ethnic_cd = "Hispanic or Latino"
		elseif(rs->QUAL[patients]->ethnic_cd = "Non-Hispanic")
		rs->QUAL[patients]->ethnic_cd = "Not Hispanic or Latino"
		elseif(rs->QUAL[patients]->ethnic_cd ="multiple")
		rs->QUAL[patients]->ethnic_cd = " "
		endif
 
		if(rs->QUAL[patients]->Race = "*ZZZ*")
		rs->QUAL[patients]->Race = " "
		elseif(rs->QUAL[patients]->Race = "*American Indian*")
		rs->QUAL[patients]->Race = "American Indian or Alaska Native"
		elseif(rs->QUAL[patients]->Race = "*African American*")
		rs->QUAL[patients]->Race = "Black or African American"
		elseif(rs->QUAL[patients]->Race = "*Native Hawaiian*")
		rs->QUAL[patients]->Race = "Native Hawaiian or Other Pacific Islander"
		elseif(rs->QUAL[patients]->Race = "Other")
		rs->QUAL[patients]->Race = "Other Race"
		endif
 
		if(c3.event_cd = 2276648185)
		rs->QUAL[patients]->Specimen = "NP Swab"
		rs->QUAL[patients]->Specimen_type = "258500001"
		rs->QUAL[patients]->Specimen_ns = "SCT"
		rs->QUAL[patients]->service_resource = "POC Abbot ID NOW_Abbott_DIT"
		rs->qual[patients].ACCESSION = cnvtstring(c3.order_id)
		rs->qual[patients].result_status = "F"
 		rs->qual[patients].TEST_RESULT_STATUS = "F"
		;rs->QUAL[patients]->o_loinc = "94534-5"
		rs->QUAL[patients]->EAU_TEST_KIT = "ID NOW COVID-19_Abbott Diagnostics Scarborough, Inc._EUA"
		endif
 
   		if(c3.event_cd = 2404008691)
		rs->QUAL[patients]->Specimen = "Mid-Turbinate(upper nasal)"
		rs->QUAL[patients]->Specimen_type = "445297001"
		rs->QUAL[patients]->Specimen_ns = "SCT"
		rs->QUAL[patients]->service_resource = "BD Veritor Plus"
		rs->qual[patients].ACCESSION = cnvtstring(c3.order_id)
		rs->QUAL[patients]->EAU_TEST_KIT = "BD Veritor System for Rapid Detection of SARS-CoV-2_Becton, Dickinson and Company_EUA"
		rs->qual[patients].result_status = "F"
 		rs->qual[patients].TEST_RESULT_STATUS = "F"
		;rs->QUAL[patients]->o_loinc = "94558-4"
		;rs->QUAL[patients]->loinc = "94558-4"
		endif
		if( c3.event_cd = 5015944927.00);POC Rapid COVID-19 PCR
 			rs->qual[patients].ACCESSION = cnvtstring(c3.order_id)
 			rs->QUAL[patients].Specimen = "Mid-Turbinate(upper nasal)"
 			rs->qual[patients].result_status = "F"
 			rs->qual[patients].TEST_RESULT_STATUS = "F"
 			rs->QUAL[patients]->Specimen_type = "445297001"
			rs->QUAL[patients]->Specimen_ns = "SCT"
		endif
 
with nocounter, time = 1700;, ORAHINTCBO("INDEX( E XIE17ENCOUNTER)")
 
if(size(rs->qual,5) > 0)
/****************************************************************************************************
 				;results
*****************************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
	, CLINICAL_EVENT C
	, result r
	, encounter e
	, organization org
	, long_blob lb
	, ce_event_note cen
	, order_comment ocm
	, long_text lt
	, orders o
	, organization_alias orga
	, address a
 
PLAN d
JOIN c where c.clinical_event_id = rs->qual[d.seq].clinical_evt_id
 
and c.event_cd in (
;				;	2258261423	;CoVID19-SARS-CoV-2 Source
;				2258265897	;CoVID19-SARS-CoV-2 by PCR
;				,2254653289	;COVID 19 (DH/CDC)
;				,2259614555	;COVID-19/Coronavirus RNA PCR
;				,2258239523	;COVID-19 (SARS-CoV-2, NAA)
;				,2265151661	;CoVID_19 (SARS-CoV2, NAA)
;				,2258239523	;COVID-19 (SARS-CoV-2, NAA)
;				,2270692929	;CoVID 19-SARS-CoV-2 Overall Result
;				,2258265897	;CoVID 19-SARS-CoV-2 by PCR
;				,2270688963	;CoVID 19-PAN-SARS-CoV-2 by PCR
				2276648185 ;NEW POC ORDER
				,2404008691 ;POC Ag
				,5015944927.00	;POC Rapid COVID-19 PCR
;				,2291914727
;				,2291907909
;					,2282064783
;					,2287776717
;					,2290710033
;					,2290710049
;					,2290713753
;					,2290713803
;					,2290718387
	)
join r where r.person_id = outerjoin(c.person_id) and r.event_id = outerjoin(c.event_id)
 
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
 
join orga where orga.organization_id = outerjoin(org.organization_id) and orga.org_alias_type_cd = outerjoin(653405.00);	CLIA
 
join a where a.parent_entity_id = outerjoin(org.organization_id)
	and a.active_ind = outerjoin(1)
	and a.end_effective_dt_tm > outerjoin(cnvtdatetime(sysdate))
 	and a.address_type_cd = 754.00
 
order by d.seq
 
head d.seq
 
    rs->QUAL[d.seq]->PerformDtTm = format(c.performed_dt_tm, "MM/DD/YYYY hh:mm:ss;;D")
    rs->QUAL[d.seq]->SpecimenP = uar_get_code_display(c.event_cd)
    rs->QUAL[d.seq]->event = uar_get_code_display(c.event_cd)
    rs->QUAL[d.seq]->CollectionDtTm = format(c.event_end_dt_tm, "YYYYMMDDhhssmm;;D")
    rs->QUAL[d.seq]->Result = c.result_val;uar_get_code_description(mrr.response_cd)
    rs->QUAL[d.seq].ResultUnit = uar_get_code_display(c.result_units_cd)
    rs->QUAL[d.seq].RESULT_DT = format(C.valid_from_dt_tm, "YYYYMMDDhhssmm;;D")
 	rs->QUAL[d.seq]->Result_ns = "SCT"
 	;rs->QUAL[d.seq].result_status = uar_get_code_display(c.result_status_cd)
 	rs->QUAL[d.seq].org_id_2 = org.organization_id
 
 	if(c.event_cd = 2404008691)
 	rs->QUAL[d.seq]->event = "SARS-CoV-2 Ag Resp QI IA.rapid"
 	elseif(c.event_cd = 2276648185)
 	rs->QUAL[d.seq]->event = "SARS-CoV-2 RdRp Resp Ql NAA+probe"
 	endif
 
 	if(rs->QUAL[d.seq]->Result = "Positive")
 	rs->QUAL[d.seq]->Result = "Detected"
 	rs->QUAL[d.seq]->Result_sc = "260373001"
 	endif
 	if(rs->QUAL[d.seq]->Result = "Negative")
 	rs->QUAL[d.seq]->Result = "Not detected"
 	rs->QUAL[d.seq]->Result_sc = "260415000"
 	endif
 	if(rs->QUAL[d.seq]->Result = "Invalid")
 	rs->QUAL[d.seq]->Result = "Invalid result"
 	rs->QUAL[d.seq]->Result_sc = "455371000124106"
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
 
					rs->QUAL[d.seq].ResultCmt = replace(replace(
							trim(substring(1,1200,blobnortf)),char(10),""),char(13),"") ;.blob1
 
					blobnortf = performloc
 
 
				endif
				fndStrng = findstring("Performing location:",rs->QUAL[d.seq]->ResultCmt,0);
				if (fndStrng > 0)
				rs->QUAL[d.seq]->Perform_location = ;rs->QUAL[PATIENTS]->ResultCmt
			      substring(39 + fndStrng,57,rs->QUAL[d.seq]->ResultCmt)
			    else
			    rs->QUAL[d.seq]->Perform_location = org.org_name
			    rs->QUAL[d.seq]->perform_addr = a.street_addr
			    rs->QUAL[d.seq]->perform_addr2 = a.street_addr2
			    rs->QUAL[d.seq]->perform_city = a.city
			    rs->QUAL[d.seq]->perform_state = a.state
			    rs->QUAL[d.seq]->perform_zip = a.zipcode
			    rs->QUAL[d.seq]->perform_county = uar_get_code_display(A.county_cd)
			    endif
 
		if (rs->QUAL[d.seq]->Perform_location != "*Perform*")
		rs->QUAL[d.seq]->PerformingCLIA = orga.alias
		endif
 
;			if(c.event_cd = 2276648185)
; 			rs->qual[d.seq].ACCESSION = cnvtstring(c.order_id)
; 			rs->qual[d.seq].Specimen = "NP Swab"
; 			rs->qual[d.seq].result_status = "F"
; 			rs->qual[d.seq].TEST_RESULT_STATUS = "F"
; 			endif
 
	if (rs->QUAL[d.seq]->org_id_2 = 628085)
	;rs->QUAL[d.seq]->FAC_PHONE = "2024443597"
 	rs->QUAL[d.seq]->PerformingCLIA  = "09D0207566"
 	elseif(rs->QUAL[d.seq]->org_id_2 = 628088)
	rs->QUAL[d.seq]->PerformingCLIA   = "09D0208070"
	elseif(rs->QUAL[d.seq]->org_id_2 = 627889)
	rs->QUAL[d.seq]->PerformingCLIA   = "21D0219647"
	elseif(rs->QUAL[d.seq]->org_id_2 = 589723)
	rs->QUAL[d.seq]->PerformingCLIA   = "21D0219549"
	elseif(rs->QUAL[d.seq]->org_id_2 = 628009)
	rs->QUAL[d.seq]->PerformingCLIA   = "21D0219268"
	elseif(rs->QUAL[d.seq]->org_id_2 = 628058)
	rs->QUAL[d.seq]->PerformingCLIA   = "21D0693562"
	elseif(rs->QUAL[d.seq]->org_id_2 = 3837372)
	rs->QUAL[d.seq]->PerformingCLIA   = "21D0210256"
	elseif(rs->QUAL[d.seq]->org_id_2 = 3763758)
	rs->QUAL[d.seq]->PerformingCLIA   = "21D0212005"
	elseif(rs->QUAL[d.seq]->org_id_2 = 3440653)
	rs->QUAL[d.seq]->PerformingCLIA   = "21D0705218"
	endif
 
  		if(rs->qual[d.seq].service_resource = "*WHC*")
		rs->QUAL[d.seq]->PerformingCLIA  = "09D0208070"
 		rs->QUAL[d.seq]->Perform_location = "Washington Hospital Center"
 		rs->QUAL[d.seq]->perform_addr = ""
		;rs->QUAL[d.seq]->perform_addr2 = a.street_addr2
		rs->QUAL[d.seq]->perform_city = ""
		rs->QUAL[d.seq]->perform_state = ""
 		rs->QUAL[d.seq]->perform_zip = "20010"
 		elseif(rs->qual[d.seq].service_resource = "*UMH*")
 		rs->QUAL[d.seq]->PerformingCLIA  = "21D0693562"
 		rs->QUAL[d.seq]->Perform_location = "Union Memorial Hospital"
 		rs->QUAL[d.seq]->perform_addr = ""
		;rs->QUAL[d.seq]->perform_addr2 = a.street_addr2
		rs->QUAL[d.seq]->perform_city = ""
		rs->QUAL[d.seq]->perform_state = ""
 		rs->QUAL[d.seq]->perform_zip = "21218"
 		elseif(rs->qual[d.seq].service_resource = "*GUH*")
 		rs->QUAL[d.seq]->PerformingCLIA  = "09D0207566"
 		rs->QUAL[d.seq]->Perform_location = "Georgetown University Hospital"
 		rs->QUAL[d.seq]->perform_addr = ""
		;rs->QUAL[d.seq]->perform_addr2 = a.street_addr2
		rs->QUAL[d.seq]->perform_city = ""
		rs->QUAL[d.seq]->perform_state = ""
 		rs->QUAL[d.seq]->perform_zip = "20007"
 		elseif(rs->qual[d.seq].service_resource = "*FSH*")
 		rs->QUAL[d.seq]->PerformingCLIA  = "21D0219549"
 		rs->QUAL[d.seq]->Perform_location = "Franklin Square Hospital Center"
 		rs->QUAL[d.seq]->perform_addr = ""
		;rs->QUAL[d.seq]->perform_addr2 = a.street_addr2
		rs->QUAL[d.seq]->perform_city = ""
		rs->QUAL[d.seq]->perform_state = ""
 		rs->QUAL[d.seq]->perform_zip = "21237"
 		elseif(rs->qual[d.seq].service_resource = "*SMD*")
 		rs->QUAL[d.seq]->PerformingCLIA  = "21D0210256"
 		rs->QUAL[d.seq]->Perform_location = "Medstar Southern Maryland Hospital Center"
 		rs->QUAL[d.seq]->perform_addr = ""
		;rs->QUAL[d.seq]->perform_addr2 = a.street_addr2
		rs->QUAL[d.seq]->perform_city = ""
		rs->QUAL[d.seq]->perform_state = ""
 		rs->QUAL[d.seq]->perform_zip = "20735"
 		elseif(rs->qual[d.seq].service_resource = "*HBR*")
 		rs->QUAL[d.seq]->PerformingCLIA  = "21D0219268"
 		rs->QUAL[d.seq]->Perform_location = "Harbor Hospital Center"
 		rs->QUAL[d.seq]->perform_addr = ""
		;rs->QUAL[d.seq]->perform_addr2 = a.street_addr2
		rs->QUAL[d.seq]->perform_city = ""
		rs->QUAL[d.seq]->perform_state = ""
 		elseif(rs->qual[d.seq].service_resource = "*MMC*")
 		rs->QUAL[d.seq]->PerformingCLIA  = "21D0212005"
 		rs->QUAL[d.seq]->Perform_location = "MedStar Montgomery Medical Center"
 		rs->QUAL[d.seq]->perform_addr = ""
		;rs->QUAL[d.seq]->perform_addr2 = a.street_addr2
		rs->QUAL[d.seq]->perform_city = ""
		rs->QUAL[d.seq]->perform_state = ""
 		rs->QUAL[d.seq]->perform_zip = "20832"
 		elseif(rs->qual[d.seq].service_resource = "*GSH*")
 		rs->QUAL[d.seq]->PerformingCLIA  = "21D0219647"
 		rs->QUAL[d.seq]->Perform_location = "Good Samaritan Hospital"
 		rs->QUAL[d.seq]->perform_addr = ""
		;rs->QUAL[d.seq]->perform_addr2 = a.street_addr2
		rs->QUAL[d.seq]->perform_city = ""
		rs->QUAL[d.seq]->perform_state = ""
 		rs->QUAL[d.seq]->perform_zip = "21239"
 		elseif(rs->qual[d.seq].service_resource = "*SMH*")
 		rs->QUAL[d.seq]->PerformingCLIA  = "21D0705218"
 		rs->QUAL[d.seq]->Perform_location = "MedStar St Marys Hospital"
 		rs->QUAL[d.seq]->perform_zip = "20650"
 		rs->QUAL[d.seq]->perform_addr = ""
		;rs->QUAL[d.seq]->perform_addr2 = a.street_addr2
		rs->QUAL[d.seq]->perform_city = ""
		rs->QUAL[d.seq]->perform_state = ""
 		endif
 
with nocounter, time = 1200
 
;------------------------------------------------------------------------------------------
;Additional Detail
;-------------------------------------------------------------------------------------------
 
	for(cnt=1 to size(rs->qual,5))
		if(rs->qual[cnt].event_id > 0)
			set rs->qual[cnt].int_result = subroutine_get_blob(rs->qual[cnt].event_id)
		endif
	endfor
 
;/*********************************************************************************************
; 					GETTING encounter info    ;001
;**********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
 
		,encounter 		e
		,organization 	org
		,encntr_alias 	ea
		,encntr_alias 	ea2
 
 
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
	rs->QUAL[d.seq].e_location = org.org_name
 	RS->QUAL[d.seq].reg_dt = e.reg_dt_tm
 	RS->QUAL[d.seq].visit_reason = e.reason_for_visit
 	RS->QUAL[d.seq].admit_from = e.admit_src_cd
 
; 	if(RS->QUAL[d.seq].admit_from in(5070292.00,    5044615.00 ,    309193.00))
; 	RS->QUAL[d.seq].jail = "Y"
 
 	if (RS->QUAL[d.seq].admit_from in(423346946.00, 1692366029.00, 5070292.00, 56494552.00, 4190886.00))
 	RS->QUAL[d.seq].ltc = "Yes"
 	elseif(RS->QUAL[d.seq].admit_from in( 5070300
 											,5070300
											,309198
											,1992515983
											,309200
											,5070288
											,1692372825
											))
 	RS->QUAL[d.seq].ltc = "Unknown"
 	elseif(RS->QUAL[d.seq].admit_from in(
 	    5047147.00
 	))
 	RS->QUAL[d.seq].ltc = "No"
 	endif
 
with nocounter, time = 1200
 
/**************************************************************************************
 					GETTING LTC powerform results   ;001
****************************************************************************************/
Select into "nl:"
 
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
,clinical_event ce
 
PLAN D
 
JOIN ce where ce.encntr_id = rs->qual[d.seq].EncntrId
and ce.event_cd in (823735959.00)
 
detail
 
if(ce.result_val in("Nursing home","Assisted living"))
 
RS->QUAL[d.seq].ltc = "Yes"
 
endif
 
with nocounter, format, time = 1200
 
;/********************************************************************************************
; 					GETTING SPECIMEN info
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
	,order_detail od
 
 
 
 plan d
 
join od where od.order_id = rs->qual[d.seq].OrderId
and od.oe_field_id =       12584.00
detail
 
rs->QUAL[d.seq].Specimen = OD.oe_field_display_value
 
 
with nocounter, time = 1200
;/*******************************************************************************************
; 					GETTING order info
;********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
		,orders o
		,order_action oa
		,encounter e
		;,cust_future_order_info cfoi
		,organization org
		,encntr_alias 	ea
		,encntr_alias 	ea2
		,prsnl pr
		,prsnl_alias pra
;		,perform_result      pres
;    	,result             r
;    	,accession_order_r  aor
;    	,CONTAINER C
 
 
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
rs->QUAL[d.seq].PROVIDER_FNAME = PR.name_first
rs->QUAL[d.seq].PROVIDER_LNAME = PR.name_last
rs->QUAL[d.seq].npi = pra.alias
rs->QUAL[d.seq].Order_DTTM = O.orig_order_dt_tm
 
 
with nocounter, time = 1200
 
;;/*******************************************************************************************
;; 					GETTING pt address
;;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
		,ADDRESS A
 
PLAN d
 
	join A WHERE A.parent_entity_id = rs->qual[d.seq].PERSONID
 	AND A.address_type_cd = 756.00	;Home
 	and a.active_ind = 1
 	and a.end_effective_dt_tm > cnvtdatetime(sysdate)
 
order by d.seq
 
detail
rs->QUAL[D.SEQ].Zip = A.zipcode
rs->QUAL[D.SEQ].County = UAR_GET_CODE_DISPLAY(A.county_cd)
rs->QUAL[D.SEQ].City = A.CITY
rs->QUAL[D.SEQ].County = uar_get_code_display(A.county_cd)
rs->QUAL[D.SEQ].State = A.state
RS->QUAL[D.SEQ].StreetAddr = A.street_addr
RS->QUAL[D.SEQ].StreetAddr2 = A.street_addr2
 
;if (RS->QUAL[D.SEQ].StreetAddr = "UNKNOWN")
;rs->QUAL[D.SEQ].homeless = "Y"
;ENDIF
with nocounter, time = 1200
;;/********************************************************************************************
;; 					GETTING zip OF ORG
;;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
		,ADDRESS A
		,PHONE PH
 
PLAN d
 
	join A WHERE A.parent_entity_id = rs->qual[d.seq].org_id
	and a.active_ind = 1
	and a.end_effective_dt_tm > cnvtdatetime(sysdate)
	and a.address_type_cd = 754.00
 
	JOIN PH WHERE PH.parent_entity_id = outerjoin(A.parent_entity_id)
	AND PH.active_ind = outerjoin(1)
	and ph.beg_effective_dt_tm < outerjoin(cnvtdatetime(curdate,curtime))
	and ph.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime))
	and ph.phone_type_cd =         outerjoin(163.00)
	AND PH.parent_entity_name = outerjoin("ORGANIZATION")
 
order by d.seq
 
detail
rs->QUAL[D.SEQ].FAC_PHONE = PH.phone_num
rs->QUAL[D.SEQ].fac_ZIP= A.zipcode
rs->QUAL[D.SEQ].fac_County = A.county
rs->QUAL[D.SEQ].fac_City = A.CITY
rs->QUAL[D.SEQ].fac_State = A.state
RS->QUAL[D.SEQ].fac_StreetAddr = A.street_addr
RS->QUAL[D.SEQ].fac_StreetAddr2 = A.street_addr2
 
if(rs->qual[d.seq].org_id = 628085)
	rs->QUAL[d.seq]->FAC_PHONE = "2024443597"
endif
 
with nocounter, time = 1200
 
;/********************************************************************************************
; 					GETTING onset date info  ;001
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
	,clinical_event ce
	,ce_date_result cdr
 
 plan d
 
join ce where ce.person_id = rs->qual[d.seq].PersonId
and ce.encntr_id = rs->qual[d.seq].ENCNTRid
and ce.event_cd in( 2273998547.00, 2273998843.00,2230980383.00,2385366457.00,2384922167.00,2384924885.00
)
 
join cdr where cdr.event_id = outerjoin(ce.event_id)
 
detail
 
 if(ce.event_cd = 2273998547.00)
rs->QUAL[d.seq].onset_dt = FORMAT(CDR.result_dt_tm, "YYYYMMDD;;Q");cnvtdatetime(ce.result_val, "MM/DD/YYYY hh:mm:ss;;D")
 
elseif(ce.event_cd = 2273998843.00 and ce.result_val != "*Asympomatic*")
rs->QUAL[d.seq].symptoms = "Yes"
 
elseif(ce.event_cd = 2273998843.00 and ce.result_val = "*Asympomatic*")
rs->QUAL[d.seq].symptoms = "No"
 
elseif(ce.event_cd = 2230980383.00 and ce.result_val in ("None*"))
rs->QUAL[d.seq].symptoms = "No"
 
elseif(ce.event_cd = 2230980383.00 and ce.result_val not in ("None*","*Unable*"))
rs->QUAL[d.seq].symptoms = "Yes"
 
elseif(ce.event_cd = 2385366457.00 and ce.result_val in ("Yes"))
rs->QUAL[d.seq].oc_stat = "Yes"
 
elseif(ce.event_cd = 2385366457.00 and ce.result_val in ("No"))
rs->QUAL[d.seq].oc_stat = "No"
 
elseif(ce.event_cd = 2385366457.00 and ce.result_val in ("Unknown"))
rs->QUAL[d.seq].oc_stat = "Unknown"
 
elseif(ce.event_cd = 2384922167.00 and ce.result_val in ("Yes"))
rs->QUAL[d.seq].ltc = "Yes"
 
elseif(ce.event_cd = 2384922167.00 and ce.result_val in ("No"))
rs->QUAL[d.seq].ltc= "No"
 
elseif(ce.event_cd = 2384922167.00 and ce.result_val in ("Unknown"))
rs->QUAL[d.seq].ltc = "Unknown"
 
elseif(ce.event_cd = 2384924885.00 and ce.result_val in ("Yes"))
rs->QUAL[d.seq].preg_ind = "Pregnant"
 
elseif(ce.event_cd = 2384924885.00 and ce.result_val in ("No"))
rs->QUAL[d.seq].preg_ind = "Not Pregnant"
 
;elseif(ce.event_cd = 2384924885.00 and ce.result_val in ("Unknown"))
;rs->QUAL[d.seq].preg_ind = "Unknown"
 
endif
 
;if(rs->QUAL[d.seq].symptoms not in ("Y","N"))
;rs->QUAL[d.seq].symptoms = "UNK"
;endif
 
 
 
with nocounter, time = 1200
;;/************************************************************************************
;; 					GETTING pt first test ;001
;;*************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
		,clinical_event c
PLAN d
 
	join c WHERE c.person_id = rs->qual[d.seq].PERSONID
	and c.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
	and c.event_class_cd in ( 236.00,224.00)
	;and c.valid_from_dt_tm between CNVTDATETIME($START_DT)AND CNVTDATETIME($END_DT)
	and c.result_status_cd in (25,34,35)
	and c.authentic_flag = 1
	and c.event_cd in (
					2258265897	;CoVID19-SARS-CoV-2 by PCR
				,2254653289	;COVID 19 (DH/CDC)
				,2259614555	;COVID-19/Coronavirus RNA PCR
				,2258239523	;COVID-19 (SARS-CoV-2, NAA)
				,2265151661	;CoVID_19 (SARS-CoV2, NAA)
				,2258239523	;COVID-19 (SARS-CoV-2, NAA)
				,2270692929	;CoVID 19-SARS-CoV-2 Overall Result
				,2258265897	;CoVID 19-SARS-CoV-2 by PCR
				,2270688963	;CoVID 19-PAN-SARS-CoV-2 by PCR
				,2259601949	;COVID19(SARS-CoV-2)
				,2276648185 ; NEW POC ORDER
					,2282064783
					,2287776717
					,2290710033
					,2290710049
					,2290713753
					,2290713803
					,2290718387
				,2291914727 ;inhouse IgG
				,2291907909 ;Inhouse IgG Interp
				,2385455807 ;PCR Ag
				,2404008691 ;POC Ag
				;,104260588.00 ; flu rapid test - for testing - remove*****************
	)
 
 
order by c.person_id
 
 head c.person_id
 cnt = 0
detail
 cnt = cnt + 1
 
 IF(cnt = 1)
 rs->qual[d.seq].FIRST_TEST = "Yes"
 elseIF(cnt > 1)
 rs->qual[d.seq].FIRST_TEST = "No"
 ENDIF
 
with nocounter, time = 1000
;
;;/**************************************************************************************
;; 					GETTING Pregnancy powerform results  ;001
;;****************************************************************************************/
Select into "nl:"
 
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
,clinical_event ce
 
PLAN D
 
JOIN ce where ce.encntr_id = rs->qual[d.seq].EncntrId
and ce.event_cd =      704785.00;	Pregnancy
 
 
detail
 
if(ce.result_val = "Confirmed positive")
 
rs->QUAL[D.SEQ].preg_ind = "Pregnant"
 
elseif(ce.result_val in( "Patient denies","Confirmed negative"))
 
rs->QUAL[D.SEQ].preg_ind = "Not Pregnant"
 
elseif(ce.result_val = "Possible unconfirmed")
 
rs->QUAL[D.SEQ].preg_ind = "Possibly Pregnant"
 
endif
 
with nocounter, format, time = 1200
 
;;======================================================================
;; GETTING pregnancy indicator  ;001
;;======================================================================
 
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
  , Problem pr
  , nomenclature n
  ,pregnancy_instance pi
  ,pregnancy_estimate pe
 
 
PLAN D1
 JOIN pR WHERE pR.person_id = RS->QUAL[D1.SEQ].PersonId
 
	 and pR.active_ind = 1
	 AND PR.active_status_cd = 188
	 and pR.life_cycle_status_cd = 3301 ; active
	 AND PR.active_status_cd = 188; ACTIVE
	 and pr.data_status_cd in (23,34,25,35)
		AND PR.problem_instance_id = (SELECT MAX(pR2.PROBLEM_INSTANCE_ID)
								from PROBLEM   PR2
								where PR.PROBLEM_id = pR2.PROBLEM_id and pR2.active_ind = 1)
 
		JOIN PI WHERE PI.person_id = Pr.person_id and pi.active_ind = 1
 		AND Pi.pregnancy_id = (SELECT MAX(pi2.pregnancy_id)
								from PRegnancy_instance   Pi2
								where Pi.person_id = pi2.person_id and pi2.active_ind = 1)
 
		join pe where pi.pregnancy_id = pe.pregnancy_id and pe.active_ind = 1
		and pe.pregnancy_estimate_id = (SELECT MAX(pe2.pregnancy_estimate_id)
								from PRegnancy_estimate  Pe2
								where Pe.pregnancy_id = pe2.pregnancy_id and pe2.active_ind = 1)
 
join n where n.nomenclature_id = pR.nomenclature_id
		and n.source_identifier_keycap in (
								"191073013"
											)
											AND N.active_ind = 1
											AND N.active_status_cd = 188 ; ACTIVE
 
; JOIN PI WHERE PI.person_id = P.person_id and pi.active_ind = 1
; AND Pi.pregnancy_id = (SELECT MAX(pi2.pregnancy_id)
;								from PRegnancy_instance   Pi2
;								where Pi.person_id = pi2.person_id and pi2.active_ind = 1)
 order by d1.seq
 
 DETAIL
 
  RS->QUAL[d1.seq].preg_ind = "Pregnant"
 
 with nocounter, time = 1500
 
 /****************************************************************************************************
 					;get patient employment information   ;001
*****************************************************************************************************/
 
Select into "nl:"
FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
	,person_org_reltn por
 
PLAN D1
 
 
join por
	where por.person_id =  RS->QUAL[D1.SEQ].PERSONID
		and por.active_ind = 1
		and por.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
		and por.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
		and por.person_org_reltn_cd = 1136.00;employer
 
detail
 
	RS->QUAL[D1.SEQ].occupation = 	uar_get_code_display(por.empl_status_cd)
 
	if(RS->QUAL[D1.SEQ].occupation in ("Retired","Not Employed","Self Employed"))
	RS->QUAL[D1.SEQ].oc_stat = "No"
	endif
 
 
with nocounter,time = 1300, ORAHINTCBO("INDEX( POR XIE1PERSON_ORG_RELTN)")
;/********************************************************************************************
; 					GETTING age info   ;001
;*********************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
	,person p
	,encounter e
 
 
 
 plan d
 
join p where p.person_id = rs->qual[d.seq].PersonId
join e where e.encntr_id = rs->qual[d.seq].EncntrId
 
 
detail
 
 	if(datetimediff(e.reg_dt_tm, p.birth_dt_tm) > 365)
 	rs->QUAL[d.seq]->AGE = datetimediff(e.reg_dt_tm, p.birth_dt_tm)/365
 	rs->QUAL[d.seq]->age_unit = "Years"
 	elseif(datetimediff(e.reg_dt_tm, p.birth_dt_tm) < 365 and datetimediff(e.reg_dt_tm, p.birth_dt_tm) > 28 )
 	rs->QUAL[d.seq]->AGE = datetimediff(e.reg_dt_tm, p.birth_dt_tm)/365/12
 	rs->QUAL[d.seq]->age_unit = "Months"
 	elseif(datetimediff(e.reg_dt_tm, p.birth_dt_tm) < 28)
 	rs->QUAL[d.seq]->AGE = datetimediff(e.reg_dt_tm, p.birth_dt_tm)/365
 	rs->QUAL[d.seq]->age_unit = "Days"
 	elseif(datetimediff(e.reg_dt_tm, p.birth_dt_tm) < 1 )
 	rs->QUAL[d.seq]->AGE = datetimediff(e.reg_dt_tm, p.birth_dt_tm)/365/24
 	rs->QUAL[d.seq]->age_unit = "Hours"
 	endif
 
 
with nocounter, time = 1200
 
/********************************************************************************************
               OUTPUT DATA TO $OUTDEV/EMAILING
*********************************************************************************************/
If($Type = 2)
;#exit_program
; if (size(rs->QUAL,5) > 0); AT LEAST ONE PATIENT FOUND ABOVE
 
 SELECT DISTINCT INTO VALUE(FILE_NAME)
 
 	 	 SENDING_FACILITY_NAME = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
 	, SENDING_FACILITY_CLIA = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].PerformingCLIA))
 	, MESSAGE_CONTROL_ID = cnvtstringchk(rs->QUAL[D1.SEQ].event_id)
 	, PATIENT_ID = trim(SUBSTRING(1, 15, rs->QUAL[D1.SEQ].CMRN))
 	, SSN = " "
	, LASTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LastName))
	, FIRSTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FirstName))
	, MIDDLE_NAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].MiddleName))
	, STREET_ADDRESS = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr))
	, STREET_ADDRESS_2 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr2))
	, CITY = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].City))
	, COUNTY = " ";trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].County))
	, STATE = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].State))
	, ZIP = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].Zip))
	, PT_PHONE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].PT_PHONE))
	, RACE = SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Race)
	, ETHNICITY = SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ETHNIC_CD)
	, DOB = SUBSTRING(1, 20, rs->QUAL[D1.SEQ].DOB)
	, SEX = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].Gender))
	, MSGDATETIME = FORMAT(rs->QUAL[D1.SEQ].SYSTEM_DATE, "YYYYMMDDhhmmss;;D")
	, SPECIMEN_ID = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].accession))
	, SPECIMEN_TYPE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
	, SPECIMEN_SOURCE_SITE = " ";trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
	, RESULT_UNIT_ID = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].ResultUnit))
	, PROVIDER_ID		 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].npi))
	, PROVIDER_LASTNAME	 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].PROVIDER_LNAME))
	, PROVIDER_FIRSTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].PROVIDER_FNAME))
 
	, ORDERING_PROV_ADDR = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_StreetAddr))
	, ORDERING_PROV_ADDR2 = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_StreetAddr2))
	, ORDERING_PROV_CITY= trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].fac_City))
	, ORDERING_PROV_STATE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_State))
	, ORDERING_PROV_ZIP = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_ZIP))
	, ORDERING_PROV_COUNTY = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_County))
	, ORDERING_PROV_PHONE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_PHONE))
 
	, ORDERING_FACILITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
	, ORDERING_FAC_ADDR = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_StreetAddr))
	, ORDERING_FAC_ADDR2 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].fac_StreetAddr2))
	, ORDERING_FAC_CITY= trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_City))
	, ORDERING_FAC_STATE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_State))
	, ORDERING_FAC_ZIP = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_ZIP))
	, ORDERING_FAC_COUNTY = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_County))
	, ORDERING_FAC_PHONE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_PHONE))
	, OBSERVATION_DATETIME = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].CollectionDtTm))
	, RESULT_STATUS = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].result_status))
	, SPECIMEN_RECEIVE_DATE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].CollectionDtTm))
	, ORDER_CODE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LOINC))
	, ORDER_CODE_TEXT_DESCRIPTION = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].EVENT))
	, ORDER_CODE_NAMING_SYSTEM = "LN"
	, RESULT_VALUE_TYPE = "CE"
	, RESULT_TEST_CODE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LOINC))
	, RESULT_TEST_TEXT_DESCRIPTION = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].EVENT))
	, RESULT_TEST_NAMING_SYSTEM = "LN"
	, OBSERVATION_VALUE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].result_sc))
	, OBSERVATION_VALUE_RESULT_TEXT = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Result))
	, OBSERVATION_VALUE_RESULT_NAMING_SYSTEM = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].result_ns))
	, TEST_RESULT_STATUS = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].TEST_RESULT_STATUS))
	, PERFORMING_LAB_ID_PRODUCERID = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].PerformingCLIA))
	, PERFORMING_LAB_ID_PRODUCERID_TEXT = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].Perform_Location))
	, PERFORMING_LAB_ID_PRODUCERID_NS = "CLIA"
	, DT_REPORTED = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].RESULT_DT))
	, PERFORMING_LAB_ADDR = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_addr))
	, PERFORMING_LAB_ADDR2 = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_addr2))
	, PERFORMING_LAB_CITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_city))
	, PERFORMING_LAB_STATE = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_state))
	, PERFORMING_LAB_ZIP = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_zip))
	, PERFORMING_LAB_COUNTY =  trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_county))
 
	, SPECIMEN_TYPE_IDENTIFIER = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].specimen_type))
	, SPECIMEN_TYPE_NAMINGSYSTEM = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].specimen_ns))
	, ORDER_DATE = format(RS->QUAL[d1.seq].ORDER_DTTM, "YYYYMMDDhhmmss;;D")
	, EAU_TEST_KIT_IDENTIFIER = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].EAU_TEST_KIT));"ID NOW COVID-19_Abbott Diagnostics Scarborough, Inc._EUA"
	, MODEL_NAME_TESTKIT_IDENTIFIER = " "
	, DEVICE_IDENTIFIER = " ";trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].service_resource))
	, MODEL_NAME_BASED_INSTRUMENT = " "
	, DEVICE_IDENTIFIER_BASED_INSTRUMENT = " "
	, INSTANCE_BASED_TEST_KIT = " "
	, INSTANCE_BASED_INSTRUMENT = " "
	, PATIENTS_AGE = trim(cnvtstring(rs->QUAL[D1.SEQ].age))
	, PATIENTS_AGE_UNIT = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].age_unit))
 
	, FIRST_TEST = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].FIRST_TEST))
	, HEALTH_CARE_WORKER = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].oc_stat))
	, SYMPTOMATIC = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].symptoms))
	, SYMPTOM_ONSET = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].onset_dt))
	, HOSPITALIZED = "No"
	, ICU = "No"
	, CONGREGATE_CARE_SETTING = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].LTC))
	, PREGNANT = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].preg_ind))
	;, ORDERING_FAC_PHONE = rs->QUAL[D1.SEQ].ORG_ID)
 
 
;	, RESULT = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Result))
;   , RESULTCMT = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].ResultCmt))
;	, ACCESSION = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ACCESSION))
;	, TEST_NAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].EVENT))
;	, ONSET_DATE = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].onset_dt))
;	, SERVICE_RESOURCE = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].SERVICE_RESOURCE))
;	, ORDERID = cnvtstringchk(rs->QUAL[D1.SEQ].clinical_evt_id)
;	, LOINC = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LOINC))
 
 
	FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
 
	plan d1
 
	where rs->QUAL[d1.seq].ENCNTR_CD IN (
										   309309.00	;Outpatient
							  			 ,5043178.00	;Clinic
						      			 ,309314.00		;Recurring Clinic
										 ,3012539.00	;Outpatient Message
										 ,5048254.00   	;HOSPICE Outpt
										 ,0.0
									)
 
	;and rs->QUAL[d1.seq].State = "VA"
	and rs->QUAL[d1.seq].Result != "TNP"
	and rs->QUAL[d1.seq].Result != "QNS"
	and rs->QUAL[d1.seq].Result != "Invalid"
 	and rs->QUAL[d1.seq].Result != "Not Detected"
 	and rs->QUAL[d1.seq].Result != "Not detected"
 	and rs->QUAL[d1.seq].Result != "Negative"
 	and rs->QUAL[d1.seq].Result != "NEG*"
 	 
	with noheading,PCFormat('', '|',1,1)
	, format=STREAM, compress, nocounter, format;Heading
 
 
	select into $outdev
		msg="success"
		from dummyt
		with nocounter
 
 elseif($type = 1)
 
 if (size(rs->QUAL,5) > 0)
 
 	select distinct into $outdev
 
 	 	 SENDING_FACILITY_NAME = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
 	, SENDING_FACILITY_CLIA = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].PerformingCLIA))
 	, MESSAGE_CONTROL_ID = cnvtstringchk(rs->QUAL[D1.SEQ].event_id)
 	, PATIENT_ID = trim(SUBSTRING(1, 15, rs->QUAL[D1.SEQ].CMRN))
 	, SSN = " "
	, LASTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LastName))
	, FIRSTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FirstName))
	, MIDDLE_NAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].MiddleName))
	, STREET_ADDRESS = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr))
	, STREET_ADDRESS_2 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr2))
	, CITY = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].City))
	, COUNTY = " ";trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].County))
	, STATE = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].State))
	, ZIP = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].Zip))
	, PT_PHONE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].PT_PHONE))
	, RACE = SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Race)
	, ETHNICITY = SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ETHNIC_CD)
	, DOB = SUBSTRING(1, 20, rs->QUAL[D1.SEQ].DOB)
	, SEX = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].Gender))
	, MSGDATETIME = FORMAT(rs->QUAL[D1.SEQ].SYSTEM_DATE, "YYYYMMDDhhmmss;;D")
	, SPECIMEN_ID = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].accession))
	, SPECIMEN_TYPE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
	, SPECIMEN_SOURCE_SITE = " ";trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
	, RESULT_UNIT_ID = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].ResultUnit))
	, PROVIDER_ID		 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].npi))
	, PROVIDER_LASTNAME	 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].PROVIDER_LNAME))
	, PROVIDER_FIRSTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].PROVIDER_FNAME))
 
	, ORDERING_PROV_ADDR = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_StreetAddr))
	, ORDERING_PROV_ADDR2 = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_StreetAddr2))
	, ORDERING_PROV_CITY= trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].fac_City))
	, ORDERING_PROV_STATE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_State))
	, ORDERING_PROV_ZIP = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_ZIP))
	, ORDERING_PROV_COUNTY = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_County))
	, ORDERING_PROV_PHONE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_PHONE))
 
	, ORDERING_FACILITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
	, ORDERING_FAC_ADDR = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_StreetAddr))
	, ORDERING_FAC_ADDR2 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].fac_StreetAddr2))
	, ORDERING_FAC_CITY= trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_City))
	, ORDERING_FAC_STATE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_State))
	, ORDERING_FAC_ZIP = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_ZIP))
	, ORDERING_FAC_COUNTY = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_County))
	, ORDERING_FAC_PHONE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_PHONE))
	, OBSERVATION_DATETIME = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].CollectionDtTm))
	, RESULT_STATUS = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].result_status))
	, SPECIMEN_RECEIVE_DATE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].CollectionDtTm))
	, ORDER_CODE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LOINC))
	, ORDER_CODE_TEXT_DESCRIPTION = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].EVENT))
	, ORDER_CODE_NAMING_SYSTEM = "LN"
	, RESULT_VALUE_TYPE = "CE"
	, RESULT_TEST_CODE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LOINC))
	, RESULT_TEST_TEXT_DESCRIPTION = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].EVENT))
	, RESULT_TEST_NAMING_SYSTEM = "LN"
	, OBSERVATION_VALUE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].result_sc))
	, OBSERVATION_VALUE_RESULT_TEXT = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Result))
	, OBSERVATION_VALUE_RESULT_NAMING_SYSTEM = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].result_ns))
	, TEST_RESULT_STATUS = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].TEST_RESULT_STATUS))
	, PERFORMING_LAB_ID_PRODUCERID = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].PerformingCLIA))
	, PERFORMING_LAB_ID_PRODUCERID_TEXT = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].Perform_Location))
	, PERFORMING_LAB_ID_PRODUCERID_NS = "CLIA"
	, DT_REPORTED = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].RESULT_DT))
	, PERFORMING_LAB_ADDR = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_addr))
	, PERFORMING_LAB_ADDR2 = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_addr2))
	, PERFORMING_LAB_CITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_city))
	, PERFORMING_LAB_STATE = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_state))
	, PERFORMING_LAB_ZIP = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_zip))
	, PERFORMING_LAB_COUNTY =  trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_county))
 
	, SPECIMEN_TYPE_IDENTIFIER = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].specimen_type))
	, SPECIMEN_TYPE_NAMINGSYSTEM = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].specimen_ns))
	, ORDER_DATE = format(RS->QUAL[d1.seq].ORDER_DTTM, "YYYYMMDDhhmmss;;D")
	, EAU_TEST_KIT_IDENTIFIER = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].EAU_TEST_KIT));"ID NOW COVID-19_Abbott Diagnostics Scarborough, Inc._EUA"
	, MODEL_NAME_TESTKIT_IDENTIFIER = " "
	, DEVICE_IDENTIFIER = " ";trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].service_resource))
	, MODEL_NAME_BASED_INSTRUMENT = " "
	, DEVICE_IDENTIFIER_BASED_INSTRUMENT = " "
	, INSTANCE_BASED_TEST_KIT = " "
	, INSTANCE_BASED_INSTRUMENT = " "
	, PATIENTS_AGE = trim(cnvtstring(rs->QUAL[D1.SEQ].age))
	, PATIENTS_AGE_UNIT = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].age_unit))
 
	, FIRST_TEST = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].FIRST_TEST))
	, HEALTH_CARE_WORKER = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].oc_stat))
	, SYMPTOMATIC = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].symptoms))
	, SYMPTOM_ONSET = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].onset_dt))
	, HOSPITALIZED = "No"
	, ICU = "No"
	, CONGREGATE_CARE_SETTING = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].LTC))
	, PREGNANT = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].preg_ind))
;	;, ORDER_id = rs->QUAL[D1.SEQ].ORG_ID
;
;   ;, RESULTCMT = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].ResultCmt))
;
;;	, ONSET_DATE = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].onset_dt))
;;	, SERVICE_RESOURCE = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].SERVICE_RESOURCE))
;;	, ORDERID = cnvtstringchk(rs->QUAL[D1.SEQ].clinical_evt_id)
	,rs->QUAL[D1.SEQ].ORG_ID
 
 
	FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
 
	plan d1
 
	where rs->QUAL[d1.seq].ENCNTR_CD IN (
										   309309.00	;Outpatient
							  			 ,5043178.00	;Clinic
						      			 ,309314.00		;Recurring Clinic
										 ,3012539.00	;Outpatient Message
										 ,5048254.00   	;HOSPICE Outpt
										 ,0.0
									)
 
	;and rs->QUAL[d1.seq].State != "DC"
	;and rs->QUAL[d1.seq].State != "MD"
	and rs->QUAL[d1.seq].Result != "TNP"
	and rs->QUAL[d1.seq].Result != "QNS"
	and rs->QUAL[d1.seq].Result != "Invalid"
 	and rs->QUAL[d1.seq].Result != "Not Detected"
 	and rs->QUAL[d1.seq].Result != "Not detected"
 	and rs->QUAL[d1.seq].Result != "Negative"
 	and rs->QUAL[d1.seq].Result != "NEG*"
 	 
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
 ;EMAIL
select into value(FILENAME)
  	 	 SENDING_FACILITY_NAME = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
 	, SENDING_FACILITY_CLIA = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].PerformingCLIA))
 	, MESSAGE_CONTROL_ID = cnvtstringchk(rs->QUAL[D1.SEQ].event_id)
 	, PATIENT_ID = trim(SUBSTRING(1, 15, rs->QUAL[D1.SEQ].CMRN))
 	, SSN = " "
	, LASTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LastName))
	, FIRSTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FirstName))
	, MIDDLE_NAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].MiddleName))
	, STREET_ADDRESS = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr))
	, STREET_ADDRESS_2 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr2))
	, CITY = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].City))
	, COUNTY = " ";trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].County))
	, STATE = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].State))
	, ZIP = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].Zip))
	, PT_PHONE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].PT_PHONE))
	, RACE = SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Race)
	, ETHNICITY = SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ETHNIC_CD)
	, DOB = SUBSTRING(1, 20, rs->QUAL[D1.SEQ].DOB)
	, SEX = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].Gender))
	, MSGDATETIME = FORMAT(rs->QUAL[D1.SEQ].SYSTEM_DATE, "YYYYMMDDhhmmss;;D")
	, SPECIMEN_ID = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].accession))
	, SPECIMEN_TYPE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
	, SPECIMEN_SOURCE_SITE = " ";trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
	, RESULT_UNIT_ID = trim(SUBSTRING(1, 10, rs->QUAL[D1.SEQ].ResultUnit))
	, PROVIDER_ID		 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].npi))
	, PROVIDER_LASTNAME	 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].PROVIDER_LNAME))
	, PROVIDER_FIRSTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].PROVIDER_FNAME))
 
	, ORDERING_PROV_ADDR = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_StreetAddr))
	, ORDERING_PROV_ADDR2 = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_StreetAddr2))
	, ORDERING_PROV_CITY= trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].fac_City))
	, ORDERING_PROV_STATE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_State))
	, ORDERING_PROV_ZIP = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_ZIP))
	, ORDERING_PROV_COUNTY = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_County))
	, ORDERING_PROV_PHONE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_PHONE))
 
	, ORDERING_FACILITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
	, ORDERING_FAC_ADDR = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_StreetAddr))
	, ORDERING_FAC_ADDR2 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].fac_StreetAddr2))
	, ORDERING_FAC_CITY= trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].fac_City))
	, ORDERING_FAC_STATE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_State))
	, ORDERING_FAC_ZIP = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_ZIP))
	, ORDERING_FAC_COUNTY = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_County))
	, ORDERING_FAC_PHONE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].fac_PHONE))
	, OBSERVATION_DATETIME = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].CollectionDtTm))
	, RESULT_STATUS = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].result_status))
	, SPECIMEN_RECEIVE_DATE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].CollectionDtTm))
	, ORDER_CODE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LOINC))
	, ORDER_CODE_TEXT_DESCRIPTION = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].EVENT))
	, ORDER_CODE_NAMING_SYSTEM = "LN"
	, RESULT_VALUE_TYPE = "CE"
	, RESULT_TEST_CODE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LOINC))
	, RESULT_TEST_TEXT_DESCRIPTION = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].EVENT))
	, RESULT_TEST_NAMING_SYSTEM = "LN"
	, OBSERVATION_VALUE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].result_sc))
	, OBSERVATION_VALUE_RESULT_TEXT = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Result))
	, OBSERVATION_VALUE_RESULT_NAMING_SYSTEM = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].result_ns))
	, TEST_RESULT_STATUS = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].TEST_RESULT_STATUS))
	, PERFORMING_LAB_ID_PRODUCERID = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].PerformingCLIA))
	, PERFORMING_LAB_ID_PRODUCERID_TEXT = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].Perform_Location))
	, PERFORMING_LAB_ID_PRODUCERID_NS = "CLIA"
	, DT_REPORTED = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].RESULT_DT))
	, PERFORMING_LAB_ADDR = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_addr))
	, PERFORMING_LAB_ADDR2 = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_addr2))
	, PERFORMING_LAB_CITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_city))
	, PERFORMING_LAB_STATE = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_state))
	, PERFORMING_LAB_ZIP = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_zip))
	, PERFORMING_LAB_COUNTY =  trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].perform_county))
 
	, SPECIMEN_TYPE_IDENTIFIER = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].specimen_type))
	, SPECIMEN_TYPE_NAMINGSYSTEM = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].specimen_ns))
	, ORDER_DATE = format(RS->QUAL[d1.seq].ORDER_DTTM, "YYYYMMDDhhmmss;;D")
	, EAU_TEST_KIT_IDENTIFIER = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].EAU_TEST_KIT));"ID NOW COVID-19_Abbott Diagnostics Scarborough, Inc._EUA"
	, MODEL_NAME_TESTKIT_IDENTIFIER = " "
	, DEVICE_IDENTIFIER = " ";trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].service_resource))
	, MODEL_NAME_BASED_INSTRUMENT = " "
	, DEVICE_IDENTIFIER_BASED_INSTRUMENT = " "
	, INSTANCE_BASED_TEST_KIT = " "
	, INSTANCE_BASED_INSTRUMENT = " "
	, PATIENTS_AGE = trim(cnvtstring(rs->QUAL[D1.SEQ].age))
	, PATIENTS_AGE_UNIT = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].age_unit))
 
	, FIRST_TEST = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].FIRST_TEST))
	, HEALTH_CARE_WORKER = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].oc_stat))
	, SYMPTOMATIC = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].symptoms))
	, SYMPTOM_ONSET = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].onset_dt))
	, HOSPITALIZED = "No"
	, ICU = "No"
	, CONGREGATE_CARE_SETTING = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].LTC))
	, PREGNANT = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].preg_ind))
 
		FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
 
	plan d1
 
	where rs->QUAL[d1.seq].ENCNTR_CD IN (
										   309309.00	;Outpatient
							  			 ,5043178.00	;Clinic
						      			 ,309314.00		;Recurring Clinic
										 ,3012539.00	;Outpatient Message
										 ,5048254.00   	;HOSPICE Outpt
										 ,0.0
									)
 
	;and rs->QUAL[d1.seq].State != "DC"
	;and rs->QUAL[d1.seq].State != "MD"
	and rs->QUAL[d1.seq].Result != "TNP"
	and rs->QUAL[d1.seq].Result != "QNS"
	and rs->QUAL[d1.seq].Result != "Invalid"
 	and rs->QUAL[d1.seq].Result != "Not Detected"
 	and rs->QUAL[d1.seq].Result != "Not detected"
 	and rs->QUAL[d1.seq].Result != "Negative"
 	and rs->QUAL[d1.seq].Result != "NEG*" 
 
	with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress
 
 	;***********EMAIL THE ACTUAL ZIPPED FILE**************************** ;MOD004
		if(CURDOMAIN = PRODUCTION_DOMAIN);ONLY EMAIL OUT OF P41
;;			SET  AIX_COMMAND  =  Build2 ('zip ', filename_zip, ' ', filename)
;;			SET  AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
;;			SET  AIX_CMDSTATUS = 0
;;			CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
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
 
	 	Report_value 		= "No data found"
 
		from (dummyt d1 with seq = size(1))
 
		set EMAIL_SUBJECT = "COVID-19 VA DOH ELR TEST -No accounts found"
 
 
	;***********EMAIL THE ACTUAL ZIPPED FILE**************************** ;MOD004
		if(CURDOMAIN = PRODUCTION_DOMAIN);ONLY EMAIL OUT OF P41
;;			SET  AIX_COMMAND  =  Build2 ('zip ', filename_zip, ' ', filename)
;;			SET  AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
;;			SET  AIX_CMDSTATUS = 0
;;			CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
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
 
subroutine  subroutine_get_blob(this_event_id)
	set x1 = 0
	declare blob_id = vc with public,protect
	declare blob_ret_len = i4 with noconstant(0), public,protect
	set blob_in=fillstring(30000," ")
	declare compression_cd = f8 with public,protect
 
	select into "nl:"
		b.BLOB_CONTENTS
	from ce_blob b
	where event_id = this_event_id
	and b.valid_until_dt_tm > cnvtdatetime(curdate,curtime)
	order by b.event_id,b.valid_from_dt_tm
	detail
  		blob_in =b.BLOB_CONTENTS
   		compression_cd = b.compression_cd
	with nocounter
 
	call echo(concat("compression_cd = ",cnvtstring(compression_cd)))
	set blob_out=fillstring(30000," ")
	set blob_out2=fillstring(30000," ")
	set blob_out3=fillstring(30000," ")
	if(compression_cd in( 728.00,727)); OCFCOMP);decompress the garbage
	   	call  uar_ocf_uncompress(blob_in,size(trim(blob_in,3)),blob_out,size(blob_out),blob_ret_len)
	 	;call echo(blob_out)
	   	;;determine rtf, then do another uar tool if it is
	   	set rtf_ind = findstring("rtf1",blob_out,0)
	    if(rtf_ind > 0)
	   		call echo("rtf found")
	   		set stat=uar_rtf(blob_out,size(blob_out), blob_out2,size(blob_out2),0,0)
	   		set blob_out2=trim(blob_out2,3)
	   	else
	   		set blob_out2=trim(blob_out,3)
	   	endif
	else; it wasn't compressed
		set blob_out2 = replace(blob_in,"ocf_blob"," ",0)
	endif
 	set blob_out3 = substring(1,1000,blob_out2) ;80 char for testing
 	call echo(blob_out3)
	return(blob_out3)
end ;subroutine
end
go