###################################################################################################
# File               : report_snapshot.tcl                                                        #
# Author             : ADT-DT (jblee)                                                             #
# Description        : generate snapshot report                                                   #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.14                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
###################################################################################################
###########################################################################################
## Pre configuration
###########################################################################################
if {![file isdirectory ${REPORT_DIR}/snapshot]} {
    file mkdir ${REPORT_DIR}/snapshot
}

set min_mask_order [get_attr [get_layer $MIN_ROUTING_LAYER] mask_order]
set max_mask_order [get_attr [get_layer $MAX_ROUTING_LAYER] mask_order]
set routing_layer [get_layer -f "is_routing_layer==true && mask_order>=$min_mask_order && mask_order<=$max_mask_order"]

###########################################################################################
## Snapshot
###########################################################################################
puts "Information_ADF: Capturing snapshot !!"

report_congestion -layers [get_layers -filter "layer_type==interconnect"] -nosplit
gui_start
gui_show_window -window [lindex [gui_get_window_ids] 0] -show_state maximized
gui_set_setting -window [gui_get_current_window -types Layout -mru] -setting showRoute -value false
gui_set_setting -window [gui_get_current_window -types Layout -mru] -setting showPortShape -value false

## Hierarchy Map
gui_show_map -window [gui_get_current_window -types Layout -mru] -map {Hierarchy} -show {true}
gui_load_hierarchy_vm -level 1
gui_zoom -window [gui_get_window_ids -type Layout] -full
gui_write_window_image -file ${REPORT_DIR}/snapshot/${TOP_DESIGN}.hierarchy_level_1.png -format png  -window [gui_get_window_ids -type Layout]
gui_load_hierarchy_vm -level 2
gui_write_window_image -file ${REPORT_DIR}/snapshot/${TOP_DESIGN}.hierarchy_level_2.png -format png  -window [gui_get_window_ids -type Layout]
gui_load_hierarchy_vm -level 3
gui_write_window_image -file ${REPORT_DIR}/snapshot/${TOP_DESIGN}.hierarchy_level_3.png -format png  -window [gui_get_window_ids -type Layout]
gui_show_map -window [gui_get_current_window -types Layout -mru] -map {Hierarchy} -show {false}

## Cell Density Map
gui_show_map -window [gui_get_current_window -types Layout -mru] -map {cellDensityMap} -show {true}
gui_set_map_option -map {cellDensityMap} -option {min_threshold} -value {0.5}
gui_set_map_option -map {cellDensityMap} -option {max_threshold} -value {1}
gui_load_cell_density_mm
gui_write_window_image -file ${REPORT_DIR}/snapshot/${TOP_DESIGN}.cell_density.png -format png  -window [gui_get_window_ids -type Layout]

## Congestion Map
gui_show_map -window [gui_get_current_window -types Layout -mru] -map {globalCongestionMap} -show {true}
gui_set_setting -window [gui_get_current_window -types Layout -mru] -setting showCellCore -value false
gui_set_map_option -map {globalCongestionMap} -option {use_underflow} -value {true}
gui_set_map_option -map {globalCongestionMap} -option {layers} -value [get_object_name $routing_layer]
gui_write_window_image -file ${REPORT_DIR}/snapshot/${TOP_DESIGN}.congestion.png -format png  -window [gui_get_window_ids -type Layout]
gui_set_setting -window [gui_get_current_window -types Layout -mru] -setting showCellCore -value true

## Pin Density Map
gui_show_map -window [gui_get_current_window -types Layout -mru] -map {pinDensityMap} -show {true}
gui_load_pin_density_mm
gui_write_window_image -file ${REPORT_DIR}/snapshot/${TOP_DESIGN}.pin_density.png -format png -window [gui_get_window_ids -type Layout]

## Ports check
gui_change_highlight  -collection [get_shapes -of_objects [get_ports *]] -color red
change_selection [get_ports  -filter "port_type != power && port_type != ground"]
gui_highlight_nets_of_selected
gui_write_window_image -format png -file ${REPORT_DIR}/snapshot/${TOP_DESIGN}.port.png
gui_change_highlight -remove -all_colors

##legality check (check place)
if { [sizeof [get_drc_error_data -filter "name=~*legality.err" -all]] } {
    gui_open_error_data  __${TOP_DESIGN}_check_legality.err
    gui_write_window_image -format png -file ${REPORT_DIR}/snapshot/${TOP_DESIGN}.checkPlace.png
}
gui_stop
