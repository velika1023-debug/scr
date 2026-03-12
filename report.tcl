###################################################################################################
# File               : report.tcl                                                                 #
# Author             : ADT-DT (jblee)                                                             #
# Description        : generate output and report design                                          #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################
###########################################################################################
## Pre configuration
###########################################################################################

if {$GEN_INIT_STAGE_RPT == "false" && ${DESIGN_STAGE} == "to_initial_opto" && ![info exists Final_stage]} { 
    puts "Information_ADF : Skip Report for Initial Stage"    
    return 
}

if {![file isdirectory ${REPORT_DIR}/${DESIGN_STAGE}]} {
    file mkdir ${REPORT_DIR}/${DESIGN_STAGE}
}

## update_timing
update_timing -full

## To report power, turn on leakagae/dynamic temporarily, although scenario status was false.
set f_leakage_scn [get_object_name [get_scenarios -quiet -f "active == true && leakage_power == false"]]
set f_dynamic_scn [get_object_name [get_scenarios -quiet -f "active == true && dynamic_power == false"]]
if { [llength $f_leakage_scn] } {
    set_scenario_status [get_scenarios $f_leakage_scn] -leakage_power true
}
if { [llength $f_dynamic_scn] } {
    set_scenario_status [get_scenarios $f_dynamic_scn] -dynamic_power true
}

if { [sizeof [get_core_area]] != 0 } {
    ## util configuration
    set CBD_x [format "%g" [lindex [lindex [get_attribute [current_design ] boundary] 2] 0]]
    set CBD_y [format "%g" [lindex [lindex [get_attribute [current_design ] boundary] 2] 1]]
    create_utilization_configuration -capacity boundary -force util_config_1
    create_utilization_configuration -capacity core_area -force util_config_2 -exclude { hard_macros macro_keepouts soft_macros io_cells hard_blockages }
}

###########################################################################################
## Report
###########################################################################################
puts "Information_ADF: reporting !!"

## app_options
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.app_options.rpt               { report_app_options -non_default }

## qor
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.qor_sum.rpt                   { report_qor -summary }
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.qor.rpt                       { report_qor -scenario [all_scenarios] }
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.qor_snap.rpt                  { proc_qor }

## constraint
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.constraints.setup.rpt         { report_constraints -max_delay -scenario [all_scenarios] -all_violators -nosplit }
if { [sizeof [get_scenarios -filter "active&&hold"]] != 0 } {
    redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.constraints.hold.rpt      { report_constraints -min_delay -scenario [all_scenarios] -all_violators -nosplit }
}
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.constraints.mttv.rpt          { report_constraints -max_tran -max_cap -scenario [all_scenarios] -all_violators -nosplit }

## global timing
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.global_timing.rpt             { report_global_timing -pba_mode [get_app_option_value -name time.pba_optimization_mode] -nosplit }

## max timing
if { [get_app_option_value -name time.pocvm_enable_analysis] } {
    redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.max.timing.rpt            { report_timing -del max -sce [all_scenarios] -tra -cap -inp -net -phy -att -nos -der \
                                                                                                        -max_paths 10 -path_type full_clock_ex -report_by group }
} else {
    redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.max.timing.rpt            { report_timing -del max -sce [all_scenarios] -tra -cap -inp -net -phy -att -nos \
                                                                                                        -max_paths 10 -path_type full_clock_ex -report_by group }
}

## min timing
if { $USE_CCD } {
    if { [get_app_option_value -name time.pocvm_enable_analysis] } {
        redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.min.timing.rpt        { report_timing -del min -sce [all_scenarios] -tra -cap -inp -net -phy -att -nos -der \
                                                                                                        -max_paths 10 -path_type full_clock_ex -report_by group }
    } else {
        redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.min.timing.rpt        { report_timing -del min -sce [all_scenarios] -tra -cap -inp -net -phy -att -nos \
                                                                                                        -max_paths 10 -path_type full_clock_ex -report_by group }
    }
}

## congestion
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.congestion.rpt                { report_congestion -layers [get_layers -filter "layer_type==interconnect"] -nosplit }

## multibit
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.mbit.rpt                      { report_multibit }

## clock gating
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.clock_gating.rpt              { report_clock_gating -gated -ungated -multi_stage }

## register transform
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.transformed_register.rpt      { report_transformed_register }

## vth use
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.vth_ratio.rpt                 { report_threshold_voltage_group -nosplit [get_cells -hierarchical -filter \
                                                                                                        "is_physical_only!=true && design_type==lib_cell"] }

## power
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.power.rpt                     { report_power -verbose -scenarios [all_scenarios] -nosplit }

## physical
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.physical.rpt                  { report_design -all -nosplit }

## utilization
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.utilization.rpt               { puts "###### Total UTIL #######" }
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.utilization.rpt -append       { report_utilization -config util_config_1 }
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.utilization.rpt -append       { puts "\n###### Effective UTIL #######" }
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.utilization.rpt -append       { report_utilization -config util_config_2 }
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.utilization.rpt -append       { puts "\n###### CHIP SIZE #######" }
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.utilization.rpt -append       { puts "${CBD_x} X ${CBD_y}" }

## cells added during optimization
redirect -tee ${REPORT_DIR}/${DESIGN_STAGE}/${TOP_DESIGN}.${DESIGN_STAGE}.count_buf_inv.rpt             { count_buf_inv -dont_suppress_empty -extra_stats }


if {[info exists Final_stage]} {
    ## app_var
    redirect -tee ${REPORT_DIR}/${TOP_DESIGN}.app_var.rpt                   { printvar -app }
    
    ## check design 
    redirect -tee ${REPORT_DIR}/${TOP_DESIGN}.check_design.rpt              { check_design -checks pre_clock_tree_stage }
    
    ## collect 'ADF' message
    redirect -tee ${REPORT_DIR}/${TOP_DESIGN}.adf_info.rpt                  { sh grep -E {^[^[:space:]]+_ADF} ${LOG_DIR}/${TOP_DESIGN}.syn.log }
    
    ## check multi-voltage env
    redirect -tee ${REPORT_DIR}/${TOP_DESIGN}.check_mv_design.rpt           { check_mv_design }
    
    ## check unmapped cell
    redirect -tee ${REPORT_DIR}/${TOP_DESIGN}.unmapped.rpt                  { query_objects [get_cells -hierarchical -filter "is_unmapped==true"] }
    
    ## check timing 
    redirect -tee ${REPORT_DIR}/${TOP_DESIGN}.check_timing.rpt              { check_timing }
    
    ## legality
    redirect -tee ${REPORT_DIR}/${TOP_DESIGN}.check_legality.rpt            { check_legality -verbose }

    ## Search for latch cells
    set ALL_LATCH_CELL [all_registers -level_sensitive]
    echo "# Latch list"                                                     > ${REPORT_DIR}/${TOP_DESIGN}.include_lockup_latches.rpt
    echo "# Latch list (Excluded cells with names containing \"LOCKUP\")"   > ${REPORT_DIR}/${TOP_DESIGN}.latches.rpt
    
    if { [sizeof_collection ${ALL_LATCH_CELL}] > 0 } {
        foreach_in_collection cell $ALL_LATCH_CELL {
            set fname [get_attr $cell full_name]
            echo "$fname" >> ${REPORT_DIR}/${TOP_DESIGN}.include_lockup_latches.rpt
    
            set endli [lindex [split $fname "/"] end]
            if { ![string match -nocase "*lockup*" $endli] } {
                echo "$fname" >> ${REPORT_DIR}/${TOP_DESIGN}.latches.rpt
            }
        }
    }
    unset ALL_LATCH_CELL
    
    ## clock report 
    redirect -tee ${REPORT_DIR}/${TOP_DESIGN}.clocks.rpt                    {
        set HFMHZ [format "%.2f" [expr 1000.0 / [lindex [lsort -unique -increasing [get_attr [get_clocks -filter "defined(sources)"] period]] 0]]]
        echo ""
        echo "################################################"
        echo "# High Frequency Clock : ${HFMHZ}MHz"
        echo "################################################"
        echo ""
        echo ""
        report_clocks -skew -nos
    }

    ## report snapshot
    source -echo -verbose ${COMMON_FC_SYN}/report_snapshot.tcl
}


## Roll back scenario status
if { [llength $f_leakage_scn] } {
    set_scenario_status [get_scenarios $f_leakage_scn] -leakage_power false
}
if { [llength $f_dynamic_scn] } {
    set_scenario_status [get_scenarios $f_dynamic_scn] -dynamic_power false
}

#################################################################################
# link Final report
#################################################################################
if {[info exists Final_stage] && ${Final_stage} == 1} {
    puts "\[Final Stage\] ${DESIGN_STAGE}"
    cd ${REPORT_DIR}
    foreach rpt_list [glob -nocomplain ${DESIGN_STAGE}/*] {
        set rpt_name [file tail $rpt_list]
        set new_name [regsub -all "${DESIGN_STAGE}" $rpt_name "final"]
        exec ln -sf ${DESIGN_STAGE}/$rpt_name $new_name
    }
    cd ${RUN_DIR}
}
