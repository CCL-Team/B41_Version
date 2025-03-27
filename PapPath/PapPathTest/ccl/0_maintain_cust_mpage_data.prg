/*************************************************************************
 Program Title:   Maintain Cust mPage Data
 
 Object name:     0_maintain_cust_mpage_data
 Source file:     0_maintain_cust_mpage_data.prg
 
 Purpose:         Delete/update data tied to a specific user and data
                  source represented as a unique CDF_MEAN in CS 100705.
 
 Tables read:     CUST_MPAGE_DATA
 
 Executed from:   mPages
 
 Special Notes:   This can be called two ways:
                  Single value:
                      For a single value, you can fill out the first three params rather than building out a request JSON.
                      Those params are just:
                          outdev (usually 'MINE')
                          prsnl_id (the current user)
                          cdf_mean (the unique cdf_mean representing the data from code_set 100705)
                          data (the data to store)
                  Multi value:
                      This way ignores the PRSNL_ID, CDF_MEAN and DATA params in favor of a JSON coming in with multiple values to
                      maintain.  You still send outdev, but the values in the other two params are disregarded.  A fifth param
                      is sent, with a JSON with this structure:
                          {
                              "MPAGE_DATA": {
                                  "PRSNL_ID": 123,
                                  "ELEMENT": [
                                      {
                                          "CDF_MEAN": "TEST1"
                                      },
                                      {
                                          "CDF_MEAN": "TEST2"
                                      }
                                  ]
                              }
                          }
 
                  Returns:
                      In both cases, this returns a JSON of this format:
                          {
                              "REPLY": {
                                  "STATUS_DATA":{
                                      "STATUS":"S",
                                      "SUBEVENTSTATUS":[
                                          {
                                              "OPERATIONNAME":"",
                                              "OPERATIONSTATUS":"",
                                              "TARGETOBJECTNAME":"",
                                              "TARGETOBJECTVALUE":""
                                          }
                                      ]
                                  }
                              },
                          }
 
                      Where the status_data can be ignored or checked for:
                          Failure    (status_data->status = 'F')
                          Success    (status_data->status = 'S')
                      with further details in status_data->status->subeventstatus on error
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 05/03/2018 Michael Mayes               Initial release
 
*************END OF ALL MODCONTROL BLOCKS* *******************************/
drop   program 0_maintain_cust_mpage_data:dba go
create program 0_maintain_cust_mpage_data:dba
 
prompt
    "Output to File/Printer/MINE" = "MINE",   ;* Enter or select the printer or file name to send this report to.
    "PRSNL_ID"                    = 0.0,
    "CDF_MEAN"                    = "",
    "DATA"                        = ""
with outdev, p_id, cdf_mean, data
 
 
/*************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
%i cust_script:mmm_mp_common_subs.inc
 
 
/*************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
free record mpage_data
record mpage_data(
    1 prsnl_id = f8
    1 element[*]
        2 cdf_mean = vc
        2 cv_value = f8
        2 data     = vc
%i cust_script:mmm_mp_status.inc
)
 
 
free record reply
record reply(
%i cust_script:mmm_mp_status.inc
)
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare err_code = i4 with protect, noconstant(0)
declare err_msg  = vc with protect, noconstant("")
declare idx      = i4 with protect, noconstant(0)
 
 
/*************************************************************
; DVDev Start Coding
**************************************************************/
 
set reply->status_data->status = 'F'
 
; Check for optional 5th param.  If found it should be a json string of several values to find and the prsnl_id.
if(reflect(parameter(5, 0)) > ' ')
    set stat = cnvtjsontorec(value(parameter(5, 0)))
else
    set stat = alterlist(mpage_data->element, 1)
 
    set mpage_data->prsnl_id             = $p_id
    set mpage_data->element[1]->cdf_mean = $cdf_mean
    set mpage_data->element[1]->data     = $data
endif
 
;I'm going to do a delete insert, because Cerner has problems with dup prefs, and even in my last
;persistence project at Cerner had duplicates drop out sometimes.  It would be nice to clean them
;up with normal mPage use.
 
/**********************************************************************
DESCRIPTION:  Delete older values if present
***********************************************************************/
delete
  from cust_mpage_data cmd
 where cmd.prsnl_id = mpage_data->prsnl_id
   and cmd.data_cd in (
       select cv.code_value
         from code_value cv
        where cv.code_set = 100705
          and expand(idx, 1, size(mpage_data->element, 5),
                          cv.cdf_meaning, mpage_data->element[idx].cdf_mean)
       )
with nocounter
 
set err_code = error(err_msg, 0)
if (err_code > 0)
    call WriteStatus('F', 'Deleting previous stored value', 'F', '0_MAINTAIN_CUST_MPAGE_DATA', err_msg, reply)
 
    go to exit_script
endif
 
 
/**********************************************************************
DESCRIPTION:  Find values using CDFMEAN
***********************************************************************/
select into 'nl:'
  from code_value cv,
       (dummyt d with seq = value(size(mpage_data->element, 5)))
 plan d
  where mpage_data->prsnl_id > 0.0
    and mpage_data->element[d.seq]->cdf_mean > ' '
 join cv
  where cv.code_set    = 100705
    and cv.cdf_meaning = mpage_data->element[d.seq]->cdf_mean
    and cv.active_ind  = 1
detail
    mpage_data->element[d.seq]->cv_value = cv.code_value
with nocounter
 
set err_code = error(err_msg, 0)
if (err_code > 0)
    call WriteStatus('F', 'Finding code_values', 'F', '0_MAINTAIN_CUST_MPAGE_DATA', err_msg, reply)
 
    go to exit_script
endif
 
;debugging
call echorecord(mpage_data)
 
 
/**********************************************************************
DESCRIPTION:  Insert the new values
***********************************************************************/
insert
  into cust_mpage_data cmd,
       (dummyt d with seq = value(size(mpage_data->element, 5)))
   set cmd.cust_mpage_data_id = SEQ(CUST_MPAGE_DATA_SEQ, NEXTVAL),
       cmd.data_cd            = mpage_data->element[d.seq]->cv_value,
       cmd.prsnl_id           = mpage_data->prsnl_id,
       cmd.value_txt          = mpage_data->element[d.seq]->data
 plan d
  where mpage_data->prsnl_id > 0.0
    and mpage_data->element[d.seq]->cdf_mean > ' '
 join cmd
with nocounter
 
set err_code = error(err_msg, 0)
if (err_code > 0)
    call WriteStatus('F', 'Inserting new values', 'F', '0_MAINTAIN_CUST_MPAGE_DATA', err_msg, reply)
 
    go to exit_script
endif
 
 
set reply->status_data->status = 'S'
 
 
/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
#exit_script
 
if(reply->status_data->status = 'S')
    commit
else
    rollback
endif
 
call putStringToFile($outdev, cnvtrectojson(reply))
 
end
go
 
