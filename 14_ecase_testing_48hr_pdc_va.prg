/************************************************************************************************************
 Program Title:     14_ecase_testing_48hr_pdc_va.prg
 Create Date:       08/11/2022
 Object name:       14_ecase_testing_48hr_pdc_va
 Source file:       14_ecase_testing_48hr_pdc_va.prg
 MCGA:
 OPAS:
 Purpose:https:
 Executed from:     Explorer Menu
 Special Notes:
**************************************************************************************************************
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^IMPORTANT^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
**************************************************************************************************************
 Clone from jwd_PALLIATIVE_CARE_METRICS.prg

 This report is only for ***VA DEPT OF HEALTH*** and looks for DTAs:

 wrapper - 14_ecase_testing_wrapper

*******************************************************************************************************************************
*******************************************************************************************************************************
*******************************************************************************************************************************
*******************************************************************************************************************************
                                  MODIFICATION CONTROL LOG                                   
*******************************************************************************************************************************
Mod Date       Analyst           MCGA   Comment                                              
--- ---------- ----------------- ------ ---------------------------------------------------------------------------------------
N/A 08/11/2022 Jeremy Daniel     N/A    Initial Release
001 08/31/2023 Michael Mayes     N/A    (TASK PENDING)Changes to allow patient state to also allow pats in; Empty file name
002 01/25/2024 Michael Mayes      344896 (SCTASK0066907) Adding result.
*************END OF ALL MODCONTROL BLOCKS* ************************************************************************************/
drop program 14_ecase_testing_48hr_pdc_va go
create program 14_ecase_testing_48hr_pdc_va

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

declare fileName      = vc
declare emptyfileName = vc   ;001

DECLARE dataDate = vc

SET dataDate = TRIM(FORMAT(CNVTDATETIME(curdate,curtime3),"mmddyyyyhhmm;;d"),3)

SET FILE_NAME       =  concat( "/cerner/d_p41/cust_output_2/doh_covid_results/md_elr_"
                             , format(cnvtdatetime(curdate,curtime3),"YYYYMMDDhhmmss;;Q")
                             , ".csv")
                             
;001->
SET EMPTY_FILE_NAME =  concat( "/cerner/d_p41/cust_output_2/doh_covid_results/no_data_md_elr_"
                             , format(cnvtdatetime(curdate,curtime3),"YYYYMMDDhhmmss;;Q")
                             , ".csv")
;001<-       

;set start_dt_tm = cnvtdatetime((curdate-1), 000000)
;set end_dt_tm =   cnvtdatetime((curdate-1), 235959)


;***** Set Print Record Structure
free record rs
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
        2 ACCESSION = VC
        2 Specimen = vc
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
        2 State_cd = vc
        2 Zip = vc
        2 Phone = vc
        2 Phone_cd = vc
        2 phone2 = vc
        2 phone2_cd = vc
        2 FAC_PHONE = VC
        2 fac_ZIP= vc
        2 fac_County = vc
        2 fac_City = vc
        2 fac_State = vc
        2 fac_StreetAddr = vc
        2 fac_StreetAddr2 = vc
        2 OrderOrgId = f8
        2 org_id = f8
        2 OrderNumber = vc
        2 OrderDesc = vc
        2 OrderDtTm = vc
        2 Order_PROVIDER = VC
        2 OrderDocName = vc
        2 OrderDocStreetAddr = vc
        2 OrderDocCityStateZip = vc
        2 OrderDocPhone = vc
        2 OrderStatus = vc
        2 AttendDocName = vc
        2 Specimen = vc
        2 specimenp = f8
        2 FacCd = vc
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
        2 Result_dttm = vc
        2 auth_flag = i2
        2 res_status = vc
        2 CMRN = VC
        2 pt_phone = vc
        2 onset_dt = vc
        2 NPI = VC
        2 oc_stat = vc
        2 clia = vc
        2 int_result = vc
        2 event_id = f8
        2 ORDER_DTTM = DQ8
        2 o_loinc = vc
        2 loinc = vc
        2 perform_addr = vc
        2 perform_addr2 = vc
        2 perform_city = vc
        2 perform_state = vc
        2 perform_zip = vc
        2 perform_county = vc
        2 symptoms = vc
        2 preg_ind = vc
        2 FIRST_TEST = vc
        2 occupation = vc
        2 reg_dt = dq8
        2 visit_reason = vc
        2 admit_from = f8
        2 ltc = vc
        2 LOCATION = vc
        2 facility = vc
        2 parent_entity_id = f8
        2 contributor = f8
        2 result_snow = vc
        2 event_cd = f8
        2 48hr_ind = i2
        2 date_diff = i4
        2 discharge_dttm = dq8
        2 action_event = vc
)


;****************************************************************************************************
;                               VARIABLE DECLARATIONS / EMAIL DEFINITIONS
;****************************************************************************************************
IF($TYPE = 3);EMAILING OF REPORT
    DECLARE EMAIL_SUBJECT = VC WITH NOCONSTANT(" ")
    SET EMAIL_SUBJECT = build2("Ecase Kick Out - 48 P-DC VA Results Report")
    DECLARE EMAIL_ADDRESSES = VC WITH NOCONSTANT("")
    DECLARE EMAIL_BODY = VC WITH NOCONSTANT("")
    DECLARE UNICODE = VC WITH NOCONSTANT("")
    DECLARE AIX_COMMAND   = VC WITH NOCONSTANT("")
    DECLARE AIX_CMDLEN    = I4 WITH NOCONSTANT(0)
    DECLARE AIX_CMDSTATUS = I4 WITH NOCONSTANT(0)
    DECLARE PRODUCTION_DOMAIN = vc with constant("P41");FOR TESTING ONLY

    Declare EMAIL_ADDRESS   = vc
    SET EMAIL_ADDRESS = $OUTDEV

    SET EMAIL_BODY = concat("ecase_ko_48hr-p-dc_va",
    format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"), ".dat")
 
    ;001->  Empty file name definition as and some refactoring.
    declare filename     = vc with  noconstant(concat( "ecase_ko_48hr-p-dc_va"
                                                     , format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q")
                                                     , trim(substring(3,3,cnvtstring(RAND(0)))) ;<<<< 3 random #s
                                                     , ".csv"
                                                     )
                                              )
    
    declare emptyfileName = vc with  noconstant(concat( 'no_data_'
                                                      , "ecase_ko_48hr-p-dc_va"
                                                      , format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q")
                                                      , trim(substring(3,3,cnvtstring(RAND(0)))) ;<<<< 3 random #s
                                                      , ".csv"
                                                      )
                                               )
    ;001<-

    IF ($TYPE = 3 and CURDOMAIN = PRODUCTION_DOMAIN)
        Select into (value(EMAIL_BODY))
    build2("The Ecase Kick Out - 48 P-DC VA Results report is attached to this email.",
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
;                               main select
;*****************************************************************************************************
    ;Build and prod have these results diff... so I'm going to hunt for it with the uar.
    declare poc_rap_covid_pcr_cd = f8 with protect,   constant(uar_get_code_by('DISPLAY_KEY', 72, 'POCRAPIDCOVID19PCR'))   ;002

    select into "nl:"

    from

    Person p
    , encounter e
    , clinical_event c3
    , organization org
    , organization_alias orga
    , ORDERS O
    , PERSON_ALIAS PA
    , phone ph
    , code_value_outbound cvo
    , code_value_outbound cvo2


    plan c3 where c3.event_cd in (

                    2258265897  ;CoVID19-SARS-CoV-2 by PCR
                    ,2254653289 ;COVID 19 (DH/CDC)
                    ,2259614555 ;COVID-19/Coronavirus RNA PCR
                    ,2258239523 ;COVID-19 (SARS-CoV-2, NAA)
                    ,2265151661 ;CoVID_19 (SARS-CoV2, NAA)
                    ,2258239523 ;COVID-19 (SARS-CoV-2, NAA)
                    ,2270692929 ;CoVID 19-SARS-CoV-2 Overall Result
                    ,2258265897 ;CoVID 19-SARS-CoV-2 by PCR
                    ,2270688963 ;CoVID 19-PAN-SARS-CoV-2 by PCR
                    ,2259601949 ;COVID19(SARS-CoV-2)
                    ,2276648185 ; NEW POC ORDER
                    ,2385455807 ;PCR Ag
                    ,2404008691 ;POC Ag
                    ,2435117743 ;COVID-19(SARS-CoV-2) Ag
                    ,poc_rap_covid_pcr_cd ;POC Rapid COVID-19 PCR ;003
        )

        AND C3.normalcy_cd = 201.00
        ;and c3.result_val != "Invalid"
        and c3.event_end_dt_tm > cnvtlookbehind("40,D")
        and c3.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
        and c3.event_class_cd in ( 236.00,224.00)
        and c3.valid_from_dt_tm between CNVTDATETIME($START_DT)AND CNVTDATETIME($END_DT)
        and c3.result_status_cd in (25,34,35)
        and c3.authentic_flag = 1
        ;and c3.contributor_system_cd  not in  (1038645461.00,  926194249.00);  EMRLINK_ADD/demo
        ;cnvtdatetime((curdate-1), 000000)and cnvtdatetime((curdate-1), 235959)

    JOIN O WHERE O.order_id = outerjoin(C3.order_id)

    join cvo where cvo.code_value = outerjoin(c3.event_cd) and cvo.contributor_source_cd = outerjoin(56496061.00)   ;LOINC

    join cvo2 where cvo2.code_value = outerjoin(o.catalog_cd) and cvo2.contributor_source_cd = outerjoin(56496061.00)   ;LOINC

    join e where e.encntr_id = c3.encntr_id; and e.contributor_system_cd not in  (1038645461.00,  926194249.00);    EMRLINK_ADD/demo
    and e.disch_dt_tm != null
    ;and e.disch_dt_tm < cnvtlookbehind("2,D")

    join org where org.organization_id = OUTERJOIN(e.organization_id)

    join orga where orga.organization_id = outerjoin(e.organization_id) and orga.org_alias_type_cd = outerjoin(653405.00);  CLIA

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
        and ph.phone_type_cd = outerjoin(170)   ;Home
        and ph.beg_effective_dt_tm < outerjoin(cnvtdatetime(curdate,curtime))
        and ph.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime))
        AND PH.parent_entity_name = outerjoin("PERSON")
        ;and ph.phone_format_cd = outerjoin(        874.00)

    order by C3.clinical_event_id

head report
    patients = 0

head C3.clinical_event_id


patients = patients + 1
STAT=ALTERLIST(RS->QUAL,PATIENTS)

    rs->QUAL[patients]->FirstName = p.name_first
    rs->QUAL[patients]->LastName = p.name_last
    ;rs->QUAL[patients]->AGE = CNVTAGE(P.birth_dt_tm)
    rs->QUAL[patients]->DOB = format(p.birth_dt_tm, "MM/DD/YYYY;;D")
    rs->QUAL[patients]->Gender = uar_get_code_display(p.sex_cd)
    rs->QUAL[patients]->ethnic_cd = UAR_GET_CODE_DISPLAY(P.ethnic_grp_cd)
    rs->QUAL[patients]->Race = uar_get_code_display(p.race_cd)
    rs->QUAL[patients]->PersonId = c3.person_id
    rs->QUAL[patients]->EncntrId = c3.encntr_id
    rs->QUAL[patients]->OrderId = c3.order_id
    rs->QUAL[patients]->Order_DTTM = O.orig_order_dt_tm
    rs->QUAL[patients]->loinc = cvo.alias
    rs->QUAL[patients]->o_loinc = cvo2.alias
    rs->QUAL[patients]->clinical_evt_id = c3.clinical_event_id
    rs->QUAL[patients]->OrderDesc = uar_get_code_display(c3.event_cd)
    rs->QUAL[patients]->event_cd = c3.event_cd
    rs->QUAL[patients]->auth_flag = c3.authentic_flag
    rs->QUAL[patients]->res_status = uar_get_code_display(c3.result_status_cd)
    rs->QUAL[patients]->ACCESSION = C3.accession_nbr
    rs->QUAL[patients]->ethnic_cd = UAR_GET_CODE_DISPLAY(P.ethnic_grp_cd)
    rs->QUAL[patients]->CMRN = PA.alias
    rs->QUAL[patients]->ORG_ID = E.organization_id
    rs->QUAL[patients]->pt_phone = ph.phone_num_key
    rs->QUAL[patients]->event_id = c3.event_id
    rs->QUAL[patients]->location = uar_get_code_display(e.location_cd)
    rs->QUAL[patients]->facility = uar_get_code_display(e.loc_facility_cd)
;   RS->QUAL[patients]->symptoms = "UNK"
;   RS->QUAL[patients]->preg_ind = "UNK"
;   RS->QUAL[patients]->oc_stat = "UNK"
    ;rs->QUAL[patients]->service_resource = uar_get_code_display(c3.resource_cd)
    rs->QUAL[patients]->OrderingCLIA = orga.alias
    rs->QUAL[patients]->contributor = c3.contributor_system_cd

    rs->QUAL[patients]->date_diff = datetimediff(c3.valid_from_dt_tm,e.disch_dt_tm,1)

    if (datetimediff(c3.valid_from_dt_tm,e.disch_dt_tm,1) > 1)
    rs->QUAL[patients].48hr_ind = 1
    endif

    if(rs->qual[patients].ACCESSION = " ")
        rs->qual[patients].ACCESSION = cnvtstring(c3.order_id)
        endif

    if(rs->QUAL[patients]->Race in ( "*ZZ*","*Hispanic/Spanish*","*Unknown*"))
    rs->QUAL[patients]->Race = " "
    endif

    if(rs->QUAL[patients]->Race in ( "*Non Hispanic*","*Multiple*","*Declined to Answer*"))
    rs->QUAL[patients]->Race = " "
    endif

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
                                    ,13500062
                                    ,13497282
                                    ,13497021
                                    ,13500524
                                    ,13498999
                                    ))
        rs->QUAL[patients]->oc_stat = "Y"
        endif

    if(rs->QUAL[patients]->Gender = "Female")
    rs->QUAL[patients]->Gender = "F"
    elseif (rs->QUAL[patients]->Gender = "Male")
    rs->QUAL[patients]->Gender = "M"
    else rs->QUAL[patients]->Gender = "U"
    endif

    if(rs->QUAL[patients]->ACCESSION != null)

    if (rs->QUAL[patients]->org_id = 628085)
    rs->QUAL[patients]->clia  = "09D0207566"
    elseif(rs->QUAL[patients]->org_id = 628088)
    rs->QUAL[patients]->clia  = "09D0208070"
    elseif(rs->QUAL[patients]->org_id = 627889)
    rs->QUAL[patients]->clia  = "21D0219647"
    elseif(rs->QUAL[patients]->org_id = 589723)
    rs->QUAL[patients]->clia  = "21D0219549"
    elseif(rs->QUAL[patients]->org_id = 628009)
    rs->QUAL[patients]->clia  = "21D0219268"
    elseif(rs->QUAL[patients]->org_id = 628058)
    rs->QUAL[patients]->clia  = "21D0693562"
    elseif(rs->QUAL[patients]->org_id = 3837372)
    rs->QUAL[patients]->clia  = "21D0210256"
    elseif(rs->QUAL[patients]->org_id = 3763758)
    rs->QUAL[patients]->clia  = "21D0212005"
    elseif(rs->QUAL[patients]->org_id = 3440653)
    rs->QUAL[patients]->clia  = "21D0705218"
    endif

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
        rs->QUAL[patients]->ethnic_cd = "H"
        elseif(rs->QUAL[patients]->ethnic_cd = "Non-Hispanic")
        rs->QUAL[patients]->ethnic_cd = "N"
        elseif(rs->QUAL[patients]->ethnic_cd = "Unknown")
        rs->QUAL[patients]->ethnic_cd = "U"
        else
        rs->QUAL[patients]->ethnic_cd = " "
        endif

        if(rs->QUAL[patients]->Race = "*ZZZ*")
        rs->QUAL[patients]->Race = " "
        endif

        if(rs->QUAL[patients]->event_cd =  2404008691.00)
        rs->QUAL[patients]->OrderDesc = "POC Rapid COVID-19 Screen_BD_Antigen"
        endif

        if(rs->QUAL[patients]->event_cd =   2276648185.00)
        rs->QUAL[patients]->OrderDesc = "Abbott ID NOW Molecular"
        endif


with nocounter, time = 1000;, ORAHINTCBO("INDEX( E XIE17ENCOUNTER)")

IF (SIZE (RS->QUAL,5)=0)
go to EXITPROGRAM
ENDIF
/**************************************************************************************
                results
****************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
    , CLINICAL_EVENT C
    , encounter e
    , organization org
    , long_blob lb
    , ce_event_note cen
    , order_comment ocm
    , long_text lt
    , organization_alias orga
    , address a


PLAN d
JOIN c where c.clinical_event_id = rs->qual[d.seq].clinical_evt_id

and c.event_cd in (

            2259601949  ;COVID19(SARS-CoV-2) ;Respiratory Virus Pnl PCR
    )

and c.event_end_dt_tm  > CNVTDATETIME(CNVTDATE( 04072020), 0700)

;join o where o.order_id = outerjoin(c.order_id)

join cen where cen.event_id = outerjoin(c.event_id)

join ocm where ocm.order_id = outerjoin(c.order_id)

join lt where lt.long_text_id = outerjoin(ocm.long_text_id)
    and lt.active_ind = outerjoin(1)
    ;and cnvtupper(lt.parent_entity_name)= outerjoin ("RESULT_COMMENT" )

join lb
    where lb.parent_entity_id = outerjoin(cen.ce_event_note_id)

join e where e.encntr_id = outerjoin(c.encntr_id)

join org where org.organization_id = OUTERJOIN(e.organization_id)

join orga where orga.organization_id = outerjoin(org.organization_id) and orga.org_alias_type_cd = outerjoin(653405.00);    CLIA

join a where a.parent_entity_id = outerjoin(org.organization_id)
    and a.active_ind = outerjoin(1)
    and a.end_effective_dt_tm > outerjoin(cnvtdatetime(sysdate))
    and a.address_type_cd = outerjoin(754.00)



order by d.seq

head d.seq

    rs->QUAL[d.seq]->PerformDtTm = format(c.performed_dt_tm, "MM/DD/YYYY;;D")
    rs->QUAL[d.seq]->SpecimenP = c.event_cd
    rs->QUAL[d.seq]->event = uar_get_code_display(c.event_cd)
    rs->QUAL[d.seq]->CollectionDtTm = format(c.event_end_dt_tm, "MM/DD/YYYY;;D")
    rs->QUAL[d.seq]->Result = cnvtupper(c.result_val);c.result_val;uar_get_code_description(mrr.response_cd)
    rs->QUAL[d.seq]->ResultUnit = uar_get_code_display(c.result_units_cd)
    rs->QUAL[d.seq]->RESULT_DTTM = format(C.valid_from_dt_tm, "MM/DD/YYYY;;D")
    rs->QUAL[d.seq]->service_resource = uar_get_code_display(c.resource_cd)


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
                            trim(substring(1,2000,blobnortf)),char(10),""),char(13),"") ;.blob1

                    blobnortf = performloc


                endif
                fndStrng = findstring("Performing location:",rs->QUAL[d.seq]->ResultCmt,0);
                if (fndStrng > 0)
                rs->QUAL[d.seq]->Perform_location = ;rs->QUAL[PATIENTS]->ResultCmt
                  substring(20 + fndStrng,255,rs->QUAL[d.seq]->ResultCmt)
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

            if (rs->QUAL[d.seq]->org_id = 628085)
            rs->QUAL[d.seq]->PerformingCLIA  = "09D0207566"
            elseif(rs->QUAL[d.seq]->org_id = 628088)
            rs->QUAL[d.seq]->PerformingCLIA  = "09D0208070"
            elseif(rs->QUAL[d.seq]->org_id = 627889)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0219647"
            elseif(rs->QUAL[d.seq]->org_id = 589723)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0219549"
            elseif(rs->QUAL[d.seq]->org_id = 628009)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0219268"
            elseif(rs->QUAL[d.seq]->org_id = 628058)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0693562"
            elseif(rs->QUAL[d.seq]->org_id = 3837372)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0210256"
            elseif(rs->QUAL[d.seq]->org_id = 3763758)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0212005"
            elseif(rs->QUAL[d.seq]->org_id = 3440653)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0705218"
            endif
        endif

        if(rs->qual[d.seq].service_resource = "*WHC*")
        rs->QUAL[d.seq]->PerformingCLIA  = "09D0208070"
        rs->QUAL[d.seq]->Perform_location = "Washington Hospital Center"
        rs->QUAL[d.seq]->perform_zip = "20010"
        elseif(rs->qual[d.seq].service_resource = "*UMH*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0693562"
        rs->QUAL[d.seq]->Perform_location = "Union Memorial Hospital"
        rs->QUAL[d.seq]->perform_zip = "21218"
        elseif(rs->qual[d.seq].service_resource = "*GUH*")
        rs->QUAL[d.seq]->PerformingCLIA  = "09D0207566"
        rs->QUAL[d.seq]->Perform_location = "Georgetown University Hospital"
        rs->QUAL[d.seq]->perform_zip = "20007"
        elseif(rs->qual[d.seq].service_resource = "*FSH*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0219549"
        rs->QUAL[d.seq]->Perform_location = "Franklin Square Hospital Center"
        rs->QUAL[d.seq]->perform_zip = "21237"
        elseif(rs->qual[d.seq].service_resource = "*SMD*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0210256"
        rs->QUAL[d.seq]->Perform_location = "Medstar Southern Maryland Hospital Center"
        rs->QUAL[d.seq]->perform_zip = "20735"
        elseif(rs->qual[d.seq].service_resource = "*HBR*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0219268"
        rs->QUAL[d.seq]->Perform_location = "Harbor Hospital Center"
        rs->QUAL[d.seq]->perform_zip = "21225"
        elseif(rs->qual[d.seq].service_resource = "*MMC*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0212005"
        rs->QUAL[d.seq]->Perform_location = "MedStar Montgomery Medical Center"
        rs->QUAL[d.seq]->perform_zip = "20832"
        elseif(rs->qual[d.seq].service_resource = "*GSH*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0219647"
        rs->QUAL[d.seq]->Perform_location = "Good Samaritan Hospital"
        rs->QUAL[d.seq]->perform_zip = "21239"
        elseif(rs->qual[d.seq].service_resource = "*SMH*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0705218"
        rs->QUAL[d.seq]->Perform_location = "MedStar St Marys Hospital"
        rs->QUAL[d.seq]->perform_zip = "20650"
        endif
 ;start 002
         if(rs->QUAL[d.seq]->Result IN( "Detected","DETECTED"))
            rs->QUAL[d.seq]->result_snow =  "260373001";    Detected
            elseif(rs->QUAL[d.seq]->Result = "Inconclusive")
            rs->QUAL[d.seq]->result_snow = "419984006"; Inconclusive
            elseif(rs->QUAL[d.seq]->Result = "Indeterminate")
            rs->QUAL[d.seq]->result_snow = "82334004";  Indeterminate
            elseif(rs->QUAL[d.seq]->Result = "Invalid")
            rs->QUAL[d.seq]->result_snow = "455371000124106";   Invalid
            elseif(rs->QUAL[d.seq]->Result IN ("Negative","NEGATIVE"))
            rs->QUAL[d.seq]->result_snow = "260385009"; Negative
            elseif(rs->QUAL[d.seq]->Result = "Non-Reactive")
            rs->QUAL[d.seq]->result_snow = "131194007"; Non-Reactive
            elseif(rs->QUAL[d.seq]->Result in ("Not detected","Not Detected","NOT DETECTED"))
            rs->QUAL[d.seq]->result_snow = "260415000"; Not detected
            elseif(rs->QUAL[d.seq]->Result IN ( "Positive","POSITIVE"))
            rs->QUAL[d.seq]->result_snow = "10828004";  Positive
            elseif(rs->QUAL[d.seq]->Result = "Reactive")
            rs->QUAL[d.seq]->result_snow = "11214006";  Reactive
            elseif(rs->QUAL[d.seq]->Result = "Specimen unsatisfactory")
            rs->QUAL[d.seq]->result_snow = "125154007"; Specimen unsatisfactory
        endif
 ;end 002
with nocounter, time = 300

/**************************************************************************************
                ;results
***************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
    , CLINICAL_EVENT C
    , encounter e
    , organization org
    , long_blob lb
    , ce_event_note cen
    , order_comment ocm
    , long_text lt
    , ce_blob  cb
    , organization_alias orga
    , address a




PLAN d
JOIN c where c.clinical_event_id = rs->qual[d.seq].clinical_evt_id

and c.event_cd in (
                ;   2258261423  ;CoVID19-SARS-CoV-2 Source
                2258265897  ;CoVID19-SARS-CoV-2 by PCR
                ,2254653289 ;COVID 19 (DH/CDC)
                ,2259614555 ;COVID-19/Coronavirus RNA PCR
                ,2258239523 ;COVID-19 (SARS-CoV-2, NAA)
                ,2265151661 ;CoVID_19 (SARS-CoV2, NAA)
                ,2258239523 ;COVID-19 (SARS-CoV-2, NAA)
                ,2270692929 ;CoVID 19-SARS-CoV-2 Overall Result
                ,2258265897 ;CoVID 19-SARS-CoV-2 by PCR
                ,2270688963 ;CoVID 19-PAN-SARS-CoV-2 by PCR

                ,2276648185 ; NEW POC ORDER
                ;,2274006443 ; OCC HEALTH
                    ,2282064783
                    ,2287776717
                    ,2290710033
                    ,2290710049
                    ,2290713753
                    ,2290713803
                    ,2290718387
                    ,2291914727
                    ;,2291907909 ;interp causing line break Ag
                    ,2385455807 ; PCR Ag
                    ,2404008691 ;POC Ag
                    ,2435117743 ;COVID-19(SARS-CoV-2) Ag
                    ,poc_rap_covid_pcr_cd ;POC Rapid COVID-19 PCR ;003


    )
    ;and c.result_val in ("Positive", "Negative", "Not Detected", "Detected", "POSITIVE","NEGATIVE", "DETECTED", "NOT DETECTED")

;join o where o.order_id = outerjoin(c.order_id)

join cen where cen.event_id = outerjoin(c.event_id)

join ocm where ocm.order_id = outerjoin(c.order_id)

join lt where lt.long_text_id = outerjoin(ocm.long_text_id)
    and lt.active_ind = outerjoin(1)
    ;and cnvtupper(lt.parent_entity_name)= outerjoin ("RESULT_COMMENT" )

join lb
    where lb.parent_entity_id = outerjoin(cen.ce_event_note_id)

join e where e.encntr_id = outerjoin(c.encntr_id)

join org where org.organization_id = OUTERJOIN(e.organization_id)

join orga where orga.organization_id = outerjoin(org.organization_id) and orga.org_alias_type_cd = outerjoin(653405.00);    CLIA

join cb where cb.event_id = outerjoin(c.event_id)

join a where a.parent_entity_id = outerjoin(org.organization_id)
    and a.active_ind = outerjoin(1)
    and a.end_effective_dt_tm > outerjoin(cnvtdatetime(sysdate))
    and a.address_type_cd = outerjoin(754.00)

order by d.seq

head d.seq

    rs->QUAL[d.seq]->PerformDtTm = format(c.performed_dt_tm, "MM/DD/YYYY;;D")
    rs->QUAL[d.seq]->SpecimenP = c.event_cd
    rs->QUAL[d.seq]->event = uar_get_code_display(c.event_cd)
    rs->QUAL[d.seq]->CollectionDtTm = format(c.event_end_dt_tm, "MM/DD/YYYY;;D")
    rs->QUAL[d.seq]->Result = replace(replace(replace(
                            trim(substring(1,2000,cnvtupper(c.result_val))),char(10),""),char(13),""),char(44),"") ;.blob1;uar_get_code_description(mrr.response_cd)
    rs->QUAL[d.seq]->ResultUnit = uar_get_code_display(c.result_units_cd)
    rs->QUAL[d.seq]->Result_dttm = format(C.valid_from_dt_tm, "MM/DD/YYYY hh:mm:ss;;D")
    rs->QUAL[d.seq]->service_resource = uar_get_code_display(c.resource_cd)


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

                    rs->QUAL[d.seq].Resultcmt = replace(replace(
                            trim(substring(1,2500,blobnortf)),char(10),""),char(13),"") ;.blob1

                    blobnortf = performloc


                endif
                fndStrng = findstring("Performing location:",rs->QUAL[d.seq]->ResultCmt,0);
                if (fndStrng > 0)
                rs->QUAL[d.seq]->Perform_location = ;rs->QUAL[PATIENTS]->ResultCmt
                  substring(20 + fndStrng,255,rs->QUAL[d.seq]->ResultCmt)
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

            if (rs->QUAL[d.seq]->org_id = 628085)
            rs->QUAL[d.seq]->PerformingCLIA  = "09D0207566"
            elseif(rs->QUAL[d.seq]->org_id = 628088)
            rs->QUAL[d.seq]->PerformingCLIA  = "09D0208070"
            elseif(rs->QUAL[d.seq]->org_id = 627889)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0219647"
            elseif(rs->QUAL[d.seq]->org_id = 589723)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0219549"
            elseif(rs->QUAL[d.seq]->org_id = 628009)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0219268"
            elseif(rs->QUAL[d.seq]->org_id = 628058)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0693562"
            elseif(rs->QUAL[d.seq]->org_id = 3837372)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0210256"
            elseif(rs->QUAL[d.seq]->org_id = 3763758)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0212005"
            elseif(rs->QUAL[d.seq]->org_id = 3440653)
            rs->QUAL[d.seq]->PerformingCLIA  = "21D0705218"
            endif
        endif

            if(c.event_cd = 2276648185)
            rs->qual[d.seq].ACCESSION = cnvtstring(c.order_id)
            rs->QUAL[d.seq]->Specimen = "NP Swab"
            rs->QUAL[d.seq]->service_resource = "POC Abbot ID NOW_Abbott_DIT"
            rs->QUAL[d.seq]->o_loinc = "94534-5"
            endif

        if(c.event_cd = 2404008691)
        rs->qual[d.seq].ACCESSION = cnvtstring(c.order_id)
        rs->QUAL[d.seq]->Specimen = "Mid-Turbinate(upper nasal)"
        rs->QUAL[d.seq]->service_resource = "BD Veritor Plus"
        rs->QUAL[d.seq]->o_loinc = "94558-4"

        if(rs->qual[d.seq].ACCESSION = "0")
        rs->qual[d.seq].ACCESSION = cnvtstring(c.event_id)
        endif
        endif

        if(rs->qual[d.seq].service_resource = "*WHC*")
        rs->QUAL[d.seq]->PerformingCLIA  = "09D0208070"
        rs->QUAL[d.seq]->Perform_location = "Washington Hospital Center"
        rs->QUAL[d.seq]->perform_zip = "20010"
        elseif(rs->qual[d.seq].service_resource = "*UMH*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0693562"
        rs->QUAL[d.seq]->Perform_location = "Union Memorial Hospital"
        rs->QUAL[d.seq]->perform_zip = "21218"
        elseif(rs->qual[d.seq].service_resource = "*GUH*")
        rs->QUAL[d.seq]->PerformingCLIA  = "09D0207566"
        rs->QUAL[d.seq]->Perform_location = "Georgetown University Hospital"
        rs->QUAL[d.seq]->perform_zip = "20007"
        elseif(rs->qual[d.seq].service_resource = "*FSH*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0219549"
        rs->QUAL[d.seq]->Perform_location = "Franklin Square Hospital Center"
        rs->QUAL[d.seq]->perform_zip = "21237"
        elseif(rs->qual[d.seq].service_resource = "*SMD*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0210256"
        rs->QUAL[d.seq]->Perform_location = "Medstar Southern Maryland Hospital Center"
        rs->QUAL[d.seq]->perform_zip = "20735"
        elseif(rs->qual[d.seq].service_resource = "*HBR*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0219268"
        rs->QUAL[d.seq]->Perform_location = "Harbor Hospital Center"
        rs->QUAL[d.seq]->perform_zip = "21225"
        elseif(rs->qual[d.seq].service_resource = "*MMC*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0212005"
        rs->QUAL[d.seq]->Perform_location = "MedStar Montgomery Medical Center"
        rs->QUAL[d.seq]->perform_zip = "20832"
        elseif(rs->qual[d.seq].service_resource = "*GSH*")
        rs->QUAL[d.seq]->PerformingCLIA  = "21D0219647"
        rs->QUAL[d.seq]->Perform_location = "Good Samaritan Hospital"
        rs->QUAL[d.seq]->perform_zip = "21239"
        endif
 ;start 002
         if(rs->QUAL[d.seq]->Result IN( "Detected","DETECTED"))
            rs->QUAL[d.seq]->result_snow =  "260373001";    Detected
            elseif(rs->QUAL[d.seq]->Result = "Inconclusive")
            rs->QUAL[d.seq]->result_snow = "419984006"; Inconclusive
            elseif(rs->QUAL[d.seq]->Result = "Indeterminate")
            rs->QUAL[d.seq]->result_snow = "82334004";  Indeterminate
            elseif(rs->QUAL[d.seq]->Result = "Invalid")
            rs->QUAL[d.seq]->result_snow = "455371000124106";   Invalid
            elseif(rs->QUAL[d.seq]->Result IN ("Negative","NEGATIVE"))
            rs->QUAL[d.seq]->result_snow = "260385009"; Negative
            elseif(rs->QUAL[d.seq]->Result = "Non-Reactive")
            rs->QUAL[d.seq]->result_snow = "131194007"; Non-Reactive
            elseif(rs->QUAL[d.seq]->Result in ("Not detected","Not Detected","NOT DETECTED"))
            rs->QUAL[d.seq]->result_snow = "260415000"; Not detected
            elseif(rs->QUAL[d.seq]->Result IN ( "Positive","POSITIVE"))
            rs->QUAL[d.seq]->result_snow = "10828004";  Positive
            elseif(rs->QUAL[d.seq]->Result = "Reactive")
            rs->QUAL[d.seq]->result_snow = "11214006";  Reactive
            elseif(rs->QUAL[d.seq]->Result = "Specimen unsatisfactory")
            rs->QUAL[d.seq]->result_snow = "125154007"; Specimen unsatisfactory
        endif
 ;end 002
with nocounter, time = 500

 ;------------------------------------------------------------------------------------------
;Additional Detail
;-------------------------------------------------------------------------------------------

    for(cnt=1 to size(rs->qual,5))
        if(rs->qual[cnt].event_id > 0)
            set rs->qual[cnt].int_result = subroutine_get_blob(rs->qual[cnt].event_id)
        endif
    endfor

;/*************************************************************************************
;                   GETTING encounter info
;**************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))

        ,encounter e
        ,organization org
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

    ;join e where e.encntr_id = outerjoin(ea.encntr_id)

;order by d.seq

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
    RS->QUAL[d.seq].discharge_dttm = e.disch_dt_tm

 ;  if(RS->QUAL[d.seq].admit_from in(5070292.00,    5044615.00 ,    309193.00))
;   RS->QUAL[d.seq].jail = "Y"

    if (RS->QUAL[d.seq].admit_from in(423346946.00, 1692366029.00, 5070292.00, 56494552.00, 4190886.00))
    RS->QUAL[d.seq].ltc = "Y"
    elseif(RS->QUAL[d.seq].admit_from in( 5070300
                                            ,5070300
                                            ,309198
                                            ,1992515983
                                            ,309200
                                            ,5070288
                                            ,1692372825
                                            ))
    RS->QUAL[d.seq].ltc = "UNK"
    elseif(RS->QUAL[d.seq].admit_from in(
        5047147.00
    ))
    RS->QUAL[d.seq].ltc = "N"
    endif

with nocounter, time = 400

;;/**************************************************************************************
;;                  GETTING LTC powerform results
;;****************************************************************************************/
;Select into "nl:"
;
;FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
;,clinical_event ce
;
;PLAN D
;
;JOIN ce where ce.encntr_id = rs->qual[d.seq].EncntrId
;and ce.event_cd in (823735959.00)
;
;detail
;
;if(ce.result_val in("Nursing home","Assisted living"))
;
;RS->QUAL[d.seq].ltc = "Y"
;
;endif
;
;with nocounter, format, time = 500
;;/*******************************************************************************************
;;                  GETTING order info
;;********************************************************************************************/
;Select into "nl:"
;FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
;       ,orders o
;       ,order_action oa
;       ,prsnl pr
;       ,prsnl_alias pra
;
;PLAN d
;
;   join o where o.order_id = rs->qual[d.seq].orderid
;
;   join oa where oa.order_id = o.order_id
;
;   join pr where pr.person_id = oa.order_provider_id
;
;   join pra where pra.person_id = pr.person_id and pra.prsnl_alias_type_cd = 4038127.00 ;npi
;
;
;order by d.seq
;
;detail
;
;rs->QUAL[d.seq].Order_PROVIDER = concat(trim(pr.name_last) ,", ", trim(pr.name_first))
;rs->QUAL[d.seq].npi = replace(replace(
;                           trim(substring(1,200,pra.alias)),char(10),""),char(13),"")
;
;if(rs->QUAL[d.seq].Order_PROVIDER = "*Unassigned*")
;rs->QUAL[d.seq].Order_PROVIDER = " "
;endif
;
;with nocounter, time = 300
;;/**************************************************************************************
;;                  GETTING future order info
;;***************************************************************************************/
;;Select into "nl:"
;;FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
;;      ,orders o
;;      ,encounter e
;;      ;,cust_future_order_info cfoi
;;      ,organization org
;;      ,encntr_alias   ea
;;      ,encntr_alias   ea2
;;
;;PLAN d
;;
;;  join o where o.order_id = rs->qual[d.seq].orderid
;;
;;  ;join cfoi where cfoi.order_id = o.order_id
;;
;;  join e WHERE e.encntr_id = o.originating_encntr_id
;;
;;  join org where org.organization_id = e.organization_id
;;
;;  join ea where ea.encntr_id = outerjoin(e.encntr_id);)
;;    AND EA.encntr_alias_type_cd = outerjoin(1077.00); FIN
;;    AND EA.active_ind = outerjoin(1)
;;
;;  join ea2 where ea2.encntr_id =outerjoin(e.encntr_id)
;;    AND EA2.encntr_alias_type_cd = outerjoin(1079.00); MRN
;;    AND EA2.active_ind = outerjoin(1)
;;
;;order by d.seq
;
;;detail
;;
;;rs->QUAL[d.seq].ENCNTR_ID_2 = e.encntr_id
;;rs->QUAL[d.seq].REG_DT_TM_2 = e.reg_dt_tm
;;rs->QUAL[d.seq].disch_dt_tm_2 = e.disch_dt_tm
;;rs->QUAL[d.seq].ENCNTR_TYPE_2 = UAR_GET_CODE_DISPLAY(E.encntr_type_cd)
;;rs->QUAL[d.seq].nurse_unit_2 = uar_get_code_display(e.loc_nurse_unit_cd)
;;rs->QUAL[d.seq].ORG_ID_2 = org.organization_id
;;rs->QUAL[d.seq].FIN_2 = ea.alias
;;rs->QUAL[d.seq].MRN_2 = eA2.ALIAS
;;rs->QUAL[d.seq].hospital_cd_2 = org.org_name
;;
;;
;;with nocounter, time = 1200
;;;;/*************************************************************************************
;;;;                    GETTING order info
;;;;**************************************************************************************/
;;Select into "nl:"
;;FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
;;      ,orders o
;;      ,order_detail od
;;PLAN d
;; join o where o.order_id = rs->qual[d.seq].OrderId
;;join od where od.order_id = outerjoin(o.order_id)
;;and od.oe_field_id = outerjoin(830572167.00);performing location
;;
;;order by d.seq
;;
;;detail
;;
;;    rs->QUAL[d.seq]->OrderDtTm = format(o.orig_order_dt_tm, "MM/DD/YYYY hh:mm:ss;;D")
;;    rs->QUAL[d.seq]->OrderDesc = trim(o.hna_order_mnemonic)
;;    rs->QUAL[d.seq]->OrderStatus = uar_get_code_display(o.order_status_cd)
;;
;;with nocounter, time = 100
;;/********************************************************************************************
;;                  GETTING SPECIMEN info
;;*********************************************************************************************/
;Select into "nl:"
;FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
;   ,order_detail od
;
; plan d
;
;join od where od.order_id = rs->qual[d.seq].OrderId
;and od.oe_field_id =       12584.00
;detail
;
;rs->QUAL[d.seq].Specimen = OD.oe_field_display_value
;
;
;with nocounter, time = 200

;/************************************************************************************
;                   GETTING pt address
;*************************************************************************************/
Select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
        ,ADDRESS A
PLAN d

    join A WHERE A.parent_entity_id = rs->qual[d.seq].PERSONID
    AND A.address_type_cd = 756.00  ;Home
    and a.active_ind = 1
    and a.end_effective_dt_tm > cnvtdatetime(sysdate)

order by d.seq

detail
rs->QUAL[D.SEQ].Zip = A.zipcode
rs->QUAL[D.SEQ].County = UAR_GET_CODE_DISPLAY(A.county_cd)
rs->QUAL[D.SEQ].City = A.CITY
rs->QUAL[D.SEQ].State_cd = A.state
RS->QUAL[D.SEQ].StreetAddr = A.street_addr
RS->QUAL[D.SEQ].StreetAddr2 = A.street_addr2

If(rs->QUAL[D.SEQ].County = "Virginia")
rs->QUAL[D.SEQ].County = " "
endif
with nocounter, time = 500
;;/********************************************************************************************
;;                  GETTING zip OF ORG
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
    ;AND PH.parent_entity_name = "ORGANIZATION"

order by d.seq

detail
rs->QUAL[D.SEQ].parent_entity_id = a.parent_entity_id
rs->QUAL[D.SEQ].FAC_PHONE = PH.phone_num_key
rs->QUAL[D.SEQ].fac_ZIP= A.zipcode
rs->QUAL[D.SEQ].fac_County = A.county
rs->QUAL[D.SEQ].fac_City = A.CITY
rs->QUAL[D.SEQ].fac_State = A.state
RS->QUAL[D.SEQ].fac_StreetAddr = A.street_addr
RS->QUAL[D.SEQ].fac_StreetAddr2 = A.street_addr2

If(rs->QUAL[D.SEQ].parent_entity_id in(
      589723.00 ;Franklin Square Hospital Center
,      628085.00    ;Georgetown University Hospital
,      627889.00    ;Good Samaritan Hospital
,      628009.00    ;Harbor Hospital Center
,     3763758.00    ;MedStar Montgomery Medical Center
,     3440653.00    ;MedStar St Mary's Hospital
,     3837372.00    ;Medstar Southern Maryland Hospital Center
,      628738.00    ;National Rehabilitation Hospital
,      628058.00    ;Union Memorial Hospital
,      628088.00    ;Washington Hospital Center
)or RS->QUAL[D.SEQ].fac_StreetAddr2 = "Hospital:*"
or RS->QUAL[D.SEQ].fac_StreetAddr2 = "202-*")

RS->QUAL[D.SEQ].fac_StreetAddr2 = " "
endif

with nocounter, time = 500

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

;;;/********************************************************************************************
;;;                     GETTING diagnosis of pt
;;;*********************************************************************************************/
;
;
;;Select into "nl:"
;;FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
;;      ,diagnosis      dX
;;      ,nomenclature   n
;;
;;
;; PLAN D1
;; JOIN DX WHERE dX.encntr_id = rs->qual[d1.seq].EncntrId
;;                 AND DX.diagnosis_id != 0.00
;;                AND DX.confirmation_status_cd in( 3305.00,674227.00) ;CONFIRMED, complaint of
;;                AND DX.active_status_cd =         188.00
;;                AND DX.END_EFFECTIVE_DT_TM > cnvtdatetime(curdate,curtime3)
;; join n where n.nomenclature_id = DX.nomenclature_id
;;          AND N.active_ind = 1
;;      AND N.active_status_cd = 188 ; ACTIVE
;;      and n.source_identifier_keycap in (
;;                              "R05"  ;Cough
;;                              ,"J02.9" ;Acute pharyngitis
;;                              ,"J06.9" ;Acute respiratory disease
;;                              ,"J18.9" ;PNEUMONIA
;;                              ,"J11.1" ;Sore throat with influenza
;;                              ,"R50.9" ;Fever  or fever wilt chills
;;                              ,"R68.83" ;Chills without fever
;;                              ,"J34.89" ;Rhinorrhea
;;                              ,"R06.02" ;Shortness of breath
;;                              ,"R06.03" ;Acute respiratory distress
;;                              ,"5A1935Z" ;Mechanical Vent less than 24 consecutive hours
;;                              ,"5A1945Z" ;Mechanical Vent 24 - 96 consecutive hours
;;                              ,"5A1955Z" ;Mechanical Vent greater than 96 Consecutive hours
;;                              ,"R51" ; HEADACHE
;;                              ,"R68.83" ; CHILLS
;;                              ,"R09.81";CONGESTION
;;                              ,"R68.89" ;COLD SWEAT
;;                              ,"R63.0" ;LOSS APPETITE
;;                              ,"R43.2" ;LOSS TASTE
;;                              ,"R43.0" ;LOSS SMELL
;;                              ,"R19.7" ;DIARRHEA
;;                              ,"M79.10" ;MUSCLE ACHE
;;                              ,"M25.50" ;JOINT PAIN
;;                              ,"M43.6" ;NECK STIFFNESS
;;                              ,"R22.1" ;SWOLLEN NECK
;;                              ,"R53.1" ;WEAKNESS
;;                              ,"T14.8XXA" ;BRUISING
;;                              ,"R58" ;BLEEDING
;;                              ,"H10.029" ;PINKEYE
;;                              ,"R17" ;JAUNDICE
;;                              ,"R21" ;RASH
;;                              ,"R11.10" ;VOMITING
;;                              ,"R11.0" ;NAUSEA
;;                              ,"J96.90" ;RESPIRATORY FAILURE
;;                              ,"J96.91" ;RESPIRATORY FAILURE w hypoxia
;;                              ,"J96.00" ;RESPIRATORY FAILURE,acute
;;                                          )
;;
;;detail
;;
;;RS->QUAL[D1.SEQ].symptoms = "Y"
;;
;;;if(RS->QUAL[D1.SEQ].symptoms != "Y")
;;;RS->QUAL[D1.SEQ].symptoms = "N"
;;;endif
;;
;;; if(n.source_identifier_keycap = "R05")
;;; RS->QUAL[D1.SEQ].cough_cd2 = "Y"
;;; elseif(n.source_identifier_keycap = "J02.9")
;;;     RS->QUAL[D1.SEQ].sore_throat_cd2 = "Y"
;;;     elseif(n.source_identifier_keycap = "J11.1")
;;;     RS->QUAL[D1.SEQ].st_flu_cd2 = "Y"
;;;     elseif(n.source_identifier_keycap = "R50.9")
;;;     RS->QUAL[D1.SEQ].fever_cd2 = "Y"
;;;     elseif(n.source_identifier_keycap = "R68.83")
;;;     RS->QUAL[D1.SEQ].RHINO_cd = "Y"
;;;     elseif(n.source_identifier_keycap = "R06.02")
;;;     RS->QUAL[D1.SEQ].SOB_cd = "Y"
;;;     elseif(n.source_identifier_keycap = "R06.03")
;;;     RS->QUAL[D1.SEQ].ARD_cd = "Y"
;;;     elseif(n.source_identifier_keycap = "J18.9")
;;;     RS->QUAL[D1.SEQ].PNEUMONIA = "Y"
;;;     elseif(n.source_identifier_keycap = "J06.9")
;;;     RS->QUAL[D1.SEQ].acute_resp_disease = "Y"
;;;     elseif(n.source_identifier_keycap in ("5A1945Z","5A1935Z","5A1955Z"))
;;;     RS->QUAL[D1.SEQ].VENT = "Y"
;;;
;;;     elseif(n.source_identifier_keycap in ("R51"))
;;;     RS->QUAL[D1.SEQ].headache = "Y"
;;;     elseif(n.source_identifier_keycap in ("R68.83"))
;;;     RS->QUAL[D1.SEQ].CHILLS = "Y"
;;;     elseif(n.source_identifier_keycap in ("R09.81"))
;;;     RS->QUAL[D1.SEQ].CONGESTION = "Y"
;;;     elseif(n.source_identifier_keycap in ("R68.89"))
;;;     RS->QUAL[D1.SEQ].COLDSWEAT = "Y"
;;;     elseif(n.source_identifier_keycap in ("R63.0"))
;;;     RS->QUAL[D1.SEQ].LOSSAPP = "Y"
;;;     elseif(n.source_identifier_keycap in ("R43.2"))
;;;     RS->QUAL[D1.SEQ].LOSSTASTE = "Y"
;;;     elseif(n.source_identifier_keycap in ("R43.0"))
;;;     RS->QUAL[D1.SEQ].LOSSSMELL = "Y"
;;;     elseif(n.source_identifier_keycap in ("R19.7","R11.10","R11.0"))
;;;     RS->QUAL[D1.SEQ].diarrhea = "Y"
;;;     elseif(n.source_identifier_keycap in ("M79.10"))
;;;     RS->QUAL[D1.SEQ].MUSCLEACHE = "Y"
;;;     elseif(n.source_identifier_keycap in ("M25.50"))
;;;     RS->QUAL[D1.SEQ].JOINTPAIN = "Y"
;;;     elseif(n.source_identifier_keycap in ("M43.6"))
;;;     RS->QUAL[D1.SEQ].NECKSTIFF = "Y"
;;;     elseif(n.source_identifier_keycap in ("R22.1"))
;;;     RS->QUAL[D1.SEQ].swollenneck = "Y"
;;;     elseif(n.source_identifier_keycap in ("R53.1"))
;;;     RS->QUAL[D1.SEQ].weakness = "Y"
;;;     elseif(n.source_identifier_keycap in ("T14.8XXA"))
;;;     RS->QUAL[D1.SEQ].BRUISING = "Y"
;;;     elseif(n.source_identifier_keycap in ("R58"))
;;;     RS->QUAL[D1.SEQ].BLEEDING = "Y"
;;;     elseif(n.source_identifier_keycap in ("H10.029"))
;;;     RS->QUAL[D1.SEQ].PINKEYE = "Y"
;;;     elseif(n.source_identifier_keycap in ("R17"))
;;;     RS->QUAL[D1.SEQ].JAUNDICE = "Y"
;;;     elseif(n.source_identifier_keycap in ("R21"))
;;;     RS->QUAL[D1.SEQ].RASH = "Y"
;;;     elseif(n.source_identifier_keycap in ("J96.90" ,"J96.91" ,"J96.00" ))
;;;     RS->QUAL[D1.SEQ].hypoxic = "Y"
;;;     endif
;;
;;
;;with nocounter, time = 400
;
;;/************************************************************************************
;;                  GETTING pt first test
;;*************************************************************************************/
;Select into "nl:"
;FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
;       ,clinical_event c
;PLAN d
;
;   join c WHERE c.person_id = rs->qual[d.seq].PERSONID
;   and c.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3)
;   and c.event_class_cd in ( 236.00,224.00)
;   ;and c.valid_from_dt_tm between CNVTDATETIME($START_DT)AND CNVTDATETIME($END_DT)
;   and c.result_status_cd in (25,34,35)
;   and c.authentic_flag = 1
;   and c.event_cd in (
;                   2258265897  ;CoVID19-SARS-CoV-2 by PCR
;               ,2254653289 ;COVID 19 (DH/CDC)
;               ,2259614555 ;COVID-19/Coronavirus RNA PCR
;               ,2258239523 ;COVID-19 (SARS-CoV-2, NAA)
;               ,2265151661 ;CoVID_19 (SARS-CoV2, NAA)
;               ,2258239523 ;COVID-19 (SARS-CoV-2, NAA)
;               ,2270692929 ;CoVID 19-SARS-CoV-2 Overall Result
;               ,2258265897 ;CoVID 19-SARS-CoV-2 by PCR
;               ,2270688963 ;CoVID 19-PAN-SARS-CoV-2 by PCR
;               ,2259601949 ;COVID19(SARS-CoV-2)
;               ,2276648185 ; NEW POC ORDER
;                   ,2282064783
;                   ,2287776717
;                   ,2290710033
;                   ,2290710049
;                   ,2290713753
;                   ,2290713803
;                   ,2290718387
;               ,2291914727 ;inhouse IgG
;               ,2291907909 ;Inhouse IgG Interp
;               ,2385455807 ;PCR Ag
;               ,2404008691 ;POC Ag
;               ;,104260588.00 ; flu rapid test - for testing - remove*****************
;   )
;
;
;order by c.person_id
;
; head c.person_id
; cnt = 0           ;count_example
;detail
; cnt = cnt + 1
;
; IF(cnt = 1)
; rs->qual[d.seq].FIRST_TEST = "Y"
; elseIF(cnt > 1)
; rs->qual[d.seq].FIRST_TEST = "N"
; ENDIF
;
;with nocounter, time = 100
;
;;/**************************************************************************************
;;                  GETTING Pregnancy powerform results
;;****************************************************************************************/
;Select into "nl:"
;
;FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
;,clinical_event ce
;
;PLAN D
;
;JOIN ce where ce.encntr_id = rs->qual[d.seq].EncntrId
;and ce.event_cd =      704785.00;  Pregnancy
;
;
;detail
;
;if(ce.result_val = "Confirmed positive")
;
;rs->QUAL[D.SEQ].preg_ind = "Y"
;
;elseif(ce.result_val in( "Patient denies","Confirmed negative"))
;
;rs->QUAL[D.SEQ].preg_ind = "N"
;
;;elseif(ce.result_val = "Possible unconfirmed")
;;
;;rs->QUAL[D.SEQ].preg_ind = "Possibly Pregnant"
;
;endif
;
;with nocounter, format, time = 500
;
;;======================================================================
;; GETTING pregnancy indicator
;;======================================================================
;
;Select into "nl:"
;FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
;  , Problem pr
;  , nomenclature n
;  , pregnancy_instance pi
;  , pregnancy_estimate pe
;
;
;PLAN D1
; JOIN pR WHERE pR.person_id = RS->QUAL[D1.SEQ].PersonId
;
;    and pR.active_ind = 1
;    AND PR.active_status_cd = 188
;    and pR.life_cycle_status_cd = 3301 ; active
;    AND PR.active_status_cd = 188; ACTIVE
;    and pr.data_status_cd in (23,34,25,35)
;       AND PR.problem_instance_id = (SELECT MAX(pR2.PROBLEM_INSTANCE_ID)
;                               from PROBLEM   PR2
;                               where PR.PROBLEM_id = pR2.PROBLEM_id and pR2.active_ind = 1)
;
;JOIN PI WHERE PI.person_id = Pr.person_id and pi.active_ind = 1
;       AND Pi.pregnancy_id = (SELECT MAX(pi2.pregnancy_id)
;                               from PRegnancy_instance   Pi2
;                               where Pi.person_id = pi2.person_id and pi2.active_ind = 1)
;
;join pe where pi.pregnancy_id = pe.pregnancy_id and pe.active_ind = 1
;       and pe.pregnancy_estimate_id = (SELECT MAX(pe2.pregnancy_estimate_id)
;                               from PRegnancy_estimate  Pe2
;                               where Pe.pregnancy_id = pe2.pregnancy_id and pe2.active_ind = 1)
;
;join n where n.nomenclature_id = pR.nomenclature_id
;       and n.source_identifier_keycap in (
;                               "191073013"
;                                           )
;                                           AND N.active_ind = 1
;                                           AND N.active_status_cd = 188 ; ACTIVE
;
;; JOIN PI WHERE PI.person_id = P.person_id and pi.active_ind = 1
;; AND Pi.pregnancy_id = (SELECT MAX(pi2.pregnancy_id)
;;                              from PRegnancy_instance   Pi2
;;                              where Pi.person_id = pi2.person_id and pi2.active_ind = 1)
; order by d1.seq
;
; DETAIL
;
;  RS->QUAL[d1.seq].preg_ind = "Y"
;
; with nocounter, time = 500
;
; ;/********************************************************************************************
;;                  GETTING onset date info
;;*********************************************************************************************/
;Select into "nl:"
;FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
;   ,clinical_event ce
;   ,ce_date_result cdr
;
; plan d
;
;join ce where ce.person_id = rs->qual[d.seq].PersonId
;and ce.encntr_id = rs->qual[d.seq].ENCNTRid
;and ce.event_cd in( 2273998547.00, 2273998843.00,2230980383.00,2385366457.00,2384922167.00,2384924885.00
;)
;
;join cdr where cdr.event_id = outerjoin(ce.event_id)
;
;detail
;
; if(ce.event_cd = 2273998547.00)
;rs->QUAL[d.seq].onset_dt = FORMAT(CDR.result_dt_tm, "MM/DD/YYYY;;Q");cnvtdatetime(ce.result_val, "MM/DD/YYYY hh:mm:ss;;D")
;
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
;
;elseif(ce.event_cd = 2385366457.00 and ce.result_val in ("Yes"))
;rs->QUAL[d.seq].oc_stat = "Y"
;
;elseif(ce.event_cd = 2385366457.00 and ce.result_val in ("No"))
;rs->QUAL[d.seq].oc_stat = "N"
;
;elseif(ce.event_cd = 2385366457.00 and ce.result_val in ("Unknown"))
;rs->QUAL[d.seq].oc_stat = "UNK"
;
;elseif(ce.event_cd = 2384922167.00 and ce.result_val in ("Yes"))
;rs->QUAL[d.seq].ltc = "Y"
;
;elseif(ce.event_cd = 2384922167.00 and ce.result_val in ("No"))
;rs->QUAL[d.seq].ltc= "N"
;
;elseif(ce.event_cd = 2384922167.00 and ce.result_val in ("Unknown"))
;rs->QUAL[d.seq].ltc = "UNK"
;
;elseif(ce.event_cd = 2384924885.00 and ce.result_val in ("Yes"))
;rs->QUAL[d.seq].preg_ind = "Y"
;
;elseif(ce.event_cd = 2384924885.00 and ce.result_val in ("No"))
;rs->QUAL[d.seq].preg_ind = "N"
;
;elseif(ce.event_cd = 2384924885.00 and ce.result_val in ("Unknown"))
;rs->QUAL[d.seq].preg_ind = "UNK"
;
;endif
;
;;if(rs->QUAL[d.seq].symptoms not in ("Y","N"))
;;rs->QUAL[d.seq].symptoms = "UNK"
;;endif
;
;with nocounter, time = 500
;/****************************************************************************************************
;                   ;get patient employment information
;*****************************************************************************************************/
;
;Select into "nl:"
;FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
;   ,person_org_reltn por
;
;PLAN D1
;
;
;join por
;   where por.person_id =  RS->QUAL[D1.SEQ].PERSONID
;       and por.active_ind = 1
;       and por.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
;       and por.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
;       and por.person_org_reltn_cd = 1136.00;employer
;
;detail
;
;   RS->QUAL[D1.SEQ].occupation =   uar_get_code_display(por.empl_status_cd)
;
;   if(RS->QUAL[D1.SEQ].occupation in ("Retired","Not Employed","Self Employed"))
;   RS->QUAL[D1.SEQ].oc_stat = "N"
;   endif
;
;with nocounter,time = 300, ORAHINTCBO("INDEX( POR XIE1PERSON_ORG_RELTN)")

/*******************************************************************************************
               OUTPUT DATA TO $OUTDEV/EMAILING
********************************************************************************************/
#EXITPROGRAM
If($Type = 2)
;#exit_program
; if (size(rs->QUAL,5) > 0); AT LEAST ONE PATIENT FOUND ABOVE

 SELECT INTO VALUE(FILE_NAME)

    TEST_NAME = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].OrderDesc))
    , RESULT = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Result))
    , UNIT = " "
    ;, RESULTCMT = trim(SUBSTRING(1, 2000, rs->QUAL[D1.SEQ].ResultCmt))
    , ORDER_NUMBER = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ACCESSION))
    , COLLECTION_DATE = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].CollectionDtTm))
    , RESULT_DATE = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].Result_dttm))
    ;,auth_flag = rs->QUAL[D1.SEQ].auth_flag
    ;,result_status = rs->QUAL[D1.SEQ].res_status
    , CMRN = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].cmrn))
    , FIRSTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FirstName))
    , LASTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LastName))
    , DOB = trim(SUBSTRING(1, 25, rs->QUAL[D1.SEQ].DOB))
    , GENDER = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Gender))
    , RACE = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].Race))
    , PT_PHONE = format(rs->QUAL[D1.SEQ].pt_phone, "###-###-####")
    ;, AGE = rs->QUAL[D1.SEQ].age
    ;, COUNTY = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].County))
    , STREETADDR = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr))
    , STREETADDR2 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr2))
    , CITY = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].City))
    , STATE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].State_cd))
    , ZIP = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Zip))
    , ORDERING_FACILITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
    , ORDER_PROVIDER = trim(SUBSTRING(1, 75, rs->QUAL[D1.SEQ].Order_PROVIDER))
    , PROVIDER_ADDR = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_StreetAddr))
    , PROVIDER_ADDR2 = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_StreetAddr2))
    , PROVIDER_CITY= trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_City))
    , PROVIDER_STATE = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_State))
    , PROVIDER_ZIP = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_ZIP))
    , PROVIDER_PHONE = format(rs->QUAL[D1.SEQ].FAC_PHONE, "###-###-####")
    , REF_RANGE = " "
    , SPECIMEN = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
    ;, ONSET_DATE = " "
    , REPORTING_FACILITY = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].Perform_Location))
    , REPORTING_CLIA = rs->QUAL[D1.SEQ].PerformingCLIA
    ;, encntr_type = rs->QUAL[D1.SEQ].Encntr_Type

    , ORDER_DATE = format(RS->QUAL[d1.seq].ORDER_DTTM, "MM/DD/YYYY;;D")
    , TEST_CODE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].loinc))
    , RESULT_CODE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].result_snow))
    , DEVICE_IDENTIFIER = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].service_resource))
    , PT_ETHNICITY = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ethnic_cd))
    , ORDERING_PROVIDER_NPI = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].npi))
    , PATIENT_COUNTY = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].County))
    , PERFORMING_FACILITY = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].Perform_Location))
    , PERFORMING_FACILITY_CLIA = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].PerformingCLIA))
    , PERFORMING_FACILITY_ZIP = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].perform_zip))
    , FIRST_TEST = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].FIRST_TEST))
    , HEALTH_CARE_WORKER = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].oc_stat))
    , SYMPTOMATIC = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].symptoms))
    , SYMPTOM_ONSET = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].onset_dt))
    , HOSPITALIZED = "N"
    , ICU = "N"
    , CONGREGATE_CARE_SETTING = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].LTC))
    , PREGNANT = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].preg_ind))
    , REG_DATE = format(RS->QUAL[d1.seq].reg_dt, "MM/DD/YYYY hh:mm:ss;;D")
    , DISCHARGE_DATE = format(RS->QUAL[d1.seq].discharge_dttm, "MM/DD/YYYY hh:mm:ss;;D")
    ;, encntr_type = rs->QUAL[D1.SEQ].Encntr_Type


    FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))

    plan d1

    where ;(rs->QUAL[d1.seq].State_cd in( "DC","MD") or rs->QUAL[d1.seq].fac_State in( "DC","MD"))
     ;AND
     rs->QUAL[d1.seq].48hr_ind = 1
     and rs->QUAL[d1.seq].date_diff > 1
    and rs->QUAL[d1.seq].Result in ("POS*","DET*")
    AND rs->QUAL[d1.seq].action_event != "Endorse"
    and (   rs->QUAL[d1.seq].fac_State    =  "VA"
         or rs->QUAL[d1.seq].State_cd     =  "VA"
        )

    with Heading, PCFormat('"', ',',1), format=STREAM, compress, nocounter, format;, maxrow=50000;'', ',', 1,1


    select into $outdev
        msg="success"
        from dummyt
        with nocounter

 elseif($type = 1)

 if (size(rs->QUAL,5) > 0)

    select into $outdev

    TEST_NAME = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].OrderDesc))
    , RESULT = if(rs->QUAL[D1.SEQ].Result != " ")
    trim(SUBSTRING(1, 1000, rs->QUAL[D1.SEQ].Result))
    else
    trim(rs->QUAL[D1.SEQ].INT_Result)
    endif

    , UNIT = " "
    ;, RESULTCMT = trim(SUBSTRING(1, 2000, rs->QUAL[D1.SEQ].ResultCmt))
    , ORDER_NUMBER = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ACCESSION))
    , COLLECTION_DATE = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].CollectionDtTm))
    , RESULT_DATE = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].Result_dttm))
    , DICHARGE_DTTM = format(rs->QUAL[d1.seq].DISCHARGE_DTTM, "@SHORTDATETIME")
    ;,auth_flag = rs->QUAL[D1.SEQ].auth_flag
    ;,result_status = rs->QUAL[D1.SEQ].res_status
    , CMRN = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].cmrn))
    , FIRSTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FirstName))
    , LASTNAME = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LastName))
    , DOB = trim(SUBSTRING(1, 25, rs->QUAL[D1.SEQ].DOB))
    , GENDER = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Gender))
    , RACE = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].Race))
    , PT_PHONE = format(rs->QUAL[D1.SEQ].pt_phone, "###-###-####")
    ;, AGE = rs->QUAL[D1.SEQ].age
    ;, COUNTY = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].County))
    , STREETADDR = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr))
    , STREETADDR2 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr2))
    , CITY = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].City))
    , STATE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].State_cd))
    , ZIP = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Zip))
    , ORDERING_FACILITY = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name))
    , ORDER_PROVIDER = trim(SUBSTRING(1, 75, rs->QUAL[D1.SEQ].Order_PROVIDER))
    , PROVIDER_ADDR = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_StreetAddr))
    , PROVIDER_ADDR2 = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_StreetAddr2))
    , PROVIDER_CITY= trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_City))
    , PROVIDER_STATE = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_State))
    , PROVIDER_ZIP = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_ZIP))
    , PROVIDER_PHONE = format(rs->QUAL[D1.SEQ].FAC_PHONE, "###-###-####")
    , REF_RANGE = " "
    , SPECIMEN = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN))
    ;, ONSET_DATE = " "
    , REPORTING_FACILITY = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].Perform_Location))
    , REPORTING_CLIA = rs->QUAL[D1.SEQ].PerformingCLIA
    ;, encntr_type = rs->QUAL[D1.SEQ].Encntr_Type

    , ORDER_DATE = format(RS->QUAL[d1.seq].ORDER_DTTM, "MM/DD/YYYY;;D")
    , TEST_CODE = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].loinc))
    , RESULT_CODE = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].result_snow))
    , DEVICE_IDENTIFIER = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].service_resource))
    , PT_ETHNICITY = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ethnic_cd))
    , ORDERING_PROVIDER_NPI = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].npi))
    , PATIENT_COUNTY = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].County))
    , PERFORMING_FACILITY = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].Perform_Location))
    , PERFORMING_FACILITY_CLIA = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].PerformingCLIA))
    , PERFORMING_FACILITY_ZIP = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].perform_zip))
    , FIRST_TEST = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].FIRST_TEST))
    , HEALTH_CARE_WORKER = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].oc_stat))
    , SYMPTOMATIC = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].symptoms))
    , SYMPTOM_ONSET = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].onset_dt))
    , HOSPITALIZED = "N"
    , ICU = "N"
    , CONGREGATE_CARE_SETTING = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].LTC))
    , PREGNANT = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].preg_ind))
    , LOCATION = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].LOCATION))
    , FACILITY = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].FACILITY))


    , event_cd = rs->QUAL[D1.SEQ].specimenp
    , event = rs->QUAL[D1.SEQ].EVENT
    , ENCNTRID = rs->QUAL[D1.SEQ].EncntrId
    , PERSONID = rs->QUAL[D1.SEQ].PersonId
    , ORDERID = rs->QUAL[D1.SEQ].OrderId
    , INTERP_RESULT = trim(rs->QUAL[D1.SEQ].INT_Result)
    , 48hr_ind = rs->QUAL[D1.SEQ].48hr_ind
    , date_diff = rs->QUAL[D1.SEQ].date_diff
    , REG_DATE = format(RS->QUAL[d1.seq].reg_dt, "MM/DD/YYYY hh:mm:ss;;D")
    , DISCHARGE_DATE = format(RS->QUAL[d1.seq].discharge_dttm, "MM/DD/YYYY hh:mm:ss;;D")

    FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))


    plan d1

    where ;(rs->QUAL[d1.seq].State_cd in( "DC","MD") or rs->QUAL[d1.seq].fac_State in( "DC","MD"))
     ;AND
     rs->QUAL[d1.seq].48hr_ind = 1
     and rs->QUAL[d1.seq].date_diff > 1
    and rs->QUAL[d1.seq].Result in ("POS*","DET*")
    AND rs->QUAL[d1.seq].action_event != "Endorse"
    and (   rs->QUAL[d1.seq].fac_State    =  "VA"
         or rs->QUAL[d1.seq].State_cd     =  "VA"
        )

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

    ;001->
    select into 'nl:'
      FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))

     plan d1
      where rs->QUAL[d1.seq].48hr_ind     =  1
        and rs->QUAL[d1.seq].date_diff    >  1
        and rs->QUAL[d1.seq].Result       in ("POS*","DET*")
        AND rs->QUAL[d1.seq].action_event != "Endorse"
        and (   rs->QUAL[d1.seq].fac_State    =  "VA"
             or rs->QUAL[d1.seq].State_cd     =  "VA"
            )
    with nocounter
    
    if(curqual = 0)
        set FILE_NAME = EMPTY_FILE_NAME
        set FILENAME  = emptyfileName
    endif

    call echo(build('FILE_NAME:', FILE_NAME))
    call echo(build('FILENAME:', FILENAME))
    ;001<-
    
    select into value(FILENAME)
          TEST_NAME                = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].OrderDesc        ))
        , RESULT                   = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Result          ))
        , UNIT                     = " "
        , ORDER_NUMBER             = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ACCESSION        ))
        , COLLECTION_DATE          = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].CollectionDtTm   ))
        , RESULT_DATE              = trim(SUBSTRING(1, 50, rs->QUAL[D1.SEQ].Result_dttm      ))
        , CMRN                     = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].cmrn             ))
        , FIRSTNAME                = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FirstName        ))
        , LASTNAME                 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].LastName         ))
        , DOB                      = trim(SUBSTRING(1, 25, rs->QUAL[D1.SEQ].DOB              ))
        , GENDER                   = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Gender           ))
        , RACE                     = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].Race             ))
        , PT_PHONE                 = format(rs->QUAL[D1.SEQ].pt_phone, "###-###-####")
        , STREETADDR               = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr       ))
        , STREETADDR2              = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].StreetAddr2      ))
        , CITY                     = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].City             ))
        , STATE                    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].State_cd         ))
        , ZIP                      = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].Zip              ))
        , ORDERING_FACILITY        = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].Clinic_Name     ))
        , ORDER_PROVIDER           = trim(SUBSTRING(1, 75, rs->QUAL[D1.SEQ].Order_PROVIDER   ))
        , PROVIDER_ADDR            = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_StreetAddr  ))
        , PROVIDER_ADDR2           = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_StreetAddr2 ))
        , PROVIDER_CITY            = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_City        ))
        , PROVIDER_STATE           = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_State       ))
        , PROVIDER_ZIP             = trim(SUBSTRING(1, 100, rs->QUAL[D1.SEQ].fac_ZIP         ))
        , PROVIDER_PHONE           = format(rs->QUAL[D1.SEQ].FAC_PHONE, "###-###-####")
        , REF_RANGE                = " "
        , SPECIMEN                 = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].SPECIMEN         ))
        , REPORTING_FACILITY       = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].Perform_Location))
        , REPORTING_CLIA           = rs->QUAL[D1.SEQ].PerformingCLIA
        , ORDER_DATE               = format(RS->QUAL[d1.seq].ORDER_DTTM, "MM/DD/YYYY;;D")
        , TEST_CODE                = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].loinc            ))
        , RESULT_CODE              = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].result_snow      ))
        , DEVICE_IDENTIFIER        = trim(SUBSTRING(1, 40, rs->QUAL[D1.SEQ].service_resource ))
        , PT_ETHNICITY             = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ethnic_cd        ))
        , ORDERING_PROVIDER_NPI    = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].npi              ))
        , PATIENT_COUNTY           = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].County           ))
        , PERFORMING_FACILITY      = trim(SUBSTRING(1, 200, rs->QUAL[D1.SEQ].Perform_Location))
        , PERFORMING_FACILITY_CLIA = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].PerformingCLIA   ))
        , PERFORMING_FACILITY_ZIP  = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].perform_zip      ))
        , FIRST_TEST               = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].FIRST_TEST       ))
        , HEALTH_CARE_WORKER       = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].oc_stat          ))
        , SYMPTOMATIC              = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].symptoms         ))
        , SYMPTOM_ONSET            = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].onset_dt         ))
        , HOSPITALIZED             = "N"
        , ICU                      = "N"
        , CONGREGATE_CARE_SETTING  = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].LTC              ))
        , PREGNANT                 = trim(SUBSTRING(1, 20, rs->QUAL[D1.SEQ].preg_ind         ))
        , REG_DATE                 = format(RS->QUAL[d1.seq].reg_dt, "MM/DD/YYYY hh:mm:ss;;D")
        , DISCHARGE_DATE           = format(RS->QUAL[d1.seq].discharge_dttm, "MM/DD/YYYY hh:mm:ss;;D")

     FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))

     plan d1
      where rs->QUAL[d1.seq].48hr_ind     =  1
        and rs->QUAL[d1.seq].date_diff    >  1
        and rs->QUAL[d1.seq].Result       in ("POS*","DET*")
        AND rs->QUAL[d1.seq].action_event != "Endorse"
        and (   rs->QUAL[d1.seq].fac_State    =  "VA"
             or rs->QUAL[d1.seq].State_cd     =  "VA"
            )

    with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress



    ;***********EMAIL THE ACTUAL ZIPPED FILE**************************** ;MOD004
    if(CURDOMAIN = PRODUCTION_DOMAIN);ONLY EMAIL OUT OF P41


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
