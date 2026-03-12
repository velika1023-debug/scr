################################################################################
# File Name     : sub_para_setup.tcl
# Author        : DT-PI
# Creation Date : 2024-05-27
# Last Modified : 2024-06-19
# Version       : v0.2
# Location      : ${COMMON_PT_TCL}/sub_para_setup.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	By using ${STA_SCRIPT_DIR}/sub_hier_inst_info.tcl
#    read_para* This is a script that automatically sets related variables.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-05-27] : iskim1001
#       - Initial Version Release
#   v0.2 [2024-06-19] : iskim1001
#   	- Add x_loc, y_loc, rotation, flip Value doubble check
#   v0.3 [2024-09-09] : iskim1001
#   	- Moved RC_FILE varialbe from run_sta.tcl
#-------------------------------------------------------------------------------
# Useage        :
#		Usage...
#################################################################################
set RC_FILE(${TOP_DESIGN},${CORNER_RC}_${CORNER_TEMP})          [set ${TOP_DESIGN}(SPEF_DIR)]/${DESIGN}.${CORNER_TEMP}c_${CORNER_RC}.spef.gz

if { $HIER_DESIGN != "NONE" } {
	foreach DB_LIST $READ_DB_LISTS {
		set BLK_NAME [lindex [split ${DB_LIST} ,] 0]
		set BLK_TYPE [lindex [split ${DB_LIST} ,] 1]

		if { $BLK_NAME == "${DESIGN}" } { continue }

		if { $BLK_TYPE == "NET"} {

			# This part checks whether the ${BLK_NAME}(FULL_HIER) variable is declared in the sub_hier_inst_info.tcl file.
			if { [info exists ${BLK_NAME}(FULL_HIER) ] } {
				puts "Information_ADF: The ${BLK_NAME}(FULL_HIER) array variable exists."
			} else {
				puts "Error_ADF: The variable ${BLK_NAME}(FULL_HIER) array does not exist."
				puts "Error_ADF: Please check the file below."
				puts "Error_ADF: ${STA_SCRIPT_DIR}/sub_hier_inst_info.tcl"
				exec touch :ERROR:ABNORMAL_EXIT
				exit
			}

	    	set value [regsub -all "{|}" [set ${BLK_NAME}(FULL_HIER)]  ""]
	    	foreach {inst_name x_loc y_loc rotation flip} $value {
	    		puts ""
	    		puts "Information_ADF: $BLK_NAME"

	    		#The part that checks whether x_loc or y_loc is a number
	    		if { ![string is integer -strict $x_loc] && ![string is double -strict $x_loc] } { set para_flag "x_loc" }
	            if { ![string is integer -strict $y_loc] && ![string is double -strict $y_loc] } { set para_flag "y_loc" }

				#This is the part where rotation information is checked.
				if { $rotation != "rotate_none" && $rotation != "rotate_90"  && \
					 $rotation != "rotate_180"  && $rotation != "rotate_270" } { set para_flag "rotation" }

				#This is the part where flip information is checked.
				if { $flip != "flip_none" && $flip != "flip_both" && \
					 $flip != "flip_x"    && $flip != "flip_y" } { set para_flag "flip" }

				#This is the part where para_flag is checked.
				if {[info exists para_flag] } {
					puts "Error_ADF: Please check the file below."
					puts "Error_ADF: ${STA_SCRIPT_DIR}/sub_hier_inst_info.tcl"
					puts "Error_ADF: The $para_flag information is described incorrectly."
					puts "Error_ADF: Check plz... ( $para_flag )"
	    			puts "Error_ADF: This is the currently setting value. "
	    			puts "Error_ADF:     $inst_name , $x_loc , $y_loc , $rotation , $flip"
					puts "Error_ADF: Values : "
					puts "Error_ADF:     x_loc    : Offset of the origin in X-direction to transform locations)"
					puts "Error_ADF:     y_loc    : Offset of the origin in Y-direction to transform locations)"
					puts "Error_ADF:     rotation : rotate_none, rotate_90, rotate_180, rotate_270"
					puts "Error_ADF:     flip     : flip_x, flip_y, flip_both, flip_none)"
					exec touch :ERROR:ABNORMAL_EXIT
					exit
	    		}

	    		#Setting part for use in read_parasitics.tcl File
	    		set RC_FILE($inst_name,${CORNER_RC}_${CORNER_TEMP}) "[set ${BLK_NAME}(SPEF_DIR)]/${BLK_NAME}.${CORNER_TEMP}c_${CORNER_RC}.spef.gz"
	    		set LOCATION_INFO($inst_name) "$x_loc $y_loc $rotation $flip"

	    		set ${BLK_NAME}(INST_NAME)      "$inst_name"
	    		set ${BLK_NAME}(RC_FILE)        "[set ${BLK_NAME}(SPEF_DIR)]/${BLK_NAME}.${CORNER_TEMP}c_${CORNER_RC}.spef.gz"
	    		set ${BLK_NAME}(LOCATION_INFO)  "$x_loc $y_loc $rotation $flip"
	    		puts "Information_ADF: ${BLK_NAME}(INST_NAME)     : [set ${BLK_NAME}(INST_NAME)]"
	    		puts "Information_ADF: ${BLK_NAME}(RC_FILE)       : [set ${BLK_NAME}(RC_FILE)]"
	    		puts "Information_ADF: ${BLK_NAME}(LOCATION_INFO) : [set ${BLK_NAME}(LOCATION_INFO)]"
	    		puts ""
	    	}
    	}
	}
}
