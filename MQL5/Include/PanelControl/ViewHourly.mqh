//+------------------------------------------------------------------+
//|                                                   ViewHourly.mqh |
//|        Panel de Control MT5 - Vista "Por Hora" (mapa de calor)    |
//+------------------------------------------------------------------+
#ifndef PC_VIEWHOURLY_MQH
#define PC_VIEWHOURLY_MQH

#include "Panel.mqh"

//+------------------------------------------------------------------+
//| Formato compacto para las celdas (+6, -8, +0.45)                   |
//+------------------------------------------------------------------+
string PC_CellValue(const double v)
  {
   if(MathAbs(v)<1.0) return(PC_Signed(v,2));
   return(PC_Signed(v,0));
  }

//+------------------------------------------------------------------+
void CPanel::DrawHourlyView(const SRect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PC_CLR_PANEL,PC_CLR_BORDER);
   string title="Rendimiento por Horas";
   m_r.Text(rc.x+S(10),rc.y+S(8),title,PC_CLR_BLUE_LIGHT,FS(13),TA_LEFT|TA_TOP,true);
   int tw=m_r.TextWidth(title,FS(13),true);
   int ix=rc.x+S(10)+tw+S(16), iy=rc.y+S(16);
   m_r.Circle(ix,iy,S(7),PC_CLR_BLUE);
   m_r.Text(ix,iy,"i",PC_CLR_WHITE,FS(9),TA_CENTER|TA_VCENTER,true);
   Hit(ix-S(8),iy-S(8),S(16),S(16),ACT_INFO,0);

   //--- botones de la derecha
   int bh=S(18), by=rc.y+S(7);
   int x=rc.x+rc.w-S(10);
   string tl=(m_hour_by_close ? "Hora CIERRE" : "Hora APERTURA");
   int w=m_r.TextWidth(tl,FS(10),true)+S(16);
   x-=w;
   Button(x,by,w,bh,tl,true,ACT_HOUR_TIME,0,0,10);
   x-=S(12);
   string modes[3]={"Compra/Venta","Compra","Venta"};
   for(int i=2; i>=0; i--)
     {
      int mw=MathMax(S(46),m_r.TextWidth(modes[i],FS(10),true)+S(14));
      x-=mw;
      Button(x,by,mw,bh,modes[i],(m_hour_mode==i),ACT_HOUR_MODE,i,0,10);
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
      if(m_hour_mode==HOUR_BUY && m_recs[i].type!=0) continue;
      if(m_hour_mode==HOUR_SELL && m_recs[i].type!=1) continue;
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
   if(cell_w<S(14) || cell_h<S(14))
     {
      DrawEmpty(rc,"El panel es demasiado pequeño para el mapa de calor");
      return;
     }
   int totals_x=gx+label_w+24*cell_w+S(8);
   tot_w=gx+gw-totals_x;
   bool small_font=(cell_w<S(34));

   for(int h=0; h<24; h++)
      m_r.Text(gx+label_w+h*cell_w+cell_w/2,gy+hdr_h/2,StringFormat("%02d",h),PC_CLR_TEXT_MUTED,FS(9),TA_CENTER|TA_VCENTER,false);
   m_r.Text(totals_x+tot_w/2,gy+hdr_h/2,"TOTAL",PC_CLR_TEXT_DIM,FS(9),TA_CENTER|TA_VCENTER,true);

   color empty_bg=PC_Mix(PC_CLR_PANEL,PC_CLR_BG,0.4);
   int inner_w=cell_w-2, inner_h=cell_h-2;

   for(int d=0; d<7; d++)
     {
      int ry=gy+hdr_h+S(2)+d*cell_h;
      m_r.Text(gx,ry+cell_h/2,PC_DAYS_SHORT[d],PC_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_VCENTER,false);
      for(int h=0; h<24; h++)
        {
         int k=d*24+h;
         int cx=gx+label_w+h*cell_w+1, cy=ry+1;
         if(cnt[k]==0)
           {
            m_r.Box(cx,cy,inner_w,inner_h,empty_bg,PC_CLR_GRID);
            continue;
           }
         color c=PC_PnLColor(net[k]);
         m_r.Box(cx,cy,inner_w,inner_h,PC_Mix(c,PC_CLR_PANEL,0.8),c);
         m_r.Text(cx+inner_w/2,cy+inner_h/2-S(5),PC_CellValue(net[k]),c,FS(small_font ? 9 : 10),TA_CENTER|TA_VCENTER,true);
         m_r.Text(cx+inner_w/2,cy+inner_h-S(3),IntegerToString(cnt[k])+"T",PC_CLR_TEXT_MUTED,FS(8),TA_CENTER|TA_BOTTOM,false);
         Hit(cx,cy,inner_w,inner_h,ACT_HOUR_CELL,d,h);
        }
      //--- total del día
      if(rcnt[d]>0)
        {
         color rcol=PC_PnLColor(rnet[d]);
         m_r.Box(totals_x,ry+1,tot_w,inner_h,PC_Mix(rcol,PC_CLR_PANEL,0.86),rcol);
         m_r.Text(totals_x+tot_w/2,ry+1+inner_h/2,PC_Signed(rnet[d]),rcol,FS(10),TA_CENTER|TA_VCENTER,true);
        }
      else
         m_r.Box(totals_x,ry+1,tot_w,inner_h,empty_bg,PC_CLR_GRID);
     }

   //--- fila TOTAL
   int ty=gy+hdr_h+S(2)+7*cell_h;
   m_r.Text(gx,ty+cell_h/2,"TOTAL",PC_CLR_TEXT_DIM,FS(9),TA_LEFT|TA_VCENTER,true);
   for(int h=0; h<24; h++)
     {
      int cx=gx+label_w+h*cell_w+1, cy=ty+1;
      if(ccnt[h]==0)
        {
         m_r.Box(cx,cy,inner_w,inner_h,empty_bg,PC_CLR_GRID);
         continue;
        }
      color c=PC_PnLColor(cnet[h]);
      m_r.Box(cx,cy,inner_w,inner_h,PC_Mix(c,PC_CLR_PANEL,0.86),c);
      string txt=(small_font ? PC_CellValue(cnet[h]) : PC_Signed(cnet[h]));
      m_r.Text(cx+inner_w/2,cy+inner_h/2,txt,c,FS(8),TA_CENTER|TA_VCENTER,true);
     }
   color gcol=PC_PnLColor(gnet);
   if(gcnt>0)
     {
      m_r.Box(totals_x,ty+1,tot_w,inner_h,PC_Mix(gcol,PC_CLR_PANEL,0.8),gcol);
      m_r.Text(totals_x+tot_w/2,ty+1+inner_h/2,PC_Signed(gnet),gcol,FS(11),TA_CENTER|TA_VCENTER,true);
     }
   else
      m_r.Box(totals_x,ty+1,tot_w,inner_h,empty_bg,PC_CLR_GRID);
  }

//+------------------------------------------------------------------+
//| Popup de detalle de una celda                                      |
//+------------------------------------------------------------------+
void CPanel::DrawHourCellPopup()
  {
   int d=(int)m_popup_p1, h=(int)m_popup_p2;
   int    nb=0, ns=0, bw=0, bl=0, sw=0, sl=0;
   double bnet=0.0, snet=0.0;
   int    list[];
   ArrayResize(list,0);

   for(int i=0; i<ArraySize(m_recs); i++)
     {
      if(m_hour_mode==HOUR_BUY && m_recs[i].type!=0) continue;
      if(m_hour_mode==HOUR_SELL && m_recs[i].type!=1) continue;
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

   string title=StringFormat("%s %02d:00 - %02d:59  (%s)",PC_DAYS_LONG[d],h,h,(m_hour_by_close ? "hora de cierre" : "hora de apertura"));
   PopupFrame(x,y,w,hgt,title);

   int lx=x+S(12), ty=y+S(32), lh=S(17);
   m_r.Text(lx,ty,"Total de operaciones: "+IntegerToString(total),PC_CLR_TEXT,FS(11),TA_LEFT|TA_TOP,true);
   ty+=lh+S(2);

   double bwr=(nb>0 ? 100.0*bw/nb : 0.0), swr=(ns>0 ? 100.0*sw/ns : 0.0);
   string sb="Compras: ";
   m_r.Text(lx,ty,sb,PC_CLR_GREEN,FS(10),TA_LEFT|TA_TOP,true);
   m_r.Text(lx+m_r.TextWidth(sb,FS(10),true),ty,StringFormat("%d  (G: %d / P: %d, WR %s)",nb,bw,bl,PC_Pct(bwr,1)),PC_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   ty+=lh;
   string ss="Ventas: ";
   m_r.Text(lx,ty,ss,PC_CLR_RED,FS(10),TA_LEFT|TA_TOP,true);
   m_r.Text(lx+m_r.TextWidth(ss,FS(10),true),ty,StringFormat("%d  (G: %d / P: %d, WR %s)",ns,sw,sl,PC_Pct(swr,1)),PC_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   ty+=lh;

   string p1="P&L Compras: ";
   m_r.Text(lx,ty,p1,PC_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   m_r.Text(lx+m_r.TextWidth(p1,FS(10)),ty,PC_Signed(bnet)+" "+m_currency,PC_PnLColor(bnet),FS(10),TA_LEFT|TA_TOP,true);
   int half=lx+w/2;
   string p2="P&L Ventas: ";
   m_r.Text(half,ty,p2,PC_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   m_r.Text(half+m_r.TextWidth(p2,FS(10)),ty,PC_Signed(snet)+" "+m_currency,PC_PnLColor(snet),FS(10),TA_LEFT|TA_TOP,true);
   ty+=lh;
   string p3="P&L Total: ";
   m_r.Text(lx,ty,p3,PC_CLR_TEXT,FS(11),TA_LEFT|TA_TOP,true);
   m_r.Text(lx+m_r.TextWidth(p3,FS(11),true),ty,PC_Signed(bnet+snet)+" "+m_currency,PC_PnLColor(bnet+snet),FS(11),TA_LEFT|TA_TOP,true);
   ty+=lh+S(2);

   if(max_rows>0)
     {
      m_r.HLine(lx,x+w-S(12),ty,PC_CLR_BORDER2);
      ty+=S(6);
      int c0=lx, c1=lx+S(120), c2=lx+S(200), c3=x+w-S(12);
      m_r.Text(c0,ty,(m_hour_by_close ? "Cierre" : "Apertura"),PC_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c1,ty,"Símbolo",PC_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c2,ty,"Tipo",PC_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c3,ty,"Neto",PC_CLR_TEXT_MUTED,FS(9),TA_RIGHT|TA_TOP,true);
      ty+=S(14);
      for(int k=0; k<max_rows; k++)
        {
         SPosRecord r=m_recs[list[k]];
         datetime t=(m_hour_by_close ? r.close_time : r.open_time);
         m_r.Text(c0,ty,PC_DateTimeStr(t),PC_CLR_TEXT_DIM,FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c1,ty,m_r.Ellipsis(r.symbol,c2-c1-S(6),FS(9)),PC_CLR_TEXT,FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c2,ty,(r.type==0 ? "Compra" : "Venta"),(r.type==0 ? PC_CLR_GREEN : PC_CLR_RED),FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c3,ty,PC_Signed(r.net),PC_PnLColor(r.net),FS(9),TA_RIGHT|TA_TOP,true);
         ty+=rowh;
        }
      if(ArraySize(list)>max_rows)
         m_r.Text(lx,ty,StringFormat("... y %d operación(es) más",ArraySize(list)-max_rows),PC_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,false);
     }
  }

#endif // PC_VIEWHOURLY_MQH
