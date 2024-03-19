/**************************************************************************
 Program Title:   mp_cust_get_patient_handoff
 
 Object name:     mp_cust_get_patient_handoff
 Source file:     mp_cust_get_patient_handoff.prg
 
 Purpose:         This script calls two smart templates and returns to a 
                  front end component for TOP Patient Handoff.
 
 Tables read:     
 
 Executed from:   MPage
 
 Special Notes:   
 
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 08/21/2019 Michael Mayes        216094    Initial release
 
*************END OF ALL MODCONTROL BLOCKS* ********************************/
drop program mp_cust_get_patient_handoff:dba go
create program mp_cust_get_patient_handoff:dba

prompt
      "Output to File/Printer/MINE:" = 'MINE'
    , "Person Id:"                   = 0.0   
    , "Encounter Id:"                = 0.0
with OUTDEV, per_id, enc_id



/**************************************************************
; DVDev INCLUDES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc


/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
free record mcgph_reply
record mcgph_reply(
    1 hm_st_reply  = vc
    1 ord_st_reply = vc
    1 event_reply  = vc
    1 event_dt_txt = vc
    1 event_cd     = f8  
)

record st_request(
    1 visit[*]
        2 encntr_id = f8
    1 person[*]
        2 person_id = f8
)
 
 
record ord_reply(
    1 text                      = vc
    1 status_data
        2 status                = c1
        2 subeventstatus[1]
            3 OperationName     = c25
            3 OperationStatus   = c1
            3 TargetObjectName  = c25
            3 TargetObjectValue = vc
)

record hm_reply(
    1 text                      = vc
    1 status_data
        2 status                = c1
        2 subeventstatus[1]
            3 OperationName     = c25
            3 OperationStatus   = c1
            3 TargetObjectName  = c25
            3 TargetObjectValue = vc
)

record ConvTextIn (
    1 desired_format_cd         = f8
    1 origin_format_cd          = f8
    1 origin_text               = gvc
)
 
record ConvTextOut (
    1 converted_text            = gvc
    1 status_data
        2 status                = c1
        2 subeventstatus [*]
            3 OperationName     = c25
            3 OperationStatus   = c1
            3 TargetObjectName  = c25
            3 TargetObjectValue = vc
)


/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare mcgph_strip_tags(html_txt = vc) = vc
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare handoff_cd   = f8  with protect, constant(uar_get_code_by('DISPLAYKEY', 72, 'PATIENTHANDOFFDOCUMENTATION'))

declare xhtml_cd     = f8  with protect,constant(252522796.0)  ; (23)  XHTML        XHTML
declare rtf_cd       = f8  with protect,constant(125.0)        ; (23)  RTF          RTF
 
;server application call constants for tdbexecute call for ConvertFormattedText request
declare appnum       = i4  with protect,constant(3202004)      ; 2004 Release Main Application
declare tasknum      = i4  with protect,constant(3202004)      ; Tasks that contain only requests that read or query data
declare reqnum       = i4  with protect,constant(969553)       ; ConvertFormattedText request

declare act_cd       = f8  with protect, constant(uar_get_code_by(   'MEANING',  8, 'ACTIVE'))
declare mod_cd       = f8  with protect, constant(uar_get_code_by(   'MEANING',  8, 'MODIFIED'))
declare auth_cd      = f8  with protect, constant(uar_get_code_by(   'MEANING',  8, 'AUTH'))
declare alt_cd       = f8  with protect, constant(uar_get_code_by(   'MEANING',  8, 'ALTERED'))


/**************************************************************
; DVDev Start Coding
**************************************************************/
;First send up the code that we'll use for writing free text.
set mcgph_reply->event_cd = handoff_cd


;set up the request for the smart templates.
set stat = alterlist(st_request->person, 1)
set st_request->person[1]->person_id = $per_id

set stat = alterlist(st_request->visit, 1)
set st_request->visit[1]->encntr_id = $enc_id


;Now we'll call those and get the RTF return
execute 14_st_pat_handoff_orders with replace(request, st_request), replace(reply, ord_reply)
execute 14_st_RecsAddressedToday with replace(request, st_request), replace(reply, hm_reply)

call echorecord(ord_reply)
call echorecord(hm_reply)


;set the output format and origin format code for the call to ConvertFormattedText (we want HTML from the RTF)
set ConvTextIn->origin_format_cd  = rtf_cd
set ConvTextIn->desired_format_cd = xhtml_cd


;Order first
set ConvTextIn->origin_text   = ord_reply->text
set stat = tdbexecute(appnum, tasknum, reqnum, "REC", ConvTextIn, "REC", ConvTextOut)
set mcgph_reply->ord_st_reply = mcgph_strip_tags(ConvTextOut->converted_text)


;Now HM
set ConvTextOut->converted_text = ''
set ConvTextIn->origin_text     = hm_reply->text
set stat = tdbexecute(appnum, tasknum, reqnum, "REC", ConvTextIn, "REC", ConvTextOut)
set mcgph_reply->hm_st_reply   = mcgph_strip_tags(ConvTextOut->converted_text)


;See if there was a previous handoff on the encounter, and if so send it up.
/***********************************************************************
DESCRIPTION: Find LCV handoff event
***********************************************************************/
select into 'nl:'
  from clinical_event ce
 where ce.encntr_id         =  $enc_id
   and ce.result_status_cd  in (act_cd, mod_cd, auth_cd, alt_cd)
   and ce.valid_until_dt_tm >  cnvtdatetime(curdate,curtime3)
   and ce.event_cd          =  handoff_cd
order by ce.event_end_dt_tm desc
head report
    mcgph_reply->event_reply  = trim(ce.result_val)
    mcgph_reply->event_dt_txt = format(ce.event_end_dt_tm, '@SHORTDATETIME')
with nocounter


/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
/* mcgph_strip_tags
   The return from the service gives us a full HTML page.  We just want the inner divs since we are
   going to be displaying this in a component.  I need to do some HTML parsing to just show the body
   of the return.  This should do that.
   
   Input:
        html_txt (vc) = The full HTML of the conversion.
   
   Output:
        (vc)          = The inner body HTML
*/
subroutine mcgph_strip_tags(html_txt)
    declare mcgph_body_tag  = vc with protect,   constant('<body')
    declare mcgph_end_tag   = vc with protect,   constant('>')
    declare mcgph_body_end  = vc with protect,   constant('</body>')
    
    declare parse_start_pos = i4 with protect, noconstant(0)
    declare parse_end_pos   = i4 with protect, noconstant(0)
    
    declare ret_str         = vc with protect, noconstant('')
    
    ;Find our body start
    set parse_start_pos = findstring(mcgph_body_tag, html_txt)
    set parse_start_pos = findstring(mcgph_end_tag, html_txt, parse_start_pos) + 1
    
    set ret_str         = substring(parse_start_pos, size(html_txt, 3) - parse_start_pos + 1, html_txt)
    
    ;find our body end
    set parse_end_pos   = findstring(mcgph_body_end, ret_str, 1, 1) - 1
    
    set ret_str         = substring(1, parse_end_pos, ret_str)
    
    return (ret_str)
end

 
#exit_script

call echojson(mcgph_reply)

call putRSToFile($OUTDEV, mcgph_reply)

end
go
 