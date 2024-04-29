drop program mmmtestAPICall go
create program mmmtestAPICall

PROMPT
      "Output to File/Printer/MINE"     = "MINE"
    ;, "LOOKUP_KEY: "                    = ""
    ;, "REQUEST_KEY: "                   = ""
    , "PAT_PERSON_ID: "                 = 0.0
    ;, "ALIAS_TYPE: "                    = ""
    ;, "ALIAS_POOL_CD: "                 = 0.0
    ;, "PAT_ENCNTR_ID: "                 = 0.0
    ;, "TEMPLATE_VARIABLES (OPTIONAL): " = ""
WITH outdev
   ;, lookup_key
   ;, request_key
   , pat_person_id
   ;, alias_type
   ;, alias_pool_cd
   ;, pat_encntr_id
   ;, template_variables

DECLARE alias = vc WITH protect, noconstant("")
DECLARE requestbody = vc WITH protect, noconstant("")


SET alias = cnvtstring( $PAT_PERSON_ID,value(size( $PAT_PERSON_ID)))
SET requestbody = build('{"id":"',alias,'"}')

call echo(build('requestbody:', requestbody))

EXECUTE hi_http_proxy_post_request value( $OUTDEV)
                                 , 'hi_record_person_empi_lookup'
                                 , "RECORD"
                                 , value( $PAT_PERSON_ID)
                                 , value(0.0)
                                 , value(requestbody)

call echorecord(memoryproxyreply)


end
go

mmmtestAPICall 'MINE', 26817165.0 go