################################################################################
# File Name     : report_mttv_detail.tcl
# Author        : DT-PI
# Creation Date : 2024-06-10
# Last Modified : 2025-02-10
# Version       : v0.2
# Location      : ${COMMON_PT}/report_mttv_detail.tcl
#-------------------------------------------------------------------------------
# Description   :
# 	All_violatores.max_tran.rpt.{CLOCK,DATA} Shows the report in detail
#-------------------------------------------------------------------------------
# Change Log    :
# 	v0.1 [2024-06-10] : iskim1001
#       - We reorganized the existing report_mttv.tcl(v0.8) script.
#   v0.2 [2025-02-10] : jaeeun1115
#       - Considering multiple drivers
#-------------------------------------------------------------------------------
# Useage        :
# 	pt_shell > source ${COMMON_TCL_PT}/report_mttv_detial.tcl
#################################################################################



set DesignName      [get_object_name  [current_design]]
set product_version $sh_product_version
set scr_version     "v0.1 (2024.06.10)"

puts "Information_ADF: sourcing file START - [info script]"
foreach  DATA_CLK "DATA CLOCK" {
	###########################################################################
	# File Setting
	###########################################################################
	set INPUT_FILE       "${RPT_DIR}/all_violators.max_tran.rpt.${DATA_CLK}"
	set OUTPUT_FILE      "${RPT_DIR}/all_violators.max_tran.rpt.${DATA_CLK}_detail"

	###########################################################################
    # INPUT_FILE Check
	###########################################################################
	if {  [file exist $INPUT_FILE] } {
		puts "Information_ADF: Found file $INPUT_FILE .... "
	} else {
		puts "Warning_ADF: Not Found file $INPUT_FILE ...."
		puts "Warning_ADF: Detail report generation is skipped...."
		puts "Warning_ADF: Detail report generation is skipped...."
		puts "Warning_ADF: Not Found file $INPUT_FILE .... (done)"
		continue
	}

	###########################################################################
    # INPUT_FILE Open
	###########################################################################
    set OPEN_INPUT_FILE  [ open $INPUT_FILE   r+ ]
    set OPEN_OUTPUT_FILE [ open $OUTPUT_FILE  w+ ]


	###########################################################################
    # Display header
	###########################################################################
    puts $OPEN_OUTPUT_FILE "********************************************"
    puts $OPEN_OUTPUT_FILE "Report         : MTTV Clock Data Report     "
    puts $OPEN_OUTPUT_FILE "Design         : ${DesignName}              "
    puts $OPEN_OUTPUT_FILE "Version        : $product_version           "
    puts $OPEN_OUTPUT_FILE "Date           : [exec date]                "
    puts $OPEN_OUTPUT_FILE "Scr Version    : $scr_version               "
    puts $OPEN_OUTPUT_FILE "Input File     : $INPUT_FILE                "
    puts $OPEN_OUTPUT_FILE "********************************************"
    puts $OPEN_OUTPUT_FILE "# Information                               "
    puts $OPEN_OUTPUT_FILE "# D-- : Driver                              "
    puts $OPEN_OUTPUT_FILE "# N-- : Net                                 "
    puts $OPEN_OUTPUT_FILE "# L-- : Load                                "
    puts $OPEN_OUTPUT_FILE "# Slk : Slack                               "
    puts $OPEN_OUTPUT_FILE "# Req : Required Transition                 "
    puts $OPEN_OUTPUT_FILE "# Act : Actual Transition                   "
    puts $OPEN_OUTPUT_FILE "# **PAD cell does not list up               "




	###########################################################################
	# Create MttvPinDriverUniq
	###########################################################################
	set MttvPinDriverUniq ""
	while { [ gets $OPEN_INPUT_FILE line ] >= 0 } {
		if { [regexp "VIOLATED" $line] } {
			set MttvPin                  [lindex $line 0]

			# Classifies object_class (pin or port) of Mttv point
			if { [regexp {/} $MttvPin] } {
				set MttvPinDirection   [get_attribute [get_pins $MttvPin ] direction				   ]
				set MttvPinClass       [get_attribute [get_pins $MttvPin ] object_class 			   ]
				set MttvPinConstraint  [get_attribute [get_pins $MttvPin ] constraining_max_transition]
			} else {
				set MttvPinDirection   [get_attribute [get_ports $MttvPin] direction				   ]
				set MttvPinClass       [get_attribute [get_ports $MttvPin] object_class 			   ]
				set MttvPinConstraint  [get_attribute [get_ports $MttvPin] constraining_max_transition]
			}

			if { $MttvPinConstraint != "INFINITY" && $MttvPinConstraint != "" } {
				# Classifies data or clock (pin or port) of Mttv point
				set MttvPinDriver ""

				# Set MttvPinDriver according to object_class and direction.
                      if { ( $MttvPinClass == "port" || $MttvPinClass == "pin" ) && ( $MttvPinDirection == "inout" ) } { continue
				} elseif {   $MttvPinClass == "pin"                              &&   $MttvPinDirection != "inout"   } { set MttvPinDriver [get_object_name [get_attribute [get_pins $MttvPin] net.leaf_drivers]]
			    } elseif {   $MttvPinClass == "port"                             &&   $MttvPinDirection == "out"     } { set MttvPinDriver [get_object_name [get_pins -of  [get_nets -of [get_ports $MttvPin]] -filter "is_hierarchical == false"]]
			    } elseif {   $MttvPinClass == "port"                             &&   $MttvPinDirection == "in"      } { set MttvPinDriver $MttvPin
			    } else   { puts "Unkonw object_class & MttvPinDirection ( MttvPin : $MttvPin , Pin/Port : $MttvPinClass , Pin direction : $MttvPinDirection )"         }

				# Distinguish between clock and data for the violation occurrence part in the report
				if { [sizeof_collection [get_ports -quiet $MttvPinDriver]] > 0 } {
					set MttvPinDriver_direction [get_attribute [get_ports $MttvPinDriver] direction]
				} else {
					set MttvPinDriver_direction [get_attribute [get_pins  $MttvPinDriver] direction]
				}

				if { $MttvPinDriver_direction != "inout" } {
                    foreach item $MttvPinDriver {
					    lappend MttvPinDriverUniq  $item
                    }
				}
			}
		}
	}

	###########################################################################
	# sort -u MttvPinDriverUniq
	###########################################################################
	set MttvPinDriverUniq  [lsort -unique $MttvPinDriverUniq  ]



	###########################################################################
	# Check Constraint
	###########################################################################
	set MttvPinDriver ""
    set i 0
	foreach MttvPinDriver  $MttvPinDriverUniq {
		#--------------------------------------------------------------------------
		# The part that checks whether MttvPinDriver is a port or a pin.
		#--------------------------------------------------------------------------
		if { [sizeof_collection [get_ports -quiet $MttvPinDriver]] > 0 } {
			set driver_constraint [get_attribute -quiet [get_ports $MttvPinDriver] constraining_max_transition]
		} else {
			set driver_constraint [get_attribute -quiet [get_pins  $MttvPinDriver] constraining_max_transition]
		}

		#--------------------------------------------------------------------------
		# Syntax to check whether the value of dirver_constraint variable is not INFINITY and is not blank("").
		#--------------------------------------------------------------------------
		if {  $driver_constraint != "INFINITY" && $driver_constraint != "" } {
			incr i
        	set slack_pin ""
			# Get driver port/pin information
			if { [sizeof_collection [get_ports -quiet $MttvPinDriver]] > 0 } {
        		set DriverActTran [format %.6f [get_attribute     [get_ports $MttvPinDriver          ] drc_actual_max_transition   ]]
        		set DriverConTran [format %.6f [get_attribute     [get_ports $MttvPinDriver          ] constraining_max_transition ]]
        		set DriverRefName [get_attribute     [get_cells -of $MttvPinDriver     ] ref_name                    ]
        		set DriverNet     [get_object_name   [get_nets -of [get_ports $MttvPinDriver ]]]
        		set DriverFanout  [sizeof_collection [get_pins [all_connected [ get_nets -of [get_ports $MttvPinDriver]] -leaf] -quiet -filter "pin_direction == in" ] ]
        		set DriverLoads   [get_object_name   [get_pins [all_connected [ get_nets -of [get_ports $MttvPinDriver]] -leaf] -quiet -filter "pin_direction == in" ] ]
        		set DriverSlack   [format %.6f [get_attribute [get_ports $MttvPinDriver] drc_max_transition_slack]]
			} else {
        		set DriverActTran [format %.6f [get_attribute     [get_pins $MttvPinDriver          ] drc_actual_max_transition   ]]
        		set DriverConTran [format %.6f [get_attribute     [get_pins $MttvPinDriver          ] constraining_max_transition ]]
        		set DriverRefName [get_attribute     [get_cells -of $MttvPinDriver     ] ref_name                    ]
        		set DriverNet     [get_object_name   [get_nets -of [get_pins $MttvPinDriver ]]]
        		set DriverFanout  [sizeof_collection [get_pins [all_connected [ get_nets -of [get_pins $MttvPinDriver]] -leaf] -quiet -filter "pin_direction == in" ] ]
        		set DriverLoads   [get_object_name   [get_pins [all_connected [ get_nets -of [get_pins $MttvPinDriver]] -leaf] -quiet -filter "pin_direction == in" ] ]
        		set DriverSlack   [format %.6f [get_attribute [get_pins $MttvPinDriver] drc_max_transition_slack]]
			}

        	#Get Load port/pin information
        	foreach MttvPinDriverLoad $DriverLoads {
				# The part that checks whether MttvPinDriverLoad is a port or a pin.
				if { [sizeof_collection [get_ports -quiet $MttvPinDriverLoad]] > 0 } {
					set load_constraint [get_attribute -quiet [get_ports $MttvPinDriverLoad] constraining_max_transition]
				} else {
					set load_constraint [get_attribute -quiet [get_pins  $MttvPinDriverLoad] constraining_max_transition]
				}

				# Syntax to check whether the value of load_constraint variable is not INFINITY and is not blank("").
				if { $load_constraint != "INFINITY" && $load_constraint != ""  } {
					# Get load port/pin information
					if { [sizeof_collection [get_ports -quiet $MttvPinDriverLoad]] > 0 } {
						set LoadActTran   [format %.6f [get_attribute [get_ports $MttvPinDriverLoad      ] drc_actual_max_transition   ]]
        	    		set LoadConTran   [format %.6f [get_attribute [get_ports $MttvPinDriverLoad      ] constraining_max_transition ]]
        	    		set LoadRefName   [get_attribute [get_cells -of $MttvPinDriverLoad ] ref_name ]
        	    		set LoadDirection [get_attribute [get_ports $MttvPinDriverLoad      ] direction]
        	    		set LoadSlack     [format %.6f [get_attribute [get_ports $MttvPinDriverLoad] drc_max_transition_slack]]
        	    		lappend slack_pin "$LoadSlack $MttvPinDriverLoad $LoadActTran"
					} else {
        	    		set LoadActTran   [format %.6f [get_attribute [get_pins $MttvPinDriverLoad      ] drc_actual_max_transition   ]]
        	    		set LoadConTran   [format %.6f [get_attribute [get_pins $MttvPinDriverLoad      ] constraining_max_transition ]]
        	    		set LoadRefName   [get_attribute [get_cells -of $MttvPinDriverLoad ] ref_name ]
        	    		set LoadDirection [get_attribute [get_pins $MttvPinDriverLoad      ] direction]
        	    		set LoadSlack     [format %.6f [get_attribute [get_pins $MttvPinDriverLoad] drc_max_transition_slack]]
						lappend slack_pin "$LoadSlack $MttvPinDriverLoad $LoadActTran"
					}
				}
        	}

			# Detail Display :
			if { $DriverFanout > 0 } {
				#Display driver pin information
        		puts $OPEN_OUTPUT_FILE "\n"
        		puts $OPEN_OUTPUT_FILE "#$i. (#.fanout $DriverFanout )"
        		puts $OPEN_OUTPUT_FILE "D-- (Slk: $DriverSlack , Req: $DriverConTran, Act: $DriverActTran  $DriverRefName ) : $MttvPinDriver "
        		puts $OPEN_OUTPUT_FILE "  N-- $DriverNet"

        		#Display load pin information
        		foreach sp [lsort -real -index 0 $slack_pin] {
        		    # positve slack display hide
        		    if { ![regexp {^-} [lindex $sp 0]] } { break  }
        		    puts $OPEN_OUTPUT_FILE "    L-- (Slk: [format  "% .6f" [lindex $sp 0]] , Req: $LoadConTran, Act: [lindex $sp 2]  $LoadRefName ) : [lindex $sp 1] "
        		}
			}
		}


	}

	close $OPEN_INPUT_FILE
	close $OPEN_OUTPUT_FILE
	puts "Information_ADF: Found file $INPUT_FILE .... (done)"
}

exec touch _report_mttv.done
puts "Information_ADF: sourcing file END - [info script]"
