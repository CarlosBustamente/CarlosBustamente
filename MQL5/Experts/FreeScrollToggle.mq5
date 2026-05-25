//+------------------------------------------------------------------+
//|                                             FreeScrollToggle.mq5 |
//|                        Boton para desplazamiento libre en MT5    |
//+------------------------------------------------------------------+
#property strict
#property version   "1.10"
#property description "EA que agrega navegacion libre tipo TradingView con boton para volver a tiempo real."

input int    InpButtonWidth             = 170;          // Ancho del boton en pixeles
input int    InpButtonHeight            = 28;           // Alto del boton en pixeles
input int    InpRightMargin             = 12;           // Margen derecho en pixeles
input int    InpPriceScaleDragWidth     = 85;           // Ancho sensible del eje de precios
input double InpHorizontalSensitivity   = 1.00;         // Sensibilidad del arrastre horizontal
input double InpVerticalSensitivity     = 1.00;         // Sensibilidad del arrastre vertical
input bool   InpInvertHorizontalDrag    = false;        // Invierte arrastre horizontal si tu MT5 lo requiere
input bool   InpInvertVerticalDrag      = false;        // Invierte arrastre vertical si tu MT5 lo requiere
input color  InpFreeModeColor           = clrSeaGreen;  // Color cuando el modo libre esta activo
input color  InpRealtimeColor           = clrDodgerBlue;// Color para activar movimiento libre

const int LEFT_MOUSE_BUTTON = 1;

string g_button_name             = "BTN_TV_STYLE_FREE_MOVE";
bool   g_free_navigation         = false;
bool   g_dragging                = false;
bool   g_dragging_price_scale    = false;
bool   g_saved_autoscroll        = true;
bool   g_saved_scale_fix         = false;
bool   g_saved_mouse_scroll      = true;
double g_saved_fixed_min         = 0.0;
double g_saved_fixed_max         = 0.0;
double g_horizontal_pixel_buffer = 0.0;
int    g_last_mouse_x            = 0;
int    g_last_mouse_y            = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   g_saved_autoscroll = GetAutoScroll();

   if(!CreateOrUpdateButton())
      return INIT_FAILED;

   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_free_navigation)
      RestoreSavedChartState();

   ObjectDelete(0, g_button_name);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Chart events                                                     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == g_button_name)
   {
      HandleButtonClick();
      return;
   }

   if(id == CHARTEVENT_CHART_CHANGE)
   {
      PlaceButton();
      return;
   }

   if(id == CHARTEVENT_MOUSE_MOVE)
      HandleMouseMove((int)lparam, (int)dparam, sparam);
}

//+------------------------------------------------------------------+
//| Crea o actualiza el boton                                        |
//+------------------------------------------------------------------+
bool CreateOrUpdateButton()
{
   if(ObjectFind(0, g_button_name) < 0)
   {
      if(!ObjectCreate(0, g_button_name, OBJ_BUTTON, 0, 0, 0))
      {
         PrintFormat("No se pudo crear el boton. Error: %d", GetLastError());
         return false;
      }

      ObjectSetInteger(0, g_button_name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, g_button_name, OBJPROP_XSIZE, InpButtonWidth);
      ObjectSetInteger(0, g_button_name, OBJPROP_YSIZE, InpButtonHeight);
      ObjectSetInteger(0, g_button_name, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, g_button_name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, g_button_name, OBJPROP_BORDER_COLOR, clrWhite);
      ObjectSetInteger(0, g_button_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, g_button_name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, g_button_name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, g_button_name, OBJPROP_ZORDER, 1000);
   }

   PlaceButton();
   UpdateButtonState();
   return true;
}

//+------------------------------------------------------------------+
//| Ubica el boton a la derecha y a media altura                     |
//+------------------------------------------------------------------+
void PlaceButton()
{
   long chart_height = 0;

   if(!ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, chart_height))
      chart_height = 600;

   int y_distance = (int)MathMax(0, (chart_height - InpButtonHeight) / 2);

   ObjectSetInteger(0, g_button_name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, g_button_name, OBJPROP_XDISTANCE, InpRightMargin);
   ObjectSetInteger(0, g_button_name, OBJPROP_YDISTANCE, y_distance);
}

//+------------------------------------------------------------------+
//| Gestiona el clic del boton                                       |
//+------------------------------------------------------------------+
void HandleButtonClick()
{
   ObjectSetInteger(0, g_button_name, OBJPROP_STATE, false);

   if(!g_free_navigation)
      EnableFreeNavigation();
   else
      GoToRealtimeBar();
}

//+------------------------------------------------------------------+
//| Activa navegacion libre tipo TradingView                         |
//+------------------------------------------------------------------+
void EnableFreeNavigation()
{
   SaveChartState();

   ChartSetInteger(0, CHART_AUTOSCROLL, false);
   ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
   PrepareFixedPriceScale();

   g_free_navigation = true;
   ResetDragState();

   UpdateButtonState();
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Vuelve a la barra actual y restaura el movimiento en tiempo real |
//+------------------------------------------------------------------+
void GoToRealtimeBar()
{
   ChartNavigate(0, CHART_END, 0);
   RestoreSavedChartState();
   ChartSetInteger(0, CHART_AUTOSCROLL, true);

   g_free_navigation = false;
   ResetDragState();

   UpdateButtonState();
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Guarda el estado que sera restaurado al salir del modo libre      |
//+------------------------------------------------------------------+
void SaveChartState()
{
   g_saved_autoscroll   = GetChartInteger(CHART_AUTOSCROLL, true);
   g_saved_scale_fix    = GetChartInteger(CHART_SCALEFIX, false);
   g_saved_mouse_scroll = GetChartInteger(CHART_MOUSE_SCROLL, true);
   g_saved_fixed_min    = GetChartDouble(CHART_FIXED_MIN, 0.0);
   g_saved_fixed_max    = GetChartDouble(CHART_FIXED_MAX, 0.0);
}

//+------------------------------------------------------------------+
//| Restaura auto-scroll, escala y scroll nativo del mouse            |
//+------------------------------------------------------------------+
void RestoreSavedChartState()
{
   ChartSetInteger(0, CHART_AUTOSCROLL, g_saved_autoscroll);
   ChartSetInteger(0, CHART_MOUSE_SCROLL, g_saved_mouse_scroll);
   ChartSetInteger(0, CHART_SCALEFIX, g_saved_scale_fix);

   if(g_saved_scale_fix)
   {
      ChartSetDouble(0, CHART_FIXED_MIN, g_saved_fixed_min);
      ChartSetDouble(0, CHART_FIXED_MAX, g_saved_fixed_max);
   }
}

//+------------------------------------------------------------------+
//| Fija la escala actual para permitir pan vertical por precio       |
//+------------------------------------------------------------------+
void PrepareFixedPriceScale()
{
   double price_min = 0.0;
   double price_max = 0.0;

   if(!ChartGetDouble(0, CHART_PRICE_MIN, 0, price_min) ||
      !ChartGetDouble(0, CHART_PRICE_MAX, 0, price_max) ||
      price_max <= price_min)
   {
      return;
   }

   ChartSetDouble(0, CHART_FIXED_MIN, price_min);
   ChartSetDouble(0, CHART_FIXED_MAX, price_max);
   ChartSetInteger(0, CHART_SCALEFIX, true);
}

//+------------------------------------------------------------------+
//| Procesa arrastres del mouse                                      |
//+------------------------------------------------------------------+
void HandleMouseMove(const int x, const int y, const string button_state)
{
   if(!g_free_navigation)
      return;

   bool left_pressed = ((int)StringToInteger(button_state) & LEFT_MOUSE_BUTTON) == LEFT_MOUSE_BUTTON;

   if(!left_pressed)
   {
      ResetDragState();
      return;
   }

   if(!g_dragging && IsInsideButton(x, y))
      return;

   if(!g_dragging)
   {
      g_dragging = true;
      g_dragging_price_scale = IsInPriceScale(x);
      g_last_mouse_x = x;
      g_last_mouse_y = y;
      g_horizontal_pixel_buffer = 0.0;
      return;
   }

   int dx = x - g_last_mouse_x;
   int dy = y - g_last_mouse_y;
   g_last_mouse_x = x;
   g_last_mouse_y = y;

   if(g_dragging_price_scale)
      PanVertical(dy);
   else
      PanHorizontal(dx);
}

//+------------------------------------------------------------------+
//| Arrastre horizontal sobre el area principal del grafico           |
//+------------------------------------------------------------------+
void PanHorizontal(const int dx)
{
   if(dx == 0)
      return;

   long chart_width = 0;
   long visible_bars = 0;

   if(!ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, chart_width) ||
      !ChartGetInteger(0, CHART_VISIBLE_BARS, 0, visible_bars) ||
      chart_width <= 0 || visible_bars <= 0)
   {
      return;
   }

   double pixels_per_bar = MathMax(1.0, (double)chart_width / (double)visible_bars);
   g_horizontal_pixel_buffer += (double)dx * InpHorizontalSensitivity;

   int bars_to_move = (int)(g_horizontal_pixel_buffer / pixels_per_bar);
   if(bars_to_move == 0)
      return;

   int shift = -bars_to_move;
   if(InpInvertHorizontalDrag)
      shift = -shift;

   ChartNavigate(0, CHART_CURRENT_POS, shift);
   g_horizontal_pixel_buffer -= (double)bars_to_move * pixels_per_bar;
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Arrastre vertical sobre el eje de precios                         |
//+------------------------------------------------------------------+
void PanVertical(const int dy)
{
   if(dy == 0)
      return;

   long chart_height = 0;
   double fixed_min = 0.0;
   double fixed_max = 0.0;

   if(!ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, chart_height) ||
      !ChartGetDouble(0, CHART_FIXED_MIN, 0, fixed_min) ||
      !ChartGetDouble(0, CHART_FIXED_MAX, 0, fixed_max) ||
      chart_height <= 0 || fixed_max <= fixed_min)
   {
      return;
   }

   double price_range = fixed_max - fixed_min;
   double price_delta = ((double)dy / (double)chart_height) * price_range * InpVerticalSensitivity;

   if(InpInvertVerticalDrag)
      price_delta = -price_delta;

   ChartSetDouble(0, CHART_FIXED_MIN, fixed_min + price_delta);
   ChartSetDouble(0, CHART_FIXED_MAX, fixed_max + price_delta);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Refresca texto y color del boton                                 |
//+------------------------------------------------------------------+
void UpdateButtonState()
{
   string text = g_free_navigation ? "Ir a tiempo real" : "Movimiento libre";
   color  bg   = g_free_navigation ? InpFreeModeColor : InpRealtimeColor;

   ObjectSetString(0, g_button_name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, g_button_name, OBJPROP_BGCOLOR, bg);
}

//+------------------------------------------------------------------+
//| Lee CHART_AUTOSCROLL de forma segura                             |
//+------------------------------------------------------------------+
bool GetAutoScroll()
{
   long value = 0;

   if(!ChartGetInteger(0, CHART_AUTOSCROLL, 0, value))
      return true;

   return (value != 0);
}

//+------------------------------------------------------------------+
//| Lee una propiedad entera del grafico                              |
//+------------------------------------------------------------------+
bool GetChartInteger(const ENUM_CHART_PROPERTY_INTEGER property_id,
                     const bool default_value)
{
   long value = 0;

   if(!ChartGetInteger(0, property_id, 0, value))
      return default_value;

   return (value != 0);
}

//+------------------------------------------------------------------+
//| Lee una propiedad double del grafico                              |
//+------------------------------------------------------------------+
double GetChartDouble(const ENUM_CHART_PROPERTY_DOUBLE property_id,
                      const double default_value)
{
   double value = 0.0;

   if(!ChartGetDouble(0, property_id, 0, value))
      return default_value;

   return value;
}

//+------------------------------------------------------------------+
//| Limpia estado de arrastre                                        |
//+------------------------------------------------------------------+
void ResetDragState()
{
   g_dragging = false;
   g_dragging_price_scale = false;
   g_horizontal_pixel_buffer = 0.0;
}

//+------------------------------------------------------------------+
//| Detecta si el mouse esta sobre el boton                           |
//+------------------------------------------------------------------+
bool IsInsideButton(const int x, const int y)
{
   long chart_width = 0;

   if(!ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, chart_width))
      return false;

   int left = (int)chart_width - InpRightMargin - InpButtonWidth;
   int right = (int)chart_width - InpRightMargin;

   long chart_height = 0;
   if(!ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0, chart_height))
      chart_height = 600;

   int top = (int)MathMax(0, ((int)chart_height - InpButtonHeight) / 2);
   int bottom = top + InpButtonHeight;

   return (x >= left && x <= right && y >= top && y <= bottom);
}

//+------------------------------------------------------------------+
//| Detecta el area sensible de la escala de precios                  |
//+------------------------------------------------------------------+
bool IsInPriceScale(const int x)
{
   long chart_width = 0;

   if(!ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, chart_width))
      return false;

   return (x >= (int)chart_width - InpPriceScaleDragWidth);
}
//+------------------------------------------------------------------+
