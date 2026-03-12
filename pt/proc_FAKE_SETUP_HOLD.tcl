################################################################################
# File Name     : FAKE_setup_hold_violation.tcl
# Author        : DT-PI(iskim1001)
# Creation Date : 2024-03-13
# Last Modified : 2025-07-15
# Version       : v1.5
# Location      : ${COMMON_TCL_PT}/output_write_sdf.tcl
#-------------------------------------------------------------------------------
# Description   :
#	Before creating the FAKE_SDF
#	Create a script to make Setup & Hold into zero slack.
#	setup :
#   	- multiply_slack ( +1.1 ) --> set_annotated_delay -slack
#   hold  :
#   	- multiply_slack ( -1.1 ) --> set_annotated_delay +slack
#-------------------------------------------------------------------------------
# Change Log    :
#   v0.1 [2023-03-03] : iskim1001
#   	- first released for Denali Project
#   v0.2 [2023-03-16] : iskim1001
#   	- multiply_slack & Error Fix
#   v0.3 [2024-03-06] : iskim1001
#   	- Script Modify
#   v0.4 [2024-03-15] : iskim1001
#   	- IN2OUT Add
#   v0.5 [2024-05-09] : emlee
#   	- add -min -max option
#   	- default multiply_slack variable change ( 1.8 -> 1.3 )
#   v0.6 [2024-05-24] : iskim1001
#   	- ADF Message Rule Change
#       	Before : <ADF_ERROR>: , <ADF_WARN>:  , <ADF_INFO>:
#       	After  : Error_ADF:   , Warning_ADF: , Information_ADF:
#   v0.7 [2024-06-18] : iskim1001
#   	- Bug fix
#			regexp {[ ]-} $line => string match "*) -*" $line [line 129]
#   v0.8 [2024-06-27] : iskim1001
#   	- Boundary Bugfix (IN2REG)
#   v0.9 [2024-08-02] : jjh8744
#   	- Add direction filter to Driver_pin variable. (IN2REG)
#   v1.0 [2025-01-09] : jaeeun1115
#       - Add -max_path option to report_timing
#   v1.1 [2025-02-13] : iskim1001
#   	- Modified Default multiply_slack ( 1.8 -> 1.1 ) 
#   	- Boundary Driver_pin Variable command Modify :
#   		Before : set Driver_pin        [get_attribute  [get_pins -of $Net_of_EP -leaf -filter "direction ==  out"] net.leaf_drivers]
#   		After  : set Driver_pin        [get_attribute  [get_pins -of $Net_of_EP -leaf -filter "direction =~ *out"] net.leaf_drivers]
#   	- set_annotated_delay option remove ( -increment , ${minmax}
#   		Before : set fmt "set_annotated_delay -increment  ${minmax} -net $derated_slack -from $Driver_pin_name -to $EP "
#   		After  : set fmt "set_annotated_delay                       -net $derated_slack -from $Driver_pin_name -to $EP "
#   v1.2 [2025-02-14] : sjlee
#   	- set_annotated_delay option remove ( -increment for hold )
#   v1.3 [2025-02-17] : sjlee
#       - to find pin name related with inout PAD pin 
#   v1.4 [2025-02-19]  sjlee
#       - Applied increment options when setup hacking
#   v1.5 [2025-07-15] : sjlee
#       - I2O path hack
#-------------------------------------------------------------------------------
# Usage        :
# 	pt_shell > source ./FAKE_SETUP_HOLD.tcl
# 	pt_shell > FAKE_SETUP_HOLD -type setup
# 	pt_shell > FAKE_SETUP_HOLD -type hold
#################################################################################

puts ""
puts "Warning_ADF: FAKE_SDF is not a normal flow, and PI users must keep this in mind."
puts "Warning_ADF: Be sure to check the log and report to see if FAKE_SDF was successfully annotated."
puts ""
puts "Information_ADF: Create set_annotated_delay_for_{setup,hold}_hacking.list."
puts "Information_ADF: The default value is blank and is annotated in both min and max."
puts ""


proc FAKE_SETUP_HOLD  {args} {
	parse_proc_arguments -args $args p_args

	# Option setting
	set sh_flag            $p_args(-type)

	#min_max setting
	if { $sh_flag == "setup" } {
		set min_max  "max"
		set multiply_slack 1.1
	} elseif { $sh_flag == "hold"  } {
		set min_max  "min"
		set multiply_slack -1.1
	} else   {
		set min_max  "max"
		set multiply_slack 1.1
	}


	if {[info exists p_args(-multiply_slack) ]} {
		set multiply_slack     $p_args(-multiply_slack)
		puts "User setting multiply_slack Value : $multiply_slack"
	} else {
		puts "Default setting multiply_slack Value : $multiply_slack"
	}

	if {[info exists p_args(-debug)]} {
		set is_debug "1"
	} else {
		set is_debug "0"
	}



	# File setting
	set SEP1_FILE "${sh_flag}_sep_1.summary"
	set SEP2_FILE "${sh_flag}_sep_2.summary"
	set SEP3_FILE "${sh_flag}_sep_3.summary"
	set HACK_FILE "set_annotated_delay_for_${sh_flag}_hacking.list"
	if { $is_debug } {
		puts ""
		puts "<DEBUG_MODE> : File Check "
		puts "<DEBUG> : SEP1_FILE \"${sh_flag}_sep_1.summary\" "
		puts "<DEBUG> : SEP2_FILE \"${sh_flag}_sep_2.summary\" "
		puts "<DEBUG> : SEP3_FILE \"${sh_flag}_sep_3.summary\" "
		puts "<DEBUG> : HACK_FILE \"set_annotated_delay_for_${sh_flag}_hacking.list\" "
		puts ""
	}

	# STEP 1 : sep ( start_end_pair) report Gen
	echo -n "STEP_1 ($min_max) : sep report create ... "
    redirect -file $SEP1_FILE { report_timing -delay ${min_max} -sig 6 -start_end_pair -nosplit -path summary -max_path 200000000 }
    #redirect -file $SEP1_FILE { report_timing -delay ${min_max} -sig 6 -start_end_pair -nosplit -path summary -max_path 99999 }
	echo "(done)"


	echo -n "STEP_2 ($min_max) : report format chagne ... "
	# STEP 2 : report format change ( EP SLACK SP EP_TYPE SP_TYPE )
	set OPEN_SEP1_FILE [ open $SEP1_FILE r+ ]
	redirect -file $SEP2_FILE {
		while { [ gets $OPEN_SEP1_FILE line ] >= 0 } {
			if { [string match "*) -*" $line] } {
				set EP      [ lindex $line end-2 ]
				set SLACK   [ lindex $line end   ]
				set SP      [ lindex $line 0     ]
				set EP_TYPE [ lindex $line end-1 ]
				set SP_TYPE [ lindex $line 1     ]
				puts "$EP $SLACK $SP $EP_TYPE $SP_TYPE"
			}
		}
	}
	echo "(done)"

	echo -n "STEP_3 ($min_max) : report sorting ... "
	# STEP 3 : report sorting
    redirect -file $SEP3_FILE { exec sh -c "sort -k2,2n $SEP2_FILE | sort -u -k1,1" }
	echo "(done)"


	# STEP 4 : Main Program
	echo -n "STEP_4 ($min_max) : Create set_annotated_delay file"
    set OPEN_SEP3_FILE [ open $SEP3_FILE  r+ ]
    set OPEN_HACK_FILE [ open $HACK_FILE  w+ ]
	set TOTAL_LINE     [lindex [exec wc -l $SEP3_FILE ] 0]
	set LAST_REPORTED_PROGRESS -1
	set CURRENT_LINE 0


	# report format change ( EP SLACK SP EP_TYPE SP_TYPE )
    while { [ gets $OPEN_SEP3_FILE line ] >= 0 } {
		if { [ string match "*\(in\)*" $line ] || [ string match "*\(out\)*" $line ]  || [ string match "*\(inout\)*" $line ] } {
			####################################################################
			# Boundary ( in / out / inout )
			####################################################################
			set EP              [ lindex $line 0 ]
            set SLACK           [ lindex $line 1 ]

			if { [ string match "*\(in\)*" $line ] } {
            	set Net_of_EP       [ get_nets -of [get_pins $EP  ]] ; set TYPE "I2R"
                if {$Net_of_EP == ""} {
                    set Net_of_EP   [ get_nets -q -of [get_port $EP  ]] ; set TYPE "I2O"
                }
			} elseif { [ string match "*\(inout\)*" $line ] } {
            	set Net_of_EP       [ get_nets -of [get_pins $EP  ]] ; set TYPE "inout(PAD)"
                if {$Net_of_EP == ""} {
                    set Net_of_EP   [ get_nets -q -of [get_port $EP  ]] ; set TYPE "inout(PAD)"
                }
			} else {
            	set Net_of_EP       [ get_nets -of [get_ports $EP ]] ; set TYPE "R2O"
			}

            #set Driver_pin        [get_attribute  [get_pins -of $Net_of_EP -leaf -filter "direction =~ *out"] net.leaf_drivers]
            set Driver_pin        [get_pins -of $Net_of_EP -leaf -filter "direction =~ *out"]
            set Driver_pin_name   [get_object_name $Driver_pin]

            set derated_slack   [ expr $SLACK * ${multiply_slack} ]

			#debug mode
			if { $is_debug } { puts "<DEBUG-${min_max}> : set derated_slack \[expr $SLACK * $multiply_slack \] "}

			#IN2REG & REG2OUT & IN2OUT
            if {$sh_flag == "setup"} {
                set fmt "set_annotated_delay -increment -net $derated_slack -from $Driver_pin_name -to $EP \;# $TYPE "
            } else {
                set fmt "set_annotated_delay -increment -net $derated_slack -from $Driver_pin_name -to $EP \;# $TYPE "
            }
    

			#debug mode
			if { $is_debug } { puts "<DEBUG-${min_max}> : $fmt" ;puts "" }

			puts $OPEN_HACK_FILE  $fmt


		} else {
			####################################################################
			# Exclude Boundary ( in / out / inout )
			####################################################################
            set EP              [ lindex $line 0 ]
            set SLACK           [ lindex $line 1 ]
            set Net_of_EP       [ get_nets -of [ get_pins $EP]]
            set Driver_pin      [ get_pins -leaf -filter "direction == out" -of $Net_of_EP ]
            set Driver_pin_name [ get_object_name $Driver_pin]

            set derated_slack [ expr $SLACK * $multiply_slack ]

			#debug mode
			if { $is_debug } { puts "<DEBUG-${min_max}> : set derated_slack \[expr $SLACK * $multiply_slack \] " }


            if { $Driver_pin_name != "" && $EP != ""} {
                if {$sh_flag == "setup"} {
                    set fmt "set_annotated_delay -increment -net $derated_slack -from $Driver_pin_name -to $EP \;# REG2REG"
                } else {
                    set fmt "set_annotated_delay -increment -net $derated_slack -from $Driver_pin_name -to $EP \;# REG2REG"
                }

			}

			#debug mode
			if { $is_debug } { puts "<DEBUG-${min_max}> : $fmt" ;puts "" }

			puts $OPEN_HACK_FILE  $fmt


		}
        incr CURRENT_LINE
        set PROGRESS [expr {($CURRENT_LINE * 100) / $TOTAL_LINE}]
        if {$PROGRESS >= $LAST_REPORTED_PROGRESS + 10} {
            set LAST_REPORTED_PROGRESS [expr {int($PROGRESS / 10) * 10}]
#            puts "Progress: $LAST_REPORTED_PROGRESS%"
            echo -n "...$LAST_REPORTED_PROGRESS%"
        }

	} ;# while $OPEN_SETUP_SEP3_FILE END
	close $OPEN_SEP3_FILE
	close $OPEN_HACK_FILE
	echo ""



}
define_proc_attributes FAKE_SETUP_HOLD \
-info "-type (setup or hold) " \
-define_args {
    {-type               " setup or hold             "  ""        string    required  }
    {-multiply_slack     " default is 1.1            "  ""        float     optional  }
    {-debug              " debug mode                "  ""        boolean   {optional hidden} }

}
