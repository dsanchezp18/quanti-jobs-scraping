# ============================================================
# Build analysis sample
# Author: Daniel Sanchez
# Purpose: Acumular los cortes de junio y julio, eliminar duplicados y
#          exportar la muestra analitica y la submuestra con habilidades.
# Inputs:  data/raw/ofertas_2026-06-*.csv, data/raw/ofertas_2026-07-*.csv
# Outputs: data/intermediate/ofertas_unicas.rds,
#          data/final/ofertas_universo_analitico.csv,
#          data/final/ofertas_con_habilidades.csv,
#          outputs/tables/embudo_muestra.csv,
#          outputs/tables/cortes_acumulados.csv
# ============================================================

# 0. Setup ----
library(dplyr)
library(readr)
library(stringr)
library(tibble)

# set.seed(42)

raw_dir <- file.path("data", "raw")
intermediate_dir <- file.path("data", "intermediate")
final_dir <- file.path("data", "final")
tables_dir <- file.path("outputs", "tables")

cut_pattern <- "^ofertas_2026-(06|07)-[0-9]{2}\\.csv$"
cut_date_pattern <- "2026-[0-9]{2}-[0-9]{2}"

dir.create(intermediate_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(final_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Load Data ----
raw_files <- list.files(
  path = raw_dir,
  pattern = cut_pattern,
  full.names = TRUE
)

if (length(raw_files) == 0) {
  stop("No se encontraron archivos de cortes de junio o julio en data/raw.")
}

raw_files <- sort(raw_files)

# Todos los cortes comparten el mismo esquema, asi que readr los apila directamente.
ofertas_brutas <- read_csv(
  raw_files,
  col_types = cols(.default = "c"),
  id = "cut_path"
) |>
  mutate(
    cut_file = basename(cut_path),
    cut_date = str_extract(cut_file, cut_date_pattern)
  ) |>
  select(-cut_path)

cortes_acumulados <- ofertas_brutas |>
  count(cut_date, cut_file, name = "n_registros") |>
  arrange(cut_date, cut_file)

n_bruto <- nrow(ofertas_brutas)

# 2. Clean / Transform ----
ofertas_unicas <- ofertas_brutas |>
  mutate(description_length = str_length(coalesce(description, ""))) |>
  arrange(source, job_id, desc(cut_date), desc(description_length)) |>
  group_by(source, job_id) |>
  slice(1) |>
  ungroup() |>
  select(-description_length)

n_unicas <- nrow(ofertas_unicas)

ofertas_universo <- ofertas_unicas |>
  filter(in_universe == "TRUE")

n_universo <- nrow(ofertas_universo)

ofertas_con_habilidades <- ofertas_universo |>
  filter(!is.na(skills), skills != "")

n_con_habilidades <- nrow(ofertas_con_habilidades)

embudo_muestra <- tibble(
  etapa = factor(
    c("Registros brutos", "Ofertas unicas", "Universo analitico", "Con habilidades declaradas"),
    levels = c("Registros brutos", "Ofertas unicas", "Universo analitico", "Con habilidades declaradas")
  ),
  n = c(n_bruto, n_unicas, n_universo, n_con_habilidades)
)

# 3. Analysis ----
# Esta etapa solo deja listas las muestras para los scripts de analisis.

# 4. Export ----
saveRDS(ofertas_unicas, file.path(intermediate_dir, "ofertas_unicas.rds"))
write_csv(ofertas_universo, file.path(final_dir, "ofertas_universo_analitico.csv"))
write_csv(ofertas_con_habilidades, file.path(final_dir, "ofertas_con_habilidades.csv"))
write_csv(embudo_muestra, file.path(tables_dir, "embudo_muestra.csv"))
write_csv(cortes_acumulados, file.path(tables_dir, "cortes_acumulados.csv"))

message("Muestra analitica construida: ", n_con_habilidades, " ofertas con habilidades.")

sessionInfo()
