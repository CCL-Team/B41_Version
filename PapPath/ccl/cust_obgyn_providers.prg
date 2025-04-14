/**************************************************************************
 Program Title:   OBGYN Cerv Cyto Mpage Get Providers

 Object name:     cust_obgyn_providers
 Source file:     cust_obgyn_providers.prg

 Purpose:         Gets a list of patients, qualifying with the drop down filters
                  and the corresponding information needed by the page

 Tables read:

 Executed from:   MPage

 Special Notes:

***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 08/21/2024 Michael Mayes        239854    Initial release

*************END OF ALL MODCONTROL BLOCKS* ********************************/
  drop program cust_obgyn_providers:dba go
create program cust_obgyn_providers:dba


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
free record params
record params(
    1 prov_cnt = i4
    1 prov[*]
        2 id   = f8
        2 text = vc
        
%i cust_script:mpajax_cust_status.inc
)

/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
declare echoMockJSON_undercap(script = vc, out_rs = vc(ref)) = null with protect
declare putRSToFile_undercap(out_loc = vc, out_rs = vc(ref)) = null with protect


/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare err_code = i4 with protect, noconstant(0)
declare err_msg  = vc with protect, noconstant("")
 
if(validate(debug_ind, -1) = -1)
    declare debug_ind = i2 with protect, noconstant(0)
endif


/**************************************************************
; DVDev Start Coding
**************************************************************/
select into 'nl:'
  from prsnl p
 
 where p.physician_ind = 1
   and p.active_ind    = 1
   and p.position_cd   > 0

order by p.name_last_key
       , p.name_first_key
    
detail
    params->prov_cnt = params->prov_cnt + 1
    
    if(mod(params->prov_cnt, 50) = 1)
        stat = alterlist(params->prov, params->prov_cnt + 49)
    endif
    
    params->prov[params->prov_cnt].id   = p.person_id
    params->prov[params->prov_cnt].text = trim(p.name_full_formatted, 3)
    
foot report
    stat = alterlist(params->prov, params->prov_cnt)

with nocounter
 
set err_code = error(err_msg, 0)
if (err_code > 0)
    call WriteStatus('F', 'Gathering providers', 'F', '0_CUST_MP_SURG_PROC_FILT', err_msg, params)
 
    go to exit_script
endif


/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************
/***********************************************************************
NAME:                  putRSToFile
 
DESCRIPITON:           Use eks_put_source to write out a string to a file.
 
PARAMETER DESCRIPTION: out_loc (vc): Usually 'MINE', or coming from a prompt
                       out_rs  (rs): Record Structure to return, passed by ref
 
NOTES:                 $OUTDEV used to be specified as the out in the cerner
                       sub I stole this from, but that caused any script using
                       the include to have to be a prompt program.
 
                       The only problem with passing the RS by ref is that
                       the RS that gets put in the JSON is the out_rs, not the
                       name of the RS coming from the file.
                       
                       
                       Copying from my libraries to this... because I think 
                       I am fighting JSON casing, and I supposedly can fix this.
 
************************************************************************/
subroutine putRSToFile_undercap(out_loc, out_rs)
 
    free record eksrequest
    record eksrequest (
        1 source_dir = vc
        1 source_filename = vc
        1 nbrlines = i4
        1 line [*]
            2 linedata = vc
        1 overflowpage [*]
            2 ofr_qual [*]
                3 ofr_line = vc
        1 isblob = c1
        1 document_size = i4
        1 document = gvc
    )
 
    set eksrequest->source_dir = out_loc
    set eksrequest->isblob = '1'
    set eksrequest->document = cnvtrectojson(out_rs, 2)
    set eksrequest->document_size = size(eksrequest->document)
 
    execute eks_put_source with replace(request,eksrequest), replace(reply, eksreply)
    
end

/***********************************************************************
NAME:                  echoMockJSON
 
DESCRIPITON:           Echo text that can be copy pasted into MpageCCLAjax mock.js framework
 
PARAMETER DESCRIPTION:  script  (vc): Name of script
                        out_rs  (rs): Record Structure to return, passed by ref
 
NOTES:                 Copying from my libraries to this... because I think 
                       I am fighting JSON casing, and I supposedly can fix this.
 
************************************************************************/
subroutine echoMockJSON_undercap(script, out_rs)
    
    call echo('MOCK INFO')
    
    call echo(concat('var ', script, ' ='))
    
    call echo(cnvtrectojson(out_rs, 2))    
end


set params->status_data->status = "S"

#exit_script

if(debug_ind = 1)
    call echoMockJSON_undercap('cust_obgyn_providers', params)
endif

call putRSToFile_undercap($outdev, params)


end
go

