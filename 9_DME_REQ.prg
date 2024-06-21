/*      Source file name:     	9_DME_REQ.PRG
        Object name:           	dmereqfinal
        Request #:             	N/A
 
 
        Program purpose:  Requisition for DME equipment
 
        Tables read:
 
        Tables updated:
 
        Executing from:
 
        Special Notes:
 
*************************************************************************
;************************************************************************
;*              GENERATED MODIFICATION CONTROL LOG                      *
;************************************************************************
;*                                                                      *
;*Mod Date     Engineer             Comment                             *
;*--- -------- -------------------- ----------------------------------- *
;*020 12/30/15 DAE110               Added logic to only print when      *
;                                   ordered/modified in ED locations.   *
;                                   Added this reference section.       *
;                                   program name: 9_dme_req             *
;                                                                       *
--------------------------------
002 06/21/2017  Swetha Srinivasaraghavan of Cerner (and Brian Twardy)
MCGA: 207853    Key user: Nancy DiBenedetto of MNRH
OPAS Request/Task: [pending]___/[pending]___
OPAS Incident: #R2:000056290108
CCL script: cust_script:9_dme_req.prg     (no name change has been made)
Currently this DME requsition is prining all the diagnoses for the encounter. The requisition was
overlaying the diagnoses on top of other fields. Not prety. This script/program has been modified
to put the diagnoses in their own layout builder section. (See Layout Builder)
NOTE:  An issue was addressed to eliminate those diagnoses with an expired
       end_effective_dt_tm. Plus... we are now ordering the diagnoses by ranking then by
       clinical_diag_priority.
Additionally, some small formatting changes have been made to tidy things up.
--------------------------------
003 12-04-2018 DMA112   SOM Incident 6592689      migration issue - missing MMC and SHMC addresses
--------------------------------
004 02/25/2019  Brian Twardy
MCGA: 213495    Key User: Ntiense Inokon of MWHC
SOM Task: TASK2123611
CCL script: cust_script:9_dme_req.prg     (no name change has been made)
Order Comment added to this requisition.
--------------------------------
005 06/14/2019  Brian Twardy
MCGA: n/a
SOM Task: TASK2755121   (in B41 and M41)
Source CCL: cust_script:9_dme_req.prg  (no name change)
With the 2018 Code Upgrade, Request->order_qual[*].conversation_id no longer exists. This has been commented out
of this script.  Also, eliminate "free record request".
--------------------------------
006 05/08/2020  Brian Twardy
MCGA: 221798
SOM Task: TASK3563922
Source CCL: cust_script:9_dme_req.prg  (no name change)
This revision was done for the Alternative Care Site project during the COVID-19 virus pandemic. The DC Convention Center
was converted into a mini-hospital... with all patients assigned to the ACS unit.. which falls under WHC.
This script now generate the DME orders for the Alternative Care Site nursing unit to an email address, rather than to a printer.
However, when re-printing any of these orders from the Orders page in Powerchart, the order will print to
the selected printer as always... rather than generate an email.
-------------------------------
;************************************************************************/
 
 
drop program 9_dme_req:dba go
create program 9_dme_req:dba
 
prompt
	"Output to File/Printer/MINE" = "MINE"
 
with OUTDEV
;
/***************************************************/
declare GVC_PRSNL_NAME = vc with noconstant(' '), public
 
SELECT into "nl:"
PL.USERNAME
FROM PRSNL PL
WHERE PL.PERSON_ID =       4698974.00 ;REQINFO->UPDT_ID   							; 02/25/2019 TESTING
DETAIL
	GVC_PRSNL_NAME = PL.USERNAME
WITH NOCOUNTER
 
 
 
;;Testing via tst file
;free record request go
;record request
;(
;	1 person_id = f8
;	1 print_prsnl_id = f8
;	1 order_qual[1]
;    	2 order_id = f8
;    	2 encntr_id = f8
;    	2 conversation_id = f8
;	1 printer_name = c50
;) go
;
;set request->person_id = 20596460.00 go
;set request->order_qual[1].encntr_id = 117056568.00 go
;set request->order_qual[1].order_id = 5828814877 go
;set request->printer_name = "TYRGAPPRMLP001" go
;
;execute axb_card_req go
 
;;Testing with output to screen
;free record request
;record request
;(
;	1 person_id = f8
;	1 print_prsnl_id = f8
;	1 order_qual[1]
;    	2 order_id = f8
;    	2 encntr_id = f8
;    	2 conversation_id = f8
;	1 printer_name = c50
;)
;
;set request->person_id = 20596460.00
;set request->order_qual[1].encntr_id = 117056568
;set request->order_qual[1].order_id = 5828814877
;set request->printer_name ="woaclsr001" ;"tyrgapprmlp001";
 
 
 
 
 
;/***************************************************/
;;free record request							; 005 06/14/2019 greened out
record request
(
	1 person_id = f8
	1 print_prsnl_id = f8
    1 order_qual[*]
    	2 order_id = f8
    	2 encntr_id = f8
;;    	2 conversation_id = f8					; 005 06/14/2019 greened out
	1 printer_name = c50
)
 
 
;;set stat = alterlist (request->order_qual,1) 													; 02/25/2019 TESTING
;;set request->person_id =     1885752.00															; 02/25/2019 TESTING
;;set request->order_qual[1].encntr_id =   155609484.00											; 02/25/2019 TESTING
;;set request->order_qual[1].order_id = 11008713781.00											; 02/25/2019 TESTING
 
 
;select into $outdev   request->order_qual[1].order_id from dummyt with format
;
;go to EXIT_PROGRAM
 
;set request->printer_name =  $outdev  ;"woaclsr001" ;"tyrgapprmlp001";								; 02/25/2019 TESTING
 ;5471108.00	   16184282.00	  463340073.00
 
 
 
;select into value("cer_temp:reqRequest.dat")
;from dual
;detail
;	col 0 "Printer: ", request->printer_name
;	row + 1
;	sz = size(request->order_qual,5)
;	col 0 "Size: ",sz;, "  ", request->order_qual[1].order_id
;	row +  1
;with nocounter, append
 
declare inerror_cd     = f8 with protect, constant(uar_get_code_by("MEANING", 8, "INERROR"))
declare test_seq = i2
declare mrn_cd = f8 with constant ( uar_get_code_by( "MEANING", 319, "MRN" ) )
declare fin_cd = f8 with constant ( uar_get_code_by( "MEANING", 319, "FIN NBR" ) )
declare NPI = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "NPI") )
DECLARE ATTENDING_MD = F8 WITH PUBLIC, CONSTANT(UAR_GET_CODE_BY("MEANING",333,"ATTENDDOC"))
;declare MEA_WGHT = f8 with protected, constant(uar_get_code_by("DISPLAYKEY",72,"WEIGHTMEASURED"))
;declare MEA_HGHT = f8 with protected, constant(uar_get_code_by("DISPLAYKEY",72,"HEIGHTLENGTHMEASURED"))
;declare MEA_WGHT = f8 with protected, constant(uar_get_code_by("DISPLAYKEY",72,"WEIGHTDOSING"))
;declare MEA_HGHT = f8 with protected, constant(uar_get_code_by("DISPLAYKEY",72,"HEIGHTLENGTHDOSING"))
DECLARE result_val= VC WITH PROTECT,NOCONSTANT("")
DECLARE result_unit = VC WITH PROTECT,NOCONSTANT("")
DECLARE M_DIAG = VC WITH NOCONSTANT(" ")
declare M_isolate = vc with NOCONSTANT(" ")
set weight_cd = uar_get_code_by("DISPLAYKEY", 72, "WEIGHTDOSING")	;005 BEGIN
set height_cd = uar_get_code_by("DISPLAYKEY", 72, "HEIGHTLENGTHDOSING")
declare canceled_cd    = f8 with protect, constant(uar_get_code_by("MEANING", 12025, "CANCELED"))
declare ordr_action_cd = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "ORDER"))
 
declare NPI_ID = f8 with constant ( uar_get_code_by( "DISPLAYKEY", 263, "NPI" ) )
declare rec_cnt  = i4
declare od_cnt = i4
 
/**************************************************************
; DVDev Start Coding
**************************************************************/
 
EXECUTE reportrtl
 
%i cust_script:9_dme_req.dvl
 
free record card_req
record card_req
(
	1 encntr_id    =     f8
	1 person_id    =     f8
	1 mrn          =     vc
	1 fin          =     vc
	1 npi  = vc
	1 ptStreetAddr = vc
	1 ptStreetAddr2 = vc
	1 ptStreetAddr3 = vc
	1 ptStreetAddr4 = vc
	1 ptHomePhone = vc
	1 ptMobilePHone = vc
	1 ptCity = vc
	1 ptState = vc
	1 ptZip = vc
	1 facility     =     vc
	1 fac_addr     =     vc
	1 fac_city     =     vc
	1 fac_ph = VC
	1 room_bed = vc
	1 address = vc
	1 dob          =     dq8
	1 sex          =     vc
	1 age          = vc
	1 pt_name      =     vc
	1 order_dt_tm  =     dq8
	1 order_name   =     vc
	1 disp_ind     =     I2   ; 020  added to capture print req
	1 ordering_md  =     vc
	1 full_diag_disp =     vc
	1 allergy      =     vc
	1 order_no     =     f8
	1 order_comment =    vc
	1 status_up_dt   = dq8
	1 digit_sign = vc
	1 spec_inst = vc
	1 OTHER = vc
    1 height   = vc
	1 weight  = vc
	1 loc_nurse_unit_cd = f8													; 006 05/08/2020 New
	1 activity_type_cd = f8														; 006 05/08/2020 New
	1 order_comment = vc														; 004 02/25/2019 New
		1 insuranceInfo[*]
		2 subscriberName1 = vc
		2 groupNo1 = vc
		2 policyNo1 = vc
		1 secondaryinsuranceInfo[*]
			2 subscriberName2 = vc
			2 groupNo2 = vc
		    2 policyNo2 = vc
		1 diag[*]
		   2 diag_display =     vc
		1 ord_detail[*]
		    2 title = vc
		    2 meaning = vc
		    2 value = vc
 
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
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 006 05/08/2020  Used to identify the Alternate Cae Site (The DC Convention Center) during the COVID-19 experience
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
declare ALTERNATECARESITE_CD = f8		with noconstant(0.00)
select into "nl:"
from code_value cv
where cv.code_set = 220
    and cv.display_key = 'ALTERNATECARESITE'
    and cv.cdf_meaning = 'NURSEUNIT'
detail
	ALTERNATECARESITE_CD = cv.code_value
with nocounter
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
 
 
/******************************************************************************/
/******************************************************************************
*     FIND ACTIVE ALLERGIES AND CREATE ALLERGY LINE                           *
******************************************************************************/
 
 
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
 
 
;;;select into $outdev  size(request->order_qual,5) from dummyt with format
;;;go to exit_program
 
 
for(rec_cnt = 1 to size(request->order_qual,5))
;for(rec_cnt = 1 to 1);  fastest for testing 00X
 
SELECT into "nl:"
	/*EA.ALIAS
	,*/ P.NAME_FULL_FORMATTED
	, P_SEX_DISP = UAR_GET_CODE_DISPLAY(P.SEX_CD)
	, Age = CNVTAGE(P.BIRTH_DT_TM)
	, format(P.BIRTH_DT_TM, ";;q")
	, e.encntr_type_cd							; 020
	, E.LOC_NURSE_UNIT_CD
	, E_LOC_NURSE_UNIT_DISP = UAR_GET_CODE_DISPLAY(E.LOC_NURSE_UNIT_CD)
	, Facility =  UAR_GET_CODE_DESCRIPTION(e.loc_facility_cd)
	, E.REG_DT_TM
	, E.reason_for_visit
	;, TRANSPORT_MODE = UAR_GET_CODE_DISPLAY(e.admit_mode_cd)
	;,ORDER_NO = TRIM(O.order_id,9)
	, O.CATALOG_CD
	, O_CATALOG_DISP = UAR_GET_CODE_DISPLAY(O.CATALOG_CD)
	, ORDER_NAME = SUBSTRING(1,50, O.order_mnemonic)
	, O.ENCNTR_ID
	;,order_no = FORMAT(O.order_id, "#########;P0")
	, O.ORIG_ORDER_DT_TM
	, o.status_dt_tm
	, O.ORDER_STATUS_CD
	, O.CURRENT_START_DT_TM
	, O.ACTIVE_STATUS_DT_TM
	;, O_ORDER_STATUS_DISP = UAR_GET_CODE_DISPLAY(O.ORDER_STATUS_CD)
	;, OA.order_detail_display_line
	, COMMENTS = trim(lt.long_text,5)
	, PS.name_full_formatted
;	, EL_LOC_ROOM_DISP = UAR_GET_CODE_DISPLAY(EL.LOC_ROOM_CD)
;	, EL_LOC_BED_DISP = UAR_GET_CODE_DISPLAY(EL.LOC_BED_CD)
	, Attend_MD = att.name_full_formatted
	, ALIAS1 = SUBSTRING( 1, 15, CNVTALIAS(EA.ALIAS, EA.alias_pool_cd ))
	, ALIAS2 = SUBSTRING( 1, 15, CNVTALIAS(EA1.alias, EA1.alias_pool_cd))
	, oa.digital_signature_ident
	, c.event_tag
	, od.oe_field_display_value
 
FROM
	ORDERS   O
	,ORDER_DETAIL OD
	;,CODE_VALUE CV
	, ENCOUNTER   E
	, ENCNTR_ALIAS   EA
	, ENCNTR_ALIAS   EA1
	, PERSON   P
	;, ENCNTR_LOC_HIST   EL
	, encntr_prsnl_reltn   epr
	, prsnl   att
	;, clinical_event C
	;, ALLERGY   A
	, ORDER_ACTION   OA
	, long_text lt
	, PRSNL   PS
	, dummyt dt
	, clinical_event C    ; height
	, clinical_event CW   ;weight
 
PLAN o
	where o.order_id = request->order_qual[rec_cnt].order_id
 
	and o.encntr_id = request->order_qual[rec_cnt].encntr_id
	and o.active_ind+0 = 1
JOIN OD
	WHERE OD.order_id = O.order_id
join P
	where P.person_id = request->person_id
join E
	where e.encntr_id = o.encntr_id
;JOIN EL
;	WHERE EL.encntr_id = E.encntr_id
JOIN OA
	WHERE OA.order_id = O.order_id
;	and oa.action_type_cd = ordr_action_cd
	and oa.action_sequence = o.last_action_sequence    ; 020 commented out above line and added this to capture last action
JOIN PS
	WHERE PS.person_id = OA.order_provider_id
JOIN epr
	WHERE epr.encntr_id = outerjoin(e.encntr_id)
    AND epr.encntr_prsnl_r_cd = outerjoin(ATTENDING_MD)
	AND epr.active_ind = outerjoin(1)
	AND epr.end_effective_dt_tm > outerjoin( cnvtdatetime(curdate,curtime3))
	;AND epr.active_status_cd = outerjoin(188)
JOIN att
	WHERE att.person_id = outerjoin(epr.prsnl_person_id)
join lt
	where lt.parent_entity_id = outerjoin(o.order_id)
	and lt.active_ind = outerjoin(1)
	and cnvtupper(lt.parent_entity_name)= outerjoin ("ORDER_COMMENT")
JOIN ea WHERE EA.ENCNTR_ID = outerjoin(E.ENCNTR_ID)
	and EA.ENCNTR_ALIAS_TYPE_CD+0 = outerjoin(mrn_cd)
	and ea.ACTIVE_IND = outerjoin(1)
	and EA.END_EFFECTIVE_DT_TM > outerjoin(CNVTDATETIME(CURDATE, curtime3))
JOIN ea1 WHERE EA1.ENCNTR_ID = outerjoin(E.ENCNTR_ID)
	and EA1.ENCNTR_ALIAS_TYPE_CD+0 = outerjoin(fin_cd)
	and ea1.ACTIVE_IND = outerjoin(1)
	and EA1.END_EFFECTIVE_DT_TM > outerjoin(CNVTDATETIME(CURDATE, curtime3))
 
 
 
JOIN  dt
 
;Join C
; where c.encntr_id = e.encntr_id
;and c.event_cd +0  = height_cd;,weight_cd)
;
; and c.performed_dt_tm = (select max(ce.performed_dt_tm)
;                        from clinical_event ce
;					    where c.encntr_id = ce.encntr_id
;					    and c.event_cd = ce.event_cd)
;
;Join Cw
; where cw.encntr_id = e.encntr_id
;and cw.event_cd +0  = weight_cd
;
; and cw.performed_dt_tm = (select max(ce.performed_dt_tm)
;                        from clinical_event ce
;					    where cw.encntr_id = ce.encntr_id
;					    and cw.event_cd = ce.event_cd)
 
 
;JOIN  dt
Join C
	where c.encntr_id = e.encntr_id
	and c.event_cd  = height_cd
	and c.RESULT_STATUS_CD in(25,35)
	and c.performed_dt_tm = (select max(ce.performed_dt_tm)
                        from clinical_event ce
					    where c.encntr_id = ce.encntr_id
					    and c.event_cd = ce.event_cd
					    and ce.RESULT_STATUS_CD in(25,35))
 
;join dt1
 
Join Cw
	where cw.encntr_id = e.encntr_id
	and cw.event_cd   = weight_cd
	and cw.RESULT_STATUS_CD in(25,35)
 
	and cw.performed_dt_tm = (select max(ce.performed_dt_tm)
                        from clinical_event ce
					    where cw.encntr_id = ce.encntr_id
					    and cw.event_cd = ce.event_cd
					    and ce.RESULT_STATUS_CD in(25,35))
 
 
;join d
;Join C
;	where c.encntr_id = e.encntr_id
;	/*or*/and c.event_cd in (height_cd,weight_cd)
;	and c.result_status_cd in (25,35);auth, modified
;	and c.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
 
head o.order_id
 	card_req->encntr_id = e.encntr_id
	card_req->person_id = p.person_id
    card_req->loc_nurse_unit_cd = e.loc_nurse_unit_cd							; 006 05/08/2020 new
    card_req->activity_type_cd = o.activity_type_cd								; 006 05/08/2020 new
	card_req->mrn = ALIAS1
	card_req->fin = ALIAS2
	;card_req->NPI = ALIAS3
	card_req->facility = Facility
	card_req->pt_name = p.name_full_formatted
	card_req->dob = P.BIRTH_DT_TM
	card_req->sex = P_SEX_DISP
	card_req->age = Age
	card_req->order_dt_tm = o.orig_order_dt_tm
	card_req->status_up_dt = o.status_dt_tm
	card_req->order_name = ORDER_NAME
	card_req->ordering_md = ps.name_full_formatted
	card_req->order_no = O.order_id
	card_req->order_comment = COMMENTS ;OA.order_detail_display_line
	card_req->digit_sign = oa.digital_signature_ident
	card_req->room_bed = concat(trim(uar_get_code_display(e.loc_nurse_unit_cd),3),"/",
								trim(uar_get_code_display(e.loc_room_cd),3),"/",
								trim(uar_get_code_display(e.loc_bed_cd),3))
 
	if(e.loc_facility_cd = 633867.00)
		card_req->fac_addr = "9000 Franklin Square Drive"
		card_req->fac_city = "Baltimore, MD 21237"
		card_req->fac_ph = "(443)777-7000"
	elseif(e.loc_facility_cd = 4363210.00)
		card_req->fac_addr = "3800 Reservoir Road"
		card_req->fac_city = "Washington, DC 20007"
		card_req->fac_ph = "(202) 444-2000"
	elseif(e.loc_facility_cd = 4362818.00)
		card_req->fac_addr = "5601 Loch Raven Boulevard"
		card_req->fac_city = "Baltimore, MD 21239"
		card_req->fac_ph = "(443) 444-8000"
	elseif(e.loc_facility_cd = 4363058.00)
		card_req->fac_addr = "3001 South Hanover Street"
		card_req->fac_city = "Baltimore, MD 21225"
		card_req->fac_ph = "(410)350-3200"
	elseif(e.loc_facility_cd = 4364516.00)
		card_req->fac_addr = "102 Irving Street NW"
		card_req->fac_city = "Washington, DC 20010"
		card_req->fac_ph  = "(202)877-1760"
	elseif(e.loc_facility_cd = 4363156.00)
		card_req->fac_addr = "201 East University Parkway"
		card_req->fac_city = "Baltimore, MD 21218"
		card_req->fac_ph = "(410)554-2000"
	elseif(e.loc_facility_cd = 4363216.00)
		card_req->fac_addr = "110 Irving St. NW "
		card_req->fac_city = "Washington, DC 20010"
		card_req->fac_ph = "(202)877-3900"
    ; begin 003 - migration fix - add addresses for MMC and SHMC
	elseif(e.loc_facility_cd = 446795444.00)
		card_req->fac_addr = "18101 Prince Phillip Dr"
		card_req->fac_city = "Olney, MD 20832"
		card_req->fac_ph = "(301)774-8882"
	elseif(e.loc_facility_cd = 465210143.00)
		card_req->fac_addr = "7503 Surratts Rd"
		card_req->fac_city = "Clinton, MD 20735"
		card_req->fac_ph = "(301)868-8000"
    ; end 003 - migration fix - add addresses for MMC and SHMC
 
	endif
 
; 020 section for only printing order/modify order actions for Emergency encouter type
;     enctr_type = emergency and action_type not in (order,modify)
	if(e.encntr_type_cd = 309310 and oa.action_type_cd not in (2534,2533))
 		card_req->disp_ind = 0
  	else card_req->disp_ind = 1
 	endif
; 020 end section
 
	 detail
/***************************Height and Weight***********************************************************/
 
	 ;if (c.event_cd = height_cd)
   card_req->height = concat(trim(c.result_val)," ",
      trim(uar_get_code_display(c.result_units_cd)))
     ;elseif(c.event_cd = weight_cd)
    card_req->weight = concat(trim(cw.result_val)," ",
      trim(uar_get_code_display(cw.result_units_cd)))
  ;endif
  WITH nocounter, outerjoin = dt
 
/**************************************Diagnosis*****************************************/
 
 SELECT into "nl:"
	DG.diag_ftdesc
	,DG.diagnosis_id
	,DG.diag_ftdesc
	,DG.diagnosis_display
	,Clinical_code = UAR_GET_CODE_DISPLAY(DG.clinical_service_cd)
	,rank = (if (dg.ranking_cd = 0.00)												; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
				999999999999.99														; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
		    else																	; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
		    	dg.ranking_cd														; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
		    endif)																	; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
	,priority =																		; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
		   (if (dg.clinical_diag_priority = 0)										; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
				999999999999.99														; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
		    else																	; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
		    	dg.clinical_diag_priority											; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
		    endif)																	; 002 06/21/2017  New. This is used for sorting... ignoring zeroes.
 
FROM
	;(dummyt   d  with seq = value(size(card_req->diag,5)))
	diagnosis DG
 
WHERE DG.ENCNTR_ID = card_req->encntr_id
AND DG.ACTIVE_IND = 1
and dg.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3) 			; 002 06/21/2017  New. This was just found to be a problem
and dg.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3) 			; 002 06/21/2017  New. This was just found to be a problem
 
order by rank, priority, cnvtupper(trim(DG.diagnosis_display))			; 002 06/21/2017  New. Ordering was requested too.
 
head report
	cnt_1 = 0
detail
	cnt_1 = cnt_1+1
	stat = alterlist(card_req->diag, cnt_1)
 
	card_req->diag[CNT_1].diag_display = DG.diagnosis_display
 
	if(cnt_1 = 1)
	M_DIAG = DG.diagnosis_display
	else
	M_DIAG = concat(M_DIAG,"; ",DG.diagnosis_display)					; 002 06/21/2017  Now a semicolon here, rather than a comma
	endif
 
FOOT REPORT
	;card_req->full_diag_disp = M_DIAG
	stat = alterlist(card_req->diag,cnt_1)
with nocounter
 
/*************************************ordering MD*****************************************/
 
;head c.clinical_event_id
;	/***************************Height and Weight***********************************************************/
;	if (c.event_cd = height_cd)
;		card_req->height = concat(trim(c.event_tag)," ", trim(uar_get_code_display(c.result_units_cd)))
;	elseif (c.event_cd = weight_cd)
;    	card_req->weight = concat(trim(c.event_tag)," ", trim(uar_get_code_display(c.result_units_cd)))
;	endif
;
;detail
;	/*****************************order detail**************************************/
 
 
 
select INTO "nl:"
ORD.order_id
 
 
FROM
     ORDERS   ORD
    ,ORDER_CATALOG OC
	,OE_FORMAT_FIELDS OFF
	,ORDER_DETAIL OD
	,code_value CV
 
PLAN ORD
	where ORD.order_id = request->order_qual[rec_cnt].order_id
JOIN OD
  WHERE OD.order_id = ORD.order_id
 
JOIN OC
 
where OC.catalog_cd = ORD.catalog_cd
 
 
JOIN OFF
 
  WHERE OC.oe_format_id = OFF.oe_format_id
 
and off.oe_field_id = od.oe_field_id
 
and off.accept_flag != 2.00
 
JOIN CV
	WHERE CV.code_value = OD.oe_field_id
 
order by ord.order_id
 
head report
 
 
ocnt_1 = 0
 
;
Head ord.encntr_id ;ORD.order_id
 
   NULL
Head od.detail_sequence
;detail
	ocnt_1 = ocnt_1+1
	stat = alterlist(card_req->ord_detail, ocnt_1)
 
	card_req->ord_detail [ocnt_1].title = cv.display
	card_req->ord_detail [ocnt_1].value = od.oe_field_display_value
	card_req->ord_detail [ocnt_1].meaning = od.oe_field_display_value
with nocounter
 
/**************************************************************************************************************/
SELECT into "nl:"
PS1.name_full_formatted
,ATT1.name_full_formatted
,oa1.order_provider_id
,ALIAS3 =  SUBSTRING( 1, 15, CNVTALIAS(PA1.ALIAS, PA1.alias_pool_cd ))
FROM
	ORDERS   O
	, PRSNL   PS1
    ,prsnl_alias pa1
	, ORDER_ACTION   OA1
	, encntr_prsnl_reltn   epr1
	, prsnl   att1
	, ENCOUNTER E1
 
	PLAN O
 
	WHERE O.order_id = request->order_qual[rec_cnt].order_id
 
jOIN E1
 
WHERE E1.encntr_id = O.encntr_id
 
	JOIN OA1
 
                WHERE OA1.order_id = O.order_id
 
JOIN PS1
                WHERE PS1.person_id = OA1.order_provider_id
JOIN PA1 WHERE PA1.person_id = PS1.person_id
AND PA1.alias_pool_cd =        4706676.00
			AND pa1.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
			AND pa1.end_effective_dt_tm>= cnvtdatetime(curdate,curtime3)
 
 
JOIN epr1
 
                WHERE epr1.encntr_id = outerjoin(e1.encntr_id)
 
                    AND epr1.encntr_prsnl_r_cd = outerjoin(1119.00)
 
                    AND epr1.active_ind = outerjoin(1)
 
 
JOIN att1
 
                WHERE att1.person_id = outerjoin(epr1.prsnl_person_id)
 
 
 
  DETAIL
 
 
  CARD_REQ->npi = ALIAS3
 
/************************************Patient Address**********************************************************/
 ;DECLARE address = VC WITH PROTECTED,NOCONSTANT("")
select INTO "nl:"
	A.street_addr
	,a.zipcode
from address a
plan a
	where a.parent_entity_id = request->person_id
		and a.address_type_cd = 756.00;home
		and a.active_ind = 1
order by a.address_type_seq
detail
    card_req->ptStreetAddr = BUILD(a.street_addr, ",")
    card_req->ptStreetAddr2 = a.street_addr2
    card_req->ptStreetAddr3 = a.street_addr3
    card_req->ptStreetAddr4 = a.street_addr4
    card_req->ptCity = BUILD(a.city, ",")
    card_req->ptState = BUILD(a.state, ",", a.zipcode)
    ;card_req->ptZip = a.zipcode
;    card_req->address = BUILD(a.street_addr,a.street_addr2, ", ", a.city,", ",
;     a.state, ",",a.zipcode)
with nocounter
 
 
/********************Patient Phone Numbers ****************************************************/
select into "nl:"
from phone pt_ph
plan pt_ph
	where pt_ph.parent_entity_id = request->person_id
		and pt_ph.phone_type_cd in(4149712.00,170.00);mobile,home
		and pt_ph.active_ind = 1
order by pt_ph.phone_type_cd,pt_ph.phone_type_seq
detail
	if(pt_ph.phone_type_cd = 4149712.00)
		card_req->ptMobilePHone = pt_ph.phone_num
	else
	    card_req->ptMobilePHone = "N/A"
	    endif
	   if(pt_ph.phone_type_cd =         170.00)
		card_req->ptHomePhone = pt_ph.phone_num
		else
		card_req->ptHomePhone = "N/A"
	endif
 
with nocounter
 
/***************************************************************************
*************************/
select distinct into "nl:"
	epr.person_org_reltn_id
	,epr.person_plan_reltn_id
	,hp.plan_name,hp.policy_nbr
	,epr.policy_nbr,epr.group_nbr
	,uar_get_code_display(epr.subscriber_type_cd)
from encntr_plan_reltn epr
	,health_plan hp
 
plan epr
	where epr.encntr_id = request->order_qual [rec_cnt].encntr_id
	and epr.active_ind = 1
	and epr.beg_effective_dt_tm <= cnvtdatetime(curdate , curtime3 )
	and epr.end_effective_dt_tm >= cnvtdatetime(curdate , curtime3 )
	and epr.priority_seq <= 2
 
 
join hp
	where hp.health_plan_id = outerjoin(epr.health_plan_id)
head report
	priPlanCnt = 0
	secPlanCnt = 0
head epr.priority_seq
 
	if(epr.priority_seq = 1)
		priPlanCnt = priPlanCnt + 1
		stat = alterlist(card_req->insuranceInfo,priPlanCnt)
 
		card_req->insuranceInfo[priPlanCnt].subscriberName1 = hp.plan_name
		card_req->insuranceInfo[priPlanCnt].policyNo1 = epr.member_nbr
		card_req->insuranceInfo[priPlanCnt].groupNo1 = epr.group_nbr
 
	else
	 	secPlanCnt = secPlanCnt + 1
		stat = alterlist(card_req->secondaryinsuranceInfo,secPlanCnt)
 
 
		card_req->secondaryinsuranceInfo[secPlanCnt].subscriberName2 = hp.plan_name
		card_req->secondaryinsuranceInfo[secPlanCnt].policyNo2 = epr.member_nbr
		card_req->secondaryinsuranceInfo[secPlanCnt].groupNo2 = epr.group_nbr
 
	endif
	with nocounter
 
/******************************************************************************
* 004 02/25/2019     RETRIEVE ORDER COMMENT
******************************************************************************/
 
select into "nl:"
from order_comment oc,
long_text lt
plan oc
	where oc.order_id = request->order_qual[rec_cnt].order_id and
          oc.comment_type_cd = 66.00   ; comment_cd
join lt
    where lt.long_text_id = oc.long_text_id
detail
	card_req->order_comment = lt.long_text
with nocounter
 
 
if (card_req->disp_ind = 1 )
 
	; 006 05/08/2020 The following "If"... not the "else"... is all new. We are emailing out the requisition if...
	;   - The patient is on the Alternative Care Site nursing unit (a unit under WHC)
	;	- The order has an Activity Type of DME (other orders use this CCL too, so don't inculded them here)
	;	- The order is being generated by System, System fr automatic printing/emailing, rather than manually reprinting
 
	If (card_req->loc_nurse_unit_cd =  ALTERNATECARESITE_CD and
	    card_req->activity_type_cd =   102273864.00 and 		; DME
	    request->print_prsnl_id < 10.00)  ; When < 10, we know that SYSTEM, SYSTEM is generating the requisition, so
	    								  ; it is not a reprint being done here. With repprints... we want the requisition to
	    								  ; print... and not be emailed.
 
		set  _OUTPUTTYPE  =  RPT_PDF		; These fields are defined in cust_script:9_dme_req.dvl
 
 
		declare new_timedisp = vc with noconstant("")
		declare tempfile1a = vc	with noconstant("") 					; 006 05/08/2020 new
 
 		set new_timedisp = format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q")										; 061 06/12/2019  This is better
	 	set tempfile1a = build2("dme_req_", new_timedisp,"_",
	 					   		trim(substring(2,4,cnvtstring(RAND(0)))),		; Random # generator 4 digits
	 					   		".pdf")
 
		SET _SendTo = value(tempfile1a)
 
		CALL LayoutQuery(0)
 
		DECLARE EMAIL_SUBJECT = VC WITH NOCONSTANT(" ")
 
		SET EMAIL_SUBJECT = build2("ACS - ", trim(card_req->order_name), "   ",  trim(card_req->fin))
 
		DECLARE EMAIL_BODY = VC WITH NOCONSTANT("")
		DECLARE UNICODE = VC WITH NOCONSTANT("")
 
		DECLARE AIX_COMMAND	  = VC WITH NOCONSTANT("")
		DECLARE AIX_CMDLEN	  = I4 WITH NOCONSTANT(0)
		DECLARE AIX_CMDSTATUS = I4 WITH NOCONSTANT(0)
 
		Declare EMAIL_ADDRESS 	= vc WITH NOCONSTANT("")
		SET EMAIL_ADDRESS = "Dana.A.Belongia@medstar.net brian.twardy@medstar.net"
 
		SET EMAIL_BODY = concat("dme_req_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
				 				"_",trim(substring(2,4,cnvtstring(RAND(0)))),							; Random # generator 4 digits
						        ".txt")
		;------------------------------------------------------------------------------------------
		;; Below, we are creating a file that will hold the email body. The file's name is inside EMAIL_BODY.
 
		Select into (value(EMAIL_BODY))
						body1 = build2("A  '", trim(card_req->order_name), "' order is attached to this email."),
						body2 = build2("Patient: " ,trim(card_req->pt_name)),
						body3 = build2("MRN: ",trim(card_req->mrn)),
						body4 = build2("FIN:   " ,trim(card_req->fin)),
						body5 = build2("Unit/Room/Bed: ",trim(card_req->room_bed)),
						body6 = build2("Order Date/Time: ",format(cnvtdatetime(card_req->order_dt_tm), "MM/DD/YYYY hh:mm;;Q"))
		from dummyt
		Detail
			col 01 body1
			row +2
			col 01 body2
			row +1
			col 01 body3
			row +1
			col 01 body4
			row +1
			col 01 body5
			row +1
			col 01 body6
		with format,  maxcol = 300
 
		SET  AIX_COMMAND  =
			build2 ( "cat ", email_body ," | tr -d \\r",
				   " | mailx  -S from='report@medstar.net' -s '" ,email_subject , "' -a ", tempfile1a, " ", EMAIL_ADDRESS)
 
		SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
		SET AIX_CMDSTATUS = 0
		CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
		call pause(2)	; Let's slow things down before the clean up immediately below.
		call pause(2)	; Let's slow things down before the clean up immediately below.
 
		; 	clean up.   (Removing EMAIL_BODY from $CCLUSERDIR does work.)
 
;;		SET  AIX_COMMAND  =
;;			CONCAT ('rm -f ' , tempfile1a,  ' | rm -f ' , email_body)
;;
;;		SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
;;		SET AIX_CMDSTATUS = 0
;;		CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
		set stat = initrec(card_req)
		set od_cnt = 0
 
	Else  ; 006 05/08/2020  Before now... these few lines under this else were the only lines here.
 
		SET _SendTo = value(trim(request->printer_name))											; 02/25/2019 TESTING
		; SET _SendTo =  value($OUTDEV);;															; 02/25/2019 TESTING
 
		CALL LayoutQuery(0)
 
		set stat = initrec(card_req)
		set od_cnt = 0
 
	Endif
 
endif
 
 
 
 
 
endfor
 
 
#EXIT_PROGRAM
 
end
go
 
