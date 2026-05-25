//+------------------------------------------------------------------+
//|                                             FreeScrollToggle.mq5 |
//|                        Boton para desplazamiento libre en MT5    |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property description "EA que agrega un boton para activar/desactivar el desplazamiento libre del grafico."

input int  InpButtonWidth       = 150;          // Ancho del boton en pixeles
input int  InpButtonHeight      = 28;           // Alto del boton en pixeles
input int  InpRightMargin       = 12;           // Margen derecho en pixeles
input color InpEnabledColor     = clrSeaGreen;  // Color cuando esta activo
input color InpDisabledColor    = clrFireBrick; // Color cuando esta inactivo

string g_button_name       = "BTN_FREE_SCROLL_TOGGLE";
bool   g_free_scroll       = false;
bool   g_saved_autoscroll  = true;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   g_saved_autoscroll = GetAutoScroll();

   if(!CreateOrUpdateButton())
      return INIT_FAILED;

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_free_scroll)
      ChartSetInteger(0, CHART_AUTOSCROLL, g_saved_autoscroll);

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
      ToggleFreeScroll();
      return;
   }

   if(id == CHARTEVENT_CHART_CHANGE)
      PlaceButton();
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
//| Cambia entre modo libre y modo normal                            |
//+------------------------------------------------------------------+
void ToggleFreeScroll()
{
   ObjectSetInteger(0, g_button_name, OBJPROP_STATE, false);

   if(!g_free_scroll)
   {
      g_saved_autoscroll = GetAutoScroll();

      // Al apagar el auto-scroll, el grafico deja de saltar al ultimo tick.
      ChartSetInteger(0, CHART_AUTOSCROLL, false);
      g_free_scroll = true;
   }
   else
   {
      ChartSetInteger(0, CHART_AUTOSCROLL, g_saved_autoscroll);
      g_free_scroll = false;
   }

   UpdateButtonState();
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Refresca texto y color del boton                                 |
//+------------------------------------------------------------------+
void UpdateButtonState()
{
   string text = g_free_scroll ? "Scroll libre: ON" : "Scroll libre: OFF";
   color  bg   = g_free_scroll ? InpEnabledColor : InpDisabledColor;

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
