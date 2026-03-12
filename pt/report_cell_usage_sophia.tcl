################################################################################
# File Name     : report_cel_usage_sophia.tcl
# Author        : jaeeun1115
# Creation Date : 2024-12-09
# Last Modified : 2025-06-25 
# Version       : v0.3
# Location      : ${PRJ_PT}/design_scripts/basic_reports.tcl
#-------------------------------------------------------------------------------
# Description   : 
#-------------------------------------------------------------------------------
# Change Log    :
# 	[2024-12-09 v0.1] : Initial Version Release
# 	[2025-01-15 v0.2] : Add lindex due to multiple libs cell for one ref
# 	[2025-06-25 v0.3] : Add ETM usage
#-------------------------------------------------------------------------------
# Useage        :
#		pt_shell> source report_cel_usage_sophia.tcl
#################################################################################

set USED_LIB_CELLS [get_lib_cells */* -filter "is_instantiated == true"]
set REPORT_MEM_LIST ""
set REPORT_IP_LIST ""
set REPORT_PWRPAD_LIST ""
set REPORT_PAD_LIST ""
set REPORT_ETM_LIST ""

#========================================================
# Memory
#========================================================
set MEM_CELLS [get_lib_cells */* -filter "is_instantiated == true && is_memory_cell == true"]
set MEM_CNT 0
set MEM_AREA 0

foreach_in_collection mem $MEM_CELLS {
    set current_ref_name [get_attr $mem base_name]

    set [set current_ref_name](cnt)       [sizeof_collection [get_cells -h -f "ref_name =~ $current_ref_name"]]
    set [set current_ref_name](unit_area) [lindex [get_attr [get_lib_cells $mem] area] 0]
    set [set current_ref_name](area)      [expr $[set current_ref_name](cnt) * $[set current_ref_name](unit_area)]

    if {[regexp -nocase {OTP} $current_ref_name]} {
        lappend REPORT_IP_LIST $current_ref_name
        continue
    } else {
        lappend REPORT_MEM_LIST $current_ref_name
    }

    set MEM_CNT  [expr $MEM_CNT + $[set current_ref_name](cnt)]
    set MEM_AREA [expr $MEM_AREA + $[set current_ref_name](area)]
}


#========================================================
# PAD
#========================================================
foreach_in_collection lc $USED_LIB_CELLS {
    if { [get_attr $lc is_memory_cell]==false } {
        set ref_name [get_attr $lc base_name]

        if {[regexp -nocase {^P.?(VDD|VSS)} $ref_name]} {
            lappend REPORT_PWRPAD_LIST $ref_name

        } elseif {[get_attr $lc is_pad_cell]==true || [regexp -nocase {^(PB|PA|POSC|PEXTFS|PESDCORE)} $ref_name]} {
            lappend REPORT_PAD_LIST $ref_name
        }
    }
}

set PWRPAD_CNT 0
set PWRPAD_AREA 0
set PAD_CNT 0
set PAD_AREA 0

foreach pwrpad $REPORT_PWRPAD_LIST {
    set [set pwrpad](cnt)       [sizeof_collection [get_cells -h -f "ref_name =~ $pwrpad"]] 
    set [set pwrpad](unit_area) [lindex [get_attr [get_lib_cells */$pwrpad] area] 0]
    set [set pwrpad](area)      [expr $[set pwrpad](cnt) * $[set pwrpad](unit_area)]

    set PWRPAD_CNT [expr $PWRPAD_CNT + $[set pwrpad](cnt)]
    set PWRPAD_AREA [expr $PWRPAD_AREA + $[set pwrpad](area)]
}
foreach pad $REPORT_PAD_LIST {
    set [set pad](cnt)       [sizeof_collection [get_cells -h -f "ref_name =~ $pad"]] 
    set [set pad](unit_area) [lindex [get_attr [get_lib_cells */$pad] area] 0]
    set [set pad](area)      [expr $[set pad](cnt) * $[set pad](unit_area)]

    set PAD_CNT [expr $PAD_CNT + $[set pad](cnt)]
    set PAD_AREA [expr $PAD_AREA + $[set pad](area)]
}

set ALL_PAD_LIST [concat $REPORT_PWRPAD_LIST $REPORT_PAD_LIST]


#========================================================
# IP (PLL + Unknown)
#========================================================
set BB_CELLS [get_attr [get_lib_cells */* -filter "is_instantiated == true && is_black_box==true && is_memory_cell==false"] base_name]

foreach bb $BB_CELLS {
    if {[lsearch -exact $ALL_PAD_LIST $bb] < 0 } {

        # IP conditions could be added
        if {[regexp -nocase {.*(CDM|EFROM).*} $bb]} {
            continue
        } elseif {[regexp -nocase {^(PFILL|FILL.*CAP|FILLECO|PCORNER|PLINK|HEAD|FOOT|ANTENNA)} $bb]} {
            continue
        }
        lappend REPORT_IP_LIST $bb
    }
}
set IP_CNT 0
set IP_AREA 0
set PLL_CNT 0
set PLL_AREA 0

foreach ip $REPORT_IP_LIST {
    set [set ip](cnt)       [sizeof_collection [get_cells -h -f "ref_name =~ $ip"]] 
    set [set ip](unit_area) [lindex [get_attr [get_lib_cells */$ip] area] 0]
    set [set ip](area)      [expr $[set ip](cnt) * $[set ip](unit_area)]

    set IP_CNT  [expr $IP_CNT + $[set ip](cnt)]
    set IP_AREA [expr $IP_AREA + $[set ip](area)]

    if {[regexp -nocase {PLL} $ip]} {
        set PLL_CNT  [expr $PLL_CNT + $[set ip](cnt)]
        set PLL_AREA [expr $PLL_AREA + $[set ip](area)]
    }
}


#========================================================
# ETM (Sub Design)
#========================================================
foreach etm $READ_DB_LISTS {
    if {[regexp {,ETM,} $etm]} {
        lappend REPORT_ETM_LIST [lindex [split $etm ,] 0]
    }
}

set ETM_CNT 0
set ETM_AREA 0

foreach etm $REPORT_ETM_LIST {
    set [set etm](cnt)       [sizeof_collection [get_cells -h -f "ref_name =~ $etm"]] 
    set [set etm](unit_area) [lindex [get_attr [get_lib_cells */$etm] area] 0]
    set [set etm](area)      [expr $[set etm](cnt) * $[set etm](unit_area)]

    set ETM_CNT  [expr $ETM_CNT + $[set etm](cnt)]
    set ETM_AREA [expr $ETM_AREA + $[set etm](area)]
}

#========================================================
# NAND2 area for gate count
#========================================================
set NAND2_GATES [get_lib_cells */* -filter "function_id == Ia2.0"]

foreach_in_collection nand2 $NAND2_GATES {
    set ref_name [get_attr $nand2 base_name]
    if {[regexp {^NAND2_D1_} $ref_name] || [regexp {^NAND2_X1N_} $ref_name] || [regexp {.*_ND2_1} $ref_name]} {
        set NAND2_REF  $ref_name
        set NAND2_AREA [get_attr $nand2 area]
        break
    }
}
if {![info exist NAND2_AREA]} {
    set no_nand2_match_by_naming_rule 1
    foreach_in_collection nand2 $NAND2_GATES {
        set temp [list [get_attr $nand2 area] [get_attr $nand2 base_name]]
        lappend NAND2_LIST [join $temp -]
    }
    lsort $NAND2_LIST
    set NAND2_REF  [lindex [split [lindex $NAND2_LIST 0] -] 1]
    set NAND2_AREA [lindex [split [lindex $NAND2_LIST 0] -] 0]
}


#========================================================
# Report Total Summary
#========================================================
set OUTPUT_FILE "${REPORT_DIR}/cell_usage.rpt.for_sophia"
set output [open ${OUTPUT_FILE} w+]

puts $output [string repeat = 100]
puts $output " Target Design: [get_object_name [current_design]]"
puts $output " Report Date  : [date]" 
puts $output " Report by    : [sh whoami] @ [info hostname]:[pwd]"
puts $output [string repeat = 100]


# TOTAL SUMMARY
puts $output "  TOTAL SUMMARY"
puts $output "                                                             count                   area"
puts $output [string repeat = 100]

set temp [open ${REPORT_DIR}/cell_usage.rpt.sort_by_ref_name r]
while { [gets $temp line] >= 0 } {
    if {[regexp {Total} $line]} {
        set cnt_all  [lindex $line 1]
        set area_all [lindex $line 2]
        break
    }
}
close $temp

puts $output [format "  %-53s %10d %8s %13.4f %8s" "Total" $cnt_all "" $area_all ""]


# Memory SUMMARY
if {$MEM_CNT > 0} {
    set cnt_ratio  [expr double($MEM_CNT)/double($cnt_all) * 100.0]
    set area_ratio [expr double($MEM_AREA)/$area_all * 100.0]
    puts $output [format "  %-53s %10d (%5.2f%%) %13.4f (%5.2f%%)" "Total Memories" $MEM_CNT $cnt_ratio $MEM_AREA $area_ratio]
}

# PAD SUMMARY
if {[expr $PWRPAD_CNT + $PAD_CNT] > 0} {
    set cnt_ratio  [expr double([expr $PWRPAD_CNT + $PAD_CNT])/double($cnt_all) * 100.0]
    set area_ratio [expr double([expr $PWRPAD_AREA + $PAD_AREA])/$area_all * 100.0]
    puts $output [format "  %-53s %10d (%5.2f%%) %13.4f (%5.2f%%)" "Total PAD cells" [expr $PWRPAD_CNT + $PAD_CNT] $cnt_ratio [expr $PWRPAD_AREA + $PAD_AREA] $area_ratio]

    set cnt_ratio  [expr double($PAD_CNT)/double($cnt_all) * 100.0]
    set area_ratio [expr double($PAD_AREA)/$area_all * 100.0]
    puts $output [format "  %-53s %10d (%5.2f%%) %13.4f (%5.2f%%)" "      PAD cells" $PAD_CNT $cnt_ratio $PAD_AREA $area_ratio]

    set cnt_ratio  [expr double($PWRPAD_CNT)/double($cnt_all) * 100.0]
    set area_ratio [expr double($PWRPAD_AREA)/$area_all * 100.0]
    puts $output [format "  %-53s %10d (%5.2f%%) %13.4f (%5.2f%%)" "      PWRPAD cells" $PWRPAD_CNT $cnt_ratio $PWRPAD_AREA $area_ratio]
}

# IP SUMMARY
if {$IP_CNT > 0} {
    set cnt_ratio  [expr double($IP_CNT)/double($cnt_all) * 100.0]
    set area_ratio [expr double($IP_AREA)/double($area_all) * 100.0]
    puts $output [format "  %-53s %10d (%5.2f%%) %13.4f (%5.2f%%)" "Total IP cells" $IP_CNT $cnt_ratio $IP_AREA $area_ratio]

    set cnt_ratio  [expr double($PLL_CNT)/double($cnt_all) * 100.0]
    set area_ratio [expr double($PLL_AREA)/double($area_all) * 100.0]
    puts $output [format "  %-53s %10d (%5.2f%%) %13.4f (%5.2f%%)" "      PLL" $PLL_CNT $cnt_ratio $PLL_AREA $area_ratio]
}

# ETM SUMMARY
if {$ETM_CNT > 0} {
    set cnt_ratio  [expr double($ETM_CNT)/double($cnt_all) * 100.0]
    set area_ratio [expr double($ETM_AREA)/double($area_all) * 100.0]
    puts $output [format "  %-53s %10d (%5.2f%%) %13.4f (%5.2f%%)" "Total ETM cells" $ETM_CNT $cnt_ratio $ETM_AREA $area_ratio]
}


# Logic SUMMARY (excluding above)
set LOGIC_CNT  [expr $cnt_all - $MEM_CNT - $PWRPAD_CNT - $PAD_CNT - $IP_CNT - $ETM_CNT]
set LOGIC_AREA [expr $area_all - $MEM_AREA - $PWRPAD_CNT - $PAD_CNT - $IP_AREA - $ETM_AREA]

set cnt_ratio  [expr double($LOGIC_CNT)/double($cnt_all) * 100.0]
set area_ratio [expr double($LOGIC_AREA)/double($area_all) * 100.0]
puts $output [format "  %-53s %10d (%5.2f%%) %13.4f (%5.2f%%)" "Other Logic cells" $LOGIC_CNT $cnt_ratio $LOGIC_AREA $area_ratio]

puts $output [string repeat = 100]


#========================================================
# NAND2 area for gate counting
#========================================================
puts $output [string repeat = 100]
puts $output "  NAND2 Area for Gate Counting"

if {[info exist no_nand2_match_by_naming_rule] && $no_nand2_match_by_naming_rule} {
    puts $output "  <Warning> : Selected by area not naming rule. Please check if it's right."
}

puts $output "      ref_name  : $NAND2_REF"
puts $output "      area      : $NAND2_AREA"
puts $output ""
puts $output "  Gate Counting"
puts $output "      Total Area       : $area_all"
puts $output "      Total Gate Count : [expr round(double($area_all)/double($NAND2_AREA))] "
if {$ETM_CNT > 0} {
    puts $output ""
    puts $output "  Gate Counting (except ETM)"
    puts $output "      Area (except ETM)       : [expr double($area_all)-double($ETM_AREA)]"
    puts $output "      Gate Count (except ETM) : [expr round((double($area_all)-double($ETM_AREA))/double($NAND2_AREA))]"
}
puts $output [string repeat = 100]
puts $output ""


#========================================================
# USAGE BY REF
#========================================================
# MEMORY USAGE BY REF
if {${MEM_CNT} > 0} {
    puts $output [string repeat = 100]
    puts $output "  MEMORY USAGE BY REF"
    puts $output "  ref_name                                                   count                   area"
    puts $output [string repeat = 100]
    
    foreach mem $REPORT_MEM_LIST {
        set cnt_ratio  [expr double($[set mem](cnt))/double($cnt_all) * 100.0]
        set area_ratio [expr double($[set mem](area))/double($area_all) * 100.0]
        
        set line1 [regsub -all " " [format "%-53s %10d" $mem [set [set mem](cnt)]] "."]
        set line2 [format "  $line1 (%5.2f%%) %13.4f (%5.2f%%)" $cnt_ratio [set [set mem](area)] $area_ratio]
    
        puts $output $line2
    }
    puts $output [string repeat = 100]
    puts $output ""
}

# PAD USAGE BY REF
if {$PAD_CNT > 0 } {
    puts $output [string repeat = 100]
    puts $output "  PAD USAGE BY REF"
    puts $output "  ref_name                                                   count                   area"
    puts $output [string repeat = 100]

    foreach pad $REPORT_PAD_LIST {
        set cnt_ratio  [expr double($[set pad](cnt))/double($cnt_all) * 100.0]
        set area_ratia [expr double($[set pad](area))/double($area_all) * 100.0]

        set line1 [regsub -all " " [format "%-53s %10d" $pad [set [set pad](cnt)]] "."]
        set line2 [format "  $line1 (%5.2f%%) %13.4f (%5.2f%%)" $cnt_ratio [set [set pad](area)] $area_ratio]

        puts $output $line2
    }
    puts $output [string repeat = 100]
    puts $output ""
}

# PWRPAD USAGE BY REF
if {$PWRPAD_CNT > 0} {
    puts $output [string repeat = 100]
    puts $output "  PWRPAD USAGE BY REF"
    puts $output "  ref_name                                                   count                   area"
    puts $output [string repeat = 100]

    foreach pad $REPORT_PWRPAD_LIST {
        set cnt_ratio  [expr double($[set pad](cnt))/double($cnt_all) * 100.0]
        set area_ratia [expr double($[set pad](area))/double($area_all) * 100.0]

        set line1 [regsub -all " " [format "%-53s %10d" $pad [set [set pad](cnt)]] "."]
        set line2 [format "  $line1 (%5.2f%%) %13.4f (%5.2f%%)" $cnt_ratio [set [set pad](area)] $area_ratio]

        puts $output $line2
    }
    puts $output [string repeat = 100]
    puts $output ""
}

# IP USAGE BY REF
if {$IP_CNT > 0} {
    puts $output [string repeat = 100]
    puts $output "  IP USAGE BY REF"
    puts $output ""
    puts $output "  <Info> : All unknown types are detected as IP."
    puts $output "           If there's any wrong type of reference, please report to dtpi@adtek.co.kr"
    puts $output ""
    puts $output "  ref_name                                                   count                   area"
    puts $output [string repeat = 100]

    foreach ip $REPORT_IP_LIST {
        set cnt_ratio  [expr double($[set ip](cnt))/double($cnt_all) * 100.0]
        set area_ratio [expr double($[set ip](area))/double($area_all) * 100.0]

        set line1 [regsub -all " " [format "%-53s %10d" $ip [set [set ip](cnt)]] "."]
        set line2 [format "  $line1 (%5.2f%%) %13.4f (%5.2f%%)" $cnt_ratio [set [set ip](area)] $area_ratio]
    
        puts $output $line2
    }
    puts $output [string repeat = 100]
    puts $output ""
}

# ETM USAGE BY REF
if {$ETM_CNT > 0} {
    puts $output [string repeat = 100]
    puts $output "  ETM USAGE BY REF"
    puts $output "  ref_name                                                   count                   area"
    puts $output [string repeat = 100]

    foreach etm $REPORT_ETM_LIST {
        set cnt_ratio  [expr double($[set etm](cnt))/double($cnt_all) * 100.0]
        set area_ratio [expr double($[set etm](area))/double($area_all) * 100.0]

        set line1 [regsub -all " " [format "%-53s %10d" $etm [set [set etm](cnt)]] "."]
        set line2 [format "  $line1 (%5.2f%%) %13.4f (%5.2f%%)" $cnt_ratio [set [set etm](area)] $area_ratio]
    
        puts $output $line2
    }
    puts $output [string repeat = 100]
    puts $output ""
}


#========================================================
# MATCH INST
#========================================================
# MATCH INST (MEMORY)
if {$MEM_CNT > 0} {
    puts $output [string repeat = 100]
    puts $output "  MATCH INST (MEMORY)"
    puts $output "  ref_name                                  Inst name"
    puts $output [string repeat = 100]

    foreach mem $REPORT_MEM_LIST {
        set current_mem [get_cells -h -f "ref_name =~ $mem"]

        foreach_in_collection inst $current_mem {
            puts $output [format "  %-41s [get_object_name $inst]" $mem]
        }
    }
    puts $output [string repeat = 100]
    puts $output ""
}

# MATCH INST (PAD)
if {$PAD_CNT > 0} {
    puts $output [string repeat = 100]
    puts $output "  MATCH INST (PAD)"
    puts $output "  ref_name                                  Inst name"
    puts $output [string repeat = 100]

    foreach pad $REPORT_PAD_LIST {
        set current_pad [get_cells -h -f "ref_name =~ $pad"]

        foreach_in_collection inst $current_pad {
            puts $output [format "  %-41s [get_object_name $inst]" $pad]
        }
    }
    puts $output [string repeat = 100]
    puts $output ""
}

# MATCH INST (PWRPAD)
if {$PAD_CNT > 0} {
    puts $output [string repeat = 100]
    puts $output "  MATCH INST (PWRPAD)"
    puts $output "  ref_name                                  Inst name"
    puts $output [string repeat = 100]

    foreach pwrpad $REPORT_PWRPAD_LIST {
        set current_pwrpad [get_cells -h -f "ref_name =~ $pwrpad"]

        foreach_in_collection inst $current_pwrpad {
            puts $output [format "  %-41s [get_object_name $inst]" $pwrpad]
        }
    }
    puts $output [string repeat = 100]
    puts $output ""
}

# MATCH INST (IP)
if {$IP_CNT > 0} {
    puts $output [string repeat = 100]
    puts $output "  MATCH INST (IP)"
    puts $output "  ref_name                                  Inst name"
    puts $output [string repeat = 100]

    foreach ip $REPORT_IP_LIST {
        set current_ip [get_cells -h -f "ref_name =~ $ip"]

        foreach_in_collection inst $current_ip {
            puts $output [format "  %-41s [get_object_name $inst]" $ip]
        }
    }
    puts $output [string repeat = 100]
    puts $output ""

}

# MATCH INST (ETM)
if {$IP_CNT > 0} {
    puts $output [string repeat = 100]
    puts $output "  MATCH INST (ETM)"
    puts $output "  ref_name                                  Inst name"
    puts $output [string repeat = 100]

    foreach etm $REPORT_ETM_LIST {
        set current_etm [get_cells -h -f "ref_name =~ $etm"]

        foreach_in_collection inst $current_etm {
            puts $output [format "  %-41s [get_object_name $inst]" $etm]
        }
    }
    puts $output [string repeat = 100]
    puts $output ""

}

close $output
