/**************************************************************************
 Program Title:   mp_adv_dir_comp
 
 Object name:     mp_adv_dir_comp
 Source file:     mp_adv_dir_comp.prg
 
 Purpose:         Returns initial component HTML and links JS and CSS.
 
 Tables read:
 
 Executed from:   MPage
 
 Special Notes:
 
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 04/04/2018 Michael Mayes        211181    Initial release
 
*************END OF ALL MODCONTROL BLOCKS* ********************************/
drop program mp_adv_dir_comp:dba go
create program mp_adv_dir_comp:dba
 
prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
with OUTDEV
 
 
 
/**************************************************************
; DVDev INCLUDES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc
 
 
/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare html_ret      = vc with protect, noconstant('')
 
 
/**************************************************************
; DVDev Start Coding
**************************************************************/
 
;My plan is to uniquely create a DIV that the JS can identify and do any dynamic stuff it needs to do.
;I don't want to write a bunch of HTML in CCL if I can get away with it.
;THIS ID NEEDS TO BE UNIQUE ON THE PAGE
set html_ret = build2(^<div class="madc_parent"></div>^)
 
 
;This is a placeholder image stolen from crisp.  It brings in our JS and CSS after the fact when our component loads.
;It doesn't seem to use the server which makes sense I suppose.  Bedrock settings probably still do.
;You'll have to be very careful that any CSS/JS doesn't conflict with other components.
;;set html_ret = build2(html_ret, ^<img src='I:\\mPages\\common\\img\\blank.png' width='0px' height='0px' ^,
set html_ret = build2(html_ret, ^<img src='../custom_mpage_content/mpage_reference_files/common/img/blank.png' width='0px' height='0px' ^,
                                             ;JS
                                     ^onLoad='var compJS = document.createElement("script");^,
	                                         ^compJS.setAttribute("type","text/javascript");^,
	                                         ^compJS.setAttribute("src",^,
                                                      ;;^"I:\\mPages\\adv_directives\\js\\mp_adv_dir_comp.js");^,
                                             ^"../custom_mpage_content/mpage_reference_files/adv_directives/js/mp_adv_dir_comp.js");^,
		                                     ^document.getElementsByTagName("head")[0].appendChild(compJS);^,
                                             ;CSS
                                             ^var compCSS = document.createElement("link");^,
	                                         ^compCSS.setAttribute("rel","stylesheet");^,
	                                         ^compCSS.setAttribute("href",^,
                                                      ;;^"I:\\mPages\\adv_directives\\css\\mp_adv_dir_comp.css");^,
                                              ^"../custom_mpage_content/mpage_reference_files/adv_directives/css/mp_adv_dir_comp.css");^,
		                                     ^document.getElementsByTagName("head")[0].appendChild(compCSS);^,
	                                        ^'^,
                                ^>^)
                           
 
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
 
#exit_script
 
call putStringToFile($OUTDEV, html_ret)
 
end
go
 
