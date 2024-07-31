/*************************************************************************
 Program Title:   CC Medication Inotrope Vasopressor Autotext 
 
 Object name:     5_st_cc_ino_vaso_auto
 Source file:     5_st_cc_ino_vaso_auto.prg
 
 Purpose:         This ST is supposed to be a subset of the 5_st_cc_inpat_meds, pulling only
                  the currently specific inotrope active IV meds from it.
                  
                  This will be used in autotext (.medicationInotropeVasopressorContinCritCare)
                  supposedly as a ST too...
                  Also in the note Consultation Note – Shock Team Activation (Cardiogenic Shock)
                  
                  In the ST they don't want the header... and no nodata message.
                  
                  and in the Autotext they want a header if we have data.
                  
                  To facilitate this, I'm wrapping this ST with another script,
                  and adding the header if we need it.
                  
                  Wrapper is 5_st_cc_cont_inf_all_auto.
 
 Tables read:
 
 Executed from:
 
 Special Notes:   
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 2024-06-05 Michael Mayes        241764 Initial (This was copied from 5_st_cc_inpat_meds at this time, then adjusted.)
*************END OF ALL MODCONTROL BLOCKS* *******************************/
  drop program 5_st_cc_ino_vaso_auto:dba go
create program 5_st_cc_ino_vaso_auto:dba

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

record st_request(
    1 visit_cnt         = i4
    1 visit[*]
        2 encntr_id     = f8
)

record st_reply(
   1 text                       = vc
      1 status_data
         2 status               = c1
         2 subeventstatus[1]
            3 OperationName     = c25
            3 OperationStatus   = c1
            3 TargetObjectName  = c25
            3 TargetObjectValue = vc
)

 
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare header    = vc  with protect, noconstant(' ')
declare tmp_str   = vc  with protect, noconstant(' ')
declare empty_str = vc  with protect, noconstant(' ') 
declare head_str  = vc  with protect, noconstant(' ') 

/**************************************************************
; DVDev Start Coding
**************************************************************/
;Just doing this exactly like the script does.  This gets a implicit trim on reol.
set empty_str = build2(rhead, reol)
set empty_str = build2(empty_str, rtfeof) 



set stat = alterlist(st_request->visit, 1)
set st_request->visit_cnt = 1
set st_request->visit[1]->encntr_id = e_id

execute 5_st_cc_ino_vaso:dba with replace(request, st_request), replace(reply, st_reply)

if (st_reply->status_data->status = "F")
    go to exit_program
endif


call echorecord(st_reply)


call echo(st_reply->text)

call echo(empty_str)
call echo(st_reply->text)

if(st_reply->text = empty_str)
    set reply->status_data->status = "S"
    set reply->text = st_reply->text
else
    set reply->status_data->status = "S"
    set reply->text = replace(st_reply->text, rhead
                                         , notrim(build2( rhead
                                                        , wbu, 'Inotropic Agents/Vasopressors (Continuous)', wr
                                                        , reol
                                                        )
                                                 )
                             )
endif
set reply->status_data->status = "S"
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
;call echorecord(data)
;call echorecord(reply)
;call echorecord(drec)
 
call echo(reply->text)
 
end
go
 
 
