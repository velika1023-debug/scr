#################################################################################################
##                                                                                             ##
## SAMSUNG FOUNDRY RESERVES THE RIGHT TO CHANGE PRODUCTS, INFORMATION AND SPECIFICATIONS       ##
## WITHOUT NOTICE.                                                                             ##
##                                                                                             ##
## No part of this publication may be reproduced, stored in a retrieval system, or transmitted ##
## in any form or by any means, electric or mechanical, by photocopying, recording,            ##
## or otherwise, without the prior written consent of Samsung. This publication is intended    ##
## for use by designated recipients only. This publication contains confidential information   ##
## (including trade secrets) of Samsung protected by Competition Law, Trade Secrets Protection ##
## Act and other related laws, and therefore may not be, in part or in whole, directly or      ##
## indirectly publicized, distributed, photocopied or used (including in a posting on the      ##
## Internet where unspecified access is possible) by any unauthorized third party. Samsung     ##
## reserves its right to take any and all measures both in equity and law available to it and  ##
## claim full damages against any party that misappropriates Samsung's trade secrets and/or    ##
## confidential information                                                                    ##
##                                                                                             ##
## All brand names, trademarks and registered trademarks belong to their respective owners.    ##
##                                                                                             ##
## 2023 Samsung Foundry                                                                        ##
##                                                                                             ##
#################################################################################################
##                                                                                             ##
## Title                : basic_reports.tcl                                                    ##
## Description          : Basic STA reports                                                    ##
## Process              : Any Samsung Foundry Process                                          ##
## Author               : Deokkeun Oh                                                          ##
## Initial Release Date : Mar. 13, 2023                                                        ##
## Last Update Date     : Mar. 13, 2023                                                        ##
## Script Version       : V1.00                                                                ##
## Usage                : This script is called from main script - run_sta.tcl                 ##
## Tool Version         : Samsung Foundry guided PrimeTime version                             ##
##                                                                                             ##
#################################################################################################

if {[info exist BACKGROUND_RPT] && $BACKGROUND_RPT} {
  set bgopt "-bg"
} else {
  set bgopt "-file"     ;# default NOP
}

;#------------------------------------------------------------------------------
;# Util procedures
;#------------------------------------------------------------------------------
set required_proc_info     [list \
                             sec_check_mem_min_period         ${UTIL_SCRIPT_DIR}/sec_check_mem_min_period.{tbc,tcl} \
                             sec_check_mem_min_pulse_width    ${UTIL_SCRIPT_DIR}/sec_check_mem_min_pulse_width.{tbc,tcl} \
                           ]

foreach {pname file_pattern} ${required_proc_info} {
  if { [info proc $pname] == "" } {
    set file_found        0
    foreach fname [glob -nocomplain $file_pattern] {
      echo "** SEC_INFO: sourcing file - $fname"
      source $fname
      set file_found 1
      break       ;# skip tcl if tbc file exists
    }
    if {! $file_found } {
      echo "** SEC_ERROR: required file not found - $file_pattern"
      echo "              maybe SEC_SNPS_TCL_UTIL_DIR OS environment variable is not set"
    }
  }
}

echo "** SEC_INFO: generating basic timing reports..."
;#------------------------------------------------------------------------------
;# Check_timing
;#------------------------------------------------------------------------------
set include_list        [list \
                          clock_crossing \
                          data_check_multiple_clock \
                          ideal_clocks \
                          latency_override \
                          ms_separation \
                          multiple_clock \
                          retain \
                        ]
if {[info exist MULTI_VDD] && $MULTI_VDD} {
  lappend include_list "signal_level"
  lappend include_list "supply_net_voltage"
}
if {[info exist CROSS_VOLTAGE_ANALYSIS] && $CROSS_VOLTAGE_ANALYSIS} {
  lappend include_list "unconnected_pg_pins"
  lappend include_list "supply_net_voltage"
  lappend include_list "operating_conditions"
}
redirect $bgopt ${RPT_DIR}/check_timing.rpt {
  check_timing -sig 4 -verbose -include $include_list
}

set rpt_opt     ""
#==============================================================================
# DT-PI_Add : Add "-voltage" option in multi voltage design
#==============================================================================
if { ([info exist MULTI_VDD] && ${MULTI_VDD}) || ([info exist CROSS_VOLTAGE_ANALYSIS] && ${CROSS_VOLTAGE_ANALYSIS}) || ([info exist is_lppi] && ${is_lppi}) } {
  set rpt_opt      "-voltage"
}
if {$timing_pocvm_enable_analysis} {
  append rpt_opt " -variation"
}

;#------------------------------------------------------------------------------
;# General timing reports
;#------------------------------------------------------------------------------
if {[info exist MINMAX] && ![regexp -nocase {auto} $MINMAX]} {
  set list_minmax     [split [string tolower $MINMAX] "_"]
} else {
  set list_minmax     {min max}]
}
set sethld(min)     hold
set sethld(max)     setup
foreach minmax $list_minmax {
  if {![info exist CROSS_VOLTAGE_ANALYSIS] || ! $CROSS_VOLTAGE_ANALYSIS} {
    ;# basic critical timing
    set cmd_line     "report_timing -delay_type $minmax -net -cap -input -tran -nosplit -sig 4 $rpt_opt \
                                    -group \[get_path_group *\]"
    redirect $bgopt ${RPT_DIR}/$sethld($minmax)_timing.critical_per_group.gba.rpt {
      eval $cmd_line
    }

    ;# violation summary
    redirect $bgopt ${RPT_DIR}/all_violators.${minmax}_delay.gba.rpt {
      report_constraint -sig 4 -all_violators -nosplit -${minmax}_delay
    }
  }
  ;# basic critical timing w/ full_clock_expanded
  redirect $bgopt ${RPT_DIR}/$sethld($minmax)_timing.critical_per_group.full_clock_expanded.gba.rpt {
    set cmd_line "\
      report_timing -delay_type $minmax -net -cap -tran -input -derate -nosplit -sig 4 $rpt_opt \
            -variation -path_type full_clock_expanded \
            -group \[get_path_group *\] "
    eval $cmd_line
  }
  ;# max 1000 timing w/ full_clock_expanded
  redirect $bgopt ${RPT_DIR}/$sethld($minmax)_timing.worst100_violated.gba.rpt {
    set cmd_line "\
      report_timing -delay_type $minmax -nworst 1 -max_paths 100 -net -cap -derate -input $rpt_opt \
            -variation -tran -nosplit -sig 4 -slack_lesser_than 0.0 \
            -group \[get_path_group *\] "
    eval $cmd_line
  }
}

if {[info exist CROSS_VOLTAGE_ANALYSIS] && $CROSS_VOLTAGE_ANALYSIS} {
  return 1
}

;#------------------------------------------------------------------------------
;# All violators
;#------------------------------------------------------------------------------
redirect $bgopt ${RPT_DIR}/all_violators.all.gba.rpt {
  report_constraint -sig 4 -all_violators -nosplit
}

;#------------------------------------------------------------------------------
;# DRCs: max-transition, max-capacitance, min-pulse, min_period
;#------------------------------------------------------------------------------
#DM_ORG redirect $bgopt ${RPT_DIR}/all_violators.max_tran.rpt {
#DM_ORG   report_constraint -sig 4 -all_violators -max_tran -nosplit
#DM_ORG }
#Step 1 : Create all_transition violation report
report_constraint -sig 4 -all_violators -max_tran -nosplit > ${RPT_DIR}/all_violators.max_tran.rpt

#Step 2 : Split all_transition violation report (CLOCK. DATA)
source ${COMMON_TCL_PT}/split_clock_data_mttv.tcl
split_clock_data_mttv ${REPORT_DIR}/all_violators.max_tran.rpt

#Step 3 : Create all_transition report Detail
if {[regexp -nocase {POST} $PRE_POST]} {
#ORG	source ${COMMON_TCL_PT}/report_mttv.tcl
source ${COMMON_TCL_PT}/report_mttv_detail.tcl
}

redirect $bgopt ${RPT_DIR}/all_violators.max_cap.rpt {
  report_constraint -sig 4 -all_violators -max_cap -nosplit
}

redirect $bgopt ${RPT_DIR}/all_violators.min_pulse.rpt {
  report_constraint -sig 4 -all_violators -min_pulse_width -nosplit
}

redirect $bgopt ${RPT_DIR}/all_violators.min_period.rpt {
  report_constraint -sig 4 -all_violators -min_period -nosplit
}

;#------------------------------------------------------------------------------
;# PrimeTime native min_period and min_pulse derate are unsupported with older
;# than 2021.06-SP5-2 releases.
;# So, check min_period and min_pulse_width of memories using custom procedures.
;#------------------------------------------------------------------------------
if {$pt_main_version < 2021.06 || ($pt_main_version == 2021.06 && $pt_sp_version_val <= 5.1)} {
    echo "** SEC_WARN: Checking min_period and min_pulse_width of memories using custom precedures since"
    echo "             PrimeTime older than 2021.06-SP5-2 release doesn't support native min-period derate"
    echo "** SEC_WARN: Default SVT margin will be used for the memories that Vth class is not distinguishible by naming convention"
    echo "             You may override min_period and min_pulse_width checks for the unclassified memories."

    set mem_cells              [get_cells -quiet -hier * -filter "is_memory_cell == true"]
    set mem_ck_pins            [get_pins -quiet -of $mem_cells -filter "is_clock_pin == true"]
    set vddpe_voltages         [lsort -u [get_attribute $mem_ck_pins power_rail_voltage_max]]

    set_app_var timing_include_uncertainty_for_pulse_checks      setup_only

    foreach v $vddpe_voltages {
      set mem_ck_pins_of_volt     [filter_collection $mem_ck_pins "power_rail_voltage_max == $v"]
      set mem_cells_of_volt       [get_cells -of $mem_ck_pins_of_volt]
      set slvt_mem_cells          [filter_collection $mem_cells_of_volt "lib_cell.full_name =~ *_slvt_* || lib_cell.full_name =~ *_slt_*"]
      set lvt_mem_cells           [filter_collection $mem_cells_of_volt "lib_cell.full_name =~ *_lvt_*"]
      set unknown_mem_cells       [remove_from_collection $mem_cells_of_volt $slvt_mem_cells]
      set unknown_mem_cells       [remove_from_collection $unknown_mem_cells $lvt_mem_cells]
      set volt_str                [regsub -- {\.} [expr $v] "P"]
      foreach vtstr {slvt lvt unknown} {
        set target_mem_cells  [set ${vtstr}_mem_cells]
        if {$target_mem_cells != "" && [sizeof $target_mem_cells] > 0} {
          if {$vtstr == "unknown"} {
            set rel_gb    [index_ocv_variable -quiet REL_GBAND ${default_vt} $CORNER_PROC $volt_str]
          } else {
            set rel_gb    [index_ocv_variable -quiet REL_GBAND ${vtstr} $CORNER_PROC $volt_str]
          }
          if {$rel_gb == ""} {
            echo "** SEC_ERROR: failed to get OCV variable - [string toupper REL_GBAND(${vtstr},${CORNER_PROC},${volt_str},*)]"
            exec touch :ERROR:ABNORMAL_EXIT; if {![info exist EXIT_ON_SCRIPT_ERROR] || $EXIT_ON_SCRIPT_ERROR} { exit -1 }
            set rel_gb     0.2
          }
          set mp_derate    [expr 1.0 + $rel_gb]

          echo "** SEC_INFO: using derate $mp_derate for min_period and min_pulse_width checking of [sizeof $target_mem_cells] [string toupper $vtstr] memory cells of ${v}V"
          set cmd_line         "sec_check_mem_min_period -derate $mp_derate -cells \$${vtstr}_mem_cells"
          echo $cmd_line
          redirect $bgopt ${RPT_DIR}/all_violators.mem_min_period.${v}.${vtstr}.rpt {
                eval $cmd_line
          }
          set cmd_line         "sec_check_mem_min_pulse_width -derate $mp_derate -cells \$${vtstr}_mem_cells"
          echo $cmd_line
          redirect $bgopt ${RPT_DIR}/all_violators.mem_min_pulse_width.${v}.${vtstr}.rpt {
                eval $cmd_line
          }
       }
    }
  }
}

;#------------------------------------------------------------------------------
;# Report QoR
;#------------------------------------------------------------------------------
redirect $bgopt ${RPT_DIR}/qor.rpt {
  report_qor
}

redirect $bgopt ${RPT_DIR}/report_global_timing.rpt {
	report_global_timing -sig 4 -pba_mode $PBA_MODE
}

#==============================================================================
# DT-PI_Add : sta_2b setting
#==============================================================================
if {[ info exists sta_2b] && ${sta_2b} } {
	if { $HIER_DESIGN != "NONE" } {
	report_global_timing -path summary -group *1b* -separate_all_groups -pba path >> ${RPT_DIR}/report_global_timing.rpt
	report_global_timing -path summary -group *2b* -separate_all_groups -pba path >> ${RPT_DIR}/report_global_timing.rpt
	report_global_timing -path summary -group * -separate_all_groups -pba path > ${RPT_DIR}/report_global_timing_group.rpt
	report_global_timing -path end -group *  -pba path > ${RPT_DIR}/report_global_timing_detail.rpt
	}
}

;#------------------------------------------------------------------------------
;# Analysis coverage
;#------------------------------------------------------------------------------
set exclude_list        [list constant_disabled mode_disabled user_disabled false_paths]
set detail_list         [list untested]

if {[info exist MINMAX]} {
  if {[string match -nocase "max" $MINMAX]} {
    set check_type_list     [list setup recovery clock_gating_setup out_setup min_period clock_separation max_skew]
  } elseif {[string match -nocase "min" $MINMAX]} {
    set check_type_list     [list hold removal clock_gating_hold out_hold clock_separation max_skew]
  } else {
    set check_type_list     [list setup recovery clock_gating_setup out_setup min_period \
                      hold removal clock_gating_hold out_hold \
                      clock_separation max_skew]
  }
} else {
  set check_type_list     [list setup recovery clock_gating_setup out_setup min_period \
                    hold removal clock_gating_hold out_hold \
                    clock_separation max_skew]
}
redirect $bgopt ${RPT_DIR}/analysis_coverage.rpt {
  report_analysis_coverage  -sig 4 -nosplit  \
                -exclude_untested ${exclude_list} \
                -status_details ${detail_list} \
                -check_type ${check_type_list}
}

;#------------------------------------------------------------------------------
;# Clock info
;#------------------------------------------------------------------------------
redirect ${RPT_DIR}/clocks.rpt {
  report_clock
}

return 1
