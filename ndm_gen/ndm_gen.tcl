###################################################################################################
# File               : ndm_gen.tcl                                                                #
# Author             : ADT-DT-PI                                                                  #
# Description        : Generate NDMs                                                              #
# Usage              :                                                                            #
# Init Release Date  : 2025.09.01                                                                 #
# Script Version     : 1.1                                                                        #
# Revision History   :                                                                            #
#         2025.09.01 - first released                                                             #
#         2025.11.26 - add foreach to prevent error                                               #
###################################################################################################
# -============================================
# Variable Setup
# -============================================
set LIB_FILE         ""
set LEF_FILE         ""
set TECH_FILE        ""


# -============================================
# Setup Option
# -============================================
set sh_continue_on_error true

##-------------------------------------------------------------------------------------------
## Handling message
##-------------------------------------------------------------------------------------------
set_message_info -id LEFR-064         -limit 20

##-------------------------------------------------------------------------------------------
## ndm_gen app options
##-------------------------------------------------------------------------------------------
set_app_options -as_user_default -name lib.physical_model.block_all                 -value false
set_app_options -name file.lef.allow_site_conflicts                                 -value true
set_app_options -name file.lef.auto_rename_conflict_sites                           -value true
set_app_options -name file.lef.non_real_cut_obs_mode                                -value true
set_app_options -name lib.logic_model.allow_ccs_timing                              -value true
set_app_options -name lib.logic_model.auto_remove_incompatible_timing_designs       -value true
set_app_options -name lib.logic_model.auto_remove_timing_only_designs               -value true
set_app_options -name lib.logic_model.require_same_opt_attrs                        -value false
set_app_options -name lib.logic_model.use_db_rail_names                             -value true
set_app_options -name lib.setting.use_tech_scale_factor                             -value true
set_app_options -name lib.workspace.allow_commit_workspace_overwrite                -value true
set_app_options -name lib.workspace.allow_missing_related_pg_pins                   -value true
set_app_options -name lib.workspace.enable_rc_support                               -value true
set_app_options -name lib.workspace.group_libs_create_slg                           -value false
set_app_options -name lib.workspace.group_libs_macro_grouping_strategy              -value single_cell_per_lib
set_app_options -name lib.workspace.group_libs_naming_strategies                    -value common_prefix
set_app_options -name lib.workspace.remove_frame_bus_properties                     -value true
set_app_options -name lib.workspace.save_design_views                               -value false
set_app_options -name lib.workspace.save_layout_views                               -value false
## Options for RC
set_app_options -name lib.logic_model.align_unspecified_pgpin_direction_with_xtools -value false
set_app_options -name lib.workspace.enable_rc_support                               -value true
set_app_options -name lib.workspace.group_libs_fix_cell_shadowing                   -value false

# -============================================
# DK Setup
# -============================================
set LIB_FILES  ""
foreach lib $LIB_FILE {
    if {[file exists $lib]} {
        puts ""
        puts "#####################################################################"
        puts "## USER lib : $lib"
        puts "#####################################################################"
        puts ""
        set i 0
        set Fin [open $lib r ]
        while { [gets $Fin line] != -1 } { 
            if { [regexp {^#} $line ] || ![regexp {\w+} $line] } { continue }
            incr i
            puts "LINK_LIB($i) : $line"
            set LIB_FILES [concat $LIB_FILES $line]
        }
        close $Fin
             
    } else {
        puts ""
        puts "#####################################################################"
        puts "Warning_ADF : File $lib is not exists"
        puts "Warning_ADF : File $lib is not exists"
        puts "Warning_ADF : File $lib is not exists"
        puts "#####################################################################"
        puts ""
    }
}

set LEF_FILES ""
foreach lef $LEF_FILE {
    if {[file exists $lef]} {
        puts ""
        puts "#####################################################################"
        puts "## USER lef : $lef"
        puts "#####################################################################"
        puts ""
        set i 0
        set Fin [open $lef r ]
        while { [gets $Fin line] != -1 } { 
            if { [regexp {^#} $line ] || ![regexp {\w+} $line] } { continue }
            incr i
            puts "LINK_LEF($i) : $line"
            set LEF_FILES [concat $LEF_FILES $line]
        } 
        close $Fin
    } else {
        puts ""
        puts "#####################################################################"
        puts "Warning_ADF : File $lef is not exists"
        puts "Warning_ADF : File $lef is not exists"
        puts "Warning_ADF : File $lef is not exists"
        puts "#####################################################################"
        puts ""
    }
}

# -============================================
# NDM Gen
# -============================================
if {![info exist SCALE_FACTOR] || $SCALE_FACTOR == ""} {
    set value [exec cat $TECH_FILE | grep lengthPrecision]
    regexp {lengthPrecision\s*=\s*(\d+)} $value match SCALE_FACTOR
    puts "Information_ADF : tech : $TECH_FILE , Scale_factor : $SCALE_FACTOR"
}


create_workspace EXPLORATION -flow exploration -scale_factor $SCALE_FACTOR -technology $TECH_FILE
foreach ll $LIB_FILES {
    if {[file exists $ll]} {
    puts "Information_ADF : Read DB - $ll"
    set lib_name [lindex [split $ll "/"] end]
    read_db  $ll -process_label $lib_name
    } else {
        puts ""
        puts "#####################################################################"
        puts "Warning_ADF : File $ll is not exists"
        puts "Warning_ADF : File $ll is not exists"
        puts "Warning_ADF : File $ll is not exists"
        puts "#####################################################################"
        puts ""
    }
}

foreach ll $LEF_FILES {
    if {[file exists $ll]} {
    puts "Information_ADF : Read LEF - $ll"
    read_lef $ll
    } else {
        puts ""
        puts "#####################################################################"
        puts "Warning_ADF : File $ll is not exists"
        puts "Warning_ADF : File $ll is not exists"
        puts "Warning_ADF : File $ll is not exists"
        puts "#####################################################################"
        puts ""
    }
}

group_libs

check_workspace
commit_workspace 
report_workspace
remove_workspace 
