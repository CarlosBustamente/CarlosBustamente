//+------------------------------------------------------------------+
//|                                             ViewTransactions.mqh |
//|        Panel de Control MT5 - Vista "Transacciones" (tabla)       |
//+------------------------------------------------------------------+
#ifndef PC_VIEWTRANSACTIONS_MQH
#define PC_VIEWTRANSACTIONS_MQH

#include "Panel.mqh"

//+------------------------------------------------------------------+
void CPanel::DrawTransactionsView(const SRect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PC_CLR_PANEL,PC_CLR_BORDER);
   m_r.Text(rc.x+S(10),rc.y+S(8),"Historial de Transacciones",PC_CLR_TEXT,FS(13),TA_LEFT|TA_TOP,true);

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
   Button(nx,rc.y+S(7),nav,nav,">",false,ACT_TX_NEXT,0,0,10);
   string pg=StringFormat("%d / %d",m_tx_page+1,m_tx_pages);
   int pw=m_r.TextWidth(pg,FS(10))+S(12);
   nx-=pw;
   m_r.Text(nx+pw/2,rc.y+S(7)+nav/2,pg,PC_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,false);
   nx-=nav;
   Button(nx,rc.y+S(7),nav,nav,"<",false,ACT_TX_PREV,0,0,10);

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
   m_r.Fill(tx,table_y,tw,rowh,PC_CLR_PANEL3);
   for(int c=0; c<8; c++)
      m_r.Text((colx[c]+colx[c+1])/2,table_y+rowh/2,names[c],PC_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,true);

   //--- filas (más recientes primero)
   int start=m_tx_page*rows;
   for(int k=0; k<rows; k++)
     {
      int idx=n-1-(start+k);
      if(idx<0) break;
      int ry=table_y+rowh*(k+1);
      if((k%2)==1) m_r.Fill(tx,ry,tw,rowh,PC_Mix(PC_CLR_PANEL,PC_CLR_PANEL2,0.6));
      SPosRecord r=m_recs[idx];
      int cy=ry+rowh/2;
      color tc=(r.type==0 ? PC_CLR_GREEN : PC_CLR_RED);
      m_r.Text((colx[0]+colx[1])/2,cy,m_r.Ellipsis(r.symbol,colx[1]-colx[0]-S(6),FS(10)),PC_CLR_TEXT,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[1]+colx[2])/2,cy,(r.type==0 ? "Compra" : "Venta"),tc,FS(10),TA_CENTER|TA_VCENTER,true);
      m_r.Text((colx[2]+colx[3])/2,cy,IntegerToString(r.magic),PC_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[3]+colx[4])/2,cy,DoubleToString(r.vol_in,2),PC_CLR_TEXT,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[4]+colx[5])/2,cy,PC_DateTimeStr(r.open_time),PC_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[5]+colx[6])/2,cy,PC_DateTimeStr(r.close_time),PC_CLR_TEXT_DIM,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[6]+colx[7])/2,cy,PC_Duration((long)r.close_time-(long)r.open_time),PC_CLR_TEXT_MUTED,FS(10),TA_CENTER|TA_VCENTER,false);
      m_r.Text((colx[7]+colx[8])/2,cy,PC_Signed(r.net)+" "+m_currency,PC_PnLColor(r.net),FS(10),TA_CENTER|TA_VCENTER,true);
     }
   m_r.Frame(tx,table_y,tw,rowh*(rows+1),PC_CLR_BORDER);

   //--- pie con totales
   int fy=rc.y+rc.h-footer_h-S(4);
   m_r.HLine(tx,tx+tw-1,fy,PC_CLR_BORDER2);
   string foot=StringFormat("%d operaciones  ·  Volumen: %s lotes  ·  Neto: ",n,DoubleToString(m_stats.volume,2));
   int fw=m_r.TextWidth(foot,FS(10));
   m_r.Text(tx,fy+footer_h/2,foot,PC_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_VCENTER,false);
   m_r.Text(tx+fw,fy+footer_h/2,PC_Signed(m_stats.net)+" "+m_currency,PC_PnLColor(m_stats.net),FS(10),TA_LEFT|TA_VCENTER,true);
   string right=StringFormat("Mostrando %d - %d",start+1,MathMin(n,start+rows));
   m_r.Text(tx+tw,fy+footer_h/2,right,PC_CLR_TEXT_MUTED,FS(10),TA_RIGHT|TA_VCENTER,false);
  }

#endif // PC_VIEWTRANSACTIONS_MQH
