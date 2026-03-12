#-#
if {$USE_MCMM} {
 set CORNER_PROC   [lindex [split $MCMM_SCN2(NAME) "._"] 0 ]
 set CORNER_VOLT   [lindex [split $MCMM_SCN2(NAME) "._"] 1 ]
 set CORNER_TEMP   [lindex [split $MCMM_SCN2(NAME) "._"] 2 ]
 set CORNER_RC_A   [lindex [split $MCMM_SCN2(NAME) "._"] 3 ]
 set CORNER_RC_B   [lindex [split $MCMM_SCN2(NAME) "._"] 4 ]
 set CORNER_RC     "${CORNER_RC_A}_${CORNER_RC_B}"

 set_opcond_inference -level closest_unresolved -applies_to macro_cells                                                                                                                                                                                                    
 set_opcond_inference -level closest_unresolved -applies_to pad_cells
 report_opcond_inference > ${REPORT_DIR}/opcond_inference.rpt
} else {
 set CORNER_PROC   [lindex [split $SET_SCENARIO "._"] 0 ]
 set CORNER_VOLT   [lindex [split $SET_SCENARIO "._"] 1 ]
 set CORNER_TEMP   [lindex [split $SET_SCENARIO "._"] 2 ]
 set CORNER_RC_A   [lindex [split $SET_SCENARIO "._"] 3 ]
 set CORNER_RC_B   [lindex [split $SET_SCENARIO "._"] 4 ]
 set CORNER_RC     "${CORNER_RC_A}_${CORNER_RC_B}"

 set_opcond_inference -level closest_unresolved -applies_to macro_cells                                                                                                                                                                                                    
 set_opcond_inference -level closest_unresolved -applies_to pad_cells
 report_opcond_inference > ${REPORT_DIR}/opcond_inference.rpt
}
