CLASS zcl_parallel_stock_req_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS: run_test.
ENDCLASS.

CLASS zcl_parallel_stock_req_test IMPLEMENTATION.

  METHOD run_test.
    DATA(lo_stock) = NEW zcl_parallel_stock_req( ).

    lo_stock->set_max_parallel_tasks( iv_max = 5 ).

    DATA(lt_matwerks) = VALUE zcl_parallel_stock_req=>tt_matwerks(
      ( matnr = 'MAT1' werks = '1000' )
      ( matnr = 'MAT2' werks = '2000' )
      ( matnr = 'MAT3' werks = '3000' )
      ( matnr = 'MAT4' werks = '4000' )
      ( matnr = 'MAT5' werks = '5000' )
      ( matnr = 'MAT6' werks = '6000' )
    ).

    lo_stock->execute_parallel( lt_matwerks ).

    DATA(lt_results) = lo_stock->get_results( ).
    DATA(lt_errors)  = lo_stock->get_errors( ).

    LOOP AT lt_results INTO DATA(ls_result).
      WRITE: / 'Resultado:', ls_result-matnr, ls_result-werks.
    ENDLOOP.

    LOOP AT lt_errors INTO DATA(ls_error).
      WRITE: / 'Error:', ls_error-taskname, ls_error-matnr, ls_error-werks, ls_error-error_type, ls_error-message.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
