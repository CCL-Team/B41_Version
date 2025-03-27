/*************************************************************************
 Program Title:   Get Cust mPage Data
 
 Object name:     0_get_cust_mpage_data
 Source file:     0_get_cust_mpage_data.prg
 
 Purpose:         Gathers data from the cust_mpage_data table.  This data
                  is stored using a unique CDF_MEAN in CS 100705.
 
 Tables read:     CUST_MPAGE_DATA
 
 Executed from:   mPages
 
 Special Notes:   This can be called two ways:
                  Single value:
                      For a single value, you can fill out the first three params rather than building out a request JSON.
                      Those params are just:
                          outdev (usually 'MINE')
                          prsnl_id (the current user)
                          cdf_mean (the unique cdf_mean representing the data from code_set 100705)
                  Multi value:
                      This way ignores the PRSNL_ID and CDF_MEAN params in favor of a JSON coming in with multiple values to
                      retrieve.  You still send outdev, but the values in the other two params are disregarded.  A fourth param
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
                              "MPAGE_DATA": {
                                  "PRSNL_ID": 123,
                                  "ELEMENT": [
                                      {
                                          "CDF_MEAN": "TEST1",
                                          "DATA": "Test data 1"
                                      },
                                      {
                                          "CDF_MEAN": "TEST2",
                                          "DATA": "Test data 2"
                                      }
                                  ],
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
                          No Results (status_data->status = 'Z')
                      with further details in status_data->status->subeventstatus on error
 
**************************************************************************
                  MODIFICATION CONTROL LOG
**************************************************************************
Mod Date       Analyst              MCGA   Comment
--- ---------- -------------------- ------ -------------------------------
001 05/03/2018 Michael Mayes               Initial release
 
*************END OF ALL MODCONTROL BLOCKS* *******************************/
drop   program 0_get_cust_mpage_data:dba go
create program 0_get_cust_mpage_data:dba
 
prompt
    "Output to File/Printer/MINE" = "MINE",   ;* Enter or select the printer or file name to send this report to.
    "PRSNL_ID"                    = 0.0,
    "CDF_MEAN"                    = ""
with outdev, p_id, cdf_mean
 
 
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
        2 data     = vc
%i cust_script:mmm_mp_status.inc
)
 
 
/*************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
declare err_code = i4 with protect, noconstant(0)
declare err_msg  = vc with protect, noconstant("")
 
 
/*************************************************************
; DVDev Start Coding
**************************************************************/
set mpage_data->status_data->status = 'F'
 
 
; Check for optional 4th param.  If found it should be a json string of several values to find and the prsnl_id.
if(reflect(parameter(4, 0)) > ' ')
    set stat = cnvtjsontorec(value(parameter(4, 0)))
 
    set mpage_data->prsnl_id             = $p_id
else
    set stat = alterlist(mpage_data->element, 1)
 
    set mpage_data->prsnl_id             = $p_id
    set mpage_data->element[1]->cdf_mean = $cdf_mean
endif
 
 
;By now the mpage_data RS should be filled either with a single value to find, or multiple.
/**********************************************************************
DESCRIPTION:  Retrieves the value(s) from cust_mpage_data
***********************************************************************/
select into 'nl:'
  from cust_mpage_data cmd,
       code_value cv,
       (dummyt d with seq = value(size(mpage_data->element, 5)))
  plan d
   where mpage_data->element[d.seq]->cdf_mean > ' '
  join cv
   where cv.code_set    = 100705
     and cv.cdf_meaning = mpage_data->element[d.seq]->cdf_mean
     and cv.active_ind  = 1
  join cmd
   where cmd.prsnl_id = mpage_data->prsnl_id
     and cmd.data_cd  = cv.code_value
detail
    mpage_data->element[d.seq]->data = cmd.value_txt
with nocounter
 
if(curqual = 0)
    set mpage_data->status_data->status = 'Z'
endif
 
set err_code = error(err_msg, 0)
if (err_code > 0)
    call WriteStatus('F', 'Getting data', 'F', '0_GET_CUST_MPAGE_DATA', err_msg, mpage_data)
 
    go to exit_script
endif
 
 
set mpage_data->status_data->status = 'S'
 
/*************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
 
#exit_script
 
call echorecord(mpage_data)
 
call putStringToFile($outdev, cnvtrectojson(mpage_data))
 
end
go
 
