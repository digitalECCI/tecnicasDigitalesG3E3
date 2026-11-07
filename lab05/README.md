# Lab05 - Máquinas de Estado Finito: Semáforo Básico en FPGA.

## Integrantes

    * [Cristian Santiago Alfonso Valderrama]
    (https://github.com/CristianAlfonso-ecci) 
    * [Fredi Alexander Melo Prada]
    (https://github.com/Fredi-melo-ecci) 
    * [Fabiam Acevedo]
    (https://github.com/Fabiam-Acevedo-ECCI) 

## Informe

Indice:

1. [Semaforo](#1-Semaforo)
2. [Simulaciones](#2-simulaciones)
3. [Implementación en FPGA](#3-implementación-en-fpga)
4. [Preguntas de análisis](#4-Preguntas-de-análisis)
5. [Conclusiones](#5-conclusiones)
6. [Referencias](#6-referencias)

## Documentación del diseño implementado

Todos los módulos fueron simulados para verificar su correcto comportamiento lógico y, posteriormente, se sintetizaron e implementaron en una FPGA usando Quartus, comprobando su operación en hardware.

## 1. Semaforo

### 1.1 Introducción

El presente informe describe el diseño, la implementación y las pruebas físicas de un sistema de semaforización vehicular y peatonal mediante una tarjeta FPGA DE10-Lite de la familia MAX 10. El desarrollo se realizó en Verilog, utilizando una máquina de estados finitos tipo Moore para organizar la secuencia de funcionamiento y definir las salidas correspondientes a cada etapa del semáforo.

El sistema integra un módulo de control, un divisor de frecuencia y contadores que permiten establecer los intervalos de las luces roja, amarilla y verde. A partir del reloj de 50 MHz de la tarjeta, se genera una referencia temporal de un segundo para controlar la duración de los estados. Asimismo, se coordinan las señales del semáforo vehicular y del peatonal, de manera que el paso peatonal se habilite durante la etapa de rojo vehicular.

Como funcionalidad adicional, se incorporaron un botón de solicitud y un buzzer, con el propósito de proporcionar una indicación sonora durante el verde peatonal cuando exista una solicitud previa del usuario. El diseño se llevó a un montaje físico con la FPGA y dos módulos de semáforo, en el cual se realizaron pruebas del prototipo.

Este laboratorio permitió aplicar conceptos de lógica combinacional y secuencial, máquinas de estados, temporización y descripción de hardware. En el informe se presentan la arquitectura del sistema, los cálculos de temporización, la implementación en Verilog, las evidencias del montaje y el análisis de los resultados obtenidos.

### 1.2 Marco teórico

### - Sistemas secuenciales y máquinas de estados finitos

Un sistema digital secuencial conserva información sobre su funcionamiento anterior mediante registros. A diferencia de la lógica combinacional, cuya salida depende de las entradas actuales, un sistema secuencial utiliza también la información almacenada para determinar su comportamiento.

Una máquina de estados finitos, o FSM (Finite State Machine), permite representar este comportamiento mediante un conjunto limitado de estados y reglas de transición. Sus elementos principales son:

- Estados: representan las condiciones de funcionamiento del sistema.
- Entradas: corresponden a las señales que intervienen en las decisiones de control.
- Lógica de transición: determina el próximo estado.
- Salidas: son las señales de control generadas por la máquina.
- Estado inicial: establece la condición de arranque o reinicio.

En el semáforo, los estados representan las distintas etapas de circulación, mientras que el cumplimiento del tiempo asignado a cada etapa determina las transiciones.

### - Modelos Moore y Mealy

Las máquinas de estados se clasifican principalmente en los modelos Moore y Mealy. En una máquina Moore, las salidas dependen del estado actual. En una máquina Mealy, las salidas dependen tanto del estado actual como de las entradas.

El control principal del semáforo se desarrolla mediante el modelo **Moore**, ya que cada estado establece una combinación definida de luces vehiculares y peatonales. Así, las entradas y los contadores determinan cuándo debe producirse una transición, mientras que el estado determina cuáles luces se activan.

Esta organización facilita la representación del sistema mediante un diagrama de estados y permite separar las decisiones de transición de las señales que controlan los módulos luminosos.

### - Secuencia del semáforo vehicular y peatonal

El sistema coordina el paso vehicular y peatonal mediante una secuencia repetitiva. En el diseño desarrollado se distinguen cuatro estados:

| Estado | Luz vehicular activa | Luz peatonal activa | Duración programada |
|---|---|---|---|
| Rojo vehicular | Roja | Verde | 10 s |
| Amarillo hacia verde | Amarilla | Roja | 3 s |
| Verde vehicular | Verde | Roja | 10 s |
| Amarillo hacia rojo | Amarilla | Roja | 3 s |

Aunque las dos etapas amarillas activan la misma luz, se representan mediante estados diferentes porque conducen a estados distintos. Una precede al verde vehicular y la otra al rojo vehicular.

La coordinación establece que el verde peatonal se habilite durante el rojo vehicular. Durante las etapas amarillas y el verde vehicular, el semáforo peatonal permanece en rojo. Esta relación evita que el diseño autorice simultáneamente el paso vehicular y peatonal.

La guía presenta cuatro etapas en su diagrama, aunque algunos apartados mencionan tres estados. Para este desarrollo se distinguen las cuatro etapas, conservando los intervalos de 10 s y 3 s indicados.

### - Organización de la FSM en Verilog

La descripción de la máquina se organiza en tres bloques:

1. Registro de estado: almacena el estado actual y se actualiza en el flanco positivo del reloj.
2. Lógica de próximo estado: evalúa el estado actual y las condiciones de transición.
3. Lógica de salida: determina las luces que deben activarse en cada estado.

En Verilog, el bloque secuencial se describe mediante `always @(posedge clk)`, mientras que los bloques combinacionales se describen mediante `always @(*)`.

Esta separación facilita la lectura, la simulación y la revisión del diseño. En los bloques combinacionales deben asignarse valores a todas las salidas en cada posible condición, mediante valores predeterminados o ramas completas, para evitar la inferencia de almacenamiento no deseado.

### - Referencia temporal y divisor de frecuencia

El diseño utiliza el reloj de 50 MHz de la tarjeta como referencia temporal. Esta frecuencia equivale a 50.000.000 ciclos por segundo y corresponde a un periodo de 20 ns.

Para controlar intervalos de varios segundos, un contador genera una señal de habilitación denominada `tick_1hz`. Esta señal se activa durante un ciclo del reloj principal y se repite una vez por segundo.

La cantidad de ciclos entre pulsos se obtiene mediante la relación entre la frecuencia del reloj y la frecuencia de repetición deseada. Para un reloj de 50 MHz y una repetición de 1 Hz, se requieren 50.000.000 ciclos. Como el contador comienza en cero, el valor final de comparación es `49_999_999`.

El tick no es una onda cuadrada que permanezca medio segundo en alto y medio segundo en bajo. Es un pulso breve que habilita la actualización del contador de segundos, mientras los registros continúan trabajando con el reloj principal. El uso de pulsos de habilitación permite mantener una referencia de reloj común para la lógica secuencial.

### - Contadores y duración de los estados

Los contadores permiten transformar los pulsos de referencia en intervalos de tiempo. En el semáforo, el contador de duración avanza una vez por cada `tick_1hz`.

Para una etapa de diez segundos, el conteo comienza en cero y recorre los valores de 0 a 9; al recibir el décimo tick se produce la transición. Para una etapa de tres segundos, recorre los valores de 0 a 2 y cambia de estado con el tercer tick.

El ancho del registro debe permitir representar todos los valores utilizados. Un contador de cuatro bits puede representar valores de 0 a 15, por lo que resulta suficiente para contar las duraciones de tres y diez segundos.

El contador del divisor requiere una capacidad mayor, porque debe representar valores hasta `49_999_999`. El mínimo necesario es 26 bits; utilizar un registro de mayor ancho también permite realizar ese conteo. Los contadores y las señales temporales deben generarse de forma síncrona para conservar una relación definida con el reloj principal.

### - Botón de solicitud y alarma sonora

El laboratorio contempla una ampliación mediante un botón y una alarma sonora. Su propósito es acompañar el verde peatonal con una señal audible únicamente cuando el usuario haya realizado una solicitud previa.

Para conservar esa solicitud después de liberar el botón, el sistema necesita un registro de memoria. Mientras el paso peatonal está bloqueado, una pulsación válida almacena la solicitud. Al comenzar el verde peatonal, la lógica puede habilitar el buzzer si dicha solicitud está pendiente.

Al finalizar el intervalo autorizado, la solicitud atendida debe borrarse para evitar que la alarma se active indefinidamente en los ciclos posteriores. Por tanto, la orden de activación del buzzer depende tanto de la etapa peatonal como de la solicitud almacenada; esta lógica complementa la FSM Moore que controla las luces.

### Evidencias de simulación

La simulación permite comprobar la secuencia de estados, los tiempos de permanencia y la relación entre las salidas antes de evaluar el montaje físico. Para ello se utiliza un testbench, que genera el reloj, aplica el reinicio y establece las condiciones de prueba.

Las formas de onda permiten observar el estado actual, los contadores, las luces vehiculares y peatonales y, cuando se incluye la ampliación, la solicitud y la orden de activación del buzzer. La guía propone utilizar Icarus Verilog y capturar las formas de onda como evidencia del comportamiento temporal.

La implementación física complementa esta verificación mediante la programación de la FPGA y la conexión de los módulos externos. En esta etapa se contrastan las señales descritas en Verilog con el comportamiento observable de los semáforos, manteniendo una distinción entre los tiempos programados y los tiempos que hayan sido medidos experimentalmente.

---
## 1.3 Diseño del sistema

### - Arquitectura del sistema

El diseño se divide en los siguientes bloques funcionales:

| Bloque | Función |
|---|---|
| Generador de referencia temporal | Cuenta ciclos del reloj de 50 MHz y produce un pulso de habilitación cada segundo. |
| Contador de duración | Cuenta los pulsos de un segundo para determinar cuándo termina cada etapa. |
| Máquina de estados | Define la secuencia de funcionamiento y el próximo estado. |
| Lógica de salidas | Establece las luces vehiculares y peatonales correspondientes al estado actual. |
| Registro de solicitud | Conserva la solicitud realizada mediante el botón. |
| Control del buzzer | Habilita la alarma durante el verde peatonal cuando existe una solicitud pendiente. |

La arquitectura separa la generación de tiempo de la lógica de control. De esta forma, el contador determina cuándo debe ocurrir una transición y la máquina de estados establece qué salidas deben activarse.

### - Diagrama de bloques:

![Diagrama-de-bloques.png](Evidencias/Diagrama de bloques.png)

### - Definición de los estados

La máquina se organizó en cuatro estados. Aunque existen tres colores vehiculares, se utilizaron dos estados diferentes para la luz amarilla, debido a que cada uno conduce a una etapa distinta.

| Estado | Codificación | Descripción | Duración |
|---|:---:|---|:---:|
| Rojo vehicular | `00` | Detiene los vehículos y habilita el paso peatonal. | 10 s |
| Amarillo hacia verde | `01` | Mantiene bloqueado el paso peatonal y precede al verde vehicular. | 3 s |
| Verde vehicular | `10` | Habilita el paso vehicular y mantiene el rojo peatonal. | 10 s |
| Amarillo hacia rojo | `11` | Mantiene bloqueado el paso peatonal y precede al rojo vehicular. | 3 s |

La secuencia programada es:

Rojo vehicular → Amarillo hacia verde → Verde vehicular → Amarillo hacia rojo → Rojo vehicular.

El ciclo completo tiene una duración nominal de 26 segundos, correspondiente a la suma de los cuatro intervalos programados.

![DIAGRAMA_DE_ESTADOS.jpeg](Evidencias/DIAGRAMA DE ESTADOS.jpeg)


### 4- Tabla de salidas

Las salidas de los semáforos se determinan a partir del estado actual. En la siguiente tabla, `1` representa una orden lógica de encendido y `0` una orden de apagado.

| Estado | Rojo vehicular | Amarillo vehicular | Verde vehicular | Rojo peatonal | Verde peatonal |
|---|:---:|:---:|:---:|:---:|:---:|
| Rojo vehicular | 1 | 0 | 0 | 0 | 1 |
| Amarillo hacia verde | 0 | 1 | 0 | 1 | 0 |
| Verde vehicular | 0 | 0 | 1 | 1 | 0 |
| Amarillo hacia rojo | 0 | 1 | 0 | 1 | 0 |

La tabla permite comprobar que el verde vehicular y el verde peatonal nunca se ordenan simultáneamente. Asimismo, durante las dos etapas amarillas, el semáforo peatonal permanece en rojo.

Los valores de esta tabla describen la lógica de control; su correspondencia eléctrica debe coincidir con la polaridad de los módulos utilizados en el montaje.

### 4.5. Temporización y condiciones de transición

El reloj principal de 50 MHz proporciona la referencia temporal del sistema. El generador de tiempo cuenta 50.000.000 ciclos y produce un pulso de habilitación denominado `tick_1hz`, cuya repetición corresponde a un segundo.

El contador de duración avanza únicamente cuando recibe este pulso. Al completarse el intervalo del estado actual, la FSM cambia al siguiente estado y el contador comienza el conteo de la nueva etapa.

| Estado actual | Condición de finalización | Estado siguiente |
|---|---|---|
| Rojo vehicular | Completar 10 ticks | Amarillo hacia verde |
| Amarillo hacia verde | Completar 3 ticks | Verde vehicular |
| Verde vehicular | Completar 10 ticks | Amarillo hacia rojo |
| Amarillo hacia rojo | Completar 3 ticks | Rojo vehicular |

Al iniciar el conteo desde cero, las etapas de diez segundos utilizan los valores de 0 a 9 y realizan la transición con el décimo tick. Las etapas de tres segundos utilizan los valores de 0 a 2 y realizan la transición con el tercer tick.

El reinicio establece una condición conocida para la máquina de estados, el contador de duración y el registro de solicitud de la alarma.

### -  Diseño de la solicitud de alarma sonora

La alarma se diseñó como una funcionalidad adicional al control de las luces. El botón no cambia directamente el estado del semáforo ni adelanta el paso peatonal; su función es registrar una solicitud de acompañamiento sonoro.

El comportamiento previsto es el siguiente:

1. El usuario presiona el botón mientras el paso peatonal está bloqueado.
2. El sistema conserva la solicitud en un registro.
3. Al comenzar el verde peatonal, se habilita el buzzer si existe una solicitud pendiente.
4. La alarma permanece habilitada durante ese intervalo.
5. Al finalizar el verde peatonal, se desactiva la alarma y se elimina la solicitud atendida.

La condición lógica de habilitación puede expresarse como:

`alarma_habilitada = verde_peatonal AND solicitud_almacenada`

Esta expresión representa la orden de activación de la alarma, no necesariamente la señal eléctrica de excitación del buzzer. La generación de esa señal depende del dispositivo utilizado.

### - Entradas y salidas del diseño

Las señales principales utilizadas para integrar los bloques son:

| Señal | Tipo | Función |
|---|---|---|
| `clk` | Entrada | Reloj principal de 50 MHz. |
| `rst` | Entrada | Reinicia el sistema a su condición inicial. |
| `boton_alarma` | Entrada | Permite solicitar la indicación sonora. |
| `veh_rojo` | Salida | Control de la luz roja vehicular. |
| `veh_amarillo` | Salida | Control de la luz amarilla vehicular. |
| `veh_verde` | Salida | Control de la luz verde vehicular. |
| `peat_rojo` | Salida | Control de la luz roja peatonal. |
| `peat_verde` | Salida | Control de la luz verde peatonal. |
| `buzzer` | Salida | Control de la alarma sonora. |

Las señales internas incluyen el estado actual, el próximo estado, el tick de un segundo, el contador de duración y el registro de solicitud.

## Codificación en código Verilog:

### Divisor de frecuencia (señal de reloj clk)

```verilog
module divisor (
    input clk,
    input rst,
    output reg tick
);

    reg [15:0] count;

    always @(posedge clk) begin

        if (rst) begin
            count <= 0;
            tick <= 0;
        end

        else if (count == 49999) begin
            count <= 0;
            tick <= 1;
        end

        else begin
            count <= count + 1;
            tick <= 0;
        end

    end

endmodule
```

### Módulo selector de velocidad
```verilog
`include "cronometro.v"
//`include "divisor.v"

module seleccion (
    input clk,
    input rst,
    input tick,
    input [1:0] sw,
    output reg en
);

    reg [9:0] count;
    reg [9:0] limit;

    always @(*) begin

        case (sw)

            2'b00: limit = 10'd999;
            2'b01: limit = 10'd99;
            2'b10: limit = 10'd9;
            2'b11: limit = 10'd0;

            default: limit = 10'd999;

        endcase

    end

    always @(posedge clk) begin

        if (rst) begin
            count <= 0;
            en <= 0;
        end

        else begin

            en <= 0;

            if (tick) begin

                if (count == limit) begin
                    count <= 0;
                    en <= 1;
                end

                else begin
                    count <= count + 1;
                end

            end

        end

    end

endmodule
```
### Módulo decodificador de 7 segmentos(anodo comun)

```verilog

module siete_seg (
    input [3:0] A,
    output reg [6:0] seg
);

    always @(*) begin

        case (A)

            4'b0000: seg = 7'b1000000;
            4'b0001: seg = 7'b1111001;
            4'b0010: seg = 7'b0100100;
            4'b0011: seg = 7'b0110000;
            4'b0100: seg = 7'b0011001;
            4'b0101: seg = 7'b0010010;
            4'b0110: seg = 7'b0000010;
            4'b0111: seg = 7'b1111000;
            4'b1000: seg = 7'b0000000;
            4'b1001: seg = 7'b0010000; // se deja haboilitado hasta el numero decimal 9 
            // 4'b1010: seg = 7'b0001000;
            // 4'b1011: seg = 7'b0000011;
            // 4'b1100: seg = 7'b1000110;
            // 4'b1101: seg = 7'b0100001;
            // 4'b1110: seg = 7'b0000110;
            // 4'b1111: seg = 7'b0001110;

            default: seg = 7'b1111111;

        endcase

    end

endmodule

```
### Módulo principal del cronómetro


``` verilog
`include "contador.v"
`include "divisor.v"
`include "7_seg.v"

module cronometro (
    input clk,
    input rst,
    input tick,
    input en,

    output [3:0] mil,
    output [3:0] cen,
    output [3:0] dec,
    output [3:0] seg
);

    wire en_mil;
    wire en_cen;
    wire en_dec;
    wire en_seg;

    assign en_mil = en;

    assign en_cen = en &&
                    (mil == 9);

    assign en_dec = en &&
                    (mil == 9) &&
                    (cen == 9);

    assign en_seg = en &&
                    (mil == 9) &&
                    (cen == 9) &&
                    (dec == 9);

    contador mili (
        .clk(clk),
        .rst(rst),
        .en(en_mil),
        .q(mil)
    );

    contador cent (
        .clk(clk),
        .rst(rst),
        .en(en_cen),
        .q(cen)
    );

    contador dece (
        .clk(clk),
        .rst(rst),
        .en(en_dec),
        .q(dec)
    );

    contador segu (
        .clk(clk),
        .rst(rst),
        .en(en_seg),
        .q(seg)
    );

endmodule

```

### Modulo Selector (se carga en quartus, encargado de seleccionar)

El módulo `select` se encarga de decidir qué valor se muestra en el display de 7 segmentos: el resultado de la suma o el valor de la entrada `A`, según la posición del interruptor `sel`.

- Si `sel = 0`, se muestra el resultado de la suma (`res`).
- Si `sel = 1`, se muestra directamente el valor de `A`.

El bloque `always @(*)` hace esta selección de forma automática: cada vez que cambia `sel`, `A` o el resultado de la suma, actualiza la salida `So` sin necesidad de un reloj. Finalmente, el módulo envía el valor seleccionado al decodificador de 7 segmentos para que se visualice en el display.

```verilog
`include "sumadorthree.v"
`include "seg.v"

module select (
    input wire [3:0] A,
    input wire [3:0] B,
    input wire Ci,
    input wire sel,
    output wire[6:0] seg,
    output reg [3:0] So
);

    wire [3:0] res;
    sum3b sum (
        .A(A[2:0]),
        .B(B),
        .Ci(Ci),
        .So(res),
        .Co()
    );
    always @(*) begin
        case (sel)
            1'b0: begin
                So = res;
            end
            1'b1: begin
                So = A;
            end
        endcase
    end

    seg segs (
        .A(So),
        .seg(seg)
    );   
endmodule
```

Codificación en código Verilog tb_selector:

```verilog
`timescale 1ns / 1ps
`include "sel.v"

module tb_sel;
    reg [3:0] A;
    reg [2:0] B;
    reg Ci;
    reg sel;

    wire [6:0] seg;
    wire [3:0] So;

    integer i, j;

    select uut (
        .A(A),
        .B(B),
        .Ci(Ci),
        .sel(sel),
        .seg(seg),
        .So(So)
    );

initial begin
    $dumpfile("tb_sel.vcd");
    $dumpvars(0,tb_sel);

    for(i=0; i<16; i=i+1) begin
        for(j=0; j<8; j=j+1) begin
            A=i;
            B=j;
            Ci=0;
            sel=0;
            #10;
        end
    end
    for(i=0; i<16; i=i+1) begin
            A=i;
            Ci=0;
            sel=1;
            #10;
    end
end
endmodule
```

---

## 2. Simulaciones

Antes de llevar a cabo la implementación física, el diseño se sometió a un proceso de simulación por GTKWAVE con el fin de verificar el comportamiento lógico del circuito.

---
- CRONOMETRO

![Simulación tb_cronometro_1.png](   Evidencias/tb_cronometro_1.png)

![Simulación tb_cronometro_2.png](   Evidencias/tb_cronometro_2.png)


## 3. Implementación en FPGA

Después de verificar el funcionamiento de los módulos mediante simulación, se implementó el diseño completo del cronómetro en la FPGA Altera MAX 10 utilizando el software Quartus. El sistema integró el divisor de frecuencia, el selector de velocidad, los contadores decimales conectados en cascada y los módulos decodificadores para display de 7 segmentos.

Para visualizar el conteo se utilizaron cuatro displays de 7 segmentos. Cada display representa uno de los dígitos del cronómetro: milisegundos, centésimas, décimas y segundos. Las salidas de 4 bits generadas por los contadores (`mil`, `cen`, `dec` y `seg`) se conectaron a cuatro instancias del módulo `siete_seg`,encargado de convertir cada valor BCD en las siete señales necesarias para controlar los segmentos del display.

La disposición lógica empleada fue la siguiente:

```text
HEX3   HEX2   HEX1   HEX0
 seg    dec    cen    mil
```

De esta forma, el dígito de menor peso (`mil`) se visualiza en `HEX0`, mientras que el contador de segundos (`seg`) se visualiza en `HEX3`. Por ejemplo, para el valor `1.234`, los displays presentan los valores `1`, `2`, `3` y `4`.

La asignación de las señales a los pines físicos de la tarjeta se realizó mediante la herramienta Pin Planner de Quartus. Se configuraron las entradas correspondientes al reloj, al reinicio y a los interruptores de control, así como las salidas de cada uno de los cuatro displays: `HEX0[6:0]`, `HEX1[6:0]`, `HEX2[6:0]` y `HEX3[6:0]`.

Debido a que la tarjeta utiliza displays de ánodo común, la lógica de control es activa en bajo. Por esta razón, el decodificador asigna un valor lógico `0` a los segmentos que deben encenderse y un valor `1` a los segmentos que deben permanecer apagados.

Finalmente, el diseño fue compilado y programado en la FPGA. La implementación física permitió comprobar el avance del cronómetro y verificar que los cuatro displays actualizaran los valores de manera sincronizada de acuerdo con la velocidad seleccionada mediante los switche

### Evidencias de implementación

En esta sección se incorporan las evidencias obtenidas durante la implementación y demostración del funcionamiento de los circuitos en FPGA.

[Ver implementación de DIVISOR DE FRECUENCIA EN UN CRONOMETRO descrito en FPGA con salida en display de 7 segmentos](https://youtu.be/m1DGkvdYnMI)

---

## 4. Resultados

La simulación permitió comprobar el funcionamiento integrado del cronómetro antes de su implementación física. Mediante el testbench se verificó la generación de los pulsos de habilitación, el comportamiento de los contadores decimales y la propagación del acarreo entre los cuatro dígitos. Se observó que cada contador avanzaba únicamente cuando recibía su respectiva señal de habilitación y que, al alcanzar el valor `9`, retornaba a `0`, permitiendo el incremento del dígito inmediatamente superior.

Asimismo, se validó el funcionamiento del divisor de frecuencia y del módulo selector de velocidad. Dependiendo de la combinación aplicada a los interruptores `sw[1:0]`, el sistema modificó la cantidad de pulsos `tick` necesarios para generar la señal `en`. Esto permitió obtener diferentes velocidades de conteo sin alterar la señal de reloj principal de la FPGA.

Durante la simulación, las salidas `mil`, `cen`, `dec` y `seg` mostraron una secuencia de conteo decimal coherente. Por ejemplo, al completarse el ciclo de los dígitos inferiores, se observó la transición de `0.999` a `1.000`, confirmando el funcionamiento correcto de la lógica de acarreo en cascada.

La implementación en la FPGA Altera MAX 10 confirmó los resultados obtenidos en el entorno de simulación. Los cuatro displays de 7 segmentos visualizaron de forma sincronizada los valores generados por los contadores, representando las unidades de milisegundo, centésimas, décimas y segundos. Al modificar los interruptores de selección, fue posible observar directamente el cambio en la velocidad de avance del cronómetro.

Finalmente, se comprobó que el decodificador BCD a 7 segmentos operó correctamente con los displays de ánodo común de la tarjeta. Los dígitos entre `0` y `9` se visualizaron de acuerdo con las señales generadas por el módulo `siete_seg`, utilizando lógica activa en bajo, donde un `0` lógico enciende el segmento correspondiente. De esta forma, la implementación física validó la correspondencia entre la simulación en Verilog y el comportamiento real del sistema en hardware.



## 5. Conclusiones

- Se diseñó e implementó un cronómetro digital en Verilog para una FPGA Altera MAX 10, integrando un divisor de frecuencia, un selector de velocidad, contadores BCD en cascada y decodificadores para displays de 7 segmentos.

- La estructura modular del diseño facilitó la construcción, simulación y verificación de cada bloque funcional, permitiendo integrar el sistema completo de manera organizada y reutilizable.

- El divisor de frecuencia y el selector controlaron la velocidad de avance del cronómetro mediante pulsos de habilitación (`en`), evitando modificar directamente el reloj principal de la FPGA y manteniendo un funcionamiento síncrono.

- La conexión en cascada de cuatro contadores módulo 10 permitió representar milisegundos, centésimas, décimas y segundos. La lógica de acarreo aseguró transiciones correctas entre los dígitos, por ejemplo, de `0.999` a `1.000`.

- La simulación y la implementación física validaron el comportamiento del sistema. Los cuatro displays de 7 segmentos visualizaron correctamente el conteo mediante lógica activa en bajo, propia de los displays de ánodo común de la FPGA.
---

## 6. Referencias

* Material de clase de la asignatura Técnicas Digitales, Universidad ECCI.
* Documentación y material proporcionado para el Laboratorio 04: divisor de frecuencia.
* IEEE Standard for Verilog Hardware Description Language.
* Manual de usuario DE10-Lite Cost-effective Max 10 board
