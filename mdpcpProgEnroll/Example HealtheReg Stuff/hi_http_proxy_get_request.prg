DROP PROGRAM hi_http_proxy_get_request:dba GO
CREATE PROGRAM hi_http_proxy_get_request:dba
 PROMPT
  "Output to File/Printer/MINE: " = "MINE",
  "HTTP_ENDPOINT (KEY or URI): " = "",
  "DATATYPE (XML, JSON, or RECORD): " = "JSON",
  "PAT_PERSON_ID (OPTIONAL): " = 0.0,
  "USR_PERSON_ID (OPTIONAL): " = 0.0,
  "TEMPLATE_VARIABLES (OPTIONAL): " = ""
  WITH output_type, http_endpoint, datatype,
  pat_person_id, usr_person_id, template_variables
 DECLARE cloud_proxy_server = i4 WITH protect, constant(99999950)
 DECLARE cloud_discovery_uri = i4 WITH protect, constant(99999951)
 DECLARE freesrvhandle(srvhandle=i4) = null
 SUBROUTINE freesrvhandle(srvhandle)
   IF (srvhandle > 0)
    CALL uar_srvdestroyinstance(srvhandle)
   ENDIF
 END ;Subroutine
 FREE RECORD proxyreply
 RECORD proxyreply(
   1 transactionstatus
     2 successind = ui1
     2 debugerrormessage = vc
     2 prereqerrorind = ui1
   1 httpreply
     2 version = vc
     2 status = ui2
     2 statusreason = vc
     2 httpheaders[*]
       3 name = vc
       3 value = vc
     2 body = gvc
 ) WITH persistscript
 DECLARE executehttpproxy(inputparams=vc(ref)) = i1
 SUBROUTINE executehttpproxy(inputparams)
   DECLARE stat = i4 WITH protect, noconstant(0)
   SET httpproxymsg = uar_srvselectmessage(cloud_proxy_server)
   SET httpproxyrequest = uar_srvcreaterequest(httpproxymsg)
   SET httpproxyreply = uar_srvcreatereply(httpproxymsg)
   SET httpendpoint = uar_srvgetstruct(httpproxyrequest,"httpEndpoint")
   SET stat = uar_srvsetstringfixed(httpendpoint,"endpoint",inputparams->httpendpoint.endpoint,size(
     inputparams->endpoint))
   FOR (templateindex = 1 TO size(inputparams->httpendpoint.templatevariables,5))
     SET newindex = uar_srvadditem(httpendpoint,"templateVariables")
     SET stat = uar_srvsetstringfixed(newindex,"name",inputparams->httpendpoint.templatevariables[
      templateindex].name,size(inputparams->httpendpoint.templatevariables[templateindex].name))
     SET stat = uar_srvsetstringfixed(newindex,"value",inputparams->httpendpoint.templatevariables[
      templateindex].value,size(inputparams->httpendpoint.templatevariables[templateindex].value))
   ENDFOR
   SET userdata = uar_srvgetstruct(httpproxyrequest,"userData")
   SET stat = uar_srvsetshort(userdata,"asSystemUser",inputparams->userdata.assystemuser)
   SET stat = uar_srvsetlong(userdata,"logicalDomainId",inputparams->userdata.logicaldomainid)
   SET httprequest = uar_srvgetstruct(httpproxyrequest,"httpRequest")
   SET stat = uar_srvsetstringfixed(httprequest,"httpMethod",inputparams->httprequest.httpmethod,size
    (inputparams->httprequest.httpmethod))
   FOR (headerindex = 1 TO size(inputparams->httprequest.httpheaders,5))
     SET newindex = uar_srvadditem(httprequest,"httpHeaders")
     SET stat = uar_srvsetstringfixed(newindex,"name",inputparams->httprequest.httpheaders[
      headerindex].name,size(inputparams->httprequest.httpheaders[headerindex].name))
     SET stat = uar_srvsetstringfixed(newindex,"value",inputparams->httprequest.httpheaders[
      headerindex].value,size(inputparams->httprequest.httpheaders[headerindex].value))
   ENDFOR
   IF (size(inputparams->httprequest.body) > 0)
    SET stat = uar_srvsetasis(httprequest,"body",inputparams->httprequest.body,size(inputparams->
      httprequest.body))
   ENDIF
   DECLARE executed = i4 WITH private, constant(uar_srvexecute(httpproxymsg,httpproxyrequest,
     httpproxyreply))
   IF (executed != 0)
    CALL freesrvhandle(httpproxyrequest)
    CALL freesrvhandle(httpproxyreply)
    RETURN(0)
   ENDIF
   SET transactionstatus = uar_srvgetstruct(httpproxyreply,"transactionStatus")
   SET proxyreply->transactionstatus.successind = uar_srvgetshort(transactionstatus,"success_ind")
   SET proxyreply->transactionstatus.debugerrormessage = uar_srvgetstringptr(transactionstatus,
    "debug_error_message")
   SET httpreply = uar_srvgetstruct(httpproxyreply,"httpReply")
   SET proxyreply->httpreply.version = uar_srvgetstringptr(httpreply,"version")
   SET proxyreply->httpreply.status = uar_srvgetushort(httpreply,"status")
   SET proxyreply->httpreply.statusreason = uar_srvgetstringptr(httpreply,"statusReason")
   SET bodysize = uar_srvgetasissize(httpreply,"body")
   IF (bodysize > 0)
    SET temp = ""
    SET stat = memrealloc(temp,1,build("C",bodysize))
    SET temp = notrim(uar_srvgetasisptr(httpreply,"body"))
    SET proxyreply->httpreply.body = temp
   ENDIF
   SET itemcount = uar_srvgetitemcount(httpreply,"httpHeaders")
   SET stat = alterlist(proxyreply->httpreply.httpheaders,itemcount)
   FOR (headerindex = 1 TO itemcount)
     SET item = uar_srvgetitem(httpreply,"httpHeaders",(headerindex - 1))
     SET proxyreply->httpreply.httpheaders[headerindex].name = uar_srvgetstringptr(item,"name")
     SET proxyreply->httpreply.httpheaders[headerindex].value = uar_srvgetstringptr(item,"value")
   ENDFOR
   CALL freesrvhandle(httpproxyrequest)
   CALL freesrvhandle(httpproxyreply)
   RETURN(1)
 END ;Subroutine
 DECLARE executeuridiscovery(inputparams=vc(ref),uridiscoveryreply=vc(ref)) = i1
 SUBROUTINE executeuridiscovery(inputparams,uridiscoveryreply)
   DECLARE stat = i4 WITH protect, noconstant(0)
   SET discoverymsg = uar_srvselectmessage(cloud_discovery_uri)
   SET discoveryrequest = uar_srvcreaterequest(discoverymsg)
   SET discoveryreply = uar_srvcreatereply(discoverymsg)
   SET userdata = uar_srvgetstruct(discoveryrequest,"userData")
   SET stat = uar_srvsetshort(userdata,"asSystemUser",inputparams->userdata.assystemuser)
   SET stat = uar_srvsetlong(userdata,"logicalDomainId",inputparams->userdata.logicaldomainid)
   FOR (endpointindex = 1 TO size(inputparams->endpoints,5))
     SET endpoint = uar_srvadditem(discoveryrequest,"endpoints")
     SET stat = uar_srvsetstringfixed(endpoint,"endpoint",inputparams->endpoints[endpointindex].
      endpoint,size(inputparams->endpoints[endpointindex].endpoint))
     FOR (templateindex = 1 TO size(inputparams->endpoints[endpointindex].templatevariables,5))
       SET template = uar_srvadditem(endpoint,"templateVariables")
       SET stat = uar_srvsetstringfixed(template,"name",inputparams->endpoints[endpointindex].
        templatevariables[templateindex].name,size(inputparams->endpoints[endpointindex].
         templatevariables[templateindex].name))
       SET stat = uar_srvsetstringfixed(template,"value",inputparams->endpoints[endpointindex].
        templatevariables[templateindex].value,size(inputparams->endpoints[endpointindex].
         templatevariables[templateindex].value))
     ENDFOR
   ENDFOR
   DECLARE executed = i4 WITH private, constant(uar_srvexecute(discoverymsg,discoveryrequest,
     discoveryreply))
   IF (executed != 0)
    CALL freesrvhandle(discoveryrequest)
    CALL freesrvhandle(discoveryreply)
    RETURN(0)
   ENDIF
   SET transactionstatus = uar_srvgetstruct(discoveryreply,"transactionStatus")
   SET uridiscoveryreply->transactionstatus.successind = uar_srvgetshort(transactionstatus,
    "success_ind")
   SET uridiscoveryreply->transactionstatus.debugerrormessage = uar_srvgetstringptr(transactionstatus,
    "debug_error_message")
   SET endpointcount = uar_srvgetitemcount(discoveryreply,"uriEndpoints")
   SET stat = alterlist(uridiscoveryreply->uriendpoints,endpointcount)
   FOR (endpointindex = 1 TO endpointcount)
     SET endpoint = uar_srvgetitem(discoveryreply,"uriEndpoints",(endpointindex - 1))
     SET uridiscoveryreply->uriendpoints[endpointindex].successind = uar_srvgetshort(endpoint,
      "success_ind")
     SET uridiscoveryreply->uriendpoints[endpointindex].debugerrormessage = uar_srvgetstringptr(
      endpoint,"debug_error_message")
     SET uridiscoveryreply->uriendpoints[endpointindex].endpoint = uar_srvgetstringptr(endpoint,
      "endpoint")
     SET uridiscoveryreply->uriendpoints[endpointindex].uri = uar_srvgetstringptr(endpoint,"uri")
   ENDFOR
   CALL freesrvhandle(discoveryrequest)
   CALL freesrvhandle(discoveryreply)
   RETURN(1)
 END ;Subroutine
 FREE RECORD proxyserviceparams
 RECORD proxyserviceparams(
   1 httpendpoint
     2 endpoint = vc
     2 templatevariables[*]
       3 name = vc
       3 value = vc
   1 userdata
     2 assystemuser = i1
     2 logicaldomainid = i4
   1 httprequest
     2 httpmethod = vc
     2 httpheaders[*]
       3 name = vc
       3 value = vc
     2 body = gvc
 )
 DECLARE callproxy(proxyvalues=vc(ref)) = null
 SUBROUTINE callproxy(proxyvalues)
   DECLARE language = vc WITH protect, noconstant(" ")
   SET proxyreply->transactionstatus.successind = 0
   IF (trim(proxyvalues->endpoint)="")
    SET proxyreply->transactionstatus.debugerrormessage = "Http endpoint not defined"
    RETURN
   ENDIF
   IF (trim(proxyvalues->method)="")
    SET proxyreply->transactionstatus.debugerrormessage = "Http method not defined"
    RETURN
   ENDIF
   SET proxyserviceparams->httpendpoint.endpoint = proxyvalues->endpoint
   SET proxyserviceparams->httprequest.httpmethod = proxyvalues->method
   SET proxyserviceparams->userdata.assystemuser = 0
   SET stat = alterlist(proxyserviceparams->httprequest.httpheaders,1)
   IF ((((proxyvalues->datatype="JSON")) OR ((proxyvalues->datatype="RECORD"))) )
    SET proxyserviceparams->httprequest.httpheaders[1].name = "Accept"
    SET proxyserviceparams->httprequest.httpheaders[1].value = "application/json"
   ELSEIF ((proxyvalues->datatype="XML"))
    SET proxyserviceparams->httprequest.httpheaders[1].name = "Accept"
    SET proxyserviceparams->httprequest.httpheaders[1].value = "application/xml"
   ELSE
    SET proxyreply->transactionstatus.debugerrormessage = "Unsupported datatype for request"
    RETURN
   ENDIF
   SET language = logical("lang")
   IF (language > " ")
    SET stat = alterlist(proxyserviceparams->httprequest.httpheaders,2)
    SET proxyserviceparams->httprequest.httpheaders[2].name = "Accept-Language"
    SET proxyserviceparams->httprequest.httpheaders[2].value = language
   ENDIF
   IF ((proxyvalues->patientid > 0.0))
    SET stat = alterlist(proxyserviceparams->templatevariables,1)
    SET proxyserviceparams->templatevariables[1].name = "data_partition_person_id"
    SET proxyserviceparams->templatevariables[1].value = cnvtstring( $PAT_PERSON_ID,0)
   ENDIF
   IF ((proxyvalues->userid > 0.0))
    SET stat = alterlist(proxyserviceparams->templatevariables,2)
    SET proxyserviceparams->templatevariables[2].name = "hi_personnel_user_alias"
    SET proxyserviceparams->templatevariables[2].value = cnvtstring( $USR_PERSON_ID,0)
   ENDIF
   IF ((proxyvalues->templatevariables != ""))
    DECLARE templatenamevalue = vc WITH noconstant("")
    DECLARE num = i4 WITH noconstant(1)
    DECLARE notfnd = vc WITH constant("<not_found>")
    DECLARE templatename = vc WITH noconstant("")
    DECLARE templatevalue = vc WITH noconstant("")
    DECLARE convertedvalue = vc WITH noconstant("")
    DECLARE decimalvalue = vc WITH noconstant("")
    WHILE (templatenamevalue != notfnd)
      SET templatenamevalue = trim(piece( $TEMPLATE_VARIABLES,";",num,notfnd),3)
      IF (templatenamevalue != notfnd)
       SET templatename = trim(piece(templatenamevalue,"=",1,notfnd),3)
       SET templatevalue = trim(piece(templatenamevalue,"=",2,notfnd),3)
       IF (templatename != notfnd
        AND templatevalue != notfnd)
        SET sizeoftemplatevariables = (size(proxyserviceparams->templatevariables,5)+ 1)
        SET stat = alterlist(proxyserviceparams->templatevariables,sizeoftemplatevariables)
        SET proxyserviceparams->templatevariables[sizeoftemplatevariables].name = templatename
        IF (isnumeric(templatevalue) != 0)
         SET precision = size(trim(piece(templatevalue,".",2,""),3))
         SET convertedvalue = cnvtstring(templatevalue,value(size(templatevalue)),value(precision))
         SET proxyserviceparams->templatevariables[sizeoftemplatevariables].value = convertedvalue
        ELSE
         SET proxyserviceparams->templatevariables[sizeoftemplatevariables].value = templatevalue
        ENDIF
       ENDIF
      ENDIF
      SET num = (num+ 1)
    ENDWHILE
   ENDIF
   IF ((proxyvalues->body != ""))
    SET stat = alterlist(proxyserviceparams->httprequest.httpheaders,(size(proxyserviceparams->
      httprequest.httpheaders,5)+ 1))
    SET headerindex = size(proxyserviceparams->httprequest.httpheaders,5)
    SET proxyserviceparams->httprequest.httpheaders[headerindex].name = "Content-Type"
    SET proxyserviceparams->httprequest.httpheaders[headerindex].value = proxyvalues->contenttype
    SET proxyserviceparams->httprequest.body = proxyvalues->body
   ENDIF
   SET stat = executehttpproxy(proxyserviceparams)
   IF (stat=0)
    SET proxyreply->transactionstatus.debugerrormessage =
    "An error occurred attempting to access the Http Proxy Service"
   ENDIF
 END ;Subroutine
 FREE RECORD getproxyvalues
 RECORD getproxyvalues(
   1 endpoint = vc
   1 method = vc
   1 datatype = vc
   1 patientid = f8
   1 userid = f8
   1 templatevariables = vc
   1 body = gvc
   1 contenttype = vc
 )
 SET getproxyvalues->endpoint =  $HTTP_ENDPOINT
 SET getproxyvalues->method = "GET"
 SET getproxyvalues->datatype =  $DATATYPE
 SET getproxyvalues->patientid =  $PAT_PERSON_ID
 SET getproxyvalues->userid =  $USR_PERSON_ID
 SET getproxyvalues->templatevariables =  $TEMPLATE_VARIABLES
 CALL callproxy(getproxyvalues)
 IF (( $DATATYPE="JSON"))
  SET _memory_reply_string = cnvtrectojson(proxyreply)
 ELSEIF (( $DATATYPE="XML"))
  SET _memory_reply_string = cnvtrectoxml(proxyreply)
 ELSEIF (( $DATATYPE="RECORD"))
  FREE RECORD memoryproxyreply
  RECORD memoryproxyreply(
    1 transactionstatus
      2 successind = ui1
      2 debugerrormessage = vc
      2 prereqerrorind = ui1
    1 httpreply
      2 version = vc
      2 status = ui2
      2 statusreason = vc
      2 httpheaders[*]
        3 name = vc
        3 value = vc
      2 body = gvc
  ) WITH persistscript
  SET stat = moverec(proxyreply,memoryproxyreply)
 ENDIF
END GO
