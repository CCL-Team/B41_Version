DROP PROGRAM hi_alias_lookup:dba GO
CREATE PROGRAM hi_alias_lookup:dba
PROMPT
    "Output to File/Printer/MINE" = "MINE",
    "LOOKUP_KEY: " = "",
    "REQUEST_KEY: " = "",
    "PAT_PERSON_ID: " = 0.0,
    "ALIAS_TYPE: " = "",
    "ALIAS_POOL_CD: " = 0.0,
    "PAT_ENCNTR_ID: " = 0.0,
    "TEMPLATE_VARIABLES (OPTIONAL): " = ""
WITH outdev, lookup_key, request_key,
pat_person_id, alias_type, alias_pool_cd,
pat_encntr_id, template_variables

RECORD aliaslookupreply(
    1 transactionstatus
        2 successind = i1
        2 debugerrormessage = vc
    1 hiuri = vc
    1 errorindicator = i1
    1 status_data
        2 status = c1
        2 subeventstatus[1]
            3 operationname = c25
            3 operationstatus = c1
            3 targetobjectname = c25
            3 targetobjectvalue = vc
) WITH persistscript

SET aliaslookupreply->status_data.status = "F"
SET aliaslookupreply->errorindicator = 1

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

DECLARE addsubeventstatus(replyrecord=vc(ref),operationname=vc,operationstatus=c1,targetobjectname=
vc,targetobjectvalue=vc) = null WITH protect
SUBROUTINE addsubeventstatus(replyrecord,operationname,operationstatus,targetobjectname,
targetobjectvalue)
    DECLARE stataddsubevent = i4 WITH private, noconstant(0)
    DECLARE subeventstatussize = i4 WITH private, noconstant(size(replyrecord->status_data.
    subeventstatus,5))
    IF (((size(trim(replyrecord->status_data.subeventstatus[subeventstatussize].operationname),1) > 0)
        OR (((size(trim(replyrecord->status_data.subeventstatus[subeventstatussize].operationstatus),1)
        > 0) OR (((size(trim(replyrecord->status_data.subeventstatus[subeventstatussize].targetobjectname
        ),1) > 0) OR (size(trim(replyrecord->status_data.subeventstatus[subeventstatussize].
        targetobjectvalue),1) > 0)) )) )) )

        SET subeventstatussize = (subeventstatussize+ 1)
        SET stataddsubevent = alter(replyrecord->status_data.subeventstatus,subeventstatussize)
    ENDIF

    SET replyrecord->status_data.subeventstatus[subeventstatussize].operationname = substring(0,25,
    operationname)
    SET replyrecord->status_data.subeventstatus[subeventstatussize].operationstatus = operationstatus
    SET replyrecord->status_data.subeventstatus[subeventstatussize].targetobjectname = substring(0,25,
    targetobjectname)
    SET replyrecord->status_data.subeventstatus[subeventstatussize].targetobjectvalue =
    targetobjectvalue
END ;Subroutine

DECLARE getencounteralias(alias_type=vc,alias_pool_cd=f8,encntr_id=f8) = vc
SUBROUTINE getencounteralias(alias_type,alias_pool_cd,encntr_id)
    DECLARE enc_alias = vc WITH noconstant("")
    DECLARE aliascount = i4
    IF (encntr_id <= 0.0)
        RETURN(enc_alias)
    ENDIF

    DECLARE alias_type_cd = f8 WITH noconstant(uar_get_code_by("MEANING",319,nullterm(alias_type)))
    
    SELECT INTO "nl:"
        ea.encntr_id, ea.alias
    FROM encntr_alias ea
    WHERE ea.encntr_id=encntr_id
    AND ea.encntr_alias_type_cd=alias_type_cd
    AND ea.alias_pool_cd=alias_pool_cd
    AND ea.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
    AND ea.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
    AND ea.active_ind=1
    DETAIL
        enc_alias = ea.alias, aliascount = (aliascount+ 1)
    WITH nocounter
    ;end select

    IF (aliascount > 1)
        RETURN("MULTIPLE QUALIFIED")
    ENDIF
    RETURN(enc_alias)
END ;Subroutine

DECLARE getpersonalias(alias_type=vc,alias_pool_cd=f8,person_id=f8) = vc
SUBROUTINE getpersonalias(alias_type,alias_pool_cd,person_id)
    DECLARE prsn_alias = vc WITH noconstant("")
    DECLARE aliascount = i4
    IF (person_id <= 0.0)
        RETURN(prsn_alias)
    ENDIF
    DECLARE alias_type_cd = f8 WITH noconstant(uar_get_code_by("MEANING",4,nullterm(alias_type)))

    SELECT INTO "nl:"
        pa.person_id, pa.alias
    FROM person_alias pa
    WHERE pa.person_id=person_id
    AND pa.person_alias_type_cd=alias_type_cd
    AND pa.alias_pool_cd=alias_pool_cd
    AND pa.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
    AND pa.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
    AND pa.active_ind=1
    DETAIL
        aliascount = (aliascount+ 1), prsn_alias = pa.alias
    WITH nocounter
    ;end select

    IF (aliascount > 1)
        RETURN("MULTIPLE QUALIFIED")
    ENDIF
    RETURN(prsn_alias)
END ;Subroutine

FREE RECORD aliasdiscoveryrequest
RECORD aliasdiscoveryrequest(
    1 userdata
        2 assystemuser = i1
        2 logicaldomainid = i4
    1 endpoints[*]
        2 endpoint = vc
        2 templatevariables[*]
            3 name = vc
            3 value = vc
) WITH protect

FREE RECORD uridiscoveryreply
RECORD uridiscoveryreply(
    1 transactionstatus
        2 successind = i1
        2 debugerrormessage = vc
    1 uriendpoints[*]
        2 successind = i1
        2 debugerrormessage = vc
        2 endpoint = vc
        2 uri = vc
) WITH protect

DECLARE requesturi(urikey=vc,fieldvalues=vc(ref),templatevariables=vc) = vc
SUBROUTINE requesturi(urikey,fieldvalues,templatevariables)
    DECLARE fieldcount = i4 WITH protect, noconstant(0)
    DECLARE uri = vc WITH protect, noconstant("")
    SET aliasdiscoveryrequest->userdata.assystemuser = 0
    SET stat = alterlist(aliasdiscoveryrequest->endpoints,1)
    SET curalias endpoints aliasdiscoveryrequest->endpoints[1]
    SET stat = alterlist(endpoints->templatevariables,1)
    SET endpoints->endpoint = urikey
    SET fieldcount = size(fieldvalues->fields,5)
    SET stat = alterlist(endpoints->templatevariables,fieldcount)
    FOR (index = 1 TO fieldcount)
        SET endpoints->templatevariables[index].name = fieldvalues->fields[index].field_name
        SET endpoints->templatevariables[index].value = fieldvalues->fields[index].field_value
    ENDFOR

    IF (templatevariables != "")
        DECLARE stat = i4 WITH noconstant(0)
        DECLARE templatenamevalue = vc WITH noconstant("")
        DECLARE num = i4 WITH noconstant(1)
        DECLARE notfnd = vc WITH constant("<not_found>")
        DECLARE templatename = vc WITH noconstant("")
        DECLARE templatevalue = vc WITH noconstant("")
        DECLARE convertedvalue = vc WITH noconstant("")
        DECLARE decimalvalue = vc WITH noconstant("")
        WHILE (templatenamevalue != notfnd)
            SET templatenamevalue = trim(piece(templatevariables,";",num,notfnd),3)
            IF (templatenamevalue != notfnd)
                SET templatename = trim(piece(templatenamevalue,"=",1,notfnd),3)
                SET templatevalue = trim(piece(templatenamevalue,"=",2,notfnd),3)
                IF (templatename != notfnd
                    AND templatevalue != notfnd)
                    SET sizeoftemplatevariables = (size(aliasdiscoveryrequest->endpoints[1].templatevariables,5)
                        + 1)
                    SET stat = alterlist(aliasdiscoveryrequest->endpoints[1].templatevariables,
                    sizeoftemplatevariables)
                    SET aliasdiscoveryrequest->endpoints[1].templatevariables[sizeoftemplatevariables].name =
                    templatename
                    IF (isnumeric(templatevalue) != 0)
                        SET precision = size(trim(piece(templatevalue,".",2,""),3))
                        SET convertedvalue = cnvtstring(templatevalue,value(size(templatevalue)),value(precision))
                        SET aliasdiscoveryrequest->endpoints[1].templatevariables[sizeoftemplatevariables].value =
                        convertedvalue
                    ELSE
                        SET aliasdiscoveryrequest->endpoints[1].templatevariables[sizeoftemplatevariables].value =
                        templatevalue
                    ENDIF
                ENDIF
            ENDIF
            SET num = (num+ 1)
        ENDWHILE
    ENDIF
    SET curalias endpoints off
    SET stat = executeuridiscovery(aliasdiscoveryrequest,uridiscoveryreply)
    IF (stat=0)
        SET aliaslookupreply->transactionstatus.successind = 0
        SET aliaslookupreply->transactionstatus.debugerrormessage =
        "Could not connect to http proxy service."
        CALL addsubeventstatus(aliaslookupreply,"getHealtheIntentURI","F","HI-ERROR-106",build2(
        "The HealtheIntent uri could not be built due to connection errors with the proxy.",""))
        RETURN("")
    ENDIF
    IF ((uridiscoveryreply->transactionstatus.successind != 1))
        SET aliaslookupreply->transactionstatus.successind = uridiscoveryreply->transactionstatus.
        successind
        SET aliaslookupreply->transactionstatus.debugerrormessage = uridiscoveryreply->transactionstatus.
        debugerrormessage
        CALL addsubeventstatus(aliaslookupreply,"getHealtheIntentURI","F","HI-ERROR-104",build2(
        "The HealtheIntent uri could not be built due to a service proxy error.",""))
        RETURN("")
    ENDIF

    IF ((uridiscoveryreply->uriendpoints[1].successind != 1))
        SET aliaslookupreply->transactionstatus.successind = uridiscoveryreply->transactionstatus.
        successind
        SET aliaslookupreply->transactionstatus.debugerrormessage = uridiscoveryreply->transactionstatus.
        debugerrormessage
        CALL addsubeventstatus(aliaslookupreply,"getHealtheIntentURI","F","HI-ERROR-102",build2(
        "The HealtheIntent uri could not be built due to unregistered endpoints.",""))
        RETURN("")
    ENDIF
    SET uri = uridiscoveryreply->uriendpoints[1].uri
    RETURN(uri)
END ;Subroutine

IF (((trim( $LOOKUP_KEY)="") OR (((trim( $REQUEST_KEY)="") OR (((( $PAT_PERSON_ID <= 0.0)
    AND ( $PAT_ENCNTR_ID <= 0.0)) OR (((trim( $ALIAS_TYPE) != ""
    AND ( $ALIAS_POOL_CD <= 0.0)) OR (trim( $ALIAS_TYPE)=""
    AND  ( $ALIAS_POOL_CD > 0.0))) )) )) )) )
    CALL addsubeventstatus(aliaslookupreply,"getHealtheIntentURI","F","HI-ALIAS-ERROR-100",
    "Missing configuration for looking up alias.")
    GO TO exit_script
ENDIF

DECLARE alias = vc WITH protect, noconstant("")
DECLARE requestbody = vc WITH protect, noconstant("")
DECLARE stat = i4 WITH noconstant(0)
IF (trim( $ALIAS_TYPE) != ""
    AND ( $ALIAS_POOL_CD > 0.0))
    IF (( $PAT_ENCNTR_ID > 0.0))
        SET alias = getencounteralias( $ALIAS_TYPE, $ALIAS_POOL_CD, $PAT_ENCNTR_ID)
        IF (alias="")
            SET alias = getpersonalias( $ALIAS_TYPE, $ALIAS_POOL_CD, $PAT_PERSON_ID)
        ENDIF
    ELSE
        SET alias = getpersonalias( $ALIAS_TYPE, $ALIAS_POOL_CD, $PAT_PERSON_ID)
    ENDIF
ELSEIF (( $PAT_PERSON_ID > 0.0))
    SET alias = cnvtstring( $PAT_PERSON_ID,value(size( $PAT_PERSON_ID)))
ELSE
    CALL addsubeventstatus(aliaslookupreply,"getHealtheIntentURI","F","HI-ALIAS-ERROR-103",
    "Could not determine alias which should be sent to lookup.")
    GO TO exit_script
ENDIF

IF (alias="MULTIPLE_QUALIFIED")
    CALL addsubeventstatus(aliaslookupreply,"getHealtheIntentURI","F","HI-ALIAS-ERROR-104",
    "Multiple aliases of the given type found.")
    GO TO exit_script
ENDIF

IF (trim(alias) != "")
    SET requestbody = build('{"id":"',alias,'"}')
    EXECUTE hi_http_proxy_post_request value( $OUTDEV), value( $LOOKUP_KEY), "RECORD",
    value( $PAT_PERSON_ID), value(0.0), value(requestbody)
    IF ((memoryproxyreply->transactionstatus.successind=1))
        IF ((memoryproxyreply->httpreply.status=200))
            SET aliaslookupreply->errorindicator = 0
            SET stat = cnvtjsontorec(memoryproxyreply->httpreply.body)
            SET requesturi = requesturi( $REQUEST_KEY,response, $TEMPLATE_VARIABLES)
            IF (trim(requesturi) != "")
                SET aliaslookupreply->hiuri = requesturi
                SET aliaslookupreply->status_data.status = "S"
            ENDIF
        ELSE
            DECLARE locationurl = vc WITH noconstant("")
            IF (size(memoryproxyreply->httpreply.httpheaders,5) > 0)
                FOR (templateindex = 1 TO size(memoryproxyreply->httpreply.httpheaders,5))
                    IF ((memoryproxyreply->httpreply.httpheaders[templateindex].name="Location")
                        AND trim(memoryproxyreply->httpreply.httpheaders[templateindex].value) != "")
                        SET locationurl = trim(memoryproxyreply->httpreply.httpheaders[templateindex].value)
                    ENDIF
                ENDFOR
            ENDIF
            IF (locationurl != "")
                SET aliaslookupreply->hiuri = locationurl
                SET aliaslookupreply->status_data.status = "P"
            ELSE
                CALL addsubeventstatus(aliaslookupreply,"getHealtheIntentURI","F","HI-ALIAS-ERROR-105",
                "EMPI lookup did not succeed, and no error Location was provided.")
            ENDIF
        ENDIF
    ELSE
        SET aliaslookupreply->transactionstatus.successind = memoryproxyreply->transactionstatus.
        successind
        SET aliaslookupreply->transactionstatus.debugerrormessage = memoryproxyreply->transactionstatus.
        debugerrormessage
        CALL addsubeventstatus(aliaslookupreply,"getHealtheIntentURI","F","HI-ALIAS-ERROR-101",build2(
        "Alias lookup service call failed.",""))
    ENDIF
ELSE
    CALL addsubeventstatus(aliaslookupreply,"getHealtheIntentURI","F","HI-ALIAS-ERROR-102",build2(
    "No alias with the provided type ", $ALIAS_TYPE," was found in alias pool ", $ALIAS_POOL_CD))
ENDIF

#exit_script
END GO
