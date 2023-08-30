*"* use this source file for your ABAP unit test classes
CLASS ltc_easy_toc DEFINITION FOR TESTING  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.

  PRIVATE SECTION.
    METHODS:
      setup,
      _ref_req FOR TESTING,
      _create_with_ref FOR TESTING.


    DATA: mo_cut TYPE REF TO zcl_easy_toc.
ENDCLASS.


CLASS ltc_easy_toc IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( target = 'ABQ.100' ).
  ENDMETHOD.

  METHOD _ref_req.

    DATA(result) = mo_cut->add_reference_request( 'ABDK946369' ).
    result = mo_cut->add_reference_request( 'ABDK946525' ).

  ENDMETHOD.

  METHOD _create_with_ref.

*    mo_cut->add_reference_request( 'ABDK946369' ).
*    mo_cut->add_reference_request( 'ABDK946525' ).
*
*    mo_cut->create_toc( ).
*
*    cl_demo_output=>display( mo_cut->toc_request ).

  ENDMETHOD.

ENDCLASS.
