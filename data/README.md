# Data

## Purpose
Agrupa los archivos de entrada y los datasets construidos durante el flujo analitico.

## Contents
- `raw/`: cortes originales incluidos en el repo.
- `intermediate/`: objetos temporales de trabajo.
- `final/`: datasets listos para el analisis.

## Naming Convention
Los nombres distinguen claramente entre cortes originales, objetos intermedios y salidas finales.

## Dependencies
`raw/` alimenta los scripts de `code/cleaning/`, que a su vez escriben en `intermediate/` y `final/`.
