################################################################################
# File Name     : design_setup.tcl
# Author        : DT-PI
# Last Modified : 2025-08-04
# Version       : v1.0
# Location      : ${COMMON_TCL_PT}/read_design_setup.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	This file is an example file. This header is used to track the version and
# 	change history of the file.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-05-24] : iskim1001
#       - Initial Version Release
#   v0.2 [2024-06-19] : iskim1001
#       - Part 4 Modify
#       	- BLK_PATH Check  Add
#   v0.3 [2024-06-27] : jjh8744
#       - Add Variable BLK(UPF_DIR)
#   v0.4 [2024-07-11] : iskim1001
#       - Change Variabel
#       	- Before : switch -glob $NET_TYPE {
#       	- After  : switch -glob $indb     {
#   v0.5 [2024-09-02] : iskim1001
#       - design_setup.tcl is merged.
#   v0.6 [2024-09-06] : jjh8744
#       - Modified to enable path setting during top-only
#   v0.7 [2024-10-22] : iskim1001
#       - Added BLK_ECO_NUM to BLK_OUTPUT_PT variable in POST
#   v0.8 [2024-11-19] : iskim1001
#       - Modify : 
#       	Before : if {[lsearch -exact $READ_DESIGN $BLK] != -1} {
#       	After  : if {[lsearch -exact $READ_DESIGN $BLK_NAME] != -1} {
#       - Add :
#       	if { $BLK_NAME == ${DESIGN} } { continue }
#   v0.9 [2024-12-03] : jjh8744
#       - Modify :
#       	Modify path setting of ETM, HSC DBs when AUTO_DETECT is not enabled
#   v1.0 [2025-08-04] : jaeeun1115
#       - Setting CROSS_VOLTAGE_ANALYSIS with $SMVA
#-------------------------------------------------------------------------------
# Useage        :
#		Usage...
#################################################################################

;#------------------------------------------------------------------------------
;# Process technology
;#   example:  LN08LPP, LN14LPP, LN14LPP_SBC, LN10LPP, etc.
;#------------------------------------------------------------------------------
set TECH            $PROCESS

;#------------------------------------------------------------------------------
;# Top cell name  
;#------------------------------------------------------------------------------
set TOP_DESIGN	        $DESIGN

;#------------------------------------------------------------------------------
;# Clock network cell type
;#   - clock tree must be made of unique cell type
;#------------------------------------------------------------------------------
set CLOCK_CELL_TYPE $CK_TYPE	

;#------------------------------------------------------------------------------
;# Metal Option
;#  - used for via variation techfile mapping
;#     example>  14M_3Mx_2Fx_7Dx_2Iz_LB, 14M_3Mx_1Fx_8Dx_2Iz_LB, etc.
;#------------------------------------------------------------------------------
set METAL_OPTION            ${MetalSpec}

;#------------------------------------------------------------------------------
;# Multi-voltage Option
;#------------------------------------------------------------------------------
if { $UPF != "0" } {
	set MULTI_VDD 1
} else {
	set MULTI_VDD 0
}

if { [regexp "mvdd" $CORNER] || $SMVA != "0" } {
	set CROSS_VOLTAGE_ANALYSIS 1
} else {
	set CROSS_VOLTAGE_ANALYSIS 0
}

if { [regexp "dvd" $CORNER] } {
	set  DVD_AWARE "1"
} else {
	set  DVD_AWARE "0"
}

;#------------------------------------------------------------------------------
;# PART 1 : Inital DB setting
;# set NET, HSC, and ETM in array format for the design set in READ_DESIGN.
;#------------------------------------------------------------------------------
set TOP_DESIGN        $DESIGN
set DEFAULT_DB_DESIGN ${READ_DESIGN}

foreach BLK ${READ_DESIGN} {
	if { $BLK == "NONE" } { continue }

	if {[regexp -nocase {PRE} $PRE_POST]} {
		switch -glob $indb {
                "syn"    { set BLK_INDB_TOOL [set ${BLK}(SYN_TOOL) ] ;set BLK_NET_REVISION  [set ${BLK}(NET_REVISION_SYN)   ]  }
                "bist"   { set BLK_INDB_TOOL [set ${BLK}(BIST_TOOL)] ;set BLK_NET_REVISION  [set ${BLK}(NET_REVISION_BIST)  ]  }
                "scan"   { set BLK_INDB_TOOL [set ${BLK}(SCAN_TOOL)] ;set BLK_NET_REVISION  [set ${BLK}(NET_REVISION_SCAN)  ]  }
                "pnrin"  { set BLK_INDB_TOOL pnrin                   ;set BLK_NET_REVISION  [set ${BLK}(NET_REVISION_PNRIN) ]  }
                default  { set BLK_NET_REVISION  "Error_ADF: indb variable Check......." }
        }
		set BLK_NAME          [set ${BLK}(NAME)     ]
		set BLK_INDB_VER      [set ${BLK}(INDB_VER) ]
		set BLK_OUTPUT_PT     ${OUTFD_DIR}/${BLK_NAME}/${BLK_INDB_VER}/pt_sta/${BLK_NET_REVISION}/${MODE}/${CORNER}/output
		set ${BLK}(ETM)       ${BLK_OUTPUT_PT}/${BLK}.${MODE}.${CORNER}.ETM_lib.db
		set ${BLK}(HSC)       ${BLK_OUTPUT_PT}/${BLK}.${MODE}.${CORNER}.hsc
		set ${BLK}(NET)       ${OUTFD_DIR}/${BLK_NAME}/${BLK_INDB_VER}/${BLK_INDB_TOOL}/${BLK_NET_REVISION}/output/${BLK}.v
		set ${BLK}(UPF_DIR)   ${OUTFD_DIR}/${BLK_NAME}/${BLK_INDB_VER}/${BLK_INDB_TOOL}/${BLK_NET_REVISION}/output
		set ${BLK}(DB_DIR)    ${OUTFD_DIR}/${BLK_NAME}/${BLK_INDB_VER}/${BLK_INDB_TOOL}/${BLK_NET_REVISION}

	} elseif {[regexp -nocase {POST} $PRE_POST]} {
		set BLK_NAME          [set ${BLK}(NAME)              ]
		set BLK_INDB_VER      [set ${BLK}(INDB_VER)          ]
		set BLK_INDB_TOOL     [set ${BLK}(PNR_TOOL)          ]
		set BLK_NET_REVISION  [set ${BLK}(NET_REVISION_POST) ]
		set BLK_ECO_NUM       [set ${BLK}(NET_ECO_NUM)       ]

		set BLK_OUTPUT_PT     ${OUTFD_DIR}/${BLK_NAME}/${BLK_INDB_VER}/pt_sta/${BLK_NET_REVISION}/${BLK_ECO_NUM}/${MODE}/${CORNER}/output
		set ${BLK}(ETM)       ${BLK_OUTPUT_PT}/${BLK}.${MODE}.${CORNER}.ETM_lib.db
        set ${BLK}(HSC)       ${BLK_OUTPUT_PT}/${BLK}.${MODE}.${CORNER}.hsc
		set ${BLK}(SPEF_DIR)  ${OUTFD_DIR}/${BLK_NAME}/${BLK_INDB_VER}/${BLK_INDB_TOOL}/${BLK_NET_REVISION}/${BLK_ECO_NUM}/output
		set ${BLK}(UPF_DIR)   ${OUTFD_DIR}/${BLK_NAME}/${BLK_INDB_VER}/${BLK_INDB_TOOL}/${BLK_NET_REVISION}/${BLK_ECO_NUM}/output

		set ${BLK}(NET)       [set ${BLK}(SPEF_DIR)]/${BLK}.v

	} else {
		puts "Error_ADF: Variable check Please PRE_POST"
		exit
	}
}


;#------------------------------------------------------------------------------
;# PART2: Overwriting user_setting
;# If the user_setting value exists, the value is overwritten in the array
;# that was previously set according to the format.
;#------------------------------------------------------------------------------
set USER_INPUT_BLK ""
set USER_INPUT_BLK_TYPE ""

if { ${HIER_DESIGN} == "NONE" } {
	puts "#######################################################"
	puts "HIER_DESIGN is set to NONE"
	puts "#######################################################"

	if { $USER_INPUT != "AUTO_DETECT" } {
		set BLK_NAME [lindex [split ${USER_INPUT} ,] 0]
		set BLK_TYPE [lindex [split ${USER_INPUT} ,] 1]
		set BLK_PATH [lindex [split ${USER_INPUT} ,] 2]
		set ${TOP_DESIGN}(NET)      $BLK_PATH
		set ${TOP_DESIGN}(SPEF_DIR) [regsub {\/[^\/]*$} $BLK_PATH ""]

	}

} else {
	if { [info exists USER_INPUT] && $USER_INPUT != "AUTO_DETECT" } {
		puts "#######################################################"
		puts "HIER_DESIGN exists.               "
		puts "Update variables for DESIGN set to USER_INPUT."
		puts "#######################################################"

		foreach BLK $USER_INPUT  {
			set BLK_NAME [lindex [split ${BLK} ,] 0]
			set BLK_TYPE [lindex [split ${BLK} ,] 1]
			set BLK_PATH [lindex [split ${BLK} ,] 2]
			
			if {[lsearch -exact $READ_DESIGN $BLK_NAME] != -1} {
				lappend USER_INPUT_BLK      "$BLK_NAME"
				lappend USER_INPUT_BLK_TYPE "$BLK_NAME,${BLK_TYPE}"
				if { $BLK_PATH == "AUTO_DETECT" } {
					puts "Information_ADF: Because BLK_PATH is AUTO_DETECT, the variable is not overwritten."
					puts "Information_ADF: Before : [set ${BLK_NAME}($BLK_TYPE)]"
					puts "Information_ADF: After  : [set ${BLK_NAME}($BLK_TYPE)]"
				} else {
					puts "Ifnormation_ADF: The ${BLK_NAME}($BLK_TYPE) variable was overwritten according to the variable set by the user."
					puts "Information_ADF: Before : [set ${BLK_NAME}($BLK_TYPE)]"
                    if { ${BLK_TYPE} == "HSC" } {
					    set ${BLK_NAME}($BLK_TYPE) ${BLK_PATH}/${BLK_NAME}.${MODE}.${CORNER}.hsc
                    } elseif { ${BLK_TYPE} == "ETM" } {
					    set ${BLK_NAME}($BLK_TYPE) ${BLK_PATH}/${BLK_NAME}.${MODE}.${CORNER}.ETM_lib.db
                    } else {
					    set ${BLK_NAME}($BLK_TYPE) $BLK_PATH
                    }
					puts "Information_ADF: After  : [set ${BLK_NAME}($BLK_TYPE)]"
				}
				puts ""
			}
		}

		# DEFAULT_DB_DESIGN - USER_INPUT_BLK = DEFAULT_DB_DESIGN
		foreach item $USER_INPUT_BLK {
			set index [lsearch -exact $DEFAULT_DB_DESIGN $item]
			if { $index != -1 } {
				set DEFAULT_DB_DESIGN [lreplace $DEFAULT_DB_DESIGN $index $index]
			}
		}
	} else {
		puts "#######################################################"
		puts "USER_INPUT is set to NONE in the makefile."
		puts "The part about overwriting variables is skipped."
		puts "#######################################################"
	}
}


;#------------------------------------------------------------------------------
;# PART3: Select DB to be actually used
;# Select the DB that will be actually used in READ_DESIGN and USER_INPUT and set it in NETLISTS, ETMLISTS, and HSCLISTS.
;#------------------------------------------------------------------------------
set READ_DB_LISTS "${DESIGN},NET,[set ${DESIGN}(NET)]"

foreach BLK $DEFAULT_DB_DESIGN {
	if { $BLK == ${DESIGN} } { lappend NETLISTS [set ${BLK}(NET)]; continue }

          if { $is_etm } { lappend ETMLISTS [set ${BLK}(ETM) ] ; lappend READ_DB_LISTS "${BLK},ETM,[set ${BLK}(ETM)]"
	} elseif { $is_hsc } { lappend HSCLISTS [set ${BLK}(HSC) ] ; lappend READ_DB_LISTS "${BLK},HSC,[set ${BLK}(HSC)]"
    } else   {             lappend NETLISTS [set ${BLK}(NET) ] ; lappend READ_DB_LISTS "${BLK},NET,[set ${BLK}(NET)]"
	}

}

if {[info exists USER_INPUT_BLK_TYPE] &&  $USER_INPUT_BLK_TYPE != "" } {
	foreach BLK $USER_INPUT_BLK_TYPE {
		set BLK_NAME [lindex [split ${BLK} ,] 0]
		set BLK_TYPE [lindex [split ${BLK} ,] 1]

		if { $BLK_NAME == ${DESIGN} } { continue }
		      if { $BLK_TYPE == "NET" } { lappend NETLISTS [set ${BLK_NAME}(NET) ] ; lappend READ_DB_LISTS "${BLK_NAME},NET,[set ${BLK_NAME}(NET)]"
		} elseif { $BLK_TYPE == "ETM" } { lappend ETMLISTS [set ${BLK_NAME}(ETM) ] ; lappend READ_DB_LISTS "${BLK_NAME},ETM,[set ${BLK_NAME}(ETM)]"
		} elseif { $BLK_TYPE == "HSC" } { lappend HSCLISTS [set ${BLK_NAME}(HSC) ] ; lappend READ_DB_LISTS "${BLK_NAME},HSC,[set ${BLK_NAME}(HSC)]"
	 	} else   { 	puts "Error_ADF: Unknow BLK_TYPE .... $BLK_TYPE"
		}
	}
}

;#------------------------------------------------------------------------------
;# PART4: Print DB to be actually used
;#------------------------------------------------------------------------------
redirect -tee ${LOG_DIR}/read_design_db.log {
	puts "Information_ADF: READ_DB_LISTS Setting"
	puts "Information_ADF: $READ_DESIGN"
	foreach DB_LIST $READ_DB_LISTS {
		set BLK_NAME [lindex [split ${DB_LIST} ,] 0]
		set BLK_TYPE [lindex [split ${DB_LIST} ,] 1]
		set BLK_PATH [lindex [split ${DB_LIST} ,] 2]

		if { $BLK_TYPE == "NET" || $BLK_TYPE == "ETM" || $BLK_TYPE == "HSC" } {
		} else {
			puts "Error_ADF: Unknow BLK_TYPE .... $BLK_TYPE"
		}

		# print
		if {[file exist $BLK_PATH]} {
			puts [format "%-17s %+15s : %20s : %s" "Information_ADF:" "    Found($BLK_TYPE)" "$BLK_NAME" "$BLK_PATH"]
		} else {
			puts [format "%-17s %+15s : %20s : %s" "Error_ADF:"       "Not Found($BLK_TYPE)" "$BLK_NAME" "$BLK_PATH"]
		}
	}
}
