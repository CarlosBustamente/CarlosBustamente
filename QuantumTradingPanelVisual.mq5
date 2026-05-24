//+------------------------------------------------------------------+
//|                                      QuantumTradingPanelVisual.mq5 |
//|                     Panel visual/interactivo listo para MetaTrader |
//+------------------------------------------------------------------+
#property copyright "Quantum Trading Panel Visual"
#property version   "1.00"
#property strict
#property description "Panel visual para MT5. No ejecuta operaciones; deja hooks para conectar un gestor externo."

//--- Tamano del panel
enum ENUM_QTP_PANEL_SIZE
  {
   PANEL_PEQUENO = 0,   // PANEL_PEQUENO
   PANEL_MEDIANO = 1,   // PANEL_MEDIANO
   PANEL_GRANDE  = 2    // PANEL_GRANDE
  };

//--- Tema de colores del panel
enum ENUM_QTP_THEME
  {
   T_DARK_MATTER = 0,   // T_DARK_MATTER
   T_NOVA        = 1,   // T_NOVA
   T_QUANTUM_NOIR= 2,   // T_QUANTUM_NOIR
   T_VOID_PULSE  = 3,   // T_VOID_PULSE
   T_NEBULA      = 4,   // T_NEBULA
   T_SINGULARITY = 5,   // T_SINGULARITY
   T_ENTROPY     = 6,   // T_ENTROPY
   T_DEEP_FIELD  = 7,   // T_DEEP_FIELD
   T_AURUM       = 8    // T_AURUM
  };

//--- Ocultar botones de trading
enum ENUM_QTP_HIDE_BUTTONS
  {
   H_NINGUNO = 0,       // H_NINGUNO
   H_MARKET  = 1,       // H_MARKET
   H_LIMIT   = 2        // H_LIMIT
  };

//--- Accion seleccionada en el panel
enum ENUM_QTP_ACTION
  {
   ACTION_NONE       = 0,
   ACTION_BUY_MARKET = 1,
   ACTION_SELL_MARKET= 2,
   ACTION_BUY_LIMIT  = 3,
   ACTION_SELL_LIMIT = 4
  };

//--- Inputs visibles en propiedades del EA
input ENUM_QTP_PANEL_SIZE   InpPanelSize       = PANEL_MEDIANO;  // Tamano del panel
input ENUM_QTP_THEME        InpTheme           = T_DARK_MATTER;  // Tema de colores del panel
input ENUM_QTP_HIDE_BUTTONS InpHideTradingBtns = H_NINGUNO;      // Ocultar botones trading
input int                   InpLabelFontSize   = 10;             // Tamano texto etiqueta
input color                 InpMarketLineColor = clrWhite;       // Color linea de entrada MARKET
input color                 InpLimitLineColor  = clrGold;        // Color linea de entrada LIMIT
input color                 InpSLLineColor     = clrRed;         // Color linea SL
input color                 InpTPLineColor     = clrLimeGreen;   // Color linea TP
input ENUM_BASE_CORNER      InpCorner          = CORNER_LEFT_UPPER; // Esquina del panel
input int                   InpX               = 18;             // Posicion X
input int                   InpY               = 2;              // Posicion Y
input string                InpPanelTitle      = "QUANTUM TRADING"; // Titulo del panel
input double                InpMoneyValue      = 210.0;          // Valor inicial campo $
input double                InpPtsSlValue      = 1000.0;         // Valor inicial campo PTS-SL
input double                InpRiskRewardValue = 2.0;            // Valor inicial campo R:R

//--- Prefijo unico de objetos
string g_prefix = "QTP_VISUAL_";

//--- Estado
ENUM_QTP_ACTION g_selected_action = ACTION_NONE;

//--- Metricas escalables
int g_panel_w;
int g_panel_h;
int g_btn_h;
int g_gap;
int g_pad;
int g_title_h;
int g_font_size;
int g_x;
int g_y;

//--- Paleta activa
color g_panel_bg;
color g_panel_border;
color g_title_bg;
color g_text;
color g_text_muted;
color g_buy;
color g_sell;
color g_money;
color g_info_bg;
color g_cancel;
color g_execute;
color g_disabled;
color g_close;

//--- Nombres de objetos
string OBJ_BG       = "bg";
string OBJ_TITLE    = "title";
string OBJ_BUY_MKT  = "buy_market";
string OBJ_SELL_MKT = "sell_market";
string OBJ_BUY_LMT  = "buy_limit";
string OBJ_SELL_LMT = "sell_limit";
string OBJ_MONEY_L  = "money_label";
string OBJ_MONEY_V  = "money_value";
string OBJ_SL_L     = "sl_label";
string OBJ_SL_V     = "sl_value";
string OBJ_RR_L     = "rr_label";
string OBJ_RR_V     = "rr_value";
string OBJ_CANCEL   = "cancel";
string OBJ_EXECUTE  = "execute";
string OBJ_CLOSEALL = "close_all";

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_prefix = StringFormat("QTP_VISUAL_%I64d_", ChartID());
   ConfigureMetrics();
   ConfigureTheme();
   BuildPanel();
   RefreshPanel();
   ChartRedraw(0);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DeletePanelObjects();
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Tick handler: disponible para refrescar datos si tu gestor lo usa |
//+------------------------------------------------------------------+
void OnTick()
  {
   // OHLC actual en tiempo real, listo para consumir desde tu logica.
   MqlRates current_bar[];
   if(CopyRates(_Symbol, _Period, 0, 1, current_bar) == 1)
     {
      // Ejemplo de acceso:
      // current_bar[0].open, current_bar[0].high, current_bar[0].low, current_bar[0].close
     }
  }

//+------------------------------------------------------------------+
//| Eventos de objetos graficos                                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   if(StringFind(sparam, g_prefix) != 0)
      return;

   string key = StringSubstr(sparam, StringLen(g_prefix));

   if(key == OBJ_BUY_MKT)
      SelectAction(ACTION_BUY_MARKET);
   else if(key == OBJ_SELL_MKT)
      SelectAction(ACTION_SELL_MARKET);
   else if(key == OBJ_BUY_LMT)
      SelectAction(ACTION_BUY_LIMIT);
   else if(key == OBJ_SELL_LMT)
      SelectAction(ACTION_SELL_LIMIT);
   else if(key == OBJ_CANCEL)
      CancelSelection();
   else if(key == OBJ_EXECUTE)
      ExecuteSelection();
   else if(key == OBJ_CLOSEALL)
      CloseAllRequested();

   RefreshPanel();
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Configuracion visual                                               |
//+------------------------------------------------------------------+
void ConfigureMetrics()
  {
   double scale = 1.0;
   if(InpPanelSize == PANEL_PEQUENO)
      scale = 0.86;
   else if(InpPanelSize == PANEL_GRANDE)
      scale = 1.18;

   g_panel_w  = (int)MathRound(190.0 * scale);
   g_btn_h    = (int)MathRound(24.0 * scale);
   g_gap      = MathMax(2, (int)MathRound(4.0 * scale));
   g_pad      = MathMax(4, (int)MathRound(6.0 * scale));
   g_title_h  = (int)MathRound(24.0 * scale);
   g_font_size= MathMax(7, (int)MathRound((double)InpLabelFontSize * scale));
   g_x        = InpX;
   g_y        = InpY;

   int rows = 1; // titulo
   if(InpHideTradingBtns != H_MARKET)
      rows++;
   if(InpHideTradingBtns != H_LIMIT)
      rows++;
   rows += 5; // dinero + PTS-SL + R:R + cancelar/ejecutar + cerrar todo
   g_panel_h = g_title_h + (g_btn_h * rows) + (g_gap * (rows + 2)) + g_pad;
  }

void ConfigureTheme()
  {
   // Base DARK_MATTER
   g_panel_bg     = C'8,10,14';
   g_panel_border = C'110,110,110';
   g_title_bg     = C'3,3,5';
   g_text         = clrWhite;
   g_text_muted   = C'230,230,230';
   g_buy          = C'0,130,230';
   g_sell         = C'105,105,105';
   g_money        = C'0,115,15';
   g_info_bg      = C'2,10,25';
   g_cancel       = clrRed;
   g_execute      = C'0,115,15';
   g_disabled     = C'95,95,95';
   g_close        = C'85,85,85';

   if(InpTheme == T_NOVA)
     {
      g_panel_bg = C'12,23,34';
      g_title_bg = C'16,55,86';
      g_buy      = C'0,150,255';
      g_sell     = C'124,134,148';
      g_money    = C'0,150,95';
      g_execute  = C'0,150,95';
     }
   else if(InpTheme == T_QUANTUM_NOIR)
     {
      g_panel_bg = C'0,0,0';
      g_title_bg = C'10,10,10';
      g_buy      = C'20,110,210';
      g_sell     = C'80,80,80';
      g_money    = C'0,92,0';
      g_execute  = C'0,92,0';
     }
   else if(InpTheme == T_VOID_PULSE)
     {
      g_panel_bg = C'16,9,28';
      g_title_bg = C'38,13,64';
      g_buy      = C'97,60,255';
      g_sell     = C'85,76,100';
      g_money    = C'0,135,70';
      g_execute  = C'0,135,70';
     }
   else if(InpTheme == T_NEBULA)
     {
      g_panel_bg = C'8,18,28';
      g_title_bg = C'24,50,76';
      g_buy      = C'0,175,220';
      g_sell     = C'90,100,116';
      g_money    = C'18,140,80';
      g_execute  = C'18,140,80';
     }
   else if(InpTheme == T_SINGULARITY)
     {
      g_panel_bg = C'15,15,18';
      g_title_bg = C'32,32,38';
      g_buy      = C'15,120,245';
      g_sell     = C'72,72,82';
      g_money    = C'0,105,35';
      g_execute  = C'0,105,35';
     }
   else if(InpTheme == T_ENTROPY)
     {
      g_panel_bg = C'28,12,10';
      g_title_bg = C'72,24,18';
      g_buy      = C'220,85,30';
      g_sell     = C'110,80,72';
      g_money    = C'0,120,45';
      g_execute  = C'0,120,45';
     }
   else if(InpTheme == T_DEEP_FIELD)
     {
      g_panel_bg = C'3,9,22';
      g_title_bg = C'4,16,46';
      g_buy      = C'0,95,220';
      g_sell     = C'72,80,95';
      g_money    = C'0,92,65';
      g_execute  = C'0,92,65';
     }
   else if(InpTheme == T_AURUM)
     {
      g_panel_bg = C'24,20,12';
      g_title_bg = C'70,52,10';
      g_buy      = C'190,145,35';
      g_sell     = C'105,95,75';
      g_money    = C'128,96,0';
      g_execute  = C'128,96,0';
     }
  }

//+------------------------------------------------------------------+
//| Construccion del panel                                             |
//+------------------------------------------------------------------+
void BuildPanel()
  {
   DeletePanelObjects();

   int x = g_x;
   int y = g_y;
   int full_w = g_panel_w;
   int col_gap = g_gap;
   int col_w = (full_w - (g_pad * 2) - col_gap) / 2;
   int row_y = y + g_gap;

   CreateRect(OBJ_BG, x, y, full_w, g_panel_h, g_panel_bg, g_panel_border);

   CreateButton(OBJ_TITLE, x + g_pad, row_y, full_w - (g_pad * 2), g_title_h,
                InpPanelTitle, g_title_bg, g_text, g_font_size + 1, false);
   row_y += g_title_h + g_gap;

   bool show_market = (InpHideTradingBtns != H_MARKET);
   bool show_limit  = (InpHideTradingBtns != H_LIMIT);

   if(show_market)
     {
      CreateButton(OBJ_BUY_MKT,  x + g_pad, row_y, col_w, g_btn_h,
                   "BUY MRKT", g_buy, g_text, g_font_size, true);
      CreateButton(OBJ_SELL_MKT, x + g_pad + col_w + col_gap, row_y, col_w, g_btn_h,
                   "SELL MRKT", g_sell, g_text, g_font_size, true);
      row_y += g_btn_h + g_gap;
     }

   if(show_limit)
     {
      CreateButton(OBJ_BUY_LMT,  x + g_pad, row_y, col_w, g_btn_h,
                   "BUY LIMIT", g_sell, g_text, g_font_size, true);
      CreateButton(OBJ_SELL_LMT, x + g_pad + col_w + col_gap, row_y, col_w, g_btn_h,
                   "SELL LIMIT", g_sell, g_text, g_font_size, true);
      row_y += g_btn_h + g_gap;
     }

   CreateButton(OBJ_MONEY_L, x + g_pad, row_y, col_w, g_btn_h,
                "$", g_money, g_text, g_font_size + 1, false);
   CreateButton(OBJ_MONEY_V, x + g_pad + col_w + col_gap, row_y, col_w, g_btn_h,
                DoubleToPanelText(InpMoneyValue), g_info_bg, g_text, g_font_size, false);
   row_y += g_btn_h + g_gap;

   CreateButton(OBJ_SL_L, x + g_pad, row_y, col_w, g_btn_h,
                "PTS-SL [OFF]", g_sell, g_text, g_font_size, false);
   CreateButton(OBJ_SL_V, x + g_pad + col_w + col_gap, row_y, col_w, g_btn_h,
                DoubleToPanelText(InpPtsSlValue), g_info_bg, g_text, g_font_size, false);
   row_y += g_btn_h + g_gap;

   CreateButton(OBJ_RR_L, x + g_pad, row_y, col_w, g_btn_h,
                "R:R [ON]", g_money, g_text, g_font_size, false);
   CreateButton(OBJ_RR_V, x + g_pad + col_w + col_gap, row_y, col_w, g_btn_h,
                DoubleToPanelText(InpRiskRewardValue), g_info_bg, g_text, g_font_size, false);
   row_y += g_btn_h + g_gap;

   CreateButton(OBJ_CANCEL, x + g_pad, row_y, col_w, g_btn_h,
                "CANCELAR", g_disabled, g_text, g_font_size, true);
   CreateButton(OBJ_EXECUTE, x + g_pad + col_w + col_gap, row_y, col_w, g_btn_h,
                "EJECUTAR", g_disabled, g_text, g_font_size, true);
   row_y += g_btn_h + g_gap;

   CreateButton(OBJ_CLOSEALL, x + g_pad, row_y, full_w - (g_pad * 2), g_btn_h,
                "CERRAR TODO", g_close, g_text, g_font_size, true);
  }

void CreateRect(const string key,
                const int x,
                const int y,
                const int w,
                const int h,
                const color bg,
                const color border)
  {
   string name = ObjName(key);
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, InpCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 1);
  }

void CreateButton(const string key,
                  const int x,
                  const int y,
                  const int w,
                  const int h,
                  const string text,
                  const color bg,
                  const color txt,
                  const int font_size,
                  const bool clickable)
  {
   string name = ObjName(key);
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, InpCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, txt);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, g_panel_border);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, clickable ? 10 : 5);
  }

//+------------------------------------------------------------------+
//| Estado visual                                                     |
//+------------------------------------------------------------------+
void SelectAction(const ENUM_QTP_ACTION action)
  {
   g_selected_action = action;
   RefreshPanel();
   OnPanelActionSelected(action);
  }

void CancelSelection()
  {
   if(g_selected_action == ACTION_NONE)
      return;

   ENUM_QTP_ACTION previous = g_selected_action;
   g_selected_action = ACTION_NONE;
   RefreshPanel();
   OnPanelCancel(previous);
  }

void ExecuteSelection()
  {
   if(g_selected_action == ACTION_NONE)
      return;

   OnPanelExecute(g_selected_action);
  }

void CloseAllRequested()
  {
   OnPanelCloseAll();
  }

void RefreshPanel()
  {
   SetTradingButtonColor(OBJ_BUY_MKT,  ACTION_BUY_MARKET,  g_buy);
   SetTradingButtonColor(OBJ_SELL_MKT, ACTION_SELL_MARKET, g_sell);
   SetTradingButtonColor(OBJ_BUY_LMT,  ACTION_BUY_LIMIT,   g_sell);
   SetTradingButtonColor(OBJ_SELL_LMT, ACTION_SELL_LIMIT,  g_sell);

   bool active = (g_selected_action != ACTION_NONE);
   SetButtonStyle(OBJ_CANCEL,  active ? g_cancel  : g_disabled, g_text, active, false);
   SetButtonStyle(OBJ_EXECUTE, active ? g_execute : g_disabled, g_text, active, false);
  }

void SetTradingButtonColor(const string key,
                           const ENUM_QTP_ACTION action,
                           const color active_color)
  {
   if(!ObjectExists(key))
      return;

   if(g_selected_action == ACTION_NONE)
     {
      SetButtonStyle(key, active_color, g_text, true, false);
      return;
     }

   bool selected = (g_selected_action == action);
   SetButtonStyle(key, selected ? active_color : g_disabled, selected ? g_text : g_text_muted, true, selected);
  }

void SetButtonStyle(const string key,
                    const color bg,
                    const color txt,
                    const bool enabled,
                    const bool selected)
  {
   string name = ObjName(key);
   if(ObjectFind(0, name) < 0)
      return;

   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, txt);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, selected ? clrWhite : g_panel_border);
   ObjectSetInteger(0, name, OBJPROP_STATE, selected);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, enabled ? 10 : 3);
  }

//+------------------------------------------------------------------+
//| Hooks para conectar tu gestor                                     |
//+------------------------------------------------------------------+
void OnPanelActionSelected(const ENUM_QTP_ACTION action)
  {
   // Aqui puedes notificar a tu gestor que se selecciono BUY/SELL MARKET/LIMIT.
   PrintFormat("Panel: accion seleccionada = %s", ActionToString(action));
  }

void OnPanelCancel(const ENUM_QTP_ACTION previous_action)
  {
   // Aqui puedes cancelar lineas/preview/estado temporal de tu gestor.
   PrintFormat("Panel: cancelar seleccion previa = %s", ActionToString(previous_action));
  }

void OnPanelExecute(const ENUM_QTP_ACTION action)
  {
   // Aqui llamas a tu gestor de ordenes. Este EA visual NO envia trades.
   PrintFormat("Panel: ejecutar accion = %s", ActionToString(action));
  }

void OnPanelCloseAll()
  {
   // Aqui puedes conectar tu funcion de cierre total si ya existe en otro modulo.
   Print("Panel: cerrar todo solicitado");
  }

//+------------------------------------------------------------------+
//| Utilidades                                                        |
//+------------------------------------------------------------------+
string ObjName(const string key)
  {
   return(g_prefix + key);
  }

bool ObjectExists(const string key)
  {
   return(ObjectFind(0, ObjName(key)) >= 0);
  }

void DeletePanelObjects()
  {
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, g_prefix) == 0)
         ObjectDelete(0, name);
     }
  }

string DoubleToPanelText(const double value)
  {
   if(MathAbs(value - MathRound(value)) < 0.0000001)
      return(IntegerToString((int)MathRound(value)));

   return(DoubleToString(value, 2));
  }

string ActionToString(const ENUM_QTP_ACTION action)
  {
   switch(action)
     {
      case ACTION_BUY_MARKET:
         return("BUY_MARKET");
      case ACTION_SELL_MARKET:
         return("SELL_MARKET");
      case ACTION_BUY_LIMIT:
         return("BUY_LIMIT");
      case ACTION_SELL_LIMIT:
         return("SELL_LIMIT");
      default:
         return("NONE");
     }
  }
//+------------------------------------------------------------------+
