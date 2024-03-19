/* TOP Patient Handoff
   The desire is for this component to call two smart templates and display them in a
   custom component.  In addition, this will allow for a freetext entry that is saved in
   a custom clinical event using the handoff rules.
   
   MAs will be making the notes and providers will be viewing at the moment.
*/
mPageCCLCall = function(script, fn, stat) {
    
    return function(opts) {
        var ajax = new XMLCclRequest();
        ajax.onreadystatechange = function() {
            if (ajax.readyState === 4 && ajax.status === 200) {
                var callFn, json, statusData;
                
                callFn = true;
                json = $.parseJSON(ajax.responseText);
                statusData = null;
                for (var i in json) {
                    if (json[i]["STATUS_DATA"]) {
                        statusData = json[i]["STATUS_DATA"];
                        break; 
                    } 
                }
                if (statusData && statusData.STATUS) {
                    if (stat) {
                        stat(statusData);
                    } else if (/[fp]/i.test(statusData.STATUS)) {
                        callFn = false;
                    }
                }
                callFn && fn(json);
            }else if (ajax.readyState === 4 && ajax.status >= 400 && ajax.status <= 599) {
                alert("The page did not load properly, please refresh the page to try again.");
            }
        };
        ajax.open("GET", script);
        ajax.send(opts);
    };
}

mmatph_redraw = function(){

  
    $('.mmatph_parent').empty();
   
    var parseReply, opts;
    
    opts = "^MINE^,value($PAT_PersonId$),value($VIS_EncntrId$)";

     
     
    parseReply = function(json){
        var hm_st, ord_st, label, textbox, button, docLabel, eventCd, handoffTxt, docDate;

        hm_st      = json.COMP_DATA.HEALTH_RECOM;
        ord_st     = json.COMP_DATA.HANDOFF_ORDERS;
        lmp_st     = json.COMP_DATA.LAST_LMP;
        eventCd    = json.COMP_DATA.HANDOFF_CD;
        handoffTxt = json.COMP_DATA.HANDOFF;
        docDate    = json.COMP_DATA.HANDOFF_DT;
        
        label      = $('<p><span class="mmatph_title">Handoff Notes</span><span class="mmatph_subtitle">(255 char limit)</span>')
        textbox    = $('<textarea/>').addClass('mmatph_text_input').text(handoffTxt).attr({
            'rows': '5',
            'maxlength': 255
        });
        button     = $('<button/>').text('Submit');
        docLabel   = $('<span/>').addClass('mmatph_subtitle');
        
        if(docDate !== '') $(docLabel).text('Last Documented: ' + docDate);
        
        $(button).click(function(){
            var parseReply, opts;
            
            opts = "^MINE^, value($VIS_EncntrId$), ^" + eventCd + "^, ^" + $('.mmatph_text_input').text() + "^";
            
            parseReply = function(json){
                mmatph_redraw();
            }
            mPageCCLCall('medstar_mp_add_sticky_note', parseReply)(opts);
        });
        
        $('.mmatph_parent').append(hm_st + '<br/>' + ord_st + '<br/>' + lmp_st + '<br/>');
        $('.mmatph_parent').append(label);
        $('.mmatph_parent').append(textbox);
        $('.mmatph_parent').append(button);
        $('.mmatph_parent').append(docLabel);

    }
    mPageCCLCall('mp_cust_get_ma_patient_handoff', parseReply)(opts);

}


$(document).ready(function(){
    mmatph_redraw();
});

