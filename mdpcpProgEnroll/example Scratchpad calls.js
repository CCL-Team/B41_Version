A = function (a) {
            return a.ENTRY_TYPE_MEANING === h.CONSTANTS.ENTRY_TYPE_MEANING.ORDER ? MP_ScratchPad.addOrderSynonymToScratchpad({
                SYNONYM_ID: a.ENTRY_ID,
                SYNONYM_DISPLAY: a.ORDER_MNEMONIC
            }, h.CONSTANTS.INPATIENT_AMBULATORY_IN_OFFICE_VENUE_TYPE) : a.ENTRY_TYPE_MEANING === h.CONSTANTS.ENTRY_TYPE_MEANING.PRESCRIPTION && MP_ScratchPad.addOrderSynonymToScratchpad({
                SYNONYM_ID: a.ENTRY_ID,
                SYNONYM_DISPLAY: a.ORDER_MNEMONIC
            }, h.CONSTANTS.DISCHARGE_AMBULATORY_MED_AS_RX_VENUE_TYPE)
        },
        B = function (a) {
            return MP_ScratchPad.removeOrderSynonymBySynonymId(a)
        },
        
        
        
        
        
        
        
}, PrenatalLabComponent.prototype.onApplyOrder = function(a) {
    var b = "CAP:MPG.PrenatalLabs.O2-ORDER",
        c = this.getCriterion().category_mean;
    new CapabilityTimer(b, c).capture();
    var d = MP_Util.CreateTimer(b, c);
    d && d.Stop();
    var e = "PHARMACY" === a.ACTIVITY_TYPE ? 1 : 0,
        f = {
            SYNONYM_ID: a.SYNONYM_ID,
            SYNONYM_DISPLAY: a.SYNONYM_NAME,
            SENTENCE_ID: a.SENTENCE_ID,
            SENTENCE_DISPLAY: a.DESCRIPTION
        };
    MP_ScratchPad.addOrderToScratchpad(f, e), this.renderScratchpadNotificationSection(), this.m_orderDataPopUp.hide()
    
    
    
    








SelectFav: function(a, b, c) {
    var d
      , e
      , f = Util.gp(a)
      , g = {}
      , h = parseInt(b, 10)
      , i = MP_Util.GetCompObjById(h);
    
    i || (i = MP_Util.GetCompObjById(b));
    
    var j = i.m_base;
    
    if (f) {
        var k = _gbt("DD", f)
          , l = k[0].innerHTML
          , m = k[1].innerHTML
          , n = k[2].innerHTML;
       
        g.rowId = f.id;

        var o = n.split("|");
        
        2 === c ? (  e = k[5].innerHTML
                   , g.PATH_CAT_ID = parseInt(o[0], 10)
                   , g.PATH_CAT_SYN_ID = 2 == e ? parseInt(o[1], 10) : 0
                   , g.PW_CAT_SYN_NAME = l) 
                : ( g.SYN_ID = parseInt(o[0], 10)
                  , g.SENT_ID = parseInt(o[2], 10)
                  , g.SYNONYM = l
                  , g.SENTENCE = m)
                , Util.Style.ccss(f, "noe-order-row-selected") ? j.removeOrderFromScratchpad(g.rowId) 
                                                               : ( i.toggleOrderRowSelection($(f), $(a), !0)
                                                                                            , d = j.addOrderToScratchpad(g)
                                                                                            , d ? j.fireOrderTimer(g.SYN_ID || g.PATH_CAT_ID) 
                                                                                                : i.toggleOrderRowSelection($(f), $(a), !1)
                                                                 )
    }
},