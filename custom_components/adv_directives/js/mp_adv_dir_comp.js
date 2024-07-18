/* Advanced Directives component
    This component is designed to gather information from advanced directive forms
    and display in a custom component.  If no form is identified, we allow launching to
    do a fresh documentation.
    
    Added later was the ability to view scanned AD documents, this is handled after the
    current form work we do.
*/

//Component init function.
$(document).ready(function(){
    getAdvancedDirectivesJSON();
});

// Function to return Advanced Directives and/or Advanced Planning Documents for this patient
function getAdvancedDirectivesJSON(){
    try {
        // Initialize the request object
        var cclData, json, encType, refId;
        
        cclData = new XMLCclRequest();
        
        // Get the response
        cclData.onreadystatechange = function(){
            if(cclData.readyState == 4 && cclData.status == 200){
                json = $.parseJSON(cclData.responseText);
                if(json && json.REC){
                    //alert(JSON.stringify(json));
                    
                    $(".madc_parent").empty();  //emptying out the component before redrawing
                    madcCreateBaseComp();
                    
                    if((  json.REC.NEW_AD_MOLST_FORM_LIST && json.REC.NEW_AD_MOLST_FORM_LIST.NEW_AD_MOLST_DATA_IND > 0)
                       //|| json.REC.NEW_AD_MOLST_FORM_IND === 1
                      ){
                        //Just using the first activity_id, they should all be the same, and we know we have at least 1.
						
                        refId = json.REC.DCP_FORMS_REF_ID;
                        

						
                        if(json.REC.NEW_AD_MOLST_FORM_IND === 0){
                            
                            madcCreateFormLink( json.REC.PERSON_ID, json.REC.ENCNTR_ID, 0
                                            , json.REC.AD_FORM_REF_ID, 'OLD Advance Directives/MO(L)ST', 1, '');
                                            
                            //madcCreateTable(json.REC.ADV_DIR_LIST);
                            madcCreateADMolstLayout(json.REC.NEW_AD_MOLST_FORM_LIST);
                            
                        }else{
                            
                            madcCreateFormLink(json.REC.PERSON_ID, json.REC.ENCNTR_ID, json.REC.DCP_FORMS_ACTIVITY_ID, 
                                               refId, 'Advance Directives/MO(L)ST', 0, json.REC.VERSION_DT_TM);
                            
                            madcCreateADMolstLayout(json.REC.NEW_AD_MOLST_FORM_LIST);   
                        }                                 
                              
                    }
                    else{
                        madcCreateFormLink( json.REC.PERSON_ID, json.REC.ENCNTR_ID, 0
                                          , json.REC.AD_FORM_REF_ID, 'NO Advance Directives/MO(L)ST', 1, '');
                     
                    }
                    
                    madcCreateADVaultForms(json.REC);
                    
                    if(json.REC.DOC_LIST && json.REC.DOC_LIST.length){
                        madcCreateDocLink(json.REC, 0);
                    }else{
                        madcCreateDocLink(json.REC, 1);
                    }
                    
                }
            }
        }
        
        //  Call the ccl program and send the parameter string
        cclData.open('GET', "mp_get_adv_dir");
        //alert('mp_get_adv_dir ' + "^MINE^, value($VIS_Encntrid$), value($PAT_Personid$), 0");
        cclData.send("^MINE^, value($VIS_Encntrid$), value($PAT_Personid$), 0");
        
    }
    catch(e){
        alert("function getAdvancedDirectives():\n"+e.description+"\n"+e.Reason+"\n");
        return;
    }
    
    return;
}


/* madcCreateBaseComp
   We redraw a lot during interactions with this component.  Rather than doing a bunch of HTML work in
   a bunch of places, we'll just do it here.
*/
function madcCreateBaseComp(){
    var pfDiv    , adVaultDiv    , scanDiv
      , pfHead   , adVaultHead   , scanHead
      , pfDivCont, adVaultDivCont, scanDivCont;
    
    pfDiv          = document.createElement('div');
    adVaultDiv     = document.createElement('div');
    scanDiv        = document.createElement('div');
    
    pfHead         = document.createElement('div');
    adVaultHead    = document.createElement('div');
    scanHead       = document.createElement('div');
    
    pfDivCont      = document.createElement('div');
    adVaultDivCont = document.createElement('div');
    scanDivCont    = document.createElement('div');
    
    $(pfDiv)      .addClass('madc_pf');
    $(adVaultDiv) .addClass('madc_advault');
    $(scanDiv)    .addClass('madc_scan');
   
    $(pfHead)     .addClass('madc_cont_head').text('Healthcare Decision Making PowerForms');
    $(adVaultHead).addClass('madc_cont_head').text('MOST/MOLST PowerForms');
    $(scanHead)   .addClass('madc_cont_head').text('Healthcare Decision Making Clinical Documents');
    
    $(pfDivCont)     .addClass('madc_pf_cont');
    $(adVaultDivCont).addClass('madc_advault_cont');
    $(scanDivCont)   .addClass('madc_scan_cont');
    
    $(pfDiv)     .append(pfHead)     .append(pfDivCont);
    $(adVaultDiv).append(adVaultHead).append(adVaultDivCont);
    $(scanDiv)   .append(scanHead)   .append(scanDivCont);
    
    $(".madc_parent").append(pfDiv);
    $(".madc_parent").append(adVaultDiv);
    $(".madc_parent").append(scanDiv);
}


/* madcCreateFormLink
   Creates a message to display in the component, with the link to an empty powerform or 
   a previously documented powerform.
   
   Inputs:
       perId    (f8):  Person ID
       encId    (f8):  Encounter ID
       actId    (f8):  Activity ID
       refId    (f8):  Ref ID
       txt     (str):  Text to show in the message
       styleInd (i2):  0 - Normal Form
                       1 - Empty Form
       dateTxt (str):  Date that the form was entered.
*/
function madcCreateFormLink(perId, encId, actId, refId, txt, styleInd, dateTxt){
    //alert("in function")
    var msgP, icon, wrap, style, title, date, refId;
	//alert(perId + "/" + encId + "/" + actId + "/" + txt + "/" + styleInd + "/" + dateTxt)
    try{
        wrap = document.createElement('span');
        icon = document.createElement('span');
        msgP = document.createElement('span');
        
        style = styleInd === 1 ? 'madc_error' 
                               : 'madc_form';
        
        
        if(styleInd === 1){
            title = "Click to open *new* Advance Directives/MO(L)ST PowerForm";
        }else{
            title = "Click to open Advance Directives/MO(L)ST PowerForm";
        }
    
        $(wrap)
            .attr('title', title)
            .addClass('madc_link_cursor')
            .on('click', function(){
                             madcopenPowerForm(encId, perId, actId, refId, 0);
                         });
        
        $(icon)
            .text(String.fromCharCode(0x00A4)) //Icon for a notepad
            .addClass('madc_wing'); 
        
        $(msgP)
            .text(txt)
            .addClass(style);
        
        $(wrap).append(icon).append(msgP);
        
        if(styleInd === 0){
            date = document.createElement('span');
            
            $(date)
                .text(' (' + dateTxt + ')')
                .addClass('madc_date');
            
            $(wrap).append(date);
        }
        
        $('.madc_pf_cont').append(wrap);
    } catch(e){
        alert("function madcCreateFormLink():\n"+e.description+"\n"+e.Reason+"\n");
    }
}


/* madcCreateTable
   Creates a table to display the advanced directives found in the script.
   
   Inputs:
       adv_dir_list    (array):  Array of adv_dir_list elements
*/
function madcCreateTable(adv_dir_list){
    var table, tbody, tr, td, i;
    
    table = document.createElement('table');
    tbody = document.createElement('tbody');
    //alert(adv_dir_list.length)
    for(i = 0; i < adv_dir_list.length; i++){
        tr = document.createElement('tr');
        td = document.createElement('td');
        
        $(td)
            .text(adv_dir_list[i].FORM_ELEMENT)
            .addClass('madc_thead');
        $(tr).append(td);
        
        td = document.createElement('td');
        
        $(td)
            .text(adv_dir_list[i].EVENT_TAG)
            .addClass('madc_ttxt');;
        $(tr).append(td);
        
        $(tbody).append(tr);
    }
    
    $(table)
        .addClass('madc_table')
        .append(tbody);
        
    $(".madc_pf_cont").append(table);
}

/* madcCreateADMolstLayout
   Creates a display for the AD Molst Events/Values.
   
   Inputs:
       adv_dir_list    (array):  Array of adv_dir_list elements
*/
function madcCreateADMolstLayout(new_list){
    var table, tbody, tr, td, i, subList;
    
    table = $('<table>').addClass('madc_table');
    tbody = $('<tbody>');
    
    var sectFunct = function(list){
        
        for(i = 0; i < list.length; i++){
            tr = $('<tr>');
            td = $('<td>');
            
            $(td).text(list[i].FORM_ELEMENT)
                 .addClass('madc_thead');
            
            $(tr).append(td);
            
            td = $('<td>');
            
            $(td).text(list[i].EVENT_TAG)
                 .addClass('madc_ttxt');
                 
            $(tr).append(td);
            
            if(i === list.length - 1){
                $(tbody).append(tr);
                
                tr = $('<tr>');
                
                td = $('<td>');
                $(td).html('&nbsp;');   //So hacky... I hate myself.
                $(tr).append(td);
                
                td = $('<td>');
                $(td).html('&nbsp;');   //So hacky... I hate myself.
                $(tr).append(td);
                
                $(tbody).append(tr);
                
            }else{
                $(tbody).append(tr);
            }
            
            
        }
        
    }
    
    sectFunct(new_list.AD_SECT);
    sectFunct(new_list.MOLST_SECT);
    sectFunct(new_list.DECISION1);
    sectFunct(new_list.DECISION2);
    sectFunct(new_list.FINAL);
    
    
    $(table).append(tbody);
        
    $(".madc_pf_cont").append(table);
    
}


/* madcCreateADVaultFormLink
   Creates a message to display in the component, with the link to an empty PowerForm or 
   a previously documented PowerForm.  This one is focused on the ADVault forms.
   
   Inputs:
       json     (JSON):  JSON containing information on AD
       refId      (f8):  Reference id of the form
       actId      (f8):  Activity id of the form
       formName   (vc):  Name of the form
       formDate   (vc):  Date of the form Doc
       style      (i4):  This got complicated again.
                            0 - Standard Text   (Black) Used for when a form exists, but we still show a new link.
                            1 - Form Text       (Blue)  Used for a documented form
                            2 - Error Text      (Red)   Used for a missing form documented.
   Note:
        I was going to let the sub deal with most the work around gathering which act/ref to 
        use, but I think this is easier since we have to deal with empty/new forms as well.
*/
function madcCreateADVaultFormLink(json, refId, actId, formName, formDate, style){
    var msgP, icon, wrap, linkstyle, title, date
      , encId, perId
      , formLoop;

    try{
        wrap = document.createElement('div');
        icon = document.createElement('span');
        msgP = document.createElement('span');
        
        encId = json.ENCNTR_ID;
        perId = json.PERSON_ID;
        
        if     (style === 0) linkstyle = 'madc_form_standard'
        else if(style === 1) linkstyle = 'madc_form'
        else                 linkstyle = 'madc_error'
        
        
        title    = "Click to open " + formName + " PowerForm";
        
        $(wrap)
                .attr('title', title)
                .addClass('madc_link_cursor')
                .on('click',  function(){
                                     madcopenPowerForm(encId, perId, actId, refId, 0);
                              });
            
        
        $(icon)
            .text(String.fromCharCode(0x00A4)) //Icon for a notepad
            .addClass('madc_wing'); 
        
        
        $(msgP).addClass(linkstyle);
        
        if(actId === 0) $(msgP).html('Document <span style="color: Red; font-weight: bold">NEW</span> ' + formName);
        else            $(msgP).html(                  formName);
        
        $(wrap).append(icon).append(msgP);
        
        
        if(actId > 0){
            date = document.createElement('span');
        
        
            $(date)
                .text(' (' + formDate + ')')
                .addClass('madc_date');
            
            
            $(wrap).append(date);
        }
        
        $('.madc_advault_cont').append(wrap);
        
    } catch(e){
        alert("function madcCreateADVaultFormLink():\n"+e.description+"\n"+e.Reason+"\n");
    }
}



/* madcCreateADVaultForms
   Creates a message to display in the component, with the link to an empty PowerForm or 
   a previously documented PowerForm.  This one is focused on the ADVault forms, and work will
   be done to determine if MD MOLST or DC MOST should be shown.
   
   Inputs:
       json    (JSON):  JSON containing information on AD
       
   Note:
       The way I was doing this before seems a bit dumb and was driven off of emulating the McAlduff 
       MPage.  I don't think we need to do that anymore, so I'm refactoring this a bit.
       
       The other sections could probably benefit from a refactor, but for now I am leaving them be.
*/
function madcCreateADVaultForms(json){
    var formLoop, mdInd, dcInd;
        
	dcInd = false;
    mdInd = false;
        
    //Man this could be so simplifed if we just always show both links... writing to requirements however.
    //Hey guess what, that is what we are going to do now... simplifying the below.
    //Psych... it gets a little complicated.  They want the new form links to be after the form links... rather than at the end.
    try{
        if(json.AD_VAULT_CNT > 0){
            //Loop across forms and show links.  Should be a max of 2 forms, but usually just one.
            for(formLoop = 0; formLoop < json.AD_VAULT_CNT; formLoop++){
                
                madcCreateADVaultFormLink(json, json.AD_VAULT[formLoop].DCP_FORMS_REF_ID
                                              , json.AD_VAULT[formLoop].DCP_FORMS_ACTIVITY_ID
                                              , json.AD_VAULT[formLoop].POWERFORM
                                              , json.AD_VAULT[formLoop].FORM_DATE
                                              , 1)
                
                
                //Inds for link checking below.
                if(json.AD_VAULT[formLoop].DCP_FORMS_REF_ID === json.DC_FORM_REF_ID){
                    dcInd = true;
                    
                    madcCreateADVaultFormLink(json, json.DC_FORM_REF_ID
                                                  , 0
                                                  , json.DC_FORM_NAME
                                                  , ''
                                                  , 0)
                }
                
                
                if(json.AD_VAULT[formLoop].DCP_FORMS_REF_ID === json.MD_FORM_REF_ID){
                    //Used below in case we didn't have a form
                    mdInd = true;
                    
                    madcCreateADVaultFormLink(json, json.MD_FORM_REF_ID
                                                  , 0
                                                  , json.MD_FORM_NAME
                                                  , ''
                                                  , 0)
                }


                /* We want a separator now.  This is difficult with the way this logic is layed out.  Let me document my thoughts:
                        If we have two forms... we want a separation between them here somewhere in the loop.
                        If we have no forms... we have to have a separation below.
                        If we have one form... we want a separation after it.
                        
                        So I think we add code here to add a separation on formLoop = 0.  Then one below where AD_VAULT_CNT = 0.
                        I think that handles all three cases.
                */
                
                //I'm going to be annoying and use jquery here... even though this sub was agnostic until now.
                if(formLoop === 0) $('.madc_advault_cont').append('<br />');
            }
        }
        
        //Handle links if there are no documented forms.
        //Now we just show new links for both, all the time.  Nothing fancy
        if(!dcInd) madcCreateADVaultFormLink(json, json.DC_FORM_REF_ID
                                            , 0
                                            , json.DC_FORM_NAME
                                            , ''
                                            , 2)
                                            
                                            
        // See comment in loop about separators.
        if(json.AD_VAULT_CNT === 0) $('.madc_advault_cont').append('<br />');
        
            
        if(!mdInd) madcCreateADVaultFormLink(json, json.MD_FORM_REF_ID
                                            , 0
                                            , json.MD_FORM_NAME
                                            , ''
                                            , 2)
        
        
    } catch(e){
        alert("function madcCreateADVaultForms():\n"+e.description+"\n"+e.Reason+"\n");
    }
}


/* madcCreateDocLink
   Creates a message to display in the component, with the link to an empty powerform.
   
   Inputs:
       json    (JSON):  JSON containing information on AD
       empty_ind (i2):  0 = JSON contains information
                        1 = JSON is empty in terms of docs.
*/
function madcCreateDocLink(json, empty_ind){
    var div, link, date, perId, encId, i;
    
    try{
        perId = json.PERSON_ID;
        encId = json.ENCNTR_ID
        
        if(empty_ind === 0){
            for(i = 0; i < json.DOC_LIST.length; i++){
                var evntId, title, txt, dateTxt;
                
                div  = document.createElement('div');
                form = document.createElement('span');
                icon = document.createElement('span');
                
                evntId  = json.DOC_LIST[i].EVENT_ID;
                title   = json.DOC_LIST[i].EVENT_TITLE_TEXT;
                txt     = json.DOC_LIST[i].EVENT_DISP;
                dateTxt = json.DOC_LIST[i].EVENT_END_DT_TM;
                
                $(div).addClass('madc_doc_div');
                
                $(icon)
                    .text(String.fromCharCode(0x00A4)) //Icon for a notepad
                    .addClass('madc_wing');
                    
                $(div).append(icon);
                
                $(form)
                    .attr('title', 'Open ClinicalNote')
                    .text(txt)
                    .addClass('madc_form');
                    
                date = document.createElement('span');
                
                $(date)
                    .text(' (' + dateTxt + ')')
                    .addClass('madc_date');
                
                $(div)
                    .append(form)
                    .append(date)
                    .addClass('madc_link_cursor')
                    .attr('data-event-id', evntId)
                    .on('click', function(){
                                     var eventId = $(this).attr('data-event-id');
                                     
                                     madcopenPowerNote(perId, eventId);
                                     
                                     //No redraw here, the window isn't a focus grabber, so refresh has no purpose
                                     
                                     //This guy started giving me problems.
                                     //MPAGES_EVENT("CLINICALNOTE",'"' + perId + '|' + encId + '|' + evntId + '||||||"');
                                    });
                
                $('.madc_scan_cont').append(div);
            }
        }else{
            div  = document.createElement('div');
            form = document.createElement('span');
            icon = document.createElement('span');
            
            $(div).addClass('madc_doc_div');
            
            $(icon)
                .text(String.fromCharCode(0x00A4)) //Icon for a notepad
                .addClass('madc_wing');
                
            $(div).append(icon);
            
            $(form)
                .text('No Healthcare Decision Making Clinical Documents Found')
                .addClass('madc_error');
                
            $(div).append(form);
            
            $('.madc_scan_cont').append(div);
        }
            

    } catch(e){
        alert("function madcCreateDocLink():\n"+e.description+"\n"+e.Reason+"\n");
    }
}



// Stolen from summary2 mpage 
function madcloadXMLString(txt)
{
	try //Internet Explorer
	{
		//this creates the XML object
		xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
		xmlDoc.async = "false";
		xmlDoc.onreadystatechange = madcverify;
		xmlDoc.loadXML(txt);
		return(xmlDoc);
	}
	catch(e)
	{
		alert(e.message);
		try //Firefox, Mozilla, Opera, etc.
		{
			parser = new DOMParser();
			xmlDoc = parser.parseFromString(txt,"text/xml");
			return(xmlDoc);
		}
		catch(e) { alert(e.message); }
	}
	alert('returning null...');
	return(null);
}

// Stolen from summary2 mpage
// these are the possible AJAX readyState flags
function madcverify()
{
    // 0 Object is not initialized
    // 1 Loading object is loading data
    // 2 Loaded object has loaded data
    // 3 Data from object can be worked with
    // 4 Object completely initialized
    if (xmlDoc.readyState != 4)
        return (false);
}

//Stolen from summary2 mpage
function madcopenPowerForm(encntrId,personId,activityId,formId,chartMode)
{
    var chartMode = 0;      // 0=Read/Write; 1=Read Only
    
    if(window.navigator.userAgent.indexOf("Edg") > -1){
        window.external.DiscernObjectFactory("POWERFORM")
          .then(function (PowerFormMPageUtils){
                    PowerFormMPageUtils.OpenForm(parseFloat(personId), parseFloat(encntrId), parseFloat(formId), parseFloat(activityId), chartMode)
                        .then(function (){
                            //redraw after coming back
                            getAdvancedDirectivesJSON();
                        });
                }
               );
    }else{
        var obj = window.external.DiscernObjectFactory("POWERFORM");
        obj.OpenForm(parseFloat(personId), parseFloat(encntrId), parseFloat(formId), parseFloat(activityId), chartMode);
                             
        //redraw after coming back
        getAdvancedDirectivesJSON();
    }
}

function madcopenPowerNote(personId,eventId)
{
  //var chartMode = 0;      // 0=Read/Write; 1=Read Only
  var obj = window.external.DiscernObjectFactory("PVVIEWERMPAGE");
  obj.CreateDocViewer(personId);
  obj.AppendDocEvent(eventId);
  obj.LaunchDocViewer();
}