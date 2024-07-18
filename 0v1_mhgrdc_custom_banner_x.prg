/***************************************************************************************************************************
 Program Title:		MHGRDC Custom Banner Bar Fields
 Object name:		0v1_mhgrdc_custom_banner
 Source file:		0v1_mhgrdc_custom_banner.prg
 Purpose:			Provide custom banner fields
 Prompts:
 
 Tables read:
 
 Tables updated:
 Executed from:		powerchart
 Programs Executed:
 Special Notes:
 
****************************************************************************************************************************
											MODIFICATION CONTROL LOG
****************************************************************************************************************************
Mod	 Date		 Analyst				  OPAS			Comment
---	 ----------	 --------------------	  ------	    ----------------------------------------
001	 02/22/2012	 Brandon Gordon			  16510266		Initial release
002  05/03/2013  Tameka Overton           35346065      Fixed allergies qualificaiton issue with end_effective_dt_tm
003  06/28/2013  Brian Twardy         	  See below.	See the Modification History below.
004  04/29/2014	 Siddharth Shetty		  000039954884	Added IMO codes for critical alerts field
005  07/07/2014  Brian Twardy         	  See below.	See the Modification History below.
006  10/07/2014  Brian Twardy         	  See below.	See the Modification History below.
007  12/15/2015  Brian Twardy         	  See below.	See the Modification History below.
008  02/03/2016	 Swetha Srinivasaraghavan See Below.	See Modification History below.
009  05/09/2016	 Swetha Srinivasaraghavan 000049414365	(Incident)
														Added "INVOLUNTARY COMMITMENT", "PSYCHOLOGICAL FINDING"
														to problems' list.
010	 11/22/2016	 Troy Shelton             000052531831	(Incident)
														Added "DIFFICULT AIRWAY" to problems' list and fixed display issue
														with Transplant problem.
011  12/09/2016  Troy Shelton             NA            Added "No blood products" to problems list
012  12/28/2016  See below
013  01/11/2017  See below
014  01/12/2017  See below
 
- - - - - For all further revisions, please document them fully below in the MODOFICATION HISTORY - - - - -
- - - - - For all further revisions, please document them fully below in the MODOFICATION HISTORY - - - - -
- - - - - For all further revisions, please document them fully below in the MODOFICATION HISTORY - - - - -
 
****************************************************************************************************************************
-------------------------------------------------------------------------------------
MODIFICATION HISTORY
-------------------------------------------------------------------------------------
---------------------------
003 06/28/2013 Brian Twardy
OPAS Request/Task R2:000036126815  and several others (Primary user... Ann-Marie Lesko @ UMH)
Old CCL Source:  cust_script:0_mhgrdc_custom_banner.prg
New CCL Source:  cust_script:0_mhgrdc_custom_banner.prg  (The script has not been renamed.)
The Patient Banner in PowerChart is displaying an incorrect Code Status for the patient..... on
occasions. The reason is that the clinical_event table was being queried by the
patient's person_id, rather than by the encntr_id.  This has been corrected.
---------------------------
004 04/29/2014
---------------------------
005 07/07/2014 Brian Twardy   (7/7/2014   change made in TST41)
MCGA: MCGA18591 UMH/Dosing weight method added to banner bar for ED
Key user:  Lisa-marie Williams = UMH
OPAS Request/Task R2:000014589548/R2:000024624368
Old CCL Source:  cust_script:0_mhgrdc_custom_banner.prg
New CCL Source:  cust_script:0_mhgrdc_custom_banner.prg  (The script has not been renamed.)
---------------------------
006 10/07/2014 Brian Twardy
MCGA: MCGA19037 (and MCGA16689)  Isolation precautions status added to the Critical Alerts custom field
OPAS Request/Task: R2:000014912628/R2:000025301948
Old CCL Source:  cust_script:0_mhgrdc_custom_banner.prg
New CCL Source:  cust_script:0_mhgrdc_custom_banner.prg  (The script has not been renamed.)
---------------------------
007 12/15/2015 Brian Twardy
Two requests for the "Alerts" section of the banner bar have been addded into B41 today, 9/29/2015.
(1)	MCGA: MCGA201442 (Add problems... Malignant Hyperthermia and Family History of Malignant Hyperthermia)
	OPAS Request/Task: R2:000061601648/R2:000083389218
	Key User: David T Smith
(2)	MCGA: MCGA201563 (Add "Research study patient" to the Alerted Critical Conditions)
	OPAS Request/Task: R2:000061689993/R2:000083605027
	Key User: Kim Vandenassem
CCL Script:  cust_script:0_mhgrdc_custom_banner.prg  (no name change)
-------------------------------------------
008	02/03/2016	Swetha Srinivasaraghavan
MCGA: 202839/202566
Old CCL Source:  cust_script:0_mhgrdc_custom_banner.prg
Modifications:
Sl.	FieldName		Prior to 008		008 Updates
1.	CUSTOMFIELD1	Sex/Age				Displays PCP.
										Displays provider name assigned the Primary Care Provider lifetime relationship;
										"Unknown, the Unknown" suppressed from showing;
										The format looks the same as Attending field
2.	CUSTOMFIELD2	"No Allergies		Modified to "NOT RECORDED".
					Recorded"
3.	CUSTOMFIELD3	Critical Alerts +	Code Status + Critical Alerts.
					Isolation			Moved Code Status here from CUSTOMFIELD5 and listed it first;
										If an order is not found,
											Clinic & Recurring Outpatient encounter types (cs 71) display nothing
											All other encounter types display “Code: Not Recorded”
4.	CUSTOMFIELD4	Dose Wt				Added the date of the result MM/DD/YYYY at the end.
										Clinic/Recurring Outpatient encounter type:
										(With revision #32 in 2020, we added Recurring Clinic here)
											If patient < 16 years old,
												Display the most recent result within the last 31 days
											Else
												Display the most recent result within the last 1 year
										All other encounter types: Encounter specific (as it is today),
											Display the most recent
											If a newer dosing weight is documented on a different encounter,
												Display nothing (blank)
5.	CUSTOMFIELD5	Code Status			Moved Isolation here from CUSTOMFIELD3;
										Added label "Iso:" when there is a result found. Else displays nothing.
-------------------------------------------
012 12/28/2016
MCGA: 204074  (Modify Add Insurance to Banner Bar) -  Jessica Johnson - orig request - August 2016
Help Desk/OPAS Request/Task: R2:000064711880/R2:000086893375
Revise the banner bar for ambulatory patients, so that the primary insurer will appear in the position where Isolation status
appears for inpatients.   The real estate on the banner bar for this field has increased from two invisible columns to three,
in order to cut down on the number of times that hovering would be necessary.  Only ambulatory patients will display this
insurance field. Ambulatory patients are those with an encounter type of Clinic, Recurring Clinic, Recurring OutPatient, or
Outpatient Message. Inpatients will not be affected by this revision.
NOTE: The following request has been put on hold for the time being.... perhaps longer....
   MCGA: 204528  (Modify Demographic Banner Bar to include Clinical Trials Flag in the Code Status Field) -
														             Dr. Neil Weissman and Courtney Colbert - orig request Sept 2016
   CareNet Agenda Item: 1045
   Help Desk/OPAS Request/Task: R2:000064176371/R2:000086781369
   "Research Study: Yes" or "Research Study: No" will appear in the code status/critical alerts custom field (right in front
   of the critical alerts field) for ambulatory patients. Ambulatory patients are those with an encounter type of Clinic,
   Recurring Clinic, Recurring OutPatient, or Outpatient Message. Inpatients will not be affected by this revision.
-------------------------------------------
013  01/11/2017  Troy Shelton
Incident Management Id: R2:000054046921
Difficult Airway from the Alerted Critical Conditions folder is no longer displaying in the Banner Bar.
Per Brian Twardy:
The CCL programming is looking for "RESPIRATORY OBSTRUCTION", but it found EMBARRASSED AIRWAY. So, the one problem for patient
did NOT qualify as a Critical Alert.
Per Jim Mckusky:
We took the latest SNOMED and IMO content to B41/Prod in December.  C41/T41 are still using an older version of SNOMED and IMO
content.
Quick solution:
Add EMBARRASSED AIRWAY. Quick solution tested and approved by Joy Upton on 1/11/16. Moved to Prod on 1/11/16.
Future proposed solution:
Data Architects to communicate with all necessary teams when new SNOMED and IMO content is available.
Data Architects to provide list of new SNOMED and IMO content.
May also want to re-write Critical Alerts code.
-------------------------------------------
014  01/12/2017  Troy Shelton
Re-wrote Critical Alerts code
Why? When the SNOMED and IMO content is updated via a package, the IMO code for Critical Alert problems "may" get re-aassociated
to a different SNOMED. If it gets re-associated to a different SNOMED, it breaks the CCL code that displays the Critical Alert
problems in the patient banner bar.
-------------------------------------------
015  12/08/2017 Brian Twardy     (swapped into P41 from B41 on 02/01/2018)
MCGA: 210007
OPAS Request/Task: R2:000071762735/R2:000090414603
CCL Source:  cust_script:0v1_mhgrdc_custom_banner.prg   (no name change)
Update the Clinical Trial status within the existing Code Status + Clinical Trial + Critical Problems field to display the
patient's research study status. The Clinical Trial status should display based on the clinical trials flag (=yes) and the
patient's subject status within PowerTrials.
REVISED on 01/31/2018: Display the Clinical Trial field in the custom field in this order: Code Status +  Critical Problems +
                       Clinical Trial. This order is different than what was originally requested.
The research study status should display as follows, based on the statuses listed below:
  - Subject Status = On Study; Banner Bar Display = On Research Study: Yes
  - Subject Status = On Treatment; Banner Bar Display = On Research Study: Yes
  - Subject Status = Withdrawn; Banner Bar Display = On Research Study: No
  - Subject Status = Off Treatment; Banner Bar Display = On Research Study: Yes
  - Subject Status = On Follow-Up; Banner Bar Display = On Research Study: Yes
  - Subject Status = Off Study; Banner Bar Display = On Research Study: No
If the clinical trials flag is set to no, or the patient does not have a subject status in PowerTrials, then the banner bar
display = On Research Study: No
Every patient should have a designation on the banner bar for research study status; also as the patient's subject status
changes, the banner display should also be displayed dynamically.
-------------------------------------------
016  02/20/2018 Brian Twardy        (Placed into B41 on 2/7/2018)
MCGA: 210840	(Key Users: Ntiense Inokon, Dr Joel McAlduff, Courtney Colbert, and many others)
OPAS Request/Task: _______/___________
CCL Source:  cust_script:0v1_mhgrdc_custom_banner.prg   (no name change)
Research patients should strictly be identified in the banner bar by having the banner bar look into the data supplied to
Medconnect through the use of the Powertrials application.  The CCL script used by the banner bar now looks at the
PowerTrials info in Medconnect, rather than looking at the charted Problems. Up to recently, the “Research study patient”
problem would be the only way that the banner bar would know that a patient was a research patient. Now that the banner bar
is using the PowerTrials data, we have removed the  “Research study patient” problem completely from the banner bar.
-------------------------------------------
017  06/26/2018 Brian Twardy        (Placed into B41 on 5/1/2018)
MCGA: 212072	(Key Users: Brandan Furlong, Kathryn Lee,Lou Maniatis, Joel McAlduff, and many others)
SOM Request/Task: REQ0938673 / TASK1725971
CCL Source:  cust_script:0v1_mhgrdc_custom_banner.prg   (no name change)
We are just allowing any inactive allergy nomenclature to be displayed.  This came about when NKA was being replaced with
'No Known Nomenclature'. See MCGA 210849 for a little more background too.
-------------------------------------------
018  09/14/2018 Brian Twardy
MCGA: 212860	(Key Users:  Lori Whitelaw of IT Ambulatory Support, Joel McAlduff, and many others)
SOM Request/Request Item/Task:REQ1077308 / RITM1108699 / TASK1984812
CCL Source (old):  cust_script:0v1_mhgrdc_custom_banner.prg     (Name changed!!!)
CCL Source (new):  cust_script:0v1_mhgrdc_custom_banner_x.prg   (Name changed!!!)
Added primary nurse, patient phone #s, and advance directives... all depending on the encoubnter type.
-------------------------------------------
019  DECEASED PATIENT code.
Still on hold as of 12/12/2018.
Removed from B41 on 02/13/2019 with #023.
See #024 below.
-------------------------------------------
020  12/12/2018 Troy Shelton
MCGA: 213960 (Key Users: Debby Cowell, Nicole Mauck, Hilary Poan)
SOM Request/Request Item/Task: TASK2216137
CCL Source: cust_script:0v1_mhgrdc_custom_banner_x.prg (no name change)
Added 'Potential for harm to others' problem that is placed by PLAN_HARM_TO_OTHERS_PROB rule to the critical alerts
banner bar field.
-------------------------------------------
021  01/18/2019 Brian Twardy
MCGA: 215221	(Key Users:  Alisia Hewes, Sharon Bonner and lots of folks)
SOM Task: TASK2442703
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
Break/Fix MCGA regarding the assigned Primary RN field. For encounters where there has only been one active,
assigned RN and the patient has returned to the current unit, this field is no longer confused in thinking that the RN
from the first trip to this unit is different from the RN in the second visit. It knew that there was an assigned RN each time,
but it considered the 2nd RN to be a different RN... not the same one.
-------------------------------------------
022  02/08/2019 Brian Twardy
MCGA: n/a	(Key Users:  Hannah Spangler)
SOM Incident: INC6926675
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
The Code Status field was not being displayed correctly in some instances when there happen to be multiple
Code Status for a patient and they all were updated at the same time. The "order by" has been improved.
-------------------------------------------
023  02/13/2019  Brian Twardy
MCGA: 212871      (Key Users: Jessica Johnson, Subin James, Ryan Van Oosten)
SOM Task: TASK2504077
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
Regarding the phone numbers dislayed in the banner bar, we swapped in "Primary" for "Home" and "Secondary" for "Alt".
-------------------------------------------
024 03/19/2019 - Brian Twardy    (originally... for testing in B41 11/23/2018)
MCGA: 214314 	(Key Users: Emily Bloch of GUH, Joel McAlduff, and many others)
SOM Task: TASK2322057
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
Added DECEASED PATIENT to the critical alerts banner bar field, as the leading data field among the others that already
populate that banner bar field.
-------------------------------------------
025 04/17/2019 - Brian Twardy
MCGA: 216444 	(Key User: Dr Joel McAlduff)
SOM Task: TASK2645823
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
Revised the Est and Mea dosing weight labels to read as Estimated and Measured.
-------------------------------------------
026 05/12/2019 - Brian Twardy
MCGA: n/a
SOM Incident: INC7502685   (Customer: Amanda Ryan of MGUH and Hilary Poan, Clinical Project Manager at Corporate)
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
Revised the Primary Nurse field, because one instance was reported as Muliple for Unit", rather
than just one Primary nurse. This was because the encntr_loc_hist table had been greatly
back-dated, and that causes issues when reading from the encntr_loc_hist table, unless
complicated processing is performed.
-------------------------------------------
027 07/16/2019 - Brian Twardy
MCGA: n/a
SOM Incident: ______
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
The Primary Nurse field was not showing "Multiple For Unit" when the current nursing unit had
multiple nurses. It was only showing the last estabalished, active Primary Nurse.
-------------------------------------------
028 07/31/2019 - Brian Twardy        (in P41.... 8/12/2019)
MCGA: 215088     (Requester: Dr Joel McAlduff
SOM Task: TASK2454194
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
Added the CLINICAL_DISPLAY_LINE data as 'hover over' information for the Patient Isolation field that is displayed
in the banner bar.  It is understood that the the 'hover over' data might truncate and end with an
ellipsis (...), if the character count exceeds the maximum allowed.
-------------------------------------------
029 10/18/2019 - Brian Twardy        (in P41.... 10/28/2019)
MCGA: (1 of 2) 218510 - Add hover over details to code status in banner
      (2 of 2) 218303 - add hover over data to patient isolation fields in banner bar part 2
SOM Task:   (1 of 2) TASK3008653
			(2 of 2) TASK2965447
Requester for both:   Dr Joel McAlduff, with Infection Control work group and Debbie Ellerby also requesters for 2 of 2
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
(1 of 2) Five required intervention questions within the Code Status order details are now displayed as hover over information.
         This only applies when the code status order is for 'DNR with Conditions'
(2 of 2) CLINICAL_DISPLAY_LINE data as hover over information for the Patient Isolation order. The hover over data might
 		 truncate and end with an ellipsis (...) if the character count exceeds the maximum. Part 2.... The ICPs asked
		 for the organisms displayed in the comments of the order when the order is created by a discern rule.
-------------------------------------------
030 01/29/2020 - Brian Twardy
MCGA: n/a
SOM Incident: INC9128799   (requester: Leah Seiler of MFSMC)
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
One patient's Primary Nurse was not appearing in the banner bar.  The reason had to do with the location
chosen by this script that the patient was when the Primary Nurse relationship was established.  In some cases,
the order of the encntr_loc_hist rows is different when ordered by encntr_loc_hist_id rather than
transaction_dt_tm. This was one of those cases. Now, we are ordering by encntr_loc_hist_id.
-------------------------------------------
031 02/03/2020 - Brian Twardy        (in P41.... 02/12/2020)
MCGA: (1) 220312 - code status revision/enhancemnet
      (2) 219397 - Hospice Patient now included as an Alerted Critical Conditions
SOM Task: (1) TASK3345052
		  (2) TASK3170391
Requester for both:   Dr Joel McAlduff)
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
(1) Revise the code status 'hover over' field to include order comments. These order comments will be included for any
    ordered code status... not just for code status orders of/fo 'DNR with Conditions'.
(2) By looking to the "Alerted Critical Conditions " public folder, Hospice Care Patient, will be included as
    an alerted criltical condition here on the banner bar. Now, this folder is being accessed for these conditions....
    not a hard coded list.
-------------------------------------------
032 03/26/2020 - Brian Twardy
MCGA: 220955
SOM Task:  TASK3473096
Requester: Cathy Oparaocha
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
For displaying dosing weight, added Recurring Clinic encounter type to logic used by the Clinic and
Recurring Outpatient encounter types. Otherwise, these Recurring Clinic encounters are treated as Inpatients, and
the dosing weight will often be missing on the banner bar
-------------------------------------------
033 04/08/2020 - Brian Twardy   (actually... in P41: 04/14/2020)
MCGA: 221361 RUSH:  Add new Isolation Type in the Codeset for the "Patient Isolation" order for "COVID19"
SOM Task: TASK3513677  (ad hoc task under the parent RITM in SOM)
Requesters:  Hilary Poan, Joel McAlduff, etc
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
COVID-19 update has been made to the isolation field. If COVID19 is an isolation type,
display it first among the isolation types (if there are multiple types).
NOTE: In P41, the patient isolation order comments sometimes contain "@NEWLINE". This is now being filtered out.
-------------------------------------------
034 07/21/2020 - Brian Twardy
MCGA: 222336
SOM Task: TASK3691033
Requesters: Joel McAlduff
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
Now, four orders, rather than just one, will be used to order Code Status. The three new ones are
  - Code Status Full Code
  - Code Status Do Not Resuscitate (Allow all pre-arrest interventions)
  - Code Status DNR and Pre-arrest Limitations
-------------------------------------------
035 01/08/2021 - Brian Twardy
MCGA: n/a
SOM Task: n/a
Requesters: Joel McAlduff
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
Another critical alert problem was added to the *Alerted Critical Conditions* folder. This new problem
is "ADA Support Peraon Required".  A small, but important, revision was needed for the banner bar to pick
this new problem up and display it.  Dr McAlduff developed a rule to have this problem added to a patient's record, and
this rule is a bit different than the other problems in the above mentioned folder. That is why the
revision was made to this script today, after first testing it out with Dr McAlduff in B41 last evening.
-------------------------------------------
036 01/21/2021 - Brian Twardy
MCGA: 224234
SOM Task: TASK3992570
Requesters: Joel McAlduff
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
Added insurance information by appending it after the Primary RN data in the patient banner for emergency, inpatient and
observation, etc encounters (any that would display the Primary RN). We are doing this similarly to what we did in 2016
for ambulatory encounters. (See the earlier modification, #012 12/28/2016)
-------------------------------------------
037 11/18/2021 - Brian Twardy
MCGA: n/a
SOM RITM/Task: RITM2716301 / TASK4918080
Requesters: Debbie Ellerby of GUH  (and many others due to a new rule being implemented by Rose Miranda. That rule's MCGA
			was this: MCGA229317 - C Auris ICP Isolation Rules RE: banner bar
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
We are now trimming off "Ordered by Discern :" from the Patient Isolation order's comments. This is just another text string
that we be filtering out... like many other that we are already filtering out.
-------------------------------------------
038 01/10/2022 - Brian Twardy   11/21/2021 - in B41
MCGA: 230858
SOM RITM/Task: RITM2746397  / TASK4991904
Requesters: Edward Woo (President of MMG), Rohan Korah, John Gutwald, and many moe
CCL Source:  cust_script:0v1_mhgrdc_custom_banner_x.prg   (no name change)
The Community Record Number (aka EMPI, CMRN, EAD) has been added to the banner bar for all encounter types.
-------------------------------------------
039 12/05/2022 - Brian Twardy   (09/27/2022 - in B41)
MCGA: 235341
SOM RITM/Task: RITM3101714 / TASK5691377
Requesters: Dr Stephen Evans, Dr Joel Mcalduff, and others associated with the Acute Case Management project
CCL Source: 0v1_mhgrdc_custom_banner_x.prg   (no name change)
Added Anticipated Discharge Date for the general inpatient types to the last custom field. Look for the "ADOD" label. Nothing will
appear if no ADOD has been charted for a general inpatient type of encounter type, such as inpatient, observation, etc.
-------------------------------------------
040 03/24/2023 - Brian Twardy  
(1)	MCGA: 236250
	SOM RITM/Task: RITM3180763 / TASK5839908
	Requesters: Jennifer Mccraw, Camille Muñoz, Krystal Thousand, and many more
	CCL Source: 0v1_mhgrdc_custom_banner_x.prg   (no name change)
	For Outpatients, Recurring Clinic, etc...  voicemail indicator has been added.  This is a task for the Tonic
	project.
(2) MCGA: 237806
	SOM RITM/Task: RITM3317412 / TASK6095060
	Requesters: Ryan Van Oosten and many more
	CCL Source: 0v1_mhgrdc_custom_banner_x.prg   (no name change)
	EMPI (aka CMRN) now includes the person alias, which adds 1 or 2 leading zeroes
-------------------------------------------
041 08/04/2023 - Brian Twardy
MCGA: n/a
SNOW incident: INC0273374   (the incident is in the queue of the MSH-Medconnect Core System team)
Requesters: : Olutoyin Idowu, and many others
CCL Source: 0v1_mhgrdc_custom_banner_x.prg   (no name change)
Primary Insurance has been tweaked to pull in the secondary insurance if there was no primary insurance.
-------------------------------------------
042a 09/20/2023 - Brian Twardy  
MCGA: 240810  (allergies)
SNOW RITM/Task: RITM0030732 / SCTASK0046393
Requesters: Camille Munoz, Jim McKusky, Carol Hawkins, and many more
Exclude any allergies with a reaction status of canceled, Resolved, or Do Not Use.
-------------------------------------------
043 10/25/2023 - Brian Twardy
MCGA: n/a
SNOW incident: INC0382897
Requesters: : Mark Marino and Karthi Dandapani
CCL Source: 0v1_mhgrdc_custom_banner_x.prg   (no name change)
A SNOMED problem is being added back real quickie, until the *Alerted Critical Conditions* folder (the NOM_CAT_LIST table) 
can be updated.
-------------------------------------------
044 12/05/2023 - David Smith
MCGA: 238895 (assigned nurse) 
SNOW RITM/Task: RITM0017752 / SCTASK0023738   (assigned nurse)
Requesters: Hilary Poan, Ashley Shelter, Leah Seiler, Christy Bryant, and many more
Replace the Primary RN in the banner bar with the Assigned Nurse  

-------------------------------------------
045 05/13/2024 - Jennifer King
MCGA: 347702
Add active_ind qualification to insurance

*****************************************************************************************************************************/
 
drop program 0v1_mhgrdc_custom_banner_x go
create program 0v1_mhgrdc_custom_banner_x
 
DECLARE PRODUCTION_DOMAIN = vc with constant("P41")			; 018 09/14/2018 for CUSTOMFIELD1
 
DECLARE  CUSTOMFIELD5 ( NULL ) =  NULL  WITH  PROTECT
DECLARE  CUSTOMFIELD4 ( NULL ) =  NULL  WITH  PROTECT
DECLARE  CUSTOMFIELD3 ( NULL ) =  NULL  WITH  PROTECT
DECLARE  CUSTOMFIELD2 ( NULL ) =  NULL  WITH  PROTECT
DECLARE  CUSTOMFIELD1 ( NULL ) =  NULL  WITH  PROTECT
DECLARE  PARSEREQUEST ( NULL ) =  NULL  WITH  PROTECT
DECLARE  ICUSTOMFIELDINDEX  =  I4  WITH  NOCONSTANT (0 ), PROTECT
DECLARE  ICUSTFIELDCNT  =  I4  WITH  CONSTANT ( SIZE ( REQUEST -> CUSTOM_FIELD , 5 )), PROTECT
 
;--------------------------------------------------------------------------
; 038 01/10/2022  Added for the EMPI # (CMNR)
 
declare cmrn_display = vc with noconstant('')
 
Select into "nl:"
from
	encounter e,
	person_alias   p
plan e
	where e.encntr_id = request->encntr_id
join P where p.person_id = e.person_id
	and p.person_alias_type_cd in (2.00)   ; 2 is CMRN
	and p.active_ind = 1
	and p.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
 
order by p.end_effective_dt_tm, p.person_alias_id
 
detail
;	cmrn_display = trim(substring(1, 40, p.alias))									; 040 03/24/2023 Replaced. See below.
	cmrn_display = trim(substring(1, 40, cnvtalias(p.alias,p.alias_pool_cd)))		; 040 03/24/2023 Replacement.
with nocounter
 
;--------------------------------------------------------------------------
 
 
SET  REPLY -> STATUS_DATA -> STATUS  = "F"
 
SET  STAT  =  ALTERLIST ( REPLY -> CUSTOM_FIELD ,  ICUSTFIELDCNT )
 
 CALL PARSEREQUEST ( NULL )
 
SET  STAT  =  ALTERLIST ( REPLY -> CUSTOM_FIELD ,  ICUSTOMFIELDINDEX )
 
SET  REPLY -> STATUS_DATA -> STATUS  = "S"
 
SUBROUTINE   PARSEREQUEST  ( X  )
	FOR (  IND  = 1  TO  ICUSTFIELDCNT  )
 
		CASE (  REQUEST -> CUSTOM_FIELD [ IND ]-> CUSTOM_FIELD_SHOW  )
			 OF 1 :
			 	CALL CUSTOMFIELD1 ( NULL )
			 OF 2 :
			 	CALL CUSTOMFIELD2 ( NULL )
			 OF 3 :
			 	CALL CUSTOMFIELD3 ( NULL )
			 OF 4 :
			 	CALL CUSTOMFIELD4 ( NULL )
			 OF 5 :
			 	CALL CUSTOMFIELD5 ( NULL )
		ENDCASE
	ENDFOR
END ;Subroutine
 
; ---------------------------------------------------------------------------------------------------------------------
; 017 09/14/2018   	The below CUSTOMFIELD1 field was displaying the Primary Care Provider. Now, it will display
;                  	the following:
;					- For Outpatients, Recurring Clinic, etc : Patient Home and Alternate phone#s
;					- For Inpatinets, Observation, etc : Attending Physician --AND-- the Primary RN
; ---------------------------------------------------------------------------------------------------------------------
 
;; [The old CCL code for CUSTOMFIELD1 was here. In February 2020, the green lines have been deleted.]
 
; ---------------------------------------------------------------------------------------------------------------------
; 017 09/14/2018   	Here is the replacement for CUSTOMFIELD1
; ---------------------------------------------------------------------------------------------------------------------
 
SUBROUTINE CUSTOMFIELD1 ( NULL)
 
Declare encntr_type_cd_c1 = f8 with noconstant(0.00)		; The suffix of "c1" stands for Customefield1.
 
Select into "nl:"
from encounter e
where e.encntr_id = request->encntr_id
detail
	encntr_type_cd_c1 = e.encntr_type_cd
with nocounter
 
If (encntr_type_cd_c1 in (3012539.00,	;	Outpatient Message
						  5043178.00,	;	Clinic
						   309314.00,	;	Recurring Clinic
						  5045671.00, 	;	Recurring Outpatient
						  5762781.00))	;	Client
 
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; 017 09/14/2018  We are getting the patient's phone numbers for ambulatory patients only
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	Declare pat_home_phone = vc with noconstant("")
	Declare pat_bus_phone = vc with noconstant("")
 
	select into "nl:"
	from
		phone p
	plan p
		where p.parent_entity_id = request->person_id and
	  	   	  p.parent_entity_name = "PERSON" and
	  		  p.active_ind = 1 and
	  		  p.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3) and
	  		  p.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3) and
  		  	  p.phone_num_key != "000*" and
  		  	  p.phone_num_key != "999*"
	order by p.beg_effective_dt_tm
	detail
		if (p.phone_type_cd =  170.00) ; Home
			pat_home_phone = trim(substring(1,30,p.phone_num))
;		elseif (p.phone_type_cd = 161.00) ;	Alternate						; swapped out for the Business phone. See below.
;			pat_alt_phone = trim(substring(1,30,p.phone_num))
		elseif (p.phone_type_cd = 163.00) ;	Business
			pat_bus_phone = trim(substring(1,30,p.phone_num))
		endif
	with nocounter
 
	set ICUSTOMFIELDINDEX = ICUSTOMFIELDINDEX + 1
 
;038 01/10/2022 The below CUSTOM_FIELD_DISPLAY field was revised to include the EMPI #(CMNR)
 
	set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY =
													(If (pat_home_phone > " ")			; There is a Home phone
														(If (pat_bus_phone > " ")
															build2("EMPI: ", CMRN_display, " | Primary: ", pat_home_phone,
															       "  Secondary: ", pat_bus_phone)
														 Else
															build2("EMPI: ", CMRN_display, " | Primary: ", pat_home_phone)
														 Endif)
													 Else		; There is no Home phone
														(If (pat_bus_phone > " ")
															build2("EMPI: ", CMRN_display, " | Secondary: ", pat_bus_phone)
														 Else
															""
														 Endif)
													 endif)
; -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -
;040 03/24/2023 The below CUSTOM_FIELD_DISPLAY field was revised to include the voicemail indicator.
; -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -
	declare PRIMARYPHONEVOICEMAIL_cd =  f8 with constant(uar_get_code_by("DISPLAY_KEY",72,"PRIMARYPHONEVOICEMAIL"))
	declare PRIMARYPHONEVOICEMAIL =  vc with noconstant('')
 
	select into "nl:"
	from
		clinical_event ce
	plan ce
		where ce.person_id = request->person_id and
	  	   	  ce.event_cd = PRIMARYPHONEVOICEMAIL_cd and
	  	   	  ce.result_status_cd in (25.00, 34.00, 35.00) and
	  	   	  ce.valid_until_dt_tm > cnvtdatetime(curdate, curtime3)
	order by ce.event_end_dt_tm 
	detail
		PRIMARYPHONEVOICEMAIL = trim(ce.result_val)
	with nocounter

	declare text_len_cust_field_1_i4 = i4 with noconstant(0)
	declare cust_field_1_buff = vc with noconstant('')
	
	set text_len_cust_field_1_i4 = 
							textlen(REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX]->CUSTOM_FIELD_DISPLAY)

	set REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX]->CUSTOM_FIELD_DISPLAY =
							build2(REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX]->CUSTOM_FIELD_DISPLAY,
								    " | Primary VM for Results: ",			; 03/24/2023 New way
								    trim(PRIMARYPHONEVOICEMAIL))			; 03/24/2023 New way

; -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -
 
	set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 1
 
Else 	; Paired with If (encntr_type_cd_c1 in(......))
 
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; 017 09/14/2018 Immediately below, processing for inpatients (non-ambulatory encounter types)
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	; This record structure is used to load the Primary Nurse for this patient for this encounter
 
	record rn (
	01 cnt = i4
	01 qual [*]
	   02 person_id = f8
	   02 encntr_id = f8
	   02 rn_person_id = f8
	   02 rn = vc
	   02 beg_effective_dt_tm_ppr = dq8
	   02 loc_nurse_unit_cd = f8
;	   02 loc_nurse_unit_display = vc
	)
 
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; CUSTOMFIELD1...
	; 017 09/14/2018 We are getting the Attending physician now (for an inpatient, aka, non-ambulatory encounter type)
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	declare attending_name = vc with noconstant("")
 
	Select into "nl:"
	From
		encntr_prsnl_reltn  epr,
		prsnl p
 
	plan epr
		where epr.encntr_id = request->encntr_id and
			  epr.encntr_prsnl_r_cd = 1119.00 and	;	Attending Physician
			  epr.active_ind = 1 and
			  cnvtdatetime(curdate, curtime3) between epr.beg_effective_dt_tm and epr.end_effective_dt_tm
	join p
		where p.person_id = epr.prsnl_person_id
	Detail
		attending_name = TRIM(P.name_full_formatted, 3)
	with nocounter
 
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 044 12/05/2023
; The Primary RN has been replaced with the Assigned RN. You will find the new logic farther down, right after the grren CCL that
; you see immediaterly below.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
;	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;	; CUSTOMFIELD1... (continued)
;	; 017 09/14/2018 We are getting the Primary Nurse for this patient now (for an inpatient, aka, non-ambulatory encounter type)
;	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 
;	declare PRIMARYNURSE_CD = f8 with constant(uar_get_code_by ("DISPLAYKEY",331, "PRIMARYNURSE"))			;   1614315707.00
;	declare Primary_nurse_name = vc with noconstant("")
; 
;	Select into "nl:"
;	From person_prsnl_reltn ppr,
;		 prsnl p
;	Plan ppr
;		where ppr.person_id  = request->person_id and		; Looking for this patient. We will filter down to the encntr later
;		      ppr.active_ind = 1 and
;		      ppr.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3) and
;		      ppr.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3) and
;		      ppr.person_prsnl_r_cd =  PRIMARYNURSE_CD 					; 1614315707.00
;	join p
;		where p.person_id = ppr.prsnl_person_id
;	Order by  ppr.beg_effective_dt_tm
; 
;	head report
;		cnt = 0
;	Detail
;		cnt = cnt + 1
;		stat = alterlist(rn->qual,cnt)
;		rn->qual[cnt].encntr_id = request->encntr_id
;		rn->qual[cnt].person_id = request->person_id
;		rn->qual[cnt].rn_person_id = ppr.prsnl_person_id
;		rn->qual[cnt].rn = trim(substring(1,150,p.name_full_formatted))
;		rn->qual[cnt].beg_effective_dt_tm_ppr = ppr.beg_effective_dt_tm
;	with nocounter
; 
;	;-----------------------------------------------------------------------------------------------------
;	; 017 09/14/2018  CUSTOMFIELD1... (continued)
;	; Checking the relationship begin date for each of the selected Primary Nurses against the patient's
;	; location history... and matching it against the patient's currect location for this encounter.
;	;-----------------------------------------------------------------------------------------------------
;;; 	Declare primary_nurse_loc_ind = i2 with noconstant(0)
;;	Declare cnt_elh = i2 with noconstant(0)										; 021 01/18/2019 no longer needed
;	declare loc_nurse_unit_cd = f8 with noconstant(0.00)
; 
;	select into "nl:"
;	from encounter e
;	where e.encntr_id = request->encntr_id
;	detail
;		loc_nurse_unit_cd = e.loc_nurse_unit_cd
;	with nocounter
; 
;	select into "nl:"
;	from (dummyt d with seq = size(rn->qual,5)),
;	      encounter e,
;		  encntr_loc_hist elh_dis,					; 026 05/12/2019 New table - leaving/discharging the unit
;		  encntr_loc_hist elh_ent					; 026 05/12/2019 New table - entering the unit
; 
;	plan d
; 
;	join e
;		where e.person_id = rn->qual[d.seq].person_id
; 
;	Join elh_dis			; associated with the leaving unit					; 026 05/12/2019 New table
;		where
;		    elh_dis.encntr_id = e.encntr_id and
;	   	   (elh_dis.end_effective_dt_tm != cnvtdatetime("31-DEC-2100 00:00:00") or
;	  	    elh_dis.active_ind = 1) and
;		    elh_dis.transaction_dt_tm >= cnvtdatetime(rn->qual[d.seq].beg_effective_dt_tm_ppr)
; 
;	Join elh_ent			; associated with the entering unit					; 026 05/12/2019 New table
;		where
;	 		elh_ent.encntr_id = elh_dis.encntr_id and
; 	       (elh_ent.end_effective_dt_tm != cnvtdatetime("31-DEC-2100 00:00:00") or
;	  	    elh_ent.active_ind = 1) and
;	  	    elh_ent.transaction_dt_tm <=  cnvtdatetime(rn->qual[d.seq].beg_effective_dt_tm_ppr) and
;	  	    elh_ent.loc_nurse_unit_cd = loc_nurse_unit_cd and
;;;	  		elh_ent.transaction_dt_tm  = (select max(sub.transaction_dt_tm)					; 030 01/29/2020 replaced
;	  		elh_ent.encntr_loc_hist_id  = (select max(sub.encntr_loc_hist_id)				; 030 01/29/2020 replacement
;	  									  from encntr_loc_hist sub
;	  									  where sub.encntr_id = elh_ent.encntr_id and
;	  									        sub.transaction_dt_tm < elh_dis.transaction_dt_tm and	;  elh_dis used here !!!
;									           (sub.end_effective_dt_tm != cnvtdatetime("31-DEC-2100 00:00:00") or
;	  	    								    sub.active_ind = 1)
;	  									  with nocounter,orahintcbo ("index (sub xie1encntr_loc_hist)")) and
;	  	    elh_ent.transaction_dt_tm <= cnvtdatetime(curdate, curtime3)
; 
;	order by elh_ent.transaction_dt_tm
; 
;	Detail
;		If (elh_ent.loc_nurse_unit_cd = loc_nurse_unit_cd)			; We may be doing this 'unit check' in the join elh_ent
;			If (primary_nurse_name <= " ") 			; If ( No RN has been found yet)
;				primary_nurse_name = trim(substring(1,140,rn->qual[d.seq].rn))			; We only want the RNs name, if there is only one.
;			ElseIf (primary_nurse_name != rn->qual[d.seq].rn)  ; Elseif ( an RN has been found and it is not
;				primary_nurse_name = 'Multiple for Unit'								; 021 01/18/2019 greened out. no longer needed here
;			endif
;	    endif
;	with nocounter,  orahintcbo ("index (elh_dis xie1encntr_loc_hist)")
; 
;	If (primary_nurse_name <= " ")		; 026 05/12/2019 New "if"
;										;            only matters if there was no Primary RN found above and the very last
;										;            ELH row for this encounter has for "our" unit and the ELH.Transaction_dt_tm
;										;            fell after the ppr beg_effective_dt_tm. This happens once in a grea while.
;		Select into "nl:"
;		from (dummyt d with seq = size(rn->qual,5)),
;			 encntr_loc_hist elh
;		Plan d
;			where rn->qual[d.seq].encntr_id = request->encntr_id
;		join elh
;			where elh.encntr_id = rn->qual[d.seq].encntr_id and
;		   		  elh.transaction_dt_tm <= cnvtdatetime(rn->qual[d.seq].beg_effective_dt_tm_ppr) and
;		   		  elh.loc_nurse_unit_cd = loc_nurse_unit_cd and
;;		   		  elh.transaction_dt_tm = (select max(sub.transaction_dt_tm)					; 030 01/29/2020 replaced
;		   		  elh.encntr_loc_hist_id = (select max( elh.encntr_loc_hist_id)					; 030 01/29/2020 replacement
;		    							   from encntr_loc_hist sub
;									       where sub.encntr_id = elh.encntr_id and
;									             sub.loc_nurse_unit_cd = loc_nurse_unit_cd and
;									            (sub.end_effective_dt_tm != cnvtdatetime("31-DEC-2100 00:00:00") or
;	  	    								     sub.active_ind = 1)
;									       with nocounter, orahintcbo ("index (sub xie1encntr_loc_hist)"))
;		detail
;;			primary_nurse_name = trim(substring(1,140,rn->qual[d.seq].rn))						; 027 07/16/2019 Greened out. See below
;			If (primary_nurse_name <= " ") 														; 027 07/16/2019 replacement
;				primary_nurse_name = trim(substring(1,140,rn->qual[d.seq].rn))					; 027 07/16/2019 replacement
;			ElseIf (primary_nurse_name != rn->qual[d.seq].rn)  									; 027 07/16/2019 replacement
;				primary_nurse_name = 'Multiple for Unit'										; 027 07/16/2019 replacement
;			endif																				; 027 07/16/2019 replacement
; 
;		with nocounter, time = 10
;	endif
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 043 12/05/2023
; The Primary RN has been replaced with the Assigned RN. The old logic is above. The new logic is below.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	declare Primary_nurse_name = vc with noconstant("")
	declare nurse_cnt = i2 with noconstant(0)
	
	select into "nl:"
		from  dcp_shift_assignment   dsa,
			  prsnl   p
	plan dsa
		where dsa.encntr_id = request->encntr_id and 
		  	  dsa.active_ind = 1 and
		  	  dsa.end_effective_dt_tm > cnvtdatetime(curdate, curtime3) and
		  	  ;;;;dsa.assigned_reltn_type_cd  = 1131027299.00 ;Nurse    11/30/2023 - Remove
		  	  dsa.assign_type_cd =  3542542.00	;Nursing				11/30/2023 - Add
	join p 
		where p.person_id = dsa.prsnl_id and
		      p.position_cd in (101750722.00,	;RN/Charge Nurse
	  						    101750863.00,	;RN/Charge Nurse w/MedReschedule
	  						    2649552595.00,	;Women's Health Nurse 				11/30/2023 - Add
							    2203749621.00,	;Women's Health Nurse w/MedResched  11/30/2023 - Add
							    1022475753.00,	;NRH CIR RN/Charge					11/30/2023 - Add
	  						    101750868.00)	;BH Nurse
	order by
		 dsa.assignment_id ; dsa.beg_effective_dt_tm desc,
;;	detail
;;		Primary_nurse_name = trim(substring(1,140,p.name_full_formatted))
	detail
		nurse_cnt = nurse_cnt + 1
		If (nurse_cnt = 1)
			primary_nurse_name = trim(substring(1,140,p.name_full_formatted))
		elseif (nurse_cnt = 2)
			primary_nurse_name = build2(primary_nurse_name, "; ", trim(substring(1,140,p.name_full_formatted)))
		else
			primary_nurse_name = "Multiple"
		endif
	with nocounter

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 042 08/08/2023
; The end of the new Assigned RN logic.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
   ; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
 
	set ICUSTOMFIELDINDEX = ICUSTOMFIELDINDEX + 1
 
;038 01/10/2022 The below CUSTOM_FIELD_DISPLAY was revised to include the EMPI# (CMNR)
 
;	set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY =
;													(If (attending_name <= " ")
;														build2("Prim RN: ", Primary_nurse_name)
;													 Else
;													 	build2("Att: ",attending_name, " | Prim RN: ", Primary_nurse_name)
;													 endif)
 
;038 01/10/2022 The above CUSTOM_FIELD_DISPLAY was revised to include the EMPI #(CMNR)	See below.
 
	set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY =
													(If (attending_name <= " ")
														build2("EMPI: ", CMRN_display, " | Assgn Nurse: ", Primary_nurse_name)
													 Else
													 	build2("EMPI: ", CMRN_display, " | Att: ", attending_name,
													 	       " | Assgn Nurse: ", Primary_nurse_name)
													 endif)
	set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 1
 
 
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&
	; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	; 036 01/21/2021 New. Patient's Insurance Information for inpatients (aka inpats, EDs, Observs, etc) will be
	;				 appended now.
	; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
 
	declare  var_pri_insur_disp_ip = vc with noconstant('')
	declare  var_pri_member_nbr_ip = vc with noconstant('')
 
	select into "nl:"
	from
		  encntr_plan_reltn epr
		, health_plan hp
		, organization o
	plan epr
		where epr.encntr_id =  REQUEST->ENCNTR_ID
		  and epr.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
		  and epr.active_ind = 1 	;045 - added
	join hp
		where hp.health_plan_id = outerjoin(epr.health_plan_id)
	join o
		where o.organization_id = outerjoin(epr.organization_id)
	order by  epr.priority_seq
	detail
		if (epr.priority_seq = 1)			;primary insurance
		    if(hp.plan_desc <= " " )
			    var_pri_insur_disp_ip = o.org_name
			    var_pri_member_nbr_ip = epr.member_nbr
		    else
			    var_pri_insur_disp_ip = hp.plan_desc
			    var_pri_member_nbr_ip = epr.member_nbr
		    endif
		endif
		; -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -		
		; 041 08/04/2023  New
		; -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -		
		if (epr.priority_seq = 2 and			;non-primary insurance
		    var_pri_insur_disp_ip = '')
		    if(hp.plan_desc <= " " )
			    var_pri_insur_disp_ip = o.org_name
			    var_pri_member_nbr_ip = epr.member_nbr
		    else
			    var_pri_insur_disp_ip = hp.plan_desc
			    var_pri_member_nbr_ip = epr.member_nbr
		    endif
		endif
		; -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -     -		
		
	with nocounter
 
	set reply->custom_field[icustomfieldindex].custom_field_display =
			(If (reply->custom_field[icustomfieldindex].custom_field_display <= " ")
					build2("Ins: ",trim(var_pri_insur_disp_ip))
			 Else
					build2(trim(reply->custom_field[icustomfieldindex].custom_field_display), " | ",
						   "Ins: ",trim(var_pri_insur_disp_ip))
			 endif)
 
	; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	; 036 01/21/2021 Ends here
	; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
 
Endif	; Paired with If (encntr_type_cd_c1 in(......))
 
END ;Subroutine
 
; ---------------------------------------------------------------------------------------------------------------------
SUBROUTINE CUSTOMFIELD2  ( NULL  )
	;Allergies(change sort order): Latex 1st, Meds (sort by severity & then alpha), Food & Environment (sort by severity & then alpha)
	free record ALLERGIES_REC
	record ALLERGIES_REC
	(
		1 allergies_str = vc
		1 qual[*]
			2 a_name = vc
			2 a_subst_type = vc
			2 a_subst_sort = i2
			2 a_severity = vc
			2 a_severity_sort = i2
			2 reactions[*]
				3 r_name = vc
	)
 
	declare cancelled_cd = f8 with protect, constant(uar_get_code_by("MEANING",8,"CANCELLED"))
	declare react_stat_cancel_cd = f8 with protect, constant(uar_get_code_by("MEANING",12025,"CANCELED"))
	declare food_allergy_cd = f8 with protect, constant(uar_get_code_by("MEANING",12020,"FOOD"))
	declare drug_allergy_cd = f8 with protect, constant(uar_get_code_by("MEANING",12020,"DRUG"))
	declare envr_allergy_cd = f8 with protect, constant(uar_get_code_by("MEANING",12020,"ENVIRONMENT"))
	declare mild_cd = f8 with protect, constant(uar_get_code_by("DISPLAY_KEY",12022,"MILD"))
	declare moderate_cd = f8 with protect, constant(uar_get_code_by("DISPLAY_KEY",12022,"MODERATE"))
	declare severe_cd = f8 with protect, constant(uar_get_code_by("DISPLAY_KEY",12022,"SEVERE"))
	declare crit_cd = f8 with protect, constant(uar_get_code_by("DISPLAY_KEY",12022,"CRITICAL"))
 
	declare r_cnt        = i4 with protect, noconstant(0)
	declare a_cnt		 = i4 with protect, noconstant(0)
	declare allergy_list = vc with protect, noconstant('')
	declare divider 	 = vc with protect, noconstant(' ')
 
	;initialize the allergy string
	set ALLERGIES_REC->allergies_str = "NOT RECORDED" ; 008 Changed from "No Allergies Recorded" 	 ; 043 10/25/2023  Real line!!!
;	set ALLERGIES_REC->allergies_str = "NOT RECORDED," ; 008 Changed from "No Allergies Recorded"    ; 043 10/25/2023  For testing
 
	;*******************************
	;* Collect patient's allergies *
	;*******************************
	select into "nl:"
		sort_key = cnvtupper(build(a.substance_ftdesc,n1.source_string)),
		a_allergy = trim(a.substance_ftdesc,3),
		n_allergy = trim(n1.source_string,3),
		r_reaction = trim(r.reaction_ftdesc,3),
		n_reaction = trim(n2.source_string,3),
		a_subst_type = uar_get_code_display(a.substance_type_cd),
		a_subst_sort = 	if(cnvtupper(build(a.substance_ftdesc,n1.source_string)) = "LATEX")
							1
						elseif(a.substance_type_cd = drug_allergy_cd)
							2
						elseif(a.substance_type_cd in (food_allergy_cd,envr_allergy_cd))
							3
						else
							4
					   	endif,
		a_severity = uar_get_code_display(a.severity_cd),
		a_severity_sort = 	if(a.severity_cd = mild_cd)
								4
							elseif(a.severity_cd = moderate_cd)
								3
							elseif(a.severity_cd = severe_cd)
								2
							elseif(a.severity_cd = crit_cd)
								1
							else
								5
							endif
	from
		allergy a,
		dummyt da1,
		nomenclature n1,
		dummyt da2,
		reaction r,
		dummyt da3,
		nomenclature n2
	plan a
		where a.person_id = REQUEST->PERSON_ID
		and a.active_ind = 1
		and (a.end_effective_dt_tm between cnvtdatetime(curdate,curtime3) and cnvtdatetime("31-DEC-2100 23:59:59")
			;002 added 23:59:59
				or a.end_effective_dt_tm = NULL)
		and a.data_status_cd != cancelled_cd
		and a.cancel_dt_tm = NULL
;		and a.reaction_status_cd != react_stat_cancel_cd			; 042 09/20/2023 replaced.
		and a.reaction_status_cd not in (react_stat_cancel_cd,		; 042 09/20/2023 replacement.
										 639002.00)					; Resolved or "Do Not Use"
		
	join da1
	join n1
		where n1.nomenclature_id = a.substance_nom_id
;;;;;;;;;;;;;;;;		and n1.active_ind = 1   			; 017 06/26/2018  Greened out today
		and n1.data_status_cd != cancelled_cd
	join da2
	join r
		where r.allergy_id = a.allergy_id
	join da3
	join n2
		where n2.nomenclature_id = r.reaction_nom_id
	order by a_subst_sort, a_severity_sort, sort_key
 
	head a.person_id
		allergy_list = ""
		divider = " "
		a_cnt = 0
 
	head sort_key
		allergy = trim(build(cnvtupper(substring(1,1,a_allergy)),substring(2,textlen(a_allergy),a_allergy),
					  cnvtupper(substring(1,1,n_allergy)),substring(2,textlen(n_allergy),n_allergy)),3)
		a_cnt = a_cnt + 1
		r_cnt = 0
 
		stat = alterlist(ALLERGIES_REC->qual, a_cnt)
		ALLERGIES_REC->qual[a_cnt]->a_name = replace(allergy,'"',"'")
		ALLERGIES_REC->qual[a_cnt]->a_subst_type = a_subst_type
		ALLERGIES_REC->qual[a_cnt]->a_subst_sort = a_subst_sort
		ALLERGIES_REC->qual[a_cnt]->a_severity = a_severity
		ALLERGIES_REC->qual[a_cnt]->a_severity_sort = a_severity_sort
 
	detail
		r_cnt = r_cnt + 1
		if(a_cnt = 1 or r_cnt = 1)
		  allergies = trim(allergy,3)
 
	 		if(trim(r_reaction,3) != "" OR trim(n_reaction,3) != "")
			  stat = alterlist(ALLERGIES_REC->qual[a_cnt]->reactions, r_cnt)
			  ALLERGIES_REC->qual[a_cnt]->reactions[r_cnt]->r_name = replace(concat(trim(r_reaction), trim(n_reaction)),'"',"'")
			endif
		elseif(trim(r_reaction,3) != "" OR trim(n_reaction,3) != "")
		  allergies = notrim(concat(trim(allergies,3),", "))
 
		  stat = alterlist(ALLERGIES_REC->qual[a_cnt]->reactions, r_cnt)
		  ALLERGIES_REC->qual[a_cnt]->reactions[r_cnt]->r_name = replace(concat(trim(r_reaction), trim(n_reaction)),'"',"'")
		endif
 
	foot sort_key
		allergy_list = concat(trim(allergy_list),divider,trim(allergies))
		divider = ", "
 
	foot a.person_id
 
		if(trim(allergy_list,3) > '')
			ALLERGIES_REC->allergies_str = replace(allergy_list, ",", ", ")					; 043 10/25/2023  This is the actual one.
;			ALLERGIES_REC->allergies_str = build2(',',replace(allergy_list, ",", ", "))		; 043 10/25/2023  For testing
 
		endif
 
	with nocounter, outerjoin = da1, outerjoin = da2, outerjoin = da3
		,orahintcbo("index(a xif7allergy)","index(r xif2reaction)","index(n1 xpknomenclature)")
 
	set ICUSTOMFIELDINDEX = ICUSTOMFIELDINDEX + 1
	set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY =
														ALLERGIES_REC->allergies_str
	set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 2
 
	;call echorecord(ALLERGIES_REC)
END ;Subroutine
 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SUBROUTINE CUSTOMFIELD3  ( NULL  )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 	SET ICUSTOMFIELDINDEX = ICUSTOMFIELDINDEX + 1 ; 008 Brought it outside of HEAD CE2.event_cd because previous field was
 												  ;     displaying values from allergies in this field if curqual was 0
 
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; 024 03/19/2019 (was 019 11/26/2018)
	; Added DECEASED PATIENT to the beginning of ths Critial Alerts field for decesased patient.
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;	set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY = "LEAD OFF"		; Just for testing
	;	set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 3				; Just for testing
 
		declare deceased_patient_ind = i2 with noconstant(0)
	;	set	deceased_patient_ind = 1															; Just for testing
 
	select
	from  person   p
	plan p
		where p.person_id = REQUEST -> PERSON_ID and
			  p.deceased_cd = 684729.00   ; Yes
	detail
		deceased_patient_ind = 1
		REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY = "DECEASED PATIENT"
		REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 3
	with nocounter
 
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	;
	; 029 10/18/2019 Code Status overhauled.
	;                Since order details are being included for DNR with conditions Code Status, we are finally
	;				 going to look soley at the Code Status order (and it's details), rather than depending on a
	;				 rule creating a clinical_event row. See the new Code Status CCL immediately below.
	;				 A large swath of greened out CCL code from October 2019 was removed in February 2020.
	;
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	; [Old CCL was here. Look in the archives if you are curious.]
 
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; 029 10/18/2019 Code Status overhauled... replacement starts now
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	declare RECURRINGOUTPATIENT_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",71,"RECURRINGOUTPATIENT"))
	declare CLINIC_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",71,"CLINIC"))
 
	declare codestatus_cd = f8 with constant(uar_get_code_by("DISPLAYKEY", 200, "CODESTATUS"))
	declare CODESTATUSDNRANDPREARRESTLIMITATIO_cd = f8 																		; 034 09/01/2020 New
									with constant(uar_get_code_by("DISPLAYKEY", 200, "CODESTATUSDNRANDPREARRESTLIMITATIO"))
	declare CODESTATUSDONOTRESUSCITATEALLOWAL_cd = f8 																		; 034 09/01/2020 New
									with constant(uar_get_code_by("DISPLAYKEY", 200, "CODESTATUSDONOTRESUSCITATEALLOWAL"))
	declare CODESTATUSFULLCODE_cd = f8 																						; 034 09/01/2020 New
									with constant(uar_get_code_by("DISPLAYKEY", 200, "CODESTATUSFULLCODE"))
 
	declare code_status_oef = vc with noconstant ("")
	declare code_status_intervs = vc with noconstant ("")
	declare code_status_final = vc with noconstant ("")
	declare cnt_cs = i2 with noconstant(0)
 
 
	; See?  there are no interventions for this one order. At least. there aren't suppose to be. That's why it's handled here in
	; it's own Select. If one day there are interventions, then the next select will include them.
 
	Select into "nl"
	from orders o
	plan o
		where  o.person_id = request->person_id and
			   o.encntr_id = request->encntr_id and
			   o.catalog_cd = CODESTATUSFULLCODE_cd  and	; Code Status Full Code
			   o.order_status_cd in (2543.00, 		; Completed
	       							 2550.00) and 	; Ordered
	       	   o.active_ind = 1
	Detail
			CODE_STATUS_OEF = uar_get_code_description(o.catalog_cd)
			CODE_STATUS_INTERVS = ''
 
	foot report
 
		CODE_STATUS_FINAL = CODE_STATUS_OEF
 
		ICUSTOMFIELDINDEX = 3
 
		If (deceased_patient_ind = 0)   ; 0 is "No"... or... anything but "Yes"
			REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY =
							trim(CODE_STATUS_OEF)
		Else
			REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY =
							build2(REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY,
								   "; ", trim(CODE_STATUS_OEF))
		Endif
	 	REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX]. CUSTOM_FIELD_INDEX = 3
 
	with nocounter
 
 
 
 
	Select into "nl"
	from orders o,
	     order_detail od,
		 oe_format_fields off,														; 029 10/28/2019 added
	     order_entry_format oef,													; 029 10/28/2019 added
 		 dummyt d,																	; 031 02/03/2020 new table
 		 order_comment oc,															; 031 02/03/2020 new table
 		 long_text lt																; 031 02/03/2020 new table
 
	plan o
		where  o.person_id = request->person_id and
			   o.encntr_id = request->encntr_id and
;			   o.catalog_cd = CODESTATUS_CD and   																	; 034 09/01/2020 Replaced. See below.
			   o.catalog_cd in (CODESTATUS_CD ,																		; 034 09/01/2020 Replacement. All 4 orders now
			   					CODESTATUSDONOTRESUSCITATEALLOWAL_cd,		; Code Status Do Not Resuscitate (Allow all pre-arrest interve
						  		CODESTATUSDNRANDPREARRESTLIMITATIO_cd,   	; Code Status DNR and Pre-arrest Limitations
								CODESTATUSFULLCODE_cd) and					; Code Status Full Code
			   o.order_status_cd in (2543.00, 		; Completed
	       							 2550.00) and 	; Ordered
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
 
	join d																		; 031 02/03/2020 new table
 
	join oc																		; 031 02/03/2020 new table
		where oc.order_id = (o.order_id) and
		      oc.comment_type_cd = 66.00 and ; order_comment
		      oc.action_sequence = (select max(sub.action_sequence)
		                            from order_comment sub
		                            where sub.order_id = oc.order_id and
		                                  sub.comment_type_cd = 66.00 ; order_comment
		                            with nocounter)
 
	join lt																			; 031 02/03/2020 new table
		where lt.long_text_id = outerjoin(oc.long_text_id)
 
;	order by o.orig_order_dt_tm, od.detail_sequence									; 029 10/28/2019 replaced
	order by o.orig_order_dt_tm, off.group_seq, od.action_sequence desc 			; 029 10/28/2019 replacement
 
	Head report
		cnt_cs = 0
 
	Head off.group_seq
 
		cnt_cs = cnt_cs + 1
 
		If (off.label_text = 'Code Status')   ; In P41... this would be the same as od.oe_field_id = 2031600739.00. In B41, it's different
			CODE_STATUS_OEF = trim(od.oe_field_display_value)
		Else																		; 034 09/01 2020   The else has been re-written
		 	If (CODE_STATUS_OEF = "DNR with Conditions" or
		 		CODE_STATUS_OEF = "DNR and Pre-arrest Limitations" or
		 		CODE_STATUS_OEF = "DNR (Allow all pre-arrest interventions)")
		 		If (cnvtupper(od.oe_field_display_value) = "DO NOT*" or
		 		    cnvtupper(od.oe_field_display_value) = "NO *")
	;				if (cnt_cs = 2)
					if (CODE_STATUS_INTERVS <= " ")
				 		CODE_STATUS_INTERVS = trim(od.oe_field_display_value)
				 	else
				 		CODE_STATUS_INTERVS = trim(build2(code_status_intervs, "; ", trim(od.oe_field_display_value)))
				 	endif
				endif
			endif
 
		endif
 
	foot report
 
		CODE_STATUS_FINAL = CODE_STATUS_OEF
 
		ICUSTOMFIELDINDEX = 3
 
		If (deceased_patient_ind = 0)   ; 0 is "No"... or... anything but "Yes"
			REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY =
;							trim(code_status_final)		; This was greened out when it was decided that the interventions ahould be loaded later
							trim(CODE_STATUS_OEF)
		Else
			REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY =
							build2(REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY,
;								   "; ", trim(code_status_final)) ; This was greened out when it was decided that the interventions ahould be loaded later
								   "; ", trim(CODE_STATUS_OEF))
		Endif
 
		; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
		; 031 02/03/2020  New. We are adding on the order comments... if there are any.
		; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
 
		If (lt.long_text > " ")
			If (CODE_STATUS_INTERVS > " ")
				CODE_STATUS_INTERVS = build2(CODE_STATUS_INTERVS, char(10), "(Code Status Order Comments: ",
											 trim(replace(replace(lt.long_text, char(13), ""), char(10), " ")),
										     ") ")
			Else
				CODE_STATUS_INTERVS = build2("Code Status Order Comments: ",
											 trim(replace(replace(lt.long_text, char(13), ""), char(10), " "))  ;,
										     )
			Endif
 
		Endif
		; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
 
	 	REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 3
 
	with nocounter,
	     outerjoin = d													; 031 02/03/2020 outerjoin is new
 
 
	if (CODE_STATUS_OEF <= " ") 			; Clinic & Recurring Outpatient encounter types display nothing...
      										; .... instead of “Code: Not Recorded” when an order is not found
 
		select into 'NL:'
		from encounter   e
		where e.person_id = REQUEST -> PERSON_ID
		and e.encntr_id = REQUEST -> ENCNTR_ID
		and e.encntr_type_cd not in (CLINIC_VAR, RECURRINGOUTPATIENT_VAR,
		     						 309314.00) ;	Recurring Clinic			; 032 03/26/2020  Added here too.
		DETAIL
			If (deceased_patient_ind = 0)   ; 0 is "No"... or... anything but "Yes"
				REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY =
											   "Code: Not Ordered"
			Else
				REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY =
										build2(REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY,
											   "; Code: Not Ordered")
			Endif
 
		 	REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 3
		WITH  NOCOUNTER
 
	endif
 
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	; 029 10/18/2019 Code Status overhauled... replacement ends here
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	;Critical Alerts - pull from the diagnosis & problems table only display if a result is found (no label)
	;Utilize the custom type of "Critical Alert"
	free set diag_prob
	record diag_prob
	(
	  1 diag_prob_cnt = i4
	  1 diag_prob_list [*]
	    2 diag_prob = vc
	    2 nomen_id = f8
	    2 type = c1
	)
 
	declare dpCnt = i4 with protect, noconstant(0)
	declare critDisp = vc with protect, noconstant("")
	declare critAlertVocabCD = f8 with protect, constant(uar_get_code_by("MEANING", 400, "SNMCT"));
	declare critAlertVocabCD1 = f8 with protect, constant(uar_get_code_by("MEANING", 400, "CRITICALERTS"))
	declare critAlertVocabCD2 = f8 with protect, constant(uar_get_code_by("MEANING", 400, "IMO"))
	declare lcActiveCd = f8 with protect, constant(uar_get_code_by("MEANING", 12030, "ACTIVE"))
	declare idx = i4 with protect, noconstant(0)
 
	;diagnosis text
	select into "nl:"
		tRANKING = UAR_GET_CODE_DESCRIPTION(D.ranking_cd)
		,DIAGNOSIS = TRIM(N.source_string,3)
		,NOMEN_ID = n.nomenclature_id
	from diagnosis d,
		 nomenclature n
	plan d
		where d.encntr_id = REQUEST -> ENCNTR_ID
		and d.active_ind = 1
		and d.end_effective_dt_tm between cnvtdatetime(curdate, curtime3) and cnvtdatetime("31-DEC-2100 23:59:59")
	join n
		where d.nomenclature_id > 0.0
		and n.nomenclature_id = d.nomenclature_id
		and n.source_vocabulary_cd in (critAlertVocabCD, critAlertVocabCD1,critAlertVocabCD2)
		and n.source_string_keycap IN ("PROCEDURE REFUSED", "EXPECTED DIFFICULT INTUBATION", "HIGH RISK OF HARM TO OTHERS",
									   "TRANSPLANT", "AT RISK OF HARMING OTHERS", "H/O: TISSUE/ORGAN RECIPIENT",
									   "FAILED OR DIFFICULT INTUBATION")
		and n.active_ind = 1
	ORDER BY tRANKING asc
	detail
		diag_prob->diag_prob_cnt = diag_prob->diag_prob_cnt + 1
		stat = alterlist(diag_prob->diag_prob_list, diag_prob->diag_prob_cnt)
 
	 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->diag_prob = DIAGNOSIS
	 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->nomen_id = NOMEN_ID
	 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->type = "D"
	with nocounter, orahintcbo("index(d xie1diagnosis","index(n xpknomenclature)")
 
	;---------------------------------------------------------------------------------------------------------------------
	; problem text
	;---------------------------------------------------------------------------------------------------------------------
 
	Declare VAR_ENCNTR_TYPE_CD_1 = f8 with noconstant (0.00)					; 012 12/28/2016  New "Insurance"
																				; 012 12/28/2016  New "Insurance"
	Select into "nl:"															; 012 12/28/2016  New "Insurance"
	from encounter e															; 012 12/28/2016  New "Insurance"
	where e.encntr_id = REQUEST -> ENCNTR_ID									; 012 12/28/2016  New "Insurance"
	detail																		; 012 12/28/2016  New "Insurance"
		VAR_ENCNTR_TYPE_CD_1 = e.encntr_type_cd									; 012 12/28/2016  New "Insurance"
	with nocounter																; 012 12/28/2016  New "Insurance"
 
	; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	; mod 014 - replacing this code. comment out - start
	;	[Green code removed in Sept 2019]
 
	; mod 014 - critical alert re-write - start
 
	; 031 02/03/2020  The below Select uses the *Alerted Critical Conditions* Problem folder for a list of
	;				  critical problems. That list is found in the 'nomen_cat_list' table.
	;				  We will not hard code the list of critical problems here anymore.  Diagnoses?  They are still hard coded in this script.
 
	select into "nl:"
			PROBLEM =
			 (IF(trim(P.annotated_display,3) != "")			; 010 fixed display issue with Transplant problem
							TRIM(P.annotated_display,3)
						ELSE
							TRIM(N.source_string,3)
						ENDIF)
			,NOMEN_ID = n.nomenclature_id
	from problem p,
		 nomenclature n,
         cmt_cross_map ccm,
		 nomenclature n2,
		 nomen_cat_list   ncl				; 031 02/03/2020 new table
 
	plan p
		where p.person_id = REQUEST -> PERSON_ID
		and p.active_ind = 1
		and p.end_effective_dt_tm between cnvtdatetime(curdate, curtime3) and cnvtdatetime("31-DEC-2100 23:59:59")
		and p.life_cycle_status_cd = lcActiveCd
 
	join n
		where n.nomenclature_id = p.nomenclature_id
		and n.nomenclature_id > 0.0
		and n.active_ind = 1
;		and n.source_vocabulary_cd = (critAlertVocabCD ; SNOMED				; 035 01/08/2021	replaced
		and n.source_vocabulary_cd in (critAlertVocabCD,  ; SNOMED			; 035 01/08/2021	replacement
									   critAlertVocabCD2) ; IMO				; 035 01/08/2021	replacement
 
    join ccm 
                                                                         
      where (   ccm.target_concept_cki = n.concept_cki                      ; 035 01/08/2021   replacement
             or ccm.concept_cki        = n.concept_cki)                     ; 035 01/08/2021    replacement
        and ccm.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
        ;and ccm.end_effective_dt_tm >  cnvtdatetime(curdate, curtime3)
        and (   (ccm.concept_cki         in("IMO!5726264","IMO!805170"))
             or (    ccm.concept_cki not in("IMO!5726264","IMO!805170") 
                 and ccm.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
                )
            )
 
	join n2
		where ccm.concept_cki = n2.concept_cki
;		and n2.source_identifier_keycap in (                       			; 031 02/03/2020 These codes are from the
;			"1045449"   ; Difficult airway									;				 *Alerted Critical Conditions* folder.
;		  , "807826"    ; Family history of malignant hyperthermia			;				 The will now be found by using the
;		  , "958879"    ; Involuntary commitment							; 				 nomen_cat_list table. See the
;		  , "23049"     ; Malignant hyperthermia							;				 "join ncl" immediately below.
;		  , "30956744"  ; Potential for harm to others
;		  , "805170"    ; Procedure refused
;;;;		  , "7894155"   ; Research study patient						; 016 02/20/2018  Removed today
;		  , "334434"    ; Transplant
;		  , "5726264"   ; No blood products
;		)
 
		join ncl															; 031 02/03/2020 new table
			where ncl.nomenclature_id = n2.nomenclature_id and			
				 (ncl.parent_category_id =  14798516.00)       ; *Alerted Critical Conditions*
 
	Order by PROBLEM 																			; 007 12/15/2015
;	detail																						; 007 12/15/2015
	head PROBLEM																				; 007 12/15/2015
		diag_prob->diag_prob_cnt = diag_prob->diag_prob_cnt + 1
		stat = alterlist(diag_prob->diag_prob_list, diag_prob->diag_prob_cnt)
 
	 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->diag_prob = PROBLEM
	 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->nomen_id = NOMEN_ID
	 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->type = "P"
 
	with nocounter, orahintcbo("index(p xie1problem","index(n xpknomenclature)")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  043 	10/25/2023   adding in 'Potential for harm to others' from SNOMED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	select into "nl:"
			PROBLEM = TRIM(P.annotated_display,3),
			NOMEN_ID = p.nomenclature_id
	from problem p
	plan p
		where p.person_id = REQUEST -> PERSON_ID
		and p.nomenclature_id =      7699966.00   ;'Potential for harm to others'
		and p.active_ind = 1
		and p.end_effective_dt_tm between cnvtdatetime(curdate, curtime3) and cnvtdatetime("31-DEC-2100 23:59:59")
		and p.life_cycle_status_cd = lcActiveCd
	head PROBLEM	
		diag_prob->diag_prob_cnt = diag_prob->diag_prob_cnt + 1
		stat = alterlist(diag_prob->diag_prob_list, diag_prob->diag_prob_cnt)
 
	 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->diag_prob = PROBLEM
	 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->nomen_id = NOMEN_ID
	 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->type = "P"
 
	with nocounter

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 
	; mod 014 - critical alert re-write - end
 
  	set is_harm_prob_found = 0 ; mod 020 - begin
 
	;Build crital alert list
	if(diag_prob->diag_prob_cnt >0)
		set critDisp = ""
		for(dpCnt = 1 to diag_prob->diag_prob_cnt)
			if(dpCnt > 1)
				set critDisp = notrim(build2(critDisp, ", "))
			endif
 
			set critDisp = build2(critDisp, diag_prob->diag_prob_list[dpCnt]->diag_prob)
 
			; mod 020 - check if "Potential for harm to others" problem has already been added to patient's chart. This will prevent
			; duplicates since "Potential for harm to others" problem exists in the Alerted Critical Conditions folder and may also
			; be added by the PLAN_HARM_TO_OTHERS_PROB rule.
			if(diag_prob->diag_prob_list[dpCnt].diag_prob = "Potential for harm to others")
				set is_harm_prob_found = 1
			endif
 
		endfor
	endif
 
	; mod 020
	if(is_harm_prob_found = 0)
 
		;call echo("Check to see if PLAN_HARM_TO_OTHERS_PROB rule added a 'Potential for harm to others' problem")
 
		select into "nl:"
		PROBLEM = (
			IF(trim(P.annotated_display,3) != "")
				TRIM(P.annotated_display,3)
			ELSE
				TRIM(N.source_string,3)
			ENDIF
		)
		, NOMEN_ID = n.nomenclature_id
		, snomed=n.concept_cki
		from problem p
			 , nomenclature n
		plan p
			where p.person_id = REQUEST -> PERSON_ID      ; Problems are person level. Friendly reminder.
				and p.active_ind = 1
				and p.end_effective_dt_tm between cnvtdatetime(curdate, curtime3) and cnvtdatetime("31-DEC-2100 23:59:59")
				and p.life_cycle_status_cd = lcActiveCd ; 3301.00	; Active
		join n
			where p.nomenclature_id > 0.0
				and n.nomenclature_id = p.nomenclature_id
			  and n.source_vocabulary_cd = value(uar_get_code_by("DISPLAY_KEY",400,"IMO"))
			  and n.source_identifier_keycap = "30956744"  ; Potential for harm to others
				and n.active_ind = 1
		Order by PROBLEM
		head PROBLEM
			diag_prob->diag_prob_cnt = diag_prob->diag_prob_cnt + 1
			stat = alterlist(diag_prob->diag_prob_list, diag_prob->diag_prob_cnt)
 
		 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->diag_prob = PROBLEM
		 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->nomen_id = NOMEN_ID
		 	diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->type = "P"
 
		 	if(critDisp > "")
		 		critDisp = notrim(build2(critDisp, ", "))
		 	endif
 
			critDisp = build2(critDisp, diag_prob->diag_prob_list[diag_prob->diag_prob_cnt]->diag_prob)
 
		with nocounter, orahintcbo("index(p xie1problem","index(n xpknomenclature)")
 
	endif ; mod 020 - end
 
; - - - - - - - - - - 015 12/08/2017    The Clinical Trials request has been implemented. Here is a part of the revision - - -
 
	Declare VAR_CLIN_TRIAL_IND = i2 with noconstant (0)
    Declare VAR_CLIN_TRIAL_DISP = vc with noconstant (' ')
    Declare spaces = vc with noconstant(fillstring(50, "^"))
    declare code_status_intervs_final  = vc
    				with noconstant((if(textlen(critDisp) < 40)
	    								build2 ('...',
	    										'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^',
	    										'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^',
	    										char(10),
	    										trim(code_status_intervs))
	    							 elseif(textlen(critDisp) < 80)
	    								build2 ('...',
	    										'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^',
	    										'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^',
	    										char(10),
	    										trim(code_status_intervs))
	    							 else
	    								build2 ('...',
	    										'^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^',
	    										char(10),
	    										trim(code_status_intervs))
    								 endif))
 
 
    Select into "nl:"
	from pt_prot_reg   ppr,
	  	 prot_master   pm
	plan ppr
		where ppr.person_id = REQUEST -> PERSON_ID and
			  ppr.on_study_dt_tm <= cnvtdatetime ( curdate, curtime3 ) and
			  ppr.off_study_dt_tm >= cnvtdatetime ( curdate, curtime3 ) and
			  ppr.beg_effective_dt_tm <= cnvtdatetime ( curdate, curtime3 ) and
	          ppr.end_effective_dt_tm >= cnvtdatetime ( curdate, curtime3 )
	join pm
	 	where pm.prot_master_id = ppr.prot_master_id and
		   	  pm.beg_effective_dt_tm <= cnvtdatetime ( curdate, curtime3 ) and
	       	  pm.end_effective_dt_tm >= cnvtdatetime ( curdate, curtime3 ) and
			  pm.display_ind = 1
    head report
    	VAR_CLIN_TRIAL_IND = 1  				 ; Which means.... we found this to be a research study patient
	with nocounter
 
	; Look immediately Below. 1 means that we found this to be a research study patient
 
	If (VAR_CLIN_TRIAL_IND = 1)
		set VAR_CLIN_TRIAL_DISP = "On Research Study: Yes"
	Else
		set VAR_CLIN_TRIAL_DISP = "On Research Study: No"
	Endif
 
 	IF(TEXTLEN(TRIM(REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY, 3)) != 0)
 
		if (TEXTLEN(TRIM(critDisp, 3)) != 0)			; if critical alerts are present
 
			set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY =
								build2(REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY, '; ',
									   TRIM(critDisp, 3), 											; 015 12/08/2017 the change on 02/01/2018
									   ; 029 10/18/2019 code_status_intervs were created much earlier... But they aren't as important as
									   ;                Deceased Patient, critDisp, or VAR_CLIN_TRIAL_DISP ,so they are not added to this
									   ;				Custom Field until last
									   "; ",
									   TRIM(VAR_CLIN_TRIAL_DISP, 3),
									   (If (code_status_intervs > " ")
									   		   build2( "; ", replace(code_status_intervs_final, '^', ' '))
									   	Else
									   		" "
									   	Endif))
			set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 3
 
		Else   ; critical alerts are not present
 
			set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY =
								build2(REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY, '; ',
									   ; 029 10/18/2019 code_status_intervs were created much earlier... But they aren't as important as
									   ;                Deceased Patient, critDisp, or VAR_CLIN_TRIAL_DISP ,so they are not added to this
									   ;				Custom Field until last
									   TRIM(VAR_CLIN_TRIAL_DISP, 3),
									   (If (code_status_intervs > " ")
									   		   build2( "; ", replace(code_status_intervs_final, '^', ' '))
									   	Else
									   		" "
									   	Endif))
			set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 3
 
		endif
 
	ELSE
 
		if (TEXTLEN(TRIM(critDisp, 3)) != 0)			; if critical alerts are present
 
			set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY =
										Build2(TRIM(critDisp, 3), "; ", VAR_CLIN_TRIAL_DISP)
			set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 3; 008 added
 
		Else
 
			set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY =
														   TRIM(VAR_CLIN_TRIAL_DISP, 3)
 
			set REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 3
 
		endif
 
	ENDIF
 
 
 
; - - - - - 015 12/08/2017  The above Clinical Trials request has caused below lines to be greened out.- - -
;           September 2019 The green lines of code have been removed.
 
END ;Subroutine
 
 
SUBROUTINE CUSTOMFIELD4  ( NULL  )
	; 008 Entire subroutine logic changed
	;Dosing Weight
	DECLARE  DOSING_WEIGHT_CD  =  f8  WITH  NOCONSTANT (uar_get_code_by("DISPLAYKEY",72,"WEIGHTDOSING")), PROTECT
	DECLARE  AUTH_CD  =  f8  WITH  NOCONSTANT (uar_get_code_by("MEANING",8,"AUTH")), PROTECT
	DECLARE  MODIFIED_CD  =  f8  WITH  NOCONSTANT (uar_get_code_by("MEANING",8,"MODIFIED")), PROTECT
	DECLARE  ALTERED_CD  =  f8  WITH  NOCONSTANT (uar_get_code_by("MEANING",8,"ALTERED")), PROTECT
	DECLARE  DOSING_WEIGHT_METHOD_CD = f8
				with noconstant (uar_get_code_by ("DISPLAYKEY", 72,"DOSINGWEIGHTMETHOD")), protect ; 005 07/07/2014  102259026.00
	DECLARE wtCnt  = i4 with protect
	DECLARE RECURRINGOUTPATIENT_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",71,"RECURRINGOUTPATIENT")),protect
	DECLARE CLINIC_VAR = f8 with Constant(uar_get_code_by("DISPLAYKEY",71,"CLINIC")),protect
	DECLARE ind = i4 with Protect
 	SET ICUSTOMFIELDINDEX = ICUSTOMFIELDINDEX + 1
 
 	RECORD weightDetails
	(
		1 wdList[*]
			2 encId = f8
			2 encTypeCd = f8
		 	2 wtVal = vc
			2 wtUnit = vc
			2 wtMethod = vc
			2 performedDate = dq8 ; vc
			2 datePosition = i4 ; datePosition of 1 indicates the most recent weight
								; as we will be sorting by performed_dt_tm descending
		1 dp1Value = vc ; value from datePosition = 1
		1 dp1EncType = f8 ; encounter type from datePosition = 1
	)
 
 	SELECT INTO "NL:"
	FROM clinical_event ce2
		, encounter e
		, dummyt d			; to provide the outerjoin feature
		, clinical_event ce_m
	PLAN ce2 WHERE ce2.person_id = REQUEST -> PERSON_ID
			  ;AND ce2.encntr_id = REQUEST -> ENCNTR_ID
			  AND ce2.event_cd = DOSING_WEIGHT_CD
			  AND ce2.event_end_dt_tm < cnvtdatetime(curdate,curtime3)
			  AND ce2.valid_until_dt_tm BETWEEN cnvtdatetime(curdate,curtime3) AND cnvtdatetime("31-DEC-2100 23:59:59")
			  AND ce2.result_status_cd+0 IN (AUTH_CD,MODIFIED_CD,ALTERED_CD)
 
	JOIN e WHERE e.encntr_id = ce2.encntr_id
 
	JOIN d					; to provide the OuterJoin feature
 
	JOIN ce_m WHERE ce_m.parent_event_id = ce2.parent_event_id
				  AND ce_m.event_cd = DOSING_WEIGHT_METHOD_CD ;  102259026.00
				  AND ce_m.result_status_cd + 1 - 1 IN (AUTH_CD,MODIFIED_CD,ALTERED_CD) ; (25.00, 34.00, 35.00)
				  AND cnvtdatetime(curdate, curtime3) BETWEEN ce_m.valid_from_dt_tm AND ce_m.valid_until_dt_tm ; 008 Coding best practices
 
	ORDER BY ce2.performed_dt_tm desc
 
	HEAD REPORT
		wtCnt = 0
 
	DETAIL
	 wtCnt = wtCnt + 1
 
	IF(mod(wtCnt,10) = 1)
		stat = alterlist(weightDetails->wdList, wtCnt + 9)
	ENDIF
 
	weightDetails->wdList[wtCnt].encId = e.encntr_id
	weightDetails->wdList[wtCnt].encTypeCd = e.encntr_type_cd
	weightDetails->wdList[wtCnt].performedDate = ce2.performed_dt_tm
;	weightDetails->wdList[wtCnt].wtMethod = trim(substring(1,3, ce_m.result_val))			; 025 04/17/2019 replaced
	weightDetails->wdList[wtCnt].wtMethod = trim(ce_m.result_val)							; 025 04/17/2019 replacement
	weightDetails->wdList[wtCnt].wtUnit = trim(uar_get_code_display(ce2.result_units_cd))
	weightDetails->wdList[wtCnt].wtVal = trim(ce2.result_val,3)
	weightDetails->wdList[wtCnt].datePosition = wtCnt
 
	FOOT REPORT
	stat = alterlist(weightDetails->wdList, wtCnt)
 
	WITH  NOCOUNTER, orahintcbo("index(ce2 xie9clinical_event"), outerjoin = d 	; to provide the outerjoin feature
 
	SELECT INTO "NL:"
	FROM (DUMMYT D WITH SEQ = VALUE(SIZE(weightDetails->wdList, 5)))
	WHERE weightDetails->wdList[D.seq].datePosition = 1 ;Most recent result
	DETAIL
		weightDetails->dp1Value = build2(trim(weightDetails->wdList[D.seq].wtVal,3)," "
									, trim(weightDetails->wdList[D.seq].wtUnit)," "
									, trim(weightDetails->wdList[D.seq].wtMethod), " "					;025 04/17/2019   " " has been added
									, "(", weightDetails->wdList[D.seq].performedDate, ")") ; 008 Added performed_dt_tm
		weightDetails->dp1EncType = weightDetails->wdList[D.seq].encTypeCd
	WITH NOCOUNTER
 
	SELECT INTO "NL:"
	FROM PERSON P
		, ENCOUNTER E
	PLAN P WHERE P.person_id = REQUEST -> PERSON_ID
	JOIN E WHERE E.person_id = P.person_id
			  AND E.encntr_id = REQUEST -> ENCNTR_ID
	DETAIL
		IF(E.encntr_type_cd = CLINIC_VAR OR E.encntr_type_cd = RECURRINGOUTPATIENT_VAR or
		   E.encntr_type_cd = 309314.00) ;	Recurring Clinic			; 032 03/26/2020 Recurring Clinic added here
 
			IF(P.birth_dt_tm > CNVTLOOKBEHIND("16, Y")) ; If the patients age is < 16
				; We know that the location = 1 contains the most recent value, so we will make use of that knowledge here
				IF(weightDetails->wdList[1].performedDate > CNVTLOOKBEHIND("31,D"))
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY =  weightDetails->dp1Value
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 4
				ELSE
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY = ""
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 4
				ENDIF
 
			ELSE
				IF(weightDetails->wdList[1].performedDate > CNVTLOOKBEHIND("1,Y"))
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY =  weightDetails->dp1Value
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 4
				ELSE
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY = ""
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 4
				ENDIF
			ENDIF
 
		ELSE
			POS = LOCATEVAL(ind,1,SIZE(weightDetails->wdList, 5),E.encntr_id,weightDetails->wdList[ind].encId)
			IF(POS!=0)
				IF(weightDetails->wdList[POS].datePosition = 1) ; current encounter has the newest dosing wt
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY = weightDetails->dp1Value
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 4
				ELSE
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY = ""
					REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 4
				ENDIF
			ELSE
				REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY = ""
				REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 4
			ENDIF
		ENDIF
	WITH NOCOUNTER
END ;Subroutine
 
SUBROUTINE CUSTOMFIELD5 (NULL)
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
declare RECURRINGOUTPATIENT_VAR5 = f8 with Constant(uar_get_code_by("DISPLAYKEY",71,"RECURRINGOUTPATIENT"))
declare CLINIC_VAR5 = f8 with Constant(uar_get_code_by("DISPLAYKEY",71,"CLINIC"))
 
; 012 12/28/2016   The "Research study patient" request has been withdrawn. Only the Insurance revision is going in now.
 
declare RECURRINGCLINIC_CD5 = f8 with constant(uar_get_code_by("DISPLAYKEY",71,"RECURRINGCLINIC"));  309314.00		; 012 12/28/2016
declare OUTPATIENTMESSAGE_CD5 = f8 with constant(uar_get_code_by("DISPLAYKEY",71,"OUTPATIENTMESSAGE")); 3012539.00  ; 012 12/28/2016
 
Declare VAR_ENCNTR_TYPE_CD = f8 with noconstant (0.00)						; 012 12/28/2016  New "Insurance"
																			; 012 12/28/2016  New "Insurance"
Select into "nl:"															; 012 12/28/2016  New "Insurance"
from encounter e															; 012 12/28/2016  New "Insurance"
where e.encntr_id =  REQUEST -> ENCNTR_ID ; 117056269.00 ;					; 012 12/28/2016  New "Insurance"
detail																		; 012 12/28/2016  New "Insurance"
	VAR_ENCNTR_TYPE_CD = e.encntr_type_cd									; 012 12/28/2016  New "Insurance"
with nocounter																; 012 12/28/2016  New "Insurance"
 
 
Declare VAR_PRI_INSUR_DISP = vc with noconstant(" ")
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
; First, check to see if the patient is an ambulatory patient
 
If (VAR_ENCNTR_TYPE_CD in ( CLINIC_VAR5,			  ; 5043178.00, 								; 012 12/15/2016  New
   							RECURRINGOUTPATIENT_VAR5, ; 5045671.00									; 012 12/15/2016  New
   							RECURRINGCLINIC_CD5,      ; 309314.00									; 012 12/15/2016  New
						    OUTPATIENTMESSAGE_CD5))	  ; 3012539.00									; 012 12/15/2016  New
 
	; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	;     Patient's Insurance Information
	; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
 
	select into "nl:"
	from
		  encntr_plan_reltn epr
		, health_plan hp
		, organization o
	plan epr
		where epr.encntr_id =  REQUEST -> ENCNTR_ID ;117056269.00
		  and epr.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3) ;006
		  and epr.active_ind = 1	;045 - added
	join hp
		where hp.health_plan_id = outerjoin(epr.health_plan_id)
	join o
		where o.organization_id = outerjoin(epr.organization_id) ;003
	order by  epr.priority_seq
	detail
		if (epr.priority_seq = 1)			;primary insurance
		    if(hp.plan_desc <= " " )
			    VAR_PRI_INSUR_DISP = o.org_name
			    VAR_PRI_MEMBER_NBR = epr.member_nbr
		    else
			    VAR_PRI_INSUR_DISP = hp.plan_desc
			    VAR_PRI_MEMBER_NBR = epr.member_nbr
		    endif
		endif
	with nocounter
 
	SET ICUSTOMFIELDINDEX = ICUSTOMFIELDINDEX + 1
	SET REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY = build2("Ins: ",VAR_PRI_INSUR_DISP)
	SET REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 5
 
Else ; Not an ambulatory patient
 
 ; *** Isolation Precautions *** 008 Isolation in its own field
;	DECLARE ISOLATION_CD  =  f8  WITH  CONSTANT (uar_get_code_by("DISPLAY_KEY",72,"ISOLATIONPRECAUTIONSORDERDETAIL"))
;	DECLARE AUTH_CD  =  f8  WITH  CONSTANT (uar_get_code_by("MEANING",8,"AUTH"))
;	DECLARE MODIFIED_CD  =  f8  WITH  CONSTANT (uar_get_code_by("MEANING",8,"MODIFIED"))
;	DECLARE ALTERED_CD  =  f8  WITH  CONSTANT (uar_get_code_by("MEANING",8,"ALTERED"))
;	DECLARE isoDisp = vc  with noconstant("")
 
;	select into 'nl:'
;	from clinical_event ce2
;	where ce2.person_id = REQUEST -> PERSON_ID					; 003 06/28/2013   Replaced by the line below.
;	and ce2.encntr_id = REQUEST -> ENCNTR_ID					; 003 06/28/2013   Replacement line.
;	and ce2.event_cd = ISOLATION_CD
;	and ce2.event_end_dt_tm < cnvtdatetime(curdate,curtime3)
;	and ce2.valid_until_dt_tm between cnvtdatetime(curdate,curtime3) and cnvtdatetime("31-DEC-2100 23:59:59")
;	and ce2.result_status_cd+0 in (AUTH_CD,MODIFIED_CD,ALTERED_CD)
;	order by ce2.updt_dt_tm desc
;	head ce2.event_cd
;		isoDisp = trim(ce2.result_val)
;	WITH  NOCOUNTER, orahintcbo("index(ce2 xie9clinical_event")
;
;	SET isoDisp = replace(isoDisp, "Standard Precautions", "")
;	SET isoDisp = replace(isoDisp, "Not Ordered", "")
;	SET isoDisp = replace(isoDisp, " Precautions", "")
;	SET isoDisp = replace(isoDisp, "not resulted", "")
;
;	SET ICUSTOMFIELDINDEX = ICUSTOMFIELDINDEX + 1
;	IF(TEXTLEN(TRIM(isoDisp,3)) != 0)
;		SET REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_DISPLAY = build2('Iso: ', isoDisp) ; 008 add 'Iso: ' when
;																						; a result is found,  else display nothing
;		SET REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 5
;	ENDIF
 
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 028 07/31/2019   New... displaying the order's clinical_display_line minus the word "Precations" and minus
;				   the date/time at the end.  Above, we were only displaying data from the clinical_event table.
; 				   *** NOTE ***: At one time during the verification of this revision to the banner bar, we were
;								 adding the below data from the order to the data which was obtained from the clinical_event
;								 table (as shown above). That above 'select' was later greened out.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 029 10/18/2019   New... displaying the order's comments.... comments from a discern Rule. These comments include the
;                  organism tied to the patient's isolation.
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	DECLARE iso_new_Disp = vc  with noconstant("")
	DECLARE iso_long_text = vc  with noconstant("")										; 029 10/18/2019 new field for order comments
	DECLARE PATIENTISOLATION_CD  =  f8  WITH  CONSTANT ( uar_get_code_by('DISPLAYKEY',200, 'PATIENTISOLATION')) ;     3976772.00
 
	select into 'nl:'
	from encounter e,
		 orders o,
		 order_comment oc,		; 029 10/18/2019 new table
		 long_text lt			; 029 10/18/2019 new table
 
    plan e
    	where e.encntr_id = REQUEST->ENCNTR_ID
    join o
    	where o.person_id = e.person_id and
    		  o.encntr_id = e.encntr_id and
    		  o.catalog_cd = PATIENTISOLATION_CD and ; 3976772.00
    		((o.order_status_cd = 2550.00 and 		 ; Ordered
    		  e.disch_dt_tm = NULL) ;< cnvtdatetime("01-JAN-2000 00:00:00"))
    		  or
    		 (o.order_status_cd in (2543.00,	     ; Completed
    		 						2550.00) and     ; Ordered
    		  e.disch_dt_tm != NULL)
    		) and
    		  o.active_ind = 1
	join oc																				; 029 10/18/2019 new table
		where oc.order_id = outerjoin(o.order_id) and
		      oc.order_id > outerjoin(0)
	join lt																				; 029 10/18/2019 new table
		where lt.long_text_id = outerjoin(oc.long_text_id) and
		      lt.active_ind = outerjoin(1) and
		      lt.long_text_id > outerjoin(0) and
		      lt.long_text != outerjoin("Discern has re-ordered labs*")					; 029 10/18/2019 long text is new
	order by o.current_start_dt_tm desc, oc.action_sequence desc
	head o.catalog_cd
		iso_new_Disp = trim(substring(1, findstring(',', o.clinical_display_line, 1, 1) - 1,  o.clinical_display_line))
		iso_long_text = trim(lt.long_text)												; 029 10/18/2019 long text is new
	with  nocounter
 
;; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
;; 033 04/08/2020  Rearranging the isolation types so that COVID19 will appear as the first one.
;;				   Notice that we rearrange the COVID19 Precaution before we add the iso_long_text
;;                 onto the end of the iso_new_Disp string. Adding the long text occurs farther below.
;; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
 
	set iso_new_Disp =
 
 			 (if (findstring("COVID19 Precautions |", iso_new_Disp) > 0)
 				build2("COVID19 Precautions | ", replace (iso_new_Disp, "COVID19 Precautions | ", ""))
 			  elseif (findstring("| COVID19 Precautions", iso_new_Disp) > 0)
 				build2("COVID19 Precautions | ", replace (iso_new_Disp, "| COVID19 Precautions", ""))
 			  else
 			  	iso_new_Disp
 			  endif)
 
;; 033 04/08/2020 New ends here
;; -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -    -
 
	set iso_new_Disp = replace(iso_new_Disp, " Precautions", "")
 
	set iso_new_Disp =  build2(iso_new_Disp, "; ", trim(iso_long_text))									; 029 10/18/2019 long text is new
 
	set iso_new_Disp = replace(iso_new_Disp, "Ordered by Discern due to active problem(s) for ", "")	; 029 10/18/2019 new too
	set iso_new_Disp = replace(iso_new_Disp, "Ordered by Discern due to provider order of ", "")		; 029 10/18/2019 new too
	set iso_new_Disp = replace(iso_new_Disp, "Ordered by Discern due to provider order for ", "")		; 029 10/18/2019 new too
	set iso_new_Disp = replace(iso_new_Disp, "Ordered by Discern due to provider order ", "")			; 029 10/18/2019 new too
	set iso_new_Disp = replace(iso_new_Disp, "Added by Discern due to diagnosis of ", "")				; 029 10/18/2019 new too
	set iso_new_Disp = replace(iso_new_Disp, "Updated by Discern due to provider order ", "")			; 029 10/18/2019 new too
	set iso_new_Disp =
					   replace(iso_new_Disp,
							   "Respiratory Viral Panel. Respiratory Viral Panel",
							   "Respiratory Viral Panel")												; 029 10/18/2019 new too  (special special case)
 
	set iso_new_Disp = replace(iso_new_Disp, "Ordered by Discern : ", "")								; 037 11/18/2021 NEW
	set iso_new_Disp = replace(iso_new_Disp, "@MISC:24.", "")											; 029 10/18/2019 Just for B41
	set iso_new_Disp = replace(iso_new_Disp, "@NEWLINE", "")											; 033 04/08/2020 Just for P41
 
	If (iso_new_disp = "*." or iso_new_disp = "*;" )
		set iso_new_Disp = 	substring(1, textlen(iso_new_Disp) - 1, iso_new_Disp)
	endif
 
 
 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	SET ICUSTOMFIELDINDEX = ICUSTOMFIELDINDEX + 1
 
	IF (curqual > 0)
		SET REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY =
															build2('Iso: ', iso_New_Disp) ; Include 'Iso: ' when....
;																						  ; ... a result is found,  else display nothing
		SET REPLY -> CUSTOM_FIELD [ ICUSTOMFIELDINDEX ]-> CUSTOM_FIELD_INDEX = 5
 
	ENDIF
 
 
;	SET REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY = 							; 029 10/18/2019 new... for testing only
;					Build2("07 ", trim( REPLY->CUSTOM_FIELD[ICUSTOMFIELDINDEX].CUSTOM_FIELD_DISPLAY))





; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
; 039 123/05/2022  
; Finding the Anticipated Discharge Date and adding it here.
; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -

	; This record structure is used to load the anticipated date of discharge for this patient for this encounter.

	; The banner bar loves record structures!!!!  It hates using declared variables.
	record adod (
		01 adod_vc = vc		; anticipated date of discharge
	)

 	select into "nl:"
	from ;dummyt d,
		 clinical_event ce,
		 ce_date_result cedr
	plan ce 
		where ce.person_id = request->person_id and
			  ce.encntr_id = request->encntr_id and
			  ce.event_cd = 3910661.00 and ;	Anticipated Discharge Date
			  ce.valid_until_dt_tm >= cnvtdatetime(curdate,curtime3) and
			  ce.result_status_cd in (25.00, 34.00, 35.00)
	join cedr
		where cedr.event_id = ce.event_id  and
			  cedr.valid_until_dt_tm >= cnvtdatetime(curdate, curtime3)
	order by ce.event_end_dt_tm
	head report
		adod->adod_vc = ''	
	detail
		adod->adod_vc = format(cedr.result_dt_tm, "MM/DD/YYYY;;Q")
	with  nocounter

	If (adod->adod_vc > '')
 
		If (reply->custom_field[icustomfieldindex].custom_field_display = NULL)
			set reply->custom_field[icustomfieldindex].custom_field_display = 	
							build2("ADOD: ", trim(substring(1,180,adod->adod_vc)))
		Else
			set reply->custom_field[icustomfieldindex].custom_field_display = 	
							build2("ADOD: ", trim(substring(1,180,adod->adod_vc)), " | ", 
								   trim(reply->custom_field[icustomfieldindex].custom_field_display))
		endif

	endif	
					
	set reply -> custom_field [ icustomfieldindex ]-> custom_field_index = 5

 	
; -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -


 
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
 
ENDIF
END ; Subroutine
 
 
;;SET  SCRIPT_VERSION  = "06/28/13 13:30"
 
end
go
 