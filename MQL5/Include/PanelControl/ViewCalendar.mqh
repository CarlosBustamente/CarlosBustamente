//+------------------------------------------------------------------+
//|                                                 ViewCalendar.mqh |
//|        Panel de Control MT5 - Vista "Calendario" mensual          |
//+------------------------------------------------------------------+
#ifndef PC_VIEWCALENDAR_MQH
#define PC_VIEWCALENDAR_MQH

#include "Panel.mqh"

//+------------------------------------------------------------------+
void CPanel::DrawCalendarView(const SRect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PC_CLR_PANEL,PC_CLR_BORDER);

   //--- el calendario navega por meses, por lo que ignora el rango
   //    temporal de la cabecera (mantiene símbolo / mágico / tipo)
   SPosRecord recs[];
   m_data.CollectNoTime(recs);
   SDayStat days[];
   m_data.BuildDaily(recs,days);

   datetime month_start=PC_MakeDate(m_cal_year,m_cal_month,1);
   int dim=PC_DaysInMonth(m_cal_year,m_cal_month);
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
   Button(rc.x+S(10),hy,nav,nav,"<",false,ACT_CAL_PREV,0,0,10);
   string title=PC_MONTHS[m_cal_month-1]+" "+IntegerToString(m_cal_year);
   int tw=MathMax(S(110),m_r.TextWidth(title,FS(12),true));
   int tx=rc.x+S(10)+nav+S(8);
   m_r.Text(tx+tw/2,hy+nav/2,title,PC_CLR_BLUE_LIGHT,FS(12),TA_CENTER|TA_VCENTER,true);
   Button(tx+tw+S(8),hy,nav,nav,">",false,ACT_CAL_NEXT,0,0,10);

   int sx=tx+tw+S(8)+nav+S(14);
   int sw=rc.x+rc.w-S(10)-sx;
   int sh=S(28);
   int sy=hy-S(5);
   color sbg=(mnet>=0 ? PC_CLR_SUMMARY_G : PC_CLR_SUMMARY_R);
   m_r.Box(sx,sy,sw,sh,sbg,PC_Mix(sbg,PC_CLR_WHITE,0.35));
   string labels[5]={"Operaciones","Ganadas","Perdidas","Beneficio","Porcentaje"};
   string vals[5];
   vals[0]=IntegerToString(mt);
   vals[1]=IntegerToString(mw);
   vals[2]=IntegerToString(ml);
   vals[3]=PC_Signed(mnet);
   vals[4]=PC_SignedPct(mpct);
   int cw5=sw/5;
   for(int i=0; i<5; i++)
     {
      int cx=sx+cw5*i+cw5/2;
      m_r.Text(cx,sy+S(3),labels[i],PC_Mix(PC_CLR_WHITE,sbg,0.25),FS(8),TA_CENTER|TA_TOP,false);
      m_r.Text(cx,sy+S(13),vals[i],PC_CLR_WHITE,FS(10),TA_CENTER|TA_TOP,true);
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
      m_r.Fill(gx+d*day_w,gy,day_w-2,hdr_h,PC_CLR_PANEL3);
      m_r.Text(gx+d*day_w+(day_w-2)/2,gy+hdr_h/2,PC_DAYS_SHORT[d],PC_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,true);
     }
   m_r.Fill(totals_x,gy,tot_w,hdr_h,PC_CLR_PANEL3);
   m_r.Text(totals_x+tot_w/2,gy+hdr_h/2,"Totales",PC_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,true);

   int first_dow=PC_WeekDay(month_start);
   int rows=(first_dow+dim+6)/7;
   int cell_h=(gh-hdr_h-S(2))/rows;
   if(cell_h<S(26)) cell_h=S(26);
   bool compact=(cell_h<S(48) || day_w<S(70));
   int ch=cell_h-2, cwid=day_w-2;
   datetime today=PC_DayStart(TimeCurrent());

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
         int di=CTradeData::FindDay(days,d);

         if(!in_month)
           {
            m_r.Box(cx,cy,cwid,ch,PC_Mix(PC_CLR_PANEL,PC_CLR_BG,0.6),(di>=0 ? PC_PnLColor(days[di].net) : PC_CLR_BORDER));
            MqlDateTime odt; TimeToStruct(d,odt);
            m_r.Text(cx+cwid/2,cy+S(3),IntegerToString(odt.day),PC_CLR_TEXT_MUTED,FS(8),TA_CENTER|TA_TOP,false);
            if(di>=0)
               m_r.Text(cx+cwid/2,cy+ch/2,PC_Signed(days[di].net),PC_PnLColor(days[di].net),FS(9),TA_CENTER|TA_VCENTER,true);
            continue;
           }

         if(di<0)
           {
            m_r.Box(cx,cy,cwid,ch,PC_CLR_PANEL2,(d==today ? PC_CLR_BLUE_LIGHT : PC_CLR_BORDER));
            m_r.Text(cx+S(3),cy+S(2),IntegerToString(day),PC_CLR_TEXT_MUTED,FS(8),TA_LEFT|TA_TOP,false);
            continue;
           }

         SDayStat ds=days[di];
         color c=PC_PnLColor(ds.net);
         m_r.Box(cx,cy,cwid,ch,PC_Mix(c,PC_CLR_PANEL,0.9),c);
         if(d==today) m_r.Frame(cx+1,cy+1,cwid-2,ch-2,PC_CLR_BLUE_LIGHT);
         m_r.Text(cx+S(3),cy+S(2),IntegerToString(day),PC_CLR_TEXT_MUTED,FS(8),TA_LEFT|TA_TOP,false);

         double pct=(ds.bal_start>0 ? ds.net/ds.bal_start*100.0 : 0.0);
         double ddp=(ds.bal_start>0 ? ds.max_dd/ds.bal_start*100.0 : 0.0);
         if(compact)
           {
            m_r.Text(cx+cwid/2,cy+ch/2-S(2),PC_Signed(ds.net),c,FS(10),TA_CENTER|TA_VCENTER,true);
            m_r.Text(cx+cwid/2,cy+ch-S(3),StringFormat("%dT %dG %dP",ds.trades,ds.wins,ds.losses),PC_CLR_TEXT_MUTED,FS(8),TA_CENTER|TA_BOTTOM,false);
           }
         else
           {
            m_r.Text(cx+S(4),cy+S(13),PC_Signed(ds.net),c,FS(11),TA_LEFT|TA_TOP,true);
            m_r.Text(cx+S(4),cy+S(27),PC_SignedPct(pct),c,FS(9),TA_LEFT|TA_TOP,false);
            if(ds.max_dd>0.0)
               m_r.Text(cx+cwid-S(4),cy+S(14),"-"+PC_Pct(ddp,1)+" DD",PC_CLR_RED,FS(9),TA_RIGHT|TA_TOP,false);

            //--- línea inferior: 1T 1G 0P WR:100%
            double wr=(ds.trades>0 ? 100.0*ds.wins/ds.trades : 0.0);
            string seg[4];
            color  segc[4];
            seg[0]=IntegerToString(ds.trades)+"T ";  segc[0]=PC_CLR_TEXT_DIM;
            seg[1]=IntegerToString(ds.wins)+"G ";    segc[1]=PC_CLR_GREEN;
            seg[2]=IntegerToString(ds.losses)+"P ";  segc[2]=PC_CLR_RED;
            seg[3]="WR:"+DoubleToString(wr,0)+"%";   segc[3]=PC_CLR_TEXT_DIM;
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
         Hit(cx,cy,cwid,ch,ACT_CAL_DAY,(long)d);
         wnet+=ds.net;
         wtrades+=ds.trades;
        }

      //--- total semanal
      if(wtrades>0)
        {
         color wc=PC_PnLColor(wnet);
         double wbal=m_data.BalanceAt((datetime)((long)MathMax((long)week_start,(long)month_start)-1));
         double wpct=(wbal>0 ? wnet/wbal*100.0 : 0.0);
         m_r.Box(totals_x,cy,tot_w,ch,PC_Mix(wc,PC_CLR_PANEL,0.9),wc);
         m_r.Text(totals_x+tot_w/2,cy+ch/2-S(7),PC_Signed(wnet),wc,FS(11),TA_CENTER|TA_VCENTER,true);
         m_r.Text(totals_x+tot_w/2,cy+ch/2+S(8),PC_Pct(wpct),wc,FS(9),TA_CENTER|TA_VCENTER,false);
        }
      else
         m_r.Box(totals_x,cy,tot_w,ch,PC_CLR_PANEL2,PC_CLR_BORDER);
     }
  }

//+------------------------------------------------------------------+
//| Popup con las operaciones de un día                                |
//+------------------------------------------------------------------+
void CPanel::DrawCalDayPopup()
  {
   datetime day=(datetime)m_popup_p1;
   SPosRecord recs[];
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
   string title=PC_DAYS_LONG[PC_WeekDay(day)]+" "+StringFormat("%02d.%02d.%d",dt.day,dt.mon,dt.year);
   PopupFrame(x,y,w,h,title);

   int ty=y+S(32);
   int lx=x+S(12);
   m_r.Text(lx,ty,StringFormat("Operaciones: %d   Ganadas: %d   Perdidas: %d",n,wins,losses),PC_CLR_TEXT,FS(10),TA_LEFT|TA_TOP,false);
   ty+=S(16);
   string s1="Beneficio neto: ";
   m_r.Text(lx,ty,s1,PC_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   m_r.Text(lx+m_r.TextWidth(s1,FS(10)),ty,PC_Signed(net)+" "+m_currency+"  ("+PC_SignedPct(pct)+")",PC_PnLColor(net),FS(10),TA_LEFT|TA_TOP,true);
   ty+=S(16);
   m_r.Text(lx,ty,StringFormat("Balance al inicio del día: %s %s",PC_Money(bal),m_currency),PC_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,false);
   ty+=S(18);

   if(max_rows>0)
     {
      m_r.HLine(lx,x+w-S(12),ty,PC_CLR_BORDER2);
      ty+=S(6);
      int c0=lx, c1=lx+S(64), c2=lx+S(150), c3=lx+S(210), c4=x+w-S(12);
      m_r.Text(c0,ty,"Cierre",PC_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c1,ty,"Símbolo",PC_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c2,ty,"Tipo",PC_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c3,ty,"Volumen",PC_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,true);
      m_r.Text(c4,ty,"Neto",PC_CLR_TEXT_MUTED,FS(9),TA_RIGHT|TA_TOP,true);
      ty+=S(14);
      for(int i=0; i<max_rows; i++)
        {
         SPosRecord r=recs[i];
         m_r.Text(c0,ty,TimeToString(r.close_time,TIME_SECONDS),PC_CLR_TEXT_DIM,FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c1,ty,m_r.Ellipsis(r.symbol,c2-c1-S(6),FS(9)),PC_CLR_TEXT,FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c2,ty,(r.type==0 ? "Compra" : "Venta"),(r.type==0 ? PC_CLR_GREEN : PC_CLR_RED),FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c3,ty,DoubleToString(r.vol_in,2),PC_CLR_TEXT_DIM,FS(9),TA_LEFT|TA_TOP,false);
         m_r.Text(c4,ty,PC_Signed(r.net),PC_PnLColor(r.net),FS(9),TA_RIGHT|TA_TOP,true);
         ty+=rowh;
        }
      if(n>max_rows)
         m_r.Text(lx,ty,StringFormat("... y %d operación(es) más",n-max_rows),PC_CLR_TEXT_MUTED,FS(9),TA_LEFT|TA_TOP,false);
     }
  }

#endif // PC_VIEWCALENDAR_MQH
