/***********************************************************************************************************
 Program Title:     14_referral_mrn_rad_extract.prg
 Create Date:       02/16/2024
 Object name:       14_referral_mrn_rad_extract
 Source file:       14_referral_mrn_rad_extract.prg
 MCGA:
 OPAS:
 Purpose:https:
 Executed from:     Explorer Menu
 Special Notes:

**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ ---------------------------------------------------------------------------------------
N/A 06/03/2024 Simeon Akinsulie     346022 Initial Release
001 09/18/2024 Michael Mayes        349910 Adding locations and fields
002 10/14/2024 Michael Mayes        350390 Removing some modalities from new locations
003            Michael Mayes               I think I have mod 3s down there fighting something... looks like pulling in a new 
                                           location and some versioning work.
004 01/21/2025 Michael Mayes        351941 Adding location and modality to Georgetown
005 02/26/2025 Michael Mayes        352481 Adding Mammo to Georgetown
006 03/26/2025 Michael Mayes        352854 Adding MRI to Georgetown
*************END OF ALL MODCONTROL BLOCKS* **************************************************************************************/
  drop program 14_referral_mrn_rad_extract go
create program 14_referral_mrn_rad_extract

prompt
    "Output to File/Printer/MINE" = "MINE"    ;* Enter or select the printer or file name to send this report to.
    , "Registration Start Date"   = "SYSDATE"
    , "Registration End Date"     = "SYSDATE"
    , "Report Type"               = 1

with OUTDEV, Start_Dt, End_Dt, Type

declare num       = i4 with protect
declare idx       = i4 with protect  ;variable needs to be declared prior to calling arraysplit
declare order_cnt = i4 with protect
DECLARE fileName  = vc

DECLARE dataDate       = vc
declare  start_dt_tm_n = vc
declare end_dt_tm_n    = vc

SET dataDate           = TRIM(FORMAT(CNVTDATETIME(curdate,curtime3),"mmddyyyyhhmm;;d"),3)
set opsInd             = validate(request->batch_selection)
set output_file        = $1
set start_dt_tm_n      = $start_dt
set end_dt_tm_n        = $End_Dt
set dateRange          = build2(format(cnvtdate($start_dt),"mm/dd/yyyy;;D")," to ",format(cnvtdate($End_Dt),"mm/dd/yyyy;;D"))

declare start_time     = vc
declare end_time       = vc
declare opsStDt        = dq8 with public
declare opsCurrDt      = dq8 with public
declare info_domain    = vc with protect, constant("TWISTLE")
declare info_name      = vc with protect, constant("NEW_RAD_EXTRACT")
declare last_run_date  = vc
declare next_run_hour  = vc
declare last_run_hour  = vc


set start_dt_tm_n = substring(1,8,$start_dt)
set end_dt_tm_n   = substring(1,8,$End_Dt)

if(textlen($start_dt)= 14)
    set start_time = substring(10,5,$start_dt)

else
    set start_time = "0000"

endif

if(textlen($End_Dt)= 14)
    set end_time = substring(10,5,$End_Dt)

else
    set end_time = "2359"

endif

call echo(start_dt_tm_n)
call echo(start_time   )
call echo(end_dt_tm_n  )
call echo(end_time     )
call echo($start_dt    )


;---------------------------------------------------------------------------------------------------------------------------------
;       RECORD STRUCTURE
;---------------------------------------------------------------------------------------------------------------------------------
free record rs
record rs
(   1 printcnt                   = i4
    1 qual[*]
        2 headercol              = vc
        2 personid               = f8
        2 firstname              = vc
        2 lastname               = vc
        2 mrn                    = vc
    2 dob                        = vc
    2 cmrn                       = vc
        2 phone                  = vc
        2 email                  = vc
        2 multiple_orders        = vc
        2 zip                    = vc
        2 order_cnt_tot          = i4
        2 orders[*]
          3 encntrid             = f8
          3 orderid              = f8
          3 encntr_type          = vc
          3 e_location           = vc
          3 clinic_name          = vc
      3 clinic_name              = vc
      3 fin                      = vc
      3 encntr_cd                = vc
      3 reg_dt                   = dq8
      3 visit_reason             = vc
      3 admit_from               = vc
      3 location                 = vc
      3 order_name               = vc
      3 rec_count                = vc
        3 target_provider        = vc
        3 target_specialty       = vc
        3 target_phone           = vc
        3 target_address         = vc
        3 target_service         = vc
        3 oe_value               = vc
        3 addr_prov_flag         = vc
        3 order_cnt              = i4
        3 order_cnt_tot          = i4
        3 dx_code                = vc
        3 dx_display             = vc
        3 source_string          = vc
        3 performing_location    = vc
        3 performing_location_cd = f8
        3 modality               = vc
        3 referral_type          = vc
        3 order_date             = vc
)

;---------------------------------------------------------------------------------------------------------------------------------
;Logic to determine date range when running from scheduler
;---------------------------------------------------------------------------------------------------------------------------------

if (OpsInd = 1 or $OUTDEV = "OPS" or $Type = 2)
    set OpsInd = 1
    select into "nl:"
           DMI.info_domain ;"HIIQ"
         , DMI.info_name ;"EXTRACT" (Most recent Ops Dt/Tm)
         , DMI.info_date ; Last Ops run Date & Time (updated when job runs)
         , DMI.updt_cnt ;Increment count with each run
         , DMI.updt_dt_tm ;System update dt/tm
      from DM_INFO DMI

      plan DMI
       where DMI.info_domain = info_domain
         and DMI.info_name = info_name

    detail
        call echo("DM_INFO")
        call echo(dmi.info_date)

        last_run_hour = format(DMI.info_date, "hh;;q")
        next_run_hour = format(cnvtlookahead("1,H",DMI.info_date), "hh;;q")
        last_run_date = format(DMI.info_date, "mmddyyyy;;q")
    with nocounter

    call echo(last_run_hour)
    call echo(next_run_hour)
    call echo(last_run_date)

    set opsCurrDt = cnvtdatetime(curdate,curtime3)

    set xCheck = findstring(',', $start_dt)
    set xECheck = findstring(',', $End_Dt)

    call echo("Else")

    if(WEEKDAY(CURDATE) = 1)
        call echo("Weekend")
        ;First time running with no entry in DM_Info table
        if(cnvtint(format(CNVTDATETIME(curdate,curtime),"hh;;q")) = 8)
            set start_dt_tm_n = trim(format(cnvtdatetime((curdate-3), 0000), "mmddyyyy;;d"),3)
            set end_dt_tm_n   = trim(format(cnvtdatetime((curdate), 0000), "mmddyyyy;;d"),3)
            set start_time    = "1600"
            set end_time      = "0759"

        else
            set end_dt_tm_n   = trim(format(cnvtdatetime((curdate), 0000), "mmddyyyy;;d"),3)
            set start_time    = build2(format(cnvtlookbehind("1,H",CNVTDATETIME(curdate,curtime)),"hh;;q"),"00")
            set end_time      = build2(format(cnvtlookbehind("1,H",CNVTDATETIME(curdate,curtime)),"hh;;q"),"59")
            set start_dt_tm_n = trim(format(cnvtdatetime((curdate), 0000), "mmddyyyy;;d"),3)

        endif

    elseif(WEEKDAY(CURDATE) in(2,3,4,5))
        call echo('Logic 2')
        if(cnvtint(format(CNVTDATETIME(curdate,curtime),"hh;;q")) = 8)
            set start_dt_tm_n = trim(format(cnvtdatetime((curdate-1), 0000), "mmddyyyy;;d"),3)
            set end_dt_tm_n   = trim(format(cnvtdatetime((curdate), 0000), "mmddyyyy;;d"),3)
            set start_time    = "1600"
            set end_time      = "0759"

        else
            set start_dt_tm_n = trim(format(cnvtdatetime((curdate), 0000), "mmddyyyy;;d"),3)
            set end_dt_tm_n   = trim(format(cnvtdatetime((curdate), 0000), "mmddyyyy;;d"),3)
            set start_time    = build2(format(cnvtlookbehind("1,H",CNVTDATETIME(curdate,curtime)),"hh;;q"),"00")
            set end_time      = build2(format(cnvtlookbehind("1,H",CNVTDATETIME(curdate,curtime)),"hh;;q"),"59")

      endif

    else
        go to exit_program
    endif
    call echo(build2('Got to end',start_dt_tm_n,' ', end_dt_tm_n))
endif









declare temp_string        = vc  with public, noconstant(fillstring(300, " "))

call echo(build2("start_dt_tm_n:",start_dt_tm_n))
call echo(build2("end_dt_tm_n:",end_dt_tm_n))
call echo(build2("start_time:",start_time))
call echo(build2("end_time:",end_time))




;---------------------------------------------------------------------------------------------------------------------------------
;       start coding here
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
  from orders o,
       order_detail od,
       order_catalog oc,
       person p,
       encounter e,
       organization org
  plan o
   where o.orig_order_dt_tm between cnvtdatetime(cnvtdate(start_dt_tm_n),cnvtint(start_time))
     and cnvtdatetime(cnvtdate(end_dt_tm_n),cnvtint(end_time))
     and o.order_status_cd = 2546  ; FUTURE
     and o.catalog_type_cd = 2517  ; RAD

  join oc
   where oc.catalog_cd = o.catalog_cd
     and oc.active_ind = 1
     and oc.activity_subtype_cd != 1328919335.00 ; Diagnostic Radiology
     and cnvtupper(oc.primary_mnemonic) != "*XR*"
     and cnvtupper(oc.primary_mnemonic) != "NM *"  ;004 These are moving up here, from Washington specifically... no one gets now.
     and cnvtupper(oc.primary_mnemonic) != "IR *"  ;004 These are moving up here, from Washington specifically... no one gets now.

  join od
   where od.order_id = o.order_id
     and od.oe_field_id =831982505
     ;003->This gave us some problems
     and od.action_sequence = (select max(od1.action_sequence)
                                 from order_detail od1
                                where od1.order_id = o.order_id
                                  and od1.oe_field_id = od.oe_field_id
                              )
     ;003<-
     ;002->
     and (   (od.oe_field_value in ( 2627174945.00      ;Medstar Chevy Chase CT MR US XR
                                   , 2627174677.00      ;Medstar Rockville CT MR XR
                                   , 831586843.00       ;Medstar Bel Air CT XR DEXA MAMMO MR US
                                   , 831587279.00       ;Medstar Brandywine CT XR DEXA MR US
                                   , 831587733.00       ;Medstar Lafayette I MR
                                   , 831588331.00       ;Medstar Lafayette II CT XR DEXA MAMMO US
                                   , 831588519.00       ;Medstar Timonium MR
                                   , 5757404269.00      ;MRN Chevy Chase at Barlow                                  ;004 Adding.
                                   , 4567751099.00      ;BUILD BARLOW  THIS CAN PROBABLY BE REMOVED AFTER PROD MOVE ;004 Adding.
                                   )
             )
          or (od.oe_field_value in ( 1821487843.00      ;Medstar Washington Hosp All Modalities
                                   )
              and (    cnvtupper(oc.primary_mnemonic) != "DXA *"
                   ;004->  removing to move global... DXA stays though.
                   ;and cnvtupper(oc.primary_mnemonic) != "NM *"
                   ;and cnvtupper(oc.primary_mnemonic) != "IR *"
                   ;004<-
                  )
             )
          ;003->
          or (
              od.oe_field_value in ( 1821481899.00      ;MedStar Georgetown Univ All Modalities
                                   )
              and (    cnvtupper(oc.primary_mnemonic) = "US *"
                    or cnvtupper(oc.primary_mnemonic) = "CT *"  ; 004 Adding CTs now.  (There might be one order we are missing?)
                    or cnvtupper(oc.primary_mnemonic) = "MG *"    ; 005 Adding Mammo now.
                    
                    ;006-> We are going to be goofy here... if we use the ACTIVITY_SUBTYPE_CD on OC... we have several types that 
                    ;      mri... going to try and bring them all in.
                    ;      I think we are mostly safe from my querying, some MRI are missing act subtypes.
                    ;      we are pretty explicit with stat MRIs though.
                    or cnvtupper(oc.primary_mnemonic) = "MRA *"
                    or cnvtupper(oc.primary_mnemonic) = "MRI *"
                    or cnvtupper(oc.primary_mnemonic) = "MRV *"
                    or cnvtupper(oc.primary_mnemonic) = "MR *"
                    or cnvtupper(oc.primary_mnemonic) = "STAT * MRI *"
                    ;<-006
                  )
             )
          ;003<-
         )
     ;002<-
  join e
   where e.encntr_id =  o.originating_encntr_id
     and e.encntr_type_cd in ( 5043178.00 ;Clinic
                             , 309314.00  ;Recurring Clinic
                             , 3012539.00 ;Outpatient Message
                             ) ;Clinic, Recurring Clinic, Message
     and e.med_service_cd !=   950461507.00;cancelled

  join p
   where p.person_id = e.person_id
     and p.name_last_key != "ZZ*"
     and p.name_last_key != "CAREMOBILE"
     and p.name_last_key != "REGRESSION"
     and p.name_last_key != "TEST"
     and p.name_last_key != "CERNERTEST"
     and p.name_last_key != "*PATIENT*"
     AND not OPERATOR(P.NAME_LAST_KEY,"REGEXPLIKE","[0-9]")
     and p.active_ind = 1
     and p.end_effective_dt_tm > cnvtdatetime(sysdate)

  join org
   where org.organization_id = e.organization_id

order by o.person_id, o.order_id,  od.action_sequence desc
head report
    patients = 0
head p.person_id
    patients = patients + 1
    order_cnt = 0

    if(patients > size(rs->qual,5))
        stat=alterlist(rs->qual,patients+100)
    endif

    rs->qual[patients].firstname = cnvtcap(cnvtlower(p.name_first))
    rs->qual[patients].lastname = cnvtcap(cnvtlower(p.name_last))
    rs->qual[patients].personid = e.person_id
    rs->qual[patients].dob = datebirthformat(p.birth_dt_tm, p.birth_tz, 0, "@SHORTDATE4YR")
head o.order_id
    order_cnt = order_cnt + 1
    stat = alterlist(rs->qual[patients].orders, order_cnt)

    rs->qual[patients].orders[order_cnt].encntrid               = e.encntr_id
    rs->qual[patients].orders[order_cnt].reg_dt                 = e.reg_dt_tm
    rs->qual[patients].orders[order_cnt].location               = uar_get_code_display(e.location_cd)
    rs->qual[patients].orders[order_cnt].orderid                = o.order_id
    rs->qual[patients].orders[order_cnt].encntr_type            = uar_get_code_display(e.encntr_type_cd)
    rs->qual[patients].orders[order_cnt].Clinic_Name            = uar_get_code_display(e.loc_facility_cd)
    rs->qual[patients].orders[order_cnt].e_location             = org.org_name
    rs->qual[patients].orders[order_cnt].reg_dt                 = e.reg_dt_tm
    rs->qual[patients].orders[order_cnt].visit_reason           = e.reason_for_visit
    rs->qual[patients].orders[order_cnt].performing_location    =
        ;replace(replace(replace(replace(replace(replace(trim(od.oe_field_display_value)
        ;       ,"CT","")
        ;       ,"XR","")
        ;       ,"DEXA","")
        ;       ,"MAMMO","")
        ;       ,"US","")
        ;       ,"MR","")
        ;;001 note - MR replace here catches the first part of MRN on some of these locations... fun.
        ;;Replacing it over that.
        trim(od.oe_field_display_value, 3)
    rs->qual[patients].orders[order_cnt].performing_location_cd = od.oe_field_value
    rs->qual[patients].orders[order_cnt].order_date             = format(o.orig_order_dt_tm, "mm/dd/yy hh:mm")

    if(o.ordered_as_mnemonic > " ")
        rs->qual[patients].orders[order_cnt].order_name = o.ordered_as_mnemonic
    else
        rs->qual[patients].orders[order_cnt].order_name = uar_get_code_display(o.catalog_cd)
    endif

    rs->qual[patients].orders[order_cnt].target_service =
            replace(trim(substring(1,255,o.ordered_as_mnemonic)),"Referral to MedStar ","")

    rs->qual[patients].orders[order_cnt].referral_type = "radiology"
    rs->qual[patients].orders[order_cnt].order_cnt = order_cnt
    if(oc.activity_subtype_cd in (633750, 633747))
        rs->qual[patients].orders[order_cnt].modality = concat(trim(uar_get_code_display(oc.activity_subtype_cd),3)
                                                              ,' (', trim(uar_get_code_meaning(oc.activity_subtype_cd),3),')')

    elseif(substring(1, 3, uar_get_code_display(o.catalog_cd)) = "MRI")
      rs->qual[patients].orders[order_cnt].modality = concat(trim(uar_get_code_display(oc.activity_subtype_cd)), " (MRI)")

    elseif(substring(1, 3, uar_get_code_display(o.catalog_cd)) = "CT")
      rs->qual[patients].orders[order_cnt].modality = concat(trim(uar_get_code_display(oc.activity_subtype_cd)), " (CT)")

    elseif(substring(1, 3, uar_get_code_display(o.catalog_cd)) = "DXA")
      rs->qual[patients].orders[order_cnt].modality = "Dexa Scan"

    else
      rs->qual[patients].orders[order_cnt].modality = uar_get_code_display(oc.activity_subtype_cd)

    endif

foot p.person_id
    rs->qual[patients].order_cnt_tot = order_cnt

    if(order_cnt > 1)
        rs->qual[patients].multiple_orders = 'Y'
    endif

foot report
    stat = alterlist(rs->qual,patients)
    order_cnt = 0
with nocounter, time = 700


;---------------------------------------------------------------------------------------------------------------------------------
;   NO ENCOUNTERS MESSAGE
;---------------------------------------------------------------------------------------------------------------------------------
if((size(rs->qual,5) = 0)and $Type = 1)
    if(OpsInd !=1)
        select into $OUTDEV
          from dummyt
        Detail
            row + 1
            col 001 "URGENT CARE REFERRAL EXTRACT";report_title

            row + 1
            col 001 "You requested: "
            col 016  $Start_Dt
            col 040 "TO"
            col 045 $End_Dt

            row + 1
            col 001  "No Encounters were found for that data range."

            row + 1
            col 001 "Please Search Again"

            row + 2
    with format, separator = " "
  endif

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
   where pa.person_id = rs->qual[d.seq].personid
     and pa.person_alias_type_cd = 2 ; CMRN
     and pa.active_ind = 1
     and pa.end_effective_dt_tm > cnvtdatetime(curdate,curtime)

order by d.seq

head d.seq
    rs->qual[d.seq]->cmrn = cnvtalias(pa.alias,pa.alias_pool_cd)

with nocounter

;---------------------------------------------------------------------------------------------------------------------------------
;                   GETTING EMAIL INFO
;---------------------------------------------------------------------------------------------------------------------------------
Select into "nl:"
  FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
     , PHONE PH

  PLAN d

  join ph
   where ph.parent_entity_id = rs->qual[d.seq].PersonId
     and ph.active_ind = outerjoin(1)
     and ph.phone_type_cd = outerjoin(170)   ;Home
     and ph.beg_effective_dt_tm < outerjoin(cnvtdatetime(curdate,curtime))
     and ph.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime))
     AND PH.parent_entity_name = outerjoin("PERSON_PATIENT")
detail
    rs->QUAL[d.seq]->email = PH.phone_num

with nocounter, time = 1000

;---------------------------------------------------------------------------------------------------------------------------------
;                   GETTING PHONE INFO
;---------------------------------------------------------------------------------------------------------------------------------
Select into "nl:"
  from (dummyt d with seq = size(rs->qual,5)),
       phone ph

  PLAN d

  join ph
   where ph.parent_entity_id = rs->qual[d.seq].personid
     and ph.active_ind = 1
     and ph.phone_type_cd = 170  ;home
     and ph.beg_effective_dt_tm < cnvtdatetime(curdate,curtime)
     and ph.end_effective_dt_tm > cnvtdatetime(curdate,curtime)
     and ph.parent_entity_name = "PERSON"

order by d.seq
head d.seq
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
  from (dummyt d with seq = size(rs->qual,5))
     , address a

  plan d

  join a
   where a.parent_entity_id = rs->qual[d.seq].personid
     and a.address_type_cd = 756.00;   home
     and a.parent_entity_name = "PERSON"
     and a.active_ind = 1
     and a.end_effective_dt_tm > cnvtdatetime(sysdate)

order by d.seq

head d.seq
  rs->qual[d.seq].zip = a.zipcode

with nocounter, time = 400

;---------------------------------------------------------------------------------------------------------------------------------
;                   ADDITIONAL DX CODE DETAILS
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"
  from (dummyt d1 with seq = size(rs->qual,5))
     , (dummyt d2 with seq = 1)
     , diagnosis dg
     , nomenclature n
  plan d1
   where maxrec(d2, size(rs->qual[d1.seq].orders, 5))

  join d2

  join dg
   where dg.encntr_id = rs->qual[d1.seq].orders[d2.seq].encntrid
     and dg.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

  join n
   where n.nomenclature_id = dg.nomenclature_id
     and n.source_identifier_keycap in ( "R10.9"     ;Abdominal pain
                                       , "K64.9"    ;Hemorrhoids
                                       , "D64.9"    ;Unspecified anemia
                                       , "R19.4"    ;Change in bowel habits
                                       , "R14.0"    ;Bloating
                                       , "Z12.11"   ;Colon cancer screening
                                       , "Z80.0"    ;Family history of colon cancer
                                       , "R12"      ;Heartburn
                                       , "R1.0"     ;Nausea
                                       , "R11.10"   ;Vomiting
                                       , "R13.10"   ;Difficulty swallowing
                                       , "K62.5"    ;Bleeding
                                       , "K21.9"    ;GERD
                                       , "R13.10"   ;Dysphagia
                                       , "R10.13"   ;Epigastric pain
                                       , "B96.81"   ;H. Pylori
                                       , "R63.4"    ;weight loss
                                       , "K92.1"    ;Blood in stool
                                       )
     and n.active_ind = 1

order by d1.seq
detail
    rs->qual[d1.seq].orders[d2.seq].dx_code = n.source_identifier_keycap
    rs->qual[d1.seq].orders[d2.seq].dx_display = dg.diagnosis_display
    rs->qual[d1.seq].orders[d2.seq].source_string = n.source_string

WITH nocounter, time = 400


;;/************************************************************************************
;;                  GETTING ORDER DETAIL INFO Performing Location
;;*************************************************************************************/
select into "nl:"
  from (dummyt d1 with seq = size(rs->qual,5))
     , (dummyt d2 with seq = 1)
     , order_detail od

  plan d1
   where maxrec(d2, size(rs->qual[d1.seq].orders, 5))

  join d2

  join od
   where od.order_id = rs->qual[d1.seq].orders[d2.seq].orderid
     and od.oe_field_id in (831982505,;Performing Location Radiology
                            951929101, ;TARGET_PROVIDER
                            258409575,
                            951929101) ;Target Phone

order od.order_id, od.oe_field_id, od.action_sequence desc
head od.order_id
    null
head od.oe_field_id
    case(od.oe_field_id)
    of 831982505:
        rs->qual[d1.seq].orders[d2.seq].performing_location =
                ;replace(replace(replace(replace(replace(replace(trim(od.oe_field_display_value)
                ;       ,"CT", "")
                ;       ,"XR","")
                ;       ,"DEXA","")
                ;       ,"MAMMO","")
                ;       ,"US","")
                ;       ,"MR","")
                ;;001 note - MR replace here catches the first part of MRN on some of these locations... fun.
                ;;Replacing it over that.
                trim(od.oe_field_display_value, 3)

        rs->qual[d1.seq].orders[d2.seq].performing_location_cd = od.oe_field_value

    of 951929101:
        rs->qual[d1.seq].orders[d2.seq].target_provider = od.oe_field_display_value

        x=findstring(",",OD.oe_field_display_value, 1,0)

        rs->qual[d1.seq].orders[d2.seq].target_provider = substring(1,x+3,od.oe_field_display_value);od.oe_field_display_value
        if (rs->qual[d1.seq].orders[d2.seq].target_provider  in ("*, MD*","*, PA*","*, DP*","*, CR*") )
          rs->qual[d1.seq].orders[d2.seq].target_provider = substring(1,x+3,od.oe_field_display_value)
        else
          rs->qual[d1.seq].orders[d2.seq].target_provider = substring(1,x-1,od.oe_field_display_value);od.oe_field_display_value
        endif

        if(rs->qual[d1.seq].orders[d2.seq].target_provider in ("1*","2*","3*","4*","5*","6*","7*","8*","9*","MedStar*") )
          rs->qual[d1.seq].orders[d2.seq].addr_prov_flag = "Y"
        endif

        if (rs->qual[d1.seq].orders[d2.seq].target_provider in("MedStar*") )
          rs->qual[d1.seq].orders[d2.seq].target_provider = substring(1,x-1,od.oe_field_display_value);od.oe_field_display_value
        endif

        if (rs->qual[d1.seq].orders[d2.seq].target_provider in("Ple*") )
          rs->qual[d1.seq].orders[d2.seq].target_provider = "REMOVED"
        endif

    of 258409575:
        rs->qual[d1.seq].orders[d2.seq].target_provider = od.oe_field_display_value

    of 951929101:
        X = 0

        x=findstring("PH. ",od.oe_field_display_value, 1,0)

        if(x > 1)
            rs->qual[d1.seq].orders[d2.seq].target_phone = substring(x+4,x+12,od.oe_field_display_value)
        endif

    endcase

with nocounter, expand = 1



;/*********************************************************************************************
;                   GETTING encounter info
;**********************************************************************************************/
Select into "nl:"
  FROM (DUMMYT D WITH SEQ = SIZE(RS->QUAL,5))
     , (dummyt d2 with seq = 1)
     , encntr_alias     ea

  plan d
   where maxrec(d2, size(rs->qual[d.seq].orders, 5))

  join d2

  join ea
   where ea.encntr_id = rs->qual[d.seq].orders[d2.seq].encntrid
     and ea.encntr_alias_type_cd in (1077,10790); fin,mrn
     and ea.active_ind = 1
order by d.seq, ea.encntr_id, ea.encntr_alias_type_cd
detail
    case(ea.encntr_alias_type_cd)
        of 1077: rs->qual[d.seq].orders[d2.seq].fin = ea.alias
        of 1079: rs->qual[d.seq].mrn = ea.alias
    endcase
with nocounter, time = 500

call echorecord(rs)
;---------------------------------------------------------------------------------------------------------------------------------
;               OUTPUT DATA TO $OUTDEV/EMAILING
;---------------------------------------------------------------------------------------------------------------------------------
call echorecord(rs)

select
  if(opsind = 1 and findfile(value(output_file))=0); not found
      with nocounter, format, format=stream, separator=" ", pcformat('"', ',',1),compress, check,heading

  elseif(opsind = 1 and findfile(value(output_file))=1); found
      with nocounter, format, format=stream, separator=" ", pcformat('"', ',',1),compress, check, noheading, append

  else
      with nocounter, time = 1500, format, separator = " "
  endif

  into value(output_file)
       lastname                      = trim(substring(1, 30, rs->qual[d1.seq].lastname))
     , firstname                     = trim(substring(1, 30, rs->qual[d1.seq].firstname))
     , order_count                   = rs->qual[d1.seq].orders[d2.seq].order_cnt
     , order_count_total             = rs->qual[d1.seq].order_cnt_tot
     , multiple_orders               = trim(substring(1, 10,rs->qual[d1.seq].multiple_orders))
     , email                         = trim(substring(1, 75, rs->qual[d1.seq].email))
     , phone                         = trim(substring(1, 30, rs->qual[d1.seq].phone))
     , referral_target_service       = trim(substring(1, 100, rs->qual[d1.seq].orders[d2.seq].target_service))
     , referral_target_provider_name = trim(substring(1, 75, rs->qual[d1.seq].orders[d2.seq].target_provider))
     , referral_target_phone         = trim(substring(1, 15, rs->qual[d1.seq].orders[d2.seq].target_phone))
     , address_provider_flag         = trim(substring(1, 15, rs->qual[d1.seq].orders[d2.seq].addr_prov_flag))
     , cmrn                          = trim(substring(1, 30, rs->qual[d1.seq].cmrn))
     , order_name                    = trim(substring(1, 75, rs->qual[d1.seq].orders[d2.seq].order_name))
     , date_of_service               = format(rs->qual[d1.seq].orders[d2.seq].reg_dt, "mm/dd/yyyy hh:mm:ss;;d")
     , location                      = trim(substring(1, 75, rs->qual[d1.seq].orders[d2.seq].e_location))
     , personid                      = rs->qual[d1.seq].personid
     , orderid                       = rs->qual[d1.seq].orders[d2.seq].orderid
     , referral_type                 = trim(substring(1, 10,rs->qual[d1.seq].orders[d2.seq].referral_type))
     , modality                      = trim(substring(1, 50,rs->qual[d1.seq].orders[d2.seq].modality))
     , ref_to_location               = trim(substring(1, 50,rs->qual[d1.seq].orders[d2.seq].performing_location))  ;001

  from (dummyt d1 with seq           = value(size(rs->qual,5))),
       (dummyt d2 with seq = 1)

  plan d1
   where maxrec(d2, size(rs->qual[d1.seq].orders, 5))

  join d2
   where rs->qual[d1.seq].orders[d2.seq].performing_location_cd in (
                           2627174945.00 ;Medstar Chevy Chase CT MR US XR
                         , 2627174677.00 ;Medstar Rockville CT MR XR
                         , 831586843.00  ;Medstar Bel Air CT XR DEXA MAMMO MR US
                         , 831587279.00  ;Medstar Brandywine CT XR DEXA MR US
                         , 831587733.00  ;Medstar Lafayette I MR
                         , 831588331.00  ;Medstar Lafayette II CT XR DEXA MAMMO US
                         , 831588519.00  ;Medstar Timonium MR
                         , 5757404269.00 ;MRN Chevy Chase at Barlow                                  ;004 Adding.
                         , 4567751099.00 ;BUILD BARLOW  THIS CAN PROBABLY BE REMOVED AFTER PROD MOVE ;004 Adding.
                         ;001->          
                         , 1821481899.00 ;MedStar Georgetown Univ All Modalities
                         , 1821487843.00 ;Medstar Washington Hosp All Modalities
                         ;001<-
                        )

order by lastname,firstname
with nocounter, time = 1500, format, separator = " "






#exit_program2


#exit_program
end
go


