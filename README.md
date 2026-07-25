# quanti-jobs-scraping

Analisis reproducible en R de las herramientas y competencias tecnicas mas solicitadas en ofertas laborales de datos en Ecuador.

Este repositorio parte de dos cortes de ofertas ya recolectados publicamente en Multitrabajos, Computrabajo y Mipleo (17 de junio y 16 de julio de 2026). Contiene el dataset resultante y el codigo de analisis, no el codigo de recoleccion. La metodologia de scraping se documenta por separado y todavia no se hace publica.

## Estructura

```text
.
├── data/
│   └── raw/
│       ├── ofertas_2026-06-17.csv
│       └── ofertas_2026-07-16.csv
├── outputs/
│   ├── figures/
│   └── tables/
├── scripts/
│   └── 01_analisis_mercado_datos.R
└── README.md
```

## Que hace el script

`scripts/01_analisis_mercado_datos.R`:

1. Combina los dos cortes y elimina duplicados por oferta, conservando la version con la descripcion mas completa.
2. Filtra al universo analitico (ofertas de datos y tecnologia clasificadas por el pipeline de recoleccion).
3. Calcula la frecuencia de herramientas (Excel, Power BI, SQL, SAP, Python) y de competencias tecnicas (KPIs, bases de datos, ERP, dashboards, business intelligence) entre las ofertas con habilidades declaradas.
4. Calcula combinaciones de herramientas (Excel + Power BI + SQL).
5. Exporta figuras a `outputs/figures/`, tablas a `outputs/tables/` y un resumen a `outputs/mercado_datos_resumen.rds`.

## Como correrlo

```r
source("scripts/01_analisis_mercado_datos.R")
```

## Dataset

Cada fila es una oferta laboral publica clasificada como perteneciente o no al universo de roles de datos y tecnologia en Ecuador. Las columnas relevantes para este analisis son `source`, `job_id`, `in_universe`, `job_family`, `skills`, `description` y `scraped_at`. El dataset no incluye informacion identificable de postulantes.

## Articulo relacionado

Este analisis sustenta la version tecnica publicada en [El Quantificador](https://elquantificador.blog/) sobre las herramientas que piden los empleadores ecuatorianos en el mercado de datos.
