##########################################################################################
# File               : user_dont_use.tcl                                                 # 
# Description        : Check and set the dont_use list in the design.                    #
##########################################################################################

# ##- Dont use    ----------------------------------------------------------------------------------#                        
# set DONT_USE_LIST        [list   FRICG*     \
#                                  DLY*       \
#                                  SDFFYQ*    \
#                                  A*TSL_*    \
#                                  B*TSL_*    \
#                                  C*TSL_*    \
#                                  D*TSL_*    \
#                                  F*TSL_*    \
#                                  I*TSL_*    \
#                                  L*TSL_*    \
#                                  M*TSL_*    \
#                                  N*TSL_*    \
#                                  O*TSL_*    \
#                                  POST*TSL_* \
#                                  S*TSL_*    \
#                                  T*TSL_*    \
#                                  X*TSL_*    \
#                                  SDFFYRPQ*  \
#                                  *_X0*      \
#                                  *_X16*     \
#                                  *_X20*     \
#                                  *_X24*     \
#                                  *_X28*     \
#                                  *_X32*     \
#                                  *TIEHI_*   \
#                                  *TIELO_*]
# 
# if {$DONT_USE_LIST != ""} {
#     set dont_use_list [list ]
#  
#     foreach dont_use $DONT_USE_LIST {
#         set dont_use_list [concat $dont_use_list */${dont_use}]
#     }
#  
#     set_lib_cell_purpose -exclude {power optimization} [get_lib_cells $dont_use_list]
#     puts "Information_ADF : dont_use  $dont_use_list "
#  
# } else { puts  "Warning_ADF : The  do use list does not exist. " }
# 
# ##- Do use     ----------------------------------------------------------------------------------#                        
# 
# set DO_USE    [list  ]
# 
# foreach dousecelltype $DO_USE {
#      puts "remove_attribute [get_object_name [get_lib_cells  */${dousecelltype}]] dont_use"
#       remove_attribute [get_lib_cells */${dousecelltype}] dont_use
#       set_lib_cell_purpose -include {power optimization} [get_lib_cells */${dousecelltype}]
#      unset dousecelltype         
# }                               
