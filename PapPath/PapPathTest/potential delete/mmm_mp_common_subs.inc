/**************************************************************************
 Include Title:   mp_common_subs
 
 Object name:     mp_common_subs
 Source file:     mp_common_subs.inc
 
 Purpose:
 
 Tables read:     
 
 Executed from:   MPage
 
 Special Notes:   Just common subroutines that mPage backend scripts utilize
 
***************************************************************************
                  MODIFICATION CONTROL LOG
***************************************************************************
Mod Date       Analyst              OPAS/MCGA     Comment
--- ---------- -------------------- --------- -----------------------------
001 02/20/2018 Michael Mayes        210739    Initial release
 
*************END OF ALL MODCONTROL BLOCKS* ********************************/

declare putStringToFile(out_loc = vc, in_str = vc(ref)) = null with protect


/***********************************************************************
NAME:                  putRSToFile
 
DESCRIPITON:           Use eks_put_source to write out a string to a file.
 
PARAMETER DESCRIPTION: out_loc (vc): Usually 'MINE', or coming from a prompt
                       out_rs  (rs): Record Structure to return, passed by ref
 
NOTES:                 $OUTDEV used to be specified as the out in the cerner
                       sub I stole this from, but that caused any script using
                       the include to have to be a prompt program.
 
************************************************************************/
subroutine putStringToFile(out_loc, out_rs)
	
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
    set eksrequest->document = cnvtrectojson(out_rs)
    set eksrequest->document_size = size(eksrequest->document)

    execute eks_put_source with replace(request,eksrequest), replace(reply, eksreply)
end