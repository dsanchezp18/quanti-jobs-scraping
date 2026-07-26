# Cleaning

## Purpose
Construye la muestra analitica a partir de los cortes crudos incluidos en el repositorio.

## Contents
- `01_build_analysis_sample.R`: combina cortes, elimina duplicados y exporta datasets intermedios y finales.

## Naming Convention
Cada script describe una etapa concreta de transformacion desde `data/raw/`.

## Dependencies
Lee archivos de `data/raw/` y escribe a `data/intermediate/` y `data/final/`.
