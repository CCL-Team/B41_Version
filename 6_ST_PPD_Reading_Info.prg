/*********************************************************************************************************************************
 Date Written:   April 12, 2018
 Program Title:  14_Amb_Loc_Patient_Visits
 Source file:
 Object name:
 New object :
 Directory:      CUST_SCRIPT:
 DVD Version:
 HNA Version:
 CCL Version:
 Purpose:       Smart Template to display PPD reading detail ie medication Name, Date, Performed by Route and site
 
**********************************************************************************************************************************
MODIFICATION CONTROL LOG
**********************************************************************************************************************************
 Mod   Date        Engineer         OPAS                  Comment
 ----  ----------- ---------------  ----                  ------------------------------------------------------------------------
 001   04/17/2018   SAA126          MCGA-210747           Initial Release
 002   10/08/2018   DMA112          SOM INCIDENT 6153771  fix sort order
 003   02/12/2019   SAA126          MCGA-214135           Added Expiration Date and Lot Number
 004   02/06/2024   MMM174          INC0516103            Attempted void and redocument not pulling into ST.  Correction for that.
*********************************************************************************************************************************/
 
drop program 6_ST_PPD_Reading_Info go
create program 6_ST_PPD_Reading_Info
 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
%i cust_script:0_rtf_template_format.inc
 
declare personId        = f8 with protect, constant(request->person[1]->person_id)
declare enctrId         = f8 with protect, constant(request->visit[1]->encntr_id)
declare CANCELED        = f8 with constant(uar_get_code_by("MEANING", 8, "CANCELED")), protect
declare DELETED         = f8 with constant(uar_get_code_by("MEANING", 8, "DELETED")), protect
declare VOIDEDWRSLT     = f8 with constant(uar_get_code_by("MEANING", 8, "VOIDEDWRSLT")), protect
declare st_message      = vc
DECLARE  rtf_table      = vc with protect, noconstant('')
DECLARE 200_PPD_CD      = f8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAYKEY", 200,"TUBERCULINPURIFIEDPROTEINDERIVATIVE"));2770744.00 ""
 
/**************************************************************
; DVDev Start Coding
**************************************************************/
 
select INTO "nl:"
    Medication_Name                 = build2(trim(uar_Get_code_display(o.catalog_cd))," (",trim(O.ordered_as_mnemonic),")"),
    Ordered_Date_Time               = format(O.orig_order_dt_tm,"MM/DD/YYYY HH:MM;;"),
    Administered_date_time          = format(cmr.admin_end_dt_tm,"MM/DD/YYYY HH:MM;;"),
    Performed_by                    = trim(p.name_full_formatted),
    Route                           = trim(uar_Get_code_display(cmr.admin_route_cd)),
    Site                            = trim(uar_Get_code_display(cmr.admin_site_cd))
from
    Orders o,
    order_action oa,
    clinical_event ce,
    ce_med_result cmr,
    person p
PLAN o
    where o.person_id               = personId
    and O.catalog_cd                = 200_PPD_CD
    and o.order_status_cd           NOT IN (CANCELED, DELETED, VOIDEDWRSLT)
JOIN oa
    where oa.order_id               = O.order_id
JOIN p
    where p.person_id               = oa.action_personnel_id
join ce
    where ce.order_id               = outerjoin(O.order_id)
      and ce.valid_until_dt_tm     >= outerjoin(cnvtdatetime(curdate, curtime3))
      and (   ce.result_status_cd   = outerjoin(34)
           or ce.result_status_cd   = outerjoin(25)
           or ce.result_status_cd   = outerjoin(35)
          )
join cmr
    where cmr.event_id              = outerjoin(ce.event_id )
    AND TEXTLEN(CNVTSTRING(cmr.admin_end_dt_tm)) > 1                                ; 002
;order by o.catalog_cd, format(cmr.admin_end_dt_tm,"MM/DD/YYYY HH:MM;;") DESC       ; 002
order by o.catalog_cd, cmr.admin_end_dt_tm DESC                                     ; 002
 
head report
    st_message =  rhead
    head o.catalog_cd
        st_message = build2(st_message,wb, "Medication Name: ",wr, trim(uar_Get_code_display(o.catalog_cd))," (",trim(O.
        ordered_as_mnemonic),")",reol)
        st_message = build2(st_message,wb, "Additional Information: ",wr, trim(O.simplified_display_line),reol)
        st_message = build2(st_message,wb, "Ordered Date/Time: ",wr, Ordered_Date_Time,reol)
        st_message = build2(st_message,wb, "Administered Date/Time: ",wr, Administered_date_time,reol)
        st_message = build2(st_message,wb, "Performed By: ",wr, trim(substring(1,100,Performed_by)),reol)
        st_message = build2(st_message,wb, "Route: ",wr, Route,reol)
        st_message = build2(st_message,wb, "Site: ",wr, Site,reol)
        st_message = build2(st_message,wb, "LOT Number: ",wr, cmr.substance_lot_number,reol)
        st_message = build2(st_message,wb, "Expiration Date: ",wr, format(cmr.substance_exp_dt_tm,"MM/DD/YYYY;;"),reol)
;       st_message = build2(st_message,wb, "LOT Number: ",wr, cmr.substance_lot_number,reol)
;       st_message = build2(st_message,wb, "Expiration Date: ",wr, format(cmr.substance_exp_dt_tm,"MM/DD/YYYY;;"),reol)
 
with nocounter
 
/**************************************************************
; Reply
**************************************************************/
if(curqual = 0)
    set rtfStr = build2(RHEAD,REOL)
    set reply->text = concat(rtfStr, rtfeof)
else
    set reply->text  = build2(reply->text,st_message, rtfeof)
endif
end
go
 