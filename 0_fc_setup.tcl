###################################################################################################
# File               : 0_fc_setup.tcl                                                             #
# Author             : ADT-DT (jblee)                                                             #
# Description        : fc option list                                                             #
# Usage              :                                                                            #
# Init Release Date  : 2025.08.27                                                                 #
# Script Version     : 1.1                                                                        #
# Revision History   :                                                                            #
#         2025.08.14 - first released                                                             #
#         2025.08.27 - Move define_name_rules to TOOLS                                            #
###################################################################################################

#######################################################################################################
#  CPU
#######################################################################################################
# CPU Setup
set_app_options -as_user_default -name shell.common.monitor_cpu_memory -value true

if { ${NUM_CPUS} == "" || ${NUM_CPUS} > 16 } { set NUM_CPUS "16" }
set_host_options -max_cores ${NUM_CPUS}
report_host_options


#######################################################################################################
# Handling message
#######################################################################################################
# Avoiding too many messages
set_message_info -id ATTR-11          -limit 20
set_message_info -id ATTR-12          -limit 20
set_message_info -id OPT-008          -limit 20
set_message_info -id ZRT-030          -limit 20
set_message_info -id ZRT-083          -limit 20
set_message_info -id ZRT-061          -limit 20

# connon_pg_net
set_message_info -id NDM-041          -limit 20
set_message_info -id NDM-042          -limit 20
set_message_info -id NDM-043          -limit 20
set_message_info -id NDM-044          -limit 20
set_message_info -id NDM-060          -limit 20
set_message_info -id MV-203           -limit 20


#######################################################################################################
#  Common env & app option
#######################################################################################################
# To prevent run interrupted
set sh_continue_on_error true

# set old date for backup
set old [sh date +%m%d_%H:%M:%S]

# set temp dir for environment setup
setenv TMPDIR ${RUN_DIR}/TMP

# qor_data option
set_qor_data_options -output ${REPORT_DIR}/qor_data -label_order "synthesis to_initial_opto to_final_opto"

# To ensure repeatability
set_app_options -name shell.common.enable_deterministic_mode -value true

# Specifies whether the new library is saved to the disk or memory during the execution of the create_lib command.
set_app_options -name lib.setting.on_disk_operation -value true

# Check for latches in RTL - add jmpark
set_app_options -name hdlin.report.check_no_latch -value true

# Change the limit of file size for using nxtgrd instead of tlup
set_app_options -name file.tlup.max_preservation_size -value 150

#******************************************************************************
# hdl naming rule
#******************************************************************************
set_app_options -name hdlin.naming.shorten_long_module_name -value true
set_app_options -name hdlin.naming.module_name_limit -value 100
set_app_options -name hdlin.naming.template_naming_style -value "%s"
set_app_options -name hdlin.naming.template_parameter_style -value ""

#******************************************************************************
# Useful Option (Global Scope)
#******************************************************************************
# Sets the maximum number of objects that can be displayed by any command that displays a collection
set_app_options -name shell.common.collection_result_display_limit -value 40

# report_default_significant_digits
set_app_options -name shell.common.report_default_significant_digits -value 4

# Controls whether long reports are displayed one page at a time
set sh_enable_page_mode false
