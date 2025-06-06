drop program 14_st_visit_referral_orders go
create program 14_st_visit_referral_orders


/*--------------------------------------------------------------------------------------------------------------------------------
 Name           : 14_st_visit_referral_orders.prg
 Author:        : Simeon Akinsulie
 Date           : 02/12/2024
 Location       : cust_script
 Purpose            : Smart template script to pull visit referral orders

----------------------------------------------------------------------------------------------------------------------------------
 History
----------------------------------------------------------------------------------------------------------------------------------
 Ver  By            Date        Description
 ---  ---           ----------  -----------
 001  saa126      02/12/2024  Initial Release
 002  mmm174        06/06/2025  Small formatting changes to prevent RTF error.
 End History
--------------------------------------------------------------------------------------------------------------------------------*/



/*--------------------------------------------------------------------------------------------------------------------------------
  Includes File(s) and subroutine
--------------------------------------------------------------------------------------------------------------------------------*/
%i cust_script:0_rtf_template_format.inc

/*--------------------------------------------------------------------------------------------------------------------------------
  Declare request/reply structures if not built for debugging
--------------------------------------------------------------------------------------------------------------------------------*/
;if (validate(request->person) = 0)
;  free record request
;  record request (
;    1 person[1]
;      2 person_id = f8
;  )
;  set request->person[1].person_id = 32751766
;endif
;
;if (validate(reply->text,"NOTDECLARED") = "NOTDECLARED")
;  free record reply
;  record reply (
;    1 text = vc
;)
;endif
;
/*--------------------------------------------------------------------------------------------------------------------------------
  Declare Record Structure
--------------------------------------------------------------------------------------------------------------------------------*/


record orders(
    1 orders[*]
        2 order_id                = f8
        2 order_name              = vc
        2 ref_to_prsnl            = vc
        2 ref_to_prsnl_id         = f8
        2 ref_to_prsnl_credential = vc
        2 ref_service_desired     = vc
        2 ref_special_instruction = vc
        2 ref_to_ph_fx            = vc
        2 ref_to_loc              = vc
        2 ref_to_loc2             = vc
        2 ref_to_loc3             = vc
        2 suggested_time_frame    = vc
        2 comment_ind             = i4
        2 order_comment           = vc
)


/*--------------------------------------------------------------------------------------------------------------------------------
  Declare Variables
--------------------------------------------------------------------------------------------------------------------------------*/

declare rtf_out          = vc with protect, noconstant('')
declare cnt              = i4
declare num              = i4 with noconstant(0),public
declare modality_parser  = vc
declare prsnl_credential = vc
declare pos              = i4
declare bullet_start     = vc
declare bullet_end       = vc
declare lb_cntrl         = i4
set bullet_start         = "{\f2 {\pntext \'B7\tab}{*\pn\pnlvlblt\pnstart1{\pntxtb\'B7}}{\ltrch "
set bullet_end           = "}\li720\ri0\sa0\sb0\jclisttab\tx720\fi-360\ql\par }"



/*--------------------------------------------------------------------------------------------------------------------------------
  Declare constants for RTF tags
--------------------------------------------------------------------------------------------------------------------------------*/



;---------------------------------------------------------------------------------------------------------------------------------
;   Get Wound Info
;---------------------------------------------------------------------------------------------------------------------------------
select into 'nl:'
       o.order_id
     , oef.description
     , od.oe_field_value
     , od.oe_field_display_value
     , rtf_out                   = build2(trim(uar_get_code_display(o.catalog_cd),3)," ")
     , od.oe_field_id
     , oc.activity_subtype_cd
  from orders o
     , order_catalog oc
     , order_detail od
     , order_entry_fields oef
  plan o
   where (   o.encntr_id             = request->visit[1]->encntr_id ;250873718;
          or o.originating_encntr_id = request->visit[1]->encntr_id ;250873718);
         )
  and o.catalog_type_cd = 249926603.00
  and o.catalog_cd != 833039803.00
join oc
  where oc.catalog_cd = o.catalog_cd
join od
  where od.order_id = o.order_id
  and od.action_sequence = (select max(action_sequence)
                                        from order_detail
                                        where order_id = od.order_id
                                        and   oe_field_id = od.oe_field_id)
join oef
  where oef.oe_field_id = od.oe_field_id
order by o.order_id, od.oe_field_id, od.updt_dt_tm desc

head report
  cnt = 0

head o.order_id
  cnt =  cnt + 1
  stat = alterlist(orders->orders,cnt)

  orders->orders[cnt].order_id = o.order_id
  orders->orders[cnt].order_name = trim(
    replace(replace(
      replace(
        trim(oc.description),
          "'", ""),

          "Referral to",""),"Referral","")
          ,3)
  ;replace(o.order_mnemonic,"Referral To",""); uar_get_Code_display(o.catalog_cd)


head od.oe_field_id
  case(od.oe_field_id)
    of 12663.00:
      orders->orders[cnt].ref_special_instruction = build2(", ",trim(od.oe_field_display_value,3))
    of 951916695.00:
      orders->orders[cnt].ref_service_desired = build2(", ",trim(od.oe_field_display_value,3))
    of 258409575.00:
      orders->orders[cnt].ref_to_prsnl = build2(" with ",trim(piece(trim(od.oe_field_display_value,3), ',', 2, ''), 3)," ",
      trim(piece(trim(od.oe_field_display_value,3), ',', 1, ''), 3))
      orders->orders[cnt].ref_to_prsnl_id = od.oe_field_value
    of 1593931077.00:
      orders->orders[cnt].ref_to_ph_fx = trim(od.oe_field_display_value,3)
      pos = findstring("F:",orders->orders[cnt].ref_to_ph_fx,1,1)
      if(pos> 0)
        orders->orders[cnt].ref_to_ph_fx = substring(1,pos-1,orders->orders[cnt].ref_to_ph_fx)
      endif
      orders->orders[cnt].ref_to_ph_fx = build2(" by calling ",trim(replace(orders->orders[cnt].ref_to_ph_fx,"P:",""),3))
    of 5103775435.00:
      orders->orders[cnt].ref_to_loc = build2(" with ",trim(od.oe_field_display_value,3))
    of 5103775435.00:
      orders->orders[cnt].ref_to_loc2 = build2(", ",trim(od.oe_field_display_value,3))
    of 951929101.00:
      orders->orders[cnt].ref_to_loc3 = build2(", ",trim(od.oe_field_display_value,3))
    of 6113731097.00:
      orders->orders[cnt].suggested_time_frame = build2(" Follow-Up In: ",trim(od.oe_field_display_value,3))
      if(od.oe_field_value = 6113542243.00 or od.oe_field_display_value ="Other - See Comments")


        orders->orders[cnt].comment_ind = 1
      endif
  endcase
with nocounter

if(size(orders->orders,5)> 0)
  select into "nl:"
  from (dummyt d with seq = value(size(orders->orders,5))),
    person_name pn
  plan d
    where orders->orders[d.seq].ref_to_prsnl_id > 0
  join pn
    where pn.person_id = orders->orders[d.seq].ref_to_prsnl_id
    and pn.end_effective_dt_tm > cnvtdatetime(sysdate)
    and pn.name_type_cd = 614387.00
    and pn.active_ind = 1
  order by d.seq;, cr.display_seq
  head d.seq
    if(trim(pn.name_middle_key) > " ")
      orders->orders[d.seq].ref_to_prsnl = build2("with ",trim(pn.name_first,3)," ",trim(pn.name_middle_key,3)," ",
      trim(pn.name_last,3))
    else
      orders->orders[d.seq].ref_to_prsnl = build2("with ",trim(pn.name_first,3)," ",trim(pn.name_last,3))
    endif
  with nocounter
;---------------------------------------------------------------------------------------------------------------------------------
;Get Order Comment
;---------------------------------------------------------------------------------------------------------------------------------
  select into "nl:"
      ord_cmt = substring(1, 5000, lt.long_text)
  from (dummyt d with seq = size(orders->orders, 5))
      ,order_comment oc
      ,long_text lt
  plan d
    where orders->orders[d.seq].order_id > 0
  join oc
    where oc.order_id = orders->orders[d.seq].order_id
    and oc.comment_type_cd = 66
  join lt
    where lt.long_text_id = oc.long_text_id
  order d.seq, oc.updt_dt_tm desc
  head d.seq
    orders->orders[d.seq].order_comment = trim(replace(ord_cmt, '\', '\\'), 3)
    call echo(orders->orders[d.seq].order_comment)
  with nocounter


  set rtf_out = build2(rh2bu,"Referrals to be Scheduled with: ")
  for(cnt = 1 to size(orders->orders,5))
    if(orders->orders[cnt].ref_to_loc ="" and trim(orders->orders[cnt].ref_to_loc2,3)> " ")
      set orders->orders[cnt].ref_to_loc2 = build2(", AT ", trim(orders->orders[cnt].ref_to_loc2,3))
    endif

    if(lb_cntrl = 1)
      set rtf_out = notrim(build2(rtf_out,wb,trim(orders->orders[cnt].order_name,3),":",wr))
    else
      set rtf_out = notrim(build2(rtf_out,reol,wb,trim(orders->orders[cnt].order_name,3),":",wr))
    endif

    if(trim(orders->orders[cnt].suggested_time_frame,3)> " " and orders->orders[cnt].comment_ind = 0)
        set rtf_out = notrim(build2(rtf_out," ",trim(orders->orders[cnt].suggested_time_frame,3)))
    endif

    if(trim(orders->orders[cnt].ref_to_prsnl,3)> " ")
      set rtf_out = notrim(build2(rtf_out," ",trim(orders->orders[cnt].ref_to_prsnl,3))); provider
    endif

    if(trim(orders->orders[cnt].ref_to_loc,3)> " ")
      set rtf_out = notrim(build2(rtf_out," ",trim(orders->orders[cnt].ref_to_loc,3))) ; Practice
    endif

    if(trim(orders->orders[cnt].ref_to_prsnl,3) = "" and trim(orders->orders[cnt].ref_to_loc,3) = "" and
      trim(orders->orders[cnt].ref_to_loc3,3)> " ")
      set rtf_out = notrim(build2(rtf_out," ",trim(orders->orders[cnt].ref_to_loc3,3))) ; Location Name
    endif
    if(trim(orders->orders[cnt].ref_to_ph_fx,3)> " ")
      set rtf_out = notrim(build2(rtf_out," ",trim(orders->orders[cnt].ref_to_ph_fx,3))) ; Phone
    endif

    if(trim(orders->orders[cnt].ref_service_desired,3)> " ")
      set rtf_out = notrim(build2(rtf_out," ",trim(orders->orders[cnt].ref_service_desired,3))) ; Service Desired
    endif

    if(trim(orders->orders[cnt].ref_special_instruction,3)> " ")
      set rtf_out = notrim(build2(rtf_out," ",trim(orders->orders[cnt].ref_special_instruction,3))) ; Special Instructions
    endif

    set lb_cntrl = 0

    if(trim(orders->orders[cnt].order_comment,3) > " ")
        if(orders->orders[cnt].comment_ind = 1 )
          set rtf_out = notrim(build2(rtf_out,", Follow-Up In: See Additional Information",reol))
        else
          set rtf_out = notrim(build2(rtf_out,reol))
        endif
        set rtf_out = notrim(build2(rtf_out,wb, bullet_start," ","Additional Information: ", reol, wr,
        trim(orders->orders[cnt].order_comment,3), bullet_end ))


        set lb_cntrl = 1
    endif


    if(findstring(",",trim(rtf_out,3),1,1) = textlen(trim(rtf_out,3)))
      set rtf_out = replace(rtf_out,",","",2)
    endif

  endfor
  set rtf_out= build2(rhead,rtf_out,rtfeof)
    call echo(rtf_out)
    set reply->text = rtf_out
else
    set reply->text = build2(rhead," ",rtfeof)
endif
#exitscript


call echorecord(orders)

set drec->status_data->status = "S"
set reply->status_data->status = "S"

;set _Memory_Reply_String = rtf_out

end
go
