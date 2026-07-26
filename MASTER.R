# ============================================================
# Quanti jobs scraping master script
# Author: Daniel Sanchez
# Purpose: Ejecutar el flujo completo del analisis reproducible del
#          mercado laboral de datos en Ecuador.
# Inputs:  data/raw/ofertas_2026-06-17.csv, data/raw/ofertas_2026-07-16.csv
# Outputs: data/intermediate/*.rds, data/final/*.csv, outputs/*
# ============================================================

# 0. Setup ----
source(file.path("code", "cleaning", "01_build_analysis_sample.R"))
source(file.path("code", "analysis", "01_market_tools_outputs.R"))
