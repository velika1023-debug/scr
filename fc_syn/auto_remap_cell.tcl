# ==============================================================
#  Script: auto_remap_cell.tcl
#  Purpose: Auto remap S6T lib cells to M7P5T equivalents
#            and save missing/failed cells to external files
#  Tool: Synopsys Fusion Compiler (fc_shell)
#  Author: DT jmpark
#  Date: 2025-11-13
# ==============================================================

set debug_mode 0 ;# 0=normal (recommended), 1=verbose debug

# --------------------------------------------------------------
# 1. Define mapping between S6T and M7P5T libraries
# --------------------------------------------------------------
set lib_pairs {
    {ln05lpe_sc_s6t_flk_lvt_c54l08_sspg_nominal_max_0p6750v_m40c ln05lpe_sc_m7p5t_flk_lvt_c60l08_sspg_nominal_max_0p6750v_m40c}
    {ln05lpe_sc_s6t_flkp_rvt_c54l08_sspg_nominal_max_0p6750v_m40c ln05lpe_sc_m7p5t_flkp_rvt_c60l08_sspg_nominal_max_0p6750v_m40c}
}

# --------------------------------------------------------------
# 2. Define cell name replacement patterns
# --------------------------------------------------------------
set cell_name_map {
    _S6TL_ _M7P5TL_
    _S6TR_ _M7P5TR_
    _S6TSL_ _M7P5TSL_
}

# --------------------------------------------------------------
# 3. Main loop for each library pair
# --------------------------------------------------------------
foreach pair $lib_pairs {
    lassign $pair old_lib new_lib
    puts "\n=== Processing: $old_lib -> $new_lib ==="

    # Extract LLP pattern
    regexp {(c[0-9]+[el][0-9]+)} $old_lib old_match
    regexp {(c[0-9]+[el][0-9]+)} $new_lib new_match
    set old_llp $old_match
    set new_llp $new_match
    set upper_old_llp [string toupper $old_llp]
    set upper_new_llp [string toupper $new_llp]

    puts "LLP mapping detected: $old_llp -> $new_llp"

    # Get all lib cells from source library
    set old_cell_paths [get_object_name [get_lib_cells -quiet ${old_lib}/*]]

    # Counters
    set cnt_total 0
    set cnt_mapped 0
    set cnt_skipped 0
    set cnt_missing 0
    set cnt_failed 0

    # Storage lists
    set failed_cells {}
    set missing_cells {}

    # --------------------------------------------------------------
    # Create manual set_reference output script
    # --------------------------------------------------------------
    set short_lib [file tail $old_lib]
    set manual_file "manual_set_reference_${short_lib}.tcl"
    set fh_manual [open $manual_file "w"]
    puts $fh_manual "# Manual set_reference commands for failures"
    puts $fh_manual "# Source: $old_lib"
    puts $fh_manual "# Target: $new_lib"
    puts $fh_manual "# Generated: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]\n"

    # --------------------------------------------------------------
    # Iterate over each cell in the source library
    # --------------------------------------------------------------
    foreach old_path $old_cell_paths {
        incr cnt_total
        set old [file tail $old_path]
        set old_cell_path $old_lib/$old

        # Cell name mapping (S6T ? M7P5T and LLP)
        set new_cell [string map $cell_name_map $old]
        if {$upper_old_llp ne "" && $upper_new_llp ne ""} {
            set new_cell [string map [list $upper_old_llp $upper_new_llp] $new_cell]
        }
        set new_cell_path $new_lib/$new_cell

        # Check new lib cell existence
        set lib_exist [expr {[sizeof_collection [get_lib_cells -quiet $new_cell_path]] == 1}]

        # Find instances of the original cell in design
        set insts [get_cells -hierarchical -quiet -filter "ref_name =~ $old"]
        set inst_count [sizeof_collection $insts]

        # ----------------------------------------------------------
        # CASE 1: New cell exists and instances exist ? try remap
        # ----------------------------------------------------------
        if {$lib_exist && $inst_count >= 1} {

            if {[catch {
                set_reference -to_block $new_cell_path \
                              -of_object [get_lib_cells $old_cell_path] \
                              -pin_rebind safe
            } errMsg]} {

                # FAIL: count increases by instance count
                set cnt_failed [expr {$cnt_failed + $inst_count}]

                set inst_names [lrange [get_object_name $insts] 0 19]
                lappend failed_cells [list $old $new_cell "set_reference_error" $inst_count $inst_names $errMsg]

                puts "\[FAILED\]"
                puts "  OLD CELL : $old"
                puts "  NEW CELL : $new_cell"
                puts "  INST CNT : $inst_count"
                puts "  ERROR    : $errMsg"

                # manual recovery script output
                puts $fh_manual "## FAIL: $old -> $new_cell"
                puts $fh_manual "set_reference -to_block $new_cell_path -of_object \[get_lib_cells $old_cell_path\] -pin_rebind safe\n"

            } else {

                # Successfully mapped
                set cnt_mapped [expr {$cnt_mapped + $inst_count}]
                puts "\[MAPPED\]"
                puts "  OLD CELL : $old"
                puts "  NEW CELL : $new_cell"
                puts "  INST CNT : $inst_count"
            }

        # ----------------------------------------------------------
        # CASE 2: New lib cell missing but inst exists ? hard failure
        # ----------------------------------------------------------
        } elseif {!$lib_exist && $inst_count >= 1} {

            # FAIL: add inst_count
            set cnt_failed [expr {$cnt_failed + $inst_count}]

            set inst_names [lrange [get_object_name $insts] 0 19]
            set errMsg "Target lib cell not found: $new_cell_path"

            lappend failed_cells [list $old $new_cell "missing_target_cell" $inst_count $inst_names $errMsg]

            puts "\[FAILED\]"
            puts "  OLD CELL : $old"
            puts "  NEW CELL : $new_cell"
            puts "  INST CNT : $inst_count"
            puts "  ERROR    : $errMsg"

            # manual recovery output
            puts $fh_manual "## FAIL (Missing target): $old -> $new_cell"
            puts $fh_manual "# Target cell does not exist: $new_cell_path"
            puts $fh_manual "set_reference -to_block $new_cell_path -of_object \[get_lib_cells $old_cell_path\] -pin_rebind safe\n"

        # ----------------------------------------------------------
        # CASE 3: New cell missing and no instances ? simply missing
        # ----------------------------------------------------------
        } elseif {!$lib_exist && $inst_count == 0} {
            incr cnt_missing
            lappend missing_cells $old

        # ----------------------------------------------------------
        # CASE 4: New cell exists but no instances ? skipped
        # ----------------------------------------------------------
        } else {
            incr cnt_skipped
        }
    }

    # Close manual reference script
    close $fh_manual
    puts "\n>>> Manual set_reference TCL generated: $manual_file"

    # --------------------------------------------------------------
    # Save missing cell list
    # --------------------------------------------------------------
    if {$cnt_missing > 0} {
        set short_lib [file tail $old_lib]
        set filename "missing_cells_${short_lib}.txt"
        set fh [open $filename "w"]
        puts $fh "# Missing cells: no matching cell exists in target library"
        puts $fh "# Source: $old_lib"
        puts $fh "# Target: $new_lib\n"
        foreach cell $missing_cells { puts $fh $cell }
        close $fh
        puts ">>> Missing cell list saved to: $filename"
    }

    # --------------------------------------------------------------
    # Save failed cell list
    # --------------------------------------------------------------
    if {$cnt_failed > 0} {
        set short_lib [file tail $old_lib]
        set fail_file "failed_cells_${short_lib}.txt"
        set fh [open $fail_file "w"]
        puts $fh "# Failed cell remap list"
        puts $fh "# Source: $old_lib"
        puts $fh "# Target: $new_lib\n"
        foreach f $failed_cells {
            lassign $f old new fail_type inst_cnt inst_names errMsg
            puts $fh "OLD:$old | NEW:$new | TYPE:$fail_type | INST_CNT:$inst_cnt | INSTS:[join $inst_names , ] | ERROR:$errMsg"
        }
        close $fh
        puts ">>> Failed cell list saved to: $fail_file"
    }

    # --------------------------------------------------------------
    # Summary
    # --------------------------------------------------------------
    puts "\n--- Summary for $old_lib ---"
    puts [format "  Total cells : %-5d   (All cells defined in source library)" $cnt_total]
    puts [format "  Remapped    : %-5d   (Successfully replaced with $new_lib equivalents)" $cnt_mapped]
    puts [format "  Skipped     : %-5d   (No instances in design to change)" $cnt_skipped]
    puts [format "  Missing     : %-5d   (No matching cell in target $new_lib library)" $cnt_missing]
    puts [format "  Failed      : %-5d   (instance-level count)" $cnt_failed]
}
