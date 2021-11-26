# Análisis de estructura de la población y demográfico con *Lupinus*

## Índice:

1. [Estructura de la población](#estructura):  
	a. [PCA](#pca)  
	b. [Admixture](#admixture)  
2. [Demografia](#demografia)  
	a. [Infiriendo el SFS](#SFS)  
	b. [Fastsimcoal](#fastsimcoal)  

# Estructura de la población <a name = "estructura"></a>
## PCA <a name = "pca"></a>

Ahora que ya tenemos nuestro VCF listo, podemos empezar a hacer análisis. Primero, verificaremos la estructura de la población mediante un [análisis de componentes principales (PCA)](https://en.wikipedia.org/wiki/Principal_component_analysis). PCA es un método sin modelo y sin necesidad de una asignación de población previa que ayuda a identificar la estructura de la población y la ascendencia compartida. En el caso de los datos genéticos, PCA identifica los principales ejes de variación basado en las frecuencias alélicas, con el primer componente explicando la variación principal observada, el segundo componente la siguiente variación más grande y así sucesivamente. Al hacer esto, el algoritmo calcula las coordenadas de los individuos a lo largo de los ejes para posicionar las muestras en el conjunto de datos. Para realizar un PCA en los datos de *Lupinus*, usaremos el software [plink - versión 1.9](https://www.cog-genomics.org/plink/).

1. Crear una carpeta llamada "demografia" dentro de la carpeta "data" donde vamos hacer estos analisis.
2. Dentro de esta carpeta, crear una otra llamada "PCA".
3. El archivo input que vamos usar es el formato *plink* generado por *Stacks* en *populations*: **populations.plink.ped** y **populations.plink.map**. Entonces tenemos que obtener la ruta de estos archivos (`pwd`).
4. Necesitamos cargar el módulo de *plink* en el cluster: `module load plink`.
5. ahora podemos ejecutar *plink* usando los archivos de *Stacks* (`-file`) para calcular el PCA (`--pca`). Además, pediremos a plink que genere un formato "corregido" (`--recode12`) para ejecutar el análisis de *admixture* que sigue abajo.

**Output:** 6 archivos: 2 con los resultados de los PCA (plink.eigenval y plink.eigenvec), 2 que vamos usar en *admixture* (plink.ped y plink.map) y 2 con información sobre la ejecución y los datos (plink.log y plink.nosex).

6. Vamos descargar en nuestra computadora (`scp`) los outputs del PCA (plink.eigenval y plink.eigenvec) para graficar usando R.
7. Abra R Studio.
8. Primero vamos cargar los paquetes que necesitamos y setar el directorio:  

```{r}
library(tidyverse)
library(ggplot2)

setwd("<camino_donde_esta_los_archivos>")
```

9. Vamos ler los archivos generados por *plink* en R:  

```{r}
pca <- read_table2("./plink.eigenvec", col_names = FALSE)

eigenval <- scan("./plink.eigenval")
```

10. Necesitamos añadir nombres para las columnas del PCA:  

```{r}
names(pca)[1] <- "Species"
names(pca)[2] <- "Ind"

#de las columnas con las coordenadas (de la 3 hasta la última), vamos a nombrar las columnas con el título PC[nUmero de columna] así:
names(pca)[3:ncol(pca)] <- paste0("PC", 1:(ncol(pca)-2))
```

11. Ahora vamos a convertir los eigenvalues a porcentaje:  

```{r}
pve <- data.frame(PC = 1:length(eigenval), pve = eigenval/sum(eigenval)*100)
```

12. Listo! Ahora si a graficar! Primero, vamos graficar la variancia explicada por cada componente principal:  

```{r}
a <- ggplot(pve, aes(PC, pve)) +
	geom_bar(stat = "identity") +
	ylab("Percentage de la variancia") +
	theme_light(); a
```

13. Ahora vamos a graficar el PCA para los dos primeros ejes:  

```{r}
b <- ggplot(pca, aes(PC1, PC2, col = Species)) +
	geom_point(size = 3) +
	scale_colour_manual(values = c("red", "blue")) +
	coord_equal() +
	theme_light() +
	xlab(paste0("PC1 (", signif(pve$pve[1], 3), "%)")) +
	ylab(paste0("PC2 (", signif(pve$pve[2], 3), "%)")); b
```

⚠️ <span style="color:red">reportar imagen del PCA</spam> ⚠️

---

## Admixture <a name = "admixture"></a>

El software [*Admixture*](https://dalexander.github.io/admixture/) | [Manual](https://dalexander.github.io/admixture/admixture-manual.pdf) es una herramienta de estimación de máxima verosimilitud de ancestralidad (#K) para los individuos estudiados a partir de conjuntos de datos de genotipos (SNP) multilocus - ver fig. abajo.

![Un gráfico de *admixture* (imagen de: [Lawson et al., 2018](https://www.nature.com/articles/s41467-018-05257-7))](../Imagenes/admixture.png)

**Suposiciones del modelo:**
- Los SNP no están vinculados.
- Los individuos no están relacionados.
- Los sitios son bialélicos y se eliminan los singletons.
- Hay gran cantidad de SNP (~ 10,000).
- Las poblaciones tienen una cantidad similar de individuos (no se detectarán poblaciones subrepresentadas).

Es importante tener en cuenta que diferentes historias evolutivas pueden generar un patrón muy similar de estructura poblacional, por lo que se necesita mucho cuidado al interpretar los resultados (para más información, mire [Lawson et al., 2018](https://www.nature.com/articles/s41467-018-05257-7)).

Otros softwares para detectar estructura poblacional:
- [STRUCTURE](https://web.stanford.edu/group/pritchardlab/structure.html)
- [FASTSTRUCTURE](https://rajanil.github.io/fastStructure/)
- [CONSTRUCT](https://github.com/gbradburd/conStruct)
y muchos otros

1. Dentro de la carpeta "demografia", vamos crear una llamada "admixture".
2. Entra en la carpeta "admixture".
3. El archivo input que vamos usar es el generado por *plink* cuando hicimos el PCA `../PCA/plink.ped`.
4. Vamos entonces a cargar el modulo en el cluster: `module load admixture`.
5. La línea de comando para correr *admixture* és: `admixture <archivo> <#K>`. Debido a que queremos comparar diferentes números de grupos (K de 1 a 5), lo ejecutaremos usando validación cruzada, por lo que necesitamos generar un *for loop:*  
`for k in {1..5}; do admixture --cv=10 <ruta_del_archivo> $k > log${k}.out; done`

**Output**: 3 archivos (log.out, .P y .Q) para cada valor de K.

7. Vamos descargar (`scp`) los outputs del *admixture* para graficar en R.
8. En R Studio, primero vamos cargar los paquetes que necesitamos y setar el directorio:

```{r}
library(ggplot2)
setwd("<camino_donde_estan_los_archivos>")
```

9. Vamos mirar los likelihoods de cada K:

```{r}
#lista los archivos en la carpeta con extensión .out
f <- list.files(path = ".", pattern = ".out")

#creamos un data.frame vacío
lh_K <- data.frame(K = numeric(),
                   CV_error = numeric())

#hacemos un for loop para sacar los valores K y CV_error de cada archivo
for(i in f){
  temp <- readLines(i)[grep("CV", readLines(i))]
  k <- as.integer(sub(".*?K=*?(\\d+).*", "\\1", temp))
  cv <- as.numeric(sub(".*?): *?(\\d+(?:.\\d+)).*", "\\1", temp))
  lh_K[nrow(lh_K) + 1,] <- c(k, cv)
}

print(lh_K)
```

10. Ahora graficamos los valores *CV error*:

```{r}
a <- ggplot(lh_K, aes(x = K, y = CV_error)) +
  geom_point() +
  geom_line() +
  ylab("Cross-validation error") +
  xlab("K") +
  theme_light(); a
```

> **PREGUNTA:** ¿Cual es el valor de K más probable para estos datos?

11. Ahora que ya descubrimos cual es valor K de clusters mas probable, vamos a graficar la ancestralidad estimada por admixture para cada individuo. Pero antes de hacer la gráfica necesitamos cargar la matriz Q:

```{r}
#cargar la matrix Q para el K más probable
q <- read.table("plink.2.Q")

#plot
barplot(t(as.matrix(q)), col = c("#ef8a62", "#91bfdb"), xlab = "Individual #", ylab = "Ancesrty")
```
⚠️ <span style="color:red">reportar las dos gráficas generadas en R</spam> ⚠️

---
# Demografia <a name = "demografia"></a>

En esta parte estimaremos algunos parámetros demográficos (tamanho poblacional, tiempo de divergencia, ...) basados en nuestro conjunto de datos y compararemos dos modelos demográficos de divergencia, aislamiento sin migración (A) y con migración (B - fig. abajo), para verificar cuál de estos modelos es el más probable.

![Los dos modelos de aislamiento sin migración (A) y con migración (B) que vamos comparar ([imagen modificada del manual de Fastsimcoal](http://cmpg.unibe.ch/software/fastsimcoal2511/man/fastsimcoal25.pdf))](../Imagenes/fastsimcoal_models.png)


## Infiriendo el SFS <a name = "SFS"></a>

Antes de empezar las estimaciones demográficas, necesitamos transformar nuestros datos al [*Site Frequency Spectrum* (SFS)](https://en.wikipedia.org/wiki/Allele_frequency_spectrum). Cada entrada en el SFS indica el número total de loci con la correspondiente frecuencia de alelos derivados.

![SFS y folded SFS ([imagen de acá](https://www.mun.ca/biology/scarr/SFS_&_FSFS.html))](../Imagenes/SFS_FSFS.jpg)

La figura arriba muestra cómo el cálculo de **SFS** para 10 bp y n = 6 individuos haploides. El SFS va a tener n-1 = 5 clases, porque cualquier variante de SNP podría ocurrir en 1/6, 2/6, ..., o 5/6 individuos: si ocurre en 6/6  signfica que los individuos son invariantes. El SFS se obtiene contando el número de SNP derivados con respecto a los "1"s (en recuadros grises) individuales. Cuando no está claro si el estado del carácter en el individuo #1 es ancestral o derivado, el SFS se "dobla" (**folded SFS**) combinando las clases "1" y "5" (ambas clases tienen un carácter de una manera y cinco de otra), y el clases "2" y "4" (ambas tienen dos en un sentido y tres en el otro). La clase '3' permanece sin cambios (combina los tipos equilibrados 000111 y 111000).

Es importante tener en cuenta que existen diferentes tipos de SFS (para una, dos o muchas poblaciones si se conoce el estado derivado o no) - [mirar acá para una buena explicación](https://theg-cat.com/tag/joint-sfs/). Esto dependerá de lo que se quiera hacer con *fastsimcoal*. Para obtener más información al respecto, consulte el [manual de fastsimcoal](http://cmpg.unibe.ch/software/fastsimcoal27/man/fastsimcoal27.pdf).

Aquí, vamos utilizar un script llamado [*easySFS*](https://github.com/isaacovercast/easySFS) para generar el SFS de nuestro archivo vcf. Existen otros softwares que pueden generar el SFS, como [Arlequin](http://cmpg.unibe.ch/software/arlequin35/), [angsd](http://www.popgen.dk/angsd/index.php/ANGSD) y [dadi](https://dadi.readthedocs.io/en/latest/). Como tenemos dos poblaciones, vamos estimar el *joint* SFS o 2D SFS ("minor allele frequency SFS" = *jointMAF*).

1. En la carpeta *data* vamos activar un ambiente *conda* ya creado con algunos softwares que necesitamos:  
	- Cargar: `module load conda`
	- Activar el ambiente: `source activate ~/data/conda/conda_envs/easySFS`
2. Crear una carpeta *fastsimcoal* dentro de la carpeta *demografia* y entrar en la carpeta.
3. Clonar el repositorio de *easySFS* [repositorio de github](https://github.com/isaacovercast/easySFS):  

	`git clone https://github.com/isaacovercast/easySFS.git`

4. Hacer ejecutable:
	- entrar en la carpeta: `cd easySFS`
	- hacer ejecutable: `chmod +x easySFS.py`

Ahora estamos listos para crear el archivo SFS:
1. Necesitamos 2 archivos para hacer el SFS: el vcf (con uno solo SNP por loci) y el *mapa de población* que usamos con *Stacks* - mira las rutas donde están estos dos archivos.  
2. vamos a generar el SFS en dos pasos. El primero es:  
`./easySFS.py -i <ruta_vcf>/populations.snps.vcf -p <ruta_pop_map>/Lupinus_pops.txt --preview`

Que dará como resultado algo como esto:
```
L_alopecuroides
(2, 215)	(3, 322)	(4, 389)	(5, 435)	(6, 467)	(7, 491)	(8, 507)	(9, 209)	(10, 214)

L_triananus
(2, 457)	(3, 685)	(4, 823)	(5, 916)	(6, 980)	(7, 1023)	(8, 1051)	(9, 538)	(10, 544)
```
Cada columna es el número de muestras (2n) en la proyección y el número de sitios segregantes en ese valor de proyección. El manual de *dadi* recomienda maximizar el número de sitios segregantes, pero al mismo tiempo, si tiene muchos datos faltantes, es posible que deba equilibrar el número de sitios segregados con el número de muestras para evitar reducir demasiado el muestreo.

> **PREGUNTA:** ¿Qué número de muestras parece ser una buena opción para esto dataset?

⚠️ <span style="color:red">reportar el número de muestras escogida</spam> ⚠️

A continuación, ejecute el script con los valores para proyectar para cada población (x,y), así:  
`./easySFS.py -i <ruta_vcf>/populations.snps.vcf -p <ruta_pop_map>/Lupinus_pops.txt --proj x,y`

Esto vas generar una carpeta `output` con archivos para los softwares *dadi* y *fastsimcoal*. Usaremos el **jointMAF** producido para *fastsimcoal* (`populations_jointMAFpop1_0.obs`).


## Fastsimcoal <a name = "fastsimcoal"></a>

Ahora que ya tenemos nuestro joint SFS, finalmente podemos ejecutar [*fastsimcoal2*](http://cmpg.unibe.ch/software/fastsimcoal27/) :)  
Fastsimcoal es un software de modelado demográfico que permite probar varios escenarios demográficos con diferentes niveles de complejidad dependiendo de sus datos. Utiliza el SFS para ajustar los parámetros del modelo a los datos observados mediante la realización de simulaciones coalescentes. El manual es bastante completo y se puede encontrar [acá](http://cmpg.unibe.ch/software/fastsimcoal27/man/fastsimcoal27.pdf).

Antes de empezar necesitamos:
1. Dentro de esta carpeta *fastsimcoal* vamos hacer el download del software: `wget <RUTA_INTERNET>`
2. Descomprimir el archivo zip : `unzip <ARCHIVO>.zip`
3. Dentro de la carpeta corremos el comando `chmod +x <ARCHIVO>` para hacer el archivo executable  y estamos listos.
4. Vamos volver a nuestra carpeta inicial de `fastsimcoal` y crear una carpeta llamada `modelos`. Dentro de `modelos`, vamos generar dos carpetas: `div` y `div_mig` - una a cada modelo demográfico que probaremos.

### Archivos de entrada:  
Para ejecutar fastsimcoal2 necesitamos 3 archivos en una misma carpeta. Los 3 archivos deben tener el mismo prefijo pero diferente extensión. Todos son archivos de texto:
- SFS observado = `${PREFIX}_jointMAFpop1_0.obs`, ya generado por *easySFS*
- Archivo que define el modelo demográfico = `${PREFIX}.tpl`
- Archivo que define los parámetros = `${PREFIX}.est`

### Modelo de divergencia `div`:  
Para la carpeta `div`:
- Copie el SFS generado por *easySFS*.
- Para los archivos `.tpl` y `.est` vamos modificar dos archivos ejemplos en la carpeta `example` de *fastsimcoal*. Vamos a copiar de los archivos así: `cp <RUTA>/fastsimcoal/fsc27_linux64/example\ files/2PopDiv20Mb/2PopDiv20Mb.* `.  
- Recuerden que todos los 3 archivos deben tener el mismo prefijo. Entonces cambiemos (`mv`) los prefijos de los archivos a algo significativo, como el nombre del organismo y el modelo: `Lupinus_div`. Todos los archivos deberían verse así:
```
Lupinus_div.est  Lupinus_div.tpl  Lupinus_div_jointMAFpop1_0.obs
```
- Usando `nano`, vamos modificar los archivos `.est` y `.tpl`.
En el `.tpl` tenemos que cambiar el número de los individuos para lo que establecimos en el SFS y la tasa de mutación (usaremos 7e-9). En el `.est`, podemos dejar los *priors* como están, pero es importante mirarlos y comprender lo que pasa.


Estamos casi listos para hacer nuestra primera prueba, pero necesitamos crear la línea de comando y el archivo *sbatch*.

Primero intentemos directamente en la línea de comando:
1. Descubrir la ruta de fastsimcoal y generar una variable para esto: `ruta_fastsimcoal=<RUTA>/fsc2702`
2. En el terminal, crear una variable con el nombre del prefijo: `PREFIX="Lupinus_div"`
3. Vamos ejecutar *fastsimcoal* con estas con estas opciones:
`$ruta_fastsimcoal`  
`-t ${PREFIX}.tpl`  
`-e ${PREFIX}.est`  
`-n 250000` número de simulaciones coalescentes para aproximar el SFS esperado en cada ciclo.  
`-m` utilizar frecuencia de alelos menores (MAF)  
`--removeZeroSFS` ignorar los sitios monomórficos.  
`-M` estimación de parámetros por máxima probabilidad compuesta de la SFS.  
`-L 40` número de ciclos de optimización (ECM) para estimar los parámetros.  
`-q` pocas mensajes a la consola (no detallado).  

Ahora vamos hacer un *sbatch* porqué tenemos que ejecutar *fastsimcoal* mucho más de una vez. `fastsimcoal2` no debe ejecutarse una sola vez porque es posible que no encuentre la mejor combinación de estimaciones de parámetros de inmediato. Es mejor ejecutarlo 50 veces o más y que de estas ejecuciones seleccione la que tenga el *likelihood* más alto, que es la ejecución con las estimaciones de parámetros de mejor ajuste para este modelo. Debido a limitaciones de tiempo, ejecutaremos este modelo solo 5 veces. En el *sbatch* vamos añadir una línea que indica ejecutar varias veces el mismo comando: `#SBATCH --array=1-5`. En este caso, *sbatch* ejecutará fastsimcoal de 1 a 5, generando la variable `${SLURM_ARRAY_TASK_ID}` con el número de ejecución. Usaremos esta variable para generar una carpeta para cada ejecución y evitar sobrescribir los resultados. Entonces, en el *sbatch* vamos poner:
```
ruta_fastsimcoal=<RUTA>/fsc2702
PREFIX="Lupinus_div"

cd <RUTA_MODELO_DIV>

mkdir Run${SLURM_ARRAY_TASK_ID}
cp ${PREFIX}.est Run${SLURM_ARRAY_TASK_ID}/
cp ${PREFIX}.tpl Run${SLURM_ARRAY_TASK_ID}/
cp ${PREFIX}_jointMAFpop1_0.obs Run${SLURM_ARRAY_TASK_ID}/
cd Run${SLURM_ARRAY_TASK_ID}/

$ruta_fastsimcoal -t ${PREFIX}.tpl -e ${PREFIX}.est -n 250000 -m --removeZeroSFS -M -L 40 -q

cp ${PREFIX}/${PREFIX}.bestlhoods <RUTA>/div/bestlhoods/${PREFIX}_${SLURM_ARRAY_TASK_ID}.bestlhoods
```

Antes de ejecutar el *sbatch*, no se olvide de generar una nueva carpeta llamada `bestlhoods` dentro de la carpeta `div`, que es donde vamos poner los resultados para mirar el mejor likelihood.

**Memoria necesaria:** ~70mb

**Tiempo de ejecución:** ~11min

**Output:** en cada carpeta `Run*` vamos tener una nueva carpeta con el nombre del ${PREFIX}. En esta carpeta tenemos 5 archivos. Los más importantes para nosotros son ${PREFIX}.bestlhoods y ${PREFIX}_maxL.par

Los archivos ${PREFIX}.bestlhoods ya quedaron copiados en la carpeta `bestlhoods`. Naveguemos a esa carpeta y comparemos qué *run* presenta el mejor *likelihood*. Para esto, vamos ejecutar la línea:  
`cat ${PREFIX}_{1..5}.bestlhoods | grep -v MaxObsLhood | awk '{print NR,$5}' | sort -k 2`

¿Qué hicimos con este comando? En cada archivo sacamos el encabezado con `grep`, después mostramos en la pantalla el número de ejecución que en este caso corresponde al número de línea usando el comando `awk '{print NR,$5}` donde $5 es la columna del *MaxEstLhood* y, por lo tanto, la probabilidad que queremos comparar entre diferentes ejecuciones. Por último, ordenamos el archivo de la mejor probabilidad a la peor con `sort`.

### Modelo de divergencia con migración `div_mig`:  
Ahora que del modelo *div* ya esta siendo ejecutado, vamos generar los archivos para el modelo de divergencia con migración `div_mig`. Copie `cp` los 3 archivos *input* del `div` para `div_mig`. En este modelo, tenemos que modificar los archivos para añadir una matriz de migración en el `.tpl` y los parámetros de migración en el `.est`. Vamos intentar hacer estas modificaciones en grupos. Un consejo es echar un vistazo a la página 77 del [manual](http://cmpg.unibe.ch/software/fastsimcoal27/man/fastsimcoal27.pdf).

⚠️ <span style="color:red">reportar los archivos *.est* y *.tpl* generados para el modelo div_mig</spam> ⚠️

**Memoria necesaria:** ~70mb

**Tiempo de ejecución:** ~21min

**Output:** similar al modelo `div`, pero con más columnas en los archivos *.bestlhoods porque este modelo tiene más parámetros para estimar.

De manera similar al modelo `div`, modifique el comando `cat` para comparar qué *run* presenta el mejor *likelihood*.

### Comparación de modelos con AIC:  
Vamos usar [*Akaike information criterion* (AIC)](https://en.wikipedia.org/wiki/Akaike_information_criterion) para comparar los dos modelos que ejecutamos. El AIC encuentra el modelo que explica la mayor variación en los datos, mientras que penaliza a los modelos que utilizan un número excesivo de parámetros. Cuanto menor sea el AIC, mejor se ajustará al modelo. Se calcula así:  
<img src="https://render.githubusercontent.com/render/math?math=AIC = 2K-2ln(L)">   

Dónde:  
- *K*: el número de parámetros del modelo  
- *ln(L)*: la probabilidad logarítmica del modelo - fastsimcoal ya calcula este valor automáticamente, pero en *log10*

Aquí porque solo estamos comparando dos modelos, calculemos manualmente AIC, en R:

```{r}
#los valores de log(likelihood) para cada modelo
div <- <VALOR>
div_mig <- <VALOR>

#el numero de parametros para cada modelo
k_div <- <NUM_PARAM>
k_div_mig <- <NUM_PARAM>

#convertir de log10 a ln
ln_div <- div/log10(exp(1))
ln_div

ln_div_mig <- div_mig/log10(exp(1))
ln_div_mig

#calcular el AIC de cada modelo
AIC_div <- 2*k_div-2*ln_div
AIC_div
AIC_div_mig <- 2*k_div_mig-2*ln_div_mig
AIC_div_mig

```

> **PREGUNTA:** ¿Qué modelo explica mejor los datos?

⚠️ <span style="color:red">reportar el mejor modelo y los valores de AIC para cada modelo</spam> ⚠️

### Bootstrap:  
Ahora que sabemos cuál de los modelos es el mejor, podemos hacer *bootstrapping* para averiguar qué tan seguros estamos de nuestras estimaciones de parámetros. Para esto vamos obtener intervalos de confianza haciendo *parametric bootstraps* - en las páginas 58-60 del [manual](http://cmpg.unibe.ch/software/fastsimcoal27/man/fastsimcoal27.pdf) hay una buena explicación.

La idea es que utilizemos el archivo que contiene las estimaciones de los parámetros (*_maxL.par*) de la ejecución com mejor *likelihood*, para simular 100 SFS y ejecutar *fastsimcoal* basado en estos SFS simulados. De esta forma, descubriremos cómo nuestros datos tienen poder para inferir correctamente los parámetros estimados.

1. Crear una carpeta `bootstrap` en la carpeta `fastsimcoal`.
2. Copiar el archivo `\${PREFIX}_maxL.par` de la mejor *run* del mejor modelo para la carpeta `bootstrap` - vamos modificar esto archivo.
3. Tenemos que mirar cuantos SNPs se usaron en *easySFS* para modificar el archivo `\${PREFIX}_maxL.par`. Para esto, miramos el archivo `datadict.txt` creado por *easySFS*. Usando el comando `wc` podemos descubrir cuántas líneas hay en este archivo - ese es el número de SNP utilizados.
4. modificar `\${PREFIX}_maxL.par`:
	- En la línea abajo de "//Number of independent loci [chromosome]" sustituir 1 por el número de SNPs utilizados por *easySFS*
	- Sustituir la última línea: FREQ por DNA y 1 por 100, que se quede así: `DNA 100 0 7e-9 OUTEXP`

5. Retirar *_maxL* del nombre del archivo (`mv`)

6. Ejecutar fastsimcoal con el archivo `.par` modificado para generar 10 SFS simulados. Por razones de tiempo, acá vamos simular solo 10 SFSs, pero lo correcto es generar mucho más, como 100.

`$ruta_fastsimcoal -i ${PREFIX}.par -n10 -j -d -s<número_SNPs> -x -I -q`

`-n` Generará 10 SFS.   
`-j` Genera los archivos en directorios separados.  
`-d` Calcula SFS para los sitios derivados (acá yo penso que tenemos que usar `-m`, pero la versión 2.7 esta con un *bug*. Yo escribí en el google groups preguntando acerca de esto problema).  
`-s` Genera SNPs de los datos de ADN - especificar el número máximo de SNP para generar (use 0 para generar todos los SNP).  
`-x` No genera *Arlequin* output.  
`-I` Genera mutaciones de acuerdo con el modelo de mutación de sitio infinito (IS).  
`-q` Salida de mensaje mínimo en la console.  

7. con este procedimiento, se puede estimar los parámetros de estos SFS simulados utilizando los mismos `.tpl` y `.est` de la ejecución inicial de *fastsimcoal*. Entonces tenemos que copiar `.tpl` y `.est` para cada una de las carpetas
con los SFS simulados. En la carpeta del modelo que tenga los archivos `.tpl` y `.est`, hacer:  
`for i in {1..10}; do cp ${PREFIX}.* <RUTA>/bootstrap/${PREFIX}/${PREFIX}_$i; done`

8. Ahora que ya tenemos los archivos listos para hacer el bootstrap, vamos copiar y modificar el `.sh` usado en la ejecución inicial de *fastsimcoal* para hacer los *bootstraps*. Primero copie el `.sh` para la carpeta `bootstrap`. Ahora vamos cambiar el archivo:
	- cambiar `--job_name` y el `--array=1-10`
	- cambiar la ruta para la carpeta `boostrap/${PREFIX}/${PREFIX}_${SLURM_ARRAY_TASK_ID}`_
	- como ahora las carpetas ya están todas generadas de antemano, tenemos que remover las líneas con los comandos `mkdir`, `cp` y `cd`
	- en la línea de comando del *fastsimcoal*, cambiar la opción `-m` por `-d` (esto solo por el *bug*)
	- cambiar la carpeta `bestlhoods` por una nueva que vamos crear llamada `results` dentro de la carpeta `bootstrap` y no se olvide de crear la carpeta `results`.

9. Ejecutar el *sbatch*.

**Memoria necesaria:** ~70mb

**Tiempo de ejecución:** ~10min

**Output:** dentro de la carpeta `results` vamos tener todos los archivos `bestlhoods` para calcular los intervalos de confianza.

10. Para calcular los intervalos de confianza, en la carpeta `results` vamos generar una tabla que podemos copiar y salvar en un archivo *.txt* en tu computadora para leerlo en R. Vamos hacer así:  
`cat ${PREFIX}_{1..10}.bestlhoods | grep -v MaxObsLhood` .  
Si desea poner un encabezado en la tabla, simplemente cópielo de uno de los archivos, por ejemplo:  
`head -n 1 Lupinus_<MODELO>_1.bestlhoods`.  

11. En R en tu computadora:

```{r}
setwd("<RUTA>")
boot <- read.csv("fastsimcoal_bootstrap.txt", sep = "\t")

quantile(boot$NANC,c(.025,.975))
quantile(boot$NPOP1,c(.025,.975))
quantile(boot$NPOP2,c(.025,.975))
quantile(boot$TDIV,c(.025,.975))
```

y listo :smile:

⚠️ <span style="color:red">reportar los *point estimation* para cada parámetro y los intervalos de confianza</spam> ⚠️
