################################################################################
# File Name     : dvd_aware_setup.tcl
# Author        : DT-PI
# Last Modified : 2024-12-04
# Version       : v0.1
# Location      : ${COMMON_TCL_PT}/dvd_aware_sta.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	This file is an example file. This header is used to track the version and
# 	change history of the file.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-12-04] : jjh8744 
#       - Initial Version Release
#-------------------------------------------------------------------------------
# Useage        :
#		pt_shell> source dvd_aware_setup.tcl
#################################################################################

set timing_enable_dvd_analysis true
set pba_derate_only_mode false
set error_cnt "0"

set DVD_FILE "${SPEF_DIR}/${DESIGN}.${MODE}.[regsub "_dvd" ${CORNER} ""].{dvd,effvdd.dvd}"
foreach fname [glob -nocomplain $DVD_FILE] {
	echo $fname
	if {[file exist $fname]} {
		set DVD_FILE $fname
		break
	} else {
		incr error_cnt
	}
}

#TBD set Fin  [open $DVD_FILE r]
#TBD set EDIT_DVD_FILE ""
#TBD set Fout [open $EDIT_DVD_FILE w]
#TBD while { [gets $Fin line] != -1 } {
#TBD 	if {[string match "# dvd *" $line]} {
#TBD 		set PG_ARC_INDEX [expr [lsearch $line pg_arc] -1]
#TBD 	} elseif {[string match "#*" $line]} {
#TBD 	} else {
#TBD 		set ORG_NAME     [lindex $line $PG_ARC_INDEX]
#TBD 		set NEW_NAME     [regsub {\-} [lindex $line $PG_ARC_INDEX] {/}]
#TBD 		regsub $ORG_NAME $line $NEW_NAME line
#TBD 	}
#TBD 	puts $Fout "$line"
#TBD }
#TBD close $Fin
#TBD close $Fout

if { $error_cnt == "2" } {
	puts "Error_ADF: $DVD_FILE does not exist."
	exit
} else {
	puts "Information_ADF:"
	puts "      DVD_FILE          - $DVD_FILE"
	if { $dvd_mode == "0" } {
		puts "      DvD analysis mode - 0 (VSS)"
	} elseif { $dvd_mode == "1" } {
		puts "      DvD analysis mode - 1 (NON-VSS)"
	} else {
		puts "Error_ADF: Need to check dvd_mode variable."
		puts "           The variable must be one of 0, 1, or none."
	}
	set cmd "read_dvd -mode $dvd_mode $DVD_FILE"
	puts $cmd
	eval $cmd
}
