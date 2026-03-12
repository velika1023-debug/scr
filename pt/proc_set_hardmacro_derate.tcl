#################################################################################################
# Title       : set_hardmacro_derate.tcl
# Author      : DT-PI
# Date        : 2024.11.06
# Version     : v0.3
# Description : Tcl for HARDMACRO derate setting
# Change Log  :
# 	v0.1 [2024-03-12] : jjh8744
#       - Initial Version Release
# 	v0.2 [2024-10-28] : iskim1001
#       - print formattin modify
# 	v0.3 [2024-11-06] : iskim1001
#       - Changed the way it is applied and added the -output option
#------------------------------------------------------------------------------------------------
# Usage :
#  For detailed explanation, see the Info section of define_proc_attribute below.
# When used alone in pt_shell>
#  	pt_shell > source ${COMMON_TCL_PROCS}/set_hardmacro_derate.tcl
#  	pt_shell > set_hardmacro_derate -name rbphys2a1s14lpp28g2l1c_afe -derate 0.9999 -gband
#
# When applying to run_sta.tcl
#	;#==============================================================================
#	;# DT-PI_Add : Hard Macro Derate setting
#	;# For detailed usage, use the command below.
#	;# pt_shell> set_hardmacro_derate -help
#	;# 	Usage : When to apply derate.       set_hardmacro_derate -ref_name rbphys2a1s14lpp28g2l1c_afe -derate 1.0
#	;# 	Usage : When applying *_guardband   set_hardmacro_derate -ref_name rbphys2a1s14lpp28g2l1c_afe -derate 1.0 -gband
#	;# 	Usage : When applying -coefficient. set_hardmacro_derate -ref_name rbphys2a1s14lpp28g2l1c_afe -derate 1.0 -coeff
#	;#
#	#==============================================================================
#	source_wrap ${COMMON_TCL_PT_PROC}/proc_set_hardmacro_derate.tcl
#	# It is already defined in proc. --> set HM_input  "${STA_SCRIPT_DIR}/hard_macro_derate_skip.list"
#	# It is already defined in proc. --> set HM_output "set_hardmacro_derate_skip.tcl"
#
#	foreach HARD_MACRO_CELL [adt_make_list_from_file $HM_input] {
#		set_hardmacro_derate -name $HARD_MACRO_CELL -derate 1.0 -gband
#	}
#	source_wrap -e -v $HM_output
##################################################################################################

set __proc_name   						"set_hardmacro_derate"
set __adt_scr_version($__proc_name) 	"0.3 - 2024.11.06"
set debug_mode 0

if {[info proc $__proc_name] == ""} {
  echo "## ADT_INFO: ADT custom procedure added - $__proc_name ($__adt_scr_version($__proc_name))"
}


;#------------------------------------------------------------------------------
;# proecdure main body
;#------------------------------------------------------------------------------
#Main Program
proc set_hardmacro_derate { args } {
	set debug_mode 0

	global USE_POCVM USE_AOCVM

	parse_proc_arguments -args $args results

	# Option Value Setting
	foreach argname [array names results] {
		switch -glob -- $argname {
			"-name"      { set name   $results($argname) }
			"-derate"    { set derate     $results($argname) }
			"-gband"     { set gband      $results($argname) }
			"-debug"     { set debug      $results($argname) }
			"-coeff"     { set coeff      $results($argname) }
			"-output"    { set output     $results($argname) }
			default    {  puts stdout "## ADT_ERROR: unknown arguments - $argname" ; return}

		}
	}

	# Output File setting
	if { [info exists results(-output)] } { set output $result(-output) } else { set output "set_hard_macro_derate.tcl" }

	# OUTPUT OPEN
	set FO [open $output "a"]

	# AOCV or POCV  guard_band option
	      if { [info exists USE_AOCVM] && $USE_AOCVM } { set ocv_opt "-aocvm_guardband"
	} elseif { [info exists USE_POCVM] && $USE_POCVM } { set ocv_opt "-pocvm_guardband"
	} else   {                                           set ocv_opt "Unknown_ocv"
	}

	# find -name
	set result     [get_lib -q *${name}* ]

	# Library Check
	    if { [sizeof_collection $result ] > 0 } { set FLAG 1
	} else {	                                  set FLAG 0
	}

	if { $FLAG == "0"  } {
		puts $FO "\n###############################################################################"
		puts $FO "# $name"
		puts $FO "# By user setting, HardMacro derate is applied as below."
		puts $FO "###############################################################################"
		puts $FO "#Warning_ADF: Not Found Library --> ${name} "
		puts $FO "#Warning_ADF: Please check the Library Name again"

	} elseif { $FLAG == "1" } {
		set result_list [get_object_name   $result]
		foreach result_obj $result_list {
			puts $FO "\n###############################################################################"
			puts $FO "# User Setting     : $name"
			puts $FO "# Library          : $result_obj"
			puts $FO "# Source_file_name : [get_attribute [get_lib $result_obj] source_file_name]"
			puts $FO "# By user setting, HardMacro derate is applied as below."
			puts $FO "###############################################################################"
			;# Derate setting Command ( Nomal derate & guard_band derate )
			if { [info exists results(-derate)] && ![info exists results(-coeff)] } {
				set cmd_line "set_timing_derate "

				      if { ![info exists results(-gband)] } { append cmd_line "$derate"
				} elseif {  [info exists results(-gband)] } { append cmd_line "$ocv_opt $derate"
				} else   {                                    append cmd_line "Unknow_option"
				}
			set CMD_1 "${cmd_line} -cell_delay -clock -early \[ get_lib_cells $result_obj/* \]" ;puts $FO "$CMD_1"
			set CMD_2 "${cmd_line} -cell_delay -clock -late  \[ get_lib_cells $result_obj/* \]" ;puts $FO "$CMD_2"
			set CMD_3 "${cmd_line} -cell_delay -data  -early \[ get_lib_cells $result_obj/* \]" ;puts $FO "$CMD_3"
			set CMD_4 "${cmd_line} -cell_delay -data  -late  \[ get_lib_cells $result_obj/* \]" ;puts $FO "$CMD_4"
			puts $FO ""

			# coefficient derate setting
			} elseif { [info exists results(-derate)] && [info exists results(-coeff)] } {
				if { $USE_AOCVM } {
					set CMD_1 "set_aocvm_coefficient $derate  \[ get_lib_cells $result_obj/* \]";puts $FO "$CMD_1"
					puts $FO ""
				} elseif { $USE_POCVM } {
					set cmd_line "set_timing_derate -pocvm_coefficient_scale_factor $derate "
					set CMD_1 "${cmd_line} -cell_delay -clock -early \[ get_lib_cells $result_obj/* \]";puts $FO "$CMD_1"
					set CMD_2 "${cmd_line} -cell_delay -clock -late  \[ get_lib_cells $result_obj/* \]";puts $FO "$CMD_2"
					set CMD_3 "${cmd_line} -cell_delay -data  -early \[ get_lib_cells $result_obj/* \]";puts $FO "$CMD_3"
					set CMD_4 "${cmd_line} -cell_delay -data  -late  \[ get_lib_cells $result_obj/* \]";puts $FO "$CMD_4"
					puts $FO ""
				} else {
					puts "Error_ADF: Unknown_coeff_ocv"
					return
				}
			}
		}
	} else {
		puts "Error_ADF: Unknown FLAG value --> $FLAG "
		puts "Error_ADF: Unknown FLAG value --> $FLAG "
		puts "Error_ADF: Unknown FLAG value --> $FLAG "
		return
	}
close $FO
}

define_proc_attributes set_hardmacro_derate \
-info "Set the derate value of the HARDMACRO.

Usage : When to apply derate.
pt_shell> set_hardmacro_derate -name rbphys2a1s14lpp28g2l1c_afe -derate 0.9999
    set_timing_derate 0.9999 -cell_delay -clock -early \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate 0.9999 -cell_delay -clock -late  \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate 0.9999 -cell_delay -data  -early \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate 0.9999 -cell_delay -data  -late  \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]

Usage : When applying -aocvm_guardband or -pocvm_guardband. (-pocvm_guardband or -aocvm_guardband options are set automatically.)
<AOCV>
pt_shell> set_hardmacro_derate -name rbphys2a1s14lpp28g2l1c_afe -derate 0.9999 -gband
    set_timing_derate -aocvm_guardband 0.9999 -cell_delay -clock -early \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate -aocvm_guardband 0.9999 -cell_delay -clock -late  \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate -aocvm_guardband 0.9999 -cell_delay -data  -early \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate -aocvm_guardband 0.9999 -cell_delay -data  -late  \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
<POCV>
pt_shell> set_hardmacro_derate -name rbphys2a1s14lpp28g2l1c_afe -derate 0.9999 -gband
    set_timing_derate -pocvm_guardband 0.9999 -cell_delay -clock -early \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate -pocvm_guardband 0.9999 -cell_delay -clock -late  \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate -pocvm_guardband 0.9999 -cell_delay -data  -early \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate -pocvm_guardband 0.9999 -cell_delay -data  -late  \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]

Usage : When applying -coefficient. (Different commands apply in AOCV and POCV.)
<AOCV>
pt_shell>  set_hardmacro_derate -name rbphys2a1s14lpp28g2l1c_afe -derate 0.9999 -coeff
    set_aocvm_coefficient 0.9999 \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
<POCV>
pt_shell>  set_hardmacro_derate -name rbphys2a1s14lpp28g2l1c_afe -derate 0.9999 -coeff
    set_timing_derate -pocvm_coefficient_scale_factor   0.9999  -cell_delay -clock -early \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate -pocvm_coefficient_scale_factor   0.9999  -cell_delay -clock -late  \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate -pocvm_coefficient_scale_factor   0.9999  -cell_delay -data  -early \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]
    set_timing_derate -pocvm_coefficient_scale_factor   0.9999  -cell_delay -data  -late  \[get_lib_cells rbphys2a1s14lpp28g2l1c_afe_sspg_0p810_0p840_125_sigRCmax/* \]

#======================================================================================================
# Use -coeff option when it is difficult to meet timing violations due to ocv margin in HARD MACRO.
# If use the -coeff option, adjust the value after discussing it with the project manager.
#======================================================================================================
" \
-define_args {
    {-name   "Set name of HARDMACROs Reference Name                                                                   " ""  string  required }
    {-derate "Set the derate value or guard_band derate value.                                                        " ""  float   required }
    {-output "Set output File name                                                                                    " ""  string  optional }
    {-gband  "Activate the -aocvm_guardband or -pocvm_guardband option depending on the OCV Type.                     " ""  boolean optional }
    {-coeff	 "Activate the -pocvm_coefficient_scale_factor or set_aocvm_coefficient option depending on the OCV Type  " ""  boolean optional }
	{-debug  "turn on debug mode                                                                                      " ""  boolean {optional hidden}}

}


set HM_input  "${STA_SCRIPT_DIR}/hard_macro_derate_skip.list"
set HM_output "set_hard_macro_derate.tcl"

puts ""
puts "##########################################################"
puts "# set_hardmacro_derate Input & Output File Setting"
puts "##########################################################"
puts "Information_ADF : HM_input  --> $HM_input"
puts "Information_ADF : HM_output --> $HM_output"
puts ""

if { [file exists $HM_output] } {
	puts "Information_ADF: Already exist file ( $HM_output )"
	puts "Information_ADF: Remove ... "
	file delete $HM_output
}
