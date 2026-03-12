################################################################################
# File Name     : auto_site_mapping.tcl
# Author        : DT-PI
# Last Modified : 2024-02-18
# Version       : v0.2
# Location      : ${COMMON_TCL}/dc_syn
#-------------------------------------------------------------------------------
# Description   :
#   auto site mapping
#
#-------------------------------------------------------------------------------
# Change Log    :
#       - Initial Version Release
#       - Modify Version Release (250617)
#
#-------------------------------------------------------------------------------
# Useage        :
#		dc_shell >> source auto_site_mapping.tcl
#################################################################################

# --------------------------------------
# Load Site Info from TECH File
# --------------------------------------
if {![info exists TECH_FILE] || ![file exist $TECH_FILE]} {
    puts "Warning_ADF : TECH FILE is not exists"; return

}
set fpin [open $TECH_FILE "r"]

set Site_List_TECH ""
array unset SITE_INFO_TECH
set Site_name ""
set WIDTH ""
set HEIGHT ""

while {[gets $fpin line] >= 0} {
    if {[regexp {^Layer} $line]} {continue}
    set close_count [regexp -all {\}} $line]
    
    if {[regexp {^Tile} $line]} {
        regexp {Tile\s+"([^"]+)"} $line match Site_name
        lappend Site_List_TECH $Site_name
    }

    if {$Site_name != ""} {
        if {!$close_count} {
            if {[regexp {width}  $line]} { set WIDTH  [expr 1* [lindex $line 2]] }
            if {[regexp {height} $line]} { set HEIGHT [expr 1* [lindex $line 2]] }
        } else {
            set SITE_INFO_TECH($Site_name) [list $WIDTH $HEIGHT]
            set Site_name ""
            set WIDTH ""
            set HEIGHT ""
        }
    }
}
close $fpin
puts "TECH Site Name : $Site_List_TECH "

####################################################################################################
# LEF Setup
####################################################################################################
set LEF_DIRS ""
set LEF_FILE "${LIB_DIR}/abs/00_PRIM/${ABS_PRIM_VERSION}/02_LEF/lef.abs.list"
if {![info exists LEF_FILE] || ![file exist $LEF_FILE]} {
    puts "Warning_ADF : LEF FILE is not exists"; return
}

if {[file exists [which $LEF_FILE ]]} {
    set Fin [open $LEF_FILE r]
    while { [ gets $Fin line ] != -1 } {
        if { [regexp {^#} $line] || ![regexp {\w+} $line] } { continue } ; #Exclude comments or leading blanks
        if {[info exists DK_TYPE] } {
            if {[string match "*SEC*" $DK_TYPE ] && ![regexp {_flk_} $line] } {continue}
            if {[string match "*ARM*" $DK_TYPE ] && ![regexp {_base_} $line]} {continue}
            if {[string match "*SNPS*" $DK_TYPE]} {puts "Warning_ADF : SNPS DK  is not accurate."}
        }
        set LEF_DIRS [concat $LEF_DIRS $line]
    } ;close $Fin 
}

# --------------------------------------
# Load Site Info from LEF File
# --------------------------------------
set Site_List_LEF ""
array unset SITE_INFO_LEF

foreach LEF $LEF_DIRS {
    set fpin [open $LEF "r"]
    
    set Site_name ""
    set WIDTH ""
    set HEIGHT ""
    
    while {[gets $fpin line] >= 0} {
        if {[regexp {^MACRO} $line]} { break }
        if {[regexp {^SITE} $line]} {
            set Site_name [lindex $line 1]
        }
        if {[info exists SITE_INFO_LEF($Site_name)]} {set Site_name ""; continue}
        if {$Site_name != ""} {
            if {[regexp {^END} $line]} {set Site_name ""; set WIDTH ""; set HEIGHT "" }
            if {[regexp {SIZE} $line]} {
                set WIDTH  [expr 1* [lindex $line 1]]
                set HEIGHT [expr 1* [lindex $line 3]]
            }
        }

        if {$Site_name != "" && $WIDTH != "" && $HEIGHT != ""} {
            lappend Site_List_LEF $Site_name
            set SITE_INFO_LEF($Site_name) [list $WIDTH $HEIGHT]
        }
    }
    close $fpin
}
puts "LEF Site Name : $Site_List_LEF "

# --------------------------------------
# Compare TECH vs LEF Site Size Info
# --------------------------------------
foreach st $Site_List_TECH {
    set Width_t  [lindex $SITE_INFO_TECH($st) 0]
    set Height_t [lindex $SITE_INFO_TECH($st) 1]

    foreach sl $Site_List_LEF {
        set Width_l  [lindex $SITE_INFO_LEF($sl) 0]
        set Height_l [lindex $SITE_INFO_LEF($sl) 1]
        if {$Width_t eq $Width_l && $Height_t eq $Height_l} {
            puts "Information_ADF : Site Match! TECH: $st , LEF: $sl"
            lappend Site_map "$sl $st"
        }
    }
}
if {[info exists Site_map] && $Site_map != ""} {
    if {[llength $Site_map] > 1} {
        puts "Warning_ADF: More than one site has been mapped."

        # 1. Site name sort
        set name_list {}
        foreach ll $Site_map {
            lappend name_list [lindex $ll 0] 
        }

        # 2. common_prefix 
        proc common_prefix {list} {
            set first [lindex $list 0]
            set len [string length $first]

            for {set i 0} {$i < $len} {incr i} {
                set char [string index $first $i]
                foreach item $list {
                    if {[string index $item $i] ne $char} {
                        return [string range $first 0 [expr {$i - 1}]]
                    }
                }
            }
            return $first
        }
        set prefix [common_prefix $name_list]

        # 3.common prefix check
        set filtered_map {}
        foreach pair $Site_map {
            if {[lindex $pair 0] eq $prefix} {
                lappend filtered_map $pair
            }
        }

        # 4. Site_map Update
        set Site_map $filtered_map
    }
	puts "Information_ADF: Auto defined DEF site mapping"
    set mapping_cmd "set_app_var mw_site_name_mapping { $Site_map }"
	puts "    $mapping_cmd" ; eval $mapping_cmd
} else {
    puts "Error_ADF: Site Match is Failed"
}
