/*****************************************************************************
        Source file name:       32_krf_search_goal.prg
        Object name:            32_krf_search_goal
 
      	Application Analyst:	Kim Frazier
 
		NOTES: 					how to pull information from script for searching
______________________________________________________________________________________________
keywords:	rtl2 external file patstring wildcard search utility already exists read script files
;			javascript prompt
______________________________________________________________________________________________
As part of a long range plan for searching for an existing report/template before writing a new one,
this script looks in scripts matching a script name filter for keywords in the header/mod log of a script.
 
10/11/2021
Next step, when $script = 3, I want all the header text displayed, not just the matches.
can be done by adding a space to the keywords being searched for.
DONE
 
10/14/2021
Next step, limit search by a modified date range.
Also, add a prompt to select where to stop searching in the script.
DONE
 
10/19/21 next to do - add prompt search ccl_prompt_definitions
 DONE
 
11/16/2021 include includes in v2
 
consideration: option to include includes
				option to select just rule scripts ?
 
*************************************************************************************************/
drop program 32_krf_search_goal go
create program 32_krf_search_goal
 
prompt
	"Output to File/Printer/MINE" = "MINE"     ;* Enter all or part of the script name using wildcard(*) at start and/or end
	, "Script Name Filter" = "*"               ;* Example: *_CENSUS_*
	, "Search Keywords, Pipe Delimited" = ""   ;* Example: plan of care|stroke|frazier
	, "And Not text" = ""
	, "Code Value" = ""                        ;* Enter numeric value.
	, "Search by code_set:" = 0
	, "Display Key search text:" = ""
	, "Results:" = ""
	, "CCL Report/Script" = "1"
	, "Template Scripts (in 16529)" = "1"
	, "Prompt Search" = "0"
	, "Include Includes:" = "0"
	, "by Modified Date?" = "0"
	, "Start:" = "CURDATE"
	, "End:" = "CURDATE"
	, "How much script to search in:" = "2"
	, "What is returned:" = "2"                ;* Check to only see the script name, no header detail.
 
with OUTDEV, scriptfilter, textsearch, nottext, cv_cd, code_set, dkey,
	code_values_list, report_flag, st_flag, p_flag, inc_flag, bymodified, startmod, endmod,
	stoppoint, script
 
 
;if(curnode != "mhgrdcapp8")
;go to exitscript
;endif
 
declare tab = c1 with public,protect,constant(char(09))
declare rflag = c1 with public,protect
declare sflag = c1 with public,protect
if($report_flag = "1")
set rflag = "Y"
else
set rflag = "N"
endif
if($st_flag = "1")
set sflag = "Y"
else
set sflag = "N"
endif
if($p_flag = "1")
set pflag = "Y"
else
set pflag = "N"
endif
if($inc_flag = "1")
set incflag = "Y"
else
set incflag = "N"
endif
 
 
declare startchar = vc with constant(format(cnvtdate($startmod),"mm/dd/yyyy;;d"))
declare endchar = vc with constant(format(cnvtdate($endmod),"mm/dd/yyyy;;d"))
declare sdate = i4 with public,protect
declare edate = i4 with public,protect
set sdate = cnvtdate($startmod,A)
set edate = cnvtdate($endmod,A)
 
declare qual_text = vc with public,protect
if($textsearch = "NOT REQUIRED WHEN CV IS SELECTED" ) ;clean up the qualifier display
	set qual_text = "None"
else
	set qual_text = $textsearch
endif
 
declare qualifiers = vc with public,protect
set qualifiers = build2("File search: ",trim($scriptfilter), char(10),
						"Keywords: ", trim(qual_text), char(10),
						"AND Not: ", trim($nottext), char(10),
						"Reports: ", rflag, " ST: ", sflag,char(10),
						"Prompts: ",pflag,	char(10),
						"Includes: ", incflag, char(10)
						)
if($bymodified ="1")
	set qualifiers = build2(qualifiers,"Modified between ", startchar, " to ", endchar)
endif
 
;handle code_value search
declare this_cv_int = ui4 with public,protect,constant(cnvtint($cv_cd))
declare this_cv_display = vc with public,protect
declare this_cv_display_key = vc with public,protect
declare this_cv_meaning = vc with public,protect
declare this_cv_cki = vc with public,protect
declare this_cv_found = i2 with public,protect,noconstant(0)
 
if(cnvtint($cv_cd) > 0)
 
	select into "NL:" from code_value cv
	where cv.code_value = cnvtreal($cv_cd)
	detail
	qualifiers = build2(qualifiers,"Code Value: ", $cv_cd, " (",trim(cv.display) ,")" )
	this_cv_display = trim(cv.display)
	this_cv_display_key = trim(cv.display_key)
	this_cv_meaning = cv.cdf_meaning
	this_cv_cki = cv.cki
	with nocounter
	if(curqual = 0)
		set qualifiers = build2(qualifiers,"Code Value: ", $cv_cd, " (Invalid)" )
		go to
		 exitscript
	endif
 
	call echo(this_cv_int)
	call echo(this_cv_display)
	call echo(this_cv_display_key)
 
	call echo(this_cv_meaning)
else
	set this_cv_found = 1; default it to always look like it was found
endif
 
 
; My qualifier for output
record dummy(
 1 pick[2]
 	2 row =i2
 	2 qual = vc
 )
 set dummy->pick[1].row =  0
 set dummy->pick[1].qual = trim(qualifiers)
 set dummy->pick[2].row = 1
 set dummy->pick[2].qual = " "
 
; load My keywords to be searched for
free record keywords
record keywords(
	1 list[*]
		2 word = vc
		2 found = i2
		2 pi_found = i2
)
if($textsearch != "NOT REQUIRED WHEN CV IS SELECTED")
declare searchstring = vc with public,protect,noconstant(build2(trim($textsearch),"|"));add delimiter to end to help find last word
if($script = "3")
	set searchstring = build2(searchstring, " |") ;add a space to cause all text to pull in
endif
 
 
declare loc = i2 with public,protect
declare cnt = i2 with public,protect
declare startloc = i2 with public,protect
declare size = i2 with public,protect
set startloc = 1
 
if (textlen(searchstring) > 0)
	set loc = findstring("|",searchstring,startloc,0)
	while(loc > 0)
		set cnt = cnt + 1
		set stat = alterlist(keywords->list,cnt)
		set size =  (findstring("|",searchstring,(startloc+1),0) ) - startloc
		set keywords->list[cnt].word = cnvtupper(substring(startloc,size,searchstring))
		set startloc =  loc + 1
		set loc = findstring("|",searchstring,startloc,0)
	endwhile
 
endif
endif
;go to exitscript
 
free record scripts
record scripts(
	1 object[*]
	2 name= vc
	2 objname = vc
	2 inc_parent = vc
	2 pass = c1
	2 FOUND = c1
	2 row = i2
	2 MODIFIED_DT = I4
	2 modified_by = vc
)
 
 
declare cnt = i4 with public,protect
declare thisname = vc with public,protect
declare thisobj = vc with public,protect
declare thisincname = vc with public,protect
declare temp_filename = vc with public,protect
declare tot = i4 with public,protect
declare pi_tot = i4 with public,protect
 
set thisname = trim($scriptfilter)
 
/***************************************************************************************
*	GET SCRIPT NAMES MATCHING PARAMETER $SCRIPTFILTER
***************************************************************************************/
 
select into "NL:"
from dprotect d,
ccl_cust_script_objects cs
plan d
where d.object_name like PATSTRING(value(thisname))
join cs
where d.object_name = cs.object_name
 
and (	($report_flag = "1" and
		not exists(select cv.code_value from code_value cv
				where cv.code_set = 16529
					and cnvtupper(cv.definition) = cnvtupper(cs.object_name)
					and cv.cdf_meaning = "CLINNOTETEMP"
					)
		)
	or
		($st_flag = "1" and exists(select cv.code_value from code_value cv
				where cv.code_set = 16529
					and cnvtupper(cv.definition) = cnvtupper(cs.object_name)
					and cv.cdf_meaning = "CLINNOTETEMP"
					)
		)
	)
 
and (($bymodified = "1" and d.datestamp between sdate and edate)
	or $bymodified = "0"
	)
 
head report
cnt = 0
detail
cnt = cnt + 1
if(mod(cnt,100) = 1)
	stat = alterlist(scripts->object,cnt+100)
endif
 
scripts->object[cnt].name = trim(cs.object_name,3)
 scripts->object[cnt].row = 1
 scripts->object[cnt].MODIFIED_DT  = D.datestamp
 scripts->object[cnt].modified_by = d.user_name
 scripts->object[cnt].objname = trim(d.source_name,4)
foot report
stat = alterlist(scripts->object,cnt)
with nocounter, time=100
 
 
/***************************************************************************************
*	GET THE ACTUAL FILE NAME IN CUST_SCRIPT: FOLDER
***************************************************************************************/
declare x = i4 with public,protect
 
for(x = 1 to size(scripts->object,5))
 	if (not findfile(scripts->object[x].objname)) ;if I can't find the file, manually look for it, or pass
 
	set temp_filename = build2("cust_script:",cnvtlower(scripts->object[x].name),".prg")
	if (not findfile(temp_filename))
		set temp_filename = build2("cust_script:",cnvtlower(scripts->object[x].name),".ccl")
		if (not findfile(temp_filename))
			set scripts->object[x].pass = "1"; build2("notfound:",cnvtlower(scripts->object[x].name))
		else
			set scripts->object[x].objname = temp_filename
		endif
 
	else
		set scripts->object[x].objname = temp_filename
	endif
endif
endfor
 
; add a blank line to line up with the qualifier dummy table
;declare x = i2 with public,protect
;set x =size(scripts->object,5) +1
;set stat = alterlist( scripts->object,x)
;set scripts->object[x].name = ""
;set scripts->object[x].row = 0
;set scripts->object[x].found = "Y"
 
 
;how much to search
declare stopvalue = vc with public,protect
if($stoppoint = "1")
	set stopvalue = "dropprogram"
else
	set stopvalue = build2("bitterend:-)",format(curdate,"yyyyddmmhh;;d"));method to my madness
endif
 
;CAPTURE HEADERS/Detail lines AND WHAT SCRIPT THEY ARE IN
free record header
record header(
1 line[*]
	2 ldetail = vc
	2 lscript = vc
)
;CAPTURE PROGRAM INFO AND WHAT SCRIPT THEY ARE IN
free record programinfo
record programinfo(
1 line[*]
	2 ldetail = vc
	2 lscript = vc
)
DECLARE TEMPCONTENT = VC WITH PUBLIC,PROTECT
DECLARE thisphrase = VC WITH PUBLIC,PROTECT
DECLARE thisword = VC WITH PUBLIC,PROTECT
declare cnt = i4 with public,protect
/***************************************************************************************
*	SEARCH SCRIPT/PROG INFO FOR EACH SCRIPT FOUND
***************************************************************************************/
 
 set x = 1
 call echo(size(scripts->object,5))
while (x <= size(scripts->object,5) and x < 20000) ;for each script & failsafe max
call echo(x)
; call echo(size(scripts->object,5))
	if(scripts->object[x].pass != "1") ;skip on pass
		SET inccnt = 0;RESET TO 0 EACH SCRIPT
	    set thisname = scripts->object[x].name
	    set thisobj = scripts->object[x].objname
	    if(this_cv_int > 0) ;reset the found flag only if code_value is searched for
	    	set this_cv_found = 0
	    ELSE
	    	SET THIS_CV_FOUND = 1 ;BY DEFAULT
	    endif
 
		free define rtl2
		DEFINE RTL2 IS thisobj;format is "cust_script:32_smh_total_joint_rpt.prg"
 
;	call echo(build2("search this Script: ",thisobj))
 
		SELECT into "nl:"
		mystring =trim(R.LINE,3)
		FROM RTL2t R
		plan r
		head report
		cnt = size(header->line,5)
		stat = alterlist(header->line,cnt+30)
		lcnt = 0
		stopfound = 0
		detail
		if(stopfound = 0) ;stop looking when you find the "drop program" or "bitter end" commands
		stopfound = findstring(stopvalue,cnvtalphanum(cnvtlower(mystring),2),1,0)
 
		if(lcnt < 5000 and stopfound = 0) ;only look at 1st 5000 lines
			lcnt = lcnt + 1
			for (y = 1 to size(keywords->list,5)) ;for every line, look for each keyword
				line_out_flag = 0
				if( findstring(keywords->list[y].word,cnvtupper(mystring) ,0,0))
 
				if((textlen($nottext) > 0 and findstring($nottext ,cnvtupper(mystring),0,0) = 0)
					or textlen($nottext) = 0)
					cnt = cnt + 1
					if(size(header->line,5) < cnt)
						stat = alterlist(header->line,cnt+30)
					endif
 
					header->line[cnt].lscript = thisname
					header->line[cnt].ldetail = build2(trim(format(lcnt,"####;P0")), ": ", trim(cnvtupper(mystring)))
					keywords->list[y].found = 1
 					line_out_flag = 1
				endif
				endif
 
			endfor ;for each keyword
 
		;INCLUDES
 
				if($inc_flag = "1") ;IF include is checked, look for an include in each line
				;stat = alterlist(incscripts->object,0) ;clear the list
 
				 if( thisobj not like "*.inc*"
				 	and findstring("%I",cnvtupper(mystring),0,0)
				 	and not findstring(";%I",cnvtupper(mystring),0,0))
				 	loc = findstring(".INC",cnvtupper(mystring),0,0)
				 	if(loc > 0)
				 		thisscript = trim( substring(1,loc+4,cnvtupper(mystring)))
;				 		call echo(thisscript)
;				 		call echo(thisobj)
;				 		call echo(x)
				 		;stat = alterlist(incscripts->object,inccnt)
				 		include_text = trim(substring(0, findstring(" ",mystring,1,0), mystring)); = the include phrase,%I or %include
				 		include_text = replace(mystring,trim(include_text) ,"")	;= the script - include phrase
						loc = findstring(";",include_text,1);to remove any comments
						if(loc > 0) ;found a comment
							include_text = substring(0,loc-1,include_text) ; = the script - comments
						endif
						loc = findstring(":",include_text,0)
						thisincname = substring(loc +1, size(include_text,3)-loc,include_text)
						cursize = size(scripts->object,5)
						stat = alterlist(scripts->object,cursize + 1);insert at the end
						scripts->object[cursize+1].name = thisincname;get script name without path
						scripts->object[cursize+1].objname =trim( include_text ,3)
			 			scripts->object[cursize+1].row  = 1
			 			scripts->object[cursize+1].inc_parent = build2(trim(thisOBJ),":")
			 			scripts->object[cursize+1].MODIFIED_DT = 73050
 						scripts->object[cursize+1].modified_by ="INCLUDED"
;				 		call echo(scripts->object[cursize+1].objname)
				 	endif
				 endif
				endif
 
 
		;CODEVALUE
			;for each line, check for code value search criteria if prompt exists
 
			if(this_cv_int > 0 )
;			call echo( build2("searching: ",mystring))
;			CALL ECHO(BUILD2("LOC=",findstring(trim(cnvtstring(this_cv_int,12,0)),mystring,1,0)))
				if(findstring(this_cv_display_key,mystring,0,0) ;look for display_key
					or findstring(this_cv_display,mystring,0,0) ;or display
					or findstring(trim(cnvtstring(this_cv_int,12,0)),mystring,1,0)		;or code_value
					or (findstring(this_cv_meaning,mystring,0,0) and this_cv_meaning > "")	;meaning
					or (findstring(this_cv_cki,mystring,0,0) and this_cv_cki > "")	;cki
					)
					;found code_value
;					call echo("FOUND in my cv string")
					if(	line_out_flag = 0) ;don't write if already written from word search
					cnt = cnt + 1
					if(size(header->line,5) < cnt)
						stat = alterlist(header->line,cnt+30)
					endif
					header->line[cnt].lscript = thisname
					header->line[cnt].ldetail = build2(trim(format(lcnt,"####;P0")), ": ", trim(cnvtupper(mystring)))
					endif
					this_cv_found = 1 ;turn on when found, off once per script
 				endif
			endif ;if search by code_value
		endif ;line count/stop
 
		endif ;stopfound
		foot report
		stat = alterlist(header->line,cnt)
		with nocounter, time=100
 
 
 call echo("finished word search")
		;check keyword list to see if I found them all
		;clear keyword list found flag before the next script
		set tot = 0
		for (k = 1 to size(keywords->list,5))
			set tot = tot + keywords->list[k].found
			;set keywords->list[k].found =  0 ;CLEAR
		endfor
		if(tot = size(keywords->list,5) or (this_cv_found and this_cv_int > 0)) ;found them all, or CV, flag it for display
			set scripts->object[x].found = "Y"
		endif
		set tot = 0
 
	endif; file wasn't found, pass
 
 
 ; BUT WAIT, THERE'S MORE - Prompt search if flag checked
 if(thisname > " ")
 
  ; GET PROMPT DATA
	if($p_flag = "1") ;prompt search next
		select into "NL:"
		mystring = build2("$",trim(pd.prompt_name),"-",trim(pd.display), " ", trim(pd.description ))
		from ccl_prompt_definitions pd
		where cnvtupper(pd.program_name) =  thisname
		order by pd.program_name,pd.position
		head report
		cnt =size(header->line,5)
		detail
		for (y = 1 to size(keywords->list,5)) ;for every line, look for each keyword
				line_out_flag = 0
			if( findstring(keywords->list[y].word,cnvtupper(mystring) ,0,0))
 
				if((textlen($nottext) > 0 and findstring($nottext ,cnvtupper(mystring),0,0) = 0)
					or textlen($nottext) = 0)
					cnt = cnt + 1
					if(size(header->line,5) < cnt)
						stat = alterlist(header->line,cnt+30)
					endif
					header->line[cnt].lscript = thisname
					header->line[cnt].ldetail = build2("PMPT: ", trim(mystring))
					keywords->list[y].found = 1
				endif
			endif
		endfor
 
		with nocounter
 		set tot = 0
		for (k = 1 to size(keywords->list,5))
			set tot = tot + keywords->list[k].found
			;set keywords->list[k].found =  0 ;CLEAR
		endfor
		if(tot = size(keywords->list,5) and this_cv_found) ;found them all, flag it for display
			set scripts->object[x].found = "Y"
		endif
		set tot = 0
	endif
 
; GET PROGRAM INFORMATION DATA
 	set pi_tot = 0 ;clear counter before starting this script
 
	select into "NL:"
	from ccl_prompt_file def ;has a row for each prompt item
	where def.file_name = THISNAME
	order by def.collation_seq
	head report
	tempcontent = " "
	tot = 0
	sloc = 0
	eloc = 0
 
	iterations = 0
	next = " "
	thisphrase = " "
	thisword = " "
	DETAIL
	TEMPCONTENT = BUILD2(TEMPCONTENT, TRIM(DEF.CONTENT))
	FOOT REPORT
	sLOC = FINDSTRING("%%description%%",tempcontent,0,0)
	eLOC = findstring("%%end-description%%", tempcontent,sloc,0)
	tempcontent = substring(sloc+15, eloc-(sloc+15),tempcontent)
;	call echo(tempcontent)
	for (k = 1 to size(keywords->list,5))
		if(findstring(keywords->list[k].word,cnvtupper(tempcontent),0)> 0)
			if((textlen($nottext) > 0 and findstring($nottext,cnvtupper(tempcontent),0)=0)
				or textlen($nottext) =0)
				keywords->list[k].pi_found = 1
				keywords->list[k].found = 1
				call echo("FOUND ONE")
			endif
		endif
	endfor
	tot = 0
	for (k = 1 to size(keywords->list,5))
		tot = tot + keywords->list[k].found
		pi_tot = pi_tot + keywords->list[k].pi_found
		keywords->list[k].found =  0 ;CLEAR
		keywords->list[k].PI_found =  0 ;CLEAR
	endfor
	if(tot = size(keywords->list,5);found them all,
		and pi_tot > 0) ;and one in PI data, flag script for display
		scripts->object[x].found = "Y"
 
; trim off formatting codes
		iterations = 0 ;failsafe
		sloc = findstring(" ",tempcontent,0,0)
		while(sloc > 0 and iterations < 200)
			cnt = sloc + 1
			next = substring(cnt,1,tempcontent) ;one char at a time
			while(next not in ("\","%")
				and cnt <= textlen(tempcontent))
 
				thisword = build2(thisword, next)
				cnt = cnt + 1
				next  = substring( cnt,1,tempcontent)
			endwhile
			thisword = substring( sloc, cnt - sloc,tempcontent)
			thisphrase = build2(thisphrase ," ",thisword)
			thisword = ""
			sloc = findstring(" ",tempcontent,cnt,0)
			iterations += 1
 
		endwhile
 
		cnt = size(header->line,5)
		cnt += 1
		stat = alterlist(header->line,cnt)
		if(thisphrase > " ")
			header->line[cnt].ldetail =build2("INFO: ",trim(thisphrase))
			header->line[cnt].lscript =thisname
		endif
 
	endif
	with nocounter, time=100
 
 
 endif
 set x=x+1
endwhile ;while scripts exist
 
;add a blank like to cause the qualifier to print
set cnt = size(header->line,5)
set stat = alterlist(header->line, cnt+1)
 
; add a blank line to line up with the qualifier dummy table
declare x = i2 with public,protect
set x =size(scripts->object,5) +1
set stat = alterlist( scripts->object,x)
set scripts->object[x].name = ""
set scripts->object[x].row = 0
set scripts->object[x].found = "Y"
 
/***************************************************************************************
*	OUTPUT THE RESULTS
***************************************************************************************/
call echorecord(header)
 
 
select distinct into $outdev
qualifiers = dummy->pick[dq.seq].qual
, script = substring(1,120,build2(scripts->object[d.seq].inc_parent, trim(scripts->object[d.seq].objname )))
;,script = substring(1,50,trim(header->line[dh.seq].lscript))
,Modified = od.date_str
,Modified_by = scripts->object[d.seq].MODIFIED_by
, Text = evaluate2(
		if($script != "1"); write blank when only scripts names are requested
		substring(1,200,header->line[dh.seq].ldetail )
		else " "
		endif
		)
from
(dummyt dq with seq = 2),
(dummyt d with seq = size(scripts->object,5)) ,
(dummyt dh with seq = size(header->line,5))
,omf_date od
plan dq
join d
where scripts->object[d.seq].row = dummy->pick[dq.seq].row
and scripts->object[d.seq].FOUND = "Y"
join dh
where scripts->object[d.seq].name = header->line[dh.seq].lscript
join od
where od.dt_nbr = scripts->object[d.seq].modified_dt
order by  dummy->pick[dq.seq].row,script,text
with NOCOUNTER,format,separator= " "
call echorecord( keywords)
call echorecord(scripts)
free record keywords
free record header
free record scripts
#exitscript
 
end go
;OUTDEV, scriptfilter, textsearch, nottext,cv_cd, report_flag, st_flag, p_flag,inc_flag,
					;bymodified, startmod, endmod,stoppoint,  outputscript
 
;execute 32_krf_search_goal "MINE","19*","DYSTOCIA|RISK","","",0.00,"","","1","0","0","0", "0","", "","2","2" go
