##########################################################################################
# File               : user_dont_touch.tcl                                               #
# Description        : Check and set the dont_touch list  in the design.                 #
##########################################################################################


# #------------------------------
# # dont touch cell
# #------------------------------
# set DONT_TOUCH_CELLS ""
#  
# if {[info exists DONT_TOUCH_CELLS] && ($DONT_TOUCH_CELLS != "")} {
#     puts "Information_ADF  :  Setting dont_touch on instances."
#     set get_cells_cmd get_cells
#     foreach cell $DONT_TOUCH_CELLS {
#         if {![string match "*/*" $cell]} {
#             lappend get_cells_cmd "-hier"
#         }
#         set_dont_touch [eval $get_cells_cmd $cell]
#         set get_cells_cmd "get_cells"
#     }
# } else  { puts "Warning_ADF  :  Done touch cell does not exist" }
# #------------------------------
# # dont touch net
# #------------------------------
# set DONT_TOUCH_NETS ""
#  
# if {[info exists DONT_TOUCH_NETS] && $DONT_TOUCH_NETS != ""} {
#     set_dont_touch [get_nets $DONT_TOUCH_NETS] true
# } else  { puts "Warning_ADF  :  Done touch net does not exist" }
#  
# #------------------------------
# # freeze net
# #------------------------------
# 
# set FREEZE_NETS ""
#   
#    
# if {[info exists FREEZE_NETS] && $FREEZE_NETS != ""} {
#     set_attribute [get_nets $FREEZE_NETS] physical_status locked
#     set_dont_touch [get_nets $FREEZE_NETS] true
# } else  { puts "Warning_ADF  :  freeze net does not exist" }
#    
