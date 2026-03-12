###############################################################################
# File Name     : proc_gen_subhier_pin_inout_delay.tcl
# Author        : DT-PI
# Creation Date : 2024-06-13
# Last Modified : 2024-06-24
# Version       : v0.3
# Location      : ${COMMON_TCL_PT}/proc_gen_subhier_pin_inout_delay.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	This file is an example file. This header is used to track the version and
# 	change history of the file.
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-06-13] : iskim1001
#       - Initial Version Release
# 	v0.2 [2024-06-20] : iskim1001
# 		- Add -exclude_pattern option
# 	v0.3 [2024-06-24] : iskim1001
# 		- Add logic to automatically identify MIM (is_mim)
#-------------------------------------------------------------------------------
# Useage        :
# 	pt_shell > source gen_subhier_pin_inout_delay.tcl
# 	pt_shell > gen_subhier_pin_inout_delay -HierDesign CPU_PON_TOP
# 	pt_shell > gen_subhier_pin_inout_delay -HierDesign CPU_PON_TOP -exclude_pattern " *jtag*  RESETB"
# 	pt_shell > gen_subhier_pin_inout_delay -HierDesign TSABI_ca53_cpu_1_1_1_1_3_3
# 	pt_shell > gen_subhier_pin_inout_delay -HierDesign TSABI_ca53_cpu_1_1_1_1_3_3  -HierInst g_ca53_cpu_0__u_ca53_cpu -input_scale 0.5 -output_scale 0.3
# 		or
# 	pt_shell > \
#		foreach HierDesign $HIER_DESIGN {
#			puts $HierDesign
#			set HierDesign [set ${HierDesign}(NAME)]
#			set HierInst [set ${HierDesign}(INST_NAME)]
#			gen_subhier_pin_inout_delay -HierDesign $HierDesign -HierInst $HierInst
#		}
#################################################################################

set scr_version     "v0.3 (2024.06.24)"
proc gen_subhier_pin_inout_delay {args} {
	parse_proc_arguments -args $args p_args
	global DESIGN
	global scr_version

	# Default Value setting
	set Definput_scale   0.7 ;# 70%
	set Defoutput_scale  0.7 ;# 70%
	set HierPinMet       0
	set HierPinVio       0
	set HierPinNoPath    0
	set HierPinInfinity  0
	set WriteCMDArray    {}
	set HierClkList      {}
	set HierPinList      {}

	# Option Setting
	if {[info exists p_args(-debug)           ] } { set debug 1                                  } else { set debug    0                    }
	if {[info exists p_args(-input_scale)     ] } { set input_scale    $p_args(-input_scale)     } else { set input_scale  $Definput_scale  }
	if {[info exists p_args(-output_scale)    ] } { set output_scale   $p_args(-output_scale)    } else { set output_scale $Defoutput_scale }
	if {[info exists p_args(-HierDesign)      ] } { set HierDesign     $p_args(-HierDesign)      }
	if {[info exists p_args(-HierInst)        ] } { set HierInst       $p_args(-HierInst)        }
	if {[info exists p_args(-exclude_pattern) ] } { set ExcludePattern $p_args(-exclude_pattern); set EXCLUDE_FLAG "1" } else { set ExcludePattern ""; set EXCLUDE_FLAG "0" }


	# File Setting
	set OUTPUT_FILE       "hier_pin_const_${HierDesign}.tcl"
	set OUTPUT_FILE_DEBUG "hier_pin_const_${HierDesign}.tcl__debug"

	# Main Program
	puts "$HierDesign in progress ...."
	set FOUT  [open ${OUTPUT_FILE} w]; 	if { $debug } { set FOUT_DBG [open ${OUTPUT_FILE_DEBUG} w ] }

	# HierInst Information
	set HierInst       [get_object_name [sort_collection -dict [get_cells -h -f "ref_name == $HierDesign"] {full_name}]]
	set HierInstNum    [llength $HierInst]
	set HierInstIndex0 [lindex $HierInst 0 ]

	# is_mim variable on/off according to HierInstNum
	if { $HierInstNum  > 1 } {
		if {[info exists p_args(-HierInst)] } {
			puts "Information_ADF: HierDesign is a MIM, but because the -HierInst option is set, the set Instance is written."
			puts "Information_ADF: The is_mim variable is set to 0."
			set is_mim 0
			set HierInst $p_args(-HierInst)
		} else {
			puts "Information_ADF: The is_mim variable is set to 1."
			set is_mim 1
		}
	} else {
			puts "Information_ADF: The is_mim variable is set to 1."
		set is_mim 0
	}

	if { $is_mim } {
		#Create a HierPortList  : g_ca53_cpu_0__u_ca53_cpu/LSBYPOUT -> LSBYPOUT
		puts "Information_ADF: Slack values are collected for MIM instances (HierPin), and instances are written based on WNS."
		set HierPortList ""
		foreach HierPin [get_obj [get_pins -of $HierInstIndex0] ] {
			lappend HierPortList [regsub "$HierInstIndex0/" $HierPin "" ]
		}

		#Categorize HierPinSlk MIM START
		foreach HierPort $HierPortList {
			set NumInf    0; set NumBlank  0; set NumSlk    0
			foreach Inst $HierInst {
				set HierPin    [get_pins $Inst/$HierPort ]
				set HierPinSlk [get_attribute [get_timing_path -th $HierPin ] slack ]
				if { $HierPinSlk == "INFINITY" } {
					incr NumInf
					set  CheckPin    $HierPin
					set  CheckPinSlk $HierPinSlk
				} elseif { $HierPinSlk == "" } {
					incr NumBlank
					set  CheckPin    $HierPin
					set  CheckPinSlk "BLANK"
				} else {
					incr NumSlk
					if { ![info exists CheckPin   ] } { set CheckPin    $HierPin    }
					if { ![info exists CheckPinSlk] } { set CheckPinSlk $HierPinSlk }
					if { $HierPinSlk < $CheckPinSlk } {
						set CheckPin    $HierPin
						set CheckPinSlk $HierPinSlk
					}
				}
			}
			set Sum [expr $NumInf + $NumBlank + $NumSlk]
			append_to_collection HierPinList $CheckPin
			if { $debug } { puts $FOUT_DBG "#DEBUG: $HierPort : $HierInstNum/$Sum == NumInf($NumInf) + NumBlank($NumBlank) + NumSlk($NumSlk) : ($CheckPinSlk) [get_object_name $CheckPin]" }
			unset CheckPinSlk ; unset CheckPin
		}

	} else {
		set HierPinList    [get_pins -of $HierInst ]
	}
	set HierPinListNum [sizeof_collection $HierPinList]

	#Processing related to the -exclude_pattern option
	if { [info exists EXCLUDE_FLAG] && $EXCLUDE_FLAG } {
		puts "Information_ADF: Apply exclude pattern:"
		puts "    $ExcludePattern"
		if { [llength $ExcludePattern ] > 0 } {
			foreach pat $ExcludePattern {
				append_to_collection  ExcludePatternPinList [filter_collection $HierPinList "full_name =~ */${pat}"]
			}
			set HierPinList [remove_from_collection $HierPinList $ExcludePatternPinList]
			set ExcludePatternPinListNum [sizeof_collection $ExcludePatternPinList]
		}
	} else {
		puts "Information_ADF: The exclude pattern is not applied."
		set ExcludePattern           "none"
		set ExcludePatternPinListNum "0"
	}

	# HierPinList = HierPinList - ExcludePatternPinList
	set i 1
	foreach_in_collection HierPin $HierPinList {
		set HierPinSlack [get_attribute [get_timing_path -th $HierPin ] slack]
		if { $debug } { puts $FOUT_DBG "#DEBUG: $i, $HierPinSlack, [get_object_name $HierPin]"		}

		# Part to check for 4 cases of $HierPinSlack
		if { $HierPinSlack == "INFINITY" } {
			incr HierPinInfinity
    	} elseif { $HierPinSlack > 0     } {
			incr HierPinMet
		} elseif { $HierPinSlack == ""   } {
			incr HierPinNoPath
		} elseif { $HierPinSlack < 0     } {
			incr HierPinVio
			set HierPinName        [get_attribute $HierPin full_name]
			set HierPinDir         [get_attribute $HierPin direction]

			# MIM Check
			if { $is_mim } {
				foreach inst $HierInst {
					if { [string match "$inst/*" $HierPinName] } {
						set HierPortName  [regsub "$inst/" $HierPinName ""]
					}
				}
			} else {
				set HierPortName       [regsub "$HierInst/" $HierPinName ""]
			}

			#Find Fast Clock
			set HierPinEpClkList   [get_object_name [get_attribute [get_timing_paths -th $HierPin ] endpoint_clock]]
			foreach HierPinClkName $HierPinEpClkList {
				set HierPinClkPeriod [get_attribute [get_clocks $HierPinClkName ] period]
				if { ! [info exists HierPinFastClkName  ] } { set HierPinFastClkName   $HierPinClkName   }
				if { ! [info exists HierPinFastClkPeriod] } { set HierPinFastClkPeriod $HierPinClkPeriod }

				if { $HierPinClkPeriod < $HierPinFastClkPeriod } {
 					set HierPinFastClkName   $HierPinClkName
 					set HierPinFastClkPeriod $HierPinClkPeriod
				}
			}
			set HierPinEpClk       $HierPinFastClkName   ; unset  HierPinFastClkName
			set HierPinEpClkPeriod $HierPinFastClkPeriod ; unset  HierPinFastClkPeriod

			# $HierPinDir check section
			if { $HierPinDir == "in" } {
				set Scale $input_scale
				set cmd "set_input_delay  "
			} elseif { $HierPinDir == "out" } {
				set Scale $output_scale
				set cmd "set_output_delay "
			} else {
				set Scale 0
				set cmd "Error_ADF: The Value of variable HierPinDir is $HierPinDir "
			}

			if { $debug } {
				set HierPinSp   [get_object_name [get_attribute [get_timing_paths -th $HierPin ] startpoint]]
				set HierPinEp   [get_object_name [get_attribute [get_timing_paths -th $HierPin ] endpoint  ]]
				puts $FOUT_DBG "#DEBUG: $i, $HierPinSlack, $HierPinName "
				puts $FOUT_DBG "#report_timing -nosp -from $HierPinSp -th $HierPinName -to $HierPinEp -include_hierarchical_pins"
				puts $FOUT_DBG ""
			}

			set ClkPeriodScale  [format %.4f [expr $HierPinEpClkPeriod * $Scale]]
			set WriteCMD "$cmd $ClkPeriodScale -clock $HierPinEpClk \[get_ports $HierPortName\] "
			lappend WriteCMDArray $WriteCMD
		}
		incr i
	}


	# Create Report
	puts $FOUT "#*********************************************"
	puts $FOUT "# Report           : gen_subhier_pin_inout_delay"
	puts $FOUT "# Design           : ${DESIGN}           "
	puts $FOUT "# Design Hier      : $HierDesign         "
	puts $FOUT "# Design Hier Inst : $HierInst           "
	puts $FOUT "# Scr Version      : $scr_version        "
	puts $FOUT "# Date             : [exec date]         "
	puts $FOUT "#*********************************************"
	puts $FOUT ""
	puts $FOUT "#*********************************************"
	puts $FOUT "# Information "
	puts $FOUT "#*********************************************"
	puts $FOUT "# A report is generated only for the point where a violation occurred."
	puts $FOUT "# If Design is MIM, information is displayed for only one instance."
	puts $FOUT "# is_mim                   : $is_mim             "
	puts $FOUT "# input_scale              : $input_scale        "
	puts $FOUT "# output_scale             : $output_scale       "
	puts $FOUT "# ExcludePattern           : $ExcludePattern     "
	puts $FOUT "# Num of Hier Pin Met      : $HierPinMet         "
	puts $FOUT "# Num of Hier Pin Vio      : $HierPinVio         "
	puts $FOUT "# Num of Hier Pin Nopath   : $HierPinNoPath      "
	puts $FOUT "# Num of Hier Pin Infinity : $HierPinInfinity    "
	puts $FOUT "# Num of Hier pin Exclude  : $ExcludePatternPinListNum"
	puts $FOUT "# Num of Hier Pin Total    : $HierPinListNum     "
	puts $FOUT ""
	puts $FOUT "#*********************************************"
	puts $FOUT "# Exclude Pattern Pin List "
	puts $FOUT "#*********************************************"
	if { $EXCLUDE_FLAG } {
		if { $is_mim } {
			foreach pat $ExcludePattern {
				foreach inst $HierInst {
					set pin "$inst/$pat"
					puts -nonewline $FOUT "# [get_object_name [get_pins  $pin]] "
				}
				puts $FOUT ""
			}

		} else {
			foreach_in_collection ExcludePin $ExcludePatternPinList {
				puts $FOUT "#   [get_object_name $ExcludePin]"
			}
		}
	} else {
		puts $FOUT "# none"
	}
	puts $FOUT ""
	puts $FOUT "#*********************************************"
	puts $FOUT "# Command List"
	puts $FOUT "#*********************************************"
	if {[llength $WriteCMDArray ] > 0 } {
		set i 0
		foreach cmd_line $WriteCMDArray {
			puts $FOUT "$cmd_line"
			incr i
	    }
	}

	close $FOUT; if { $debug } { close $FOUT_DBG }

	puts "$HierDesign in progress .... Done"
	puts "Information_ADF: Please check the files below"
	puts "file : $OUTPUT_FILE "
}

define_proc_attributes gen_subhier_pin_inout_delay \
-info "It passes through the hierarchy pin and creates boundary conditions for points where violation occurs."\
-define_args {
    {-HierDesign      "Module name of hierarchy.  ex) CPU_PON_TOP          "                                    ""        string   required }
    {-HierInst        "Instance name of hierarchy ex) I__CPU_PON_TOP       "                                    ""        string   optional }
    {-input_scale     "Scale value of set_input_delay : default 0.7 (70%)  "                                    "value"   string   optional }
    {-output_scale    "Scale value of set_output_delay: default 0.7 (70%)  "                                    "value"   string   optional }
	{-exclude_pattern "Enter the port pattern that will not be scaled for set_input_delay or set_output_delay." "pattern" string   optional }
	{-debug            "debug"                                                                                  ""        boolean {optional hidden} }
}
