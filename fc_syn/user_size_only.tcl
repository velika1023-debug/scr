##########################################################################################
# File               : user_size_only.tcl                                                # 
# Description        : Check and set the dont_use list in the design.                    #
##########################################################################################


# #source ../tsdb_outdir/dft_inserted_designs/${top_design}_2ND.dft_inserted_design/${top_design}.sdc
# set preserve_instances [tessent_get_preserve_instances icl_extract]
# set_boundary_optimization $preserve_instances  false 
# set_ungroup $preserve_instances false
# set_boundary_optimization [tessent_get_optimize_instances] true
# set_size_only -all_instance [tessent_get_size_only_instances]
# set_constant_register_removal [get_cells LTEST_INTF_*] false
# set_unloaded_register_removal [get_cells LTEST_INTF_*] false
# set size_only_cells [get_cells -quiet -hier -filter "full_name =~ *bda_persistent* && is_hierarchical ==true"]
# foreach_in_collection col $size_only_cells {
#     puts [get_attribute $col full_name]
#     set_boundary_optimization $col false
#     set_dont_touch [get_pins -of_objects $col] true
# }
# foreach_in_collection col [get_cells -hier -f "full_name =~ *_2ND_tessent* && is_hierarchical == true"] {
#     puts [get_attribute $col full_name]
#     set_boundary_optimization $col false
# 
# }
# foreach_in_collection col [get_cells -hier -f "full_name =~ *IEEE1687_SEGMENT* && is_hierarchical == true"] {
#     puts [get_attribute $col full_name]
#     set_boundary_optimization $col false
# }
# 
# set size_only_cells [get_cells -quiet -hier -filter "full_name =~ *bda_persistent* && is_hierarchical ==false"]
# foreach_in_collection col $size_only_cells {
#     set_size_only -all_instances $col true
#     set_dont_touch [get_nets -of_objects $col] true
# }
# 
# set size_only_cells [get_cells -quiet -hier -filter "full_name =~ *udnt* && is_hierarchical ==false"]
# foreach_in_collection col $size_only_cells {
#   set inst_name [get_attribute $col full_name]
#     set_size_only -all_instances $col true
#     set_dont_touch [get_nets -of_objects $col] true
# }
# 
# set size_only_instances [get_cell -quiet -hier -quiet -filter "full_name =~ *tessent_persistent* && is_hierarchical == false"]
# foreach_in_collection col $size_only_instances {
#     puts [get_attribute $col full_name]
#     set_size_only -all_instances $col true
#     set_dont_touch [get_nets -of_objects $col] true
# }
# 
# set dont_touch_list [list \
# 			 u_SDUMP_INTF/udnt_buf_ijtag_tck/udnt_buf \
# 			 u_SDUMP_INTF/udnt_icg_int/udnt_icg \
# 			 u_SDUMP_INTF/udnt_icg_ext/udnt_icg \
# 			]
# 
# foreach dont_touch $dont_touch_list {
#     foreach_in_collection col [get_cells -quiet $dont_touch] {
# 	puts [get_attribute $col full_name]
# 	set_dont_touch $col true
#     }
# }
# 
# 
# set size_only_cells [get_cells -quiet -hier -filter "full_name =~ *occ_control/ShiftReg/FF_reg*"]
# foreach_in_collection col $size_only_cells {
#     puts [get_attribute $col full_name]
#     set_size_only -all_instances $col
#     set_dont_touch [get_nets -of_objects $col] true
# }
# set size_only_cells [get_cells -quiet -hier -filter "full_name =~ *occ_ctrl*"]
# foreach_in_collection col $size_only_cells {
#     puts [get_attribute $col full_name]
#     set_size_only -all_instances $col
#     set_dont_touch [get_nets -of_objects $col] true
# }
# 
# set size_only_cells [get_cells -quiet -hier -filter "full_name =~ *MBISTPG_COUNTER_A/COUNTERA_CNT_reg*"]
# foreach_in_collection col $size_only_cells {
#     puts [get_attribute $col full_name]
#     set_size_only -all_instances $col
#     set_dont_touch [get_nets -of_objects $col] true
# }
# set size_only_cells [get_cells -quiet -hier -filter "full_name =~ *MBISTPG_CTL_COMP/ERROR_CNT_REG_reg*"]
# foreach_in_collection col $size_only_cells {
#     puts [get_attribute $col full_name]
#     set_size_only -all_instances $col
#     set_dont_touch [get_nets -of_objects $col] true
# }
# set size_only_cells [get_cells -quiet -hier -filter "full_name =~ *MBISTPG_CTL_COMP/FL_CNT_REG_reg*"]
# foreach_in_collection col $size_only_cells {
#     puts [get_attribute $col full_name]
#     set_size_only -all_instances $col
#     set_dont_touch [get_nets -of_objects $col] true
# }
# set size_only_cells [get_cells -quiet -hier -filter "full_name =~ *MBISTPG_FSM/RUNTEST_EN_REG_reg*"]
# foreach_in_collection col $size_only_cells {
#     puts [get_attribute $col full_name]
#     set_size_only -all_instances $col
#     set_dont_touch [get_nets -of_objects $col] true
# }
# 
# set size_only_cells [get_cells -quiet -hier -filter "full_name =~ *_1ST_tessent_tdr_*_inst/*_latch_reg* && is_hierarchical ==false"]
# foreach_in_collection col $size_only_cells {
#     puts [get_attribute $col full_name]
#     set_size_only -all_instances $col true
#     set_dont_touch [get_nets -of_objects $col] true
# }
# 
