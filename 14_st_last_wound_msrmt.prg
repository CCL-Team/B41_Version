drop program 14_st_last_wound_msrmt go
create program 14_st_last_wound_msrmt

prompt 
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to. 

with OUTDEV

/*--------------------------------------------------------------------------------------------------------------------------------
 Name           : 14_st_wound_size_trend.prg
 Author:        : Simeon Akinsulie
 Date           : 11/07/2019
 Location       : cust_script
 Purpose		: Smart template script to pull patient's most recent wound measurement
 
----------------------------------------------------------------------------------------------------------------------------------
 History
----------------------------------------------------------------------------------------------------------------------------------
 Ver  By   			Date        Description
 ---  ---  			----------  -----------
 001  saa126	  	01/07/2019  Initial Release
 002  saa126		06/13/2022	Add Wound 6 through 30	
 003  saa126		03/25/2024	For some reason... RTF errored in prod.  Passed in build?  Dyndoc level diff?
 
 End History
--------------------------------------------------------------------------------------------------------------------------------*/ 

 
/*--------------------------------------------------------------------------------------------------------------------------------
  Includes File(s) and subroutine
--------------------------------------------------------------------------------------------------------------------------------*/  
%i cust_script:0_rtf_template_format.inc

declare getEventCodes(n0=i1) = i4
declare set_row(col1_txt = vc, col2_txt = vc, col3_txt = vc, col4_txt = vc, col5_txt = vc, col6_txt = vc, col7_txt = vc
,col8_txt = vc, col9_txt = vc) = vc

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
free record eventcds
record eventcds(
  1 event_cds[*]
    2 event_cd = f8
    2 display_key = vc
    2 type = vc
    2 display = vc
)
 
record wnd_history(
	1 person_id = vc
	1 date_range = vc
	1 form_name = vc
	1 qual[*]
		2 wound_label = vc
    2 wound_onset_date = vc
    2 wound_treatment_start_date = vc	
    2 depth = f8
    2 width = f8
    2 length = f8
    2 area = f8
    2 volume = f8  
    2 measurement_date = vc
)
 
record cells(
	1 cells[*]
		2 size = i4
)

/*--------------------------------------------------------------------------------------------------------------------------------
  Declare Variables
--------------------------------------------------------------------------------------------------------------------------------*/  

declare wnd_form = f8 with constant(6596150623),protect
declare wnd_form2 = f8 with constant(2925942763),protect
declare personId =  f8 with protect,constant(request->person[1]->person_id) ; constant(157127788)
declare rtf_output = vc with protect, noconstant('')
declare cnt = i4
declare num = i4 with noconstant(0),public
declare  rtf_table = vc with protect, noconstant('')

/*--------------------------------------------------------------------------------------------------------------------------------
  Declare constants for RTF tags
--------------------------------------------------------------------------------------------------------------------------------*/

 
;---------------------------------------------------------------------------------------------------------------------------------
;	Get Wound Info
;---------------------------------------------------------------------------------------------------------------------------------

;---------------------------------------------------------------------------------------------------------------------------------
;	Get Wound Info
;---------------------------------------------------------------------------------------------------------------------------------
select into "nl:"  
  cdl.label_name
  ,sort_ind = cnvtdatetime(ce.event_end_dt_tm)    
  ,ce.event_cd, ce.result_val,  
  unit = uar_get_code_display(ce.result_units_cd),
  date = format(ce.event_end_dt_tm, "MM/DD/YY HH:MM:SS"),
  cdr.result_dt_tm
from  v500_event_set_code esc,
  v500_event_set_canon vs,
  v500_event_set_canon vs2,
  v500_event_set_canon vs3,
  v500_event_set_canon vs4,
  v500_event_set_explode exp,
  clinical_event ce,
  ce_dynamic_label cdl,
  ce_date_result cdr
plan esc    
join vs  
  where vs.event_set_cd = esc.event_set_cd  
  and vs.event_set_collating_seq = 1  
join vs2  
  where vs2.parent_event_set_cd = vs.event_set_cd
join vs3  
  where vs3.parent_event_set_cd = vs2.event_set_cd  
  and vs3.event_set_cd =  3998539.00  
join vs4  
  where vs4.parent_event_set_cd = vs3.event_set_cd  
join exp  
  where exp.event_set_cd = vs4.event_set_cd  
join ce  
  where ce.person_id = personId;38612888                        
  and ce.event_cd = exp.event_cd    
  and ce.event_tag != "Date\Time Correction"   
  and ce.valid_until_dt_tm > cnvtdatetime(curdate,curtime3)  
  and ce.view_level = 1  and  ce.result_val > " "  
  and ce.event_cd in (4988550565, ;Wound Onset Date:	 	
                      4988550605, ;Wound Treatment Start Date:	 
                      4988528955, ;Incision, Wound Length:
                      4988529227, ;Incision, Wound Width:	 
                      4988548791 ;Incision, Wound Depth:	 
                      )
join cdl    
  where cdl.ce_dynamic_label_id = ce.ce_dynamic_label_id 
  and cdl.label_name > " " 
join cdr
  where cdr.event_id = outerjoin(ce.event_id)
	and cdr.valid_until_dt_tm >= outerjoin(cnvtdatetime(curdate,curtime3))  
order  cdl.label_name desc, ce.event_cd, ce.performed_dt_tm desc
head report
	cnt = 0
head cdl.label_name
  cnt = cnt + 1
  stat = alterlist(wnd_history->qual, cnt)
  wnd_history->qual[cnt].wound_label = cdl.label_name
  wnd_history->qual[cnt].measurement_date = format(ce.event_end_dt_tm,"mm/dd/yyyy;;d")
head ce.event_cd  
  case(ce.event_cd)
    of 4988550565: wnd_history->qual[cnt].wound_onset_date = format(cdr.result_dt_tm,"MM/DD/YYYY;;D")
    of 4988550605: wnd_history->qual[cnt].wound_treatment_start_date = format(cdr.result_dt_tm,"MM/DD/YYYY;;D")
    of 4988528955: wnd_history->qual[cnt].length = cnvtreal(ce.result_val)
    of 4988529227: wnd_history->qual[cnt].width = cnvtreal(ce.result_val)
    of 4988548791: wnd_history->qual[cnt].depth = cnvtreal(ce.result_val)
  endcase
foot cdl.label_name
		wnd_history->qual[cnt].area = wnd_history->qual[cnt].width * wnd_history->qual[cnt].length
		wnd_history->qual[cnt].volume = (wnd_history->qual[cnt].width * wnd_history->qual[cnt].length * wnd_history->qual[cnt].depth)
with nocounter, separator=" ", format
call echorecord( wnd_history)
if(size(wnd_history->qual,5) >0)
	call echorecord(wnd_history)
	set stat = alterlist(cells->cells,9)  ;003
	set cells->cells[1]->size = 850
	set cells->cells[2]->size = 1950
	set cells->cells[3]->size = 3100
	set cells->cells[4]->size = 4500 ;4800
	set cells->cells[5]->size = 5800
	set cells->cells[6]->size = 7150
	set cells->cells[7]->size = 8250
	set cells->cells[8]->size = 9350
	set cells->cells[9]->size = 10500
	;set cells->cells[10]->size = 12000
 
	set rtf_table = build2(rh2b, set_row("Wound#", "Onset Dt","Tx Start Dt","Msrment Dt", "Length(cm)", 
	"Width(cm)","Depth(cm)","Area(cm2)","Volume(cm3)"))
	set rtf_table = build2(rtf_table, wr)
	;for each wound label
	for(cnt = 1 to (size(wnd_history->qual,5))	)
    set rtf_table = notrim(build2(rtf_table,set_row(
    trim(wnd_history->qual[cnt].wound_label,3),
    trim(wnd_history->qual[cnt].wound_onset_date,3),
    trim(wnd_history->qual[cnt].wound_treatment_start_date,3),
    trim(wnd_history->qual[cnt].measurement_date,3),
    trim(format(wnd_history->qual[cnt].length,"#####.##"),3),
    trim(format(wnd_history->qual[cnt].width,"#####.##"),3),
    trim(format(wnd_history->qual[cnt].depth,"#####.##"),3),
    trim((format(wnd_history->qual[cnt].area,"#####.##")),3),
    trim((format(wnd_history->qual[cnt].volume,"#####.##")),3))))
	endfor
	set rtf_table= build2(rhead,rtf_table,rtfeof)
	call echo(rtf_table)
	set reply->text = rtf_table
else
	set reply->text = build2(rhead,"No Qualifying data to display",rtfeof)
endif
#exitscript
set drec->status_data->status = "S"
set reply->status_data->status = "S"

;set _Memory_Reply_String = Reply->Text

subroutine set_row(col1_txt, col2_txt, col3_txt, col4_txt, col5_txt, col6_txt, col7_txt, col8_txt, col9_txt)
	declare row_str = vc
	set row_str = concat(
		rtf_row(cells, 1),
		rtf_cell(col1_txt, 0),
		rtf_cell(col2_txt, 0),
		rtf_cell(col3_txt, 0),
		rtf_cell(col4_txt, 0),
		rtf_cell(col5_txt, 0),
		rtf_cell(col6_txt, 0),
		rtf_cell(col7_txt, 0),
		rtf_cell(col8_txt, 0),
		rtf_cell(col9_txt, 1)
;		,
;		rtf_cell(col9_txt, 1)
	)
	;call echo(row_str)
	return (row_str)
end
 
 
end
go
 