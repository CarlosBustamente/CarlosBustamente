//+------------------------------------------------------------------+
//|                                                        Panel.mqh |
//|     Panel de Control MT5 - Núcleo de la interfaz (CPanel)         |
//+------------------------------------------------------------------+
#ifndef PC_PANEL_MQH
#define PC_PANEL_MQH

#include "Config.mqh"
#include "Render.mqh"
#include "TradeData.mqh"

struct SRect
  {
   int               x;
   int               y;
   int               w;
   int               h;
  };

struct SHit
  {
   int               x1;
   int               y1;
   int               x2;
   int               y2;
   int               action;
   long              p1;
   long              p2;
  };

struct SPanelSettings
  {
   string            font;
   double            scale;
   bool              start_maximized;
   int               x;
   int               y;
   int               w;
   int               h;
   double            daily_loss_limit;
   double            max_dd_pct;
   int               max_trades_day;
   int               revenge_minutes;
   double            sl_factor;
   int               refresh_ms;
   bool              demo_data;
   bool              clean_chart;
  };

//+------------------------------------------------------------------+
//| CPanel                                                            |
//+------------------------------------------------------------------+
class CPanel
  {
private:
   CRender           m_r;
   CTradeData        m_data;
   SPanelSettings    m_set;
   string            m_currency;

   //--- estado de la interfaz
   ENUM_PC_RANGE     m_range;
   ENUM_PC_TAB       m_tab;
   ENUM_PC_FTAB      m_ftab;
   bool              m_minimized;
   bool              m_maximized;
   int               m_cal_year;
   int               m_cal_month;
   ENUM_PC_HOUR_MODE m_hour_mode;
   bool              m_hour_by_close;
   bool              m_arena_advanced;
   int               m_tx_page;
   int               m_tx_pages;
   int               m_filter_scroll;
   datetime          m_custom_from;
   datetime          m_custom_to;

   //--- ventana emergente
   ENUM_PC_POPUP     m_popup;
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
   SHit              m_hits[];
   int               m_hit_count;

   //--- geometría calculada en cada Draw
   SRect             m_rc_filter;
   SRect             m_rc_content;
   SRect             m_rc_plot;
   int               m_plot_points;

   //--- datos calculados en cada Draw
   SPosRecord        m_recs[];
   SStats            m_stats;

   //--- refresco
   bool              m_reload_pending;
   uint              m_reload_due;
   double            m_last_equity;
   double            m_last_balance;

   //--- utilidades
   int               S(const int v) const { return((int)MathRound(v*m_set.scale)); }
   int               FS(const int v) const { return(MathMax(7,(int)MathRound(v*m_set.scale))); }
   void              Hit(const int x,const int y,const int w,const int h,const int action,const long p1=0,const long p2=0);
   bool              InRect(const SRect &rc,const int x,const int y) const { return(x>=rc.x && x<rc.x+rc.w && y>=rc.y && y<rc.y+rc.h); }
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
                              const double bar_ratio,const bool has_bar);
   void              DrawTabs(const int y,const int h);
   void              DrawFilterPanel(const SRect &rc);
   void              DrawContent(const SRect &rc);
   void              DrawEmpty(const SRect &rc,const string msg);

   //--- ventanas emergentes
   void              DrawPopups();
   void              PopupFrame(const int x,const int y,const int w,const int h,const string title);
   void              DrawDatePicker();
   void              DrawInfoPopup(const int kind);
   void              DrawHourCellPopup();
   void              DrawCalDayPopup();

   //--- vistas (definidas en View*.mqh)
   void              DrawChartView(const SRect &rc);
   void              DrawTransactionsView(const SRect &rc);
   void              DrawCalendarView(const SRect &rc);
   void              DrawHourlyView(const SRect &rc);
   void              DrawArenaView(const SRect &rc);
   void              DrawArenaOverview(const SRect &rc);
   void              DrawArenaAdvanced(const SRect &rc);
   void              ArenaBarCard(const int x,const int y,const int w,const int h,const string title,const string value,
                                  const color value_clr,const color frame,const double v,const double vmin,const double vmax,
                                  const double &bounds[],const color &clrs[],const string rating,const string &ticks[]);
   void              ArenaGaugeCard(const int x,const int y,const int w,const int h,const string title,const double score);
   void              ArenaTextCard(const int x,const int y,const int w,const int h,const string title,const color frame,const string &lines[]);
   void              MetricRow(const int x,const int y,const int w,const string label,const string value,const color clr);

public:
                     CPanel();
                    ~CPanel();

   bool              Init(const SPanelSettings &settings);
   void              Deinit();
   void              OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   void              OnTimer();
   void              OnTradeEvent();
   void              Redraw() { Draw(); }
  };

//+------------------------------------------------------------------+
CPanel::CPanel() : m_currency("USD"),m_range(RANGE_ALL),m_tab(TAB_CHART),m_ftab(FTAB_SYMBOL),
                   m_minimized(false),m_maximized(true),m_cal_year(2025),m_cal_month(1),
                   m_hour_mode(HOUR_BOTH),m_hour_by_close(true),m_arena_advanced(false),
                   m_tx_page(0),m_tx_pages(1),m_filter_scroll(0),m_custom_from(0),m_custom_to(0),
                   m_popup(POPUP_NONE),m_popup_p1(0),m_popup_p2(0),m_dp_view(0),m_dp_stage(0),
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
CPanel::~CPanel()
  {
  }

//+------------------------------------------------------------------+
bool CPanel::Init(const SPanelSettings &settings)
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
   m_dp_view=PC_MonthStart(TimeCurrent());
   m_custom_from=PC_MonthStart(TimeCurrent());
   m_custom_to=PC_DayStart(TimeCurrent());

   m_chart_scroll_orig=(bool)ChartGetInteger(0,CHART_MOUSE_SCROLL);
   m_oneclick_orig=(bool)ChartGetInteger(0,CHART_SHOW_ONE_CLICK);
   m_price_scale_orig=(bool)ChartGetInteger(0,CHART_SHOW_PRICE_SCALE);
   m_date_scale_orig=(bool)ChartGetInteger(0,CHART_SHOW_DATE_SCALE);
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,true);
   ChartSetInteger(0,CHART_EVENT_MOUSE_WHEEL,true);

   string name=StringFormat("PC_STATS_%I64d",ChartID());
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
void CPanel::Deinit()
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
void CPanel::ApplyChartMode()
  {
   if(!m_set.clean_chart) return;
   bool full=(m_maximized && !m_minimized);
   ChartSetInteger(0,CHART_SHOW_ONE_CLICK,false);
   ChartSetInteger(0,CHART_SHOW_PRICE_SCALE,(full ? false : m_price_scale_orig));
   ChartSetInteger(0,CHART_SHOW_DATE_SCALE,(full ? false : m_date_scale_orig));
  }

//+------------------------------------------------------------------+
void CPanel::ApplyGeometry()
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
void CPanel::UpdateRange()
  {
   datetime now=TimeCurrent();
   datetime from=0, to=D'2100.01.01';
   switch(m_range)
     {
      case RANGE_TODAY:
         from=PC_DayStart(now);
         to=(datetime)((long)from+86399);
         break;
      case RANGE_WEEK:
         from=PC_WeekStart(now);
         to=(datetime)((long)from+7*86400-1);
         break;
      case RANGE_MONTH:
        {
         from=PC_MonthStart(now);
         MqlDateTime dt; TimeToStruct(from,dt);
         int ny=dt.year, nm=dt.mon+1; if(nm>12) { nm=1; ny++; }
         to=(datetime)((long)PC_MakeDate(ny,nm,1)-1);
         break;
        }
      case RANGE_CUSTOM:
         from=PC_DayStart(m_custom_from);
         to=(datetime)((long)PC_DayStart(m_custom_to)+86399);
         break;
      default:
         break;
     }
   m_data.SetRange(from,to);
   m_data.ApplyFilter();
   m_tx_page=0;
  }

//+------------------------------------------------------------------+
void CPanel::RefreshData()
  {
   m_data.GetFiltered(m_recs);
   m_data.ComputeStats(m_recs,m_stats);
  }

//+------------------------------------------------------------------+
void CPanel::Hit(const int x,const int y,const int w,const int h,const int action,const long p1,const long p2)
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
void CPanel::Button(const int x,const int y,const int w,const int h,const string txt,const bool active,const int action,const long p1,const long p2,const int fs)
  {
   m_r.Box(x,y,w,h,(active ? PC_CLR_BLUE : PC_CLR_BTN),(active ? PC_CLR_BLUE_LIGHT : PC_CLR_BORDER2));
   m_r.Text(x+w/2,y+h/2,txt,(active ? PC_CLR_WHITE : PC_CLR_TEXT),FS(fs),TA_CENTER|TA_VCENTER,active);
   Hit(x,y,w,h,action,p1,p2);
  }

//+------------------------------------------------------------------+
//| Dibujo completo                                                   |
//+------------------------------------------------------------------+
void CPanel::Draw()
  {
   if(!m_r.IsCreated()) return;
   m_hit_count=0;
   RefreshData();

   int W=m_r.Width(), H=m_r.Height();
   m_r.Clear(PC_CLR_BG);
   m_r.Frame(0,0,W,H,PC_CLR_BORDER);
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
void CPanel::DrawHeader()
  {
   int W=m_r.Width();
   int h=S(30);
   int pad=S(10);
   m_r.Text(pad,h/2,"Estadísticas",PC_CLR_BLUE_LIGHT,FS(16),TA_LEFT|TA_VCENTER,true);
   int tw=m_r.TextWidth("Estadísticas",FS(16),true);
   string acc=StringFormat("Cuenta %I64d · %s",AccountInfoInteger(ACCOUNT_LOGIN),m_currency);
   if(m_data.DemoMode()) acc="DATOS DE EJEMPLO · "+m_currency;
   m_r.Text(pad+tw+S(12),h/2+S(1),acc,PC_CLR_TEXT_MUTED,FS(10),TA_LEFT|TA_VCENTER,false);

   int bh=S(18), gap=S(4);
   int by=(h-bh)/2;
   int x=W-pad;

   //--- minimizar / maximizar
   int sq=S(20);
   x-=sq;
   Button(x,by,sq,bh,(m_minimized ? "▼" : "—"),m_minimized,ACT_MINIMIZE,0,0,11);
   x-=gap+sq;
   Button(x,by,sq,bh,"□",m_maximized,ACT_MAXIMIZE,0,0,12);
   x-=S(10);

   if(m_minimized)
     {
      //--- resumen compacto
      string sum=StringFormat("P&L: %s %s   Ops: %d   WR: %s",PC_Signed(m_stats.net),m_currency,m_stats.trades,PC_Pct(m_stats.win_rate,1));
      m_r.Text(x,h/2,sum,PC_CLR_TEXT_DIM,FS(11),TA_RIGHT|TA_VCENTER,false);
      return;
     }

   for(int i=4; i>=0; i--)
     {
      int w=MathMax(S(44),m_r.TextWidth(PC_RANGE_NAMES[i],FS(11),true)+S(14));
      x-=w;
      Button(x,by,w,bh,PC_RANGE_NAMES[i],(m_range==i),ACT_RANGE,i,0,11);
      x-=gap;
     }
  }

//+------------------------------------------------------------------+
void CPanel::DrawCards(const int y,const int h)
  {
   int W=m_r.Width();
   int pad=S(10), gap=S(8);
   int cw=(W-2*pad-5*gap)/6;
   if(cw<S(60)) cw=S(60);
   int x=pad;

   //--- 1. P&L Total
   string v1=PC_Money(m_stats.net)+" "+m_currency;
   string s1=StringFormat("G: %s | P: %s",PC_Money(m_stats.gross_win),PC_Money(m_stats.gross_loss));
   DrawCard(x,y,cw,h,"P&L Total",PC_CLR_TEXT_DIM,v1,PC_PnLColor(m_stats.net),s1,PC_CLR_TEXT_MUTED,0,false);
   x+=cw+gap;

   //--- 2. Límite diario (prop)
   SPosRecord today[];
   datetime ds=PC_DayStart(TimeCurrent());
   m_data.CollectInRange(ds,(datetime)((long)ds+86399),today);
   double today_closed=0;
   for(int i=0; i<ArraySize(today); i++) today_closed+=today[i].net;
   double floating=(m_data.DemoMode() ? 0.0 : AccountInfoDouble(ACCOUNT_PROFIT));
   double today_pnl=today_closed+floating;
   double limit=MathMax(0.0,m_set.daily_loss_limit);
   double used=(limit>0 ? MathMin(1.0,MathMax(0.0,-today_pnl)/limit) : 0.0);
   double remaining=(limit>0 ? MathMax(0.0,limit+MathMin(0.0,today_pnl)) : 0.0);
   string v2=PC_Signed(today_pnl)+" "+m_currency;
   string s2=(limit>0 ? "Restante: "+PC_Money(remaining) : "Sin límite configurado");
   color c2=(today_pnl<0 ? (used>0.8 ? PC_CLR_RED : PC_CLR_ORANGE) : (today_pnl>0 ? PC_CLR_GREEN : PC_CLR_ORANGE));
   DrawCard(x,y,cw,h,"Límite Diario Prop",PC_CLR_CYAN,v2,c2,s2,PC_CLR_TEXT_MUTED,used,limit>0);
   x+=cw+gap;

   //--- 3. DD de Equity
   double balance=(m_data.DemoMode() ? m_data.CurrentBalance() : AccountInfoDouble(ACCOUNT_BALANCE));
   double equity=(m_data.DemoMode() ? balance-floating : AccountInfoDouble(ACCOUNT_EQUITY));
   double eq_dd=MathMax(0.0,balance-equity);
   double eq_pct=(balance>0 ? eq_dd/balance*100.0 : 0.0);
   string v3=PC_Money(eq_dd)+" "+m_currency;
   DrawCard(x,y,cw,h,"DD de Equity",PC_CLR_TEXT_DIM,v3,(eq_dd>0 ? PC_CLR_RED : PC_CLR_GREEN),"("+PC_Pct(eq_pct)+")",PC_CLR_TEXT_MUTED,0,false);
   x+=cw+gap;

   //--- 4. Operaciones / WR
   string v4=StringFormat("%d (%s)",m_stats.trades,PC_Pct(m_stats.win_rate,1));
   string s4=StringFormat("G: %d | P: %d",m_stats.wins,m_stats.losses);
   DrawCard(x,y,cw,h,"Operaciones / WR",PC_CLR_TEXT_DIM,v4,PC_CLR_WHITE,s4,PC_CLR_TEXT_MUTED,0,false);
   x+=cw+gap;

   //--- 5. DD desde máximo histórico
   double hwm=m_data.HighWatermark();
   double hwm_dd=MathMax(0.0,hwm-balance);
   double allowed=(m_set.max_dd_pct>0 ? hwm*m_set.max_dd_pct/100.0 : 0.0);
   double hwm_used=(allowed>0 ? MathMin(1.0,hwm_dd/allowed) : 0.0);
   string v5=PC_Money(hwm_dd)+" "+m_currency;
   string s5=(allowed>0 ? "Usado: "+PC_Pct(hwm_used*100.0,1) : "Máx: "+PC_Money(hwm));
   DrawCard(x,y,cw,h,"DD Máximo Histórico",PC_CLR_PURPLE,v5,(hwm_dd>0 ? PC_CLR_RED : PC_CLR_GREEN),s5,PC_CLR_TEXT_MUTED,hwm_used,allowed>0);
   x+=cw+gap;

   //--- 6. Swap y Comisión (dos líneas)
   int last_w=W-pad-x;
   if(last_w<cw) last_w=cw;
   m_r.Box(x,y,last_w,h,PC_CLR_PANEL,PC_CLR_BORDER);
   m_r.Text(x+last_w/2,y+S(5),"Swap y Comisión",PC_CLR_TEXT_DIM,FS(11),TA_CENTER|TA_TOP,true);
   m_r.Text(x+last_w/2,y+S(21),"Swap: "+PC_Money(m_stats.swap,3),PC_PnLColor(m_stats.swap),FS(11),TA_CENTER|TA_TOP,true);
   m_r.Text(x+last_w/2,y+S(35),"Com.: "+PC_Money(m_stats.commission,3),PC_PnLColor(m_stats.commission),FS(11),TA_CENTER|TA_TOP,true);
  }

//+------------------------------------------------------------------+
void CPanel::DrawCard(const int x,const int y,const int w,const int h,const string title,const color title_clr,
                      const string value,const color value_clr,const string sub,const color sub_clr,
                      const double bar_ratio,const bool has_bar)
  {
   m_r.Box(x,y,w,h,PC_CLR_PANEL,PC_CLR_BORDER);
   m_r.Text(x+w/2,y+S(5),title,title_clr,FS(11),TA_CENTER|TA_TOP,true);
   m_r.Text(x+w/2,y+S(18),value,value_clr,FS(16),TA_CENTER|TA_TOP,true);
   m_r.Text(x+w/2,y+S(38),sub,sub_clr,FS(9),TA_CENTER|TA_TOP,false);
   if(has_bar)
     {
      int bx=x+S(6), bw=w-S(12), by=y+h-S(5), bh=S(2);
      m_r.Fill(bx,by,bw,bh,PC_CLR_BORDER2);
      color bc=(bar_ratio<0.5 ? PC_CLR_GREEN : (bar_ratio<0.8 ? PC_CLR_ORANGE : PC_CLR_RED));
      int fwid=(int)MathRound(bw*MathMax(0.0,MathMin(1.0,bar_ratio)));
      if(fwid>0) m_r.Fill(bx,by,fwid,bh,bc);
     }
  }

//+------------------------------------------------------------------+
void CPanel::DrawTabs(const int y,const int h)
  {
   int pad=S(10), gap=S(4);
   int x=pad;
   for(int i=0; i<5; i++)
     {
      int w=m_r.TextWidth(PC_TAB_NAMES[i],FS(11),true)+S(20);
      Button(x,y,w,h,PC_TAB_NAMES[i],(m_tab==i),ACT_TAB,i,0,11);
      x+=w+gap;
     }
  }

//+------------------------------------------------------------------+
//| Panel lateral de filtros                                          |
//+------------------------------------------------------------------+
void CPanel::DrawFilterPanel(const SRect &rc)
  {
   m_r.Box(rc.x,rc.y,rc.w,rc.h,PC_CLR_PANEL,PC_CLR_BORDER);
   int pad=S(6), gap=S(3);
   int tw=(rc.w-2*pad-2*gap)/3;
   int ty=rc.y+pad;
   for(int i=0; i<3; i++)
      Button(rc.x+pad+i*(tw+gap),ty,tw,S(16),PC_FTAB_NAMES[i],(m_ftab==i),ACT_FTAB,i,0,9);

   m_r.Text(rc.x+rc.w/2,ty+S(22),PC_FTAB_TITLES[m_ftab],PC_CLR_BLUE_LIGHT,FS(9),TA_CENTER|TA_TOP,false);

   int rowh=S(17);
   int list_y=ty+S(38);
   int cb=S(10);
   int text_x=rc.x+pad+cb+S(6);

   //--- TODOS
   bool all_on=true;
   int count=0;
   if(m_ftab==FTAB_SYMBOL) { all_on=m_data.AllSymbolsOn(); count=m_data.SymbolCount(); }
   else if(m_ftab==FTAB_MAGIC) { all_on=m_data.AllMagicsOn(); count=m_data.MagicCount(); }
   else { all_on=(m_data.BuyOn() && m_data.SellOn()); count=2; }

   m_r.Checkbox(rc.x+pad,list_y+(rowh-cb)/2,cb,all_on,PC_CLR_BLUE_LIGHT);
   m_r.Text(text_x,list_y+rowh/2,"TODOS",PC_CLR_TEXT,FS(10),TA_LEFT|TA_VCENTER,false);
   Hit(rc.x,list_y,rc.w,rowh,ACT_FILTER_ALL);
   m_r.HLine(rc.x+pad,rc.x+rc.w-pad,list_y+rowh+S(2),PC_CLR_BORDER2);

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
      color sq=PC_SYMBOL_PALETTE[i%12];
      if(m_ftab==FTAB_SYMBOL) { on=m_data.SymbolOn(i); name=m_data.SymbolAt(i); }
      else if(m_ftab==FTAB_MAGIC) { on=m_data.MagicOn(i); name=IntegerToString(m_data.MagicAt(i)); if(m_data.MagicAt(i)==0) name="0 (manual)"; }
      else { on=(i==0 ? m_data.BuyOn() : m_data.SellOn()); name=(i==0 ? "Compra" : "Venta"); sq=(i==0 ? PC_CLR_GREEN : PC_CLR_RED); }

      m_r.Checkbox(rc.x+pad,ry+(rowh-cb)/2,cb,on,PC_CLR_BLUE_LIGHT);
      int sqs=S(8);
      m_r.Fill(rc.x+pad+cb+S(4),ry+(rowh-sqs)/2,sqs,sqs,sq);
      int nx=rc.x+pad+cb+S(4)+sqs+S(5);
      m_r.Text(nx,ry+rowh/2,m_r.Ellipsis(name,rc.x+rc.w-pad-nx-(count>visible ? S(6) : 0),FS(10)),(on ? PC_CLR_TEXT : PC_CLR_TEXT_MUTED),FS(10),TA_LEFT|TA_VCENTER,false);
      Hit(rc.x,ry,rc.w,rowh,ACT_FILTER_ITEM,i);
     }

   //--- barra de desplazamiento
   if(count>visible)
     {
      int track_x=rc.x+rc.w-S(5), track_y=items_y, track_h=visible*rowh;
      m_r.Fill(track_x,track_y,S(3),track_h,PC_CLR_BORDER);
      int th=MathMax(S(10),track_h*visible/count);
      int ty2=track_y+(track_h-th)*m_filter_scroll/MathMax(1,count-visible);
      m_r.Fill(track_x,ty2,S(3),th,PC_CLR_BORDER2);
     }
  }

//+------------------------------------------------------------------+
void CPanel::DrawContent(const SRect &rc)
  {
   switch(m_tab)
     {
      case TAB_CHART:        DrawChartView(rc);        break;
      case TAB_TRANSACTIONS: DrawTransactionsView(rc); break;
      case TAB_CALENDAR:     DrawCalendarView(rc);     break;
      case TAB_HOURLY:       DrawHourlyView(rc);       break;
      case TAB_ARENA:        DrawArenaView(rc);        break;
     }
  }

//+------------------------------------------------------------------+
void CPanel::DrawEmpty(const SRect &rc,const string msg)
  {
   m_r.Text(rc.x+rc.w/2,rc.y+rc.h/2,msg,PC_CLR_TEXT_MUTED,FS(12),TA_CENTER|TA_VCENTER,false);
  }

//+------------------------------------------------------------------+
//| Ventanas emergentes                                               |
//+------------------------------------------------------------------+
void CPanel::DrawPopups()
  {
   switch(m_popup)
     {
      case POPUP_DATEPICKER:  DrawDatePicker();      break;
      case POPUP_INFO_HOURLY: DrawInfoPopup(0);      break;
      case POPUP_INFO_ARENA:  DrawInfoPopup(1);      break;
      case POPUP_HOUR_CELL:   DrawHourCellPopup();   break;
      case POPUP_CAL_DAY:     DrawCalDayPopup();     break;
      default: break;
     }
  }

//+------------------------------------------------------------------+
void CPanel::PopupFrame(const int x,const int y,const int w,const int h,const string title)
  {
   Hit(0,0,m_r.Width(),m_r.Height(),ACT_BACKDROP);
   m_r.Fill(x+S(4),y+S(4),w,h,PC_CLR_BG);
   m_r.Box(x,y,w,h,PC_CLR_PANEL,PC_CLR_BLUE);
   int th=S(24);
   m_r.Fill(x+1,y+1,w-2,th,PC_CLR_PANEL3);
   m_r.HLine(x+1,x+w-2,y+th,PC_CLR_BLUE);
   m_r.Text(x+w/2,y+th/2+1,title,PC_CLR_BLUE_LIGHT,FS(11),TA_CENTER|TA_VCENTER,true);
   Hit(x,y,w,h,ACT_NONE);
   int cs=S(18);
   m_r.Text(x+w-cs/2-S(4),y+th/2+1,"×",PC_CLR_TEXT,FS(14),TA_CENTER|TA_VCENTER,true);
   Hit(x+w-cs-S(4),y+(th-cs)/2,cs+S(4),cs,ACT_POPUP_CLOSE);
  }

//+------------------------------------------------------------------+
void CPanel::DrawDatePicker()
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
   Button(x+S(10),ny,nav,nav,"<",false,ACT_DP_PREV,0,0,10);
   Button(x+w-S(10)-nav,ny,nav,nav,">",false,ACT_DP_NEXT,0,0,10);
   m_r.Text(x+w/2,ny+nav/2,PC_MONTHS[vdt.mon-1]+" "+IntegerToString(vdt.year),PC_CLR_BLUE_LIGHT,FS(11),TA_CENTER|TA_VCENTER,true);

   int gx=x+S(10), gy=ny+nav+S(8);
   int cw=(w-S(20))/7, ch=S(22);
   for(int d=0; d<7; d++)
      m_r.Text(gx+d*cw+cw/2,gy+S(6),PC_DAYS_SHORT[d],PC_CLR_TEXT_MUTED,FS(9),TA_CENTER|TA_TOP,false);
   gy+=S(18);

   datetime month_start=PC_MakeDate(vdt.year,vdt.mon,1);
   int first_dow=PC_WeekDay(month_start);
   int dim=PC_DaysInMonth(vdt.year,vdt.mon);
   datetime today=PC_DayStart(TimeCurrent());
   datetime sel_from=PC_DayStart(m_custom_from);
   for(int idx=0; idx<42; idx++)
     {
      int day=idx-first_dow+1;
      int col=idx%7, row=idx/7;
      int cx=gx+col*cw, cy=gy+row*ch;
      if(day<1 || day>dim) continue;
      datetime d=PC_MakeDate(vdt.year,vdt.mon,day);
      bool is_sel=(m_dp_stage==1 && d==sel_from);
      color bg=(is_sel ? PC_CLR_BLUE : PC_CLR_PANEL2);
      m_r.Box(cx+1,cy+1,cw-2,ch-2,bg,(d==today ? PC_CLR_BLUE_LIGHT : PC_CLR_BORDER));
      m_r.Text(cx+cw/2,cy+ch/2,IntegerToString(day),(is_sel ? PC_CLR_WHITE : PC_CLR_TEXT),FS(10),TA_CENTER|TA_VCENTER,false);
      Hit(cx,cy,cw,ch,ACT_DP_DAY,(long)d);
     }

   int fy=gy+6*ch+S(6);
   if(m_dp_stage==0)
      m_r.Text(x+w/2,fy,"Haz clic en un día para fijar el inicio",PC_CLR_TEXT_MUTED,FS(9),TA_CENTER|TA_TOP,false);
   else
     {
      m_r.Text(x+S(10),fy,"Inicio: "+PC_DateStr(sel_from),PC_CLR_GREEN,FS(9),TA_LEFT|TA_TOP,false);
      Button(x+w-S(10)-S(64),fy-S(3),S(64),S(16),"Reiniciar",false,ACT_DP_RESET,0,0,9);
     }
  }

//+------------------------------------------------------------------+
void CPanel::DrawInfoPopup(const int kind)
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
      m_r.Text(x+S(12),ty+i*lh,wrapped[i],PC_CLR_TEXT_DIM,FS(10),TA_LEFT|TA_TOP,false);
  }

//+------------------------------------------------------------------+
//| Eventos                                                           |
//+------------------------------------------------------------------+
void CPanel::OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
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
      if(m_tab==TAB_CHART && m_popup==POPUP_NONE && !m_minimized)
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
      if(lparam==27 && m_popup!=POPUP_NONE)
        {
         m_popup=POPUP_NONE;
         Draw();
        }
      return;
     }
  }

//+------------------------------------------------------------------+
void CPanel::HandleWheel(const int delta)
  {
   if(m_popup==POPUP_DATEPICKER)
     {
      Dispatch(delta>0 ? ACT_DP_PREV : ACT_DP_NEXT,0,0);
      return;
     }
   if(m_popup!=POPUP_NONE) return;

   if(InRect(m_rc_filter,m_mouse_x,m_mouse_y))
     {
      m_filter_scroll-=delta;
      if(m_filter_scroll<0) m_filter_scroll=0;
      Draw();
      return;
     }
   if(InRect(m_rc_content,m_mouse_x,m_mouse_y))
     {
      if(m_tab==TAB_TRANSACTIONS) Dispatch(delta>0 ? ACT_TX_PREV : ACT_TX_NEXT,0,0);
      else if(m_tab==TAB_CALENDAR) Dispatch(delta>0 ? ACT_CAL_PREV : ACT_CAL_NEXT,0,0);
     }
  }

//+------------------------------------------------------------------+
bool CPanel::HandleClick(const int mx,const int my)
  {
   for(int i=m_hit_count-1; i>=0; i--)
     {
      if(mx>=m_hits[i].x1 && mx<m_hits[i].x2 && my>=m_hits[i].y1 && my<m_hits[i].y2)
        {
         if(m_hits[i].action==ACT_NONE) return(true);
         Dispatch(m_hits[i].action,m_hits[i].p1,m_hits[i].p2);
         return(true);
        }
     }
   return(false);
  }

//+------------------------------------------------------------------+
void CPanel::Dispatch(const int action,const long p1,const long p2)
  {
   switch(action)
     {
      case ACT_RANGE:
         if(p1==RANGE_CUSTOM)
           {
            m_popup=POPUP_DATEPICKER;
            m_dp_stage=0;
            m_dp_view=PC_MonthStart(m_custom_from>0 ? m_custom_from : TimeCurrent());
           }
         else
           {
            m_range=(ENUM_PC_RANGE)p1;
            m_popup=POPUP_NONE;
            UpdateRange();
           }
         break;
      case ACT_TAB:
         m_tab=(ENUM_PC_TAB)p1;
         m_popup=POPUP_NONE;
         m_hover_plot=false;
         break;
      case ACT_FTAB:
         m_ftab=(ENUM_PC_FTAB)p1;
         m_filter_scroll=0;
         break;
      case ACT_FILTER_ALL:
         if(m_ftab==FTAB_SYMBOL) m_data.SetAllSymbols(!m_data.AllSymbolsOn());
         else if(m_ftab==FTAB_MAGIC) m_data.SetAllMagics(!m_data.AllMagicsOn());
         else m_data.SetAllTypes(!(m_data.BuyOn() && m_data.SellOn()));
         m_data.ApplyFilter();
         m_tx_page=0;
         break;
      case ACT_FILTER_ITEM:
         if(m_ftab==FTAB_SYMBOL) m_data.ToggleSymbol((int)p1);
         else if(m_ftab==FTAB_MAGIC) m_data.ToggleMagic((int)p1);
         else { if(p1==0) m_data.ToggleBuy(); else m_data.ToggleSell(); }
         m_data.ApplyFilter();
         m_tx_page=0;
         break;
      case ACT_CAL_PREV:
         m_cal_month--;
         if(m_cal_month<1) { m_cal_month=12; m_cal_year--; }
         m_popup=POPUP_NONE;
         break;
      case ACT_CAL_NEXT:
         m_cal_month++;
         if(m_cal_month>12) { m_cal_month=1; m_cal_year++; }
         m_popup=POPUP_NONE;
         break;
      case ACT_CAL_DAY:
         m_popup=POPUP_CAL_DAY;
         m_popup_p1=p1;
         break;
      case ACT_HOUR_MODE:
         m_hour_mode=(ENUM_PC_HOUR_MODE)p1;
         m_popup=POPUP_NONE;
         break;
      case ACT_HOUR_TIME:
         m_hour_by_close=!m_hour_by_close;
         m_popup=POPUP_NONE;
         break;
      case ACT_HOUR_CELL:
         m_popup=POPUP_HOUR_CELL;
         m_popup_p1=p1;
         m_popup_p2=p2;
         break;
      case ACT_ARENA_VIEW:
         m_arena_advanced=(p1==1);
         break;
      case ACT_INFO:
         m_popup=(p1==0 ? POPUP_INFO_HOURLY : POPUP_INFO_ARENA);
         break;
      case ACT_POPUP_CLOSE:
      case ACT_BACKDROP:
         m_popup=POPUP_NONE;
         break;
      case ACT_TX_PREV:
         if(m_tx_page>0) m_tx_page--;
         break;
      case ACT_TX_NEXT:
         if(m_tx_page<m_tx_pages-1) m_tx_page++;
         break;
      case ACT_MINIMIZE:
         m_minimized=!m_minimized;
         m_popup=POPUP_NONE;
         ApplyGeometry();
         break;
      case ACT_MAXIMIZE:
         m_maximized=!m_maximized;
         ApplyGeometry();
         break;
      case ACT_DP_PREV:
        {
         MqlDateTime dt; TimeToStruct(m_dp_view,dt);
         dt.mon--; if(dt.mon<1) { dt.mon=12; dt.year--; }
         m_dp_view=PC_MakeDate(dt.year,dt.mon,1);
         break;
        }
      case ACT_DP_NEXT:
        {
         MqlDateTime dt; TimeToStruct(m_dp_view,dt);
         dt.mon++; if(dt.mon>12) { dt.mon=1; dt.year++; }
         m_dp_view=PC_MakeDate(dt.year,dt.mon,1);
         break;
        }
      case ACT_DP_DAY:
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
            m_range=RANGE_CUSTOM;
            m_popup=POPUP_NONE;
            UpdateRange();
           }
         break;
        }
      case ACT_DP_RESET:
         m_dp_stage=0;
         break;
      default:
         break;
     }
   Draw();
  }

//+------------------------------------------------------------------+
void CPanel::OnTimer()
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
   if(m_popup!=POPUP_NONE || m_hover_plot) return;
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
void CPanel::OnTradeEvent()
  {
   m_reload_pending=true;
   m_reload_due=GetTickCount()+400;
  }

#endif // PC_PANEL_MQH
