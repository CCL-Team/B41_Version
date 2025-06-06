/************************************************************************************************
      Source file name:		cust_scrip:7_ip_resus_stat.prg			(yymmdd will be added with modifications)
      Object name:			7_ip_resus_stat							(yymmdd will be added with modifications)
      Request #:			R2:000014065778 / Task: R2:000023533852
      MCGA:					17810
      Key Requestors:		Sui-Kuen Lyn-Canizalez
      Application Analyst:	Brian Twardy
 
*************************************************************************************************
*                         GENERATED MODIFICATION CONTROL LOG
*************************************************************************************************
 
Mod  Date       Analyst               OPAS Ticket			Comment
---  ---------  -------------------- -----------------		-----------------------------------------
000  03/04/14   Brian Twardy         R/T R2:000014065778/	Initial Release.
									     R2:000023533852
001  04/23/14 	Brian Twardy		 See below.				See MODIFICATION HISTORY below.
 ***** For all additional modifications, please look below *****
-----------------------------------------------------------------------
MODIFICATION HISTORY
-------------------------
001 04/24/2014 Brian Twardy
OPAS Request/Task #: R2:000014306864/R2:000024028138
Key User:  Karthi Dandapani from WHC
Old source: cust_script: 7_IP_RESUS_STAT_140310.prg
New source: cust_script: 7_IP_RESUS_STAT_140424.prg
This report will now be able to generate emails.
-------------------------
002 05/07/2014 Brian Twardy
OPAS Request/Task #: n/a
Key User:  Karthi Dandapani from WHC
Old source: cust_script: 7_IP_RESUS_STAT_140424.prg
New source: cust_script: 7_IP_RESUS_STAT_140507.prg
This report will now be able to generate emails to 2 additional folks, EMAIL_ADDRESS_05 and _06.
-------------------------
003 10/10/2016 Brian Twardy
OPAS Request/Task #: n/a
Key User:  Karthi Dandapani from WHC
CCL source: cust_script: 7_IP_RESUS_STAT_140507.prg (no name change)
This report will now include the following address when generating emails:
 - Kimberly.woodard@medstar.net
-------------------------
004 01/18/2017  Brian Twardy
MCGA: _____
OPAS Incident:
Cerner SR: 415110973
CCL source: cust_script: 7_IP_RESUS_STAT_140507.prg (no name change)
Emailing issues after upgrade to RHEL 6.8 last evening
-------------------------
005 07/31/2019     Brian Twardy
MCGA: MCGA215258   (Requested by Dr Joel McAlduff. MCGA assigned to Deborah Cowell of the MSH-Medcnnect Nrsg-Clinic)
SOM RITM/Task: RITM1399104/TASK2653058
CCL script: cust_script:7_IP_RESUS_STAT_140507.prg   (no name chnage)
The Resuscitation Status order has been replaced with the new, Code Status order.
--------------------------
006 12/19/2019   Brian Twardy
MCGA: n/a
SOM Task: n/a
CCL script: cust_script:7_IP_RESUS_STAT_140507.prg   (no name change)
These three hospitals are being renamed on the occasion of St Mary's finally being migrated into Medconnect.
The prompts may have been revised, along with the possibility of the designations of these hospitals within this program/script.
  - Medstar Montgomery Medical Center
  - Medstar Southern Maryland Hospital Center
  - Medstar St Mary's Hospital
--------------------------
007 09/22/2020   Brian Twardy
MCGA:  222336    (Requesters: Joel Mcalduff)
SOM Catalog Task: TASK3822102
CCL script:  cust_script:7_IP_RESUS_STAT_140507.prg   (no name change)
Now, four different orders, rather than one, will be used to order Code Status. The 3 new ones are:
  - Code Status Full Code
  - Code Status Do Not Resuscitate (Allow all pre-arrest interventions)
  - Code Status DNR and Pre-arrest Limitations
Some housecleaning was done to the report too, including adding the special interventions to the printable
report format.
NOTE: The banner bar in Powerchart and several other reports were updated under this same MCGA. To see them all,
      you can a grep on the MCGA #, 222336. (There may be more soon, so I did not list them all here.)
--------------------------
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA    Comment
--- ---------- -------------------- ------  -------------------------------
008 2025-04-07 Michael Mayes        353473  They want an on the fly addition of DX to this.
*******************************************************************************************************/
 
drop program 7_ip_resus_stat_140507:dba go
create program 7_ip_resus_stat_140507:dba
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Facility" = 4363216
	, "Report_type" = ""
 
with OUTDEV, Facility, Report_type
 
 
declare printed_date = vc with
        constant(format(cnvtdatetime(curdate,curtime3),"MM/DD/YYYY  hh:mm;;Q"))
 
Declare cnt = i4 with noconstant(0)
Declare cnt_cs = i4 with noconstant(0)									; 007 09/22/2020new
 
 
Declare facility_var = vc with constant(cnvtupper(uar_get_code_description(cnvtreal($Facility))))
declare report_title_var	= vc with constant("INPATIENT RESUSCITATION STATUS REPORT")
 
declare CENSUS_CD = f8 with constant(uar_get_code_by('DISPLAY', 339, 'Census')), protect
declare INPT_CLASS_CD  = f8 with constant(uar_get_code_by('DISPLAY',321,'Inpatient')), protect
declare EMR_CLASS_CD  = f8 with constant(uar_get_code_by('DISPLAY',321,'Emergency')), protect
 
declare PATIENTCARE_CD = f8 with constant(uar_get_code_by('DISPLAYKEY',6000,'PATIENTCARE'))					;   2515.00
declare COMMUNICATIONORDERS_CD = f8 with constant(uar_get_code_by('DISPLAYKEY',106,'COMMUNICATIONORDERS'))	; 681592.00
 
declare ORDER_STAT_ORDERED_cd = f8 with constant( uar_get_code_by("DISPLAYKEY", 6004, "ORDERED"))  ; 2550
declare MRN_CD = f8 with constant(uar_get_code_by("MEANING", 319, "MRN")) ; 1079
declare FIN_CD = f8 with constant(uar_get_code_by("MEANING", 319, "FIN NBR")) ; 1077
 
;declare RESUSCITATIONSTATUS_CD = f8											; 007 09/22/2020 greened out. No longer used. (earlier not used too)
;				with constant(uar_get_code_by("DISPLAYKEY", 200, "RESUSCITATIONSTATUS"))
 
Declare CODESTATUS_CD			= f8 with constant(uar_get_code_by ("DISPLAYKEY", 200, "CODESTATUS"))  ;2038185437.00  ; 005 07/31/2019
declare CODESTATUSDNRANDPREARRESTLIMITATIO_cd = f8 																		; 007 09/22/2020 New
								with constant(uar_get_code_by("DISPLAYKEY", 200, "CODESTATUSDNRANDPREARRESTLIMITATIO"))
declare CODESTATUSDONOTRESUSCITATEALLOWAL_cd = f8 																		; 007 09/22/2020 New
								with constant(uar_get_code_by("DISPLAYKEY", 200, "CODESTATUSDONOTRESUSCITATEALLOWAL"))
declare CODESTATUSFULLCODE_cd = f8 																						; 007 09/22/2020 New
								with constant(uar_get_code_by("DISPLAYKEY", 200, "CODESTATUSFULLCODE"))
 
declare code_status_oef = vc with noconstant('') 							; 007 09/22/2020 new
declare code_status_intervs = vc with noconstant('') 						; 007 09/22/2020 new
 
declare OUTPATIENTINVASIVEPROCEDURE_CD = f8
				with constant(uar_get_code_by('DISPLAYKEY',34,'OUTPATIENTINVASIVEPROCEDURE'))	; 5048119.00
declare PARTBBILLING_CD = f8
				with constant(uar_get_code_by('DISPLAYKEY',34,'PARTBBILLING'))	; 53675914.00
 
declare VAR_FIRST_ROW_FOR_THIS_ORDER = vc with noconstant(" ")
 
;---------------------------------------------------------------------------------------
; 002 04/24/2014  Email definitions, etc
;---------------------------------------------------------------------------------------
 
DECLARE EMAIL_SUBJECT = VC WITH PROTECTED,CONSTANT(NULLTERM("Inpatient Resuscitation Status Report"))
DECLARE EMAIL_ADDRESSES = VC WITH PROTECTED,NOCONSTANT
DECLARE EMAIL_BODY = VC WITH PROTECTED,NOCONSTANT("")
DECLARE UNICODE = VC WITH PROTECTED,NOCONSTANT("")
 
DECLARE AIX_COMMAND	  = VC WITH PROTECTED,NOCONSTANT("")
DECLARE AIX_CMDLEN	  = I4 WITH PROTECTED,NOCONSTANT(0)
DECLARE AIX_CMDSTATUS = I4 WITH PROTECTED,NOCONSTANT(0)
 
DECLARE PRODUCTION_DOMAIN = vc with constant("P41")			; we only want emails to go out from Production
 
;SET EMAIL_ADDRESSES = build2("brian.twardy@medstar.net ",
;							 "nneka.o.mokwunye@medstar.net ",
;							 "linda.l.self@medstar.net ",
;							 "amanda.alleyne@medstar.net")
DECLARE EMAIL_ADDRESS_01 = VC
SET EMAIL_ADDRESS_01 = "nneka.o.mokwunye@medstar.net"
DECLARE EMAIL_ADDRESS_02 = VC
SET EMAIL_ADDRESS_02 = "linda.l.self@medstar.net"
DECLARE EMAIL_ADDRESS_03 = VC
SET EMAIL_ADDRESS_03 = "amanda.alleyne@medstar.net"
DECLARE EMAIL_ADDRESS_04 = VC
SET EMAIL_ADDRESS_04 = "brian.twardy@medstar.net"
DECLARE EMAIL_ADDRESS_05 = VC
SET EMAIL_ADDRESS_05 = "bridget.cavanagh-Busby@medstar.net"
DECLARE EMAIL_ADDRESS_06 = VC
SET EMAIL_ADDRESS_06 = "kenneth.boyd@medstar.net"
DECLARE EMAIL_ADDRESS_07 = VC																; 003 10/10/2016  New address
SET EMAIL_ADDRESS_07 = "kimberly.woodard@medstar.net"
 
SET EMAIL_BODY = concat("ip_resus_stat_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"), ".dat")
 
DECLARE FILENAME = VC
		WITH PROTECTED, CONSTANT(CONCAT("ip_resus_stat_",
									     format(cnvtdatetime(curdate, curtime), "YYYYMMDDhhmmss;;Q"),".csv"))
 
;DECLARE TEMP_FILENAME = VC																						; 004 01/18/2017  Greened out today
;		WITH PROTECTED,CONSTANT(CONCAT("ip_resus_stat_temp",
;										format(cnvtdatetime(curdate, curtime), "YYYYMMDDhhmmss;;Q"),".csv"))
 
;DECLARE FILEPATH = VC WITH PROTECTED,CONSTANT(CONCAT("/cerner/d_p41/print/",FILENAME))							; 004 01/18/2017  Greened out today
;DECLARE TEMP_FILEPATH = VC 																					; 004 01/18/2017  Greened out today
;							WITH PROTECTED,CONSTANT(CONCAT("/cerner/d_p41/print/",TEMP_FILENAME))
 
;; Below, we are creating a file that will hold the email body. The file is named EMAIL_BODY.
;; char(13), char(10)  is a carraige return/Line feed (or maybe it's the other way around.)
 
if ($Report_type = "E")
	Select into (value(EMAIL_BODY))
		build2("Run date and time: ",
			   format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
			   "The Inpatient Resuscitation Status Report is attached to this email.", char(13), char(10),char(13), char(10),
		       "For:  ", facility_var, char(13), char(10), char(13), char(10),
		       "This report is a snapshot, as of this date and time: ", printed_date)
	from dummyt
	with format, noheading
endif
;----------------------------------------------------------------------------------------
 
 
 
 
free record resus
record resus
( 1 cnt = i2
  1 cnt_resus_orders = i2
  1 qual[*]
    2 encntr_id = f8
    2 person_id = f8
    2 patient = vc
    2 patient_last_key = vc
    2 patient_first_key = vc
    2 mrn = vc
    2 fin = vc
    2 facility = vc
    2 fac_cd = f8
    2 dob = dq8
    2 age = vc
    2 pt_loc = vc
    2 nurse_unit = vc
    2 room = vc
    2 bed = vc
    2 pt_loc = vc
    2 dxList = vc  ;008
    2 order_id = f8
    2 order_status = vc
;    2 catalog = vc											; 007 09/22/2020 Removed. We use catalog_cd mostly now
    2 catalog_cd = f8
    2 code_status = vc
    2 special_interventions = vc
    2 current_start_dt_tm = dq8
    2 projected_stop_dt_tm = dq8)
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; November 2013  Brian Twardy
; The two following lines were added becuase we are using Layout Builder. The
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
execute reportrtl
%i cust_script:7_ip_resus_stat_140507.dvl
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Select patient, encounter, and order data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
SELECT into "nl:"
	  facility = uar_get_code_description(e.loc_facility_cd)
	, e.loc_facility_cd
 
  ;;;;;;;;; For immediately below....... Make "pt_loc" look like the "pat location" in PowerChart, which is one of these 3 formats
  ;		unit
  ;		unit; room
  ;		unit; room; bed
 
	, pt_loc =
			build2(
					trim(substring(1,50,uar_get_code_display(e.loc_nurse_unit_cd))),
					(if (e.loc_room_cd > 0.00 or e.loc_bed_cd > 0.00) '; ' endif),
				    trim(substring(1,50,uar_get_code_display(e.loc_room_cd))),
					(if (e.loc_bed_cd > 0.00) '; ' endif),
				    trim(substring(1,50,uar_get_code_display(e.loc_bed_cd)))
			     )
    , nurse_unit = trim(substring(1,50,uar_get_code_description(e.loc_nurse_unit_cd)))
    , room = trim(substring(1,50,uar_get_code_display(e.loc_room_cd)))
    , bed = trim(substring(1,50,uar_get_code_display(e.loc_bed_cd)))
	, patient = p.name_full_formatted
	, mrn = trim(substring(1,30,cnvtalias(eam.alias,eam.alias_pool_cd)) )   ;     eam.alias
	, fin = /*eaf.alias*/   trim(substring(1,30,cnvtalias(eaf.alias,eaf.alias_pool_cd)) )
	, dob = p.birth_dt_tm
	, age = cnvtage(p.birth_dt_tm)
	, catalog = uar_get_code_description(o.catalog_cd)
	, order_id =o.order_id
	, o.template_order_id
;;	, code_status = od.oe_field_display_value ; od_rt.oe_field_display_value			; 007 09/22/2020 Removed
	, o.order_status_cd
	, order_disp = uar_get_code_display(o.order_status_cd)
	, current_start_dt_tm = o.current_start_dt_tm
	, projected_stop_dt_tm = o.projected_stop_dt_tm
	, orig_order_dt_tm = o.orig_order_dt_tm
 
FROM
	 encntr_domain   e
	,encounter encount
	,orders   o
;	,order_detail od		; 007 09/22/2020 Removed this join. See a later Select
	,encntr_alias eam
	,encntr_alias eaf
	,person   p
 
 
plan e
	where
		e.loc_facility_cd = $FACILITY    ; 4363216.00
	and
		e.active_ind +1 -1  = 1			; encntr_domain rows need be active for us
	and
		e.end_effective_dt_tm + 1 - 1 > cnvtdatetime(curdate, curtime3)
	and
		e.encntr_domain_type_cd + 1 - 1 = CENSUS_CD  ; 1139.00 ;
	and
		e.active_status_dt_tm + 1 -1  >= cnvtlookbehind ('80,d')
	and
		e.med_service_cd + 1 - 1  not in ( 0.00,  OUTPATIENTINVASIVEPROCEDURE_CD, PARTBBILLING_CD) 	; 0.00, 5048119.00, 53675914.00
	and
	    E.LOC_BUILDING_CD + 1 - 1 > 0
 
;	AND   E.LOC_ROOM_CD > 0
;	AND   E.LOC_BED_CD > 0
;
 
join encount
	where
		encount.encntr_id = e.encntr_id
	and
		encount.active_ind + 1 - 1 = 1
	and
		encount.encntr_class_cd + 1 - 1  in ( INPT_CLASS_CD, EMR_CLASS_CD)  ;  (319456.00, 319455.00)
	and
		encount.disch_dt_tm + 1 - 1 =  null
 
;;join o							; 007 09/22/2020 Replaced. Look at the join immediately below
;;	where o.person_id = encount.person_id and
;;		  o.encntr_id = encount.encntr_id and
;;;		  o.catalog_cd  = RESUSCITATIONSTATUS_CD and					; 2958523.00		; 005 07/31/2019 Replaced. See below.
;;		  o.catalog_cd in(RESUSCITATIONSTATUS_CD, CODESTATUS_CD) and						; 005 07/31/2019 Replacement
;;		  o.catalog_type_cd = PATIENTCARE_CD and						;    2515.00
;;		  o.activity_type_cd = COMMUNICATIONORDERS_CD and				;  681592.00
;;  		  o.order_status_cd + 1 - 1 = ORDER_STAT_ORDERED_cd  and 		;    2550.00
;;		  o.template_order_id + 1 - 1 = 0.00 and
;;		  o.active_ind + 1 - 1 = 1 and
;;	      trim(o.CLINICAL_DISPLAY_LINE) != "*Full Resuscitation*"
 
join o								; 007 09/22/2020 Replacemment join.
	where o.person_id = encount.person_id and
		  o.encntr_id = encount.encntr_id and
		  o.catalog_cd in(CODESTATUS_CD,
		  				  CODESTATUSFULLCODE_cd,
		   				  CODESTATUSDONOTRESUSCITATEALLOWAL_cd,
					  	  CODESTATUSDNRANDPREARRESTLIMITATIO_cd) and
  		  o.order_status_cd + 1 - 1 = ORDER_STAT_ORDERED_cd  and 		;    2550.00
		  o.active_ind + 1 - 1 = 1
 
;join od								; 007 09/22/2020 Removed this join. See a later Select
;	where od.order_id = o.order_id and
;;		  od.oe_field_meaning_id + 1 - 1 in(229.00, 1103.00)   						; 005 07/31/2019  Replaced. See below.
;;		   ; 229.00 is RESUSCITATIONSTATUS    1103.00 is Special Instructions		; 005 07/31/2019  Replaced. See below.
;      	 (od.oe_field_meaning_id + 1 - 1 in(229.00, 1103.00)						; 005 07/31/2019  Replacement
;		   ; 229.00 is RESUSCITATIONSTATUS    1103.00 is Special Instructions		; 005 07/31/2019  Replacement
;		  or																		; 005 07/31/2019  Replacement
;      	  od.oe_field_id in( 2031600739.00) ; Code Status							; 005 07/31/2019  Replacement
;      	 )																			; 005 07/31/2019  Replacement
 
join eam
	where eam.encntr_id = encount.encntr_id and
		  eam.end_effective_dt_tm + 1 - 1 >= cnvtdatetime(curdate, curtime3) and
		  eam.active_ind + 1 - 1 = 1  and
		  eam.encntr_alias_type_cd + 1 - 1 = MRN_CD
 
join eaf
	where eaf.encntr_id = encount.encntr_id and
		  eaf.end_effective_dt_tm + 1 - 1 >= cnvtdatetime(curdate, curtime3) and
		  eaf.active_ind + 1 - 1 = 1  and
		  eaf.encntr_alias_type_cd + 1 - 1 = FIN_CD
 
join p
	where p.person_id = encount.person_id and
		  trim(p.name_last_key) != 'CERNERTEST'
 
order by facility, pt_loc, patient, e.encntr_id, o.order_id
;	,  od.oe_field_meaning_id, od.detail_sequence desc			; 007 09/22/2020    'od.' fields have been removed
 
head report
	cnt = 0
	stat = alterlist(resus->qual,1)
	resus->cnt_resus_orders = 0
 
head o.order_id
	VAR_FIRST_ROW_FOR_THIS_ORDER = "YES"
  	cnt = cnt + 1
	STAT = ALTERLIST ( resus-> qual ,  cnt )
 
;head od.oe_field_meaning_id
;	null
;
;head od.detail_sequence  ; We'll be getting the last/latest order detail for Resus orderss and the last/latest for
						 ; special instructions.
;detail
;    If (VAR_FIRST_ROW_FOR_THIS_ORDER = "YES")
 
		resus->qual[cnt].person_id = e.person_id
		resus->qual[cnt].encntr_id =  e.encntr_id
		resus->qual[cnt].patient =  p.name_full_formatted
		resus->qual[cnt].fin = fin
	 	resus->qual[cnt].mrn = mrn
		resus->qual[cnt].facility = facility
	    resus->qual[cnt].nurse_unit = nurse_unit
	    resus->qual[cnt].room = room
	    resus->qual[cnt].bed =  bed
	;    pt_enc->qual[cnt].pt_loc = build2(trim(substring(1,30, nurse_unit)),';',
	;    						 		trim(substring(1,30, room)),';',
	;    						 		trim(substring(1,30, bed))
	;    						 	   )
	    resus->qual[cnt].pt_loc = pt_loc
		resus->qual[cnt].age = age
		resus->qual[cnt].dob = dob
		resus->qual[cnt].order_id = order_id
		resus->qual[cnt].catalog_cd = o.catalog_cd					; 007 09/22/2020 This is new
;		resus->qual[cnt].catalog = catalog							; 007 09/22/2020 Removed. We use catalog_cd mostly now
;;		resus->qual[cnt].code_status =
;;;						 (if (od.oe_field_meaning_id = 229.00)  ;229.00 is RESUSCITATIONSTATUS			; 005 07/31/2019 Replaced. See Below.
;;						 (if (od.oe_field_meaning_id = 229.00  ;229.00 is RESUSCITATIONSTATUS			; 005 07/31/2019 Replacement
;;							 or																			; 005 07/31/2019 Replacement
;;      	  				     od.oe_field_id in( 2031600739.00)) ; Code Status							; 005 07/31/2019 Replacement
;;						 		od.oe_field_display_value
;;						  else
;;						  		" "
;;						  endif)
;;		resus->qual[cnt].special_interventions =
;;						 (if (od.oe_field_meaning_id = 1103.00)  ;1103.00 is Special Instructions
;;						 		od.oe_field_display_value
;;						  else
;;						  		" "
;;						  endif)
		resus->qual[cnt].current_start_dt_tm  = current_start_dt_tm
		resus->qual[cnt].projected_stop_dt_tm = projected_stop_dt_tm
 
		resus->cnt_resus_orders = resus->cnt_resus_orders + 1
 
;	ELSE
;		resus->qual[cnt].code_status =
;;						 (if (od.oe_field_meaning_id = 229.00)  ;229.00 is RESUSCITATIONSTATUS			; 005 07/31/2019 Replaced. See Below.
;						 (if (od.oe_field_meaning_id = 229.00  ;229.00 is RESUSCITATIONSTATUS			; 005 07/31/2019 Replacement
;							 or																			; 005 07/31/2019 Replacement
;      	  				     od.oe_field_id in( 2031600739.00)) ; Code Status							; 005 07/31/2019 Replacement
;
;						 		od.oe_field_display_value
;						  else
;						  		resus->qual[cnt].code_status
;						  endif)
;		resus->qual[cnt].special_interventions =
;						 (if (od.oe_field_meaning_id = 1103.00)  ;1103.00 is Special Instructions
;						 		od.oe_field_display_value
;						  else
;						  		resus->qual[cnt].special_interventions
;						  endif)
;
;	ENDIF
 
;;foot od.oe_field_meaning_id
;;	VAR_FIRST_ROW_FOR_THIS_ORDER = "NO"
 
foot report
  	resus->cnt = cnt
	STAT = ALTERLIST ( resus-> qual ,  cnt )
 
with nocounter, time = 900 ;, maxrec = 5
 
;;go to exit_script
 
 
;**********************************************************************************************************
; 007 09/22/2020   Get the Code Status orders and the associated info for them
;				   Prior to now, this was done in the one, big Select found above.
;**********************************************************************************************************
 
;;declare cnt_cs = i2 with noconstant(0)
;;
;;; See?  there are no interventions for this one order. At least. there aren't suppose to be. That's why it's handled here in
;;; it's own Select. If one day there are interventions, then the next select will include them.
;;
;;Select into "nl"
;;from (dummyt d with seq = size(resus->qual,5))
;;plan d
;;	where
;;		  resus->qual[d.seq].catalog_cd = CODESTATUSFULLCODE_cd
;;Detail
;;	resus->qual[d.seq].catalog_cd =  = uar_get_code_description(resus->qual[d.seq].catalog_cd)
;;	code_status_intervs = ''
;;with nocounter
 
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
Select into "nl"
	encntr_id = resus->qual[d.seq].encntr_id
from (dummyt d with seq = size(resus->qual,5)),
	 orders o,
     order_detail od,
	 oe_format_fields off,
     order_entry_format oef  ;,
plan d
join o
	where o.person_id = resus->qual[d.seq].person_id and
		  o.encntr_id = resus->qual[d.seq].encntr_id and
		  o.catalog_cd in ( CODESTATUSFULLCODE_cd,
		  					CODESTATUS_CD,
		   					CODESTATUSDONOTRESUSCITATEALLOWAL_cd,
					  		CODESTATUSDNRANDPREARRESTLIMITATIO_cd) and
		   o.order_status_cd = 2550.00 and 	; Ordered
       	   o.active_ind = 1
join od
	where od.order_id = o.order_id and
		  od.oe_field_meaning = "OTHER"
join off
	where off.oe_field_id = od.oe_field_id and
		  off.accept_flag = 0 and
		  off.core_ind = 1
join oef
    where oef.oe_format_id = off.oe_format_id and
		  oef.catalog_type_cd = 2515.00  and ; Patient Care
		  oef.oe_format_name = "Code Status" and
		  oef.action_type_cd =  2534.00	  ; order
	; In P41.. These will be the 6 order detail oe_field_id values (in B41, they are different, so that's why we are
	;		   joining these last two tables... so this will work in the various domains. We are not hard coding these
	;   	   just for P41.
	;
	;			  group_seq 10		2031600739.00, ;	Code Status
	;			  group_seq 15		2031607781.00, ;	Intubate
	;			  group_seq 20		2031612493.00, ;	Vasopressors
	;			  group_seq 25		2031613207.00, ;	Non-Invasive Ventilation
	;			  group_seq 30		2031626739.00) ;	Antiarrhythmic Meds/Pacers
	;			  group_seq 40		2031624917.00, ;	Cardioversion
 
order by encntr_id, o.orig_order_dt_tm, off.group_seq, od.action_sequence desc
 
head encntr_id
	CODE_STATUS_OEF = ''
	CODE_STATUS_INTERVS = ''
head o.orig_order_dt_tm
	null
Head off.group_seq
;	cnt_cs = cnt_cs + 1
 
	If (off.label_text = 'Code Status')
		CODE_STATUS_OEF = trim(od.oe_field_display_value)
	Else
	 	If (CODE_STATUS_OEF = "DNR with Conditions" or
	 		CODE_STATUS_OEF = "DNR and Pre-arrest Limitations" or
	 		CODE_STATUS_OEF = "DNR (Allow all pre-arrest interventions)")
	 		If (cnvtupper(od.oe_field_display_value) = "DO NOT*" or
	 		    cnvtupper(od.oe_field_display_value) = "NO *")
				if (CODE_STATUS_INTERVS <= " ")
			 		CODE_STATUS_INTERVS = trim(od.oe_field_display_value)
			 	else
			 		CODE_STATUS_INTERVS = trim(build2(code_status_intervs, "; ", trim(od.oe_field_display_value)))
			 	endif
			endif
		endif
	endif
 
foot encntr_id
	 resus->qual[d.seq].code_status = CODE_STATUS_OEF
	 resus->qual[d.seq].special_interventions = CODE_STATUS_INTERVS
 
with nocounter

;008->
/*************************************************************************
DESCRIPTION:  Find Patients DX List
       NOTE:  
**************************************************************************/
select into 'nl:'
  from diagnosis    dx
     , nomenclature n
     , (dummyt d with seq = value(resus->cnt))
  plan d
   where resus->cnt                    >  0
     and resus->qual[d.seq]->encntr_id != 0
  join dx
   where dx.encntr_id           =  resus->qual[d.seq]->encntr_id
     and dx.diag_type_cd        in (88.000, 89.000)  ;Discharge, Final
     and dx.active_ind          =  1
     and dx.beg_effective_dt_tm <= cnvtdatetime(curdate , curtime3)
     and dx.end_effective_dt_tm >= cnvtdatetime(curdate , curtime3)
  join n
   where dx.nomenclature_id     =  n.nomenclature_id
     and n.active_ind           =  1
     and n.beg_effective_dt_tm  <= cnvtdatetime(curdate , curtime3)
     and n.end_effective_dt_tm  >= cnvtdatetime(curdate , curtime3)
detail
    if(resus->qual[d.seq]->dxList = '') 
        resus->qual[d.seq]->dxList = notrim(build2( trim(n.source_identifier, 3), ' - ', trim(n.source_string, 3)))
    else                                
        resus->qual[d.seq]->dxList = notrim(build2( resus->qual[d.seq]->dxList, ', '
                                                  , trim(n.source_identifier, 3), ' - ', trim(n.source_string, 3)))
    endif
with nocounter
;008<-
 
 
If ($Report_type = "S")  ; S is Spreadsheet
 
;-----------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------
;;; Exit message
;;; Below, we are seeing if any data was selected. If none was, print out a short... you ain't got nothin' message,
;;; Then exit to the end of the script.... Else.... continue on generating the Spreadsheet
;-----------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------
 
 
	if (SIZE(resus->qual, 5) = 0)
 
	  select into value($OUTDEV)
 
	  rpt_type = (if($Report_type = "S")
		  			"Report Type:  Spreadsheet"
		  		else
		  			"Report Type:  Report"	; You won't see this one.  Layout Builder will be called, not this part of the script.
		  		endif)
 
	  from (dummyt d)
	  head page
	    "{ps/792 0 translate 90 rotate/}" ;landscape program
	    row + 1
	  detail
 
		  col 0 report_title_var
		  row + 2
	      col 0 "There are no active resuscitation orders that match your requested parameters."
	      row + 2
	      col 0 facility_var
	      row + 2
	      col 0 "As of: "
	      col 10 printed_date
		  row + 2
		  col 0 rpt_type
	  with nocounter, dio = postscript, landscape
 
	  GO TO EXIT_SCRIPT
 
	ENDIF
 
	SELECT into $OUTDEV
		  facility = trim(substring(1,150,resus->QUAL[D1.SEQ].facility))
		, pat_location = trim(substring(1,150,resus->QUAL[D1.SEQ].pt_loc))
		, patient = trim(substring(1,150,resus->QUAL[D1.SEQ].patient))
		, mrn = trim(substring(1,150,resus->QUAL[D1.SEQ].mrn))
		, fin = trim(substring(1,150,resus->QUAL[D1.SEQ].fin))
		, dob = format(resus->QUAL[D1.SEQ].dob, "MM/DD/YYYY;;Q")
		, age = trim(substring(1,150,resus->QUAL[D1.SEQ].age))
        , DXes = trim(substring(1,2000,resus->qual[d1.seq]->dxList))  ;008
		, order_id = resus->QUAL[D1.SEQ].order_id
		, code_status_order = trim(substring(1,150,resus->QUAL[D1.SEQ].code_status))
		, special_interventions = trim(substring(1,400,resus->QUAL[D1.SEQ].special_interventions))
		, start_dt_tm = format(resus->QUAL[D1.SEQ].current_start_dt_tm, "MM/DD/YYYY hh:mm;;Q")
		, stop_dt_tm = format(resus->QUAL[D1.SEQ].projected_stop_dt_tm, "MM/DD/YYYY hh:mm;;Q")
 
	FROM
		(DUMMYT   D1  WITH SEQ = VALUE(SIZE(resus->qual, 5)))
 
	WHERE     resus->qual[d1.seq].nurse_unit != "Train1" and
			  resus->qual[d1.seq].code_status != "Full Code"
 
	order by facility, pat_location, patient
 
	WITH NOCOUNTER, SEPARATOR=" ", FORMAT
 
;------------------
; 002 04/24/2014  emailing is new
;------------------
 
elseif ($Report_type = "E" and  			; E is Email
 		CURDOMAIN = PRODUCTION_DOMAIN)		; CURDOAMIN is a system variable.  		PRODUCTION_DOMAIN is ours, and it's declared above.
 
;	SELECT INTO CONCAT('cer_print:',FILENAME)											; 004 01/18/2017   Greened out today
	SELECT INTO value(FILENAME)															; 004 01/18/2017   New today
		  facility = trim(substring(1,150,resus->QUAL[D1.SEQ].facility))
		, pat_location = trim(substring(1,150,resus->QUAL[D1.SEQ].pt_loc))
		, patient = trim(substring(1,150,resus->QUAL[D1.SEQ].patient))
		, mrn = trim(substring(1,150,resus->QUAL[D1.SEQ].mrn))
		, fin = trim(substring(1,150,resus->QUAL[D1.SEQ].fin))
		, dob = format(resus->QUAL[D1.SEQ].dob, "MM/DD/YYYY;;Q")
		, age = trim(substring(1,150,resus->QUAL[D1.SEQ].age))
        , DXes = trim(substring(1,2000,resus->qual[d1.seq]->dxList))  ;008
		, order_id = resus->QUAL[D1.SEQ].order_id
		, code_status_order = trim(substring(1,150,resus->QUAL[D1.SEQ].code_status))
		, special_interventions = trim(substring(1,400,resus->QUAL[D1.SEQ].special_interventions))
		, start_dt_tm = format(resus->QUAL[D1.SEQ].current_start_dt_tm, "MM/DD/YYYY hh:mm;;Q")
		, stop_dt_tm = format(resus->QUAL[D1.SEQ].projected_stop_dt_tm, "MM/DD/YYYY hh:mm;;Q")
 
	FROM
		(DUMMYT   D1  WITH SEQ = VALUE(SIZE(resus->qual, 5)))
 
	WHERE     resus->qual[d1.seq].nurse_unit != "Train1" and
			  resus->qual[d1.seq].code_status != "Full Code"
 
	order by facility, pat_location, patient
 
;	WITH NOCOUNTER, SEPARATOR=" ", FORMAT
	WITH NOCOUNTER,PCFORMAT('"',','), FORMAT
 
 
;;  See the SET  AIX_COMMAND below.
;;  EMAIL_BODY is a file name, not a declare variable.
;;  EMAIL_BODY is created earlier in this script.
;;   See the  "rm -f ", EMAIL_BODY"  linux command abbut 5 lines down from here?  That is removing this file.
 
; first email
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 004 01/18/2017 The below AIX_COMMAND replaces the one just below it.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	SET  AIX_COMMAND  =
		build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
			   " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS_01)
 
;	SET  AIX_COMMAND  =
;		CONCAT ('rm -f ' , TEMP_FILENAME , ' | unix2dos ' , FILENAME , ' | ' ,
; 					    '(cat ' , EMAIL_BODY , '; uuencode ' , FILEPATH , ' ' ,
;			    FILENAME , ')' ,
;			    " | mailx -s '" ,EMAIL_SUBJECT , "' " ,EMAIL_ADDRESS_01 , ' -- -f report@medstar.net | rm -f ' ,TEMP_FILENAME )
 
 
	SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
	SET AIX_CMDSTATUS = 0
	CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
; second email
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 004 01/18/2017 The below AIX_COMMAND replaces the one just below it.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	SET  AIX_COMMAND  =
		build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
			   " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS_02)
 
;	SET  AIX_COMMAND  =
;		CONCAT ('rm -f ' , TEMP_FILENAME , ' | unix2dos ' , FILENAME , ' | ' ,
; 					    '(cat ' , EMAIL_BODY , '; uuencode ' , FILEPATH , ' ' ,
;			    FILENAME , ')' ,
;			    " | mailx -s '" ,EMAIL_SUBJECT , "' " ,EMAIL_ADDRESS_02 , ' -- -f report@medstar.net | rm -f ' ,TEMP_FILENAME )
 
 
	SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
	SET AIX_CMDSTATUS = 0
	CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
; third email
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 004 01/18/2017 The below AIX_COMMAND replaces the one just below it.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	SET  AIX_COMMAND  =
		build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
			   " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS_03)
 
;	SET  AIX_COMMAND  =
;		CONCAT ('rm -f ' , TEMP_FILENAME , ' | unix2dos ' , FILENAME , ' | ' ,
; 					    '(cat ' , EMAIL_BODY , '; uuencode ' , FILEPATH , ' ' ,
;			    FILENAME , ')' ,
;			    " | mailx -s '" ,EMAIL_SUBJECT , "' " ,EMAIL_ADDRESS_03 , ' -- -f report@medstar.net | rm -f ' ,TEMP_FILENAME )
 
	SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
	SET AIX_CMDSTATUS = 0
	CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
; fourth email
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 004 01/18/2017 The below AIX_COMMAND replaces the one just below it.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	SET  AIX_COMMAND  =
		build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
			   " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS_04)
 
;	SET  AIX_COMMAND  =
;		CONCAT ('rm -f ' , TEMP_FILENAME , ' | unix2dos ' , FILENAME , ' | ' ,
; 					    '(cat ' , EMAIL_BODY , '; uuencode ' , FILEPATH , ' ' ,
;			    FILENAME , ')' ,
;			    " | mailx -s '" ,EMAIL_SUBJECT , "' " ,EMAIL_ADDRESS_04 , ' -- -f report@medstar.net | rm -f ' ,TEMP_FILENAME )
 
	SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
	SET AIX_CMDSTATUS = 0
	CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
; fifth email
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 004 01/18/2017 The below AIX_COMMAND replaces the one just below it.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	SET  AIX_COMMAND  =
		build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
			   " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS_05)
 
;	SET  AIX_COMMAND  =
;		CONCAT ('rm -f ' , TEMP_FILENAME , ' | unix2dos ' , FILENAME , ' | ' ,
; 					    '(cat ' , EMAIL_BODY , '; uuencode ' , FILEPATH , ' ' ,
;			    FILENAME , ')' ,
;			    " | mailx -s '" ,EMAIL_SUBJECT , "' " ,EMAIL_ADDRESS_05 , ' -- -f report@medstar.net | rm -f ' ,TEMP_FILENAME )
 
	SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
	SET AIX_CMDSTATUS = 0
	CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
; sixth email
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 004 01/18/2017 The below AIX_COMMAND replaces the one just below it.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	SET  AIX_COMMAND  =
		build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
			   " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS_06)
 
;	SET  AIX_COMMAND  =
;		CONCAT ('rm -f ' , TEMP_FILENAME , ' | unix2dos ' , FILENAME , ' | ' ,
; 					    '(cat ' , EMAIL_BODY , '; uuencode ' , FILEPATH , ' ' ,
;			    FILENAME , ')' ,
;			    " | mailx -s '" ,EMAIL_SUBJECT , "' " ,EMAIL_ADDRESS_06 , ' -- -f report@medstar.net | rm -f ' ,TEMP_FILENAME )
 
 
	SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
	SET AIX_CMDSTATUS = 0
	CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
; seventh email
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 004 01/18/2017 The below AIX_COMMAND replaces the one just below it.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	SET  AIX_COMMAND  =
		build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
			   " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS_07)
 
;	SET  AIX_COMMAND  =
;		CONCAT ('rm -f ' , TEMP_FILENAME , ' | unix2dos ' , FILENAME , ' | ' ,
; 					    '(cat ' , EMAIL_BODY , '; uuencode ' , FILEPATH , ' ' ,
;			    FILENAME , ')' ,
;			    " | mailx -s '" ,EMAIL_SUBJECT , "' " ,EMAIL_ADDRESS_07 , ' -- -f report@medstar.net | rm -f ' ,TEMP_FILENAME )
 
 
	SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
	SET AIX_CMDSTATUS = 0
	CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
 ; clean up.   (Removing the files in cer_print does not seem to work. They are deleted by the system in a day or 2.
 ; 				Removing EMAIL_BODY from $CCLUSERDIR does work.)
 
	SET  AIX_COMMAND  =
;		CONCAT ('rm -f ' , EMAIL_BODY)													; 004 01/18/2017  Greened out
		CONCAT ('rm -f ' , FILENAME,  ' | rm -f ' , EMAIL_BODY)							; 004 01/18/2017  Replacement
 
	SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
	SET AIX_CMDSTATUS = 0
	CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
 
 
;------------------
; 002 04/24/2014  The above emailing is new
;------------------
 
 
elseif ($Report_Type = "R")  ;  We're using Layout Builder for the Report version.
 
 
 
	select into "nl:"									; 007 09/22/2020 thi select is new
	from (dummyt d with seq = size(resus->qual,5))
	where resus->qual[d.seq].code_status != "Full Code"
	head report
		cnt_cs = 0
	detail
		cnt_cs = cnt_cs + 1
	with nocounter
 
 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; The two following lines were added because we are using Layout Builder.
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 
	SET _SendTo =  $OUTDEV   ; request->output_device
	CALL LayoutQuery(0)
 
 
ENDIF
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 
 
#EXIT_SCRIPT
 
end
go
