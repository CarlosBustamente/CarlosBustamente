//+------------------------------------------------------------------+
//|                                                       Config.mqh |
//|              Panel de Control MT5 - Paleta, enumeraciones, textos |
//+------------------------------------------------------------------+
#ifndef PC_CONFIG_MQH
#define PC_CONFIG_MQH

//--- Paleta (tomada de las capturas de referencia)
#define PC_CLR_BG           C'20,22,26'
#define PC_CLR_PANEL        C'28,31,36'
#define PC_CLR_PANEL2       C'36,39,45'
#define PC_CLR_PANEL3       C'44,48,55'
#define PC_CLR_BORDER       C'48,52,60'
#define PC_CLR_BORDER2      C'66,71,82'
#define PC_CLR_TEXT         C'226,229,236'
#define PC_CLR_TEXT_DIM     C'160,166,178'
#define PC_CLR_TEXT_MUTED   C'110,116,130'
#define PC_CLR_BLUE         C'30,120,240'
#define PC_CLR_BLUE_LIGHT   C'51,153,255'
#define PC_CLR_CYAN         C'0,190,255'
#define PC_CLR_GREEN        C'46,204,113'
#define PC_CLR_GREEN_BRIGHT C'80,230,140'
#define PC_CLR_RED          C'233,70,60'
#define PC_CLR_ORANGE       C'255,176,32'
#define PC_CLR_PURPLE       C'190,110,255'
#define PC_CLR_YELLOW       C'241,196,15'
#define PC_CLR_WHITE        C'255,255,255'
#define PC_CLR_BTN          C'46,50,58'
#define PC_CLR_GRID         C'42,46,54'
#define PC_CLR_SUMMARY_G    C'30,110,60'
#define PC_CLR_SUMMARY_R    C'130,40,40'

//--- Rango temporal de la cabecera
enum ENUM_PC_RANGE
  {
   RANGE_TODAY  = 0,   // Hoy
   RANGE_WEEK   = 1,   // Semana
   RANGE_MONTH  = 2,   // Mes
   RANGE_ALL    = 3,   // Todo
   RANGE_CUSTOM = 4    // Personalizado
  };

//--- Pestañas principales
enum ENUM_PC_TAB
  {
   TAB_CHART        = 0,
   TAB_TRANSACTIONS = 1,
   TAB_CALENDAR     = 2,
   TAB_HOURLY       = 3,
   TAB_ARENA        = 4
  };

//--- Pestañas del panel de filtros
enum ENUM_PC_FTAB
  {
   FTAB_SYMBOL = 0,
   FTAB_MAGIC  = 1,
   FTAB_TYPE   = 2
  };

//--- Modo del mapa de calor
enum ENUM_PC_HOUR_MODE
  {
   HOUR_BOTH = 0,
   HOUR_BUY  = 1,
   HOUR_SELL = 2
  };

//--- Ventanas emergentes
enum ENUM_PC_POPUP
  {
   POPUP_NONE        = 0,
   POPUP_HOUR_CELL   = 1,
   POPUP_INFO_HOURLY = 2,
   POPUP_INFO_ARENA  = 3,
   POPUP_DATEPICKER  = 4,
   POPUP_CAL_DAY     = 5
  };

//--- Acciones registradas en el mapa de clics
enum ENUM_PC_ACTION
  {
   ACT_NONE = 0,
   ACT_RANGE,
   ACT_TAB,
   ACT_FTAB,
   ACT_FILTER_ALL,
   ACT_FILTER_ITEM,
   ACT_CAL_PREV,
   ACT_CAL_NEXT,
   ACT_CAL_DAY,
   ACT_HOUR_MODE,
   ACT_HOUR_TIME,
   ACT_HOUR_CELL,
   ACT_ARENA_VIEW,
   ACT_INFO,
   ACT_POPUP_CLOSE,
   ACT_BACKDROP,
   ACT_TX_PREV,
   ACT_TX_NEXT,
   ACT_MINIMIZE,
   ACT_MAXIMIZE,
   ACT_DP_PREV,
   ACT_DP_NEXT,
   ACT_DP_DAY,
   ACT_DP_RESET
  };

//--- Textos en español
string PC_DAYS_SHORT[7]  = {"Lun","Mar","Mié","Jue","Vie","Sáb","Dom"};
string PC_DAYS_LONG[7]   = {"Lunes","Martes","Miércoles","Jueves","Viernes","Sábado","Domingo"};
string PC_MONTHS[12]     = {"Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"};
string PC_RANGE_NAMES[5] = {"Hoy","Semana","Mes","Todo","Personalizado"};
string PC_TAB_NAMES[5]   = {"Gráfico","Transacciones","Calendario","Por Hora","Estadísticas Arena"};
string PC_FTAB_NAMES[3]  = {"SF","MN","TP"};
string PC_FTAB_TITLES[3] = {"Filtros de Símbolo","Filtros de Mágico","Filtro por Tipo"};

//--- Paleta para los cuadros de color de los símbolos
color PC_SYMBOL_PALETTE[12] =
  {
   C'46,204,113', C'155,89,182', C'236,240,241', C'230,126,34', C'241,196,15', C'52,152,219',
   C'26,188,156', C'231,76,60',  C'149,165,166', C'52,73,94',   C'255,105,180', C'0,206,209'
  };

//+------------------------------------------------------------------+
//| Utilidades de color                                               |
//+------------------------------------------------------------------+
color PC_Mix(const color a,const color b,const double t)
  {
   double k=MathMax(0.0,MathMin(1.0,t));
   uint ua=(uint)a, ub=(uint)b;
   int ar=(int)(ua&0xFF), ag=(int)((ua>>8)&0xFF), ab=(int)((ua>>16)&0xFF);
   int br=(int)(ub&0xFF), bg=(int)((ub>>8)&0xFF), bb=(int)((ub>>16)&0xFF);
   int r=(int)MathRound(ar+(br-ar)*k);
   int g=(int)MathRound(ag+(bg-ag)*k);
   int bl=(int)MathRound(ab+(bb-ab)*k);
   return((color)(r|(g<<8)|(bl<<16)));
  }

color PC_PnLColor(const double v)
  {
   if(v>0.0) return(PC_CLR_GREEN);
   if(v<0.0) return(PC_CLR_RED);
   return(PC_CLR_TEXT_DIM);
  }

//+------------------------------------------------------------------+
//| Utilidades de formato                                             |
//+------------------------------------------------------------------+
string PC_Money(const double v,const int digits=2)
  {
   return(DoubleToString(v,digits));
  }

string PC_Signed(const double v,const int digits=2)
  {
   if(v>0.0) return("+"+DoubleToString(v,digits));
   return(DoubleToString(v,digits));
  }

string PC_Pct(const double v,const int digits=2)
  {
   return(DoubleToString(v,digits)+"%");
  }

string PC_SignedPct(const double v,const int digits=2)
  {
   return(PC_Signed(v,digits)+"%");
  }

string PC_Duration(const long seconds)
  {
   long s=MathAbs(seconds);
   long d=s/86400; s%=86400;
   long h=s/3600;  s%=3600;
   long m=s/60;    s%=60;
   if(d>0) return(IntegerToString(d)+"d "+IntegerToString(h)+"h");
   if(h>0) return(IntegerToString(h)+"h "+IntegerToString(m)+"m");
   if(m>0) return(IntegerToString(m)+"m "+IntegerToString(s)+"s");
   return(IntegerToString(s)+"s");
  }

//+------------------------------------------------------------------+
//| Utilidades de fecha (hora del servidor)                           |
//+------------------------------------------------------------------+
datetime PC_DayStart(const datetime t)
  {
   long v=(long)t;
   return((datetime)(v-(v%86400)));
  }

datetime PC_WeekStart(const datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t,dt);
   int dow=(dt.day_of_week+6)%7;    // Lunes = 0
   return((datetime)((long)PC_DayStart(t)-(long)dow*86400));
  }

datetime PC_MonthStart(const datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t,dt);
   dt.day=1; dt.hour=0; dt.min=0; dt.sec=0;
   return(StructToTime(dt));
  }

datetime PC_MakeDate(const int year,const int month,const int day)
  {
   MqlDateTime dt;
   dt.year=year; dt.mon=month; dt.day=day; dt.hour=0; dt.min=0; dt.sec=0;
   return(StructToTime(dt));
  }

int PC_DaysInMonth(const int year,const int month)
  {
   int ny=year, nm=month+1;
   if(nm>12) { nm=1; ny++; }
   datetime a=PC_MakeDate(year,month,1);
   datetime b=PC_MakeDate(ny,nm,1);
   return((int)(((long)b-(long)a)/86400));
  }

//--- Día de la semana con Lunes = 0 ... Domingo = 6
int PC_WeekDay(const datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t,dt);
   return((dt.day_of_week+6)%7);
  }

string PC_DateStr(const datetime t)
  {
   return(TimeToString(t,TIME_DATE));
  }

string PC_DateTimeStr(const datetime t)
  {
   return(TimeToString(t,TIME_DATE|TIME_MINUTES|TIME_SECONDS));
  }

#endif // PC_CONFIG_MQH
