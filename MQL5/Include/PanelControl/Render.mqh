//+------------------------------------------------------------------+
//|                                                       Render.mqh |
//|        Panel de Control MT5 - Capa de dibujo sobre CCanvas (ARGB) |
//+------------------------------------------------------------------+
#ifndef PC_RENDER_MQH
#define PC_RENDER_MQH

#include <Canvas/Canvas.mqh>
#include "Config.mqh"

//+------------------------------------------------------------------+
//| CRender: un único bitmap (OBJ_BITMAP_LABEL) donde se pinta todo   |
//+------------------------------------------------------------------+
class CRender
  {
private:
   CCanvas           m_canvas;
   string            m_name;
   int               m_x;
   int               m_y;
   int               m_w;
   int               m_h;
   string            m_font;
   int               m_font_size;
   bool              m_font_bold;
   bool              m_created;

   void              ApplyFont(const int size,const bool bold);
   uint              ARGB(const color clr) const { return(ColorToARGB(clr,255)); }

public:
                     CRender();
                    ~CRender();

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
CRender::CRender() : m_name(""),m_x(0),m_y(0),m_w(0),m_h(0),m_font("Arial"),m_font_size(-1),m_font_bold(false),m_created(false)
  {
  }

//+------------------------------------------------------------------+
CRender::~CRender()
  {
   Destroy();
  }

//+------------------------------------------------------------------+
bool CRender::Create(const string name,const int x,const int y,const int w,const int h,const string font)
  {
   Destroy();
   m_name=name;
   m_x=x; m_y=y;
   m_w=MathMax(1,w);
   m_h=MathMax(1,h);
   m_font=(font=="" ? "Arial" : font);
   if(!m_canvas.CreateBitmapLabel(0,0,m_name,m_x,m_y,m_w,m_h,COLOR_FORMAT_ARGB_NORMALIZE))
     {
      Print("PanelControl: no se pudo crear el lienzo (",GetLastError(),")");
      return(false);
     }
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
void CRender::Destroy()
  {
   if(m_created)
     {
      m_canvas.Destroy();
      m_created=false;
     }
   if(m_name!="" && ObjectFind(0,m_name)>=0)
      ObjectDelete(0,m_name);
  }

//+------------------------------------------------------------------+
bool CRender::Resize(const int w,const int h)
  {
   int nw=MathMax(1,w), nh=MathMax(1,h);
   if(nw==m_w && nh==m_h) return(true);
   m_w=nw; m_h=nh;
   bool ok=m_canvas.Resize(m_w,m_h);
   m_font_size=-1;
   return(ok);
  }

//+------------------------------------------------------------------+
void CRender::Move(const int x,const int y)
  {
   m_x=x; m_y=y;
   ObjectSetInteger(0,m_name,OBJPROP_XDISTANCE,m_x);
   ObjectSetInteger(0,m_name,OBJPROP_YDISTANCE,m_y);
  }

//+------------------------------------------------------------------+
void CRender::Update()
  {
   m_canvas.Update(false);
  }

//+------------------------------------------------------------------+
void CRender::BringToFront()
  {
   ObjectSetInteger(0,m_name,OBJPROP_ZORDER,1000);
  }

//+------------------------------------------------------------------+
void CRender::ApplyFont(const int size,const bool bold)
  {
   if(size==m_font_size && bold==m_font_bold) return;
   m_font_size=size;
   m_font_bold=bold;
   m_canvas.FontSet(m_font,size,(bold ? FW_BOLD : FW_NORMAL));
  }

//+------------------------------------------------------------------+
void CRender::Clear(const color clr)
  {
   m_canvas.Erase(ARGB(clr));
  }

//+------------------------------------------------------------------+
void CRender::Fill(const int x,const int y,const int w,const int h,const color clr)
  {
   if(w<=0 || h<=0) return;
   m_canvas.FillRectangle(x,y,x+w-1,y+h-1,ARGB(clr));
  }

//+------------------------------------------------------------------+
void CRender::Frame(const int x,const int y,const int w,const int h,const color clr)
  {
   if(w<=0 || h<=0) return;
   m_canvas.Rectangle(x,y,x+w-1,y+h-1,ARGB(clr));
  }

//+------------------------------------------------------------------+
void CRender::Box(const int x,const int y,const int w,const int h,const color fill,const color border)
  {
   Fill(x,y,w,h,fill);
   Frame(x,y,w,h,border);
  }

//+------------------------------------------------------------------+
void CRender::HLine(const int x1,const int x2,const int y,const color clr)
  {
   m_canvas.LineHorizontal(x1,x2,y,ARGB(clr));
  }

//+------------------------------------------------------------------+
void CRender::VLine(const int x,const int y1,const int y2,const color clr)
  {
   m_canvas.LineVertical(x,y1,y2,ARGB(clr));
  }

//+------------------------------------------------------------------+
void CRender::Line(const int x1,const int y1,const int x2,const int y2,const color clr)
  {
   m_canvas.LineAA(x1,y1,x2,y2,ARGB(clr));
  }

//+------------------------------------------------------------------+
void CRender::DottedHLine(const int x1,const int x2,const int y,const color clr,const int step)
  {
   uint c=ARGB(clr);
   int a=MathMin(x1,x2), b=MathMax(x1,x2);
   for(int x=a; x<=b; x+=MathMax(1,step))
      m_canvas.PixelSet(x,y,c);
  }

//+------------------------------------------------------------------+
void CRender::DottedVLine(const int x,const int y1,const int y2,const color clr,const int step)
  {
   uint c=ARGB(clr);
   int a=MathMin(y1,y2), b=MathMax(y1,y2);
   for(int y=a; y<=b; y+=MathMax(1,step))
      m_canvas.PixelSet(x,y,c);
  }

//+------------------------------------------------------------------+
void CRender::Pixel(const int x,const int y,const color clr)
  {
   m_canvas.PixelSet(x,y,ARGB(clr));
  }

//+------------------------------------------------------------------+
void CRender::Circle(const int cx,const int cy,const int r,const color clr)
  {
   m_canvas.FillCircle(cx,cy,r,ARGB(clr));
  }

//+------------------------------------------------------------------+
//| Anillo/arco relleno. Ángulos en grados, sentido matemático        |
//| (0 = derecha, 90 = arriba).                                       |
//+------------------------------------------------------------------+
void CRender::Ring(const int cx,const int cy,const int r_out,const int r_in,double a_from,double a_to,const color clr)
  {
   if(a_to<a_from) { double t=a_to; a_to=a_from; a_from=t; }
   if(a_to-a_from<0.01) return;
   uint c=ARGB(clr);
   int xs[4], ys[4];
   double step=2.0;
   for(double a=a_from; a<a_to; a+=step)
     {
      double a2=MathMin(a+step,a_to);
      double r1=a*M_PI/180.0, r2=a2*M_PI/180.0;
      xs[0]=cx+(int)MathRound(r_out*MathCos(r1)); ys[0]=cy-(int)MathRound(r_out*MathSin(r1));
      xs[1]=cx+(int)MathRound(r_out*MathCos(r2)); ys[1]=cy-(int)MathRound(r_out*MathSin(r2));
      xs[2]=cx+(int)MathRound(r_in*MathCos(r2));  ys[2]=cy-(int)MathRound(r_in*MathSin(r2));
      xs[3]=cx+(int)MathRound(r_in*MathCos(r1));  ys[3]=cy-(int)MathRound(r_in*MathSin(r1));
      m_canvas.FillPolygon(xs,ys,c);
     }
  }

//+------------------------------------------------------------------+
void CRender::TriangleLeft(const int cx,const int cy,const int size,const color clr)
  {
   int s=MathMax(2,size/2);
   m_canvas.FillTriangle(cx-s,cy,cx+s,cy-s,cx+s,cy+s,ARGB(clr));
  }

//+------------------------------------------------------------------+
void CRender::TriangleRight(const int cx,const int cy,const int size,const color clr)
  {
   int s=MathMax(2,size/2);
   m_canvas.FillTriangle(cx+s,cy,cx-s,cy-s,cx-s,cy+s,ARGB(clr));
  }

//+------------------------------------------------------------------+
void CRender::Checkbox(const int x,const int y,const int size,const bool checked,const color clr_on)
  {
   if(checked)
     {
      Fill(x,y,size,size,clr_on);
      int x1=x+size/4,      y1=y+size/2;
      int x2=x+size/2-1,    y2=y+size-size/4-1;
      int x3=x+size-size/4, y3=y+size/4;
      Line(x1,y1,x2,y2,PC_CLR_WHITE);
      Line(x2,y2,x3,y3,PC_CLR_WHITE);
     }
   else
     {
      Fill(x,y,size,size,PC_CLR_PANEL2);
      Frame(x,y,size,size,PC_CLR_BORDER2);
     }
  }

//+------------------------------------------------------------------+
void CRender::Text(const int x,const int y,const string txt,const color clr,const int size,const uint align,const bool bold)
  {
   if(txt=="") return;
   ApplyFont(size,bold);
   m_canvas.TextOut(x,y,txt,ARGB(clr),align);
  }

//+------------------------------------------------------------------+
int CRender::TextWidth(const string txt,const int size,const bool bold)
  {
   if(txt=="") return(0);
   ApplyFont(size,bold);
   return(m_canvas.TextWidth(txt));
  }

//+------------------------------------------------------------------+
int CRender::TextHeight(const int size,const bool bold)
  {
   ApplyFont(size,bold);
   return(m_canvas.TextHeight("Ag"));
  }

//+------------------------------------------------------------------+
string CRender::Ellipsis(const string txt,const int max_w,const int size,const bool bold)
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
int CRender::WrapText(const string txt,const int max_w,const int size,const bool bold,string &lines[])
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

#endif // PC_RENDER_MQH
