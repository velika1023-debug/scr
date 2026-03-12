###################################################################################################
# File               : 0_fc_setup.tcl                                                             #
# Author             : ADT-DT (bmkim)                                                             #
# Description        : fc option list                                                             #
# Usage              :                                                                            #
# Init Release Date  : 2025.06.04                                                                 #
# Script Version     : 1.0                                                                        #
# Revision History   :                                                                            #
#         2025.06.04 - first released                                                             #
###################################################################################################

set sh_continue_on_error true

##-------------------------------------------------------------------------------------------
## Handling message
##-------------------------------------------------------------------------------------------
set_message_info -id LEFR-064         -limit 20

##-------------------------------------------------------------------------------------------
## ndm_gen app options
##-------------------------------------------------------------------------------------------
set_app_options -as_user_default -name lib.physical_model.block_all                 -value false
set_app_options -name file.lef.allow_site_conflicts                                 -value true
set_app_options -name file.lef.auto_rename_conflict_sites                           -value true
set_app_options -name file.lef.non_real_cut_obs_mode                                -value true
set_app_options -name lib.logic_model.allow_ccs_timing                              -value true
set_app_options -name lib.logic_model.auto_remove_incompatible_timing_designs       -value true
set_app_options -name lib.logic_model.auto_remove_timing_only_designs               -value true
set_app_options -name lib.logic_model.require_same_opt_attrs                        -value false
set_app_options -name lib.logic_model.use_db_rail_names                             -value true
set_app_options -name lib.setting.use_tech_scale_factor                             -value true
set_app_options -name lib.workspace.allow_commit_workspace_overwrite                -value true
set_app_options -name lib.workspace.allow_missing_related_pg_pins                   -value true
set_app_options -name lib.workspace.enable_rc_support                               -value true
set_app_options -name lib.workspace.group_libs_create_slg                           -value false
set_app_options -name lib.workspace.group_libs_macro_grouping_strategy              -value single_cell_per_lib
set_app_options -name lib.workspace.group_libs_naming_strategies                    -value common_prefix
set_app_options -name lib.workspace.remove_frame_bus_properties                     -value true
set_app_options -name lib.workspace.save_design_views                               -value false
set_app_options -name lib.workspace.save_layout_views                               -value false

## Options for RC
set_app_options -name lib.logic_model.align_unspecified_pgpin_direction_with_xtools -value false
set_app_options -name lib.workspace.enable_rc_support                               -value true
set_app_options -name lib.workspace.group_libs_fix_cell_shadowing                   -value false
