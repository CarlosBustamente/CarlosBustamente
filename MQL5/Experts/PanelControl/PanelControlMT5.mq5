//+------------------------------------------------------------------+
//|                                              PanelControlMT5.mq5 |
//|      Panel de Control MT5 - Herramienta de análisis de trading    |
//+------------------------------------------------------------------+
#property copyright   "Panel de Control MT5"
#property link        ""
#property version     "1.00"
#property description "Panel de análisis de rendimiento en tiempo real para posiciones cerradas."
#property description "Pestañas: Gráfico, Transacciones, Calendario, Por Hora y Estadísticas Arena."
#property description "Filtros por símbolo, número mágico, tipo y rango temporal. No ejecuta operaciones."

#include <PanelControl/PanelControl.mqh>

//+------------------------------------------------------------------+
//| Parámetros de entrada                                             |
//+------------------------------------------------------------------+
input group "=== Apariencia ==="
input string   InpFontName        = "Arial";   // Fuente del panel
input double   InpUIScale         = 1.0;       // Escala de la interfaz (1.0 = 100%)
input bool     InpStartMaximized  = true;      // Iniciar ocupando todo el gráfico
input int      InpPanelX          = 10;        // Posición X (modo ventana)
input int      InpPanelY          = 10;        // Posición Y (modo ventana)
input int      InpPanelWidth      = 1024;      // Ancho (modo ventana)
input int      InpPanelHeight     = 560;       // Alto (modo ventana)
input bool     InpCleanChart      = true;      // Ocultar panel de un clic y escalas en pantalla completa

input group "=== Gestión de riesgo (tarjetas superiores) ==="
input double   InpDailyLossLimit  = 500.0;     // Límite de pérdida diaria (dinero, 0 = sin límite)
input double   InpMaxDrawdownPct  = 10.0;      // Drawdown máximo permitido desde el máximo histórico (%)

input group "=== Análisis de disciplina (Estadísticas Arena) ==="
input int      InpMaxTradesPerDay = 3;         // Umbral de sobre-trading (operaciones por día)
input int      InpRevengeMinutes  = 5;         // Minutos tras una pérdida para marcar revenge trading
input double   InpSLViolationFactor = 1.3;     // Factor sobre la pérdida mediana para marcar violación de stop

input group "=== Actualización ==="
input int      InpRefreshMs       = 1000;      // Intervalo de refresco de equity (ms)

input group "=== Demostración ==="
input bool     InpDemoData        = false;     // Usar datos de ejemplo en lugar del historial real

//--- instancia única del panel
CPanel g_panel;

//+------------------------------------------------------------------+
//| Inicialización                                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   SPanelSettings s;
   s.font            =InpFontName;
   s.scale           =InpUIScale;
   s.start_maximized =InpStartMaximized;
   s.x               =InpPanelX;
   s.y               =InpPanelY;
   s.w               =InpPanelWidth;
   s.h               =InpPanelHeight;
   s.daily_loss_limit=InpDailyLossLimit;
   s.max_dd_pct      =InpMaxDrawdownPct;
   s.max_trades_day  =InpMaxTradesPerDay;
   s.revenge_minutes =InpRevengeMinutes;
   s.sl_factor       =InpSLViolationFactor;
   s.refresh_ms      =InpRefreshMs;
   s.demo_data       =InpDemoData;
   s.clean_chart     =InpCleanChart;

   if(!g_panel.Init(s))
      return(INIT_FAILED);

   EventSetMillisecondTimer(MathMax(250,InpRefreshMs));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Finalización                                                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_panel.Deinit();
  }

//+------------------------------------------------------------------+
//| El panel no opera: OnTick queda vacío intencionadamente           |
//+------------------------------------------------------------------+
void OnTick()
  {
  }

//+------------------------------------------------------------------+
//| Refresco periódico (equity, DD, recarga diferida del historial)   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   g_panel.OnTimer();
  }

//+------------------------------------------------------------------+
//| Actualización en tiempo real al cerrar posiciones                 |
//+------------------------------------------------------------------+
void OnTrade()
  {
   g_panel.OnTradeEvent();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD || trans.type==TRADE_TRANSACTION_HISTORY_ADD)
      g_panel.OnTradeEvent();
  }

//+------------------------------------------------------------------+
//| Eventos del gráfico (ratón, rueda, teclado, cambio de tamaño)     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   g_panel.OnChartEvent(id,lparam,dparam,sparam);
  }
//+------------------------------------------------------------------+
