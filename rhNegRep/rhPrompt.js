var theForm = null;

function onLoad() {

    theForm = new DiscernForm();

    // insert event handlers

    theForm.ORG_SEARCH_BUT.onClick   = orgSearchClick;
    theForm.PROV_SEARCH_BUT.onClick  = provSearchClick;

}

function orgSearchClick(sender){
    var orgSearchVal = theForm.ORG_SEARCH.value;
    var oldOrgVal    = theForm.ORG_IDS.value;  //This is a bell (7) char separated list of key values
    var oldOrgList   = '-99999'
    
    if(orgSearchVal != null && orgSearchVal != ''){
        
        if(oldOrgVal && oldOrgVal != '0.0') oldOrgList = makeCommaList(oldOrgVal)
            
        var queryString = "select distinct                                                                          "
                        + "       ORG_NAME = o.org_name                                                             "
                        + "     , ORG_ID   = o.organization_id                                                      "
                        + "     , SORT     = 1                                                                      "
                        + "                                                                                         "
                        + "from org_set   os                                                                        "
                        + "   , org_set_org_r   osor                                                                "
                        + "   , organization   o                                                                    "
                        + "   , location   l                                                                        "
                        + "                                                                                         "
                        + "where os.name               in ('*Amb*','*Medstar Facilities*')                          "
                        + "  and os.active_ind         =  1                                                         "
                        + "                                                                                         "
                        + "  and osor.org_set_id       =  os.org_set_id                                             "
                        + "  and osor.active_ind       =  1                                                         "
                        + "                                                                                         "
                        + "  and o.organization_id     =  osor.organization_id                                      "
                        + "  and o.active_ind          =  1                                                         "
                        + "  and o.organization_id not in(   589723.00  /*Franklin Square Hospital Center        */ "
                        + "                              ,   627889.00  /*Good Samaritan Hospital                */ "
                        + "                              ,   628009.00  /*Harbor Hospital Center                 */ "
                        + "                              ,   628058.00  /*Union Memorial Hospital                */ "
                        + "                              ,   628085.00  /*Georgetown University Hospital         */ "
                        + "                              ,   628088.00  /*Washington Hospital Center             */ "
                        + "                              ,   628738.00  /*National Rehabilitation Hospital       */ "
                        + "                              ,   640191.00  /*Franklin Square Employee Health        */ "
                        + "                              ,   640192.00  /*Franklin Square Psych                  */ "
                        + "                              ,   640194.00  /*Union Memorial Psych                   */ "
                        + "                              ,   640196.00  /*WHC Psych                              */ "
                        + "                              ,   642194.00  /*UMH Tucker, Andrew                     */ "
                        + "                              ,   664189.00  /*GUH Psych                              */ "
                        + "                              ,   807419.00  /*GUH Quest Diagnostics Nichols Institute*/ "
                        + "                              ,   807425.00  /*GUH Labcorp                            */ "
                        + "                              ,   807427.00  /*WHC Labcorp                            */ "
                        + "                              ,  3440653.00  /*MedStar St Mary's Hospital             */ "
                        + "                              ,  3476823.00  /*Medstar Diversified                    */ "
                        + "                              ,  4678436.00  /*Medstar Affiliated Phys                */ "
                        + "                              ,  5335375.00  /*PAL Owings Mills                       */ "
                        + "                              ,  5335384.00  /*PAL Smyth                              */ "
                        + "                              ,  6591470.00  /*Dave Choi Vascular Surgery             */ "
                        + "                              ,  7232532.00  /*Rafael J. Convit Plastic Surgery       */ "
                        + "                              ,  7232553.00  /*Gastroenterology Consultants of DC     */ "
                        + "                              ,  7232577.00  /*Robinson Cardiology                    */ "
                        + "                              ,  7232590.00  /*Metro Renal Associates                 */ "
                        + "                              ,  7232615.00  /*National Capital Nephrology            */ "
                        + "                              ,  7316485.00  /*Maximed Associates                     */ "
                        + "                              ,  8608690.00  /*Emmanuel T Mbualungu MD                */ "
                        + "                              ,  8611509.00  /*Georges C Awah MD                      */ "
                        + "                              ,  9308346.00  /*MMC LabCorp                            */ "
                        + "                              ,  9448872.00  /*Krishna Dass MD                        */ "
                        + "                              ,  9514275.00  /*SMD LabCorp                            */ "
                        + "                              ,  1325870.00  /*MedStar Health                         */ "
                        + "                              ,  1650929.00  /*zzzFranklin Square Hospital Center     */ "
                        + "                              ,  2650023.00  /*WHC Labcorp Stats                      */ "
                        + "                              ,  3433629.00  /*Medstar Physician Partners             */ "
                        + "                              , 10608377.00  /*SMD Saint Mary's Stats                 */ "
                        + "                              , 10608446.00  /*SMD Health Fair                        */ "
                        + "                              , 10679417.00  /*Integrative Family Medicine            */ "
                        + "                              , 10843874.00  /*Integrative Family Medicine Gaithersbur*/ "
                        + "                              , 10925508.00  /*MSMHC Rehab Admin Only                 */ "
                        + "                              , 12012326.00  /*Irene F Ibarra MD PA                   */ "
                        + "                              )                                                          "
                        + "  and cnvtupper(o.org_name) =  value(concat('*','" + orgSearchVal + "','*'))             "
                        + "                                                                                         "
                        + "  and l.organization_id     =  o.organization_id                                         "
                        + "  and l.location_type_cd    =  ( select cv.code_value                                    "
                        + "                                   from code_value cv                                    "
                        + "                                  where cv.code_set = 222                                "
                        + "                                    and cdf_meaning = 'FACILITY'                         "
                        + "                               )                                                         "
                        + "  and l.beg_effective_dt_tm <  cnvtdatetime(curdate, curtime3)                           "
                        + "  and l.end_effective_dt_tm >= cnvtdatetime(curdate, curtime3)                           "
                        + "  and l.active_ind = 1                                                                   "
                        + "union(                                                                                   "
                        + "    select ORG_NAME = o.org_name                                                         "
                        + "         , ORG_ID   = o.organization_id                                                  "
                        + "         , SORT     = 0                                                                  "
                        + "      from organization o                                                                "
                        + "     where o.organization_id in (" + oldOrgList + ")                                     "
                        + ")                                                                                        "
                        + "order by 3, 2, 1                                                                         "
                        + "with RDBUNION                                                                            "
                        ;
        
        theForm.ORG_IDS.query = queryString;
        
        theForm.ORG_IDS.updateFields();
        
        theForm.ORG_IDS.value = oldOrgVal;
        
        theForm.reformat();
        theForm.updateUI();
    }
}

function provSearchClick(sender){
    var provSearchVal = theForm.PROV_SEARCH.value;
    var oldProvVal    = theForm.PROV_IDS.value;  //This is a bell (7) char separated list of key values
    var oldProvList   = '-99999'
    
    if(provSearchVal != null && provSearchVal != ''){

        if(oldProvVal && oldProvVal != '0.0') oldProvList = makeCommaList(oldProvVal)
        
        var queryString = "select prsnl_id        = pr2.person_id                                        "
                        + "     , prsnl_full_name = pr2.name_full_formatted                              "
                        + "     , SORT            = 1                                                    "
                        + "  from prsnl pr2                                                              "
                        + "  plan pr2                                                                    "
                        + "   where pr2.active_ind = 1                                                   "
                        + "     and pr2.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)             "
                        + "     and pr2.name_full_formatted > ' '                                        "
                        + "     and cnvtupper(pr2.name_last) = value(concat('" + provSearchVal + "','*'))"
                        + "union(                                                                        "
                        + "    select prsnl_id        = pr.person_id                                     "
                        + "         , prsnl_full_name = pr.name_full_formatted                           "
                        + "         , SORT            = 0                                                "
                        + "      from prsnl pr                                                           "
                        + "     where pr.person_id in (" + oldProvList + ")                              "
                        + ")                                                                             "
                        + "order by 3, 2, 1                                                              "
                        + "with RDBUNION                                                                 "
                        ;
        
        theForm.PROV_IDS.query = queryString;
        
        theForm.PROV_IDS.updateFields();
        
        theForm.PROV_IDS.value = oldProvVal;
        
        theForm.reformat();
        theForm.updateUI();
    }
}

function makeCommaList(obj){
    var list = obj.split(String.fromCharCode(7));
    
    return(list.join(','));
}