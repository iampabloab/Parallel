CLASS zcl_parallel_stock_req DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_matwerks,
             matnr TYPE matnr,
             werks TYPE werks_d,
           END OF ty_matwerks,
           tt_matwerks TYPE STANDARD TABLE OF ty_matwerks WITH EMPTY KEY,
           tt_results TYPE STANDARD TABLE OF bapi_mds_resb WITH EMPTY KEY,
           BEGIN OF ty_error,
             taskname TYPE string,
             matnr    TYPE matnr,
             werks    TYPE werks_d,
             error_type TYPE string,
             message  TYPE string,
           END OF ty_error,
           tt_errors TYPE STANDARD TABLE OF ty_error WITH EMPTY KEY.

    METHODS:
      execute_parallel
        IMPORTING it_matwerks TYPE tt_matwerks,
      get_results
        RETURNING VALUE(rt_results) TYPE tt_results,
      get_errors
        RETURNING VALUE(rt_errors) TYPE tt_errors,
      set_max_parallel_tasks
        IMPORTING iv_max TYPE i.

  PRIVATE SECTION.
    DATA: mt_results TYPE tt_results,
          mt_errors  TYPE tt_errors,
          mv_tasks_done TYPE i,
          mt_matwerks TYPE tt_matwerks,
          mv_max_parallel_tasks TYPE i VALUE 10.

    METHODS:
      call_bapi_parallel
        IMPORTING is_matwerks TYPE ty_matwerks
                    iv_taskname TYPE string,
      receive_result
        USING iv_taskname TYPE string.
ENDCLASS.

CLASS zcl_parallel_stock_req IMPLEMENTATION.

  METHOD execute_parallel.
    CLEAR: mt_results, mt_errors, mv_tasks_done.
    mt_matwerks = it_matwerks.

    DATA: lv_index TYPE i VALUE 0,
          lv_taskname TYPE string,
          lv_active_tasks TYPE i VALUE 0.

    LOOP AT it_matwerks INTO DATA(ls_matwerks).
      WHILE lv_active_tasks >= mv_max_parallel_tasks.
        WAIT UP TO 1 SECONDS.
        lv_active_tasks = lines( it_matwerks ) - mv_tasks_done.
      ENDWHILE.

      ADD 1 TO lv_index.
      CONCATENATE 'TASK_' lv_index INTO lv_taskname.

      call_bapi_parallel(
        EXPORTING
          is_matwerks = ls_matwerks
          iv_taskname = lv_taskname
      ).

      lv_active_tasks = lv_active_tasks + 1.
    ENDLOOP.

    WHILE mv_tasks_done < lines( it_matwerks ).
      WAIT UP TO 1 SECONDS.
    ENDWHILE.
  ENDMETHOD.

  METHOD call_bapi_parallel.
    CALL FUNCTION 'MD_STOCK_REQUIREMENTS_LIST_API'
      STARTING NEW TASK iv_taskname
      DESTINATION 'NONE'
      PERFORMING receive_result ON END OF TASK
      EXPORTING
        matnr = is_matwerks-matnr
        werks = is_matwerks-werks
      EXCEPTIONS
        communication_failure = 1
        system_failure        = 2
        OTHERS                = 3.

    IF sy-subrc <> 0.
      APPEND VALUE ty_error(
        taskname = iv_taskname
        matnr    = is_matwerks-matnr
        werks    = is_matwerks-werks
        error_type = SWITCH string( sy-subrc
                      WHEN 1 THEN 'COMMUNICATION_FAILURE'
                      WHEN 2 THEN 'SYSTEM_FAILURE'
                      ELSE 'UNKNOWN_ERROR' )
        message  = 'Error al iniciar tarea RFC'
      ) TO mt_errors.

      ADD 1 TO mv_tasks_done.
    ENDIF.
  ENDMETHOD.

  METHOD receive_result.
    DATA: lt_result TYPE tt_results.
    DATA(ls_matwerks) = VALUE ty_matwerks( ).

    RECEIVE RESULTS FROM FUNCTION 'MD_STOCK_REQUIREMENTS_LIST_API'
      IMPORTING
        et_result = lt_result
      EXCEPTIONS
        communication_failure = 1
        system_failure        = 2
        OTHERS                = 3.

    READ TABLE mt_matwerks INDEX mv_tasks_done + 1 INTO ls_matwerks.

    IF sy-subrc = 0 AND sy-subrc <= 3.
      CASE sy-subrc.
        WHEN 0.
          APPEND LINES OF lt_result TO mt_results.
        WHEN 1 OR 2 OR 3.
          APPEND VALUE ty_error(
            taskname = iv_taskname
            matnr    = ls_matwerks-matnr
            werks    = ls_matwerks-werks
            error_type = SWITCH string( sy-subrc
                          WHEN 1 THEN 'COMMUNICATION_FAILURE'
                          WHEN 2 THEN 'SYSTEM_FAILURE'
                          ELSE 'UNKNOWN_ERROR' )
            message  = 'Error al recibir resultados'
          ) TO mt_errors.
      ENDCASE.
    ENDIF.

    ADD 1 TO mv_tasks_done.
  ENDMETHOD.

  METHOD get_results.
    rt_results = mt_results.
  ENDMETHOD.

  METHOD get_errors.
    rt_errors = mt_errors.
  ENDMETHOD.

  METHOD set_max_parallel_tasks.
    mv_max_parallel_tasks = iv_max.
  ENDMETHOD.

ENDCLASS.
