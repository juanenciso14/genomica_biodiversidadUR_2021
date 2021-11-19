<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
# Índice

- [Algunos tips para escribir ciclos `for` en `bash`](#algunos-tips-para-escribir-ciclos-for-en-bash)
    - [Un par de ejemplos con expansiones de expresiones a listas](#un-par-de-ejemplos-con-expansiones-de-expresiones-a-listas)
    - [Un ejemplo con parámetros posicionales](#un-ejemplo-con-parámetros-posicionales)

<!-- markdown-toc end -->

# Algunos tips para escribir ciclos `for` en `bash`

**Advertencia:** Este es un tutorial muy corto sobre como escribir
algunos bucles o ciclos `for` en `bash`. Esta no es una guía comprensiva
sobre estos elementos del lenguaje. Para información más detallada
consulte [el manual de
`bash`](https://www.gnu.org/software/bash/manual/bash.html#Looping-Constructs).

Para operar con ciclos `for` de forma básica podemos aprender un par de
estrategias. Los ciclos `for` en `bash` operan sobre expansiones de
expresiones a listas ó sobre parámetros posicionales especificados de
forma explícita.

Todos los ciclos `for` escritos en `bash` tienen un encabezado, una
instrucción `do`, un bloque de código que se quiere ejecutar y finalmente
una instrucción `done`. En los ejemplos que veremos todos los ciclos
`for` declaran una variable con la que irá visitando los distintos
objetos a lo largo de la ejecución del ciclo.

Ejemplo de la estructura de un ciclo `for` escrito en múltiples líneas:

``` shell
# vr es la variable declarada para hacer el recorrido

# los tres puntos ... son una elipsis de la lista de objetos
# que vamos a recorrer con el for
for vr in ...
do # abrimos el bloque de código con la instrucción do
    # aquí va el bloque de codigo
    # puede tener una o varias lineas
done # cerramos el bloque de código con la instrucción done
```

Ejemplo de la estructura de un ciclo `for` escrito en una sola línea:

``` shell
# esta es una forma compacta de la estructura mostrada arriba
# separa las partes del ciclo for con el caracter ;
# los primeros tres puntos son una elipsis de la lista de objetos que recorremos
# los segundos tres puntos son una elipsis del bloque de codigo que ejecutamos en el for
for vr in ...; do ...; done
```

## Un par de ejemplos con expansiones de expresiones a listas

1.  **Expansiones con nombres de archivos que se ajustan a un patrón**

    Suponga que el directorio en el que está trabajando actualmente
    contiene 120 archivos de texto que terminan en la extensión `.txt`.
    Para cada uno de estos archivos quiere imprimir la primera línea.
    Recuerde que usamos el operador `*` para hacer expansiones de
    patrones en los nombres de los archivos a una lista que contiene los
    nombres de todos los archivos que contienen el patrón. Si quisieras
    listar los 120 archivos con extensión `.txt` de tu directiorio,
    escribirías `ls *.txt`. Esta expansión se puede usar en el
    encabezado de un ciclo `for` como lo muestra el ejemplo:

    ``` shell
    # arch es mi variable de recorrido
    # *.txt se expande a la lista de archivos con extension .txt
    for arch in *.txt
    do # instruccion do
        # quiero la primera linea de cada archivo de la lista

        # fíjese que hago referencia a la variable arch
        # usando el operador $
        head -n 1 $arch
    done # instruccion done
    ```

    -   [ ] Reto: ¿Puedes escribir este ejemplo en una sola línea?

    -   [ ] Reto: ¿Qué modificaciones haría para incluir la primera
        línea y las últimas tres líneas de cada archivo en un nuevo
        archivo?

2.  **Expansiones con corchetes `{}`**

    Suponga que quieree imprimir en pantalla los números del 1 al 10.
    Puede definir una secuencia de números dentro de corchetes
    especificando los límites de la secuencia separados por el operador
    `..` y encerrados en corchetes `{}`. Luego, la expansión de esta
    secuencia se puede recorrer unando un ciclo `for` como lo muestra el
    ejemplo:

    ``` shell
    for num in {1..10}; do echo $num; done
    ```

    -   [ ] Reto: ¿Puede escribir este ciclo en múltiples líneas?

    -   [ ] Reto: Puede incluir una secuencia de valores arbitrarios
        separados por `,` al interior de los corchetes. Imprime las
        letras `a`, `E`, `Z`, `q`, `t` usando esta estrategia en un
        ciclo `for`.

## Un ejemplo con parámetros posicionales

1.  **Usamos los parámetros posicionales de la siguiente forma**:

    Suponga que queremos imprimir en pantalla los valores 1, 5, 6, 8, 12.
    Podríamos usar la estrategia del último reto pero hay otra forma más
    simple de hacerlo: Podemos escribir los valores separados por
    espacio entre ellos en el encabezado del `for`, como lo muestra el
    ejemplo:

    ``` shell
    for val in 1 5 6 8 12
    do
        echo $val
    done
    ```

    -   [ ] Reto: ¿Qué cambios debe hacer en el ciclo `for` para que el
        orden de la impresión de los números sea el siguiente?

        ``` shell
        12
        5
        1
        6
        8
        ```

    -   [ ] Reto: Suponga que tiene tres archivos de texto plano llamados
        `a1.txt` `lista.log` `caso.err`. ¿Cómo puede imprimir la primera línea
        de cada archivo usando esta estrategia?
