CLASS zcl_easy_toc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA: toc_target             TYPE tr_target,
          toc_target_sysid       TYPE tmscsys-sysnam,
          toc_author             TYPE tr_as4user,
          toc_text               TYPE as4text,
          toc_request            TYPE trkorr,
          toc_reference_requests TYPE trwbo_request_headers.

    METHODS:

      "! <p class="shorttext synchronized" lang="en">Constructor</p>
      "! @parameter target | Target system
      "! @parameter user | Owner of the ToC
      constructor
        IMPORTING
          target TYPE tr_target
          user   TYPE as4user DEFAULT sy-uname,


      "! <p class="shorttext synchronized" lang="en">Creates an empty Transport of copies</p>
      create_toc
        RETURNING
          VALUE(result) TYPE REF TO zcl_result,

      "! <p class="shorttext synchronized" lang="en">Get info on the request</p>
      "!
      "! @parameter request | <p class="shorttext synchronized" lang="en"></p>
      add_reference_request
        IMPORTING
          reference_request TYPE trkorr
        EXPORTING
          task_list         TYPE trwbo_request_headers
          descr             TYPE as4text
        RETURNING
          VALUE(result)     TYPE REF TO zcl_result,

      "! <p class="shorttext synchronized" lang="en">Release ToC</p>
      "!
      release_toc,

      "! <p class="shorttext synchronized" lang="en">Transport ToC</p>
      "!
      transport_toc.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_easy_toc IMPLEMENTATION.

  METHOD constructor.
    me->toc_target = target.
    me->toc_author = user.
    SPLIT target AT '.' INTO me->toc_target_sysid DATA(dummy).

    SELECT COUNT( * ) FROM tmscsys INTO @DATA(l_cnt)
      WHERE sysnam = @me->toc_target_sysid.
    IF l_cnt = 0.
      RAISE EXCEPTION TYPE lcx_target_system_invalid.
    ENDIF.

  ENDMETHOD.

  METHOD create_toc.

    TYPES: t_docu TYPE STANDARD TABLE OF tline WITH DEFAULT KEY.

    DATA: l_es_msg(200)      TYPE c,
          l_ev_exception(50) TYPE c.

    IF lines( me->toc_reference_requests ) = 0.
      RAISE EXCEPTION TYPE lcx_no_reference_requests
        MESSAGE e368(00) WITH 'No reference requests assigned'.
      EXIT.
    ENDIF.

    me->toc_text = |ToC-{ me->toc_reference_requests[ 1 ]-as4text }|.
    CALL FUNCTION 'TR_EXT_CREATE_REQUEST'
      EXPORTING
        iv_request_type = 'T'
        iv_target       = me->toc_target
        iv_author       = me->toc_author
        iv_text         = me->toc_text
      IMPORTING
        es_req_id       = me->toc_request
        es_msg          = l_es_msg
        ev_exception    = l_ev_exception.

    IF sy-subrc = 0.
      result = zcl_result=>ok( |ToC created correctly { me->toc_request }| ).
    ELSE.
      result = zcl_result=>fail( |Error when creating the request SUBRC { sy-subrc }| ).
    ENDIF.

    LOOP AT me->toc_reference_requests INTO DATA(l_ref).

      CALL FUNCTION 'TR_COPY_COMM'
        EXPORTING
*         wi_dialog                = ' '
          wi_trkorr_from           = l_ref-trkorr
          wi_trkorr_to             = me->toc_request
          wi_without_documentation = 'X'
        EXCEPTIONS
          db_access_error          = 1
          trkorr_from_not_exist    = 2
          trkorr_to_is_repair      = 3
          trkorr_to_locked         = 4
          trkorr_to_not_exist      = 5
          trkorr_to_released       = 6
          user_not_owner           = 7
          no_authorization         = 8
          wrong_client             = 9
          wrong_category           = 10
          object_not_patchable     = 11
          OTHERS                   = 12.

    ENDLOOP.

    DATA(title) = VALUE t_docu( ( tdformat = '/' tdline = 'Requests in this ToC' ) ).

    DATA(i_docu) = VALUE t_docu( BASE title
                                FOR req IN me->toc_reference_requests ( tdformat = '/' tdline = req-trkorr ) ).

    CALL FUNCTION 'TRINT_DOCU_INTERFACE'
      EXPORTING
        iv_action           = 'M'
        iv_modify_appending = ' '
        iv_object           = me->toc_request
      TABLES
        tt_line             = i_docu
      EXCEPTIONS
        OTHERS              = 1.

  ENDMETHOD.

  METHOD add_reference_request.

    DATA: l_request_headers TYPE trwbo_request_headers,
          l_requests        TYPE trwbo_requests.

    CALL FUNCTION 'TR_READ_REQUEST_WITH_TASKS'
      EXPORTING
        iv_trkorr          = reference_request
      IMPORTING
        et_request_headers = l_request_headers
        et_requests        = l_requests
      EXCEPTIONS
        invalid_input      = 1
        OTHERS             = 2.
    IF sy-subrc = 0.
      result = zcl_result=>ok( |Request { reference_request } added as reference| ).
    ELSE.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      result = zcl_result=>fail( |Request { reference_request } cannot be added SUBRC { sy-subrc } | ).
    ENDIF.

    me->toc_reference_requests = CORRESPONDING #( BASE ( me->toc_reference_requests ) l_request_headers ).

    result = zcl_result=>ok( |Just adding another text...| ).

  ENDMETHOD.


  METHOD release_toc.

    DATA: g_request       TYPE trwbo_request,
          g_deleted_tasks TYPE trwbo_t_e070,
          g_messages      TYPE ctsgerrmsgs.

    CALL FUNCTION 'TRINT_RELEASE_REQUEST'
      EXPORTING
        iv_trkorr                   = me->toc_request
        iv_dialog                   = ' '
        iv_without_locking          = 'X'
      IMPORTING
        es_request                  = g_request
        et_deleted_tasks            = g_deleted_tasks
        et_messages                 = g_messages
      EXCEPTIONS
        cts_initialization_failure  = 1
        enqueue_failed              = 2
        no_authorization            = 3
        invalid_request             = 4
        request_already_released    = 5
        repeat_too_early            = 6
        object_lock_error           = 7
        object_check_error          = 8
        docu_missing                = 9
        db_access_error             = 10
        action_aborted_by_user      = 11
        export_failed               = 12
        execute_objects_check       = 13
        release_in_bg_mode          = 14
        release_in_bg_mode_w_objchk = 15
        error_in_export_methods     = 16
        object_lang_error           = 17
        OTHERS                      = 18.

    IF sy-subrc <> 0.
      WRITE: 'Release Return code', sy-subrc, sy-msgv1.
    ENDIF.

  ENDMETHOD.

  METHOD transport_toc.

    DATA: lv_trretcode     TYPE trretcode,
          l_imp_exceptions TYPE stmscalert.

    CALL FUNCTION 'TMS_MGR_IMPORT_TR_REQUEST'
      EXPORTING
        iv_system                  = 'ABQ'
        iv_request                 = me->toc_request
        iv_ignore_cvers            = 'X'
        iv_monitor                 = 'X'
        iv_verbose                 = 'X'
      IMPORTING
        ev_tp_ret_code             = lv_trretcode
        es_exception               = l_imp_exceptions
      EXCEPTIONS
        read_config_failed         = 1
        table_of_requests_is_empty = 2
        OTHERS                     = 3.

  ENDMETHOD.

ENDCLASS.
