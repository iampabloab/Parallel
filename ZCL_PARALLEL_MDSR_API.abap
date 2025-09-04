
CLASS zcl_parallel_mdsr_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_input,
             matnr TYPE matnr,
             werks TYPE werks_d,
           END OF ty_input,
           tt_input TYPE STANDARD TABLE OF ty_input WITH EMPTY KEY,
           tt_result TYPE STANDARD TABLE OF bapi_mdsr_list WITH EMPTY KEY,
           tt_error TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    METHODS:
      constructor
        IMPORTING iv_max_tasks TYPE i DEFAULT 5,

      get_stock_requirements_parallel
        IMPORTING it_input TYPE tt_input
        RETURNING VALUE(rt_result) TYPE tt_result
        RETURNING VALUE(rt_errors) TYPE tt_error.

  PRIVATE SECTION.
    DATA: mv_max_tasks TYPE i,
          mt_active_tasks TYPE TABLE OF string,
          mt_result TYPE tt_result,
          mt_errors TYPE tt_error.

    METHODS:
      start_task
        IMPORTING is_input TYPE ty_input
                  iv_taskname TYPE string,

      callback_form
        IMPORTING p_task TYPE any.
ENDCLASS.

CLASS zcl_parallel_mdsr_api IMPLEMENTATION.

  METHOD constructor.
    mv_max_tasks = iv_max_tasks.
  ENDMETHOD.

  METHOD get_stock_requirements_parallel.
    DATA: lv_taskname TYPE string,
          lv_index TYPE i VALUE 0.

    CLEAR: mt_result, mt_active_tasks, mt_errors.

    LOOP AT it_input INTO DATA(ls_input).
      IF ls_input-matnr IS INITIAL OR ls_input-werks IS INITIAL.
        APPEND |Entrada inválida: MATNR={ ls_input-matnr }, WERKS={ ls_input-werks }| TO mt_errors.
        CONTINUE.
      ENDIF.

      WHILE lines( mt_active_tasks ) >= mv_max_tasks.
        WAIT UP TO 1 SECONDS.
      ENDWHILE.

      lv_index = lv_index + 1.
      lv_taskname = |TASK_{ lv_index }|.

      start_task(
        is_input = ls_input
        iv_taskname = lv_taskname
      ).

      APPEND lv_taskname TO mt_active_tasks.
    ENDLOOP.

    WHILE lines( mt_active_tasks ) > 0.
      WAIT UP TO 1 SECONDS.
    ENDWHILE.

    rt_result = mt_result.
    rt_errors = mt_errors.
  ENDMETHOD.

  METHOD start_task.
    CALL FUNCTION 'MD_STOCK_REQUIREMENTS_LIST_API'
      STARTING NEW TASK iv_taskname
      calling callback_form ON END OF TASK
      EXPORTING
        material = is_input-matnr
        plant    = is_input-werks
      EXCEPTIONS
        communication_failure = 1
        system_failure        = 2
        OTHERS                = 3.

    IF sy-subrc <> 0.
      APPEND |Error al iniciar tarea { iv_taskname } para MATNR={ is_input-matnr }, WERKS={ is_input-werks }| TO mt_errors.
      DELETE mt_active_tasks WHERE table_line = iv_taskname.
    ENDIF.
  ENDMETHOD.

  METHOD callback_form.
    DATA: lt_result TYPE tt_result.

    RECEIVE RESULTS FROM FUNCTION 'MD_STOCK_REQUIREMENTS_LIST_API'
      IMPORTING
        stock_requirements_list = lt_result
      EXCEPTIONS
        communication_failure = 1
        system_failure        = 2
        OTHERS = 3.

    IF sy-subrc <> 0.
      APPEND |Error al recibir resultados de tarea { p_task }| TO mt_errors.
    ELSE.
      APPEND LINES OF lt_result TO mt_result.
    ENDIF.

    DELETE mt_active_tasks WHERE table_line = p_task.
  ENDMETHOD.

ENDCLASS.
