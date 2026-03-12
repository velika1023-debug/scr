#!/usr/bin/tclsh

#################################################################################################
# Title       : split_eco_file.tcl
# Author      : DT-PI
# Date        : 2024.02.13
# Description : Split eco tcl for sub blocks. 
# Usage :
#  pt_shell > source ./split_eco_file.tcl
#  pt_shell > split_eco_file
#				-inst_hier_names "\
#					ddr_chip_axi   I__CHIP_PON25G_CORE/I__CPU_TOP_MAIN/I__ddr_chip_axi     \
#					CPU_PP_TOP     I__CHIP_PON25G_CORE/I__CPU_PP_TOP                       \
#					RV64_TOP_WRAP  I__CHIP_PON25G_CORE/I__CPU_TOP_MAIN/I__RV64_TOP_WRAP    " \
#				-input "eco_icc2tcl.tcl"
#################################################################################################

proc split_eco_file {args} {

	parse_proc_arguments -args $args p_args
		set inst_hier_names $p_args(-inst_hier_names)
		set input			$p_args(-input)

    set all_hiers  ""
    set all_files  ""

	foreach { inst hier } $inst_hier_names {
		lappend all_files $inst
		lappend all_hiers $hier
	}

    if {[llength $all_hiers] ne [llength $all_files] } {
        echo "ERROR : Instance name does not have a respective file name or vice versa"
        return 0
    }

    echo "##########################################################################"
    set cnt_inst 0
    foreach item $all_hiers {
        set output_array([lindex $all_hiers $cnt_inst]) [lindex $all_files $cnt_inst]
        echo " Instance [lindex $all_hiers $cnt_inst] will be output to filename : $output_array([lindex $all_hiers $cnt_inst]).tcl "
        set cnt_inst [expr $cnt_inst +1]
    }

    echo "All other instance and top will be mapped to : top_eco.tcl"
    echo "##########################################################################"
    set ECO_FILE [open $input "r"]

    set cur_output_file top_out.tcl
    redirect $cur_output_file { echo "# START eco file top_eco.tcl :: TOP LEVEL"}

    foreach item $all_hiers {
        redirect $output_array($item).tcl {echo "# START eco file $output_array($item).tcl :: $item" }
    }

    set cnt_ref 0
    set cnt_imp 0

    while {[gets $ECO_FILE line] >= 0 } {
        if {[regexp {current_instance} $line match]} {
            set cur_output_file top_out.tcl
            if {[regexp {current_instance \S+} $line match]} {
                foreach item $all_hiers {
                    if {[regexp $item $line match]} {
                        ;#establish current output file, default top
                        set cur_output_file $output_array($item).tcl
                        ;#echo "$line $item"
                        regsub -all -- ${item}/ $line "" line
                        ;#echo $line
                        regsub -all -- ${item} $line "" line
                        ;#echo $line
                    }
                }
                redirect -append $cur_output_file { echo "current_instance" }
                redirect -append $cur_output_file { echo $line }

            } else {
                redirect -append $cur_output_file { echo "current_instance" }
            }
        } else {
            ;#output line to last file
            ;# echo "$line"
            ;# echo "$cur_output_file"
            redirect -append $cur_output_file { echo $line }
        }
        set cnt_ref [incr cnt_ref]

        if { ${cnt_ref}==1000 } {
			set cnt_imp [expr $cnt_imp + $cnt_ref]; echo "Processed $cnt_imp lines ..."; set cnt_ref 0
		}
    }

    set cnt_imp [expr $cnt_imp + $cnt_ref]; 
echo " Processed $cnt_imp lines ... DONE ..."

    ;#Outputing last current_instance in file
    redirect -append top_out.tcl { echo "current_instance" }
    foreach item $all_hiers {
        redirect -append $output_array($item).tcl {echo "current_instance" }
    }

    close $ECO_FILE
}

define_proc_attributes split_eco_file -hide_body \
-info "Split FLAT ECO file" \
-define_args {
    {-inst_hier_names "string of Instance name in quotes" "" string required}
    {-input  "input TOP eco file" "" string required}
}
