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
## Title                : pba_reports.tcl                                                      ##
## Description          : Advanced Path-Based timing reports                                   ##
## Process              : Any Samsung Foundry Process                                          ##
## Author               : Deokkeun Oh                                                          ##
## Initial Release Date : Mar. 13, 2023                                                        ##
## Last Update Date     : Mar. 13, 2023                                                        ##
## Script Version       : V1.00                                                                ##
## Usage                : This script is called from main script - run_sta.tcl                 ##
## Tool Version         : Samsung Foundry guided PrimeTime version                             ##
##                                                                                             ##
#################################################################################################
#2024.11.18 : iskim1001 : Add report_constraint options ( -recover_group and -removal_group ) 



if {[info exist BACKGROUND_RPT] && $BACKGROUND_RPT} {
  set bgopt "-bg"   
} else {
  set bgopt "-file"     ;# default NOP
}
set rpt_opt     ""
#==============================================================================
# DT-PI_Add : Add "-voltage" option in multi voltage design
#==============================================================================
if { ([info exist MULTI_VDD] && ${MULTI_VDD}) || ([info exist CROSS_VOLTAGE_ANALYSIS] && ${CROSS_VOLTAGE_ANALYSIS}) || ([info exist DVD_AWARE] && ${DVD_AWARE})} {
  set rpt_opt      "-voltage"
} 
if {$timing_pocvm_enable_analysis} {
  append rpt_opt " -variation"
}

if {[info exist pt_main_version] && $pt_main_version >= 2017.12} {
  echo "** SEC_INFO: 'infinity' mode will be used for exhaustive PBA in PrimeTime 2017.12 or higher version"
  set_app_var pba_exhaustive_endpoint_path_limit    infinity
} elseif {[info exist pt_main_version] && $pt_main_version >= 2015.12} {
  set PBA_EXHAUSTIVE_SEARCH_LIMIT   500
  echo "** SEC_INFO: Using PrimeTime 2015.12 or higher version. report_constraint command will be used for reporting violators in PBA mode"
  set_app_var pba_exhaustive_endpoint_path_limit    $PBA_EXHAUSTIVE_SEARCH_LIMIT
  echo "** SEC_INFO: setting 'pba_exhaustive_endpoint_path_limit' to $PBA_EXHAUSTIVE_SEARCH_LIMIT for runtime feasibility"
} else {
  echo "** SEC_ERROR: PrimeTime version is inadequate to run PBA. Use 2015.12 or higher version"
}

;#------------------------------------------------------------------------------
;# Required util procedures
;#------------------------------------------------------------------------------
set required_proc_info  [list \
                          get_elapsed_time_string   ${UTIL_SCRIPT_DIR}/util_procs.{tbc,tcl} \
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

if {[info exist MINMAX] && ![regexp -nocase {auto} $MINMAX]} {
  set list_minmax   [split [string tolower $MINMAX] "_"]
} else {
  set list_minmax   {min max}]
}

;#------------------------------------------------------------------------------
;# Report PBA vioators
;#------------------------------------------------------------------------------
unset -nocomplain minmax sethld
set sethld(min) hold
set sethld(max) setup

foreach minmax $list_minmax {
  ;# report PBA violators using PrimeTime native command
  if {$pt_main_version >= 2019.12 && $timing_enable_graph_based_refinement} {
    echo "** SEC_INFO: HyperTrace PBA is enabled."
    echo "             This feature is recommended only when there are many violators (e.g. 10% or more endpoints are violated)"
  }
  
  ;# Update ml_exhaustive mode	
  if {$pt_main_version >= 2019.12 && [info exist PBA_MODE] && [regexp -nocase {^ml} $PBA_MODE]} {
    set pba_mode  "ml_exhaustive"
  } elseif {[regexp -nocase {^exhaustive} $PBA_MODE]} {
    set pba_mode  "exhaustive"
  } else {
    set pba_mode  "path"
  }

  if { ([info exist DVD_AWARE] && ${DVD_AWARE})} {
	puts "No change pba_derate_only_mode value in DvD aware STA mode"
  } elseif {[info exist PBA_DERATE_ONLY($sethld($minmax))] && $PBA_DERATE_ONLY($sethld($minmax))} {
    set_app_var pba_derate_only_mode  1
    echo "** SEC_INFO: pba_derate_only_mode = 1 for reporting '$minmax' violators"
  } else {
    set_app_var pba_derate_only_mode  0
    echo "** SEC_INFO: pba_derate_only_mode = 0 for reporting '$minmax' violators. runtime might be infeasible for large designs"
  }
  #DM_ORG set cmd_line  "report_constraint -all_violators -${minmax}_delay -sig 4 -pba_mode ${pba_mode} -nosplit > ${RPT_DIR}/all_violators.${minmax}_delay.pba_mode_${pba_mode}.rpt"
  #request by yskong (check reset timing)
  if {[string match *max* $minmax]} {
	  	set cmd_line  "report_constraint -all_violators -${minmax}_delay -sig 4 -pba_mode ${pba_mode} -nosplit -recovery_group > ${RPT_DIR}/all_violators.${minmax}_delay.pba_mode_${pba_mode}.rpt"
  } elseif {[string match *min* $minmax]} {
		set cmd_line  "report_constraint -all_violators -${minmax}_delay -sig 4 -pba_mode ${pba_mode} -nosplit -removal_group > ${RPT_DIR}/all_violators.${minmax}_delay.pba_mode_${pba_mode}.rpt"
  } else {
		echo "Error"
  } 
  echo "** SEC_INFO: reporting PBA $sethld($minmax) violators using PrimeTime command:"
  echo "             $cmd_line"
  eval $cmd_line

  ;# PBA critical timing w/ full_clock_expanded
  redirect $bgopt ${RPT_DIR}/$sethld($minmax)_timing.critical_per_group.full_clock_expanded.pba_mode_path.rpt {
    set cmd_line "\
      report_timing -delay_type $minmax -net -cap -tran -input -derate -nosplit -sig 4 $rpt_opt \
            -path_type full_clock_expanded -pba_mode ${pba_mode} \
            -slack_lesser_than 100.0 \
            -group \[get_path_group *\] "
    eval $cmd_line
  }
}

return 1
