################################################################################
# File Name     : config_teco_physical.tcl
# Author        : DT-PI
# Creation Date : 2025-04-17
# Last Modified : 2025-06-10
# Version       : v0.2
# Location      : $COMMON_IMPL_DIR/common_tcl/pt/config_teco_physical.tcl
#-------------------------------------------------------------------------------
# Description   :
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2025-04-17] : jaeeun1115
#       - Initial Version Release
# 	v0.2 [2025-06-10] : jaeeun1115
#       - Add the condition for loading lef & def of HSC sub blocks
#-------------------------------------------------------------------------------
# Useage        : 
#   source $COMMON_IMPL_DIR/common_tcl/pt/config_teco_physical.tcl
#################################################################################

;#------------------------------------------------------------------------------
;# Collaterals for Physical-aware ECO
;#------------------------------------------------------------------------------
set ECO_WORK_DIR        ./
set ECO_SCRIPT_PATH     ./
set LEF_PATH            ${SPEF_DIR}
set DEF_PATH            ${SPEF_DIR}
set LEF_FILES           [glob -nocomplain ${LEF_PATH}/*.lef]
set DEF_FILE            ${DEF_PATH}/${DESIGN}.def.gz

;#------------------------------------------------------------------------------
;# flat_dmsa Hier Design Info setting
;#------------------------------------------------------------------------------
if { ([info exist is_flat] && $is_flat ) && $HIER_DESIGN != "NONE" } {

	puts "Information_ADF: Hierarchy  designs  -  $HIER_DESIGN "

    remote_execute { foreach db $READ_DB_LISTS {puts "$db"} } -verbose > temp

    set input [open temp r]
    
    while { [gets $input line] >=0 } {
        if {[regexp {(,NET,|,HSC,)} $line]} {
            lappend NET_DESIGN_NAME_LIST [lindex [split $line ,] 0]
            lappend NET_DESIGN_LIST      $line
        }
    }
    
    set UNI_NET_DESIGN_NAME_LIST [lsort -unique $NET_DESIGN_NAME_LIST]
    set UNI_NET_DESIGN_LIST      [lsort -unique $NET_DESIGN_LIST]
    
    puts "Information_ADF: Hierarchy  designs with NET | HSC -  $UNI_NET_DESIGN_NAME_LIST"
    puts "Information_ADF: NET | HSC db list"
    foreach db $UNI_NET_DESIGN_LIST {
        puts "  $db"
    }
    close $input
    #sh rm -f temp


	foreach BLK  $UNI_NET_DESIGN_NAME_LIST  {
		puts "Information_ADF: Hierarchy  designs  -  $BLK "
		set BLK_NAME         [ set ${BLK}(NAME)         ];#set sub_name          $SUB_NAME($BLK)
		set BLK_INDB_VER     [ set ${BLK}(INDB_VER)     ];#set sub_net_ver       $SUB_INDB_VER($BLK)
		set BLK_PNR_TOOL     [ set ${BLK}(PNR_TOOL)     ];#set sub_pnr_tool      $SUB_PNR_TOOL($BLK)
		set BLK_NET_REVISION [ set ${BLK}(NET_REVISION_POST) ];#set sub_net_revision  $SUB_NET_REVISION_POST($BLK)
		set BLK_ECO_NUM      [ set ${BLK}(NET_ECO_NUM)  ];#set sub_net_eco_num   $SUB_NET_ECO_NUM($BLK)

		set BLK_SUB_SPEF_DIR ${OUTFD_DIR}/$BLK_NAME/$BLK_INDB_VER/$BLK_PNR_TOOL/$BLK_NET_REVISION/$BLK_ECO_NUM/output

		set SUB_LEF_FILES($BLK)   [glob -nocomplain ${BLK_SUB_SPEF_DIR}/*.lef]
		set SUB_DEF_FILE($BLK)    ${BLK_SUB_SPEF_DIR}/${BLK}.def.gz
		puts "$SUB_LEF_FILES($BLK)"
		puts "$SUB_DEF_FILE($BLK)"

		set LEF_FILES [concat $LEF_FILES $SUB_LEF_FILES($BLK)]
		set DEF_FILE [concat $DEF_FILE $SUB_DEF_FILE($BLK)]
	}
}

set LEF_FILES [lsort -unique $LEF_FILES]
set DEF_FILE  [lsort -unique $DEF_FILE]
puts ""
puts "ALL_LEF_FILES : $LEF_FILES"
puts "ALL_DEF_FILE : $DEF_FILE"
puts ""
