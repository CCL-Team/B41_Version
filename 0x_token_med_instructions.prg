/*****************************************************************************

         Author:                 Kelly Hoagland
         Source file name:       0x_token_med_instructions.prg
         Object name:            0x_token_med_instructions
         Request #:

         Program purpose:   Token for medication instructions with grid

 ******************************************************************************/
  /*  ************************************************************************
     *                      GENERATED MODIFICATION CONTROL LOG              *
     ************************************************************************
     *                                                                      *
     *Mod Date     Engineer             Comment                             *
     *--- -------- -------------------- ----------------------------------- *
     *000 10/01/15 Kelly Hoagland       Initial Release                     *
     *001 08/31/2016  Swetha Srini		Object renamed from					*
     									mhgr_dc_med_instructions to 		*
     									0x_token_med_instructions			*
     *002 01/26/17 Kelly Hoagland       Fix issue with last_action_sequence *
     *003 02-27-2019 DMA112             Fix rounding issue
     *004 02/14/2024 MMM174             Fixing issue missing duration units
                                        (SCTASK0073204) (INC0518110)
     ************************************************************************
     ********************  END OF ALL MODCONTROL BLOCKS  ********************/

drop program 0x_token_med_instructions:dba go
create program 0x_token_med_instructions:dba
 /*
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Financial Number:" = ""

with OUTDEV, fin_nbr
 */

free record req_rec
record req_rec
( 1 script_name = vc
  1 encntr_id = f8
  1 person_id = f8
  1 tracking_id = f8
  1 tracking_group = f8
  1 prsnl_id = f8
  1 fontsize = vc
  1 fontfamily = vc)

;set req_rec->script_name = "0x_token_med_instructions"
declare fin_cd = f8 with public, constant(uar_get_code_by("MEANING", 319, "FIN NBR"))
declare LongText = vc with public, noconstant("")
declare csHeader = vc with private
declare pharmacy_cd = f8 with public, constant(uar_get_code_by("MEANING", 6000, "PHARMACY"))

set csHeader = "<html><body>"
set LongText = csHeader
set tab = "&nbsp;&nbsp;&nbsp;&nbsp;"

/*
select into "nl:"
from encntr_alias ea
, encounter e
plan ea where ea.alias = $fin_nbr
  and ea.encntr_alias_type_cd = fin_cd
  and ea.active_ind = 1
join e where e.encntr_id = ea.encntr_id
detail
  req_rec->encntr_id = e.encntr_id
  req_rec->person_id = e.person_id
with nocounter

if (curqual = 0)
  set LongText = "<html><body><p> No encounter found with that financial number. </p>"
  go to exit_script
endif
 */


set req_rec->encntr_id = request->encntr_id
set req_rec->person_id = request->person_id

; <PERSON_ID type="DOUBLE" value="16753890.000000"/>
; <TRACKING_ID type="DOUBLE" value="336860614.000000"/>
; <TRACKING_GROUP type="DOUBLE" value="0.000000"/>
; <PRSNL_ID type="DOUBLE" value="15210755.000000"/>
; <FONTSIZE type="STRING" length="6"><![CDATA[12.0pt]]></FONTSIZE>
; <FONTFAMILY type="STRING" length="21"><![CDATA[Times New Roman,serif]]></FONTFAMILY>
;</CCLREC>
;*/

free record info
record info
( 1 orders[*]
    2 order_id = f8
    2 encntr_id = f8
    2 med_rec_ind = i2
    2 medication = vc
    2 med_display = vc
    2 generic_name = vc
    2 brand_name = vc
    2 dose = vc
    2 volume_dose = vc
    2 strength_dose = f8
    2 strength_unit = f8
    2 med_dose = f8
    2 freq = vc
    2 instructions = vc
    2 note = vc
    2 comment = vc
    2 new_ind = i2
    2 new_cont = vc
    2 next_dose = vc
    2 pharmacy_id = vc
    2 pharmacy_name = vc
    2 disp_qty = vc
    2 refills = vc
    2 home_med_ind = i2
    2 indication = vc
    2 spec_inst = vc
    2 start_dt_tm = dq8
    2 stop_dt_tm = dq8
    2 stop_type_cd = f8
)

declare pass_field_in = f8 with public, noconstant(0.0)
declare num_tabs = f8 with public, noconstant(0.0)
declare strength_string = vc with public, noconstant("")
declare volume_string = vc with public, noconstant("")
declare dsValue = vc with public, noconstant("")
declare temp_string = vc with public, noconstant("")
declare temp_durr = vc with public, noconstant("")
declare dur_unit = vc with public, noconstant("")
declare unit_disp = vc with public, noconstant("")
declare x = i4 with public, noconstant(0)
declare pharm_cd = f8 with public, constant(uar_get_code_by("MEANING", 6000, "PHARMACY"))
declare ordered_cd = f8 with public, constant(uar_get_code_by("MEANING", 6004, "ORDERED"))
declare brand_name_cd = f8 with public, constant(uar_get_code_by("MEANING", 11000, "BRAND_NAME"))
declare generic_name_cd = f8 with public, constant(uar_get_code_by("MEANING", 11000, "GENERIC_NAME"))
declare comment_cd = f8 with public, constant(uar_get_code_by("MEANING", 14, "ORD COMMENT"))
declare primary_cd = f8 with public, constant(uar_get_code_by("MEANING", 6011, "PRIMARY"))
declare usa_cd = f8 with public, constant(uar_get_code_by("MEANING", 281, "US"))

;check if reconciliation has been done
select into "nl:"
from order_recon o
plan o where o.encntr_id = req_rec->encntr_id
  and o.recon_type_flag = 3 ;discharge recon
with nocounter

if (curqual = 0)
  set LongText = "<html><body><p> No changes to medication instructions documented. </p>"
  go to exit_script
endif

select into "nl:"
from orders o
, order_ingredient oi
;, order_catalog_item_r oir
;, object_identifier_index oii
, order_recon_detail ord
, order_catalog_synonym ocs
plan o where o.person_id = req_rec->person_id
  and o.catalog_type_cd = pharm_cd
  and o.order_status_cd = ordered_cd
  and o.orig_ord_as_flag in (1, 2) ;disch meds and home meds
join oi where oi.order_id = o.order_id
;002  and oi.action_sequence = o.last_action_sequence
;join oir where oir.catalog_cd = o.catalog_cd
;join oii where oii.object_id = oir.item_id
;  and oii.identifier_type_cd in (brand_name_cd, generic_name_cd)
;  and oii.active_ind = 1
join ocs where ocs.catalog_cd = o.catalog_cd
  and ocs.active_ind = 1
  and ocs.mnemonic_type_cd = primary_cd
join ord where ord.order_nbr = outerjoin(o.order_id)
;order by uar_get_code_display(o.catalog_cd), o.order_id, oii.identifier_type_cd, ord.updt_dt_tm desc
order by cnvtupper(uar_get_code_display(o.catalog_cd)), o.order_id, ord.updt_dt_tm desc
, oi.action_sequence desc ;002

head report
  x = 0
%i cust_script:mhgr_dc_parse_zeroes.inc

head o.order_id
  x = x + 1
  if (mod(x, 10) = 1)
    stat = alterlist(info->orders, x + 9)
  endif
  info->orders[x].medication = o.ordered_as_mnemonic
  info->orders[x].strength_dose = oi.strength
  info->orders[x].strength_unit = oi.strength_unit
  unit_loc = findstring(trim(uar_get_code_display(oi.strength_unit)), o.ordered_as_mnemonic, 1, 0)
  space_loc = findstring(" ", trim(substring(1, unit_loc-1, o.ordered_as_mnemonic)), 1, 1)
  info->orders[x].med_dose = cnvtreal(substring(space_loc, (unit_loc-space_loc), o.ordered_as_mnemonic))
  pass_field_in = oi.strength
  parse_zeroes
  strength_string = dsValue
  pass_field_in = oi.volume
  parse_zeroes
  volume_string = dsValue
  if (oi.volume > 1)
    case (cnvtlower(uar_get_code_display(oi.volume_unit)))
       of "*cap*":  unit_disp = "capsules"
       of "*tab*":  unit_disp = "tablets"
       else unit_disp = uar_get_code_display(oi.volume_unit)
    endcase
  else
    case (cnvtlower(uar_get_code_display(oi.volume_unit)))
       of "*cap*":  unit_disp = "capsule"
       of "*tab*":  unit_disp = "tablet"
       else unit_disp = uar_get_code_display(oi.volume_unit)
    endcase
  endif
  if (oi.volume = 0.0 and oi.strength != 0)
    info->orders[x].dose = concat(trim(strength_string), " "
                              , trim(uar_get_code_display(oi.strength_unit)))
  elseif ((oi.volume != 0.0 and oi.strength = 0) or (oi.volume = 1 and oi.strength != 0))
    info->orders[x].dose = concat(trim(volume_string), " ", unit_disp)
  elseif (oi.volume != 0 and oi.strength != 0)
    info->orders[x].dose = concat(trim(volume_string), " ", unit_disp
                           , " (equals ", trim(strength_string), " "
                           , trim(uar_get_code_display(oi.strength_unit)), ")")
  endif
  temp_string = replace(cnvtlower(uar_get_code_description(oi.volume_unit)), "(s)", "")
  if (volume_string = "n/a")
    info->orders[x].volume_dose = ""
  elseif (oi.volume <= 1)
    info->orders[x].volume_dose = concat(trim(volume_string), " ", trim(temp_string))
  else
    info->orders[x].volume_dose = concat(trim(volume_string), " ", trim(temp_string), "s")
  endif
  ;info->orders[x].brand_name = oii.value
  info->orders[x].order_id = o.order_id
  info->orders[x].encntr_id = o.encntr_id
  info->orders[x].home_med_ind = o.orig_ord_as_flag
  if (ord.continue_order_ind = 1 and o.encntr_id != req_rec->encntr_id)
    info->orders[x].new_cont = "Continue"
  elseif (ord.continue_order_ind = 3 or (ord.continue_order_ind = 1 and o.encntr_id = req_rec->encntr_id))
    info->orders[x].new_cont = "New"
    info->orders[x].new_ind = 1
  else
    info->orders[x].new_cont = cnvtstring(ord.continue_order_ind)
  endif
  info->orders[x].note = ord.recon_note_txt
;  info->orders[x].next_dose = uar_get_code_display(o.order_status_cd)
;  info->orders[x].new_pharmacy = o.order_detail_display_line

detail
  info->orders[x].generic_name = ocs.mnemonic
;  case (oii.identifier_type_cd)
;    of brand_name_cd: info->orders[x].brand_name = oii.value
;    of generic_name_cd: info->orders[x].generic_name = ocs.mnemonic ;oii.value
;  endcase

foot o.order_id
  b_ind = findstring(info->orders[x].brand_name, info->orders[x].medication)
  g_ind = findstring(info->orders[x].generic_name, info->orders[x].medication)
  place = findstring(" ", info->orders[x].medication)
  len = textlen(info->orders[x].medication)
;  if (info->orders[x].brand_name = info->orders[x].medication)
    info->orders[x].med_display = concat(trim(info->orders[x].generic_name), " ("
                                  , info->orders[x].medication, ")")
;  else
;    info->orders[x].med_display = concat(trim(info->orders[x].generic_name), " ("
;                                  , info->orders[x].brand_name
;                                  , substring(place, len, info->orders[x].medication), ")")
;  else
if (g_ind != 0)
;    place = findstring(" ", info->orders[x].medication)
;    len = textlen(info->orders[x].medication)
    info->orders[x].med_display = info->orders[x].medication
endif

foot report
  stat = alterlist(info->orders,x)

with nocounter

;; begin 003
DECLARE var_strength_dose = vc
DECLARE int_len_strength_dose = i4
DECLARE my_int = i4
;; end 003

declare num = i4 with public
select into "nl:"
  sort_order = if (od.oe_field_meaning = "DRUGFORM")
                 1
               elseif (od.oe_field_meaning = "RXROUTE")
                 2
               elseif (od.oe_field_meaning = "FREQ")
                 3
               elseif (od.oe_field_meaning = "PRNINSTRUCTIONS")
                 4
               elseif (od.oe_field_meaning = "DURATION")
                 5
               elseif (od.oe_field_meaning = "DURATIONUNIT")      ;004
                 6
               elseif (od.oe_field_meaning = "REQROUTINGTYPE")
                 7
               elseif (od.oe_field_meaning = "DONTPRINTRXREASON")
                 8
               elseif (od.oe_field_meaning = "FREETXTDOSE")       ;004
                 9
               else
                 10
               endif
from order_detail od
plan od where expand(num, 1, size(info->orders, 5), od.order_id, info->orders[num].order_id)
  and od.oe_field_meaning in ("DRUGFORM", "RXROUTE", "FREQ", "PRNINSTRUCTIONS", "DURATION", "REQROUTINGTYPE", "DONTPRINTRXREASON"
                             
                             , "DURATIONUNIT", "FREETXTDOSE"
                             
                             ,"ROUTINGPHARMACYID", "ROUTINGPHARMACYNAME"
                             , "DISPENSEQTY", "DISPENSEQTYUNIT", "TOTALREFILLS", "INDICATION", "REQSTARTDTTM"
                             , "STOPDTTM", "STOPTYPE")
order by od.order_id, sort_order, od.action_sequence desc, od.detail_sequence

head report
%i cust_script:mhgr_dc_parse_zeroes.inc

head od.order_id
  x = locateval(num, 1, size(info->orders, 5), od.order_id, info->orders[num].order_id)
  temp_durr = ""
  call echo(od.order_id)
  temp_val = 0.0

head sort_order
  call echo(build(od.oe_field_meaning, ": ", od.oe_field_display_value))
  call echo(info->orders[x].instructions)
  temp_string = ""
  if (sort_order > 1 and textlen(trim(info->orders[x].instructions)) = 0)
    if (textlen(trim(info->orders[x].volume_dose)) = 0)
      info->orders[x].instructions = info->orders[x].dose
    else
      info->orders[x].instructions = info->orders[x].volume_dose
    endif
    call echo(build("updated:", info->orders[x].instructions))
  endif
  case (od.oe_field_meaning)
    of "FREETXTDOSE" : info->orders[x].dose = od.oe_field_display_value
                       info->orders[x].instructions = concat(info->orders[x].dose, " ", info->orders[x].instructions)
    of "DRUGFORM": 	if (cnvtlower(trim(uar_get_code_description(od.oe_field_value))) = "oral suspension")
                      temp_string = info->orders[x].dose
                  	elseif (cnvtlower(trim(uar_get_code_description(od.oe_field_value))) = "injection")
                      temp_string = concat(info->orders[x].dose, " inject")
                  	elseif ((cnvtlower(trim(uar_get_code_display(od.oe_field_value))) in ("*cap*", "*tab*"))
                  	   and (info->orders[x].dose != "*equals*")
                  	   and (info->orders[x].med_dose > 0))
                  	  num_tabs = info->orders[x].strength_dose/info->orders[x].med_dose
                  	  pass_field_in = num_tabs
                      parse_zeroes
                      if (num_tabs = 1)
                        temp_string = concat(info->orders[x].dose)
                      else
                        if (cnvtlower(trim(uar_get_code_display(od.oe_field_value))) = "*cap*")
                          if (cnvtreal(dsValue) <= 1)
                            temp_string = concat(trim(dsValue), " capsule = ", info->orders[x].dose)
                          else
                            temp_string = concat(trim(dsValue), " capsules = ", info->orders[x].dose)
                          endif
                        else
                          if (cnvtreal(dsValue) <= 1)
                            temp_string = concat(trim(dsValue), " tablet = ", info->orders[x].dose)
                          else
                            temp_string = concat(trim(dsValue), " tablets = ", info->orders[x].dose)
                          endif
                        endif
                      endif
                  	elseif (info->orders[x].dose = "*equals*")
                      temp_string = info->orders[x].dose
                    else
                      temp_string = info->orders[x].volume_dose
                      if (info->orders[x].med_dose = 0.0 and info->orders[x].med_display != "*(*"
                      and info->orders[x].strength_dose != 0)
						; begin 003
                      	done = "FALSE"
                      	var_strength_dose = cnvtstring(info->orders[x].strength_dose,11,4)
                      	int_len_strength_dose = TEXTLEN(var_strength_dose)
                      	WHILE (done = "FALSE")
                      		my_int = FINDSTRING("0",var_strength_dose,1,1)
                      		IF ((my_int != 0) AND (int_len_strength_dose = my_int))
                      			var_strength_dose = SUBSTRING(1,(int_len_strength_dose - 1), var_strength_dose)
                      		ELSE
                      			done = "TRUE"
                      			int_len_strength_dose = 0
                      			my_int = 0
                      		ENDIF
                      		int_len_strength_dose = TEXTLEN(var_strength_dose)
                      	ENDWHILE
                        ; end 003
                        info->orders[x].med_display = concat(info->orders[x].med_display, " " ;, " ("
                                                             ;,trim(info->orders[x].med_display), " "
                                                             ;,cnvtstring(info->orders[x].strength_dose), " "			;003
                                                             ,var_strength_dose, " "									;003
                                                             ,trim(uar_get_code_display(info->orders[x].strength_unit))) ;, ")")
                      endif
                   	endif
    of "RXROUTE":  	if (cnvtlower(uar_get_code_description(od.oe_field_value)) = "intramuscular")
                      temp_string = concat(info->orders[x].dose, " ", cnvtlower(uar_get_code_description(od.oe_field_value)))
                    else
                      temp_string = cnvtlower(uar_get_code_description(od.oe_field_value))
                    endif
    of "FREQ":  	temp_string = cnvtlower(uar_get_code_description(od.oe_field_value))
                    info->orders[x].freq = od.oe_field_display_value
    of "PRNINSTRUCTIONS":	if (cnvtupper(od.oe_field_display_value) = "AS NEEDED FOR*")
                              temp_string = od.oe_field_display_value
                            else
                              temp_string = concat("as needed for ", od.oe_field_display_value)
                            endif
    of "DURATION":	temp_string = concat("for ", od.oe_field_display_value)
                    temp_durr = concat("for ", od.oe_field_display_value)
                    temp_val = cnvtreal(od.oe_field_display_value)
    of "DURATIONUNIT":	dur_unit = replace(od.oe_field_display_value, "(s)", "")
                        if (temp_val > 1)
                          temp_string = concat(cnvtlower(dur_unit), "s")
                        else
                          temp_string = cnvtlower(dur_unit)
                        endif
                        temp_durr = concat(temp_durr, " ", trim(temp_string))
    of "REQROUTINGTYPE":  if (od.oe_field_display_value != "Do Not Route")
                            info->orders[x].pharmacy_name = replace(od.oe_field_display_value, "(Rx)", "")
                          endif
                          info->orders[x].pharmacy_name = replace(info->orders[x].pharmacy_name, "Print Requisition", "Printed")
                          info->orders[x].pharmacy_name = replace(info->orders[x].pharmacy_name, "Route to Pharmacy Electronically"
                                                                                               , "Electronically sent to")
    of "DONTPRINTRXREASON": if (textlen(trim(info->orders[x].pharmacy_name)) = 0)
                              info->orders[x].pharmacy_name = replace(od.oe_field_display_value, "(Rx)", "")
                            elseif (textlen(trim(od.oe_field_display_value)) != 0)
                              info->orders[x].pharmacy_name = concat(info->orders[x].pharmacy_name, ": "
                                                            , replace(od.oe_field_display_value, "(Rx)", ""))
                            endif
                            info->orders[x].pharmacy_name = replace(info->orders[x].pharmacy_name
                                                            , "other reason", "~") ;"not sent, not printed")
                            info->orders[x].pharmacy_name = replace(info->orders[x].pharmacy_name, "Print Requisition", "Printed")
  endcase
  call echo(temp_string)
  info->orders[x].instructions = concat(trim(info->orders[x].instructions), " ", trim(temp_string))

detail
;call echo(build(od.oe_field_meaning, ":", od.oe_field_display_value))
  case (od.oe_field_meaning)
    of "ROUTINGPHARMACYID":   info->orders[x].pharmacy_id = od.oe_field_display_value
    of "ROUTINGPHARMACYNAME": if (info->orders[x].pharmacy_name != "Printed")
                                info->orders[x].pharmacy_name = concat(trim(info->orders[x].pharmacy_name), " "
                                                               , od.oe_field_display_value)
                              endif
    of "DISPENSEQTY":  info->orders[x].disp_qty = od.oe_field_display_value
    of "DISPENSEQTYUNIT":  info->orders[x].disp_qty = concat(trim(info->orders[x].disp_qty), " ", trim(od.oe_field_display_value))
    of "TOTALREFILLS":  info->orders[x].refills = od.oe_field_display_value
    of "INDICATION": info->orders[x].indication = od.oe_field_display_value
                     if (od.oe_field_display_value != "Other")
                     info->orders[x].instructions = concat(trim(info->orders[x].instructions), ". Prescribed for the treatment of "
                                                    , trim(od.oe_field_display_value))
                     endif
    of "REQSTARTDTTM":  info->orders[x].start_dt_tm = od.oe_field_dt_tm_value
    of "STOPDTTM":  info->orders[x].stop_dt_tm = od.oe_field_dt_tm_value
    of "STOPTYPE":  info->orders[x].stop_type_cd = od.oe_field_value
if(od.oe_field_value != 2337)
        info->orders[x].instructions = replace(info->orders[x].instructions, temp_durr,"")
      endif
  endcase

with nocounter

select into "nl:"
from order_entry_fields oef
, order_detail od
plan oef where oef.description = "Special Instructions*"
join od where expand(num, 1, size(info->orders, 5), od.order_id, info->orders[num].order_id)
  and od.oe_field_id = oef.oe_field_id
order by od.order_id, od.action_sequence, od.detail_sequence

head od.order_id
  x = locateval(num, 1, size(info->orders, 5), od.order_id, info->orders[num].order_id)

head od.action_sequence
  info->orders[x].spec_inst = ""

detail
  if (textlen(trim(info->orders[x].spec_inst)) = 0)
    info->orders[x].spec_inst = trim(od.oe_field_display_value)
  else
    info->orders[x].spec_inst = concat(trim(info->orders[x].spec_inst), ", ", trim(od.oe_field_display_value))
  endif
with nocounter

select into "nl:"
from order_entry_fields oef
, order_detail od
plan oef where oef.description in ("Freetext Indication", "Indications")
  and oef.catalog_type_cd = pharmacy_cd
join od where expand(num, 1, size(info->orders, 5), od.order_id, info->orders[num].order_id)
  and od.oe_field_id = oef.oe_field_id
order by od.order_id, od.action_sequence desc

head od.order_id
  x = locateval(num, 1, size(info->orders, 5), od.order_id, info->orders[num].order_id)
  if (textlen(trim(info->orders[x].indication)) = 0)
    if (od.oe_field_value = 0)
      info->orders[x].instructions = concat(trim(info->orders[x].instructions), ". Prescribed for the treatment of "
                                        , trim(od.oe_field_display_value))
    else
      info->orders[x].instructions = concat(trim(info->orders[x].instructions), ". Prescribed for the treatment of "
                                        , trim(uar_get_code_display(od.oe_field_value)))
    endif
  else
    if (od.oe_field_value = 0)
      info->orders[x].instructions = concat(trim(info->orders[x].instructions), " and "
                                        , trim(od.oe_field_display_value))
    else
      info->orders[x].instructions = concat(trim(info->orders[x].instructions), " and "
                                        , trim(uar_get_code_display(od.oe_field_value)))
    endif
  endif
  ;call echo(build(od.order_id, ":", od.oe_field_value, "-", od.oe_field_display_value))

detail
  if (info->orders[x].instructions = "*Other*")
    info->orders[x].instructions = replace(info->orders[x].instructions, "Other", od.oe_field_display_value)
  endif
with nocounter

select into "nl:"
from order_comment oc
, long_text lt
plan oc where expand(num, 1, size(info->orders, 5), oc.order_id, info->orders[num].order_id)
  and oc.comment_type_cd = comment_cd
join lt where lt.long_text_id = oc.long_text_id
order by oc.order_id, oc.action_sequence desc

head oc.order_id
  x = locateval(num, 1, size(info->orders, 5), oc.order_id, info->orders[num].order_id)
  info->orders[x].comment = replace(trim(lt.long_text), char(10), " <br>")

with nocounter

;call trace(15)
/* Call server to get pharmacy address/phone *
call echo("Call server for addresses")
;Include the CRMRTL UARS
execute crmrtl
execute srvrtl

;CRM VARIABLES
declare hApp       = i4 with protect, noconstant (0)
declare hTask      = i4 with protect, noconstant (0)
declare hStep      = i4 with protect, noconstant (0)
declare hReq       = i4 with protect, noconstant (0)
declare hItem      = i4 with protect, noconstant (0)
declare crmStatus  = i2 with protect, noconstant (0)

;STATUS VARIABLES
declare srvStat    = i4 with protect, noconstant (0)

;CREATE CRM HANDLES
set crmStatus = uar_CrmBeginApp(600005, hApp)
if(crmStatus != 0)
  call echo("Error in Begin App for application 600005.")
  call echo(build("Crm Status: ", crmStatus))
  call echo("Cannot call Server. Exiting Script.")
  go to exit_script
endif

set crmStatus = uar_CrmBeginTask(hApp, 500195, hTask)
if(crmStatus != 0)
  call echo("Error in Begin Task for task 500195.")
  call echo(build("Crm Status: ", crmStatus))
  call echo("Cannot call task for Server. Exiting Script.")
  call uar_CrmEndApp(hApp)
  go to exit_script
endif

set crmStatus = uar_CrmBeginReq(hTask, "", 3202501, hStep)
if(crmStatus != 0)
  call echo("Error in Begin Request for request 3202501.")
  call echo(build("Crm Status: ", crmStatus))
  go to exit_script
else
  set hReq = uar_CrmGetRequest(hStep)
  for (a = 1 to size(info->orders, 5))
    if (info->orders[a].pharmacy_id != NULL)
      set hItem = uar_SrvAddItem(hReq, "ids")
      set srvStat = uar_SrvSetString(hItem, "id", info->orders[a].pharmacy_id)
    endif
  endfor
endif
call uar_oen_dump_object(hReq)

  /*
set stat = alterlist(info->pharm, size(request->ids, 5))
for (x = 1 to size(request->ids, 5))
  set info->pharm[x].addr1 = reply->pharmacies[x].primary_business_address.street_address_lines[1].street_address_line
  set info->pharm[x].addr2 = reply->pharmacies[x].primary_business_address.street_address_lines[1].street_address_line
  set info->pharm[x].city = reply->pharmacies[x].primary_business_address.city
  set info->pharm[x].state = reply->pharmacies[x].primary_business_address.state
  set info->pharm[x].zip = reply->pharmacies[x].primary_business_address.postal_code
  set info->pharm[x].phone = reply->pharmacies[x].primary_business_telephone.value
endfor */
;DESTROY CRM HANDLES
;set crmStatus = uar_CrmEndTask(hTask)
;set crmStatus = uar_CrmEndApp(hApp)



/* TDBEXECUTE(<appid>,<taskid>,<reqid>,<request_from_type>,<request_from>,<reply_to_type>,<reply_to>) */
free record requestin
record requestin
( 1 ids[*]
    2 id = vc)
free record replyout
record replyout
( 1 pharmacies[*]
    2 id = vc
    2 version_dt_tm = dq8
    2 pharmacy_name = vc
    2 pharmacy_number = vc
    2 active_begin_dt_tm = dq8
    2 active_end_dt_tm = dq8
    2 pharmacy_contributions[*]
      3 contributor_system_cd = f8
      3 version_dt_tm = dq8
      3 contribution_id = vc
      3 pharmacy_name = vc
      3 pharmacy_number = vc
      3 active_begin_dt_tm = dq8
      3 active_end_dt_tm = dq8
      3 addresses[*]
        4 type_cd = f8
        4 type_seq = i2
        4 street_address_lines[*]
          5 street_address_line = vc
        4 city = vc
        4 state = vc
        4 postal_code = vc
        4 country = vc
        4 cross_street = vc
      3 telecom_addresses[*]
        4 type_cd = f8
        4 type_seq = i2
        4 contact_method_cd = f8
        4 value = vc
        4 extension = vc
      3 service_level = vc
      3 partner_account = vc
      3 service_levels
        4 new_rx_ind = i2
        4 ref_req_ind = i2
        4 epcs_ind = i2
      3 specialties
        4 mail_order_ind = i2
        4 retail_ind = i2
        4 specialty_ind = i2
        4 twenty_four_hour_ind = i2
        4 long_term_ind = i2
    2 primary_business_address
      3 type_cd = f8
      3 type_seq = i2
      3 street_address_lines[*]
        4 street_address_line = vc
      3 city = vc
      3 state = vc
      3 postal_code = vc
      3 country = vc
      3 cross_street = vc
    2 primary_business_telephone
      3 type_cd = f8
      3 type_seq = i2
      3 contact_method_cd = f8
      3 value = vc
      3 extension = vc
    2 primary_business_fax
      3 type_cd = f8
      3 type_seq = i2
      3 contact_method_cd = f8
      3 value = vc
      3 extension = vc
    2 primary_business_email
      3 type_cd = f8
      3 type_seq = i2
      3 contact_method_cd = f8
      3 value = vc
      3 extension = vc
  1 status_data
    2 status = c1
    2 SubEventStatus[*]
      3 OperationName = c25
      3 OperationStatus = c1
      3 TargetObjectName = c25
      3 TargetObjectVale = vc
)

;declare pharm_id = vc with public, noconstant(fillstring(100, " "))
select into "nl:"
  ;pharm_id = info->orders[d.seq].pharmacy_id
from (dummyt d with seq = size(info->orders, 5))
plan d where info->orders[d.seq].pharmacy_id != NULL
 and info->orders[d.seq].pharmacy_name != "Printed"
order by d.seq

head report
  x = 0

head d.seq
  if (info->orders[d.seq].new_ind = 1)
    x = x + 1
    if (mod(x, 10) = 1)
      stat = alterlist(requestin->ids, x + 9)
    endif
    requestin->ids[x].id = info->orders[d.seq].pharmacy_id
  endif

foot report
  stat = alterlist(requestin->ids, x)

with nocounter
call echorecord(requestin)

set stat = tdbexecute(600005,500195,3202501,"REC",requestin,"REC",replyout)
call echo(build("tdbexecute=",stat))
call echorecord(replyout)

call echoxml(req_rec, "kh_info_req.dat")
call echoxml(info, "kh_info.dat")
call echorecord(info)


;now put the info into a table to be viewed.
/*declare LongText = vc
declare csHeader = vc
declare csBTableRow = vc
declare csETableRow = vc
set csHeader = concat("<html><body><table><tr>")
/*<table border=0 cellspacing=0 cellpadding=0><tr>",
              "<td width=200 valign=top><p><b>",
             "<span style='font-size:8.0pt;font-family:Arial'>Medication</span></b></p></td>",
              "<td width=220 valign=top><p><b>",
             "<span style='font-size:8.0pt;font-family:Arial'>Instructions</span></b></p></td>",
             ; "<td width=60 valign=top><p><b>",
             ;"<span style='font-size:8.0pt;font-family:Arial'>New or Continued</span></b></p></td>",
              "<td width=50 valign=top><p><b>",
             "<span style='font-size:8.0pt;font-family:Arial'>Dispense Qty</span></b></p></td>",
              "<td width=50 valign=top><p><b>",
             "<span style='font-size:8.0pt;font-family:Arial'>Refills</span></b></p></td>",
              "<td width=50 valign=top><p><b>",
             "<span style='font-size:8.0pt;font-family:Arial'>Take Next Dose</span></b></p></td>",
              "<td width=125 valign=top><p><b>",
             "<span style='font-size:8.0pt;font-family:Arial'>New Prescription Location</span></b></p></td></tr>")*;/


set csBTableRow = "<td><p><span style='font-size:10.0pt;font-family:Times New Roman,serif'>"
set csETableRow = "</span></p></td></tr>"
set LongText = concat(csHeader, csBTableRow)
for (iOrder = 1 to size(info->orders,5))
;  set LongText = concat(LongText, "<tr>")
;  if (info->orders[iOrder].new_cont = "New")
;    set LongText = concat(LongText, "<b>*", info->orders[iOrder].med_display, "</b>")
;  else
    set LongText = concat(LongText, "<b>", info->orders[iOrder].med_display, "</b>")
;  endif
  ;set LongText = concat(LongText, csBTableRow, info->orders[iOrder].dose, csETableRow)
  set LongText = concat(LongText, " ", info->orders[iOrder].instructions)
;  if (textlen(info->orders[iOrder].disp_qty) != 0)
;    set LongText = concat(LongText, ", Qty: ", info->orders[iOrder].disp_qty)
;  endif
  if (textlen(info->orders[iOrder].refills) != 0)
    set LongText = concat(LongText, ", Refills: ", info->orders[iOrder].refills)
  endif
  if (textlen(info->orders[iOrder].spec_inst) != 0)
    set LongText = concat(LongText, "  <br>  Special Instructions: ", info->orders[iOrder].spec_inst)
  endif
  if (textlen(info->orders[iOrder].comment) != 0)
    set LongText = concat(LongText, "  <br>  Order Comment: ", info->orders[iOrder].comment)
  endif
  if (textlen(info->orders[iOrder].note) != 0)
;    set LongText = concat(LongText, csETableRow)
;  else
    set LongText = concat(LongText, "  <br>  Notes for Patient: ", info->orders[iOrder].note)
;                       ,csETableRow)
  endif
  ;set LongText = concat(LongText, csBTableRow, info->orders[iOrder].new_cont, csETableRow)
;  set LongText = concat(LongText, csBTableRow, info->orders[iOrder].disp_qty, csETableRow)
;  set LongText = concat(LongText, csBTableRow, info->orders[iOrder].refills, csETableRow)
;  set LongText = concat(LongText, csBTableRow, info->orders[iOrder].next_dose, csETableRow)
  if (info->orders[iOrder].encntr_id = request->encntr_id and textlen(trim(info->orders[iOrder].pharmacy_name)) != 0)
    set LongText = concat(LongText, "<br> New Prescription Location: ", info->orders[iOrder].pharmacy_name)
  endif
  set LongText = concat(LongText, "<br>Take Next Dose:__________________ <br><br>")
endfor
;set LongText = concat(LongText, "<br><br><b>* = New Medication</b>")
;set LongText = concat(LongText, "</font></body></html>")
set LongText = concat(LongText, csETableRow, "</table></body></html>")
call echo(LongText)
*/

declare csTableHead = vc
declare csBTableRow = vc
declare csETableRow = vc
declare row_ind = i2 with public, noconstant(0)
declare row_cnt = i2 with public, noconstant(0)
declare prev_order_ind = i2 with public, noconstant(0)
set csTableHead = concat("<table><tr><table border=0 cellspacing=0 cellpadding=0><tr>",
              "<td width=40 valign=top><p><b></td>",
              "<td width=500 valign=top><p><b>",
              "</b></p></td></tr>")


set csBTableRow = "<td><p><span style='font-size:10.0pt;font-family:Times New Roman,serif'>"
set csETableRow = "</td></tr>"


if (size(info->orders, 5) = 0)
  set LongText = concat(LongText, "<p> No medications documented. </p>")
else
for (iOrder = 1 to size(info->orders,5))
  set row_ind = 0
  set row_cnt = 0
  set prev_order_ind = 0
  if (iOrder > 1)
    set LongText = concat(LongText, "<span style='font-size:6.0pt;font-family:Times New Roman,serif'><br>")
  endif
  set LongText = concat(LongText, "<span style='font-size:12.0pt;font-family:Times New Roman,serif'>")
  set LongText = concat(LongText, "<b>", info->orders[iOrder].med_display, "</b>", "<br>")
  ;set LongText = concat(LongText, "<table><tr><td width=20 valign=top><p></td><td width=620 valign=top>")
  if ((info->orders[iOrder].dose = NULL or info->orders[iOrder].freq = NULL) and
      (textlen(trim(info->orders[iOrder].pharmacy_name)) = 0)) ;is not a new prescription
    set LongText = concat(LongText,"Directions:  Use as previously directed by your prescribing physician")
    set prev_order_ind = 1
    set row_cnt = row_cnt + 1
  elseif (textlen(trim(info->orders[iOrder].instructions)) != 0)
    set LongText = concat(LongText,"Directions:", info->orders[iOrder].instructions)
    set row_cnt = row_cnt + 1
  endif
  if (row_ind < row_cnt)
    set LongText = concat(LongText, "<br>")
    set row_ind = row_cnt
  endif
  if (textlen(info->orders[iOrder].spec_inst) != 0 and prev_order_ind = 0)
    set LongText = concat(LongText, "  Special Instructions: ", info->orders[iOrder].spec_inst)
    set row_cnt = row_cnt + 1
  endif
  if (row_ind < row_cnt)
    set LongText = concat(LongText, "<br>")
    set row_ind = row_cnt
  endif
  if (textlen(info->orders[iOrder].comment) != 0 and prev_order_ind = 0)
    set LongText = concat(LongText, "Order Comment: ", info->orders[iOrder].comment)
    set row_cnt = row_cnt + 1
  endif
  if (row_ind < row_cnt)
    set LongText = concat(LongText, "<br>")
    set row_ind = row_cnt
  endif
  if (textlen(info->orders[iOrder].note) != 0 and prev_order_ind = 0)
    set LongText = concat(LongText, "  Notes for Patient: ", info->orders[iOrder].note)
    set row_cnt = row_cnt + 1
  endif
  if (row_ind < row_cnt)
    set LongText = concat(LongText, "<br>")
    set row_ind = row_cnt
  endif
  if (cnvtdatetime(info->orders[iOrder].start_dt_tm) > sysdate and prev_order_ind = 0)
    set LongText = concat(LongText, "  Start Date/Time: "
               , format(cnvtdatetime(info->orders[iOrder].start_dt_tm), "MM/DD/YYYY HH:MM;;Q"))
    set row_cnt = row_cnt + 1
  endif
;  if (cnvtdatetime(info->orders[iOrder].stop_dt_tm) > sysdate and uar_get_code_meaning(info->orders[iOrder].stop_type) != "SOFT")
;    set LongText = concat(LongText, "<br>", tab, "  Stop Date/Time: "
;               , format(cnvtdatetime(info->orders[iOrder].stop_dt_tm), "MM/DD/YYYY HH:MM;;Q"))
;  endif
  if (row_ind < row_cnt)
    set LongText = concat(LongText, "<br>")
    set row_ind = row_cnt
  endif
  if (info->orders[iOrder].encntr_id = req_rec->encntr_id and textlen(trim(info->orders[iOrder].pharmacy_name)) != 0
   and prev_order_ind = 0)
    set LongText = concat(LongText, " *New Prescription* ")
    if (info->orders[iOrder].pharmacy_name != "~")
      set LongText = concat(LongText, ": ", info->orders[iOrder].pharmacy_name)
      for (pha = 1 to size(replyout->pharmacies, 5))
      call echo(build(info->orders[iOrder].pharmacy_id, " = ", replyout->pharmacies[pha].id))
        if (info->orders[iOrder].pharmacy_id = replyout->pharmacies[pha].id)
          set LongText = concat(LongText, "<sup><i> ", cnvtstring(pha), "</i></sup>")
        endif
      endfor
    endif
    set LongText = concat(LongText, " || ")
    if (info->orders[iOrder].encntr_id = req_rec->encntr_id and textlen(info->orders[iOrder].refills) != 0
     and prev_order_ind = 0)
      set LongText = concat(LongText, " Refills: ", info->orders[iOrder].refills)
      set row_cnt = row_cnt + 1
    endif
  endif
  if (row_ind < row_cnt)
    set LongText = concat(LongText, "<br>")
    set row_ind = row_cnt
  endif
;  set LongText = concat(LongText, "</td><td width=250 valign=top>")
  set LongText = concat(LongText, " Take Next Dose:______ ", "<br>")  ; </span></td></tr></table>")
endfor
if (size(replyout->pharmacies, 5) > 0)
  set LongText = concat(LongText,
  "_______________________________________________________________________________________")
for (pha = 1 to size(replyout->pharmacies, 5))
    set LongText = concat(LongText, "<br><i><sup>", cnvtstring(pha), "</sup> ", replyout->pharmacies[pha].pharmacy_name)
    for (a = 1 to size(replyout->pharmacies[pha].primary_business_address.street_address_lines, 5))
      set LongText = concat(LongText, ": ",
                   replyout->pharmacies[pha].primary_business_address.street_address_lines[a].street_address_line)
    endfor
    set LongText = concat(LongText, ", ", replyout->pharmacies[pha].primary_business_address.city, ", "
                      , replyout->pharmacies[pha].primary_business_address.state)
    if (textlen(trim(replyout->pharmacies[pha].primary_business_address.postal_code)) = 9)
      set LongText = concat(LongText, "  ", format(replyout->pharmacies[pha].primary_business_address.postal_code, "#####-####"))
    elseif (textlen(trim(replyout->pharmacies[pha].primary_business_address.postal_code)) = 5)
      set LongText = concat(LongText, "  ", format(replyout->pharmacies[pha].primary_business_address.postal_code, "#####"))
    else
      set LongText = concat(LongText, "  ", replyout->pharmacies[pha].primary_business_address.postal_code)
    endif
    set LongText = concat(LongText, "|| ", cnvtphone(replyout->pharmacies[pha].primary_business_telephone.value,
                                                 replyout->pharmacies[pha].primary_business_telephone.type_cd))
  endfor
endif
endif

#EXIT_SCRIPT

set LongText = concat(LongText,"</i></body></html>")
call echo(build("LongText:",LongText))

set reply->text = LongText
set reply->format = 1 ;this means HTML so the caller will know how to handle.
call echoxml(reply, "kh_reply.dat")

end
go
;execute 0x_token_med_instructions "MINE", "3038613513" go
