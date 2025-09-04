# Z_PARALLEL_STOCK_REQ

## Descripción

Este paquete contiene la clase `ZCL_PARALLEL_STOCK_REQ` que permite ejecutar la BAPI `MD_STOCK_REQUIREMENTS_LIST_API` en paralelo para múltiples combinaciones de materiales y centros, con manejo avanzado de errores y control de concurrencia.

## Componentes

- `ZCL_PARALLEL_STOCK_REQ`: Clase principal con lógica de ejecución paralela.
- `ZCL_PARALLEL_STOCK_REQ_TEST`: Clase de prueba con ejemplo de uso.
- `README.md`: Documentación técnica.

## Uso

1. Configura el número máximo de tareas paralelas con `SET_MAX_PARALLEL_TASKS`.
2. Ejecuta la consulta con `EXECUTE_PARALLEL`.
3. Obtén resultados con `GET_RESULTS` y errores con `GET_ERRORS`.

## Importación

Este paquete está preparado para ser importado offline en abapGit.
