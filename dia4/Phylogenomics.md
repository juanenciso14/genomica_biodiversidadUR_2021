# Infiriendo filogenias

## Tabla de contenido

1. [Árboles de máxima verosimilitud](#raxml)
2. [Árboles de especies](#esp)

# Árboles de máxima verosimilitud <a name = "raxml"></a>

Hay muchos softwares para ejecutar árboles concatenados de máxima verosimilitud (ML). Los más populares para grandes datos genómicos son: [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/), [ExaML](https://cme.h-its.org/exelixis/web/software/examl/index.html), [FastTree](http://www.microbesonline.org/fasttree/) e [IQ-TREE](http://www.iqtree.org/). Acá, usaremos [RAxML 8.2.11](https://cme.h-its.org/exelixis/web/software/raxml/) | [manual](https://cme.h-its.org/exelixis/resource/download/NewManual.pdf) para inferir un árbol de máxima verosimilitud (ML).

Vamos a crear una carpeta llamada "Filogenomica" (con el comando `mkdir`), y dentro de esta carpeta vamos crear una otra carpeta llamada "raxml". Para generar una hipótesis de relación entre los 18 individuos, usaremos para *input* el archivo .vcf de *Heliconius* ya filtrado y solo con sitios variables. Copie este archivo desde su carpeta original a la carpeta "raxml".

Primero, en la carpeta "raxml", necesitamos excluir los sitios que RAxML asumirá como monomórficos. Para eso, vamos asegurarnos de que los datos solo tengan sitios bialélicos y eliminaremos los sitios que tengan heterocigosidad muy alta (que no estan en equilibrio HW).

```
module load vcftools

file="<name_of_file>"

# Primero vamos a calcular HW con valores de p
vcftools --gzvcf $file.vcf.gz --hardy --max-alleles 2 --out $file

# Luego vamos a extraer los sitios que queremos mantener
awk '{split($3,gen,"/"); \
	if(gen[1]!=0 && gen[3]!=0 && $8>1e-5) \
	print $1"\t"$2}' $file.hwe > ${file}_sites_toKeep

# Y finalemente, creamos un nuevo VCF con los sitios que queremos mantener
vcftools --gzvcf ../bams_subsampled_chr/$file.vcf.gz \
	--positions ${file}_sites_toKeep \
	--recode --stdout | gzip > $file.altHom.vcf.gz
```

Ahora necesitamos transformar el archivo `$file.altHom.vcf.gz` en un archivo phylip que és el formato aceptado por RAxML. Para eso clonaremos un repositorio de github donde hay un script de Python que hace esta conversión. Dentro de la carpeta "raxml", ejecute el siguiente comando:  
`git clone https://github.com/joanam/scripts.git`  

Al hacer esto, debería aparecer una carpeta llamada "scripts". Dentro de "scripts" hay varios archivos, y usaremos uno llamado "vcf2phylip.py" para transformar nuestros datos. En la carpeta "raxml" execute estes comandos:

```
module load python

file="<nombre_del_archivo>"

python ./scripts/vcf2phylip.py -i $file.altHom.vcf.gz -o "${file}.phylip"
```

Ahora que tenemos nuestro archivo phylip podemos hacer un *sbatch* para ejecutar RAxML.

Los parámetros que usaremos:  
`-T` Especifica cuantos procesadores (¡SOLO EN LA VERSIÓN PTHREADS!).  
`-s` Especifica el nombre del archivo de entrada (phylip o fasta).  
`-f a` Hace un análisis de bootstrap rápido y la búsqueda del mejor árbol de ML en la misma ejecución.  
`-N` Indica el número de bootstraps que se van a calcular. Por ejemplo, 100 bootstraps.  
`- m` Indica el modelo de evolución. Al usar *ASC_* usted indica que desea aplicar una corrección a el *ascertainment bias* a los cálculos de verosimilitud. Para datos de SNPs vamos utilizar el modelo gamma de heterogeneidad de tasas con corrección de *ascertainment bias* y optimización de las tasas de sustitución (ASC_GTRGAMMA). Con este modelo necesita especificar el tipo de corrección (siguiente parámetro).  
`--asc-corr` Permite especificar el tipo corrección de *ascertainment bias* que desea utilizar (predeterminado: lewis).  
`-o` Especifica el nombre de un solo *outgroup* o una lista separada por comas de *outgroups.*  
`-n` Especifica el nombre del archivo de salida.  
`-p` Especifica un *random seed* para la inferencia inicial de parsimonia. Para todas las opciones en RAxML que requieran algún tipo de aleatorización, se debe especificar esta opción.  
`-x` Especifica un *random seed* para el bootstrap rápido.

El código para el *sbatch* es:
```
module load raxml/8.2.11

file="<name_of_file>"

# Prueba rápida con 100 bootstraps
raxmlHPC-PTHREADS-AVX -T 2 \
	-p 12345 -x 12345 \
	-s ${file}.phylip \
	-m ASC_GTRGAMMA --asc-corr=lewis \
	-N 100 -f a \
	-o H.eth.aer.JM67,H.hec.fel.JM273,H.num.num.MJ09.4125,H.num.sil.MJ09.4184,H.par.ser.JM202,H.par.spn.JM371 \
	-n RAXML_100boot.out
```

**Memoria necesaria:** 90mb

**Tiempo de ejecución:** ~25min

**Output:** cinco archivos `RAxML.*.<output_name>.out` (bestTree, bipartitions, bipartionsBranchLabels, bootstrap, info).
Para observar árboles es bueno tener el software [FigTree](http://tree.bio.ed.ac.uk/software/figtree/) en su computadora.
Descárguelo `RAxML_bipartitions.RAXML_100boot.out` en su computadora y abra el archivo en FigTree.

⚠️ <span style="color:red">reportar imagen del árbol</spam> ⚠️

----

# Árboles de especies <a name = "esp"></a>

Los árboles de especies muestran el patrón de ramificación de linajes de especies a través del proceso de especiación. Cuando las comunidades reproductivas se dividen por especiación, las copias de genes dentro de estas comunidades también se dividen según la descendencia. Las árboles de genes continúan ramificándose y descendiendo a través del tiempo. Por lo tanto, los árboles genéticos (de genes) están contenidos dentro de las ramas de la filogenia de las especies ([Maddison, 1997](https://academic.oup.com/sysbio/article/46/3/523/1651369)).

![Conflicto entre árboles de genes y de especie - figura de [Marin et al., 2020](https://onlinelibrary.wiley.com/doi/epdf/10.1111/jeb.13677)](./Imagenes/speciesTree.jpg)

Para inferir los árboles de especies entre las especies de *Heliconius*, vamos usar la metodología de [SVDquartets](https://academic.oup.com/bioinformatics/article/30/23/3317/206559?login=true) implementado en [PAUP](https://paup.phylosolutions.com/) que infiere relaciones entre cuartetos de taxones bajo el modelo coalescente para estimar los árboles de especies. Otro software ampliamente utilizado para esto es [ASTRAL](https://github.com/smirarab/ASTRAL).

Antes de empezar necesitamos bajar el software:
1. Vamos generar una carpeta llamada "PAUP" dentro de la carpeta "Filogenomica".
2. Dentro de la carpeta "PAUP", tenemos que hacer el download del software PAUP (la versión para Linux):  
`wget http://phylosolutions.com/paup-test/paup4a168_centos64.gz`
3. Para descomprimir PAUP:  
`gunzip paup4a168_centos64.gz`
4. Ahora, para hacer que PAUP sea ejecutable:  
`chmod +x paup4a168_centos64`

Ahora estamos listos para empezar 😃
1. PAUP acepta como input un archivo en el formato *nexus*. Para esto, copiaremos a la carpeta "PAUP" y modificaremos manualmente nuestro archivo *phylip* utilizado en RAxML a uno *nexus*. Usando `nano`, sustituiremos la primera línea del archivo *phylip* a:
```
#NEXUS
begin data;
	dimensions ntax=18 nchar=52125;
	format datatype=nucleotide gap=- missing=N matchchar=.;
matrix
```
y agregaremos código con algunas instrucciones a PAUP al final del archivo
```
;
End;
begin sets;
	taxpartition Heliconius =
		H.eth.aer       : 1,
		H.hec.fel       : 2,
		H.melp.malleti  : 3-6,
		H.num.num       : 7,
		H.num.sil       : 8,
		H.par.ser       : 9,
		H.par.spn       : 10,
		H.tim.fln       : 11-14,
		H.tim.thx       : 15-18;
end;
begin paup;
	cd *;	[ sets the default directory to the one containing this file]
	svdq speciestree=y taxpartition=Heliconius evalQuartets=all nthreads=2 bootstrap=y nreps=100;
	savetrees;
end;
```

- **Taxpartition** és donde diremos al software la especie a que pertenece cada muestra, con la **taxpartition** *Heliconius*
- **speciestree** especifica realizar un análisis de árboles de especies (y)
- **evalQuartets** hará una búsqueda exhaustiva con todos los cuartetos (all)
- **nthreads**  número de procesadores (2)
- **bootstrap** si hará bootstrap (y)
- **nreps** número de réplicas de bootstrap (100)
- **savetrees** salva la árbol

Cambiar `mv` la extensión del archivo de *.phy* para *.nex.*  
Ahora estamos listos para ejecutar PAUP :)
```
file="<nombre_del_archivo.nex>"

# Running svdquartets
./paup4a168_centos64 $file -n
```
**Memoria necesaria:** ~20mb

**Tiempo de ejecución:** >2min (no necesita hacer sbatch)

**Output:** Un archivo con el árbol de especies(.tre). A continuación, haga lo mismo con RAxML. Descárguelo a su computador y mírelo en FigTree.

⚠️ <span style="color:red">reportar imagen del árbol</spam> ⚠️

---
