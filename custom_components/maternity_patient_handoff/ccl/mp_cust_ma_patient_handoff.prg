  drop program mp_cust_ma_patient_handoff:dba go
create program mp_cust_ma_patient_handoff:dba
 
/***************************************************************************
 Program Title:     MP_CUST_MA_PATIENT_HANDOFF
 
 Object name:       mp_cust_ma_patient_handoff
 Source file:       mp_cust_ma_patient_handoff.prg
 
 Purpose:           Returns initial component HTML and links JS and CSS
 
 Tables read:       N/A
 
 Executed from:     mPage
 
 Special Notes:     N/A
 
****************************************************************************
                  MODIFICATION CONTROL LOG
****************************************************************************
Mod Date        Analyst                 MCGA   Comment
--- ----------  ----------------------- ------ -----------------------------
001 03/03/2020  Clayton Wooldridge      220155 Initial release
                                               Michael Mayes took this over for him
*************END OF ALL MODCONTROL BLOCKS* ********************************/
 
prompt
    "Output to File/Printer/MINE" = "MINE"
with OUTDEV
 
 
declare ERR_MSG = vc with protect, noconstant("")
declare EXEC_DT_TM = dq8 with protect, constant(cnvtdatetime(CURDATE, CURTIME))
 
 
if (validate(DEBUG_IND, 0) != 1)
    set DEBUG_IND = 0
endif
 
 
if (not(validate(REPLY, 0)))
    record REPLY(
%i cust_script:status_block.inc
    )
endif
 
 
set REPLY->status_data->status = "F"
set REPLY->status_data->subeventstatus[1]->targetobjectvalue = "MP_CUST_MA_PATIENT_HANDOFF"
 
 
;***************************************************************************
; EKS_PUT_SOURCE REQUEST RECORD DEFINITION
;***************************************************************************
free record EKSREQUEST
record EKSREQUEST(
    1 source_dir        = vc
    1 source_filename   = vc
    1 nbrlines          = i4
    1 line[*]
        2 linedata      = vc
    1 overflowpage[*]
        2 ofr_qual[*]
            3 ofr_line  = vc
    1 isblob            = c1
    1 document_size     = i4
    1 document          = gvc
)
 
 
;***************************************************************************
; LOCAL VARIABLE DECLARATIONS
;***************************************************************************
declare sHTML = vc with protect, noconstant("")
 
 
;***************************************************************************
; SUBROUTINE TO CONVERT THE RECORD STRUCTURE TO A JSON FILE
;***************************************************************************
subroutine (SendHTML(dest = vc, comp_html = vc) = null with protect)
 
    set stat = initrec(EKSREQUEST) ;MAKE SAFE FOR RE-USE
 
    set EKSREQUEST->source_dir = dest
    set EKSREQUEST->isblob = '1'
    set EKSREQUEST->document = comp_html
    set EKSREQUEST->document_size = size(EKSREQUEST->document)
 
    execute eks_put_source with replace(REQUEST, EKSREQUEST);, replace(REPLY, EKSREPLY)
 
end ;SendHTML
 
 
;***************************************************************************
; DYNAMICALLY CREATE THE MATERNITY PATIENT HANDOFF BASE CODE
;***************************************************************************
 
;My plan is to uniquely create a DIV that the JS can identify and do any dynamic stuff it needs to do.
;I don't want to write a bunch of HTML in CCL if I can get away with it.
;THIS ID NEEDS TO BE UNIQUE ON THE PAGE
set sHTML = build2(^<div class="mmatph_parent"></div>^)
 
 
;This is a placeholder image stolen from crisp.  It brings in our JS and CSS after the fact when our component loads.
;It doesn't seem to use the server which makes sense I suppose.  Bedrock settings probably still do.
;You'll have to be very careful that any CSS/JS doesn't conflict with other components.
set sHTML = build2(sHTML, ^<img src='../custom_mpage_content/mpage_reference_files/common/img/blank.png' width='0px' height='0px' ^,
                                        ;JS
                                ^onLoad='var compJS = document.createElement("script");^,
                                        ^compJS.setAttribute("type","text/javascript");^,
                                        ^compJS.setAttribute("src",^,
                                                 ^"../custom_mpage_content/mpage_reference_files/maternity_patient_handoff/js/mp_cust_mat_patient_handoff.js");^,
                                        ^document.getElementsByTagName("head")[0].appendChild(compJS);^,
                                        ;CSS
                                        ^var compCSS = document.createElement("link");^,
                                        ^compCSS.setAttribute("rel","stylesheet");^,
                                        ^compCSS.setAttribute("href",^,
                                                 ^"../custom_mpage_content/mpage_reference_files/maternity_patient_handoff/css/mp_cust_mat_patient_handoff.css");^,
                                        ^document.getElementsByTagName("head")[0].appendChild(compCSS);^,
                                       ^'^,
                           ^>^)
 
if (error(ERR_MSG, 0) = 0)
    set REPLY->status_data->status = "S"
endif
 
#EXIT_PROGRAM
 
call SendHTML($OUTDEV, sHTML)
 
end
go
