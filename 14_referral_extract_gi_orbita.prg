/***********************************************************************************************************
 Program Title:     14_referral_extract_gi.prg
 Create Date:       10/28/2022
 Object name:       14_referral_extract_gi
 Source file:       14_referral_extract_gi.prg
 MCGA:
 OPAS:
 Purpose:https:
 Executed from:     Explorer Menu
 Special Notes:

*************************************************************************************************************
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^IMPORTANT^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*************************************************************************************************************


**************************************************************************************************************
**************************************************************************************************************
**************************************************************************************************************
**************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**************************************************************************************************************
Mod    Date             Analyst                 SOM/MCGA                    Comment
---    ----------       --------------------    ------              ------------------------------------------
N/A    10/28/2022       Jeremy Daniel           N/A                 Initial Release
001    05/28/2025       Michael Mayes           354184              Adding some DXes
002    07/01/2025       Michael Mayes           354643              Adding a DX

*************END OF ALL MODCONTROL BLOCKS* *******************************************************************/
drop program 14_referral_extract_gi_orbita go
create program 14_referral_extract_gi_orbita

prompt
    "Output to File/Printer/MINE" = "MINE"    ;* Enter or select the printer or file name to send this report to.
    , "Registration Start Date" = "CURDATE"
    , "Registration End Date" = "CURDATE"
    , "Report Type" = 1

with OUTDEV, Start_Dt, End_Dt, Type


declare componentCd = f8 with constant(uar_get_code_by("DISPLAY_KEY", 18189,"PRIMARYEVENTID")),protect
declare blobout = vc with protect, noconstant(" ")
declare blobnortf = vc with protect, noconstant(" ")
declare lb_seg = vc with protect, noconstant(" ")
declare bsize = i4
declare uncompsize = i4
declare lenblob = i4
declare authver_cd  = f8 with constant(uar_get_code_by("MEANING" , 8 , "AUTH" )), PROTECT
declare ocfcomp_cd = f8 with Constant(uar_get_code_by("MEANING",120,"OCFCOMP")),protect
declare performloc = vc
declare ptcnt = i4
declare size = i4
declare subroutine_get_blob(f8) = vc
declare num = i4 with protect
declare idx = i4 with protect  ;variable needs to be declared prior to calling arraysplit
declare order_cnt = i4 with protect
DECLARE fileName = vc
declare start_dt_tm_n = vc
declare end_dt_tm_n = vc
DECLARE dataDate = vc
declare opsInd = i4
declare output_file = vc with noconstant(" "), protect
declare email_subject = vc
declare email_body = vc
declare email_body_noresult = vc
declare send_to = vc with noconstant(" "), protect
declare dateRange = vc
declare prsnl_credential = vc


SET dataDate = TRIM(FORMAT(CNVTDATETIME(curdate,curtime3),"mmddyyyyhhmm;;d"),3)
set opsInd = validate(request->batch_selection)
set output_file = $1
set start_dt_tm_n = $start_dt
set end_dt_tm_n = $End_Dt
set dateRange = build2(format(cnvtdate($start_dt),"mm/dd/yyyy;;D")," to ",format(cnvtdate($End_Dt),"mm/dd/yyyy;;D"))

;set file_name =  concat("/cerner/d_p41/cust_output_2/referral_extract/gi/gi_ref",format(cnvtdatetime(curdate,curtime3),"YYYYMMDD;;Q"), ".csv")

if (OpsInd = 1 or $OUTDEV = "OPS")
    set OpsInd = 1
    call echo("Got here")

    set xCheck = findstring(',', $start_dt)
    set xECheck = findstring(',', $End_Dt)
    
    if (xCheck > 0 and xECheck > 0)
        call echo("Check")
        ; Lookback dates
        ; Example: 1_humana_extract '', '1,D', '1,D'
        set xStartUnit = piece($start_dt, ',', 2, '')
        set xEndUnit   = piece($end_dt, ',', 2, '')
        
        set start_dt_tm_n = format(datetimefind(cnvtlookbehind($start_dt), xStartUnit, 'B', 'B'), "mmddyyyy;;d")
        set end_dt_tm_n = format(datetimefind(cnvtlookbehind($end_dt), xEndUnit, 'E', 'E'), "mmddyyyy;;d")
        
        set dateRange = build2(format(datetimefind(cnvtlookbehind($start_dt), xStartUnit, 'B', 'B'),"mm/dd/yyyy;;D")," to ",
                                                format(datetimefind(cnvtlookbehind($end_dt), xEndUnit, 'E', 'E'), "mm/dd/yyyy;;D"))
    elseif(textlen(trim($start_dt,3))>0 and textlen(trim($End_Dt,3))>0)
        call echo("Date")
        set start_dt_tm_n = $start_dt
        set end_dt_tm_n = $End_Dt
        set dateRange = build2(format(cnvtdate($start_dt),"mm/dd/yyyy;;D")," to ",format(cnvtdate($End_Dt),"mm/dd/yyyy;;D"))
    else
        call echo("Else")
        if(WEEKDAY(CURDATE) = 1)
            call echo("Weekend")
            set start_dt_tm_n = trim(format(cnvtdatetime((curdate-3), 000000), "mmddyyyy;;d"),3)
            set end_dt_tm_n = trim(format(cnvtdatetime((curdate-1), 235959), "mmddyyyy;;d"),3)
            set dateRange = build2(format(datetimefind(cnvtlookbehind("3,d"),"d", "b","b"),  "mm/dd/yyyy;;d")," to ",
            format(datetimefind(cnvtlookbehind("1,d"),"d", "e","e"),  "mm/dd/yyyy;;d"))
        elseif(WEEKDAY(CURDATE) in(2,3,4,5))
            set start_dt_tm_n = trim(format(cnvtdatetime((curdate-1), 000000), "mmddyyyy;;d"),3)
            set end_dt_tm_n = trim(format(cnvtdatetime((curdate-1), 235959), "mmddyyyy;;d"),3)
            set dateRange = build2(format(datetimefind(cnvtlookbehind("1,d"),"d", "b","b"),  "mm/dd/yyyy;;d")," to ",
            format(datetimefind(cnvtlookbehind("1,d"),"d", "e","e"),  "mm/dd/yyyy;;d"))
        else
            go to exit_program
        endif
    endif


    set output_file = build2("/cerner/d_p41/cust_output_2/referral_extract/gi/gi_ref",
    format(cnvtdatetime(curdate,curtime3),"YYYYMMDD;;Q"), ".csv")
    
    set email_subject = "Clinic Referral Extract Report"
    SET email_body = concat("clin_referral_extract_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"), ".dat")
    set email_body_noresult = concat("clin_referral_extract_nr",format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"), ".dat")
    
    select into (value(email_body)) build2("The Clinic Referral Extract is attached to this email.",char(13), char(10),
            "Date Range: ", trim(dateRange,3), char(13), char(10),
            "This report ran on date and time: ",format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"),char(13),char(10),
            "CLL Object name: ",trim(cnvtlower(curprog)),char(13), char(10), char(13),char(10))
    from dummyt
    with format, noheading

    select into (value(email_body_noresult)) build2("No Referral qualifying referral Order found.",char(13), char(10),
            "Date Range: ", trim(dateRange,3), char(13), char(10),
            "This report ran on date and time: ",format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"),char(13),char(10),
            "CLL Object name: ",trim(cnvtlower(curprog)),char(13), char(10), char(13),char(10))
    from dummyt
    with format, noheading
    ;"Sofy@Medstar.net, Despina.Kiaoulias@Medstar.net, Justin.M.Hughes@medstar.net, Stephen.V.Manti@medstar.net"
    
    set send_to = "Sofy@Medstar.net, Despina.Kiaoulias@Medstar.net, Justin.M.Hughes@medstar.net, Stephen.V.Manti@medstar.net"
endif







declare temp_string        = vc  with public, noconstant(fillstring(300, " "))

;---------------------------------------------------------------------------------------------------------------------------------
;                            RECORD STRUCTURE
;---------------------------------------------------------------------------------------------------------------------------------
free record rs
record rs
(   1 printcnt = i4
    1 qual[*]
        2 headercol = vc
        2 encntrid = f8
        2 personid = f8
        2 encntr_type = vc
        2 e_location = vc
        2 clinic_name = vc
        2 firstname =  vc
        2 lastname = vc
        2 encntr_cd = vc
    2 clinic_name = vc
    2 fin = vc
    2 mrn = vc
    2 dob = vc
    2 cmrn = vc
        2 reg_dt = dq8
        2 visit_reason = vc
        2 admit_from = vc
        2 rec_count = vc
        2 location = vc
        2 order_name = vc
        2 phone = vc
        2 orderid = f8
        2 order_synonym = f8
        2 email = vc
        2 target_provider = vc
        2 target_provider_id = f8
        2 target_provider_phone = vc
        2 target_provider_npi = vc
        2 target_specialty = vc
        2 target_phone = vc
        2 target_address = vc
        2 target_service = vc
        2 oe_value = vc
        2 addr_prov_flag = vc
        2 order_cnt = i4
        2 multiple_orders = vc
        2 order_cnt_tot = i4
        2 zip = vc
        2 dx_code = vc
        2 dx_display = vc
        2 source_string = vc
        2 colonoscopy = i2
        2 order_dttm = dq8
        2 egd = i2
        2 procedure = vc
        2 city = vc
        2 state = vc
        2 streetaddr = vc
        2 streetaddr2 = vc
        2 gender = vc
        2 sex_at_birth = vc
        2 fac_zip= vc
        2 fac_county = vc
        2 fac_city = vc
        2 fac_state = vc
        2 fac_streetaddr = vc
        2 fac_streetaddr2 = vc
        2 org_id = f8
        2 location_cd = f8
        2 include = i2
        2 appt_type_cd = vc
        2 med_service = vc
        2 new_to_gi = i2
        2 date_diff = i4
        2 old_gi_encounter = vc
        2 med_service_cd2 = vc
        2 maritial_status = vc
        2 referring_provider_id = f8
        2 referring_provider = vc
        2 referring_provider_npi = vc
)

;---------------------------------------------------------------------------------------------------------------------------------
;       start coding here
;---------------------------------------------------------------------------------------------------------------------------------

select into "nl:"
from orders o,
  Person p,
  encounter e,
  organization org
plan o
  where o.orig_order_dt_tm between cnvtdatetime(cnvtdate(start_dt_tm_n),0) and cnvtdatetime(cnvtdate(end_dt_tm_n),2359)
  and o.product_id = 0
  and o.activity_type_cd = 249925330.00
  and o.synonym_id = 833716701.00
  and o.catalog_cd = 833716691.00
  and o.order_status_cd in (2543.00 ;Completed
    ,2546.00 ;Future
    ,2550.00 ;Ordered
    ,2548.00 ;InProcess
  )
join e
  where e.encntr_id = o.encntr_id
  and (
;------------------------------Urgent Care Locations -----------------------------------------------------------------------------
      (e.loc_facility_cd in(select cv1.code_value
                             from code_value cv1
                              where cv1.code_set = 220 and cv1.active_ind = 1
                              and ((cnvtlower(cv1.display) = 'medstar health uc*' or
                              cnvtlower(cv1.display) = 'medstar health urgent*' or
                              cnvtlower(cv1.display) = 'medstar hlth urgent*' or
                              cnvtlower(cv1.display) = '*medstar uc*' or
                              cnvtlower(cv1.display) = 'medstar urgent care*'))
                              and cv1.cdf_meaning = 'FACILITY'))
;-------------------------------Primary Care Location ----------------------------------------------------------------------------
      or(e.loc_facility_cd in (select cvg.child_code_value
      from code_value cv,
        code_value_group cvg,
        code_value cvc
      where cv.code_set = 100705
        and cv.display_key = 'PRIMARYCARELOCATIONS'
        and cvg.parent_code_value = cv.code_value
        and cvc.code_value = cvg.child_code_value))
        or e.loc_facility_cd = 2348539959.00) ;One Medical
join p
  where p.person_id = e.person_id
    and p.name_last_key != "ZZ*"
    and p.name_last_key != "CAREMOBILE"
    and p.name_last_key != "REGRESSION"
    and p.name_last_key != "TEST"
    and p.name_last_key != "CERNERTEST"
    and p.name_last_key != "*PATIENT*"
    AND not OPERATOR(p.name_last_key,"REGEXPLIKE","[0-9]")
    and p.active_ind = 1
    and p.end_effective_dt_tm > cnvtdatetime(sysdate)
and p.birth_dt_tm < cnvtlookbehind("18,Y")
join org
  where org.organization_id = e.organization_id
order by p.person_id
head report
    patients = 0
head p.person_id
  patients = patients + 1
  STAT=ALTERLIST(RS->QUAL,PATIENTS)
  rs->qual[patients].FirstName = cnvtcap(cnvtlower(p.name_first))
  rs->qual[patients].LastName = cnvtcap(cnvtlower(p.name_last))
  rs->qual[patients].PersonId = e.person_id
  rs->qual[patients].EncntrId = e.encntr_id
  rs->qual[patients].reg_dt = e.reg_dt_tm
  rs->qual[patients].location = uar_get_code_display(e.location_cd)
  rs->qual[patients].dob = datebirthformat(p.birth_dt_tm, p.birth_tz, 0, "@SHORTDATE4YR")
    rs->qual[patients].order_name = o.ordered_as_mnemonic
  rs->qual[patients].ORDERID = O.order_id
  rs->qual[patients].order_synonym = o.synonym_id
  rs->qual[patients].ORDER_DTTM = O.orig_order_dt_tm
    rs->qual[patients].gender = uar_get_code_display(p.sex_cd)
  rs->qual[patients].target_service = replace(trim(substring(1,255,o.ordered_as_mnemonic)),"Referral to MedStar ","")
    rs->qual[patients].ORG_ID = e.organization_id
    rs->qual[patients].location_cd = e.loc_facility_cd
  rs->qual[patients].order_cnt = order_cnt
    rs->qual[patients].MED_SERVICE = UAR_GET_CODE_DISPLAY(E.med_service_cd)
    rs->qual[patients].NEW_TO_GI = 1
    rs->qual[patients].maritial_status = UAR_GET_CODE_DISPLAY(p.marital_type_cd)
  rs->qual[patients].encntr_type = uar_get_code_display(e.encntr_type_cd)
  rs->qual[patients].clinic_name = uar_get_code_display(e.loc_facility_cd)
  rs->qual[patients].e_location = org.org_name
    rs->qual[patients].reg_dt = e.reg_dt_tm
    rs->qual[patients].visit_reason = e.reason_for_visit
foot report
  order_cnt = 0
with nocounter, time = 700
;call echorecord(rs)
;---------------------------------------------------------------------------------------------------------------------------------
;   NO ENCOUNTERS MESSAGE
;---------------------------------------------------------------------------------------------------------------------------------
if (size(rs->QUAL,5) = 0); AT LEAST ONE PATIENT FOUND ABOVE
  call echo("from nothing found")
  call noDataReturn(0)
  Go to EXIT_PROGRAM
endif


;---------------------------------------------------------------------------------------------------------------------------------
;Get CMRN
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d with seq = size(rs->qual,5)),
  person_alias pa
plan d
join pa
  where pa.person_id = rs->QUAL[d.seq].personid
  and pa.person_alias_type_cd = 2 ; CMRN
  and pa.active_ind = 1
  and pa.end_effective_dt_tm > cnvtdatetime(curdate,curtime)
order by d.seq
head d.seq
  rs->qual[d.seq]->cmrn = cnvtalias(pa.alias,pa.alias_pool_cd)
with nocounter

;---------------------------------------------------------------------------------------------------------------------------------
;Get Order provider
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d1 with seq = size(rs->qual,5))
  ,order_action oa
  ,prsnl p
  ,prsnl_alias pa
plan d1
join oa
  where oa.synonym_id = rs->QUAL[d1.seq].order_synonym
  and oa.order_id = rs->qual[d1.seq].orderid
  and oa.action_type_cd = 2534
join p
  where p.person_id = oa.order_provider_id
join pa
  where pa.person_id = outerjoin(p.person_id)
  and pa.prsnl_alias_type_cd = outerjoin(4038127.00)
  and pa.active_ind = outerjoin(1)
  and pa.end_effective_dt_tm > outerjoin(cnvtdatetime(sysdate))
order by d1.seq
head d1.seq
  rs->QUAL[d1.seq].referring_provider_id = oa.order_provider_id
  rs->QUAL[d1.seq].referring_provider = build2(trim(p.name_first)," ", trim(p.name_last))
  rs->QUAL[d1.seq].referring_provider_npi = pa.alias
with nocounter
;---------------------------------------------------------------------------------------------------------------------------------
;GETTING Referring Provider and Target provider Name Formated
;Query below came from Justin Hughes
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d with seq = size(rs->qual,5)),
    credential cr
plan d
  where rs->qual[d.seq].referring_provider_id > 0
join cr
  where cr.prsnl_id = rs->qual[d.seq].referring_provider_id
  and cr.active_ind = 1
  and cr.credential_type_cd = 686580
  and cr.display_seq in (1,2)
order by d.seq, cr.display_seq
head d.seq
  prsnl_credential = ""
head cr.display_seq
  prsnl_credential = build2(trim(prsnl_credential), " ",trim(uar_get_code_display(cr.credential_cd)))
foot d.seq
  if(textlen(trim(prsnl_credential,3))>0)
    rs->qual[d.seq].referring_provider = build2(trim(rs->qual[d.seq].referring_provider,3),", ",trim(prsnl_credential,3))
  endif
with uar_code(D)

;---------------------------------------------------------------------------------------------------------------------------------
;                   GETTING SEX AT BIRTH INFO
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d1 with seq = size(rs->qual,5)),
  person_patient p
plan d1
join p
  where p.person_id = RS->QUAL[d1.seq].PersonId
detail
  rs->QUAL[d1.seq].sex_at_birth = uar_get_code_display(p.birth_sex_cd)
with nocounter, time = 300
;---------------------------------------------------------------------------------------------------------------------------------
;                   GETTING EMAIL INFO
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
    ,PHONE PH
PLAN d
join ph
  where ph.parent_entity_id = rs->qual[d.seq].PersonId
  and ph.active_ind = outerjoin(1)
  and ph.phone_type_cd = outerjoin(170)  ;Home
  and ph.beg_effective_dt_tm < outerjoin(cnvtdatetime(curdate,curtime))
  and ph.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime))
  AND PH.parent_entity_name = outerjoin("PERSON_PATIENT")
detail
  rs->QUAL[d.seq]->email = PH.phone_num
with nocounter, time = 1000

;---------------------------------------------------------------------------------------------------------------------------------
;                   GETTING PHONE INFO
;---------------------------------------------------------------------------------------------------------------------------------
  select into "nl:"
  from (dummyt d with seq = size(rs->qual,5)),
    phone ph
  PLAN d
  join ph where ph.parent_entity_id = rs->qual[d.seq].PersonId
        and ph.active_ind = outerjoin(1)
        and ph.phone_type_cd = outerjoin(170)   ;Home
        and ph.beg_effective_dt_tm < outerjoin(cnvtdatetime(curdate,curtime))
        and ph.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime))
        AND PH.parent_entity_name = outerjoin("PERSON")
  detail
    if(findstring("(",ph.phone_num)>0)
      rs->qual[d.seq]->phone = ph.phone_num
    else
      rs->qual[d.seq]->phone = format(ph.phone_num_key, "(###)###-####")
    endif
  with nocounter, time = 1000
;---------------------------------------------------------------------------------------------------------------------------------
;                   GETTING pt address
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
  ,ADDRESS A
PLAN d
join A
  WHERE A.parent_entity_id = rs->qual[d.seq].PERSONID
  and a.address_type_cd = 756.00;   Home
    and a.active_ind = 1
    and a.end_effective_dt_tm > cnvtdatetime(sysdate)
order by d.seq
detail
  rs->qual[d.seq].zip = a.zipcode
  ;rs->qual[d.seq].county = uar_get_code_display(a.county_cd)
  rs->qual[d.seq].city = a.city
  rs->qual[d.seq].state = a.state
  rs->qual[d.seq].streetaddr = a.street_addr
  rs->qual[d.seq].streetaddr2 = a.street_addr2
with nocounter, time = 400

;---------------------------------------------------------------------------------------------------------------------------------
;                   ADDITIONAL DX CODE DETAILS
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d1 with seq = size(rs->qual,5))
  ,diagnosis dg
  ,nomenclature n
plan d1
join dg
  where dg.encntr_id = RS->qual[d1.seq].EncntrId
  and dg.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
join n
  where n.nomenclature_id = dg.nomenclature_id
    ;001 Changing this to a big or list... it doesn't like pat matching on big in lists.
    and (   n.source_identifier_keycap =   'A09'     ;Infectious gastroenteritis and colitis, unspecified
         or n.source_identifier_keycap =   'K21.00'  ;Gastro-esophageal reflux disease with esophagitis, without bleeding
         or n.source_identifier_keycap =   'K21.9'   ;Gastro-esophageal reflux disease without esophagitis
         or n.source_identifier_keycap =   'K29.70'  ;Gastritis, unspecified, without bleeding
         or n.source_identifier_keycap =   'K52.9'   ;Noninfective gastroenteritis and colitis, unspecified
         or n.source_identifier_keycap =   'K59.00'  ;Constipation, unspecified
         or n.source_identifier_keycap =   'R11.0'   ;Nausea
         or n.source_identifier_keycap =   'R19.5'   ;Other fecal abnormalities
         or n.source_identifier_keycap =   'R19.7'   ;Diarrhea, unspecified
         or n.source_identifier_keycap =   'R19.8'   ;Other specified symptoms and signs involving the digestive system and abdomen
         or n.source_identifier_keycap =   'Z87.19'  ;Personal history of other diseases of the digestive system
         or n.source_identifier_keycap =   'D64.9'   ;Unspecified anemia
         or n.source_identifier_keycap =   'K21.9?'  ;GERD?*
         or n.source_identifier_keycap =   'K62.5'   ;Rectal bleeding with bright red blood*
         or n.source_identifier_keycap =   'K62.5?'  ;Bleeding* ?
         or n.source_identifier_keycap =   'K64.9'   ;Hemorrhoids
         or n.source_identifier_keycap =   'K92.1'   ;Blood in stool*
         or n.source_identifier_keycap =   'R1.0?'   ;Nausea?
         or n.source_identifier_keycap =   'R10.13?' ;Epigastric pain?
         or n.source_identifier_keycap =   'R10.9'   ;Abdominal pain
         or n.source_identifier_keycap =   'R11.10?' ;Vomiting?
         or n.source_identifier_keycap =   'R12?'    ;Heartburn?
         or n.source_identifier_keycap =   'R13.10?' ;Dysphagia?*
         or n.source_identifier_keycap =   'R14.0'   ;Bloating
         or n.source_identifier_keycap =   'R19.4'   ;Change in bowel habits*
         or n.source_identifier_keycap =   'Z12.11'  ;Colon cancer screening
         or n.source_identifier_keycap =   'Z80.0'   ;Family history of colon cancer
                                      
         ;001->
         or n.source_identifier_keycap =   'K63.5'    ; Polyp of colon
         or n.source_identifier_keycap =   'R13.10'   ; Dysphagia, unspecified
         or n.source_identifier_keycap =   'R10.13'   ; Epigastric pain
         or n.source_identifier_keycap =   'Z12.9'    ; Encounter for screening for malignant neoplasm, site unspecified
         or n.source_identifier_keycap =   'Z86.010'  ; Personal history of colon polyps
         or n.source_identifier_keycap =   'D12.6'    ; Benign neoplasm of colon, unspecified
         or n.source_identifier_keycap =   'R74.8'    ; Abnormal levels of other serum enzymes
         or n.source_identifier_keycap =   'D50.9'    ; Iron deficiency anemia, unspecified
         or n.source_identifier_keycap =   'Z13.9'    ; Encounter for screening, unspecified
         or n.source_identifier_keycap =   'R10.11'   ; Right upper quadrant pain
         or n.source_identifier_keycap =   'R74.01'   ; Elevation of levels of liver transaminase levels
         or n.source_identifier_keycap =   'R10.84'   ; Generalized abdominal pain
         or n.source_identifier_keycap =   'R10.32'   ; Left lower quadrant pain
         or n.source_identifier_keycap =   'R12'      ; Heartburn
         or n.source_identifier_keycap =   'C18.9'    ; Malignant neoplasm of colon, unspecified
         or n.source_identifier_keycap =   'R10.31'   ; Right lower quadrant pain
         or n.source_identifier_keycap =   'R10.12'   ; Left upper quadrant pain
         or n.source_identifier_keycap =   'K90.0'    ; Celiac disease
         or n.source_identifier_keycap =   'D36.9'    ; Benign neoplasm, unspecified site
         or n.source_identifier_keycap =   'Z83.71'   ; Family history of colonic polyps
         or n.source_identifier_keycap =   'K20.90'   ; Esophagitis, unspecified without bleeding
         or n.source_identifier_keycap =   'R94.5'    ; Abnormal results of liver function studies
         or n.source_identifier_keycap =   'Z85.038'  ; Personal history of other malignant neoplasm of large intestine
         or n.source_identifier_keycap =   'R10.10'   ; Upper abdominal pain, unspecified
         or n.source_identifier_keycap =   'K27.9'    ; Peptic ulcer, site unspecified, unspecified as acute or chronic, without[..]
         or n.source_identifier_keycap =   'Z86.0100' ; Personal history of colon polyps, unspecified
         or n.source_identifier_keycap =   'Z83.719'  ; Family history of colon polyps, unspecified
         or n.source_identifier_keycap =   'R11.10'   ; Vomiting, unspecified
         ;001<-
         
         ;002->
         or n.source_identifier_keycap =   'R19.5'    ; Other fecal abnormalities
         ;002<-
         
         )
  and n.active_ind = 1
order by d1.seq
Detail
    rs->qual[d1.seq].dx_code = n.source_identifier_keycap
    rs->qual[d1.seq].include = 1
    rs->qual[d1.seq].dx_display = dg.diagnosis_display
    rs->qual[d1.seq].source_string = n.source_string
WITH nocounter, time = 400

;---------------------------------------------------------------------------------------------------------------------------------
;                   GETTING Target provider info
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d with seq = size(rs->qual,5))
  ,order_detail od
plan d
join od
  where od.order_id = rs->qual[d.seq].orderid
  and od.oe_field_id in (258409575.00,1593931077)
  and od.oe_field_meaning_id in (3581,9000)
order by d.seq, od.oe_field_id
head d.seq
  null
head od.oe_field_id
  case(od.oe_field_id)
    of 258409575:
      rs->qual[d.seq]->target_provider = od.oe_field_display_value
      rs->qual[d.seq].target_provider_id = od.oe_field_value
    of 1593931077:
      rs->qual[d.seq].target_provider_phone = trim(replace(replace(od.oe_field_display_value,"P: ", ""), 'P:', ''),3)
      
      ;001-> This should give us something like:
      ;      703-852-8060 F: 877-743-0[...]
      ;      or (443) 777-2475 F:(443) 77[...]
      ;      
      ;      they were prefixed by 'P: ' or 'P:'...
      ;      I need to just grab the first number.  Looks like there is always an F: so I can pull that off.
      rs->qual[d.seq].target_provider_phone = substring(1, findstring( 'F:', rs->qual[d.seq].target_provider_phone) - 1
                                                                     , rs->qual[d.seq].target_provider_phone)
      
  endcase
with nocounter, time = 1000
;---------------------------------------------------------------------------------------------------------------------------------
;                   Format Target provider name
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d with seq = size(rs->qual,5)),
  prsnl p
plan d
  where rs->qual[d.seq].target_provider_id > 0
join p
  where p.active_ind = 1
  and p.person_id = rs->qual[d.seq].target_provider_id
  and p.end_effective_dt_tm > sysdate + 3
order by d.seq
head d.seq
  rs->qual[d.seq].target_provider = build2(trim(p.name_first)," ", trim(p.name_last))
with nocounter
;---------------------------------------------------------------------------------------------------------------------------------
; Get Target provider Credential
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d with seq = size(rs->qual,5)),
    credential cr
plan d
  where rs->qual[d.seq].target_provider_id > 0
join cr
  where cr.prsnl_id = rs->qual[d.seq].target_provider_id
  and cr.active_ind = 1
  and cr.credential_type_cd = 686580
  and cr.display_seq in (1,2)
order by d.seq, cr.display_seq
head d.seq
  prsnl_credential = ""
head cr.display_seq
  prsnl_credential = build2(trim(prsnl_credential), " ",trim(uar_get_code_display(cr.credential_cd)))
foot d.seq
  if(textlen(trim(prsnl_credential,3))>0)
    rs->qual[d.seq].target_provider = build2(trim(rs->qual[d.seq].target_provider,3),", ",trim(prsnl_credential,3))
  endif
with nocounter

;---------------------------------------------------------------------------------------------------------------------------------
;Get  Target provider npi
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d with seq = size(rs->qual,5))
  ,prsnl_alias pa
plan d
  where rs->qual[d.seq].target_provider_id > 0
join pa
  where pa.person_id = rs->qual[d.seq].target_provider_id
  and pa.prsnl_alias_type_cd = 4038127.00
  and pa.active_ind = 1
  and pa.end_effective_dt_tm > cnvtdatetime(sysdate)
order by d.seq
head d.seq
  rs->qual[d.seq].target_provider_npi = pa.alias
with nocounter

;---------------------------------------------------------------------------------------------------------------------------------
;                   GETTING EGD PROCEDURE ORDER INFO
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d with seq = size(rs->qual,5))
  ,encounter e
    ,encntr_alias ea
plan d
join e
  where e.person_id = rs->qual[d.seq].personid
    AND E.med_service_cd IN ( 5042014.0 ;--GASTROENTEROLOGY
    ,1779130601 ;--DIGESTIVE DISEASE CENTER MMG
    ,966229991  ; --DIGESTIVE DISEASE CENTER OV
    ,1860324153.00  ;GASTROENTEROLOGY OV - MMG
    ,966243763.00   ;GASTROENTEROLOGY OV - UMH
    ,5042018.00  ;Gastrointestinal Onc
    ,313011.00  ;Med-Gastroenterology
    ,966300673.00  ;MMG GASTRO AT GOOD SAM
    ,3446639117.00  ;MMG GASTRO AT GREENBELT
    ,1947994815.00;  MMG Gastro at MMMC
    ,2921375555.00  ;MMG GASTRO AT SILVER SPRING
    ,2332176105.00  ;MMG GI AT STM OV
    ,966301237.00  ;MMG GI DOWNTOWN OV
    ,966311359.00  ;MMG METRO GASTRO ASSOCIATES OV
    ,966400857.00  ;PED GASTROENTEROLOGY OV - GUH
        )
    and e.reg_dt_tm > cnvtlookbehind("4,y")
    and e.encntr_id != rs->qual[d.seq].encntrid
    and e.reg_dt_tm < cnvtdatetime(curdate,curtime)
    AND E.encntr_id = (select MAX (E2.ENCNTR_ID)
                        FROM ENCOUNTER E2 WHERE E2.person_id = E.PERSON_ID
                        AND E2.med_service_cd
                        in ( 5042014 ;--GASTROENTEROLOGY
                                                , 1779130601 ;--DIGESTIVE DISEASE CENTER MMG
                                                , 966229991  ; --DIGESTIVE DISEASE CENTER OV
                                                ; ,   5042014.00    ;Gastroenterology
                                                , 1860324153.00 ;GASTROENTEROLOGY OV - MMG
                                                ,  966243763.00 ;GASTROENTEROLOGY OV - UMH
                                                ,    5042018.00 ;Gastrointestinal Onc
                                                 ,    313011.00 ;Med-Gastroenterology
                                                 , 966300673.00 ;MMG GASTRO AT GOOD SAM
                                                , 3446639117.00 ;MMG GASTRO AT GREENBELT
                                                , 1947994815.00;    MMG Gastro at MMMC
                                                , 2921375555.00 ;MMG GASTRO AT SILVER SPRING
                                                , 2332176105.00 ;MMG GI AT STM OV
                                                ,  966301237.00 ;MMG GI DOWNTOWN OV
                                                ,  966311359.00 ;MMG METRO GASTRO ASSOCIATES OV
                                                ,  966400857.00 ;PED GASTROENTEROLOGY OV - GUH

                                                )
                                                and e2.reg_dt_tm > cnvtlookbehind("4,y")
                                                and e2.encntr_id != rs->qual[d.seq].encntrid
                                                and e2.reg_dt_tm < cnvtdatetime(curdate,curtime)
                                                )
join ea
  where ea.encntr_id = e.encntr_id
    and ea.encntr_alias_type_cd = 1077
order by e.reg_dt_tm desc
detail
  rs->qual[d.seq].date_diff = datetimediff(rs->qual[d.seq].order_dttm,e.reg_dt_tm)
  rs->qual[d.seq].old_gi_encounter = ea.alias
  rs->qual[d.seq].med_service_cd2 = uar_get_code_display(e.med_service_cd)
    if(datetimediff(rs->qual[d.seq].order_dttm,e.reg_dt_tm) < 1096 and datetimediff(rs->qual[d.seq].order_dttm,e.reg_dt_tm) > 0)
    rs->qual[d.seq]->new_to_gi = 0
    endif
with nocounter, time = 1000

;---------------------------------------------------------------------------------------------------------------------------------
;                   GETTING encounter info
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
from (dummyt d with seq = size(rs->qual,5))
        ,encntr_alias ea
plan d
  where rs->qual[d.seq].encntrid > 0
join ea
  where ea.encntr_id = rs->qual[d.seq].encntrid
  and ea.encntr_alias_type_cd in (1079, 1077);mrn,  fin
  and ea.active_ind = 1
  and ea.beg_effective_dt_tm < cnvtdatetime(curdate,curtime)
  and ea.end_effective_dt_tm > cnvtdatetime(curdate,curtime)
order by d.seq, ea.encntr_alias_type_cd
head d.seq
  null
head ea.encntr_alias_type_cd
  case(ea.encntr_alias_type_cd)
    of 1077:rs->QUAL[d.seq]->fin = ea.alias
    of 1079:rs->QUAL[d.seq]->mrn = ea.alias
  endcase
with nocounter, time = 500
;---------------------------------------------------------------------------------------------------------------------------------
;                   GETTING zip OF ORG
;---------------------------------------------------------------------------------------------------------------------------------
;select into "nl:"
;from (dummyt d with seq = size(rs->qual,5))
;  ,address a
;plan d
;  where rs->qual[d.seq].location_cd > 0
;join a
;  where a.parent_entity_id = rs->qual[d.seq].location_cd
;   and a.address_type_cd = 754
;  and a.active_ind = 1
;  and a.beg_effective_dt_tm < sysdate
;  and a.end_effective_dt_tm > sysdate
;  and a.parent_entity_name = "LOCATION"
;order by d.seq
;head d.seq
;  rs->qual[d.seq].fac_zip= a.zipcode
;  rs->qual[d.seq].fac_county = a.county
;  rs->qual[d.seq].fac_city = a.city
;  rs->qual[d.seq].fac_state = a.state
;  rs->qual[d.seq].fac_streetaddr = a.street_addr
;  rs->qual[d.seq].fac_streetaddr2 = a.street_addr2
;  if(rs->qual[d.seq].fac_zip in("20016","20817","20815","20832","20722","20878","21401","20782","20036","20695","20772","20613"
;  ,"20735","22101","20653","20007","20010","22302","20746","20622","20003","20902","20650","20721","20707","20433","20906"
;  ,"21239","21237","21222","21128","21218","21229","21209","21220","21211","21234","21042","21015","21225","21230","21224"))
;    rs->QUAL[D.SEQ].INCLUDE = 1
;  endif
;with nocounter, time = 500

;---------------------------------------------------------------------------------------------------------------------------------
;               OUTPUT DATA TO $OUTDEV/EMAILING
;---------------------------------------------------------------------------------------------------------------------------------

  select
  if (opsind = 1)
    with nocounter, format, format=stream, separator=" ", pcformat('"', ',',1),compress, check
  endif
  into value(output_file)
  ;rs->qual[d1.seq].orderid,
    lastname = trim(substring(1, 30, rs->qual[d1.seq].lastname)),
  firstname = trim(substring(1, 30, rs->qual[d1.seq].firstname)),
    email = trim(substring(1, 75, rs->qual[d1.seq].email)),
    phone  = trim(substring(1, 30, rs->qual[d1.seq].phone)),
    gender  = trim(substring(1, 30, rs->qual[d1.seq].gender)),
    sex_at_birth  = trim(substring(1, 30, rs->qual[d1.seq].sex_at_birth)),
    address = trim(substring(1, 30, rs->qual[d1.seq].streetaddr)),
    address_2 = trim(substring(1, 30, rs->qual[d1.seq].streetaddr2)),
    city = trim(substring(1, 30, rs->qual[d1.seq].city)),
    state = trim(substring(1, 30, rs->qual[d1.seq].state)),
    zipcode = trim(substring(1, 10, rs->qual[d1.seq].zip)),
    referral_target_service = trim(substring(1, 100, rs->qual[d1.seq].target_service)),
    referral_target_provider_name = trim(substring(1, 75, rs->qual[d1.seq].target_provider)),
    referral_target_provider_npi = trim(substring(1, 14, rs->qual[d1.seq].target_provider_npi)),
    referral_target_phone= trim(substring(1, 25, rs->qual[d1.seq].target_provider_phone)),

    address_provider_flag = trim(substring(1, 15, rs->qual[d1.seq].addr_prov_flag)),
  cmrn = trim(substring(1, 30, rs->qual[d1.seq].cmrn)),
    order_name = trim(substring(1, 75, rs->qual[d1.seq].order_name)),
    date_of_service = format(rs->qual[d1.seq].reg_dt, "mm/dd/yyyy hh:mm:ss;;d"),
    location = trim(substring(1, 75, rs->qual[d1.seq].e_location)),
    personid = rs->qual[d1.seq].personid,
    orderid = rs->qual[d1.seq].orderid,
    dob = trim(substring(1, 10, rs->qual[d1.seq].dob)),
    diagnosis_code = trim(substring(1, 10, rs->qual[d1.seq].dx_code)),
    source_string = trim(substring(1, 100, rs->qual[d1.seq].source_string)),
    diagnosis_display = trim(substring(1, 100, rs->qual[d1.seq].dx_display)),

    INCLUDE = rs->QUAL[D1.SEQ].INCLUDE,
    APPT_TYPE = trim(SUBSTRING(1, 75, rs->QUAL[D1.SEQ].APPT_TYPE_CD))   ,
    MED_SERVICE = substring(1,100,rs->qual[d1.seq].med_service),

    New_to_Service = rs->qual[d1.seq].new_to_gi,
    marital_status = trim(substring(1, 20, rs->qual[d1.seq].maritial_status)),
    referring_provider = substring(1,100,rs->qual[d1.seq].referring_provider),
  referring_provider_npi = substring(1,30,rs->qual[d1.seq].referring_provider_npi)
  FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
    plan d1
  where rs->QUAL[D1.SEQ].dx_code != " "
  order by lastname,firstname
    with nocounter, time = 1500, format, separator = " "

    if(curqual <= 0)
    call noDataReturn(0)
  else
    call echo(build2("found something",curqual,"- ",dateRange))
    endif
    #exit_program

;---------------------------------------------------------------------------------------------------------------------------------
;  Subroutine No Data found
;---------------------------------------------------------------------------------------------------------------------------------
subroutine noDataReturn(p0)
  if (OpsInd = 1)
    set email_body_noresult = build2("No Referral qualifying referral Order found. <br>",
            "Date Range: ", trim(dateRange,3), " <br>",
            "This report ran on date and time: ",format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), " <br>",
            "CLL Object name: ",trim(cnvtlower(curprog)), " <br>")
    call xemail("reporting@medstar.net",value(send_to),value(email_subject),value(email_body_noresult))
  else
    select into $OUTDEV
    from dummyt
    detail
      row + 1
      col 001 "GI REFERRAL EXTRACT";report_title
      row + 1
      col 001 "You requested: "
      col 016  daterange
      row + 1
      col 001  "No Encounters were found for that data range."
      row + 1
      col 001 "Please Search Again"
      row + 2
    with format, separator = " "
  endif
end
;---------------------------------------------------------------------------------------------------------------------------------
;  Subroutine to Remove file
;---------------------------------------------------------------------------------------------------------------------------------
subroutine rmfile(afile)
    set dclcom = build2("rm ",afile)
    set dcllen = size(trim(dclcom))
    call dcl(dclcom, dcllen, dclstatus)
end

;---------------------------------------------------------------------------------------------------------------------------------
;  Subroutine to email file
;---------------------------------------------------------------------------------------------------------------------------------
subroutine xmailx(afrom, ato, acc, asubject, abody, afile)

  set xcommand = fillstring(512, " ")
  if(afrom = "")
      set xfrom = "reporting@medstar.net"
  else
      set xfrom = afrom
  endif
  set xbody = concat("cat ", abody," | tr -d \\r | mailx ")
  if(afile != "")
    set xfile = concat(" -a ", char(34), trim(afile, 7), char(34))
  else
    set xfile = ""
    call echo("sending blank email")
  endif
  set xsubject = concat(" -s ", char(34), asubject, char(34))
  if(acc != "")
    set xcc = concat(" -c ", acc)
  else
    set xcc = ""
  endif
  set xfromto = concat(" -r ", xfrom, " ", ato)
  if(xcc != "")
    set xcommand = concat(trim(xbody, 7), xsubject, xfile, xcc, xfromto)
  else
    set xcommand = concat(trim(xbody, 7), xsubject, xfile, xfromto)
  endif
  call echo(xcommand)
  set xlength = size(trim(xcommand, 7))
  set xstatus = 0
  call dcl(trim(xcommand, 7), xlength, xstatus)
  call echo("Email status")
  call echo(xstatus)
  return
end

subroutine xemail(afrom, ato, asubject, abody)
  call echo("sending blank email")
  set crlf = concat(char(13), char(10))
  set xcontenttype = concat(crlf, "mime-version: 1.0", crlf, "content-type: text/html", crlf, crlf, char(0))
  set xsubject = concat(asubject, xcontenttype)
  set xfrom = afrom
  set xto = ato
  set xclass = "IPM.NOTE"
  set xpriority = 5
  set xheader = "<html><body>"
  set xfooter = "</html>"
  set xbody = concat(abody, "<br><br>")
  set xsend = concat(xheader, xbody, xfooter)
  call uar_send_mail(nullterm(xto), nullterm(xsubject), nullterm(xsend), nullterm(xfrom), xpriority, nullterm(xclass))
  return
end

end
go
