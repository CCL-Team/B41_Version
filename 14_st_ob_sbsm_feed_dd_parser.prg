/*************************************************************************
 Program Title:   SBSM Last Doc Infant Feeding
 
 Object name:     14_st_ob_sbsm_feed_dd_parser
 Source file:     14_st_ob_sbsm_feed_dd_parser.prg
 
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
  drop program 14_st_ob_sbsm_feed_dd_parser:dba go
create program 14_st_ob_sbsm_feed_dd_parser:dba

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


free record drop_list
record drop_list(
    1 cnt = i4
    1 qual[*]
        2 value = vc
        2 label = vc
)
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare parse_dyn_doc_section(ident_txt = vc, html = vc) = vc
declare fuzzy_print_debug(big_string = vc, pos = i4, sze = i4) = null
declare parse_drop_list(rs = vc(ref), section = vc) = null
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header            = vc  with protect, noconstant(' ')
declare tmp_str           = vc  with protect, noconstant(' ')

declare crtoken           = c4  with protect,   constant("%CR%")
declare tbtoken           = c4  with protect,   constant("%TB%")
declare eoftoken          = c5  with protect,   constant("%EOF%")

declare act_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ACTIVE'   ))
declare mod_cd            = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'MODIFIED' ))
declare auth_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'AUTH'     ))
declare altr_cd           = f8  with protect,   constant(uar_get_code_by(   'MEANING',     8, 'ALTERED'  ))

declare blob              = vc  with protect, noconstant('')

declare feed_section      = vc  with protect, noconstant('')

declare data_found_ind    = i2  with protect, noconstant(0)

declare looper            = i4  with protect
 

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

    ;call echo(blob)
    
    set feed_section = parse_dyn_doc_section('>Infant Feeding<', blob)
    
    call echo('---------')
    ;call echo(feed_section)

    call parse_drop_list(drop_list, feed_section)
    call echorecord(drop_list)
endif


;Presentation
;RTF header
set header = notrim(build2(rhead))
 
 
if(blob_events->cnt > 0)
    set tmp_str = notrim(build2(wu, 'Last Documented Infant Feeding', wr, reol))
    
    for(looper = 1 to drop_list->cnt)
        if(drop_list->qual[looper]->value = 'X')
            set tmp_str = notrim(build2(tmp_str, drop_list->qual[looper]->label, reol))
            
            set data_found_ind = 1
        endif
    endfor
    
    if(data_found_ind = 0)
        set tmp_str = notrim(build2(tmp_str, 'No results found on last SBSM Note'))
    endif
    
    
endif
 
call include_line(build2(header, tmp_str, RTFEOF))
 
;build reply text
for (cnt = 1 to drec->line_count)
	set  reply -> text  =  concat ( reply -> text, drec -> line_qual [ cnt ]-> disp_line )
endfor
 
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
    declare cell_end_div = vc with protect, constant('</td>')
    
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
    
    ;Apparently we whiff on the last section.  If that happens... going to look for the /div before the next /td.
    ;and pray to the parsing gods.
    if(sect_end_pos = 0)
        set sect_end_pos = findstring(cell_end_div, html, sect_end_pos, 1)
    endif
    
    
    ;Find the end div before the next section in the page.
    set sect_end_pos = findstring(end_div, substring(1, sect_end_pos, html), 1, 1)
    
    
    set out_str = substring(sect_beg_pos, (sect_end_pos - sect_beg_pos) + 6, html)  ;6 is the size of </div>
    
    
    return(out_str)
    
    
end

/* parse_drop_list
   Given a specialized section of droplists... (as in might not work anywhere else)
   pull out the values and the labels and place in an RS
   
   Input:
        rs      (vc): rs by ref for holding all this info.
        section (vc): section containing the drop lists
        
   Output:
        rs (vc(ref)): 
                        free record drop_list
                        record drop_list(
                            1 cnt = i4
                            1 qual[*]
                                2 value = vc
                                2 label = vc
                        )
*/
subroutine parse_drop_list(rs, section)
    declare beg_drop_list = vc with protect, constant('class="blockdroplist"')
    declare beg_label     = vc with protect, constant('<span>')
    
    declare worker_index  = i4 with protect, noconstant(0)
    declare range_beg_pos = i4 with protect, noconstant(0)
    declare range_end_pos = i4 with protect, noconstant(0)
    
    declare looper            = i4  with protect
    declare panic_loop_break  = i4  with protect, noconstant(100)
    declare found_ind         = i4  with protect, noconstant(0)
    
    declare out_val   = vc with protect, noconstant('')
    declare out_label = vc with protect, noconstant('')
    
    
    set worker_index = findstring(beg_drop_list, section, 1, 0)
    
    if(worker_index > 0)
        while(panic_loop_break > 0 and worker_index > 0)
            ;Find the value.
            set worker_index  = findstring('>', section, worker_index, 0)
            
            set range_beg_pos = worker_index + 1
            
            set range_end_pos = findstring('<', section, range_beg_pos, 0)
            
            set out_val = substring(range_beg_pos, range_end_pos - range_beg_pos, section)
            
            
            ;Find the label
            set worker_index  = findstring(beg_label, section, range_end_pos, 0)
            
            set range_beg_pos = worker_index + 6 ;6 = "<span>"
            
            set range_end_pos = findstring('<', section, range_beg_pos, 0)
            
            set out_label = substring(range_beg_pos, range_end_pos - range_beg_pos, section)
            
            
            
            ;save out the info
            set rs->cnt = rs->cnt + 1
            set stat = alterlist(rs->qual, rs->cnt)
            
            set rs->qual[rs->cnt]->value = trim(out_val, 3)
            set rs->qual[rs->cnt]->label = trim(out_label, 3)
            
            
            
            set worker_index = findstring(beg_drop_list, section, range_end_pos, 0)
            
            set panic_loop_break = panic_loop_break - 1
        endwhile
    endif
    
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