//+------------------------------------------------------------------+
//|                                                    TradeData.mqh |
//|    Panel de Control MT5 - Historial por posición, filtros y stats |
//+------------------------------------------------------------------+
#ifndef PC_TRADEDATA_MQH
#define PC_TRADEDATA_MQH

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Registro de una posición cerrada (agregado de sus deals)          |
//+------------------------------------------------------------------+
struct SPosRecord
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

void PC_ResetRecord(SPosRecord &r)
  {
   r.position_id=0; r.symbol=""; r.magic=0; r.type=0;
   r.vol_in=0; r.vol_out=0; r.open_time=0; r.close_time=0;
   r.open_price=0; r.close_price=0; r.profit=0; r.swap=0; r.commission=0; r.net=0;
   r.sl=0; r.tp=0; r.comment=""; r.closed=false; r.orphan=false;
  }

//+------------------------------------------------------------------+
//| Estadística de un día                                             |
//+------------------------------------------------------------------+
struct SDayStat
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
struct SStats
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
class CLongIntMap
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
                     CLongIntMap() : m_cap(0),m_count(0) {}
   void              Init(const int capacity);
   bool              Get(const long key,int &val) const;
   void              Set(const long key,const int val);
  };

void CLongIntMap::Init(const int capacity)
  {
   m_cap=MathMax(64,capacity);
   ArrayResize(m_keys,m_cap);
   ArrayResize(m_vals,m_cap);
   ArrayResize(m_used,m_cap);
   ArrayFill(m_used,0,m_cap,false);
   m_count=0;
  }

bool CLongIntMap::Get(const long key,int &val) const
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

void CLongIntMap::Set(const long key,const int val)
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

void CLongIntMap::Grow()
  {
   long ok[]; int ov[]; bool ou[];
   ArrayCopy(ok,m_keys); ArrayCopy(ov,m_vals); ArrayCopy(ou,m_used);
   int old_cap=m_cap;
   Init(old_cap*2);
   for(int i=0; i<old_cap; i++)
      if(ou[i]) Set(ok[i],ov[i]);
  }

//+------------------------------------------------------------------+
//| CTradeData                                                        |
//+------------------------------------------------------------------+
class CTradeData
  {
private:
   //--- todas las posiciones cerradas, ordenadas por cierre
   SPosRecord        m_all[];
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
   SPosRecord        m_filtered[];

   void              RebuildSymbolList();
   void              RebuildMagicList();
   bool              SymbolEnabled(const string s) const;
   bool              MagicEnabled(const long m) const;
   bool              PassStaticFilters(const SPosRecord &r) const;

public:
                     CTradeData();

   void              SetDisciplineParams(const int max_trades_day,const int revenge_minutes,const double sl_factor);
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
   void              GetFiltered(SPosRecord &out[]) const;
   void              Filtered(const int i,SPosRecord &out) const { out=m_filtered[i]; }
   int               TotalCount() const { return(ArraySize(m_all)); }
   //--- ignora el rango temporal (usado por el calendario)
   void              CollectNoTime(SPosRecord &out[]) const;
   void              CollectInRange(const datetime from,const datetime to,SPosRecord &out[]) const;

   //--- balance
   double            BalanceAt(const datetime t) const;
   double            InitialBalance() const { return(m_initial_balance); }
   double            HighWatermark() const;

   //--- estadísticas
   void              ComputeStats(const SPosRecord &recs[],SStats &s) const;
   void              BuildDaily(const SPosRecord &recs[],SDayStat &days[]) const;
   static int        FindDay(const SDayStat &days[],const datetime day);
  };

//+------------------------------------------------------------------+
CTradeData::CTradeData() : m_initial_balance(0),m_buy_on(true),m_sell_on(true),m_from(0),m_to(D'2100.01.01'),
                           m_max_trades_day(3),m_revenge_minutes(5),m_sl_factor(1.3)
  {
  }

//+------------------------------------------------------------------+
void CTradeData::SetDisciplineParams(const int max_trades_day,const int revenge_minutes,const double sl_factor)
  {
   m_max_trades_day=MathMax(1,max_trades_day);
   m_revenge_minutes=MathMax(0,revenge_minutes);
   m_sl_factor=MathMax(1.0,sl_factor);
  }

//+------------------------------------------------------------------+
//| Carga todo el historial y agrega los deals por posición           |
//+------------------------------------------------------------------+
bool CTradeData::Reload()
  {
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

   CLongIntMap pos_map;
   pos_map.Init(n*2+16);

   SPosRecord recs[];
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
         PC_ResetRecord(recs[ri]);
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
void CTradeData::RebuildSymbolList()
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
void CTradeData::RebuildMagicList()
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
bool CTradeData::SymbolEnabled(const string s) const
  {
   for(int i=0; i<ArraySize(m_symbols); i++)
      if(m_symbols[i]==s) return(m_sym_on[i]);
   return(true);
  }

bool CTradeData::MagicEnabled(const long m) const
  {
   for(int i=0; i<ArraySize(m_magics); i++)
      if(m_magics[i]==m) return(m_mag_on[i]);
   return(true);
  }

bool CTradeData::AllSymbolsOn() const
  {
   for(int i=0; i<ArraySize(m_sym_on); i++) if(!m_sym_on[i]) return(false);
   return(true);
  }

void CTradeData::SetAllSymbols(const bool on)
  {
   for(int i=0; i<ArraySize(m_sym_on); i++) m_sym_on[i]=on;
  }

bool CTradeData::AllMagicsOn() const
  {
   for(int i=0; i<ArraySize(m_mag_on); i++) if(!m_mag_on[i]) return(false);
   return(true);
  }

void CTradeData::SetAllMagics(const bool on)
  {
   for(int i=0; i<ArraySize(m_mag_on); i++) m_mag_on[i]=on;
  }

//+------------------------------------------------------------------+
bool CTradeData::PassStaticFilters(const SPosRecord &r) const
  {
   if(r.type==0 && !m_buy_on) return(false);
   if(r.type==1 && !m_sell_on) return(false);
   if(!SymbolEnabled(r.symbol)) return(false);
   if(!MagicEnabled(r.magic)) return(false);
   return(true);
  }

//+------------------------------------------------------------------+
void CTradeData::ApplyFilter()
  {
   CollectInRange(m_from,m_to,m_filtered);
  }

//+------------------------------------------------------------------+
void CTradeData::GetFiltered(SPosRecord &out[]) const
  {
   int n=ArraySize(m_filtered);
   ArrayResize(out,n);
   for(int i=0; i<n; i++) out[i]=m_filtered[i];
  }

//+------------------------------------------------------------------+
void CTradeData::CollectInRange(const datetime from,const datetime to,SPosRecord &out[]) const
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
void CTradeData::CollectNoTime(SPosRecord &out[]) const
  {
   CollectInRange(0,D'2100.01.01',out);
  }

//+------------------------------------------------------------------+
//| Balance de la cuenta justo después del último deal <= t           |
//+------------------------------------------------------------------+
double CTradeData::BalanceAt(const datetime t) const
  {
   int n=ArraySize(m_bal_t);
   if(n==0) return(AccountInfoDouble(ACCOUNT_BALANCE));
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
double CTradeData::HighWatermark() const
  {
   double hwm=MathMax(m_initial_balance,AccountInfoDouble(ACCOUNT_BALANCE));
   for(int i=0; i<ArraySize(m_bal_v); i++) if(m_bal_v[i]>hwm) hwm=m_bal_v[i];
   return(hwm);
  }

//+------------------------------------------------------------------+
//| Agrupación diaria (recs debe estar ordenado por cierre)           |
//+------------------------------------------------------------------+
void CTradeData::BuildDaily(const SPosRecord &recs[],SDayStat &days[]) const
  {
   ArrayResize(days,0);
   int n=ArraySize(recs);
   double cum=0, peak=0;
   int cur=-1;
   for(int i=0; i<n; i++)
     {
      datetime d=PC_DayStart(recs[i].close_time);
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
int CTradeData::FindDay(const SDayStat &days[],const datetime day)
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
void CTradeData::ComputeStats(const SPosRecord &recs[],SStats &s) const
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
   SDayStat days[];
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

#endif // PC_TRADEDATA_MQH
