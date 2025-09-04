
REPORT zparallel_mdsr_api_demo.

DATA(lo_api) = NEW zcl_parallel_mdsr_api( iv_max_tasks = 5 ).

DATA(lt_input) = VALUE zcl_parallel_mdsr_api=>tt_input(
  ( matnr = 'MAT1' werks = '1000' )
  ( matnr = 'MAT2' werks = '1000' )
  ( matnr = 'MAT3' werks = '2000' )
  ( matnr = 'MAT4' werks = '3000' )
  ( matnr = ''     werks = '4000' ) " Entrada inválida
).

DATA: lt_result TYPE zcl_parallel_mdsr_api=>tt_result,
      lt_errors TYPE zcl_parallel_mdsr_api=>tt_error.

CALL METHOD lo_api->get_stock_requirements_parallel
  EXPORTING
    it_input = lt_input
  IMPORTING
    rt_result = lt_result
    rt_errors = lt_errors.

WRITE: / '--- Resultados ---'.
LOOP AT lt_result INTO DATA(ls_result).
  WRITE: / 'Material:', ls_result-material,
         'Centro:', ls_result-plant,
         'Tipo:', ls_result-req_type,
         'Cantidad:', ls_result-quantity.
ENDLOOP.

WRITE: / '--- Errores ---'.
LOOP AT lt_errors INTO DATA(lv_error).
  WRITE: / lv_error.
ENDLOOP.
