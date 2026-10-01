# Panel de Control para MT5 — Herramienta de Análisis de Trading

Expert Advisor para **MetaTrader 5** que muestra, sobre el propio gráfico, un panel de
estadísticas en tiempo real basado en las **posiciones cerradas** de la cuenta. No abre ni
cierra operaciones: es exclusivamente una herramienta de análisis.

Interfaz completa en español, diseño oscuro fiel a las capturas de referencia y adaptación
automática al tamaño del gráfico.

```
MQL5/
├── Experts/PanelControlMT5.mq5     ← Expert Advisor: un único archivo independiente
└── Presets/panel_demo.set          ← preset con el modo de demostración activado
```

**Todo el proyecto está en un solo archivo `.mq5`**, sin `#include` ni librerías externas
(tampoco usa la librería estándar `Canvas.mqh`: el lienzo se implementa con las funciones
nativas `ResourceCreate`, `TextSetFont` y `TextOut`). Para no colisionar con otros programas
instalados en el terminal, **todos los identificadores globales llevan el prefijo `PControl_`**:

| Tipo | Ejemplos |
|---|---|
| Clases | `PControl_Render`, `PControl_TradeData`, `PControl_Panel`, `PControl_LongIntMap` |
| Estructuras | `PControl_PosRecord`, `PControl_DayStat`, `PControl_Stats`, `PControl_Rect`, `PControl_Hit`, `PControl_Settings` |
| Enumeraciones | `ENUM_PControl_TAB`, `ENUM_PControl_RANGE`, `ENUM_PControl_ACTION`… y sus valores (`PControl_TAB_CHART`, `PControl_ACT_MINIMIZE`…) |
| Funciones y macros | `PControl_Money()`, `PControl_PnLColor()`, `PControl_CLR_GREEN`, `PControl_MONTHS[]`… |
| Variable global | `g_PControl_panel` |
| Objeto gráfico | `PControl_Canvas_<id del gráfico>` |

El archivo está organizado en secciones numeradas (configuración, capa de dibujo, datos,
núcleo del panel, una sección por pestaña y, al final, los parámetros de entrada y los
manejadores de eventos del EA).

## Instalación

1. Abre MetaTrader 5 → `Archivo` → `Abrir carpeta de datos`.
2. Copia `MQL5/Experts/PanelControlMT5.mq5` en la carpeta `MQL5/Experts` del terminal
   (y, opcionalmente, `MQL5/Presets/panel_demo.set` en `MQL5/Presets`).
3. En MetaEditor abre `PanelControlMT5.mq5` y pulsa **Compilar** (F7).
4. En el terminal, arrastra `PanelControlMT5` desde el Navegador (`Asesores Expertos`) a
   cualquier gráfico. No requiere permiso de trading automático.

> El archivo está guardado en UTF-8 con BOM para que MetaEditor muestre correctamente
> los acentos y la letra ñ.

## Características

### Cabecera y tarjetas superiores

| Tarjeta | Contenido |
|---|---|
| **P&L Total** | Beneficio neto del rango filtrado (`G:` ganancia bruta, `P:` pérdida bruta) y barra de progreso respecto a la base configurable `InpPnLBase` (100 por defecto): verde si el neto es positivo, roja si es negativo. |
| **Operaciones Ganadoras** | Número de operaciones del periodo con beneficio neto positivo, su porcentaje sobre el total y la ganancia media. |
| **Operaciones Perdedoras** | Número de operaciones del periodo con beneficio neto negativo, su porcentaje sobre el total y la pérdida media. |
| **Operaciones / WR** | Número de operaciones, tasa de acierto y desglose ganadas/perdidas. |
| **DD Máximo del Periodo** | Mayor caída pico-valle de la curva de balance dentro del rango filtrado, en dinero y %, con barra de consumo respecto a `InpMaxDrawdownPct`. |
| **Swap y Comisión** | Totales de swap y comisión (+ fees) del rango. |

Botones de rango temporal: **Hoy · Semana · Mes · Todo · Personalizado** (abre un selector de
fecha de inicio y fin). A la derecha, botones para **minimizar** (deja solo la barra con un
resumen) y **maximizar** (alternar entre pantalla completa y modo ventana).

### Panel lateral de filtros

- **SF** — Filtros de Símbolo: casilla `TODOS` + una casilla por cada símbolo operado, con su
  cuadro de color.
- **MN** — Filtros de Mágico: una casilla por cada número mágico (0 = operaciones manuales).
- **TP** — Filtro por Tipo: Compra / Venta.

La lista se desplaza con la rueda del ratón cuando hay muchos elementos.

### Pestañas

1. **Gráfico** — Evolución del P&L neto acumulado con relleno verde/rojo, rejilla, ejes y
   tooltip al pasar el ratón (fecha, P&L acumulado y operación).
2. **Transacciones** — Tabla paginada (símbolo, tipo, mágico, volumen, apertura, cierre,
   duración, beneficio neto). Navegación con botones `<` `>` o rueda del ratón.
3. **Calendario** — Desglose mensual: celdas por día con P&L, porcentaje sobre el balance
   inicial del día, drawdown intradía (`-x% DD`) y línea `T G P WR`. Columna de **Totales**
   semanales con porcentaje, barra resumen del mes (operaciones, ganadas, perdidas, beneficio,
   porcentaje) y navegación entre meses. Clic en un día → popup con sus operaciones.
   *El calendario ignora el rango temporal de la cabecera (navega por meses), pero respeta los
   filtros de símbolo, mágico y tipo.*
4. **Por Hora** — Mapa de calor 7 × 24 (Lun–Dom × 00–23) con totales por fila y columna.
   Botones **Compra/Venta · Compra · Venta** y alternador **Hora CIERRE / Hora APERTURA**.
   Clic en una celda → popup con total de operaciones, distribución compra/venta, ratio
   ganancia/pérdida por dirección, P&L de compras, ventas y total, y lista de operaciones.
5. **Matrices** — Control de matrices (canastas de rejilla). Una matriz es el grupo de
   posiciones del mismo símbolo y número mágico cuyos intervalos abierto→cerrado se solapan:
   empieza con la primera apertura y termina cuando no queda ninguna posición abierta. Tabla
   paginada con **Símbolo, Día, # Matriz** (orden dentro del día por símbolo+mágico),
   **Apertura, Cierre, Duración, Op. Compra, Op. Venta, DD Máximo, Refuerzo (Sí/No)** y
   **Beneficio Total**, con totales al pie. Clic en una fila → popup con el detalle de la
   matriz y sus operaciones (apertura, tipo, lote, precio, comentario, neto).
   - *DD Máximo*: peor saldo flotante estimado durante la vida de la matriz, recorriendo las
     velas del símbolo (como el P&L de la canasta es lineal en el precio, se evalúa en el
     mínimo y el máximo de cada vela, sumando lo ya realizado y las comisiones). Si no hay
     velas disponibles se muestra con `~` la suma de las pérdidas realizadas. El resultado se
     guarda en caché por matriz.
   - *Refuerzo*: `Sí (n)` cuando `n` posiciones llevan en su comentario el texto de
     `InpMatrixReinforceTag` (por defecto `REF`, como las órdenes `REF_BUY_n` / `REF_SELL_n`).
   - Solo se listan canastas con al menos `InpMatrixMinOps` posiciones (por defecto 2).
6. **Estadísticas Arena** — Vista **Resumen**: Ratio de Sharpe, Factor de Beneficio y
   Drawdown Máximo con barras segmentadas y valoración; medidores de **Disciplina** y
   **Eficiencia** (0–100); **Tasa de Errores**; análisis textual; **Alertas de Rendimiento**
   y **Aspectos Positivos**. Vista **Avanzado**: tabla con más de 30 métricas (expectativa,
   payoff, rachas, factor de recuperación, Kelly, mejor/peor día, compras vs ventas, etc.).

### Actualización en tiempo real

- `OnTradeTransaction` / `OnTrade` detectan nuevos deals y recargan el historial con un breve
  retardo (para que el deal ya esté disponible en el historial).
- Un temporizador comprueba periódicamente si hay una recarga pendiente del historial y
  redibuja el panel cuando cambia el balance/equity de la cuenta.
- `CHARTEVENT_CHART_CHANGE` redimensiona el panel al cambiar el tamaño del gráfico.

## Parámetros de entrada

| Grupo | Parámetro | Descripción |
|---|---|---|
| Apariencia | `InpFontName` | Fuente (por defecto `Arial`). |
| | `InpUIScale` | Escala de toda la interfaz (1.0 = 100%, útil en pantallas HiDPI). |
| | `InpStartMaximized` | Iniciar ocupando todo el gráfico. |
| | `InpPanelX/Y/Width/Height` | Geometría en modo ventana. |
| | `InpCleanChart` | Oculta el panel de trading con un clic y, en pantalla completa, las escalas de precio y tiempo (se restauran al quitar el EA). |
| Tarjetas | `InpPnLBase` | Base (dinero) de la barra de progreso de **P&L Total**; 100 por defecto, 0 = sin barra. |
| | `InpMaxDrawdownPct` | DD tolerado (%) para la barra de **DD Máximo del Periodo**. |
| Disciplina | `InpMaxTradesPerDay` | Umbral de sobre-trading (operaciones/día). |
| | `InpRevengeMinutes` | Minutos tras una pérdida para marcar revenge trading. |
| | `InpSLViolationFactor` | Factor sobre la pérdida mediana para marcar violación de stop. |
| Control de matrices | `InpMatrixReinforceTag` | Texto que, presente en el comentario de una posición, la marca como refuerzo (`REF`). |
| | `InpMatrixMinOps` | Mínimo de posiciones solapadas para considerar una matriz (2). |
| Actualización | `InpRefreshMs` | Intervalo del temporizador (ms). |
| Demostración | `InpDemoData` | Genera un historial sintético de ~40 días (7 símbolos, 3 mágicos, más matrices de rejilla en `US30`) para probar el panel en cuentas sin operaciones. La cabecera muestra `DATOS DE EJEMPLO`. |

En `MQL5/Presets/panel_demo.set` hay un preset con el modo de demostración activado.

## Definición de las métricas

- **Registro por posición**: todos los deals de una misma `POSITION_ID` se agregan en un único
  registro (apertura = primer deal de entrada, cierre = último deal de salida, neto = beneficio +
  swap + comisión + fee). Solo se incluyen posiciones totalmente cerradas.
- **Curva de balance**: se reconstruye a partir de todos los deals (incluidos depósitos y
  retiros) y se alinea con el balance actual de la cuenta, de forma que los porcentajes del
  calendario usan el balance real al inicio de cada día / semana / mes.
- **Ratio de Sharpe** (por operación): media del P&L neto / desviación típica del P&L neto.
- **Factor de Beneficio**: beneficio bruto / |pérdida bruta|.
- **Drawdown Máximo**: mayor caída pico-valle de la curva de balance del rango, en % del pico.
- **Violación de stop**: pérdida mayor que `InpSLViolationFactor` × mediana de las pérdidas.
- **Revenge trading**: operación abierta menos de `InpRevengeMinutes` después de cerrar una
  pérdida.
- **Cambio de riesgo**: las tres últimas pérdidas duplican, en media, a las anteriores.
- **Puntuación de Disciplina** (0–100): 100 − penalizaciones por % de días con sobre-trading,
  % de violaciones de stop, % de revenge trades y cambio de riesgo.
- **Eficiencia de Operación** (0–100): 0.4 × tasa de acierto + 0.4 × min(PF, 3)/3 × 100 +
  0.2 × (100 − tasa de errores).
- **Tasa de Errores**: % de operaciones marcadas como violación de stop o revenge trading.

## Notas técnicas

- Todo el panel se dibuja en un único `OBJ_BITMAP_LABEL` sobre un buffer ARGB propio
  (`PControl_Render`), sin depender de `Canvas.mqh`: rectángulos, líneas con suavizado,
  círculos, triángulos y anillos se rasterizan directamente y el texto se escribe con
  `TextOut`. Esto da control total de colores, bordes y tipografía con un único objeto en el
  gráfico.
- La interacción se resuelve con un mapa de zonas de clic reconstruido en cada dibujo; el
  desplazamiento del gráfico se desactiva mientras el cursor está sobre el panel y se
  restaura al salir.
- `Esc` cierra cualquier ventana emergente; clic fuera de ella también la cierra.
- Los anillos de los medidores se rasterizan píxel a píxel (evita el bucle infinito de
  `CCanvas::FillPolygon` con polígonos degenerados que motivó prescindir de la librería).
- Compilado con MetaEditor 5 (build 6231) sin errores ni avisos y probado en un terminal
  real con el modo de demostración.
