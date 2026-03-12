###################################################################################################
# File               : proc_dk_match.tcl                                                          #
# Author             : ADT-DT (bmkim)                                                             #
# Description        : match dk (db, lef)                                                         #
# Usage              :                                                                            #
# Init Release Date  : 2025.06.04                                                                 #
# Script Version     : 1.1                                                                        #
# Revision History   :                                                                            #
#         2025.06.04 - first released                                                             #
###################################################################################################
set Detail_report_file  [open ${REPORT_DIR}/Match_detail_${SCN}.log w+]
set Summary_report_file [open ${REPORT_DIR}/Match_summary_${SCN}.log w+]
set script_file [open ${SCRIPT_DIR}/exploration_${SCN}.tcl w+]

set MATCH_DB ""
set N_MATCH_DB ""

set MATCH_LEF ""
set N_MATCH_LEF ""

array set LEF_COUNTER {}
set COMMON_UNMATCHED {}

# --------------------------------------
# Main 
# --------------------------------------

foreach lef_path $LEF_FILES {
    set match_dk 0
    # LEF
    set lef_file [file tail $lef_path]
    set match_lef [file rootname $lef_file]

    foreach db_path $TARGET_LIBRARY {
        set db_file [file tail $db_path]
        set match_db [file rootname $db_file]

        # MATCH
        if {[string match "*$match_lef*" $match_db]} {
            puts $Detail_report_file "Matched: $match_lef"
            puts $Detail_report_file "LEF : $lef_path"
            puts $Detail_report_file "DB  : $db_path\n"

            puts $script_file "# workspace $match_db: "
            puts $script_file "create_workspace -flow exploration -scale_factor $SCALE_FACTOR -technology $TECH_FILE ${match_db}_ws"
            puts $script_file "read_db $db_path"
            puts $script_file "read_lef $lef_path"
            puts $script_file "group_libs"
            puts $script_file "write_workspace -file ${SCRIPT_DIR}/${match_db}_ws.tcl -commit_output ${NDM_DIR}"
            puts $script_file "check_workspace"
            puts $script_file "report_workspace > ${REPORT_DIR}/report_workspace_${match_db}.rpt"
            puts $script_file "remove_workspace "
            puts $script_file "source ${SCRIPT_DIR}/${match_db}_ws.tcl \n"

            set match_dk 1
            lappend MATCH_DB $db_path
            lappend MATCH_LEF $lef_path
        }
    }
    if {$match_dk == "0"} {
        lappend N_MATCH_LEF $lef_path
        incr LEF_COUNTER($lef_path)
    }
}
close $script_file

foreach lef [array names LEF_COUNTER] {
    if {$LEF_COUNTER($lef) == $SCENARIO_COUNT } {
        lappend COMMON_UNMATCHED $lef
    }
}
foreach item $TARGET_LIBRARY {
    if {[lsearch -exact $MATCH_DB $item] == -1} {
        lappend N_MATCH_DB $item
    }
}

# --------------------------------------
# Report
# --------------------------------------
set MATCH_DB        [lsort -unique $MATCH_DB]
set N_MATCH_DB      [lsort -unique $N_MATCH_DB]
set MATCH_LEF       [lsort -unique $MATCH_LEF]
set N_MATCH_LEF     [lsort -unique $N_MATCH_LEF]


puts $Summary_report_file "# ---------------------------------"
puts $Summary_report_file "# UnMatch Summary"
puts $Summary_report_file "# ---------------------------------"
puts $Summary_report_file "# Unmatch DB"
puts $Summary_report_file [join [split $N_MATCH_DB ] "\n"]
puts $Summary_report_file ""
puts $Summary_report_file "# Unmatch LEF (Cells included in the unmatched LEF are generated in the physical_only.ndm.)"
puts $Summary_report_file [join [split $N_MATCH_LEF ] "\n"]
puts $Summary_report_file ""
puts $Summary_report_file "# ---------------------------------"
puts $Summary_report_file "# Match Summary"
puts $Summary_report_file "# ---------------------------------"
puts $Summary_report_file "# Match DB"
puts $Summary_report_file [join [split $MATCH_DB ] "\n"]
puts $Summary_report_file ""
puts $Summary_report_file "# Match LEF"
puts $Summary_report_file [join [split $MATCH_LEF ] "\n"]
puts $Summary_report_file ""

close $Detail_report_file
close $Summary_report_file
