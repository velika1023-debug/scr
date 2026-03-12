###############################################################################
# https://solvnetplus.synopsys.com/s/article/reporting-paths-in-primetime-based-on-hierarchy
#  NAME         create_path_groups_for_hierarchy
#
#  ABSTRACT     tcl proc for path groups of a hierarchy
#
#  SYNTAX:	create_path_groups_for_hierarchy
#		  -instance_path
#		  -name
#		  -reference_name
#
#  RESULT:	1 on success, 0 on failure.
#  RETURNS:   Hierarchy-specific path groups for report_qor, report_timing etc.
#  HISTORY:   Sept 20 2021 - Ioannis Seitanidis: Created
#
#  Option -instance_path supports a collection of hierarchical cells.
#  Additional option -reference_name takes a group name and translates it to a
#  hierarchical cell list. There is no upper limit for the size of the list.
#  User must specify only one of the two options -instance_path and 
#  -reference_name (otherwise an error message is printed)
#  This script will create groups ${name}_r2r, ${name}_r2o, ${name}_i2r and 
#  ${name}_i2o for fast and convenient use in report_qor, report_timing etc.
#  If for a given instance there are no points (for example startpoints), the 
#  creation of this group path should be skipped and a warning message is 
#  printed.
#
#  These files contain Synopsys Confidential Information as governed by the 
#  Synopsys End User Software License Agreement (?\uc3dbgreement??, between Synopsys 
#  and recipient. Recipient will use the script solely in connection with 
#  exercising recipient?\uc172 rights under the Agreement.  Recipient will protect 
#  the script from unauthorized dissemination to third parties.  THE FILES ARE 
#  PROVIDED ?\uc3dbS IS?? WITHOUT ANY WARRANTIES, WHETHER EXPRESS, IMPLIED OR 
#  OTHERWISE.  SYNOPSYS SPECIFICALLY DISCLAIMS ANY IMPLIED WARRANTIES OF 
#  NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
###############################################################################

echo "\n\nThese files contain Synopsys Confidential Information as governed by \nthe Synopsys End User Software License Agreement (?\uc3dbgreement??, between \nSynopsys and recipient. Recipient will use the script solely in \nconnection with exercising recipient?\uc172 rights under the Agreement.  \nRecipient will protect the script from unauthorized dissemination \nto third parties.  THE FILES ARE PROVIDED ?\uc3dbS IS?? WITHOUT ANY WARRANTIES, \nWHETHER EXPRESS, IMPLIED OR OTHERWISE.  SYNOPSYS SPECIFICALLY DISCLAIMS \nANY IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND \nFITNESS FOR A PARTICULAR PURPOSE.\n\n"

proc create_path_groups_for_hierarchy {args} {

  # parse the proc arguments
  parse_proc_arguments -args $args p_args 

  set is_instance [info exists p_args(-instance_path)]
  set is_ref_name [info exists p_args(-reference_name)]

  if { $is_instance && $is_ref_name } {
    echo "Error: Both options -instance_path and -reference_name are specified. Only one of them should be set."
    return 0
  }
  if { !$is_instance && !$is_ref_name } {
    echo "Error: None of options -instance_path and -reference_name is specified. Set one of them."
    return 0
  }

  set name $p_args(-name)

  if { $is_instance } {
    set temp $p_args(-instance_path)
    set instances [get_cells $temp]
  } elseif { $is_ref_name } {
    set reference $p_args(-reference_name)
    set instances [all_instances $reference -hierarchy]
  } else {
    set instances ""
  }

  if { [sizeof_collection $instances] == 0 } {
    echo "Error: No valid instance is specified."
    return 0
  }

  # Check if all instances are valid
  foreach_in_collection instance $instances {
    set inst_name [get_object_name $instance]
    set cell [get_cells $inst_name]
    if {[sizeof_collection $cell] != 1} {
      echo "Error: $inst_name is not a valid hierarchy name."
      return 0
    }
    if {[get_attribute $cell is_hierarchical] == false} {
      echo "Error: Specified hierarchy ($inst_name) is non hierarchical."
      return 0
    }
  }

  # Create group paths
  foreach_in_collection instance $instances {
    set instance [get_object_name $instance]

    set instance_startpoints [get_pins -quiet -hier -filter "full_name =~ $instance/* && is_clock_pin"]
    set has_sp 1
    if {[sizeof_collection $instance_startpoints] == 0} {
      echo "Warning: $instance has no startpoint pins. Creation of group paths ${name}_r2r and ${name}_r2o will be skipped."
      set has_sp 0
    }
  
    set instance_endpoints [get_pins -quiet -hier -filter "full_name =~ $instance/* && is_data_pin"]
    set has_ep 1
    if {[sizeof_collection $instance_endpoints] == 0} {
      echo "Warning: $instance has no endpoint pins. Creation of group paths ${name}_r2r and ${name}_i2r will be skipped."
      set has_ep 0
    }

    #org 
    set instance_throughpoints_in [get_pins -quiet $instance/* -filter "direction !~ out"]
    #CA53
    #set instance_throughpoints_in [get_pins -q -h  -f "full_name =~  $instance/*IO_BUF*/Y"]
    set has_tp_in 1
    if {[sizeof_collection $instance_throughpoints_in] == 0} {
      echo "Warning: $instance has no input or inout ports. Creation of group paths ${name}_i2r and ${name}_i2o will be skipped."
      set has_tp_in 0
    }

    #org 
    set instance_throughpoints_out [get_pins -quiet $instance/* -filter "direction !~ in"]
    #set instance_throughpoints_out [get_pins -q -h  -f "full_name =~ $instance/*UPF_ISO*/Y"]
    set has_tp_out 1
    if {[sizeof_collection $instance_throughpoints_out] == 0} {
      echo "Warning: $instance has no output or inout ports. Creation of group paths ${name}_r2o and ${name}_i2o will be skipped."
      set has_tp_out 0
    }

    # Suppress warnings where PrimeTime filters pins that are not real startpoints
    suppress_message UITE-216
    
    # instance/REG2REG
    if { $has_sp && $has_ep } {
     group_path  -name ${name}_r2r_1b -from    $instance_startpoints       -to $instance_endpoints 
    }
    if { $has_sp && $has_ep } {
     group_path  -name ${name}_r2r_2b -from    $instance_startpoints  -th  $instance_throughpoints_out   -to $instance_endpoints 
    }

    if { $has_tp_in && $has_ep } {
      group_path  -name ${name}_i2r_2b -through $instance_throughpoints_in -to $instance_endpoints
    }
    if { $has_sp && $has_tp_out } {
      group_path  -name ${name}_r2o_2b -from    $instance_startpoints       -through $instance_throughpoints_out
    }
    if { $has_tp_in && $has_tp_out } {
      group_path  -name ${name}_i2o_2b -through $instance_throughpoints_in -through $instance_throughpoints_out 
    }
    unsuppress_message UITE-216

  }

  return 1
}

define_proc_attributes create_path_groups_for_hierarchy \
    -info "Defines new path groups group_name_r2r, group_name_i2r, group_name_r2o, group_name_i2o." \
    -define_args \
    { {-name "Specify the name of the new path group." value string required} \
      {-instance_path "Specify the full name of the hierarchical cell(s)." value list optional} \
      {-reference_name "Specify a reference cell name and get all hierarchical instances of the cell." value string optional}
    }
