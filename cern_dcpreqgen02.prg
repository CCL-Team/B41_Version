
/*~BB~************************************************************************
      *                                                                      *
      *  Copyright Notice:  (c) 1983 Laboratory Information Systems &        *
      *                              Technology, Inc.                        *
      *       Revision      (c) 1984-1995 Cerner Corporation                 *
      *                                                                      *
      *  Cerner (R) Proprietary Rights Notice:  All rights reserved.         *
      *  This material contains the valuable properties and trade secrets of *
      *  Cerner Corporation of Kansas City, Missouri, United States of       *
      *  America (Cerner), embodying substantial creative efforts and        *
      *  confidential information, ideas and expressions, no part of which   *
      *  may be reproduced or transmitted in any form or by any means, or    *
      *  retained in any storage or retrieval system without the express     *
      *  written permission of Cerner.                                       *
      *                                                                      *
      *  Cerner is a registered mark of Cerner Corporation.                  *
      *                                                                      *
  ~BE~***********************************************************************/
/*****************************************************************************

        Source file name:       CERN_DCPREQGEN02.PRG
        Object name:            dcpreqgen02
        Request #:              N/A

        Product:                PowerChart
        Product Team:           Order Management
        HNA Version:            500
        CCL Version:

        Program purpose:

        Tables read:

        Tables updated:

        Executing from:

        Special Notes:

******************************************************************************/
;~DB~************************************************************************
;    *                      GENERATED MODIFICATION CONTROL LOG              *
;    ************************************************************************
;    *                                                                      *
;    *Mod Date     Engineer             Comment                             *
;    *--- -------- -------------------- ----------------------------------- *
;    *002 09/08/00 SB3282               Fix field printing twice            *
;    *004 05/01/05 LP010060             Fix multiple order details defects  *
;    *005 05/26/05 RM010964             Fix printing age, height and weight *
;    *006 04/10/06 AT012526             Order details with multiple lines   *
;                                       print correctly (CR 1-365117141)    *
;                                       Reduced unnecessary calls to script *
;                                       dcp_parse_text.                     *
;                                       Allow for page breaks               *
;    *007 12/13/06 KS012546             CR 1-853090761 - Orders requiring   *
;                                       dr. cosign are not printing a       *
;                                       requisition.                        *
;    *008 11/14/07 NV013841             More than two lines of allergies    *
;                                       prompts that the patient has        *
;                                       additional allergies.CR 1-899593881 *
;    *009 04/17/07 GG013711             Added Free set for various records  *
;    *010 06/12/07 SH016288             Add Modify, & Discontinue Banner Bar*
;                                       CR 1-899593932                      *
;                                       CR 1-899593932 & CR 1-1127184359    *
;    *011 06/05/07 SH016288             Remove activity&catalogCR1-919486213*
;    *012 06/05/07 SH016288             Add printing on activate action     *
;                                       Removed print on future action      *
;                                       CR 1-1127184331                     *
;    *013 06/12/07 SH016288             Remove time zone on dob and admit   *
;                                       CR 1-919486297                      *
;    *014 06/05/07 SH016288             Remove dcpreq02 CR 1-919486121      *
;    *015 06/05/07 SH016288             Move order details up by half of    *
;                                       the space available                 *
;                                       CR 1-1127184340                     *
;    *016 06/05/07 SH016288             Add ordered time to order d/t       *
;                                       display time zone if utc            *
;                                       CR 1-919486328                      *
;    *017 06/05/07 SH016288             DOB one day off CR 1-1065284374     *
;    *018 06/20/07 SH016288             Requisition tries to print the total*
;                                       number of orders instead of orders  *
;                                       that count                          *
;                                       CR 1-1162354921                     *
;    *019 08/07/07 RD012555             Add ellipsis to mnemonics that are  *
;                                       truncated.                          *
;    *020 09/25/07 MK012585             Fix to display Dt/Tm fields         *
;                                       correctly when UTC is on            *
;    *021 10/05/07 MK012585             Fix to format the time correctly    *
;                                       when UTC is on                      *
;    *022 10/10/07 MK012585             Fix to display the time in military *
;                                       format                              *
;    *023 08/20/08 KK014173             Update the subscript to print the   *
;                                        correct comments of the orders.    *
;    *024 04/04/09 KW8277               Correction for orders that do not   *
;                                       qualify to print, being printed on  *
;                                       multi-action. CR 1-2898209013       *
;    *025 02/05/09 MK012585             Join Order_action table using       *
;                                       conversation_id if one is passed in.*
;    *026 06/05/09 AS017690             Complex Med Changes                 *
;    *027 08/20/09 AD010624             Replace > " " comparisons with      *
;                                       size() > 0, trim both sides of order*
;                                       details instead of right side only  *
;    *028 10/31/09 SK018443             If the admitting dx string length is*
;                   greater than the display area,                          *
;                   truncate and add ellipsis                               *
;    *029 11/05/09 RD012555             Do not print for Protocols          *
/*---------------------------------------------------------------------------
#030 10/23/2012    Brian Twardy
Original CCL:  cer_script: cern_dcpreqgen02.prg
New CCL:       cer_script: cern_dcpreqgen02.prg  (I had tested with dcpreqgen02a.prg)
OPAS Request:  R2:000011908239  Task: R2:000019156909
For only Good Samaritan Hispital, A requisition route of 'Nutritionist Adult
Route' which is associated to a orderable of 'Consult to Nutritionist Adult',
will have the printed notices for discontinued consults turned off, regarding printing.
During testing... I will use the following orderable... Catalog_cd:  8591356 (Notify MD
of Decline in Functional Ability from Baseline).
--------------------------------
#031 11/14/2012    Brian Twardy
Original CCL:  cer_script: cern_dcpreqgen02.prg
New CCL:       cer_script: cern_dcpreqgen02.prg  (I have not changed the source name.)
OPAS Incident: R2:000032320155
For Harbor Hospital, Mike Willingham, requested that the discontinued
Sleep Apnea notifications would no longer print. The changes to this
script can be seen below. Each change is tagged with '031' and
'11/14/2012'  (there aren't many)
PLUS.....
As requested by Sharon Bonner, with a phone call after the above change was
made today...
For 'Consult to Pastoral Spiritual Care' discontinued orders, we will also
suppress their printing. This applies to routings for all facilities/departments.
(There are 6 at this time). These changes will also be tagged with '031' and
'11/14/2012'  (There stil aren't many, they're just larger now.)
--------------------------------
#032 11/28/2012    Brian Twardy
Original CCL:  cer_script: cern_dcpreqgen02.prg
New CCL:       cer_script: cern_dcpreqgen02.prg  (I have not changed the source name.)
Today we corrected the fact that the change from 11/14/2012 caused the discontinued
Nutrition notices to again start printing at GSH. To see where today's change was done,
look for 11/28/2012 to the CCL below.
--------------------------------
#033 01/07/2013    Brian Twardy
Original CCL:  cer_script: cern_dcpreqgen02.prg
New CCL:       cer_script: cern_dcpreqgen02.prg  (I have not changed the source name.)
Request/Task: R2:000012060367/R2:000019436678
Need to update the Hgt/Wgt, because it was not appearing on the printed for. It
is not appearing because it was not being selected.
This request was addressed in P41.
--------------------------------
#034 01/11/2013    Brian Twardy
Original CCL:  cer_script: cern_dcpreqgen02.prg
New CCL:       cer_script: cern_dcpreqgen02.prg  (I have not changed the source name.)
OPAS Incident: R2:000033647774
Two catalog entries now exist - duplicates- (two rows in code_set 200 with a display_key value of
"CONSULTTONUTRITIONISTADULT"), and the two catalog entries must be accounted for.
This orderable, "Consult to Nutritionist Adult", has been looked at by this
script for months. This orderable is NOT to have it's notification/report
printed when one of these orders is discontinued at GSH.  (See #030 10/23/2012)
So, the following code_values will be hardcoded in this program
for the two catloag items, "Consult to Nutritionist Adult":
    2780807.00
  101881045.00
#035 02/20/2013   Tameka Overton
Original CCL:  cer_script: cern_dcpreqgen02.prg
New CCL:       cer_script: cern_dcpreqgen02.prg  (I have not changed the source name.)
OPAS Incident: R2:000034249212
The incorrect MRN is displaying because the MRN for the selected encounter isn't being used and the MRN for
the patient is being used. Also, the FIN qualification needs to be modified because the current active
row may not be displayed
--------------------------------
#036 04/23/2013    Brian Twardy
Original CCL:  cer_script:  cern_dcpreqgen02.prg
New CCL:       cust_script: cern_dcpreqgen02.prg  (I have not changed the source name.) New location though.
                                                   No access to cer_script was granted, so I now am using
                                                   cust_script.
OPAS Req/Inc: R2:000012477699/R2:000020287381
Suppress the printing of the Consult to Psychiatry order if the patient was discharged, but do print
the requisition if the order was manually discontinued order. The action_personnel_id field/column
in the order_action table is the telling bit of data that indicates whether the associated order
action was performed by the system (value of 1 would be for a discharge) and a human being (a
value greater than 1 would be a manually discontinued order)
--------------------------------
#037 04/24/2013    Brian Twardy
Original CCL:  cust_script: cern_dcpreqgen02.prg
New CCL:       cust_script: cern_dcpreqgen02.prg  (I have not changed the source name.)
OPAS Incident: R2:000035200179
We will now suppress the printing of FSH 'consult to psychiatry' requistions,
except when the order_type is order_cd (ia, the inital order)
--------------------------------
#038 05/01/2013    Brian Twardy
Original CCL:  cust_script: cern_dcpreqgen02.prg
New CCL:       cust_script: cern_dcpreqgen02.prg  (I have not changed the source name.)
OPAS Request/Task: R2:000012719278/R2:000020787101
We will now suppress the printing of the 'Consult to Wound Ostomy Nurse' requistions,
except when the order_type is order_cd (ia, the inital order). This will apply to all facilities.
--------------------------------
#039 05/28/2013    Brian Twardy
Original CCL:  cust_script: cern_dcpreqgen02.prg
New CCL:       cust_script: cern_dcpreqgen02.prg  (I have not changed the source name.)
OPAS Request/Task: _______________/_______________  (Still awaiting the approval of the MCGA item.)
MCGA: MCGA16020
We will now suppress the printing of the certain diet requistions, when the order_type
is Cancel or Discontinue. This will apply to all facilities.
The diet orderables will be identified as follows:
 - Must have Catalog Type of  "Food and Nutrition Services"
 - Must have Requisition Format of "DCPREQGEN02"
 - Must NOT have one of the following Activity Types:
        - Snacks
        - Tube Feeding Additives
        - Tube Feeding
        - Tube Feeding Water Flush
--------------------------------
040 06/06/13 Siddharth Shetty     OPAS # 21169261
                                        Add diagnosis section to the requestion for
                                        orderables ED Bed request Communication, Place in Outpatient
                                        Observation, Place in Outpatient Extended Recovery, Admit to Inpatient.
--------------------------------
041 06/25/13 Siddharth Shetty           added qualifications to get diagnosis with classification as
                                        'Medical' and Confirmation as
                                        'confirmed'.
--------------------------------
042 07/10/13 Brandon Gordon     R2:36028634 - Stop req printing for ED Bed Request Communications
                                              Order when order is DC/Canc/Dischrg
--------------------------------
#043 07/13/2013  Brian Twardy
OPAS Incident: R2:000036326262   (It really should have been a request)
Source CCL:    cust_script: cern_dcpreqgen02.prg  (No name change)
Key user: Jennifer Talaber of Union Memorial, via Beverly Collins.
The following 3 orderable will also be added to the 2 included with the above orderable
mentioned in Updates 030 and 034. Now, all hospitals will have their requisitions
suppressed for these 4 orderables when the order is discontinued. It had
only been GSH that was suppressing the original 2 orderables.
I, Brian Twardy, added the 'RN Nutrition Consult' to this request, because
I have seen these discontinued requisitions printing from the same routing, due
to the same reason, a high Nutritionist Risk ssore.
        Consult to Nutrition from MD        # 114735211.00
        Consult to Nutritionist Pediatric   # 101947214.00
        RN Nutrition Consult                # 2780816.00
--------------------------------
#044 08/21/2013  Brian Twardy
OPAS Request/Task: R2:000013210585/R2:000021790490
Source CCL:    cust_script: cern_dcpreqgen02.prg  (No name change)
Key user: Carol Vittek
Modify requisition printing for Nutrition orders so that only the original order prints.  We do not want
additional requisitions for the frequency of each order. Change to be made for all hospital sites.
Rationale: Currently a requisition is printed for the original order that includes the frequency,
e. g. 4x/day. In addition to the req for the original order, 4 additional requisitions print for this
order for a total of 5 pieces of paper. If the order frequency is 3x/day - 4 requisitions will print,
and so on.
This is only for:
   Tube Feeding Additives           - 101816336.00
   Tube Feeding Bolus               - 101816417.00
   Tube Feeding Water Flushes  (This is not set up to print at all. The agreement is to skip this one.)
--------------------------------
045 10/21/13 Brandon Gordon     R2:22275504 - Restructured print format for Materials Mgmt orders
--------------------------------
#045a 3/18/2014 Tameka Overton
OPAS Request Task:23413618
Added encoutner type
--------------------------------
#046 03/25/2014  Brian Twardy
OPAS Request/Task: R2:000013280463/R2:000021935371  MCGA 14729  Key User:  Beverly Collins  - IS
OPAS Request/Task: R2:000013600560/R2:000022646033  MCGA 16586  Key User:  Ayeshya Kapoor  - WHC
OPAS Request/Task: R2:000013600296/R2:000022646049  MCGA 16581  Key User:  Lunar Song  - NRH
Source CCL:    cust_script: cern_dcpreqgen02.prg  (No name change)
Discontinued orders will now be surprtessed for ALL orderables.  Up to now, we have been specific,
but these 3 requests direct us to suppress any discontinued orders... that are discontinued by the SYSTEM,
rather than by an actual user.
Plus.... some of the newer fields (fields added over the past year or so) needed to be lined up, just to be neater.
--------------------------------
#047 04/09/2014  Brian Twardy
OPAS Incident: R2:000039548867                      Key User: Kenneth Lyons and  Mark Steppling of GUH
OPAS Request/Task: R2:000013270021/R2:000021914671  Key User: Lunar Song (NRH)  request for attening MD for consults
Source CCL:    cust_script: cern_dcpreqgen02.prg  (No name change)
GUH needs to have the Encounter Type 'not' overlay the Nuring Unit for the Material Managemnet version
of this report/requisition. The overlaying was an error.
NRH wants to have the attendind MD displayed for consults. This will apply to all hospitals. It will be displayed
immediately below the Ordering MD.
--------------------------------
#048 05/17/2014  Brian Twardy
OPAS Request/Task: R2:000014396937/R2:000024250961  Key Users: Beverly Collins/Evangeline Waihenya/Stevie Battista
MCGA: 17856
Source CCL:    cust_script: cern_dcpreqgen02.prg  (No name change)
Remove Admitting diagnosis from any dietary requisition. Dietary associates have no need to see the diagnosis.
A dietary orderable is defined as any orderable with a Catalog Type of 'Food and Nutrition Services', aka DIETARY.
Plus... the 2nd line of ALLERGIES no longer overlays the 1st line.
--------------------------------
049 06/17/14 Jennifer King      MCGA18411-Changed to print 3 meal assist orders at NRH when d/c'd
--------------------------------
#050 09/22/2014  Brian Twardy
OPAS Request/Task: ____/____    Key Users: Leslie Adams @ NRH / Beverly Collins of I.S
MCGA: 19205
Source CCL:    cust_script: cern_dcpreqgen02.prg  (No name change)
The requisition/order needs to print when:
Facility:           NRH
Orderables:         1:1 supervision                 --- OR ---
                    Total Assistance with Feeding   --- OR ---
                    Assist with Meals
Order Action Type:  Status Change
Order Status:       Completed
FYI.. The 3 orderables addressed here are the same three as were addressed with modification #049, from June 2014.
FYI.. This will not be cancelled by #039 from 05/28/2013, because the Catalog Type for 3 these orders
is "Patient Care", not "Food and Nutrition Services".
--------------------------------
051 04/28/15 Jennifer King      MCGA18835-print cancelled reqs for 3 nutrition orders
--------------------------------
052 05/06/15 Jennifer King      MCGA19566-do not print child orders for CPM Application order
--------------------------------
053 05/06/15 Jennifer King      MCGA20213-do not print Modified Barium Swallow for GSH Recurring Outpt and 4WST
--------------------------------
054 05.26.15 Kathleen Entwistle MCGA200808 - adding "activity type" to requisition for MM orders only.
--------------------------------
055 10.22.15 Kathleen Entwistle MCGA201165 - added logic to print canceled "admit to inpatient" orders at mguh.
--------------------------------
056 02.23.16 Kathleen Entwistle MCGA201050 - 1. Added isolation status to demographics  (NOTE: See 059 10/30/2018 !!!)
                                             2. Excluded following fields from displaying in order details
                                                    "Adhoc Frequency Instance", "Frequency Schedule ID" and "Difference in Minutes"
                                             3. Added creatinine/GFR results to display for PICC Insertion Adult GUH order

--------------------------------
#057 10/17/2017  Brian Twardy
MCGA: 209615
OPAS Request/Task: ____/____    Key User(s): Steve McCormick of MGUH
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
Ensure that discontinued or cancelled "Peripherally Inserted Central Catheter Insertion" orders at MGUH will print....
but only if discontinued or canceled by a human and not by System, System.  This applies only for MGUH.
--------------------------------
#058 08/03/2018  Brian Twardy
MCGA: 211870
SOM Task:  TASK1715331  Requester: Ashley Shelter of MUMH  (for Orville Henry and Gail Grant)
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
For only MUMH and MGSH, the following orders for registration should generate a requisition when
these orders have been discontinued OR cancelled by either the system (MODIFED. See NOTE below) OR by personnel actively
discontinuing or cancelling the order:
  - Admit to Inpatient
  - Change Attending Provider to
  - Place in Outpatient Extended Recovery
  - Place in Outpatient Observation
  - Transfer Level of Care or Location
NOTE... This was modified on 08/09/2018.  These orders will not automatically print if canceled, discontinued, or voided
by "System, System".  That applies to both GSH and to UMH.
--------------------------------
#059 10/30/2018  Brian Twardy
MCGA: 213235
SOM Task:  TASK2040610  Requester: Emily Bloch - GUH
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
Added the patient Code status on the requisition. However, see #062 07/05/2019 for a later revision.
Also fixed the isolation status. (See Modification Entry #056 02.23.16)
--------------------------------
#060 12/07/2018  Brian Twardy
MCGA: 214642
SOM Task:  TASK2361508  Requester: Hilary Poan and Rong Huang)
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
Adjust the requisition for admission/obs orders below for Southern Maryland and
Montgomery General to include diagnoses, for just these 3 orders:
   - Admit to Inpatient
   - Place in Outpatient Observation
   - Place in Short Stay (Post Procedure)
Plus... the label ADMIT DX is now VISIT REASON for every order.
--------------------------------
#061 06/12/2019  Brian Twardy
MCGA: 216421
SOM Task:  TASK2361508  Requester: Karthi Dandapani and Michelle Long, both of MWHC)
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
This will now generate the following orders for WHC to an email address, rather than to a printer.
However, when re-printing any of these orders from the Orders page in Powerchart, the order will print to
the selected printer as always... rather than generate an email.
 - Transfer Level of Care or Location
 - Change Attending Provider To
 - Admit to Inpatient
 - Place in Outpatient Observation
 - Status Change - Inpatient to Outpatient Observation
 - Status Change - Outpatient Observation to Inpatient
This will only apply to WHC orders. All of the other facilities will have
their same orders print as always... using the req/routing setups found in DCPTools. Additionally,
all of the other WHC orders not in this list of six orders will continue to print using the req/routing setups for these
orders.
NOTE:  The "printfile" (established with the variable, tempfile1a) that is created in this CCL script will be generated
as a PDF file when it is emailed.  Otherwise, it will be generated as it always had been, as a PostScript file.
----  UPDATE     UPDATE     UPDATE     UPDATE     UPDATE     UPDATE     UPDATE  ----
----  UPDATE     UPDATE     UPDATE     UPDATE     UPDATE     UPDATE     UPDATE  ----
NOTE: The above list of orders has been updated to this list....
 - Admit to Inpatient
 - Admit to NICU
 - Change Attending Provider To
 - Change Primary Care Provider (PCP)
 - MWHC ED Admit to Inpatient
 - MWHC ED Place in Outpatient Observation
 - Place in Outpatient Observation
 - Status Change - Inpatient to Outpatient Observation
 - Status Change - Outpatient Observation to Inpatient
 - Transfer Level of Care or Location
PLUS....With the 2018 Code Upgrade, Request->order_qual[*].conversation_id no longer exists. This has been commented out
of this script.  The "free record request" has been removed too.
--------------------------------
#062 07/05/2019  Brian Twardy
MCGA: N/A
SOM Incident:  INC7830134   (Customer: Ntiense Inokon)
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
Corrected the patient's Code Status on the requisition. It now displays the latest charted Code Status, not the oldest one.
  (See Modification Entry #059 10/30/2018)
--------------------------------
#063 11/12/19 David Smith
MCGA: 218682
Requester: Huang Rong (MMMC)
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
Note: Do PRINT "Consult to Palliative Care" (101806820.00) orders when CANCELED at MMMC.
--------------------------------
#064 01/28/2020  Brian Twardy
MCGA: 220178     (Requester(s): Natalie Tshiala, Carol Wier, and Jaclyn Craig... all from MFSMC)
SOM Task:  TASK3327035
Original SOM incident: INC8910814 (logged on 12/24/2019 to another Medconnect support team)
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
It was identified at MFSMC that 'Physical Therapy Evaluation and Treat' and 'Occupational Therapy Evaluation
and Treat' orders were sometimes not both printed when ordered together.  This issue is being researched, and the fix
has been implemented. The Physical Therapy Evaluation and Treatment order is now being handled by a separate
requisition route (CCL executable) and a seaparate requisition format.
-    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
Physical Therapy Evaluation and Treatment
    This order now uses a new....
        - requisition format (CCL executable): DCPREQGEN02T   cust_script:cern_dcpreqgen02t.prg
        - requisition route: PT Eval and Treat 02
Occupationall Therapy Evaluation and Treatment
    This order still uses the old....
        - requisition format (CCL executable): DCPREQGEN02    cust_script:cern_dcpreqgen02.prg
        - requisition route: OT Eval and Treat
Also... (adding onto #063 mentioned above)
These three hospitals are being renamed on the occasion of St Mary's finally being migrated into Medconnect.
The prompts may have been revised, along with the possibility of the designations of these hospitals within this program/script.
  - Medstar Montgomery Medical Center
  - Medstar Southern Maryland Hospital Center
  - Medstar St Mary's Hospital
--------------------------------
#065 01/18/21 David Smith
MCGA: 218682
Requester: Joseph Opinion (FirstNet)
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
Note: See MOD060. We are including St. Mary's in this same list now
--------------------------------
#066 02/03/2021  Brian Twardy
MCGA: 225225  - Assigeee group: MSH-Medconnect Pharmacy      Assignee: Evelyn Nyarko-Ahlijah
Requester(s): Max Smith
SOM Task:  TASK4191152  (Custom Develpment team's task)
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
The pharmacogenomics group requested an email notification to be sent when one of these two orders are ordered:
  - Consult to Pharmacogenomics and Pharmacogenetics Maryland
  - Consult to Pharmacogenomics and Pharmacogenetics Washington
NOTE: No re-printing (or printing) is available for these Consults.
--------------------------------
#067 02/14/2021  Brian Twardy
MCGA: 222651
Requester(s): Rong Huang and Anthony Atkins, both of MMC
SOM Task:  TASK3734435
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
Executable: dcpreqgen02   (No name change)
For only Montgomery Medical Center (MMC), when any of these 4 orders are cancelled or discontinued by a
person (not by "SYSTEM, SYSTEM"), the requisition should now print. Up to now, these orders would not
print... when cancelled.
  - Admit to Inpatient
  - Place in Outpatient Observation
  - Place in short stay (post procedure
  - Transfer Level of Care or Location
NOTE: The first three of the above listed orders were already set in dcptools to print at three Medconnect printers/queues.
      For this request, the fourth order, which was only set to print at two of these printers, is now set to also
      print at that third printer, mmcadspt001.
--------------------------------
#068 03/08/2021  Brian Twardy
MCGA: 225691
Requester(s): Nicole Bivins and Ashley Shelter of UMH
SOM Task: TASK4269519
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
This script will generate an email for the following order, just for Union Memorial UMH patients. Printing will
still occur as it has been.
   - Pulmonary Function Testing (PFT)
This is similar to modification #061 from 2019, for WHC. However, this time, this requisition/order will print
--AND-- it will be generated by email... all when an order is ordered. Modification #061 will only email.
To do this, we will loop through twice, generating two tempfiles... one that will print and the other one will be attached
to an email.  (Look for the variable/indicator... pft_order_email_ind)
--------------------------------
#069 02/14/2022  Brian Twardy
MCGAs: 1. 231040 (Create New Contact Information PF with Printed Requisition Rules)
       2. 231511 (For Updated Emergency Contact order - Update the Print requisition "DCPREQGEN02")
Requester(s): Rong Huang of MMMC
SOM Task: 1. TASK5048534
          2. TASK5066691
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
1. Now expanding the room for order comments for the Updated Emergency Contact order (just that order, Updated Emergency Contact)
   Later, a change was made here.  Now, those comments are charted into a Powerform and a rul creates the order. There was a
   possible timing issue with the rule, so... now... this script pulls the charted comments from the clinical_event and the
   ce_blob tables.
2. Now excluding two meaningless order details for all otrders (seen when testing the Updated Emergency Contact order):
   - ADHOCFREQINSTANCE
   - DIFFINMIN
--------------------------------
#070 06/20/2022  Brian Twardy
MCGAs: 232502
SOM RITM/Task: RITM2939528 / TASK5369440
Requester(s): Mara Knowles of GUH
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
For the 'Peripherally Inserted Central Catheter Insertion' order, two events will be swapped out for a single one as
listed here:
   - Out - GFR African American
   - Out - GFR Non African American
   - In - GFR Universal
This GFR, and the other 2 also, have always just been for GUH.
--------------------------------
#071 07/22/2022  Brian Twardy
MCGA:232552   (Requesters: Joseph Opinion, among many for this project)
SOM Request/Task: RITM2913500 / TASK5366463
CCL Source: cust_script:cern_dcpreqgen02.prg  (no name change)
For the Admission Order Standardization project, several new orders will be replacing existing orders.
--------------------------------
#072 09/06/2022  Brian Twardy
MCGA:235017   (Requester: Ashley Shelter)
SOM Request/Task: RITM3070456 / TASK5627844
CCL Source: cust_script:cern_dcpreqgen02.prg  (no name change)
For the 'Update Emergency Contact' order - display as 'Updated Contact Information' instead
--------------------------------
#073 11/15/2022  Brian Twardy
MCGA: N/A
SOM Incident: INC14949120
CCL Source: cust_script:cern_dcpreqgen02.prg  (no name change)
Updated the list of ADT Orders for WHC's emailing to include these. This came during Wave 2 of the CapMan Go Live.
   - Admit to Inpatient-MedStar Health
   - Place in Outpatient Extended Recovery-MedStar Health
   - Place in Outpatient Observation-MedStar Health
   - Transfer Level of Care or Location-MedStar Health
--------------------------------
#074 11/16/2022  Brian Twardy
MCGA: 236107
SOM Task:  RITM3165679 / TASK5812077
Requester: Rong Huang
Source CCL: cust_script:cern_dcpreqgen02.prg  (No name change)
Adjust the requisition for admission/obs orders below for Southern Maryland, Montgomery General, and St Mary's
to include diagnoses, for these 4 new orders from the CapMan project.
   - Admit to Inpatient-MedStar Health
   - Place in Outpatient Extended Recovery-MedStar Health
   - Place in Outpatient Observation-MedStar Health
   - Transfer Level of Care or Location-MedStar Health
For a little history, see #060 (from 2018) and #065 (from 2021) farther above.
--------------------------------
#075 11/29/2022  Kevin Sherwood
MCGA: 236177
CCL Source: cust_script:cern_dcpreqgen02.prg  (no name change)
Filter out print job if order is "Admit to Inpatient-MedStar Health and modified via discernrule
oe_field_id = 2835127395.00 ; "DiscernRule" ; action_sequence = 2
--------------------------------
#076 11/30/2022  Brian Twardy
MCGA: 236230
SOM Task: RITM3174170 / TASK5827641
Requesters: Rong Huang, Stephen Alvey, Sarah Fletcher, Lucy Raymond
Source CCL: cern_dcpreqgen02.prg  (No name change)
Adjust the requisition for older, status change' orders below, for Southern Maryland, Montgomery General, and St Mary's.
We only added the diagnoses similarly as we did with modifications #074 and #060.  See above.
   - Status Change - Inpatient Admission to Outpatient Extended Recovery
   - Status Change - Inpatient to Outpatient Observation
   - Status Change - Outpatient Extended Recovery to Inpatient Admission
   - Status Change - Outpatient Observation to Inpatient
   - Status Change - Outpatient Observation to Outpatient Extended Recovery
--------------------------------
#077 12/09/2022  Brian Twardy
MCGA: n/a
SOM Task: RITM3193171 / TASK5862021
Requester: Rong Huang
Source CCL: cern_dcpreqgen02.prg  (No name change)
In order to fully display long order names, such as "Status Change - Outpatient Observation to Outpatient Extended Recovery",
this script now checks the length of the order name, and it sets the font size used to display the order name accordingly.
The order name is displayed about half way down the page ion a text box and at the bottom of the page.
This revision is in palce for any order name... no matter the kind of order.
--------------------------------
#078 12/19/2022  Brian Twardy
MCGA: 236482
SOM RITM/Task: RITM3198006 / TASK5871296
Requesters: Nicole Plitt of MFSMC and Vivienne Lettsome
Source CCL: cern_dcpreqgen02.prg  (No name change)
For "Pulse Oximetry with Exercise orders for MFSMC, enabled automatic printing of canceled and discontinued orders. The
one exception is a "Cancel and Reorder". For those, the discontinue/cancel will not be automatically printed.
--------------------------------
#079 01/10/2023  Brian Twardy
MCGA: 236482  (continued from above, #078)
SOM RITM/Task: RITM3198006 / TASK5871296  (continued from above, #078)
Requesters: Nicole Plitt of MFSMC and Vivienne Lettsome
CCL script: cern_dcpreqgen02.prg  (No name change)
Any cancel or discontinue order mentioned above with change "#078" above must come BEFORE the next
ordered order... rather than before "OR" after it.
--------------------------------
#080 4/23/24 MCGA 346698
 For WHC only, Add another order that gets placed by a rule.
 3341919083.00 Update Patient Information
--------------------------------
#081 MCGA 348629
8/6/2024 Kim Frazier
FOR GUH only, For Negative Pressure Wound Therapy Discontinued
   101806105.00         200     Negative Pressure Wound Therapy Discontinued

 -7/23/24 - Send email to
1)  lem23@gunet.georgetown.edu
2)  dmitric.crowe@gunet.georgetown.edu
3) christina.m.koehler@gunet.georgetown.edu
4) fiona.j.mulroe@gunet.georgetown.edu
5) kimberly.mauck@gunet.georgetown.edu"
Also Include guh-nisupport@gunet.georgetown.edu

#082 mcga 348658
8/6/2024 Kim Frazier
For GUH only, for Specialty Bed Request Ordered
  101815498.00          200     Specialty Bed   SPECIALTYBED

send email to
1)  lem23@gunet.georgetown.edu
2)  dmitric.crowe@gunet.georgetown.edu
Also Include guh-nisupport@gunet.georgetown.edu
--------------------------------

083 01/14/2025 Kim Frazier in complete
mcga 350991 For MMMC only, please exclude Ambulatory Surgery encounter from
            Negative Pressure Wound Therapy Discontinue order requisition printing.
            
;This modblock style is horrible... I'm trying something more standard.  Hate me if you will.  ;084
******************************************************************************************************************************
                  MODIFICATION CONTROL LOG CONTINUED     
******************************************************************************************************************************
Mod Date       Analyst              MCGA   Comment       
--- ---------- -------------------- ------ -----------------------------------------------------------------------------------
084 02/26/2025 Michael Mayes        352263 FSH has special logic in here around Pulse Oximetry with Exercise.  They don't like 
                                           that currently.  They want to move that to Ambulating Pulse Ox RT.  In addition
                                           they want to add MMMC to that special case logic.
******************************************************************************************************************************/

drop program dcpreqgen02:dba go
create program dcpreqgen02:dba

prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.

with OUTDEV


;Request structure always be present as the first record
;declaration as Output server calls CCLSET_RECORD without
;passing in a record structure name. The memory gets allocated
;to this request definition

;free record request                    ; 061 06/12/2019 (really 06/14/2019)  Greened out
record request
( 1 person_id = f8
  1 print_prsnl_id = f8
  1 order_qual[*]
    2 order_id = f8
    2 encntr_id = f8
;;    2 conversation_id = f8            ; 061 06/12/2019 (really 06/14/2019)  Greened out
  1 printer_name = c50
)

;; 2019  5 lines beliow are used in testing     ;;;;;;; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
;;set stat = alterlist(request->order_qual, 1)
;;set request->person_id =   5442846.00 ;11601877.00
;;set request->order_qual[1].encntr_id =    163355991.00    ;33341677.00
;;set request->order_qual[1].order_id = 11399952671.00  ;  1917072081.00
;;set request->print_prsnl_id = 133132.00


; mod 009
free set orders
free set allergy
free set diagnosis
free set pt

record orders
( 1 name                           = vc
  1 age                            = vc
  1 dob                            = vc
  1 mrn                            = vc
  1 location                       = vc
  1 facility                       = vc
  1 nurse_unit                     = vc
  1 room                           = vc
  1 bed                            = vc
  1 sex                            = vc
  1 fnbr                           = vc
  1 med_service                    = vc
  1 admit_diagnosis                = vc
  1 isolation                      = vc          ;056 02.23.2016  ;059 10/30/2018 Isolation was corrected today
  1 creat                          = vc          ;056
  1 creat_date                     = dq8         ;056
  1 gfr                            = vc          ;056
  1 gfr_date                       = dq8         ;056
; 1 gfrAA                          = vc          ;056            ; 070 06/20/2022 Removed.
; 1 gfrAA_date                     = dq8         ;056            ; 070 06/20/2022 Removed.
  1 height                         = vc
  1 weight                         = vc
  1 admit_dt                       = vc
  1 attending                      = vc
  1 admitting                      = vc
  1 order_location                 = VC
  1 spoolout_ind                   = i2
  1 cnt                            = i2
  1 encntr_type                    = vc          ;045
  1 code_status                    = vc          ; 059 10/30/2018 new
  1 qual[*]
    2 order_id                     = f8
    2 display_ind                  = i2
    2 template_order_flag          = i2
    2 cs_flag                      = i2
    2 iv_ind                       = i2
    2 mnemonic                     = vc
    2 mnem_ln_cnt                  = i2
    2 mnem_ln_qual[*]
      3 mnem_line                  = vc
    2 display_line                 = vc
    2 disp_ln_cnt                  = i2
    2 disp_ln_qual[*]
      3 disp_line                  = vc
    2 order_dt                     = vc
    2 signed_dt                    = vc
    2 status                       = vc
    2 accession                    = vc
    2 catalog_cd                   = f8          ;056
    2 catalog                      = vc
    2 catalog_type_cd              = f8
    2 activity                     = vc
    2 activity_type_cd             = f8
    2 another_new_order_ind        = i2          ; 078 12/19/2022 New
    ;2 pulse_oxi_with_exer_ord_ind = i2          ; 078 12/19/2022 New
    2 pulse_oxi_ord_ind            = i2          ; 084 Adding this and removing the above... 
    2 last_action_seq              = i4
    2 enter_by                     = vc
    2 order_dr                     = vc
    2 type                         = vc
    2 action                       = vc
    2 action_type_cd               = f8
    2 comment_ind                  = i2
    2 comment                      = vc
    2 com_ln_cnt                   = i2
    2 com_ln_qual[*]
      3 com_line                   = vc
    2 oe_format_id                 = f8
    2 clin_line_ind                = i2
    2 stat_ind                     = i2
    2 d_cnt                        = i2
    2 d_qual[*]
      3 field_description          = vc
      3 label_text                 = vc
      3 value                      = vc
      3 value_cnt                  = i2
      3 value_qual[*]
        4 value_line               = vc
      3 field_value                = f8
      3 oe_field_meaning_id        = f8
      3 group_seq                  = i4
      3 print_ind                  = i2
      3 clin_line_ind              = i2
      3 label                      = vc
      3 suffix                     = i2
      3 field_type_flag            = i2
    2 priority                     = vc
    2 req_st_dt                    = vc
    2 frequency                    = vc
    2 rate                         = vc
    2 duration                     = vc
    2 duration_unit                = vc
    2 nurse_collect                = vc
    2 fmt_action_cd                = f8
)

record allergy
( 1 cnt                            = i2
  1 qual[*]
    2 list                         = vc
  1 line                           = vc
  1 line_cnt                       = i2
  1 line_qual[*]
    2 line                         = vc
)

record diagnosis
( 1 cnt                            = i2
  1 qual[*]
    2 diag                         = vc
  1 dline                          = vc
  1 dline_cnt                      = i2
  1 dline_qual[*]
    2 dline                        = vc
)

record pt
( 1 line_cnt                       = i2
  1 lns[*]
    2 line                         = vc
)




/*****************************************************************************
*    Program Driver Variables                                                *
*****************************************************************************/

declare order_cnt      = i4 with protect, noconstant(size(request->order_qual,5))
declare ord_cnt        = i4 with protect, noconstant(size(request->order_qual,5));018
set stat = alterlist(orders->qual,order_cnt)

declare person_id      = f8 with protect, noconstant(0.0)
declare encntr_id      = f8 with protect, noconstant(0.0)

set orders->spoolout_ind = 0
set pharm_flag = 0     ; Set to 1 if you want to pull the MNEM_DISP_LEVEL and IV_DISP_LEVEL from the tables.

declare mrn_alias_cd   = f8 with protect, constant(uar_get_code_by("MEANING", 4, "MRN"))
declare comment_cd     = f8 with protect, constant(uar_get_code_by("MEANING", 14, "ORD COMMENT"))
declare fnbr_cd        = f8 with protect, constant(uar_get_code_by("MEANING", 319, "FIN NBR"))
declare mrnnbr_cd        = f8 with protect, constant(uar_get_code_by("MEANING", 319, "MRN"));035
declare admit_doc_cd   = f8 with protect, constant(uar_get_code_by("MEANING", 333, "ADMITDOC"))
declare attend_doc_cd  = f8 with protect, constant(uar_get_code_by("MEANING", 333, "ATTENDDOC"))
declare canceled_cd    = f8 with protect, constant(uar_get_code_by("MEANING", 12025, "CANCELED"))
declare inerror_cd     = f8 with protect, constant(uar_get_code_by("MEANING", 8, "INERROR"))
declare pharmacy_cd    = f8 with protect, constant(uar_get_code_by("MEANING", 6000, "PHARMACY"))
declare consults_cd    = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 6000, "CONSULTS")) ; 047 04/09/2014    636063.00
declare iv_cd          = f8 with protect, constant(uar_get_code_by("MEANING", 16389, "IVSOLUTIONS"))
declare complete_cd    = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "COMPLETE"))
declare modify_cd      = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "MODIFY"))
declare order_cd       = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "ORDER"))
declare cancel_cd      = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "CANCEL"))
declare discont_cd     = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "DISCONTINUE"))
declare studactivate_cd = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "STUDACTIVATE")) ;007
declare activate_cd    = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "ACTIVATE")) ;011
declare void_cd    = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "VOID"))                ;026
declare suspend_cd    = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "SUSPEND"))          ;026
declare resume_cd    = f8 with protect, constant(uar_get_code_by("MEANING", 6003, "RESUME"))            ;026
declare intermittent_cd = f8 with protect, constant(uar_get_code_by("MEANING", 18309, "INTERMITTENT"))  ;026
DECLARE CODE_STATUS_CD  =  f8  WITH  CONSTANT (uar_get_code_by("DESCRIPTION",72,"Code Status"))         ; 059 10/30/2018 New


declare last_mod = c3 with private, noconstant(fillstring(3, "000"))
declare offset = i2 with protect, noconstant(0)
declare daylight = i2 with protect, noconstant(0)
declare tz_index = i4 with protect, noconstant(0)
declare saved_pos = i4 with protect, noconstant(0)
declare max_length = i4 with protect, noconstant(0)
declare xcol = i4 with protect, noconstant(0)
declare ycol = i4 with protect, noconstant(0)

declare mnemonic_size = i4 with protect, noconstant(0)  ;019
declare mnem_length = i4 with protect, noconstant(0)    ;019

declare print_diag_flag = i2 with protect, noconstant(0) ;040 SDS116

declare disp_creatGFR = i2 with protect, noconstant(0) ;056


;---------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------
; 066  02/03/2021
; Emailing when any of the following Consult orders are being processed. The requisition is not included with the
; email. All that is included is a body with info about the patient and the order.
; NOTE: No re-printing (or printing) is available for these Consults.
;---------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------
declare consult_to_pharmacogenomics_ind = i2 with noconstant (0)    ; 1 will mean... one of these consults has appeared
declare consult_to_pharm_description = vc with noconstant('')
declare consult_to_pharm_order_id_disp = vc with noconstant('')
declare consult_to_pharm_dt_tm_disp = vc with noconstant('')
declare consult_to_pharm_FIN = vc with noconstant('')

select into "nl:"
from (dummyt d1 with seq = size(request->order_qual,5)),
      orders o,
      encntr_alias eaf   ; to get the FIN
plan d1
join o
  where o.order_id = request->order_qual[d1.seq].order_id and
        o.order_status_cd = 2550.00 and     ; Ordered
        o.active_ind = 1 and
      ((CURDOMAIN = 'P41' and
        o.catalog_cd in (2398592483.00, ;   Consult to Pharmacogenomics and Pharmacogenetics Washington
                         2398560933.00)) ;  Consult to Pharmacogenomics and Pharmacogenetics Maryland
        or
       (CURDOMAIN = 'B41' and
        o.catalog_cd in (1879636863.00, ;   Consult to Pharmacogenomics and Pharmacogenetics Washington
                         1878331491.00)) ;  Consult to Pharmacogenomics and Pharmacogenetics Maryland
       )
join eaf
    where eaf.encntr_id = o.encntr_id and
          eaf.encntr_alias_type_cd = 1077.00 and ; FIN
          eaf.active_ind = 1 and
          eaf.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
detail
    consult_to_pharmacogenomics_ind = 1
    consult_to_pharm_description = uar_get_code_description(o.catalog_cd)
    consult_to_pharm_order_id_disp = substring(1,20,cnvtstring(o.order_id,14,0))
    consult_to_pharm_dt_tm_disp = format(o.orig_order_dt_tm, "MM/DD/YYYY hh:mm;;Q")
    consult_to_pharm_FIN = cnvtalias(eaf.alias, eaf.alias_pool_cd)
with nocounter


If (CURDOMAIN = 'P41' and                                   ; 066 02/03/2021  use this line in P41
    consult_to_pharmacogenomics_ind = 1)                    ; 1 means that one of the Consults to Pharmacogenomics has appeared

    declare email_subject_cons_pharm = VC WITH NOCONSTANT(" ")

    set email_subject_cons_pharm = 'Consult to Pharmacogenomics Alert'

    declare email_body_cons_pharm = vc with noconstant("")
    declare unicode_cons_pharm = vc with noconstant("")

    declare aix_command_cons_pharm    = vc with noconstant("")
    declare aix_cmdlen_cons_pharm     = i4 with noconstant(0)
    declare aix_cmdstatus_cons_pharm = i4 with noconstant(0)

    declare email_address_cons_pharm    = vc with noconstant("")
    set email_address_cons_pharm =
;               "brian.twardy@medstar.net"                                      ; 066 02/03/2021 for B41 only
                "Max.Smith@medstar.net"                                         ; 066 02/03/2021 for P41
    set email_cc_list_cons_pharm =
                "brian.twardy@medstar.net,Evelyn.M.Nyarko-ahlijah@medstar.net"

    set email_body_cons_pharm = concat("consult_pharm_req_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                            "_",trim(substring(2,4,cnvtstring(RAND(0)))),       ; Random # generator 4 digits
                            ".txt")
;------------------------------------------------------------------------------------------
;; Below, we are creating a file that will hold the email body. The file's name is inside email_body_cons_pharm.

    select into (value(email_body_cons_pharm))
                    bodyord = build2  ("Order:      ", trim(consult_to_pharm_description)),
                    bodyordid = build2("Order ID:  ", trim(consult_to_pharm_order_id_disp)),
                    bodyFIN = build2("FIN:          ", trim(consult_to_pharm_FIN)),
                    bodyorddt = build2("Ordered:   ",trim(consult_to_pharm_dt_tm_disp)),
                    bodymsg01 =
                        "A Consult to Pharmacogenomics order has been placed. Please review your Consult Patient List for details.",
                    bodymsg02 =
                        "This is an automated message sent from MedConnect.",
                    domain_email_body = (if (curdomain = "P41")
                                                " "
                                         else
                                             build2("This email was sent from a Non-Production Domain:  ", trim(curdomain))
                                         endif)
    from dummyt
    Detail
        row +1
        col 01 bodymsg01
        row +2
        col 01 bodymsg02
        row +2
        col 01 bodyord
        row +2
        col 01 bodyFIN
        row +2
        col 01 bodyorddt
        row +2
        col 01 bodyordid
        row +4
        col 01 domain_email_body

    with format, format = variable   ,   maxcol = 140

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    set  aix_command_cons_pharm  =
        build2 ( "cat ", email_bodY_cons_pharm ," | tr -d \\r",
               " | mailx  -S from='report@medstar.net' -s '" ,email_subject_cons_pharm , "' -c ", email_cc_list_cons_pharm,
               " ", email_address_cons_pharm)

    set aix_cmdlen_cons_pharm = size(trim(aix_command_cons_pharm))
    set aix_cmdstatus_cons_pharm = 0
    call dcl(aix_command_cons_pharm, aix_cmdlen_cons_pharm, aix_cmdstatus_cons_pharm)

    call pause(2)   ; Let's slow things down before the clean up immediately below.
    call pause(2)   ; Let's slow things down before the clean up immediately below.

    ;   clean up.   (Removing EMAIL_BODY from $CCLUSERDIR does work.)

    set  aix_command_cons_pharm  =
        concat ('rm -f ' , email_body_cons_pharm)

    set aix_cmdlen_cons_pharm = size(trim(aix_command_cons_pharm))
    set aix_cmdstatus_cons_pharm = 0
    call dcl(aix_command_cons_pharm,aix_cmdlen_cons_pharm, aix_cmdstatus_cons_pharm)

    Go to Exit_script

endif




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; #030 10/23/2012   The below few lines are for GSH and the 'Consult to Nutritionist Adult'
;;;                   alert/notification/requisition.

;declare CONSULT_NUTRITION_CD = f8
;                with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "CONSULTTONUTRITIONISTADULT"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; #034 01/11/2013   Because there are now duplicates for this orderable, 'Consult to Nutritionist Adult',
;;;                   I am hard coding the code_values in here.  It is unclear which is being used in P41, because
;;;                   they are both active in code_set 200. therefore, we will look for one or the other when
;;;                   looking for 'Consult to Nutritionist Adult'.

declare CONSULT_NUTRITION_CD_A = f8 with protect, constant(2780807.00)
declare CONSULT_NUTRITION_CD_B = f8 with protect, constant(101881045.00)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; #043 07/13/2013  The following 3 orderables will also be added to the 2 orderables included above in Updates 030 and 034.
;;;                  Now, all hospitals will have their requisitions suppressed for these 5 orders when the order
;;;                  is discontinued.  (Up to now, only GSH was excluing the original 2.)
;;;                  I, Brian Twardy, added the 'RN Nutrition Consult' to this request, because I have seen these
;;;                  discontinued requisitions printing from the same routing, due to the same reason, a high
;;;                  Nutritionist Risk ssore.

declare CONSULT_NUTRITION_FROM_MD_CD = f8
           with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "CONSULTTONUTRITIONFROMMD"))       ; 114735211.00
declare CONSULT_NUTRITION_PED_CD = f8
           with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "CONSULTTONUTRITIONISTPEDIATRIC")) ; 101947214.00
declare RN_NUTRITION_CONSULT_CD = f8
           with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "RNNUTRITIONCONSULT"))             ; 2780816.00


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; #059 10/30/2018
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
declare HEMODIALYSISELEMENTS_CD = f8
           with constant(uar_get_code_by("DISPLAYKEY", 200, "HEMODIALYSISELEMENTS"))        ; 1006163621.00
declare HEMODIALYSISELEMENTSFSMC_CD = f8
           with constant(uar_get_code_by("DISPLAYKEY", 200, "HEMODIALYSISELEMENTSFSMC"))    ; 1588902027.00
declare HEMODIALYSISELEMENTSMGUH_CD = f8
           with constant(uar_get_code_by("DISPLAYKEY", 200, "HEMODIALYSISELEMENTSMGUH"))    ; 1587316143.00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 069 02/14/2022 New order to address in a customized manner  (it's not in P41 yet, so let's use the uar_get_code_by
;;;                function.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

declare UPDATEDEMERGENCYCONTACT_CD = f8              ; 2826084063.00 in B41  ; 3341919083.00 in P41
           with constant(uar_get_code_by("DISPLAYKEY", 200, "UPDATEDEMERGENCYCONTACT"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; #060 12/07/2018 Two new facilities
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

declare MMC_FACILITY_CD = f8            ; MedStar Montgomery Medical Center
select into "nl:" code_value = cv.code_value
from code_value cv
where cv.code_set = 220
;   and cv.display_key = 'MMC'                                                              ; 064 01/28/2020 replaced
    and cv.code_value = 446795444.00    ; MedStar Montgomery Medical Center                 ; 064 01/28/2020 replacement
    and cv.cdf_meaning ='FACILITY'
detail
MMC_FACILITY_CD = cv.code_value
with nocounter


declare SMHC_FACILITY_CD = f8           ; MedStar Southern Maryland Hospital Center
select into "nl:" code_value = cv.code_value
from code_value cv
where cv.code_set = 220
;   and display_key = 'SMHC'                                                                ; 064 01/28/2020 replaced
    and cv.code_value = 465210143.00    ; MedStar Southern Maryland Hospital Center         ; 064 01/28/2020 replacement
    and cv.cdf_meaning ='FACILITY'
detail
SMHC_FACILITY_CD = cv.code_value
with nocounter

;MOD065 START
declare STMARYS_FACILITY_CD = f8                ; MedStar St. Mary's Hospital
select into "nl:" code_value = cv.code_value
from code_value cv
where cv.code_set = 220
    and cv.code_value = 465209542.00
    and cv.cdf_meaning ='FACILITY'
detail
STMARYS_FACILITY_CD = code_value
with nocounter
;MOD065 END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; #050 09/19/2014
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

declare action_type_status_change_cd = f8 with constant(uar_get_code_by ("MEANING",6003 , "STATUSCHANGE"))      ; 2539.00
declare order_status_completed_cd = f8 with constant(uar_get_code_by("MEANING", 6004, "COMPLETED"))             ; 2543.00

 ;;; 049 ;;; JJK 6/17/2014 Declaring variables for NRH facility and particular nutrition orders

declare NRH_FACILITY_CD = f8
select into "nl:" code_value = cv.code_value
from code_value cv
where code_set = 220
    and display_key = 'NATIONALREHAB'
    and cdf_meaning ='FACILITY'
detail
NRH_FACILITY_CD = code_value
with nocounter

declare ASSISTWITHMEALS_CD = f8
           with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "ASSISTWITHMEALS"))

declare ONETOONESUPER_CD = f8
           with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "1TO1SUPERVISIONWITHMEALS"))

declare TOTALASSISTWITHFEEDING_CD = f8
           with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "TOTALASSISTANCEWITHFEEDING"))


declare GSH_FACILITY_CD = f8
select into "nl:" code_value = cv.code_value
from code_value cv
where code_set = 220
    and display_key = 'GOODSAMHOSP'
    and cdf_meaning ='FACILITY'
detail
GSH_FACILITY_CD = code_value
with nocounter
;;;;; #030 ends here ;;;;;;;;;;;;  More for 030 follows farther below.  ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; #031 11/14/2012   The below few lines are for Harbor and the 'Consult for Sleep Apnea Risk'
;;;                   alert/notification/requisition
;;;                   --AND--
;;;                   for PASTORAL SPIRITUAL CARE for any/all facilities/departments.

declare CONSULT_SLEEP_APNEA_CD = f8
                with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "CONSULTFORSLEEPAPNEARISK"))
declare CONSULT_PAST_SPIRIT_CD = f8
                with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "CONSULTTOPASTORALSPIRITUALCARE"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 036 04/23/2013  Added today.

declare CONSULT_PSYCHIATRY_CD = f8
                with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "CONSULTTOPSYCHIATRY")) ; 101817871.00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 038 05/01/2013  Added today.

declare CONSULT_WOUND_OSTOMY_NURSE_CD = f8
                with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "CONSULTTOWOUNDOSTOMYNURSE")) ;     2780801.00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 039 05/28/2013  Added today.

declare DCPREQGEN02_FORMAT_CD = f8
                with protect, constant(uar_get_code_by('DISPLAYKEY', 6002, "DCPREQGEN02"));     5386201.00
declare FOODANDNUTRITIONSERVICES_CD = f8
                with protect, constant(uar_get_code_by('DISPLAYKEY', 6000, "FOODANDNUTRITIONSERVICES")) ;     2511.00

declare SNACKS_CD = f8
                with protect, constant(uar_get_code_by('DISPLAYKEY', 106, "SNACKS"))                    ;     636695.00
declare TUBEFEEDING_CD = f8
                with protect, constant(uar_get_code_by('DISPLAYKEY', 106, "TUBEFEEDING"))               ;     681643.00
declare TUBEFEEDINGADDITVIVES_CD = f8
                with protect, constant(uar_get_code_by('DISPLAYKEY', 106, "TUBEFEEDINGADDITIVES"))      ;     102279124.00
declare TUBEFEEDINGWATERFLUSH_CD = f8
                with protect, constant(uar_get_code_by('DISPLAYKEY', 106, "TUBEFEEDINGWATERFLUSH"))     ;     102069512.00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 044 08/21/2013  Added today.

declare TUBEFEEDINGADDITIVES_CAT_CD = f8
                with protect, constant(uar_get_code_by('DISPLAYKEY', 200, "TUBEFEEDINGADDITIVES"))  ;     101816336.00
declare TUBEFEEDINGBOLUS_CAT_CD = f8
                with protect, constant(uar_get_code_by('DISPLAYKEY', 200, "TUBEFEEDINGBOLUS"))      ;     101816417.00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


declare HHC_FACILITY_CD = f8
select into "nl:" code_value = cv.code_value
from code_value cv
where code_set = 220
    and display_key = 'HARBOR'
    and cdf_meaning ='FACILITY'
detail
HHC_FACILITY_CD = code_value
with nocounter
;;;;; #031 ends here ;;;;;;;;;;;;  More for 031 follows farther below.  ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 037  04/24/2013  For the Consult to Psychiatry requisition suppressing... at Franklin Square only

declare FSH_FACILITY_CD = f8
select into "nl:" code_value = cv.code_value
from code_value cv
where code_set = 220
    and display_key = 'FRANKLINSQUARE'
    and cdf_meaning ='FACILITY'
    and active_ind = 1
detail
FSH_FACILITY_CD = code_value
with nocounter

declare ED_BED_REQUEST_CD = f8 with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "EDBEDREQUESTCOMMUNICATION")) ;042
declare MAT_MGMT_CD = f8 with protect, constant(uar_get_code_by("MEANING",6000,"MATERIALMGMT"))


;055 start new declarations

;MGUH facility code variable
declare GUH_FACILITY_CD = f8
select into "nl:" code_value = cv.code_value
from code_value cv
where code_set = 220
    and display_key = 'GEORGETOWN'
    and cdf_meaning ='FACILITY'
detail
GUH_FACILITY_CD = code_value
with nocounter


;MWHC facility code variable
declare WHC_FACILITY_CD = f8                                                ;061 04/26/2019   New
select into "nl:" code_value = cv.code_value
from code_value cv
where cv.code_set = 220
    and cv.display_key = 'WASHINGTONHOSP'           ;     4363216.00    WashingtonHosp
    and cv.cdf_meaning ='FACILITY'
detail
    WHC_FACILITY_CD = cv.code_value
with nocounter




;Admit to Inpatient orderable variable
declare ADMITTOINPATIENT_CD = f8                                                                            ; 058 08/03/2018 But not New. See #055
           with protect, constant(uar_get_code_by("DISPLAYKEY", 200, "ADMITTOINPATIENT"))

;055 end new declarations


declare CHANGEATTENDINGPROVIDERTO_CD = f8                                                                   ; 058 08/03/2018 New
           with constant(uar_get_code_by("DISPLAYKEY", 200, "CHANGEATTENDINGPROVIDERTO"))
declare PLACEINOUTPATIENTEXTENDEDRECOVERY_CD = f8                                                           ; 058 08/03/2018 New
           with constant(uar_get_code_by("DISPLAYKEY", 200, "PLACEINOUTPATIENTEXTENDEDRECOVERY"))
declare PLACEINOUTPATIENTOBSERVATION_CD = f8                                                                ; 058 08/03/2018 New
           with constant(uar_get_code_by("DISPLAYKEY", 200, "PLACEINOUTPATIENTOBSERVATION"))
declare TRANSFERLEVELOFCAREORLOCATION_CD = f8                                                               ; 058 08/03/2018 New
           with constant(uar_get_code_by("DISPLAYKEY", 200, "TRANSFERLEVELOFCAREORLOCATION"))

;--------------------------------------------------------------------------------------------------------------------
; 071 07/22/2022  These are the 4 new ADT orders
declare mf8_placeinoutpatientextendedrecoveryme = f8            ; Place in Outpatient Extended Recovery-MedStar Health
            with constant(uar_get_code_by("DISPLAYKEY",200,"PLACEINOUTPATIENTEXTENDEDRECOVERYME"))
declare mf8_transferlevelofcareorlocationmedst = f8             ; Transfer Level of Care or Location-MedStar Health
            with constant(uar_get_code_by("DISPLAYKEY",200,"TRANSFERLEVELOFCAREORLOCATIONMEDST"))
declare mf8_placeinoutpatientobservationmedstar = f8            ; Place in Outpatient Observation-MedStar Health
            with constant(uar_get_code_by("DISPLAYKEY",200,"PLACEINOUTPATIENTOBSERVATIONMEDSTAR"))
declare mf8_admittoinpatientmedstarhealth = f8                  ; Admit to Inpatient-MedStar Health
            with constant(uar_get_code_by("DISPLAYKEY",200,"ADMITTOINPATIENTMEDSTARHEALTH"))
;--------------------------------------------------------------------------------------------------------------------



/******************************************************************************
*     PATIENT INFORMATION                                                     *
******************************************************************************/

select into "nl:"
from person p,
     encounter e,
     ;person_alias pa,;035
     encntr_alias ea_mrn,
     encntr_alias ea,
     encntr_prsnl_reltn epr,
     prsnl pl,
    (dummyt d1 with seq = 1),
    (dummyt d2 with seq = 1),
    (dummyt d3 with seq = 1)
  ,encntr_loc_hist elh
  ,time_zone_r t
plan p
  where p.person_id = request->person_id
join e
  where e.encntr_id = request->order_qual[1].encntr_id
join elh
  where elh.encntr_id = e.encntr_id
join t
  where t.parent_entity_id = outerjoin(elh.loc_facility_cd)
   and t.parent_entity_name = outerjoin("LOCATION")
join d1
;035
join ea_mrn
  where ea_mrn.encntr_id = e.encntr_id
    and ea_mrn.encntr_alias_type_cd = mrnnbr_cd
    and ea_mrn.active_ind = 1
    and ea_mrn.beg_effective_dt_tm < cnvtdatetime(curdate,curtime3)
    and ea_mrn.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)

/*
join pa
  where pa.person_id = p.person_id
    and pa.person_alias_type_cd = mrn_alias_cd
    and pa.active_ind = 1
    and pa.beg_effective_dt_tm < cnvtdatetime(curdate,curtime3)
    and pa.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
*/
join d2
join ea
  where ea.encntr_id = e.encntr_id
    and ea.encntr_alias_type_cd = fnbr_cd
    and ea.active_ind = 1
    ;035
    and ea.beg_effective_dt_tm < cnvtdatetime(curdate,curtime3)
    and ea.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
join d3
join epr
  where epr.encntr_id = e.encntr_id
    and (epr.encntr_prsnl_r_cd = admit_doc_cd
         or epr.encntr_prsnl_r_cd = attend_doc_cd)
    and epr.active_ind = 1
join pl
  where pl.person_id = epr.prsnl_person_id
head report
  person_id = p.person_id
  encntr_id = e.encntr_id
  orders->name = p.name_full_formatted
  orders->sex = uar_get_code_display(p.sex_cd)
  orders->age = cnvtage(p.birth_dt_tm) ;005
  tz_index = datetimezonebyname(trim(t.time_zone))

  orders->dob = format(datetimezone(p.birth_dt_tm, p.birth_tz,2),"mm/dd/yy;;d") ;017
  orders->admit_dt = format(datetimezone(e.reg_dt_tm, tz_index), "mm/dd/yy;;d");013
  orders->facility = uar_get_code_description(e.loc_facility_cd)
  orders->nurse_unit = uar_get_code_display(e.loc_nurse_unit_cd)
  orders->room = uar_get_code_display(e.loc_room_cd)
  orders->bed = uar_get_code_display(e.loc_bed_cd)
  orders->location = concat(trim(orders->nurse_unit),"/",trim(orders->room),"/",
    trim(orders->bed))
  orders->admit_diagnosis = trim(e.reason_for_visit , 3)
  orders->med_service = uar_get_code_display(e.med_service_cd)
 orders->encntr_type = uar_get_code_display(e.encntr_type_cd);045
; orders->isolation = uar_get_code_display(e.isolation_cd)  ;056 02.22.2016         ; 059 10/30/2019  greened out today

head epr.encntr_prsnl_r_cd
  if (epr.encntr_prsnl_r_cd = attend_doc_cd)
;       orders->attending = pl.name_full_formatted  ;   047 04/09/2014  This one line was replaced by the 'if' below'

        if (pl.name_last_key = "UNASSIGNED" and pl.name_first_key = "UNASSIGNED" )
            orders->attending = " "
        else
            orders->attending = pl.name_full_formatted
        endif

  elseif (epr.encntr_prsnl_r_cd = admit_doc_cd)
    orders->admitting = pl.name_full_formatted
  endif
detail
  /*035
  if (pa.person_alias_type_cd = mrn_alias_cd)
    if (pa.alias_pool_cd > 0)
      orders->mrn = cnvtalias(pa.alias,pa.alias_pool_cd)
    else
      orders->mrn = pa.alias
    endif
  endif
  */
  ;035 start
  if(ea_mrn.alias_pool_cd > 0)
    orders->mrn = cnvtalias(ea_mrn.alias,ea_mrn.alias_pool_cd)
  else
     orders->mrn = ea_mrn.alias
  endif
  if (ea.encntr_alias_type_cd = fnbr_cd)
    if (ea.alias_pool_cd > 0)
      orders->fnbr = cnvtalias(ea.alias,ea.alias_pool_cd)
    else
      orders->fnbr = ea.alias
    endif
  endif
with nocounter,outerjoin=d1,dontcare=pa,outerjoin=d2,dontcare=ea,
  outerjoin=d3,dontcare=epr



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 059 10/30/2018  Get the patient's Code Status
;;;                 Based on the Banner Bar
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

select into 'nl:'
from clinical_event ce2
where ce2.person_id = request->person_id
and ce2.encntr_id = request->order_qual[1].encntr_id
and ce2.event_cd =  CODE_STATUS_CD
and ce2.event_end_dt_tm < cnvtdatetime(curdate,curtime3)
and ce2.valid_until_dt_tm between cnvtdatetime(curdate,curtime3) and cnvtdatetime("31-DEC-2100 23:59:59")
and ce2.result_status_cd+8-8 in (25.00, 34.00, 35.00)
and ce2.entry_mode_cd !=  677002.00 ;  powerform_entry_cd ;
and ce2.event_class_cd =  236.00    ;txt_event_class_cd ;
;order by ce2.updt_dt_tm desc                                                               ; 062 07/05/2019 Replaced. See Below
order by ce2.updt_dt_tm                                                                     ; 062 07/05/2019 Replacement
Detail ce2.event_cd
    orders->code_status = trim(ce2.result_val,3)
WITH  NOCOUNTER, orahintcbo("index(ce2 xie9clinical_event")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 059 10/30/2018  Get the patient's Isolation precautions
;;;                 Based on the Banner Bar
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DECLARE ISOLATION_CD  =  f8  WITH  CONSTANT (uar_get_code_by("DISPLAY_KEY",72,"ISOLATIONPRECAUTIONSORDERDETAIL"))
DECLARE isoDisp = vc  with noconstant("")

select into 'nl:'
from clinical_event ce2
where ce2.person_id = request->person_id
and ce2.encntr_id = request->order_qual[1].encntr_id
and ce2.event_cd = ISOLATION_CD
and ce2.event_end_dt_tm < cnvtdatetime(curdate,curtime3)
and ce2.valid_until_dt_tm between cnvtdatetime(curdate,curtime3) and cnvtdatetime("31-DEC-2100 23:59:59")
and ce2.result_status_cd+8-8 in (25.00, 34.00, 35.00)
order by ce2.updt_dt_tm desc
head ce2.event_cd
    isoDisp = trim(ce2.result_val)
WITH  NOCOUNTER, orahintcbo("index(ce2 xie9clinical_event")

SET isoDisp = replace(isoDisp, "Standard Precautions", "")
SET isoDisp = replace(isoDisp, "Not Ordered", "")
;SET isoDisp = replace(isoDisp, " Precautions", "")
SET isoDisp = replace(isoDisp, "not resulted", "")

IF(TEXTLEN(TRIM(isoDisp,3)) != 0)
    set orders->isolation = trim(isoDisp,3)
endif




/*****************************************************************************
*     CLINICAL EVENT INFORMATION                                             *
******************************************************************************/

set height_cd = uar_get_code_by("DISPLAYKEY", 72, "HEIGHTLENGTHDOSING") ;033 01/07/2013  These two variables are now set...
set weight_cd = uar_get_code_by("DISPLAYKEY", 72, "WEIGHTDOSING")       ;                ...using different event_cd's.

;set height_cd = uar_get_code_by("DISPLAYKEY", 72, "CLINICALHEIGHT")      ; replaced with above 'set'. ;005 BEGIN
;set weight_cd = uar_get_code_by("DISPLAYKEY", 72, "CLINICALWEIGHT")      ; replaced with above 'set'.

;select into "nl:"
;from code_value cv
;plan cv
;  where cv.code_set = 72
;    and cv.display_key in ("CLINICALHEIGHT","CLINICALWEIGHT")
;    and cv.active_ind = 1
;detail
;  case (cv.display_key)
;  of "CLINICALHEIGHT":
;    height_cd = cv.code_value
;  of "CLINICALWEIGHT":
;    weight_cd = cv.code_value
;  endcase
;with nocounter
;005 END   ;<<<<<<<<<<<<<<<  See? This is where 005 ended.

select into "nl:"
from clinical_event c
plan c
  where c.person_id = person_id
;   and c.encntr_id = encntr_id  ;005
    and c.event_cd in (height_cd,weight_cd)
    and c.view_level = 1
    and c.publish_flag = 1
    and c.valid_until_dt_tm = cnvtdatetime("31-DEC-2100,00:00:00")
    and c.result_status_cd != inerror_cd
order c.event_end_dt_tm
detail
  if (c.event_cd = height_cd)
    orders->height = concat(trim(c.event_tag)," ",
      trim(uar_get_code_display(c.result_units_cd)))
  elseif (c.event_cd = weight_cd)
    orders->weight = concat(trim(c.event_tag)," ",
      trim(uar_get_code_display(c.result_units_cd)))
  endif
foot report                 ; 047 04/09/2014  This foot report is new.
  if (cnvtupper(orders->height) = "NOT DONE*")
        orders->height = "Not Done"
        orders->weight = " "
  endif

with nocounter


;056

/******************************************************************************
*     FIND LAST CHARTED CREATININE VALUE FOR PATIENT                         *
******************************************************************************/
;THIS SELECT IS SPECIFIC TO THE GUH PERIPHERALLY INSERTED CENTRAL CATHETER INSERTION
;ORDERABLE.  ;056

select into "nl:"

from
    clinical_event ce

plan ce
    where ce.person_id =person_id
    and ce.event_id =  (select MAX(ce2.event_id)
                FROM  clinical_event ce2
                where ce2.event_cd =       2700655.00   ;CREATININE
                and ce2.person_id = person_id
                AND   ce2.result_status_cd IN (25.00, 34.00, 35.00)     ;(cvAUTH, cvMODIFIED)
                and ce2.verified_dt_tm between cnvtdatetime(curdate-365,curtime3) and cnvtdatetime(curdate,curtime3)
             )

detail

    orders->creat = concat(trim(ce.result_val)," ",trim(uar_get_code_display(ce.result_units_cd)))
    orders->creat_date = ce.verified_dt_tm

with nocounter

/******************************************************************************
*     Find last charted non african american gfr value for patient      ; 070 06/20/2022 Replaced
*     Find last charted GFR Universal value for patient                 ; 070 06/20/2022 Replacement
******************************************************************************/
; This select is specific to the GUH peripherally inserted central catheter insertion

select into "nl:"

from
    clinical_event ce

plan ce
    where ce.person_id =person_id
    and ce.event_id =  (select MAX(ce2.event_id)
                FROM  clinical_event ce2
;               where ce2.event_cd =     7817880.00 ; NON AFRICAN AMERICAN GFR          ; 070 06/20/2022 Replaced
                where ce2.event_cd =  3247177021.00 ; GFR Universal                     ; 070 06/20/2022 Replacement
                  and ce2.person_id = person_id
                  and ce2.result_status_cd IN (25.00, 34.00, 35.00)     ;(cvAUTH, cvMODIFIED)
                with nocounter
             )
detail
    orders->GFR = concat(trim(ce.result_val)," ",trim(uar_get_code_display(ce.result_units_cd)))
    orders->gfr_date = ce.verified_dt_tm

with nocounter

;;/******************************************************************************
;;*     Find last charted african american gfr value for patient        ; 070 06/20/2022 Removed. See above for replacement
;;******************************************************************************/
;; This select is specific to the GUH peripherally inserted central catheter insertion
;;
;;select into "nl:"
;;
;;from
;;  clinical_event ce
;;
;;plan ce
;;      where ce.person_id =person_id
;;  and ce.event_id =  (select MAX(ce2.event_id)
;;              FROM  clinical_event ce2
;;              where ce2.event_cd =  7817876.00    ;AFRICAN AMERICAN GFR
;;              and ce2.person_id = person_id
;;              AND   ce2.result_status_cd IN (25.00, 34.00, 35.00)     ;(cvAUTH, cvMODIFIED)
;;           )
;;
;;detail
;;
;;  orders->GFRAA = concat(trim(ce.result_val)," ",trim(uar_get_code_display(ce.result_units_cd)))
;;  orders->gfrAA_date = ce.verified_dt_tm
;;
;;with nocounter

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
  if (size(n.source_string,1) > 0 or size(a.substance_ftdesc,1) > 0)     ;027
    allergy->cnt = allergy->cnt + 1
    stat = alterlist(allergy->qual,allergy->cnt)
    allergy->qual[allergy->cnt].list = a.substance_ftdesc
    if (size(n.source_string,1) > 0)     ;027
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
   set max_length = 86
   execute dcp_parse_text value(allergy->line), value(max_length)
   set stat = alterlist(allergy->line_qual, pt->line_cnt)
   set allergy->line_cnt = pt->line_cnt
   for (x = 1 to pt->line_cnt)
     set allergy->line_qual[x].line = pt->lns[x].line
   endfor
endif
;040 SDS116
/******************************************************************************
*     FIND DIAGNOSIS AND CREATE DIAGNOSIS LINE                           *
******************************************************************************/

select into "nl:"
     priority_seq = (if (DG.CLINICAL_DIAG_PRIORITY < 1)                         ; 060 12/07/2018 new
                          999                                                   ; 060 12/07/2018 new
                     else                                                       ; 060 12/07/2018 new
                          DG.CLINICAL_DIAG_PRIORITY                             ; 060 12/07/2018 new
                     endif)                                                     ; 060 12/07/2018 new
from ;(dummyt d with seq = 1),
  DIAGNOSIS DG

;plan D

;plan DG
  where DG.encntr_id = encntr_id
  and dg.classification_cd = 674232.00;Medical mod 041
  and dg.confirmation_status_cd = 3305.00 ;Confirmed mod 041
order by priority_seq                                                           ; 060 12/07/2018 There was no "order by"
head report
  DIAGNOSIS->cnt = 0
detail
    DIAGNOSIS->cnt = DIAGNOSIS->cnt + 1
    stat = alterlist(DIAGNOSIS->qual,DIAGNOSIS->cnt)
    DIAGNOSIS->qual[DIAGNOSIS->cnt].diag = DG.diagnosis_display

with nocounter;,outerjoin=d

for (x = 1 to DIAGNOSIS->cnt)
  if (x = 1)
    set DIAGNOSIS->dline = diagnosis->qual[x].diag
  else
    set diagnosis->dline = concat(trim(diagnosis->dline),"; ", trim(diagnosis->qual[x].diag))
  endif
endfor

if (diagnosis->cnt > 0)
   set pt->line_cnt = 0
   set max_length = 106                                     ; 074 11/16/2022  This is now 106. It was 86
   execute dcp_parse_text value(diagnosis->dline), value(max_length)
   set stat = alterlist(diagnosis->dline_qual, pt->line_cnt)
   set diagnosis->dline_cnt = pt->line_cnt
   for (x = 1 to pt->line_cnt)
     set diagnosis->dline_qual[x].dline = pt->lns[x].line
   endfor
endif


/******************************************************************************
*     USED FOR THE MNEMONIC ON PHARMACY ORDERS                                *
******************************************************************************/
;040sds116

/******************************************************************************
*     USED FOR THE MNEMONIC ON PHARMACY ORDERS                                *
******************************************************************************/

set mnem_disp_level = "1"
set iv_disp_level = "0"

if (pharm_flag = 1)
   select into "nl:"
   from name_value_prefs n,app_prefs a
   plan n
     where n.pvc_name in ("MNEM_DISP_LEVEL","IV_DISP_LEVEL")
   join a
     where a.app_prefs_id = n.parent_entity_id
       and a.prsnl_id = 0
       and a.position_cd = 0
   detail
     if (n.pvc_name = "MNEM_DISP_LEVEL"
     and n.pvc_value in ("0","1","2"))
       mnem_disp_level = n.pvc_value
     elseif (n.pvc_name = "IV_DISP_LEVEL"
     and n.pvc_value in ("0","1"))
       iv_disp_level = n.pvc_value
     endif
   with nocounter
endif

/******************************************************************************
*     ORDER LEVEL INFORMATION                                                 *
******************************************************************************/
declare oiCnt = i4 with protect, noconstant(0)
set ord_cnt = 0
set oiCnt = 0                                       ;026
set max_length = 70                                 ;018


;*****************************************************************************************************
; 078 12/19/2022   This select is for FSMC's Pulse Oximetry with exercise order
; 084 02/26/2025   This is getting work... changing orders... adding locations...
;*****************************************************************************************************

;084-> We have a prod vs build mismatch here... so... have to handle that
declare pulse_oxi_cat_cd = f8 with protect, noconstant(0.0)

if (curdomain = "P41") set pulse_oxi_cat_cd = 5660625365.00
else                   set pulse_oxi_cat_cd = 4567207055.00
endif
;084<-

select into "nl:"

  from orders o
     , encounter e

  plan o
   where o.encntr_id       =  request->order_qual[1].encntr_id
     and o.person_id       =  request->person_id
     and o.order_id        =  request->order_qual[1].order_id ; Using [1]. This may need to be adjusted if order(s) are sent here.
     ;084-> Removing this order and moving to a new one.
     ;and o.catalog_cd      =  3883394.00                      ; Pulse Oximetry with Exercise
     and o.catalog_cd      =  pulse_oxi_cat_cd                 ; Ambulating Pulse Ox RT
     ;084<- Removing this order and moving to a new one.
     and o.order_status_cd in ( 2542.00        ; Canceled
                              , 2545.00        ; Discontinued
                              )
     and o.active_ind      =  1
  
  join e
   where e.encntr_id       =  o.encntr_id
     ;084-> Removing this to add a new Fac
     ;and e.loc_facility_cd = 633867.00 ; Franklin Square
     and e.loc_facility_cd in ( 633867.00         ; Franklin Square
                              , 446795444.00      ; MMMC
                              )
     ;084<-
                              
Detail
    ;084-> Killing this in order to make it more in line with the order we are looking for.
    ;orders->qual[1].pulse_oxi_with_exer_ord_ind = 1 ; Using [1]. This may need to be adjusted if order(s) are sent here.
    orders->qual[1].pulse_oxi_ord_ind           = 1 ; Using [1]. This may need to be adjusted if order(s) are sent here.
          
    

    ;call pause(2)   ; Let's slow things down before we look for an "ordered" order created with the Discontined/canceled order
    ;call pause(2)   ; Let's slow things down before we look for an "ordered" order created with the Discontined/canceled order
    ;084<-
with nocounter

;084 It doesn't like these in the query any more.
call pause(2)   ; Let's slow things down before we look for an "ordered" order created with the Discontined/canceled order
call pause(2)   ; Let's slow things down before we look for an "ordered" order created with the Discontined/canceled order

If (    request->print_prsnl_id < 10.00  ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition
    ;084-> Killing this in order to make it more in line with the order we are looking for.
    ;and orders->qual[1].pulse_oxi_with_exer_ord_ind = 1
    and orders->qual[1].pulse_oxi_ord_ind = 1
    ;084<-
   )

    ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
    ; We are now looking for a matching, re-order for this same encounter. If one is found,
    ; we will only print the re-order. We will not print the discontinue/cancel.
    ;
    ; 079 01/10/2023 The above discontinue/cancel must come before the re-order for the discontinue/cancel to be suppressed.
    ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
    select into "nl:"
      from orders o
         , encounter e
      
      plan o
        where o.encntr_id         =  request->order_qual[1].encntr_id
          and o.person_id         =  request->person_id
;         and o.order_id          !=  request->order_qual[1].order_id     ; 079 01/10/2023  Replaced with the below line
              ; 079 01/10/2023  Below line. (only suppress the printing of the cancel/discontinue if it came BEFORE the Re-order order)
          and o.order_id          >  request->order_qual[1].order_id
              ;084-> Killing this
              ;o.catalog_cd        =  3883394.00       ; Pulse Oximetry with Exercise
          and o.catalog_cd        =  pulse_oxi_cat_cd ; Ambulating Pulse Ox RT
              ;084<-
          and o.order_status_cd   =  2550.00 ; Ordered
          and o.orig_order_dt_tm  >  cnvtlookbehind("1,MIN")
          and o.orig_order_dt_tm  >= cnvtlookbehind("2,MIN", cnvtdatetime(orders->oa_action_dt_tm))
          and o.orig_order_dt_tm  <= cnvtlookahead ("2,MIN", cnvtdatetime(orders->oa_action_dt_tm))
          and o.active_ind        =  1
    join e
        where e.encntr_id = o.encntr_id
        ;084-> Removing this to add a new Fac
          ;and e.loc_facility_cd = 633867.00 ; Franklin Square
          and e.loc_facility_cd in ( 633867.00         ; Franklin Square
                                   , 446795444.00      ; MMMC
                                   )
        ;084<-
    Detail
        orders->qual[1].another_new_order_ind = 1   ; NOTE: 1 means the printing of the cancel/discontinue will be suppressed.
    with nocounter

endif

;*****************************************************************************************************



select into "nl:"
from  orders o,
      order_catalog oc,                                         ;  039  05/28/2013
      encounter e,                                              ; #030
      order_action oa,
      prsnl pl,
      prsnl pl2,
      ;oe_format_fields oef,
      (dummyt d1 with seq = value(order_cnt)),
      (dummyt d2 with seq = value(order_cnt)),
      order_ingredient oi                           ;026
plan d1
join o
  where o.order_id = request->order_qual[d1.seq].order_id
join oc                                                         ;  039  05/28/2013
  where o.catalog_cd = oc.catalog_cd                            ;  039  05/28/2013
join e                                                           ; #030
  where e.encntr_id = o.encntr_id                                ; #030
join oa
;;  where oa.order_id = o.order_id                                                          ; 061 06/14/2019 Replaced below
;;    and ((myrequest->order_qual[d1.seq].conversation_id > 0 and    ;025                   ; 061 06/14/2019 Replaced below
;;          oa.order_conversation_id = myrequest->order_qual[d1.seq].conversation_id) or    ; 061 06/14/2019 Replaced below
;;          (myrequest->order_qual[d1.seq].conversation_id <= 0 and                         ; 061 06/14/2019 Replaced below
;;           oa.action_sequence = o.last_action_sequence))                                  ; 061 06/14/2019 Replaced below
  where oa.order_id = o.order_id                                                            ; 061 06/14/2019 Replacement
    and oa.action_sequence = o.last_action_sequence                                         ; 061 06/14/2019 Replacement
join pl
  where pl.person_id = oa.action_personnel_id
join pl2
  where pl2.person_id = oa.order_provider_id
join d2
  join oi where o.order_id = oi.order_id                            ;026
    and o.last_ingred_action_sequence = oi.action_sequence          ;026

order by o.oe_format_id, o.activity_type_cd, o.current_start_dt_tm

head report
  orders->order_location = trim(uar_get_code_display(oa.order_locn_cd))
  mnemonic_size = size(o.hna_order_mnemonic,3) - 1  ;019

head o.order_id
  ord_cnt = ord_cnt + 1
  orders->qual[ord_cnt].status = uar_get_code_display(o.order_status_cd)
  orders->qual[ord_cnt].catalog = uar_get_code_display(o.catalog_type_cd)
  orders->qual[ord_cnt].catalog_type_cd = o.catalog_type_cd
  orders->qual[ord_cnt].activity = uar_get_code_display(o.activity_type_cd)
  orders->qual[ord_cnt]->activity_type_cd = o.activity_type_cd
  orders->qual[ord_cnt].display_line = o.clinical_display_line
  orders->qual[ord_cnt].order_id = o.order_id
  orders->qual[ord_cnt].display_ind = 1
  orders->qual[ord_cnt].template_order_flag = o.template_order_flag
  orders->qual[ord_cnt].cs_flag = o.cs_flag
  orders->qual[ord_cnt].oe_format_id = o.oe_format_id
  orders->qual[ord_cnt].catalog_cd = o.catalog_cd               ;056

  if (size(substring(245,10,o.clinical_display_line),1) > 0)     ;027
    orders->qual[ord_cnt].clin_line_ind = 1
  else
    orders->qual[ord_cnt].clin_line_ind = 0
  endif

  ;BEGIN 019
  mnem_length = size(trim(o.hna_order_mnemonic),1)
  if (mnem_length >= mnemonic_size
      and SUBSTRING(mnem_length - 3, mnem_length, o.hna_order_mnemonic) != "...")
    orders->qual[ord_cnt].mnemonic = concat(cnvtupper(trim(o.hna_order_mnemonic)), "...")
  else
    orders->qual[ord_cnt].mnemonic = cnvtupper(trim(o.hna_order_mnemonic))
  endif
  ;END 019
;019  orders->qual[ord_cnt].mnemonic = cnvtupper(trim(o.hna_order_mnemonic))

  if (CURUTC>0);Begin 016
    orders->qual[ord_cnt].order_dt =  datetimezoneformat(oa.order_dt_tm, oa.order_tz, "MM/dd/yy HH:mm ZZZ")  ;022
  else
    orders->qual[ord_cnt].order_dt = format(oa.order_dt_tm, "mm/dd/yy hh:mm;;d")
  endif ;END 016

  if (CURUTC>0) ;Begin 020
    orders->qual[ord_cnt].signed_dt = datetimezoneformat(o.orig_order_dt_tm, o.orig_order_tz, "MM/dd/yy HH:mm ZZZ") ;022
  else
    orders->qual[ord_cnt].signed_dt = format(o.orig_order_dt_tm, "mm/dd/yy hh:mm;;d")
  endif ;End 020

  orders->qual[ord_cnt].comment_ind = o.order_comment_ind
  orders->qual[ord_cnt].last_action_seq = o.last_action_sequence
  orders->qual[ord_cnt].enter_by = pl.name_full_formatted
  orders->qual[ord_cnt].order_dr = pl2.name_full_formatted
  orders->qual[ord_cnt].type = uar_get_code_display(oa.communication_type_cd)
  orders->qual[ord_cnt].action_type_cd = oa.action_type_cd
  orders->qual[ord_cnt].action = uar_get_code_display(oa.action_type_cd)
  orders->qual[ord_cnt].iv_ind = o.iv_ind
  if (o.dcp_clin_cat_cd = iv_cd)
    orders->qual[ord_cnt].iv_ind = 1
  endif

  head oi.comp_sequence                                                             ;026
   if (oi.comp_sequence >0 and o.med_order_type_cd = intermittent_cd)               ;026
     ;if the order ingredient is a diluent  and is clinically significant           ;026
     if (oi.ingredient_type_flag = 2 and oi.clinically_significant_flag = 2)        ;026
       oiCnt = oiCnt + 1                                                            ;026
       ;if the order ingredient is a additive                                       ;026
     else if (oi.ingredient_type_flag = 3)                                          ;026
       oiCnt = oiCnt + 1                                                            ;026
     endif                                                                          ;026
    endif                                                                           ;026
  endif                                                                             ;026

  foot o.order_id                                                                                                   ;026
  if (o.catalog_type_cd = pharmacy_cd)                                                                              ;026
    if (o.iv_ind = 1 or (o.med_order_type_cd = intermittent_cd and oiCnt > 1) )                                     ;026
      if (iv_disp_level = "1")                                                                                      ;026
        ;if the display text is larger then the print area , add the '...' at the end                               ;026
        mnem_length = size(trim(o.ordered_as_mnemonic),1)                                                           ;026
        if (mnem_length > max_length)                                                                               ;026
          orders->qual[ord_cnt].mnemonic = trim(concat(substring(1, max_length-3, o.ordered_as_mnemonic), "..."))   ;026
        else                                                                                                        ;026
          orders->qual[ord_cnt].mnemonic = o.ordered_as_mnemonic                                                    ;026
        endif                                                                                                       ;026
      else                                                                                                          ;026
        ;if the display text is larger then the print area , add the '...' at the end                               ;026
        mnem_length = size(trim(o.hna_order_mnemonic),1)                                                            ;026
        if (mnem_length > max_length)                                                                               ;026
          orders->qual[ord_cnt].mnemonic = trim(concat(substring(1, max_length-3, o.hna_order_mnemonic), "..."))    ;026
        else                                                                                                        ;026
          orders->qual[ord_cnt].mnemonic = o.hna_order_mnemonic                                                     ;026
        endif                                                                                                       ;026
      endif                                                                                                         ;026
  else                                                                                                              ;026
    if (mnem_disp_level = "0")
      ;BEGIN 019
      mnem_length = size(trim(o.hna_order_mnemonic),1)
      if (mnem_length >= mnemonic_size
          and SUBSTRING(mnem_length - 3, mnem_length, o.hna_order_mnemonic) != "...")
        orders->qual[ord_cnt].mnemonic = concat(trim(o.hna_order_mnemonic), "...")
      else
        orders->qual[ord_cnt].mnemonic = trim(o.hna_order_mnemonic)
      endif
      ;END 019
;019      orders->qual[ord_cnt].mnemonic = trim(o.hna_order_mnemonic)
    endif
    if (mnem_disp_level = "1")
      if (o.hna_order_mnemonic = o.ordered_as_mnemonic
      or size(o.ordered_as_mnemonic,1) = 0)     ;027
        ;BEGIN 019
        mnem_length = size(trim(o.hna_order_mnemonic),1)
        if (mnem_length >= mnemonic_size
            and SUBSTRING(mnem_length - 3, mnem_length, o.hna_order_mnemonic) != "...")
          orders->qual[ord_cnt].mnemonic = concat(trim(o.hna_order_mnemonic), "...")
        else
          orders->qual[ord_cnt].mnemonic = trim(o.hna_order_mnemonic)
        endif
        ;END 019
;019        orders->qual[ord_cnt].mnemonic = trim(o.hna_order_mnemonic)
      else
        ;BEGIN 019
        mnem_length = size(trim(o.hna_order_mnemonic),1)
        if (mnem_length >= mnemonic_size
            and SUBSTRING(mnem_length - 3, mnem_length, o.hna_order_mnemonic) != "...")
          orders->qual[ord_cnt].mnemonic = concat(trim(o.hna_order_mnemonic), "...")
        else
          orders->qual[ord_cnt].mnemonic = trim(o.hna_order_mnemonic)
        endif

        mnem_length = size(trim(o.ordered_as_mnemonic),1)
        if (mnem_length >= mnemonic_size
            and SUBSTRING(mnem_length - 3, mnem_length, o.ordered_as_mnemonic) != "...")
          orders->qual[ord_cnt].mnemonic = concat(orders->qual[ord_cnt].mnemonic,"(",trim(o.ordered_as_mnemonic),"...)")
        else
          orders->qual[ord_cnt].mnemonic = concat(orders->qual[ord_cnt].mnemonic,"(",trim(o.ordered_as_mnemonic),")")
        endif
        ;END 019
;019        orders->qual[ord_cnt].mnemonic = concat(trim(o.hna_order_mnemonic),"(",trim(o.ordered_as_mnemonic),")")
      endif
    endif
    if (mnem_disp_level = "2" and o.iv_ind != 1)
      if (o.hna_order_mnemonic = o.ordered_as_mnemonic
      or size(o.ordered_as_mnemonic,1) = 0)     ;027
        ;BEGIN 019
        mnem_length = size(trim(o.hna_order_mnemonic),1)
        if (mnem_length >= mnemonic_size
            and SUBSTRING(mnem_length - 3, mnem_length, o.hna_order_mnemonic) != "...")
          orders->qual[ord_cnt].mnemonic = concat(trim(o.hna_order_mnemonic), "...")
        else
          orders->qual[ord_cnt].mnemonic = trim(o.hna_order_mnemonic)
        endif
        ;END 019
;019        orders->qual[ord_cnt].mnemonic = trim(o.hna_order_mnemonic)
      else
        ;BEGIN 019
        mnem_length = size(trim(o.hna_order_mnemonic),1)
        if (mnem_length >= mnemonic_size
            and SUBSTRING(mnem_length - 3, mnem_length, o.hna_order_mnemonic) != "...")
          orders->qual[ord_cnt].mnemonic = concat(trim(o.hna_order_mnemonic), "...")
        else
          orders->qual[ord_cnt].mnemonic = trim(o.hna_order_mnemonic)
        endif

        mnem_length = size(trim(o.ordered_as_mnemonic),1)
        if (mnem_length >= mnemonic_size
            and SUBSTRING(mnem_length - 3, mnem_length, o.ordered_as_mnemonic) != "...")
          orders->qual[ord_cnt].mnemonic = concat(orders->qual[ord_cnt].mnemonic,"(",trim(o.ordered_as_mnemonic),"...)")
        else
          orders->qual[ord_cnt].mnemonic = concat(orders->qual[ord_cnt].mnemonic,"(",trim(o.ordered_as_mnemonic),")")
        endif
        ;END 019
;019        orders->qual[ord_cnt].mnemonic = concat(trim(o.hna_order_mnemonic),"(",trim(o.ordered_as_mnemonic),")")
      endif
      if (o.order_mnemonic != o.ordered_as_mnemonic and size(o.order_mnemonic,1) > 0)     ;027
        ;BEGIN 019
        mnem_length = size(trim(o.order_mnemonic),1)
        if (mnem_length >= mnemonic_size
            and SUBSTRING(mnem_length - 3, mnem_length, o.order_mnemonic) != "...")
          orders->qual[ord_cnt].mnemonic = concat(trim(orders->qual[ord_cnt].mnemonic),"(",trim(o.order_mnemonic),"...)")
        else
          orders->qual[ord_cnt].mnemonic = concat(trim(orders->qual[ord_cnt].mnemonic),"(",trim(o.order_mnemonic),")")
        endif
        ;END 019
;019        orders->qual[ord_cnt].mnemonic = concat(trim(orders->qual[ord_cnt].mnemonic),"(",trim(o.order_mnemonic),")")
      endif
    endif
  endif
 endif                                                                                          ;026

  if (oa.action_type_cd in (order_cd, suspend_cd, resume_cd, cancel_cd, discont_cd, void_cd))   ;026
    orders->qual[ord_cnt].fmt_action_cd = oa.action_type_cd
  else
    orders->qual[ord_cnt].fmt_action_cd = order_cd
  endif

/*****************************************************************************
 *Put logic in here if you want to keep certain types of orders to not print *
 *May be things like complete orders/continuing orders/etc..                 *
 *****************************************************************************/

IF ( oa.action_type_cd in (order_cd)
      AND o.encntr_id>0                                                                             ;052 - added
        and o.catalog_cd  =         2780651.00      ;CPM Application order - do not print child orders
              and o.template_order_id != 0.00)

        orders->qual[ord_cnt].display_ind = 0  ;  do not Print this requisition
        ;orders->spoolout_ind = 0

; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
; 067 02/14/2021
; Print any of these 4 Admit/Discharge/Transfer (ADT) orders/requistions for Montgomery Medical Center (MMC) when
; they are cancelled or discontinued by a human being, rather than by SYSTEM, SYSTEM. Up to now, they
; would not print, because the default in this program/script is to not print cancelled or discontinued
; orders.
; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
elseif (oa.action_type_cd in (cancel_cd, discont_cd) and
        oa.action_personnel_id >= 8.00 and        ; 1.00 is SYSTEM SYSTEM  (Let's use 8.00 though)
        o.encntr_id > 0 and
        o.catalog_cd in ( 101851470.00,     ;   Admit to Inpatient
                          101851509.00,     ;   Place in Outpatient Observation
                         1788750081.00,     ;   Place in Short Stay (Post Procedure)
                          101815625.00) and ;   Transfer Level of Care or Location
        e.loc_facility_cd = MMC_FACILITY_CD)
            orders->qual[ord_cnt].display_ind = 1  ; Print this requisition
            orders->spoolout_ind = 1

ELSEIF ( oa.action_type_cd in (order_cd)
      AND o.encntr_id>0                                                                             ;053 - added
        and o.catalog_cd  =   101937715.00  ;Modified Barium Swallow
        and e.loc_facility_cd = GSH_FACILITY_CD
        and (e.loc_nurse_unit_cd =     4369695.00 ;gsh 4WST
            or e.encntr_type_cd =     5045671.00 ;recurring outpatient
            ))

        orders->qual[ord_cnt].display_ind = 0  ;  do not Print this requisition
        ;orders->spoolout_ind = 0


ELSEIF ( oa.action_type_cd in (cancel_cd,discont_cd)
      AND o.encntr_id>0                                                                             ;051 - added
        and o.catalog_cd  =  113627414.00           ;Calorie Count
         AND e.loc_facility_cd = NRH_FACILITY_CD)

        orders->qual[ord_cnt].display_ind = 1  ; Print this requisition
        orders->spoolout_ind = 1

;-----------------------------------------------------------------------------------------------
; 078 12/19/2022  New for FSMC's Pulse Oximetry with Exercise requisitions
;-----------------------------------------------------------------------------------------------

elseif (oa.action_type_cd in (cancel_cd, discont_cd)
        and o.encntr_id       > 0
        
        ;084-> Big work here, new cat code, and new location.
        ;and o.catalog_cd = 3883394.00               ; Pulse Oximetry with Exercise
        ;and e.loc_facility_cd = 633867.00)          ; Franklin Square
        and o.catalog_cd      =  pulse_oxi_cat_cd          ; Ambulating Pulse Ox RT
        and e.loc_facility_cd in ( 633867.00         ; Franklin Square
                                 , 446795444.00      ; MMMC
                                 )
        )
        ;084<-
        

            If (request->print_prsnl_id < 10.00 and  ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition
                orders->qual[ord_cnt].another_new_order_ind = 0) ; 0 means that there was not a re-order within the last minute or so
                    orders->qual[ord_cnt].display_ind = 1  ; print this requisition
                    orders->spoolout_ind = 1
            endif

            If (request->print_prsnl_id > 10.00)  ; when > 10, we know that a human is generating the requisition manually
                    orders->qual[ord_cnt].display_ind = 1  ; print this requisition
                    orders->spoolout_ind = 1
            endif
            ; -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -

;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------


;MOD063 START
ELSEIF ( oa.action_type_cd in (cancel_cd, discont_cd)
      AND o.encntr_id>0
        and o.catalog_cd  = 101806820.00            ;Consult to Palliative Care
         AND e.loc_facility_cd = MMC_FACILITY_CD)

        orders->qual[ord_cnt].display_ind = 1  ; Print this requisition
        orders->spoolout_ind = 1
;MOD063 END


ELSEIF ( oa.action_type_cd in (cancel_cd, discont_cd, void_cd)                                              ;058  08/03/2018 - New 'elseif'  another one is below
     and o.encntr_id > 0
     and o.catalog_cd in (  ADMITTOINPATIENT_CD,                          ; 101851470.00
                            CHANGEATTENDINGPROVIDERTO_CD,                 ; 101851441.00
                            PLACEINOUTPATIENTEXTENDEDRECOVERY_CD,         ; 101851532.00
                            PLACEINOUTPATIENTOBSERVATION_CD,              ; 101851509.00
                            TRANSFERLEVELOFCAREORLOCATION_CD,             ; 101815625.00
                            mf8_placeinoutpatientextendedrecoveryme,                                        ; 071 07/22/2022 New
                            mf8_transferlevelofcareorlocationmedst,                                         ; 071 07/22/2022 New
                            mf8_placeinoutpatientobservationmedstar,                                        ; 071 07/22/2022 New
                            mf8_admittoinpatientmedstarhealth)                                              ; 071 07/22/2022 New

     and e.loc_facility_cd in (GSH_FACILITY_CD,
                               4363156.00)                                ; Union Memorial Hospital
     and oa.action_personnel_id >= 8.00)                                  ; 1.00 is SYSTEM SYSTEM  (Let's use 8.00 though)

        orders->qual[ord_cnt].display_ind = 1  ; Print this requisition
        orders->spoolout_ind = 1

ELSEIF ( oa.action_type_cd in (order_cd)                                                            ; 044 - in
      AND o.encntr_id>0                                                                             ; 044 - in
      AND o.template_order_flag != 7    ; ( 7 = Protocol)                                           ; 044 - in
      AND (o.catalog_cd not in (TUBEFEEDINGADDITIVES_CAT_CD,    ; 101816336.00                      ; 044 - in
                                TUBEFEEDINGBOLUS_CAT_CD)        ; 101816417.00                      ; 044 - in
                                or                                                                  ; 044 - in
             (o.catalog_cd  in (TUBEFEEDINGADDITIVES_CAT_CD,    ; 101816336.00                      ; 044 - in
                                TUBEFEEDINGBOLUS_CAT_CD) and    ; 101816417.00                      ; 044 - in
              o.template_order_id = 0.00)                                                           ; 044 - in
           )                                                                                        ; 044 - in
   )                                                                                                ; 044 - in
                                                                                                    ; 044 - in
     orders->qual[ord_cnt].display_ind = 1  ;  Print this requisition                               ; 044 - in
     orders->spoolout_ind = 1                                                                       ; 044 - in

;083 no print for MMC, Negative Pressure Wound Discontinue order
ELSEIF
        (oa.action_type_cd in (order_cd)
        and e.encntr_type_cd =     5048231.00 ; amb surg
        and o.catalog_cd IN (101806105) ; neg pressure wound d/c, specialty bed
        and e.loc_facility_cd = MMC_FACILITY_CD
        )
                orders->qual[ord_cnt].display_ind = 0
;083 END mod

ELSEIF ( oa.action_type_cd in (modify_cd,activate_cd,studactivate_cd)                               ;             039 - in
      AND o.encntr_id>0                                                                             ; 037 - in
      AND o.template_order_flag != 7    ; ( 7 = Protocol)                                           ; 037 - in
      AND (e.loc_facility_cd != FSH_FACILITY_CD or o.catalog_cd != CONSULT_PSYCHIATRY_CD)           ; 037 - in
      AND o.catalog_cd != CONSULT_WOUND_OSTOMY_NURSE_CD                                             ;             038 - in
      )                                                                                             ; 037 - in
                                                                                                    ; 037 - in
     orders->qual[ord_cnt].display_ind = 1  ;  Print this requisition                               ; 037 - in
     orders->spoolout_ind = 1                                                                       ; 037 - in

; 039  05/28/2013  Below is just one part of #039. We want to suppress the printing
;                  of certain Diet orders for discontinued and cancelled orders. Cancels
;                  used to be handled above, but now they're handled below. Discontinued
;                  orders are handled even farther below.

ELSEIF ( oa.action_type_cd in (cancel_cd)                                                           ; 039 - in
      AND o.encntr_id>0                                                                             ; 039 - in
      AND o.template_order_flag != 7        ; ( 7 = Protocol)                                       ; 039 - in
      AND (e.loc_facility_cd != FSH_FACILITY_CD or o.catalog_cd != CONSULT_PSYCHIATRY_CD)           ; 039 - in < copied from above
      AND o.catalog_cd != CONSULT_WOUND_OSTOMY_NURSE_CD                                             ; 039 - in < copied from above
      AND (oc.requisition_format_cd != DCPREQGEN02_FORMAT_CD or         ; Not = -or-                ; 039 - in
           oc.catalog_type_cd != FOODANDNUTRITIONSERVICES_CD or         ; Not = -or-                ; 039 - in
           oc.activity_type_cd in (SNACKS_CD, TUBEFEEDING_CD,           ; in the list               ; 039 - in
                                   TUBEFEEDINGADDITVIVES_CD, TUBEFEEDINGWATERFLUSH_CD)              ; 039 - in
          )                                                                                         ; 039 - in
      )                                                                                             ; 039 - in
                                                                                                    ; 039 - in
     orders->qual[ord_cnt].display_ind = 1  ;  Print this requisition                               ; 039 - in
     orders->spoolout_ind = 1                                                                       ; 039 - in


                                                                                                    ; 037 - in
ELSEIF ( oa.action_type_cd in (modify_cd,cancel_cd,activate_cd,studactivate_cd,discont_cd)          ; 037 - in
      AND o.encntr_id>0                                                                             ; 037 - in
      AND o.template_order_flag != 7        ; ( 7 = Protocol)                                       ; 037 - in
;;;;  AND e.loc_facility_cd = FSH_FACILITY_CD                                                       ; 037 - in ;;; 038 - out
;;;;  AND o.catalog_cd = CONSULT_PSYCHIATRY_CD                                                      ; 037 - in ;;; 038 - out
      AND (                                                                                         ;;;;;;;;;; 038 - in
            (e.loc_facility_cd = FSH_FACILITY_CD AND o.catalog_cd = CONSULT_PSYCHIATRY_CD)          ;;;;;;;;;; 038 - in
               OR                                                                                   ;;;;;;;;;; 038 - in
            (o.catalog_cd = CONSULT_WOUND_OSTOMY_NURSE_CD)                                          ;;;;;;;;;; 038 - in
          )                                                                                         ;;;;;;;;;; 038 - in
   )                                                                                                ; 037 - in
                                                                                                    ; 037 - in
     orders->qual[ord_cnt].display_ind = 0 ;  Do NOT print this requisition                         ; 037 - in


ELSEIF (oa.action_type_cd = discont_cd and
;;;     o.catalog_cd = CONSULT_NUTRITION_CD and   ;;;;;;;;;; 034 01/11/2013   replaced with line below.  <<<<<<<<<<<<<<<

;;;     o.catalog_cd in(CONSULT_NUTRITION_CD_A, CONSULT_NUTRITION_CD_B)  and  ;;;; #043 we are adding 3 more catalog_cds. This...
                                                                              ;;;;      ... line is being replaced and appended.
        o.catalog_cd in(CONSULT_NUTRITION_CD_A, CONSULT_NUTRITION_CD_B,
                        CONSULT_NUTRITION_FROM_MD_CD,CONSULT_NUTRITION_PED_CD,
                        RN_NUTRITION_CONSULT_CD))
;;;     e.loc_facility_cd = GSH_FACILITY_CD)                                  ;;;; #043  We are no longer looking at facility.
                                                                              ;;;;       This now applies to all.

             orders->qual[ord_cnt].display_ind = 0 ;  Do NOT print this requisition

ELSEIF (oa.action_type_cd = discont_cd and
        o.catalog_cd = CONSULT_SLEEP_APNEA_CD and
        e.loc_facility_cd = HHC_FACILITY_CD)

             orders->qual[ord_cnt].display_ind = 0 ;  Do NOT print this requisition

ELSEIF (oa.action_type_cd = discont_cd and
        o.catalog_cd = CONSULT_PAST_SPIRIT_CD)

             orders->qual[ord_cnt].display_ind = 0 ;  Do NOT print this requisition

;-----------------------------------------
;;; 039  05/28/2013  Brian Twardy
;;; To filter out the Diet orderables...
;;; - Must have Catalog Type of  "Food and Nutrition Services"
;;; - Must have Requisition Format of "DCPREQGEN02"
;;; - Must NOT have one of the following Activity Types:
;;;     - Snacks
;;;     - Tube Feeding Additives
;;;     - Tube Feeding
;;;     - Tube Feeding Water Flush
;----------------------------------------

ELSEIF (oa.action_type_cd in (discont_cd, cancel_cd) and
        oc.requisition_format_cd = DCPREQGEN02_FORMAT_CD and                                    ; 039 - in
        oc.catalog_type_cd = FOODANDNUTRITIONSERVICES_CD and                                    ; 039 - in
        oc.activity_type_cd  != SNACKS_CD and                                                   ; 039 - in
        oc.activity_type_cd  != TUBEFEEDING_CD and                                              ; 039 - in
        oc.activity_type_cd  != TUBEFEEDINGADDITVIVES_CD and                                    ; 039 - in
        oc.activity_type_cd  != TUBEFEEDINGWATERFLUSH_CD                                        ; 039 - in
       )                                                                                        ; 039 - in
                                                                                                ; 039 - in
             orders->qual[ord_cnt].display_ind = 0 ;  Do NOT print this requisition             ; 039 - in

;-----------------------------------------
;;; 036  04/23/2013  Brian Twardy
;;; For 'Consult to Psychiatry', when the discontinue action is the result of the system,
;;; such as a patient discharge would do, rather than a manual discontinue action that would be
;;; performed by a human being directly, then Do NOT print this requisition.
;-----------------------------------------

ELSEIF (oa.action_type_cd = discont_cd and
        o.catalog_cd = CONSULT_PSYCHIATRY_CD AND        ; 101817871.00 is Consult to Psychiatry
        oa.action_personnel_id <= 1.00)                 ; 1.00 is SYSTEM SYSTEM

             orders->qual[ord_cnt].display_ind = 0 ;  Do NOT print this requisition

;-----------------------------------------
;042 BDG100 BEG suppress printing of ED Bed Request Req for GoodSam if disc/canc/discharged
elseif(o.catalog_cd = ED_BED_REQUEST_CD
        and e.loc_facility_cd = GSH_FACILITY_CD
        and oa.action_type_cd in(discont_cd, cancel_cd))

    orders->qual[ord_cnt].display_ind = 0

;042 BDG100 END


;;;-----------------------------------------
;;; 050  09/22/2014  Brian Twardy
;;;
;;; #049 below has been commented out today and replaced with #50. We are only adding onto
;;; #049, but I wanted to show what was here, before #050. That's why #049 has been totally
;;; replaced, and not just enhanced.
;-----------------------------------------

;;;; 049 ;;; 6/17/2014 JJK - Print 3 particular NRH orders to print when discontinued
;
;elseif(o.catalog_cd IN (ASSISTWITHMEALS_CD, ONETOONESUPER_CD, TOTALASSISTWITHFEEDING_CD)
;       and e.loc_facility_cd = NRH_FACILITY_CD
;       and oa.action_type_cd in(discont_cd))
;
;   orders->qual[ord_cnt].display_ind = 1
;   orders->spoolout_ind = 1

;;;;; end of 049

;;;-----------------------------------------
;;; 050  09/22/2014  Brian Twardy
;;;
;;; For 'Assist with Meals', '1 to 1 Supervision with Meals', and 'Total Assistance with Feeding',
;;; we want to print the requisition as we were doing with modification # 049
;;;      --PLUS---
;;;  Also look for the following condition(s), because we want to print the requisition then too:
;;;  when the the action_type is 'Status change' and the order_status is 'Completed'
;-----------------------------------------

ELSEIF ( o.catalog_cd IN (ASSISTWITHMEALS_CD, ONETOONESUPER_CD, TOTALASSISTWITHFEEDING_CD) and
         e.loc_facility_cd = NRH_FACILITY_CD
         and
        (oa.action_type_cd = discont_cd                             ; 2532.00
             or
         (oa.action_type_cd = action_type_status_change_cd and      ; 2539.00
          o.order_status_cd = order_status_completed_cd)))          ; 2543.00   Note that this is from the order table. Later, when...
                                                                    ;           we print the banner, we'll be looking in a record structure...
                                                                    ;           for this status, and that will have been loaded from orders, not...
                                                                    ;           from order_action. (They should match, but... let's just be...
                                                                    ;           sure and look in orders here, since that's what's in the ...
                                                                    ;           record structure.)
                orders->qual[ord_cnt].display_ind = 1
                orders->spoolout_ind = 1

;;; - - - - - - - 050 ends here.  - - - - - - - - - - - - - - - - - - - - -

;082  print for discontinued specialty bed order (email)
 ELSEIF
        (
        o.catalog_cd =101815498.00 ;  specialty bed
        and e.loc_facility_cd = GUH_FACILITY_CD                                 ;4363210.00
        and oa.action_type_cd  = order_cd
        and trim(request->printer_name) = "yydummy"
        )
                orders->qual[ord_cnt].display_ind = 1
                orders->spoolout_ind = 1
; end 082
;

ELSEIF (oa.action_type_cd = discont_cd and
        o.encntr_id>0 and
;        o.template_order_flag != 7 and         ; ( 7 = Protocol)
        oa.action_personnel_id <= 1.00)         ; 1.00 is SYSTEM SYSTEM

             orders->qual[ord_cnt].display_ind = 0 ;  Do NOT Print this requisition
             orders->spoolout_ind = 0

;055 start
ELSEIF
        (
        o.catalog_cd IN (ADMITTOINPATIENT_CD,                                   ;101851470.00
                         mf8_admittoinpatientmedstarhealth)                                     ; 071 07/22/2022 new
        and e.loc_facility_cd = GUH_FACILITY_CD                                 ;4363210.00
        and (oa.action_type_cd = discont_cd)                                    ; 2532.00
        )
                orders->qual[ord_cnt].display_ind = 1
                orders->spoolout_ind = 1
;055 end

;;;-----------------------------------------
;;; 057  10/27/2017  Brian Twardy
;;; Canceled or discontinued "Peripherally Inserted Central Catheter Insertion" orders, canceled or discontinued by
;;; anyone other than System, System will PRINT.... but only at MGUH
;-----------------------------------------

ELSEIF ( oa.action_type_cd in (cancel_cd, discont_cd) and
         o.encntr_id > 0 and
         o.catalog_cd  =  2780697.00 and            ; Peripherally Inserted Central Catheter Insertion
         e.loc_facility_cd = GUH_FACILITY_CD and    ; 4363210.00
         oa.action_personnel_id > 1.00)             ; 1.00 is SYSTEM SYSTEM

            orders->qual[ord_cnt].display_ind = 1   ; Print this requisition
            orders->spoolout_ind = 1

 ;081 print for GUH, Negative Pressure Wound Discontinue order
ELSEIF
        (
        o.catalog_cd IN (101806105) ; neg pressure wound d/c, specialty bed
        and e.loc_facility_cd = GUH_FACILITY_CD                                 ;4363210.00
        )
                orders->qual[ord_cnt].display_ind = 1
                orders->spoolout_ind = 1

ELSE    ;Nothing should fall through to here, but in case it does... do not print the requisitiuon.

     orders->qual[ord_cnt].display_ind = 0 ;  Do NOT print this requisition

ENDIF

;      orders->qual[ord_cnt].display_ind = 1 ; 05/17/2014   Just for testing  !!!!!!!!!!!!!!!!!!!!!
;      orders->spoolout_ind = 1              ; 05/17/2014   Just for testing  !!!!!!!!!!!!!!!!!!!!!



;;;IF(O.catalog_cd IN (62170870.00, 62170831.00, 62170820.00, 62170826.00))             ; 060 12/07/2018  This line..... out
if (o.catalog_cd in ( 101851470.00,     ; Admit to Inpatient                            ; 060 12/07/2018  These lines... in
                      101851509.00,     ; Place in Outpatient Observation               ; 060 12/07/2018  These lines... in
                     1788750081.00,     ; Place in Short Stay (Post Procedure)          ; 060 12/07/2018  These lines... in
                     3807959815.00,     ; Admit to Inpatient-MedStar Health                     ; 074 11/16/2022 New
                     3808005117.00,     ; Place in Outpatient Extended Recovery-MedStar Health  ; 074 11/16/2022 New
                     3808056467.00,     ; Place in Outpatient Observation-MedStar Health        ; 074 11/16/2022 New
                     3808061269.00,     ; Transfer Level of Care or Location-MedStar Health     ; 074 11/16/2022 New
                      468416338.00,     ; Status Change - Inpatient Admission to Outpatient Extended R  ; 076 11/30/2022 New
                      187950822.00,     ; Status Change - Inpatient to Outpatient Observation           ; 076 11/30/2022 New
                      468505675.00,     ; Status Change - Outpatient Extended Recovery to Inpatient Ad  ; 076 11/30/2022 New
                      187950990.00,     ; Status Change - Outpatient Observation to Inpatient           ; 076 11/30/2022 New
                      468507580.00)     ; Status Change - Outpatient Observation to Outpatient Extende  ; 076 11/30/2022 New


    and                                                                                 ; 060 12/07/2018  These lines... in
    e.loc_facility_cd in (SMHC_FACILITY_CD  , MMC_FACILITY_CD, STMARYS_FACILITY_CD))    ; 060 12/07/2018 MOD065 Add St. Marys
        print_diag_flag = 1
endif

;056 start
    ;only display the creatinine and GFR results if the following qualifications are true

    if (o.catalog_cd in (2780697.00) and e.loc_facility_cd =  4363210.00)   ;PICC and Georgetown
;   if (o.catalog_cd in (2780697.00) and e.loc_facility_cd in (4363210.00,                                  ; 070 06/20/2022 TESTING
;                                                              GSH_FACILITY_CD))    ;PICC and Georgetown    ; 070 06/20/2022 TESTING
            disp_creatGFR = 1
    endif

;056 end

;075_begin
IF  ( (oa.action_type_cd in (modify_cd)) ;075
and ( o.catalog_cd in ( mf8_admittoinpatientmedstarhealth ) )
and ( oa.COMMUNICATION_TYPE_CD = 680281.00 ) ;discernrule
and ( oa.action_personnel_id = 1.0)  ;system
;078 12/19/2022 New See below. When < 10, we know that SYSTEM, SYSTEM is generating the requisition. It is not a re-print.
and (request->print_prsnl_id < 10.00))              ; 078 12/19/2022  New line
            orders->qual[ord_cnt].display_ind = 0   ; do not print admit if order modified by rule
            orders->spoolout_ind = 0
endif ;075_end

with outerjoin = d2, nocounter


;;; #032 11/28/2012   The above 'If' statement replaced the one above it.
;;;                   The 'one above it' was from 11/14/2012.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


/******************************************************************************
*  GET ORDER DETAIL INFORMATION                                               *
******************************************************************************/

select into "nl:"
from order_detail od,
     oe_format_fields oef,
     order_entry_fields of1,
     (dummyt d1 with seq = value(order_cnt))
plan d1
  join od
    where orders->qual[d1.seq].order_id = od.order_id
    and od.oe_field_meaning_id not in ( 2071.00,    ; ADHOCFREQINSTANCE           ; 069 02/14/2022 New. Take note of the 'not in'
                                        2097.00)    ; DIFFINMIN                   ; 069 02/14/2022 New. Take note of the 'not in'
  join oef
    where oef.oe_format_id = orders->qual[d1.seq].oe_format_id
      and oef.action_type_cd = orders->qual[d1.seq].fmt_action_cd
      and oef.oe_field_id = od.oe_field_id
  join of1
    where of1.oe_field_id = oef.oe_field_id
  order by od.order_id, od.oe_field_id, od.action_sequence desc

;if order details need to print in the order on the format...try this order by
; order by od.order_id,oef.group_seq,oef.field_seq,od.oe_field_id,
;          od.action_sequence desc

  head report
    orders->qual[d1.seq].d_cnt = 0
  head od.order_id
    stat = alterlist(orders->qual[d1.seq].d_qual,5)
    orders->qual[d1.seq].stat_ind = 0
  head od.oe_field_id
    act_seq = od.action_sequence
    odflag = 1
    if (od.oe_field_meaning = "COLLPRI" or
        od.oe_field_meaning = "PRIORITY")
      orders->qual[d1.seq].priority = od.oe_field_display_value
    endif
    if (od.oe_field_meaning = "REQSTARTDTTM")
      if (CURUTC>0) ;Begin 020
        ;Begin 021
        orders->qual[d1.seq].req_st_dt = datetimezoneformat(od.oe_field_dt_tm_value, od.oe_field_tz, "MM/dd/yy HH:mm ZZZ") ;022
        ;End 021
      else
        orders->qual[d1.seq].req_st_dt = format(od.oe_field_dt_tm_value, "mm/dd/yy hh:mm;;d")
      endif ;End 020
    endif
    if (od.oe_field_meaning = "FREQ")
      orders->qual[d1.seq].frequency = od.oe_field_display_value
    endif
    if (od.oe_field_meaning = "RATE")
      orders->qual[d1.seq].rate = od.oe_field_display_value
    endif
    if (od.oe_field_meaning = "DURATION")
      orders->qual[d1.seq].duration = od.oe_field_display_value
    endif
    if (od.oe_field_meaning = "DURATIONUNIT")
      orders->qual[d1.seq].duration_unit = od.oe_field_display_value
    endif
    if (od.oe_field_meaning = "NURSECOLLECT")
      orders->qual[d1.seq].nurse_collect = od.oe_field_display_value
    endif
  head od.action_sequence
    if (act_seq != od.action_sequence)
      odflag = 0
    endif
  detail
    if (odflag = 1)
      orders->qual[d1.seq].d_cnt=orders->qual[d1.seq].d_cnt+1
      dc = orders->qual[d1.seq].d_cnt
      if (dc > size(orders->qual[d1.seq].d_qual,5))
        stat = alterlist(orders->qual[d1.seq].d_qual,dc + 5)
      endif
      orders->qual[d1.seq].d_qual[dc].label_text = trim(oef.label_text)
      orders->qual[d1.seq].d_qual[dc].field_value=od.oe_field_value
      orders->qual[d1.seq].d_qual[dc].group_seq = oef.group_seq
      orders->qual[d1.seq].d_qual[dc].oe_field_meaning_id = od.oe_field_meaning_id
      if (od.oe_field_dt_tm_value != NULL) ;Begin 020
        if (CURUTC>0)
          orders->qual[d1.seq].d_qual[dc].value = datetimezoneformat(od.oe_field_dt_tm_value, od.oe_field_tz,
               "MM/dd/yy HH:mm ZZZ") ;022
        else
          orders->qual[d1.seq].d_qual[dc].value = format(od.oe_field_dt_tm_value, "mm/dd/yy hh:mm;;d")
        endif
      else
        orders->qual[d1.seq].d_qual[dc].value = trim(od.oe_field_display_value,3)     ;027
      endif ;End 020
      orders->qual[d1.seq].d_qual[dc].clin_line_ind = oef.clin_line_ind
      orders->qual[d1.seq].d_qual[dc].label =trim(oef.clin_line_label)
      orders->qual[d1.seq].d_qual[dc].suffix = oef.clin_suffix_ind
      orders->qual[d1.seq].d_qual[dc].field_type_flag = of1.field_type_flag
      if (size(od.oe_field_display_value,1) > 0)     ;027
        orders->qual[d1.seq].d_qual[dc].print_ind = 0
      else
        orders->qual[d1.seq].d_qual[dc].print_ind = 1
      endif
      if ((od.oe_field_meaning_id = 1100
           or od.oe_field_meaning_id = 8
           or OD.OE_FIELD_MEANING_ID = 127
           or od.oe_field_meaning_id = 43)
           and trim(cnvtupper(od.oe_field_display_value),3) = "STAT")     ;027
        orders->qual[d1.seq].stat_ind = 1
      endif

      ;056

      ;if particular order entry fields should not be printed on the requisition, they can be added here:

     if (disp_creatGFR = 1)         ;if the order is PICC

      if ((od.oe_field_id in (12775.00  ;adhoc frequency instance
                            , 633592    ;frequency schedule id
                            , 633595)   ;difference in minutes
            ))

            orders->qual[d1.seq].d_qual[dc].print_ind = 1   ;do not print the order entry fields above on the requisition.
      endif

     endif
      ;056 end

      if (of1.field_type_flag = 7)
        if (od.oe_field_value = 1)
          if (oef.disp_yes_no_flag = 0 or oef.disp_yes_no_flag = 1)
            orders->qual[d1.seq].d_qual[dc].value = trim(oef.label_text)
          else
            orders->qual[d1.seq].d_qual[dc].clin_line_ind = 0
          endif
        else
          if (oef.disp_yes_no_flag = 0 or oef.disp_yes_no_flag = 2)
            orders->qual[d1.seq].d_qual[dc].value = trim(oef.clin_line_label)
          else
            orders->qual[d1.seq].d_qual[dc].clin_line_ind = 0
          endif
        endif
      endif
    endif
  foot od.order_id
    stat = alterlist(orders->qual[d1.seq].d_qual, dc)
  with nocounter

/******************************************************************************
*   BUILD ORDER DETAILS LINE IF IT EXCEEDS 255 CHARACTERS                     *
******************************************************************************/

for (x = 1 to order_cnt)
  if (orders->qual[x].clin_line_ind = 1)
    set started_build_ind = 0
    for (fsub = 1 to 31)
      for (xx = 1 to orders->qual[x].d_cnt)
        if ((orders->qual[x].d_qual[xx].group_seq = fsub or fsub = 31)
             and orders->qual[x].d_qual[xx].print_ind = 0)
;          set orders->qual[x].d_qual[xx].print_ind = 1   ;004
          if (orders->qual[x].d_qual[xx].clin_line_ind = 1)
            if (started_build_ind = 0)
              set started_build_ind = 1
              if (orders->qual[x].d_qual[xx].suffix = 0
                  and size(orders->qual[x].d_qual[xx].label,1) > 0)     ;027
                set orders->qual[x].display_line =
                  concat(trim(orders->qual[x].d_qual[xx].label)," ",
                    trim(orders->qual[x].d_qual[xx].value))
              elseif (orders->qual[x].d_qual[xx].suffix = 1
                      and size(orders->qual[x].d_qual[xx].label,1) > 0)     ;027
                set orders->qual[x].display_line =
                  concat(trim(orders->qual[x].d_qual[xx].value)," ",
                    trim(orders->qual[x].d_qual[xx].label))
              else
                set orders->qual[x].display_line =
                  concat(trim(orders->qual[x].d_qual[xx].value)," ")
              endif
            else
              if (orders->qual[x].d_qual[xx].suffix = 0
                  and size(orders->qual[x].d_qual[xx].label,1) > 0)     ;027
                set orders->qual[x].display_line =
                  concat(trim(orders->qual[x].display_line),",",
                    trim(orders->qual[x].d_qual[xx].label)," ",
                    trim(orders->qual[x].d_qual[xx].value))
              elseif (orders->qual[x].d_qual[xx].suffix = 1
                      and size(orders->qual[x].d_qual[xx].label,1) > 0)     ;027
                set orders->qual[x].display_line =
                  concat(trim(orders->qual[x].display_line),",",
                    trim(orders->qual[x].d_qual[xx].value)," ",
                    trim(orders->qual[x].d_qual[xx].label))
              else
                set orders->qual[x].display_line =
                  concat(trim(orders->qual[x].display_line),",",
                    trim(orders->qual[x].d_qual[xx].value)," ")
              endif
            endif
          endif
        endif
      endfor
    endfor
  endif
endfor

/******************************************************************************
*  LINE WRAPPING FOR ORDER DETAILS                                            *
******************************************************************************/
set max_length = 90
for (x = 1 to order_cnt)

  if (size(orders->qual[x].display_line,1) > 0)     ;027
   set pt->line_cnt = 0
   execute dcp_parse_text value(orders->qual[x].display_line),value(max_length)
   set stat = alterlist(orders->qual[x].disp_ln_qual, pt->line_cnt)
   set orders->qual[x].disp_ln_cnt = pt->line_cnt
   for (y = 1 to pt->line_cnt)
     set orders->qual[x].disp_ln_qual[y].disp_line = pt->lns[y].line
   endfor
  endif

  for (ww = 1 to orders->qual[x]->d_cnt)
    ;check for long strings and possible free text fields that have return characters
    if(orders->qual[x].d_qual[ww].field_type_flag = 0  ;alphanumeric detail
        or orders->qual[x].d_qual[ww].field_type_flag = 11  ;printer detail
        or textlen(trim(orders->qual[x].d_qual[ww].value,3)) > max_length)
        set pt->line_cnt = 0
        execute dcp_parse_text value(orders->qual[x].d_qual[ww].value),value(max_length)
        set stat = alterlist(orders->qual[x].d_qual[ww].value_qual, pt->line_cnt)
        set orders->qual[x].d_qual[ww].value_cnt = pt->line_cnt
        for (y = 1 to pt->line_cnt)
            set orders->qual[x].d_qual[ww].value_qual[y].value_line = pt->lns[y].line
        endfor
    else
        set orders->qual[x].d_qual[ww].value_cnt = 1
    endif
  endfor
endfor

/******************************************************************************
*    GET ACCESSION NUMBER                                                     *
******************************************************************************/

for (x = 1 to order_cnt)
  select into "nl:"
  from accession_order_r aor
  plan aor
    where aor.order_id = orders->qual[x].order_id
  detail
    orders->qual[x].accession = aor.accession
  with nocounter
endfor

/******************************************************************************
*   LINE WRAPPING FOR ORDERABLE                                               *
******************************************************************************/

set max_length = 90
for (x = 1 to order_cnt)
  if (textlen(orders->qual[x].mnemonic) > 0)
   set pt->line_cnt = 0
   execute dcp_parse_text value(orders->qual[x].mnemonic),value(max_length)
   set stat = alterlist(orders->qual[x].mnem_ln_qual, pt->line_cnt)
   set orders->qual[x].mnem_ln_cnt = pt->line_cnt
   for (y = 1 to pt->line_cnt)
     set orders->qual[x].mnem_ln_qual[y].mnem_line = pt->lns[y].line
   endfor
  endif
endfor

/******************************************************************************
*     RETRIEVE ORDER COMMENT AND LINE WRAPPING                                *
******************************************************************************/

set max_length = 120
for (x = 1 to order_cnt)
  if (orders->qual[x].comment_ind = 1)
    select into "nl:"
    from order_comment oc,
      long_text lt
    plan oc
      where oc.order_id = orders->qual[x].order_id
        and oc.comment_type_cd = comment_cd
    join lt
      where lt.long_text_id = oc.long_text_id
    detail
      orders->qual[x].comment = lt.long_text
    with nocounter
    set pt->line_cnt = 0
    execute dcp_parse_text value(orders->qual[x].comment),value(max_length)
    set stat = alterlist(orders->qual[x].com_ln_qual, pt->line_cnt)
    set orders->qual[x].com_ln_cnt = pt->line_cnt
    for (y = 1 to pt->line_cnt)
      set orders->qual[x].com_ln_qual[y].com_line = pt->lns[y].line
    endfor
  endif
endfor

/******************************************************************************
*  SEND TO OUTPUT PRINTER                                                     *
******************************************************************************/

declare new_timedisp = vc with noconstant("")           ; 061 06/12/2019 Finally, this is declared
declare tempfile1a = vc with noconstant("")             ; 061 06/12/2019 Finally, this is declared
declare PRODUCTION_DOMAIN = vc with constant("P41")     ; 061 06/12/2019 we only want emails to go out from Production
declare pft_order_email_ind = i2 with noconstant(0)     ; 068 03/08/2021 0 means print. 1 means email.


;###################################################
#Loop_for_Pulmonary_Function_Testing                    ; 068 03/08/2021  Only the 'Pulmonary Function Testing' order(s) will
;###################################################    ;                 loop back here from below.
                                                        ;                 1st time through, print it. (pft_order_email_ind = 0)
                                                        ;                 2nd time, generate the email(pft_order_email_ind = 1)

if (orders->spoolout_ind = 1)

;set new_timedisp = cnvtstring(curtime3)                                            ; 061 06/12/2019  Greened out today
 set new_timedisp = format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q")    ; 061 06/12/2019  This is better

;set tempfile1a = build(concat("cer_temp:dcpreq", "_",new_timedisp),".dat")         ; 061 06/12/2019  Greened out today
;-----------------------------------------------------------------------------------------------------------------------
; 061 06/12/2019  We want to create a PDF file if we are emailing  --but-- a postscript file if we are printing.
;                 Emailing is being introduced for the first time now, May 2019.
;                 We will only email...
;                   - a small set of orders
;                   - only from WHC
;                   - only when generated automatically and not as a manual re-print from the Orders page
;                   - only from P41 (production)
;-----------------------------------------------------------------------------------------------------------------------

 If (orders->qual[1].catalog_cd in (101851470.00,     ; Admit to Inpatient
                                    155622002.00,     ; Admit to NICU
                                    101851441.00,     ; Change Attending Provider To
                                    996881997.00,     ; Change Primary Care Provider (PCP)
                                    177018848.00,     ; MWHC ED Admit to Inpatient
                                    177194832.00,     ; MWHC ED Place in Outpatient Observation
                                    101851509.00,     ; Place in Outpatient Observation
                                    187950822.00,     ; Status Change - Inpatient to Outpatient Observation
                                    187950990.00,     ; Status Change - Outpatient Observation to Inpatient
                                    101815625.00,     ; Transfer Level of Care or Location
                                    3341919083.00, ;080 add - Update Patient Information
                                    mf8_placeinoutpatientextendedrecoveryme,                        ; 073 11/15/2022 New
                                    mf8_transferlevelofcareorlocationmedst,                         ; 073 11/15/2022 New
                                    mf8_placeinoutpatientobservationmedstar,                        ; 073 11/15/2022 New
                                    mf8_admittoinpatientmedstarhealth) and                          ; 073 11/15/2022 New

     orders->facility = "Washington*Hosp*" and  ; description has been used here
     request->print_prsnl_id < 10.00)  ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition, so make it a PDF file

     If (CURDOMAIN = PRODUCTION_DOMAIN )    ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

        ; 064 01/28/2020 cer_temp not here. We remove PDFs with the linux command after emailing anyway.
        set tempfile1a = build2("dcpreqgen02_", new_timedisp,"_",
                                trim(substring(2,4,cnvtstring(RAND(0)))),       ; Random # generator 4 digits
                                ".pdf")
     Else                               ; If we fell to here (to the "Else"), we must not be in P41 (aka, production)

        go to exit_script               ; Do not send emails from anywhere but from P41. So... jump to the end of this script and leave it.

     Endif

 ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
 ; 068 03/08/2021 This 'Elseif' is new. We will print and email the requisition for a Pulmonary Function Testing order.
 ;                In thie 'Elseif', we will email the requisition. We will loop around and the 2nd time through, we will
 ;                fall through to the 'Else', where the requisition will be printed.
 ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -

 Elseif (orders->qual[1].catalog_cd = 101816483.00 and      ; Pulmonary Function Testing order
         orders->facility = "Union*Memorial*Hospital*" and  ; Description has been used here
         orders->qual[1].action_type_cd = 2534.00 and       ; Order. We only email if this order is being ordered... originally ordered!!
         request->print_prsnl_id < 10.00 and  ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition
         pft_order_email_ind = 1)             ; 0 when we want to print. 1 when we want to email

     If (CURDOMAIN = PRODUCTION_DOMAIN )    ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.

        ;  We remove PDFs with the linux command after emailing anyway.
        set tempfile1a = build2("dcpreqgen02_", new_timedisp,"_",
                                trim(substring(2,4,cnvtstring(RAND(0)))),       ; Random # generator 4 digits
                                ".pdf")
      Else                              ; If we fell to here (to the "Else"), we must not be in P41 (aka, production)

        go to exit_script               ; Look above. See the Elseif?  See the "pft_order_email_ind = 1"?
                                        ; We only dropped to here if we want to email now. It would be the 2nd time through the
                                        ;'#Loop_for_Pulmonary_Function_Testing' loop.
                                        ; So, it's OK to check if we are in P41. It is OK to perform this check:
                                        ; Do not send emails from anywhere but from P41. So... jump to the end of this script and leave it.

     Endif

 ;#081 #082
  Elseif ( (orders->qual[1].catalog_cd =101806105   ;Negative pressure or
            or (orders->qual[1].catalog_cd = 101815498 and orders->qual[1].action_type_cd =order_cd and trim(request->printer_name) = "yydummy")); Specialty Bed discontinued
             and orders->facility = "Georgetown University Hospital"    ; Description has been used here
          and request->print_prsnl_id < 10.00                   ; system generated.  If demanded, they get paper?
         )

     If (CURDOMAIN = PRODUCTION_DOMAIN )    ; CURDOMAIN is a system variable.   PRODUCTION_DOMAIN is ours, and it's declared above.
        ;If (trim(CURDOMAIN) = "B41")
        set tempfile1a = build2("dcpreqgen02_", new_timedisp,"_",
                                trim(substring(2,4,cnvtstring(RAND(0)))),       ; Random # generator 4 digits
                                ".pdf")
     Else                               ; If we fell to here (to the "Else"), we must not be in P41 (aka, production)

        go to exit_script               ; Do not send emails from anywhere but from P41. So... jump to the end of this script and leave it.

     Endif

 ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -

 Else   ;This is for a file for printing the req, not for emailing it.          ; 064 01/28/2020 cer_temp here. We do not later remove
     set tempfile1a = build2("cer_temp:dcpreqgen02_", new_timedisp,"_",         ;       printed files, as we do with emailed ones as above
                              trim(substring(2,4,cnvtstring(RAND(0)))),         ; Random # generator 4 digits
                             ".dat")

 endif

;-----------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------

 set cancel_banner = "************************CANCEL*************************" ;010
 set discont_banner = "********************DISCONTINUED***********************" ;010
 set modify_banner = "***********************MODIFIED************************";010
    ; 050 09/22/2014  The below set created for non-material-managemnet orders, and just a few of them, at that.
 set completed_banner = "*********************COMPLETED**********************"          ; 050  09/22/2014  For action_type of...
                                                                                        ;                  "status change" and...
                                                                                        ;                  order_status of "Completed"

;#########################################################################################################################
 ;Print different format for material management orders
;#########################################################################################################################
 if(orders->qual[1].catalog_type_cd  = MAT_MGMT_CD)
 select into value(tempfile1a)  ; $OUTDEV
; select into $OUTDEV
; select into value(request->printer_name)
; select into "mine"
   d1.seq
 from (dummyt d1 with seq = 1)

 plan d1

 head report

  first_page = "Y"
  saved_pos = 0

 Head Page
  "{LPI/8}{CPI/12}{FONT/4}","  ",row+1
  line1 = fillstring(35,"_"),
  line2 = fillstring(10,"_"),
  spaces = fillstring(50, " ")

  "{CPI/12}{POS/30/45}", "MEDICAL RECORD NUMBER" ,row+1
  "{CPI/10}{POS/35/55}{b}", "*",orders->mrn,"*" ,row+1
  "{CPI/12}{POS/235/45}", "VISIT NUMBER" ,row+1
  "{CPI/10}{POS/240/55}{b}", "*",
  call print(trim(cnvtstring(cnvtint(request->order_qual[1].encntr_id)))),
    "*",row+1
  "{CPI/12}{POS/420/45}", "PATIENT ACCOUNT NUMBER" ,row+1
  "{CPI/10}{POS/440/55}{b}", "*",orders->fnbr,"*",row+1


  "{CPI/12}{POS/30/120}", "PATIENT NAME:",row+1
  "{CPI/10}{POS/150/120}{b}", call print(trim(orders->name,3)),"{endb}", row+1

  "{CPI/12}{POS/30/140}", "ADMIT DATE:  ",row+1
  "{CPI/12}{POS/150/140}", orders->admit_dt,row+1

  "{CPI/12}{POS/30/150}", "NURSING UNIT:", row+1
  "{CPI/12}{POS/150/150}{B}", orders->nurse_unit, "{ENDB}",row+1        ;046 03/25/2014 Here's the modification.
  "{CPI/12}{POS/30/160}", "ROOM/BED:", row+1
  "{CPI/12}{POS/150/160}", orders->room,orders->bed, row+1
  "{CPI/12}{POS/30/335}", "PATIENT NAME:",row+1
  "{CPI/10}{POS/150/335}{b}", call print(trim(orders->name,3)),"{endb}", row+1
  "{CPI/12}{POS/30/355}", "ADMIT DATE:  ",row+1
  "{CPI/12}{POS/150/355}", orders->admit_dt,row+1

  "{CPI/12}{POS/30/365}", "NURSING UNIT:", row+1
  "{CPI/12}{POS/150/365}{B}", orders->nurse_unit, "{ENDB}",row+1        ;046 03/25/2014 Here's the modification.
  "{CPI/12}{POS/30/375}", "ROOM/BED:", row+1
  "{CPI/12}{POS/150/375}", orders->room,orders->bed, row+1

  IF( print_diag_flag = 1)
  "{CPI/12}{POS/30/250}", "DIAGNOSIS:    ","{b}"

  if (DIAGNOSIS->dline_cnt > 0)

    DIAGNOSIS->dline_qual[1].dline, row+1
  endif
  if (diagnosis->dline_cnt > 1)

    "{POS/97/260}", "{b}", diagnosis->dline_qual[2].dline                   ; 074 11/16/2022  This is now 97. It was 110
  endif

  if (diagnosis->dline_cnt > 2)
    "{CPI/12}", "{b}", " ..." ,row+1
    "{POS/160/280}", "{b}", "**** See patient chart for additional diagnosis information ****", row+1
  endif   ;008

  endif
  ;040 sds116

;***mnem box
  "{CPI/10}{POS/20/263}{BOX/75/2}",ROW+1
  "{CPI/8}{POS/25/268}{color/20/145}",ROW+1
  "{CPI/8}{POS/25/275}{color/20/145}",ROW+1
  "{CPI/8}{POS/25/282}{color/20/145}",ROW+1
  "{CPI/8}{POS/25/285}{color/20/145}",ROW+1

  "{CPI/12}{POS/330/355}{B}", "ORDER DATE/TIME:"
  "{CPI/12}{POS/330/365}", "ORDERING MD:","{endb}",row+1
  "{CPI/12}{POS/330/375}",  "ORDER ENTERED BY:",ROW+1
  "{CPI/12}{POS/330/385}", "ORDER NUMBER:" ,row+1

  if (saved_pos > 0)
    "{CPI/10}{POS/1/90}"," ",
    "{CPI/10}{b}",
;    call center(orders->facility,1,190) ;011                       ; 046 03/25/2014   Centering more towards the center below.
    call center(orders->facility,1,215) ;011                        ; 046 03/25/2014   Here is the new centering.
    ;011orders->qual[save_vv]->catalog,",  ",orders->qual[save_vv]->activity),1,190)
    row+1

; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
; 077 12/09/2022 The one line below has been replaced with the following "If", "Elseif", "Else" today
;
;   "{CPI/8}{POS/30/278}{b}", "ORDER:  ", orders->qual[saved_pos].mnemonic, row+1

    If (textlen(trim(orders->qual[saved_pos].mnemonic)) > 72)
        "{CPI/13}{POS/30/278}{b}", "ORDER:  ", orders->qual[saved_pos].mnemonic, row+1
    Elseif (textlen(trim(orders->qual[saved_pos].mnemonic)) > 68)
        "{CPI/11}{POS/30/278}{b}", "ORDER:  ", orders->qual[saved_pos].mnemonic, row+1
    Else
        "{CPI/8}{POS/30/278}{b}", "ORDER:  ", orders->qual[saved_pos].mnemonic, row+1
    Endif
; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    "{CPI/10}{POS/450/355}", orders->qual[saved_pos].order_dt, row+1
    "{CPI/12}{POS/450/365}", orders->qual[saved_pos].order_dr,row+1
    "{CPI/12}{POS/450/375}", orders->qual[saved_pos].enter_by,ROW+1
    "{CPI/12}{POS/450/385}", call print(trim(cnvtstring(cnvtint(orders->qual[saved_pos]->order_id)))) ,row+1

;054 commented line below out, replaced with two lines below.
;   "{CPI/12}{POS/30/735}", "ORDER    ", "{CPI/9}{B}",orders->qual[saved_pos].mnemonic ;014

;054 added two lines below to replace the line above.

; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
; 077 12/09/2022 The one line below has been replaced with the following "If", "Elseif", "Else" today
;
;   "{CPI/12}{POS/30/715}", "ORDER    ", "{CPI/9}{B}",orders->qual[saved_pos].mnemonic, row + 1;014

    If (textlen(trim(orders->qual[saved_pos].mnemonic)) > 72 )
        "{CPI/12}{POS/30/715}", "ORDER    ", "{CPI/13}{B}",orders->qual[saved_pos].mnemonic, row + 1
    Elseif (textlen(trim(orders->qual[saved_pos].mnemonic)) > 68)
        "{CPI/12}{POS/30/715}", "ORDER    ", "{CPI/11}{B}",orders->qual[saved_pos].mnemonic, row + 1
    Else
        "{CPI/12}{POS/30/715}", "ORDER    ", "{CPI/9}{B}",orders->qual[saved_pos].mnemonic, row + 1
    Endif
; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    "{CPI/12}{POS/30/730}", "ACTIVITY TYPE    ", "{CPI/9}{B}",orders->qual[saved_pos].activity
    saved_pos = 0
  endif

 detail
 ;018  for (VV = 1 to VALUE(order_cnt))
 for (VV = 1 to VALUE(ord_cnt));018
  if (orders->qual[VV].display_ind = 1)
    go_ahead_and_print  = 1

    if (go_ahead_and_print = 1)
      spoolout = 1
      if (first_page = "N")
        break
      endif
      if (orders->qual[vv]->action_type_cd = cancel_cd)
        "{CPI/12}{POS/130/75}{B}", cancel_banner,row+1      ; 046 03/25/2014   Centering more towards the center. Replacement
      elseif (orders->qual[vv]->action_type_cd = discont_cd)
        "{CPI/12}{POS/130/75}{B}", discont_banner,row+1     ; 046 03/25/2014   Centering more towards the center. Replacement
      elseif (orders->qual[vv]->action_type_cd = modify_cd)
        "{CPI/12}{POS/130/75}{B}", modify_banner,row+1      ; 046 03/25/2014   Centering more towards the center. Replacement
      endif

      first_page = "N"

      "{CPI/10}{POS/1/90}"," ",
      "{CPI/10}{b}",
      call center(orders->facility,1,215) ;011                      ; 046 03/25/2014   Here is the new centering.

; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
; 077 12/09/2022 The one line below has been replaced with the following "If", "Elseif", "Else" today
;
;   "{CPI/8}{POS/30/278}{b}", "ORDER:  ", orders->qual[vv].mnemonic, row+1

    If (textlen(trim(orders->qual[vv].mnemonic)) > 72)
        "{CPI/13}{POS/30/278}{b}", "ORDER:  ", orders->qual[vv].mnemonic, row+1
    Elseif (textlen(trim(orders->qual[vv].mnemonic)) > 68)
        "{CPI/11}{POS/30/278}{b}", "ORDER:  ", orders->qual[vv].mnemonic, row+1
    Else
        "{CPI/8}{POS/30/278}{b}", "ORDER:  ", orders->qual[vv].mnemonic, row+1
    Endif
; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

      "{CPI/10}{POS/450/355}", orders->qual[vv].order_dt, row+1
      "{CPI/12}{POS/450/365}", orders->qual[vv].order_dr,row+1
      "{CPI/12}{POS/450/375}", orders->qual[vv].enter_by,ROW+1
      "{CPI/12}{POS/450/385}", call print(trim(cnvtstring(cnvtint(orders->qual[vv]->order_id)))) ,row+1
    "{CPI/12}{POS/30/715}", "ORDER    ", "{CPI/9}{B}",orders->qual[vv].mnemonic, row + 1;014
    "{CPI/12}{POS/30/730}", "ACTIVITY TYPE    ", "{CPI/9}{B}",orders->qual[vv].activity

      xcol=330
      ycol=140                              ; 047 04/09/2014  We are moving this down to the level of the ADMIT DATE
      for (fsub = 1 to 31)
        for (ww = 1 to orders->qual[vv]->d_cnt)
          if ((orders->qual[vv].d_qual[ww]->group_seq = fsub)
          or (fsub = 31 and orders->qual[vv]->d_qual[ww]->print_ind = 0))
            orders->qual[vv]->d_qual[ww]->print_ind = 1


            if (textlen(trim(orders->qual[vv].d_qual[ww].value,3)) > 0)
                "{ENDB}{CPI/13}",call print(calcpos(xcol,ycol)),
                call print(orders->qual[vv].d_qual[ww].label_text),"  ",row+1
                xcol = 450
                if(orders->qual[vv].d_qual[ww].value_cnt > 1)
                    for (dsub = 1 to orders->qual[vv].d_qual[ww].value_cnt)
                        call print (calcpos(xcol,ycol)) "{b}",orders->qual[vv].d_qual[ww].value_qual[dsub].value_line,"{endb}",
                        row+1
                        ycol = ycol + 12

                        if (ycol > 600 and dsub < orders->qual[vv].d_qual[ww].value_cnt)
                            call print (calcpos(xcol,ycol)),"**Continued on next page**"
                            saved_pos = vv
                            break
                            xcol = 330
                            ycol = 180;040 381
                            "{CPI/13}",call print(calcpos(xcol,ycol)),
                             call print(concat(orders->qual[vv].d_qual[ww].label_text, " cont. "))
                            xcol = 450
                        endif

                    endfor
                else
                    call print (calcpos(xcol,ycol)) "{b}",orders->qual[vv].d_qual[ww].value,"{endb}", row +1
                    ycol = ycol + 12
                endif
                xcol = 330
            endif
          endif
          if (ycol > 600 and ww < orders->qual[vv]->d_cnt)
            saved_pos = vv
            break
            ycol = 421;040 381
          endif
        endfor
      endfor

      /******************************************************************************/

      xcol=30
      ycol=395
      for (fsub = 1 to 31)
        for (ww = 1 to orders->qual[vv]->d_cnt)
          if ((orders->qual[vv].d_qual[ww]->group_seq = fsub)
          or (fsub = 31 and orders->qual[vv]->d_qual[ww]->print_ind = 0))
            orders->qual[vv]->d_qual[ww]->print_ind = 1


            if (textlen(trim(orders->qual[vv].d_qual[ww].value,3)) > 0)
                "{CPI/13}",call print(calcpos(xcol,ycol)),
                call print(orders->qual[vv].d_qual[ww].label_text),"  ",row+1
                xcol = 150
                if(orders->qual[vv].d_qual[ww].value_cnt > 1)
                    for (dsub = 1 to orders->qual[vv].d_qual[ww].value_cnt)
                        call print (calcpos(xcol,ycol)) "{b}",orders->qual[vv].d_qual[ww].value_qual[dsub].value_line,"{endb}",
                        row+1
                        ycol = ycol + 12

                        if (ycol > 600 and dsub < orders->qual[vv].d_qual[ww].value_cnt)
                            call print (calcpos(xcol,ycol)),"**Continued on next page**"
                            saved_pos = vv
                            break
                            xcol = 30
                            ycol = 421
                            "{CPI/13}",call print(calcpos(xcol,ycol)),
                             call print(concat(orders->qual[vv].d_qual[ww].label_text, " cont. "))
                            xcol = 150
                        endif

                    endfor
                else
                    call print (calcpos(xcol,ycol)) "{b}",orders->qual[vv].d_qual[ww].value,"{endb}", row +1
                    ycol = ycol + 12
                endif
                xcol = 30
            endif
          endif
          if (ycol > 600 and ww < orders->qual[vv]->d_cnt)
            saved_pos = vv
            break
            ycol = 421
          endif
        endfor
      endfor
    endif
    if(ycol > 600)
      saved_pos = vv
      break
      ycol = 421
    else
      ycol = ycol + 12
    endif
    xcol = 30
    if (orders->qual[vv]->comment_ind = 1 and orders->qual[vv]->com_ln_cnt > 0)
        "{CPI/13}"
        call print (calcpos (xcol,ycol)), "Comment "
        if (orders->qual[vv].com_ln_cnt > 7)
            ocnt = 7
        else
            ocnt = orders->qual[vv].com_ln_cnt ;023
        endif
        ycol = ycol + 16
        for (com_cnt = 1 to ocnt)
            call print (calcpos (xcol,ycol)),"{b}", orders->qual[vv].com_ln_qual[com_cnt]->com_line,"{endb}" ;023
            row + 1
            ycol = ycol + 12
        endfor
        if (orders->qual[vv].com_ln_cnt > 7) ;023
          call print (calcpos (xcol,ycol)),
           "{cpi/13}", "**** Please check chart for further comments ****"
        endif
    endif
  endif
 endfor

;foot page 014
;014    "{font/8}{cpi/12}{pos/50/750}","dcpreqgen02"

 with nocounter, maxrow=800, maxcol=800, dio=postscript

;#########################################################################################################################
        ; ------------------------------------------------------------------
 else   ; *********  Print the Non-Material Management requisition  *********
        ; ------------------------------------------------------------------
;#########################################################################################################################
; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
; 069 02/14/2022 The below is to get comments from a charted BLOB... not from an order. This is used for just one order,
;                Updated Emergency Contact.
; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -

 if (orders->qual[1].catalog_cd = UPDATEDEMERGENCYCONTACT_CD)  ; 2826084063.00 in B41  ; 3341919083.00 in P41

    declare ocfcomp_cd = f8 with Constant(uar_get_code_by("MEANING",120,"OCFCOMP")),protect
    declare nocomp_cd = f8 with Constant(uar_get_code_by("MEANING",120,"NOCOMP")),protect
    declare blobout = vc with protect, noconstant(" ")
    declare blobnortf = vc with protect, noconstant(" ")
    declare lb_seg = vc with protect, noconstant(" ")
    declare bsize = i4
    declare corrected_cd            = f8 with Constant(uar_get_code_by("MEANING",1901,"CORRECTED")),protect
    declare verified_cd             = f8 with Constant(uar_get_code_by("MEANING",1901,"VERIFIED")),protect
    declare autoverif_cd            = f8 with Constant(uar_get_code_by("MEANING",1901,"AUTOVERIFIED")),protect
    declare at_glb = f8 with protect,constant(uar_get_code_by("DISPLAYKEY",106,"GENERALLAB"))
    declare crlf                    = vc with Constant(concat(char(13),char(10))),protect
    declare cr                      = vc with Constant(concat(char(13))),protect
    declare lf                      = vc with Constant(concat(char(10))),protect
    declare lab_cd = f8 with constant(uar_get_code_by("DISPLAYKEY",93,"LABORATORY"))
    declare ce_verif_cd = f8 with Constant(uar_get_code_by("MEANING",8,"AUTH")),protect
    declare ce_mod_cd = f8 with Constant(uar_get_code_by("MEANING",8,"MODIFIED")),protect
    declare date_res_cd = f8 with Constant(uar_get_code_by("MEANING",53,"DATE")),protect ;002
    declare event_id = f8

    select into "nl:"
          lenblob = size(ce.blob_contents)
        , c.event_end_dt_tm
        , c_event_disp = uar_get_code_display(c.event_cd)
        , c_event_disp = uar_get_code_display(c.event_cd)
        , c.result_val
        , c_result_status_disp = uar_get_code_display(c.result_status_cd)
        , c.clinical_event_id
        , ce.blob_contents
        , ce.blob_length
        , ce.blob_seq_num
        , compression_disp = uar_get_code_display(ce.compression_cd)
        , event_id = ce.EVENT_ID
    from
        clinical_event   c,
        ce_blob ce
    plan c
        where
            c.person_id = request->person_id and
            c.encntr_id = request->order_qual[1].encntr_id and
            c.event_cd = 823578227.00 and ; Preadm Additional Information
            c.result_status_cd in (25.00, 34.00, 35.00) and
            c.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
    join ce
        where ce.event_id = c.event_id and
              ce.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
    order by c.updt_dt_tm   desc
    head report
     glb_cnt = 0
     blobout = " "
     blobnortf = " "
     bsize = 0
     blobout = notrim(fillstring(32768," "))
     blobnortf = notrim(fillstring(32768," "))
     if(ce.compression_cd = ocfcomp_cd)
        uncompsize = 0
        blob_un = uar_ocf_uncompress(ce.blob_contents, lenblob,
                                    blobout, size(blobout), uncompsize)
        stat = uar_rtf2(blobout,uncompsize,blobnortf,size(blobnortf),bsize,0)
        blobnortf = substring(1,bsize,blobnortf)
     else
        stat = uar_rtf2(ce.blob_contents,lenblob,blobnortf,size(blobnortf),bsize,0)
        blobnortf = substring(1,bsize,blobnortf)
    endif
    with nocounter, separator=" ", format
    
    ;084 Moving this into the if, because we are getting some big grief if these vars aren't declared in the outside code path.
    record blob_line (
    01 cntr = i4
    01 qual [*]
       02 line_num = i4
       02 line = vc
    )

    declare mark_old = i4 with noconstant
    declare mark     = i4 with noconstant

    set mark_old = 1
    set mark = 1
    set cnt = 0
    ;069 02/14/2022  Replace each carriage return/linefeed with something weird... say, "xX". We'll remove them later.
    set blobnortf = replace(blobnortf,crlf,"xX")
    for (cnt = 1 to 30)
     if (mark > 0 and mark_old > 0)
        set stat = alterlist(blob_line->qual, cnt)
        set mark = findstring("xX", blobnortf, mark_old + 1)
        set blob_line->qual[cnt].line =  trim(substring(mark_old, mark - mark_old, blobnortf))
        if (blob_line->qual[cnt].line = "x")  ; 069 02/14/2022 Lines with just a CR/LF will now have just an "x". That's
                                              ;                because on those lines.. mark - mark-old = 1 so the xX will become just x
            set blob_line->qual[cnt].line = ""
        endif
        if (mark < 2)
            set mark_old = 3
        else
            set mark_old = mark
        endif
     endif
    endfor
 endif

; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
; 069 02/14/2022 The above ends here. It picks up again farther below.
; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -

 select

 If (orders->qual[1].catalog_cd in (101851470.00,     ; Admit to Inpatient
                                    155622002.00,     ; Admit to NICU
                                    101851441.00,     ; Change Attending Provider To
                                    996881997.00,     ; Change Primary Care Provider (PCP)
                                    177018848.00,     ; MWHC ED Admit to Inpatient
                                    177194832.00,     ; MWHC ED Place in Outpatient Observation
                                    101851509.00,     ; Place in Outpatient Observation
                                    187950822.00,     ; Status Change - Inpatient to Outpatient Observation
                                    187950990.00,     ; Status Change - Outpatient Observation to Inpatient
                                    101815625.00,     ; Transfer Level of Care or Location
                                    3341919083.00, ;080 add - Update Patient Information
                                    mf8_placeinoutpatientextendedrecoveryme,                                        ; 071 07/22/2022 New
                                    mf8_transferlevelofcareorlocationmedst,                                         ; 071 07/22/2022 New
                                    mf8_placeinoutpatientobservationmedstar,                                        ; 071 07/22/2022 New
                                    mf8_admittoinpatientmedstarhealth)  and                                         ; 071 07/22/2022 New

     orders->facility = "Washington*Hosp*" and  ; description has been used here
     request->print_prsnl_id < 10.00)  ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition, so make it a PDF file

        with nocounter, maxrow=800, maxcol=800,  dio = PDF_REPORTRTL , nocpc    ; 061 06/12/2019  PDF is used here, so "with" is established

 ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
 ; 068 03/08/2021 This 'Elseif' is new. We will print and email the requisition for a Pulmonary Function Testing order.
 ;                In thie 'Elseif', we will email the requisition. We will loop around and the 2nd time through, we will
 ;                fall through to the 'Else', where the requisition will be printed.
 ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -

 Elseif (orders->qual[1].catalog_cd = 101816483.00 and      ; Pulmonary Function Testing order
         orders->facility = "Union*Memorial*Hospital*" and  ; Description has been used here
         request->print_prsnl_id < 10.00 and  ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition
         orders->qual[1].action_type_cd = 2534.00 and       ; Order. We only email if this order is being ordered... originally ordered!!
         pft_order_email_ind = 1)             ; 0 when we want to print. 1 when we want to email

        with nocounter, maxrow=800, maxcol=800,  dio = PDF_REPORTRTL , nocpc    ; 068 03/08/2021  PDF is used here, so "with" is established

; #081 #082
  Elseif (orders->qual[1].catalog_cd = 101806105 and        ; Negative Pressure wound Therapy d/c
         orders->facility = "Georgetown University Hospital" and    ; Description has been used here
         request->print_prsnl_id < 10.00   ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition
         ;orders->qual[1].action_type_cd = 2534.00  ; Order. We only email if this order is being ordered... originally ordered!!
         )

        with nocounter, maxrow=800, maxcol=800,  dio = PDF_REPORTRTL , nocpc    ; 068 03/08/2021  PDF is used here, so "with" is established
   Elseif (orders->qual[1].catalog_cd =101815498.00 and         ; Negative Pressure wound Therapy
         orders->facility = "Georgetown University Hospital" and    ; Description has been used here
         trim(request->printer_name) = "yydummy" and
         request->print_prsnl_id < 10.00  and  ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition
         orders->qual[1].action_type_cd = order_cd  ; Order. We only email if this order is being ordered... originally ordered!!
         )
        with nocounter, maxrow=800, maxcol=800,  dio = PDF_REPORTRTL , nocpc    ; 068 03/08/2021  PDF is used here, so "with" is established
 ;end #081, #082
 else
        with nocounter, maxrow=800, maxcol=800, dio=postscript                  ; 061 06/12/2019  postscript (Line was at the end until now)
 endif

 into value(tempfile1a)
;into $OUTDEV             ; 2019   This is used when testing.   <<<<<<<<<<<<  ;;;;;;;;;;;;;;;; 09/22/2014 testing

   d1.seq
 from (dummyt d1 with seq = 1)

 plan d1

 head report

  first_page = "Y"
  saved_pos = 0

 Head Page
  "{LPI/8}{CPI/12}{FONT/4}","  ",row+1
  line1 = fillstring(35,"_"),
  line2 = fillstring(10,"_"),
  spaces = fillstring(50, " ")

  "{CPI/12}{POS/30/45}", "MEDICAL RECORD NUMBER" ,row+1
  "{CPI/10}{POS/30/55}{b}", "*",orders->mrn,"*" ,row+1
  "{CPI/12}{POS/235/45}", "VISIT NUMBER" ,row+1
  "{CPI/10}{POS/240/55}{b}", "*",
  call print(trim(cnvtstring(cnvtint(request->order_qual[1].encntr_id)))),
    "*",row+1
  "{CPI/12}{POS/420/45}", "PATIENT ACCOUNT NUMBER" ,row+1
  "{CPI/10}{POS/440/55}{b}", "*",orders->fnbr,"*",row+1

  "{CPI/12}{POS/30/120}", "PATIENT NAME:",row+1
  "{CPI/10}{POS/125/120}{b}", call print(trim(orders->name,3)),"{endb}", row+1
  "{CPI/12}{POS/410/120}",  "DOB:  ", orders->dob,row+1

  ; Looking for this??? {CPI/12}{POS/30/130}", "ADMIT DX: ...... It is about 100 lines below.

  "{CPI/12}{POS/410/130}", "AGE:  ", orders->age,row+1                  ; 079 01/10/2023   The "real" line... when validating is complete
; "{CPI/12}{POS/410/130}", "AGE.  ", orders->age,row+1                  ; 079 01/10/2023   For validation only


; 059 10/30/2018  The "if" for the 3 HEMODIALYSIS ELEMENTS orders was added below.

  If(orders->qual[ord_cnt].catalog_cd =  HEMODIALYSISELEMENTS_CD     or     ; 1006163621.00
     orders->qual[ord_cnt].catalog_cd =  HEMODIALYSISELEMENTSFSMC_CD or     ; 1588902027.00
     orders->qual[ord_cnt].catalog_cd =  HEMODIALYSISELEMENTSMGUH_CD)       ; 1587316143.00

      "{CPI/12}{POS/30/170}", "ADMIT DATE:  ",row+1
      "{CPI/12}{POS/125/170}", orders->admit_dt,row+1
      "{CPI/12}{POS/410/170}", "DOSING HGT / WT: ",
      if (orders->height = "Not Done")
          call print(trim(orders->height)),row+1
      else
          call print(trim(orders->height)), "/", call print(trim(orders->weight)),row+1
      endif
      "{CPI/12}{POS/30/140}", "CODE STATUS:", row+1
      "{CPI/12}{POS/125/140}{B}", orders->code_status, "{ENDB}",row+1
      "{CPI/12}{POS/30/160}", "ENCOUNTER TYPE:", row+1
      "{CPI/12}{POS/125/160}{B}", orders->encntr_type, "{ENDB}",row+1
      "{CPI/12}{POS/30/150}", "ISOLATION:", row+1
      "{CPI/12}{POS/125/150}{B}", orders->isolation, "{ENDB}",row+1
      "{CPI/12}{POS/30/180}", "NURSING UNIT:", row+1
      "{CPI/12}{POS/125/180}{B}", orders->nurse_unit, "{ENDB}",row+1
      "{CPI/12}{POS/410/180}", "SEX:  ",  orders->sex,row+1
      "{CPI/12}{POS/30/190}", "ROOM/BED:", row+1
      "{CPI/12}{POS/125/190}", orders->room,orders->bed, row+1
  Else

      "{CPI/12}{POS/30/160}", "ADMIT DATE:  ",row+1
      "{CPI/12}{POS/125/160}", orders->admit_dt,row+1
;     "{CPI/12}{POS/410/160}", "DOSING HGT / WT ",                  ; 02/14/2022  Turn back to black after Go Live
      "{CPI/12}{POS/410/160}", "DOSING HGT / WT:",                  ; 02/14/2022  Turn back to green after Go Live
      if (orders->height = "Not Done")
          call print(trim(orders->height)),row+1
      else
          call print(trim(orders->height)), "/", call print(trim(orders->weight)),row+1
      endif
      "{CPI/12}{POS/30/150}", "ENCOUNTER TYPE:", row+1
      "{CPI/12}{POS/125/150}{B}", orders->encntr_type, "{ENDB}",row+1
      "{CPI/12}{POS/30/140}", "ISOLATION:", row+1
      "{CPI/12}{POS/125/140}{B}", orders->isolation, "{ENDB}",row+1
      "{CPI/12}{POS/30/170}", "NURSING UNIT:", row+1
      "{CPI/12}{POS/125/170}{B}", orders->nurse_unit, "{ENDB}",row+1
      "{CPI/12}{POS/410/170}", "SEX:  ",  orders->sex,row+1
      "{CPI/12}{POS/30/180}", "ROOM/BED:", row+1
      "{CPI/12}{POS/125/180}", orders->room,orders->bed, row+1

  Endif


  "{CPI/12}{POS/30/210}", "ALLERGIES: ","{b}"

  if (allergy->line_cnt > 0)
     "{POS/125/210}",allergy->line_qual[1].line, row+1
  endif

  if (allergy->line_cnt > 1)
    "{POS/125/220}", "{b}", allergy->line_qual[2].line
  endif

  if (allergy->line_cnt > 2)
    "{CPI/12}", "{b}", " ..." ,row+1
    "{POS/160/240}", "{b}", "**** See patient chart for additional allergy information ****", row+1
  endif

  IF( print_diag_flag = 1)

    "{CPI/12}{POS/30/250}", "DIAGNOSIS:    ","{b}"

     if (DIAGNOSIS->dline_cnt > 0)

        DIAGNOSIS->dline_qual[1].dline, row+1
     endif

     if (diagnosis->dline_cnt > 1)

        "{POS/97/260}", "{b}", diagnosis->dline_qual[2].dline               ; 074 11/16/2022  This is now 97. It was 110
     endif

     if (diagnosis->dline_cnt > 2)
        "{CPI/12}", "{b}", " ..." ,row+1
        "{POS/160/280}", "{b}", "**** See patient chart for additional diagnosis information ****", row+1
     endif

  endif

    if (disp_creatGFR = 1)
        if (orders->creat != NULL)
            "{CPI/12}{POS/30/250}","CREATININE:", row + 1
            "{CPI/12}{POS/125/250}","{b}",   ; 070 06/20/2022 I like a 125 rather than the 190 for the horizontal coordinate
             call print(BUILD2(ORDERS->CREAT," ","(",format(ORDERS->creat_date, "MM/DD/YYYY hh:mm:ss;;d"),")")),"{endb}", row + 1
;
;            070 06/20/2022  The below few lines were replaced. Looks like 'ORDERS->gfr_date' was missing.
;
;           "{CPI/12}{POS/30/262}","NON AFRICAN AMERICAN GFR:", row + 1
;           "{CPI/12}{POS/190/262}","{b}",
;            call print(BUILD2(ORDERS->gfr," ","(",format(ORDERS->gfraa_date, "MM/DD/YYYY hh:mm:ss;;q"),")")),"{endb}", row + 1
;           "{CPI/12}{POS/30/274}","AFRICAN AMERICAN GFR:", row + 1
;           "{CPI/12}{POS/190/274}","{b}",
;            call print(BUILD2(ORDERS->gfrAA," ","(",format(ORDERS->gfraa_date, "MM/DD/YYYY hh:mm:ss;;q"),")")),"{endb}", row+1
;
;            070 06/20/2022  The below line is the replacement
;

            If (ORDERS->gfr_date > NULL)       ; 070 06/20/2022 This check for the gfr_date is new.
                "{CPI/12}{POS/30/262}","GFR UNIVERSAL:", row + 1
                "{CPI/12}{POS/125/262}","{b}", ; 070 06/20/2022 I like a 125 rather than the 190 for the horizontal coordinate
                 call print(BUILD2(ORDERS->gfr," ","(",format(ORDERS->gfr_date, "MM/DD/YYYY hh:mm:ss;;q"),")")),"{endb}", row+1
            else                               ; 070 06/20/2022 This check for the gfr_date is new.
                "{CPI/12}{POS/30/262}","GFR UNIVERSAL:", row + 1
                 call print(" "), row+1
            endif                              ; 070 06/20/2022 This check for the gfr_date is new.
;
        else
            "{CPI/12}{POS/30/250}","CREATININE:", row + 1
            ;  070 06/20/2022 For below... I like a 125 rather than the 190 for the horizontal coordinate
            "{CPI/12}{POS/125/250}","{b}","No charted values for past 1 year.","{endb}", row + 1
;
;            070 06/20/2022  The below few lines were removed. They were not printed, anyway, were they?
;
;           "{CPI/12}{POS/30/262}","NON AFRICAN AMERICAN GFR:", row + 1
;           "{CPI/12}{POS/190/262}","{b}","No charted values for past 1 year.","{endb}", row + 1
;           "{CPI/12}{POS/30/274}","AFRICAN AMERICAN GFR:", row + 1
;           "{CPI/12}{POS/190/274}","{b}","No charted values for past 1 year.","{endb}", row+1
        endif
    endif

  "{CPI/10}{POS/20/295}{BOX/75/2}",ROW+1
  "{CPI/8}{POS/24/300}{color/20/145}",ROW+1
  "{CPI/8}{POS/24/307}{color/20/145}",ROW+1
  "{CPI/8}{POS/24/314}{color/20/145}",ROW+1
  "{CPI/8}{POS/24/318}{color/20/145}",ROW+1

  "{CPI/12}{POS/30/335}{B}", "ORDER DATE/TIME:"
  "{CPI/12}{POS/30/347}",    "ORDERING MD:","{endb}",row+1

  IF (orders->qual[saved_pos].catalog_type_cd = consults_cd)
    "{CPI/12}{POS/30/359}{B}", "ATTENDING MD:","{endb}", ROW+1
    "{CPI/12}{POS/30/371}", "ORDER ENTERED BY:",ROW+1
    "{CPI/12}{POS/30/383}", "ORDER NUMBER:" ,row+1
  ELSE
    "{CPI/12}{POS/30/359}", "ORDER ENTERED BY:",ROW+1
    "{CPI/12}{POS/30/371}", "ORDER NUMBER:" ,row+1
  ENDIF


  if (saved_pos > 0)
    "{CPI/10}{POS/1/90}"," ",
    "{CPI/10}{b}",
    call center(orders->facility,1,215)
    row+1

; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
     ; 072 09/06/2022 Replaced one line with the following "If" statement
;    "{CPI/8}{POS/30/310}{b}", "ORDER:  ", orders->qual[saved_pos].mnemonic, row+1

    If (orders->qual[saved_pos].mnemonic = "UPDATED EMERGENCY CONTACT")
        "{CPI/8}{POS/30/310}{b}", "ORDER:  ", "UPDATED CONTACT INFORMATION", row+1
    else
; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
; 077 12/09/2022 The one line below has been replaced with the following "If", "Elseif", "Else" today
;
;       "{CPI/8}{POS/30/310}{b}", "ORDER:  ", orders->qual[saved_pos].mnemonic, row+1

        If (textlen(trim(orders->qual[saved_pos].mnemonic)) > 72)
            "{CPI/13}{POS/30/310}{b}", "ORDER:  ", orders->qual[saved_pos].mnemonic, row+1
        Elseif (textlen(trim(orders->qual[saved_pos].mnemonic)) > 68)
            "{CPI/11}{POS/30/310}{b}", "ORDER:  ", orders->qual[saved_pos].mnemonic, row+1
        Else
            "{CPI/8}{POS/30/310}{b}", "ORDER:  ", orders->qual[saved_pos].mnemonic, row+1
        Endif
; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    endif
; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -

    "{CPI/10}{POS/245/335}", orders->qual[saved_pos].order_dt, row+1
    "{CPI/12}{POS/245/347}", orders->qual[saved_pos].order_dr,row+1
    if ((orders->qual[saved_pos].catalog_type_cd = consults_cd))
        "{CPI/12}{POS/245/359}", orders->admitting,ROW+1        ; 047 04/09/2014 New field for consults only
        "{CPI/12}{POS/245/371}", orders->qual[saved_pos].enter_by,ROW+1
        "{CPI/12}{POS/245/383}", call print(trim(cnvtstring(cnvtint(orders->qual[saved_pos]->order_id)))) ,row+1
    else
        "{CPI/12}{POS/245/359}", orders->qual[saved_pos].enter_by,ROW+1
        "{CPI/12}{POS/245/371}", call print(trim(cnvtstring(cnvtint(orders->qual[saved_pos]->order_id)))) ,row+1
    endif

; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
; 077 12/09/2022 The one line below has been replaced with the following "If", "Elseif", "Else" today
;
;   "{CPI/12}{POS/30/735}", "ORDER    ", "{CPI/9}{B}",orders->qual[saved_pos].mnemonic ;014

    If (textlen(trim(orders->qual[saved_pos].mnemonic)) > 72)
            "{CPI/12}{POS/30/735}", "ORDER    ", "{CPI/13}{B}",orders->qual[saved_pos].mnemonic
    Elseif (textlen(trim(orders->qual[saved_pos].mnemonic)) > 68)
            "{CPI/12}{POS/30/735}", "ORDER    ", "{CPI/11}{B}",orders->qual[saved_pos].mnemonic
    Else
            "{CPI/12}{POS/30/735}", "ORDER    ", "{CPI/9}{B}",orders->qual[saved_pos].mnemonic
    Endif
; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    saved_pos = 0

  endif

detail
for (VV = 1 to VALUE(ord_cnt))
  if (orders->qual[VV].display_ind = 1)
    go_ahead_and_print  = 1

    if (go_ahead_and_print = 1)
      spoolout = 1
      if (first_page = "N")
        break
      endif
      if (orders->qual[vv]->action_type_cd = cancel_cd)
        "{CPI/12}{POS/130/75}{B}", cancel_banner,row+1
      elseif (orders->qual[vv]->action_type_cd = discont_cd)
        "{CPI/12}{POS/130/75}{B}", discont_banner,row+1
      elseif (orders->qual[vv]->action_type_cd = modify_cd)
        "{CPI/12}{POS/130/75}{B}", modify_banner,row+1
      elseif (orders->qual[vv]->action_type_cd = action_type_status_change_cd and   ; 2539.00
              orders->qual[vv]->status = 'Completed')
        "{CPI/12}{POS/130/75}{B}", completed_banner,row+1
      endif

      first_page = "N"

      "{CPI/10}{POS/1/90}"," ",
      "{CPI/10}{b}",
      call center(orders->facility,1,215)

; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
     ; 072 09/06/2022 Replaced one line with the following "If" statement
;      "{CPI/8}{POS/30/310}{b}", "ORDER:  ", orders->qual[vv].mnemonic, row+1

      If (orders->qual[vv].mnemonic = "UPDATED EMERGENCY CONTACT")
        "{CPI/8}{POS/30/310}{b}", "ORDER:  ", "UPDATED CONTACT INFORMATION", row+1
      else

; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
; 077 12/09/2022 The one line below has been replaced with the following "If", "Elseif", "Else" today
;
;       "{CPI/8}{POS/30/310}{b}", "ORDER:  ", orders->qual[vv].mnemonic, row+1

        If (textlen(trim(orders->qual[vv].mnemonic)) > 72)
            "{CPI/13}{POS/30/310}{b}", "ORDER:  ", orders->qual[vv].mnemonic, row+1
        Elseif (textlen(trim(orders->qual[vv].mnemonic)) > 68)
            "{CPI/11}{POS/30/310}{b}", "ORDER:  ", orders->qual[vv].mnemonic, row+1
        Else
            "{CPI/8}{POS/30/310}{b}", "ORDER:  ", orders->qual[vv].mnemonic, row+1
        Endif
; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

      endif
; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -

      "{CPI/10}{POS/245/335}", orders->qual[vv].order_dt, row+1
      "{CPI/12}{POS/245/347}", orders->qual[vv].order_dr,row+1
      IF (orders->qual[vv].catalog_type_cd != 2511.00 )     ; 2511.00 is 'Food and Nutrition Services' (aka,DIETARY)

;         "{CPI/12}{POS/30/130}", "ADMIT DX:", row+1                                ; 060 12/07/2018 replaced.
          "{CPI/12}{POS/30/130}", "VISIT REASON:", row+1                            ; 060 12/07/2018 replacement
            if (textlen(orders->admit_diagnosis) > 49)                                                                      ;018
                "{CPI/12}{POS/125/130}",call print (trim(concat(substring(1, 46, orders->admit_diagnosis), "..."))),row+1
            else
                "{CPI/12}{POS/125/130}",call print(orders->admit_diagnosis),row+1                                           ;018
            endif                                                                                                           ;018
      ENDIF

      if (orders->qual[vv].catalog_type_cd = consults_cd)
        "{CPI/12}{POS/245/359}", orders->attending,ROW+1    ; 047 04/09/2014  This field is new.
        "{CPI/12}{POS/245/371}", orders->qual[vv].enter_by,ROW+1
        "{CPI/12}{POS/245/383}", call print(trim(cnvtstring(cnvtint(orders->qual[vv]->order_id)))) ,row+1
      else
        "{CPI/12}{POS/245/359}", orders->qual[vv].enter_by,ROW+1
        "{CPI/12}{POS/245/371}", call print(trim(cnvtstring(cnvtint(orders->qual[vv]->order_id)))) ,row+1
      endif

; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
     ; 072 09/06/2022 Replaced one line with the following "If" statement
;      "{CPI/12}{POS/30/735}", "ORDER:   ", "{CPI/9}{B}",orders->qual[vv].mnemonic ;014

    If ( orders->qual[vv].mnemonic = "UPDATED EMERGENCY CONTACT")
      "{CPI/12}{POS/30/735}", "ORDER:   ", "{CPI/9}{B}","UPDATED CONTACT INFORMATION"
    else

; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
; 077 12/09/2022 The one line below has been replaced with the following "If", "Elseif", "Else" today
;
;       "{CPI/12}{POS/30/735}", "ORDER:   ", "{CPI/9}{B}",orders->qual[vv].mnemonic

        If (textlen(trim(orders->qual[vv].mnemonic)) > 72)
            "{CPI/12}{POS/30/735}", "ORDER:   ", "{CPI/13}{B}",orders->qual[vv].mnemonic
        Elseif (textlen(trim(orders->qual[vv].mnemonic)) > 68)
            "{CPI/12}{POS/30/735}", "ORDER:   ", "{CPI/11}{B}",orders->qual[vv].mnemonic
        Else
            "{CPI/12}{POS/30/735}", "ORDER:   ", "{CPI/9}{B}",orders->qual[vv].mnemonic
        Endif
; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    endif

      xcol=30
      ycol=403
      for (fsub = 1 to 31)
        for (ww = 1 to orders->qual[vv]->d_cnt)
          if ((orders->qual[vv].d_qual[ww]->group_seq = fsub)
          or (fsub = 31 and orders->qual[vv]->d_qual[ww]->print_ind = 0))
            orders->qual[vv]->d_qual[ww]->print_ind = 1

            if (textlen(trim(orders->qual[vv].d_qual[ww].value,3)) > 0)
                "{CPI/13}",call print(calcpos(xcol,ycol)),
                call print(orders->qual[vv].d_qual[ww].label_text),"  ",row+1
                xcol = 245
                if(orders->qual[vv].d_qual[ww].value_cnt > 1)
                    for (dsub = 1 to orders->qual[vv].d_qual[ww].value_cnt)
                        call print (calcpos(xcol,ycol)) "{b}",orders->qual[vv].d_qual[ww].value_qual[dsub].value_line,"{endb}",
                        row+1
                        ycol = ycol + 12

                        if (ycol > 680 and dsub < orders->qual[vv].d_qual[ww].value_cnt)
                            call print (calcpos(xcol,ycol)),"**Continued on next page**"
                            saved_pos = vv
                            break
                            xcol = 30
                            ycol = 421;040 381
                            "{CPI/13}",call print(calcpos(xcol,ycol)),
                             call print(concat(orders->qual[vv].d_qual[ww].label_text, " cont. "))
                            xcol = 245
                        endif

                    endfor
                else
                    call print (calcpos(xcol,ycol)) "{b}",orders->qual[vv].d_qual[ww].value,"{endb}", row +1
                    ycol = ycol + 12
                endif
                xcol = 30
            endif
          endif
          if (ycol > 680 and ww < orders->qual[vv]->d_cnt)
            saved_pos = vv
            break
            ycol = 421;040 381
          endif
        endfor
      endfor
    endif
    if(ycol > 680)
      saved_pos = vv
      break
      ycol = 421;040 381
    else
      ycol = ycol + 12
    endif
    xcol = 30
    if (orders->qual[vv]->comment_ind = 1 and orders->qual[vv]->com_ln_cnt > 0) ;023
        "{CPI/13}"
        call print (calcpos (xcol,ycol)),"{b}", "COMMENTS ", "{endb}"
;       if (orders->qual[vv].com_ln_cnt > 7)                                    ; 069 02/14/2022  Replaced. See below.
        if (orders->qual[vv].com_ln_cnt > 7 and                                 ; 069 02/14/2022  Replacement
            orders->qual[vv].catalog_cd != UPDATEDEMERGENCYCONTACT_CD)          ; 069 02/14/2022  Replacement
            ocnt = 7
        else
            ocnt = orders->qual[vv].com_ln_cnt ;023
        endif
        ycol = ycol + 16
        ;;; 069 02/14/2022   New
        if (orders->qual[vv].catalog_cd = UPDATEDEMERGENCYCONTACT_CD)
            call echo('what')
            ;084 
            ; This cd doesn't even exist anymore... but running into problems with other orders because this is 
            ;erroring on the RS not being defined... not sure how... no clue... makes no sense.
            ;for (com_cnt = 1 to size(blob_line->qual,5))
            ;    call echo("in")
            ;    line_here = replace(blob_line->qual[com_cnt].line, "xX", "")  ; 069 02/14/2022 Now, remove the xX that I added earlier.
            ;    call print (calcpos (xcol,ycol)),"{b}", line_here ,"{endb}" ;023
            ;    row + 1
            ;    ycol = ycol + 12
            ;endfor
        else
        ;;; 069 02/14/2022  New ends here
                for (com_cnt = 1 to ocnt)
                call print (calcpos (xcol,ycol)),"{b}", orders->qual[vv].com_ln_qual[com_cnt]->com_line,"{endb}" ;023
                row + 1
                ycol = ycol + 12
            endfor
        endif               ; 069 02/14/2022 This endif is new

;       if (orders->qual[vv].com_ln_cnt > 7) ;023                               ; 069 02/14/2022  Replaced. See below.
        if (orders->qual[vv].com_ln_cnt > 7 and
            orders->qual[vv].catalog_cd != UPDATEDEMERGENCYCONTACT_CD)          ; 069 02/14/2022
          call print (calcpos (xcol,ycol)),
           "{cpi/13}", "**** Please check chart for further comments ****"
        endif
    endif
  endif
endfor

endif       ;  Paired with "if (orders->qual[1].catalog_type_cd  = MAT_MGMT_CD)"
            ;     and with this "else"   ; *********  Print the Non-Material Management requisition  *********

;---------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------
;   061  06/12/2019   Emailing the WHC Admit/Discharge/Transfer orders.
;                     Otherwise... print (See the below 'Else' for the spool command)
;                     We will only email...
;                       - a small set of orders
;                       - only from WHC
;                       - only when generated automatically and not as a manual re-print from the Orders page
;                       - If not in the production domain right now (P41), we will have already left this script by
;                         falling down to exit_script with the use of a "Go To"
;---------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------

 If (orders->qual[1].catalog_cd in (101851470.00,     ; Admit to Inpatient
                                    155622002.00,     ; Admit to NICU
                                    101851441.00,     ; Change Attending Provider To
                                    996881997.00,     ; Change Primary Care Provider (PCP)
                                    177018848.00,     ; MWHC ED Admit to Inpatient
                                    177194832.00,     ; MWHC ED Place in Outpatient Observation
                                    101851509.00,     ; Place in Outpatient Observation
                                    187950822.00,     ; Status Change - Inpatient to Outpatient Observation
                                    187950990.00,     ; Status Change - Outpatient Observation to Inpatient
                                    101815625.00,     ; Transfer Level of Care or Location
                                    3341919083.00, ;080 add - Update Patient Information
                                    mf8_placeinoutpatientextendedrecoveryme,                ; 071 07/22/2022 New
                                    mf8_transferlevelofcareorlocationmedst,                 ; 071 07/22/2022 New
                                    mf8_placeinoutpatientobservationmedstar,                ; 071 07/22/2022 New
                                    mf8_admittoinpatientmedstarhealth) and                  ; 071 07/22/2022 New

    orders->facility = "Washington*Hosp*" and   ; description has been used here
    request->print_prsnl_id < 10.00)   ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition, so email it

    DECLARE EMAIL_SUBJECT = VC WITH NOCONSTANT(" ")

    SET EMAIL_SUBJECT = build2(trim(orders->qual[1].mnemonic), "   ",  trim(orders->fnbr))

    DECLARE EMAIL_BODY = VC WITH NOCONSTANT("")
    DECLARE UNICODE = VC WITH NOCONSTANT("")

    DECLARE AIX_COMMAND   = VC WITH NOCONSTANT("")
    DECLARE AIX_CMDLEN    = I4 WITH NOCONSTANT(0)
    DECLARE AIX_CMDSTATUS = I4 WITH NOCONSTANT(0)

    Declare EMAIL_ADDRESS   = vc WITH NOCONSTANT("")
;   SET EMAIL_ADDRESS = "WHC-MedconnectOrders@medstar.net"                              ;            .... to the 100 - 200 emails per day
    SET EMAIL_ADDRESS = "WHC-MedconnectOrders@medstar.net,brian.twardy@medstar.net"     ; 072 11/15/2022  I'm back for a while

    SET EMAIL_BODY = concat("email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                            "_",trim(substring(2,4,cnvtstring(RAND(0)))),                           ; Random # generator 4 digits
                            ".txt")

    ;------------------------------------------------------------------------------------------
    ;; Below, we are creating a file that will hold the email body. The file's name is inside EMAIL_BODY.

    Select into (value(EMAIL_BODY))
                    body1 = build2("A  '", trim(orders->qual[1].mnemonic), "' order is attached to this email."),
                    body2 = build2("Patient: " ,trim(orders->name)),
                    body3 = build2("MRN: ",trim(orders->mrn)),
                    body4 = build2("FIN:   " ,trim(orders->fnbr)),
                    body5 = build2("Unit:  ",trim(orders->nurse_unit)),
                    body6 = build2("Room/Bed: ",concat(trim(orders->room),trim(orders->bed))),
                    body7 = build2("Order Date/Time: ",trim(orders->qual[1].order_dt))
    from dummyt
    Detail
        col 01 body1
        row +2
        col 01 body2
        row +1
        col 01 body3
        row +1
        col 01 body4
        row +2
        col 01 body5
        row +1
        col 01 body6
        row +2
        col 01 body7
    with format,  maxcol = 200

    SET  AIX_COMMAND  =
        build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
               " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", tempfile1a, " ", EMAIL_ADDRESS)

    SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
    SET AIX_CMDSTATUS = 0
    CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)

        call pause(2)   ; Let's slow things down before the clean up immediately below.
        call pause(2)   ; Let's slow things down before the clean up immediately below.

        ;   clean up.   (Removing EMAIL_BODY from $CCLUSERDIR does work.)

            SET  AIX_COMMAND  =
                CONCAT ('rm -f ' , tempfile1a,  ' | rm -f ' , EMAIL_BODY)

            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)

 ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
 ; 068 03/08/2021 This 'Elseif' is new. We will print and email the requisition for a Pulmonary Function Testing order.
 ;                In thie 'Elseif', we will email the requisition. We will loop around and the 2nd time through, we will
 ;                fall through to the 'Else', where the requisition will be printed.
 ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -

 Elseif (orders->qual[1].catalog_cd = 101816483.00 and      ; Pulmonary Function Testing order
         orders->facility = "Union*Memorial*Hospital*" and  ; Description has been used here
         request->print_prsnl_id < 10.00 and  ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition
         orders->qual[1].action_type_cd = 2534.00 and       ; Order. We only email if this order is being ordered... originally ordered!!
         pft_order_email_ind = 1)             ; 0 when we want to print. 1 when we want to email

    DECLARE EMAIL_SUBJECT = VC WITH NOCONSTANT(" ")

    SET EMAIL_SUBJECT = build2(trim(orders->qual[1].mnemonic), "   ",  trim(orders->fnbr))

    DECLARE EMAIL_BODY = VC WITH NOCONSTANT("")
    DECLARE UNICODE = VC WITH NOCONSTANT("")

    DECLARE AIX_COMMAND   = VC WITH NOCONSTANT("")
    DECLARE AIX_CMDLEN    = I4 WITH NOCONSTANT(0)
    DECLARE AIX_CMDSTATUS = I4 WITH NOCONSTANT(0)

    Declare EMAIL_ADDRESS   = vc WITH NOCONSTANT("")
    SET EMAIL_ADDRESS = "brian.twardy@medstar.net,Ashley.B.Shelter@Medstar.net,Nicole.L.Bivins@medstar.net"
;   SET EMAIL_ADDRESS = "brian.twardy@medstar.net"

    SET EMAIL_BODY = concat("pft_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                            "_",trim(substring(2,4,cnvtstring(RAND(0)))),                           ; Random # generator 4 digits
                            ".txt")

    ;; Below, we are creating a file that will hold the email body. The file's name is inside EMAIL_BODY.

    Select into (value(EMAIL_BODY))
                    body1 = build2("A  '", trim(orders->qual[1].mnemonic), "' order is attached to this email."),
                    body2 = build2("Patient: " ,trim(orders->name)),
                    body3 = build2("MRN: ",trim(orders->mrn)),
                    body4 = build2("FIN:   " ,trim(orders->fnbr)),
                    body5 = build2("Unit:  ",trim(orders->nurse_unit)),
                    body6 = build2("Room/Bed: ",concat(trim(orders->room),trim(orders->bed))),
                    body7 = build2("Order Date/Time: ",trim(orders->qual[1].order_dt))
    from dummyt
    Detail
        col 01 body1
        row +2
        col 01 body2
        row +1
        col 01 body3
        row +1
        col 01 body4
        row +2
        col 01 body5
        row +1
        col 01 body6
        row +2
        col 01 body7
    with format,  maxcol = 200

    SET  AIX_COMMAND  =
        build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
               " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", tempfile1a, " ", EMAIL_ADDRESS)

    SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
    SET AIX_CMDSTATUS = 0
    CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)

    call pause(2)   ; Let's slow things down before the clean up immediately below.
    call pause(2)   ; Let's slow things down before the clean up immediately below.

        ;   clean up.   (Removing EMAIL_BODY from $CCLUSERDIR does work.)

    SET  AIX_COMMAND  =
        CONCAT ('rm -f ' , tempfile1a,  ' | rm -f ' , EMAIL_BODY)

    SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
    SET AIX_CMDSTATUS = 0
    CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)

 ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
 ; 068 03/08/2021 The above 'Elseif' is new. It ends here.
 ; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -

  ;#081 082
 Elseif ( (orders->qual[1].catalog_cd  = 101806105.00 or        ; Negative Pressure Wound
            (orders->qual[1].catalog_cd =101815498 and trim(request->printer_name) = "yydummy" )
            );, Specialty Bed
         and orders->facility = "Georgetown University Hospital"    ; Description has been used here
         and request->print_prsnl_id < 10.00   ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition
         ;and orders->qual[1].action_type_cd = discont_cd       ; discontinued, send email
        )

    DECLARE EMAIL_SUBJECT = VC WITH NOCONSTANT(" ")

    SET EMAIL_SUBJECT = build2(trim(orders->qual[1].mnemonic), "   ",  trim(orders->fnbr))

    DECLARE EMAIL_BODY = VC WITH NOCONSTANT("")
    DECLARE UNICODE = VC WITH NOCONSTANT("")

    DECLARE AIX_COMMAND   = VC WITH NOCONSTANT("")
    DECLARE AIX_CMDLEN    = I4 WITH NOCONSTANT(0)
    DECLARE AIX_CMDSTATUS = I4 WITH NOCONSTANT(0)

    Declare EMAIL_ADDRESS   = vc WITH NOCONSTANT("")
    if(orders->qual[1].catalog_cd =101806105.00);NPWT
        SET EMAIL_ADDRESS = build2("lem23@gunet.georgetown.edu,dmitric.crowe@gunet.georgetown.edu,guh-nisupport@gunet.georgetown.edu,",
            "christina.m.koehler@gunet.georgetown.edu,fiona.j.mulroe@gunet.georgetown.edu,kimberly.mauck@gunet.georgetown.edu")
    else ;specialty bed
        SET EMAIL_ADDRESS = "lem23@gunet.georgetown.edu,dmitric.crowe@gunet.georgetown.edu,guh-nisupport@gunet.georgetown.edu"
    endif
;   SET EMAIL_ADDRESS = "brian.twardy@medstar.net"

    SET EMAIL_BODY = concat("pft_email_body_", format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"),
                            "_",trim(substring(2,4,cnvtstring(RAND(0)))),                           ; Random # generator 4 digits
                            ".txt")

    ;; Below, we are creating a file that will hold the email body. The file's name is inside EMAIL_BODY.

    Select into (value(EMAIL_BODY))
                    body1 = build2("A  '", trim(orders->qual[1].mnemonic), "' order is attached to this email."),
                    body2 = build2("Patient: " ,trim(orders->name)),
                    body3 = build2("MRN: ",trim(orders->mrn)),
                    body4 = build2("FIN:   " ,trim(orders->fnbr)),
                    body5 = build2("Unit:  ",trim(orders->nurse_unit)),
                    body6 = build2("Room/Bed: ",concat(trim(orders->room),trim(orders->bed))),
                    body7 = build2("Order Date/Time: ",trim(orders->qual[1].order_dt))
    from dummyt
    Detail
        col 01 body1
        row +2
        col 01 body2
        row +1
        col 01 body3
        row +1
        col 01 body4
        row +2
        col 01 body5
        row +1
        col 01 body6
        row +2
        col 01 body7
    with format,  maxcol = 200

    SET  AIX_COMMAND  =
        build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
               " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", tempfile1a, " ", EMAIL_ADDRESS)

    SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
    SET AIX_CMDSTATUS = 0
    CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)

    call pause(10)  ; Let's slow things down before the clean up immediately below.
    call pause(2)   ; Let's slow things down before the clean up immediately below.

        ;   clean up.   (Removing EMAIL_BODY from $CCLUSERDIR does work.)

    SET  AIX_COMMAND  =
        CONCAT ('rm -f ' , tempfile1a,  ' | rm -f ' , EMAIL_BODY)

    SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
    SET AIX_CMDSTATUS = 0
    CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)


 ;081 082 END


Else
    set spool = value(trim(tempfile1a)) value(trim(request->printer_name)) ;with deleted  ; 2019  this is used when this is real
;   set spool = value(trim(tempfile1a)) $outdev with deleted                              ; 2019  this is for testing

endif

endif


; ---    ---     ---    ---     ---    ---     ---    ---     ---    ---     ---    ---     ---    ---     ---    ---
; 068 03/08/2021   This "if" is new. We will loop back when the order is a UMH, Pulmonary Function Testing order
; ---    ---     ---    ---     ---    ---     ---    ---     ---    ---     ---    ---     ---    ---     ---    ---

if (orders->qual[1].catalog_cd = 101816483.00 and ; Pulmonary Function Testing order
    orders->facility = "Union*Memorial*Hospital*" and   ; description has been used here
    request->print_prsnl_id < 10.00 and  ; when < 10, we know that SYSTEM, SYSTEM is generating the requisition
    orders->qual[1].action_type_cd = 2534.00 and        ; Order. We only llop back to email if this order is being originally ordered!!
    pft_order_email_ind = 0)              ; 0 when we want to print. 1 when we want to email

        set pft_order_email_ind = 1   ; 068 03/08/2021 1 means email the requistion.  0 means, print it

        go to Loop_for_Pulmonary_Function_Testing       ; 068 03/08/2021  Only the 'Pulmonary Function Testing' order(s) will
                                                        ;                 loop back.
                                                        ;                 1st time through, print it.
                                                        ;                 2nd time, generate the email
endif
; ---    ---     ---    ---     ---    ---     ---    ---     ---    ---     ---    ---     ---    ---     ---    ---



#exit_script
;set last_mod = "075"
end
go
