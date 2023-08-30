*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lcx_no_reference_requests DEFINITION INHERITING FROM cx_dynamic_check.
  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.
    ALIASES msgty FOR if_t100_dyn_msg~msgty.
ENDCLASS.

CLASS lcx_target_system_invalid DEFINITION INHERITING FROM cx_dynamic_check.
  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.
    ALIASES msgty FOR if_t100_dyn_msg~msgty.
ENDCLASS.
