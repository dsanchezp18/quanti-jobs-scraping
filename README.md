# Mercado laboral de datos en Ecuador: habilidades y herramientas demandadas

## Overview

Analisis reproducible en R del mercado laboral de datos en Ecuador, con foco en las herramientas y competencias tecnicas que aparecen en ofertas publicas de empleo.

Este repositorio usa cortes acumulados de ofertas laborales publicas en Multitrabajos, Computrabajo y Mipleo, tomados entre el 17 de junio y el 26 de julio de 2026. Contiene el dataset de entrada para el analisis, el codigo para construir la muestra analitica y las salidas que alimentan un articulo tecnico de El Quantificador. No publica el codigo de scraping ni su metodologia detallada.

## How to Replicate

1. Abre el proyecto desde la raiz del repositorio.
2. Verifica que tengas instalados `dplyr`, `ggplot2`, `readr`, `scales`, `stringr` y `tidyr`.
3. Corre `source("MASTER.R")`.

`MASTER.R` acumula los cortes disponibles de junio y julio, construye la muestra analitica y luego exporta tablas, figuras y un resumen serializado.

## Project Structure

```text
.
├── MASTER.R
├── borrador_articulo_quantificador.md
├── code/
│   ├── cleaning/
│   └── analysis/
├── data/
│   ├── raw/
│   ├── intermediate/
│   └── final/
├── outputs/
│   ├── figures/
│   └── tables/
└── documentation/
    └── archive/
```

## Data Access

Los insumos provienen de un pipeline de recoleccion separado que consolida ofertas laborales publicas para roles de datos y tecnologia en Ecuador. La capa de scraping se documenta por separado y por ahora no se transparenta en este repositorio.

Los archivos de entrada que si se incluyen aqui son:

- `data/raw/ofertas_2026-06-17.csv`
- `data/raw/ofertas_2026-07-16.csv`
- `data/raw/ofertas_2026-07-26.csv`

## Current Analytical Scope

El flujo actual:

1. acumula todos los cortes disponibles de junio y julio;
2. elimina duplicados por `source` y `job_id`, conservando la observacion mas reciente y con descripcion mas completa;
3. filtra al universo analitico marcado por el pipeline de recoleccion;
4. construye una submuestra con ofertas que declaran habilidades;
5. calcula herramientas, competencias tecnicas, combinaciones y composicion ocupacional.

Las cifras se regeneran cada vez que se ejecuta `MASTER.R`, por lo que los totales dependen de los cortes acumulados presentes en `data/raw/`.

## Outputs

Las principales salidas actuales son:

- figuras en `outputs/figures/`;
- tablas en `outputs/tables/`;
- un resumen serializado en `outputs/mercado_datos_resumen.rds`.

## Article Draft

La version lista para El Quantificador vive en `final_version/`, siguiendo el formato de los repositorios de articulos de la publicacion:

```text
final_version/
├── index.Rmd
└── images/grafico1..4.png
```

`index.Rmd` es la fuente del articulo. Las figuras de `final_version/images/` las copia el script de analisis desde `outputs/figures/`, asi que no se editan a mano. Para previsualizar:

```bash
quarto render final_version/index.Rmd --to html --embed-resources
```

El HTML resultante es un artefacto de compilacion: se regenera cuando haga falta y no se versiona.

`borrador_articulo_quantificador.md` es el borrador previo a la conversion al formato de la publicacion. Las versiones anteriores se guardan en `documentation/archive/`.

## Article Status

Este repositorio ya deja lista la base reproducible del analisis. El siguiente paso es refrescar el borrador del articulo con las nuevas cifras acumuladas de junio y julio, manteniendo el foco en lo que el mercado realmente pide en las vacantes publicas.
