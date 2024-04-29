drop program mmmtest go
create program mmmtest
 
 
/*************************************************************************
*  Include files                                                         *
*************************************************************************/
;%i cclsource:mp_common.inc
 
/* DECLARE VARIABLES *****************************************************************************/

 
/* DECLARE SUBROUTINES ***************************************************************************/
declare cnvtDQ8ToIsoDtTm(P1=F8) 										= VC with protect
 
/* RECORD STRUCTURES *****************************************************************************/
/* The record structure to pass in phone types should look like the following (in order of preference)
free record phone_types
record phone_types(
	1 phone_codes[*]
		2 phone_cd = f8
)
*/

 
/**
 * cnvtDQ8ToIsoDtTm()
 * Purpose:
 *   Converts a DQ8 into an ISO 8601 formatted date string
 *
 * @return {vc}
 *
 * @param {f8, which is the same as a dq8} dq8DtTm DateTime Value
*/
subroutine cnvtDQ8ToIsoDtTm(dq8DtTm)
	declare convertedIsoDtTm = vc with protect, noconstant("")
 
	set convertedIsoDtTm = build(replace(datetimezoneformat(cnvtdatetime(dq8DtTm) ,
		DATETIMEZONEBYNAME("UTC"),"yyyy-MM-dd HH:mm:ss",curtimezonedef)," ","T",1),"Z")
 
	return(convertedIsoDtTm)
 
end  ;subroutine cnvtDQ8ToIsoDtTm
 


 
 
 
;%i cclsource:mp_script_logging.inc
 
/***********************************************************************
 *   Parameter Variables                                               *
 ***********************************************************************/
  declare log_program_name  = vc with protect, noconstant("")
  declare log_override_ind  = i2 with protect, noconstant(0)
 
/***********************************************************************
 *   Initialize Parameters                                             *
 ***********************************************************************/
  set log_program_name = CURPROG
  set log_override_ind = 0
 
/***********************************************************************
 *   Initialize Constants                                              *
 ***********************************************************************/
  declare LOG_LEVEL_ERROR   = i2 with protect, noconstant(0)
  declare LOG_LEVEL_WARNING = i2 with protect, noconstant(1)
  declare LOG_LEVEL_AUDIT   = i2 with protect, noconstant(2)
  declare LOG_LEVEL_INFO    = i2 with protect, noconstant(3)
  declare LOG_LEVEL_DEBUG   = i2 with protect, noconstant(4)
 
/***********************************************************************
 *   Initialize Logging and Error() Function                           *
 ***********************************************************************/
  declare sErrMsg  = c132 with protect, noconstant(" ")
  declare iErrCode = i4 with protect, noconstant(Error(sErrMsg, 1))
 
  declare CRSL_MSG_DEFAULT = i4 with protect, noconstant(0)
  declare CRSL_MSG_LEVEL   = i4 with protect, noconstant(0)
 
  execute msgrtl
  set CRSL_MSG_DEFAULT = uar_MsgDefHandle ()
  set CRSL_MSG_LEVEL   = uar_MsgGetLevel (CRSL_MSG_DEFAULT)
 
/************************************************************************
 *   Initialize other variables.  These were moved here since a declare *
 *   statement cannot be used within a subroutine called from within    *
 *   detail clauses (as these subroutines are).                         *
 ***********************************************************************/
  declare lCRSLSubEventCnt       = i4 with protect, noconstant(0)
  declare iCRSLLoggingStat       = i2 with protect, noconstant(0)
  declare lCRSLSubEventSize      = i4 with protect, noconstant(0)
  declare iCRSLLogLvlOverrideInd = i2 with protect, noconstant(0)
  declare sCRSLLogText           = vc with protect, noconstant("")
  declare sCRSLLogEvent          = vc with protect, noconstant("")
  declare iCRSLHoldLogLevel      = i2 with protect, noconstant(0)
  declare iCRSLErrorOccured      = i2 with protect, noconstant(0)
  declare lCRSLUarMsgwriteStat   = i4 with protect, noconstant(0)
 
/***********************************************************************
 *   Read the DM_INFO table for the program name.  This will eliminate *
 *   the need for scripts to read for a DM_INFO row to turn on script  *
 *   logging override.                                                 *
 *   Simply setup the DM_INFO row as follows to turn on logging:       *
 *     INFO_DOMAIN = "PATHNET SCRIPT LOGGING"                          *
 *     INFO_NAME   = ccl program name in all uppercase                 *
 *     INFO_CHAR   = "L"                                               *
 ***********************************************************************/
  declare CRSL_INFO_DOMAIN    = vc with protect, constant("DISCERNABU SCRIPT LOGGING")
  declare CRSL_LOGGING_ON     = c1 with protect, constant("L")
 
if(LOGICAL("MP_LOGGING_ALL") > " " OR LOGICAL(concat("MP_LOGGING_", log_program_name)) > " ")
	set log_override_ind = 1
endif
 
 
DECLARE LOG_MESSAGE(LogMsg=VC,LogLvl=I4) = NULL
/***********************************************************************
 *   LOG_MESSAGE routine is called to write out a log message to       *
 *   msgview.  The log message and message level should be passed in   *
 *   the corresponding parameters.  The routine will use the string    *
 *   stored in log_program_name as the script.  It will also override  *
 *   the log level passed in if the log_override_ind is set to 1.      *
 ***********************************************************************/
subroutine LOG_MESSAGE(LogMsg, LogLvl)
 
  ; Initialize override flag
  set iCRSLLogLvlOverrideInd = 0
 
  ; Build log message in form "{{Script::ScriptName}} Log Message"
  set sCRSLLogText = ""
  set sCRSLLogEvent = ""
  set sCRSLLogText = CONCAT("{{Script::", VALUE(log_program_name), "}} ", LogMsg)
 
  ; Determine the appropriate log level at which to write message
  if (log_override_ind = 0)
    set iCRSLHoldLogLevel = LogLvl               ; write using passed in log level
  else
    if (CRSL_MSG_LEVEL < LogLvl)
      set iCRSLHoldLogLevel = CRSL_MSG_LEVEL  ; write using server log level (override)
      set iCRSLLogLvlOverrideInd = 1
    else
      set iCRSLHoldLogLevel = LogLvl             ; write using passed in log level
    endif
  endif
 
  ; Write log message using appropriate log level
  if (iCRSLLogLvlOverrideInd = 1)
    set sCRSLLogEvent = "Script_Override"
  else
    case (iCRSLHoldLogLevel)
      of LOG_LEVEL_ERROR:
         set sCRSLLogEvent = "Script_Error"
      of LOG_LEVEL_WARNING:
         set sCRSLLogEvent = "Script_Warning"
      of LOG_LEVEL_AUDIT:
         set sCRSLLogEvent = "Script_Audit"
      of LOG_LEVEL_INFO:
         set sCRSLLogEvent = "Script_Info"
      of LOG_LEVEL_DEBUG:
         set sCRSLLogEvent = "Script_Debug"
    endcase
  endif
 
  set lCRSLUarMsgwriteStat =
    uar_MsgWrite(CRSL_MSG_DEFAULT, 0, nullterm(sCRSLLogEvent), iCRSLHoldLogLevel, nullterm(sCRSLLogText))
    call echo(LogMsg)
 
end ; LOG_MESSAGE subroutine
 
/***************/
 
 
DECLARE ERROR_MESSAGE(LogStatusBlockInd = i2) = i2
/***********************************************************************
 *   The ERROR_MESSAGE routine is called to check for CCL errors after *
 *   a CCL select statement.  If errors are found, this routine will   *
 *   write the error to msgview and the subeventstatus block in the    *
 *   reply record.                                                     *
 ***********************************************************************/
subroutine ERROR_MESSAGE(LogStatusBlockInd)
 
  set iCRSLErrorOccured = 0
 
  ; Check for CCL error
  set iErrCode = Error(sErrMsg, 0)
  while (iErrCode > 0)
    set iCRSLErrorOccured = 1
    if(validate(reply))
      set reply->status_data->status = "F"
    endif
 
    ; Write CCL error message to msgview
    call log_message(sErrMsg, log_level_audit)
 
    ; Write CCL errors to subeventstatus block if it exists
    if (LogStatusBlockInd = 1)
      ; write error to subeventstatus
	  if(validate(reply))  ;validate reply exists before attempting to populate subeventstatus
        call populate_subeventstatus("EXECUTE", "F", "CCL SCRIPT", sErrMsg)
	  endif
    endif
 
    ; Retrieve additional CCL errors
    set iErrCode = Error(sErrMsg, 0)
  endwhile
 
  return(iCRSLErrorOccured)
 
end ; ERROR_MESSAGE subroutine
 
 /***************/
 
DECLARE ERROR_AND_ZERO_CHECK_REC(QualNum = i4,
                             OpName = vc,
                             LogMsg = vc,
                             ErrorForceExit = i2,
                             ZeroForceExit = i2,
                             RecordData = vc (REF)) = i2
/***********************************************************************
 *   The ERROR_AND_ZERO_CHECK routine is called to check for           *
 *   CCL errors or zero rows after a CCL select statement.             *
 *   If errors are found, this routine will                            *
 *   write the error to msgview and the subeventstatus block in the    *
 *   record structure provided                                         *
 ***********************************************************************/
subroutine ERROR_AND_ZERO_CHECK_REC(QualNum, OpName, LogMsg,
                                ErrorForceExit, ZeroForceExit,RecordData)
  set iCRSLErrorOccured = 0
 
  ; Check for CCL error
  set iErrCode = Error(sErrMsg, 0)
  while (iErrCode > 0)
    set iCRSLErrorOccured = 1
 
    ; Write CCL error message to msgview
    call log_message(sErrMsg, log_level_audit)
 
    ; write error to subeventstatus
    call populate_subeventstatus_rec(OpName, "F", sErrMsg, LogMsg, RecordData)
 
    ; Retrieve additional CCL errors
    set iErrCode = Error(sErrMsg, 0)
  endwhile
 
  if (iCRSLErrorOccured = 1 and ErrorForceExit = 1)
  	set RecordData->status_data->status = "F"
    go to exit_script
  endif
 
  ; Check for Zero Returned
 
  if (QualNum = 0 and ZeroForceExit = 1)
  	set RecordData->status_data->status = "Z"
    ; write error to subeventstatus
    call populate_subeventstatus_rec(OpName, "Z", "No records qualified", LogMsg, RecordData)
    go to exit_script
  endif
 
 
  return(iCRSLErrorOccured)
end
 
 /***************/
 
DECLARE ERROR_AND_ZERO_CHECK(QualNum = i4,
                             OpName = vc,
                             LogMsg = vc,
                             ErrorForceExit = i2,
                             ZeroForceExit = i2) = i2
/***********************************************************************
 *   The ERROR_AND_ZERO_CHECK routine is called to check for           *
 *   CCL errors or zero rows after a CCL select statement.             *
 *   If errors are found, this routine will                            *
 *   write the error to msgview and the subeventstatus block in the    *
 *   reply record.                                                     *
 ***********************************************************************/
subroutine ERROR_AND_ZERO_CHECK(QualNum, OpName, LogMsg, ErrorForceExit, ZeroForceExit)
  return(ERROR_AND_ZERO_CHECK_REC(QualNum, OpName, LogMsg,ErrorForceExit, ZeroForceExit, reply))
end ; ERROR_AND_ZERO_CHECK subroutine
 
 
declare POPULATE_SUBEVENTSTATUS_REC(OperationName = vc (value),
                                OperationStatus = vc (value),
                                TargetObjectName = vc (value),
                                TargetObjectValue = vc (value),
                                RecordData = vc(REF)) = i2
 
/***************************************************************************
*   The POPULATE_SUBEVENTSTATUS_REC routine is called to fill out an entry *
*   in the subeventstatus list of a standard record.                       *
***************************************************************************/
subroutine POPULATE_SUBEVENTSTATUS_REC(OperationName, OperationStatus, TargetObjectName, TargetObjectValue, RecordData)
 
  /* Validate that status block exists */
  if (validate(RecordData->status_data->status, "-1") != "-1")
    /* get current size of subevent status */
    set lCRSLSubEventCnt = size(RecordData->status_data->subeventstatus, 5)
 
    /* If last item in array is populated, then increase the size of the array by one.
       Otherwise, assume it is an empty item in the list and use it. */
    set lCRSLSubEventSize = size(trim(RecordData->status_data->subeventstatus[lCRSLSubEventCnt].OperationName))
    set lCRSLSubEventSize = lCRSLSubEventSize +
      size(trim(RecordData->status_data->subeventstatus[lCRSLSubEventCnt].OperationStatus))
    set lCRSLSubEventSize = lCRSLSubEventSize +
      size(trim(RecordData->status_data->subeventstatus[lCRSLSubEventCnt].TargetObjectName))
    set lCRSLSubEventSize = lCRSLSubEventSize +
      size(trim(RecordData->status_data->subeventstatus[lCRSLSubEventCnt].TargetObjectValue))
 
    if (lCRSLSubEventSize > 0)
      set lCRSLSubEventCnt = lCRSLSubEventCnt + 1
      set iCRSLLoggingStat = alter(RecordData->status_data->subeventstatus, lCRSLSubEventCnt)
    endif
 
    set RecordData->status_data.subeventstatus[lCRSLSubEventCnt].OperationName =
      substring(1, 25, OperationName)
    set RecordData->status_data.subeventstatus[lCRSLSubEventCnt].OperationStatus =
      substring(1, 1, OperationStatus)
    set RecordData->status_data.subeventstatus[lCRSLSubEventCnt].TargetObjectName =
      substring(1, 25, TargetObjectName)
    set RecordData->status_data.subeventstatus[lCRSLSubEventCnt].TargetObjectValue =
      TargetObjectValue
  endif
 
end ; POPULATE_SUBEVENTSTATUS subroutine
 
/***************/
 /***************/
 
 declare POPULATE_SUBEVENTSTATUS(OperationName = vc (value),
                                OperationStatus = vc (value),
                                TargetObjectName = vc (value),
                                TargetObjectValue = vc (value)) = i2
/***********************************************************************
*   The POPULATE_SUBEVENTSTATUS routine is called to fill out an entry *
*   in the subeventstatus list of a standard reply.                    *
************************************************************************/
subroutine POPULATE_SUBEVENTSTATUS(OperationName, OperationStatus, TargetObjectName, TargetObjectValue)
  call POPULATE_SUBEVENTSTATUS_REC(OperationName, OperationStatus, TargetObjectName, TargetObjectValue, reply)
end ; POPULATE_SUBEVENTSTATUS subroutine
 
/***************/
 
declare POPULATE_SUBEVENTSTATUS_MSG(OperationName = vc (value),
                                    OperationStatus = vc (value),
                                    TargetObjectName = vc (value),
                                    TargetObjectValue = vc (value),
                                    LogLevel = i2 (value)) = i2
/***************************************************************************
*   The POPULATE_SUBEVENTSTATUS_MSG routine is called to fill out an entry *
*   in the subeventstatus list of a standard reply and to write the        *
*   TargetObjectValue argument to the message log                          *
****************************************************************************/
subroutine POPULATE_SUBEVENTSTATUS_MSG(OperationName, OperationStatus, TargetObjectName, TargetObjectValue, LogLevel)
 
  call populate_subeventstatus(OperationName, OperationStatus, TargetObjectName, TargetObjectValue)
  call log_message(TargetObjectValue, LogLevel)
 
 
end ; POPULATE_SUBEVENTSTATUS_MSG subroutine
 
/***************/
 

 
/*************************************************************************
* Subroutine Declarations                                                *
*************************************************************************/
declare ConvertStrDateToIsoFormat(date = vc) = vc with protect
 
/*************************************************************************
* Record Structures                                                      *
*************************************************************************/
/*
record request
(
%i cclsource:hi_get_person_demogr_req.inc
)
*/
 
if (not validate(reply))
record reply
(
;%i cclsource:hi_get_person_demogr_rep.inc
1 person_id = f8
1 hi_person_identifier = vc
1 given_names[*]
  2 given_name = vc
1 family_names[*]
  2 family_name = vc
1 full_name = vc
1 date_of_birth = vc
1 gender_details
  2 id = vc
  2 coding_system_id = vc
1 address
  2 street_addresses[*]
    3 street_address = vc
  2 type
    3 id = vc
    3 coding_system_id = vc
  2 city = vc
  2 state_or_province_details
    3 id = vc
    3 coding_system_id = vc
  2 postal_code = vc
  2 county_or_parish = vc
  2 county_or_parish_details
    3 id = vc
    3 coding_system_id = vc
  2 country_details
    3 id = vc
    3 coding_system_id = vc
1 telecoms[*]
  2 preferred = vc
  2 number = vc
  2 country_code = vc
  2 type
    3 id = vc
    3 coding_system_id = vc
    3 display = vc
1 email_addresses[*]
  2 address = vc
  2 type
    3 id = vc
    3 coding_system_id = vc
1 health_plans[*]
  2 mill_health_plan_id = f8
  2 payer_name = vc
  2 plan_name = vc
  2 begin_iso_dt_tm = vc
  2 end_iso_dt_tm = vc
  2 member_nbr = vc
  2 line_of_business = vc
  2 source
    3 contributing_organization = vc
    3 partition_description = vc
    3 type = vc
  2 plan_identifiers[*]
    3 value = vc
    3 type = vc
;%i cclsource:status_block.inc
1 status_data
    2 status = c1
    2 subeventstatus[1]
      3 OperationName = c25
      3 OperationStatus = c1
      3 TargetObjectName = c25
      3 TargetObjectValue = vc
)
endif
 
free record person_demogr_reply
record person_demogr_reply
(
;%i cclsource:hi_proxy_reply_common.inc
  1 transactionStatus
    2 successInd = ui1
    2 debugErrorMessage = vc
    2 prereqErrorInd = ui1
  1 httpReply
    2 version = vc
    2 status = ui2
    2 statusReason = vc
    2 httpHeaders[*]
      3 name = vc
      3 value = vc
    2 body = gvc
)
 
/*************************************************************************
*  Variable Declarations                                                 *
*************************************************************************/
;call echorecord(request)
 
declare PERSON_DEMOGRAPHICS_TEST_URI = vc with protect, constant(request->demographics_test_uri)
declare PERSON_ID = f8 with protect, constant(request->person_id)
declare HI_PERSON_IDENTIFIER = vc with protect, constant(request->hi_person_identifier)
declare HI_BENEFIT_FILTER_SOURCE_TYPE = vc with protect, constant(request->benefit_coverage_source_type)
declare PERSON_DEMOGRAPHICS_REQUEST_KEY = vc with protect, constant("hi_record_api_person_demographics")
declare HI_EMPI_LOOKUP_KEY = vc with protect, constant("hi_record_person_empi_lookup")
 
declare person_demographics = gvc with protect, noconstant("")
declare person_demographic_parameters = vc with protect, noconstant("empi_person_id=")
declare bc_idx = i4 with protect, noconstant(0)
declare plan_idx = i4 with protect, noconstant(0)
declare plan_cnt = i4 with protect, noconstant(0)
declare plan_value = vc with protect, noconstant("")
declare plan_type = vc with protect, noconstant("")
declare hi_proxy_error_message = vc with protect, noconstant("")
 
/*************************************************************************
*  Begin Program                                                         *
*************************************************************************/
 
;call echo ("made it to start of program: person demographics")
 
set reply->person_id = PERSON_ID
set reply->hi_person_identifier = HI_PERSON_IDENTIFIER
set reply->status_data->status = "F"
 
;call echorecord(reply)
 
; The component is coded to pass in the service key if uri is not set in bedrock.
if (textlen(trim(PERSON_DEMOGRAPHICS_TEST_URI)) > 0)
 
call echo ("made it to start of program: execute get http request via URI")
 
  execute hi_http_proxy_get_request "MINE", PERSON_DEMOGRAPHICS_TEST_URI
    with replace("PROXYREPLY", person_demogr_reply)
else
  if (PERSON_ID = 0 and textlen(trim(HI_PERSON_IDENTIFIER)) = 0)
    set reply->status_data->subeventstatus[1]->TargetObjectValue = "Missing valid person id or HI person identifer"
    go to END_SCRIPT
  endif
 
  if (textlen(trim(HI_PERSON_IDENTIFIER)) > 0)
    set person_demographic_parameters = concat(person_demographic_parameters, trim(HI_PERSON_IDENTIFIER))
 
    if (textlen(trim(HI_BENEFIT_FILTER_SOURCE_TYPE)) > 0)
      set person_demographic_parameters =
        build2(person_demographic_parameters, ";", "benefit_coverages.type=", trim(HI_BENEFIT_FILTER_SOURCE_TYPE))
    endif
 
    execute hi_http_proxy_get_request "MINE", PERSON_DEMOGRAPHICS_REQUEST_KEY, "JSON", 0.0, 0.0,
      person_demographic_parameters with replace("PROXYREPLY", person_demogr_reply)
  else
    if (PERSON_ID > 0)
      ; call hi_alias_lookup to get record api demographics url in the aliasLookupReply.
      execute hi_alias_lookup "MINE", HI_EMPI_LOOKUP_KEY, PERSON_DEMOGRAPHICS_REQUEST_KEY, PERSON_ID
 
      ; For a successful response, call the record api demographics endpoint
      if (aliasLookupReply->status_data->status = "S")
        if (textlen(trim(request->benefit_coverage_source_type)) > 0)
          set aliasLookupReply->hiUri = build2(aliasLookupReply->hiUri,
            "&benefit_coverages.type=", HI_BENEFIT_FILTER_SOURCE_TYPE)
        endif
 
        call echorecord(aliasLookupReply)
 
        call echo('!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
        call echo(aliasLookupReply->hiUri)
        ;set aliasLookupReply->hiUri = build2(aliasLookupReply->hiUri, '/provider_relationships')
        
        
        
        ;THIS ONE WORKS FOR ATTRIB.
        ;set aliasLookupReply->hiUri = build2( 'https://medstarhealth.registries.healtheintent.com/api/populations/'
        ;                                    , 'd2f137ff-3778-4917-ab34-b8cc85cbc41d/people/bf018fa9-3646-4e52-af85-4a44e149f744'
        ;                                    , '/provider_relationships/')

        
        
        
        
        
        ;set aliasLookupReply->hiUri = 'https://medstarhealth.record.healtheintent.com/api/populations/'

        ;set aliasLookupReply->hiUri = build2( 'https://medstarhealth.registries.healtheintent.com/api/populations'
        ;                                    , '/d2f137ff-3778-4917-ab34-b8cc85cbc41d/programs/')

    

        call echo(aliasLookupReply->hiUri)
        
        
        ;set aliasLookupReply->hiUri = build2(aliasLookupReply->hiUri, '/provider_relationships')
        ;call echo(aliasLookupReply->hiUri)
        call echo('!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
 
        execute hi_http_proxy_get_request "MINE", aliasLookupReply->hiUri, "JSON"
            with replace("PROXYREPLY", person_demogr_reply)
        
        call echo(person_demogr_reply->httpReply->body)
        
        set person_demographics = concat('{"demographics_data":{"test_list":', person_demogr_reply->httpReply->body, '}}')
        call echo(person_demographics)
        set stat = cnvtjsontorec(person_demographics)
  
        call echojson(demographics_data)
        go to END_SCRIPT
 
      ; For a successful response, but no HealtheIntent person was found.
      elseif(aliasLookupReply->status_data->status = "P")
        set reply->status_data->status = "Z"
        go to END_SCRIPT
 
      else
        set reply->status_data->status = "F"
        set reply->status_data->subeventstatus[1]->targetObjectName =
          aliasLookupReply->status_data->subeventstatus[1]->targetObjectName
        set reply->status_data->subeventstatus[1]->targetObjectValue =
          aliasLookupReply->status_data->subeventstatus[1]->targetObjectValue
        call log_message(build2("httpReply->status: ", person_demogr_reply->httpReply->status), LOG_LEVEL_ERROR)
        call log_message(person_demogr_reply->httpReply->body, LOG_LEVEL_ERROR)
 
        go to END_SCRIPT
      endif
    endif
  endif
endif
 
;call echorecord (person_demogr_reply)
 
;declare temp=vc
;set temp = person_demogr_reply->httpreply->body
;call echo (build("temp:", temp) )
 
/*
 
set temp=vc
set temp= person_demogr_reply->httpreply->body)
call echo (build("temp:", temp) )
 
>>>Begin EchoRecord PERSON_DEMOGR_REPLY   ;PERSON_DEMOGR_REPLY
 1 TRANSACTIONSTATUS
  2 SUCCESSIND=UI1   {1}
  2 DEBUGERRORMESSAGE=VC0   {}
  2 PREREQERRORIND=UI1   {0}
 1 HTTPREPLY
  2 VERSION=VC8   {HTTP/1.1}
  2 STATUS=UI2   {200}
  2 STATUSREASON=VC2   {OK}
  2 HTTPHEADERS[1,24*]
   3 NAME=VC12   {Content-Type}
   3 VALUE=VC31   {application/json; charset=utf-8}
  2 HTTPHEADERS[2,24*]
   3 NAME=VC17   {Transfer-Encoding}
   3 VALUE=VC7   {chunked}
  2 HTTPHEADERS[3,24*]
   3 NAME=VC10   {Connection}
   3 VALUE=VC10   {keep-alive}
  2 HTTPHEADERS[4,24*]
   3 NAME=VC4   {Date}
   3 VALUE=VC29   {Sun, 10 Oct 2021 06:13:34 GMT}
  2 HTTPHEADERS[5,24*]
   3 NAME=VC13   {Cache-Control}
   3 VALUE=VC35   {max-age=0, private, must-revalidate}
  2 HTTPHEADERS[6,24*]
   3 NAME=VC21   {Cerner-Correlation-Id}
   3 VALUE=VC36   {b72c01c8-688b-42b2-b8be-0b2fbf1cae6d}
  2 HTTPHEADERS[7,24*]
   3 NAME=VC4   {Etag}
   3 VALUE=VC36   {W/"b139657fe9e01c2b0328a963e3c9b818"}
  2 HTTPHEADERS[8,24*]
   3 NAME=VC15   {Referrer-Policy}
   3 VALUE=VC31   {strict-origin-when-cross-origin}
  2 HTTPHEADERS[9,24*]
   3 NAME=VC6   {Server}
   3 VALUE=VC25   {nginx + Phusion Passenger}
  2 HTTPHEADERS[10,24*]
   3 NAME=VC6   {Status}
   3 VALUE=VC6   {200 OK}
  2 HTTPHEADERS[11,24*]
   3 NAME=VC25   {Strict-Transport-Security}
   3 VALUE=VC35   {max-age=31536000; includeSubDomains}
  2 HTTPHEADERS[12,24*]
   3 NAME=VC22   {X-Content-Type-Options}
   3 VALUE=VC7   {nosniff}
  2 HTTPHEADERS[13,24*]
   3 NAME=VC18   {X-Download-Options}
   3 VALUE=VC6   {noopen}
  2 HTTPHEADERS[14,24*]
   3 NAME=VC15   {X-Frame-Options}
   3 VALUE=VC10   {SAMEORIGIN}
  2 HTTPHEADERS[15,24*]
   3 NAME=VC19   {X-Newrelic-App-Data}
   3 VALUE=VC136   {PxQGVlRSDAcCR1NRBAgBU1QGBBFORCANXhZKDVRUUUAcBEkIHhFWDRRaUk4VC1dEEkhRTAcdB0hVCQYA}
                   {UlZaVwFSCFYICgwBAUkUUB1DBVsFBwYAA1YAAQgCBQYAAxVKAlBaQAc7}
  2 HTTPHEADERS[16,24*]
   3 NAME=VC33   {X-Permitted-Cross-Domain-Policies}
   3 VALUE=VC4   {none}
  2 HTTPHEADERS[17,24*]
   3 NAME=VC12   {X-Powered-By}
   3 VALUE=VC17   {Phusion Passenger}
  2 HTTPHEADERS[18,24*]
   3 NAME=VC12   {X-Request-Id}
   3 VALUE=VC36   {d1516ffb-1cc1-4573-8215-fced6b4b433a}
  2 HTTPHEADERS[19,24*]
   3 NAME=VC9   {X-Runtime}
   3 VALUE=VC8   {0.179382}
  2 HTTPHEADERS[20,24*]
   3 NAME=VC16   {X-Xss-Protection}
   3 VALUE=VC13   {1; mode=block}
  2 HTTPHEADERS[21,24*]
   3 NAME=VC7   {X-Cache}
   3 VALUE=VC20   {Miss from cloudfront}
  2 HTTPHEADERS[22,24*]
   3 NAME=VC3   {Via}
   3 VALUE=VC64   {1.1 c923d89f70351e442aa1b87e2d6434f8.cloudfront.net (CloudFront)}
  2 HTTPHEADERS[23,24*]
   3 NAME=VC12   {X-Amz-Cf-Pop}
   3 VALUE=VC8   {ATL56-C1}
  2 HTTPHEADERS[24,24*]
   3 NAME=VC11   {X-Amz-Cf-Id}
   3 VALUE=VC56   {GGgH0vYtAuNB_LWHBI4yo-496Udu7dJrG1Z59N6VhmWGUO4nXf9QXA==}
  2 BODY=VC37991   {{"prefix":null,"suffix":null,"full_name":"NEWTON, TINA MARIE","given_names":["TI}
 
*/
 
if (person_demogr_reply->transactionStatus->successInd = 1 and person_demogr_reply->httpReply->status = 200)
  set person_demographics = concat('{"demographics_data":', person_demogr_reply->httpReply->body, '}')
  set stat = cnvtjsontorec(person_demographics)
  
  call echojson(demographics_data)
  go to END_SCRIPT
  
else ;failed executing hi_http_proxy_get_request
  set hi_proxy_error_message = "person_demogr_reply->httpReply->body: "
  set hi_proxy_error_message = concat(hi_proxy_error_message, person_demogr_reply->httpReply->body)
  set hi_proxy_error_message = concat(hi_proxy_error_message, person_demogr_reply->transactionStatus->debugErrorMessage)
 
  call log_message(build2("person_demogr_reply->status: ", person_demogr_reply->httpReply->status), LOG_LEVEL_ERROR)
  call log_message(build2("Debug error message: ", person_demogr_reply->transactionStatus->debugErrorMessage)
    ,LOG_LEVEL_ERROR)
 
  set reply->status_data->subeventstatus[1]->targetObjectName = "ERROR_EXECUTING_HI_HTTP_PROXY_GET_REQUEST"
  set reply->status_data->subeventstatus[1]->targetObjectValue = hi_proxy_error_message
 
  go to END_SCRIPT
endif
 
; Map given names from person data to the reply structure.
if (validate(demographics_data->given_names))
  set given_names_size = size(demographics_data->given_names, 5)
  set stat = alterlist(reply->given_names, given_names_size)
  for (given_names_idx = 1 to given_names_size)
    set reply->given_names[given_names_idx]->given_name =
      demographics_data->given_names[given_names_idx]
  endfor
endif
 
; Map family names from person data to the reply structure.
if (validate(demographics_data->family_names))
  set family_names_size = size(demographics_data->family_names, 5)
  set stat = alterlist(reply->family_names, family_names_size)
  for (family_names_idx = 1 to family_names_size)
    set reply->family_names[family_names_idx]->family_name =
      demographics_data->family_names[family_names_idx]
  endfor
endif
 
if (validate(demographics_data->full_name) and demographics_data->full_name)
  set reply->full_name = demographics_data->full_name
endif
 
if (validate(demographics_data->date_of_birth) and demographics_data->date_of_birth)
  set reply->date_of_birth = demographics_data->date_of_birth
endif
 
; Map gender details from person data to the reply structure for hcm_ens_person_from_hi script.
if (validate(demographics_data->gender) and demographics_data->gender)
 
  if (validate(demographics_data->gender->id) and demographics_data->gender->id)
    set reply->gender_details->id = demographics_data->gender->id
  endif
 
  if (validate(demographics_data->gender->code_system_id) and demographics_data->gender->code_system_id)
    set reply->gender_details->coding_system_id =
      demographics_data->gender->code_system_id
  endif
endif
 
; Map street addresses from person data to the reply structure.
if (validate(demographics_data->address) and demographics_data->address)
 
  if (validate(demographics_data->address->street_addresses))
    set street_addresses_size = size(demographics_data->address->street_addresses, 5)
    set stat = alterlist(reply->
      address->street_addresses, street_addresses_size)
    for (street_addresses_idx = 1 to street_addresses_size)
      set reply->address->
        street_addresses[street_addresses_idx]->street_address =
        demographics_data->address->street_addresses[street_addresses_idx]
    endfor
  endif
 
  ; Map other address information from person data to the reply structure.
  if (validate(demographics_data->address->type) and demographics_data->address->type)
 
    if (validate(demographics_data->address->type->id) and demographics_data->address->type->id)
      set reply->address->type->id = demographics_data->address->type->id
    endif
 
    if (validate(demographics_data->address->type->code_system_id) and demographics_data->address->type->code_system_id)
      set reply->address->type->coding_system_id =
        demographics_data->address->type->code_system_id
    endif
  endif
 
  if (validate(demographics_data->address->city) and demographics_data->address->city)
    set reply->address->city = demographics_data->address->city
  endif
 
  if (validate(demographics_data->address->state_or_province) and demographics_data->address->state_or_province)
 
    if (validate(demographics_data->address->state_or_province->id) and demographics_data->address->state_or_province->id)
      set reply->address->state_or_province_details->id =
        demographics_data->address->state_or_province->id
    endif
 
    if (validate(demographics_data->address->state_or_province->code_system_id)
      and demographics_data->address->state_or_province->code_system_id)
 
      set reply->address->state_or_province_details->coding_system_id =
        demographics_data->address->state_or_province->code_system_id
    endif
  endif
 
  if (validate(demographics_data->address->postal_code) and demographics_data->address->postal_code)
    set reply->address->postal_code = demographics_data->address->postal_code
  endif
 
  if (validate(demographics_data->address->county_or_parish) and demographics_data->address->county_or_parish)
 
    if (validate(demographics_data->address->county_or_parish->display) and demographics_data->address->county_or_parish->display)
      set reply->address->county_or_parish =
        demographics_data->address->county_or_parish->display
    endif
 
    if (validate(demographics_data->address->county_or_parish->id) and demographics_data->address->county_or_parish->id)
      set reply->address->county_or_parish_details->id =
        demographics_data->address->county_or_parish->id
    endif
 
    if (validate(demographics_data->address->county_or_parish->code_system_id)
      and demographics_data->address->county_or_parish->code_system_id)
 
      set reply->address->county_or_parish_details->coding_system_id =
        demographics_data->address->county_or_parish->code_system_id
    endif
  endif
 
  if (validate(demographics_data->address->country) and demographics_data->address->country)
    if (validate(demographics_data->address->country->id) and demographics_data->address->country->id)
      set reply->address->country_details->id =
        demographics_data->address->country->id
    endif
 
    if (validate(demographics_data->address->country->code_system_id) and demographics_data->address->country->code_system_id)
      set reply->address->country_details->coding_system_id =
        demographics_data->address->country->code_system_id
    endif
  endif
endif
 
; Map telecom information from person data to the reply structure.
if (validate(demographics_data->telecoms))
  set telecoms_size = size(demographics_data->telecoms, 5)
  set stat = alterlist(reply->telecoms, telecoms_size)
  for (telecoms_idx = 1 to telecoms_size)
 
    if (validate(demographics_data->telecoms[telecoms_idx]->number) and demographics_data->telecoms[telecoms_idx]->number)
      set reply->telecoms[telecoms_idx]->number =
        demographics_data->telecoms[telecoms_idx]->number
    endif
 
    if (validate(demographics_data->telecoms[telecoms_idx]->type) and demographics_data->telecoms[telecoms_idx]->type)
 
      if (validate(demographics_data->telecoms[telecoms_idx]->type->id) and demographics_data->telecoms[telecoms_idx]->type->id)
        set reply->telecoms[telecoms_idx]->type->id =
          demographics_data->telecoms[telecoms_idx]->type->id
      endif
 
      if (validate(demographics_data->telecoms[telecoms_idx]->type->code_system_id)
        and demographics_data->telecoms[telecoms_idx]->type->code_system_id)
 
        set reply->telecoms[telecoms_idx]->type->coding_system_id =
          demographics_data->telecoms[telecoms_idx]->type->code_system_id
      endif
 
      if (validate(demographics_data->telecoms[telecoms_idx]->preferred))
        if (demographics_data->telecoms[telecoms_idx]->preferred = 1)
          set reply->telecoms[telecoms_idx]->preferred = "true"
        else
          set reply->telecoms[telecoms_idx]->preferred = "false"
        endif
      endif
 
      if (validate(demographics_data->telecoms[telecoms_idx]->country_code)
      and demographics_data->telecoms[telecoms_idx]->country_code)
        set reply->telecoms[telecoms_idx]->country_code =
          demographics_data->telecoms[telecoms_idx]->country_code
      endif
    endif
  endfor
endif
 
; Map email addresses from person data to the reply structure.
if (validate(demographics_data->emails))
  set email_addresses_size = size(demographics_data->emails, 5)
  set stat = alterlist(reply->email_addresses, email_addresses_size)
  for (email_addresses_idx = 1 to email_addresses_size)
 
    if (validate(demographics_data->emails[email_addresses_idx]->address)
 
    and demographics_data->emails[email_addresses_idx]->address)
      set reply->email_addresses[email_addresses_idx]->address =
        demographics_data->emails[email_addresses_idx]->address
    endif
 
    if (validate(demographics_data->emails[email_addresses_idx]->type) and demographics_data->emails[email_addresses_idx]->type)
 
      if (validate(demographics_data->emails[email_addresses_idx]->type->id)
      and demographics_data->emails[email_addresses_idx]->type->id)
        set reply->email_addresses[email_addresses_idx]->type->id =
          demographics_data->emails[email_addresses_idx]->type->id
      endif
 
      if (validate(demographics_data->emails[email_addresses_idx]->type->code_system_id)
        and demographics_data->emails[email_addresses_idx]->type->code_system_id)
        set reply->
          email_addresses[email_addresses_idx]->type->coding_system_id =
          demographics_data->emails[email_addresses_idx]->type->code_system_id
      endif
    endif
  endfor
endif
 
if (validate(demographics_data->benefit_coverages))
  set benefit_coverages_size = size(demographics_data->benefit_coverages, 5)
  set stat = alterlist(reply->health_plans, benefit_coverages_size)
 
  for (bc_idx = 1 to benefit_coverages_size)
    ; payer_name
    if (validate(demographics_data->benefit_coverages[bc_idx]->payer_name)
      and demographics_data->benefit_coverages[bc_idx]->payer_name)
 
      set reply->health_plans[bc_idx]->payer_name = demographics_data->benefit_coverages[bc_idx]->payer_name
    endif
 
    ; plan_name
    if (validate(demographics_data->benefit_coverages[bc_idx]->plan_name)
      and demographics_data->benefit_coverages[bc_idx]->plan_name)
 
      set reply->health_plans[bc_idx]->plan_name = demographics_data->benefit_coverages[bc_idx]->plan_name
    endif
 
    ; begin_iso_dt_tm
    if (validate(demographics_data->benefit_coverages[bc_idx]->begin_date)
      and demographics_data->benefit_coverages[bc_idx]->begin_date)
 
      set reply->health_plans[bc_idx]->begin_iso_dt_tm =
        ConvertStrDateToIsoFormat(demographics_data->benefit_coverages[bc_idx]->begin_date)
    endif
 
    ; end_iso_dt_tm
    if (validate(demographics_data->benefit_coverages[bc_idx]->end_date)
      and demographics_data->benefit_coverages[bc_idx]->end_date)
 
      set reply->health_plans[bc_idx]->end_iso_dt_tm =
        ConvertStrDateToIsoFormat(demographics_data->benefit_coverages[bc_idx]->end_date)
    endif
 
    ; member_nbr
    if (validate(demographics_data->benefit_coverages[bc_idx]->member_id)
      and demographics_data->benefit_coverages[bc_idx]->member_id)
 
      set reply->health_plans[bc_idx]->member_nbr = demographics_data->benefit_coverages[bc_idx]->member_id
    endif
 
    ; line_of_business
    if (validate(demographics_data->benefit_coverages[bc_idx]->line_of_business)
      and demographics_data->benefit_coverages[bc_idx]->line_of_business)
 
      set reply->health_plans[bc_idx]->line_of_business = demographics_data->benefit_coverages[bc_idx]->line_of_business
    endif
 
    ; source
    if (validate(demographics_data->benefit_coverages[bc_idx]->source)
      and demographics_data->benefit_coverages[bc_idx]->source)
 
      if (demographics_data->benefit_coverages[bc_idx]->source->contributing_organization)
        set reply->health_plans[bc_idx]->source->contributing_organization =
          demographics_data->benefit_coverages[bc_idx]->source->contributing_organization
      endif
 
      if (demographics_data->benefit_coverages[bc_idx]->source->partition_description)
        set reply->health_plans[bc_idx]->source->partition_description =
          demographics_data->benefit_coverages[bc_idx]->source->partition_description
      endif
 
      if (demographics_data->benefit_coverages[bc_idx]->source->type)
        set reply->health_plans[bc_idx]->source->type =
          demographics_data->benefit_coverages[bc_idx]->source->type
      endif
    endif
 
    ; plan_id array
    set plan_cnt = size(demographics_data->benefit_coverages[bc_idx]->plan_ids, 5)
 
    set stat = alterlist(reply->health_plans[bc_idx]->plan_identifiers, plan_cnt)
 
    for (plan_idx = 1 to plan_cnt)
      if ((validate(demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->value)
        and demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->value)
        and (validate(demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->type)
        and demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->type))
 
        set plan_value = demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->value
        set plan_type = demographics_data->benefit_coverages[bc_idx]->plan_ids[plan_idx]->type
 
        set reply->health_plans[bc_idx]->plan_identifiers[plan_idx]->value = plan_value
        set reply->health_plans[bc_idx]->plan_identifiers[plan_idx]->type = plan_type
      endif
    endfor
  endfor
endif ; end (validate(demographics_data->benefit_coverages))
 
set reply->status_data->status = "S"
 
/*
 * Converts a string date format to ISO datetime format.
 *
 * Example:
 *   ConvertStrDateToIsoFormat("2015-05-05")
 *     => "2015-05-05T05:00:00Z"
 */
subroutine ConvertStrDateToIsoFormat(date)
  declare cnvt_date = vc with protect
 
  set cnvt_date = cnvtDQ8ToIsoDtTm(cnvtdatetime(cnvtdate2(date,"YYYY-MM-DD"), 0))
  return (cnvt_date)
end
 
#END_SCRIPT
 
if (validate(debug_ind, 0) = 1)
  call echorecord(reply)
endif
 
set last_mod = "001"
set mod_date = "January 31, 2017"
 
end
go