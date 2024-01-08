/*************************************************************************
 Program Title:   SBSM Last Doc Pregnancy Notables
 
 Object name:     14_st_ob_sbsm_note_dd_parser
 Source file:     14_st_ob_sbsm_note_dd_parser.prg
 
 Purpose:
 
 Tables read:
 
 Executed from:
 
 Special Notes:   
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2023-10-17 Michael Mayes        234863 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_ob_sbsm_note_dd_parser:dba go
create program 14_st_ob_sbsm_note_dd_parser:dba

%i cust_script:0_rtf_template_format.inc
%i cust_script:0_cust_ce_blob_func.inc
 

/*record request(
   1 visit[*]
      2 encntr_id = f8
   1 person[*]
      2 person_id = f8
)*/

if(validate(reply) = 0)
    record reply(
       1 text                       = vc
          1 status_data
             2 status               = c1
             2 subeventstatus[1]
                3 OperationName     = c25
                3 OperationStatus   = c1
                3 TargetObjectName  = c25
                3 TargetObjectValue = vc
    )
endif

 
record blob_events(
    1 cnt = i4
    1 qual[*]
        2 event_id = f8
        2 event_dt = vc
)


record ConvTextIn(
    1 desired_format_cd = f8
    1 origin_format_cd  = f8
    1 origin_text       = gvc
)


record ConvTextOut(
    1 converted_text            = gvc
    1 status_data
        2 status                = c1
        2 subeventstatus[*]
            3 OperationName     = c25
            3 OperationStatus   = c1
            3 TargetObjectName  = c25
            3 TargetObjectValue = vc
)
 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare parse_dyn_doc_section(ident_txt = vc, html = vc) = vc
declare fuzzy_print_debug(big_string = vc, pos = i4, sze = i4) = null
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header            = vc   with protect, noconstant(' ')
declare tmp_str           = vc   with protect, noconstant(' ')

declare crtoken           = c4   with protect,   constant("%CR%")
declare tbtoken           = c4   with protect,   constant("%TB%")
declare eoftoken          = c5   with protect,   constant("%EOF%")

declare act_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'   ))
declare mod_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED' ))
declare auth_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'     ))
declare altr_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'  ))


declare blob              = vc   with protect, noconstant('')

declare noteable_section  = vc   with protect, noconstant('')

declare noteable_div      = vc   with protect, noconstant('')

declare looper            = i4   with protect


declare fulltext          = gvc  with protect, noconstant('')
declare perform_dt        = gvc
declare len               = i4   with protect
declare final             = vc   with protect, noconstant(' ')
declare tempvc            = vc   with protect
declare x                 = i4   with protect
declare y                 = i4   with protect
declare errc              = i4   with protect
declare errm              = vc   with protect
   



;output format variables from codeset 23
declare xhtml_cd    = f8  with protect, constant(252522796.0)  ; (23)  XHTML        XHTML
declare rtf_cd      = f8  with protect, constant(125.0)        ; (23)  RTF          RTF
declare ah_cd       = f8  with protect, constant(114.0)        ; (23)  AH           AH

;server application call constants for tdbexecute call for ConvertFormattedText request
declare appnum      = i4  with protect, constant(3202004)      ; 2004 Release Main Application
declare tasknum     = i4  with protect, constant(3202004)      ; Tasks that contain only requests that read or query data
declare reqnum      = i4  with protect, constant(969553)       ; ConvertFormattedText request

;set the output format and origin format code for the call to ConvertFormattedText
set ConvTextIn->origin_format_cd  = xhtml_cd
set ConvTextIn->desired_format_cd = rtf_cd




/**************************************************************
; DVDev Start Coding
**************************************************************/


/**********************************************************************
DESCRIPTION:  Find potential documentation
      NOTES:  
***********************************************************************/
select into "nl:"
  from dd_contribution dd
     , encounter       e
     , clinical_event  doc
     , clinical_event  mdoc
     
  plan dd
   where dd.person_id             =  p_id
  
  join e
   where e.encntr_id              =  dd.encntr_id

  join mdoc
   where mdoc.event_id               =  dd.mdoc_event_id
     and mdoc.event_title_text       = 'Office/Clinic Note - Obstetrics Recurring Prenatal Visit SBSM'
     and mdoc.encntr_id              =  dd.encntr_id
     and mdoc.valid_until_dt_tm      >  sysdate
     and mdoc.result_status_cd       in (act_cd, mod_cd, auth_cd, altr_cd)

  ;We want the doc tied to the mdoc we are after
  join doc
   where doc.event_id               =  dd.doc_event_id
     and doc.parent_event_id        =  dd.mdoc_event_id
     and doc.encntr_id              =  dd.encntr_id
     and doc.valid_until_dt_tm      >  sysdate
     and doc.result_status_cd       in (act_cd, mod_cd, auth_cd, altr_cd)
     
order by doc.performed_dt_tm desc, doc.event_id
detail
    blob_events->cnt = blob_events->cnt + 1

    if(mod(blob_events->cnt, 10) = 1)
        stat = alterlist(blob_events->qual, blob_events->cnt + 9)
    endif

    blob_events->qual[blob_events->cnt]->event_id = doc.event_id
    blob_events->qual[blob_events->cnt]->event_dt = format(doc.event_end_dt_tm, "@SHORTDATETIMENOSEC")

foot report
    stat = alterlist(blob_events->qual, blob_events->cnt)

with nocounter

call echorecord(blob_events)


if(blob_events->cnt > 0)
    ;First instance I've had where I don't actually have to loop.  We just want the latest note for the patient.
    set blob = cust_ceblob_get(blob_events->qual[1]->event_id)


    set noteable_section = parse_dyn_doc_section('>Pregnancy Notables<', blob)
    
    call echo(noteable_section)

    ;call echo(build('noteable_section:', noteable_section))

    declare beg_div      = vc with protect, constant('<div')
    declare beg_sect     = vc with protect, constant('CKI.SMARTTEMP.CODEVALUE!SBSMLASTDOCPREGNANCYNOTABLES')
    declare end_div      = vc with protect, constant('</div>')
    declare end_sect     = vc with protect, constant('CKI.SMARTTEMP.CODEVALUE!SBSMLASTDOCCONTRACEPTIONPLANAFTERD')
    
    declare worker_index = i4 with protect, noconstant(0)
    declare sect_beg_pos = i4 with protect, noconstant(0)
    declare sect_end_pos = i4 with protect, noconstant(0)

    
    ;This gets us into the tag we want... but we have to backtrack to the div
    set worker_index = findstring(beg_sect, noteable_section, 1, 0)
    
    if(worker_index > 0)
        ;Get the div
        set worker_index = findstring(beg_div, substring(1, worker_index, noteable_section), 1, 1)
        set sect_beg_pos = worker_index

        ;All of this is assuming there is no div that will land in the freetext area.  STs from my testing are landing as spans.
        
        ;It's a removable ST... if this fails us... fallback to /DIV.  If we find that /div... it should 
        ;be the next /div that we want.
        set worker_index = findstring(end_sect, noteable_section, sect_beg_pos, 0)
        
        ;We have to catch the case where the STs after our div get flat removed.  In that case... we don't really have anything to 
        ;find except our next /div.
        ;Well that and hope that somehow a div doesn't get placed in our text.  If that starts happening, we can find the second to 
        ;last end div in the section.
        if(worker_index = 0)
            set worker_index = findstring(end_div, noteable_section, sect_beg_pos, 0)
            
        else
            ;This gets us the last </div> in before that CKI.
            set worker_index = findstring(end_div, substring(1, worker_index, noteable_section), 1, 1)
            
        endif
        
        if(worker_index > 0)
            set sect_end_pos = worker_index + 6  ;</div>
            
            set noteable_div = substring(sect_beg_pos, (sect_end_pos - sect_beg_pos), noteable_section)
        
            set perform_dt = blob_events->qual[looper]->event_dt

            set fulltext   = '<?xml version="1.0" encoding="UTF-8"?>'
            set fulltext   = concat(fulltext, '<?dynamic-document type="template" version="2.0"?>'                           )
            set fulltext   = concat(fulltext, '<!DOCTYPE html SYSTEM '
                                            , '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'                   )
            set fulltext   = concat(fulltext, '<html xmlns="http://www.w3.org/1999/xhtml" xmlns:dd="DynamicDocumentation">'  )
            set fulltext   = concat(fulltext, '<head><title></title> <meta http-equiv="X-UA-Compatible" content="IE=10" /> '
                                            ,'</head><body>'                                                                       )
            set fulltext   = concat(fulltext, '<div style="font-family: tahoma,arial; font-size: 12px;">', noteable_div      )
            set fulltext   = concat(fulltext, '</div>'                                                                       )
            set fulltext   = concat(fulltext, "</body></html>"                                                               )


            set ConvTextOut->converted_text = " "
            set ConvTextIn->origin_text     = fulltext
        
            set stat                        = tdbexecute(appnum, tasknum, reqnum, "REC", ConvTextIn, "REC", ConvTextOut)

            set len                         = textlen(ConvTextOut->converted_text)

            call echorecord(ConvTextOut)
            
            ; remove trailing CRs
            ; After the get_blob_results subroutine has run, all your blob results in the
            ; record structure will have been converted so that there is a %CR% wherever
            ; an end-of-line is needed and %TB% where whitespace is needed.  It then becomes
            ; the job of your print routine to convert those tokens into appropriate codes to
            ; make those things happen.  (The %EOF% token is used locally inside the subroutine
            ; and will not be found in the results).
            set tempvc = ConvTextOut->converted_text

            for (x = 1 to 100)
                set y = findstring(crtoken, tempvc, 1, 1)

                if (y = textlen(tempvc) - 3 and y > 1)
                    set tempvc = substring(1, y - 1, tempvc)
                else
                    set x = 100
                endif
            endfor

            set tempvc = replace(tempvc, crtoken, "\par ")
            set tempvc = replace(tempvc, tbtoken, "\tab ")

            set final     = tempvc

            ; check for errors (most likely from tdbexecute)
            set errc=error(errm,0)
            
        endif
        
        
        ;call echo(build('noteable_div:', noteable_div))
    endif
endif



;Presentation

set tmp_str = final

 
set reply->text = final

 
set drec->status_data->status = "S"
set reply->status_data->status = "S"
 
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/


/* parse_dyn_doc_section
   Given some identifying text in the div for a section... parse 
   out and return the section.
   
   Input:
        ident_txt (vc): Hopefully unique identifying text within the div of the section we are after
        html      (vc): The HTML document probably coming from a DD ce_blob.
        
   Output:
        out_str   (vc): The section from within the HTML document.
*/
subroutine parse_dyn_doc_section(ident_txt, html)
    declare beg_div      = vc with protect, constant('<div')
    declare end_div      = vc with protect, constant('</div>')
    declare sect_div     = vc with protect, constant('ddsection')
    
    declare worker_index = i4 with protect, noconstant(0)
    declare sect_beg_pos = i4 with protect, noconstant(0)
    declare sect_end_pos = i4 with protect, noconstant(0)
    
    declare out_str      = vc with protect, noconstant('')
    
    
    
    set worker_index = findstring(ident_txt, html)

    
    ;Find our div start of the part we are in
    set sect_beg_pos = findstring(beg_div, substring(1, worker_index, html), 1, 1)
    
    ;This will be after the actual div end.  This is the next section div in the doc.
    ;We need to find it then back track to the close div
    set sect_end_pos = findstring(sect_div, html, worker_index, 0)
    
    ;Find the end div before the next section in the page.
    set sect_end_pos = findstring(end_div, substring(1, sect_end_pos, html), 1, 1)
    
    
    set out_str = substring(sect_beg_pos, (sect_end_pos - sect_beg_pos) + 6, html)  ;6 is the size of </div>
    
    
    return(out_str)
    
    
end




/* fuzzy_print_debug
   Given a position.  Print the surrounding string, for debug purposes.
   
   Input:
        big_string (vc): The big string/document being printed from.
        pos        (i4): The char to use as the center of our debug txt
        sze        (i4): The amount of chars before and after the pos to show.
        
   Output:
        **ACTION***: The surrounding area will be printed.
*/
subroutine fuzzy_print_debug(big_string, pos, sze)
    declare print_txt = vc with protect, noconstant('')
    
    set print_txt = substring(pos - sze, sze * 2 + 1, big_string)
    
    call echo(print_txt)
end
 
call echorecord(reply)
call echorecord(drec)
 
call echo(reply->text)
 
end
go