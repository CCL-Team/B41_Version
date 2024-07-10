/*********************************************************************************************************************************
 Program Title:     ecase_RR_rpt.prg
 Create Date:       08/15/2022
 Object name:       ecase_RR_rpt
 Source file:       ecase_RR_rpt.prg
 MCGA:
 OPAS:
 Purpose:https:
 Executed from:     Explorer Menu
 Special Notes:
 
**********************************************************************************************************************************
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^IMPORTANT^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
**********************************************************************************************************************************
 This report is a Cerner report. I modified to add email capability.
 
 Wrapper - 14_ecase_testing_wrapper
**********************************************************************************************************************************
**********************************************************************************************************************************
**********************************************************************************************************************************
**********************************************************************************************************************************
                                  MODIFICATION CONTROL LOG
**********************************************************************************************************************************
Mod Date       Analyst       SOM/MCGA Comment
--- ---------- ------------- ------   --------------------------------------------
N/A 08/15/2022 Jeremy Daniel N/A      Initial Release
001 10/12/2023 Michael Mayes 240631   (SCTASK0053833) Changes to allow build Teams integration
002 11/21/2023 Michael Mayes 240025   (SCTASK0059284)  Changes to send up no data message
003 11/21/2023 Michael Mayes 240025   (SCTASK0058496)  Changes to not exclude patients without a FIN on the encounter.
004 07/09/2024 Michael Mayes 239760   (SCTASK0093996) Adding columns for their working sessions to the file.
--------------------------------
*************END OF ALL MODCONTROL BLOCKS* ***************************************************************************************/
;Copy and paste the following into DiscernVisualDeveloper and save:     
        
drop program ecase_RR_rpt go        
create program ecase_RR_rpt     
        
prompt 
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Result Start Date" = "SYSDATE"
    , "Result End Date" = "SYSDATE"
    , "Report Type" = 1 

with OUTDEV, sdate1, edate1, Type       
        
/**************************************************************     
; DVDev DECLARED VARIABLES      
**************************************************************/     
set RR_CD = 0       
set sdate = cnvtdatetime($sdate1)       
set edate = cnvtdatetime($edate1)   
    
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
declare prcnt = i4
 
DECLARE FILENAME = vc
declare emptyfileName = vc   ;002
 
DECLARE dataDate = vc
 
SET dataDate = TRIM(FORMAT(CNVTDATETIME(curdate,curtime3),"mmddyyyyhhmm;;d"),3)
 
SET FILE_NAME =  concat("/cerner/d_p41/cust_output_2/doh_covid_results/medstar_dc-caseip-"
,format(cnvtdatetime(curdate,curtime3),"YYYYMMDDhhmmss;;Q"), ".csv")
    ;build2("medstar_DC", dataDate,".csv");medstar_dc-caseip-"
                             
;002->
SET EMPTY_FILE_NAME =  concat( "/cerner/d_p41/cust_output_2/doh_covid_results/no_data_medstar_dc-caseip-"
                             , format(cnvtdatetime(curdate,curtime3),"YYYYMMDDhhmmss;;Q")
                             , ".csv")
;002<-
 
 
set start_dt_tm = cnvtdatetime((curdate-1), 000000)
set end_dt_tm =   cnvtdatetime((curdate-1), 235959) 
;****************************************************************************************************
;                               VARIABLE DECLARATIONS / EMAIL DEFINITIONS
;****************************************************************************************************
IF($TYPE = 3);EMAILING OF REPORT
    ;001-> Major refactoring here to allow build saves to TEAMS
    DECLARE EMAIL_SUBJECT     = VC WITH NOCONSTANT(' ')
    DECLARE EMAIL_ADDRESSES   = VC WITH NOCONSTANT('')
    DECLARE EMAIL_BODY        = VC WITH NOCONSTANT('')
    DECLARE EMPTY_FILE_NAME   = vc with noconstant('')
    DECLARE UNICODE           = VC WITH NOCONSTANT('')
    
    set     FILE_NAME         = ''
    
    DECLARE AIX_COMMAND       = VC WITH NOCONSTANT('')
    DECLARE AIX_CMDLEN        = I4 WITH NOCONSTANT(0)
    DECLARE AIX_CMDSTATUS     = I4 WITH NOCONSTANT(0)
    
    DECLARE PRODUCTION_DOMAIN = vc with constant('P41')
    DECLARE BUILD_DOMAIN      = vc with constant('B41')
 
    Declare EMAIL_ADDRESS   = vc
    SET EMAIL_ADDRESS = $OUTDEV
 
    Declare newline =          vc with protect, constant(build2(char(13), char(10)))
 
    ;002 Not sure why I moved this up here with my no data work in the other scripts... but I'm emulating
    ;    that work to do this brain off... so I'm doing it here too.
    SET EMAIL_BODY = concat("ms_ecaserr_covid_", 
    format(cnvtdatetime(curdate, curtime3),"YYYYMMDDhhmmss;;Q"), ".dat")
    
    
    if(CURDOMAIN in (PRODUCTION_DOMAIN, BUILD_DOMAIN))
        
        if(CURDOMAIN = PRODUCTION_DOMAIN) 
            SET EMAIL_SUBJECT = build2("ECASE RR Report")
            SET FILE_NAME = 'ms_ecaserr_covid_'
        
        elseif(CURDOMAIN = BUILD_DOMAIN)  
            SET EMAIL_SUBJECT = build2("!!!BUILD!!! ECASE RR Report")
            SET FILE_NAME = 'ms_b41_ecaserr_covid_'
        endif
        
        ;002 This is moving down.
        ;set FILENAME = CONCAT( trim(FILE_NAME, 3)
        ;                     , format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q")
        ;                     , trim(substring(3,3,cnvtstring(RAND(0)))) ;<<<< 3 random #s
        ;                     , ".csv")
    
        Select into (value(EMAIL_BODY))
            build2( "The ECase RR report is attached to this email."                                    , newline, newline
                   
                  , "Date Range: ", $sdate1 , " to ", $edate1                                           , newline, newline

                  , "Run date and time: ",format(cnvtdatetime(curdate, curtime3), "MM/DD/YYYY hh:mm;;Q"), newline, newline
                  )

        from dummyt
        with format, noheading
    
    endif
    
    ;002->
    set FILENAME = CONCAT( trim(FILE_NAME, 3)
                         , format(cnvtdatetime(curdate, curtime3), "YYYYMMDDhhmmss;;Q")
                         , trim(substring(3,3,cnvtstring(RAND(0)))) ;<<<< 3 random #s
                         , ".csv")
    
    set emptyfileName = build2( 'no_data_' , filename)
    
    ;002<-
    
    
    ;001<-
endif

;***** Set Print Record Structure
free record rs
record rs
(   1 PRINTCNT = i4
    1 Qual[*]
        2 HeaderCol = vc
        2 EncntrId = f8
        2 PersonId = f8
        2 Encntr_Type = vc
        2 e_location = vc
        2 Clinic_Name = vc
        2 Name =  vc
        2 MRN = vc
        2 FIN = vc
        2 result_date = dq8
        2 reg_date = dq8
        2 disch_date = dq8
        2 encntr_type = vc
        2 loc = vc
        )
    
/**************************************************************     
; DVDev Start Coding        
**************************************************************/     
        
;;Set code_value for RR     
;select into "nl:"      
;cv.code_value      
;from code_value cv     
;where cv.code_set = 72     
;;and cv.display_key ="REPORTABILITYRESPONSEPUBLICHEALTH"
        
;detail     
;RR_CD = cv.code_value      
;with nocounter     
        
;Main query     
select into "nl:"   
;   Name = substring(1,30,p.name_full_formatted)    
;   , FIN =substring(1,15,ea.alias) 
;   , Result_date = format(c.event_start_dt_tm,"mm/dd/yy hh:mm;;d") 
;   , Reg_date = format(e.REG_DT_TM,"mm/dd/yy hh:mm;;d")    
;   , Disch_date = format(e.disch_dt_tm,"mm/dd/yy") 
;   , ENCNTR_TYPe = substring(1,11,(UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CLASS_CD)))  
;   , LOC= substring(1,30,o.org_name)   
        
FROM        
    clinical_event   c  
    , person   p    
    , encounter   e 
    , encntr_alias   ea 
    , organization o    
        
Plan c      
where c.event_cd =  3713631297.00   ;** uncomment when going live

;in (                                   ;comment out/remove when going live
;               2385455807 ;PCR Ag
;               ,2404008691 ;POC Ag
; 
;   );= RR_CD                           ;comment out/remove when going live
   and c.view_level = 1     
   and c.event_start_dt_tm between cnvtdatetime(sdate) and cnvtdatetime(edate)  
        
join p where c.person_id = p.person_id      
    ;and p.name_last_key not ="QQTEST" ; use to filter out test patients if desired 
        
Join e where c.encntr_ID = e.encntr_id      

;003->  Reordering columns and adding outerjoins here.      
Join ea 
 where ea.encntr_id            = outerjoin(c.encntr_id)
   and ea.encntr_alias_type_cd = outerjoin(1077)
;003<-   
Join o where e.organization_id = o.organization_id      
        
ORDER BY    c.event_id
    ,e.organization_id  
    ,p.person_id    
    ,c.event_start_dt_tm DESC   
    ,e.REG_DT_TM   DESC 
        
head report
    patients = 0
 
head C.event_id
 
patients = patients + 1
STAT=ALTERLIST(RS->QUAL,PATIENTS)
  
    rs->QUAL[patients]->name = p.name_full_formatted
    rs->QUAL[patients]->personID = c.person_id
    rs->QUAL[patients]->encntrID = c.encntr_id
    rs->QUAL[patients]->encntr_type = UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CLASS_CD)
    rs->QUAL[patients]->loc = o.org_name
    
with nocounter, time = 200
;****************************************************************************************
; OUTPUT
;****************************************************************************************
If($Type = 2)
;#exit_program
; if (size(rs->QUAL,5) > 0); AT LEAST ONE PATIENT FOUND ABOVE
 
 SELECT INTO VALUE(FILE_NAME)

      NAME           = trim(SUBSTRING(1, 130, rs->QUAL[D1.SEQ].Name))
    , FIN            = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FIN))
    , RESULT_DATE    = format(rs->QUAL[d1.seq].RESULT_DATE, "@SHORTDATETIME")
    , REG_DATE       = format(rs->QUAL[d1.seq].REG_DATE, "@SHORTDATETIME")
    , DISCH_DATE     = format(rs->QUAL[d1.seq].DISCH_DATE, "MM/DD/YYYY;;q")
    , ENCNTR_TYPE    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ENCNTR_TYPE))
    , LOC            = trim(SUBSTRING(1, 130, rs->QUAL[D1.SEQ].LOC))
    
    FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
 
 
    plan d1
 
;   where rs->QUAL[d1.seq].fac_State = "DC"
;   and (rs->QUAL[d1.seq].Result = "Detected"
;   or rs->QUAL[d1.seq].Result = "Positive" )
;   and rs->QUAL[d1.seq].action_event != "Endorse"
 
    order by LOC
 
    with Heading, PCFormat('"', ',',1), format=STREAM, compress, nocounter, format
 
 
    select into $outdev
        msg="success"
        from dummyt
        with nocounter
        
elseif($type = 1)
 
 if (size(rs->QUAL,5) > 0)
 
    select into $outdev
    
      NAME           = trim(SUBSTRING(1, 130, rs->QUAL[D1.SEQ].Name))
    , FIN            = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FIN))
    , RESULT_DATE    = format(rs->QUAL[d1.seq].RESULT_DATE, "@SHORTDATETIME")
    , REG_DATE       = format(rs->QUAL[d1.seq].REG_DATE, "@SHORTDATETIME")
    , DISCH_DATE     = format(rs->QUAL[d1.seq].DISCH_DATE, "MM/DD/YYYY;;q")
    , ENCNTR_TYPE    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ENCNTR_TYPE))
    , LOC            = trim(SUBSTRING(1, 130, rs->QUAL[D1.SEQ].LOC))
    
    
    FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
 
 
    plan d1
 
;   where rs->QUAL[d1.seq].fac_State = "DC"
;   and (rs->QUAL[d1.seq].Result = "Detected"
;   or rs->QUAL[d1.seq].Result = "Positive" )
;   and rs->QUAL[d1.seq].action_event != "Endorse"
 
    order by LOC
 
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

;EMAIL
elseif($type = 3)
 
    if (size(rs->QUAL,5) > 0); AT LEAST ONE PATIENT FOUND ABOVE

        call echo(build('FILE_NAME:', FILE_NAME))
        call echo(build('FILENAME:', FILENAME))
        
        select into value(FILENAME)
               NAME           = trim(SUBSTRING(1, 130, rs->QUAL[D1.SEQ].Name))
             , FIN            = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].FIN))
             , RESULT_DATE    = format(rs->QUAL[d1.seq].RESULT_DATE, "@SHORTDATETIME")
             , REG_DATE       = format(rs->QUAL[d1.seq].REG_DATE, "@SHORTDATETIME")
             , DISCH_DATE     = format(rs->QUAL[d1.seq].DISCH_DATE, "MM/DD/YYYY;;q")
             , ENCNTR_TYPE    = trim(SUBSTRING(1, 30, rs->QUAL[D1.SEQ].ENCNTR_TYPE))
             , LOC            = trim(SUBSTRING(1, 130, rs->QUAL[D1.SEQ].LOC))
             , PERSON_ID      = RS->QUAL[d1.seq].PersonId  ;004
             , ENCNTR_ID      = RS->QUAL[d1.seq].EncntrId  ;004
             , Document_ID    = ''                         ;004
             , RR_NOTES       = ''                         ;004
    
        FROM (DUMMYT D1 WITH SEQ = SIZE(RS->QUAL,5))
     
        plan d1
     
        order by LOC
        
        with Heading, PCFormat('"', ',', 1), format=STREAM, Format,  NoCounter , compress
 
 
        ;***********EMAIL THE ACTUAL ZIPPED FILE**************************** ;MOD004
        ;001-> Refactoring here to add B41
        if(CURDOMAIN in (PRODUCTION_DOMAIN, BUILD_DOMAIN))
     
            SET  AIX_COMMAND  =
                build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
                       " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS)
     
            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            
            call echo(build('AIX_COMMAND:', AIX_COMMAND))
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
     
            call pause(2);LETS SLOW THINGS DOWN
     
            SET  AIX_COMMAND  =
                CONCAT ('rm -f ' , FILENAME,  ' | rm -f ' , EMAIL_BODY)
     
            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            
            call echo(build('AIX_COMMAND:', AIX_COMMAND))
            
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
        
        
        endif
        ;001<-
 
    else
        ;002-> 
        ;This is the no data case... so we can do our file work.
        set FILE_NAME = EMPTY_FILE_NAME
        set FILENAME  = emptyfileName

        call echo(build('FILE_NAME:', FILE_NAME))
        call echo(build('FILENAME:', FILENAME))
        ;002<-
    
        select into value(FILENAME)
 
        Report_value        = "No data found"
 
        from (dummyt d1 with seq = size(1))
 
        if    (CURDOMAIN = PRODUCTION_DOMAIN) set EMAIL_SUBJECT = "ECASE RR Report -No accounts found"
        elseif(CURDOMAIN = BUILD_DOMAIN     ) set EMAIL_SUBJECT = "!!! BUILD !!! ECASE RR Report -No accounts found"
        endif
 
 
        ;***********EMAIL THE ACTUAL ZIPPED FILE**************************** ;MOD004
        ;001-> Refactoring here to add B41
        if(CURDOMAIN in (PRODUCTION_DOMAIN, BUILD_DOMAIN))
     
            SET  AIX_COMMAND  =
                build2 ( "cat ", EMAIL_BODY ," | tr -d \\r",
                       " | mailx  -S from='report@medstar.net' -s '" ,EMAIL_SUBJECT , "' -a ", FILENAME, " ", EMAIL_ADDRESS)
     
            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            
            call echo(build('AIX_COMMAND:', AIX_COMMAND))
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
     
            call pause(2);LETS SLOW THINGS DOWN
     
            SET  AIX_COMMAND  =
                CONCAT ('rm -f ' , FILENAME,  ' | rm -f ' , EMAIL_BODY)
     
            SET AIX_CMDLEN = SIZE(TRIM(AIX_COMMAND))
            SET AIX_CMDSTATUS = 0
            
            call echo(build('AIX_COMMAND:', AIX_COMMAND))
            
            CALL DCL(AIX_COMMAND,AIX_CMDLEN, AIX_CMDSTATUS)
            
            
        endif
        ;001<-
 
    endif
endif       
    
;call center("eCase Reportability Response",0,130)      
;row +1     
;line = fillstring(130,"=")     
;line2 = fillstring(125,"-")        
;row +2     
;col 5, "Name "     
;       
; col 35, "FIN"     
;col 50 , "Type"    
;col 65, "Reg Date"     
;col 85, "DC Date"      
;col 97, "RR Date/Time"     
;       
;row +1     
;       
;head e.organization_id     
;       
;col 0 LOC      
;row+1      
;col 0 line     
;row+1      
;head p.person_id       
;row +0     
;col 5, Name        
;col 35, FIN        
;col 50,  ENCNTR_TYPE       
;col 65, Reg_date       
;col 85, Disch_date     
;       
;detail     
;col 97, Result_date        
;row +1     
;       
;foot p.person_id       
;row +0     
;       
;row +1     
;foot e.organization_id     
;row +1     
;       
;with nocounter     
        


end
go
