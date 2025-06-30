/*********************************************************************************************************************************
 Object name:       _token_patientportal
 Source file:       _token_patientportal.prg
 Purpose:           Display Patient Portal Instructions if Patient Not Already Enrolled
 Executed from:     PowerChart Depart Process Tab
 Programs Executed: N/A
 Special Notes:     N/A


**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
 Mod  Date        Analyst               OPAS              Comment
 ---  ----------  --------------------  ------            -------------------------------------------------------------------------
 001  04/18/2018  David Smith           MCGA 211127       Initial
 002  June 2019   Swetha Srinivasaraghavan <Code Upgrade> Added <br>
 003  06/20/19    Jeremy Daniel         MCGA              Added peds indicator code and change verbiage for each scenario
 004  09/19/2019  Jeremy Daniel         MCGA              Added MU section
 005  08/06/2021  Asha Patil            MCGA227843        Modify text
 006  01/04/2022  Asha Patil            MCGA227843        Modify text formatting
 007  08/19/2024  David Smith           MCGA348392        Modify Text
 008  06/17/2025  Michael Mayes         238456            Changing the mobile phone/email/patID text a bit.
*********************************END OF ALL MODCONTROL BLOCKS********************************************************************/
drop program _token_patientportal go
create program _token_patientportal
 /****************************************************************************************************
                                    Variable Declarations
*****************************************************************************************************/
declare csText = vc
declare csHeader = vc
declare patient_id = vc ;with noconstant("PatientID - Your unique patient ID appears on page one of this document")
declare MESSAGING_VAR = f8 with Constant(uar_get_code_by("DISPLAY_KEY",263,"CONSUMERMESSAGING")),protect
declare CMRN_CD = f8 with Constant(uar_get_code_by("DISPLAY_KEY",4,"COMMUNITYMEDICALRECORDNUMBER")),protect
declare peds_ind = i2
set csHeader = concat("<html><body>")
set csText = csHeader
;set csText = concat(csText, "<p style='font-size:12.0pt;font-family:Arial'>")
/****************************************************************************************************
                                See if Patient Has an EMPI
*****************************************************************************************************/
SELECT INTO "NL"
FROM ENCOUNTER E
    ,PERSON P
    , PERSON_ALIAS   PA
PLAN E WHERE E.encntr_id = request->encntr_id
JOIN P WHERE P.person_id = e.person_id
JOIN PA WHERE PA.person_id = P.person_id
            AND PA.person_alias_type_cd = CMRN_CD ;CMRN/EMPI
            AND PA.active_ind = 1
            and PA.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
order by PA.alias
Head PA.alias

if (datetimediff(e.reg_dt_tm,p.birth_dt_tm,1) < 6574)
peds_ind = 1
endif

    patient_id = concat("PatientID - ",pa.alias)
WITH NOCOUNTER, time = 20

if(patient_id = "" or patient_id = null)
    set patient_id = "PatientID - Your unique patient ID appears on page one of this document"
endif
/****************************************************************************************************
                                See if Patient Already Registered for Portal
*****************************************************************************************************/
SELECT INTO "NL"
FROM
    PERSON P
    , PERSON_ALIAS   PA
PLAN P WHERE P.person_id = request->person_id
JOIN PA WHERE PA.person_id = P.person_id
            AND PA.alias_pool_cd = MESSAGING_VAR ;PATIENT PORTAL PERSON ALIAS
            AND PA.active_ind = 1
            AND PA.end_effective_dt_tm >cnvtdatetime(curdate,curtime3)
WITH NOCOUNTER
/****************************************************************************************************
                                 Format the Reply HTML style='font-size:16pt;font-weight:bold;text-align:center'
*****************************************************************************************************/
if(curqual <= 0 and peds_ind = 1);if(curqual <= 0)
;   set csText = concat(csText,"<table width=100% cellspacing=0 style='border-collapse:collapse;border:none'>",
;                                   "<tr style='text-align:center;font-size:20pt;'>",
;                                       "<td style='text-align:center;font-size:20pt;'><b>Manage your child's health care anytime, anywhere with the</b></td>",
;                                   "</tr>",
;                                   "<tr style='text-align:center;font-size:20pt;'>",
;                                       "<td style='text-align:center;font-size:20pt;'><b>myMedStar Patient Portal</b></td>",
;                                   "</tr>",
;                               "</table>",
    set csText = concat(csText,"<p style='font-size:16pt;font-weight:bold;text-align:center'>Manage your health care anytime, anywhere with the",
                               "<br>MedStar Health Patient Portal</p>",


    ;"<p><b>myMedStar</b> is a free, secure and convenient way to manage your child's health care and communicate with their physician.<br><br>",
    "<p><b>With our patient portal you can:</b><br>",
        "&#9679;&nbsp;&nbsp;Request and manage your child's appointments<br>",
        "&#9679;&nbsp;&nbsp;Securely view, download, and send diagnostic images and reports<br>",
        "&#9679;&nbsp;&nbsp;View most lab and pathology results as soon as they are available<br>",
        "&#9679;&nbsp;&nbsp;View and print immunization records<br>",
        "&#9679;&nbsp;&nbsp;Exchange secure email messages with any of your child's MedStar Health care providers<br>",
        "&#9679;&nbsp;&nbsp;View summaries of your child's hospital or office visits<br>",
        "&#9679;&nbsp;&nbsp;And more<br><br>",
    "<b><u>How to Enroll for Proxy Access:</u></b><br><br>",
        "1. If you already have your own portal account, you may request access by filling out the <i><b> Request Access to my Minor Child's Records </b></i> form found in the",
        "<i><b> Requests and Other Forms</b></i> section of the patient portal.<b> OR </b> <br>",
        "2. If you don't have your own portal account, Ask a front desk associate for a",
        "<i><b> Patient Portal Access Authorization Form.</b></i><br>",
        "&#9679;&nbsp;Complete the form and return it to a front desk associate along with your photo identification.<br>",
        "3. Within 2-3 business days you will receive an email invitation. Click the link to accept the invitation. <br>",
        "4. After successful verification, you will either be prompted to login to your existing MedStar Health patient portal account ",
        "<b>OR</b> if you do not have your own account, you will be prompted to create a new one.<br><br>",

         "If you have questions or need assistance creating your account, please contact support toll ",
         "free at 1-877-745-5656, 24 hours a day, 7 days a week.<br><br>",

    "MedStar Health is dedicated to helping improve your overall health care experience by providing ",     ;mod003
    "convenient, streamlined resources to help you better manage your health. We now offer the ability ",
    "for you to securely connect some of the health management apps you may use(i.e. fitness trackers, ",
    "dietary trackers, etc.) to your health record. Email us at <u>mymedstar@medstar.net</u> if you are ",
    "interested. Once we receive your request, MedStar Health will work with the appropriate vendors to ",
    "determine if they meet the technical requirements in order to establish a secure connection. <br><br>",




    "<b>Please Note:</b> Due to state privacy requirements, proxy accounts for adolescents ages 13 to 17 will be ",
    "limited to immunization data. Sensitive information will not be viewable by the proxy (parent). Account holders ",
    "will be able to request appointments and communicate with a MedStar Health physician, but access to a ",
    "patient's medication list, problem list, lab results and other information may be restricted. ",
    "When the patient turns 18 proxy access is automatically terminated.<br><br>")


elseif (curqual <= 0 and peds_ind = 0)

;   set csText = concat(csText,"<table width=100% cellspacing=0 style='border-collapse:collapse;border:none'>",
;                                   "<tr style='text-align:center;font-size:20pt;'>",
;                                       "<td style='text-align:center;font-size:20pt;'><b>Manage your health care anytime, anywhere with the</b></td>",
;                                   "</tr>",
;                                   "<tr style='text-align:center;font-size:20pt;'>",
;                                       "<td style='text-align:center;font-size:20pt;'><b>myMedStar Patient Portal</b></td>",
;                                   "</tr>",
;                               "</table>",

        set csText = concat(csText,"<p style='font-size:16pt;font-weight:bold;text-align:center'>Manage your health care anytime, anywhere with the",
                               "<br>MedStar Health Patient Portal</p>",

    ;"<p><b>myMedStar</b> is a free, secure and convenient way to manage your health care and communicate with your physician.<br><br>",
    "<p><b>With our patient portal you can:</b><br>",
        "&#9679;&nbsp;&nbsp;Request and manage appointments<br>",
        "&#9679;&nbsp;&nbsp;Securely view, download, and send any of your diagnostic images and reports<br>",
        "&#9679;&nbsp;&nbsp;View most lab and pathology results as soon as they are available<br>",
        "&#9679;&nbsp;&nbsp;Renew prescriptions<br>",
        "&#9679;&nbsp;&nbsp;Exchange secure email messages with any of your MedStar Health care providers<br>",
        "&#9679;&nbsp;&nbsp;View summaries of your hospital or office visits<br>",
        "&#9679;&nbsp;&nbsp;And more<br><br>",
    "<b><u>How to Enroll:</u></b><br><br>",
    "<b>Self-enrollment</b><br>",
        "1. Go to <u>MedStarHealth.org/PatientPortal</u><br>",
        "2. Click <b>Enroll Now</b><br><br>",
        ;"3. Follow the instructions to enroll. You will need:<br><br>",
        "You will need:<br>",
        "&nbsp;&#9679;&nbsp;&nbsp;First and last name<br>",
        "&nbsp;&#9679;&nbsp;&nbsp;Date of birth<br>",
        ;008-> This is what is changing a bit.
       ;"&nbsp;&#9679;&nbsp;&nbsp;Verification using either your email address, mobile phone or this <b>",patient_id,"</b><br><br>",
       "&nbsp;&#9679;&nbsp;&nbsp;Mobile phone number OR Email address OR this <b>",patient_id,"</b><br><br>",
        ;008<-
    "<b>Email Invitation:</b><br><br>",
    "If you provided an email address during registration you should have received an invitation to ",
    "enroll in the MedStar Health patient portal.<br><br>",

    "&nbsp;&#9679;&nbsp;&nbsp;From within the invitation, click the link to accept the invitation. <br>",
    "&nbsp;&#9679;&nbsp;&nbsp;After successful verification, you will be prompted to create your account. ",
    "Follow the onscreen instructions to complete the enrollment process. <br><br>",

    "MedStar Health is dedicated to helping improve your overall health care experience by providing ",     ;mod003
    "convenient, streamlined resources to help you better manage your health. We now offer the ability ",
    "for you to securely connect some of the health management apps you may use(i.e. fitness trackers, ",
    "dietary trackers, etc.) to your health record. Email us at <u>mymedstar@medstar.net</u> if you are ",
    "interested. Once we receive your request, MedStar Health will work with the appropriate vendors to ",
    "determine if they meet the technical requirements in order to establish a secure connection. <br><br>",

    "If you have questions or need assistance creating your account, please contact support toll ",
    "free at 1-877-745-5656, 24 hours a day, 7 days a week.<br>")

endif
/****************************************************************************************************
                                 Final Formatting
*****************************************************************************************************/
set csText = concat(csText, "</p></body></html>")
set reply->text = csText
set reply->format = 1
/****************************************************************************************************
                                    End of Program
*****************************************************************************************************/
end
go

