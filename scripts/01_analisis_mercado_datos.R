# ============================================================
# Mercado laboral de datos en Ecuador: herramientas y competencias
# Author: Daniel Sanchez
# Purpose: Reproducir, a partir de dos cortes de ofertas laborales ya
#          recolectadas, el analisis de herramientas y competencias
#          tecnicas mas solicitadas en vacantes de datos en Ecuador.
# Inputs:  data/raw/ofertas_2026-06-17.csv, data/raw/ofertas_2026-07-16.csv
# Outputs: outputs/figures/*.png, outputs/tables/*.csv,
#          outputs/mercado_datos_resumen.rds
# ============================================================

library(dplyr)
library(readr)
library(stringr)
library(tidyr)
library(ggplot2)
library(scales)

# set.seed(42)

# 0. Setup ----

raw_dir     <- file.path("data", "raw")
figures_dir <- file.path("outputs", "figures")
tables_dir  <- file.path("outputs", "tables")
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

fig_width  <- 8
fig_height <- 5

quanti_blue <- "#1B4F72"
quanti_mid  <- "#2980B9"
quanti_gray <- "#5D6D7E"

herramientas_foco <- c("Excel", "Power BI", "SQL", "SAP", "Python")

competencias_foco <- c("KPIs", "Bases de Datos", "ERP", "Dashboards", "Business Intelligence")

skill_recode <- c(
  "Sql" = "SQL", "Power Bi" = "Power BI", "Kpis" = "KPIs",
  "Erp" = "ERP", "Bi" = "BI", "Sap" = "SAP",
  "Bases De Datos" = "Bases de Datos",
  "Business Intelligence" = "Business Intelligence"
)

# 1. Load Data ----

ofertas_jun <- read_csv(
  file.path(raw_dir, "ofertas_2026-06-17.csv"),
  col_types = cols(.default = "c")
)

ofertas_jul <- read_csv(
  file.path(raw_dir, "ofertas_2026-07-16.csv"),
  col_types = cols(.default = "c")
)

n_corte_jun <- nrow(ofertas_jun)
n_corte_jul <- nrow(ofertas_jul)
n_bruto     <- n_corte_jun + n_corte_jul

# 2. Clean / Transform ----

ofertas_unicas <- bind_rows(ofertas_jun, ofertas_jul) |>
  group_by(source, job_id) |>
  slice_max(nchar(coalesce(description, "")), n = 1, with_ties = FALSE) |>
  ungroup()

n_unicas <- nrow(ofertas_unicas)

ofertas_universo <- ofertas_unicas |>
  filter(in_universe == "TRUE")

n_universo <- nrow(ofertas_universo)

ofertas_con_habilidades <- ofertas_universo |>
  filter(!is.na(skills), skills != "")

n_con_habilidades <- nrow(ofertas_con_habilidades)

habilidades_largo <- ofertas_con_habilidades |>
  select(source, job_id, job_family, skills) |>
  mutate(skill_list = str_split(skills, ";\\s*")) |>
  unnest(skill_list) |>
  mutate(
    skill = str_squish(skill_list),
    skill = str_to_title(skill),
    skill = recode(skill, !!!skill_recode)
  ) |>
  filter(skill != "") |>
  distinct(source, job_id, job_family, skill)

# 3. Analysis ----

conteo_herramientas <- habilidades_largo |>
  filter(skill %in% herramientas_foco) |>
  count(skill, name = "n_ofertas") |>
  mutate(
    porcentaje = n_ofertas / n_con_habilidades,
    skill = factor(skill, levels = herramientas_foco)
  ) |>
  arrange(skill)

conteo_competencias <- habilidades_largo |>
  filter(skill %in% competencias_foco) |>
  count(skill, name = "n_ofertas") |>
  mutate(
    porcentaje = n_ofertas / n_con_habilidades,
    skill = factor(skill, levels = competencias_foco)
  ) |>
  arrange(skill)

excel_ids <- habilidades_largo |>
  filter(skill == "Excel") |>
  transmute(job_key = paste(source, job_id, sep = "::")) |>
  distinct() |>
  pull(job_key)

powerbi_ids <- habilidades_largo |>
  filter(skill == "Power BI") |>
  transmute(job_key = paste(source, job_id, sep = "::")) |>
  distinct() |>
  pull(job_key)

sql_ids <- habilidades_largo |>
  filter(skill == "SQL") |>
  transmute(job_key = paste(source, job_id, sep = "::")) |>
  distinct() |>
  pull(job_key)

combinaciones <- tibble(
  combinacion = c(
    "Excel y Power BI",
    "Power BI y SQL",
    "Excel y SQL",
    "Excel, Power BI y SQL"
  ),
  n_ofertas = c(
    length(intersect(excel_ids, powerbi_ids)),
    length(intersect(powerbi_ids, sql_ids)),
    length(intersect(excel_ids, sql_ids)),
    length(Reduce(intersect, list(excel_ids, powerbi_ids, sql_ids)))
  )
) |>
  mutate(porcentaje = n_ofertas / n_con_habilidades)

familia_labels <- c(
  "data_analyst"                              = "Analista de datos / BI",
  "data_scientist_ml"                         = "Ciencia de datos / ML",
  "data_engineering"                          = "Ingenieria de datos",
  "it_non_data_or_software_engineering_heavy" = "TI / software",
  "data_adjacent"                             = "Adyacente a datos"
)

conteo_familias <- ofertas_universo |>
  count(job_family, name = "n_ofertas") |>
  mutate(
    familia = recode(job_family, !!!familia_labels),
    porcentaje = n_ofertas / n_universo
  ) |>
  arrange(desc(n_ofertas))

embudo_muestra <- tibble(
  etapa = factor(
    c("Registros brutos", "Ofertas unicas", "Universo analitico", "Con habilidades declaradas"),
    levels = c("Registros brutos", "Ofertas unicas", "Universo analitico", "Con habilidades declaradas")
  ),
  n = c(n_bruto, n_unicas, n_universo, n_con_habilidades)
)

# 4. Figures ----

fig_herramientas <- ggplot(conteo_herramientas, aes(x = skill, y = porcentaje)) +
  geom_col(fill = quanti_blue, width = 0.65) +
  geom_text(aes(label = percent(porcentaje, accuracy = 1)), vjust = -0.5, size = 3.5) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 0.8)) +
  labs(
    title = "Excel, Power BI y SQL dominan las ofertas de datos en Ecuador",
    subtitle = paste0("Porcentaje de las ", n_con_habilidades, " ofertas con habilidades declaradas que menciona cada herramienta"),
    x = NULL, y = NULL,
    caption = "Fuente: Multitrabajos, Computrabajo y Mipleo, cortes del 17 de junio y 16 de julio de 2026."
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank())

ggsave(
  file.path(figures_dir, "herramientas_demandadas.png"),
  fig_herramientas, width = fig_width, height = fig_height, dpi = 150
)

fig_competencias <- ggplot(conteo_competencias, aes(x = skill, y = porcentaje)) +
  geom_col(fill = quanti_mid, width = 0.65) +
  geom_text(aes(label = percent(porcentaje, accuracy = 1)), vjust = -0.5, size = 3.5) +
  scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 0.35)) +
  labs(
    title = "KPIs y bases de datos son las competencias tecnicas mas mencionadas",
    subtitle = paste0("Porcentaje de las ", n_con_habilidades, " ofertas con habilidades declaradas que menciona cada competencia"),
    x = NULL, y = NULL,
    caption = "Fuente: Multitrabajos, Computrabajo y Mipleo, cortes del 17 de junio y 16 de julio de 2026."
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank())

ggsave(
  file.path(figures_dir, "competencias_tecnicas.png"),
  fig_competencias, width = fig_width, height = fig_height, dpi = 150
)

fig_familias <- ggplot(conteo_familias, aes(x = reorder(familia, n_ofertas), y = n_ofertas)) +
  geom_col(fill = quanti_gray, width = 0.65) +
  geom_text(aes(label = n_ofertas), hjust = -0.2, size = 3.5) +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Composicion del universo analitico por familia ocupacional",
    subtitle = paste0(n_universo, " ofertas clasificadas dentro del universo de datos y tecnologia"),
    x = NULL, y = "Numero de ofertas",
    caption = "Fuente: Multitrabajos, Computrabajo y Mipleo, cortes del 17 de junio y 16 de julio de 2026."
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank())

ggsave(
  file.path(figures_dir, "familias_ocupacionales.png"),
  fig_familias, width = fig_width, height = fig_height, dpi = 150
)

# 5. Export ----

write_csv(conteo_herramientas, file.path(tables_dir, "herramientas_demandadas.csv"))
write_csv(conteo_competencias, file.path(tables_dir, "competencias_tecnicas.csv"))
write_csv(combinaciones, file.path(tables_dir, "combinaciones_herramientas.csv"))
write_csv(conteo_familias, file.path(tables_dir, "familias_ocupacionales.csv"))
write_csv(embudo_muestra, file.path(tables_dir, "embudo_muestra.csv"))

resumen_mercado_datos <- list(
  n_bruto           = n_bruto,
  n_unicas          = n_unicas,
  n_universo        = n_universo,
  n_con_habilidades = n_con_habilidades,
  conteo_herramientas = conteo_herramientas,
  conteo_competencias = conteo_competencias,
  combinaciones       = combinaciones,
  conteo_familias     = conteo_familias,
  embudo_muestra      = embudo_muestra
)

saveRDS(resumen_mercado_datos, file.path("outputs", "mercado_datos_resumen.rds"))

sessionInfo()
