# MSNR by TTQ & Milana — réplica para MetaTrader 5

Indicador MQL5 que replica el **MSNR (Malaysian Support & Resistance)** de TTQ & Milana:
detección multi-timeframe de niveles **A-shape / V-shape**, niveles **OCL (Open/Close Levels)**,
**fusión de niveles** con etiqueta combinada, seguimiento de **frescura** y la **tabla de sesión /
storyline** (Weekly y Daily).

Archivo: `MQL5/Indicators/MSNR_TTQ_Milana.mq5`

## Instalación

1. Abre MetaTrader 5 → `Archivo` → `Abrir carpeta de datos`.
2. Copia `MSNR_TTQ_Milana.mq5` dentro de `MQL5/Indicators/`.
3. En MetaEditor, abre el archivo y pulsa **Compilar** (F7).
4. En MT5, arrastra el indicador `MSNR_TTQ_Milana` al gráfico (recomendado M15, M30 o H1).

> El indicador activa automáticamente el *desplazamiento del gráfico* (chart shift) para que las
> etiquetas, que se dibujan al final de las líneas, queden visibles. Se puede desactivar con
> `Enable chart shift so labels are visible`.

## Lógica replicada

### 1. Detección de niveles (Daily, H4, H1)

Se escanean las velas **cerradas** de cada timeframe habilitado:

| Tipo | Patrón | Precio del nivel | Inicio de la línea |
|------|--------|------------------|--------------------|
| **A** (resistencia) | vela alcista seguida de vela bajista | tope de los cuerpos (`max(close₁, open₂)`) | la vela bajista |
| **V** (soporte) | vela bajista seguida de vela alcista | base de los cuerpos (`min(close₁, open₂)`) | la vela alcista |

Las líneas nacen en la segunda vela del patrón, igual que en el original, y se extienden hacia la
derecha un número configurable de barras (`Extend lines to the right`).

Para mantener el gráfico limpio, de cada timeframe sólo se conservan los **N A-shapes y N V-shapes
más recientes** (`Recent A-shapes and V-shapes kept per timeframe`, 3 por defecto), que es el
comportamiento que muestra el indicador original: en un gráfico de 5 minutos aparecen únicamente los
dos o tres últimos niveles H1 de cada tipo, los últimos H4 y los diarios. El `lookback` sólo limita
cuántas velas se escanean hacia atrás. Opcionalmente se pueden descartar patrones formados por velas
minúsculas con `Min candle body (x ATR14 of the TF)` (p. ej. `0.2`).

En gráficos de timeframe superior al nivel (p. ej. gráfico Diario) los niveles H4/H1 se ocultan,
tal como ocurre en las capturas del indicador original.

### 2. OCL (Open-Close-Levels)

Para cada timeframe con OCL activado se añaden el **Open** (`OCL-O`) y el **Close** (`OCL-C`) de las
últimas *N* velas cerradas (`Daily/H4/H1 OCL Lookback`). Se dibujan con el estilo `OCL Line Style`
(punteado por defecto) y con el color *Open/Close* del timeframe correspondiente.

### 3. Fusión de niveles (Merging)

Los niveles cuyo precio está dentro de la tolerancia (`Merge tolerance`, 0.05 % del precio por
defecto, o un número fijo de puntos) se fusionan en una sola línea. La etiqueta muestra todos los
timeframes y tipos combinados, por ejemplo `D,H4 OCL-O,A` o `D,H4,H1 A,OCL-O`.

Reglas de prioridad al fusionar (reproducen el comportamiento observado):

* El orden de los timeframes en la etiqueta es siempre `D, H4, H1`.
* El tipo de forma (A o V) lo define el componente de mayor timeframe; las formas que se fusionan
  después sólo añaden su timeframe.
* Si la línea contiene algún OCL, adopta el estilo punteado y el color del OCL (p. ej.
  `D,H1 OCL-C,V` se dibuja en rojo punteado = *Daily Close Color*).
* Si no contiene OCL, usa el color de *Resistencia/Soporte* del timeframe más alto que contenga.
* La línea comienza en el componente más antiguo.

### 4. Frescura (Fresh / Unfresh)

Un nivel es **Fresh** mientras ninguna vela posterior a su formación lo haya tocado
(rango `low ≤ nivel ≤ high`). La comprobación se hace sobre el timeframe más bajo de los
componentes fusionados.

* **Fresh** → línea gruesa (`Fresh Line Width`).
* **Unfresh** → línea fina (`Unfresh Line Width`) y color mezclado con el fondo del gráfico según
  `Unfresh Transparency` (MT5 no admite alfa en líneas, por eso se emula con mezcla de color).

Opcionalmente (`Hide levels broken by a candle close`) se ocultan los niveles que ya fueron
rotos por un cierre de vela.

### 5. Límites de niveles

`Max Resistance Levels` / `Max Support Levels` limitan cuántas líneas de cada clase se muestran.
Se conservan las más cercanas al precio actual (o las más recientes, según
`Which levels to keep when limit is hit`).

### 6. Etiquetas y tema

* `Show Timeframe`, `Show Type (A/V/OCL)`, `Show Price`, `Show Status` (● fresh, `=` tested).
* `Label Size`: Tiny / Small / Normal / Large / Huge.
* `Theme Style`: **Light** → texto oscuro, **Dark** → texto blanco.

### 7. Tabla Bias / Storyline

Panel en la esquina elegida (por defecto superior derecha), siempre con estilo oscuro como el
original:

| Fila | Contenido |
|------|-----------|
| Cabecera | `MSNR by TTQxMilana` (texto configurable) |
| Session | `Asia`, `Asia KZ`, `London`, `London KZ`, `New York`, `New York KZ` u `Off-Market` |
| ══ STORYLINE ══ | separador (texto configurable, p. ej. `BIAS`) |
| Weekly | `BULLISH` si el precio está por encima del open semanal, `BEARISH` si está por debajo |
| Daily | igual con el open diario |

Sesiones y killzones se definen en **hora de Nueva York** (`HH:MM-HH:MM`) y son editables:

| Sesión | Por defecto | Killzone |
|--------|-------------|----------|
| Asia | 18:00-02:00 | 20:00-00:00 |
| London | 02:00-08:00 | 02:00-05:00 |
| New York | 08:00-17:00 | 07:00-10:00 |

La hora de Nueva York se obtiene automáticamente desde GMT aplicando el horario de verano de EE. UU.
(`Auto`), o bien con un desplazamiento manual respecto a la hora del servidor (`Manual`).
El fin de semana (viernes tras el cierre de NY hasta la apertura de Asia del domingo) se muestra
como `Off-Market`.

## Parámetros principales

| Grupo | Parámetro | Descripción |
|-------|-----------|-------------|
| STYLE | Theme Style | Light / Dark (color del texto de las etiquetas) |
| TIMEFRAME TOGGLES | Show DAILY / H4 / H1 Levels | Activa cada timeframe |
| DETECTION | Recent A-shapes and V-shapes kept per timeframe | Niveles recientes de cada tipo por TF (limpieza del gráfico) |
| DETECTION | Daily / H4 / H1 lookback | Máximo de velas escaneadas por timeframe |
| DETECTION | Min candle body (x ATR14) | Filtro opcional de cuerpos mínimos (0 = desactivado) |
| DETECTION | Merge tolerance (%) / (points) | Distancia máxima para fusionar niveles |
| OCL | Show Daily/H4/H1 OCL, lookbacks, colores, estilo | Configuración de niveles Open/Close |
| LEVEL LIMITS | Max Resistance / Support Levels | Máximo de líneas por clase |
| COLORS | Daily / H4 / H1 Resistance & Support | Colores de las líneas A / V |
| LINE SETTINGS | Fresh / Unfresh width, transparency, extensión | Estética de las líneas |
| LABEL SETTINGS | Show labels, size, price, timeframe, type, status | Contenido de las etiquetas |
| BIAS TABLE | Show, corner, offsets, title, storyline text | Panel de sesión y storyline |
| SESSIONS | Rangos de sesión/killzone y modo horario | Cálculo de la fila *Session* |

## Notas técnicas

* El indicador no usa buffers; dibuja objetos gráficos con prefijo `MSNR_` y los elimina al
  quitarse del gráfico.
* Los niveles se recalculan como máximo una vez por segundo y en cada nueva barra; los objetos
  existentes se actualizan en sitio para evitar parpadeos.
* MT5 solo dibuja estilos de línea no sólidos con grosor 1, por lo que las líneas OCL punteadas
  se fuerzan a grosor 1.
