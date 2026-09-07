        
# Lab01 - Sumador/Restador de 4 bits

# Integrantes
    * [Cristian Santiago Alfonso Valderrama]
    (https://github.com/CristianAlfonso-ecci) 
    * [Fredi Alexander Melo Prada]
    (https://github.com/Fredi-melo-ecci) 
    * [Fabiam Acevedo]
    (https://github.com/Fabiam-Acevedo-ECCI) 

# Informe

Indice:

1. [Documentación](#documentación-de-los-circuitos-implementados-implementado)
2. [Simulaciones](#simulaciones)
3. [Evidencias de implementación](#evidencias-de-implementación)
4. [Preguntas](#preguntas)
5. [Conclusiones](#conclusiones)
6. [Referencias](#referencias)

## Documentación del diseño implementado
En esta práctica se diseñaron circuitos de lógica combinacional en Verilog, a partir del análisis de tablas de verdad y de las expresiones booleanas asociadas.

Desarrollo de la práctica
Primero se modelaron las compuertas básicas NOT, AND, OR, XOR y XNOR, y se validó su funcionamiento mediante simulación.

Luego se diseñó un circuito combinacional que detecta números primos codificados en 3 bits, evaluando todas las combinaciones posibles de entrada.

Por último, se implementó un sumador completo de 1 bit con entradas A, 𝐵 y 𝐶in, y salidas de suma S y acarreo Cout.

Todos los módulos fueron simulados para verificar su correcto comportamiento lógico y, posteriormente, se sintetizaron e implementaron en una FPGA usando Quartus, comprobando su operación en hardware.
### 1. Compuertas

#### 1.1 Compuerta AND
La compuerta AND produce un `1` únicamente cuando todas sus entradas son `1`.

| A | B | S |
| - | - | - |
| 0 | 0 | 0 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

Codificación en código Verilog:

```verilog
module and_gate(
    input A,
    input B,
    output S
);

and (S, A, B);

endmodule
```

#### 1.2 Compuerta NOT

La compuerta NOT tiene una entrada y una salida. Su función es invertir el valor lógico de la entrada; en el ejercicicio se nego la entrada A.

| A | S |
| - | - |
| 0 | 1 |
| 1 | 0 |

Codificación en código Verilog:

```verilog
module not_gate(
    input A,
    output S
);

not (S, A);

endmodule
```

### 1.3. Compuerta OR

La compuerta OR produce un `1` cuando al menos una de sus entradas es `1`.

| A | B | S |
| - | - | - |
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 1 |

Codificación en código Verilog:

```verilog
module or_gate(
    input A,
    input B,
    output S
);

or (S, A, B);

endmodule
```

### 1.4. Compuerta XOR

La compuerta XOR produce un `1` cuando sus entradas son diferentes.

| A | B | S |
| - | - | - |
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

Codificación en código Verilog:

```verilog
module xor_gate(
    input A,
    input B,
    output S
);

xor (S, A, B);

endmodule
```

### 1.5. Compuerta XNOR

La compuerta XNOR produce un `1` cuando sus entradas son iguales.

| A | B | S |
| - | - | - |
| 0 | 0 | 1 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

Codificación en código Verilog:

```verilog
module xnor_gate(
    input A,
    input B,
    output S
);

xnor (S, A, B);

endmodule
```

### Evidencia de simulación

Las tablas de verdad fueron verificadas mediante simulación ejecutando GTKWAVE (Verilog) de los respectivos módulos.    

![Simulación de compuertas lógicas](evidencias/Compuerta_AND.png)
![Simulación de compuertas lógicas](evidencias/Compuerta_NOT.png)
![Simulación de compuertas lógicas](evidencias/Compuerta_OR.png)
![Simulación de compuertas lógicas](evidencias/Compuerta_XNOR.png)
![Simulación de compuertas lógicas](evidencias/Compuerta_XOR.png)
---

## 2. Verificador de números primos     

Se diseñó un circuito combinacional capaz de determinar si un número binario de tres bits corresponde a un número primo.

Los números representables con tres bits son:

| A | B | C | Decimal | Primo |
| - | - | - | ------: | ----- |
| 0 | 0 | 0 |       0 | 0     |
| 0 | 0 | 1 |       1 | 0     |
| 0 | 1 | 0 |       2 | 1     |
| 0 | 1 | 1 |       3 | 1     |
| 1 | 0 | 0 |       4 | 0     |
| 1 | 0 | 1 |       5 | 1     |
| 1 | 1 | 0 |       6 | 0     |
| 1 | 1 | 1 |       7 | 1     |

Por lo tanto, la salida debe activarse para los valores 2, 3, 5 y 7.

La función lógica implementada fue:

```text
P = (~A & B) | (~A & C) | (B & C)
```

Implementación en Verilog:

```verilog
module primos(
    input [2:0] A,
    output S
);

//BOOLEANA: S = ~AB + AC
assign S = (~A[2]&A[1])|(A[2]&A[0]);
endmodule
```

### Evidencia de simulación

El funcionamiento del detector de números primos fue comprobado mediante simulación, verificando los ocho posibles valores de entrada.

![Simulación de compuertas lógicas](evidencias/NUMEROS_PRIMOS.png)

## 3. Sumador de 1 bit

Un sumador completo de un bit posee tres entradas:

* `A`: primer bit de entrada.
* `B`: segundo bit de entrada.
* `Cin`: acarreo de entrada.

Y dos salidas:

* `S`: resultado de la suma.
* `Cout`: acarreo de salida.

### Tabla de verdad

| A | B | Cin | Cout | S |
| - | - | --- | ---- | - |
| 0 | 0 | 0   | 0    | 0 |
| 0 | 0 | 1   | 0    | 1 |
| 0 | 1 | 0   | 0    | 1 |
| 0 | 1 | 1   | 1    | 0 |
| 1 | 0 | 0   | 0    | 1 |
| 1 | 0 | 1   | 1    | 0 |
| 1 | 1 | 0   | 1    | 0 |
| 1 | 1 | 1   | 1    | 1 |

Las expresiones utilizadas fueron:

```text
S = Ci ^ ( A ^ B);
Co = ( B & Ci ) | A & ( B | Ci);
```

Implementación en Verilog:

```verilog
module sumador(
    
    input A,
    input B,
    input Ci,

    output S,
    output Co

);

assign S = Ci ^ ( A ^ B);
assign Co = ( B & Ci ) | A & ( B | Ci);

endmodule
```

### Evidencia de simulación

El sumador completo fue verificado mediante simulación para las ocho combinaciones posibles de sus entradas.

![Simulación de compuertas lógicas](evidencias/Sumador%20de%201%20bit.jpeg)
---




## Evidencias de implementación


## Conclusiones


## Referencias

