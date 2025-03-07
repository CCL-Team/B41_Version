

/**********************************************************************************************************************

Create Date:    06/17/2021

Object name:    5_hla_worklist

Source file:    5_hla_worklist.prg

Purpose:        To display information including barcoded fields for HLA

Executed from:  DA2/Reporting Portal

Special Notes:

***********************************************************************************************************************
                                  MODIFICATION CONTROL LOG
***********************************************************************************************************************
Mod Date        Analyst                     MCGA    Comment
--- ----------  --------------------------  ------  -------------------------------------------------------------------
000 06/17/2021  Jennifer King               222182  Initial Release
001 06/27/2023  Jennifer King               238726  Add order note for certain orderables
002 07/31/2023  Jennifer King               240003  Fix missing data
003 03/07/2025  Michael Mayes               352886  Change in format of DOB, to account for possible TZ entry and issues there.

**************************************** END OF ALL MODCONTROL BLOCKS ************************************************/


drop program 5_hla_worklist:dba go
create program 5_hla_worklist:dba

prompt
    "Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
    , "Worklist Name" = ""
    , "Report_type" = "R"

with OUTDEV, WORKLIST_NAME, REPORT_TYPE




;;;;;;; DO NOT SEND EMAILS/PRINT REPORTS FROM OPERATIONS IN A NON-PROD DOMAIN ;;;;;;

if(curdomain != "P41" and validate(request->batch_selection) = 1)
    go to EXIT_SCRIPT
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Record Structures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free record rs
record rs

(
    ;1 cnt = i4

    1 qual[*]

        2 accession = vc
        2 patient_dob = vc
        2 serum_date = vc
        2 care_set_name = vc
        2 ordering_physician = vc
        2 cs_accession = vc
        2 order_id = f8     ;001 - added
        2 order_note = vc   ;001 - added
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Include Files ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

execute reportrtl
%i cust_script:5_hla_worklist.dvl



;;;;;;;;;;;;;;;;;;;;;; Declare and set selected variables and rs items ;;;;;;;;;;;;;;;;;;;;;;

declare printed_date = vc with
        constant(format(cnvtdatetime(curdate,curtime3),"MM/DD/YYYY  hh:mm;;Q"))

declare report_title_var = vc with constant("HLA Cerner Worklist Report")

declare worklist_name_var = vc with constant(trim($WORKLIST_NAME))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Main Program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;retrieve data based on worklist entered in prompt

select distinct into 'nl:'

from
    worklist wl
    ,worklist_order_r wr
    ,orders o
    ,person p
    ,encounter e
    ,accession_order_r aor
    ,orders o2
    ,orders o3
    ,accession_order_r aor2
    ,order_container_r oc
    ,container c
    ,container_event ce
    ,order_action oa
    ,prsnl pr
    ,accession_order_r aor3

plan wl
    where wl.worklist_alias = cnvtupper($WORKLIST_NAME)

join wr
    where wr.worklist_id = wl.worklist_id

join o
    where o.order_id = wr.order_id
    and o.dept_status_cd = 9322.00 ;In-Lab

join p
    where p.person_id = o.person_id

join e
    where e.person_id = p.person_id

join aor
    where aor.order_id = o.order_id

join o2
    where o2.encntr_id = e.encntr_id
    and o2.catalog_cd = 6797171.00 ;HLA PRA Fl Scr
    and o2.activity_type_cd in (694.00,3542637.00) ;HLA, Helix

join o3
    where o3.encntr_id = e.encntr_id
    and o3.order_id = o2.cs_order_id

join aor2
    where aor2.order_id = o2.order_id
    and aor2.accession = aor.accession

join oc
    where oc.order_id = o.order_id

join c
    where c.container_id = oc.container_id
    and c.specimen_type_cd = 1765.00 ;Blood

join ce
    where ce.container_id = c.container_id

join oa
    where oa.order_id = o.order_id
    and oa.action_sequence = (select max(v1.action_sequence)
                                from order_action v1
                                where v1.order_id = oa.order_id)

join pr
    where pr.person_id = oa.order_provider_id

join aor3
    where aor3.order_id = o3.order_id

order by wl.worklist_alias, aor.accession


head report
    cnt=0

detail
    cnt = cnt+1
    stat = alterlist(rs->qual,cnt)

    rs->qual[cnt].accession = build2(substring(8,2,aor.accession),"-",substring(10,3,aor.accession),"-",substring(14,5,aor.accession))

        if(o.catalog_cd = 6797472.00) ;HLA DNA Extraction Worksheet (G)
            rs->qual[cnt].accession = build2(rs->qual[cnt].accession," DNA")

        elseif(o.catalog_cd = 4376278.00) ;HLA Rslt PRA Fl Scr
            rs->qual[cnt].accession = build2(rs->qual[cnt].accession," LSPRA")

        endif
    ;003-> Changing the format here to correct TZ issue.
    ;rs->qual[cnt].patient_dob = build2(trim(p.name_last_key)," ",trim(p.name_first_key),"_",format(p.birth_dt_tm,"MMDDYY;;D"))
    rs->qual[cnt].patient_dob = build2( trim(p.name_last_key)," "
                                      , trim(p.name_first_key),"_"
                                      , datebirthformat(p.birth_dt_tm, p.birth_tz, 0, "MMDDYY;;D")
                                      )
    ;003<-
    rs->qual[cnt].serum_date = format(ce.drawn_dt_tm,"MM/DD/YYYY;;D")
    rs->qual[cnt].care_set_name = o3.hna_order_mnemonic
    rs->qual[cnt].ordering_physician = pr.name_full_formatted
    rs->qual[cnt].cs_accession = build2(substring(6,2,aor3.accession),"-",substring(10,2,aor3.accession),"-",substring(12,7,aor3.accession))
    rs->qual[cnt].order_id = o.order_id ;001 - added

with nocounter, time=600;, maxrec=10    ;002 - removed maxrec




;go to final output if no initial records qualify

if (size(rs->qual, 5) = 0) ;no data in rs
    go to FINAL_OUTPUT
endif



;001 - begin add

;add order note for certain orderables
select into "nl:"

from
    (dummyt d1 with seq = size(rs->qual,5))
    ,orders o
    ,order_comment ocom
    ,long_text lt

plan d1

join o
    where o.order_id = rs->qual[d1.seq].order_id
    and o.catalog_cd in
        (
            4376278.00  ;HLA Rslt PRA Fl Scr
            ,7218291.00 ;HLA Antibody Titer
        )

join ocom
    where ocom.order_id = o.order_id
    and ocom.comment_type_cd = 67.00 ;order note

join lt
    where lt.long_text_id = ocom.long_text_id
    and lt.active_ind = 1
    and lt.active_status_cd = 188.00 ;active

order by d1.seq, ocom.action_sequence desc

head d1.seq
    rs->qual[d1.seq].order_note = trim(replace(replace(lt.long_text,char(10)," "),char(13)," "),3)

;001 - end add



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  FINAL OUTPUT  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#FINAL_OUTPUT

;No data present in rs

if (size(rs->qual, 5) = 0)

  select into value($OUTDEV)


  rpt_type = (if($REPORT_TYPE = "S")
                "Report Type:  Spreadsheet"
            else
                "Report Type:  Report"
            endif)

  from (dummyt d1)
  head page
    "{ps/792 0 translate 90 rotate/}" ;landscape program
    row + 1
  detail

      col 0 report_title_var
      row + 2
      col 0 "There are no patients that match your requested parameters."
      row + 2
      col 0 "Worklist Name: " worklist_name_var
      row + 2
      col 0 "As of: "
      col 10 printed_date
      row + 2
      col 0 rpt_type

  with nocounter, dio = postscript, landscape

  go to exit_script

endif



;data present in the rs


if ($REPORT_TYPE = "S")  ; spreadsheet

    select into $OUTDEV

        accession = trim(substring(1,30,rs->qual[d1.seq].accession))
        ,patient_dob= trim(substring(1,75,rs->qual[d1.seq].patient_dob))
        ,serum_date = trim(substring(1,20,rs->qual[d1.seq].serum_date))
        ,care_set_name = trim(substring(1,50,rs->qual[d1.seq].care_set_name))
        ,ordering_physician = trim(substring(1,50,rs->qual[d1.seq].ordering_physician))
        ,cs_accession = trim(substring(1,30,rs->qual[d1.seq].cs_accession))
        ,order_note = trim(substring(1,500,rs->qual[d1.seq].order_note),3)  ;001 - added

    from
        (dummyt d1 with seq = value(size(rs->qual,5)))


    with nocounter, format, separator=" ", time=600



elseif ($REPORT_TYPE = "R")  ;layout builder

    SET _SendTo =  $OUTDEV
    CALL LayoutQuery(0)


endif


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



#EXIT_SCRIPT

end
go