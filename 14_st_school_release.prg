/*************************************************************************
 Program Title:   School Release Form ST
 
 Object name:     14_st_school_release
 Source file:     14_st_school_release.prg
 
 Purpose:         Simple form letter for a school release including 
                  encounter location.
 
 Tables read:
 
 Executed from:
 
 Special Notes:   
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2024-05-01 Michael Mayes        346683 Initial release
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 14_st_school_release:dba go
create program 14_st_school_release:dba

%i cust_script:0_rtf_template_format.inc
 

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
 
 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header   = vc  with protect, noconstant(' ')
declare tmp_str  = vc  with protect, noconstant(' ')
                 
declare location_str = vc with protect, noconstant(' ') 



/**************************************************************
; DVDev Start Coding
**************************************************************/

/***********************************************************************
DESCRIPTION: Find the patient location
***********************************************************************/
select into 'nl:'
  from encounter  e
     , code_value cv
  
 where e.encntr_id         =  e_id 
   and e.active_ind        =  1
   
   and cv.code_value       =  e.loc_facility_cd
   and cv.active_ind       =  1

detail
    location_str = trim(cv.description, 3)
with nocounter
 
 
 
 
;Presentation
;
;RTF header
set header = notrim(build2(rhead))
 
set tmp_str = notrim(build2(         'To Whom it May Concern:', reol))
set tmp_str = notrim(build2(tmp_str, 'This patient was seen today at ', location_str, '.', reol))
set tmp_str = notrim(build2(tmp_str, 'Please excuse from school for the following date(s): _', reol))
 
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
 
call echorecord(reply)
call echorecord(drec)
 
call echo(reply->text)
 
end
go
