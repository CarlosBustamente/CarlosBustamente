//+------------------------------------------------------------------+
//|                                                    ViewArena.mqh |
//|        Panel de Control MT5 - Vista "Estadísticas Arena"          |
//+------------------------------------------------------------------+
#ifndef PC_VIEWARENA_MQH
#define PC_VIEWARENA_MQH

#include "Panel.mqh"

//+------------------------------------------------------------------+
void CPanel::DrawArenaView(const SRect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PC_CLR_PANEL,PC_CLR_BORDER);
   string title="Estadísticas Arena";
   m_r.Text(rc.x+S(10),rc.y+S(8),title,PC_CLR_BLUE_LIGHT,FS(13),TA_LEFT|TA_TOP,true);
   int tw=m_r.TextWidth(title,FS(13),true);
   int ix=rc.x+S(10)+tw+S(16), iy=rc.y+S(16);
   m_r.Circle(ix,iy,S(7),PC_CLR_BLUE);
   m_r.Text(ix,iy,"i",PC_CLR_WHITE,FS(9),TA_CENTER|TA_VCENTER,true);
   Hit(ix-S(8),iy-S(8),S(16),S(16),ACT_INFO,1);

   int bh=S(18), by=rc.y+S(7), bw=S(72);
   int x=rc.x+rc.w-S(10)-bw;
   Button(x,by,bw,bh,"Avanzado",m_arena_advanced,ACT_ARENA_VIEW,1,0,10);
   x-=bw+S(4);
   Button(x,by,bw,bh,"Resumen",!m_arena_advanced,ACT_ARENA_VIEW,0,0,10);

   SRect body;
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
void CPanel::DrawArenaOverview(const SRect &rc)
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
   color  s_clr=(sharpe<1.0 ? PC_CLR_RED : (sharpe<2.0 ? PC_CLR_ORANGE : PC_CLR_GREEN));

   double pf=m_stats.profit_factor;
   string p_rating=(pf<1.0 ? "Pobre" : (pf<1.5 ? "Aceptable" : (pf<2.0 ? "Bueno" : "Excelente")));
   color  p_clr=(pf<1.0 ? PC_CLR_RED : (pf<1.5 ? PC_CLR_ORANGE : PC_CLR_GREEN));

   double dd=m_stats.max_dd_pct;
   string d_rating=(dd<5.0 ? "Excelente" : (dd<10.0 ? "Aceptable" : (dd<15.0 ? "Alto" : "Crítico")));
   color  d_clr=(dd<5.0 ? PC_CLR_GREEN : (dd<10.0 ? PC_CLR_ORANGE : PC_CLR_RED));

   //--- fila 1: barras
   int y=rc.y;
   double sb[2]={1.0,2.0};
   color  sc[3]={PC_CLR_RED,PC_CLR_YELLOW,PC_CLR_GREEN};
   string st[4]={"0","1","2","3"};
   ArenaBarCard(rc.x,y,cw,row1_h,"Ratio de Sharpe",DoubleToString(sharpe,2),s_clr,s_clr,sharpe,0.0,3.0,sb,sc,s_rating,st);

   double pb[2]={1.0,1.5};
   string pt[4]={"0","1","1.5","3"};
   ArenaBarCard(rc.x+cw+gap,y,cw,row1_h,"Factor de Beneficio",DoubleToString(pf,2),p_clr,p_clr,pf,0.0,3.0,pb,sc,p_rating,pt);

   double db[2]={5.0,10.0};
   color  dc[3]={PC_CLR_GREEN,PC_CLR_YELLOW,PC_CLR_RED};
   string dt[4]={"0%","5%","10%","15%"};
   ArenaBarCard(rc.x+2*(cw+gap),y,rc.w-2*(cw+gap),row1_h,"Drawdown Máximo","Equity: "+PC_Pct(dd,1),d_clr,d_clr,dd,0.0,15.0,db,dc,d_rating,dt);

   //--- fila 2: medidores
   y+=row1_h+gap;
   ArenaGaugeCard(rc.x,y,cw,row2_h,"Puntuación de Disciplina",m_stats.discipline);
   ArenaGaugeCard(rc.x+cw+gap,y,cw,row2_h,"Eficiencia de Operación",m_stats.efficiency);

   double mr=m_stats.mistake_rate;
   string m_rating=(mr<5.0 ? "Enfocado" : (mr<10.0 ? "Aceptable" : (mr<20.0 ? "Descuidado" : "Crítico")));
   color  m_clr=(mr<5.0 ? PC_CLR_GREEN : (mr<10.0 ? PC_CLR_ORANGE : PC_CLR_RED));
   int mx=rc.x+2*(cw+gap), mw=rc.w-2*(cw+gap);
   m_r.Box(mx,y,mw,row2_h,PC_CLR_PANEL2,m_clr);
   m_r.Text(mx+mw/2,y+S(8),"Tasa de Errores",PC_CLR_TEXT_DIM,FS(11),TA_CENTER|TA_TOP,true);
   m_r.Text(mx+mw/2,y+row2_h/2,PC_Pct(mr,1),m_clr,FS(20),TA_CENTER|TA_VCENTER,true);
   m_r.Text(mx+mw/2,y+row2_h-S(8),m_rating,PC_CLR_TEXT_MUTED,FS(10),TA_CENTER|TA_BOTTOM,false);

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
     { ArrayResize(flags,nf+1); flags[nf++]=StringFormat("- Tasa de acierto baja (%s). Revisa los criterios de entrada.",PC_Pct(m_stats.win_rate,1)); }
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
     { ArrayResize(good,ng+1); good[ng++]=StringFormat("- Buena tasa de acierto (%s). Tu ventaja se está mostrando.",PC_Pct(m_stats.win_rate,1)); }
   if(m_stats.payoff>=1.5 && m_stats.losses>0)
     { ArrayResize(good,ng+1); good[ng++]=StringFormat("- Excelente relación ganancia/pérdida (%.2f). Dejas correr los beneficios con disciplina.",m_stats.payoff); }
   if(m_stats.profit_factor>=1.5)
     { ArrayResize(good,ng+1); good[ng++]=StringFormat("- Factor de beneficio sólido (%.2f).",m_stats.profit_factor); }
   if(m_stats.revenge_trades==0 && m_stats.trades>=5)
     { ArrayResize(good,ng+1); good[ng++]="- Sin revenge trading: respetas el tiempo de enfriamiento tras las pérdidas."; }
   if(m_stats.max_dd_pct<5.0)
     { ArrayResize(good,ng+1); good[ng++]=StringFormat("- Drawdown contenido (%s).",PC_Pct(m_stats.max_dd_pct,1)); }
   if(ng==0) { ArrayResize(good,1); good[0]="- Sin aspectos destacables todavía. Sigue acumulando operaciones."; }

   ArenaTextCard(rc.x,y,hw,row4_h,"Alertas de Rendimiento",PC_CLR_RED,flags);
   ArenaTextCard(rc.x+hw+gap,y,rc.w-hw-gap,row4_h,"Aspectos Positivos",PC_CLR_GREEN,good);
  }

//+------------------------------------------------------------------+
//| Tarjeta con barra segmentada y marcador                            |
//+------------------------------------------------------------------+
void CPanel::ArenaBarCard(const int x,const int y,const int w,const int h,const string title,const string value,
                          const color value_clr,const color frame,const double v,const double vmin,const double vmax,
                          const double &bounds[],const color &clrs[],const string rating,const string &ticks[])
  {
   m_r.Box(x,y,w,h,PC_CLR_PANEL2,frame);
   m_r.Text(x+w/2,y+S(5),title,PC_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_TOP,false);
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
      color c=(i<ArraySize(clrs) ? clrs[i] : PC_CLR_GREEN);
      m_r.Fill(x1,by,MathMax(1,x2-x1),bh,PC_Mix(c,PC_CLR_PANEL2,0.15));
      prev=next;
     }
   double cv=MathMax(vmin,MathMin(vmax,v));
   int mxp=bx+(int)MathRound(bw*(cv-vmin)/range);
   m_r.Fill(mxp-1,by-S(2),S(2),bh+S(4),PC_CLR_WHITE);

   int nt=ArraySize(ticks);
   for(int i=0; i<nt; i++)
     {
      int tx=bx+(int)MathRound(bw*(double)i/(nt-1));
      uint al=(i==0 ? TA_LEFT : (i==nt-1 ? TA_RIGHT : TA_CENTER));
      m_r.Text(tx,by+bh+S(2),ticks[i],PC_CLR_TEXT_MUTED,FS(8),al|TA_TOP,false);
     }
   m_r.Text(x+w/2,y+h-S(4),rating,PC_CLR_TEXT_DIM,FS(9),TA_CENTER|TA_BOTTOM,false);
  }

//+------------------------------------------------------------------+
//| Tarjeta con medidor semicircular 0-100                             |
//+------------------------------------------------------------------+
void CPanel::ArenaGaugeCard(const int x,const int y,const int w,const int h,const string title,const double score)
  {
   m_r.Box(x,y,w,h,PC_CLR_PANEL2,PC_CLR_BORDER);
   m_r.Text(x+w/2,y+S(5),title,PC_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_TOP,false);
   double sc=MathMax(0.0,MathMin(100.0,score));
   color c=(sc<50.0 ? PC_CLR_RED : (sc<75.0 ? PC_CLR_ORANGE : PC_CLR_GREEN));
   int r_out=MathMin(S(52),h-S(34));
   int r_in=MathMax(S(6),r_out-MathMax(S(7),r_out/5));
   int cx=x+w/2, cy=y+h-S(14);
   m_r.Ring(cx,cy,r_out,r_in,0.0,180.0,PC_CLR_PANEL3);
   if(sc>0.0) m_r.Ring(cx,cy,r_out,r_in,180.0-180.0*sc/100.0,180.0,c);
   m_r.Text(cx,cy-S(3),IntegerToString((int)MathRound(sc)),PC_CLR_WHITE,FS(MathMax(15,r_out/2)),TA_CENTER|TA_BOTTOM,true);
   m_r.Text(cx,cy+S(1),"/100",PC_CLR_TEXT_MUTED,FS(9),TA_CENTER|TA_TOP,false);
  }

//+------------------------------------------------------------------+
//| Tarjeta de texto con título coloreado y líneas ajustadas           |
//+------------------------------------------------------------------+
void CPanel::ArenaTextCard(const int x,const int y,const int w,const int h,const string title,const color frame,const string &lines[])
  {
   m_r.Box(x,y,w,h,PC_CLR_PANEL2,frame);
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
         m_r.Text(x+S(10),ty,wrapped[j],PC_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
         ty+=lh;
        }
     }
  }

//+------------------------------------------------------------------+
//| Vista avanzada: tabla de métricas                                  |
//+------------------------------------------------------------------+
void CPanel::MetricRow(const int x,const int y,const int w,const string label,const string value,const color clr)
  {
   m_r.Text(x+S(8),y,label,PC_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
   m_r.Text(x+w-S(8),y,value,clr,FS(10),TA_RIGHT|TA_TOP,true);
  }

void CPanel::DrawArenaAdvanced(const SRect &rc)
  {
   SStats s=m_stats;
   string labels[];
   string values[];
   color  colors[];
   int n=0;
#define PC_ADD(l,v,c) { ArrayResize(labels,n+1); ArrayResize(values,n+1); ArrayResize(colors,n+1); labels[n]=(l); values[n]=(v); colors[n]=(c); n++; }

   PC_ADD("Beneficio neto",PC_Signed(s.net)+" "+m_currency,PC_PnLColor(s.net));
   PC_ADD("Beneficio bruto",PC_Money(s.gross_win),PC_CLR_GREEN);
   PC_ADD("Pérdida bruta",PC_Money(s.gross_loss),PC_CLR_RED);
   PC_ADD("Factor de beneficio",DoubleToString(s.profit_factor,2),(s.profit_factor>=1.5 ? PC_CLR_GREEN : (s.profit_factor>=1.0 ? PC_CLR_ORANGE : PC_CLR_RED)));
   PC_ADD("Expectativa por operación",PC_Signed(s.expectancy),PC_PnLColor(s.expectancy));
   PC_ADD("Ganancia media",PC_Money(s.avg_win),PC_CLR_GREEN);
   PC_ADD("Pérdida media",PC_Money(s.avg_loss),PC_CLR_RED);
   PC_ADD("Ratio ganancia/pérdida",DoubleToString(s.payoff,2),(s.payoff>=1.0 ? PC_CLR_GREEN : PC_CLR_ORANGE));
   PC_ADD("Mayor ganancia",PC_Money(s.largest_win),PC_CLR_GREEN);
   PC_ADD("Mayor pérdida",PC_Money(s.largest_loss),PC_CLR_RED);
   PC_ADD("Racha máx. ganadora",IntegerToString(s.max_consec_wins),PC_CLR_TEXT);
   PC_ADD("Racha máx. perdedora",IntegerToString(s.max_consec_losses),PC_CLR_TEXT);
   PC_ADD("Drawdown máximo",PC_Money(s.max_dd_money)+" "+m_currency+" ("+PC_Pct(s.max_dd_pct,2)+")",PC_CLR_RED);
   PC_ADD("Factor de recuperación",DoubleToString(s.recovery_factor,2),(s.recovery_factor>=2.0 ? PC_CLR_GREEN : PC_CLR_TEXT));
   PC_ADD("Ratio de Sharpe (por op.)",DoubleToString(s.sharpe,2),(s.sharpe>=1.0 ? PC_CLR_GREEN : PC_CLR_TEXT));
   PC_ADD("Desv. típica del P&L",PC_Money(s.std_dev),PC_CLR_TEXT);
   PC_ADD("Criterio de Kelly",PC_Pct(s.kelly,1),(s.kelly>0 ? PC_CLR_GREEN : PC_CLR_RED));
   PC_ADD("Duración media",PC_Duration(s.avg_duration),PC_CLR_TEXT);
   PC_ADD("Días operados",IntegerToString(s.trading_days),PC_CLR_TEXT);
   PC_ADD("Operaciones por día",DoubleToString(s.avg_trades_day,2),(s.avg_trades_day>m_set.max_trades_day ? PC_CLR_ORANGE : PC_CLR_TEXT));
   PC_ADD("Mejor día",PC_Signed(s.best_day)+"  ("+PC_DateStr(s.best_day_date)+")",PC_CLR_GREEN);
   PC_ADD("Peor día",PC_Signed(s.worst_day)+"  ("+PC_DateStr(s.worst_day_date)+")",PC_CLR_RED);
   double lwr=(s.long_trades>0 ? 100.0*s.long_wins/s.long_trades : 0.0);
   double swr=(s.short_trades>0 ? 100.0*s.short_wins/s.short_trades : 0.0);
   PC_ADD("Compras",StringFormat("%d ops · WR %s · %s",s.long_trades,PC_Pct(lwr,1),PC_Signed(s.long_net)),PC_PnLColor(s.long_net));
   PC_ADD("Ventas",StringFormat("%d ops · WR %s · %s",s.short_trades,PC_Pct(swr,1),PC_Signed(s.short_net)),PC_PnLColor(s.short_net));
   PC_ADD("Volumen total",DoubleToString(s.volume,2)+" lotes",PC_CLR_TEXT);
   PC_ADD("Swap total",PC_Money(s.swap,3),PC_PnLColor(s.swap));
   PC_ADD("Comisión total",PC_Money(s.commission,3),PC_PnLColor(s.commission));
   PC_ADD("Balance inicial del período",PC_Money(s.start_balance)+" "+m_currency,PC_CLR_TEXT);
   PC_ADD("Violaciones de stop",IntegerToString(s.sl_violations),(s.sl_violations>0 ? PC_CLR_RED : PC_CLR_GREEN));
   PC_ADD("Revenge trades",IntegerToString(s.revenge_trades),(s.revenge_trades>0 ? PC_CLR_RED : PC_CLR_GREEN));
   PC_ADD("Días con sobre-trading",IntegerToString(s.overtrading_days),(s.overtrading_days>0 ? PC_CLR_ORANGE : PC_CLR_GREEN));
   PC_ADD("Puntuación de disciplina",DoubleToString(s.discipline,0)+" / 100",(s.discipline>=75 ? PC_CLR_GREEN : (s.discipline>=50 ? PC_CLR_ORANGE : PC_CLR_RED)));
   PC_ADD("Eficiencia de operación",DoubleToString(s.efficiency,0)+" / 100",(s.efficiency>=75 ? PC_CLR_GREEN : (s.efficiency>=50 ? PC_CLR_ORANGE : PC_CLR_RED)));
   PC_ADD("Tasa de errores",PC_Pct(s.mistake_rate,1),(s.mistake_rate<5 ? PC_CLR_GREEN : (s.mistake_rate<10 ? PC_CLR_ORANGE : PC_CLR_RED)));
#undef PC_ADD

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
      m_r.Box(cx,rc.y,cw,count*rowh+S(6),PC_CLR_PANEL2,PC_CLR_BORDER);
      for(int k=0; k<count; k++)
        {
         int i=c*rows_fit+k;
         int ry=rc.y+S(3)+k*rowh;
         if((k%2)==1) m_r.Fill(cx+1,ry,cw-2,rowh,PC_Mix(PC_CLR_PANEL2,PC_CLR_PANEL3,0.5));
         MetricRow(cx,ry+(rowh-m_r.TextHeight(FS(10)))/2,cw,labels[i],values[i],colors[i]);
        }
     }
  }

#endif // PC_VIEWARENA_MQH
