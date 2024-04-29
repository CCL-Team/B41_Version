drop program mmmtest go
create program mmmtest

declare attrib_obj            = vc

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





declare uri = vc with protect, noconstant(concat('https://medstarhealth.registries.healtheintent.com/api'
                                                , '/populations/d2f137ff-3778-4917-ab34-b8cc85cbc41d'
                                                , '/programs'
                                                )
                                         )







                                       
execute hi_http_proxy_get_request "MINE", uri, "JSON"
        with replace("PROXYREPLY", person_demogr_reply)

;set attrib_obj = concat('{"attrib":{"prov":', person_demogr_reply->httpReply->body, '}}')

call echo(person_demogr_reply->httpReply->body)

;set stat = cnvtjsontorec(attrib)
;
;call echojson(rec)

end
go
mmmtest go
