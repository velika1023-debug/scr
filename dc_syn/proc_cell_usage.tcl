###################################################################################################
# File               : proc_cell_usage.tcl                                                        #
# Author             : ADT-DT (bmkim)                                                             #
# Description        : cell usage rpt                                                             #
# Usage              :                                                                            #
# Init Release Date  : 2025.01.16                                                                 #
# Last Update  Date  : 2025.01.16                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.01.16 - first released                                                             #
###################################################################################################

#-========================================
# Summary Report Line Format
#-========================================
proc print_summary_line {fpout Label count ratio area area_ratio} {
    set line [format "  %-53s %10d (%5.2f%%) %13.4f (%5.2f%%)" $Label $count $ratio $area $area_ratio]
    puts $fpout $line
}

proc print_detail_line {fpout Label count ratio area area_ratio unit_area} {
    set line [format "  %-53s %10d (%5.2f%%) %13.4f (%5.2f%%) | %10.4f" $Label $count $ratio $area $area_ratio $unit_area]
    puts $fpout $line
}

proc cell_usage_rpt {args} {

    parse_proc_arguments -args $args results
    global sh_dev_null
    suppress_message CMD-041
    suppress_message UID-341

    redirect $sh_dev_null {set Design [get_object_name [current_design]]}
    if {$Design == ""} {
        unsuppress_message CMD-041
        unsuppress_message UID-341
        return -code error "Current design is not defined"
    }
    set dk_type SEC
    if {[info exists results(-dk_type)]} {
        set dk_type $results(-dk_type)
    }
    puts "  DK_type name : $dk_type"

    set outfile "$Design.cell_usage.rpt"
    if {[info exists results(-output)]} {
        set outfile $results(-output)
    }
    puts "  Outfile name : $outfile"

    set ref_verbos false
    if {[info exists results(-ref_verbos)]} {
        set ref_verbos $results(-ref_verbos)
    }
    puts "  Ref_verbos Option : $ref_verbos"
    set sort_by area
    if {[info exists results(-sort_by)]} {
        set sort_by $results(-sort_by)
    }
    puts "  Sort_by Option : $sort_by"

    #-========================================
    # Variable Setup
    #-========================================
    if {[info exists ALL_REF ]} {unset ALL_REF }  
    if {[info exists COUNT ]} {unset COUNT }
    if {[info exists AREA ]} {unset AREA }
    if {[info exists CELL ]} {unset CELL }
    
    if {$dk_type == "SEC"} {
        set DLY_NAME "*DLY*"
        set LATCH_NAME "*LAT*"
        set ICG_NAME "*ICG*"
        set FF_NAME "*DFF*"
    } elseif {$dk_type == "ARM"} {
        set DLY_NAME "*DLY*"
        set LATCH_NAME "*LAT*"
        set ICG_NAME "*ICG*"
        set FF_NAME "*DFF*"
    } elseif {$dk_type == "SNPS"} {
        set DLY_NAME "*_DEL_*"
        set LATCH_NAME "*_LD*"
        set ICG_NAME "*_CKG*"
        set FF_NAME "*_FSD*"
    } else {puts "DK_TYPE is not valid"; continue}


    # Group similar variables together using arrays for count and area
    array set COUNT {
        COMBINATIONAL 0
        BUF 0
        INV 0
        DLY 0
        Sequential 0
        Flip_Flop 0
        LATCH 0
        ICG 0
        Black_Box 0
        Sequential_Other 0
        Memory 0
        OTHER 0
        PAD 0
        MACRO 0
    }
    
    array set AREA {
        COMBINATIONAL 0.0
        BUF 0.0
        INV 0.0
        DLY 0.0
        Sequential 0.0
        Flip_Flop 0.0
        LATCH 0.0
        ICG 0.0
        Black_Box 0.0
        Sequential_Other 0.0
        Memory 0.0
        OTHER 0.0
        PAD 0.0
        MACRO 0.0
    }
    
    array set CELL {
        ALL ""
        COMBINATIONAL ""
        BUF ""
        INV ""
        DLY ""
        Sequential ""
        Flip_Flop ""
        LATCH ""
        ICG ""
        Black_Box ""
        Sequential_Other ""
        Memory ""
        OTHER ""
        PAD ""
        MACRO ""
    }
    
    # Cell collections initialization
    set ALL_CELL [get_cells -h * -f "ref_name != **logic_1** && ref_name != **logic_0** && is_hierarchical == false"]
    set ALL_CELL_COUNT 0
    set ALL_CELL_AREA 0.0
    set Memory_LIST [get_cells -h $ALL_CELL -f "is_sequential == true && is_memory_cell == true"]
    set MACRO_LIST [get_cells -h $ALL_CELL -f "is_sequential == true && is_macro_cell == true"]
    puts "\[[date]\] > Start Sorting Cell"
    
    #-========================================
    # MAIN ANALYSIS
    #-========================================
    foreach_in_collection cell $ALL_CELL {
        set ref_name    [get_attr [get_cells $cell] ref_name]
        redirect $sh_dev_null {set cell_area   [get_attr [get_cells $cell] area]}
        if {$cell_area == ""} { set cell_area 0 }
        if {[info exists CELL_INFO($ref_name)]} { continue }
        set is_COMBINATIONAL 0
        set is_BUF 0
        set is_INV 0
        set is_DLY 0
        set is_Sequential 0
        set is_Flip_Flop 0
        set is_LATCH 0
        set is_ICG 0
        set is_Black_Box 0
        set is_Sequential_Other 0
        set is_Memory 0
        set is_OTHER 0
        set is_PAD 0
        set is_MACRO 0

        if {[sizeof [get_lib_pins -of [get_lib_cells */$ref_name] -filter "is_pad == true"]] || [string match "*VDD*" $ref_name] || [string match "*VSS*" $ref_name] } {
            set is_PAD 1
        } elseif {[string match "true" [get_attr [get_cells $cell] is_combinational]]} {
            set is_COMBINATIONAL 1
            if {[string match "*_BUF_*" $ref_name]} {
                set is_BUF 1
            } elseif {[string match "*_INV_*" $ref_name]} {
                set is_INV 1
            } elseif {[string match "$DLY_NAME" $ref_name]} {
                set is_DLY 1
            }
        } elseif {[string match "true" [get_attr [get_cells $cell] is_sequential]]} {
            if {[lsearch -exact [get_object_name $Memory_LIST] [get_object_name $cell]] != -1} {
                set is_Memory 1
            } else {
                set is_Sequential 1
                if {[string match "$FF_NAME" $ref_name] } {
                    set is_Flip_Flop 1
                } elseif {[string match "$LATCH_NAME" $ref_name]} {
                    set is_LATCH 1
                } elseif {[string match "$ICG_NAME" $ref_name]} {
                    set is_ICG 1
                } elseif {[lsearch -exact [get_object_name $MACRO_LIST] [get_object_name $cell]] != -1} {
                    set is_MACRO 1
                } else {
                    set is_Sequential_Other 1
                }
            }
        } else {
            if {[get_attr [get_cells $cell] is_black_box] && "$cell_area" == "0"} {
                set is_Black_Box 1
            } else {
                set is_OTHER 1
            }
        }
        
        set CELL_INFO($ref_name) [list $cell_area $is_COMBINATIONAL $is_BUF $is_INV $is_DLY $is_Sequential $is_Flip_Flop $is_LATCH $is_ICG $is_Black_Box $is_Sequential_Other $is_Memory $is_OTHER $is_PAD $is_MACRO]
    }

    foreach_in_collection cell $ALL_CELL {
        set ref_name    [get_attr [get_cells $cell] ref_name]
        set cell_info   $CELL_INFO($ref_name)
        set cell_area   [lindex $cell_info 0]
        set is_COMBINATIONAL [lindex $cell_info 1]
        set is_BUF [lindex $cell_info 2]
        set is_INV [lindex $cell_info 3]
        set is_DLY [lindex $cell_info 4]
        set is_Sequential [lindex $cell_info 5]
        set is_Flip_Flop [lindex $cell_info 6]
        set is_LATCH [lindex $cell_info 7]
        set is_ICG [lindex $cell_info 8]
        set is_Black_Box [lindex $cell_info 9]
        set is_Sequential_Other [lindex $cell_info 10]
        set is_Memory [lindex $cell_info 11]
        set is_OTHER [lindex $cell_info 12]
        set is_PAD [lindex $cell_info 13]
        set is_MACRO [lindex $cell_info 14]

        # FOR ALL_CELL
        incr ALL_CELL_COUNT
        set ALL_CELL_AREA [expr $ALL_CELL_AREA + $cell_area]
        if {$ref_verbos == "false" } {
            if {![info exists ALL_REF($ref_name,"count")]} {
                lappend CELL(ALL) [list $ref_name]
                set ALL_REF($ref_name,"count") 1
                set ALL_REF($ref_name,"unit_area") $cell_area
                set ALL_REF($ref_name,"area") $cell_area 
            }  else { 
                incr ALL_REF($ref_name,"count")
                set ALL_REF($ref_name,"area") [expr $ALL_REF($ref_name,"area") + $cell_area] 
            }
        }
        # PAD PROCESS
         if {$is_PAD} {
            incr COUNT(PAD)
            set AREA(PAD) [expr {$AREA(PAD) + $cell_area}]

            if {$ref_verbos == "true" } {
                # PAD 
                if {![info exists PAD_REF($ref_name,"count")]} {
                    lappend CELL(PAD) [list $ref_name]
                    set PAD_REF($ref_name,"count") 1
                    set PAD_REF($ref_name,"unit_area") $cell_area 
                    set PAD_REF($ref_name,"area") $cell_area 
                }  else { 
                    incr PAD_REF($ref_name,"count")
                    set PAD_REF($ref_name,"area") [expr $PAD_REF($ref_name,"area") + $cell_area] 
                }
            }
        }
        
        # COMBINATIONAL PROCESS
        if {$is_COMBINATIONAL} {
    
            incr COUNT(COMBINATIONAL)
            set AREA(COMBINATIONAL) [expr {$AREA(COMBINATIONAL) + $cell_area}]

            if {$ref_verbos == "true" } {
                # COMBINATIONAL REF
                if {![info exists COMBINATIONAL_REF($ref_name,"count")]} {
                    lappend CELL(COMBINATIONAL) [list $ref_name]
                    set COMBINATIONAL_REF($ref_name,"count") 1
                    set COMBINATIONAL_REF($ref_name,"unit_area") $cell_area 
                    set COMBINATIONAL_REF($ref_name,"area") $cell_area 
                }  else { 
                    incr COMBINATIONAL_REF($ref_name,"count")
                    set COMBINATIONAL_REF($ref_name,"area") [expr $COMBINATIONAL_REF($ref_name,"area") + $cell_area] 
                }
            }
    
            # Specific cells analysis (BUF, INV, DLY)
            if {$is_BUF} {
                incr COUNT(BUF)
                set AREA(BUF) [expr {$AREA(BUF) + $cell_area}]
            } elseif {$is_INV} {
                incr COUNT(INV)
                set AREA(INV) [expr {$AREA(INV) + $cell_area}]
            } elseif {$is_DLY} {
                incr COUNT(DLY)
                set AREA(DLY) [expr {$AREA(DLY) + $cell_area}]
            }
    
        }

        # MEMORY PROCESS
        if {$is_Memory} {
            incr COUNT(Memory)
            set AREA(Memory) [expr {$AREA(Memory) + $cell_area}]

            if {$ref_verbos == "true" } {   
                # Memory REF
                if {![info exists Memory_REF($ref_name,"count")]} {
                    lappend CELL(Memory) [list $ref_name]
                    set Memory_REF($ref_name,"count") 1
                    set Memory_REF($ref_name,"unit_area") $cell_area 
                    set Memory_REF($ref_name,"area") $cell_area 
                }  else { 
                    incr Memory_REF($ref_name,"count")
                    set Memory_REF($ref_name,"area") [expr $Memory_REF($ref_name,"area") + $cell_area] 
                }
            }
        }

        # Sequential PROCESS
        if {$is_Sequential} {

            incr COUNT(Sequential)
            set AREA(Sequential) [expr {$AREA(Sequential) + $cell_area}]
    
            if {$is_Flip_Flop} {
                incr COUNT(Flip_Flop)
                set AREA(Flip_Flop) [expr {$AREA(Flip_Flop) + $cell_area}]

                if {$ref_verbos == "true" } {
                    # Flip_Flop REF
                    if {![info exists Flip_Flop_REF($ref_name,"count")]} {
                        lappend CELL(Flip_Flop) [list $ref_name]
                        set Flip_Flop_REF($ref_name,"count") 1
                        set Flip_Flop_REF($ref_name,"unit_area") $cell_area 
                        set Flip_Flop_REF($ref_name,"area") $cell_area 
                    }  else { 
                        incr Flip_Flop_REF($ref_name,"count")
                        set Flip_Flop_REF($ref_name,"area") [expr $Flip_Flop_REF($ref_name,"area") + $cell_area] 
                    }
                }
    
            } elseif {$is_LATCH} {
                incr COUNT(LATCH)
                set AREA(LATCH) [expr {$AREA(LATCH) + $cell_area}]

                if {$ref_verbos == "true" } {
                    # LATCH REF
                    if {![info exists LATCH_REF($ref_name,"count")]} {
                        lappend CELL(LATCH) [list $ref_name]
                        set LATCH_REF($ref_name,"count") 1
                        set LATCH_REF($ref_name,"unit_area") $cell_area 
                        set LATCH_REF($ref_name,"area") $cell_area 
                    }  else { 
                        incr LATCH_REF($ref_name,"count")
                        set LATCH_REF($ref_name,"area") [expr $LATCH_REF($ref_name,"area") + $cell_area] 
                    }
                }
    
            } elseif {$is_ICG} {
                incr COUNT(ICG)
                set AREA(ICG) [expr {$AREA(ICG) + $cell_area}]
                
                if {$ref_verbos == "true" } {                   
                    # ICG REF
                    if {![info exists ICG_REF($ref_name,"count")]} {
                        lappend CELL(ICG) [list $ref_name]
                        set ICG_REF($ref_name,"count") 1
                        set ICG_REF($ref_name,"unit_area") $cell_area 
                        set ICG_REF($ref_name,"area") $cell_area 
                    }  else { 
                        incr ICG_REF($ref_name,"count")
                        set ICG_REF($ref_name,"area") [expr $ICG_REF($ref_name,"area") + $cell_area] 
                    }
                }
    
            } elseif {$is_MACRO} {
                incr COUNT(MACRO)
                set AREA(MACRO) [expr {$AREA(MACRO) + $cell_area}]
                
                if {$ref_verbos == "true" } {                   
                    # MACRO REF
                    if {![info exists MACRO_REF($ref_name,"count")]} {
                        lappend CELL(MACRO) [list $ref_name]
                        set MACRO_REF($ref_name,"count") 1
                        set MACRO_REF($ref_name,"unit_area") $cell_area 
                        set MACRO_REF($ref_name,"area") $cell_area 
                    }  else { 
                        incr MACRO_REF($ref_name,"count")
                        set MACRO_REF($ref_name,"area") [expr $MACRO_REF($ref_name,"area") + $cell_area] 
                    }
                }
    
            } elseif {$is_Sequential_Other} {
                incr COUNT(Sequential_Other)
                set AREA(Sequential_Other) [expr {$AREA(Sequential_Other) + $cell_area}]
    
                if {$ref_verbos == "true" } {                  
                    # Sequential Other
                    if {![info exists Sequential_Other_REF($ref_name,"count")]} {
                        lappend CELL(Sequential_Other) [list $ref_name]
                        set Sequential_Other_REF($ref_name,"count") 1
                        set Sequential_Other_REF($ref_name,"unit_area") $cell_area 
                        set Sequential_Other_REF($ref_name,"area") $cell_area 
                    }  else { 
                        incr Sequential_Other_REF($ref_name,"count")
                        set Sequential_Other_REF($ref_name,"area") [expr $Sequential_Other_REF($ref_name,"area") + $cell_area] 
                    }
                }
            }
        }
        if {$is_Black_Box} {
            incr COUNT(Black_Box)
            set AREA(Black_Box) [expr {$AREA(Black_Box) + $cell_area}]
            
            if {$ref_verbos == "true" } {                    
                # Black_Box REF
                if {![info exists Black_Box_REF($ref_name,"count")]} {
                    lappend CELL(Black_Box) [list $ref_name]
                    set Black_Box_REF($ref_name,"count") 1
                    set Black_Box_REF($ref_name,"area") $cell_area 
                    set Black_Box_REF($ref_name,"unit_area") $cell_area 
                }  else { 
                    incr Black_Box_REF($ref_name,"count")
                    set Black_Box_REF($ref_name,"area") [expr $Black_Box_REF($ref_name,"area") + $cell_area] 
                }
            }
    
        }
        # OTHER PROCESS
        if {$is_OTHER} {
            incr COUNT(OTHER)
            set AREA(OTHER) [expr {$AREA(OTHER) + $cell_area}]

            if {$ref_verbos == "true" } {
                # OTHER 
                if {![info exists OTHER_REF($ref_name,"count")]} {
                    lappend CELL(OTHER) [list $ref_name]
                    set OTHER_REF($ref_name,"count") 1
                    set OTHER_REF($ref_name,"unit_area") $cell_area 
                    set OTHER_REF($ref_name,"area") $cell_area 
                }  else { 
                    incr OTHER_REF($ref_name,"count")
                    set OTHER_REF($ref_name,"area") [expr $OTHER_REF($ref_name,"area") + $cell_area] 
                }
            }
        }
    }
    
    puts "\[[date]\] > END Sorting Cell"
    puts "\[[date]\] > Start Reporting Cell"
    #-========================================
    # REPORT STEP
    #-========================================
    set br_char "="
    set rpt_width 114
    set fpout [open report/$outfile w+]

    # Report Categories
    set categories {
        {ALL "" ALL_REF}
        {COMBINATIONAL "Total Combinational" COMBINATIONAL_REF }
        {BUF "      Buffers" }
        {INV "      Inverters" }
        {DLY "      DLY Cells" }
        {Sequential "Total Sequential" }
        {Flip_Flop "      Flip_Flop" Flip_Flop_REF }
        {ICG "      ICG cells" ICG_REF }
        {LATCH "      Non-ICG Latch cells" LATCH_REF }
        {Sequential_Other "      Sequential Other cells" Sequential_Other_REF }
        {Memory "Total Memories (SRAM, ROM, EFUSE, OTP,...)" Memory_REF }
        {MACRO "Total non-memory macro cells" MACRO_REF }
        {Black_Box "Total Black_Box Cell" Black_Box_REF }
        {PAD "Total PAD cells" PAD_REF }
        {MACRO "Total non-memory macro cells" MACRO_REF }
        {OTHER "Total other cells(FILL,HEAD,ANTENNA,...)" OTHER_REF }
    }
    
    # Print the total summary
    puts $fpout [string repeat $br_char $rpt_width]
    puts $fpout " Target Design : $Design"
    puts $fpout " Report Date   : [date]"
    puts $fpout [string repeat $br_char $rpt_width]
    puts $fpout " Total Summary"
    puts $fpout "                                                             count                   area"
    puts $fpout [string repeat $br_char $rpt_width]
    set line [format "  %-53s %10d %8s %13.4f %8s" "Total" $ALL_CELL_COUNT "" $ALL_CELL_AREA ""]
    puts $fpout $line
    
    foreach category $categories {
        set Class [lindex $category 0]
        if {$Class == "ALL"} {continue}
        set Label [lindex $category 1]
        set count $COUNT($Class)
        set area $AREA($Class)
    
        # Count > 0  Export
        if {$count > 0} {
            set COUNT_RATIO [expr double($count) / $ALL_CELL_COUNT * 100.0]
            set AREA_RATIO  [expr $area / $ALL_CELL_AREA * 100.0]
            print_summary_line $fpout $Label $count $COUNT_RATIO $area $AREA_RATIO
        }
    }
    
    puts $fpout [string repeat $br_char $rpt_width]
    
    
    # Reference Reports
    foreach category $categories {
        if {"[lindex $category 2]" != "" && [array get [lindex $category 2]] != ""} {
            set Class [lindex $category 0]
        } else { continue }
        unset -nocomplain TEMP_LIST
        set ref_list $CELL($Class)
        foreach item $ref_list {
            switch  $Class {
                ALL {lappend TEMP_LIST [list $item $ALL_REF($item,"count") $ALL_REF($item,"area") $ALL_REF($item,"unit_area")]}
                COMBINATIONAL {lappend TEMP_LIST [list $item $COMBINATIONAL_REF($item,"count") $COMBINATIONAL_REF($item,"area") $COMBINATIONAL_REF($item,"unit_area")]}
                Flip_Flop {lappend TEMP_LIST [list $item $Flip_Flop_REF($item,"count") $Flip_Flop_REF($item,"area") $Flip_Flop_REF($item,"unit_area")]}
                LATCH {lappend TEMP_LIST [list $item $LATCH_REF($item,"count") $LATCH_REF($item,"area") $LATCH_REF($item,"unit_area")]}
                ICG {lappend TEMP_LIST [list $item $ICG_REF($item,"count") $ICG_REF($item,"area") $ICG_REF($item,"unit_area")]}
                Black_Box {lappend TEMP_LIST [list $item $Black_Box_REF($item,"count") $Black_Box_REF($item,"area") $Black_Box_REF($item,"unit_area")]}
                Sequential_Other {lappend TEMP_LIST [list $item $Sequential_Other_REF($item,"count") $Sequential_Other_REF($item,"area") $Sequential_Other_REF($item,"unit_area")]}
                Memory {lappend TEMP_LIST [list $item $Memory_REF($item,"count") $Memory_REF($item,"area") $Memory_REF($item,"unit_area")]}
                OTHER {lappend TEMP_LIST [list $item $OTHER_REF($item,"count") $OTHER_REF($item,"area") $OTHER_REF($item,"unit_area")]}
                PAD {lappend TEMP_LIST [list $item $PAD_REF($item,"count") $PAD_REF($item,"area") $PAD_REF($item,"unit_area")]}
                MACRO {lappend TEMP_LIST [list $item $MACRO_REF($item,"count") $MACRO_REF($item,"area") $MACRO_REF($item,"unit_area")]}
            }
    
        }
    
        if {[llength $TEMP_LIST] > 0} {
            puts $fpout [string repeat $br_char $rpt_width]
            puts $fpout "  USAGE BY $Class REFERENCE"
            puts $fpout "  reference_name                                             count                   area               unit_area"
            puts $fpout [string repeat $br_char $rpt_width]
            if {$sort_by == "ref_name"} {
            	set SORTED_LIST	[lsort -index 0 -dictionary -increasing $TEMP_LIST]
            } elseif {$sort_by == "area"} {
	            set SORTED_LIST	[lsort -index 2 -real -decreasing $TEMP_LIST]
            }
    
            set type_cnt	0
            set total_cnt   0
            set total_area  0.0
            foreach item $SORTED_LIST {
                set Class [lindex $item 0]
                set count [lindex $item 1]
                set area [lindex $item 2]
                set unit_area [lindex $item 3]
                set ratio [expr double($count) / $ALL_CELL_COUNT * 100.0]
                set area_ratio [expr $area / $ALL_CELL_AREA * 100.0]
                print_detail_line $fpout $Class $count $ratio $area $area_ratio $unit_area
                incr type_cnt
                set total_cnt [expr $total_cnt + $count]
                set total_area [expr $total_area + $area]
            }
            puts $fpout ""
            puts $fpout "  >>>  $type_cnt base types are used."
            puts $fpout "  >>>  Total Count : $total_cnt , Total area : $total_area"
            puts $fpout ""
            puts $fpout ""
        }
    unset ref_list
    }
    
    close $fpout
    unsuppress_message CMD-041
    unsuppress_message UID-341

    puts "\[[date]\] > End Report Cell"
}

define_proc_attributes cell_usage_rpt \
        -info "report cell usage of the design" \
        -define_args {
            {-dk_type       "select Cell Name type" "<SEC | ARM | SNPS>" one_of_string {optional {values {SEC ARM SNPS}}}}
            {-ref_verbos    "report detail reference sory by type" "<true | false>" one_of_string {optional {values {true false}}}}
            {-sort_by 		"sort by the option (default = all)" "<ref_name | area>" one_of_string {optional {values {ref_name area}}}}
            {-output        "Name of output file" "outfile" string optional} }
help -verbose cell_usage_rpt
