/*********************************************************************************************************************************
 Program Title:     Order Volume
 Object name:       7_Pat_Care_Order_Vol_20140312
 Source file:       7_Pat_Care_Order_Vol_20140312.prg
 Purpose:           Pull orders by order type and order for all facilities.  Gives order volume for date range to user.

**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
 Mod  Date          Analyst                 OPAS            Comment
 ---  ----------    --------------------    ------          ----------------------------------------------------------------------
 001  03.12.2014    Kathleen R Entwistle    R2:000023571721 Created the report.
 002  11.04.2015    Tameka Overton                          Added order status
 003  11.12.2015    Brian Twardy            see comment     MCGA: 202162
                                                            Request/Task: R2:000061959837/R2:000084138609
                                                            Requestor:  Molly Leahy of GUH
                                                            Added the ordering physician
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
 004  11.27.2015    Brian Twardy            see comment     MCGA: 202225
                                                            Request/Task: R2:000061997032/R2:000084211675
                                                            CareNet Agenda List: 734
                                                            Requestor:  Molly Leahy of GUH
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            Also add the following:
                                                            - Facility prompt
                                                            - Ability to multi select more than one Order in the same Order type.
                                                            - The Attending of Record  (keep ordering provider too)
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)

 005 06/16/2016     Brian Twardy            See comment     MCGA: 203615
                                                            Request/Task: R2:000062824226/R2:000085862417
                                                            Requestor:  Molly Leahy of GUH and Dr Ernest Fischer
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            Emailing capability has been added.  A special report for
                                                            'UltaSouind Duplex Lower Extremity Vein' radiology orders will
                                                            be emailed out daily, with the use of a separate wrapper program.
                                                            This special request will use a hard coded set of ordering
                                                            physicians.  (Time was of the essence, and this needed to be done for
                                                            a study... yesterday)

 006 08/08/2016     Brian Twardy            See comment     MCGA: 203912
                                                            Request/Task: R2:000062990386/R2:000086202201
                                                            Requestor:  Molly Leahy of GUH
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            A daily report with all admissions orders, i.e. "Admit to inpatient MGUH",
                                                            with GUH level of care of "Intermediate care". We are also adding
                                                            MRN and FIN for the corresponding current location.

 007 10/26/2016     Brian Twardy            See comment     MCGA: 204856
                                                            Request/Task: R2:000064628334/R2:000086883998
                                                            Requestor:  Molly Leahy of GUH and Dr Ernest Fischer
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            Emailing capability has been added.  A special report for
                                                            'MGUH Hospitalist Imaging In' radiology and cardiology orders will
                                                            be emailed out daily or weekly, with the use of a separate wrapper program.
                                                            This special request will use the same hard coded set of ordering
                                                            physicians as  the 'UltaSouind Duplex Lower Extremity Vein' report,
                                                            which was added here with revision 005 in June 2016.
                                                            This email can be generated with $REP_TYPE = "EHOSPIN" (Email MGUH Hospitalist
                                                            Imaging In Order Report)

 008 11/15/2016     Brian Twardy            See comment     MCGA: 205069
                                                            Request/Task: R2:000065474897/R2:000087042748
                                                            Requestor:  Lunar Song of MNRH (and Jennifer Thompson)
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            Orders listed under the $PCORD parameter were ordered in such a way that
                                                            uppercase alphabetic characters were ordered before the lowercase alphabetic
                                                            characters. APPLE SAUCE was ordered before Apple Pie. This has been fixed.
                                                            Look in prompt builder.

 009 12/30/2016     Brian Twardy            See comment     MCGA: 205373
                                                            Request/Task: R2:000066443926/R2:000087232471
                                                            Requestor:  Molly Leahy of GUH and Dr Ernest Fischer
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            This request is for Dr Ernest Fischer of MGUH.....
                                                            Report should include ordered by with the same list of Hospitalist as
                                                            MCGA #204856.
                                                            A special report for 'MGUH Hospitalist Orders' will
                                                            be emailed out, perhaps only once, with the use of a separate wrapper program.
                                                            The following orders (insted of the diagnostic orders):
                                                            1.Ascitic Fluid Cell count w/ Diff
                                                            2.Body Fluid Cell count w/ Diff, Miscellaneous
                                                            3.CSF Cell Count w/ Diff
                                                            4.Fluid CSF Cell Count w/ Diff
                                                            5.Peritoneal Fluid Cell Count w/ Diff
                                                            6.Pleural Fluid Cell Count w/ Diff
                                                            7.Chest 1 View Portable (But ONLY those with indication:
                                                                        S/P Intubation/Line placement)
                                                            Other details: ordererd Monday - Friday
                                                            All other patient data/identifiers can mirror the report for the US LE Vein Report.
                                                            This email can be generated with $REP_TYPE = "EHOSPORD" (Email MGUH Hospitalist
                                                            Orders Report)

 010 01/18/2017     Brian Twardy            See comment     MCGA: _____
                                                            OPAS Incident:  _________
                                                            Cerner SR: 415110973
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            Emailing issues after upgrade to RHEL 6.8 last evening

 011 01/24/2017     Brian Twardy            See comment     MCGA: 205871
                                                            OPAS Request/Task:  R2:000067976492/R2:000087503339
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            A report in spreadsheet format was needed for this one order, 'Prepare for
                                                            OR/Anesthesia Red Blood Cells'.  This report is needed for all patients, not just
                                                            hospitalist patients (as earlier reports had been requested for earlier MCGAs).
                                                            This request is being submitted for Dr James J Malatack, through Dr Ernest Fischer.
                                                            This request is similar to these two MCGAs (among others) for Dr Fischer:
                                                            - 205373 (# 009 above)
                                                            - 204856 (# 007 above)

 012 04/03/2017     Brian Twardy            See comment     MCGA: 206684  (customer: Lunar Song MNRH)
                                                            CareNet Agenda List: 1194
                                                            OPAS Request/Task: R2:000070158616/R2:000088002911
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            To the report that is generated from Explorer Menu (the emailed
                                                            versions have been including these fields for a while)...
                                                            Added the patient name (last name, first name) to the Order Volume report &
                                                            placed the column in front of the FIN column.
                                                            Plus... for Dr Lee Monsein of the Department of Radiology of MWHC, added
                                                            the MRN right after the new patient name.

 013 06/14/2017     Brian Twardy            See comment     MCGA: n/a  (customer: Lauren W Taylor of MNRH and Jennifer Thompson of Medconnect IS)
                                                            CareNet Agenda List: n/a
                                                            OPAS Incident: R2:000056278123
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            Now that Medconnect Phase III has been implemented, many of the orderable names
                                                            are quite long, so the parameters needed to be widened in Prompt builder. That
                                                            has been done at this time.

 014 08/02/2017     Brian Twardy            See comment     MCGA: 208457  (users: Khadija Bowen - Offic Mgr Phys Practice and Lori Whitelaw of IS)
                                                            CareNet Agenda List: n/a
                                                            OPAS Request/Task: R2:000071139619/R2:000088818564
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            Added DOB (Patient name was requested too, but that was already here)

 015 03/29/2018     Brian Twardy            See comment     MCGA: 211544
                                                            Request/Task: R2:000071874736/R2:000090614575
                                                            Requestor:  Molly Leahy of GUH and Dr Ernest Fischer
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            This request is for Dr Ernest Fischer of MGUH.....
                                                            Report should include 'ordered by' folks with the same list of Hospitalist as
                                                            MCGA #205373, which is for 'MGUH Hospitalist Orders', WITH THESE 4 ADDITIONS:
                                                            -Abalos, Kathleen
                                                            -Sommovilla, Nili
                                                            -Kruse, Stacy
                                                            -Lavelle, Helen
                                                            This email can still be generated with $REP_TYPE = "EHOSPORD" (Email MGUH Hospitalist
                                                            Orders Report)

 016 03/29/2018    Brian Twardy             MCGA: n/a       CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no change)
                                            R: n/a          Migration Project
                                            T: n/a          Two hospitals have been migrated into Medconnect at this time. That has brought about a few changes to this
                                                            program script. These THREE hospitals have been added (which includes St Mary's)
                                                            - Medstar Montgomery Medical Center
                                                            - Medstar Southern Maryland Hospital Center
                                                            - Medstar St Mary's Hospital

 017 04/02/2018    Brian Twardy             MCGA: 211623    CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            Request/Task: R2:000071885751/R2:000090636416
                                                            Requestor:  Molly Leahy of GUH and Dr Ernest Fischer
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            This request is for Dr Ernest Fischer of MGUH.....
                                                            Similar to the request in 2016 (MCGA 203615). To that original DVT report in 2016
                                                            (“US Lower Ext Duplex Veins Orders Report”), include the following the folowing:
                                                            1. Add the admit date for the encounter
                                                            2. Pull all the studies from 7/1/2017-12/31/2017 rather than having it come day by day
                                                            3. Include these 4 physicians to the list already being used.:
                                                            -Abalos, Kathleen
                                                            -Sommovilla, Nili
                                                            -Kruse, Stacy
                                                            -Lavelle, Helen
                                                            This email can still be generated with $REP_TYPE = "EUS" (The 'US Lower Ext Duplex Veins
                                                            Orders Report') . The daily report being sent out will nclude the new admit date filed
                                                            and the 4 new physicians.

 018 12/18/2019   Brian Twardy              MCGA: n/a       SOM Task: n/a
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            These three hospitals are being renamed on the occasion of St Mary's finally being migrated into Medconnect.
                                                            The prompts may have been revised, along with the possibility of the designations of these hospitals
                                                            within this program/script.
                                                              - Medstar Montgomery Medical Center
                                                              - Medstar Southern Maryland Hospital Center
                                                              - Medstar St Mary's Hospital

 019 05/12/2020   Brian Twardy              MCGA: 221812    CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            SOM Task: TASK3566226
                                                            Requestor:  Kim Vandenassem
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            Addition of 2 Columns to Order Volume Report to Identify Orders from ACS Unit Location
                                                            (make it optional)

 020 08/18/2020   Brian Twardy              MCGA: 223062    CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            SOM Task: still awaiting MCGA approval
                                                            Requestor: Laura Phipps and Leah Seiler, both from FSMC
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no name change)
                                                            New emailing needed. This time for CONSULT TO NEUROLOGY and CONSULT TO NEUROSURGERY.
                                                            The $rep_type used here will be "ENEURO".

 021 02/09/2021   Brian Twardy              MCGA: n/a       CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            SOM Incident: INC11666824
                                                            Requestor: Lunor Song from MNRH
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no name change)
                                                            Enhanced to include future orders.  These orders have 0.00 in the encntr_id
                                                            column in the orders table.  Now, we will use the originating_encntr_id
                                                            column from the orders table... when we join the orders table row with the
                                                            encounter table row.
 022 03/12/2021   Kim Frazier               INC11888747     Blank reports/missing order for orders that do not have the originating encounter
                                                            id in the order table.
 023 07/16/2021   Brian Twardy              MCGA: n/a       CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            SOM Task: n/a
                                                            Requestor: myself (Brian T)
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no name change)
                                                            The special instructions in the report's order details often contain carriage returns
                                                            and line feeds.  These special characters cause some formatting issues with all of the
                                                            formats of this report. There are many formats, when one considers the emailing formats.
                                                            id in the order table.
 024 09/15/2021   Brian Twardy              MCGA: n/a       CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no change)
                                                            MCGA: n/a
                                                            SOM Task: TASK4776064
                                                            Requestor: Karthi Dandapani
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no name change)
                                                            The Medical service column has been added to the report, but only when
                                                            $REP_TYPE = "S"
                                                            FYI: The Discharge Order Report was modified too, by adding the Ordering Physician column.
 025 07/19/2022   Brian Twardy              MCGA: 234357    CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no name change)
                                                            SOM Request/Task: RITM3014246 / TASK5515745
                                                            Requestor: Melat Tessera
                                                            CCL script: cust_script:7_Pat_Care_Order_Vol_20140312.prg (no name change)
                                                            A new report to email, one for two Material Management orders for WHC:
                                                            - Equip TED Pump Daily Usage
                                                            - SCD Machine
                                                            $REP_TYPE is new, "EMATMAN"
 026 08/29/2022   Brian Twardy              MCGA: n/a       CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no name change)
                                                            SOM RITM/Task: RITM3028083 / TASK5542937
                                                            Requestor: Leif Coble
                                                            A new report to email the following order to Harbor Hospital Center:
                                                            - Orthopoxvirus(Monkeypox) by PCR
                                                            A $REP_TYPE value is new, "EMONKEYPOX"
 027 11/18/2022   Brian Twardy              MCGA: 236050    CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no name change)
                                                            SOM RITM/Task: RITM3160528 / TASK5803004
                                                            Requestor: Angela Morrell
                                                            A new report with a customized format to email the following orders to Georgetown:
                                                            - SLP Modified Barium Swallow Evaluation
                                                            - Speech Language Pathology Additional Treatment
                                                            - Speech Language Pathology Evaluation and Treatment
                                                            - Speech Language Pathology Fiberoptic Endoscopic Evaluation
                                                            A $REP_TYPE value is new, "ESLP"
 028 04/28/2023   Brian Twardy              MCGA: 238607    CCL script: 7_Pat_Care_Order_Vol_20140312.prg (no name change)
                                                            SOM RITM/Task: RITM0014609 / SCTASK0017503
                                                            Requestor: Angela Morrell
                                                            This order has been added to the 4 orders mentioned above in Modification 027.
                                                            - Modified Barium Swallow SLP
 029 08/01/2023 Kim Frazier         mcga 233481             Add a column for orderset name
 030 7/3/2024   KRF                     SCTASK0103297       Sped it up by removing bad index hints
 031 02/20/2025 Michael Mayes        PanicAsk               They are asking for a enc_type to be added to the spreadsheet.
***********************************************************************************************************************************/
drop program 7_pat_care_order_vol_20140312 go
create program 7_pat_care_order_vol_20140312
prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Facility(s):" = VALUE(0.00)
    , "Order Beginning Date" = "SYSDATE"     ;* Date the order was created.
    , "End Date" = "SYSDATE"                 ;* Date the order was created.
    , "Unit and Room?" = 0
    , "Order Type" = 636727.00
    , "Order" = 0
    , "Report Type" = "S"

with OUTDEV, FACILITY, BEGDT, ENDDT, UNIT_ROOM, OrdType, PCORD, REP_TYPE


/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/

declare day_range = i4 with constant(abs(DATETIMEDIFF(CNVTDATETIME($BEGDT),CNVTDATETIME($ENDDT)))),protect
declare attend_doc_cd  = f8 with constant(uar_get_code_by("MEANING", 333, "ATTENDDOC"))             ; 004 11/27/2015  New
declare order_cat_disp = vc with noconstant("")                                                     ; 004 11/27/2015  New
Declare facility_var = vc with noconstant("")                                                       ; 004 11/27/2015  New
Declare idx = i2 with noconstant(0)

;********************************************************************************************************
;  004 11/27/2015   New.   Put the requested facility(s) into a string, because we may want
;                          to list them out in the "you ain't got no data" message. We will want to clue
;                          the user in on what he/she requested.


If (0.00 in ($FACILITY))

    set facility_var = "Any(*)"

Else

    select into 'nl:'
        cv.display
    from
        code_value cv
    where
        cv.code_value in ($FACILITY)
    head report
        cnt = 0
    detail
        cnt = cnt + 1
        if (cnt = 1)
            facility_var = cv.display
        else
            facility_var = concat(facility_var, ', ', cv.display)
        endif
    with nocounter
Endif

;---------------------------------------------------------------------------------------
;   005  06/16/2016   Email definitions
;---------------------------------------------------------------------------------------

DECLARE EMAIL_SUBJECT = VC WITH NOCONSTANT(" ")

; Note:  EMAIL_SUBJECT will be altered later if there is no data included in the the email report.
;SET EMAIL_SUBJECT =                                                                                ; 006 08/08/2016  replaced. see below.
;               build2("US Lower Ext Duplex Veins Orders Report - ", $BEGDT, " to ", $ENDDT)        ; 006 08/08/2016  replaced. see below.
SET EMAIL_SUBJECT = (If ($REP_TYPE = "EUS")
                        build2("US Lower Ext Duplex Veins Orders Report - ", $BEGDT, " to ", $ENDDT)
                     ElseIf ($REP_TYPE = "EADM")
                        build2("Admit to Inpatient MGUH Orders Report - ", $BEGDT, " to ", $ENDDT)
                     ElseIf ($REP_TYPE = "EHOSPIN")                                                 ; 007 10/26/2016 New Email report
                        build2("MGUH Hospitalist Imaging In Order Report - ", $BEGDT, " to ", $ENDDT)
                     ElseIf ($REP_TYPE = "EHOSPORD")                                                ; 009 12/30/2016 New Email report
                        build2("MGUH Hospitalist Order Report - ", $BEGDT, " to ", $ENDDT)
                     ElseIf ($REP_TYPE = "ERBC")                                                ; 011 01/24/2017 New Email report
                        build2("MGUH Prepare for OR Anesthesia Red Blood Cells Order Report - ", $BEGDT, " to ", $ENDDT)
                     ElseIf ($REP_TYPE = "ENEURO")                                              ; 020 08/18/2020 New Email report
                        build2("MFSMC Consult to Neurology and Consult to Neurosurgery Order Report - ", $BEGDT, " to ", $ENDDT)
                     ElseIf ($REP_TYPE = "EMATMAN")                                             ; 025 07/19/2022 New Email report
                        build2("MWHC Order Volume Report of Equip TED Pump Daily Usage and SCD Machine orders - ", $BEGDT, " to ", $ENDDT)
                     ElseIf ($REP_TYPE = "EMONKEYPOX")                                          ; 026 08/29/2022 New Email report
                        build2("HHC Orthopoxvirus(Monkeypox) by PCR Order Volume Report - ", $BEGDT, " to ", $ENDDT)
                     ElseIf ($REP_TYPE = "ESLP")                                                ; 027 11/18/2022 New Email report
                        build2("MGUH SLP Order Volume Report - ", $BEGDT, " to ", $ENDDT)
                     Endif)

DECLARE EMAIL_BODY = VC WITH NOCONSTANT("")
DECLARE UNICODE = VC WITH NOCONSTANT("")

DECLARE AIX_COMMAND   = VC WITH NOCONSTANT("")
DECLARE AIX_CMDLEN    = I4 WITH NOCONSTANT(0)
DECLARE AIX_CMDSTATUS = I4 WITH NOCONSTANT(0)

DECLARE PRODUCTION_DOMAIN = vc with constant("P41")         ; we only want emails to go out from Production

Declare EMAIL_ADDRESS   = vc
SET EMAIL_ADDRESS = $OUTDEV             ; Take note that $OUTDEV is moved here, as the email address for the outgoing report

;SET EMAIL_BODY = concat("us_lower_extremity_email_body_",                                                  ; 006 08/08/2026 Replaced. See below.
;    format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"), ".dat")                                   ; 006 08/08/2026 Replaced. See below.
SET EMAIL_BODY = (If ($REP_TYPE = "EUS")                                                                    ; 006 08/08/2026 Replacement
                        concat("us_lower_extremity_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".dat")
                  ElseIf ($REP_TYPE = "EADM")
                        concat("guh_admit_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".dat")
                  ElseIf ($REP_TYPE = "EHOSPIN")                                                            ; 007 10/26/2016 New Email report
                        concat("guh_hospitalist_imag_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".dat")
                  ElseIf ($REP_TYPE = "EHOSPORD")                                                           ; 009 12/306/2016 New Email report
                        concat("guh_hospitalist_ord_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".dat")
                  ElseIf ($REP_TYPE = "ERBC")                                                           ; 011 01/24/2017 New Email report
                        concat("guh_rbc_ord_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".dat")
                  ElseIf ($REP_TYPE = "ENEURO")                                                         ; 020 08/18/2020 New Email report
                        concat("fsh_neuro_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".dat")
                  ElseIf ($REP_TYPE = "EMATMAN")                                                ; 025 07/19/2022 New Email report
                        concat("whc_mat_man_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".dat")
                  ElseIf ($REP_TYPE = "EMONKEYPOX")                                             ; 026 08/29/2022 New Email report
                        concat("hhc_orthopoxvirus_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".dat")
                  ElseIf ($REP_TYPE = "ESLP")                                                   ; 027 11/18/2022 New Email report
                        concat("guh_slp_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".dat")
                  Endif)

;DECLARE FILENAME = VC                                                                                      ; 006 08/08/2026 Replaced. See below
;       WITH  NOCONSTANT(CONCAT("us_lower_extremity_",
;                             format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q"),
;                             trim(substring(3,3,cnvtstring(RAND(0)))),     ;<<<< These 3 digits are random #s
;                             ".csv"))

DECLARE FILENAME = VC with noconstant("")                                                               ; 006 08/08/2026 Replacement
Set FILENAME = (If ($REP_TYPE = "EUS")                                                                  ; 006 08/08/2026 Replacement
                      CONCAT("us_lower_extremity_",
                              format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q"),
                              trim(substring(3,3,cnvtstring(RAND(0)))),     ;<<<< These 3 digits are random #s
                              ".csv")
                ElseIf ($REP_TYPE = "EADM")
                      CONCAT("guh_admit_",
                              format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q"),
                              trim(substring(3,3,cnvtstring(RAND(0)))),     ;<<<< These 3 digits are random #s
                              ".csv")
                ElseIf ($REP_TYPE = "EHOSPIN")                                                          ; 007 10/26/2016 New Email report
                      CONCAT("guh_hospitalist_imag_",
                              format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q"),
                              trim(substring(3,3,cnvtstring(RAND(0)))),     ;<<<< These 3 digits are random #s
                              ".csv")
                ElseIf ($REP_TYPE = "EHOSPORD")                                                         ; 009 12/30/2016 New Email report
                      CONCAT("guh_hospitalist_ord_",
                              format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q"),
                              trim(substring(3,3,cnvtstring(RAND(0)))),     ;<<<< These 3 digits are random #s
                              ".csv")
                ElseIf ($REP_TYPE = "ERBC")                                                         ; 011 01/24/2017 New Email report
                      CONCAT("guh_rbc_ord_",
                              format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q"),
                              trim(substring(3,3,cnvtstring(RAND(0)))),     ;<<<< These 3 digits are random #s
                              ".csv")
                ElseIf ($REP_TYPE = "ENEURO")                                                           ; 011 01/24/2017 New Email report
                      CONCAT("fsh_neuro_ord_",
                              format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q"),
                              trim(substring(3,3,cnvtstring(RAND(0)))),     ;<<<< These 3 digits are random #s
                              ".csv")
                ElseIf ($REP_TYPE = "EMATMAN")                                              ; 025 07/19/2022 New Email report
                        concat("whc_mat_man_ord_",
                               format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".csv")
                ElseIf ($REP_TYPE = "EMONKEYPOX")                                           ; 026 08/29/2022 New Email report
                        concat("hhc_orthopoxvirus_ord_",
                               format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".csv")
                ElseIf ($REP_TYPE = "ESLP")                                                 ; 027 11/18/2022 New Email report
                        concat("guh_slp_ord_",
                               format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                               trim(substring(3,3,cnvtstring(RAND(0)))),        ;<<<< These 3 digits are random #s
                               ".csv")
                Endif)


;------------------------------------------------------------------------------------------
;; Below, we are creating a file that will hold the email body. The file is named EMAIL_BODY.
;; char(13), char(10)  is a carriage return/Line feed (or maybe it's the other way around.)

If ($Rep_type = "EUS" and   ;   We only want to create the file if emails were requested (i.e. when $Rep_type = "EUS"  -- for
                            ;                                                                                             Email Ultra Sounds)
    CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

    ;NOTE: Immediately below, EMAIL_BODY is being filled with the email body text. We will add to it later if there is
    ;      no data included in the the email report.
    Select into (value(EMAIL_BODY))
            build2("The Order Volume Report for US Lower Extremity Duplex Vein orders is attached to this email.",
                    char(13), char(10), char(13), char(10),
                   "Run date and time: ",
                       format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
                   "For:  ", facility_var, char(13), char(10), char(13), char(10),
                   "This report was run for this date range: ", $BEGDT, "  --to--  ", $ENDDT,
                   char(13), char(10), char(13), char(10),
                   "These orders are being included in this report:", char(13), char(10), char(13), char(10),
                   "     - US Lower Ext Duplex Veins Bilateral", char(13), char(10),
                   "     - US Lower Ext Duplex Veins Left", char(13), char(10),
                   "     - US Lower Ext Duplex Veins Limited Bilat", char(13), char(10),
                   "     - US Lower Ext Duplex Veins Right"
                   )
    from dummyt
    with format, noheading

; 006 08/08/2016  The below ElseIf is new today

ElseIf ($Rep_type = "EADM" and  ;   We only want to create this file if emails were requested (i.e. when $Rep_type = "EADM"  -- for
                            ;                                                                                             Email GUH Admits)
    CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

    ;NOTE: Immediately below, EMAIL_BODY is being filled with the email body text. We will add to it later if there is
    ;      no data included in the the email report.
    Select into (value(EMAIL_BODY))
            build2("The Order Volume Report for Admit to Inpatient MGUH orders is attached to this email.",
                    char(13), char(10), char(13), char(10),
                   "Run date and time: ",
                       format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
                   "For: ", facility_var, char(13), char(10), char(13), char(10),
                   "This report was run for this date range: ", $BEGDT, "  --to--  ", $ENDDT,
                   char(13), char(10), char(13), char(10),
                   "Only orders with 'Intermediate Care' as the 'GUH level of care' are included in this report"
                   )
    from dummyt
    with format, noheading

;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -
; 007 10/24/2016  The below ElseIf is new today
;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -

ElseIf ($Rep_type = "EHOSPIN" and   ;   We only want to create this file if emails were requested (i.e. when $Rep_type = "EHOSPIN"
                            ;                                                                                   -- for    Email GUH
                            ;                                                                                             Hospitalist Images)
    CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

    ;NOTE: Immediately below, EMAIL_BODY is being filled with the email body text. We will add to it later if there is
    ;      no data included in the the email report.
    Select into (value(EMAIL_BODY))
            build2("The Order Volume Report for MGUH Hospitalist Imaging In orders is attached to this email.",
                    char(13), char(10), char(13), char(10),
                   "Run date and time: ",
                       format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
                   "For: ", facility_var, char(13), char(10), char(13), char(10),
                   "This report was run for this date range: ", $BEGDT, "  --to--  ", $ENDDT,
                   char(13), char(10), char(13), char(10),
                   "These orders are being included in this report:", char(13), char(10), char(13), char(10),
                   "     - CT Abdomen .... (all starting as CT Abdomen...)", char(13), char(10),
                   "     - CT Chest ...... (all starting as CT Chest...)", char(13), char(10),
                   "     - Echocardiogram Complete", char(13), char(10),
                   "     - Echocardiogram Complete with Bubble study", char(13), char(10),
                   "     - US Lower Ext Duplex Veins Bilateral", char(13), char(10),
                   "     - US Lower Ext Duplex Veins Left", char(13), char(10),
                   "     - US Lower Ext Duplex Veins Right", char(13), char(10),
                   "     - US Renal Complete", char(13), char(10),
                   "     - US Renal Limited", char(13), char(10),
                   "     - US Spleen"
                   )
    from dummyt
    with format, noheading

;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -
; 009 12/30/2016  The below ElseIf is new today
;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -

ElseIf ($Rep_type = "EHOSPORD" and  ;   We only want to create this file if emails were requested (i.e. when $Rep_type = "EHOSPORD"
                            ;                                                                                   -- for    Email GUH
                            ;                                                                                             Hospitalist Orders)
    CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

    ;NOTE: Immediately below, EMAIL_BODY is being filled with the email body text. We will add to it later if there is
    ;      no data included in the the email report.
    Select into (value(EMAIL_BODY))
            build2("The Order Volume Report for MGUH Hospitalist Orders is attached to this email.",
                    char(13), char(10), char(13), char(10),
                   "Run date and time: ",
                       format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
                   "For: ", facility_var, char(13), char(10), char(13), char(10),
                   "This report was run for this date range: ", $BEGDT, "  --to--  ", $ENDDT,
                   char(13), char(10), char(13), char(10),
                   "These orders are being included in this report:", char(13), char(10), char(13), char(10),
                   "     - Ascitic Fluid Cell count w/ Diff", char(13), char(10),
                   "     - Body Fluid Cell count w/ Diff, Miscellaneous", char(13), char(10),
                   "     - CSF Cell Count w/ Diff", char(13), char(10),
                   "     - Fluid CSF Cell Count w/ Diff", char(13), char(10),
                   "     - Peritoneal Fluid Cell Count w/ Diff", char(13), char(10),
                   "     - Pleural Fluid Cell Count w/ Diff", char(13), char(10),
                   "     - Chest 1 View Portable (But ONLY those with indication:", char(13), char(10),
                   "                S/P Intubation/Line placement)", char(13), char(10),char(13), char(10),
                   "Note: These orders were originally ordered Monday - Friday"
                   )
    from dummyt
    with format, noheading

ElseIf ($Rep_type = "ERBC" and  ;   We only want to create this file if emails were requested (i.e. when $Rep_type = "ERBC"
                            ;                                           -- for    Email GUH Prepare for OR/Anesthesia Red Blood Cells  Orders)
    CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

    ;NOTE: Immediately below, EMAIL_BODY is being filled with the email body text. We will add to it later if there is
    ;      no data included in the the email report.
    Select into (value(EMAIL_BODY))
            build2("The Order Volume Report for MGUH Prepare for OR/Anesthesia Red Blood Cells Orders is attached to this email.",
                    char(13), char(10), char(13), char(10),
                   "Run date and time: ",
                       format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
                   "For: ", facility_var, char(13), char(10), char(13), char(10),
                   "This report was run for this date range: ", $BEGDT, "  --to--  ", $ENDDT,
                   char(13), char(10)
                   )
    from dummyt
    with format, noheading

       ; 020 08/18/2020 New email report
ElseIf ($Rep_type = "ENEURO" and    ;   We only want to create this file if emails were requested (i.e. when $Rep_type = "ERBC"
                            ;                                           -- for    Email GUH Prepare for OR/Anesthesia Red Blood Cells  Orders)
    CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

    ;NOTE: Immediately below, EMAIL_BODY is being filled with the email body text. We will add to it later if there is
    ;      no data included in the the email report.
    Select into (value(EMAIL_BODY))
            build2("The Order Volume Report for MFSMC Consult to Neurology and Consult to Neurosurgery Orders is attached to this email.",
                    char(13), char(10), char(13), char(10),
                   "Run date and time: ",
                       format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
                   "For: ", facility_var, char(13), char(10), char(13), char(10),
                   "This report was run for this date range: ", $BEGDT, "  --to--  ", $ENDDT,
                   char(13), char(10)
                   )
    from dummyt
    with format, noheading

       ; 025 07/19/2022 New Email report
ElseIf ($REP_TYPE = "EMATMAN" and   ;   We only want to create this file if emails were requested
    CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

    ;NOTE: Immediately below, EMAIL_BODY is being filled with the email body text. We will add to it later if there is
    ;      no data included in the the email report.
    Select into (value(EMAIL_BODY))
            build2("The Order Volume Report of Equip TED Pump Daily Usage and SCD Machine orders is attached to this email.",
                    char(13), char(10), char(13), char(10),
                   "Run date and time: ",
                       format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
                   "For: ", facility_var, char(13), char(10), char(13), char(10),
                   "This report was run for this date range: ", $BEGDT, "  --to--  ", $ENDDT,
                   char(13), char(10)
                   )
    from dummyt
    with format, noheading

       ; 026 08/29/2022 New Email report
ElseIf ($REP_TYPE = "EMONKEYPOX" and    ; We only want to create this file if emails were requested
    CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

    ;NOTE: Immediately below, EMAIL_BODY is being filled with the email body text. We will add to it later if there is
    ;      no data included in the the email report.
    Select into (value(EMAIL_BODY))
            build2("The Order Volume Report of Orthopoxvirus(Monkeypox) by PCR orders is attached to this email.",
                    char(13), char(10), char(13), char(10),
                   "Run Date and Time: ",
                       format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
                   "For: ", facility_var, char(13), char(10), char(13), char(10),
                   ; The below line is shortened, because the order name is long and there is a text maximum.
;                  "This report was run for this date range: ", $BEGDT, "  --to--  ", $ENDDT,
                   "Report Date Range: ", $BEGDT, "  --to--  ", $ENDDT,
                   char(13), char(10)
                   )
    from dummyt
    with format, noheading
       ; 027 11/18/2022 New Email report
ElseIf ($REP_TYPE = "ESLP" and  ; We only want to create this file if emails were requested
    CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

    ;NOTE: Immediately below, EMAIL_BODY is being filled with the email body text. We will add to it later if there is
    ;      no data included in the the email report.
    Select into (value(EMAIL_BODY))
            build2("The Order Volume Report of SLP orders is attached to this email.",
                    char(13), char(10), char(13), char(10),
                   "Run Date and Time: ",
                       format(cnvtdatetime(curdate, curtime3),"MM/DD/YYYY hh:mm;;Q"), char(13), char(10), char(13), char(10),
                   "For: ", facility_var, char(13), char(10), char(13), char(10),
                   ; The below line is shortened, because the order name is long and there is a text maximum.
;                  "This report was run for this date range: ", $BEGDT, "  --to--  ", $ENDDT,
                   "Report Date Range: ", $BEGDT, "  --to--  ", $ENDDT,
                   char(13), char(10), char(13), char(10),
                   "These orders are being included in this report:", char(13), char(10), char(13), char(10),
                   "     - Modified Barium Swallow SLP", char(13), char(10),                    ; 028 04/28/2028 New order for this email
                   "     - SLP Modified Barium Swallow Evaluation", char(13), char(10),
                   "     - Speech Language Pathology Additional Treatment", char(13), char(10),
                   "     - Speech Language Pathology Evaluation and Treatment", char(13), char(10),
                   "     - Speech Language Pathology Fiberoptic Endoscopic Evaluation", char(13), char(10))
    from dummyt
    with format, noheading

;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -

endif

;----------------------------------------------------------------------------------------


;********************************************************************************************************

;********************************************************************************************************
;  004 11/27/2015   New.   Put the requested catalog order-ables into a string, because we may want
;                          to list them out in the "you ain't got no data" message. We will want to clue
;                          the user in on what he/she requested.


select into 'nl:'
    cv.display
from
    code_value cv
where
    cv.code_value in ($PCORD)

head report
    cnt = 0

detail
    cnt = cnt + 1
    if (cnt = 1)
        ORDER_CAT_DISP = cv.display
    elseif (cnt <= 3)
        ORDER_CAT_DISP = concat(ORDER_CAT_DISP, ', ', cv.display)
    endif
foot report
    If (cnt > 3)
        ORDER_CAT_DISP = concat(ORDER_CAT_DISP, "....")
    Endif

with nocounter


/********************************************************************************************************
        Check Date Range
********************************************************************************************************/
 /* krf eliminate to see if it's faster
if (day_range > 31 and $REP_TYPE != "E*")                   ; The 31 day check only applies if NOT run in Ops for emailing.

select into value($OUTDEV)

      from (dummyt d)
      head page
        "{ps/792 0 translate 90 rotate/}" ;landscape program
        row + 1
      detail

          col 0 "Order Volume Report"
          row + 2
          col 0 "Date range cannot exceed 31 days."
          row + 2
          col 0 "Facility(s):"                          ; 004 11/27/2015  Facility and Order Cat mentions are all new.
          col 16 facility_var
          row + 2
          col 0 "Catalog items:"
          col 16 ORDER_CAT_DISP
          row + 2
          col 0 "Between:"
          col 10 $BEGDT
          col 31 "--and--"
          col 39 $ENDDT
          row + 2
      with nocounter, dio = postscript, landscape, maxcol = 250                 ; 012 04/03/2017   maxcol = 250 is new
go to end_of_program

endif

 */
/*****************************************************************/
                                                ; 020 08/18/2020 ENEURO was added here today
If ($rep_type in("S", "ENEURO",                 ; 005 06/16/2016  This one line is new. We have emails too.
                 "EMATMAN",                     ; 025 07/19/2022 EMATMAN for WHC's Material Management orders report is new
                 "EMONKEYPOX") and              ; 026 08/29/2022 EMONKEYPOX for HHC's 'Orthopoxvirus(Monkeypox) by PCR' orders report is new
    $UNIT_ROOM = 0)                             ; 019 05/22/2020 $UNIT_ROOM is new. 0 means that unit and room is not requested.

    SELECT
        If ($rep_type = "ENEURO" or             ; 020 08/18/2020 ENEURO was added here today
            $rep_type = "EMATMAN" or            ; 025 07/19/2022 EMATMAN for WHC's Material Management orders report is new
            $rep_type = "EMONKEYPOX")           ; 026 08/29/2022 EMONKEYPOX for HHC's 'Orthopoxvirus(Monkeypox) by PCR' orders report is new
              into value(filename)
            ; 024 09/15/2021 The below "Select" fields were moved here (from below), because the "S" version of the report will now
            ;                include Service, and the "ENEURO" version will continue to not include it.
              o_catalog_disp =                                                              ; 004 11/27/2015  ... description is now being used. Another...
                        trim(substring(1,200,uar_get_code_description(o.catalog_cd)))       ; 004 11/27/2015  ... field like dept_display_name...
                                                                                            ; 004 11/27/2015  ... may be better
            , Order_Date_Time = o.orig_order_dt_tm "@SHORTDATETIME"
            , patient = trim(substring(1,130,p.name_full_formatted))                    ; 012 04/03/2017  patient is new for the Expl. Menu version
            , MRN = trim(substring(1,30,cnvtalias(eam.alias,eam.alias_pool_cd)))            ; 012 04/03/2017  MRN is new for the Expl. Menu version
            , FIN = cnvtalias(ea.alias,ea.alias_pool_cd)                                ; 004 11/27/2015  FIN is updated to include alias template
            , DOB = format(p.birth_dt_tm, "MM/DD/YYYY;;Q")                              ; 014 08/02/2017  Added today
            , Facility = uar_get_code_display(e.loc_facility_cd)
    ;       , Order_Details = o.order_detail_display_line                               ; 023 07/16/2021 Replaced. See below.
              ; 023 07/16/2021 Below, we are replacing Rarriage Returns with NULL and Line Feeds with a space.
            , Order_Details = trim(substring(1, 800, replace(replace(o.order_detail_display_line,char(13), " "), char(10), "")))
            , order_status = uar_get_code_display(o.order_status_cd);002
            , ordered_by = trim(substring(1,130, pr.name_full_formatted))               ; 003 11/12/2015  New
            , attending = (If (pr_a.name_last_key =  "UNASSIGNED" and                   ; 004 11/27/2015  New field
                              pr_a.name_first_key = "UNASSIGNED")
                               ""
                           Else
                               pr_a.name_full_formatted
                           endif)
            ;029
            , OrderSet = trim(pc.description)

              with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress
            ;030      , orahintcbo ("index(oa xpkorder_action)","index(o xie17orders)" )
        else
            into $outdev
            ; 024 09/15/2021 The below "Select" fields were moved here (from below), because the "S" version of the report will now
            ;                include Service, and the "ENEURO" version will continue to not include it.
              o_catalog_disp =                                                              ; 004 11/27/2015  ... description is now being used. Another...
                        trim(substring(1,200,uar_get_code_description(o.catalog_cd)))       ; 004 11/27/2015  ... field like dept_display_name...
                                                                                            ; 004 11/27/2015  ... may be better
            , Order_Date_Time = o.orig_order_dt_tm "@SHORTDATETIME"
            , patient = trim(substring(1,130,p.name_full_formatted))                    ; 012 04/03/2017  patient is new for the Expl. Menu version
            , ENC_TYPE = trim(substring(1, 100, uar_get_code_description(e.encntr_type_cd)))   ;031 
            , service = uar_get_code_display(e.med_service_cd)                          ; 024 09/15/2021 New for the plain, spreadsheet only
            , MRN = trim(substring(1,30,cnvtalias(eam.alias,eam.alias_pool_cd)))            ; 012 04/03/2017  MRN is new for the Expl. Menu version
            , FIN = cnvtalias(ea.alias,ea.alias_pool_cd)                                ; 004 11/27/2015  FIN is updated to include alias template
            , DOB = format(p.birth_dt_tm, "MM/DD/YYYY;;Q")                              ; 014 08/02/2017  Added today
            , Facility = uar_get_code_display(e.loc_facility_cd)
    ;       , Order_Details = o.order_detail_display_line                               ; 023 07/16/2021 Replaced. See below.
              ; 023 07/16/2021 Below, we are replacing Rarriage Returns with NULL and Line Feeds with a space.
            , Order_Details = trim(substring(1, 800, replace(replace(o.order_detail_display_line,char(13), " "), char(10), "")))
            , order_status = uar_get_code_display(o.order_status_cd);002
            , ordered_by = trim(substring(1,130, pr.name_full_formatted))               ; 003 11/12/2015  New
            , attending = (If (pr_a.name_last_key =  "UNASSIGNED" and                   ; 004 11/27/2015  New field
                              pr_a.name_first_key = "UNASSIGNED")
                               ""
                           Else
                               pr_a.name_full_formatted
                           endif)
            ;029
            , OrderSet = trim(pc.description)


                   WITH nocounter, separator = " ", format
            ;030 ,          orahintcbo ("index(oa xpkorder_action)","index(o xie17orders)" )
        endif
    FROM
          orders   o
        , ENCOUNTER   E
        , person   p                                                                ; 012 04/03/2017  person is new for the Expl. Menu version
        , encntr_alias   EA
        , encntr_alias   eam                                                        ; 012 04/03/2017  MRN is new for the Expl. Menu version
        , order_action oa                                                           ; 003 11/12/2015  New table
        , prsnl pr                                                                  ; 003 11/12/2015  New table
        , encntr_prsnl_reltn epr_a                                                  ; 004 10/29/2015  New table
        , prsnl pr_a                                                                ; 004 10/29/2015  New table
        , pathway_catalog pc

    Plan O
        where o.orig_order_dt_tm between cnvtdatetime($BEGDT) and cnvtdatetime($ENDDT)
    ;   and o.catalog_cd = $PCORD                                                   ; 004 11/27/2015  multi-orders can be selected. This line is OUT.
        and o.catalog_cd in ($PCORD)                                                ; 004 11/27/2015  multi-orders can be selected. This line is IN.
        and o.template_order_id = 0.0 ;only include Parent orders
    Join E
;       where e.encntr_id = o.encntr_id                                             ; 021 02/09/2021 Replaced
;       where e.encntr_id = o.originating_encntr_id                                 ; 022 Replaced 021 02/09/2021 Replacement
        where ( e.encntr_id = o.encntr_id or                                        ;022 3/15/2021 Replacement for 021
             (e.encntr_id = o.originating_encntr_id                                 ;022 3/15/2021 Replacement for 021
                and o.encntr_id = 0.00))                                            ;022 3/15/2021 Replacement for 021
          and (0.00 in ($FACILITY) or               ; All/Any = 0.00                ; 004 11/27/2015  New
               e.loc_facility_cd in ($FACILITY))                                    ; 004 11/27/2015  New

    Join p                                                                          ; 012 04/03/2017  Person is new for the Expl. Menu version
        where p.person_id = e.person_id                                             ;                 We want the patient's name now

    Join EA
        where ea.encntr_id = e.encntr_id
        and ea.encntr_alias_type_cd = 1077.00
        and ea.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and ea.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

      Join eam                                                                  ; 012 04/03/2017 MRN is new for the Expl. Menu version
        where eam.encntr_id = e.encntr_id
        and eam.encntr_alias_type_cd = 1079.00
        and eam.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and eam.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)


    join oa                                                                     ; 003 11/12/2015  New table
        where oa.order_id = outerjoin(o.order_id) and
              oa.action_type_cd = outerjoin(2534.00)  ; Order

    join pr
        where pr.person_id = outerjoin(oa.action_personnel_id)                  ; 005 06/16/2016   Replaced. See below.

    join epr_a                                                                  ; 004 11/27/2015  New join
          where epr_a.encntr_id = outerjoin(e.encntr_id)
            and epr_a.encntr_prsnl_r_cd = outerjoin(attend_doc_cd)
            and epr_a.active_ind = outerjoin(1)
            and epr_a.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate, curtime3))

    join pr_a                                                                   ; 004 11/27/2015  New join
        where pr_a.person_id = outerjoin(epr_a.prsnl_person_id)

;029
    join pc
        where pc.pathway_catalog_id = outerjoin(o.pathway_catalog_id)

    ;order by                                                                   ; 004 11/27/2015  new "order by". See new one below.
    ;     Facility
    ;   , order_date_time

    order by                                                                    ; 004 11/27/2015  new "order by". This is it.
          o_catalog_disp
        , Facility
        , order_date_time

;   WITH nocounter, separator = " ", format, time = 1800,
;        orahintcbo ("index(oa xpkorder_action)","index(o xie17orders)" )       ; 003 11/12/2015  These orahintcbo's are new.
;


/*****************************************************************
019 05/12/2020 The below elseif is new. We are allowing one to request the regular spreadsheet now with unit and room.
               The $UNIT_ROOM parameter is new. 1 means yes.. they wnat the unit and room. 0 means that they do not.
******************************************************************/
                                                ; 020 08/18/2020 ENEURO was added here today
ElseIf ($rep_type in("S", "ENEURO",             ; 005 06/16/2016  This one line is new. We have emails too.
                     "EMONKEYPOX") and          ; 026 08/29/2022 EMONKEYPOX for HHC's 'Orthopoxvirus(Monkeypox) by PCR' orders report is new
        $UNIT_ROOM = 1)                         ; 019 05/22/2020 $UNIT_ROOM is new. 1 means that unit and room is requested.

    SELECT
        If ($rep_type = "ENEURO" or             ; 020 08/18/2020 ENEURO was added here today
            $rep_type = "EMONKEYPOX")           ; 026 08/29/2022 EMONKEYPOX for HHC's 'Orthopoxvirus(Monkeypox) by PCR' orders report is new
            ; 024 09/15/2021 The below "Select" fields were moved here (from below), because the "S" version of the report will now
            ;                include Service, and the "ENEURO" version will continue to not include it.
              into value(filename)
              o_catalog_disp =                                                              ; 004 11/27/2015  ... description is now being used. Another...
                        trim(substring(1,200,uar_get_code_description(o.catalog_cd)))       ; 004 11/27/2015  ... field like dept_display_name...
                                                                                            ; 004 11/27/2015  ... may be better
            , Order_Date_Time = o.orig_order_dt_tm "@SHORTDATETIME"
            , patient = trim(substring(1,130,p.name_full_formatted))                        ; 012 04/03/2017  patient is new for the Expl. Menu version
            , MRN = trim(substring(1,30,cnvtalias(eam.alias,eam.alias_pool_cd)))            ; 012 04/03/2017  MRN is new for the Expl. Menu version
            , FIN = cnvtalias(ea.alias,ea.alias_pool_cd)                                    ; 004 11/27/2015  FIN is updated to include alias template
            , DOB = format(p.birth_dt_tm, "MM/DD/YYYY;;Q")                                  ; 014 08/02/2017  Added today
            , Facility = uar_get_code_display(e.loc_facility_cd)
            , UNIT = uar_get_code_display(elh.loc_nurse_unit_cd)
            , room = uar_get_code_display(elh.loc_room_cd)
    ;       , Order_Details = o.order_detail_display_line                               ; 023 07/16/2021 Replaced. See below.
              ; 023 07/16/2021 Below, we are replacing Rarriage Returns with NULL and Line Feeds with a space.
            , Order_Details = trim(substring(1, 800, replace(replace(o.order_detail_display_line,char(13), " "), char(10), "")))
            , order_status = uar_get_code_display(o.order_status_cd);002
            , ordered_by = trim(substring(1,130, pr.name_full_formatted))               ; 003 11/12/2015  New
            , attending = (If (pr_a.name_last_key =  "UNASSIGNED" and                   ; 004 11/27/2015  New field
                              pr_a.name_first_key = "UNASSIGNED")
                               ""
                           Else
                               pr_a.name_full_formatted
                           endif)
            ;029
            , OrderSet = trim(pc.description)

              with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress
            ;030,      orahintcbo ("index(oa xpkorder_action)","index(o xie17orders)" )

        else
            INTO $outdev    ;     o_catalog_disp = uar_get_code_display(o.catalog_cd)       ; 004 11/27/2015  display cuts off way too early, so...
            ; 024 09/15/2021 The below "Select" fields were moved here (from below), because the "S" version of the report will now
            ;                include Service, and the "ENEURO" version will continue to not include it.
              o_catalog_disp =                                                              ; 004 11/27/2015  ... description is now being used. Another...
                        trim(substring(1,200,uar_get_code_description(o.catalog_cd)))       ; 004 11/27/2015  ... field like dept_display_name...
                                                                                            ; 004 11/27/2015  ... may be better
            , Order_Date_Time = o.orig_order_dt_tm "@SHORTDATETIME"
            , patient = trim(substring(1,130,p.name_full_formatted))                    ; 012 04/03/2017  patient is new for the Expl. Menu version
            , ENC_TYPE = trim(substring(1, 100, uar_get_code_description(e.encntr_type_cd)))   ;031 
            , service = uar_get_code_display(e.med_service_cd)                          ; 024 09/15/2021 New for the plain, spreadsheet only
            , MRN = trim(substring(1,30,cnvtalias(eam.alias,eam.alias_pool_cd)))        ; 012 04/03/2017  MRN is new for the Expl. Menu version
            , FIN = cnvtalias(ea.alias,ea.alias_pool_cd)                                ; 004 11/27/2015  FIN is updated to include alias template
            , DOB = format(p.birth_dt_tm, "MM/DD/YYYY;;Q")                              ; 014 08/02/2017  Added today
            , Facility = uar_get_code_display(e.loc_facility_cd)
            , UNIT = uar_get_code_display(elh.loc_nurse_unit_cd)
            , room = uar_get_code_display(elh.loc_room_cd)
    ;       , Order_Details = o.order_detail_display_line                               ; 023 07/16/2021 Replaced. See below.
              ; 023 07/16/2021 Below, we are replacing Rarriage Returns with NULL and Line Feeds with a space.
            , Order_Details = trim(substring(1, 800, replace(replace(o.order_detail_display_line,char(13), " "), char(10), "")))
            , order_status = uar_get_code_display(o.order_status_cd);002
            , ordered_by = trim(substring(1,130, pr.name_full_formatted))               ; 003 11/12/2015  New
            , attending = (If (pr_a.name_last_key =  "UNASSIGNED" and                   ; 004 11/27/2015  New field
                              pr_a.name_first_key = "UNASSIGNED")
                               ""
                           Else
                               pr_a.name_full_formatted
                           endif)
            ;029
            , OrderSet = trim(pc.description)
         WITH nocounter, separator = " ", format
              ;030 ,orahintcbo ("index(oa xpkorder_action)","index(o xie17orders)" )
        endif
    FROM
          orders   o
        , encounter   e
        , encntr_loc_hist elh
        , person   p                                                                ; 012 04/03/2017  person is new for the Expl. Menu version
        , encntr_alias   EA
        , encntr_alias   eam                                                        ; 012 04/03/2017  MRN is new for the Expl. Menu version
        , order_action oa                                                           ; 003 11/12/2015  New table
        , prsnl pr                                                                  ; 003 11/12/2015  New table
        , encntr_prsnl_reltn epr_a                                                  ; 004 10/29/2015  New table
        , prsnl pr_a
        , pathway_catalog pc                                                                ; 004 10/29/2015  New table

    Plan O
        where o.orig_order_dt_tm between cnvtdatetime($BEGDT) and cnvtdatetime($ENDDT)
    ;   and o.catalog_cd = $PCORD                                                   ; 004 11/27/2015  multi-orders can be selected. This line is OUT.
        and o.catalog_cd in ($PCORD)                                                ; 004 11/27/2015  multi-orders can be selected. This line is IN.
        and o.template_order_id = 0.0 ;only include Parent orders
    Join E
;       where e.encntr_id = o.encntr_id                                             ; 021 02/09/2021 Replaced
;       where e.encntr_id = o.originating_encntr_id                                 ; 022 Replaced 021 02/09/2021 Replacement
        where ( e.encntr_id = o.encntr_id or                                        ;022 3/15/2021 Replacement for 021
             (e.encntr_id = o.originating_encntr_id                                 ;022 3/15/2021 Replacement for 021
                and o.encntr_id = 0.00))                                            ;022 3/15/2021 Replacement for 021
          and (0.00 in ($FACILITY) or               ; All/Any = 0.00                ; 004 11/27/2015  New
               e.loc_facility_cd in ($FACILITY))                                    ; 004 11/27/2015  New

    Join ELH            ; associated with the entering unit
        where
;           elh.encntr_id = o.encntr_id and                                         ; 021 02/09/2021 Replaced
            elh.encntr_id = e.encntr_id and                                         ; 021 02/09/2021 Replacement
           (elh.end_effective_dt_tm != cnvtdatetime("31-DEC-2100 00:00:00") or
            elh.active_ind = 1) and
            elh.transaction_dt_tm  = (select max(sub.transaction_dt_tm)
                                     from ENCNTR_LOC_HIST sub
                                     where sub.encntr_id = elh.encntr_id and
                                           sub.transaction_dt_tm < o.orig_order_dt_tm and
                                          (sub.end_effective_dt_tm != cnvtdatetime("31-DEC-2100 00:00:00") or
                                           sub.active_ind = 1) and
                                           sub.TRANSACTION_DT_TM between
                                                            cnvtlookbehind("80,D",cnvtdatetime($BEGDT))  and
                                                            cnvtlookahead("51,D",cnvtdatetime($ENDDT))
                                           and
                                           sub.encntr_type_cd not in (           309313.00, ; Preadmit
                                                                              607971507.00)   ; INPATIENTREFERRAL_CD

                                     with nocounter,  orahintcbo ("index (sub xie1encntr_loc_hist)"))
            and elh.transaction_dt_tm <= cnvtdatetime($ENDDT)

    Join p                                                                          ; 012 04/03/2017  Person is new for the Expl. Menu version
        where p.person_id = e.person_id                                             ;                 We want the patient's name now

    Join EA
        where ea.encntr_id = e.encntr_id
        and ea.encntr_alias_type_cd = 1077.00
        and ea.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and ea.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

      Join eam                                                                  ; 012 04/03/2017 MRN is new for the Expl. Menu version
        where eam.encntr_id = e.encntr_id
        and eam.encntr_alias_type_cd = 1079.00
        and eam.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and eam.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)


    join oa                                                                     ; 003 11/12/2015  New table
        where oa.order_id = outerjoin(o.order_id) and
              oa.action_type_cd = outerjoin(2534.00)  ; Order

    join pr
        where pr.person_id = outerjoin(oa.action_personnel_id)                  ; 005 06/16/2016   Replaced. See below.

    join epr_a                                                                  ; 004 11/27/2015  New join
          where epr_a.encntr_id = outerjoin(e.encntr_id)
            and epr_a.encntr_prsnl_r_cd = outerjoin(attend_doc_cd)
            and epr_a.active_ind = outerjoin(1)
            and epr_a.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate, curtime3))

    join pr_a                                                                   ; 004 11/27/2015  New join
        where pr_a.person_id = outerjoin(epr_a.prsnl_person_id)

;029
    join pc
        where pc.pathway_catalog_id = outerjoin(o.pathway_catalog_id)
    ;order by                                                                   ; 004 11/27/2015  new "order by". See new one below.
    ;     Facility
    ;   , order_date_time

    order by                                                                    ; 004 11/27/2015  new "order by". This is it.
          o_catalog_disp
        , Facility
        , order_date_time

    WITH nocounter, separator = " ", format, time = 1800
;,       orahintcbo ("index(oa xpkorder_action)","index(o xie17orders)" )       ; 003 11/12/2015  These orahintcbo's are new.


;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -
; 027 11/18/2022   New email being sent out from this program/script (GUH SLP Order Volume Report) SLP = Sleep, Language Pathology
;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -


                                                ; 020 08/18/2020 ENEURO was added here today
ElseIf ($rep_type = "ESLP")                     ; ESLP for 'GUH SLP Order Volume Report is new'
                                                ; NOTE:  This report for the SLP orders for GUH is only available by email


    record slp
        (
        01 pat_cnt = i4
        01 qual [*]
           02 patient = vc
           02 order_name = vc
           02 current_unit = vc
           02 dob = vc
           02 mrn = vc
           02 order_date_time = vc
         )

    declare cnt = i4 with noconstant(0)
    declare pat_cnt = i4 with noconstant(0)

    SELECT into 'nl:'
              order_name =
                        trim(substring(1,200,uar_get_code_description(o.catalog_cd)))
            , patient = trim(substring(1,130,p.name_full_formatted))
            , CURRENT_UNIT = replace(trim(substring(1,80,uar_get_code_display(e.loc_nurse_unit_cd))), "GUH ", "")
            , DOB = format(p.birth_dt_tm, "MM/DD/YYYY;;Q")
            , MRN = trim(substring(1,30,cnvtalias(eam.alias,eam.alias_pool_cd)))
            , Order_Date_Time = o.orig_order_dt_tm "@SHORTDATETIME"
    FROM
          orders   o
        , encounter   e
        , person   p
        , encntr_alias   eam

    Plan O
        where o.orig_order_dt_tm between cnvtdatetime($BEGDT) and cnvtdatetime($ENDDT)
        and o.order_status_cd = 2550.00  ;  Ordered
        and o.catalog_cd in ($PCORD)
        and o.template_order_id = 0.0 ;only include Parent orders
;;      and o.catalog_cd in (1969916755.00, ;  SLP Modified Barium Swallow Evaluation
;;                              3883311.00, ;  Speech Language Pathology Additional Treatment
;;                            101816226.00, ;  Speech Language Pathology Evaluation and Treat
;;                            101816238.00) ;  Speech Language Pathology Fiberoptic Endoscopic Evaluation o
    Join E
        where (e.encntr_id = o.encntr_id or
              (e.encntr_id = o.originating_encntr_id
                and o.encntr_id = 0.00))
          and (e.loc_facility_cd in ($FACILITY))
          and e.loc_nurse_unit_cd not in (8252317.00, ; GUH C51
                                          4378671.00, ; GUH W31
                                          4385166.00) ; GUH W32

    Join p
        where p.person_id = e.person_id

    Join eam
        where eam.encntr_id = e.encntr_id
        and eam.encntr_alias_type_cd = 1079.00
        and eam.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and eam.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
    order by
          patient
        , order_name
    Head report
        cnt = 0
        pat_cnt = 0
    head patient
        pat_cnt = pat_cnt + 1
    detail
            cnt = cnt + 1
            stat = alterlist(slp->qual, cnt)
            slp->qual[cnt].order_name = trim(substring(1,200,uar_get_code_description(o.catalog_cd)))
            slp->qual[cnt].patient = trim(substring(1,130,p.name_full_formatted))
            slp->qual[cnt].current_unit = replace(trim(substring(1,80,uar_get_code_display(e.loc_nurse_unit_cd))), "GUH ", "")
            slp->qual[cnt].DOB = format(p.birth_dt_tm, "MM/DD/YYYY;;Q")
            slp->qual[cnt].MRN = trim(substring(1,30,cnvtalias(eam.alias,eam.alias_pool_cd)))
            slp->qual[cnt].Order_Date_Time = format(o.orig_order_dt_tm, "MM/DD/YYYY hh:mm;;Q")

    foot report
            cnt = cnt + 1
            stat = alterlist(slp->qual, cnt)
            slp->qual[cnt].patient = "ZZZ blank line"
            cnt = cnt + 1
            stat = alterlist(slp->qual, cnt)
            slp->qual[cnt].patient = "ZZZZ total line"

    with  Format, separator = " " ;030 , orahintcbo ("index (o xie1orders)")



    SELECT into value(filename)
             patient =  (If (slp->qual[d.seq].patient = "ZZZZ total line")
;                               build2 ("*** Patients ", cnvtstring(slp->pat_cnt,6,0), " ****")
                                build2 ("*** Patients ", trim(substring(1,7,cnvtstring(pat_cnt,6,0))), " ****")
                             elseIf (slp->qual[d.seq].patient = "ZZZ blank line")
                                " "
                             else
                                trim(substring(1,130,slp->qual[d.seq].patient))
                            endif)
            , current_unit = trim(substring(1,80,slp->qual[d.seq].current_unit))
            , DOB = trim(substring(1,40,slp->qual[d.seq].dob))
            , MRN = trim(substring(1,30,slp->qual[d.seq].mrn))
            , Order_Date_Time = trim(substring(1,30,slp->qual[d.seq].order_date_time))
            , order_type = trim(substring(1,130,slp->qual[d.seq].order_name))
    FROM
        (dummyt d with seq = (size(slp->qual,5)))
    order by  slp->qual[d.seq].patient, order_type
    with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress


;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -
; 005 06/16/2016   New email being sent out from this program/script (Order Volume Report for US Lower Extremity Duplex Vein orders)
; 006 08/08/2016   New email being sent out from this program/script (Order Volume Report for Admit to Inpatient MGUH orders)
;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -


;ElseIf ($rep_type = "EUS" and              ; 005 06/16/2016  An else for the emailing of Ultrasound orders for GUH   006 08/08/2016 Replaced
ElseIf ($rep_type in ("EUS","EADM") and     ; 006 08/08/2016  Added in Admit GUH orders
        CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

      Select into value(FILENAME)
    ;     o_catalog_disp = uar_get_code_display(o.catalog_cd)                           ; 004 11/27/2015  display cuts off way too early, so...
          o_catalog_disp =                                                              ; 004 11/27/2015  ... description is now being used. Another...
                    trim(substring(1,200,uar_get_code_description(o.catalog_cd)))       ; 004 11/27/2015  ... field like dept_display_name...
                                                                                        ; 004 11/27/2015  ... may be better
        , Order_Date_Time = o.orig_order_dt_tm "@SHORTDATETIME"
    ;   , FIN = ea.alias                                                            ; 004 11/27/2015  FIN is updated to include alias template
        , MRN = cnvtalias(eam.alias,eam.alias_pool_cd)                              ; 005 06/16/2016  MRN is new for GUH emailing
        , FIN = cnvtalias(ea.alias,ea.alias_pool_cd)                                ; 004 11/27/2015  FIN is updated to include alias template
        , Facility = uar_get_code_display(e.loc_facility_cd)
        , Admit_Date_Time = e.reg_dt_tm "@SHORTDATETIME"                            ; 017 04/02/2018 New field for "EUS"
        , Location = build2 (trim(substring(1,50, uar_get_code_display(e.loc_nurse_unit_cd))), "; ",
                             trim(substring(1,50, uar_get_code_display(e.loc_room_cd))))
;       , Order_Details = o.order_detail_display_line                               ; 023 07/16/2021 Replaced. See below.
          ; 023 07/16/2021 Below, we are replacing Rarriage Returns with NULL and Line Feeds with a space.
        , Order_Details = trim(substring(1, 800, replace(replace(o.order_detail_display_line,char(13), " "), char(10), "")))
        , order_status = uar_get_code_display(o.order_status_cd);002
        , ordered_by = trim(substring(1,130, pr.name_full_formatted))               ; 003 11/12/2015  New
        , attending = (If (pr_a.name_last_key =  "UNASSIGNED" and                       ; 004 11/27/2015  New field
                          pr_a.name_first_key = "UNASSIGNED")
                           ""
                       Else
                           pr_a.name_full_formatted
                       endif)
        ;029
        , OrderSet = trim(pc.description)

      FROM
          orders   o
        , ENCOUNTER   E
        , encntr_alias   EA
        , encntr_alias   eam                                                        ; 005 06/16/2016  New for emailing to GUH
        , order_action oa                                                           ; 003 11/12/2015  New table
        , prsnl pr                                                                  ; 003 11/12/2015  New table
        , encntr_prsnl_reltn epr_a                                                  ; 004 10/29/2015  New table
        , prsnl pr_a                                                                ; 004 10/29/2015  New table
        ;029
        , pathway_catalog pc

      Plan O
        where o.orig_order_dt_tm between cnvtdatetime($BEGDT) and cnvtdatetime($ENDDT)
    ;   and o.catalog_cd = $PCORD                                                   ; 004 11/27/2015  multi-orders can be selected. This line is OUT.
        and o.catalog_cd in ($PCORD)                                                ; 004 11/27/2015  multi-orders can be selected. This line is IN.
        and o.order_status_cd != 2545.00    ; Discontinued                          ; 006 08/08/2016  added on 08/12/2016
        and o.template_order_id = 0.0 ;only include Parent orders
        and ($REP_TYPE = "EUS" or
             exists (select sub.order_id
                     from order_detail sub
                     where sub.order_id = o.order_id and
                           sub.oe_field_meaning_id = 9000.00  and       ; 9000 is OTHER
                           sub.oe_field_display_value = "Intermediate Care"
                     with nocounter)
                     )

      Join E
;       where e.encntr_id = o.encntr_id                                             ; 021 02/09/2021 Replaced
        where e.encntr_id = o.originating_encntr_id                                 ; 021 02/09/2021 Replacement
          and (0.00 in ($FACILITY) or               ; All/Any = 0.00                ; 004 11/27/2015  New
               e.loc_facility_cd in ($FACILITY))                                    ; 004 11/27/2015  New

      Join EA
        where ea.encntr_id = e.encntr_id
        and ea.encntr_alias_type_cd = 1077.00
        and ea.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and ea.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

      Join eam                                                                  ; 005 New join for emailing to GUH
        where eam.encntr_id = e.encntr_id
        and eam.encntr_alias_type_cd = 1079.00
        and eam.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and eam.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

      join oa                                                                   ; 003 11/12/2015  New table
        where oa.order_id = outerjoin(o.order_id) and
              oa.action_type_cd = outerjoin(2534.00)  ; Order

      join pr
        where pr.person_id = outerjoin(oa.action_personnel_id)                  ; 005 06/16/2016   Replaced. See below.

      join epr_a                                                                    ; 004 11/27/2015  New join
          where epr_a.encntr_id = outerjoin(e.encntr_id)
            and epr_a.encntr_prsnl_r_cd = outerjoin(attend_doc_cd)
            and epr_a.active_ind = outerjoin(1)
            and epr_a.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate, curtime3))

    ;029
        join pc
            where pc.pathway_catalog_id = outerjoin(o.pathway_catalog_id)

      join pr_a                                                                 ; 004 11/27/2015  New join
    ;   where pr_a.person_id = outerjoin(epr_a.prsnl_person_id)
        where pr_a.person_id =           epr_a.prsnl_person_id and
             (;$REP_TYPE != "EUS" or
              pr_a.name_full_formatted = "Michael*Molineux*"  or
              pr_a.name_full_formatted = "Kacie*Saulters*"  or
              pr_a.name_full_formatted = "Jacob*Feldman*"  or
              pr_a.name_full_formatted = "Christine*Salamanca*"  or             ; marked
              pr_a.name_full_formatted = "Ernest*Fischer*" or
              pr_a.name_full_formatted = "Alex*Montero*" or
              pr_a.name_full_formatted = "James*Malatack*" or
              pr_a.name_full_formatted = "Virginia*Malatack*" or
              pr_a.name_full_formatted = "Millicent*Yee*" or
              pr_a.name_full_formatted = "Bi*A*Awosika**" or                    ; marked
              pr_a.name_full_formatted = "Marisa*Perrotti*" or
              pr_a.name_full_formatted = "Omar*Aly*" or
              pr_a.name_full_formatted = "Marilena*Lekoudis*" or
              pr_a.name_full_formatted = "Amarin*Sangkharat*" or
              pr_a.name_full_formatted = "Sarah*C*Thornton*" or
              pr_a.name_full_formatted = "Andrea*P*Rutherfurd*" or
              pr_a.name_full_formatted = "Kyung*S*Kim*" or
              pr_a.name_full_formatted = "Lauren*E*Lubrano*" or
              pr_a.name_full_formatted = "Rusty*Phillips*" or
              pr_a.name_full_formatted = "Bassem*Khalil*" or                    ; marked
              pr_a.name_full_formatted = "Julia*Borniva*" or                    ; marked
              pr_a.name_full_formatted = "Sandeep*A*Konka*" or
              pr_a.name_full_formatted = "Tarek*Alansari*" or                   ; marked
              pr_a.name_full_formatted = "Benjamin*Lorenz*" or                  ; marked
              pr_a.name_full_formatted = "Elad*Sharon*" or                      ; marked
              pr_a.name_full_formatted = "James*Xu*" or                         ; marked
              pr_a.name_full_formatted = "Laleh*Amiri*Kordestani*" or           ; marked
              pr_a.name_full_formatted = "Paul*G*Kluetz*" or                    ; marked
              pr_a.name_full_formatted = "Stephen*Fox*"  or                     ; 006 08/08/2016  on 08/12/2016
              pr_a.name_full_formatted = "Stephanie*Cardella*" or               ; 006 08/08/2016  on 08/12/2016

            ; Looking for ordering physician now.

              pr.name_full_formatted = "Michael*Molineux*"  or
              pr.name_full_formatted = "Kacie*Saulters*"  or
              pr.name_full_formatted = "Jacob*Feldman*"  or
              pr.name_full_formatted = "Christine*Salamanca*"  or               ; marked
              pr.name_full_formatted = "Ernest*Fischer*" or
              pr.name_full_formatted = "Alex*Montero*" or
              pr.name_full_formatted = "James*Malatack*" or
              pr.name_full_formatted = "Virginia*Malatack*"  or
              pr.name_full_formatted = "Millicent*Yee*"  or
              pr.name_full_formatted = "Bi*A*Awosika**" or                      ; marked
              pr.name_full_formatted = "Marisa*Perrotti*" or
              pr.name_full_formatted = "Omar*Aly*" or
              pr.name_full_formatted = "Marilena*Lekoudis*"  or
              pr.name_full_formatted = "Amarin*Sangkharat*" or
              pr.name_full_formatted = "Sarah*C*Thornton*" or
              pr.name_full_formatted = "Andrea*P*Rutherfurd*" or
              pr.name_full_formatted = "Kyung*S*Kim*" or
              pr.name_full_formatted = "Lauren*E*Lubrano*" or
              pr.name_full_formatted = "Rusty*Phillips*" or
              pr.name_full_formatted = "Bassem*Khalil*" or                      ; marked
              pr.name_full_formatted = "Julia*Borniva*" or                      ; marked
              pr.name_full_formatted = "Sandeep*A*Konka*" or
              pr.name_full_formatted = "Tarek*Alansari*" or                     ; marked
              pr.name_full_formatted = "Benjamin*Lorenz*" or                    ; marked
              pr.name_full_formatted = "Elad*Sharon*" or                        ; marked
              pr.name_full_formatted = "James*Xu*" or                           ; marked
              pr.name_full_formatted = "Laleh*Amiri*Kordestani*" or             ; marked
              pr.name_full_formatted = "Paul*G*Kluetz*" or                      ; marked
              pr.name_full_formatted = "Stephen*Fox*"  or                       ; 006 08/08/2016  on 08/12/2016
              pr.name_full_formatted = "Stephanie*Cardella*" or                 ; 006 08/08/2016  on 08/12/2016
              pr.name_full_formatted = "Helen*Lavelle*" or                      ; 017 04/02/2018
              pr.name_full_formatted = "Stacy*Kruse*" or                        ; 017 04/02/2018
              pr.name_full_formatted = "Nili*Sommovilla*" or                    ; 017 04/02/2018
              pr.name_full_formatted = "Kathleen*Abalos*"                       ; 017 04/02/2018
              )


    ;order by                                                                   ; 004 11/27/2015  new "order by". See new one below.
    ;     Facility
    ;   , order_date_time

      order by                                                                  ; 004 11/27/2015  new "order by". This is it.
          o_catalog_disp
        , Facility
        , order_date_time

      with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress
          ;030, orahintcbo ("index(oa xpkorder_action)","index(o xie17orders)" )

;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -
; 007 10/26/2016   New email being sent out from this program/script (Order Volume Report for Hospitalist Imaging In orders)
;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -

ElseIf ($rep_type in ("EHOSPIN") and        ; 007 10/26/2016  MGUH Hospitalist Imaging In
        CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.


    record ords (
        01 cnt = i2
        01 qual [*]
           02 description = vc
           02 display = vc
           02 catalog_cd = f8
           02 active_ind = i2
    )

    set cnt = 0
    set idx = 0

    select into 'nl:'
    from code_value cv
    where cv.code_set = 200 and
        (cv.display_key = "CTABDOM*" or
         cv.display_key = "CTCHEST*" or
         cv.code_value in
                (101814921.00,  ;   CT Chest PE
                 101814682.00,  ;   CT Chest w Contrast
                 101814795.00,  ;   CT Chest wo Contrast
                 101814871.00,  ;   CT Chest wo w Contrast
                 101806712.00,  ;   Echocardiogram Complete
                 101806210.00,  ;   Echocardiogram Complete With Bubble Stud
                 101806282.00,  ;   Echocardiogram Limited Follow Up
                   2908764.00,  ;   US Abdomen Complete
                 101813260.00,  ;   US Abdomen Doppler Complete
                 101813230.00,  ;   US Abdomen Doppler Limited
                   2908767.00,  ;   US Abdomen Limited
                 101815524.00,  ;   US Lower Ext Duplex Veins Bilateral
                 101814524.00,  ;   US Lower Ext Duplex Veins Left
                 101814634.00,  ;   US Lower Ext Duplex Veins Right
                 102283474.00,  ;   US Retroperitoneal Complete
                 102283520.00,  ;   US Retroperitoneal Limited
                 101814814.00)  ;   US Spleen
        )
    order by description
    Detail
        cnt = cnt + 1
        stat = alterlist(ords->qual, cnt)
        ords->qual[cnt].description = cv.description
        ords->qual[cnt].display = cv.display
        ords->qual[cnt].catalog_cd = cv.code_value
        ords->qual[cnt].active_ind = cv.active_ind
    with format, separator = " "

;;;;    select into $outdev
;;;;        description = trim(substring(1,120,ords->qual[d.seq].description)),
;;;;        display = trim(substring(1,120,ords->qual[d.seq].display)),
;;;;        catalog_cd = ords->qual[d.seq].catalog_cd,
;;;;        active_ind = ords->qual[d.seq].active_ind
;;;;    from (dummyt d with seq = size(ords->qual,5))
;;;;    with format, separator = " "


      Select into value(FILENAME)

          o_catalog_disp = (If (o.ordered_as_mnemonic = "US Renal*")
                                build2(trim(substring(1,200,uar_get_code_description(o.catalog_cd))), " (",
                                       trim(substring(1,100,o.ordered_as_mnemonic)),")")
                            Else
                                trim(substring(1,200,uar_get_code_description(o.catalog_cd)))
                            Endif)
        , ordered_as_mnemonic = trim(substring(1,200,o.ordered_as_mnemonic))
        , Order_Date_Time = o.orig_order_dt_tm "@SHORTDATETIME"
        , MRN = cnvtalias(eam.alias,eam.alias_pool_cd)
        , FIN = cnvtalias(ea.alias,ea.alias_pool_cd)
;;;;    , discharge_dt_tm = e.disch_dt_tm "@SHORTDATETIME"          ; Only non-discharged patients are included.
        , Facility = uar_get_code_display(e.loc_facility_cd)
        , Location = build2 (trim(substring(1,50, uar_get_code_display(e.loc_nurse_unit_cd))), "; ",
                             trim(substring(1,50, uar_get_code_display(e.loc_room_cd))))
;       , Order_Details = o.order_detail_display_line                               ; 023 07/16/2021 Replaced. See below.
          ; 023 07/16/2021 Below, we are replacing Rarriage Returns with NULL and Line Feeds with a space.
        , Order_Details = trim(substring(1, 800, replace(replace(o.order_detail_display_line,char(13), " "), char(10), "")))
        , order_status = uar_get_code_display(o.order_status_cd);002
        , ordered_by = trim(substring(1,130, pr.name_full_formatted))               ; 003 11/12/2015  New
        , attending = (If (pr_a.name_last_key =  "UNASSIGNED" and                       ; 004 11/27/2015  New field
                          pr_a.name_first_key = "UNASSIGNED")
                           ""
                       Else
                           pr_a.name_full_formatted
                       endif)
            ;029
            , OrderSet = trim(pc.description)
      FROM
          orders   o
        , ENCOUNTER   E
        , encntr_alias   EA
        , encntr_alias   eam
        , order_action oa
        , prsnl pr
        , encntr_prsnl_reltn epr_a
        , prsnl pr_a
        , pathway_catalog pc

      Plan O
        where o.orig_order_dt_tm between cnvtdatetime($BEGDT) and cnvtdatetime($ENDDT)
;       and o.catalog_cd in ($PCORD)
        and expand(idx,1,size(ords->qual,5), o.catalog_cd, ords->qual[idx].catalog_cd)

;       and (    o.catalog_cd != 102283520.00 or    ; US Retroperitoneal Limited
;               (o.catalog_cd  = 102283520.00 and o.ordered_as_mnemonic = "US Renal Limited")
;           )
;       and (    o.catalog_cd != 102283474.00 or    ; US Retroperitoneal Complete
;               (o.catalog_cd  = 102283474.00 and o.ordered_as_mnemonic = "US Renal Complete")
;           )

;       and o.order_status_cd != 2545.00        ; Discontinued                  ; 007 10/26/2016  greened out
        and o.order_status_cd not in ( 2545.00, ; Discontinued                  ; 007 10/26/2016  New... cancelled has been added
                                       2542.00) ; Canceled
        and o.template_order_id = 0.0 ;only include Parent orders
      Join E
;       where e.encntr_id = o.encntr_id                                             ; 021 02/09/2021 Replaced
        where e.encntr_id = o.originating_encntr_id                                 ; 021 02/09/2021 Replacement
          and (0.00 in ($FACILITY) or               ; All/Any = 0.00
               e.loc_facility_cd in ($FACILITY))
          and e.disch_dt_tm = NULL                  ; This (inhouse patients only) is only for this email, not the others

      Join EA
        where ea.encntr_id = e.encntr_id
        and ea.encntr_alias_type_cd = 1077.00
        and ea.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and ea.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

      Join eam
        where eam.encntr_id = e.encntr_id
        and eam.encntr_alias_type_cd = 1079.00
        and eam.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and eam.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

      join oa
        where oa.order_id = outerjoin(o.order_id) and
              oa.action_type_cd = outerjoin(2534.00)  ; Order

      join pr
        where pr.person_id = outerjoin(oa.action_personnel_id)

      join epr_a
          where epr_a.encntr_id = outerjoin(e.encntr_id)
            and epr_a.encntr_prsnl_r_cd = outerjoin(attend_doc_cd)
            and epr_a.active_ind = outerjoin(1)
            and epr_a.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate, curtime3))

    ;029
        join pc
            where pc.pathway_catalog_id = outerjoin(o.pathway_catalog_id)

      join pr_a
    ;   where pr_a.person_id = outerjoin(epr_a.prsnl_person_id)
        where pr_a.person_id =           epr_a.prsnl_person_id and

             (pr_a.name_full_formatted = "Michael*Molineux*"  or
              pr_a.name_full_formatted = "Kacie*Saulters*"  or
              pr_a.name_full_formatted = "Jacob*Feldman*"  or
              pr_a.name_full_formatted = "Christine*Salamanca*"  or             ; marked
              pr_a.name_full_formatted = "Ernest*Fischer*" or
              pr_a.name_full_formatted = "Alex*Montero*" or
              pr_a.name_full_formatted = "James*Malatack*" or
              pr_a.name_full_formatted = "Virginia*Malatack*" or
              pr_a.name_full_formatted = "Millicent*Yee*" or
              pr_a.name_full_formatted = "Bi*A*Awosika**" or                    ; marked
              pr_a.name_full_formatted = "Marisa*Perrotti*" or
              pr_a.name_full_formatted = "Omar*Aly*" or
              pr_a.name_full_formatted = "Marilena*Lekoudis*" or
              pr_a.name_full_formatted = "Amarin*Sangkharat*" or
              pr_a.name_full_formatted = "Sarah*C*Thornton*" or
              pr_a.name_full_formatted = "Andrea*P*Rutherfurd*" or
              pr_a.name_full_formatted = "Kyung*S*Kim*" or
              pr_a.name_full_formatted = "Lauren*E*Lubrano*" or
              pr_a.name_full_formatted = "Rusty*Phillips*" or
              pr_a.name_full_formatted = "Bassem*Khalil*" or                    ; marked
              pr_a.name_full_formatted = "Julia*Borniva*" or                    ; marked
              pr_a.name_full_formatted = "Sandeep*A*Konka*" or
              pr_a.name_full_formatted = "Tarek*Alansari*" or                   ; marked
              pr_a.name_full_formatted = "Benjamin*Lorenz*" or                  ; marked
              pr_a.name_full_formatted = "Elad*Sharon*" or                      ; marked
              pr_a.name_full_formatted = "James*Xu*" or                         ; marked
              pr_a.name_full_formatted = "Laleh*Amiri*Kordestani*" or           ; marked
              pr_a.name_full_formatted = "Paul*G*Kluetz*" or                    ; marked
              pr_a.name_full_formatted = "Stephen*Fox*"  or                     ; 006 08/08/2016  on 08/12/2016
              pr_a.name_full_formatted = "Stephanie*Cardella*" or               ; 006 08/08/2016  on 08/12/2016

            ; Looking for ordering physician now.

              pr.name_full_formatted = "Michael*Molineux*"  or
              pr.name_full_formatted = "Kacie*Saulters*"  or
              pr.name_full_formatted = "Jacob*Feldman*"  or
              pr.name_full_formatted = "Christine*Salamanca*"  or               ; marked
              pr.name_full_formatted = "Ernest*Fischer*" or
              pr.name_full_formatted = "Alex*Montero*" or
              pr.name_full_formatted = "James*Malatack*" or
              pr.name_full_formatted = "Virginia*Malatack*"  or
              pr.name_full_formatted = "Millicent*Yee*"  or
              pr.name_full_formatted = "Bi*A*Awosika**" or                      ; marked
              pr.name_full_formatted = "Marisa*Perrotti*" or
              pr.name_full_formatted = "Omar*Aly*" or
              pr.name_full_formatted = "Marilena*Lekoudis*"  or
              pr.name_full_formatted = "Amarin*Sangkharat*" or
              pr.name_full_formatted = "Sarah*C*Thornton*" or
              pr.name_full_formatted = "Andrea*P*Rutherfurd*" or
              pr.name_full_formatted = "Kyung*S*Kim*" or
              pr.name_full_formatted = "Lauren*E*Lubrano*" or
              pr.name_full_formatted = "Rusty*Phillips*" or
              pr.name_full_formatted = "Bassem*Khalil*" or                      ; marked
              pr.name_full_formatted = "Julia*Borniva*" or                      ; marked
              pr.name_full_formatted = "Sandeep*A*Konka*" or
              pr.name_full_formatted = "Tarek*Alansari*" or                     ; marked
              pr.name_full_formatted = "Benjamin*Lorenz*" or                    ; marked
              pr.name_full_formatted = "Elad*Sharon*" or                        ; marked
              pr.name_full_formatted = "James*Xu*" or                           ; marked
              pr.name_full_formatted = "Laleh*Amiri*Kordestani*" or             ; marked
              pr.name_full_formatted = "Paul*G*Kluetz*" or                      ; marked
              pr.name_full_formatted = "Stephen*Fox*"  or                       ; 006 08/08/2016  on 08/12/2016
              pr.name_full_formatted = "Stephanie*Cardella*"                    ; 006 08/08/2016  on 08/12/2016
    )

    ;order by                                                                   ; 004 11/27/2015  new "order by". See new one below.
    ;     Facility
    ;   , order_date_time

      order by                                                                  ; 004 11/27/2015  new "order by". This is it.
          o_catalog_disp
        , Facility
        , order_date_time

      with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress
         ;030 ,  orahintcbo ("index(oa xpkorder_action)","index(o xie17orders)" )


;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -
; 009 12/29/2016   New email being sent out from this program/script (Order Volume Report for Hospitalist Orders)
;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -

ElseIf ($rep_type in ("EHOSPORD") and       ; 009 12/29/2016  MGUH Hospitalist Orders
        CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

      Select into value(FILENAME)

          o_catalog_disp =  trim(substring(1,200,uar_get_code_description(o.catalog_cd)))
        , ordered_as_mnemonic = trim(substring(1,200,o.ordered_as_mnemonic))
        , Order_Date_Time = o.orig_order_dt_tm "@SHORTDATETIME"
        , MRN = cnvtalias(eam.alias,eam.alias_pool_cd)
        , FIN = cnvtalias(ea.alias,ea.alias_pool_cd)
;;;;    , discharge_dt_tm = e.disch_dt_tm "@SHORTDATETIME"          ; Only non-discharged patients are included.
        , Facility = uar_get_code_display(e.loc_facility_cd)
        , Location = build2 (trim(substring(1,50, uar_get_code_display(e.loc_nurse_unit_cd))), "; ",
                             trim(substring(1,50, uar_get_code_display(e.loc_room_cd))))
;       , Order_Details = o.order_detail_display_line                               ; 023 07/16/2021 Replaced. See below.
          ; 023 07/16/2021 Below, we are replacing Rarriage Returns with NULL and Line Feeds with a space.
        , Order_Details = trim(substring(1, 800, replace(replace(o.order_detail_display_line,char(13), " "), char(10), "")))
        , order_status = uar_get_code_display(o.order_status_cd);002
        , ordered_by = trim(substring(1,130, pr.name_full_formatted))               ; 003 11/12/2015  New
        , attending = (If (pr_a.name_last_key =  "UNASSIGNED" and                   ; 004 11/27/2015  New field
                          pr_a.name_first_key = "UNASSIGNED")
                           ""
                       Else
                           pr_a.name_full_formatted
                       endif)
            ;029
            , OrderSet = trim(pc.description)
      FROM
          orders   o
        , ENCOUNTER   E
        , encntr_alias   EA
        , encntr_alias   eam
        , order_action oa
        , prsnl pr
        , encntr_prsnl_reltn epr_a
        , prsnl pr_a
        , pathway_catalog pc

      Plan O
        where o.orig_order_dt_tm between cnvtdatetime($BEGDT) and cnvtdatetime($ENDDT) and
;       and expand(idx,1,size(ords->qual,5), o.catalog_cd, ords->qual[idx].catalog_cd)
        o.ordered_as_mnemonic in ("Ascitic Fluid Cell Count w/Diff",
                                  "Body Fluid Cell Count w/ Diff, Miscellaneous",
                                  "CSF Cell Count w/ Diff",
                                  "Chest 1 View Portable",
                                  "Fluid CSF Cell Count w/ Diff",
                                  "Peritoneal Fluid Cell Count w/ Diff",
                                  "Pleural Fluid Cell Count w/  Dif")
        and weekday (o.orig_order_dt_tm) in (1,2,3,4,5)   ; Just orders for Mon - Fri  Note: weekday = 0 on Sunday
        and o.order_status_cd not in ( 2545.00, ; Discontinued                  ; 007 10/26/2016  New... cancelled has been added
                                       2542.00) ; Canceled
        and
            (o.catalog_cd !=   101947993.00  or      ; Not = 'Chest 1 View Portable'  ---OR---
             exists (select od.order_id              ; For 'Chest 1 View Portable',  Only inlcude orders with a reason of
                     from order_detail od            ;                      '"S/P Intubation/Line Placement"'
                     where od.order_id = o.order_id and
                           od.oe_field_display_value ="S/P Intubation/Line Placement"
                     with nocounter)
           )
           and o.template_order_id = 0.0 ;only include Parent orders
      Join E
;       where e.encntr_id = o.encntr_id                                             ; 021 02/09/2021 Replaced
        where e.encntr_id = o.originating_encntr_id                                 ; 021 02/09/2021 Replacement
          and (0.00 in ($FACILITY) or               ; All/Any = 0.00
               e.loc_facility_cd in ($FACILITY))
;         and e.disch_dt_tm = NULL                  ; This (inhouse patients only) is only for this email, not the others

      Join EA
        where ea.encntr_id = e.encntr_id
        and ea.encntr_alias_type_cd = 1077.00
        and ea.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and ea.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

      Join eam
        where eam.encntr_id = e.encntr_id
        and eam.encntr_alias_type_cd = 1079.00
        and eam.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and eam.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

      join oa
        where oa.order_id = outerjoin(o.order_id) and
              oa.action_type_cd = outerjoin(2534.00)  ; Order

      join pr
        where pr.person_id = outerjoin(oa.action_personnel_id)

      join epr_a
          where epr_a.encntr_id = outerjoin(e.encntr_id)
            and epr_a.encntr_prsnl_r_cd = outerjoin(attend_doc_cd)
            and epr_a.active_ind = outerjoin(1)
            and epr_a.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate, curtime3))

    ;029
        join pc
        where pc.pathway_catalog_id = outerjoin(o.pathway_catalog_id)

      join pr_a
    ;   where pr_a.person_id = outerjoin(epr_a.prsnl_person_id)
        where pr_a.person_id =           epr_a.prsnl_person_id and

             (pr_a.name_full_formatted = "Michael*Molineux*"  or
              pr_a.name_full_formatted = "Kacie*Saulters*"  or
              pr_a.name_full_formatted = "Jacob*Feldman*"  or
              pr_a.name_full_formatted = "Christine*Salamanca*"  or             ; marked
              pr_a.name_full_formatted = "Ernest*Fischer*" or
              pr_a.name_full_formatted = "Alex*Montero*" or
              pr_a.name_full_formatted = "James*Malatack*" or
              pr_a.name_full_formatted = "Virginia*Malatack*" or
              pr_a.name_full_formatted = "Millicent*Yee*" or
              pr_a.name_full_formatted = "Bi*A*Awosika**" or                    ; marked
              pr_a.name_full_formatted = "Marisa*Perrotti*" or
              pr_a.name_full_formatted = "Omar*Aly*" or
              pr_a.name_full_formatted = "Marilena*Lekoudis*" or
              pr_a.name_full_formatted = "Amarin*Sangkharat*" or
              pr_a.name_full_formatted = "Sarah*C*Thornton*" or
              pr_a.name_full_formatted = "Andrea*P*Rutherfurd*" or
              pr_a.name_full_formatted = "Kyung*S*Kim*" or
              pr_a.name_full_formatted = "Lauren*E*Lubrano*" or
              pr_a.name_full_formatted = "Rusty*Phillips*" or
              pr_a.name_full_formatted = "Bassem*Khalil*" or                    ; marked
              pr_a.name_full_formatted = "Julia*Borniva*" or                    ; marked
              pr_a.name_full_formatted = "Sandeep*A*Konka*" or
              pr_a.name_full_formatted = "Tarek*Alansari*" or                   ; marked
              pr_a.name_full_formatted = "Benjamin*Lorenz*" or                  ; marked
              pr_a.name_full_formatted = "Elad*Sharon*" or                      ; marked
              pr_a.name_full_formatted = "James*Xu*" or                         ; marked
              pr_a.name_full_formatted = "Laleh*Amiri*Kordestani*" or           ; marked
              pr_a.name_full_formatted = "Paul*G*Kluetz*" or                    ; marked
              pr_a.name_full_formatted = "Stephen*Fox*"  or                     ; 006 08/08/2016  on 08/12/2016
              pr_a.name_full_formatted = "Stephanie*Cardella*" or               ; 006 08/08/2016  on 08/12/2016

            ; Looking for ordering physician now.

              pr.name_full_formatted = "Michael*Molineux*"  or
              pr.name_full_formatted = "Kacie*Saulters*"  or
              pr.name_full_formatted = "Jacob*Feldman*"  or
              pr.name_full_formatted = "Christine*Salamanca*"  or               ; marked
              pr.name_full_formatted = "Ernest*Fischer*" or
              pr.name_full_formatted = "Alex*Montero*" or
              pr.name_full_formatted = "James*Malatack*" or
              pr.name_full_formatted = "Virginia*Malatack*"  or
              pr.name_full_formatted = "Millicent*Yee*"  or
              pr.name_full_formatted = "Bi*A*Awosika**" or                      ; marked
              pr.name_full_formatted = "Marisa*Perrotti*" or
              pr.name_full_formatted = "Omar*Aly*" or
              pr.name_full_formatted = "Marilena*Lekoudis*"  or
              pr.name_full_formatted = "Amarin*Sangkharat*" or
              pr.name_full_formatted = "Sarah*C*Thornton*" or
              pr.name_full_formatted = "Andrea*P*Rutherfurd*" or
              pr.name_full_formatted = "Kyung*S*Kim*" or
              pr.name_full_formatted = "Lauren*E*Lubrano*" or
              pr.name_full_formatted = "Rusty*Phillips*" or
              pr.name_full_formatted = "Bassem*Khalil*" or                      ; marked
              pr.name_full_formatted = "Julia*Borniva*" or                      ; marked
              pr.name_full_formatted = "Sandeep*A*Konka*" or
              pr.name_full_formatted = "Tarek*Alansari*" or                     ; marked
              pr.name_full_formatted = "Benjamin*Lorenz*" or                    ; marked
              pr.name_full_formatted = "Elad*Sharon*" or                        ; marked
              pr.name_full_formatted = "James*Xu*" or                           ; marked
              pr.name_full_formatted = "Laleh*Amiri*Kordestani*" or             ; marked
              pr.name_full_formatted = "Paul*G*Kluetz*" or                      ; marked
              pr.name_full_formatted = "Stephen*Fox*"  or                       ; 006 08/08/2016  on 08/12/2016
              pr.name_full_formatted = "Stephanie*Cardella*" or                 ; 006 08/08/2016  on 08/12/2016
              pr.name_full_formatted = "Helen*Lavelle*" or                      ; 015 03/29/2018
              pr.name_full_formatted = "Stacy*Kruse*" or                        ; 015 03/29/2018
              pr.name_full_formatted = "Nili*Sommovilla*" or                    ; 015 03/29/2018
              pr.name_full_formatted = "Kathleen*Abalos*"                       ; 015 03/29/2018

    )

    ;order by                                                                   ; 004 11/27/2015  new "order by". See new one below.
    ;     Facility
    ;   , order_date_time

      order by                                                                  ; 004 11/27/2015  new "order by". This is it.
          o_catalog_disp
        , Facility
        , order_date_time

      with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress
          ;030 , orahintcbo ("index(oa xpkorder_action)","index(o xie17orders)" )

;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -
; 011 01/24/2017    New email being sent out from this program/script (Order Volume Report for
;                   'Prepare for OR/Anesthesia Red Blood Cells' orders)
;     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -

ElseIf ($rep_type in ("ERBC") and          ; 011 01/24/2017  'Prepare for OR/Anesthesia Red Blood Cells' orders ... aka RBC orders
        CURDOMAIN = PRODUCTION_DOMAIN)      ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

      SELECT into value(FILENAME)

          o_catalog_disp =  trim(substring(1,200,uar_get_code_description(o.catalog_cd)))
        , ordered_as_mnemonic = trim(substring(1,200,o.ordered_as_mnemonic))
        , Order_Date_Time = o.orig_order_dt_tm "@SHORTDATETIME"
        , MRN = cnvtalias(eam.alias,eam.alias_pool_cd)
        , FIN = cnvtalias(ea.alias,ea.alias_pool_cd)
        , Facility = uar_get_code_display(e.loc_facility_cd)
        , ordering_Location = build2 (trim(substring(1,50, uar_get_code_display(elh.loc_nurse_unit_cd))), "; ",
                             trim(substring(1,50, uar_get_code_display(elh.loc_room_cd))))
;       , Order_Details = o.order_detail_display_line
        , order_status = uar_get_code_display(o.order_status_cd)
        , ordered_by = trim(substring(1,130, pr.name_full_formatted))
        , attending = (If (pr_a.name_last_key =  "UNASSIGNED" and
                          pr_a.name_first_key = "UNASSIGNED")
                           ""
                       Else
                           pr_a.name_full_formatted
                       endif)
        ;029
        , OrderSet = trim(pc.description)

      FROM
          orders   o
        , ENCOUNTER   E
        , encntr_loc_hist elh
        , encntr_alias   EA
        , encntr_alias   eam
        , order_action oa
        , prsnl pr
        , encntr_prsnl_reltn epr_a
        , prsnl pr_a
        , pathway_catalog pc

      Plan O
        where O.CATALOG_CD =   472563438.00 and   ; Prepare for OR/Anesthesia Red Blood Cell
              o.orig_order_dt_tm between cnvtdatetime($BEGDT) and cnvtdatetime($ENDDT) and
              o.order_status_cd not in ( 2545.00,   ; Discontinued                  ; 007 10/26/2016  New... cancelled has been added;
                                         2542.00)   ; Canceled
               and o.template_order_id = 0.0 ;only include Parent orders
      Join E
;       where e.encntr_id = o.encntr_id                                             ; 021 02/09/2021 Replaced
        where e.encntr_id = o.originating_encntr_id                                 ; 021 02/09/2021 Replacement
          and (0.00 in ($FACILITY) or               ; All/Any = 0.00
               e.loc_facility_cd in ($FACILITY))


    Join ELH            ; associated with the entering unit
        where
;           elh.encntr_id = o.encntr_id and                                         ; 021 02/09/2021 Replaced
            elh.encntr_id = e.encntr_id and                                         ; 021 02/09/2021 Replacement
           (elh.end_effective_dt_tm != cnvtdatetime("31-DEC-2100 00:00:00") or
            elh.active_ind = 1) and
            elh.transaction_dt_tm  = (select max(sub.transaction_dt_tm)
                                     from ENCNTR_LOC_HIST sub
                                     where sub.encntr_id = elh.encntr_id and
                                           sub.transaction_dt_tm < o.orig_order_dt_tm and
                                          (sub.end_effective_dt_tm != cnvtdatetime("31-DEC-2100 00:00:00") or
                                           sub.active_ind = 1) and
                                           sub.TRANSACTION_DT_TM between
                                                            cnvtlookbehind("70,D",cnvtdatetime($BEGDT))  and
                                                            cnvtlookahead("51,D",cnvtdatetime($ENDDT))
                                           and
                                           sub.encntr_type_cd not in (           309313.00, ; Preadmit
                                                                              607971507.00)   ; INPATIENTREFERRAL_CD

                                     with nocounter);030,  orahintcbo ("index (sub xie1encntr_loc_hist)")
            and elh.transaction_dt_tm <= cnvtdatetime($ENDDT)

      Join EA
        where ea.encntr_id = e.encntr_id
        and ea.encntr_alias_type_cd = 1077.00
        and ea.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and ea.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

      Join eam
        where eam.encntr_id = e.encntr_id
        and eam.encntr_alias_type_cd = 1079.00
        and eam.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
        and eam.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)

      join oa
        where oa.order_id = outerjoin(o.order_id) and
              oa.action_type_cd = outerjoin(2534.00)  ; Order

      join pr
        where pr.person_id = outerjoin(oa.action_personnel_id)

      join epr_a
          where epr_a.encntr_id = outerjoin(e.encntr_id)
            and epr_a.encntr_prsnl_r_cd = outerjoin(1119.00) ; attend_doc_cd)
            and epr_a.active_ind = outerjoin(1)
            and epr_a.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate, curtime3))

      join pr_a
        where pr_a.person_id = outerjoin(epr_a.prsnl_person_id)

    ;029
     join pc
     where pc.pathway_catalog_id = outerjoin(o.pathway_catalog_id)

      order by
          o_catalog_disp
        , Facility
        , o.orig_order_dt_tm

      with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress ,
           orahintcbo ("index(oa xpkorder_action)","index(o xie1orders)" )

Endif

/***************************************************************************
;       No qualifying orders per parameters
***************************************************************************/

    if (CURQUAL = 0 and $rep_type = "S")

      select into value($OUTDEV)
      from (dummyt d)
      head page
        "{ps/792 0 translate 90 rotate/}" ;landscape program
        row + 1
      detail
          col 0 "Order Volume Report"
          row + 2
          col 0 "There are no orders that match your requested parameters."
          row + 2
          col 0 "Facility(s):"                          ; 004 11/27/2015  Facility and Order Cat mentions are all new.
          col 16 facility_var
          row + 2
          col 0 "Catalog items:"
          col 16 ORDER_CAT_DISP
          row + 2
          col 0 "Between:"
          col 10 $BEGDT
          col 31 "--and--"
          col 39 $ENDDT
          row + 2
      with nocounter, dio = postscript, landscape, maxcol = 250                 ; 012 04/03/2017   maxcol = 250 is new

      go to end_of_program

     elseif (CURQUAL = 0 and $rep_type in ( "EUS", "EADM",
                                            "EHOSPIN",              ; 006 08/08/2016  Replacement.  Added in EHOSPIN
                                            "EHOSPORD",             ; 009 12/30/2016  Replacement.  Added in EHOSPORD
                                            "ERBC",                 ; 011 01/24/2017  Replacement.  Added in ERBC
                                            "ENEURO",               ; 020 08/18/2020  ENEURO is new
                                            "EMATMAN",              ; 025 07/19/2022  EMATMAN for WHCs Material Managemnet orders report is new
                                            "EMONKEYPOX",           ; 026 08/29/2022  EMONKEYPOX for HHCs Orthopoxvirus(Monkeypox) by PCR orders report is new
                                            "ESLP"))                ; 027 11/18/2022  ESLP for GUH SLP orders report is new
      Select into value(filename)
      from (dummyt d)
      detail
;         col 0 "Order Volume Report for US Lower Extremity Duplex Vein orders"         ; 006 08/08/2016  greened out today
          col 0 If ($REP_TYPE = "EUS")                                                  ; 006 08/08/2016  New today
                    "Order Volume Report for US Lower Extremity Duplex Vein orders"
                ElseIf ($REP_TYPE = "EADM")
                    "Order Volume Report for Admit to Inpatient MGUH orders"
                ElseIf ($REP_TYPE = "EHOSPIN")                                          ; 007 10/24/2016  New today
                    "Order Volume Report for Hospitalist Imaging In orders"
                ElseIf ($REP_TYPE = "EHOSPORD")                                         ; 009 12/30/2016  New today
                    "Order Volume Report for Hospitalist orders"
                ElseIf ($REP_TYPE = "ERBC")                                             ; 011 01/24/2017  New today
                    "Order Volume Report for Prepare for OR Anesthesia Red Blood Cells orders"
                ElseIf ($REP_TYPE = "ENEURO")                                           ; 020 08/18/2020  ENEURO is new
                    "Order Volume Report for Consult to Neurology and Consult to Neurosurgery orders"
                ElseIf ($REP_TYPE = "EMATMAN")                                          ; 025 07/19/2022  EMATMAN is new
                    "Order Volume Report for Equip TED Pump Daily Usage and SCD Machine orders"
                ElseIf ($REP_TYPE = "EMONKEYPOX")                                       ; 026 08/29/2022  EMONKEYPOX is new
                    "Order Volume Report for Orthopoxvirus(Monkeypox) by PCR orders"
                ElseIf ($REP_TYPE = "ESLP")                                             ; 027 11/18/2022  ESLP is new
                    "Order Volume Report for SLP orders"
                Endif
          row + 2
          col 0 "There are no orders that match your requested parameters."
          row + 2
          col 0 "Facility(s):"
          col 16 facility_var
          row + 2
          col 0 "Between:"
          col 10 $BEGDT
          col 31 "--and--"
          col 39 $ENDDT
          row + 2
      with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter

   ;NOTE: Earlier, EMAIL_SUBJECT was already assigned a value. We are changing it here, because there is no data.
;   set EMAIL_SUBJECT =                                                                                                 ;006 08/08/2016 replaced
;               build2("US Lower Ext Duplex Veins Orders Report - ", $BEGDT, " to ", $ENDDT, " **** NO DATA ****")      ;006 08/08/2016 replaced

     SET EMAIL_SUBJECT = (If ($REP_TYPE = "EUS")                                                                            ;006 08/08/2016 replacement
                            build2("US Lower Ext Duplex Veins Orders Report - ", $BEGDT, " to ", $ENDDT, " **** NO DATA ****")
                        ElseIf ($REP_TYPE = "EADM")
                            build2("Admit to Inpatient MGUH Orders Report - ", $BEGDT, " to ", $ENDDT, " **** NO DATA ****")
                        ElseIf ($REP_TYPE = "EHOSPIN")
                            build2("MGUH Hospitalist Imaging In Orders Report - ", $BEGDT, " to ", $ENDDT, " **** NO DATA ****")
                        ElseIf ($REP_TYPE = "EHOSPORD")                                                                 ; 009 12/20/2016  New
                            build2("MGUH Hospitalist Orders Report - ", $BEGDT, " to ", $ENDDT, " **** NO DATA ****")
                        ElseIf ($REP_TYPE = "ERBC")                                                                 ; 009 12/20/2016  New
                            build2("MGUH Prepare for OR Anesthesia Red Blood Cells  Orders Report - ", $BEGDT, " to ", $ENDDT, " **** NO DATA ****")
                        ElseIf ($REP_TYPE = "ENEURO")                                                                   ; 009 12/20/2016  New
                            build2("MFSMC Consult to Neurology and Consult to Neurosurgery Orders Report - ",           ; 020 08/18/2020 ENEURO is new today
                                                                        $BEGDT, " to ", $ENDDT, " **** NO DATA ****")
                        ElseIf ($REP_TYPE = "EMATMAN")                                                                  ; 025 07/19/2022  New
                            build2("MWHC Order Volume Report of Equip TED Pump Daily Usage and SCD Machine orders - ",  ; 025 07/19/2022  EMATMAN is new
                                                                        $BEGDT, " to ", $ENDDT, " **** NO DATA ****")
                        ElseIf ($REP_TYPE = "EMONKEYPOX")                                                               ; 026 08/29/2022  New
                            build2("HHC Orthopoxvirus(Monkeypox) by PCR Order Volume Report - ",                        ; 026 08/29/2022  EMONKEYPOX is new
                                                                        $BEGDT, " to ", $ENDDT, " **** NO DATA ****")
                        ElseIf ($REP_TYPE = "ESLP")                                                                     ; 027 11/18/2022  ESLP is new
                            build2("MGUH SLP Order Volume Report - ",                                                   ; 027 11/18/2022  ESLP is new
                                                                        $BEGDT, " to ", $ENDDT, " **** NO DATA ****")
                        Endif)

   ;NOTE: Earlier, EMAIL_BODY was already created and filled with the email body text. We are adding to it here,
   ;      because there is no data. Running the wrapper straight from DVDev, an error will appear, though theemail and the
   ;      empty report will be generated correctly. In Olympus, all looks to run OK without any error or alert.  Weird, huh?

     Select into (value(EMAIL_BODY))
            build2(char(13), char(10), "*********  NO DATA *********")
     from dummyt
     with format, noheading, Append

    endif

;#PRODUCE_EMAIL

    If  ($REP_TYPE = "E*" and                   ; EUS  will be for emailing of an Ultra Sound order report. Other E's may be coming.
         CURDOMAIN = PRODUCTION_DOMAIN)         ; 006 08/08/2016 EADM will be for emailing of an Admit Orders for GUH order report.
                                                ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 002 01/18/2017 The below AIX_COMMAND replaces the one just below it.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            SET  AIX_COMMAND  =
                    build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
                             " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS)

;           SET  AIX_COMMAND  =
;               build2 ('(cat ', EMAIL_BODY , ';',  "uuencode ",  filename , " " , filename, ')',
;                       ' | mailx -s "', value(email_subject) , '" ' ,EMAIL_ADDRESS , ' -- -f report@medstar.net')
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)

            call pause(2)   ; Let's slow things down before the clean up immediately below.

        ;   clean up.   (Removing EMAIL_BODY from $CCLUSERDIR does work.)

            SET  AIX_COMMAND  =
                CONCAT ('rm -f ' , FILENAME,  ' | rm -f ' , EMAIL_BODY)

            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)

    Endif


/***************************************************************************/

#end_of_program

end
go
