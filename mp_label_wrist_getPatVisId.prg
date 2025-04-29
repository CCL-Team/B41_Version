;set trace backdoor p30ins go
drop program mp_label_wrist_getPatVisId:group1 go
create program mp_label_wrist_getPatVisId:group1
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Encounter Id" = "128091894   "
	, "Person ID" = "22610775   "
	, "User Id" = "5706339"
 
with OUTDEV, ENCNTRID, PERSONID, USERID
 
SET  TRACE  =  SKIPPERSIST
SET  CCL_ENV  =  CNVTUPPER ( LOGICAL ("ENVIRONMENT_MODE" ))
IF ( ( CCL_ENV ="*PROD*" ) )
SET  TRACE  =  SKIPRECACHE
ELSE
SET  TRACE  =  NOSKIPRECACHE
ENDIF
 
SET  TRACE  =  RDBCOMMENT
SET  TRACE  =  ERROR
SET  MODIFY  MAXVARLEN 50000000
IF ( ( CURRDBUSER ="V500_MPAGE" ) )
 CALL ECHO ("command: rdb alter session set current_schema = v500 end" )
RDB  ALTER  SESSION  SET  CURRENT_SCHEMA  =  V500  END
ENDIF
 
 
set FIN_NBRR = "aaaaaaaaaaaaaaaa"
set MRN_NBRR = "aaaaaaaaaa"
set EE_NBRR = "aaaaaaaaaa"
set ORGG = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
set USER_ID = 3.0
set PRSON_ID = 4.0
set ENC_ID = 5.0
set USR_NAME = "YYYYYYYYYYYY"
declare SEX_R = vc
declare PT_NAME_R = vc
declare PT_LNAME_R = vc
declare PT_FNAME_R = vc
declare PT_MNAME_R = vc
declare PT_LNAMEANDSUFFIX_R = vc
declare PT_MNAMEANDSUFFIX_R = vc
declare PT_NAME_SUFFIX_R = vc
declare DOB_R = dq8
declare DOB_vc = vc
declare AGE_R = vc
declare REG_DT_TM_R = vc
declare ALIASPOOL_R = vc
 
 
SELECT INTO "nl:"
	FIN_NBR = trim(EA.ALIAS)
	, MRN_NBR = trim(ea1.alias)
	, EE_NBR = trim(cnvtalias(PA.alias,PA.alias_pool_cd))
	, ORG = REPLACE(UAR_GET_CODE_DISPLAY(ea.ALIAS_POOL_CD), " FIN", "")
	, E.ENCNTR_ID
	, E.ORGANIZATION_ID
	, REG_DT_TM = e.reg_dt_tm
	, p.SEX_CD
	, E_SEX_DISP = UAR_GET_CODE_DISPLAY(p.SEX_CD)
	, PT_NAME = p.name_full_formatted
	, DOB = p.birth_dt_tm
	, EA.ENCNTR_ID
	, EA_ENCNTR_ALIAS_TYPE_DISP = UAR_GET_CODE_DISPLAY(EA.ENCNTR_ALIAS_TYPE_CD)
	, USERNAME = L.USERNAME
	, L.NAME_FULL_FORMATTED
	, PT_LNAME = substring(1, 19, P.name_last)
	, PT_FNAME = substring(1, 10, P.name_first)
	, PT_MNAME = substring(1, 5, P.name_middle)
	, PT_NAME_SUFFIX = substring(1, 4, Pn.name_suffix)
	, ALIASPOOL = cv.display
 
FROM
	ENCOUNTER   E
	, ENCNTR_ALIAS   EA
	, ENCNTR_ALIAS   EA1
	, code_value cv
	, person   P
	, PRSNL   L
	, PERSON_ALIAS PA
	, PERSON_NAME PN
 
plan E
join EA
join EA1
join cv
join L
join P
join PA
join PN
where
E.encntr_id=EA.encntr_id
and E.encntr_id=ea1.encntr_id
and E.person_id=PA.person_id
and ea1.encntr_alias_type_cd=1079
AND ea1.ACTIVE_IND = 1
and ea.encntr_alias_type_cd=1077
AND ea.ACTIVE_IND = 1
and ea.alias_pool_cd=cv.code_value and cv.code_set=263 and cv.active_ind=1
AND PA.person_alias_type_cd=2
AND PA.active_ind=1
;and e.encntr_id=117082876
and e.encntr_id=cnvtreal($ENCNTRID)
;and L.person_id = 5706339
and L.person_id = cnvtreal($USERID)
and e.person_id=p.person_id
and e.person_id=PN.person_id and PN.name_type_cd=766 ;Current name
;Added by SAA126
AND EA.BEG_EFFECTIVE_DT_TM+0 <= CNVTDATETIME(curdate, curtime3)
AND EA.END_EFFECTIVE_DT_TM+0 >  CNVTDATETIME(curdate, curtime3)
AND EA1.BEG_EFFECTIVE_DT_TM+0 <= CNVTDATETIME(curdate, curtime3)
AND EA1.END_EFFECTIVE_DT_TM+0 >  CNVTDATETIME(curdate, curtime3)
AND PA.BEG_EFFECTIVE_DT_TM+0 <= CNVTDATETIME(curdate, curtime3)
AND PA.END_EFFECTIVE_DT_TM+0 >  CNVTDATETIME(curdate, curtime3)
AND PN.END_EFFECTIVE_DT_TM+0 >  CNVTDATETIME(curdate, curtime3)
 
/*; Commented to resolve an issue with organization alias not being mapped correctly.
 
SELECT INTO "nl:"
		FIN_NBR = trim(EA.ALIAS)
	, MRN_NBR = trim(ea1.alias)
	, ORG = NULLVAL(O.ALIAS, replace(cv.display, ' MRN', ''))
	, E.ENCNTR_ID
	, E.ORGANIZATION_ID
	, REG_DT_TM = e.reg_dt_tm
	, p.SEX_CD
	, E_SEX_DISP = UAR_GET_CODE_DISPLAY(p.SEX_CD)
	, PT_NAME = p.name_full_formatted
	, DOB = p.birth_dt_tm
	, EA.ENCNTR_ID
	, EA_ENCNTR_ALIAS_TYPE_DISP = UAR_GET_CODE_DISPLAY(EA.ENCNTR_ALIAS_TYPE_CD)
	, O.ORGANIZATION_ID
	, O_ORG_ALIAS_TYPE_DISP = UAR_GET_CODE_DISPLAY(O.ORG_ALIAS_TYPE_CD)
	, O_ORG_ALIAS_SUB_TYPE_DISP = UAR_GET_CODE_DISPLAY(O.ORG_ALIAS_SUB_TYPE_CD)
	, USERNAME = L.USERNAME
	, L.NAME_FULL_FORMATTED
	, PT_LNAME = P.name_last
	, PT_FNAME = P.name_first
	, ALIASPOOL = cv.display
 
FROM
	  ENCOUNTER   E
	, (left join ENCNTR_ALIAS   EA on E.encntr_id=EA.encntr_id and ea.encntr_alias_type_cd=1077 AND ea.ACTIVE_IND = 1)
	, (left join ENCNTR_ALIAS   EA1 on E.encntr_id=ea1.encntr_id and ea1.encntr_alias_type_cd=1079 AND ea1.ACTIVE_IND = 1)
	, (left join person P on e.person_id=p.person_id)
	, (left join PRSNL   L on L.person_id = cnvtreal($USERID))
	, (left join code_value cv on  ea1.alias_pool_cd=cv.code_value and cv.code_set=263 and cv.active_ind=1)
	, (left join ORGANIZATION_ALIAS O on E.organization_id=o.organization_id and o.org_alias_type_cd=1130 and  o.alias != '00000'
	 and o.active_ind=1)
where e.encntr_id=cnvtreal($ENCNTRID)
AND EA.BEG_EFFECTIVE_DT_TM+0 <= CNVTDATETIME(curdate, curtime3)
AND EA.END_EFFECTIVE_DT_TM+0 >  CNVTDATETIME(curdate, curtime3)
AND EA1.BEG_EFFECTIVE_DT_TM+0 <= CNVTDATETIME(curdate, curtime3)
AND EA1.END_EFFECTIVE_DT_TM+0 >  CNVTDATETIME(curdate, curtime3)
 */
detail
FIN_NBRR = FIN_NBR
MRN_NBRR = MRN_NBR
EE_NBRR = EE_NBR
ORGG = ORG
USER_ID = cnvtreal($USERID)
PRSON_ID = cnvtreal($PERSONID)
ENC_ID = cnvtreal($ENCNTRID)
USR_NAME = USERNAME
;PT_NAME_R = PT_NAME
PT_LNAMEANDSUFFIX_R = trim(concat(trim(PT_LNAME), "", trim(PT_NAME_SUFFIX)))
PT_MNAMEANDSUFFIX_R = trim(concat(trim(PT_MNAME), "", trim(PT_NAME_SUFFIX)))
;MAYES, moving this to Full name formatted... this is what the other data script is doing in hxr01_mp_getPatVisIdPlus.prg
;PT_NAME_R = trim(concat(trim(PT_LNAME), ", ", trim(PT_FNAME), "", trim(PT_MNAMEANDSUFFIX_R)))
PT_NAME_R = PT_NAME
PT_LNAME_R = PT_LNAME
PT_FNAME_R = PT_FNAME
PT_MNAME_R = PT_MNAME
PT_NAME_SUFFIX_R = PT_NAME_SUFFIX
SEX_R = E_SEX_DISP
AGE_R = cnvtage(DOB)
DOB_R = DOB
DOB_vc = DateBirthFormat(DOB,p.birth_tz,p.birth_prec_flag,"MM/dd/yyyy")
REG_DT_TM_R = format(reg_dt_tm,"MM/dd/yyyy HH:mm;3;d")
ALIASPOOL_R = ALIASPOOL
 
WITH MAXREC = 100, NOCOUNTER, SEPARATOR=" ", FORMAT
 
 
 
;execute eks_put_source with replace(Request,$ENCNTRID),replace(reply,$ENCNTRID)
 
 
 
free record JSON
record JSON (
      1 data = vc
)
 
 
SELECT
	name_full_formatted
 
FROM
	person
 
where person_id=21.00
 
;JSON->data = build2('{"errors":"', 'abc', '"}')
 
;set _memory_reply_string = JSON->data
;set _memory_reply_string = build2('{"errors":"', 'abc', '"}')
SELECT *
FROM ccl_report_audit   c
where c.object_name="mp_label_wrist_getPatVisId:group1"  ;object name for your CCL script
ORDER BY c.updt_dt_tm   DESC
WITH MAXREC = 100
 
 
;call echo(FIN_NBR)
 
;set _memory_reply_string = cnvtstring(cnvtreal($ENCNTRID))
;set _memory_reply_string = cnvtstring(cnvtreal(FIN_NBRR))
set foo = concat(trim(FIN_NBRR),"^",trim(ORGG),"^")
; can't figure out how to append to a string, so make a new variable
;set foo1 = concat(foo,trim(cnvtstring(cnvtreal(PRSON_ID))),"^",trim(cnvtstring(cnvtreal(USER_ID))),"^","yipkk")
set foo1 = concat(foo,trim(cnvtstring(cnvtreal(PRSON_ID))),"^",trim(USR_NAME),"^","yipkj")
set foo2 = concat(foo1,"^",trim(cnvtstring(cnvtreal(ENC_ID))))
set foo3 = concat(foo2,"^",trim(cnvtstring(cnvtreal(USER_ID))))
set foo4 = concat(foo3,"^",trim(MRN_NBRR),"^",trim(PT_NAME_R),"^",trim(SEX_R),"^",trim(AGE_R))
set foo5 = concat(foo4,"^",DOB_vc)
/*
commented below line to fix an issue with dob, pid:2016287
set foo5 = concat(foo4,"^",trim(cnvtstring(month(DOB_R))),"/",trim(cnvtstring(day(DOB_R))),"/",trim(cnvtstring(year(DOB_R))))
*/
set foo6 = concat(foo5,"^",trim(PT_LNAME_R),"^",trim(PT_FNAME_R),"^",trim(REG_DT_TM_R),"^",trim(ALIASPOOL_R),"^",trim(EE_NBRR))
;set foo = concat(foo,trim(cnvtstring(cnvtreal($USERID))),"^","yipeedoodahj")
;concat(trim(FIN_NBRR),"^",ORGG,"^",trim(cnvtstring(cnvtreal($PERSONID))),"^",trim(cnvtstring(cnvtreal($USERID))),"^","yipee")
set _memory_reply_string = foo6
;set _memory_reply_string = "abc"
;set _memory_reply_string = CCL_ENV
;call echo(_memory_reply_string)
 
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
end
go
 