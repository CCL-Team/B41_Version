/********************************************************************************************************************************
 Date Written:   
 Program Title:  
 Source file:	   15_st_cm_progress_note_hist_04.prg
 Object name:	   15_st_cm_progress_note_hist_04
 Directory:		   CUST_SCRIPT:
 DVD Version:	   
 HNA Version:
 CCL Version:	   
 Purpose:        
 Tables read:	 
 Tables updated: 
 Executed from:	 
 Special Notes:  Cycle all instances of Server 50, 51, 55, 56, 58, and 80. Note: It is not necessary to cycle Server 52 (and not 
                 recommended, because it refreshes by default, about every 15 minutes).
 
*********************************************************************************************************************************
 MODIFICATION CONTROL LOG
*********************************************************************************************************************************
 Mod   Date        By               Request           Comment
 ----  ----------- ---------------  --------------    ---------------------------------------------------------------------------
 001   08/04/2022  Troy Shelton    			              Initial release
 002   09/30/2022  Troy Shelton     INC14667003
 003   10/04/2022  Troy Shelton     INC14667003       Revising blob section.
 004   03/08/2023  Troy Shelton                       Add who performed and their role.

 Mod 001:
 Initial release
 
 Mod 002: 
 Issue reported. Some event_ids (blobs) are not displaying in smart template. It may be due to unidentified special
 character(s) or the amount of information charted. For pt with FIN # 5039960991, there are over 15 notes to combine. 
 It only displays the last four notes, then cuts off. Will create a new version.
 
 Mod 003: 
 Revised blob section. Break up the blob in small segments, then save it to record structure.
 
 Mod 004:
 Add who performed and their role.
 
 MOD 005:
 12/12/2023		Kim Frazier
 MCGA 345152 break/fix to eliminate in errored documents
 
********************************************************************************************************************************/

drop program 15_st_cm_prog_note_hist_04 go
create program 15_st_cm_prog_note_hist_04

prompt
"Output to File/Printer/MINE" = "MINE"
WITH OUTDEV

record reply (
  1 text = vc
  1 format = i4
)

free record tmp
record tmp (
  1 encntr_id = f8
  1 person_id = f8
)

;--------------------------------------------------------------------------------------------------------------------------------
; Get Patient
;--------------------------------------------------------------------------------------------------------------------------------
declare xxenc = f8
if(validate(request->visit[1]->encntr_id))
  set xxenc = request->visit[1]->encntr_id
else
  set xxenc = 183123786.00 ; for debugging ;READMISSIONS, PATCHONE	32824123	203615901
endif

select into "nl:"
from encounter e
plan e
  where e.encntr_id = xxenc
detail
  tmp->encntr_id = e.encntr_id
  tmp->person_id = e.person_id
with nocounter
 
call echo(tmp->person_id)
call echo(tmp->encntr_id)

record BLOB_REC (
  1 ELIST [*]  
    2 NAME = vc   
    2 sDATE = vc
    2 dDATE = dq8
    2 by_who = vc   ; mod 004   
    2 BLOB [*]  
      3 SEQU = I2   
      3 line = vc   
) 

;Declare variable to index ELIST
DECLARE CNT = I2
SET CNT = 0

/**************************************************************
; Declare RTF Formatting Working Variables
**************************************************************/

SET  RHEAD  =
"{\rtf1\ansi \deff0{\fonttbl{\f0\fswiss Arial;}}{\colortbl;\red0\green0\blue0;\red255\green255\blue255;}\deftab1134"

;set rhead = concat("{\rtf1\ansi \deff0{\fonttbl{\f0\fswiss MS Sans Serif;}}",
;                   "{\colortbl;\red0\green0\blue0;\red255\green255\blue255;}\deftab1134")

SET  RH2R  = "\plain \f0 \fs18 \cb2 \pard\sl0 "
SET  RH2B  = "\plain \f0 \fs18 \b \cb2 \pard\sl0 "
SET  RH2BU  = "\plain \f0 \fs18 \b \ul \cb2 \pard\sl0 "
SET  RH2U  = "\plain \f0 \fs18 \u \cb2 \pard\sl0 "
SET  RH2I  = "\plain \f0 \fs18 \i \cb2 \pard\sl0 "
SET  REOL  = "\par"
SET  RTAB  = "\tab"
SET  RTAB2  = "    "
SET  WR  = "\plain \f0 \fs18 \cb2"
SET  WB  = "\plain \f0 \fs18 \b \cb2"
SET  WU  = "\plain \f0 \fs18 \ul \cb2"
SET  WI  = "\plain \f0 \fs18 \i \cb2"
SET  WBI  = "\plain \f0 \fs18 \b \i \cb2"
SET  WIU  = "\plain \f0 \fs18 \i \ul \cb2"
SET  WBIU  = "\plain \f0 \fs18 \b \ul \i \cb2"
SET  RTFEOF  = "}"

;***** Declare blob working variables
DECLARE OCFCOMP_VAR = f8 WITH Constant(uar_get_code_by("MEANING",120,"OCFCOMP")),protect
DECLARE good_blob = vc WITH protect
DECLARE print_blob = c100 WITH protect
DECLARE outbuf = c32768  WITH protect
DECLARE blobout = vc WITH protect
;uar_rtf2() requires a pre-allocated fixed length character variable FOR the output buffer so declaring BlobNoRTF as c32768
;will use MemReAlloc() in report writer to resize to length of uncompressed blob
DECLARE  BlobNoRTF = c32768; c100 WITH protect
  
DECLARE retlen = i4 WITH protect
DECLARE offSET = i4 WITH protect
DECLARE newsize = i4 WITH protect
DECLARE nortfsize = i4 WITH protect
DECLARE finlen = i4 WITH protect
DECLARE xlen=i4 WITH protect

/***********************************************************************
		FIRST QUERY TO GATHER DATA
***********************************************************************/
SELECT INTO "NL:" ;$outdev ;
	ce.clinical_event_id
	, ce.encntr_id
	, cb.event_id
	, cb.blob_seq_num
	, cb.BLOB_LENGTH
	, ce.EVENT_TITLE_TEXT
	, ce.performed_dt_tm
  , role = uar_get_code_display(epr.encntr_prsnl_r_cd)   ; mod 004

FROM
	ce_blob   cb
	, clinical_event   ce
	, prsnl p  ; mod 004
  , encntr_prsnl_reltn epr  ; mod 004

;and ce.event_cd = 3695488539.00	;  3695488539.00	CM Progress Note in P41

;PLAN ce WHERE  CE.EVENT_CD =  1135991787.00	; CIR CM Discharge Progress Note in B41
PLAN ce WHERE  CE.EVENT_CD = 3695488539.00 ; Case Management Progress Note

	AND ce.person_id = tmp->person_id
	AND ce.encntr_id = tmp->encntr_id
	;For testing qualifying on specific event_ids
	;ce.event_id in (25680280.00, 26790291.00, 52212337.00)
	;the following qualification gets only the valid rows and prevents getting duplicates from the CE_BLOB table
	AND ce.VALID_FROM_DT_TM < cnvtdatetime(curdate,curtime3)
	AND ce.VALID_UNTIL_DT_TM > cnvtdatetime(curdate,curtime3)
	
	JOIN cb WHERE ce.event_id = cb.event_id
	;some processes appear to write new rows when the blob is updated
	;the old rows will have a valid_until_dt_tm beFORe the current date/time
	;the following qualification gets only the valid rows
	AND cb.VALID_FROM_DT_TM < cnvtdatetime(curdate,curtime3)
	AND cb.VALID_UNTIL_DT_TM > cnvtdatetime(curdate,curtime3)
	AND cb.compression_cd = ocfcomp_var
	AND ce.view_level = 1
	AND ce.result_status_cd NOT IN ( 14, 13, 25572) ;--In Error, In Progress, Not Done
	and ce.event_title_text not = "Date\Time Correction" ;005
  	and ce.event_title_text not = "In Error" ;005 

;below ensures that only the single most recent entry is returned. 
;	AND ce.performed_dt_tm = (SELECT max(c.performed_dt_tm)
;							  FROM clinical_event c
;							  WHERE c.person_id = PERSON_ID_VAR
;						  	  AND C.EVENT_CD = 3695488539.0
;							  AND c.VALID_FROM_DT_TM < cnvtdatetime(curdate,curtime3)
;							  AND c.view_level = 1
;							  AND c.result_status_cd NOT IN ( 14, 13, 25572) ;--In Error, In Progress, Not Done
;							 )

join p
where p.person_id = ce.performed_prsnl_id
join epr
 where epr.encntr_id = outerjoin(ce.encntr_id)
	and epr.prsnl_person_id = outerjoin(p.person_id)
	and epr.active_ind = outerjoin(1)
	and epr.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime))
	
ORDER BY
	CE.performed_dt_tm DESC
	, ce.encntr_id
	, cb.event_id
	, cb.blob_seq_num

HEAD cb.event_id
	;write event title and date to record structure
	CNT += 1
	IF(MOD(CNT,10)=1)
		CALL ALTERLIST(BLOB_REC->ELIST, CNT + 9)
	ENDIF
	BLOB_REC->ELIST[CNT].NAME =  ce.EVENT_TITLE_TEXT
	
	BLOB_REC->ELIST[CNT].sDATE = format(ce.performed_dt_tm ,"@SHORTDATETIME")
	BLOB_REC->ELIST[CNT].dDATE = ce.performed_dt_tm
	
  if(role > " ")
  	BLOB_REC->ELIST[CNT].by_who = build2(trim(p.name_full_formatted)," (",trim(role),")") 
  else
  	BLOB_REC->ELIST[CNT].by_who = trim(p.name_full_formatted)
  endif
	
	;*****START CODE TO WRAP TEXT AND STORE TEXT IN RECORD STRUCTURE*****
	
	;reset the blob processing variables for each event_id
	blobout = " " 
	outbuf = " "
	good_blob = " "
	blobnortf = " "
	
	;initialize blobout to a size that will be large enough to hold the full uncompressed blob
	;initialize space FOR the 32k segments
	FOR (x = 1 to (cb.blob_length/32768) )
		blobout = notrim(concat(notrim(blobout),notrim(fillstring(32768, " "))))
	ENDFOR
	
	;initialize space for the final segment.  the final segment will less than 32k.
	finlen = mod(cb.blob_length,32768)
	blobout = notrim(concat(notrim(blobout),notrim(substring(1,finlen,fillstring(32768, " ")))))
	
DETAIL
	;initialize working variables
	retlen = 1
	offSET = 0
	
	; get the blob segments and concat them into a single variable named good_blob
	; the following WHILE loop is used in case the blob_contents is actually more than 32k
	; in most cases the WHILE loop will only be executed one time because the blob is stored
	; in 32k segments
	WHILE (retlen > 0)
		; ***  this gets a segment of the blob up to 32000 specified by retlen, offSET is an accum of retlen
		retlen = blobget(outbuf, offSET, cb.blob_contents)
		offSET = offSET + retlen
			IF(retlen!=0)
				; when dealing with CE_BLOB each row is ended WITH the tag "ocf_blob"
				; these tags need to be excluded when the blob segments are re-assembled
				xlen = findstring("ocf_blob",outbuf,1)-1
				
				IF(xlen<1)
					xlen = retlen
				ENDIF
				
				good_blob = notrim(concat(notrim(good_blob), notrim(substring(1,xlen,outbuf))))
			ENDIF
	ENDWHILE
	
FOOT cb.event_id
	
	newsize = 0
	
	; put the ocf_blob terminator back on the end of the re-assembled blob
	good_blob = concat(notrim(good_blob),"ocf_blob")
	
	; uncompress the re-assembled blob. The uncompressed blob is assigned to the blobout variable.
	; additional processing on the uncompressed blob can be done using the blobout variable
	blob_un = uar_ocf_uncompress(good_blob, size(good_blob), blobout, size(blobout),newsize )  
	                 
	;reallocate BlobNoRTF to a fixed length character variable that is the size of blobout
	stat = memrealloc(BlobNoRTF,1,build("c",size(blobout)))
	;call echo(build("size of BlobNoRTF:",size(BlobNoRTF))) <--- use for testing
	
	;*** use uar_rtf2 to strip the rtf from the blob. The uncompressed blob without the rtf is assigned to BlobNoRTF
	stat = uar_rtf2(blobout,size(blobout),BlobNoRTF,size(BlobNoRTF),nortfsize,1)
	
	;use modified code from cclsource:vcclrtf.inc -> subroutine:cclrtf_printline
	par_numcol = 120 			;width to display the blob
	blob_out = blobNoRTF 		;blob section to print
	blob_len = size(BlobNoRTF)  ;length of current blob section
	
	
	;working variables for text wrap
	m_cc = 1
	textindex = 0
    numcol = par_numcol
    whiteflag = 0     
    printcol = 0
    rownum = 0
    lastline = 0
    m_linefeed = concat(char(10))
    numLines = 0

	WHILE (blob_len > 0)
		;check if blob_length is small enough to fit on one line (par_numcol)
	    IF (blob_len <= par_numcol)
	       numcol = blob_len
	       lastline = 1
	    ENDIF
	    textindex = m_cc + par_numcol 
	
	    IF (lastline = 0)
	        ; find last white space prior to max line width so words are not split at EOL
	        whiteflag = 0
	        WHILE (whiteflag = 0)                        
	           IF ((substring( textindex, 1, blob_out ) = " ") OR
	               (substring( textindex, 1, blob_out ) = m_linefeed) )          
	                whiteflag = 1
	           ELSE
	                textindex = textindex - 1
	           ENDIF
	           IF (textindex = m_cc OR textindex = 0)
	                textindex = m_cc + par_numcol
	                whiteflag = 1
	           ENDIF
	        ENDWHILE      
	        numcol = textindex - m_cc + 1
	    ENDIF
	
	    m_blob_buf = substring(m_cc, numcol, blob_out)        
	    IF (m_blob_buf > " ")
	        numLines = numLines + 1
			;print lines here
			
			;allocate memory for record stucture BLOB list
			IF(MOD(numLines,10)=1)
				CALL ALTERLIST( BLOB_REC->ELIST[cnt].BLOB, numLines + 9)
			ENDIF
			;write into record structure
			lineBlob = trim( check( m_blob_buf ) ) ;trim(m_blob_buf)
			BLOB_REC->ELIST[cnt].BLOB[numlines].line =lineBlob
			BLOB_REC->ELIST[cnt].BLOB[numlines].SEQU = numlines
	    ELSE
	        blob_len = 0
	    ENDIF
	    m_cc = m_cc + numcol
	    IF (blob_len > numcol)
	        blob_len = blob_len - numcol
	    ELSE
	        blob_len = 0
	    ENDIF
	ENDWHILE
	
	;resize BLOB list to match number of lines
	CALL ALTERLIST( BLOB_REC->ELIST[cnt].BLOB, numLines)
   
FOOT REPORT
	;resize ELIST to match number of events
	CALL ALTERLIST(BLOB_REC->ELIST, CNT)

CALL ECHORECORD(BLOB_REC) ;<--- use for testing
WITH MAXREC = 1000, RDBARRAYFETCH = 1, time = 30


/***********************************************************************
		SECOND QUERY TO DISPLAY DATA AND SEND TO POWERCHART
***********************************************************************/
;Send title of text to PowerChart
;SET REPLY->TEXT = CONCAT(RHEAD, RH2BU, "Case Mgmt Progress Notes", WR, REOL, REOL)
SET REPLY->TEXT = CONCAT(RHEAD, WR) ; RTF header only. 

;Check if any blob data was retrived. CNT will only be greater than one if a record is returned via "HEAD cb.event_id"
;If CNT = 0, then *** No Results Found *** is sent to PowerChart
IF (CNT > 0)
 
SELECT INTO "NL:" ; $outdev ; 
	ELIST_NAME = SUBSTRING(1, 30, BLOB_REC->ELIST[D1.SEQ].NAME)
	, ELIST_DATE = SUBSTRING(1, 30, BLOB_REC->ELIST[D1.SEQ].sDATE)
	, ELIST_DDATE = BLOB_REC->ELIST[D1.SEQ].dDATE
	, BLOB_SEQU = BLOB_REC->ELIST[D1.SEQ].BLOB[D2.SEQ].SEQU
	, BLOB_LINE = SUBSTRING(1, 30, BLOB_REC->ELIST[D1.SEQ].BLOB[D2.SEQ].line)

FROM
	(DUMMYT   D1  WITH SEQ = SIZE(BLOB_REC->ELIST, 5))
	, (DUMMYT   D2  WITH SEQ = 1)

PLAN D1

 WHERE MAXREC(D2, SIZE(BLOB_REC->ELIST[D1.SEQ].BLOB, 5))
JOIN D2

ORDER BY
	ELIST_DDATE desc

HEAD ELIST_DDATE
;	COL 0 BLOB_REC->ELIST[D1.SEQ].NAME
;	COL 45 BLOB_REC->ELIST[D1.SEQ].DATE
;	ROW + 1
;	;reply->text = concat(reply->text, RH2R, "{",BLOB_REC->ELIST[D1.SEQ].NAME , "}", wr, REOL) 
reply->text = concat(reply->text, RH2R, "{", BLOB_REC->ELIST[D1.SEQ].SDATE, " by ", BLOB_REC->ELIST[D1.SEQ].by_who , "}", wr, REOL)
	

DETAIL
;	COL 0 BLOB_REC->ELIST[D1.SEQ].BLOB[D2.SEQ].SEQU
;	COL 20 BLOB_REC->ELIST[D1.SEQ].BLOB[D2.SEQ].line
;	ROW + 1

	reply->text = concat(reply->text, RH2R, "{", BLOB_REC->ELIST[D1.SEQ].BLOB[D2.SEQ].line, "}", wr ,REOL)
	
FOOT ELIST_DDATE
	;ADD SPACER ROW BETWEEN RECORDS
	reply->text = concat(reply->text, RH2R, "{", "   ", "}", wr, REOL)

WITH MAXREC = 1000, NOCOUNTER, SEPARATOR=" ", FORMAT, time = 30

ELSE
	SET reply->text = concat(reply->text, RH2R, "{", " *** No Results Found ***", "}", wr ,REOL)
ENDIF

SET REPLY->TEXT = concat (reply->text, RTFEOF)

call echorecord(reply)
;call echojson(reply->text, $outdev)

#EXIT_SCRIPT

end
go


