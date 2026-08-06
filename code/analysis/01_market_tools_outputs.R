# ============================================================
# Market tools outputs
# Author: Daniel Sanchez
# Purpose: Generar tablas, figuras y el resumen del mercado laboral
#          de datos en Ecuador a partir de la muestra final.
# Inputs:  data/final/ofertas_universo_analitico.csv,
#          data/final/ofertas_con_habilidades.csv
# Outputs: outputs/figures/*.png, outputs/tables/*.csv,
#          outputs/mercado_datos_resumen.rds,
#          final_version/images/grafico*.png
# ============================================================

# 0. Setup ----
library(dplyr)
library(ggplot2)
library(readr)
library(scales)
library(stringr)
library(tidyr)
library(tibble)
library(forcats)

# set.seed(42)

final_dir <- file.path("data", "final")
figures_dir <- file.path("outputs", "figures")
tables_dir <- file.path("outputs", "tables")
article_images_dir <- file.path("final_version", "images")

dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(article_images_dir, recursive = TRUE, showWarnings = FALSE)

# El bundle de El Quantificador numera las figuras segun el orden del texto.
article_figures <- c(
  "familias_ocupacionales.png" = "grafico1.png",
  "herramientas_demandadas.png" = "grafico2.png",
  "competencias_tecnicas.png" = "grafico3.png",
  "habilidades_suaves.png" = "grafico4.png"
)

fig_width <- 6.1
fig_height <- 5.4

quanti_blue <- "#6FA8DC"
quanti_blue_dark <- "#355C7D"
quanti_burgundy <- "#A94442"
quanti_ink <- "#4A4A4A"
quanti_grid <- "#E6E6E6"
quanti_bg <- "#FFFFFF"

herramientas_foco <- c("Excel", "Power BI", "SQL", "SAP", "Python")
competencias_foco <- c("KPIs", "Bases de Datos", "ERP", "Dashboards", "Business Intelligence")
soft_skills_patterns <- tribble(
  ~skill, ~pattern,
  "Organización", "organizaci",
  "Comunicación", "comunicaci",
  "Planificación", "planificaci",
  "Proactividad", "proactiv",
  "Trabajo en equipo", "trabajo en equipo",
  "Atención al detalle", "detalle",
  "Pensamiento analítico", "analitico|analítico"
)

theme_enighur <- function() {
  theme_minimal(base_size = 11.5, base_family = "sans") +
    theme(
      plot.background = element_rect(fill = quanti_bg, color = NA),
      panel.background = element_rect(fill = quanti_bg, color = NA),
      panel.grid.major.x = element_line(color = quanti_grid, linewidth = 0.3),
      panel.grid.major.y = element_blank(),
      panel.grid.minor = element_blank(),
      axis.title = element_blank(),
      axis.text = element_text(color = quanti_ink, size = 9.8),
      axis.text.y = element_text(hjust = 1),
      axis.text.x = element_text(margin = margin(t = 5)),
      plot.title = element_blank(),
      plot.subtitle = element_blank(),
      plot.caption = element_blank(),
      legend.position = "none",
      axis.line.x = element_blank(),
      axis.line.y = element_blank(),
      axis.ticks = element_blank(),
      plot.margin = margin(12, 24, 14, 12)
    )
}

# 1. Load Data ----
ofertas_universo <- read_csv(
  file.path(final_dir, "ofertas_universo_analitico.csv"),
  col_types = cols(.default = "c")
)

ofertas_con_habilidades <- read_csv(
  file.path(final_dir, "ofertas_con_habilidades.csv"),
  col_types = cols(.default = "c")
)

embudo_muestra <- read_csv(
  file.path(tables_dir, "embudo_muestra.csv"),
  show_col_types = FALSE
)

n_universo <- nrow(ofertas_universo)
n_con_habilidades <- nrow(ofertas_con_habilidades)

# 2. Clean / Transform ----
habilidades_largo <- ofertas_con_habilidades |>
  select(source, job_id, job_family, skills) |>
  mutate(skill_list = str_split(skills, ";\\s*")) |>
  unnest(skill_list) |>
  mutate(
    skill = str_squish(skill_list),
    skill = str_to_title(skill),
    # str_to_title rompe las siglas ("SQL" -> "Sql"), asi que aqui se restauran.
    skill = recode_values(
      skill,
      "Sql" ~ "SQL",
      "Power Bi" ~ "Power BI",
      "Kpis" ~ "KPIs",
      "Erp" ~ "ERP",
      "Bi" ~ "BI",
      "Sap" ~ "SAP",
      "Bases De Datos" ~ "Bases de Datos",
      default = skill
    )
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

conteo_familias <- ofertas_universo |>
  count(job_family, name = "n_ofertas") |>
  mutate(
    familia = recode_values(
      job_family,
      "data_analyst" ~ "Analista de datos / BI",
      "data_scientist_ml" ~ "Ciencia de datos / ML",
      "data_engineering" ~ "Ingeniería de datos",
      "it_non_data_or_software_engineering_heavy" ~ "TI / software",
      "data_adjacent" ~ "Adyacente a datos",
      default = job_family
    ),
    porcentaje = n_ofertas / n_universo
  ) |>
  arrange(desc(n_ofertas))

conteo_fuentes <- ofertas_universo |>
  count(source, name = "n_ofertas") |>
  mutate(porcentaje = n_ofertas / n_universo) |>
  arrange(desc(n_ofertas))

conteo_ciudades <- ofertas_universo |>
  count(city, name = "n_ofertas") |>
  mutate(porcentaje = n_ofertas / n_universo) |>
  arrange(desc(n_ofertas))

conteo_modalidad <- ofertas_universo |>
  mutate(modality = coalesce(modality, "No especificada")) |>
  count(modality, name = "n_ofertas") |>
  mutate(porcentaje = n_ofertas / n_universo) |>
  arrange(desc(n_ofertas))

skills_familias_principales <- habilidades_largo |>
  filter(job_family %in% c("data_analyst", "data_adjacent")) |>
  count(job_family, skill, name = "n_ofertas") |>
  group_by(job_family) |>
  mutate(porcentaje = n_ofertas / sum(n_ofertas)) |>
  slice_max(n_ofertas, n = 10, with_ties = FALSE) |>
  ungroup()

conteo_habilidades_suaves <- soft_skills_patterns |>
  rowwise() |>
  mutate(n_ofertas = sum(str_detect(str_to_lower(coalesce(ofertas_universo$description, "")), pattern))) |>
  ungroup() |>
  mutate(
    porcentaje = n_ofertas / n_universo,
    skill = factor(skill, levels = skill[order(n_ofertas)])
  )

# 4. Export tables ----
write_csv(conteo_herramientas, file.path(tables_dir, "herramientas_demandadas.csv"))
write_csv(conteo_competencias, file.path(tables_dir, "competencias_tecnicas.csv"))
write_csv(combinaciones, file.path(tables_dir, "combinaciones_herramientas.csv"))
write_csv(conteo_familias, file.path(tables_dir, "familias_ocupacionales.csv"))
write_csv(conteo_fuentes, file.path(tables_dir, "fuentes_ofertas.csv"))
write_csv(conteo_ciudades, file.path(tables_dir, "ciudades_ofertas.csv"))
write_csv(conteo_modalidad, file.path(tables_dir, "modalidad_ofertas.csv"))
write_csv(skills_familias_principales, file.path(tables_dir, "skills_familias_principales.csv"))
write_csv(
  conteo_habilidades_suaves |> mutate(skill = as.character(skill)),
  file.path(tables_dir, "habilidades_suaves.csv")
)

# 5. Export figures ----
fig_herramientas <- ggplot(
  conteo_herramientas,
  aes(x = skill, y = porcentaje, fill = skill == "Excel")
) +
  geom_col(width = 0.68) +
  geom_hline(yintercept = 0, color = quanti_grid, linewidth = 0.3) +
  geom_text(
    aes(label = percent(porcentaje, accuracy = 1)),
    vjust = -0.75,
    color = quanti_ink,
    size = 3.4
  ) +
  scale_fill_manual(values = c(`TRUE` = quanti_burgundy, `FALSE` = quanti_blue)) +
  scale_x_discrete(labels = \(x) str_wrap(x, width = 10)) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, 0.8),
    breaks = seq(0, 0.8, by = 0.2),
    expand = expansion(mult = c(0, 0.04))
  ) +
  theme_enighur()

ggsave(
  file.path(figures_dir, "herramientas_demandadas.png"),
  plot = fig_herramientas,
  width = fig_width,
  height = fig_height,
  dpi = 180,
  bg = "white"
)

fig_competencias <- ggplot(
  conteo_competencias,
  aes(x = skill, y = porcentaje, fill = skill == "KPIs")
) +
  geom_col(width = 0.68) +
  geom_hline(yintercept = 0, color = quanti_grid, linewidth = 0.3) +
  geom_text(
    aes(label = percent(porcentaje, accuracy = 1)),
    vjust = -0.75,
    color = quanti_ink,
    size = 3.35
  ) +
  scale_fill_manual(values = c(`TRUE` = quanti_burgundy, `FALSE` = quanti_blue)) +
  scale_x_discrete(labels = \(x) str_wrap(x, width = 12)) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, 0.35),
    breaks = seq(0, 0.3, by = 0.1),
    expand = expansion(mult = c(0, 0.04))
  ) +
  theme_enighur()

ggsave(
  file.path(figures_dir, "competencias_tecnicas.png"),
  plot = fig_competencias,
  width = fig_width,
  height = fig_height,
  dpi = 180,
  bg = "white"
)

fig_familias <- ggplot(
  conteo_familias,
  aes(x = fct_reorder(str_wrap(familia, width = 24), n_ofertas), y = n_ofertas, fill = familia == "Adyacente a datos")
) +
  geom_col(width = 0.66) +
  geom_text(
    aes(label = n_ofertas),
    hjust = -0.25,
    color = quanti_ink,
    size = 3.4
  ) +
  coord_flip() +
  scale_fill_manual(values = c(`TRUE` = quanti_burgundy, `FALSE` = quanti_blue)) +
  scale_y_continuous(
    breaks = pretty_breaks(n = 4),
    expand = expansion(mult = c(0, 0.12))
  ) +
  theme_enighur()

ggsave(
  file.path(figures_dir, "familias_ocupacionales.png"),
  plot = fig_familias,
  width = fig_width,
  height = fig_height,
  dpi = 180,
  bg = "white"
)

fig_soft_skills <- ggplot(
  conteo_habilidades_suaves,
  aes(x = fct_reorder(str_wrap(skill, width = 20), porcentaje), y = porcentaje, fill = skill == "Organización")
) +
  geom_col(width = 0.66) +
  geom_text(
    aes(label = percent(porcentaje, accuracy = 1)),
    hjust = -0.18,
    color = quanti_ink,
    size = 3.3
  ) +
  coord_flip() +
  scale_fill_manual(values = c(`TRUE` = quanti_burgundy, `FALSE` = quanti_blue)) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, 0.55),
    breaks = seq(0, 0.5, by = 0.1),
    expand = expansion(mult = c(0, 0.08))
  ) +
  theme_enighur()

ggsave(
  file.path(figures_dir, "habilidades_suaves.png"),
  plot = fig_soft_skills,
  width = fig_width,
  height = fig_height,
  dpi = 180,
  bg = "white"
)

# 6. Save summary ----
resumen_mercado_datos <- list(
  n_bruto = embudo_muestra$n[embudo_muestra$etapa == "Registros brutos"],
  n_unicas = embudo_muestra$n[embudo_muestra$etapa == "Ofertas unicas"],
  n_universo = n_universo,
  n_con_habilidades = n_con_habilidades,
  conteo_herramientas = conteo_herramientas,
  conteo_competencias = conteo_competencias,
  combinaciones = combinaciones,
  conteo_familias = conteo_familias,
  conteo_fuentes = conteo_fuentes,
  conteo_ciudades = conteo_ciudades,
  conteo_modalidad = conteo_modalidad,
  conteo_habilidades_suaves = conteo_habilidades_suaves,
  skills_familias_principales = skills_familias_principales,
  embudo_muestra = embudo_muestra
)

saveRDS(resumen_mercado_datos, file.path("outputs", "mercado_datos_resumen.rds"))

# 7. Sync article bundle ----
file.copy(
  from = file.path(figures_dir, names(article_figures)),
  to = file.path(article_images_dir, unname(article_figures)),
  overwrite = TRUE
)

message("Tablas, figuras y resumen exportados a outputs/.")

sessionInfo()
