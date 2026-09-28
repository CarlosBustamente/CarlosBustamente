//+------------------------------------------------------------------+
//|                                                    ViewChart.mqh |
//|        Panel de Control MT5 - Vista "Gráfico" (P&L acumulado)     |
//+------------------------------------------------------------------+
#ifndef PC_VIEWCHART_MQH
#define PC_VIEWCHART_MQH

#include "Panel.mqh"

#define PC_YOF(val) (py+(int)MathRound((vmax-(val))/(vmax-vmin)*(ph-1)))

//+------------------------------------------------------------------+
void CPanel::DrawChartView(const SRect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PC_CLR_PANEL,PC_CLR_BORDER);
   m_r.Text(rc.x+S(10),rc.y+S(8),"Evolución del Balance",PC_CLR_TEXT,FS(13),TA_LEFT|TA_TOP,true);
   m_r.Text(rc.x+rc.w-S(10),rc.y+S(10),"P&L neto acumulado ("+m_currency+")",PC_CLR_TEXT_MUTED,FS(9),TA_RIGHT|TA_TOP,false);

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
   m_r.Fill(px,py,pw,ph,PC_Mix(PC_CLR_PANEL,PC_CLR_BG,0.5));

   //--- rejilla horizontal y eje Y
   int ticks=(ph<S(160) ? 4 : 6);
   for(int t=0; t<ticks; t++)
     {
      double val=vmax-(vmax-vmin)*t/(ticks-1);
      int yy=py+(int)MathRound((ph-1)*(double)t/(ticks-1));
      m_r.DottedHLine(px,px+pw-1,yy,PC_CLR_GRID,2);
      m_r.Text(px-S(6),yy,DoubleToString(val,2),PC_CLR_TEXT_MUTED,FS(9),TA_RIGHT|TA_VCENTER,false);
     }

   //--- rejilla vertical y eje X (fechas)
   int xt=(pw<S(360) ? 3 : 5);
   for(int t=0; t<xt; t++)
     {
      int xx=px+(int)MathRound((pw-1)*(double)t/(xt-1));
      m_r.DottedVLine(xx,py,py+ph-1,PC_CLR_GRID,2);
      int idx=(int)MathRound((n-1)*(double)t/(xt-1));
      uint al=(t==0 ? TA_LEFT : (t==xt-1 ? TA_RIGHT : TA_CENTER));
      m_r.Text(xx,py+ph+S(6),PC_DateStr(m_recs[idx].close_time),PC_CLR_TEXT_MUTED,FS(9),al|TA_TOP,false);
     }

   int y0=PC_YOF(0.0);
   if(y0<py) y0=py;
   if(y0>py+ph-1) y0=py+ph-1;

   //--- relleno en columnas (textura de líneas verticales)
   color gfill=PC_Mix(PC_CLR_GREEN,PC_CLR_PANEL,0.62);
   color gfill2=PC_Mix(PC_CLR_GREEN,PC_CLR_PANEL,0.78);
   color rfill=PC_Mix(PC_CLR_RED,PC_CLR_PANEL,0.62);
   color rfill2=PC_Mix(PC_CLR_RED,PC_CLR_PANEL,0.78);
   for(int cx=0; cx<pw; cx++)
     {
      double pos=(double)cx/(pw-1)*n;
      int i0=(int)MathFloor(pos);
      if(i0>=n) i0=n-1;
      if(i0<0) i0=0;
      double frac=pos-i0;
      double val=v[i0]+(v[i0+1]-v[i0])*frac;
      int yy=PC_YOF(val);
      if(yy<py) yy=py;
      if(yy>py+ph-1) yy=py+ph-1;
      bool alt=((cx%3)==0);
      color c=(val>=0 ? (alt ? gfill : gfill2) : (alt ? rfill : rfill2));
      if(yy<y0)      m_r.VLine(px+cx,yy,y0,c);
      else if(yy>y0) m_r.VLine(px+cx,y0,yy,c);
     }
   m_r.HLine(px,px+pw-1,y0,PC_CLR_BORDER2);

   //--- curva
   int prev_x=-1, prev_y=-1;
   for(int i=0; i<=n; i++)
     {
      int xx=px+(int)MathRound((pw-1)*(double)i/n);
      int yy=PC_YOF(v[i]);
      if(prev_x>=0)
        {
         color lc=(v[i]>=0 ? PC_CLR_GREEN_BRIGHT : PC_CLR_RED);
         m_r.Line(prev_x,prev_y,xx,yy,lc);
         m_r.Line(prev_x,prev_y+1,xx,yy+1,lc);
        }
      prev_x=xx; prev_y=yy;
     }
   m_r.Frame(px,py,pw,ph,PC_CLR_BORDER);

   //--- información al pasar el ratón
   if(m_hover_plot && InRect(m_rc_plot,m_mouse_x,m_mouse_y))
     {
      double pos=(double)(m_mouse_x-px)/(pw-1)*n;
      int i=(int)MathRound(pos);
      if(i<0) i=0;
      if(i>n) i=n;
      int xx=px+(int)MathRound((pw-1)*(double)i/n);
      int yy=PC_YOF(v[i]);
      m_r.DottedVLine(xx,py,py+ph-1,PC_CLR_TEXT_DIM,2);
      m_r.Circle(xx,yy,S(3),PC_CLR_WHITE);

      string l1,l2,l3;
      color  c3=PC_CLR_TEXT_DIM;
      if(i==0)
        {
         l1="Inicio del período";
         l2="P&L acumulado: 0.00 "+m_currency;
         l3="";
        }
      else
        {
         SPosRecord r=m_recs[i-1];
         l1=PC_DateTimeStr(r.close_time);
         l2="P&L acumulado: "+PC_Signed(v[i])+" "+m_currency;
         l3=StringFormat("Op. #%d  %s  %s  %s",i,r.symbol,(r.type==0 ? "Compra" : "Venta"),PC_Signed(r.net));
         c3=PC_PnLColor(r.net);
        }
      int tw=MathMax(m_r.TextWidth(l1,FS(10),true),MathMax(m_r.TextWidth(l2,FS(10)),m_r.TextWidth(l3,FS(10))))+S(16);
      int th=S(50);
      int tx=xx+S(12);
      if(tx+tw>px+pw) tx=xx-S(12)-tw;
      int ty=yy-th/2;
      if(ty<py) ty=py;
      if(ty+th>py+ph) ty=py+ph-th;
      m_r.Box(tx,ty,tw,th,PC_CLR_PANEL3,PC_CLR_BORDER2);
      m_r.Text(tx+S(8),ty+S(5),l1,PC_CLR_TEXT,FS(10),TA_LEFT|TA_TOP,true);
      m_r.Text(tx+S(8),ty+S(19),l2,PC_PnLColor(v[i]),FS(10),TA_LEFT|TA_TOP,false);
      m_r.Text(tx+S(8),ty+S(33),l3,c3,FS(10),TA_LEFT|TA_TOP,false);
     }
  }

#undef PC_YOF

#endif // PC_VIEWCHART_MQH
