  drop program 14_st_ma_handoff_orders:dba go
create program 14_st_ma_handoff_orders:dba
 
/**********************************************************************************************
 Program Title:   Maternity Patient Today's Orders
 
 Object name:     14_st_ma_handoff_orders
 Source file:     14_st_ma_handoff_orders.prg
 
 Purpose:         To gather up orders and proposed orders addressed on the
                  current encounter. Able to be executed as smart template or
                  as a driver script for an mPage component, etc.
 
 Tables read:     ORDERS
                  ORDER_PROPOSAL
 
 Executed from:   This is used in the Maternity Patient Handoff component
 
 Special Notes:   N/A
 
***********************************************************************************************
                  MODIFICATION CONTROL LOG
***********************************************************************************************
Mod Date        Analyst                 MCGA   Comment
--- ----------  ----------------------- ------ ------------------------------------------------
001 03/03/2020  Clayton Wooldridge      220155 Initial release
                                               Michael Mayes took this over for him
*************END OF ALL MODCONTROL BLOCKS* ***************************************************/
 
declare ERR_MSG    = vc  with protect, noconstant("")
declare EXEC_DT_TM = dq8 with protect,   constant(cnvtdatetime(CURDATE, CURTIME))
 
 
if (validate(DEBUG_IND, 0) != 1)
    set DEBUG_IND = 0
endif
 
 
if (validate(COMP_ONLY_IND, 0) != 1)
    set COMP_ONLY_IND = 0
endif
 
 
if (not(validate(REPLY, 0)))
    record REPLY(
        1 text                      = vc
        1 status_data
            2 status                = c1
            2 subeventstatus[1]
                3 operationname     = c15
                3 operationstatus   = c1
                3 targetobjectname  = c15
                3 targetobjectvalue = c100
        1 large_text_qual[*]
            2 text_segment          = vc
    )
endif

 
set REPLY->status_data->status = "F"
set REPLY->status_data->subeventstatus[1]->targetobjectvalue = "14_ST_MA_HANDOFF_ORDERS"
 
 
;***************************************************************************
; CONSTANT VARIABLE DECLARATIONS
;***************************************************************************
if (not(validate(TEMP, 0)))
    record TEMP(
    1 qual_cnt         = i4
    1 qual[*]
        2 order_id     = f8
        2 order_name   = vc
        2 order_status = vc
    )
endif
 
 
;***************************************************************************
; TEMPLATE VARIABLE DECLARATIONS
;***************************************************************************
declare TMPLT_ENCNTR_ID = f8 with protect, noconstant(0.0)
declare TMPLT_PERSON_ID = f8 with protect, noconstant(0.0)
 
 
;***************************************************************************
; LOCAL VARIABLE DECLARATIONS
;***************************************************************************

 
 
;***************************************************************************
; RTF CONSTANT VARIABLE DECLARATIONS
;***************************************************************************
declare RHEAD   = vc with protect,  constant(concat("{\rtf1\ansi\deff0","{\fonttbl",
                                                    "{\f0\fmodern\Courier New;}{\f1 Arial;}}",
                                                    "{\colortbl;","\red0\green0\blue0;",
                                                    "\red255\green255\blue255;",
                                                    "\red0\green0\blue255;",
                                                    "\red0\green255\blue0;",
                                                    "\red255\green0\blue0;}\deftab2520?$@rtf@$?"))
declare REOL    = vc with protect,  constant("\par?$@rtf@$?")
declare RTFEOF  = vc with protect,  constant("}")
 
 
;***************************************************************************
; SUBROUTINE TO DISPLAY RUNTIME MESSAGES IF NECESSARY
;***************************************************************************
subroutine (LogMSG(msg = vc, mode = i2(value, 0)) = null with protect)
     
    set msg = trim(msg, 3)
    if ((msg > "") and ((DEBUG_IND = 1) or (mode = 1)))
        call echo(trim(msg, 3))
    endif
 
end ;LogMSG
 
 
;***************************************************************************
; GET THE ENCOUNTER INFO FOR THIS EXECUTION
;***************************************************************************
select into "nl:"
  from encounter e
  plan e 
 where e.encntr_id = REQUEST->visit[1]->encntr_id
detail
    TMPLT_ENCNTR_ID     = e.encntr_id
    TMPLT_PERSON_ID     = e.person_id
with NOCOUNTER, TIME=300
 
if (error(ERR_MSG, 0) > 0)
    call LogMSG("*** THE ENCOUNTER QUERY HAS FAILED ***", 1)
    go to EXIT_PROGRAM
endif
 
if (TMPLT_ENCNTR_ID = 0.0)
    call LogMSG("*** THE ENCOUNTER ID IS ZERO ***", 1)
    go to EXIT_PROGRAM
endif

 
set stat = initrec(TEMP) ;MAKE SAFE FOR RE-USE
 
 
;***************************************************************************
; GET TODAY'S ORDERS FOR THIS EXECUTION
;***************************************************************************
select into "nl:"
  from orders o
  plan o 
   where o.person_id           =  TMPLT_PERSON_ID
     and o.encntr_id           =  TMPLT_ENCNTR_ID
     and o.template_order_flag in (0, 1)
     and o.active_ind          =  1
order by o.order_mnemonic, o.order_id
head report
    TEMP->qual_cnt = 0

head o.order_id
    TEMP->qual_cnt = TEMP->qual_cnt + 1
    
    if(mod(TEMP->qual_cnt, 20) = 1)
        stat = alterlist(TEMP->qual, (TEMP->qual_cnt + 19))
    endif
    
    TEMP->qual[TEMP->qual_cnt]->order_id      = o.order_id
    TEMP->qual[TEMP->qual_cnt]->order_name    = trim(uar_get_code_display(o.catalog_cd), 3)
    TEMP->qual[TEMP->qual_cnt]->order_status  = trim(uar_get_code_display(o.order_status_cd), 3)

with nocounter, time=300
 
if (error(ERR_MSG, 0) > 0)
    call LogMSG("*** THE TODAY'S ORDERS QUERY HAS FAILED ***", 1)
    go to EXIT_PROGRAM
endif
 
;***************************************************************************
; GET TODAY'S PROPOSED ORDERS FOR THIS EXECUTION
;***************************************************************************
select into "nl:"
  from order_proposal op
  plan op 
   where op.person_id      =  TMPLT_PERSON_ID
     and op.encntr_id      =  TMPLT_ENCNTR_ID
     and op.resolved_dt_tm is null
order by op.order_mnemonic, op.order_id

head op.order_id
    TEMP->qual_cnt = TEMP->qual_cnt + 1
    
    if (mod(TEMP->qual_cnt, 20) = 1)
        stat = alterlist(TEMP->qual, (TEMP->qual_cnt + 19))
    endif
    
    TEMP->qual[TEMP->qual_cnt]->order_id      = op.order_id
    TEMP->qual[TEMP->qual_cnt]->order_name    = trim(uar_get_code_display(op.catalog_cd), 3)
    TEMP->qual[TEMP->qual_cnt]->order_status  = "Proposed"


with nocounter
 

if (error(ERR_MSG, 0) > 0)
    call LogMSG("*** THE PROPOSED ORDERS QUERY HAS FAILED ***", 1)
    go to EXIT_PROGRAM
endif
 

/***********************************************************************
DESCRIPTION: Find visits future order
***********************************************************************/
select into 'nl:'
  from orders o
     , order_detail od
 where o.person_id        =  TMPLT_PERSON_ID
   and o.encntr_id        =  0.0
   and od.order_id        =  o.order_id
   and od.oe_field_value  =  TMPLT_ENCNTR_ID
   ;Looks like a prod copy solved this for us... might need to go look at patient handoff to make the same fix.
   ;and ((CURDOMAIN = "P41"  and OD.OE_FIELD_ID =   830570985.00) or
   ;     (CURDOMAIN = "B41"  and OD.OE_FIELD_ID =   465423307.00))
   and OD.OE_FIELD_ID    in (830570985, 465423307)
order by o.order_mnemonic
detail
    TEMP->qual_cnt = TEMP->qual_cnt + 1
    
    if (mod(TEMP->qual_cnt, 20) = 1)
        stat = alterlist(TEMP->qual, (TEMP->qual_cnt + 19))
    endif
    
    TEMP->qual[TEMP->qual_cnt]->order_name    = trim(uar_get_code_display(o.catalog_cd), 3)
    TEMP->qual[TEMP->qual_cnt]->order_status  = trim(uar_get_code_display(o.order_status_cd), 3)
with nocounter
 

if (error(ERR_MSG, 0) > 0)
    call LogMSG("*** THE FUTURE ORDERS QUERY HAS FAILED ***", 1)
    go to EXIT_PROGRAM
endif
 
set stat = alterlist(TEMP->qual, TEMP->qual_cnt)
 
 
if (COMP_ONLY_IND = 1)
    set REPLY->status_data->status = evaluate(TEMP->qual_cnt, 0, "Z", "S")
    go to EXIT_PROGRAM
endif
 
;Presentation
 
;***************************************************************************
; BUILD THE RTF OUTPUT FOR THE SMART TEMPLATE VERSION
;***************************************************************************
if (TEMP->qual_cnt = 0)
    set REPLY->text = concat(RHEAD, REOL, "No orders found on this encounter", RTFEOF)

else
    set REPLY->text = build2("\plain\f1\fs20\b\ul\cb2\pard\sl0?$@rtf@$?", "Today's Orders", REOL)
    
    for (qual_cnt = 1 TO TEMP->qual_cnt)
        set REPLY->text = build2(REPLY->text, "\plain\f1\fs20\cb2?$@rtf@$?", TEMP->qual[qual_cnt]->order_name,
                                              " - ", TEMP->qual[qual_cnt]->order_status, REOL)
    endfor
    
    set REPLY->text = build2(RHEAD, REPLY->text, RTFEOF)
endif
 
if (error(ERR_MSG, 0) = 0)
    set REPLY->status_data->status = "S"
endif
 
 
#EXIT_PROGRAM
 
if ((COMP_ONLY_IND = 0) and (REPLY->status_data->status = "F"))
    set REPLY->text = concat(RHEAD, REOL, "An error has occured. Please contact the help desk", RTFEOF)
endif
 
set REPLY->text = replace(REPLY->text, "?$@rtf@$?", " ", 0)

call echorecord(TEMP)
call echorecord(reply)
 
end
go