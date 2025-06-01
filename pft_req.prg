/*******************************************************************************************

        Source file name:       card_req
        Object name:            card_req

********************************************************************************************
                      GENERATED MODIFICATION CONTROL LOG
********************************************************************************************
Mod     Date        Analyst                   Comment
--- ----------- ----------------------  -----------------------------------------------------
001  __/__/____ ____________            initial implementation
002 09/20/2013  Brian Twardy            See log below
003 09/23/2013  Brian Twardy            See log below
004 10/29/2014  Brian Twardy            See log below
005 06/11/2015  Brian Twardy            See log below
009 02/05/2020  Swetha Srini            See log below
010 07/19/2022  Swetha Srini            See log below
********************************************************************************************
--------------------------------
#002 09/20/2013    Brian Twardy
Original CCL:  cust_script: card_req.prg
New CCL:       cust_script: card_req.prg  (no name change.)
OPAS Request:  n/a
For printer, umhmbekgpt194, and requisition route, 'Cardiology Vascular Lab', there have
been instances where the requisition was not printing. This was verified with the use
of the White Marsh printer too.  A change has been made to NOT loop through the request... then this
was reversed.
--------------------------------
#003 09/23/2013    Brian Twardy
Original CCL:  cust_script: card_req.prg
New CCL:       cust_script: card_req.prg  (no name change.)
OPAS Request:  n/a
The change to NOT loop through the request was put back in. This was done because we want
the Cancel/Reorder function to work.  It works.... now.
--------------------------------
#004 10/29/2014    Brian Twardy
Original CCL:  cust_script: card_req.prg
New CCL:       cust_script: card_req.prg  (no name change.)
OPAS Incident: R2:000042290799   (For Rebecca Clark of GSH)
The Order/Accession# (order_id) was printing with '.00' added to the end.  In P41,
the CNVTINT function seemed to not work any more.  In TST41, it does work.
So, the following function within a function within a function has now been added to
replace the CNVTINV(card_req->order_no) that had been in the Layout Builder for this
field:   trim(replace(cnvtstring(card_req->order_no,20,2),".00",""))
--------------------------------
#005 06/11/2015    Brian Twardy
Original CCL:  cust_script: card_req.prg
New CCL:       cust_script: card_req.prg  (no name change.)
With Avneet Baid, we made a change to eliminate the order details from being duplicated in this
report.  This followed an earlier EAD # change made by Avneet Baid to this CCL for MCGA20163,
OPAS Request/Task R2:000082162984.
--------------------------------
#006 06/22/2017    Brian Twardy
OPAS incident: R2:000056369270   (Customer: Martin Mathias - Technical Director, MGUH, Non-Invasive Cardiology)
Original CCL:  cust_script: card_req.prg
New CCL:       cust_script: card_req.prg  (no name change.)
This report has a major issue of listing the diagnoses that had already expired. That has now been addressed. Besides
eliminating any expired diagnoses, the ones that do make it onto the report are now displayed in "ranking" order (primary,
then secondary, then tertiary), then in priority sequence (1, 2, 3,...etc), then in alphabetical order.. for those
without a ranking or a priority.
--------------------------------
#007 05/10/2018    Brian Twardy
SOM incident: INC4814992   (Customers: Jeffery Sano and Moshe Mehlman, both of MWHC)
CCL script:  cust_script: card_req.prg     (no name change)
The attending physician was not being pulled into the report as accurately as it should have been. This
has been corrected by making sure that the "current" attending is being pulled into the report, rather
than having the report pick any active attending physician for the encounter included in the report.
--------------------------------
;  008 12-04-2018 DMA112   SOM Incident 6592689      Migration issue - missing MMC and SHMC addresses
--------------------------------
#009 02-NOV-2020 Swetha Srinivasaraghavan
MCGA/SOM: MCGA 219180/TASK3170192
CCL script:  cust_script: card_req.prg     (no name change)
The requisition printed garbage data for Cardiac and Vascular orders for Clinics.
Originating order_id from the Orders table has been included to ensure that the requisition prints with accurate data.
--------------------------------
#010 03/07/2021    Brian Twardy
SOM incident: INC11839625   (Customers: Crystal Pugh and Teresa Leydon)
CCL script:  cust_script: card_req.prg     (no name change)
The attending physician was not being pulled into the report for future orders. The change here is just
a continuation of modification #009.
--------------------------------
#011 07/19/2022 Swetha Srinivasaraghavan
MCGA/SOM: MCGA 230206
CCL script:  cust_script: card_req.prg and layout
ICD-10 code added to the Dx display and the signature verbiage updated to say 'Electronically Signed By'.
--------------------------------
#012 11/09/2022    Brian Twardy
MCGA: 235853
SOM RITM/Task: RITM3142767 / TASK5769450
Requesters: Karthi Dandapani and David Havrilla, both of WHC
CCL script:  cust_script: card_req.prg     (no name change)
Supressing the automatic printing of three Echocardiogram orders for WHC only.
--------------------------------
#013 11/26/2024    Michael Mayes
MCGA: 351256
SOM RITM/Task: SCTASK0135786
Requesters:
CCL script:  I'm stealing Card req... for a PFT orders Pulmonary Function Test... panic.
They need future orders supported... and now are trying to change a couple of data points.  Order Dx instead of Enc DX...
Prov ID signing instead of update ID.
--------------------------------
#014 02/20/2025    Michael Mayes
MCGA: 352700
SOM RITM/Task: SCTASK0152269
Requesters:
CCL script:  From INC1026503.  Looks like if we fail to have an enc MRN... we hard fail on a query below.
             I need to outerjoin that, and then come up with a way to deliver a correct MRN.
Prov ID signing instead of update ID.
--------------------------------
--------------------------------
#015 04/25/2025    Michael Mayes
MCGA: 353299
SOM RITM/Task: PEND
Requesters:
CCL script:  Change some labels: Ordering and Attending MD to Ordering and Attending Physician
             Add a label: for CC Physician.
--------------------------------
*****************************************************************************************/


drop program pft_req:dba go
create program pft_req:dba

prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.

with OUTDEV

/***************************************************/

;declare GVC_PRSNL_NAME = vc with noconstant(' ')
;declare GVC_FULL_NAME = vc with noconstant(' ')
;call echojson(reqinfo, "1_reinfo_tst")
;
;


;;Testing via tst file
;free record request go;record request
;(
;   1 person_id = f8
;   1 print_prsnl_id = f8
;   1 order_qual[1]
;       2 order_id = f8
;       2 encntr_id = f8
;       2 conversation_id = f8
;   1 printer_name = c50
;) go
;
;set request->person_id = 5398986.00 go
;set request->order_qual[1].encntr_id = 16066670.00 go
;set request->order_qual[1].order_id = 428198452 go
;set request->printer_name = "TYRGAPPRMLP001" go
;
;execute axb_card_req go

/***************************************************/
 /***************************************************/

record request
(
    1 person_id = f8
    1 print_prsnl_id = f8
    1 order_qual[*]
        2 order_id = f8
        2 encntr_id = f8
        2 conversation_id = f8
    1 printer_name = c50
)


declare inerror_cd     = f8 with protect, constant(uar_get_code_by("MEANING", 8, "INERROR"))
declare test_seq = i2
declare mrn_cd = f8 with constant ( uar_get_code_by( "MEANING", 319, "MRN" ) )
declare FIN = f8 with constant ( uar_get_code_by( "MEANING", 319, "FIN NBR" ) )
declare EAD = f8 with constant ( uar_get_code_by( "MEANING", 4, "CMRN" ) );ADDED 04/13/2015
DECLARE ATTENDING_MD = F8 WITH PUBLIC, CONSTANT(UAR_GET_CODE_BY("MEANING",333,"ATTENDDOC"))
;declare MEA_WGHT = f8 with protected, constant(uar_get_code_by("DISPLAYKEY",72,"WEIGHTMEASURED"))
;declare MEA_HGHT = f8 with protected, constant(uar_get_code_by("DISPLAYKEY",72,"HEIGHTLENGTHMEASURED"))
DECLARE result_val= VC WITH PROTECTED,NOCONSTANT("")
DECLARE result_unit = VC WITH PROTECTED,NOCONSTANT("")
DECLARE M_DIAG = VC WITH NOCONSTANT(" ")
DECLARE A_STRING = VC WITH NOCONSTANT(" ")
declare M_isolate = vc with NOCONSTANT(" ")
declare bus_add_cd = f8 with protect, constant(uar_get_code_by("MEANING", 212, "BUSINESS")) ;00x ss
;set weight_cd = uar_get_code_by("DISPLAYKEY", 72, "WEIGHTMEASURED")
;set height_cd = uar_get_code_by("DISPLAYKEY", 72, "HEIGHTLENGTHMEASURED")

set weight_cd = uar_get_code_by("DISPLAYKEY", 72, "WEIGHTDOSING")
set height_cd = uar_get_code_by("DISPLAYKEY", 72, "HEIGHTLENGTHDOSING")

declare canceled_cd    = f8 with protect, constant(uar_get_code_by("MEANING", 12025, "CANCELED"))
declare cnt_1 = i4
DECLARE IS_CODE = VC WITH NOCONSTANT(" ")
DECLARE IS_CODE_DISP = VC WITH NOCONSTANT(" ")
DECLARE IS_CODE_MEANING = VC WITH NOCONSTANT(" ")

declare idx = i4
declare pos = i4
declare od_cnt = i4
;declare rec_cnt  = i4          ; 002 09/20/2013  not used, because the loop has been removed.
declare rec_cnt  = i4           ; 003 09/23/2013  Returned.
declare PRIORITY_VAL = vc with protect, noconstant("")

declare ordr_comment_type = f8 with protect, constant(uar_get_code_by("DISPLAYKEY",14,"ORDERCOMMENT"))



declare NRH_ID = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "NRHPHYSICIANINDENTIFIER" ) )
declare WHC_ID = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "WHCPHYSICIANINDENTIFIER" ) )
declare GUH_ID = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "GUHPHYSICIANINDENTIFIER" ) )
declare BLT_ID = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "BLTPHYSICIANIDENTIFIER" ) )
declare NPI_ID = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "NPI" ) )
;008 - begin
declare MMC_ID = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "MMCPHYSICIANIDENTIFIER" ) )
declare SMHC_ID = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "SMDPHYSICIANIDENTIFIER" ) )
declare MMC_ID1 = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "MMCPHYSICIANIDENTIFIER" ) )
declare SMHC_ID1 = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "SMDPHYSICIANIDENTIFIER" ) )
;008 - begin
declare NRH_ID1 = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "NRHPHYSICIANINDENTIFIER" ) )
declare WHC_ID1 = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "WHCPHYSICIANINDENTIFIER" ) )
declare GUH_ID1 = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "GUHPHYSICIANINDENTIFIER" ) )
declare BLT_ID1 = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "BLTPHYSICIANIDENTIFIER" ) )
declare NPI_ID1 = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "NPI" ) )


/**************************************************************
; DVDev Start Coding
**************************************************************/

/**************************************************************
; DVDev Start Coding
**************************************************************/

EXECUTE reportrtl

%i cust_script:pft_req.dvl

free record card_req
record card_req
(
    1 encntr_id    =     f8
    1 person_id    =     f8
    1 action_cd = F8
    1 action_personnel_id = f8              ; 012 11/09/2022 New
    1 prsnl_name = vc
    1 prsnl_id = vc
    1 sign_dt_tm = vc  ;013
    1 mrn          =     vc
    1 fin          =     vc
    1 ead          = vc
    1 pat_reg = vc
    1 PID = VC
    1 PID1 = VC
    1 facility     =     vc
    1 loc_facility_cd =  f8                     ; 012 11/09/2022 New
    1 fac_addr     =     vc
    1 fac_city     =     vc
    1 encntr_type_cd =   f8                     ; 012 11/09/2022 New
    1 dob          =     dq8
    1 age          =     vc
    1 Loc_unit     =     vc
    1 Loc_room     =     vc
    1 loc_bed      =     vc
    1 sex          =     vc
    1 pt_name      =     vc
    1 attend_MD     =    vc
    1 admit_dt     =     dq8
    1 order_dt_tm  =     dq8
    1 dis_ord_dt_tm  =   dq8
    1 order_name   =     vc
    1 catalog_cd   =     f8                     ; 012 11/09/2022 New
    1 ordering_md  =     vc
    1 PROV_ID =  VC
    1 full_diag_disp =     vc
    1 full_alg_disp = vc
    1 allergy      =     vc
    1 transport    =     c50
    1 order_status =     vc
    1 order_no     =     f8
    1 order_comment =    vc
    1 indication    =    vc
    1 isolation = vc
    1 freq = vc
    1 spec_inst = vc
    1 priority = vc
    1 height   = vc
    1 weight  = vc
    1 diag[*]
        2 diag_display =     vc
    1 ord_detail[*]
        2 title = vc
        2 meaning = vc
        2 value = vc
    1 allg[*]
      2 allg_str = vc
)



record allergy
( 1 cnt = i2
  1 qual[*]
    2 list = vc
  1 line = vc
  1 line_cnt = i2
  1 line_qual[*]
    2 line = vc
)


record pt
( 1 line_cnt = i2
  1 lns[*]
    2 line = vc
)
call echojson(request, "/cerner/d_p41/cust_output_2/card_req.dat")  ; 00x ss troubleshooting 2/28/2022 ss
;;Get allergies once
select into "nl:"
from allergy a,
  (dummyt d with seq = 1),
  nomenclature n
plan a
  where a.person_id = request->person_id
    and a.active_ind = 1
    and a.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
    and (a.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
      or a.end_effective_dt_tm = NULL)
    and a.reaction_status_cd != canceled_cd
join d
join n
  where n.nomenclature_id = a.substance_nom_id
order cnvtdatetime(a.onset_dt_tm)
head report
  allergy->cnt = 0
detail
  if (size(n.source_string,1) > 0 or size(a.substance_ftdesc,1) > 0)     ;019
    allergy->cnt = allergy->cnt + 1
    stat = alterlist(allergy->qual,allergy->cnt)
    allergy->qual[allergy->cnt].list = a.substance_ftdesc
    if (size(n.source_string,1) > 0)     ;019
      allergy->qual[allergy->cnt].list = n.source_string
    endif
  endif
with nocounter,outerjoin=d,dontcare=n

for (x = 1 to allergy->cnt)
  if (x = 1)
    set allergy->line = allergy->qual[x].list
  else
    set allergy->line = concat(trim(allergy->line),", ",
      trim(allergy->qual[x].list))
  endif
endfor

if (allergy->cnt > 0)
   set pt->line_cnt = 0
   set max_length = 90
   execute dcp_parse_text value(allergy->line), value(max_length)
   set stat = alterlist(allergy->line_qual, pt->line_cnt)
   set allergy->line_cnt = pt->line_cnt
   for (x = 1 to pt->line_cnt)
     set allergy->line_qual[x].line = pt->lns[x].line
   endfor
endif

for(rec_cnt = 1 to  size(request->order_qual,5))  ; 002 09/20/2013   This loop has been removed.  003 09/23/2013  Returned.

/********** 009 Added Begins - In case of future orders, encounter ID will be 0**********/
IF(request->order_qual[rec_cnt].encntr_id = 0)
    SELECT INTO "NL:"
    FROM ORDERS   O
    WHERE O.order_id = request->order_qual[rec_cnt].order_id
    DETAIL
        request->order_qual[rec_cnt].encntr_id = O.originating_encntr_id
    WITH NOCOUNTER, SEPARATOR=" ", FORMAT
ENDIF
/********** 009 Added Ends- In case of future orders, encounter ID will be 0************/
 CALL ECHORECORD(REQUEST)
SELECT into "nl:"
    EA.ALIAS
    , P.NAME_FULL_FORMATTED
    , P_SEX_DISP = UAR_GET_CODE_DISPLAY(P.SEX_CD)
    , Age = CNVTAGE(P.BIRTH_DT_TM)
    , format(P.BIRTH_DT_TM, ";;q")
    , e.encntr_id
    , E.LOC_NURSE_UNIT_CD
    , E_LOC_NURSE_UNIT_DISP = UAR_GET_CODE_DISPLAY(E.LOC_NURSE_UNIT_CD)
    , Facility =  UAR_GET_CODE_DESCRIPTION(e.loc_facility_cd)
    , E.REG_DT_TM
    , E.reason_for_visit
    , ENCNTR_TYPE = UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CD)
    , TRANSPORT_MODE = UAR_GET_CODE_DISPLAY(e.admit_mode_cd)
    , O.CATALOG_CD
    , O_CATALOG_DISP = UAR_GET_CODE_DISPLAY(O.CATALOG_CD)
    , ORDER_NAME = trim(SUBSTRING(1,60, O.order_mnemonic))      ; 002 09/20/2013  enlarged to 60.
    , O.ENCNTR_ID
    , o.order_id
    , od.detail_sequence
    , O.ORIG_ORDER_DT_TM
    , O.ORDER_STATUS_CD
    , O.CURRENT_START_DT_TM
    , O.ACTIVE_STATUS_DT_TM
    , O_ORDER_STATUS_DISP = UAR_GET_CODE_DISPLAY(O.ORDER_STATUS_CD)  ; 002 09/20/2013  Status in now action.
    , EL_LOC_ROOM_DISP = UAR_GET_CODE_DISPLAY(E.LOC_ROOM_CD)
    , EL_LOC_BED_DISP = UAR_GET_CODE_DISPLAY(E.LOC_BED_CD)
    , ALIAS1 = EA.ALIAS
    , ALIAS2 = SUBSTRING( 1, 25, CNVTALIAS(EA1.alias, EA1.alias_pool_cd))
    , ALIAS3 = SUBSTRING( 1, 25, CNVTALIAS(PA1.alias, PA1.ALIAS_POOL_CD))
    ,c.result_val

FROM
      ORDERS   O
    , order_action oad
    , ORDER_CATALOG OC
    , OE_FORMAT_FIELDS OFF
    , ORDER_DETAIL OD
    , CODE_VALUE CV
    , ENCOUNTER   E
    , ENCNTR_ALIAS   EA
    , ENCNTR_ALIAS   EA1
    , PERSON_ALIAS   PA1
    , PERSON   P
;   , ENCNTR_LOC_HIST   EL
    , dummyt dt
    , clinical_event C    ; height
    , clinical_event CW   ;weight


PLAN o
    where o.order_id = request->order_qual[rec_cnt].order_id        ; 003 09/23/2013  Returned.
;   where o.order_id =  request->order_qual[1].order_id             ; 002 09/20/2013  replacement.
    and o.active_ind+0 = 1

join oad

where oad.ORDER_ID = o.ORDER_ID
and oad.ACTION_SEQUENCE = o.LAST_ACTION_SEQUENCE

JOIN OC
    where OC.catalog_cd = O.catalog_cd

JOIN OD
    WHERE OD.order_id = O.order_id

JOIN OFF
    WHERE OC.oe_format_id = OFF.oe_format_id
    and off.oe_field_id = od.oe_field_id
    ;015-> adding some logic because they want to pull in a specific detail and it's built as flag 2. 
    ;and off.accept_flag != 2.00 ; 0.00  REQUIRED, 1.00  OPTIONAL, 2.00  NO DISPLAY,  3.00   DISPLAY ONLY
    and (   off.accept_flag != 2.00 ; 0.00  REQUIRED, 1.00  OPTIONAL, 2.00  NO DISPLAY,  3.00   DISPLAY ONLY
         or off.oe_field_id = 740848017.00
        )
    ;015<-
JOIN CV
    WHERE CV.code_value = OD.oe_field_id
    ;AND CV.display_key IN ("PRIORITY","FREQUENCY","EKGINDICATION","SPECIAL INSTRUCTIONS","ISOLATIONCODE")
join P
    where P.person_id =  request->person_id

JOIN PA1
    where PA1.PERSON_ID = outerjoin(P.PERSON_ID)
    and PA1.PERSON_ALIAS_TYPE_CD+0 = OUTERJOIN(EAD)
    and PA1.ACTIVE_IND = OUTERJOIN(1)


join E

;   #002 09/20/2013  "e.encntr_id = request->order_qual[1].encntr_id" has replaced "e.encntr_id = o.ENCNTR_ID" below.

;   where e.encntr_id = o.ENCNTR_ID                         ; 002 09/20/2013 replaced with the line below.
    where e.encntr_id =  request->order_qual[rec_cnt].encntr_id ; 003 09/23/2013  Returned.
;   where e.encntr_id = request->order_qual[1].encntr_id    ; 002 09/20/2013 replacement.

;014-> Outerjoining all this
JOIN ea  WHERE EA.ENCNTR_ID               = outerjoin(E.ENCNTR_ID)
           and EA.ENCNTR_ALIAS_TYPE_CD+0  = outerjoin(mrn_cd)
           and ea.ACTIVE_IND              = outerjoin(1)
           and EA.END_EFFECTIVE_DT_TM     > outerjoin(CNVTDATETIME(CURDATE, curtime3))
JOIN ea1 WHERE EA1.ENCNTR_ID              = outerjoin(E.ENCNTR_ID)
           and EA1.ENCNTR_ALIAS_TYPE_CD+0 = outerjoin(FIN)
           and ea1.ACTIVE_IND             = outerjoin(1)
           and EA1.END_EFFECTIVE_DT_TM    > outerjoin(CNVTDATETIME(CURDATE, curtime3))
;014<-

;JOIN EL
;   WHERE EL.encntr_id = E.encntr_id
;       and EL.beg_effective_dt_tm +0  <= CNVTDATETIME(CURDATE, curtime3)
;   and el.end_effective_dt_tm +0 >= CNVTDATETIME(CURDATE, curtime3)

JOIN  dt
Join C
    where c.encntr_id = e.encntr_id
    and c.event_cd +0  = height_cd;,weight_cd)
    and c.performed_dt_tm = (select max(ce.performed_dt_tm)
                        from clinical_event ce
                        where c.encntr_id = ce.encntr_id
                        and c.event_cd = ce.event_cd)

Join Cw
    where cw.encntr_id = e.encntr_id
    and cw.event_cd +0  = weight_cd
    and cw.performed_dt_tm = (select max(ce.performed_dt_tm)
                        from clinical_event ce
                        where cw.encntr_id = ce.encntr_id
                        and cw.event_cd = ce.event_cd)

;order by o.order_id                                        ; 005 06/11/2015  Brian changed the "order by"
order by o.encntr_id, o.order_id, od.detail_sequence        ; 005 06/11/2015  Here is the change.
head report
    cnt_1 = 0

Head o.encntr_id

   NULL
Head o.order_id
    card_req->encntr_id = e.encntr_id
    card_req->person_id = p.person_id
    card_req->mrn = ALIAS1
    card_req->fin = ALIAS2
    card_req->ead = ALIAS3
    card_req->pat_reg = ENCNTR_TYPE
    card_req->facility = Facility
    card_req->loc_facility_cd = e.loc_facility_cd                       ; 012 11/09/2022 New
    card_req->encntr_type_cd = e.encntr_type_cd                         ; 012 11/09/2022 New
    card_req->pt_name = p.name_full_formatted
    card_req->dob = P.BIRTH_DT_TM
    card_req->age = Age
    card_req->sex = P_SEX_DISP
    card_req->Loc_unit = E_LOC_NURSE_UNIT_DISP
    card_req->Loc_room = EL_LOC_ROOM_DISP
    card_req->loc_bed  = EL_LOC_BED_DISP
    card_req->admit_dt = e.reg_dt_tm
    ;card_req->attend_MD = att.name_full_formatted
    card_req->order_dt_tm = o.orig_order_dt_tm
    card_req->dis_ord_dt_tm = o.discontinue_effective_dt_tm
    card_req->order_name = ORDER_NAME
    card_req->catalog_cd = o.catalog_cd                                 ; 012 11/09/2022 New
    ;card_req->ordering_md = order_MD
    card_req->action_cd = oad.ACTION_TYPE_CD
    card_req->action_personnel_id = oad.action_personnel_id             ; 012 11/09/2022 New

    if(e.loc_facility_cd = 633867.00)
        card_req->fac_addr = "9000 Franklin Square Drive"
        card_req->fac_city = "Baltimore, MD 21237"

    elseif(e.loc_facility_cd = 4363210.00)
        card_req->fac_addr = "3800 Reservoir Road"
        card_req->fac_city = "Washington, DC 20007"

    elseif(e.loc_facility_cd = 4362818.00)
        card_req->fac_addr = "5601 Loch Raven Boulevard"
        card_req->fac_city = "Baltimore, MD 21239"

    elseif(e.loc_facility_cd = 4363058.00)
        card_req->fac_addr = "3001 South Hanover Street"
        card_req->fac_city = "Baltimore, MD 21225"

    elseif(e.loc_facility_cd = 4364516.00)
        card_req->fac_addr = "102 Irving Street NW"
        card_req->fac_city = "Washington, DC 20010"

    elseif(e.loc_facility_cd = 4363156.00)
        card_req->fac_addr = "201 East University Parkway"
        card_req->fac_city = "Baltimore, MD 21218"

    elseif(e.loc_facility_cd = 4363216.00)
        card_req->fac_addr = "110 Irving St. NW "
        card_req->fac_city = "Washington, DC 20010"

    ; begin 008 - migration fix - add addresses for MMC and SHMC
    elseif(e.loc_facility_cd = 446795444.00)
        card_req->fac_addr = "18101 Prince Phillip Dr"
        card_req->fac_city = "Olney, MD 20832"

    elseif(e.loc_facility_cd = 465210143.00)
        card_req->fac_addr = "7503 Surratts Rd"
        card_req->fac_city = "Clinton, MD 20735"
    ; end 008 - migration fix - add addresses for MMC and SHMC
    endif

    if(e.admit_mode_cd>0)
        card_req->transport = TRANSPORT_MODE
    else
        card_req->transport = "N/A"
    endif

    card_req->order_status = uar_get_code_display(o.order_status_cd) ;;009 ss
    card_req->order_no = O.order_id
    ;card_req->order_comment = COMMENTS;OA.order_detail_display_line


Head od.detail_sequence
    call echo(od.OE_FIELD_DISPLAY_VALUE)
    if(od.oe_field_meaning != "ISOLATIONCODE")
        cnt_1 = cnt_1+1
        stat = alterlist(card_req->ord_detail, cnt_1)

        card_req->ord_detail [cnt_1].title = cv.display
        card_req->ord_detail [cnt_1].value = od.oe_field_display_value
        card_req->ord_detail [cnt_1].meaning = od.oe_field_meaning
        
        
    endif

    if(od.oe_field_meaning = "DURATIONUNIT")
        pos = locateval(idx, 1,size(card_req->ord_detail,5),"DURATION" ,card_req->ord_detail[idx].meaning)
        if(pos > 0)
            card_req->ord_detail[pos].value = concat(card_req->ord_detail[pos].value, " ", od.oe_field_display_value)
        endif
    endif


    if(od.oe_field_meaning = "ISOLATIONCODE")
        if(IS_CODE > "")
             IS_CODE = notrim(concat(IS_CODE,", "))
        endif

        IS_CODE = concat(IS_CODE, od.oe_field_display_value)
        IS_CODE_DISP = cv.display
        IS_CODE_MEANING = od.oe_field_meaning
    endif

detail
/***************************Height and Weight***********************************************************/

     ;if (c.event_cd = height_cd)
   card_req->height = concat(trim(c.result_val)," ",
      trim(uar_get_code_display(c.result_units_cd)))
     ;elseif(c.event_cd = weight_cd)
    card_req->weight = concat(trim(cw.result_val)," ",
      trim(uar_get_code_display(cw.result_units_cd)))
  ;endif

foot report
    if(IS_CODE > "")
        cnt_1 = cnt_1+1
        stat = alterlist(card_req->ord_detail, cnt_1)

        card_req->ord_detail [cnt_1].title = trim(IS_CODE_DISP)
        card_req->ord_detail [cnt_1].value = trim(IS_CODE)
        card_req->ord_detail [cnt_1].meaning = trim(IS_CODE_MEANING)
    endif

WITH nocounter, outerjoin = dt

call echo('test')
call echorecord(card_req)


;014-> Hey we can miss out on MRN now due to the outerjoin above.
;      And check it out, I figured out how to query for the correct person alias
select into 'nl:'
      alias1 = pa.alias;cnvtalias(pa.alias, pa.alias_pool_cd)  Too big... we need the naked MRN
  
  from person_alias pa
     , encounter e
     , org_alias_pool_reltn oapr
 
 where e.encntr_id                     = request->order_qual[rec_cnt].encntr_id
   
   and oapr.organization_id            =  e.organization_id
   and oapr.alias_entity_alias_type_cd =  10.0  ;MRN
   and oapr.alias_entity_name          =  'PERSON_ALIAS'
   
   and pa.person_id                    =  e.person_id
   and pa.person_alias_type_cd         =  oapr.alias_entity_alias_type_cd
   and pa.alias_pool_cd                =  oapr.alias_pool_cd
   and pa.end_effective_dt_tm          >  cnvtdatetime(curdate, curtime3)
   and pa.active_ind                   =  1
detail
    card_req->mrn = alias1
with nocounter

;014<-


 /************************suppression**********/
if(card_req->action_cd in( 2529.00, 2539.00));Completed; Status change   09/20/2013
;, 2526.00, 2532.00, 2539.00 removed other status.
    go to end_of_program
endif

; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
; 012 11/09/2022   New suppression of some Echocariogram ordersd for only WHC

If (request->print_prsnl_id < 10.00 and         ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition
    card_req->catalog_cd in (101806712.00,      ; Echocardiogram Complete
                             101806210.00,      ; Echocardiogram Complete With Bubble Study
                             101806282.00) and  ; Echocardiogram Limited Follow Up
    card_req->loc_facility_cd = 4363216.00 and  ; WashingtonHosp
    card_req->action_cd in (2526.00,            ; Cancel
                            2524.00,            ; Activate          ;11/10/2023 this is new
                            2534.00) and        ; Order
    card_req->encntr_type_cd in ( 309310.00,    ; Emergency
                                  309308.00,    ; Inpatient
                                  309309.00,    ; Outpatient        ;11/10/2023 this is new
                                  309312.00,    ; Observation
                                 5048231.00))   ; Ambulatory Surgery
    go to end_of_program
endif
; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -


/********************************NPI*************************************************/
SELECT
;p.username   ; 002 09/20/2013  p????
pn.username   ; 002 09/20/2013  replacement

FROM
    PRSNL   PN
;;  , orders OAD  ;002 09/20/2013
    , order_action  OAD

plan OAD

WHERE OAD.order_id = request->order_qual [rec_cnt].order_id     ; 003 09/23/2013  Returned.
;WHERE OAD.order_id =  request->order_qual [1].order_id         ; 002 09/20/2013  replaced.


join pn
;where oad.updt_id = pn.person_id
where oad.ORDER_PROVIDER_ID = pn.person_id   ;013 - THis is changing to the ordering provider, not the person doing the work.
;and oad.active_ind = 1                                     ; 002 09/20/2013   Out!!!
;and oad.order_status_cd = 2550.00                          ; 002 09/20/2013   Out!!!
and oad.action_type_cd = 2534.00  ;  2534.00 - New Order    ; 002 09/20/2013   In!!!

DETAIL
    card_req->prsnl_id = pn.username
    card_req->prsnl_name = BUILD2(trim(PN.name_full_formatted),", ", UAR_GET_CODE_DISPLAY(PN.position_cd))
    card_req->sign_dt_tm = datetimezoneformat(oad.action_dt_tm, oad.action_tz, "MM/dd/yy HH:mm ZZZ")
with nocounter

/*************************************ordering MD*****************************************/
SELECT into "nl:"
PS.name_full_formatted
,ATT.name_full_formatted
,oa.order_provider_id
,BLT =  SUBSTRING( 1, 15, CNVTALIAS(pa.alias,pa.alias_pool_cd ))
,WHC =  SUBSTRING( 1, 15, CNVTALIAS(pa.alias,pa.alias_pool_cd ))
,GUH = SUBSTRING( 1, 15, CNVTALIAS(pa.alias,pa.alias_pool_cd ))
, NRH = SUBSTRING( 1, 15, CNVTALIAS(pa1.alias,pa1.alias_pool_cd ))
; 008 - begin
, MMC = SUBSTRING( 1, 15, CNVTALIAS(pa.alias,pa.alias_pool_cd ))
, SMHC = SUBSTRING( 1, 15, CNVTALIAS(pa.alias,pa.alias_pool_cd ))
, MMC1 = SUBSTRING( 1, 15, CNVTALIAS(pa1.alias,pa1.alias_pool_cd ))
, SMHC1 = SUBSTRING( 1, 15, CNVTALIAS(pa1.alias,pa1.alias_pool_cd ))
; 008 - end
,BLT1 = SUBSTRING( 1, 15, CNVTALIAS(pa1.alias,pa1.alias_pool_cd ))
,WHC1 = SUBSTRING( 1, 15, CNVTALIAS(pa1.alias,pa1.alias_pool_cd ))
,GUH1 = SUBSTRING( 1, 15, CNVTALIAS(pa1.alias,pa1.alias_pool_cd ))
,NRH1 = SUBSTRING( 1, 15, CNVTALIAS(pa1.alias,pa1.alias_pool_cd ))
FROM
      ORDERS   O
    , PRSNL   PS
    , ORDER_ACTION   OA
    , encntr_prsnl_reltn   epr
    , prsnl   att
    , dummyt dt
    , prsnl_alias pa
    , dummyt dt1
    , prsnl_alias pa1
    , ENCOUNTER E

PLAN O
    WHERE O.order_id = request->order_qual[rec_cnt].order_id    ; 003 09/23/2013  Returned.
;   WHERE O.order_id =  request->order_qual[1].order_id;        ; 002 09/20/2013  replacement.


jOIN E
;   WHERE E.encntr_id = O.encntr_id                             ; 010 03/07/2021 Replaced. See Below.
    WHERE (e.encntr_id = o.encntr_id and                        ; 010 03/07/2021 Replacement
           o.encntr_id != 0.00)                                 ; 010 03/07/2021 Replacement
           or                                                   ; 010 03/07/2021 Replacement
          (e.encntr_id = o.originating_encntr_id and            ; 010 03/07/2021 Replacement
           o.encntr_id = 0.00)                                  ; 010 03/07/2021 Replacement

JOIN OA

    WHERE OA.order_id = O.order_id

JOIN PS
    WHERE PS.person_id = OA.order_provider_id



JOIN epr
     WHERE epr.encntr_id = outerjoin(e.encntr_id)
     AND epr.encntr_prsnl_r_cd = outerjoin(1119.00)
     AND epr.active_ind = outerjoin(1)
     and epr.beg_effective_dt_tm <= outerjoin(cnvtdatetime(curdate, curtime3))                  ; 007 05/10/2018  New
     and epr.end_effective_dt_tm >= outerjoin(cnvtdatetime(curdate, curtime3))                  ; 007 05/10/2018  New


JOIN att
     WHERE att.person_id = outerjoin(epr.prsnl_person_id)

join dt

 JOIN PA
   WHERE PA.person_id = ps.PERSON_ID
;   AND PA.alias_pool_cd in(NRH_ID, WHC_ID, GUH_ID, BLT_ID)                             ; 008 - comment
   AND PA.alias_pool_cd in(NRH_ID, WHC_ID, GUH_ID, BLT_ID, MMC_ID, SMHC_ID)             ; 008 - add
   AND pa.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
   AND pa.end_effective_dt_tm>= cnvtdatetime(curdate,curtime3)

join dt1

  JOIN PA1
   WHERE PA1.person_id = att.PERSON_ID
;   AND PA1.alias_pool_cd in(NRH_ID1, WHC_ID1, GUH_ID1, BLT_ID1)                    ; 008 - comment
   AND PA1.alias_pool_cd in(NRH_ID1, WHC_ID1, GUH_ID1, BLT_ID1, MMC_ID1, SMHC_ID1)  ; 008 - add
   AND pa1.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
   AND pa1.end_effective_dt_tm>= cnvtdatetime(curdate,curtime3)

DETAIL

      CARD_REQ->attend_MD = ATT.name_full_formatted
      CARD_REQ->ordering_md = PS.name_full_formatted
  IF(E.loc_facility_cd IN (4363058.00,4363156.00,4362818.00, 633867.00)and pa.alias_pool_cd in (BLT_ID))
      CARD_REQ->PID = BLT
  elseif(E.loc_facility_cd IN(4363216.00) AND PA.alias_pool_cd IN(WHC_ID))
      CARD_REQ->PID = WHC
  elseif(E.loc_building_cd IN(4363210.00) AND PA.alias_pool_cd IN(GUH_ID))
      CARD_REQ->PID = GUH
  elseif(E.loc_facility_cd IN (4364516.00)AND PA.alias_pool_cd IN(NRH_ID))
      CARD_REQ->PID = NRH
  ; 008 - begin
  elseif(E.loc_facility_cd IN (446795444.00)AND PA.alias_pool_cd IN(MMC_ID))
      CARD_REQ->PID = MMC
  elseif(E.loc_facility_cd IN (465210143.00)AND PA.alias_pool_cd IN(SMHC_ID))
      CARD_REQ->PID = SMHC
  ; 008 - end
  ENDIF


    IF(E.loc_facility_cd IN (4363058.00,4363156.00,4362818.00, 633867.00)and pa1.alias_pool_cd in (BLT_ID1))
      CARD_REQ->PID1 = BLT1
  elseif(E.loc_facility_cd IN(4363216.00) AND PA1.alias_pool_cd IN(WHC_ID1))
      CARD_REQ->PID1 = WHC1
  elseif(E.loc_building_cd IN(4363210.00) AND PA1.alias_pool_cd IN(GUH_ID1))
      CARD_REQ->PID1 = GUH1
  elseif(E.loc_facility_cd IN (4364516.00)AND PA1.alias_pool_cd IN(NRH_ID1))
      CARD_REQ->PID1 = NRH1
  ; 008 - begin
  elseif(E.loc_facility_cd IN (446795444.00)AND PA.alias_pool_cd IN(MMC_ID1))
      CARD_REQ->PID1 = MMC1
  elseif(E.loc_facility_cd IN (465210143.00)AND PA.alias_pool_cd IN(SMHC_ID1))
      CARD_REQ->PID1 = SMHC1
  ; 008 - end
  ENDIF


  ;CARD_REQ->npi_att = ALIAS3


WITH NOCOUNTER, outerjoin = dt, outerjoin = dt1


/**********************************************************************************************/
;SELECT into "nl:"
;   DG.diag_ftdesc
;   ,DG.diagnosis_id
;   ,DG.diag_ftdesc
;   ,DG.diagnosis_display
;   ,Clinical_code = UAR_GET_CODE_DISPLAY(DG.clinical_service_cd)
;   ,rank = (if (dg.ranking_cd = 0.00)                                              ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;               999999.99                                                           ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;           else                                                                    ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;               dg.ranking_cd                                                       ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;           endif)                                                                  ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;   ,priority =                                                                     ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;          (if (dg.clinical_diag_priority = 0)                                      ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;               99999999                                                            ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;           else                                                                    ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;               dg.clinical_diag_priority                                           ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;           endif)                                                                  ; 006 06/22/2017  New. This is used for sorting... ignoring zeroes.
;
;FROM
;   diagnosis dg
;   , nomenclature nm
;plan dg where dg.encntr_id = card_req->encntr_id
;   and dg.active_ind = 1
;   and dg.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)           ; 006 06/22/2017  New. We were not excluding expired diagnoses.
;   and dg.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)           ; 006 06/22/2017  New. We were not excluding expired diagnoses.
;join nm where nm.nomenclature_id = dg.nomenclature_id
;   and nm.active_ind = 1
;   and cnvtdatetime(curdate, curtime3) between nm.beg_effective_dt_tm and nm.end_effective_dt_tm
;order by rank, priority, cnvtupper(trim(DG.diagnosis_display))         ; 006 06/22/2017  New. Ordering has been added too.
;
;head report
;   cnt_1 = 0
;detail
;   cnt_1 = cnt_1+1
;   stat = alterlist(card_req->diag, cnt_1)
;
;   card_req->diag[CNT_1].diag_display = DG.diagnosis_display
;
;   if(cnt_1 = 1)
;       M_DIAG = build2(trim(DG.diagnosis_display, 3), " (", trim(nm.source_identifier, 3), ")")
;   else
;       M_DIAG = concat(M_DIAG,"; ", trim(DG.diagnosis_display, 3)
;                   , " (", trim(nm.source_identifier, 3), ")")
;   endif
;
;FOOT REPORT
;   ;card_req->full_diag_disp = M_DIAG
;   stat = alterlist(card_req->diag,cnt_1)
;with nocounter
;013 The above is replaced by a order dx lookup
select into 'nl:'
  from dcp_entity_reltn der
     , diagnosis        d
     , nomenclature     n
 where der.entity1_id = request->order_qual[rec_cnt].order_id
   and der.entity_reltn_mean = "ORDERS/DIAGN"
   and der.active_ind = 1
   
   and d.diagnosis_id = der.entity2_id
   
   and n.nomenclature_id = d.nomenclature_id
order by der.entity1_id, der.rank_sequence, d.diagnosis_id

head report
   cnt_1 = 0

detail
   cnt_1 = cnt_1+1
   stat = alterlist(card_req->diag, cnt_1)

   card_req->diag[CNT_1].diag_display = d.diagnosis_display

   if(cnt_1 = 1)
       M_DIAG = build2(trim(D.diagnosis_display, 3), " (", trim(n.source_identifier, 3), ")")
   else
       M_DIAG = concat(M_DIAG,"; ", trim(D.diagnosis_display, 3)
                   , " (", trim(n.source_identifier, 3), ")")
   endif

FOOT REPORT
   ;card_req->full_diag_disp = M_DIAG
   stat = alterlist(card_req->diag,cnt_1)
with nocounter


;013 Try again... looks like future orders whiff on that?  But good for normal orders.
if(size(card_req->diag, 5) = 0)
    select into 'nl:'
      from nomen_entity_reltn        ner
         , order_potential_diagnosis d
         , nomenclature              n
      
     where ner.parent_entity_name = 'ORDERS'
       and ner.parent_entity_id   = request->order_qual[rec_cnt].order_id
       and ner.active_ind         = 1
       
       and d.order_potential_diagnosis_id = ner.child_entity_id
       
       and n.nomenclature_id      = d.nomenclature_id

    head report
       cnt_1 = 0

    detail
       cnt_1 = cnt_1+1
       stat = alterlist(card_req->diag, cnt_1)

       card_req->diag[CNT_1].diag_display = d.diagnosis_display

       if(cnt_1 = 1)
           M_DIAG = build2(trim(D.diagnosis_display, 3), " (", trim(n.source_identifier, 3), ")")
       else
           M_DIAG = concat(M_DIAG,"; ", trim(D.diagnosis_display, 3)
                       , " (", trim(n.source_identifier, 3), ")")
       endif

    FOOT REPORT
       ;card_req->full_diag_disp = M_DIAG
       stat = alterlist(card_req->diag,cnt_1)
    with nocounter
endif

 /**********************************Get Order Comments************************************************/

select into 'nl:'
from order_comment oc
    ,long_text lt
plan oc
    where oc.order_id = request->order_qual[rec_cnt].order_id
    and oc.comment_type_cd = ordr_comment_type
join lt
    where lt.long_text_id = oc.long_text_id
    and lt.active_ind = 1
detail
    card_req->order_comment = lt.long_text
with nocounter

/****************************************************************************************************/

/*****************************************************************************
  009 ss  Clinic's Address Information - Begins
******************************************************************************/

select into "nl:"
from
    encounter e
    , address a

plan e where e.encntr_id = card_req->encntr_id
join a where a.parent_entity_id = e.organization_id
      and a.parent_entity_name = "ORGANIZATION"
      and a.active_ind = 1
      and a.address_type_cd = bus_add_cd

order by a.active_status_dt_tm

detail
    card_req->fac_addr = a.street_addr
    card_req->fac_city = a.city

with nocounter

/*****************************************************************************
  009 ss  Clinic's Address Information - Ends
******************************************************************************/


; Select into $OUTDEV
;
;  encounter = card_req->encntr_id
; ,D1 = d1.seq
; ,d2 = d2.seq
;
;
; , ORD_DISPLAY1 = card_req->ord_detail[d2.seq].title
;
; , ord_meaning = card_req->ord_detail[d2.seq].meaning
;FROM
;   (dummyt   d1  with seq = value(size(card_req,5)))     ;;;;;; this had a 10, not a 5. SORRY!!!
;   , dummyt   d2
;
;
;plan d1 WHERE MAXREC(d2,SIZE(card_req->ord_detail[d1.seq],5))
;join d2
;
;; Fac = card_req->facility,
;; ORD_DISPLAY1 = card_req->ord_detail[1].title

;populate needed variables
set pos = locateval(idx, 1,size(card_req->ord_detail,5),"PRIORITY" ,card_req->ord_detail[idx].meaning) ;Priority

if(pos > 0 and trim(card_req->ord_detail[pos].meaning) > "")
    set PRIORITY_VAL = card_req->ord_detail[pos].value
endif

call echojson(card_req, "sscardreq.dat")

call echorecord(card_req)

;set new_timedisp = format(cnvtdatetime(curdate,curtime3), "MMDDYYYY_HHMM;;d")
;set tempaxb = concat("cer_temp:axb319_",new_timedisp,".dat")
;
;;**NEEDED** - set where the report will be generated to

;SET _SendTo = $OUTDEV ;;;value(trim(request->printer_name))    ; 09/20/2013   THIS IS JUST FOR TESTING...
SET _SendTo = value(trim(request->printer_name))

; value($OUTDEV);"woiclsr002"; value(trim(request->printer_name));
;"woiclsr002";value($OUTDEV);value(trim(request->printer_name)) ;*/value(tempaxb) ;"woiclsr002";value($OUTDEV);
;
;;Execute Layout and Print to _SendTo device
CALL LayoutQuery(0)

;Reset record structure and order details counter

;;;;set stat = initrec(card_req)  ; 002 09/20/2013      Perhaps this was initializing card_Req before the Layout Builder
;;;;                                                    was finished with it.
set od_cnt = 0


;call echojson(card_req,$OUTDEV)
;
;set spool = value(trim(tempaxb)) value(trim(request->printer_name))

;with format, separator = " ", outerjoin = dt


; endfor        ; 002 09/20/2013   This loop has been removed.
 endfor         ; 003 09/23/2013  Returned.

#EXIT_SCRIPT
end
go



