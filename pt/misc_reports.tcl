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
## Title                : reports.tcl                                                          ##
## Description          : Standard STA reports                                                 ##
## Process              : LN03GAP 					                       ##
## Author               : Deokkeun Oh                                                          ##
## Initial Release Date : Mar. 13, 2023                                                        ##
## Last Update Date     : Mar. 13, 2023                                                        ##
## Script Version       : V1.00                                                                ##
## Usage                : This script is called from main script - run_sta.tcl                 ##
## Tool Version         : Samsung Foundry guided PrimeTime version                             ##
##                                                                                             ##
#################################################################################################

#==============================================================================
# DT-PI_Add : Making reports to check power information.
#==============================================================================
if { ([info exist MULTI_VDD] && ${MULTI_VDD}) || ([info exist CROSS_VOLTAGE_ANALYSIS] && ${CROSS_VOLTAGE_ANALYSIS}) } {
	report_supply_net  > ${RPT_DIR}/report_supply_net.rpt
	report_lib_groups -scaling -show {voltage} -nos > ${RPT_DIR}/report_lib_groups.rpt
	if {[info exist CROSS_VOLTAGE_ANALYSIS] && $CROSS_VOLTAGE_ANALYSIS} {
		return 1
	}
}

if {![info exist RPT_CLOCK_TIMING]} {
  set RPT_CLOCK_TIMING		0	;# default
}
if {![info exist RPT_CELL_USAGE]} {
  set RPT_CELL_USAGE 		0
}
if {![info exist RPT_CLOCK_CELL_USAGE]} {
  set RPT_CLOCK_CELL_USAGE 	0
}

;#------------------------------------------------------------------------------
;# Required util procedures
;#------------------------------------------------------------------------------
set required_proc_info 	[list \
			  sec_report_cell_usage 		${UTIL_SCRIPT_DIR}/sec_report_cell_usage.{tbc,tcl} \
			  sec_report_clock_tree_cell_usage 	${UTIL_SCRIPT_DIR}/sec_report_clock_tree_cell_usage.{tbc,tcl} \
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
      echo "** SEC_ERROR: required file not found - $pattern"
      echo "              maybe SEC_SNPS_TCL_UTIL_DIR OS environment variable is not set"
    }
  }
}

;#------------------------------------------------------------------------------
;# Clock timing
;#------------------------------------------------------------------------------
if {$RPT_CLOCK_TIMING} {
  set ALL_CLOCKS [filter_collection [all_clocks] defined(sources)]
  if {![file exist ${RPT_DIR}/CLOCK_TIMING]} {
    file mkdir ${RPT_DIR}/CLOCK_TIMING
  }
  foreach_in_collection clk $ALL_CLOCKS {
    if {[get_attribute $clk propagated_clock] == "false" } {
      echo "** SEC_WARN: clock is not propagated mode - [get_object_name $clk]"
      continue
    }
    set clk_name [get_object_name $clk]
    foreach rpt_type [list summary latency skew] {
      if {$rpt_type == "summary"} {
		while {[string match -nocase "*/*" $clk_name]} {
			set clk_name_org $clk_name
			set clk_name [regsub -nocase -- "/" $clk_name "-"]
			 echo "** SEC_INFO: $clk_name_org has been changed into $clk_name for generating clock timing report"
		}
		redirect ${RPT_DIR}/CLOCK_TIMING/${clk_name}.${rpt_type}.rpt {
	  		report_clock_timing -type ${rpt_type} -clock $clk
		}
      } else {
		redirect ${RPT_DIR}/CLOCK_TIMING/${clk_name}.${rpt_type}.rpt {
	  		report_clock_timing -verbose -type ${rpt_type} -clock $clk
		}
      }
    }
  }
}

;#------------------------------------------------------------------------------
;# Cell Usage
;#------------------------------------------------------------------------------
if {$RPT_CELL_USAGE} {
  echo "** SEC_INFO: reporting overall cell usage"
  suppress_message LNK-041
  sec_report_cell_usage \
	  -verbose \
	  -output ${RPT_DIR}/cell_usage.rpt
}

;#------------------------------------------------------------------------------
;# Clock Tree Cell Usage
;#------------------------------------------------------------------------------
if {$RPT_CLOCK_CELL_USAGE} {
  echo "** SEC_INFO: reporting clock tree cell usage"
  suppress_message LNK-041
  sec_report_clock_tree_cell_usage \
  	  -use_pt_clock_tree \
	  -verbose \
	  -output ${RPT_DIR}/clock_tree_info
}

#==============================================================================
# DT-PI_Add : Report Macro, PAD, IP for ADF
#==============================================================================
if {[file exist ${COMMON_TCL_PT}/report_cell_usage_sophia.tcl]} {
    source_wrap ${COMMON_TCL_PT}/report_cell_usage_sophia.tcl
}

#==============================================================================
# DT-PI_Add : Making report to check lppi setting
#==============================================================================
source_wrap ${COMMON_TCL_PT}/lppi_check.tcl

#===============================================================================
# DT-PI (Essential) : Script Add
#-------------------------------------------------------------------------------
set DLY_CHAIN_VIO_CNT "8"
source_wrap ${COMMON_TCL_PT_PROC}/proc_find_dly_cell_chain.tcl
find_dly_cell_chain -length_greater_than ${DLY_CHAIN_VIO_CNT} > ${RPT_DIR}/long_delay_chain.rpt

#==============================================================================
# DT-PI_Add : Making clock tree report
#==============================================================================
source_wrap ${COMMON_TCL_PT_PROC}/proc_make_clk_tree_rpt.tcl
#make_clk_tree_rpt -output ... ;# If you want to use the procedure, please add it to TOOLS/pt_sta/design_scripts/others_report.tcl.
#
#
#==============================================================================
# DT-PI_Add : Memory case check                                      by N1B0
#==============================================================================
source_wrap ${COMMON_TCL_PT}/memory_case_check.tcl

#==============================================================================
# DT-PI_Add : Dashboard report generation                            for ADF
#==============================================================================
report_global_timing -path_type end -pba_mode $PBA_MODE -format csv -output ${REPORT_DIR}/report_global_timing.dashboard_ADF.csv

#==============================================================================
# DT-PI_Add : dont_touch, dont_use, size_only
#==============================================================================
if {[file exist ${COMMON_TCL_PT}/common_con.tcl]} {
    source_wrap ${COMMON_TCL_PT}/common_con.tcl
}
