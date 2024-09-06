drop program 0_eks_hepinfpp_ordcmt_eval:dba go
create program 0_eks_hepinfpp_ordcmt_eval:dba
 
;call echoxml(request, "0_eks_hepinfpp_ordcmt_eval.dat")
;
;declare dclcom = vc with noconstant(" ")
;declare dcllen 		= i4 with noconstant(0)
;declare dclstatus	= i4 with noconstant(0)
;
;
;set dclcom = "rm /cerner/d_b41/ccluserdir/0_eks_hepinfpp_ordcmt_eval_dbg.dat"
;set dcllen = size(trim(dclcom))
;call dcl(dclcom, dcllen, dclstatus)
;
;set ccps_debug = 1
;%i cust_script:14_ccps_script_logging.inc
;
;declare MDQ8_EXEC_DT_TM = dq8 with protect, constant(cnvtdatetime(CURDATE, CURTIME3))
;declare MVC_ERR_MSG = vc with protect, noconstant("")
;
;if (validate(GI2_DEBUG_IND, 0) != 1)
;	set GI2_DEBUG_IND = 0
;endif
;
;if (validate(GI2_DATASET_ONLY_IND, 0) != 1)
;	set GI2_DATASET_ONLY_IND = 0
;endif
;call logMsg("REPLY STRUCTURE DEFINITION")
 
record eksopsrequest(
    1 expert_trigger = vc
    1 qual[*]
        2 person_id = f8
        2 sex_cd = f8
        2 birth_dt_tm = dq8
        2 encntr_id = f8
        2 accession_id = f8
        2 order_id = f8
        2 data[*]
            3 vc_var = vc
            3 double_var = f8
            3 long_var = i4
            3 short_var = i2
)
 
declare req = i4
declare happ = i4
declare htask = i4
declare hreq = i4
declare hreply = i4
declare crmstatus = i4
set ecrmok = 0
set null = 0
if(validate(recdate, "Y") = "Y"
    and validate(recdate, "N") = "N")
    record recdate(
        1 datetime = dq8
    )
 
endif
subroutine srvrequest(dparam)
    set req = 3091001
    set happ = 0
    set app = 3055000
    set task = 4801
    set endapp = 0
    set endtask = 0
    set endreq = 0
    call echo(concat("curenv = ", build(curenv)))
    if(curenv = 0)
        execute srvrtl
        execute crmrtl
        execute cclseclogin
        set crmstatus = uar_crmbeginapp(app, happ)
        call echo(concat("beginapp status = ", build(crmstatus)))
        if(happ)
            set endapp = 1
        endif
    else
        set happ = uar_crmgetapphandle()
    endif
    if(happ > 0)
        set crmstatus = uar_crmbegintask(happ, task, htask)
        if(crmstatus != ecrmok)
            call echo("Invalid CrmBeginTask return status")
            set retval = -(1)
        else
            set endtask = 1
            set crmstatus = uar_crmbeginreq(htask, 0, req, hreq)
            if(crmstatus != ecrmok)
                set retval = -(1)
                call echo(concat("Invalid CrmBeginReq return status of ", build(crmstatus)))
            elseif(hreq = null)
                set retval = -(1)
                call echo("Invalid hReq handle")
            else
                set endreq = 1
                set request_handle = hreq
                set heksopsrequest = uar_crmgetrequest(hreq)
                if(heksopsrequest = null)
                    set retval = -(1)
                    call echo("Invalid request handle return from CrmGetRequest")
                else
                    set stat = uar_srvsetstring(heksopsrequest, "EXPERT_TRIGGER", nullterm(eksopsrequest->expert_trigger))
                    for(ndx1 = 1 to size(eksopsrequest->qual, 5))
                        set hqual = uar_srvadditem(heksopsrequest, "QUAL")
                        if(hqual = null)
                            call echo("QUAL", "Invalid handle")
                        else
                            set stat = uar_srvsetdouble(hqual, "PERSON_ID", eksopsrequest->qual[ndx1].person_id)
                            set stat = uar_srvsetdouble(hqual, "SEX_CD", eksopsrequest->qual[ndx1].sex_cd)
                            set recdate->datetime = eksopsrequest->qual[ndx1].birth_dt_tm
                            set stat = uar_srvsetdate2(hqual, "BIRTH_DT_TM", recdate)
                            set stat = uar_srvsetdouble(hqual, "ENCNTR_ID", eksopsrequest->qual[ndx1].encntr_id)
                            set stat = uar_srvsetdouble(hqual, "ACCESSION_ID", eksopsrequest->qual[ndx1].accession_id)
                            set stat = uar_srvsetdouble(hqual, "ORDER_ID", eksopsrequest->qual[ndx1].order_id)
                            for(ndx2 = 1 to size(eksopsrequest->qual[ndx1].data, 5))
                                set hdata = uar_srvadditem(hqual, "DATA")
                                if(hdata = null)
                                    call echo("DATA", "Invalid handle")
                                else
                                    set stat = uar_srvsetstring(hdata, "VC_VAR", nullterm(eksopsrequest->qual[ndx1].data[ndx2].vc_var))
                                    set stat = uar_srvsetdouble(hdata, "DOUBLE_VAR", eksopsrequest->qual[ndx1].data[ndx2].double_var)
                                    set stat = uar_srvsetlong(hdata, "LONG_VAR", eksopsrequest->qual[ndx1].data[ndx2].long_var)
                                    set stat = uar_srvsetshort(hdata, "SHORT_VAR", eksopsrequest->qual[ndx1].data[ndx2].short_var)
                                endif
                            endfor
                            set retval = 100
                        endif
                    endfor
                endif
            endif
        endif
    endif
    if(crmstatus = ecrmok)
        call echo(concat("**** Begin perform request #", cnvtstring(req), " -EKS Event @", format(curdate, "dd-mmm-yyyy;;d"), " ", format(curtime3, "hh:mm:ss.cc;3;m")))
        set crmstatus = uar_crmperform(hreq)
        call echo(concat("**** End perform request #", cnvtstring(req), " -EKS Event @", format(curdate, "dd-mmm-yyyy;;d"), " ", format(curtime3, "hh:mm:ss.cc;3;m")))
        if(crmstatus != ecrmok)
            set retval = -(1)
            call echo("Invalid CrmPerform return status")
        else
            set retval = 100
            call echo("CrmPerform was successful")
        endif
    else
        set retval = -(1)
        call echo("CrmPerform not executed do to begin request error")
    endif
    if(endreq)
        call echo("Ending CRM Request")
        call uar_crmendreq(hreq)
    endif
    if(endtask)
        call echo("Ending CRM Task")
        call uar_crmendtask(htask)
    endif
    if(endapp)
        call echo("Ending CRM App")
        call uar_crmendapp(happ)
    endif
end
;Subroutine
subroutine ccl_wrap_text_incoming_orders(x, y, z)
    set eol = size(trim(z), 1)
    set bseg = 1
    set eseg = 1
    set line = substring(bseg, eol, z)
    set rorders->qual[x].line_cnt = 0
    while(eseg <= eol)
        set bseg = eseg
        set eseg += y
        if(findstring(" ", substring(bseg, eseg - bseg, line)) > 0)
            while(substring(eseg - 1, 1, line) != " "
                and eseg != bseg)
                set eseg -= 1
            endwhile
            set segment = substring(bseg, (eseg - bseg) - 1, z)
        else
            set segment = substring(bseg, eseg - bseg, z)
        endif
        set rorders->qual[x].line_cnt += 1
        set stat = alterlist(rorders->qual[x].lines, rorders->qual[x].line_cnt)
        set rorders->qual[x].lines[rorders->qual[x].line_cnt].text = segment
    endwhile
end
;Subroutine
subroutine ccl_wrap_text_powerplan(x, y, z)
    set eol = size(trim(z), 1)
    set bseg = 1
    set eseg = 1
    set line = substring(bseg, eol, z)
    set rpowerplancomments->qual[x].line_cnt = 0
    while(eseg <= eol)
        set bseg = eseg
        set eseg += y
        if(findstring(" ", substring(bseg, eseg - bseg, line)) > 0)
            while(substring(eseg - 1, 1, line) != " "
                and eseg != bseg)
                set eseg -= 1
            endwhile
            set segment = substring(bseg, (eseg - bseg) - 1, z)
        else
            set segment = substring(bseg, eseg - bseg, z)
        endif
        set rpowerplancomments->qual[x].line_cnt += 1
        set stat = alterlist(rpowerplancomments->qual[x].lines, rpowerplancomments->qual[x].line_cnt)
        set rpowerplancomments->qual[x].lines[rpowerplancomments->qual[x].line_cnt].text = segment
    endwhile
end
;Subroutine
free record rdata
record rdata(
    1 debug_comment = vc
    1 logic_prompt = vc
    1 ccl_template = i2
    1 ret_val = i1
    1 iv_set_order_id = f8
    1 orderlist[*]
        2 seq = i2
        2 isheparin = i1
        2 isivroute = i1
        2 orderid = f8
        2 catalogtypecd = f8
        2 catalogcd = f8
        2 synonymid = f8
        2 ordermnemonic = vc
        2 detaillist[*]
            3 oefieldid = f8
            3 oefieldvalue = f8
            3 oefielddisplayvalue = vc
            3 oefieldmeaning = vc
        2 subcomponentlist[*]
            3 sccatalogcd = f8
            3 sccatalog = vc
            3 scsynonymid = f8
            3 scordermnemonic = vc
            3 scivseq = i4
)
 
free record rorders
record rorders(
    1 bheparinpowerplan = i1
    1 nomatchfound_level_01 = i1
    1 textlen_matches = i1
    1 debug_ord_comment = vc
    1 debug_pp_comment = vc
    1 debug_oc_comment = vc
    1 debug_execute_comment = vc
    1 isheparinivfound = i1
    1 person_id = f8
    1 encntr_id = f8
    1 cnt = i4
    1 qual[*]
        2 bordercommentmatchespowerplancomment = i1
        2 nomatchfound_level_02 = i1
        2 textlen_matches = i1
        2 order_id = f8
        2 synonym_id = f8
        2 order_mnemonic = vc
        2 powerplan_id = f8
        2 pathway_comp_id = f8
        2 powerplan_disp = vc
        2 long_text_textlen = i4
        2 order_comment_textlen = i4
        2 order_comment = vc
        2 line_cnt = i1
        2 lines[*]
            3 text = vc
            3 nomatchfound_level_03 = i1
)
 
free record rpowerplancomments
record rpowerplancomments(
    1 debug_comment = vc
    1 cnt = i4
    1 qual[*]
        2 synonym_id = f8
        2 order_mnemonic = vc
        2 comment_textlen = i4
        2 comment = vc
        2 line_cnt = i1
        2 lines[*]
            3 text = vc
)
 
free record rcomparecomments
record rcomparecomments(
    1 debug = vc
    1 all_hep_ord_cmts_match = i1
    1 ord[*]
        2 match_found = i1
        2 pow[*]
            3 ord_matches_pow = i1
            3 qual[*]
                4 line_matches = i1
                4 oline_textlen = i4
                4 pline_textlen = i4
                4 oline = vc
                4 pline = vc
)
 
set rcomparecomments->debug = "initialized"
set rcomparecomments->comments_match = 1
declare ord_cnt = i1 with protect
declare detail_cnt = i1 with protect
declare ingredient_cnt = i1 with protect
declare hepcnt = i1 with protect
call echojson(request, "ccluserdir:0_eks_hepinfpp_ordcmt_req.dat")
for(orderlistindex = 1 to size(request->orderlist, 5))
    set ord_cnt += 1
    set stat = alterlist(rdata->orderlist, ord_cnt)
    set rdata->orderlist[ord_cnt].seq = orderlistindex
    set rdata->orderlist[ord_cnt].catalogtypecd = request->orderlist[orderlistindex].catalogtypecd
    set rdata->orderlist[ord_cnt].catalogcd = request->orderlist[orderlistindex].catalogcd
    set rdata->orderlist[ord_cnt].orderid = request->orderlist[orderlistindex].orderid
    set rdata->orderlist[ord_cnt].ordermnemonic = uar_get_code_display(request->orderlist[orderlistindex].catalogcd)
    for(detcnt = 1 to size(request->orderlist[orderlistindex].detaillist, 5))
        set stat = alterlist(rdata->orderlist[orderlistindex].detaillist, detcnt)
        set rdata->orderlist[ord_cnt].detaillist[detcnt].oefieldid = request->orderlist[orderlistindex].detaillist[detcnt].oefieldid
        set rdata->orderlist[ord_cnt].detaillist[detcnt].oefieldvalue = request->orderlist[orderlistindex].detaillist[detcnt].oefieldvalue
        set rdata->orderlist[ord_cnt].detaillist[detcnt].oefielddisplayvalue = request->orderlist[orderlistindex].detaillist[detcnt].oefielddisplayvalue
        set rdata->orderlist[ord_cnt].detaillist[detcnt].oefieldmeaning = request->orderlist[orderlistindex].detaillist[detcnt].oefieldmeaning
        if(request->orderlist[orderlistindex].detaillist[detcnt].oefieldmeaningid = 2050.0
            and request->orderlist[orderlistindex].detaillist[detcnt].oefieldvalue = 318170.0)
            set rdata->orderlist[ord_cnt].isivroute = 1
        endif
    endfor
    for(subcompcnt = 1 to size(request->orderlist[orderlistindex].subcomponentlist, 5))
        set stat = alterlist(rdata->orderlist[ord_cnt].subcomponentlist, subcompcnt)
        set rdata->orderlist[ord_cnt].subcomponentlist[subcompcnt].sccatalogcd = request->orderlist[orderlistindex].subcomponentlist[subcompcnt].sccatalogcd
        set rdata->orderlist[ord_cnt].subcomponentlist[subcompcnt].sccatalog = uar_get_code_display(request->orderlist[orderlistindex].subcomponentlist[subcompcnt].sccatalogcd)
        set rdata->orderlist[ord_cnt].subcomponentlist[subcompcnt].scsynonymid = request->orderlist[orderlistindex].subcomponentlist[subcompcnt].scsynonymid
        if(request->orderlist[orderlistindex].subcomponentlist[subcompcnt].sccatalogcd = 2759747.0
            and rdata->orderlist[ord_cnt].isivroute = 1)
            set rorders->isheparinivfound = 1
            set rorders->debug_ord_comment = "Heparin IV found"
            set hepcnt += 1
            set stat = alterlist(rorders->qual, hepcnt)
            set rorders->encntr_id = request->orderlist[orderlistindex].encntrid
            set rorders->qual[hepcnt].order_id = request->orderlist[orderlistindex].orderid
            set rorders->qual[hepcnt].synonym_id = request->orderlist[orderlistindex].subcomponentlist[subcompcnt].scsynonymid
            set rorders->qual[hepcnt].order_mnemonic = request->orderlist[orderlistindex].subcomponentlist[subcompcnt].scordermnemonic
        endif
    endfor
endfor

call echojson(rorders, "ccluserdir:0_eks_hepinfpp_ordcmt_rorders1.dat")

if(rorders->isheparinivfound = 0)
    set log_message = "Heparin IV not found. Exit."
    set retval = 0
    go to exit_script
endif
 
;select into "nl:"
;    pp = trim(pc.description, 3)
;from (dummyt d1 with seq = value(size(rorders->qual, 5)))
;    ,orders o
;    ,pathway_catalog pc
;plan d1 where rorders->qual[d1.seq].order_id > 0
;join o where o.order_id = rorders->qual[d1.seq].order_id
;join pc where pc.pathway_catalog_id = o.pathway_catalog_id
select into "nl:"
	pp = trim(pc.description, 3)
	from (dummyt d1 with seq = value(size(rorders->qual, 5)))
	,orders o
    ,act_pw_comp apc
    ,pathway pw
    ,pathway_catalog pc
    plan d1
    	where rorders->qual[d1.seq].order_id > 0
    join o
    	where o.order_id = rorders->qual[d1.seq].order_id
    join apc
    	where apc.encntr_id = o.encntr_id
    	and apc.parent_entity_id = o.order_id
        and apc.parent_entity_name = "ORDERS"
    join pw
    	where pw.pathway_id = apc.pathway_id
    join pc
    	where pc.pathway_catalog_id = pw.pw_cat_group_id
head report
    null
detail
    if(trim(pc.description, 3) = "Heparin Infusion No Bolus Protocol - Durable LVAD (0.1 - 0.3) EKM"
        or trim(pc.description, 3) = "Heparin Infusion No Subtherapeutic Bolus Protocol - ACS (0.3 - 0.7) EKM"
        or trim(pc.description, 3) = "Heparin Infusion No Subtherapeutic Bolus Protocol - Standard (0.3 - 0.7) EKM"
        or trim(pc.description, 3) = "Heparin Infusion No Subtherapeutic Bolus Protocol - Stroke (0.1 - 0.3) EKM"
        or trim(pc.description, 3) = "Heparin Infusion POST SURGICAL - No Subtherapeutic Bolus Low Target Range. MGUH EKM"
        or trim(pc.description, 3) = "Heparin Infusion POST SURGICAL - No Subtherapeutic Bolus MID Target RangeMGUH EKM"
        or trim(pc.description, 3) = "Heparin Infusion POST SURGICAL - No Subtherapeutic Bolus Standard Target Range MGUH EKM"
        or trim(pc.description, 3) = "Heparin Infusion POST SURGICAL Protocol - Low Target Range MGUH EKM"
        or trim(pc.description, 3) = "Heparin Infusion POST SURGICAL Protocol - MID Target Range MGUH EKM"
        or trim(pc.description, 3) = "Heparin Infusion POST SURGICAL Protocol - Standard Target Range MGUH EKM"
        or trim(pc.description, 3) = "Heparin Infusion Protocol - ACS (0.3 - 0.7) EKM"
        or trim(pc.description, 3) = "Heparin Infusion Protocol - Standard (0.3 - 0.7) EKM"
        or trim(pc.description, 3) = "Heparin Infusion Protocol - Stroke (0.1 - 0.3) EKM"
        or trim(pc.description, 3) =  ".Heparin Infusion Protocols Adult EKM")
        rorders->bheparinpowerplan = 1
         rorders->qual[d1.seq].powerplan_id = pw.pathway_catalog_id;o.pathway_catalog_id
         rorders->qual[d1.seq].pathway_comp_id = apc.pathway_comp_id
         rorders->qual[d1.seq].powerplan_disp = trim(pw.description, 3)
         ;call logMsg(build2("powerplan_id =", pw.pathway_catalog_id))
         ;call logMsg(build2("powerplan_desc =", pw.description))
    endif
with nocounter, nullreport
 
;end select
if(rorders->bheparinpowerplan = 0)
    set log_message = "Heparin powerplan not found. Exit."
    set retval = 0
    go to exit_script
endif
declare tmpstr1 = vc
 
select into "nl:"
    oc.order_id
    ,ord_cmt = substring(1, 5000, lt.long_text)
from (dummyt d1 with seq = value(size(rorders->qual, 5)))
    ,order_comment oc
    ,long_text lt
plan d1 where rorders->qual[d1.seq].order_id > 0
join oc where oc.order_id = rorders->qual[d1.seq].order_id
    and oc.comment_type_cd = 66.00
join lt where lt.long_text_id = oc.long_text_id
detail
    rorders->debug_oc_comment = concat(trim(cnvtstring(lt.long_text_id), 3))
     rorders->qual[d1.seq].long_text_textlen = textlen(trim(lt.long_text, 3))
     rorders->qual[d1.seq].order_comment = trim(ord_cmt, 3)
     rorders->qual[d1.seq].order_comment_textlen = textlen(rorders->qual[d1.seq].order_comment)
     ;call logMsg(build2("powerplan_Comment_main =", trim(ord_cmt, 3)))
     call ccl_wrap_text_incoming_orders(d1.seq, 100, lt.long_text)
with nocounter

call echojson(rorders, "ccluserdir:0_eks_hepinfpp_ordcmt_rorders2.dat")

;end select
declare tmpstr2 = vc
 
select into "nl:"
    powerplan_name = pcat.description
    ,clinical_category = uar_get_code_display(pc.dcp_clin_cat_cd)
    ,clinical_sub_category = uar_get_code_display(pc.dcp_clin_sub_cat_cd)
    ,synonym_id = ocs.synonym_id
    ,pathway_comp_id = pc.pathway_comp_id
    ,order_mnemonic = ocs.mnemonic
    ,include_exclude = pc.include_ind
    ,order_sentence_display_line = os.order_sentence_display_line
    ,order_sentence_comment = lt.long_text
from (dummyt d1 with seq = value(size(rorders->qual, 5)))
    ,pathway_catalog pcat
    ,pathway_comp pc
    ,order_catalog_synonym ocs
    ,pw_comp_os_reltn pcor
    ,order_sentence os
    ,long_text lt
plan d1
	where rorders->qual[d1.seq].powerplan_id > 0.00
	and rorders->qual[d1.seq].pathway_comp_id > 0
join pcat
	where pcat.pathway_catalog_id = rorders->qual[d1.seq].powerplan_id
    and pcat.active_ind = 1
join pc
	where pc.pathway_catalog_id = pcat.pathway_catalog_id
    and pc.active_ind = 1
    and pc.pathway_comp_id = rorders->qual[d1.seq].pathway_comp_id
join ocs
	where ocs.synonym_id = pc.parent_entity_id
    and ocs.catalog_type_cd = 2516.0
join pcor
	where pcor.pathway_comp_id = pc.pathway_comp_id
join os
	where os.order_sentence_id = pcor.order_sentence_id
join lt
	where lt.long_text_id = os.ord_comment_long_text_id
head report
    cnt = 0
detail
    if(trim(lt.long_text) > "")
        cnt += 1
         stat = alterlist(rpowerplancomments->qual, cnt)
         rpowerplancomments->debug_comment = "PP Comments found"
         rpowerplancomments->qual[cnt].synonym_id = ocs.synonym_id
         rpowerplancomments->qual[cnt].order_mnemonic = ocs.mnemonic
         tmpstr2 = lt.long_text
         rpowerplancomments->qual[cnt].comment_textlen = textlen(trim(lt.long_text, 3))
         rpowerplancomments->qual[cnt].comment = tmpstr2
         ;call logMsg(build2("powerplan_Comment_2 =", tmpstr2))
         call ccl_wrap_text_powerplan(cnt, 100, lt.long_text)
    endif
with nocounter
 
;end select
;call logMsg(build2("rorders->qual Len =", size(rorders->qual, 5)))
;call logMsg(build2("rpowerplancomments->qual Len =", size(rpowerplancomments->qual, 5)))
;call logMsg(build2("rpowerplancomments->qual Len =", size(rpowerplancomments->qual[p].lines, 5)))

;INC0815066 - MMM174 8-30-2024 ->  New vars... just to be a little extra passive.
declare o_line_replace = vc with protect, noconstant('')
declare p_line_replace = vc with protect, noconstant('')
;INC0815066 - MMM174 8-30-2024 <-

for(o = 1 to size(rorders->qual, 5))
    set stat = alterlist(rcomparecomments->ord, o)
    for(p = 1 to size(rpowerplancomments->qual, 5))
        set stat = alterlist(rcomparecomments->ord[o].pow, p)
        set rcomparecomments->ord[o].pow[p].ord_matches_pow = 0
        for(l = 1 to size(rpowerplancomments->qual[p].lines, 5))
            set stat = alterlist(rcomparecomments->ord[o].pow[p].qual, l)
            set rcomparecomments->ord[o].pow[p].qual[l].oline = trim(rorders->qual[o].lines[l].text, 3)
            set rcomparecomments->ord[o].pow[p].qual[l].pline = trim(rpowerplancomments->qual[p].lines[l].text, 3)
            
            ;INC0815066 - MMM174 8-30-2024 ->
            
            /* INC0815066 - MMM174 8-30-2024
               This compare mismatches in a case they have called out in an incident.
               That case is when they pick the NSTEMI/STEMI/UA (ACS) group...
               And then the Heparin Infusion No Subtherapeutic Bolus Protocol - ...
               Like the second option in there.
               {
                "LINE_MATCHES":0,
                "OLINE_TEXTLEN":0,
                "PLINE_TEXTLEN":0,
                "OLINE":"provider.\r\n\r\nNOTE: Use \"\r\n\r\nHeparin Anti-Xa Assay ACS Target (NSTEM\/STEMI\/UA)\" order when placing",
                "PLINE":"provider.\r\n\r\nNOTE: Use \"\n\nHeparin Anti-Xa Assay ACS Target (NSTEM\/STEMI\/UA)\" order when placing"
               },
               
               
               Honestly looks like a windows vs unix new line issue.  But enough to kill our compare.
               
               I don't know if this is order build... PP build... but I can code for it since this is a critical issue on a Friday
               night.  I think I'm going to tell the compare to ignore new line chars.  This will make it so we don't necessarily
               make sure the comment is _unchanged_ but as long as the text minus new lines is the same, we'll pass.
               
               I think this should honor the spirit of what we are trying to do here I think.
            */
            ;We are kind of code cowboy here, so I want to make double sure I don't have anything in here if we mess up somehow.
            ;Reinitialize
            set o_line_replace = ''
            set p_line_replace = ''
            
            ;Kill all CRs and LFs
            set o_line_replace = replace(replace(rcomparecomments->ord[o].pow[p].qual[l].oline, char(13), ''), char(10), '')
            set p_line_replace = replace(replace(rcomparecomments->ord[o].pow[p].qual[l].pline, char(13), ''), char(10), '')
            
            ;This line dies with this change.  Replaced with the below.
            ;if(rcomparecomments->ord[o].pow[p].qual[l].oline = rcomparecomments->ord[o].pow[p].qual[l].pline)
            if(o_line_replace = p_line_replace)
            
            ;INC0815066 - MMM174 8-30-2024 <-
            
                set rcomparecomments->ord[o].pow[p].qual[l].line_matches = 1
                ;call logMsg("Its a match")
                ;call logMsg(build2("powerplan_Comment_logic =", tmpstr2))
            else
            	;call logMsg("Failed Match")
                set rcomparecomments->ord[o].pow[p].qual[l].line_matches = 0
                set rcomparecomments->ord[o].pow[p].ord_matches_pow = 0
            endif
            ;call logMsg(build2("oline =", rcomparecomments->ord[o].pow[p].qual[l].oline))
            ;call logMsg(build2("oline =", rcomparecomments->ord[o].pow[p].qual[l].pline))
        endfor
    endfor
endfor
declare line_match_cnt = i2 with protect
for(o = 1 to size(rcomparecomments->ord, 5))
    for(p = 1 to size(rcomparecomments->ord[o].pow, 5))
        if(size(rcomparecomments->ord[o].pow[p].qual, 5) > 0)
            set line_match_cnt = 0
            for(q = 1 to size(rcomparecomments->ord[o].pow[p].qual, 5))
                set line_match_cnt += rcomparecomments->ord[o].pow[p].qual[q].line_matches
            endfor
            if(line_match_cnt = size(rcomparecomments->ord[o].pow[p].qual, 5))
                set rcomparecomments->ord[o].match_found = 1
            endif
        endif
    endfor
endfor

declare order_match_cnt = i2 with protect
set order_match_cnt = 0
if(size(rcomparecomments->ord, 5) > 0)
    for(o = 1 to size(rcomparecomments->ord, 5))
        set order_match_cnt += rcomparecomments->ord[o].match_found
    endfor
    if(order_match_cnt = size(rcomparecomments->ord, 5))
        set rcomparecomments->all_hep_ord_cmts_match = 1
    endif
endif

call echojson(rcomparecomments, "ccluserdir:0_eks_hepinfpp_ordcmt_rcomp.dat")

if(rcomparecomments->all_hep_ord_cmts_match = 1)
    set log_message = "Order comment = Powerplan comment. No modification found."
    set retval = 100
else
    set log_message = "Order comment has been modified; does not match a powerplan comment. See $CCLUSERDIR/txs57rcomparecmnts*.txt."
    set retval = 0
endif
 
#end_run
if(validate(link_template, 0) = 0)
    set log_personid = trigger_personid
    set log_encntrid = trigger_encntrid
    set log_accessionid = trigger_accessionid
    set log_orderid = trigger_orderid
else
    set log_accessionid = link_accessionid
    set log_orderid = link_orderid
    set log_encntrid = link_encntrid
    set log_personid = link_personid
    set log_taskassaycd = link_taskassaycd
    set log_clineventid = link_clineventid
endif
 
#exit_script
if(reqinfo->updt_id = 4079490.0
    or reqinfo->updt_id = 29096963.0
    or reqinfo->updt_id = 24117701.00)   ;MMM made this mod to troubleshoot a critical issue.  last mod up to this point was.
                                         ;    SCS937       20 of march 2024   ; INC0815066
    call echojson(request, "1tempheprequest.txt")
    call echojson(eksdata, "1temphepeksdata.txt")
    call echojson(rorders, "1tempheprorders.txt")
    call echojson(rpowerplancomments, "1tempheprppcmnts.txt")
    call echojson(rcomparecomments, "1tempheprcomparecmnts.txt")
endif
 
end go