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

//+------------------------------------------------------------------+
//| ARCHIVO ÚNICO E INDEPENDIENTE                                      |
//| No usa ninguna librería externa ni includes: todo (dibujo, datos,  |
//| interfaz y vistas) está contenido en este archivo. Todos los       |
//| identificadores globales llevan el prefijo PControl_ para evitar   |
//| conflictos con otros programas instalados en el terminal.          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| SECCIÓN 1: CONFIGURACIÓN - paleta, enumeraciones y textos         |
//+------------------------------------------------------------------+
//--- Paleta (tomada de las capturas de referencia)
#define PControl_CLR_BG           C'20,22,26'
#define PControl_CLR_PANEL        C'28,31,36'
#define PControl_CLR_PANEL2       C'36,39,45'
#define PControl_CLR_PANEL3       C'44,48,55'
#define PControl_CLR_BORDER       C'48,52,60'
#define PControl_CLR_BORDER2      C'66,71,82'
#define PControl_CLR_TEXT         C'226,229,236'
#define PControl_CLR_TEXT_DIM     C'160,166,178'
#define PControl_CLR_TEXT_MUTED   C'110,116,130'
#define PControl_CLR_BLUE         C'30,120,240'
#define PControl_CLR_BLUE_LIGHT   C'51,153,255'
#define PControl_CLR_CYAN         C'0,190,255'
#define PControl_CLR_GREEN        C'46,204,113'
#define PControl_CLR_GREEN_BRIGHT C'80,230,140'
#define PControl_CLR_RED          C'233,70,60'
#define PControl_CLR_ORANGE       C'255,176,32'
#define PControl_CLR_PURPLE       C'190,110,255'
#define PControl_CLR_YELLOW       C'241,196,15'
#define PControl_CLR_WHITE        C'255,255,255'
#define PControl_CLR_BTN          C'46,50,58'
#define PControl_CLR_GRID         C'42,46,54'
#define PControl_CLR_SUMMARY_G    C'30,110,60'
#define PControl_CLR_SUMMARY_R    C'130,40,40'

//--- Rango temporal de la cabecera
enum ENUM_PControl_RANGE
  {
   PControl_RANGE_TODAY  = 0,   // Hoy
   PControl_RANGE_WEEK   = 1,   // Semana
   PControl_RANGE_MONTH  = 2,   // Mes
   PControl_RANGE_ALL    = 3,   // Todo
   PControl_RANGE_CUSTOM = 4    // Personalizado
  };

//--- Pestañas principales
enum ENUM_PControl_TAB
  {
   PControl_TAB_CHART        = 0,
   PControl_TAB_TRANSACTIONS = 1,
   PControl_TAB_CALENDAR     = 2,
   PControl_TAB_HOURLY       = 3,
   PControl_TAB_ARENA        = 4
  };

//--- Pestañas del panel de filtros
enum ENUM_PControl_FTAB
  {
   PControl_FTAB_SYMBOL = 0,
   PControl_FTAB_MAGIC  = 1,
   PControl_FTAB_TYPE   = 2
  };

//--- Modo del mapa de calor
enum ENUM_PControl_HOUR_MODE
  {
   PControl_HOUR_BOTH = 0,
   PControl_HOUR_BUY  = 1,
   PControl_HOUR_SELL = 2
  };

//--- Ventanas emergentes
enum ENUM_PControl_POPUP
  {
   PControl_POPUP_NONE        = 0,
   PControl_POPUP_HOUR_CELL   = 1,
   PControl_POPUP_INFO_HOURLY = 2,
   PControl_POPUP_INFO_ARENA  = 3,
   PControl_POPUP_DATEPICKER  = 4,
   PControl_POPUP_CAL_DAY     = 5
  };

//--- Acciones registradas en el mapa de clics
enum ENUM_PControl_ACTION
  {
   PControl_ACT_NONE = 0,
   PControl_ACT_RANGE,
   PControl_ACT_TAB,
   PControl_ACT_FTAB,
   PControl_ACT_FILTER_ALL,
   PControl_ACT_FILTER_ITEM,
   PControl_ACT_CAL_PREV,
   PControl_ACT_CAL_NEXT,
   PControl_ACT_CAL_DAY,
   PControl_ACT_HOUR_MODE,
   PControl_ACT_HOUR_TIME,
   PControl_ACT_HOUR_CELL,
   PControl_ACT_ARENA_VIEW,
   PControl_ACT_INFO,
   PControl_ACT_POPUP_CLOSE,
   PControl_ACT_BACKDROP,
   PControl_ACT_TX_PREV,
   PControl_ACT_TX_NEXT,
   PControl_ACT_MINIMIZE,
   PControl_ACT_MAXIMIZE,
   PControl_ACT_DP_PREV,
   PControl_ACT_DP_NEXT,
   PControl_ACT_DP_DAY,
   PControl_ACT_DP_RESET
  };

//--- Textos en español
string PControl_DAYS_SHORT[7]  = {"Lun","Mar","Mié","Jue","Vie","Sáb","Dom"};
string PControl_DAYS_LONG[7]   = {"Lunes","Martes","Miércoles","Jueves","Viernes","Sábado","Domingo"};
string PControl_MONTHS[12]     = {"Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"};
string PControl_RANGE_NAMES[5] = {"Hoy","Semana","Mes","Todo","Personalizado"};
string PControl_TAB_NAMES[5]   = {"Gráfico","Transacciones","Calendario","Por Hora","Estadísticas Arena"};
string PControl_FTAB_NAMES[3]  = {"SF","MN","TP"};
string PControl_FTAB_TITLES[3] = {"Filtros de Símbolo","Filtros de Mágico","Filtro por Tipo"};

//--- Paleta para los cuadros de color de los símbolos
color PControl_SYMBOL_PALETTE[12] =
  {
   C'46,204,113', C'155,89,182', C'236,240,241', C'230,126,34', C'241,196,15', C'52,152,219',
   C'26,188,156', C'231,76,60',  C'149,165,166', C'52,73,94',   C'255,105,180', C'0,206,209'
  };

//+------------------------------------------------------------------+
//| Utilidades de color                                               |
//+------------------------------------------------------------------+
color PControl_Mix(const color a,const color b,const double t)
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

color PControl_PnLColor(const double v)
  {
   if(v>0.0) return(PControl_CLR_GREEN);
   if(v<0.0) return(PControl_CLR_RED);
   return(PControl_CLR_TEXT_DIM);
  }

//+------------------------------------------------------------------+
//| Utilidades de formato                                             |
//+------------------------------------------------------------------+
string PControl_Money(const double v,const int digits=2)
  {
   return(DoubleToString(v,digits));
  }

string PControl_Signed(const double v,const int digits=2)
  {
   if(v>0.0) return("+"+DoubleToString(v,digits));
   return(DoubleToString(v,digits));
  }

string PControl_Pct(const double v,const int digits=2)
  {
   return(DoubleToString(v,digits)+"%");
  }

string PControl_SignedPct(const double v,const int digits=2)
  {
   return(PControl_Signed(v,digits)+"%");
  }

string PControl_Duration(const long seconds)
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
datetime PControl_DayStart(const datetime t)
  {
   long v=(long)t;
   return((datetime)(v-(v%86400)));
  }

datetime PControl_WeekStart(const datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t,dt);
   int dow=(dt.day_of_week+6)%7;    // Lunes = 0
   return((datetime)((long)PControl_DayStart(t)-(long)dow*86400));
  }

datetime PControl_MonthStart(const datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t,dt);
   dt.day=1; dt.hour=0; dt.min=0; dt.sec=0;
   return(StructToTime(dt));
  }

datetime PControl_MakeDate(const int year,const int month,const int day)
  {
   MqlDateTime dt;
   dt.year=year; dt.mon=month; dt.day=day; dt.hour=0; dt.min=0; dt.sec=0;
   return(StructToTime(dt));
  }

int PControl_DaysInMonth(const int year,const int month)
  {
   int ny=year, nm=month+1;
   if(nm>12) { nm=1; ny++; }
   datetime a=PControl_MakeDate(year,month,1);
   datetime b=PControl_MakeDate(ny,nm,1);
   return((int)(((long)b-(long)a)/86400));
  }

//--- Día de la semana con Lunes = 0 ... Domingo = 6
int PControl_WeekDay(const datetime t)
  {
   MqlDateTime dt;
   TimeToStruct(t,dt);
   return((dt.day_of_week+6)%7);
  }

string PControl_DateStr(const datetime t)
  {
   return(TimeToString(t,TIME_DATE));
  }

string PControl_DateTimeStr(const datetime t)
  {
   return(TimeToString(t,TIME_DATE|TIME_MINUTES|TIME_SECONDS));
  }

//+------------------------------------------------------------------+
//| SECCIÓN 2: CAPA DE DIBUJO                                          |
//| Lienzo propio (sin librerías): buffer ARGB volcado a un recurso    |
//| dinámico vinculado a un único OBJ_BITMAP_LABEL. Solo usa las       |
//| funciones nativas ResourceCreate / TextSetFont / TextOut.          |
//+------------------------------------------------------------------+
class PControl_Render
  {
private:
   uint              m_pix[];
   string            m_name;
   string            m_res;
   int               m_x;
   int               m_y;
   int               m_w;
   int               m_h;
   string            m_font;
   int               m_font_size;
   bool              m_font_bold;
   bool              m_created;

   void              ApplyFont(const int size,const bool bold);
   uint              ToARGB(const color clr) const { return(ColorToARGB(clr,255)); }
   bool              CreateResource();
   void              PixelRaw(const int x,const int y,const uint c);
   void              PixelBlend(const int x,const int y,const uint c,const double alpha);
   void              PixelAA(const double x,const double y,const uint c);
   void              HLineRaw(int x1,int x2,const int y,const uint c);
   void              VLineRaw(const int x,int y1,int y2,const uint c);
   void              FillTriangleRaw(int x1,int y1,int x2,int y2,int x3,int y3,const uint c);

public:
                     PControl_Render();
                    ~PControl_Render();

   bool              Create(const string name,const int x,const int y,const int w,const int h,const string font);
   void              Destroy();
   bool              Resize(const int w,const int h);
   void              Move(const int x,const int y);
   void              Update();
   void              BringToFront();

   int               X() const { return(m_x); }
   int               Y() const { return(m_y); }
   int               Width() const { return(m_w); }
   int               Height() const { return(m_h); }
   string            Name() const { return(m_name); }
   bool              IsCreated() const { return(m_created); }

   //--- primitivas
   void              Clear(const color clr);
   void              Fill(const int x,const int y,const int w,const int h,const color clr);
   void              Frame(const int x,const int y,const int w,const int h,const color clr);
   void              Box(const int x,const int y,const int w,const int h,const color fill,const color border);
   void              HLine(const int x1,const int x2,const int y,const color clr);
   void              VLine(const int x,const int y1,const int y2,const color clr);
   void              Line(const int x1,const int y1,const int x2,const int y2,const color clr);
   void              DottedHLine(const int x1,const int x2,const int y,const color clr,const int step=3);
   void              DottedVLine(const int x,const int y1,const int y2,const color clr,const int step=3);
   void              Pixel(const int x,const int y,const color clr);
   void              Circle(const int cx,const int cy,const int r,const color clr);
   void              Ring(const int cx,const int cy,const int r_out,const int r_in,double a_from,double a_to,const color clr);
   void              TriangleLeft(const int cx,const int cy,const int size,const color clr);
   void              TriangleRight(const int cx,const int cy,const int size,const color clr);
   void              Checkbox(const int x,const int y,const int size,const bool checked,const color clr_on);

   //--- texto
   void              Text(const int x,const int y,const string txt,const color clr,const int size,const uint align=TA_LEFT|TA_TOP,const bool bold=false);
   int               TextWidth(const string txt,const int size,const bool bold=false);
   int               TextHeight(const int size,const bool bold=false);
   string            Ellipsis(const string txt,const int max_w,const int size,const bool bold=false);
   int               WrapText(const string txt,const int max_w,const int size,const bool bold,string &lines[]);
  };

//+------------------------------------------------------------------+
PControl_Render::PControl_Render() : m_name(""),m_res(""),m_x(0),m_y(0),m_w(0),m_h(0),m_font("Arial"),m_font_size(-1),m_font_bold(false),m_created(false)
  {
  }

//+------------------------------------------------------------------+
PControl_Render::~PControl_Render()
  {
   Destroy();
  }

//+------------------------------------------------------------------+
//| Vuelca el buffer al recurso dinámico (lo crea si no existe)        |
//+------------------------------------------------------------------+
bool PControl_Render::CreateResource()
  {
   return(ResourceCreate(m_res,m_pix,m_w,m_h,0,0,0,COLOR_FORMAT_ARGB_NORMALIZE));
  }

//+------------------------------------------------------------------+
bool PControl_Render::Create(const string name,const int x,const int y,const int w,const int h,const string font)
  {
   Destroy();
   m_name=name;
   m_x=x; m_y=y;
   m_w=MathMax(1,w);
   m_h=MathMax(1,h);
   m_font=(font=="" ? "Arial" : font);
   //--- nombre único del recurso (debe empezar por "::")
   string uniq=(string)ChartID()+(string)GetTickCount()+"."+(string)(GetMicrosecondCount()&0x3FF);
   m_res="::"+StringSubstr(m_name,0,63-StringLen(uniq))+uniq;
   if(ArrayResize(m_pix,m_w*m_h)<=0)
      return(false);
   ArrayInitialize(m_pix,0);
   if(!CreateResource())
     {
      Print("PanelControl: no se pudo crear el recurso gráfico (",GetLastError(),")");
      return(false);
     }
   if(!ObjectCreate(0,m_name,OBJ_BITMAP_LABEL,0,0,0))
     {
      Print("PanelControl: no se pudo crear el objeto del lienzo (",GetLastError(),")");
      ResourceFree(m_res);
      return(false);
     }
   ObjectSetInteger(0,m_name,OBJPROP_XDISTANCE,m_x);
   ObjectSetInteger(0,m_name,OBJPROP_YDISTANCE,m_y);
   ObjectSetInteger(0,m_name,OBJPROP_XSIZE,m_w);
   ObjectSetInteger(0,m_name,OBJPROP_YSIZE,m_h);
   ObjectSetString(0,m_name,OBJPROP_BMPFILE,m_res);
   ObjectSetInteger(0,m_name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,m_name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,m_name,OBJPROP_BACK,false);
   ObjectSetInteger(0,m_name,OBJPROP_ZORDER,1000);
   ObjectSetString(0,m_name,OBJPROP_TOOLTIP,"\n");
   m_font_size=-1;
   m_created=true;
   return(true);
  }

//+------------------------------------------------------------------+
void PControl_Render::Destroy()
  {
   if(m_name!="" && ObjectFind(0,m_name)>=0)
      ObjectDelete(0,m_name);
   if(m_res!="")
     {
      ResourceFree(m_res);
      m_res="";
     }
   ArrayFree(m_pix);
   m_created=false;
  }

//+------------------------------------------------------------------+
bool PControl_Render::Resize(const int w,const int h)
  {
   int nw=MathMax(1,w), nh=MathMax(1,h);
   if(nw==m_w && nh==m_h) return(true);
   m_w=nw; m_h=nh;
   if(ArrayResize(m_pix,m_w*m_h)<=0) return(false);
   ArrayInitialize(m_pix,0);
   bool ok=CreateResource();
   if(ok)
     {
      ObjectSetInteger(0,m_name,OBJPROP_XSIZE,m_w);
      ObjectSetInteger(0,m_name,OBJPROP_YSIZE,m_h);
      ObjectSetString(0,m_name,OBJPROP_BMPFILE,m_res);
     }
   m_font_size=-1;
   return(ok);
  }

//+------------------------------------------------------------------+
void PControl_Render::Move(const int x,const int y)
  {
   m_x=x; m_y=y;
   ObjectSetInteger(0,m_name,OBJPROP_XDISTANCE,m_x);
   ObjectSetInteger(0,m_name,OBJPROP_YDISTANCE,m_y);
  }

//+------------------------------------------------------------------+
void PControl_Render::Update()
  {
   if(m_created) CreateResource();
  }

//+------------------------------------------------------------------+
void PControl_Render::BringToFront()
  {
   ObjectSetInteger(0,m_name,OBJPROP_ZORDER,1000);
  }

//+------------------------------------------------------------------+
void PControl_Render::ApplyFont(const int size,const bool bold)
  {
   if(size==m_font_size && bold==m_font_bold) return;
   m_font_size=size;
   m_font_bold=bold;
   TextSetFont(m_font,size,(bold ? FW_BOLD : FW_NORMAL),0);
  }

//+------------------------------------------------------------------+
//| Primitivas de bajo nivel sobre el buffer                           |
//+------------------------------------------------------------------+
void PControl_Render::PixelRaw(const int x,const int y,const uint c)
  {
   if(x<0 || y<0 || x>=m_w || y>=m_h) return;
   m_pix[y*m_w+x]=c;
  }

void PControl_Render::PixelBlend(const int x,const int y,const uint c,const double alpha)
  {
   if(x<0 || y<0 || x>=m_w || y>=m_h) return;
   if(alpha>=1.0) { m_pix[y*m_w+x]=c; return; }
   if(alpha<=0.0) return;
   uint c0=m_pix[y*m_w+x];
   int r=(int)(((c0>>16)&0xFF)*(1.0-alpha)+((c>>16)&0xFF)*alpha);
   int g=(int)(((c0>>8)&0xFF)*(1.0-alpha)+((c>>8)&0xFF)*alpha);
   int b=(int)((c0&0xFF)*(1.0-alpha)+(c&0xFF)*alpha);
   m_pix[y*m_w+x]=(uint)(0xFF000000|((uint)r<<16)|((uint)g<<8)|(uint)b);
  }

void PControl_Render::PixelAA(const double x,const double y,const uint c)
  {
   int ix=(int)MathRound(x), iy=(int)MathRound(y);
   double dx=x-ix, dy=y-iy;
   if(dx==0.0 && dy==0.0) { PixelRaw(ix,iy,c); return; }
   int xx[4], yy[4];
   double rr[4], sum=0.0;
   xx[0]=ix; xx[2]=ix;
   yy[0]=iy; yy[1]=iy;
   xx[1]=(dx<0.0 ? ix-1 : (dx>0.0 ? ix+1 : ix)); xx[3]=xx[1];
   yy[2]=(dy<0.0 ? iy-1 : (dy>0.0 ? iy+1 : iy)); yy[3]=yy[2];
   for(int i=0; i<4; i++)
     {
      double ddx=xx[i]-x, ddy=yy[i]-y;
      double d2=ddx*ddx+ddy*ddy;
      rr[i]=(d2<1e-9 ? 1e9 : 1.0/d2);
      sum+=rr[i];
     }
   for(int i=0; i<4; i++)
      PixelBlend(xx[i],yy[i],c,rr[i]/sum);
  }

void PControl_Render::HLineRaw(int x1,int x2,const int y,const uint c)
  {
   if(y<0 || y>=m_h) return;
   if(x1>x2) { int t=x1; x1=x2; x2=t; }
   x1=MathMax(0,x1); x2=MathMin(m_w-1,x2);
   if(x1>x2) return;
   int base=y*m_w;
   for(int x=x1; x<=x2; x++) m_pix[base+x]=c;
  }

void PControl_Render::VLineRaw(const int x,int y1,int y2,const uint c)
  {
   if(x<0 || x>=m_w) return;
   if(y1>y2) { int t=y1; y1=y2; y2=t; }
   y1=MathMax(0,y1); y2=MathMin(m_h-1,y2);
   for(int y=y1; y<=y2; y++) m_pix[y*m_w+x]=c;
  }

void PControl_Render::FillTriangleRaw(int x1,int y1,int x2,int y2,int x3,int y3,const uint c)
  {
   int t;
   if(y1>y2) { t=y1; y1=y2; y2=t; t=x1; x1=x2; x2=t; }
   if(y1>y3) { t=y1; y1=y3; y3=t; t=x1; x1=x3; x3=t; }
   if(y2>y3) { t=y2; y2=y3; y3=t; t=x2; x2=x3; x3=t; }
   if(y1==y3) { HLineRaw(MathMin(x1,MathMin(x2,x3)),MathMax(x1,MathMax(x2,x3)),y1,c); return; }
   for(int y=y1; y<=y3; y++)
     {
      double xa=x1+(double)(x3-x1)*(y-y1)/(double)(y3-y1);
      double xb;
      if(y<y2) xb=(y2==y1 ? x2 : x1+(double)(x2-x1)*(y-y1)/(double)(y2-y1));
      else     xb=(y3==y2 ? x2 : x2+(double)(x3-x2)*(y-y2)/(double)(y3-y2));
      HLineRaw((int)MathRound(xa),(int)MathRound(xb),y,c);
     }
  }

//+------------------------------------------------------------------+
//| Primitivas públicas                                                |
//+------------------------------------------------------------------+
void PControl_Render::Clear(const color clr)
  {
   ArrayInitialize(m_pix,ToARGB(clr));
  }

void PControl_Render::Fill(const int x,const int y,const int w,const int h,const color clr)
  {
   if(w<=0 || h<=0) return;
   uint c=ToARGB(clr);
   int y1=MathMax(0,y), y2=MathMin(m_h-1,y+h-1);
   for(int yy=y1; yy<=y2; yy++) HLineRaw(x,x+w-1,yy,c);
  }

void PControl_Render::Frame(const int x,const int y,const int w,const int h,const color clr)
  {
   if(w<=0 || h<=0) return;
   uint c=ToARGB(clr);
   HLineRaw(x,x+w-1,y,c);
   HLineRaw(x,x+w-1,y+h-1,c);
   VLineRaw(x,y,y+h-1,c);
   VLineRaw(x+w-1,y,y+h-1,c);
  }

void PControl_Render::Box(const int x,const int y,const int w,const int h,const color fill,const color border)
  {
   Fill(x,y,w,h,fill);
   Frame(x,y,w,h,border);
  }

void PControl_Render::HLine(const int x1,const int x2,const int y,const color clr)
  {
   HLineRaw(x1,x2,y,ToARGB(clr));
  }

void PControl_Render::VLine(const int x,const int y1,const int y2,const color clr)
  {
   VLineRaw(x,y1,y2,ToARGB(clr));
  }

//+------------------------------------------------------------------+
//| Línea con suavizado (anti-aliasing)                                |
//+------------------------------------------------------------------+
void PControl_Render::Line(const int x1,const int y1,const int x2,const int y2,const color clr)
  {
   uint c=ToARGB(clr);
   if((x1<0 && x2<0) || (y1<0 && y2<0) || (x1>=m_w && x2>=m_w) || (y1>=m_h && y2>=m_h)) return;
   if(x1==x2 && y1==y2) { PixelRaw(x1,y1,c); return; }
   if(y1==y2) { HLineRaw(x1,x2,y1,c); return; }
   if(x1==x2) { VLineRaw(x1,y1,y2,c); return; }
   double dx=x2-x1, dy=y2-y1;
   double len=MathSqrt(dx*dx+dy*dy);
   dx/=len; dy/=len;
   double xx=x1, yy=y1;
   int steps=(int)MathCeil(len);
   for(int i=0; i<=steps; i++)
     {
      PixelAA(xx,yy,c);
      xx+=dx; yy+=dy;
     }
  }

void PControl_Render::DottedHLine(const int x1,const int x2,const int y,const color clr,const int step)
  {
   uint c=ToARGB(clr);
   int a=MathMin(x1,x2), b=MathMax(x1,x2);
   for(int x=a; x<=b; x+=MathMax(1,step))
      PixelRaw(x,y,c);
  }

void PControl_Render::DottedVLine(const int x,const int y1,const int y2,const color clr,const int step)
  {
   uint c=ToARGB(clr);
   int a=MathMin(y1,y2), b=MathMax(y1,y2);
   for(int y=a; y<=b; y+=MathMax(1,step))
      PixelRaw(x,y,c);
  }

void PControl_Render::Pixel(const int x,const int y,const color clr)
  {
   PixelRaw(x,y,ToARGB(clr));
  }

//+------------------------------------------------------------------+
//| Círculo relleno (algoritmo del punto medio)                        |
//+------------------------------------------------------------------+
void PControl_Render::Circle(const int cx,const int cy,const int r,const color clr)
  {
   if(r<=0) { PixelRaw(cx,cy,ToARGB(clr)); return; }
   uint c=ToARGB(clr);
   int f=1-r, ddx=1, ddy=-2*r, dx=0, dy=r;
   while(dy>=dx)
     {
      HLineRaw(cx-dy,cx+dy,cy-dx,c);
      HLineRaw(cx-dy,cx+dy,cy+dx,c);
      if(f>=0)
        {
         HLineRaw(cx-dx,cx+dx,cy-dy,c);
         HLineRaw(cx-dx,cx+dx,cy+dy,c);
         dy--; ddy+=2; f+=ddy;
        }
      dx++; ddx+=2; f+=ddx;
     }
  }

//+------------------------------------------------------------------+
//| Anillo/arco relleno. Ángulos en grados, sentido matemático        |
//| (0 = derecha, 90 = arriba). Rasterizado por píxel.                |
//+------------------------------------------------------------------+
void PControl_Render::Ring(const int cx,const int cy,const int r_out,const int r_in,double a_from,double a_to,const color clr)
  {
   if(a_to<a_from) { double t=a_to; a_to=a_from; a_from=t; }
   if(a_to-a_from<0.01 || r_out<=0) return;
   uint c=ToARGB(clr);
   double ro2=(double)r_out*r_out, ri2=(double)MathMax(0,r_in)*MathMax(0,r_in);
   for(int dy=-r_out; dy<=r_out; dy++)
     {
      for(int dx=-r_out; dx<=r_out; dx++)
        {
         double d2=(double)dx*dx+(double)dy*dy;
         if(d2>ro2 || d2<ri2) continue;
         double ang=MathArctan2(-(double)dy,(double)dx)*180.0/M_PI;   // pantalla: y hacia abajo
         if(ang<0.0) ang+=360.0;
         bool inside=(ang>=a_from && ang<=a_to);
         if(!inside && a_to>360.0) inside=(ang+360.0>=a_from && ang+360.0<=a_to);
         if(inside) PixelRaw(cx+dx,cy+dy,c);
        }
     }
  }

void PControl_Render::TriangleLeft(const int cx,const int cy,const int size,const color clr)
  {
   int s=MathMax(2,size/2);
   FillTriangleRaw(cx-s,cy,cx+s,cy-s,cx+s,cy+s,ToARGB(clr));
  }

void PControl_Render::TriangleRight(const int cx,const int cy,const int size,const color clr)
  {
   int s=MathMax(2,size/2);
   FillTriangleRaw(cx+s,cy,cx-s,cy-s,cx-s,cy+s,ToARGB(clr));
  }

void PControl_Render::Checkbox(const int x,const int y,const int size,const bool checked,const color clr_on)
  {
   if(checked)
     {
      Fill(x,y,size,size,clr_on);
      int x1=x+size/4,      y1=y+size/2;
      int x2=x+size/2-1,    y2=y+size-size/4-1;
      int x3=x+size-size/4, y3=y+size/4;
      Line(x1,y1,x2,y2,PControl_CLR_WHITE);
      Line(x2,y2,x3,y3,PControl_CLR_WHITE);
     }
   else
     {
      Fill(x,y,size,size,PControl_CLR_PANEL2);
      Frame(x,y,size,size,PControl_CLR_BORDER2);
     }
  }

//+------------------------------------------------------------------+
//| Texto                                                              |
//+------------------------------------------------------------------+
void PControl_Render::Text(const int x,const int y,const string txt,const color clr,const int size,const uint align,const bool bold)
  {
   if(txt=="" || !m_created) return;
   ApplyFont(size,bold);
   TextOut(txt,x,y,align,m_pix,m_w,m_h,ToARGB(clr),COLOR_FORMAT_ARGB_NORMALIZE);
  }

int PControl_Render::TextWidth(const string txt,const int size,const bool bold)
  {
   if(txt=="") return(0);
   ApplyFont(size,bold);
   uint w=0, h=0;
   TextGetSize(txt,w,h);
   return((int)w);
  }

int PControl_Render::TextHeight(const int size,const bool bold)
  {
   ApplyFont(size,bold);
   uint w=0, h=0;
   TextGetSize("Ag",w,h);
   return((int)h);
  }

string PControl_Render::Ellipsis(const string txt,const int max_w,const int size,const bool bold)
  {
   if(TextWidth(txt,size,bold)<=max_w) return(txt);
   int len=StringLen(txt);
   while(len>1)
     {
      len--;
      string cut=StringSubstr(txt,0,len)+"…";
      if(TextWidth(cut,size,bold)<=max_w) return(cut);
     }
   return("…");
  }

//+------------------------------------------------------------------+
//| Divide el texto en líneas que caben en max_w píxeles              |
//+------------------------------------------------------------------+
int PControl_Render::WrapText(const string txt,const int max_w,const int size,const bool bold,string &lines[])
  {
   ArrayResize(lines,0);
   string words[];
   int nw=StringSplit(txt,' ',words);
   string cur="";
   for(int i=0; i<nw; i++)
     {
      if(words[i]=="") continue;
      string trial=(cur=="" ? words[i] : cur+" "+words[i]);
      if(TextWidth(trial,size,bold)<=max_w || cur=="")
         cur=trial;
      else
        {
         int n=ArraySize(lines);
         ArrayResize(lines,n+1);
         lines[n]=cur;
         cur=words[i];
        }
     }
   if(cur!="")
     {
      int n=ArraySize(lines);
      ArrayResize(lines,n+1);
      lines[n]=cur;
     }
   return(ArraySize(lines));
  }

//+------------------------------------------------------------------+
//| SECCIÓN 3: DATOS - historial por posición, filtros y estadísticas |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Registro de una posición cerrada (agregado de sus deals)          |
//+------------------------------------------------------------------+
struct PControl_PosRecord
  {
   long              position_id;
   string            symbol;
   long              magic;
   int               type;          // 0 = Compra, 1 = Venta
   double            vol_in;
   double            vol_out;
   datetime          open_time;
   datetime          close_time;
   double            open_price;
   double            close_price;
   double            profit;
   double            swap;
   double            commission;    // comisión + fee
   double            net;           // profit + swap + commission
   double            sl;
   double            tp;
   string            comment;
   bool              closed;
   bool              orphan;        // cierre sin apertura en el historial cargado
  };

void PControl_ResetRecord(PControl_PosRecord &r)
  {
   r.position_id=0; r.symbol=""; r.magic=0; r.type=0;
   r.vol_in=0; r.vol_out=0; r.open_time=0; r.close_time=0;
   r.open_price=0; r.close_price=0; r.profit=0; r.swap=0; r.commission=0; r.net=0;
   r.sl=0; r.tp=0; r.comment=""; r.closed=false; r.orphan=false;
  }

//+------------------------------------------------------------------+
//| Estadística de un día                                             |
//+------------------------------------------------------------------+
struct PControl_DayStat
  {
   datetime          day;
   double            net;
   int               trades;
   int               wins;
   int               losses;
   double            max_dd;        // drawdown intradía (dinero) sobre el P&L acumulado del día
   double            bal_start;     // balance al inicio del día
  };

//+------------------------------------------------------------------+
//| Estadísticas agregadas                                            |
//+------------------------------------------------------------------+
struct PControl_Stats
  {
   int               trades;
   int               wins;
   int               losses;
   int               breakeven;
   double            win_rate;         // 0..100
   double            net;
   double            gross_win;
   double            gross_loss;       // negativo
   double            swap;
   double            commission;
   double            volume;
   double            avg_win;
   double            avg_loss;         // negativo
   double            largest_win;
   double            largest_loss;     // negativo
   double            expectancy;
   double            payoff;           // avg_win / |avg_loss|
   double            profit_factor;
   int               max_consec_wins;
   int               max_consec_losses;
   double            max_dd_money;
   double            max_dd_pct;
   double            start_balance;
   double            sharpe;           // por operación: media/desv
   double            std_dev;
   double            recovery_factor;
   double            kelly;            // %
   long              avg_duration;     // segundos
   int               trading_days;
   double            avg_trades_day;
   double            best_day;
   double            worst_day;
   datetime          best_day_date;
   datetime          worst_day_date;
   int               long_trades;
   int               long_wins;
   double            long_net;
   int               short_trades;
   int               short_wins;
   double            short_net;
   //--- disciplina
   int               overtrading_days;
   int               sl_violations;
   int               revenge_trades;
   bool              risk_shift;
   bool              risk_consistent;
   double            mistake_rate;     // %
   double            discipline;       // 0..100
   double            efficiency;       // 0..100
  };

//+------------------------------------------------------------------+
//| Mapa long -> int (direccionamiento abierto)                       |
//+------------------------------------------------------------------+
class PControl_LongIntMap
  {
private:
   long              m_keys[];
   int               m_vals[];
   bool              m_used[];
   int               m_cap;
   int               m_count;

   int               Slot(const long key) const { return((int)((ulong)key%(ulong)m_cap)); }
   void              Grow();

public:
                     PControl_LongIntMap() : m_cap(0),m_count(0) {}
   void              Init(const int capacity);
   bool              Get(const long key,int &val) const;
   void              Set(const long key,const int val);
  };

void PControl_LongIntMap::Init(const int capacity)
  {
   m_cap=MathMax(64,capacity);
   ArrayResize(m_keys,m_cap);
   ArrayResize(m_vals,m_cap);
   ArrayResize(m_used,m_cap);
   ArrayFill(m_used,0,m_cap,false);
   m_count=0;
  }

bool PControl_LongIntMap::Get(const long key,int &val) const
  {
   if(m_cap==0) return(false);
   int i=Slot(key);
   for(int n=0; n<m_cap; n++)
     {
      if(!m_used[i]) return(false);
      if(m_keys[i]==key) { val=m_vals[i]; return(true); }
      i=(i+1)%m_cap;
     }
   return(false);
  }

void PControl_LongIntMap::Set(const long key,const int val)
  {
   if(m_cap==0) Init(64);
   if((m_count+1)*2>m_cap) Grow();
   int i=Slot(key);
   for(int n=0; n<m_cap; n++)
     {
      if(!m_used[i])
        {
         m_used[i]=true; m_keys[i]=key; m_vals[i]=val; m_count++;
         return;
        }
      if(m_keys[i]==key) { m_vals[i]=val; return; }
      i=(i+1)%m_cap;
     }
  }

void PControl_LongIntMap::Grow()
  {
   long ok[]; int ov[]; bool ou[];
   ArrayCopy(ok,m_keys); ArrayCopy(ov,m_vals); ArrayCopy(ou,m_used);
   int old_cap=m_cap;
   Init(old_cap*2);
   for(int i=0; i<old_cap; i++)
      if(ou[i]) Set(ok[i],ov[i]);
  }

//+------------------------------------------------------------------+
//| PControl_TradeData                                                        |
//+------------------------------------------------------------------+
class PControl_TradeData
  {
private:
   //--- todas las posiciones cerradas, ordenadas por cierre
   PControl_PosRecord        m_all[];
   //--- curva de balance real de la cuenta (incluye depósitos/retiros)
   datetime          m_bal_t[];
   double            m_bal_v[];
   double            m_initial_balance;
   //--- filtros
   string            m_symbols[];
   bool              m_sym_on[];
   long              m_magics[];
   bool              m_mag_on[];
   bool              m_buy_on;
   bool              m_sell_on;
   datetime          m_from;
   datetime          m_to;
   //--- parámetros de disciplina
   int               m_max_trades_day;
   int               m_revenge_minutes;
   double            m_sl_factor;
   //--- resultado filtrado
   PControl_PosRecord        m_filtered[];
   //--- modo de datos de ejemplo
   bool              m_demo_mode;
   double            m_cur_balance;

   void              RebuildSymbolList();
   void              RebuildMagicList();
   bool              SymbolEnabled(const string s) const;
   bool              MagicEnabled(const long m) const;
   bool              PassStaticFilters(const PControl_PosRecord &r) const;
   void              GenerateDemo();

public:
                     PControl_TradeData();

   void              SetDisciplineParams(const int max_trades_day,const int revenge_minutes,const double sl_factor);
   void              SetDemoMode(const bool on) { m_demo_mode=on; }
   bool              DemoMode() const { return(m_demo_mode); }
   double            CurrentBalance() const { return(m_cur_balance); }
   bool              Reload();

   //--- rango temporal
   void              SetRange(const datetime from,const datetime to) { m_from=from; m_to=to; }
   datetime          From() const { return(m_from); }
   datetime          To() const { return(m_to); }

   //--- filtros por símbolo / mágico / tipo
   int               SymbolCount() const { return(ArraySize(m_symbols)); }
   string            SymbolAt(const int i) const { return(m_symbols[i]); }
   bool              SymbolOn(const int i) const { return(m_sym_on[i]); }
   void              ToggleSymbol(const int i) { if(i>=0 && i<ArraySize(m_sym_on)) m_sym_on[i]=!m_sym_on[i]; }
   bool              AllSymbolsOn() const;
   void              SetAllSymbols(const bool on);

   int               MagicCount() const { return(ArraySize(m_magics)); }
   long              MagicAt(const int i) const { return(m_magics[i]); }
   bool              MagicOn(const int i) const { return(m_mag_on[i]); }
   void              ToggleMagic(const int i) { if(i>=0 && i<ArraySize(m_mag_on)) m_mag_on[i]=!m_mag_on[i]; }
   bool              AllMagicsOn() const;
   void              SetAllMagics(const bool on);

   bool              BuyOn() const { return(m_buy_on); }
   bool              SellOn() const { return(m_sell_on); }
   void              ToggleBuy() { m_buy_on=!m_buy_on; }
   void              ToggleSell() { m_sell_on=!m_sell_on; }
   void              SetAllTypes(const bool on) { m_buy_on=on; m_sell_on=on; }

   //--- resultados
   void              ApplyFilter();
   int               FilteredCount() const { return(ArraySize(m_filtered)); }
   void              GetFiltered(PControl_PosRecord &out[]) const;
   void              Filtered(const int i,PControl_PosRecord &out) const { out=m_filtered[i]; }
   int               TotalCount() const { return(ArraySize(m_all)); }
   //--- ignora el rango temporal (usado por el calendario)
   void              CollectNoTime(PControl_PosRecord &out[]) const;
   void              CollectInRange(const datetime from,const datetime to,PControl_PosRecord &out[]) const;

   //--- balance
   double            BalanceAt(const datetime t) const;
   double            InitialBalance() const { return(m_initial_balance); }
   double            HighWatermark() const;

   //--- estadísticas
   void              ComputeStats(const PControl_PosRecord &recs[],PControl_Stats &s) const;
   void              BuildDaily(const PControl_PosRecord &recs[],PControl_DayStat &days[]) const;
   static int        FindDay(const PControl_DayStat &days[],const datetime day);
  };

//+------------------------------------------------------------------+
PControl_TradeData::PControl_TradeData() : m_initial_balance(0),m_buy_on(true),m_sell_on(true),m_from(0),m_to(D'2100.01.01'),
                           m_max_trades_day(3),m_revenge_minutes(5),m_sl_factor(1.3),
                           m_demo_mode(false),m_cur_balance(0)
  {
  }

//+------------------------------------------------------------------+
//| Datos sintéticos para previsualizar el panel sin historial        |
//+------------------------------------------------------------------+
void PControl_TradeData::GenerateDemo()
  {
   string syms[7]={"EURUSD","GBPUSD","XAUUSD","US30","USTEC","DE40","XTIUSD"};
   long   magics[3]={0,1001,2002};
   MathSrand(20240917);

   datetime now=TimeCurrent();
   datetime start=PControl_DayStart((datetime)((long)now-40*86400));
   PControl_PosRecord recs[];
   int n=0;
   double running=10000.0;
   m_initial_balance=running;
   ArrayResize(m_bal_t,0);
   ArrayResize(m_bal_v,0);

   for(int day=0; day<41; day++)
     {
      datetime d=(datetime)((long)start+(long)day*86400);
      int dow=PControl_WeekDay(d);
      if(dow>=5) continue;                       // sin fines de semana
      if(d>now) break;
      int trades_today=MathRand()%4;             // 0..3 operaciones
      if(MathRand()%5==0) trades_today+=2;       // algún día con sobre-trading
      for(int k=0; k<trades_today; k++)
        {
         PControl_PosRecord r;
         PControl_ResetRecord(r);
         int hour=6+MathRand()%16;
         int minute=MathRand()%60;
         r.open_time=(datetime)((long)d+hour*3600+minute*60);
         long dur=300+(long)(MathRand()%(6*3600));
         r.close_time=(datetime)((long)r.open_time+dur);
         if(r.close_time>now) continue;
         r.position_id=100000+n;
         r.symbol=syms[MathRand()%7];
         r.magic=magics[MathRand()%3];
         r.type=MathRand()%2;
         r.vol_in=0.1*(1+MathRand()%10);
         r.vol_out=r.vol_in;
         r.open_price=1.0+(MathRand()%1000)/1000.0;
         r.close_price=r.open_price+((MathRand()%200)-100)/10000.0;
         bool win=(MathRand()%100)<66;
         double base=(win ? 5.0+MathRand()%56 : -(4.0+MathRand()%42));
         if(!win && MathRand()%9==0) base*=2.2;  // alguna violación de stop
         r.profit=NormalizeDouble(base*(0.5+r.vol_in),2);
         r.swap=NormalizeDouble(-(MathRand()%30)/100.0,2);
         r.commission=NormalizeDouble(-5.0*r.vol_in,2);
         r.net=NormalizeDouble(r.profit+r.swap+r.commission,2);
         r.comment="demo";
         r.closed=true;
         ArrayResize(recs,n+1);
         recs[n]=r;
         n++;
        }
     }

   //--- orden por cierre y curva de balance
   long keys[];
   ArrayResize(keys,n);
   for(int i=0; i<n; i++) keys[i]=(long)recs[i].close_time*1000000+i;
   if(n>1) ArraySort(keys);
   ArrayResize(m_all,n);
   ArrayResize(m_bal_t,n+1);
   ArrayResize(m_bal_v,n+1);
   m_bal_t[0]=(datetime)((long)start-86400);
   m_bal_v[0]=running;
   for(int i=0; i<n; i++)
     {
      m_all[i]=recs[(int)(keys[i]%1000000)];
      running+=m_all[i].net;
      m_bal_t[i+1]=m_all[i].close_time;
      m_bal_v[i+1]=running;
     }
   m_cur_balance=running;
  }

//+------------------------------------------------------------------+
void PControl_TradeData::SetDisciplineParams(const int max_trades_day,const int revenge_minutes,const double sl_factor)
  {
   m_max_trades_day=MathMax(1,max_trades_day);
   m_revenge_minutes=MathMax(0,revenge_minutes);
   m_sl_factor=MathMax(1.0,sl_factor);
  }

//+------------------------------------------------------------------+
//| Carga todo el historial y agrega los deals por posición           |
//+------------------------------------------------------------------+
bool PControl_TradeData::Reload()
  {
   if(m_demo_mode)
     {
      GenerateDemo();
      RebuildSymbolList();
      RebuildMagicList();
      ApplyFilter();
      return(true);
     }
   if(!HistorySelect(0,TimeCurrent()+86400*2))
     {
      Print("PanelControl: HistorySelect falló (",GetLastError(),")");
      return(false);
     }
   int total=HistoryDealsTotal();

   //--- ordenar deals por tiempo (clave = tiempo*1e6 + índice)
   long  keys[];
   ulong tickets[];
   ArrayResize(keys,total);
   ArrayResize(tickets,total);
   int n=0;
   for(int i=0; i<total; i++)
     {
      ulong tk=HistoryDealGetTicket(i);
      if(tk==0) continue;
      tickets[n]=tk;
      keys[n]=(long)HistoryDealGetInteger(tk,DEAL_TIME)*1000000+n;
      n++;
     }
   ArrayResize(keys,n);
   ArrayResize(tickets,n);
   if(n>1) ArraySort(keys);

   PControl_LongIntMap pos_map;
   pos_map.Init(n*2+16);

   PControl_PosRecord recs[];
   ArrayResize(recs,0,n);
   int rc=0;

   ArrayResize(m_bal_t,0,n);
   ArrayResize(m_bal_v,0,n);
   double running=0.0;

   for(int k=0; k<n; k++)
     {
      int   di=(int)(keys[k]%1000000);
      ulong tk=tickets[di];
      datetime        dtime=(datetime)HistoryDealGetInteger(tk,DEAL_TIME);
      ENUM_DEAL_TYPE  dtype=(ENUM_DEAL_TYPE)HistoryDealGetInteger(tk,DEAL_TYPE);
      ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(tk,DEAL_ENTRY);
      double profit=HistoryDealGetDouble(tk,DEAL_PROFIT);
      double swap  =HistoryDealGetDouble(tk,DEAL_SWAP);
      double comm  =HistoryDealGetDouble(tk,DEAL_COMMISSION)+HistoryDealGetDouble(tk,DEAL_FEE);

      running+=profit+swap+comm;
      int bn=ArraySize(m_bal_t);
      if(bn>0 && m_bal_t[bn-1]==dtime)
         m_bal_v[bn-1]=running;
      else
        {
         ArrayResize(m_bal_t,bn+1);
         ArrayResize(m_bal_v,bn+1);
         m_bal_t[bn]=dtime;
         m_bal_v[bn]=running;
        }

      if(dtype!=DEAL_TYPE_BUY && dtype!=DEAL_TYPE_SELL) continue;

      long   pid  =HistoryDealGetInteger(tk,DEAL_POSITION_ID);
      double vol  =HistoryDealGetDouble(tk,DEAL_VOLUME);
      double price=HistoryDealGetDouble(tk,DEAL_PRICE);

      int ri=-1;
      if(!pos_map.Get(pid,ri))
        {
         ri=rc;
         ArrayResize(recs,rc+1);
         PControl_ResetRecord(recs[ri]);
         recs[ri].position_id=pid;
         recs[ri].symbol =HistoryDealGetString(tk,DEAL_SYMBOL);
         recs[ri].magic  =HistoryDealGetInteger(tk,DEAL_MAGIC);
         recs[ri].comment=HistoryDealGetString(tk,DEAL_COMMENT);
         recs[ri].sl     =HistoryDealGetDouble(tk,DEAL_SL);
         recs[ri].tp     =HistoryDealGetDouble(tk,DEAL_TP);
         recs[ri].open_time =dtime;
         recs[ri].open_price=price;
         if(entry==DEAL_ENTRY_IN)
            recs[ri].type=(dtype==DEAL_TYPE_BUY ? 0 : 1);
         else
           {
            // cierre de una posición abierta antes del historial disponible
            recs[ri].type=(dtype==DEAL_TYPE_BUY ? 1 : 0);
            recs[ri].orphan=true;
           }
         pos_map.Set(pid,ri);
         rc++;
        }

      recs[ri].profit    +=profit;
      recs[ri].swap      +=swap;
      recs[ri].commission+=comm;

      if(entry==DEAL_ENTRY_IN)
        {
         double tot=recs[ri].vol_in+vol;
         if(tot>0.0)
            recs[ri].open_price=(recs[ri].open_price*recs[ri].vol_in+price*vol)/tot;
         recs[ri].vol_in=tot;
         if(recs[ri].sl==0.0) recs[ri].sl=HistoryDealGetDouble(tk,DEAL_SL);
         if(recs[ri].tp==0.0) recs[ri].tp=HistoryDealGetDouble(tk,DEAL_TP);
        }
      else
        {
         recs[ri].vol_out    +=vol;
         recs[ri].close_time  =dtime;
         recs[ri].close_price =price;
         if(entry==DEAL_ENTRY_INOUT || recs[ri].orphan || recs[ri].vol_out>=recs[ri].vol_in-1e-8)
            recs[ri].closed=true;
        }
     }

   //--- ajustar la curva al balance real de la cuenta
   double acc_balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double offset=acc_balance-running;
   m_initial_balance=offset;
   m_cur_balance=acc_balance;
   int bn=ArraySize(m_bal_v);
   for(int i=0; i<bn; i++) m_bal_v[i]+=offset;

   //--- posiciones cerradas ordenadas por hora de cierre
   long ckeys[];
   int  nc=0;
   ArrayResize(ckeys,rc);
   for(int i=0; i<rc; i++)
     {
      if(!recs[i].closed) continue;
      ckeys[nc]=(long)recs[i].close_time*1000000+i;
      nc++;
     }
   ArrayResize(ckeys,nc);
   if(nc>1) ArraySort(ckeys);
   ArrayResize(m_all,nc);
   for(int i=0; i<nc; i++)
     {
      int ri=(int)(ckeys[i]%1000000);
      m_all[i]=recs[ri];
      m_all[i].net=m_all[i].profit+m_all[i].swap+m_all[i].commission;
     }

   RebuildSymbolList();
   RebuildMagicList();
   ApplyFilter();
   return(true);
  }

//+------------------------------------------------------------------+
void PControl_TradeData::RebuildSymbolList()
  {
   string old_names[];
   bool   old_on[];
   ArrayCopy(old_names,m_symbols);
   ArrayCopy(old_on,m_sym_on);

   string names[];
   int total=ArraySize(m_all);
   for(int i=0; i<total; i++)
     {
      string s=m_all[i].symbol;
      bool found=false;
      for(int j=0; j<ArraySize(names); j++) if(names[j]==s) { found=true; break; }
      if(!found)
        {
         int n=ArraySize(names);
         ArrayResize(names,n+1);
         names[n]=s;
        }
     }
   //--- orden alfabético (inserción)
   int cnt=ArraySize(names);
   for(int i=1; i<cnt; i++)
     {
      string key=names[i];
      int j=i-1;
      while(j>=0 && StringCompare(names[j],key,false)>0) { names[j+1]=names[j]; j--; }
      names[j+1]=key;
     }
   ArrayResize(m_symbols,cnt);
   ArrayResize(m_sym_on,cnt);
   for(int i=0; i<cnt; i++)
     {
      m_symbols[i]=names[i];
      m_sym_on[i]=true;
      for(int j=0; j<ArraySize(old_names); j++)
         if(old_names[j]==names[i]) { m_sym_on[i]=old_on[j]; break; }
     }
  }

//+------------------------------------------------------------------+
void PControl_TradeData::RebuildMagicList()
  {
   long old_m[];
   bool old_on[];
   ArrayCopy(old_m,m_magics);
   ArrayCopy(old_on,m_mag_on);

   long list[];
   int total=ArraySize(m_all);
   for(int i=0; i<total; i++)
     {
      long m=m_all[i].magic;
      bool found=false;
      for(int j=0; j<ArraySize(list); j++) if(list[j]==m) { found=true; break; }
      if(!found)
        {
         int n=ArraySize(list);
         ArrayResize(list,n+1);
         list[n]=m;
        }
     }
   int cnt=ArraySize(list);
   if(cnt>1) ArraySort(list);
   ArrayResize(m_magics,cnt);
   ArrayResize(m_mag_on,cnt);
   for(int i=0; i<cnt; i++)
     {
      m_magics[i]=list[i];
      m_mag_on[i]=true;
      for(int j=0; j<ArraySize(old_m); j++)
         if(old_m[j]==list[i]) { m_mag_on[i]=old_on[j]; break; }
     }
  }

//+------------------------------------------------------------------+
bool PControl_TradeData::SymbolEnabled(const string s) const
  {
   for(int i=0; i<ArraySize(m_symbols); i++)
      if(m_symbols[i]==s) return(m_sym_on[i]);
   return(true);
  }

bool PControl_TradeData::MagicEnabled(const long m) const
  {
   for(int i=0; i<ArraySize(m_magics); i++)
      if(m_magics[i]==m) return(m_mag_on[i]);
   return(true);
  }

bool PControl_TradeData::AllSymbolsOn() const
  {
   for(int i=0; i<ArraySize(m_sym_on); i++) if(!m_sym_on[i]) return(false);
   return(true);
  }

void PControl_TradeData::SetAllSymbols(const bool on)
  {
   for(int i=0; i<ArraySize(m_sym_on); i++) m_sym_on[i]=on;
  }

bool PControl_TradeData::AllMagicsOn() const
  {
   for(int i=0; i<ArraySize(m_mag_on); i++) if(!m_mag_on[i]) return(false);
   return(true);
  }

void PControl_TradeData::SetAllMagics(const bool on)
  {
   for(int i=0; i<ArraySize(m_mag_on); i++) m_mag_on[i]=on;
  }

//+------------------------------------------------------------------+
bool PControl_TradeData::PassStaticFilters(const PControl_PosRecord &r) const
  {
   if(r.type==0 && !m_buy_on) return(false);
   if(r.type==1 && !m_sell_on) return(false);
   if(!SymbolEnabled(r.symbol)) return(false);
   if(!MagicEnabled(r.magic)) return(false);
   return(true);
  }

//+------------------------------------------------------------------+
void PControl_TradeData::ApplyFilter()
  {
   CollectInRange(m_from,m_to,m_filtered);
  }

//+------------------------------------------------------------------+
void PControl_TradeData::GetFiltered(PControl_PosRecord &out[]) const
  {
   int n=ArraySize(m_filtered);
   ArrayResize(out,n);
   for(int i=0; i<n; i++) out[i]=m_filtered[i];
  }

//+------------------------------------------------------------------+
void PControl_TradeData::CollectInRange(const datetime from,const datetime to,PControl_PosRecord &out[]) const
  {
   int total=ArraySize(m_all);
   ArrayResize(out,0,total);
   int n=0;
   for(int i=0; i<total; i++)
     {
      if(m_all[i].close_time<from || m_all[i].close_time>to) continue;
      if(!PassStaticFilters(m_all[i])) continue;
      ArrayResize(out,n+1);
      out[n]=m_all[i];
      n++;
     }
  }

//+------------------------------------------------------------------+
void PControl_TradeData::CollectNoTime(PControl_PosRecord &out[]) const
  {
   CollectInRange(0,D'2100.01.01',out);
  }

//+------------------------------------------------------------------+
//| Balance de la cuenta justo después del último deal <= t           |
//+------------------------------------------------------------------+
double PControl_TradeData::BalanceAt(const datetime t) const
  {
   int n=ArraySize(m_bal_t);
   if(n==0) return(m_cur_balance);
   if(t<m_bal_t[0]) return(m_initial_balance);
   int lo=0, hi=n-1;
   while(lo<hi)
     {
      int mid=(lo+hi+1)/2;
      if(m_bal_t[mid]<=t) lo=mid; else hi=mid-1;
     }
   return(m_bal_v[lo]);
  }

//+------------------------------------------------------------------+
double PControl_TradeData::HighWatermark() const
  {
   double hwm=MathMax(m_initial_balance,m_cur_balance);
   for(int i=0; i<ArraySize(m_bal_v); i++) if(m_bal_v[i]>hwm) hwm=m_bal_v[i];
   return(hwm);
  }

//+------------------------------------------------------------------+
//| Agrupación diaria (recs debe estar ordenado por cierre)           |
//+------------------------------------------------------------------+
void PControl_TradeData::BuildDaily(const PControl_PosRecord &recs[],PControl_DayStat &days[]) const
  {
   ArrayResize(days,0);
   int n=ArraySize(recs);
   double cum=0, peak=0;
   int cur=-1;
   for(int i=0; i<n; i++)
     {
      datetime d=PControl_DayStart(recs[i].close_time);
      if(cur<0 || days[cur].day!=d)
        {
         cur=ArraySize(days);
         ArrayResize(days,cur+1);
         days[cur].day=d;
         days[cur].net=0; days[cur].trades=0; days[cur].wins=0; days[cur].losses=0; days[cur].max_dd=0;
         days[cur].bal_start=BalanceAt((datetime)((long)d-1));
         cum=0; peak=0;
        }
      double v=recs[i].net;
      days[cur].net+=v;
      days[cur].trades++;
      if(v>0) days[cur].wins++; else if(v<0) days[cur].losses++;
      cum+=v;
      if(cum>peak) peak=cum;
      double dd=peak-cum;
      if(dd>days[cur].max_dd) days[cur].max_dd=dd;
     }
  }

//+------------------------------------------------------------------+
int PControl_TradeData::FindDay(const PControl_DayStat &days[],const datetime day)
  {
   int n=ArraySize(days);
   int lo=0, hi=n-1;
   while(lo<=hi)
     {
      int mid=(lo+hi)/2;
      if(days[mid].day==day) return(mid);
      if(days[mid].day<day) lo=mid+1; else hi=mid-1;
     }
   return(-1);
  }

//+------------------------------------------------------------------+
//| Cálculo de estadísticas completas                                 |
//+------------------------------------------------------------------+
void PControl_TradeData::ComputeStats(const PControl_PosRecord &recs[],PControl_Stats &s) const
  {
   ZeroMemory(s);
   int n=ArraySize(recs);
   if(n==0) return;

   s.trades=n;
   s.start_balance=BalanceAt((datetime)((long)recs[0].close_time-1));

   double cum=0, peak=0;
   double sum=0, sum2=0;
   int cw=0, cl=0;
   long dur_sum=0;
   double losses_abs[];
   ArrayResize(losses_abs,0,n);
   int nl=0;

   double curve_start=s.start_balance;
   double peak_curve=curve_start;

   for(int i=0; i<n; i++)
     {
      double v=recs[i].net;
      s.net+=v;
      s.swap+=recs[i].swap;
      s.commission+=recs[i].commission;
      s.volume+=recs[i].vol_in;
      sum+=v; sum2+=v*v;
      dur_sum+=(long)recs[i].close_time-(long)recs[i].open_time;

      if(v>0)
        {
         s.wins++; s.gross_win+=v;
         if(v>s.largest_win) s.largest_win=v;
         cw++; cl=0;
         if(cw>s.max_consec_wins) s.max_consec_wins=cw;
        }
      else if(v<0)
        {
         s.losses++; s.gross_loss+=v;
         if(v<s.largest_loss) s.largest_loss=v;
         cl++; cw=0;
         if(cl>s.max_consec_losses) s.max_consec_losses=cl;
         ArrayResize(losses_abs,nl+1);
         losses_abs[nl]=-v; nl++;
        }
      else
        {
         s.breakeven++;
         cw=0; cl=0;
        }

      if(recs[i].type==0) { s.long_trades++; s.long_net+=v; if(v>0) s.long_wins++; }
      else                { s.short_trades++; s.short_net+=v; if(v>0) s.short_wins++; }

      cum+=v;
      double curve=curve_start+cum;
      if(curve>peak_curve) peak_curve=curve;
      double dd=peak_curve-curve;
      if(dd>s.max_dd_money)
        {
         s.max_dd_money=dd;
         s.max_dd_pct=(peak_curve>0 ? dd/peak_curve*100.0 : 0.0);
        }
     }

   s.win_rate=(n>0 ? 100.0*s.wins/n : 0.0);
   s.avg_win=(s.wins>0 ? s.gross_win/s.wins : 0.0);
   s.avg_loss=(s.losses>0 ? s.gross_loss/s.losses : 0.0);
   s.expectancy=s.net/n;
   s.payoff=(s.avg_loss<0 ? s.avg_win/(-s.avg_loss) : (s.avg_win>0 ? 99.0 : 0.0));
   s.profit_factor=(s.gross_loss<0 ? s.gross_win/(-s.gross_loss) : (s.gross_win>0 ? 99.0 : 0.0));
   double mean=sum/n;
   double var=(n>1 ? (sum2-n*mean*mean)/(n-1) : 0.0);
   s.std_dev=(var>0 ? MathSqrt(var) : 0.0);
   s.sharpe=(s.std_dev>0 ? mean/s.std_dev : 0.0);
   s.recovery_factor=(s.max_dd_money>0 ? s.net/s.max_dd_money : (s.net>0 ? 99.0 : 0.0));
   double wr=s.win_rate/100.0;
   s.kelly=(s.payoff>0 ? (wr-(1.0-wr)/s.payoff)*100.0 : 0.0);
   s.avg_duration=dur_sum/n;

   //--- por día
   PControl_DayStat days[];
   BuildDaily(recs,days);
   s.trading_days=ArraySize(days);
   s.avg_trades_day=(s.trading_days>0 ? (double)n/s.trading_days : 0.0);
   s.best_day=-DBL_MAX; s.worst_day=DBL_MAX;
   for(int i=0; i<s.trading_days; i++)
     {
      if(days[i].net>s.best_day)  { s.best_day=days[i].net;  s.best_day_date=days[i].day; }
      if(days[i].net<s.worst_day) { s.worst_day=days[i].net; s.worst_day_date=days[i].day; }
      if(days[i].trades>m_max_trades_day) s.overtrading_days++;
     }
   if(s.trading_days==0) { s.best_day=0; s.worst_day=0; }

   //--- disciplina: violaciones de stop (pérdida > factor * mediana de pérdidas)
   double median_loss=0;
   if(nl>0)
     {
      ArraySort(losses_abs);
      median_loss=(nl%2==1 ? losses_abs[nl/2] : (losses_abs[nl/2-1]+losses_abs[nl/2])/2.0);
     }
   bool mistake[];
   ArrayResize(mistake,n);
   ArrayFill(mistake,0,n,false);
   if(median_loss>0)
      for(int i=0; i<n; i++)
         if(recs[i].net<0 && -recs[i].net>median_loss*m_sl_factor) { s.sl_violations++; mistake[i]=true; }

   //--- revenge trading: apertura pocos minutos después de cerrar una pérdida
   long window=(long)m_revenge_minutes*60;
   if(window>0)
      for(int i=1; i<n; i++)
        {
         if(recs[i-1].net>=0) continue;
         long gap=(long)recs[i].open_time-(long)recs[i-1].close_time;
         if(gap>=0 && gap<=window) { s.revenge_trades++; mistake[i]=true; }
        }

   //--- cambio de riesgo: últimas pérdidas mucho mayores que las anteriores
   if(nl>=6)
     {
      double early=0, late=0; int ne=0, nlt=0;
      int seen=0;
      for(int i=0; i<n; i++)
        {
         if(recs[i].net>=0) continue;
         seen++;
         if(seen<=nl-3) { early+=-recs[i].net; ne++; } else { late+=-recs[i].net; nlt++; }
        }
      if(ne>0 && nlt>0 && (late/nlt)>2.0*(early/ne)) s.risk_shift=true;
     }

   //--- consistencia de riesgo: coeficiente de variación de las pérdidas
   if(nl>=3)
     {
      double m=0; for(int i=0; i<nl; i++) m+=losses_abs[i]; m/=nl;
      double v2=0; for(int i=0; i<nl; i++) v2+=(losses_abs[i]-m)*(losses_abs[i]-m); v2/=nl;
      double cv=(m>0 ? MathSqrt(v2)/m : 0);
      s.risk_consistent=(cv<0.6);
     }
   else s.risk_consistent=(nl>0);

   int mistakes=0;
   for(int i=0; i<n; i++) if(mistake[i]) mistakes++;
   s.mistake_rate=100.0*mistakes/n;

   double over_pct=(s.trading_days>0 ? 100.0*s.overtrading_days/s.trading_days : 0.0);
   double sl_pct=100.0*s.sl_violations/n;
   double rev_pct=100.0*s.revenge_trades/n;
   double score=100.0;
   score-=MathMin(30.0,over_pct*0.5);
   score-=MathMin(30.0,sl_pct*1.5);
   score-=MathMin(25.0,rev_pct*2.0);
   if(s.risk_shift) score-=15.0;
   s.discipline=MathMax(0.0,MathMin(100.0,score));

   double pf_part=MathMin(s.profit_factor,3.0)/3.0*100.0;
   s.efficiency=MathMax(0.0,MathMin(100.0,0.4*s.win_rate+0.4*pf_part+0.2*(100.0-s.mistake_rate)));
  }

//+------------------------------------------------------------------+
//| SECCIÓN 4: NÚCLEO DEL PANEL - layout, cabecera, filtros, popups   |
//+------------------------------------------------------------------+
struct PControl_Rect
  {
   int               x;
   int               y;
   int               w;
   int               h;
  };

struct PControl_Hit
  {
   int               x1;
   int               y1;
   int               x2;
   int               y2;
   int               action;
   long              p1;
   long              p2;
  };

struct PControl_Settings
  {
   string            font;
   double            scale;
   bool              start_maximized;
   int               x;
   int               y;
   int               w;
   int               h;
   double            pnl_base;
   double            max_dd_pct;
   int               max_trades_day;
   int               revenge_minutes;
   double            sl_factor;
   int               refresh_ms;
   bool              demo_data;
   bool              clean_chart;
  };

//+------------------------------------------------------------------+
//| PControl_Panel                                                            |
//+------------------------------------------------------------------+
class PControl_Panel
  {
private:
   PControl_Render           m_r;
   PControl_TradeData        m_data;
   PControl_Settings    m_set;
   string            m_currency;

   //--- estado de la interfaz
   ENUM_PControl_RANGE     m_range;
   ENUM_PControl_TAB       m_tab;
   ENUM_PControl_FTAB      m_ftab;
   bool              m_minimized;
   bool              m_maximized;
   int               m_cal_year;
   int               m_cal_month;
   ENUM_PControl_HOUR_MODE m_hour_mode;
   bool              m_hour_by_close;
   bool              m_arena_advanced;
   int               m_tx_page;
   int               m_tx_pages;
   int               m_filter_scroll;
   datetime          m_custom_from;
   datetime          m_custom_to;

   //--- ventana emergente
   ENUM_PControl_POPUP     m_popup;
   long              m_popup_p1;
   long              m_popup_p2;
   datetime          m_dp_view;
   int               m_dp_stage;

   //--- ratón
   int               m_mouse_x;
   int               m_mouse_y;
   bool              m_mouse_inside;
   bool              m_left_down;
   bool              m_chart_scroll_orig;
   bool              m_scroll_disabled;
   bool              m_oneclick_orig;
   bool              m_price_scale_orig;
   bool              m_date_scale_orig;
   void              ApplyChartMode();
   bool              m_hover_plot;

   //--- mapa de clics
   PControl_Hit              m_hits[];
   int               m_hit_count;

   //--- geometría calculada en cada Draw
   PControl_Rect             m_rc_filter;
   PControl_Rect             m_rc_content;
   PControl_Rect             m_rc_plot;
   int               m_plot_points;

   //--- datos calculados en cada Draw
   PControl_PosRecord        m_recs[];
   PControl_Stats            m_stats;

   //--- refresco
   bool              m_reload_pending;
   uint              m_reload_due;
   double            m_last_equity;
   double            m_last_balance;

   //--- utilidades
   int               S(const int v) const { return((int)MathRound(v*m_set.scale)); }
   int               FS(const int v) const { return(MathMax(7,(int)MathRound(v*m_set.scale))); }
   void              Hit(const int x,const int y,const int w,const int h,const int action,const long p1=0,const long p2=0);
   bool              InRect(const PControl_Rect &rc,const int x,const int y) const { return(x>=rc.x && x<rc.x+rc.w && y>=rc.y && y<rc.y+rc.h); }
   void              Button(const int x,const int y,const int w,const int h,const string txt,const bool active,const int action,const long p1=0,const long p2=0,const int fs=11);
   void              ApplyGeometry();
   void              UpdateRange();
   void              Dispatch(const int action,const long p1,const long p2);
   bool              HandleClick(const int mx,const int my);
   void              HandleWheel(const int delta);
   void              RefreshData();

   //--- dibujo del marco
   void              Draw();
   void              DrawHeader();
   void              DrawCards(const int y,const int h);
   void              DrawCard(const int x,const int y,const int w,const int h,const string title,const color title_clr,
                              const string value,const color value_clr,const string sub,const color sub_clr,
                              const double bar_ratio,const bool has_bar,const color bar_clr=clrNONE);
   void              DrawTabs(const int y,const int h);
   void              DrawFilterPanel(const PControl_Rect &rc);
   void              DrawContent(const PControl_Rect &rc);
   void              DrawEmpty(const PControl_Rect &rc,const string msg);

   //--- ventanas emergentes
   void              DrawPopups();
   void              PopupFrame(const int x,const int y,const int w,const int h,const string title);
   void              DrawDatePicker();
   void              DrawInfoPopup(const int kind);
   void              DrawHourCellPopup();
   void              DrawCalDayPopup();

   //--- vistas (definidas en View*.mqh)
   void              DrawChartView(const PControl_Rect &rc);
   void              DrawTransactionsView(const PControl_Rect &rc);
   void              DrawCalendarView(const PControl_Rect &rc);
   void              DrawHourlyView(const PControl_Rect &rc);
   void              DrawArenaView(const PControl_Rect &rc);
   void              DrawArenaOverview(const PControl_Rect &rc);
   void              DrawArenaAdvanced(const PControl_Rect &rc);
   void              ArenaBarCard(const int x,const int y,const int w,const int h,const string title,const string value,
                                  const color value_clr,const color frame,const double v,const double vmin,const double vmax,
                                  const double &bounds[],const color &clrs[],const string rating,const string &ticks[]);
   void              ArenaGaugeCard(const int x,const int y,const int w,const int h,const string title,const double score);
   void              ArenaTextCard(const int x,const int y,const int w,const int h,const string title,const color frame,const string &lines[]);
   void              MetricRow(const int x,const int y,const int w,const string label,const string value,const color clr);

public:
                     PControl_Panel();
                    ~PControl_Panel();

   bool              Init(const PControl_Settings &settings);
   void              Deinit();
   void              OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   void              OnTimer();
   void              OnTradeEvent();
   void              Redraw() { Draw(); }
  };

//+------------------------------------------------------------------+
PControl_Panel::PControl_Panel() : m_currency("USD"),m_range(PControl_RANGE_ALL),m_tab(PControl_TAB_CHART),m_ftab(PControl_FTAB_SYMBOL),
                   m_minimized(false),m_maximized(true),m_cal_year(2025),m_cal_month(1),
                   m_hour_mode(PControl_HOUR_BOTH),m_hour_by_close(true),m_arena_advanced(false),
                   m_tx_page(0),m_tx_pages(1),m_filter_scroll(0),m_custom_from(0),m_custom_to(0),
                   m_popup(PControl_POPUP_NONE),m_popup_p1(0),m_popup_p2(0),m_dp_view(0),m_dp_stage(0),
                   m_mouse_x(-1),m_mouse_y(-1),m_mouse_inside(false),m_left_down(false),
                   m_chart_scroll_orig(true),m_scroll_disabled(false),m_oneclick_orig(false),
                   m_price_scale_orig(true),m_date_scale_orig(true),m_hover_plot(false),
                   m_hit_count(0),m_plot_points(0),m_reload_pending(false),m_reload_due(0),
                   m_last_equity(0),m_last_balance(0)
  {
   ZeroMemory(m_rc_filter);
   ZeroMemory(m_rc_content);
   ZeroMemory(m_rc_plot);
   ZeroMemory(m_stats);
  }

//+------------------------------------------------------------------+
PControl_Panel::~PControl_Panel()
  {
  }

//+------------------------------------------------------------------+
bool PControl_Panel::Init(const PControl_Settings &settings)
  {
   m_set=settings;
   if(m_set.scale<0.5) m_set.scale=0.5;
   if(m_set.scale>3.0) m_set.scale=3.0;
   m_maximized=m_set.start_maximized;
   m_currency=AccountInfoString(ACCOUNT_CURRENCY);
   if(m_currency=="") m_currency="USD";

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   m_cal_year=dt.year;
   m_cal_month=dt.mon;
   m_dp_view=PControl_MonthStart(TimeCurrent());
   m_custom_from=PControl_MonthStart(TimeCurrent());
   m_custom_to=PControl_DayStart(TimeCurrent());

   m_chart_scroll_orig=(bool)ChartGetInteger(0,CHART_MOUSE_SCROLL);
   m_oneclick_orig=(bool)ChartGetInteger(0,CHART_SHOW_ONE_CLICK);
   m_price_scale_orig=(bool)ChartGetInteger(0,CHART_SHOW_PRICE_SCALE);
   m_date_scale_orig=(bool)ChartGetInteger(0,CHART_SHOW_DATE_SCALE);
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
   ChartSetInteger(0,CHART_EVENT_MOUSE_WHEEL,true);

   string name=StringFormat("PControl_Canvas_%I64d",ChartID());
   if(!m_r.Create(name,0,0,100,100,m_set.font)) return(false);

   m_data.SetDisciplineParams(m_set.max_trades_day,m_set.revenge_minutes,m_set.sl_factor);
   m_data.SetDemoMode(m_set.demo_data);
   m_data.Reload();
   UpdateRange();
   ApplyGeometry();
   m_last_equity=AccountInfoDouble(ACCOUNT_EQUITY);
   m_last_balance=AccountInfoDouble(ACCOUNT_BALANCE);
   Draw();
   return(true);
  }

//+------------------------------------------------------------------+
void PControl_Panel::Deinit()
  {
   if(m_scroll_disabled)
      ChartSetInteger(0,CHART_MOUSE_SCROLL,m_chart_scroll_orig);
   ChartSetInteger(0,CHART_SHOW_ONE_CLICK,m_oneclick_orig);
   ChartSetInteger(0,CHART_SHOW_PRICE_SCALE,m_price_scale_orig);
   ChartSetInteger(0,CHART_SHOW_DATE_SCALE,m_date_scale_orig);
   m_r.Destroy();
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Oculta el panel de un clic y, en pantalla completa, las escalas   |
//+------------------------------------------------------------------+
void PControl_Panel::ApplyChartMode()
  {
   if(!m_set.clean_chart) return;
   bool full=(m_maximized && !m_minimized);
   ChartSetInteger(0,CHART_SHOW_ONE_CLICK,false);
   ChartSetInteger(0,CHART_SHOW_PRICE_SCALE,(full ? false : m_price_scale_orig));
   ChartSetInteger(0,CHART_SHOW_DATE_SCALE,(full ? false : m_date_scale_orig));
  }

//+------------------------------------------------------------------+
void PControl_Panel::ApplyGeometry()
  {
   ApplyChartMode();
   int cw=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
   int ch=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   int x,y,w,h;
   if(m_maximized) { x=0; y=0; w=cw; h=ch; }
   else            { x=m_set.x; y=m_set.y; w=m_set.w; h=m_set.h; }
   if(m_minimized) h=S(30);
   m_r.Move(x,y);
   m_r.Resize(MathMax(200,w),MathMax(S(30),h));
  }

//+------------------------------------------------------------------+
void PControl_Panel::UpdateRange()
  {
   datetime now=TimeCurrent();
   datetime from=0, to=D'2100.01.01';
   switch(m_range)
     {
      case PControl_RANGE_TODAY:
         from=PControl_DayStart(now);
         to=(datetime)((long)from+86399);
         break;
      case PControl_RANGE_WEEK:
         from=PControl_WeekStart(now);
         to=(datetime)((long)from+7*86400-1);
         break;
      case PControl_RANGE_MONTH:
        {
         from=PControl_MonthStart(now);
         MqlDateTime dt; TimeToStruct(from,dt);
         int ny=dt.year, nm=dt.mon+1; if(nm>12) { nm=1; ny++; }
         to=(datetime)((long)PControl_MakeDate(ny,nm,1)-1);
         break;
        }
      case PControl_RANGE_CUSTOM:
         from=PControl_DayStart(m_custom_from);
         to=(datetime)((long)PControl_DayStart(m_custom_to)+86399);
         break;
      default:
         break;
     }
   m_data.SetRange(from,to);
   m_data.ApplyFilter();
   m_tx_page=0;
  }

//+------------------------------------------------------------------+
void PControl_Panel::RefreshData()
  {
   m_data.GetFiltered(m_recs);
   m_data.ComputeStats(m_recs,m_stats);
  }

//+------------------------------------------------------------------+
void PControl_Panel::Hit(const int x,const int y,const int w,const int h,const int action,const long p1,const long p2)
  {
   if(m_hit_count>=ArraySize(m_hits)) ArrayResize(m_hits,m_hit_count+64);
   m_hits[m_hit_count].x1=x;
   m_hits[m_hit_count].y1=y;
   m_hits[m_hit_count].x2=x+w;
   m_hits[m_hit_count].y2=y+h;
   m_hits[m_hit_count].action=action;
   m_hits[m_hit_count].p1=p1;
   m_hits[m_hit_count].p2=p2;
   m_hit_count++;
  }

//+------------------------------------------------------------------+
void PControl_Panel::Button(const int x,const int y,const int w,const int h,const string txt,const bool active,const int action,const long p1,const long p2,const int fs)
  {
   m_r.Box(x,y,w,h,(active ? PControl_CLR_BLUE : PControl_CLR_BTN),(active ? PControl_CLR_BLUE_LIGHT : PControl_CLR_BORDER2));
   m_r.Text(x+w/2,y+h/2,txt,(active ? PControl_CLR_WHITE : PControl_CLR_TEXT),FS(fs),TA_CENTER|TA_VCENTER,active);
   Hit(x,y,w,h,action,p1,p2);
  }

//+------------------------------------------------------------------+
//| Dibujo completo                                                   |
//+------------------------------------------------------------------+
void PControl_Panel::Draw()
  {
   if(!m_r.IsCreated()) return;
   m_hit_count=0;
   RefreshData();

   int W=m_r.Width(), H=m_r.Height();
   m_r.Clear(PControl_CLR_BG);
   m_r.Frame(0,0,W,H,PControl_CLR_BORDER);
   DrawHeader();

   if(!m_minimized)
     {
      int pad=S(10);
      int y=S(30)+S(4);
      int cards_h=S(52);
      DrawCards(y,cards_h);
      y+=cards_h+S(8);
      int tabs_h=S(22);
      DrawTabs(y,tabs_h);
      y+=tabs_h+S(8);

      int fw=S(112);
      m_rc_filter.x=pad; m_rc_filter.y=y; m_rc_filter.w=fw; m_rc_filter.h=H-y-pad;
      m_rc_content.x=pad+fw+S(8); m_rc_content.y=y; m_rc_content.w=W-m_rc_content.x-pad; m_rc_content.h=H-y-pad;
      if(m_rc_filter.h>S(40) && m_rc_content.w>S(40))
        {
         DrawFilterPanel(m_rc_filter);
         DrawContent(m_rc_content);
         DrawPopups();
        }
     }
   m_r.Update();
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
void PControl_Panel::DrawHeader()
  {
   int W=m_r.Width();
   int h=S(30);
   int pad=S(10);
   m_r.Text(pad,h/2,"Estadísticas",PControl_CLR_BLUE_LIGHT,FS(16),TA_LEFT|TA_VCENTER,true);
   int tw=m_r.TextWidth("Estadísticas",FS(16),true);
   string acc=StringFormat("Cuenta %I64d · %s",AccountInfoInteger(ACCOUNT_LOGIN),m_currency);
   if(m_data.DemoMode()) acc="DATOS DE EJEMPLO · "+m_currency;
   m_r.Text(pad+tw+S(12),h/2+S(1),acc,PControl_CLR_TEXT_MUTED,FS(10),TA_LEFT|TA_VCENTER,false);

   int bh=S(18), gap=S(4);
   int by=(h-bh)/2;
   int x=W-pad;

   //--- minimizar / maximizar
   int sq=S(20);
   x-=sq;
   Button(x,by,sq,bh,(m_minimized ? "▼" : "—"),m_minimized,PControl_ACT_MINIMIZE,0,0,11);
   x-=gap+sq;
   Button(x,by,sq,bh,"□",m_maximized,PControl_ACT_MAXIMIZE,0,0,12);
   x-=S(10);

   if(m_minimized)
     {
      //--- resumen compacto
      string sum=StringFormat("P&L: %s %s   Ops: %d   WR: %s",PControl_Signed(m_stats.net),m_currency,m_stats.trades,PControl_Pct(m_stats.win_rate,1));
      m_r.Text(x,h/2,sum,PControl_CLR_TEXT_DIM,FS(11),TA_RIGHT|TA_VCENTER,false);
      return;
     }

   for(int i=4; i>=0; i--)
     {
      int w=MathMax(S(44),m_r.TextWidth(PControl_RANGE_NAMES[i],FS(11),true)+S(14));
      x-=w;
      Button(x,by,w,bh,PControl_RANGE_NAMES[i],(m_range==i),PControl_ACT_RANGE,i,0,11);
      x-=gap;
     }
  }

//+------------------------------------------------------------------+
void PControl_Panel::DrawCards(const int y,const int h)
  {
   int W=m_r.Width();
   int pad=S(10), gap=S(8);
   int cw=(W-2*pad-5*gap)/6;
   if(cw<S(60)) cw=S(60);
   int x=pad;

   //--- 1. P&L Total con barra de progreso sobre la base configurada (InpPnLBase)
   double base=MathMax(0.0,m_set.pnl_base);
   double pnl_ratio=(base>0 ? MathMin(1.0,MathAbs(m_stats.net)/base) : 0.0);
   string v1=PControl_Money(m_stats.net)+" "+m_currency;
   string s1=StringFormat("G: %s | P: %s",PControl_Money(m_stats.gross_win),PControl_Money(m_stats.gross_loss));
   if(base>0) s1+=StringFormat(" · %s de %s",PControl_Pct(MathAbs(m_stats.net)/base*100.0,0),PControl_Money(base,0));
   color pnl_bar=(m_stats.net>=0 ? PControl_CLR_GREEN : PControl_CLR_RED);
   DrawCard(x,y,cw,h,"P&L Total",PControl_CLR_TEXT_DIM,v1,PControl_PnLColor(m_stats.net),s1,PControl_CLR_TEXT_MUTED,pnl_ratio,base>0,pnl_bar);
   x+=cw+gap;

   //--- 2. Operaciones ganadoras del periodo (con beneficio neto > 0)
   double win_share=(m_stats.trades>0 ? 100.0*m_stats.wins/m_stats.trades : 0.0);
   string v2=IntegerToString(m_stats.wins);
   string s2=StringFormat("%s del total | Media: %s",PControl_Pct(win_share,1),PControl_Signed(m_stats.avg_win));
   DrawCard(x,y,cw,h,"Operaciones Ganadoras",PControl_CLR_GREEN,v2,PControl_CLR_GREEN,s2,PControl_CLR_TEXT_MUTED,0,false);
   x+=cw+gap;

   //--- 3. Operaciones perdedoras del periodo (con beneficio neto < 0)
   double loss_share=(m_stats.trades>0 ? 100.0*m_stats.losses/m_stats.trades : 0.0);
   string v3=IntegerToString(m_stats.losses);
   string s3=StringFormat("%s del total | Media: %s",PControl_Pct(loss_share,1),PControl_Signed(m_stats.avg_loss));
   DrawCard(x,y,cw,h,"Operaciones Perdedoras",PControl_CLR_RED,v3,PControl_CLR_RED,s3,PControl_CLR_TEXT_MUTED,0,false);
   x+=cw+gap;

   //--- 4. Operaciones / WR
   string v4=StringFormat("%d (%s)",m_stats.trades,PControl_Pct(m_stats.win_rate,1));
   string s4=StringFormat("G: %d | P: %d",m_stats.wins,m_stats.losses);
   DrawCard(x,y,cw,h,"Operaciones / WR",PControl_CLR_TEXT_DIM,v4,PControl_CLR_WHITE,s4,PControl_CLR_TEXT_MUTED,0,false);
   x+=cw+gap;

   //--- 5. Drawdown máximo del periodo filtrado (pico-valle de la curva de balance)
   double dd_money=m_stats.max_dd_money;
   double dd_pct=m_stats.max_dd_pct;
   double dd_allowed=MathMax(0.0,m_set.max_dd_pct);
   double dd_used=(dd_allowed>0 ? MathMin(1.0,dd_pct/dd_allowed) : 0.0);
   string v5=PControl_Money(dd_money)+" "+m_currency;
   string s5=PControl_Pct(dd_pct,2)+(dd_allowed>0 ? " | Tolerado: "+PControl_Pct(dd_allowed,0) : "");
   DrawCard(x,y,cw,h,"DD Máximo del Periodo",PControl_CLR_PURPLE,v5,(dd_money>0 ? PControl_CLR_RED : PControl_CLR_GREEN),s5,PControl_CLR_TEXT_MUTED,dd_used,dd_allowed>0);
   x+=cw+gap;

   //--- 6. Swap y Comisión (dos líneas)
   int last_w=W-pad-x;
   if(last_w<cw) last_w=cw;
   m_r.Box(x,y,last_w,h,PControl_CLR_PANEL,PControl_CLR_BORDER);
   m_r.Text(x+last_w/2,y+S(5),"Swap y Comisión",PControl_CLR_TEXT_DIM,FS(11),TA_CENTER|TA_TOP,true);
   m_r.Text(x+last_w/2,y+S(21),"Swap: "+PControl_Money(m_stats.swap,3),PControl_PnLColor(m_stats.swap),FS(11),TA_CENTER|TA_TOP,true);
   m_r.Text(x+last_w/2,y+S(35),"Com.: "+PControl_Money(m_stats.commission,3),PControl_PnLColor(m_stats.commission),FS(11),TA_CENTER|TA_TOP,true);
  }

//+------------------------------------------------------------------+
void PControl_Panel::DrawCard(const int x,const int y,const int w,const int h,const string title,const color title_clr,
                      const string value,const color value_clr,const string sub,const color sub_clr,
                      const double bar_ratio,const bool has_bar,const color bar_clr)
  {
   m_r.Box(x,y,w,h,PControl_CLR_PANEL,PControl_CLR_BORDER);
   m_r.Text(x+w/2,y+S(5),title,title_clr,FS(11),TA_CENTER|TA_TOP,true);
   m_r.Text(x+w/2,y+S(18),value,value_clr,FS(16),TA_CENTER|TA_TOP,true);
   m_r.Text(x+w/2,y+S(38),m_r.Ellipsis(sub,w-S(8),FS(9)),sub_clr,FS(9),TA_CENTER|TA_TOP,false);
   if(has_bar)
     {
      int bx=x+S(6), bw=w-S(12), by=y+h-S(5), bh=S(2);
      m_r.Fill(bx,by,bw,bh,PControl_CLR_BORDER2);
      // sin color explícito: semáforo de "consumo" (verde -> naranja -> rojo)
      color bc=(bar_clr!=clrNONE ? bar_clr : (bar_ratio<0.5 ? PControl_CLR_GREEN : (bar_ratio<0.8 ? PControl_CLR_ORANGE : PControl_CLR_RED)));
      int fwid=(int)MathRound(bw*MathMax(0.0,MathMin(1.0,bar_ratio)));
      if(fwid>0) m_r.Fill(bx,by,fwid,bh,bc);
     }
  }

//+------------------------------------------------------------------+
void PControl_Panel::DrawTabs(const int y,const int h)
  {
   int pad=S(10), gap=S(4);
   int x=pad;
   for(int i=0; i<5; i++)
     {
      int w=m_r.TextWidth(PControl_TAB_NAMES[i],FS(11),true)+S(20);
      Button(x,y,w,h,PControl_TAB_NAMES[i],(m_tab==i),PControl_ACT_TAB,i,0,11);
      x+=w+gap;
     }
  }

//+------------------------------------------------------------------+
//| Panel lateral de filtros                                          |
//+------------------------------------------------------------------+
void PControl_Panel::DrawFilterPanel(const PControl_Rect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PControl_CLR_PANEL,PControl_CLR_BORDER);
   int pad=S(6), gap=S(3);
   int tw=(rc.w-2*pad-2*gap)/3;
   int ty=rc.y+pad;
   for(int i=0; i<3; i++)
      Button(rc.x+pad+i*(tw+gap),ty,tw,S(16),PControl_FTAB_NAMES[i],(m_ftab==i),PControl_ACT_FTAB,i,0,9);

   m_r.Text(rc.x+rc.w/2,ty+S(22),PControl_FTAB_TITLES[m_ftab],PControl_CLR_BLUE_LIGHT,FS(9),TA_CENTER|TA_TOP,false);

   int rowh=S(17);
   int list_y=ty+S(38);
   int cb=S(10);
   int text_x=rc.x+pad+cb+S(6);

   //--- TODOS
   bool all_on=true;
   int count=0;
   if(m_ftab==PControl_FTAB_SYMBOL) { all_on=m_data.AllSymbolsOn(); count=m_data.SymbolCount(); }
   else if(m_ftab==PControl_FTAB_MAGIC) { all_on=m_data.AllMagicsOn(); count=m_data.MagicCount(); }
   else { all_on=(m_data.BuyOn() && m_data.SellOn()); count=2; }

   m_r.Checkbox(rc.x+pad,list_y+(rowh-cb)/2,cb,all_on,PControl_CLR_BLUE_LIGHT);
   m_r.Text(text_x,list_y+rowh/2,"TODOS",PControl_CLR_TEXT,FS(10),TA_LEFT|TA_VCENTER,false);
   Hit(rc.x,list_y,rc.w,rowh,PControl_ACT_FILTER_ALL);
   m_r.HLine(rc.x+pad,rc.x+rc.w-pad,list_y+rowh+S(2),PControl_CLR_BORDER2);

   int items_y=list_y+rowh+S(6);
   int avail=rc.y+rc.h-pad-items_y;
   int visible=MathMax(1,avail/rowh);
   if(m_filter_scroll>MathMax(0,count-visible)) m_filter_scroll=MathMax(0,count-visible);
   if(m_filter_scroll<0) m_filter_scroll=0;

   for(int k=0; k<visible; k++)
     {
      int i=m_filter_scroll+k;
      if(i>=count) break;
      int ry=items_y+k*rowh;
      bool on=true;
      string name="";
      color sq=PControl_SYMBOL_PALETTE[i%12];
      if(m_ftab==PControl_FTAB_SYMBOL) { on=m_data.SymbolOn(i); name=m_data.SymbolAt(i); }
      else if(m_ftab==PControl_FTAB_MAGIC) { on=m_data.MagicOn(i); name=IntegerToString(m_data.MagicAt(i)); if(m_data.MagicAt(i)==0) name="0 (manual)"; }
      else { on=(i==0 ? m_data.BuyOn() : m_data.SellOn()); name=(i==0 ? "Compra" : "Venta"); sq=(i==0 ? PControl_CLR_GREEN : PControl_CLR_RED); }

      m_r.Checkbox(rc.x+pad,ry+(rowh-cb)/2,cb,on,PControl_CLR_BLUE_LIGHT);
      int sqs=S(8);
      m_r.Fill(rc.x+pad+cb+S(4),ry+(rowh-sqs)/2,sqs,sqs,sq);
      int nx=rc.x+pad+cb+S(4)+sqs+S(5);
      m_r.Text(nx,ry+rowh/2,m_r.Ellipsis(name,rc.x+rc.w-pad-nx-(count>visible ? S(6) : 0),FS(10)),(on ? PControl_CLR_TEXT : PControl_CLR_TEXT_MUTED),FS(10),TA_LEFT|TA_VCENTER,false);
      Hit(rc.x,ry,rc.w,rowh,PControl_ACT_FILTER_ITEM,i);
     }

   //--- barra de desplazamiento
   if(count>visible)
     {
      int track_x=rc.x+rc.w-S(5), track_y=items_y, track_h=visible*rowh;
      m_r.Fill(track_x,track_y,S(3),track_h,PControl_CLR_BORDER);
      int th=MathMax(S(10),track_h*visible/count);
      int ty2=track_y+(track_h-th)*m_filter_scroll/MathMax(1,count-visible);
      m_r.Fill(track_x,ty2,S(3),th,PControl_CLR_BORDER2);
     }
  }

//+------------------------------------------------------------------+
void PControl_Panel::DrawContent(const PControl_Rect &rc)
  {
   switch(m_tab)
     {
      case PControl_TAB_CHART:        DrawChartView(rc);        break;
      case PControl_TAB_TRANSACTIONS: DrawTransactionsView(rc); break;
      case PControl_TAB_CALENDAR:     DrawCalendarView(rc);     break;
      case PControl_TAB_HOURLY:       DrawHourlyView(rc);       break;
      case PControl_TAB_ARENA:        DrawArenaView(rc);        break;
     }
  }

//+------------------------------------------------------------------+
void PControl_Panel::DrawEmpty(const PControl_Rect &rc,const string msg)
  {
   m_r.Text(rc.x+rc.w/2,rc.y+rc.h/2,msg,PControl_CLR_TEXT_MUTED,FS(12),TA_CENTER|TA_VCENTER,false);
  }

//+------------------------------------------------------------------+
//| Ventanas emergentes                                               |
//+------------------------------------------------------------------+
void PControl_Panel::DrawPopups()
  {
   switch(m_popup)
     {
      case PControl_POPUP_DATEPICKER:  DrawDatePicker();      break;
      case PControl_POPUP_INFO_HOURLY: DrawInfoPopup(0);      break;
      case PControl_POPUP_INFO_ARENA:  DrawInfoPopup(1);      break;
      case PControl_POPUP_HOUR_CELL:   DrawHourCellPopup();   break;
      case PControl_POPUP_CAL_DAY:     DrawCalDayPopup();     break;
      default: break;
     }
  }

//+------------------------------------------------------------------+
void PControl_Panel::PopupFrame(const int x,const int y,const int w,const int h,const string title)
  {
   Hit(0,0,m_r.Width(),m_r.Height(),PControl_ACT_BACKDROP);
   m_r.Fill(x+S(4),y+S(4),w,h,PControl_CLR_BG);
   m_r.Box(x,y,w,h,PControl_CLR_PANEL,PControl_CLR_BLUE);
   int th=S(24);
   m_r.Fill(x+1,y+1,w-2,th,PControl_CLR_PANEL3);
   m_r.HLine(x+1,x+w-2,y+th,PControl_CLR_BLUE);
   m_r.Text(x+w/2,y+th/2+1,title,PControl_CLR_BLUE_LIGHT,FS(11),TA_CENTER|TA_VCENTER,true);
   Hit(x,y,w,h,PControl_ACT_NONE);
   int cs=S(18);
   m_r.Text(x+w-cs/2-S(4),y+th/2+1,"×",PControl_CLR_TEXT,FS(14),TA_CENTER|TA_VCENTER,true);
   Hit(x+w-cs-S(4),y+(th-cs)/2,cs+S(4),cs,PControl_ACT_POPUP_CLOSE);
  }

//+------------------------------------------------------------------+
void PControl_Panel::DrawDatePicker()
  {
   int w=S(250), h=S(262);
   int x=m_rc_content.x+(m_rc_content.w-w)/2;
   int y=m_rc_content.y+(m_rc_content.h-h)/2;
   if(y<S(30)) y=S(30);
   PopupFrame(x,y,w,h,(m_dp_stage==0 ? "Seleccionar fecha de inicio" : "Seleccionar fecha de fin"));

   MqlDateTime vdt;
   TimeToStruct(m_dp_view,vdt);
   int ny=y+S(30);
   int nav=S(18);
   Button(x+S(10),ny,nav,nav,"<",false,PControl_ACT_DP_PREV,0,0,10);
   Button(x+w-S(10)-nav,ny,nav,nav,">",false,PControl_ACT_DP_NEXT,0,0,10);
   m_r.Text(x+w/2,ny+nav/2,PControl_MONTHS[vdt.mon-1]+" "+IntegerToString(vdt.year),PControl_CLR_BLUE_LIGHT,FS(11),TA_CENTER|TA_VCENTER,true);

   int gx=x+S(10), gy=ny+nav+S(8);
   int cw=(w-S(20))/7, ch=S(22);
   for(int d=0; d<7; d++)
      m_r.Text(gx+d*cw+cw/2,gy+S(6),PControl_DAYS_SHORT[d],PControl_CLR_TEXT_MUTED,FS(9),TA_CENTER|TA_TOP,false);
   gy+=S(18);

   datetime month_start=PControl_MakeDate(vdt.year,vdt.mon,1);
   int first_dow=PControl_WeekDay(month_start);
   int dim=PControl_DaysInMonth(vdt.year,vdt.mon);
   datetime today=PControl_DayStart(TimeCurrent());
   datetime sel_from=PControl_DayStart(m_custom_from);
   for(int idx=0; idx<42; idx++)
     {
      int day=idx-first_dow+1;
      int col=idx%7, row=idx/7;
      int cx=gx+col*cw, cy=gy+row*ch;
      if(day<1 || day>dim) continue;
      datetime d=PControl_MakeDate(vdt.year,vdt.mon,day);
      bool is_sel=(m_dp_stage==1 && d==sel_from);
      color bg=(is_sel ? PControl_CLR_BLUE : PControl_CLR_PANEL2);
      m_r.Box(cx+1,cy+1,cw-2,ch-2,bg,(d==today ? PControl_CLR_BLUE_LIGHT : PControl_CLR_BORDER));
      m_r.Text(cx+cw/2,cy+ch/2,IntegerToString(day),(is_sel ? PControl_CLR_WHITE : PControl_CLR_TEXT),FS(10),TA_CENTER|TA_VCENTER,false);
      Hit(cx,cy,cw,ch,PControl_ACT_DP_DAY,(long)d);
     }

   int fy=gy+6*ch+S(6);
   if(m_dp_stage==0)
      m_r.Text(x+w/2,fy,"Haz clic en un día para fijar el inicio",PControl_CLR_TEXT_MUTED,FS(9),TA_CENTER|TA_TOP,false);
   else
     {
      m_r.Text(x+S(10),fy,"Inicio: "+PControl_DateStr(sel_from),PControl_CLR_GREEN,FS(9),TA_LEFT|TA_TOP,false);
      Button(x+w-S(10)-S(64),fy-S(3),S(64),S(16),"Reiniciar",false,PControl_ACT_DP_RESET,0,0,9);
     }
  }

//+------------------------------------------------------------------+
void PControl_Panel::DrawInfoPopup(const int kind)
  {
   string lines[];
   string title;
   if(kind==0)
     {
      title="Rendimiento por Horas";
      ArrayResize(lines,6);
      lines[0]="Cuadrícula 7 x 24: cada celda agrupa las operaciones cerradas por día de la semana y hora.";
      lines[1]="Alterna entre hora de APERTURA y hora de CIERRE con el botón azul de la derecha.";
      lines[2]="Filtra por dirección: Compra/Venta (ambas), solo Compra o solo Venta.";
      lines[3]="El valor superior es el P&L neto de la celda; el inferior, el número de operaciones (T).";
      lines[4]="La columna y fila TOTAL acumulan por día y por hora respectivamente.";
      lines[5]="Haz clic en una celda para ver el desglose detallado (compras, ventas, ratio G/P y P&L).";
     }
   else
     {
      title="Estadísticas Arena";
      ArrayResize(lines,8);
      lines[0]="Ratio de Sharpe: media del P&L por operación dividida por su desviación típica (0-3).";
      lines[1]="Factor de Beneficio: beneficio bruto / pérdida bruta. Por encima de 1.5 se considera bueno.";
      lines[2]="Drawdown Máximo: mayor caída desde un máximo de la curva de balance, en % del balance.";
      lines[3]="Puntuación de Disciplina (0-100): penaliza sobre-trading, violaciones de stop, revenge trading y cambios bruscos de riesgo.";
      lines[4]="Eficiencia: combina tasa de acierto (40%), factor de beneficio (40%) y ausencia de errores (20%).";
      lines[5]="Tasa de Errores: % de operaciones marcadas como violación de stop o revenge trading.";
      lines[6]="Violación de stop: pérdida mayor que la pérdida mediana multiplicada por el factor configurado.";
      lines[7]="Revenge trading: apertura pocos minutos después de cerrar una operación perdedora.";
     }

   int w=MathMin(S(520),m_rc_content.w-S(20));
   int inner=w-S(24);
   int total_lines=0;
   string wrapped[];
   ArrayResize(wrapped,0);
   for(int i=0; i<ArraySize(lines); i++)
     {
      string tmp[];
      int n=m_r.WrapText("• "+lines[i],inner,FS(10),false,tmp);
      for(int j=0; j<n; j++)
        {
         ArrayResize(wrapped,total_lines+1);
         wrapped[total_lines]=tmp[j];
         total_lines++;
        }
      ArrayResize(wrapped,total_lines+1);
      wrapped[total_lines]="";
      total_lines++;
     }
   int lh=S(14);
   int h=S(40)+total_lines*lh;
   int x=m_rc_content.x+(m_rc_content.w-w)/2;
   int y=m_rc_content.y+MathMax(S(10),(m_rc_content.h-h)/2);
   PopupFrame(x,y,w,h,title);
   int ty=y+S(32);
   for(int i=0; i<total_lines; i++)
      m_r.Text(x+S(12),ty+i*lh,wrapped[i],PControl_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
  }

//+------------------------------------------------------------------+
//| Eventos                                                           |
//+------------------------------------------------------------------+
void PControl_Panel::OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(!m_r.IsCreated()) return;

   if(id==CHARTEVENT_CHART_CHANGE)
     {
      int cw=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
      int ch=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
      if(m_maximized && (cw!=m_r.Width() || (!m_minimized && ch!=m_r.Height())))
        {
         ApplyGeometry();
         Draw();
        }
      return;
     }

   if(id==CHARTEVENT_MOUSE_MOVE)
     {
      int mx=(int)lparam-m_r.X();
      int my=(int)dparam-m_r.Y();
      m_mouse_x=mx; m_mouse_y=my;
      bool inside=(mx>=0 && my>=0 && mx<m_r.Width() && my<m_r.Height());
      m_mouse_inside=inside;

      //--- bloquear el desplazamiento del gráfico bajo el panel
      if(inside && !m_scroll_disabled)
        {
         ChartSetInteger(0,CHART_MOUSE_SCROLL,false);
         m_scroll_disabled=true;
        }
      else if(!inside && m_scroll_disabled)
        {
         ChartSetInteger(0,CHART_MOUSE_SCROLL,m_chart_scroll_orig);
         m_scroll_disabled=false;
        }

      int flags=(int)StringToInteger(sparam);
      bool left=((flags&1)!=0);
      if(left)
        {
         if(!m_left_down)
           {
            m_left_down=true;
            if(inside) HandleClick(mx,my);
           }
        }
      else
         m_left_down=false;

      //--- hover sobre el gráfico de balance
      if(m_tab==PControl_TAB_CHART && m_popup==PControl_POPUP_NONE && !m_minimized)
        {
         bool in_plot=inside && InRect(m_rc_plot,mx,my);
         if(in_plot || m_hover_plot)
           {
            m_hover_plot=in_plot;
            Draw();
           }
        }
      return;
     }

   if(id==CHARTEVENT_MOUSE_WHEEL)
     {
      if(!m_mouse_inside || m_minimized) return;
      int delta=(dparam>0 ? 1 : -1);
      HandleWheel(delta);
      return;
     }

   if(id==CHARTEVENT_KEYDOWN)
     {
      if(lparam==27 && m_popup!=PControl_POPUP_NONE)
        {
         m_popup=PControl_POPUP_NONE;
         Draw();
        }
      return;
     }
  }

//+------------------------------------------------------------------+
void PControl_Panel::HandleWheel(const int delta)
  {
   if(m_popup==PControl_POPUP_DATEPICKER)
     {
      Dispatch(delta>0 ? PControl_ACT_DP_PREV : PControl_ACT_DP_NEXT,0,0);
      return;
     }
   if(m_popup!=PControl_POPUP_NONE) return;

   if(InRect(m_rc_filter,m_mouse_x,m_mouse_y))
     {
      m_filter_scroll-=delta;
      if(m_filter_scroll<0) m_filter_scroll=0;
      Draw();
      return;
     }
   if(InRect(m_rc_content,m_mouse_x,m_mouse_y))
     {
      if(m_tab==PControl_TAB_TRANSACTIONS) Dispatch(delta>0 ? PControl_ACT_TX_PREV : PControl_ACT_TX_NEXT,0,0);
      else if(m_tab==PControl_TAB_CALENDAR) Dispatch(delta>0 ? PControl_ACT_CAL_PREV : PControl_ACT_CAL_NEXT,0,0);
     }
  }

//+------------------------------------------------------------------+
bool PControl_Panel::HandleClick(const int mx,const int my)
  {
   for(int i=m_hit_count-1; i>=0; i--)
     {
      if(mx>=m_hits[i].x1 && mx<m_hits[i].x2 && my>=m_hits[i].y1 && my<m_hits[i].y2)
        {
         if(m_hits[i].action==PControl_ACT_NONE) return(true);
         Dispatch(m_hits[i].action,m_hits[i].p1,m_hits[i].p2);
         return(true);
        }
     }
   return(false);
  }

//+------------------------------------------------------------------+
void PControl_Panel::Dispatch(const int action,const long p1,const long p2)
  {
   switch(action)
     {
      case PControl_ACT_RANGE:
         if(p1==PControl_RANGE_CUSTOM)
           {
            m_popup=PControl_POPUP_DATEPICKER;
            m_dp_stage=0;
            m_dp_view=PControl_MonthStart(m_custom_from>0 ? m_custom_from : TimeCurrent());
           }
         else
           {
            m_range=(ENUM_PControl_RANGE)p1;
            m_popup=PControl_POPUP_NONE;
            UpdateRange();
           }
         break;
      case PControl_ACT_TAB:
         m_tab=(ENUM_PControl_TAB)p1;
         m_popup=PControl_POPUP_NONE;
         m_hover_plot=false;
         break;
      case PControl_ACT_FTAB:
         m_ftab=(ENUM_PControl_FTAB)p1;
         m_filter_scroll=0;
         break;
      case PControl_ACT_FILTER_ALL:
         if(m_ftab==PControl_FTAB_SYMBOL) m_data.SetAllSymbols(!m_data.AllSymbolsOn());
         else if(m_ftab==PControl_FTAB_MAGIC) m_data.SetAllMagics(!m_data.AllMagicsOn());
         else m_data.SetAllTypes(!(m_data.BuyOn() && m_data.SellOn()));
         m_data.ApplyFilter();
         m_tx_page=0;
         break;
      case PControl_ACT_FILTER_ITEM:
         if(m_ftab==PControl_FTAB_SYMBOL) m_data.ToggleSymbol((int)p1);
         else if(m_ftab==PControl_FTAB_MAGIC) m_data.ToggleMagic((int)p1);
         else { if(p1==0) m_data.ToggleBuy(); else m_data.ToggleSell(); }
         m_data.ApplyFilter();
         m_tx_page=0;
         break;
      case PControl_ACT_CAL_PREV:
         m_cal_month--;
         if(m_cal_month<1) { m_cal_month=12; m_cal_year--; }
         m_popup=PControl_POPUP_NONE;
         break;
      case PControl_ACT_CAL_NEXT:
         m_cal_month++;
         if(m_cal_month>12) { m_cal_month=1; m_cal_year++; }
         m_popup=PControl_POPUP_NONE;
         break;
      case PControl_ACT_CAL_DAY:
         m_popup=PControl_POPUP_CAL_DAY;
         m_popup_p1=p1;
         break;
      case PControl_ACT_HOUR_MODE:
         m_hour_mode=(ENUM_PControl_HOUR_MODE)p1;
         m_popup=PControl_POPUP_NONE;
         break;
      case PControl_ACT_HOUR_TIME:
         m_hour_by_close=!m_hour_by_close;
         m_popup=PControl_POPUP_NONE;
         break;
      case PControl_ACT_HOUR_CELL:
         m_popup=PControl_POPUP_HOUR_CELL;
         m_popup_p1=p1;
         m_popup_p2=p2;
         break;
      case PControl_ACT_ARENA_VIEW:
         m_arena_advanced=(p1==1);
         break;
      case PControl_ACT_INFO:
         m_popup=(p1==0 ? PControl_POPUP_INFO_HOURLY : PControl_POPUP_INFO_ARENA);
         break;
      case PControl_ACT_POPUP_CLOSE:
      case PControl_ACT_BACKDROP:
         m_popup=PControl_POPUP_NONE;
         break;
      case PControl_ACT_TX_PREV:
         if(m_tx_page>0) m_tx_page--;
         break;
      case PControl_ACT_TX_NEXT:
         if(m_tx_page<m_tx_pages-1) m_tx_page++;
         break;
      case PControl_ACT_MINIMIZE:
         m_minimized=!m_minimized;
         m_popup=PControl_POPUP_NONE;
         ApplyGeometry();
         break;
      case PControl_ACT_MAXIMIZE:
         m_maximized=!m_maximized;
         ApplyGeometry();
         break;
      case PControl_ACT_DP_PREV:
        {
         MqlDateTime dt; TimeToStruct(m_dp_view,dt);
         dt.mon--; if(dt.mon<1) { dt.mon=12; dt.year--; }
         m_dp_view=PControl_MakeDate(dt.year,dt.mon,1);
         break;
        }
      case PControl_ACT_DP_NEXT:
        {
         MqlDateTime dt; TimeToStruct(m_dp_view,dt);
         dt.mon++; if(dt.mon>12) { dt.mon=1; dt.year++; }
         m_dp_view=PControl_MakeDate(dt.year,dt.mon,1);
         break;
        }
      case PControl_ACT_DP_DAY:
        {
         datetime d=(datetime)p1;
         if(m_dp_stage==0)
           {
            m_custom_from=d;
            m_dp_stage=1;
           }
         else
           {
            if(d<m_custom_from) { m_custom_to=m_custom_from; m_custom_from=d; }
            else m_custom_to=d;
            m_range=PControl_RANGE_CUSTOM;
            m_popup=PControl_POPUP_NONE;
            UpdateRange();
           }
         break;
        }
      case PControl_ACT_DP_RESET:
         m_dp_stage=0;
         break;
      default:
         break;
     }
   Draw();
  }

//+------------------------------------------------------------------+
void PControl_Panel::OnTimer()
  {
   if(!m_r.IsCreated()) return;
   if(m_reload_pending && (int)(GetTickCount()-m_reload_due)>=0)
     {
      m_reload_pending=false;
      m_data.Reload();
      m_data.ApplyFilter();
      m_last_equity=AccountInfoDouble(ACCOUNT_EQUITY);
      m_last_balance=AccountInfoDouble(ACCOUNT_BALANCE);
      Draw();
      return;
     }
   if(m_popup!=PControl_POPUP_NONE || m_hover_plot) return;
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   double bal=AccountInfoDouble(ACCOUNT_BALANCE);
   if(MathAbs(eq-m_last_equity)>0.005 || MathAbs(bal-m_last_balance)>0.005)
     {
      m_last_equity=eq;
      m_last_balance=bal;
      Draw();
     }
  }

//+------------------------------------------------------------------+
void PControl_Panel::OnTradeEvent()
  {
   m_reload_pending=true;
   m_reload_due=GetTickCount()+400;
  }

//+------------------------------------------------------------------+
//| SECCIÓN 5: VISTA "GRÁFICO" (P&L acumulado)                        |
//+------------------------------------------------------------------+
#define PControl_YOF(val) (py+(int)MathRound((vmax-(val))/(vmax-vmin)*(ph-1)))

//+------------------------------------------------------------------+
void PControl_Panel::DrawChartView(const PControl_Rect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PControl_CLR_PANEL,PControl_CLR_BORDER);
   m_r.Text(rc.x+S(10),rc.y+S(8),"Evolución del Balance",PControl_CLR_TEXT,FS(13),TA_LEFT|TA_TOP,true);
   m_r.Text(rc.x+rc.w-S(10),rc.y+S(10),"P&L neto acumulado ("+m_currency+")",PControl_CLR_TEXT_MUTED,FS(9),TA_RIGHT|TA_TOP,false);

   int n=ArraySize(m_recs);
   m_rc_plot.x=rc.x+S(62);
   m_rc_plot.y=rc.y+S(34);
   m_rc_plot.w=rc.w-S(74);
   m_rc_plot.h=rc.h-S(64);
   m_plot_points=n;

   if(n==0 || m_rc_plot.w<S(40) || m_rc_plot.h<S(40))
     {
      DrawEmpty(rc,"Sin operaciones cerradas en el rango seleccionado");
      return;
     }

   //--- serie acumulada (punto 0 = inicio del período)
   double v[];
   ArrayResize(v,n+1);
   v[0]=0.0;
   double vmin=0.0, vmax=0.0;
   for(int i=0; i<n; i++)
     {
      v[i+1]=v[i]+m_recs[i].net;
      if(v[i+1]<vmin) vmin=v[i+1];
      if(v[i+1]>vmax) vmax=v[i+1];
     }
   if(vmax-vmin<1e-9) { vmax+=1.0; vmin-=1.0; }
   double margin=(vmax-vmin)*0.08;
   vmax+=margin; vmin-=margin;

   int px=m_rc_plot.x, py=m_rc_plot.y, pw=m_rc_plot.w, ph=m_rc_plot.h;
   m_r.Fill(px,py,pw,ph,PControl_Mix(PControl_CLR_PANEL,PControl_CLR_BG,0.5));

   //--- rejilla horizontal y eje Y
   int ticks=(ph<S(160) ? 4 : 6);
   for(int t=0; t<ticks; t++)
     {
      double val=vmax-(vmax-vmin)*t/(ticks-1);
      int yy=py+(int)MathRound((ph-1)*(double)t/(ticks-1));
      m_r.DottedHLine(px,px+pw-1,yy,PControl_CLR_GRID,2);
      m_r.Text(px-S(6),yy,DoubleToString(val,2),PControl_CLR_TEXT_MUTED,FS(9),TA_RIGHT|TA_VCENTER,false);
     }

   //--- rejilla vertical y eje X (fechas)
   int xt=(pw<S(360) ? 3 : 5);
   for(int t=0; t<xt; t++)
     {
      int xx=px+(int)MathRound((pw-1)*(double)t/(xt-1));
      m_r.DottedVLine(xx,py,py+ph-1,PControl_CLR_GRID,2);
      int idx=(int)MathRound((n-1)*(double)t/(xt-1));
      uint al=(t==0 ? TA_LEFT : (t==xt-1 ? TA_RIGHT : TA_CENTER));
      m_r.Text(xx,py+ph+S(6),PControl_DateStr(m_recs[idx].close_time),PControl_CLR_TEXT_MUTED,FS(9),al|TA_TOP,false);
     }

   int y0=PControl_YOF(0.0);
   if(y0<py) y0=py;
   if(y0>py+ph-1) y0=py+ph-1;

   //--- relleno en columnas (textura de líneas verticales)
   color gfill=PControl_Mix(PControl_CLR_GREEN,PControl_CLR_PANEL,0.62);
   color gfill2=PControl_Mix(PControl_CLR_GREEN,PControl_CLR_PANEL,0.78);
   color rfill=PControl_Mix(PControl_CLR_RED,PControl_CLR_PANEL,0.62);
   color rfill2=PControl_Mix(PControl_CLR_RED,PControl_CLR_PANEL,0.78);
   for(int cx=0; cx<pw; cx++)
     {
      double pos=(double)cx/(pw-1)*n;
      int i0=(int)MathFloor(pos);
      if(i0>=n) i0=n-1;
      if(i0<0) i0=0;
      double frac=pos-i0;
      double val=v[i0]+(v[i0+1]-v[i0])*frac;
      int yy=PControl_YOF(val);
      if(yy<py) yy=py;
      if(yy>py+ph-1) yy=py+ph-1;
      bool alt=((cx%3)==0);
      color c=(val>=0 ? (alt ? gfill : gfill2) : (alt ? rfill : rfill2));
      if(yy<y0)      m_r.VLine(px+cx,yy,y0,c);
      else if(yy>y0) m_r.VLine(px+cx,y0,yy,c);
     }
   m_r.HLine(px,px+pw-1,y0,PControl_CLR_BORDER2);

   //--- curva
   int prev_x=-1, prev_y=-1;
   for(int i=0; i<=n; i++)
     {
      int xx=px+(int)MathRound((pw-1)*(double)i/n);
      int yy=PControl_YOF(v[i]);
      if(prev_x>=0)
        {
         color lc=(v[i]>=0 ? PControl_CLR_GREEN_BRIGHT : PControl_CLR_RED);
         m_r.Line(prev_x,prev_y,xx,yy,lc);
         m_r.Line(prev_x,prev_y+1,xx,yy+1,lc);
        }
      prev_x=xx; prev_y=yy;
     }
   m_r.Frame(px,py,pw,ph,PControl_CLR_BORDER);

   //--- información al pasar el ratón
   if(m_hover_plot && InRect(m_rc_plot,m_mouse_x,m_mouse_y))
     {
      double pos=(double)(m_mouse_x-px)/(pw-1)*n;
      int i=(int)MathRound(pos);
      if(i<0) i=0;
      if(i>n) i=n;
      int xx=px+(int)MathRound((pw-1)*(double)i/n);
      int yy=PControl_YOF(v[i]);
      m_r.DottedVLine(xx,py,py+ph-1,PControl_CLR_TEXT_DIM,2);
      m_r.Circle(xx,yy,S(3),PControl_CLR_WHITE);

      string l1,l2,l3;
      color  c3=PControl_CLR_TEXT_DIM;
      if(i==0)
        {
         l1="Inicio del período";
         l2="P&L acumulado: 0.00 "+m_currency;
         l3="";
        }
      else
        {
         PControl_PosRecord r=m_recs[i-1];
         l1=PControl_DateTimeStr(r.close_time);
         l2="P&L acumulado: "+PControl_Signed(v[i])+" "+m_currency;
         l3=StringFormat("Op. #%d  %s  %s  %s",i,r.symbol,(r.type==0 ? "Compra" : "Venta"),PControl_Signed(r.net));
         c3=PControl_PnLColor(r.net);
        }
      int tw=MathMax(m_r.TextWidth(l1,FS(10),true),MathMax(m_r.TextWidth(l2,FS(10)),m_r.TextWidth(l3,FS(10))))+S(16);
      int th=S(50);
      int tx=xx+S(12);
      if(tx+tw>px+pw) tx=xx-S(12)-tw;
      int ty=yy-th/2;
      if(ty<py) ty=py;
      if(ty+th>py+ph) ty=py+ph-th;
      m_r.Box(tx,ty,tw,th,PControl_CLR_PANEL3,PControl_CLR_BORDER2);
      m_r.Text(tx+S(8),ty+S(5),l1,PControl_CLR_TEXT,FS(10),TA_LEFT|TA_TOP,true);
      m_r.Text(tx+S(8),ty+S(19),l2,PControl_PnLColor(v[i]),FS(10),TA_LEFT|TA_TOP,false);
      m_r.Text(tx+S(8),ty+S(33),l3,c3,FS(10),TA_LEFT|TA_TOP,false);
     }
  }

#undef PControl_YOF

//+------------------------------------------------------------------+
//| SECCIÓN 6: VISTA "TRANSACCIONES" (tabla paginada)                 |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void PControl_Panel::DrawTransactionsView(const PControl_Rect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PControl_CLR_PANEL,PControl_CLR_BORDER);
   m_r.Text(rc.x+S(10),rc.y+S(8),"Historial de Transacciones",PControl_CLR_TEXT,FS(13),TA_LEFT|TA_TOP,true);

   int n=ArraySize(m_recs);
   int rowh=S(18);
   int table_y=rc.y+S(32);
   int footer_h=S(26);
   int table_h=rc.h-S(32)-footer_h-S(6);
   int rows=MathMax(1,(table_h-rowh)/rowh);
   m_tx_pages=MathMax(1,(n+rows-1)/rows);
   if(m_tx_page>m_tx_pages-1) m_tx_page=m_tx_pages-1;
   if(m_tx_page<0) m_tx_page=0;

   //--- paginación
   int nav=S(18);
   int nx=rc.x+rc.w-S(10)-nav;
   Button(nx,rc.y+S(7),nav,nav,">",false,PControl_ACT_TX_NEXT,0,0,10);
   string pg=StringFormat("%d / %d",m_tx_page+1,m_tx_pages);
   int pw=m_r.TextWidth(pg,FS(10))+S(12);
   nx-=pw;
   m_r.Text(nx+pw/2,rc.y+S(7)+nav/2,pg,PControl_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,false);
   nx-=nav;
   Button(nx,rc.y+S(7),nav,nav,"<",false,PControl_ACT_TX_PREV,0,0,10);

   if(n==0)
     {
      DrawEmpty(rc,"Sin operaciones cerradas en el rango seleccionado");
      return;
     }

   //--- columnas
   string names[8]={"Símbolo","Tipo","Mágico","Volumen","Apertura","Cierre","Duración","Beneficio Neto"};
   double frac[8]={0.13,0.08,0.09,0.08,0.18,0.18,0.10,0.16};
   int tx=rc.x+S(10), tw=rc.w-S(20);
   int colx[9];
   colx[0]=tx;
   for(int c=0; c<8; c++) colx[c+1]=colx[c]+(int)MathRound(tw*frac[c]);
   colx[8]=tx+tw;

   //--- cabecera
   m_r.Fill(tx,table_y,tw,rowh,PControl_CLR_PANEL3);
   for(int c=0; c<8; c++)
      m_r.Text((colx[c]+colx[c+1])/2,table_y+rowh/2,names[c],PControl_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,true);

   //--- filas (más recientes primero)
   int start=m_tx_page*rows;
   for(int k=0; k<rows; k++)
     {
      int idx=n-1-(start+k);
      if(idx<0) break;
      int ry=table_y+rowh*(k+1);
      if((k%2)==1) m_r.Fill(tx,ry,tw,rowh,PControl_Mix(PControl_CLR_PANEL,PControl_CLR_PANEL2,0.6));
      PControl_PosRecord r=m_recs[idx];
      int cy=ry+rowh/2;
      color tc=(r.type==0 ? PControl_CLR_GREEN : PControl_CLR_RED);
      m_r.Text((colx[0]+colx[1])/2,cy,m_r.Ellipsis(r.symbol,colx[1]-colx[0]-S(6),FS(10)),PControl_CLR_TEXT,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[1]+colx[2])/2,cy,(r.type==0 ? "Compra" : "Venta"),tc,FS(10),TA_CENTER|TA_VCENTER,true);
      m_r.Text((colx[2]+colx[3])/2,cy,IntegerToString(r.magic),PControl_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[3]+colx[4])/2,cy,DoubleToString(r.vol_in,2),PControl_CLR_TEXT,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[4]+colx[5])/2,cy,PControl_DateTimeStr(r.open_time),PControl_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[5]+colx[6])/2,cy,PControl_DateTimeStr(r.close_time),PControl_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[6]+colx[7])/2,cy,PControl_Duration((long)r.close_time-(long)r.open_time),PControl_CLR_TEXT_MUTED,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[7]+colx[8])/2,cy,PControl_Signed(r.net)+" "+m_currency,PControl_PnLColor(r.net),FS(10),TA_CENTER|TA_VCENTER,true);
     }
   m_r.Frame(tx,table_y,tw,rowh*(rows+1),PControl_CLR_BORDER);

   //--- pie con totales
   int fy=rc.y+rc.h-footer_h-S(4);
   m_r.HLine(tx,tx+tw-1,fy,PControl_CLR_BORDER2);
   string foot=StringFormat("%d operaciones  ·  Volumen: %s lotes  ·  Neto: ",n,DoubleToString(m_stats.volume,2));
   int fw=m_r.TextWidth(foot,FS(10));
   m_r.Text(tx,fy+footer_h/2,foot,PControl_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_VCENTER,false);
   m_r.Text(tx+fw,fy+footer_h/2,PControl_Signed(m_stats.net)+" "+m_currency,PControl_PnLColor(m_stats.net),FS(10),TA_LEFT|TA_VCENTER,true);
   string right=StringFormat("Mostrando %d - %d",start+1,MathMin(n,start+rows));
   m_r.Text(tx+tw,fy+footer_h/2,right,PControl_CLR_TEXT_MUTED,FS(10),TA_RIGHT|TA_VCENTER,false);
  }

//+------------------------------------------------------------------+
//| SECCIÓN 7: VISTA "CALENDARIO" mensual                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void PControl_Panel::DrawCalendarView(const PControl_Rect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PControl_CLR_PANEL,PControl_CLR_BORDER);

   //--- el calendario navega por meses, por lo que ignora el rango
   //    temporal de la cabecera (mantiene símbolo / mágico / tipo)
   PControl_PosRecord recs[];
   m_data.CollectNoTime(recs);
   PControl_DayStat days[];
   m_data.BuildDaily(recs,days);

   datetime month_start=PControl_MakeDate(m_cal_year,m_cal_month,1);
   int dim=PControl_DaysInMonth(m_cal_year,m_cal_month);
   datetime month_end=(datetime)((long)month_start+(long)dim*86400-1);

   int    mt=0, mw=0, ml=0;
   double mnet=0.0;
   for(int i=0; i<ArraySize(days); i++)
     {
      if(days[i].day<month_start || days[i].day>month_end) continue;
      mt+=days[i].trades; mw+=days[i].wins; ml+=days[i].losses; mnet+=days[i].net;
     }
   double bal_month=m_data.BalanceAt((datetime)((long)month_start-1));
   double mpct=(bal_month>0 ? mnet/bal_month*100.0 : 0.0);

   //--- cabecera: navegación + resumen mensual
   int hy=rc.y+S(8), nav=S(18);
   Button(rc.x+S(10),hy,nav,nav,"<",false,PControl_ACT_CAL_PREV,0,0,10);
   string title=PControl_MONTHS[m_cal_month-1]+" "+IntegerToString(m_cal_year);
   int tw=MathMax(S(110),m_r.TextWidth(title,FS(12),true));
   int tx=rc.x+S(10)+nav+S(8);
   m_r.Text(tx+tw/2,hy+nav/2,title,PControl_CLR_BLUE_LIGHT,FS(12),TA_CENTER|TA_VCENTER,true);
   Button(tx+tw+S(8),hy,nav,nav,">",false,PControl_ACT_CAL_NEXT,0,0,10);

   int sx=tx+tw+S(8)+nav+S(14);
   int sw=rc.x+rc.w-S(10)-sx;
   int sh=S(28);
   int sy=hy-S(5);
   color sbg=(mnet>=0 ? PControl_CLR_SUMMARY_G : PControl_CLR_SUMMARY_R);
   m_r.Box(sx,sy,sw,sh,sbg,PControl_Mix(sbg,PControl_CLR_WHITE,0.35));
   string labels[5]={"Operaciones","Ganadas","Perdidas","Beneficio","Porcentaje"};
   string vals[5];
   vals[0]=IntegerToString(mt);
   vals[1]=IntegerToString(mw);
   vals[2]=IntegerToString(ml);
   vals[3]=PControl_Signed(mnet);
   vals[4]=PControl_SignedPct(mpct);
   int cw5=sw/5;
   for(int i=0; i<5; i++)
     {
      int cx=sx+cw5*i+cw5/2;
      m_r.Text(cx,sy+S(3),labels[i],PControl_Mix(PControl_CLR_WHITE,sbg,0.25),FS(8),TA_CENTER|TA_TOP,false);
      m_r.Text(cx,sy+S(13),vals[i],PControl_CLR_WHITE,FS(10),TA_CENTER|TA_TOP,true);
     }

   //--- cuadrícula
   int gx=rc.x+S(10);
   int gy=sy+sh+S(8);
   int gw=rc.w-S(20);
   int gh=rc.y+rc.h-S(10)-gy;
   int tot_w=MathMax(S(60),(int)(gw*0.085));
   int day_w=(gw-tot_w-S(6))/7;
   int hdr_h=S(16);
   int totals_x=gx+7*day_w+S(6);
   tot_w=gx+gw-totals_x;

   for(int d=0; d<7; d++)
     {
      m_r.Fill(gx+d*day_w,gy,day_w-2,hdr_h,PControl_CLR_PANEL3);
      m_r.Text(gx+d*day_w+(day_w-2)/2,gy+hdr_h/2,PControl_DAYS_SHORT[d],PControl_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,true);
     }
   m_r.Fill(totals_x,gy,tot_w,hdr_h,PControl_CLR_PANEL3);
   m_r.Text(totals_x+tot_w/2,gy+hdr_h/2,"Totales",PControl_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,true);

   int first_dow=PControl_WeekDay(month_start);
   int rows=(first_dow+dim+6)/7;
   int cell_h=(gh-hdr_h-S(2))/rows;
   if(cell_h<S(26)) cell_h=S(26);
   bool compact=(cell_h<S(48) || day_w<S(70));
   int ch=cell_h-2, cwid=day_w-2;
   datetime today=PControl_DayStart(TimeCurrent());

   for(int row=0; row<rows; row++)
     {
      int cy=gy+hdr_h+S(2)+row*cell_h;
      double wnet=0.0;
      int wtrades=0;
      datetime week_start=(datetime)((long)month_start+(long)(row*7-first_dow)*86400);

      for(int col=0; col<7; col++)
        {
         int idx=row*7+col;
         int day=idx-first_dow+1;
         int cx=gx+col*day_w;
         datetime d=(datetime)((long)month_start+(long)(day-1)*86400);
         bool in_month=(day>=1 && day<=dim);
         int di=PControl_TradeData::FindDay(days,d);

         if(!in_month)
           {
            m_r.Box(cx,cy,cwid,ch,PControl_Mix(PControl_CLR_PANEL,PControl_CLR_BG,0.6),(di>=0 ? PControl_PnLColor(days[di].net) : PControl_CLR_BORDER));
            MqlDateTime odt; TimeToStruct(d,odt);
            m_r.Text(cx+cwid/2,cy+S(3),IntegerToString(odt.day),PControl_CLR_TEXT_MUTED,FS(8),TA_CENTER|TA_TOP,false);
            if(di>=0)
               m_r.Text(cx+cwid/2,cy+ch/2,PControl_Signed(days[di].net),PControl_PnLColor(days[di].net),FS(9),TA_CENTER|TA_VCENTER,true);
            continue;
           }

         if(di<0)
           {
            m_r.Box(cx,cy,cwid,ch,PControl_CLR_PANEL2,(d==today ? PControl_CLR_BLUE_LIGHT : PControl_CLR_BORDER));
            m_r.Text(cx+S(3),cy+S(2),IntegerToString(day),PControl_CLR_TEXT_MUTED,FS(8),TA_LEFT|TA_TOP,false);
            continue;
           }

         PControl_DayStat ds=days[di];
         color c=PControl_PnLColor(ds.net);
         m_r.Box(cx,cy,cwid,ch,PControl_Mix(c,PControl_CLR_PANEL,0.9),c);
         if(d==today) m_r.Frame(cx+1,cy+1,cwid-2,ch-2,PControl_CLR_BLUE_LIGHT);
         m_r.Text(cx+S(3),cy+S(2),IntegerToString(day),PControl_CLR_TEXT_MUTED,FS(8),TA_LEFT|TA_TOP,false);

         double pct=(ds.bal_start>0 ? ds.net/ds.bal_start*100.0 : 0.0);
         double ddp=(ds.bal_start>0 ? ds.max_dd/ds.bal_start*100.0 : 0.0);
         if(compact)
           {
            m_r.Text(cx+cwid/2,cy+ch/2-S(2),PControl_Signed(ds.net),c,FS(10),TA_CENTER|TA_VCENTER,true);
            m_r.Text(cx+cwid/2,cy+ch-S(3),StringFormat("%dT %dG %dP",ds.trades,ds.wins,ds.losses),PControl_CLR_TEXT_MUTED,FS(8),TA_CENTER|TA_BOTTOM,false);
           }
         else
           {
            m_r.Text(cx+S(4),cy+S(13),PControl_Signed(ds.net),c,FS(11),TA_LEFT|TA_TOP,true);
            m_r.Text(cx+S(4),cy+S(27),PControl_SignedPct(pct),c,FS(9),TA_LEFT|TA_TOP,false);
            if(ds.max_dd>0.0)
               m_r.Text(cx+cwid-S(4),cy+S(14),"-"+PControl_Pct(ddp,1)+" DD",PControl_CLR_RED,FS(9),TA_RIGHT|TA_TOP,false);

            //--- línea inferior: 1T 1G 0P WR:100%
            double wr=(ds.trades>0 ? 100.0*ds.wins/ds.trades : 0.0);
            string seg[4];
            color  segc[4];
            seg[0]=IntegerToString(ds.trades)+"T ";  segc[0]=PControl_CLR_TEXT_DIM;
            seg[1]=IntegerToString(ds.wins)+"G ";    segc[1]=PControl_CLR_GREEN;
            seg[2]=IntegerToString(ds.losses)+"P ";  segc[2]=PControl_CLR_RED;
            seg[3]="WR:"+DoubleToString(wr,0)+"%";   segc[3]=PControl_CLR_TEXT_DIM;
            int total_w=0;
            for(int s=0; s<4; s++) total_w+=m_r.TextWidth(seg[s],FS(8));
            int sxx=cx+(cwid-total_w)/2;
            if(sxx<cx+S(2)) sxx=cx+S(2);
            for(int s=0; s<4; s++)
              {
               m_r.Text(sxx,cy+ch-S(3),seg[s],segc[s],FS(8),TA_LEFT|TA_BOTTOM,false);
               sxx+=m_r.TextWidth(seg[s],FS(8));
              }
           }
         Hit(cx,cy,cwid,ch,PControl_ACT_CAL_DAY,(long)d);
         wnet+=ds.net;
         wtrades+=ds.trades;
        }

      //--- total semanal
      if(wtrades>0)
        {
         color wc=PControl_PnLColor(wnet);
         double wbal=m_data.BalanceAt((datetime)((long)MathMax((long)week_start,(long)month_start)-1));
         double wpct=(wbal>0 ? wnet/wbal*100.0 : 0.0);
         m_r.Box(totals_x,cy,tot_w,ch,PControl_Mix(wc,PControl_CLR_PANEL,0.9),wc);
         m_r.Text(totals_x+tot_w/2,cy+ch/2-S(7),PControl_Signed(wnet),wc,FS(11),TA_CENTER|TA_VCENTER,true);
         m_r.Text(totals_x+tot_w/2,cy+ch/2+S(8),PControl_Pct(wpct),wc,FS(9),TA_CENTER|TA_VCENTER,false);
        }
      else
         m_r.Box(totals_x,cy,tot_w,ch,PControl_CLR_PANEL2,PControl_CLR_BORDER);
     }
  }

//+------------------------------------------------------------------+
//| Popup con las operaciones de un día                                |
//+------------------------------------------------------------------+
void PControl_Panel::DrawCalDayPopup()
  {
   datetime day=(datetime)m_popup_p1;
   PControl_PosRecord recs[];
   m_data.CollectInRange(day,(datetime)((long)day+86399),recs);
   int n=ArraySize(recs);

   int    wins=0, losses=0;
   double net=0.0;
   for(int i=0; i<n; i++)
     {
      net+=recs[i].net;
      if(recs[i].net>0) wins++; else if(recs[i].net<0) losses++;
     }
   double bal=m_data.BalanceAt((datetime)((long)day-1));
   double pct=(bal>0 ? net/bal*100.0 : 0.0);

   int max_rows=MathMin(n,12);
   int rowh=S(16);
   int w=MathMin(S(460),m_rc_content.w-S(20));
   int h=S(96)+(max_rows>0 ? S(22)+max_rows*rowh : 0)+(n>max_rows ? S(14) : 0);
   int x=m_rc_content.x+(m_rc_content.w-w)/2;
   int y=m_rc_content.y+MathMax(S(6),(m_rc_content.h-h)/2);

   MqlDateTime dt; TimeToStruct(day,dt);
   string title=PControl_DAYS_LONG[PControl_WeekDay(day)]+" "+StringFormat("%02d.%02d.%d",dt.day,dt.mon,dt.year);
   PopupFrame(x,y,w,h,title);

   int ty=y+S(32);
   int lx=x+S(12);
   m_r.Text(lx,ty,StringFormat("Operaciones: %d   Ganadas: %d   Perdidas: %d",n,wins,losses),PControl_CLR_TEXT,FS(10),TA_LEFT|TA_TOP,false);
   ty+=S(16);
   string s1="Beneficio neto: ";
   m_r.Text(lx,ty,s1,PControl_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   m_r.Text(lx+m_r.TextWidth(s1,FS(10)),ty,PControl_Signed(net)+" "+m_currency+"  ("+PControl_SignedPct(pct)+")",PControl_PnLColor(net),FS(10),TA_LEFT|TA_TOP,true);
   ty+=S(16);
   m_r.Text(lx,ty,StringFormat("Balance al inicio del día: %s %s",PControl_Money(bal),m_currency),PControl_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,false);
   ty+=S(18);

   if(max_rows>0)
     {
      m_r.HLine(lx,x+w-S(12),ty,PControl_CLR_BORDER2);
      ty+=S(6);
      int c0=lx, c1=lx+S(64), c2=lx+S(150), c3=lx+S(210), c4=x+w-S(12);
      m_r.Text(c0,ty,"Cierre",PControl_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c1,ty,"Símbolo",PControl_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c2,ty,"Tipo",PControl_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c3,ty,"Volumen",PControl_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c4,ty,"Neto",PControl_CLR_TEXT_MUTED,FS(9),TA_RIGHT|TA_TOP,true);
      ty+=S(14);
      for(int i=0; i<max_rows; i++)
        {
         PControl_PosRecord r=recs[i];
         m_r.Text(c0,ty,TimeToString(r.close_time,TIME_SECONDS),PControl_CLR_TEXT_DIM,FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c1,ty,m_r.Ellipsis(r.symbol,c2-c1-S(6),FS(9)),PControl_CLR_TEXT,FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c2,ty,(r.type==0 ? "Compra" : "Venta"),(r.type==0 ? PControl_CLR_GREEN : PControl_CLR_RED),FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c3,ty,DoubleToString(r.vol_in,2),PControl_CLR_TEXT_DIM,FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c4,ty,PControl_Signed(r.net),PControl_PnLColor(r.net),FS(9),TA_RIGHT|TA_TOP,true);
         ty+=rowh;
        }
      if(n>max_rows)
         m_r.Text(lx,ty,StringFormat("... y %d operación(es) más",n-max_rows),PControl_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,false);
     }
  }

//+------------------------------------------------------------------+
//| SECCIÓN 8: VISTA "POR HORA" (mapa de calor 7x24)                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Formato compacto para las celdas (+6, -8, +0.45)                   |
//+------------------------------------------------------------------+
string PControl_CellValue(const double v)
  {
   if(MathAbs(v)<1.0) return(PControl_Signed(v,2));
   return(PControl_Signed(v,0));
  }

//+------------------------------------------------------------------+
void PControl_Panel::DrawHourlyView(const PControl_Rect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PControl_CLR_PANEL,PControl_CLR_BORDER);
   string title="Rendimiento por Horas";
   m_r.Text(rc.x+S(10),rc.y+S(8),title,PControl_CLR_BLUE_LIGHT,FS(13),TA_LEFT|TA_TOP,true);
   int tw=m_r.TextWidth(title,FS(13),true);
   int ix=rc.x+S(10)+tw+S(16), iy=rc.y+S(16);
   m_r.Circle(ix,iy,S(7),PControl_CLR_BLUE);
   m_r.Text(ix,iy,"i",PControl_CLR_WHITE,FS(9),TA_CENTER|TA_VCENTER,true);
   Hit(ix-S(8),iy-S(8),S(16),S(16),PControl_ACT_INFO,0);

   //--- botones de la derecha
   int bh=S(18), by=rc.y+S(7);
   int x=rc.x+rc.w-S(10);
   string tl=(m_hour_by_close ? "Hora CIERRE" : "Hora APERTURA");
   int w=m_r.TextWidth(tl,FS(10),true)+S(16);
   x-=w;
   Button(x,by,w,bh,tl,true,PControl_ACT_HOUR_TIME,0,0,10);
   x-=S(12);
   string modes[3]={"Compra/Venta","Compra","Venta"};
   for(int i=2; i>=0; i--)
     {
      int mw=MathMax(S(46),m_r.TextWidth(modes[i],FS(10),true)+S(14));
      x-=mw;
      Button(x,by,mw,bh,modes[i],(m_hour_mode==i),PControl_ACT_HOUR_MODE,i,0,10);
      x-=S(4);
     }

   //--- agregación 7 x 24
   double net[168];
   int    cnt[168];
   ArrayInitialize(net,0.0);
   ArrayInitialize(cnt,0);
   double rnet[7]; int rcnt[7];
   double cnet[24]; int ccnt[24];
   ArrayInitialize(rnet,0.0); ArrayInitialize(rcnt,0);
   ArrayInitialize(cnet,0.0); ArrayInitialize(ccnt,0);
   double gnet=0.0; int gcnt=0;

   for(int i=0; i<ArraySize(m_recs); i++)
     {
      if(m_hour_mode==PControl_HOUR_BUY && m_recs[i].type!=0) continue;
      if(m_hour_mode==PControl_HOUR_SELL && m_recs[i].type!=1) continue;
      datetime t=(m_hour_by_close ? m_recs[i].close_time : m_recs[i].open_time);
      MqlDateTime dt; TimeToStruct(t,dt);
      int d=(dt.day_of_week+6)%7;
      int h=dt.hour;
      int k=d*24+h;
      net[k]+=m_recs[i].net; cnt[k]++;
      rnet[d]+=m_recs[i].net; rcnt[d]++;
      cnet[h]+=m_recs[i].net; ccnt[h]++;
      gnet+=m_recs[i].net; gcnt++;
     }

   //--- geometría de la cuadrícula
   int gx=rc.x+S(10), gy=rc.y+S(34);
   int gw=rc.w-S(20), gh=rc.h-S(44);
   int label_w=S(40), tot_w=MathMax(S(60),(int)(gw*0.075)), hdr_h=S(16);
   int cell_w=(gw-label_w-tot_w-S(8))/24;
   int cell_h=(gh-hdr_h-S(6))/8;
   if(cell_h>cell_w*5/4) cell_h=cell_w*5/4;
   if(cell_w<S(14) || cell_h<S(14))
     {
      DrawEmpty(rc,"El panel es demasiado pequeño para el mapa de calor");
      return;
     }
   int totals_x=gx+label_w+24*cell_w+S(8);
   tot_w=gx+gw-totals_x;
   bool small_font=(cell_w<S(34));

   for(int h=0; h<24; h++)
      m_r.Text(gx+label_w+h*cell_w+cell_w/2,gy+hdr_h/2,StringFormat("%02d",h),PControl_CLR_TEXT_MUTED,FS(9),TA_CENTER|TA_VCENTER,false);
   m_r.Text(totals_x+tot_w/2,gy+hdr_h/2,"TOTAL",PControl_CLR_TEXT_DIM,FS(9),TA_CENTER|TA_VCENTER,true);

   color empty_bg=PControl_Mix(PControl_CLR_PANEL,PControl_CLR_BG,0.4);
   int inner_w=cell_w-2, inner_h=cell_h-2;

   for(int d=0; d<7; d++)
     {
      int ry=gy+hdr_h+S(2)+d*cell_h;
      m_r.Text(gx,ry+cell_h/2,PControl_DAYS_SHORT[d],PControl_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_VCENTER,false);
      for(int h=0; h<24; h++)
        {
         int k=d*24+h;
         int cx=gx+label_w+h*cell_w+1, cy=ry+1;
         if(cnt[k]==0)
           {
            m_r.Box(cx,cy,inner_w,inner_h,empty_bg,PControl_CLR_GRID);
            continue;
           }
         color c=PControl_PnLColor(net[k]);
         m_r.Box(cx,cy,inner_w,inner_h,PControl_Mix(c,PControl_CLR_PANEL,0.86),c);
         m_r.Text(cx+inner_w/2,cy+inner_h/2-S(5),PControl_CellValue(net[k]),c,FS(small_font ? 9 : 10),TA_CENTER|TA_VCENTER,true);
         m_r.Text(cx+inner_w/2,cy+inner_h-S(3),IntegerToString(cnt[k])+"T",PControl_CLR_TEXT_MUTED,FS(8),TA_CENTER|TA_BOTTOM,false);
         Hit(cx,cy,inner_w,inner_h,PControl_ACT_HOUR_CELL,d,h);
        }
      //--- total del día
      if(rcnt[d]>0)
        {
         color rcol=PControl_PnLColor(rnet[d]);
         m_r.Box(totals_x,ry+1,tot_w,inner_h,PControl_Mix(rcol,PControl_CLR_PANEL,0.86),rcol);
         m_r.Text(totals_x+tot_w/2,ry+1+inner_h/2,PControl_Signed(rnet[d]),rcol,FS(10),TA_CENTER|TA_VCENTER,true);
        }
      else
         m_r.Box(totals_x,ry+1,tot_w,inner_h,empty_bg,PControl_CLR_GRID);
     }

   //--- fila TOTAL
   int ty=gy+hdr_h+S(2)+7*cell_h;
   m_r.Text(gx,ty+cell_h/2,"TOTAL",PControl_CLR_TEXT_DIM,FS(9),TA_LEFT|TA_VCENTER,true);
   for(int h=0; h<24; h++)
     {
      int cx=gx+label_w+h*cell_w+1, cy=ty+1;
      if(ccnt[h]==0)
        {
         m_r.Box(cx,cy,inner_w,inner_h,empty_bg,PControl_CLR_GRID);
         continue;
        }
      color c=PControl_PnLColor(cnet[h]);
      m_r.Box(cx,cy,inner_w,inner_h,PControl_Mix(c,PControl_CLR_PANEL,0.86),c);
      string txt=(small_font ? PControl_CellValue(cnet[h]) : PControl_Signed(cnet[h]));
      m_r.Text(cx+inner_w/2,cy+inner_h/2,txt,c,FS(small_font ? 8 : 9),TA_CENTER|TA_VCENTER,true);
     }
   color gcol=PControl_PnLColor(gnet);
   if(gcnt>0)
     {
      m_r.Box(totals_x,ty+1,tot_w,inner_h,PControl_Mix(gcol,PControl_CLR_PANEL,0.8),gcol);
      m_r.Text(totals_x+tot_w/2,ty+1+inner_h/2,PControl_Signed(gnet),gcol,FS(11),TA_CENTER|TA_VCENTER,true);
     }
   else
      m_r.Box(totals_x,ty+1,tot_w,inner_h,empty_bg,PControl_CLR_GRID);
  }

//+------------------------------------------------------------------+
//| Popup de detalle de una celda                                      |
//+------------------------------------------------------------------+
void PControl_Panel::DrawHourCellPopup()
  {
   int d=(int)m_popup_p1, h=(int)m_popup_p2;
   int    nb=0, ns=0, bw=0, bl=0, sw=0, sl=0;
   double bnet=0.0, snet=0.0;
   int    list[];
   ArrayResize(list,0);

   for(int i=0; i<ArraySize(m_recs); i++)
     {
      if(m_hour_mode==PControl_HOUR_BUY && m_recs[i].type!=0) continue;
      if(m_hour_mode==PControl_HOUR_SELL && m_recs[i].type!=1) continue;
      datetime t=(m_hour_by_close ? m_recs[i].close_time : m_recs[i].open_time);
      MqlDateTime dt; TimeToStruct(t,dt);
      if((dt.day_of_week+6)%7!=d || dt.hour!=h) continue;
      double v=m_recs[i].net;
      if(m_recs[i].type==0) { nb++; bnet+=v; if(v>0) bw++; else if(v<0) bl++; }
      else                  { ns++; snet+=v; if(v>0) sw++; else if(v<0) sl++; }
      int n=ArraySize(list);
      ArrayResize(list,n+1);
      list[n]=i;
     }
   int total=nb+ns;
   int max_rows=MathMin(ArraySize(list),8);
   int rowh=S(15);

   int w=MathMin(S(400),m_rc_content.w-S(20));
   int hgt=S(150)+(max_rows>0 ? S(22)+max_rows*rowh : 0)+(ArraySize(list)>max_rows ? S(14) : 0);
   int x=m_rc_content.x+(m_rc_content.w-w)/2;
   int y=m_rc_content.y+MathMax(S(6),(m_rc_content.h-hgt)/2);

   string title=StringFormat("%s %02d:00 - %02d:59  (%s)",PControl_DAYS_LONG[d],h,h,(m_hour_by_close ? "hora de cierre" : "hora de apertura"));
   PopupFrame(x,y,w,hgt,title);

   int lx=x+S(12), ty=y+S(32), lh=S(17);
   m_r.Text(lx,ty,"Total de operaciones: "+IntegerToString(total),PControl_CLR_TEXT,FS(11),TA_LEFT|TA_TOP,true);
   ty+=lh+S(2);

   double bwr=(nb>0 ? 100.0*bw/nb : 0.0), swr=(ns>0 ? 100.0*sw/ns : 0.0);
   string sb="Compras: ";
   m_r.Text(lx,ty,sb,PControl_CLR_GREEN,FS(10),TA_LEFT|TA_TOP,true);
   m_r.Text(lx+m_r.TextWidth(sb,FS(10),true),ty,StringFormat("%d  (G: %d / P: %d, WR %s)",nb,bw,bl,PControl_Pct(bwr,1)),PControl_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   ty+=lh;
   string ss="Ventas: ";
   m_r.Text(lx,ty,ss,PControl_CLR_RED,FS(10),TA_LEFT|TA_TOP,true);
   m_r.Text(lx+m_r.TextWidth(ss,FS(10),true),ty,StringFormat("%d  (G: %d / P: %d, WR %s)",ns,sw,sl,PControl_Pct(swr,1)),PControl_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   ty+=lh;

   string p1="P&L Compras: ";
   m_r.Text(lx,ty,p1,PControl_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   m_r.Text(lx+m_r.TextWidth(p1,FS(10)),ty,PControl_Signed(bnet)+" "+m_currency,PControl_PnLColor(bnet),FS(10),TA_LEFT|TA_TOP,true);
   int half=lx+w/2;
   string p2="P&L Ventas: ";
   m_r.Text(half,ty,p2,PControl_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   m_r.Text(half+m_r.TextWidth(p2,FS(10)),ty,PControl_Signed(snet)+" "+m_currency,PControl_PnLColor(snet),FS(10),TA_LEFT|TA_TOP,true);
   ty+=lh;
   string p3="P&L Total: ";
   m_r.Text(lx,ty,p3,PControl_CLR_TEXT,FS(11),TA_LEFT|TA_TOP,true);
   m_r.Text(lx+m_r.TextWidth(p3,FS(11),true),ty,PControl_Signed(bnet+snet)+" "+m_currency,PControl_PnLColor(bnet+snet),FS(11),TA_LEFT|TA_TOP,true);
   ty+=lh+S(2);

   if(max_rows>0)
     {
      m_r.HLine(lx,x+w-S(12),ty,PControl_CLR_BORDER2);
      ty+=S(6);
      int c0=lx, c1=lx+S(120), c2=lx+S(200), c3=x+w-S(12);
      m_r.Text(c0,ty,(m_hour_by_close ? "Cierre" : "Apertura"),PControl_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c1,ty,"Símbolo",PControl_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c2,ty,"Tipo",PControl_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c3,ty,"Neto",PControl_CLR_TEXT_MUTED,FS(9),TA_RIGHT|TA_TOP,true);
      ty+=S(14);
      for(int k=0; k<max_rows; k++)
        {
         PControl_PosRecord r=m_recs[list[k]];
         datetime t=(m_hour_by_close ? r.close_time : r.open_time);
         m_r.Text(c0,ty,PControl_DateTimeStr(t),PControl_CLR_TEXT_DIM,FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c1,ty,m_r.Ellipsis(r.symbol,c2-c1-S(6),FS(9)),PControl_CLR_TEXT,FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c2,ty,(r.type==0 ? "Compra" : "Venta"),(r.type==0 ? PControl_CLR_GREEN : PControl_CLR_RED),FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c3,ty,PControl_Signed(r.net),PControl_PnLColor(r.net),FS(9),TA_RIGHT|TA_TOP,true);
         ty+=rowh;
        }
      if(ArraySize(list)>max_rows)
         m_r.Text(lx,ty,StringFormat("... y %d operación(es) más",ArraySize(list)-max_rows),PControl_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,false);
     }
  }

//+------------------------------------------------------------------+
//| SECCIÓN 9: VISTA "ESTADÍSTICAS ARENA"                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void PControl_Panel::DrawArenaView(const PControl_Rect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PControl_CLR_PANEL,PControl_CLR_BORDER);
   string title="Estadísticas Arena";
   m_r.Text(rc.x+S(10),rc.y+S(8),title,PControl_CLR_BLUE_LIGHT,FS(13),TA_LEFT|TA_TOP,true);
   int tw=m_r.TextWidth(title,FS(13),true);
   int ix=rc.x+S(10)+tw+S(16), iy=rc.y+S(16);
   m_r.Circle(ix,iy,S(7),PControl_CLR_BLUE);
   m_r.Text(ix,iy,"i",PControl_CLR_WHITE,FS(9),TA_CENTER|TA_VCENTER,true);
   Hit(ix-S(8),iy-S(8),S(16),S(16),PControl_ACT_INFO,1);

   int bh=S(18), by=rc.y+S(7), bw=S(72);
   int x=rc.x+rc.w-S(10)-bw;
   Button(x,by,bw,bh,"Avanzado",m_arena_advanced,PControl_ACT_ARENA_VIEW,1,0,10);
   x-=bw+S(4);
   Button(x,by,bw,bh,"Resumen",!m_arena_advanced,PControl_ACT_ARENA_VIEW,0,0,10);

   PControl_Rect body;
   body.x=rc.x+S(10); body.y=rc.y+S(34); body.w=rc.w-S(20); body.h=rc.h-S(44);
   if(ArraySize(m_recs)==0)
     {
      DrawEmpty(rc,"Sin operaciones cerradas en el rango seleccionado");
      return;
     }
   if(m_arena_advanced) DrawArenaAdvanced(body);
   else                 DrawArenaOverview(body);
  }

//+------------------------------------------------------------------+
void PControl_Panel::DrawArenaOverview(const PControl_Rect &rc)
  {
   int gap=S(8);
   int cw=(rc.w-2*gap)/3;
   int row1_h=MathMax(S(74),(int)(rc.h*0.17));
   int row2_h=MathMax(S(96),(int)(rc.h*0.24));
   int row3_h=MathMax(S(74),(int)(rc.h*0.19));
   int row4_h=rc.h-row1_h-row2_h-row3_h-3*gap;
   if(row4_h<S(56)) row4_h=S(56);

   //--- valoraciones
   double sharpe=m_stats.sharpe;
   string s_rating=(sharpe<0.5 ? "Bajo" : (sharpe<1.0 ? "Aceptable" : (sharpe<2.0 ? "Bueno" : "Excelente")));
   color  s_clr=(sharpe<1.0 ? PControl_CLR_RED : (sharpe<2.0 ? PControl_CLR_ORANGE : PControl_CLR_GREEN));

   double pf=m_stats.profit_factor;
   string p_rating=(pf<1.0 ? "Pobre" : (pf<1.5 ? "Aceptable" : (pf<2.0 ? "Bueno" : "Excelente")));
   color  p_clr=(pf<1.0 ? PControl_CLR_RED : (pf<1.5 ? PControl_CLR_ORANGE : PControl_CLR_GREEN));

   double dd=m_stats.max_dd_pct;
   string d_rating=(dd<5.0 ? "Excelente" : (dd<10.0 ? "Aceptable" : (dd<15.0 ? "Alto" : "Crítico")));
   color  d_clr=(dd<5.0 ? PControl_CLR_GREEN : (dd<10.0 ? PControl_CLR_ORANGE : PControl_CLR_RED));

   //--- fila 1: barras
   int y=rc.y;
   double sb[2]={1.0,2.0};
   color  sc[3]={PControl_CLR_RED,PControl_CLR_YELLOW,PControl_CLR_GREEN};
   string st[4]={"0","1","2","3"};
   ArenaBarCard(rc.x,y,cw,row1_h,"Ratio de Sharpe",DoubleToString(sharpe,2),s_clr,s_clr,sharpe,0.0,3.0,sb,sc,s_rating,st);

   double pb[2]={1.0,1.5};
   string pt[4]={"0","1","1.5","3"};
   ArenaBarCard(rc.x+cw+gap,y,cw,row1_h,"Factor de Beneficio",DoubleToString(pf,2),p_clr,p_clr,pf,0.0,3.0,pb,sc,p_rating,pt);

   double db[2]={5.0,10.0};
   color  dc[3]={PControl_CLR_GREEN,PControl_CLR_YELLOW,PControl_CLR_RED};
   string dt[4]={"0%","5%","10%","15%"};
   ArenaBarCard(rc.x+2*(cw+gap),y,rc.w-2*(cw+gap),row1_h,"Drawdown Máximo","Equity: "+PControl_Pct(dd,1),d_clr,d_clr,dd,0.0,15.0,db,dc,d_rating,dt);

   //--- fila 2: medidores
   y+=row1_h+gap;
   ArenaGaugeCard(rc.x,y,cw,row2_h,"Puntuación de Disciplina",m_stats.discipline);
   ArenaGaugeCard(rc.x+cw+gap,y,cw,row2_h,"Eficiencia de Operación",m_stats.efficiency);

   double mr=m_stats.mistake_rate;
   string m_rating=(mr<5.0 ? "Enfocado" : (mr<10.0 ? "Aceptable" : (mr<20.0 ? "Descuidado" : "Crítico")));
   color  m_clr=(mr<5.0 ? PControl_CLR_GREEN : (mr<10.0 ? PControl_CLR_ORANGE : PControl_CLR_RED));
   int mx=rc.x+2*(cw+gap), mw=rc.w-2*(cw+gap);
   m_r.Box(mx,y,mw,row2_h,PControl_CLR_PANEL2,m_clr);
   m_r.Text(mx+mw/2,y+S(8),"Tasa de Errores",PControl_CLR_TEXT_DIM,FS(11),TA_CENTER|TA_TOP,true);
   m_r.Text(mx+mw/2,y+row2_h/2,PControl_Pct(mr,1),m_clr,FS(20),TA_CENTER|TA_VCENTER,true);
   m_r.Text(mx+mw/2,y+row2_h-S(8),m_rating,PControl_CLR_TEXT_MUTED,FS(10),TA_CENTER|TA_BOTTOM,false);

   //--- fila 3: análisis textual
   y+=row2_h+gap;
   string s_lines[1], p_lines[1], d_lines[1];
   if(sharpe<0.5)      s_lines[0]="Tu Ratio de Sharpe es bajo. Estás asumiendo demasiado riesgo para el retorno obtenido. Enfócate en reducir los grandes drawdowns, el sobre-trading y las operaciones inconsistentes.";
   else if(sharpe<1.0) s_lines[0]="Ratio de Sharpe aceptable. La relación riesgo/retorno es razonable, pero hay margen para mejorar la consistencia y recortar las operaciones de baja calidad.";
   else if(sharpe<2.0) s_lines[0]="Buen Ratio de Sharpe. Obtienes retornos sólidos ajustados al riesgo. Mantén la disciplina y evita cambiar el plan.";
   else                s_lines[0]="Excelente Ratio de Sharpe. Tus retornos son muy consistentes en relación al riesgo asumido. Sigue así.";

   if(pf<1.0)          p_lines[0]="Factor de beneficio inferior a 1: pierdes más de lo que ganas. Revisa la gestión del riesgo y los criterios de entrada antes de seguir operando.";
   else if(pf<1.5)     p_lines[0]="Factor de beneficio aceptable pero ajustado. Busca mejorar la relación ganancia/pérdida cortando antes las pérdidas.";
   else                p_lines[0]="Factor de beneficio sólido. Eres consistentemente rentable. Sigue refinando tu ventaja y mantén la disciplina.";

   if(dd<5.0)          d_lines[0]="El drawdown es aceptable. Estás gestionando bien el riesgo, pero mantente alerta y evita el sobre-trading.";
   else if(dd<10.0)    d_lines[0]="Drawdown moderado. Considera reducir el tamaño de posición durante las rachas negativas para proteger el capital.";
   else                d_lines[0]="Drawdown elevado. El riesgo es excesivo: reduce la exposición y revisa tu plan de trading.";

   ArenaTextCard(rc.x,y,cw,row3_h,"Análisis del Ratio de Sharpe",s_clr,s_lines);
   ArenaTextCard(rc.x+cw+gap,y,cw,row3_h,"Análisis del Factor de Beneficio",p_clr,p_lines);
   ArenaTextCard(rc.x+2*(cw+gap),y,rc.w-2*(cw+gap),row3_h,"Análisis del Drawdown",d_clr,d_lines);

   //--- fila 4: alertas y aspectos positivos
   y+=row3_h+gap;
   int hw=(rc.w-gap)/2;
   string flags[];
   ArrayResize(flags,0);
   int nf=0;
   if(m_stats.overtrading_days>0)
     { ArrayResize(flags,nf+1); flags[nf++]=StringFormat("- Sobre-trading detectado: %d día(s) con más de %d operaciones. Reduce la frecuencia y prioriza la calidad.",m_stats.overtrading_days,m_set.max_trades_day); }
   if(m_stats.sl_violations>0)
     { ArrayResize(flags,nf+1); flags[nf++]=StringFormat("- Violación de stop-loss: %d operación(es) perdieron más de %.1fx la pérdida mediana. No muevas tu stop.",m_stats.sl_violations,m_set.sl_factor); }
   if(m_stats.revenge_trades>0)
     { ArrayResize(flags,nf+1); flags[nf++]=StringFormat("- Revenge trading: %d operación(es) abiertas menos de %d min después de una pérdida.",m_stats.revenge_trades,m_set.revenge_minutes); }
   if(m_stats.risk_shift)
     { ArrayResize(flags,nf+1); flags[nf++]="- Cambio de riesgo: las últimas pérdidas duplican a las anteriores. Posible dimensionamiento emocional."; }
   if(m_stats.win_rate<40.0)
     { ArrayResize(flags,nf+1); flags[nf++]=StringFormat("- Tasa de acierto baja (%s). Revisa los criterios de entrada.",PControl_Pct(m_stats.win_rate,1)); }
   if(m_stats.profit_factor<1.0)
     { ArrayResize(flags,nf+1); flags[nf++]="- Factor de beneficio inferior a 1: la estrategia pierde dinero en el período."; }
   if(m_stats.max_consec_losses>=5)
     { ArrayResize(flags,nf+1); flags[nf++]=StringFormat("- Racha perdedora de %d operaciones. Considera pausar tras 3 pérdidas seguidas.",m_stats.max_consec_losses); }
   if(nf==0) { ArrayResize(flags,1); flags[0]="- Sin alertas detectadas en el período."; }

   string good[];
   ArrayResize(good,0);
   int ng=0;
   if(m_stats.risk_consistent)
     { ArrayResize(good,ng+1); good[ng++]="- Dimensionamiento de riesgo consistente. Mantienes la estabilidad emocional."; }
   if(m_stats.win_rate>=55.0)
     { ArrayResize(good,ng+1); good[ng++]=StringFormat("- Buena tasa de acierto (%s). Tu ventaja se está mostrando.",PControl_Pct(m_stats.win_rate,1)); }
   if(m_stats.payoff>=1.5 && m_stats.losses>0)
     { ArrayResize(good,ng+1); good[ng++]=StringFormat("- Excelente relación ganancia/pérdida (%.2f). Dejas correr los beneficios con disciplina.",m_stats.payoff); }
   if(m_stats.profit_factor>=1.5)
     { ArrayResize(good,ng+1); good[ng++]=StringFormat("- Factor de beneficio sólido (%.2f).",m_stats.profit_factor); }
   if(m_stats.revenge_trades==0 && m_stats.trades>=5)
     { ArrayResize(good,ng+1); good[ng++]="- Sin revenge trading: respetas el tiempo de enfriamiento tras las pérdidas."; }
   if(m_stats.max_dd_pct<5.0)
     { ArrayResize(good,ng+1); good[ng++]=StringFormat("- Drawdown contenido (%s).",PControl_Pct(m_stats.max_dd_pct,1)); }
   if(ng==0) { ArrayResize(good,1); good[0]="- Sin aspectos destacables todavía. Sigue acumulando operaciones."; }

   ArenaTextCard(rc.x,y,hw,row4_h,"Alertas de Rendimiento",PControl_CLR_RED,flags);
   ArenaTextCard(rc.x+hw+gap,y,rc.w-hw-gap,row4_h,"Aspectos Positivos",PControl_CLR_GREEN,good);
  }

//+------------------------------------------------------------------+
//| Tarjeta con barra segmentada y marcador                            |
//+------------------------------------------------------------------+
void PControl_Panel::ArenaBarCard(const int x,const int y,const int w,const int h,const string title,const string value,
                          const color value_clr,const color frame,const double v,const double vmin,const double vmax,
                          const double &bounds[],const color &clrs[],const string rating,const string &ticks[])
  {
   m_r.Box(x,y,w,h,PControl_CLR_PANEL2,frame);
   m_r.Text(x+w/2,y+S(5),title,PControl_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_TOP,false);
   m_r.Text(x+w/2,y+S(17),value,value_clr,FS(16),TA_CENTER|TA_TOP,true);

   int bx=x+S(12), bw=w-S(24), by=y+S(42), bh=S(6);
   double range=vmax-vmin;
   if(range<=0) range=1.0;
   int nb=ArraySize(bounds);
   double prev=vmin;
   for(int i=0; i<=nb; i++)
     {
      double next=(i<nb ? bounds[i] : vmax);
      int x1=bx+(int)MathRound(bw*(prev-vmin)/range);
      int x2=bx+(int)MathRound(bw*(next-vmin)/range);
      color c=(i<ArraySize(clrs) ? clrs[i] : PControl_CLR_GREEN);
      m_r.Fill(x1,by,MathMax(1,x2-x1),bh,PControl_Mix(c,PControl_CLR_PANEL2,0.15));
      prev=next;
     }
   double cv=MathMax(vmin,MathMin(vmax,v));
   int mxp=bx+(int)MathRound(bw*(cv-vmin)/range);
   m_r.Fill(mxp-1,by-S(2),S(2),bh+S(4),PControl_CLR_WHITE);

   int nt=ArraySize(ticks);
   for(int i=0; i<nt; i++)
     {
      int tx=bx+(int)MathRound(bw*(double)i/(nt-1));
      uint al=(i==0 ? TA_LEFT : (i==nt-1 ? TA_RIGHT : TA_CENTER));
      m_r.Text(tx,by+bh+S(2),ticks[i],PControl_CLR_TEXT_MUTED,FS(8),al|TA_TOP,false);
     }
   m_r.Text(x+w/2,y+h-S(4),rating,PControl_CLR_TEXT_DIM,FS(9),TA_CENTER|TA_BOTTOM,false);
  }

//+------------------------------------------------------------------+
//| Tarjeta con medidor semicircular 0-100                             |
//+------------------------------------------------------------------+
void PControl_Panel::ArenaGaugeCard(const int x,const int y,const int w,const int h,const string title,const double score)
  {
   m_r.Box(x,y,w,h,PControl_CLR_PANEL2,PControl_CLR_BORDER);
   m_r.Text(x+w/2,y+S(5),title,PControl_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_TOP,false);
   double sc=MathMax(0.0,MathMin(100.0,score));
   color c=(sc<50.0 ? PControl_CLR_RED : (sc<75.0 ? PControl_CLR_ORANGE : PControl_CLR_GREEN));
   int r_out=MathMin(S(52),h-S(34));
   int r_in=MathMax(S(6),r_out-MathMax(S(7),r_out/5));
   int cx=x+w/2, cy=y+h-S(14);
   m_r.Ring(cx,cy,r_out,r_in,0.0,180.0,PControl_CLR_PANEL3);
   if(sc>0.0) m_r.Ring(cx,cy,r_out,r_in,180.0-180.0*sc/100.0,180.0,c);
   m_r.Text(cx,cy-S(3),IntegerToString((int)MathRound(sc)),PControl_CLR_WHITE,FS(MathMax(15,r_out/2)),TA_CENTER|TA_BOTTOM,true);
   m_r.Text(cx,cy+S(1),"/100",PControl_CLR_TEXT_MUTED,FS(9),TA_CENTER|TA_TOP,false);
  }

//+------------------------------------------------------------------+
//| Tarjeta de texto con título coloreado y líneas ajustadas           |
//+------------------------------------------------------------------+
void PControl_Panel::ArenaTextCard(const int x,const int y,const int w,const int h,const string title,const color frame,const string &lines[])
  {
   m_r.Box(x,y,w,h,PControl_CLR_PANEL2,frame);
   m_r.Text(x+S(10),y+S(6),title,frame,FS(11),TA_LEFT|TA_TOP,true);
   int ty=y+S(26), lh=S(15);
   int inner=w-S(20);
   for(int i=0; i<ArraySize(lines); i++)
     {
      string wrapped[];
      int n=m_r.WrapText(lines[i],inner,FS(10),false,wrapped);
      for(int j=0; j<n; j++)
        {
         if(ty+lh>y+h-S(4)) return;
         m_r.Text(x+S(10),ty,wrapped[j],PControl_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
         ty+=lh;
        }
     }
  }

//+------------------------------------------------------------------+
//| Vista avanzada: tabla de métricas                                  |
//+------------------------------------------------------------------+
void PControl_Panel::MetricRow(const int x,const int y,const int w,const string label,const string value,const color clr)
  {
   m_r.Text(x+S(8),y,label,PControl_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   m_r.Text(x+w-S(8),y,value,clr,FS(10),TA_RIGHT|TA_TOP,true);
  }

void PControl_Panel::DrawArenaAdvanced(const PControl_Rect &rc)
  {
   PControl_Stats s=m_stats;
   string labels[];
   string values[];
   color  colors[];
   int n=0;
#define PControl_ADD(l,v,c) { ArrayResize(labels,n+1); ArrayResize(values,n+1); ArrayResize(colors,n+1); labels[n]=(l); values[n]=(v); colors[n]=(c); n++; }

   PControl_ADD("Beneficio neto",PControl_Signed(s.net)+" "+m_currency,PControl_PnLColor(s.net));
   PControl_ADD("Beneficio bruto",PControl_Money(s.gross_win),PControl_CLR_GREEN);
   PControl_ADD("Pérdida bruta",PControl_Money(s.gross_loss),PControl_CLR_RED);
   PControl_ADD("Factor de beneficio",DoubleToString(s.profit_factor,2),(s.profit_factor>=1.5 ? PControl_CLR_GREEN : (s.profit_factor>=1.0 ? PControl_CLR_ORANGE : PControl_CLR_RED)));
   PControl_ADD("Expectativa por operación",PControl_Signed(s.expectancy),PControl_PnLColor(s.expectancy));
   PControl_ADD("Ganancia media",PControl_Money(s.avg_win),PControl_CLR_GREEN);
   PControl_ADD("Pérdida media",PControl_Money(s.avg_loss),PControl_CLR_RED);
   PControl_ADD("Ratio ganancia/pérdida",DoubleToString(s.payoff,2),(s.payoff>=1.0 ? PControl_CLR_GREEN : PControl_CLR_ORANGE));
   PControl_ADD("Mayor ganancia",PControl_Money(s.largest_win),PControl_CLR_GREEN);
   PControl_ADD("Mayor pérdida",PControl_Money(s.largest_loss),PControl_CLR_RED);
   PControl_ADD("Racha máx. ganadora",IntegerToString(s.max_consec_wins),PControl_CLR_TEXT);
   PControl_ADD("Racha máx. perdedora",IntegerToString(s.max_consec_losses),PControl_CLR_TEXT);
   PControl_ADD("Drawdown máximo",PControl_Money(s.max_dd_money)+" "+m_currency+" ("+PControl_Pct(s.max_dd_pct,2)+")",PControl_CLR_RED);
   PControl_ADD("Factor de recuperación",DoubleToString(s.recovery_factor,2),(s.recovery_factor>=2.0 ? PControl_CLR_GREEN : PControl_CLR_TEXT));
   PControl_ADD("Ratio de Sharpe (por op.)",DoubleToString(s.sharpe,2),(s.sharpe>=1.0 ? PControl_CLR_GREEN : PControl_CLR_TEXT));
   PControl_ADD("Desv. típica del P&L",PControl_Money(s.std_dev),PControl_CLR_TEXT);
   PControl_ADD("Criterio de Kelly",PControl_Pct(s.kelly,1),(s.kelly>0 ? PControl_CLR_GREEN : PControl_CLR_RED));
   PControl_ADD("Duración media",PControl_Duration(s.avg_duration),PControl_CLR_TEXT);
   PControl_ADD("Días operados",IntegerToString(s.trading_days),PControl_CLR_TEXT);
   PControl_ADD("Operaciones por día",DoubleToString(s.avg_trades_day,2),(s.avg_trades_day>m_set.max_trades_day ? PControl_CLR_ORANGE : PControl_CLR_TEXT));
   PControl_ADD("Mejor día",PControl_Signed(s.best_day)+"  ("+PControl_DateStr(s.best_day_date)+")",PControl_CLR_GREEN);
   PControl_ADD("Peor día",PControl_Signed(s.worst_day)+"  ("+PControl_DateStr(s.worst_day_date)+")",PControl_CLR_RED);
   double lwr=(s.long_trades>0 ? 100.0*s.long_wins/s.long_trades : 0.0);
   double swr=(s.short_trades>0 ? 100.0*s.short_wins/s.short_trades : 0.0);
   PControl_ADD("Compras",StringFormat("%d ops · WR %s · %s",s.long_trades,PControl_Pct(lwr,1),PControl_Signed(s.long_net)),PControl_PnLColor(s.long_net));
   PControl_ADD("Ventas",StringFormat("%d ops · WR %s · %s",s.short_trades,PControl_Pct(swr,1),PControl_Signed(s.short_net)),PControl_PnLColor(s.short_net));
   PControl_ADD("Volumen total",DoubleToString(s.volume,2)+" lotes",PControl_CLR_TEXT);
   PControl_ADD("Swap total",PControl_Money(s.swap,3),PControl_PnLColor(s.swap));
   PControl_ADD("Comisión total",PControl_Money(s.commission,3),PControl_PnLColor(s.commission));
   PControl_ADD("Balance inicial del período",PControl_Money(s.start_balance)+" "+m_currency,PControl_CLR_TEXT);
   PControl_ADD("Violaciones de stop",IntegerToString(s.sl_violations),(s.sl_violations>0 ? PControl_CLR_RED : PControl_CLR_GREEN));
   PControl_ADD("Revenge trades",IntegerToString(s.revenge_trades),(s.revenge_trades>0 ? PControl_CLR_RED : PControl_CLR_GREEN));
   PControl_ADD("Días con sobre-trading",IntegerToString(s.overtrading_days),(s.overtrading_days>0 ? PControl_CLR_ORANGE : PControl_CLR_GREEN));
   PControl_ADD("Puntuación de disciplina",DoubleToString(s.discipline,0)+" / 100",(s.discipline>=75 ? PControl_CLR_GREEN : (s.discipline>=50 ? PControl_CLR_ORANGE : PControl_CLR_RED)));
   PControl_ADD("Eficiencia de operación",DoubleToString(s.efficiency,0)+" / 100",(s.efficiency>=75 ? PControl_CLR_GREEN : (s.efficiency>=50 ? PControl_CLR_ORANGE : PControl_CLR_RED)));
   PControl_ADD("Tasa de errores",PControl_Pct(s.mistake_rate,1),(s.mistake_rate<5 ? PControl_CLR_GREEN : (s.mistake_rate<10 ? PControl_CLR_ORANGE : PControl_CLR_RED)));
#undef PControl_ADD

   int rowh=S(20);
   int gap=S(8);
   int rows_fit=MathMax(1,(rc.h-S(6))/rowh);
   int cols=(n+rows_fit-1)/rows_fit;
   if(cols<1) cols=1;
   if(cols>3) cols=3;
   if(cols==1 && rc.w>S(520)) cols=2;
   // reparto equilibrado: misma cantidad de filas (±1) en cada columna
   rows_fit=(n+cols-1)/cols;
   if(rows_fit*rowh+S(6)>rc.h) rowh=MathMax(S(12),(rc.h-S(6))/rows_fit);
   int cw=(rc.w-(cols-1)*gap)/cols;

   for(int c=0; c<cols; c++)
     {
      int cx=rc.x+c*(cw+gap);
      int count=MathMin(rows_fit,n-c*rows_fit);
      if(count<=0) break;
      m_r.Box(cx,rc.y,cw,count*rowh+S(6),PControl_CLR_PANEL2,PControl_CLR_BORDER);
      for(int k=0; k<count; k++)
        {
         int i=c*rows_fit+k;
         int ry=rc.y+S(3)+k*rowh;
         if((k%2)==1) m_r.Fill(cx+1,ry,cw-2,rowh,PControl_Mix(PControl_CLR_PANEL2,PControl_CLR_PANEL3,0.5));
         MetricRow(cx,ry+(rowh-m_r.TextHeight(FS(10)))/2,cw,labels[i],values[i],colors[i]);
        }
     }
  }

//+------------------------------------------------------------------+
//| SECCIÓN 10: EXPERT ADVISOR - parámetros de entrada y eventos       |
//+------------------------------------------------------------------+
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

input group "=== Tarjetas superiores ==="
input double   InpPnLBase         = 100.0;     // Base de la barra de P&L Total (dinero, 0 = sin barra)
input double   InpMaxDrawdownPct  = 10.0;      // Drawdown máximo tolerado del periodo (%) para la barra de DD

input group "=== Análisis de disciplina (Estadísticas Arena) ==="
input int      InpMaxTradesPerDay = 3;         // Umbral de sobre-trading (operaciones por día)
input int      InpRevengeMinutes  = 5;         // Minutos tras una pérdida para marcar revenge trading
input double   InpSLViolationFactor = 1.3;     // Factor sobre la pérdida mediana para marcar violación de stop

input group "=== Actualización ==="
input int      InpRefreshMs       = 1000;      // Intervalo de refresco de equity (ms)

input group "=== Demostración ==="
input bool     InpDemoData        = false;     // Usar datos de ejemplo en lugar del historial real

//--- instancia única del panel
PControl_Panel g_PControl_panel;

//+------------------------------------------------------------------+
//| Inicialización                                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   PControl_Settings s;
   s.font            =InpFontName;
   s.scale           =InpUIScale;
   s.start_maximized =InpStartMaximized;
   s.x               =InpPanelX;
   s.y               =InpPanelY;
   s.w               =InpPanelWidth;
   s.h               =InpPanelHeight;
   s.pnl_base        =InpPnLBase;
   s.max_dd_pct      =InpMaxDrawdownPct;
   s.max_trades_day  =InpMaxTradesPerDay;
   s.revenge_minutes =InpRevengeMinutes;
   s.sl_factor       =InpSLViolationFactor;
   s.refresh_ms      =InpRefreshMs;
   s.demo_data       =InpDemoData;
   s.clean_chart     =InpCleanChart;

   if(!g_PControl_panel.Init(s))
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
   g_PControl_panel.Deinit();
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
   g_PControl_panel.OnTimer();
  }

//+------------------------------------------------------------------+
//| Actualización en tiempo real al cerrar posiciones                 |
//+------------------------------------------------------------------+
void OnTrade()
  {
   g_PControl_panel.OnTradeEvent();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD || trans.type==TRADE_TRANSACTION_HISTORY_ADD)
      g_PControl_panel.OnTradeEvent();
  }

//+------------------------------------------------------------------+
//| Eventos del gráfico (ratón, rueda, teclado, cambio de tamaño)     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   g_PControl_panel.OnChartEvent(id,lparam,dparam,sparam);
  }
//+------------------------------------------------------------------+
