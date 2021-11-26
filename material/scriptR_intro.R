#cargando paquetes
library(tidyverse)
library(ggplot2)

#saber donde estamos
getwd()
#setando directorio
setwd("~/Dropbox/Postdoc_Rosario/BiodiversityGenomics_Winter2021/genomica_biodiversidadUR_2021/material/")
getwd()

#listar los archivos
f <- list.files()
f_txt <- list.files(pattern = ".txt")

#lendo tabla
mus <- read.table("genes_ch1_mus_musculus.txt")
head(mus)
dim(mus)

#cambia los nombres de las columnas
colnames(mus) <- c("scaffold", "gene")
head(mus)

#crea una tabla nueva con la columna combined
mus2 <- mus %>% rename(Scaffold = scaffold, Gene = gene) %>% mutate(Combined = paste(Scaffold, Gene, sep= "_"))
head(mus2)

#ler tabla
mus_chr1 <- read_table2("Mus_musculus.GRCm38.75_chr1.gtf", comment = "#", col_names = F)
head(mus_chr1)

unique(mus_chr1$X3)

mus_chr1_sum <- mus_chr1 %>% count(X3)
mus_chr1_sum

#grafica
ggplot(mus_chr1_sum, aes(x=X3, y=n)) + geom_bar(stat="identity")
