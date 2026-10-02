//+------------------------------------------------------------------+
//|                                             MSNR_TTQ_Milana.mq5  |
//|            Malaysian Support & Resistance (MSNR) for MetaTrader 5|
//|                                                                  |
//|  Replica of the "MSNR by TTQ & Milana" concept:                  |
//|   - Multi-timeframe A-shape / V-shape detection (D1, H4, H1)     |
//|   - OCL (Open / Close Levels) of higher-timeframe candles        |
//|   - Level merging with combined labels ("D,H4 | OCL-O,A")        |
//|   - Freshness tracking (fresh = thick, tested = thin/transparent)|
//|   - Bias table: session / killzone + Weekly & Daily storyline    |
//+------------------------------------------------------------------+
#property copyright   "MSNR replica - TTQ & Milana methodology"
#property link        ""
#property version     "1.00"
#property description "Malaysian Support & Resistance (MSNR). Multi-timeframe A/V shapes,"
#property description "OCL levels, merging logic, freshness tracking and bias dashboard."
#property indicator_chart_window
#property indicator_plots   0
#property indicator_buffers 0

//+------------------------------------------------------------------+
//| Enumerations                                                      |
//+------------------------------------------------------------------+
enum ENUM_THEME
  {
   THEME_LIGHT = 0, // Light
   THEME_DARK  = 1  // Dark
  };

enum ENUM_LABEL_SIZE
  {
   LBL_TINY   = 0, // Tiny
   LBL_SMALL  = 1, // Small
   LBL_NORMAL = 2, // Normal
   LBL_LARGE  = 3, // Large
   LBL_HUGE   = 4  // Huge
  };

enum ENUM_TIME_MODE
  {
   TIME_AUTO_GMT = 0, // Auto (GMT -> New York with DST)
   TIME_MANUAL   = 1  // Manual offset from server time
  };

enum ENUM_LEVEL_SELECT
  {
   SELECT_NEAREST = 0, // Nearest to current price
   SELECT_RECENT  = 1  // Most recent
  };

enum ENUM_OCL_STYLE
  {
   OCL_DOT     = 0, // Dotted
   OCL_DASH    = 1, // Dashed
   OCL_DASHDOT = 2, // Dash-Dot
   OCL_SOLID   = 3  // Solid
  };

//+------------------------------------------------------------------+
//| Inputs                                                            |
//+------------------------------------------------------------------+
input group "=== STYLE SETTINGS ==="
input ENUM_THEME        InpTheme              = THEME_LIGHT;   // Theme Style (label text color)

input group "=== TIMEFRAME TOGGLES ==="
input bool              InpShowDaily          = true;          // Show DAILY Levels
input bool              InpShowH4             = true;          // Show H4 Levels
input bool              InpShowH1             = true;          // Show H1 Levels

input group "=== DETECTION ==="
input int               InpRecentPerType      = 3;             // Recent A-shapes and V-shapes kept per timeframe
input int               InpLookbackDaily      = 60;            // Daily lookback (max bars scanned)
input int               InpLookbackH4         = 90;            // H4 lookback (max bars scanned)
input int               InpLookbackH1         = 72;            // H1 lookback (max bars scanned)
input double            InpMinBodyATR         = 0.0;           // Min candle body (x ATR14 of the TF, 0 = off)
input bool              InpHideBroken         = false;         // Hide levels broken by a candle close
input double            InpMergeTolerancePct  = 0.05;          // Merge tolerance (% of price)
input int               InpMergeTolerancePts  = 0;             // Merge tolerance (points, 0 = use %)

input group "=== OCL SETTINGS ==="
input bool              InpShowDailyOCL       = true;          // Show Daily OCL
input bool              InpShowH4OCL          = false;         // Show H4 OCL
input bool              InpShowH1OCL          = false;         // Show H1 OCL
input int               InpDailyOCLLookback   = 2;             // Daily OCL Lookback (completed candles)
input int               InpH4OCLLookback      = 2;             // H4 OCL Lookback (completed candles)
input int               InpH1OCLLookback      = 2;             // H1 OCL Lookback (completed candles)
input color             InpDailyOpenColor     = C'0,230,118';  // Daily Open Color
input color             InpDailyCloseColor    = C'255,82,82';  // Daily Close Color
input color             InpH4OpenColor        = C'33,150,243'; // H4 Open Color
input color             InpH4CloseColor       = C'255,152,0';  // H4 Close Color
input color             InpH1OpenColor        = C'156,39,176'; // H1 Open Color
input color             InpH1CloseColor       = C'103,58,183'; // H1 Close Color
input ENUM_OCL_STYLE    InpOCLStyle           = OCL_DOT;       // OCL Line Style

input group "=== LEVEL LIMITS ==="
input int               InpMaxResistance      = 10;            // Max Resistance Levels
input int               InpMaxSupport         = 10;            // Max Support Levels
input ENUM_LEVEL_SELECT InpLevelSelection     = SELECT_NEAREST;// Which levels to keep when limit is hit

input group "=== DAILY COLORS ==="
input color             InpDailyResColor      = C'239,83,80';  // Daily Resistance
input color             InpDailySupColor      = C'76,175,80';  // Daily Support

input group "=== H4 COLORS ==="
input color             InpH4ResColor         = C'255,152,0';  // H4 Resistance
input color             InpH4SupColor         = C'33,150,243'; // H4 Support

input group "=== H1 COLORS ==="
input color             InpH1ResColor         = C'233,30,99';  // H1 Resistance
input color             InpH1SupColor         = C'0,188,212';  // H1 Support

input group "=== LINE SETTINGS ==="
input int               InpFreshWidth         = 2;             // Fresh Line Width
input int               InpUnfreshWidth       = 1;             // Unfresh Line Width
input int               InpUnfreshTransp      = 50;            // Unfresh Transparency (0-100)
input int               InpExtendBars         = 20;            // Extend lines to the right (bars)
input bool              InpAutoChartShift     = true;          // Enable chart shift so labels are visible

input group "=== LABEL SETTINGS ==="
input bool              InpShowLabels         = true;          // Show labels
input ENUM_LABEL_SIZE   InpLabelSize          = LBL_SMALL;     // Label Size
input bool              InpShowPrice          = false;         // Show Price
input bool              InpShowTimeframe      = true;          // Show Timeframe
input bool              InpShowType           = true;          // Show Type (A/V/OCL)
input bool              InpShowStatus         = false;         // Show Status (dot = fresh, "=" = tested)

input group "=== BIAS TABLE ==="
input bool              InpShowTable          = true;          // Show Bias Table
input ENUM_BASE_CORNER  InpTableCorner        = CORNER_RIGHT_UPPER; // Table corner
input int               InpTableX             = 10;            // Table X offset (px)
input int               InpTableY             = 25;            // Table Y offset (px)
input string            InpTableTitle         = "MSNR by TTQxMilana"; // Table title
input string            InpStorylineTitle     = "STORYLINE";    // Storyline separator text (BIAS, STORYLINE...)

input group "=== SESSIONS (New York time, HH:MM-HH:MM) ==="
input ENUM_TIME_MODE    InpTimeMode           = TIME_AUTO_GMT; // Time conversion mode
input int               InpManualOffsetHours  = -7;            // Manual: hours to add to server time to get NY time
input string            InpAsiaSession        = "18:00-02:00"; // Asia session
input string            InpAsiaKZ             = "20:00-00:00"; // Asia Killzone
input string            InpLondonSession      = "02:00-08:00"; // London session
input string            InpLondonKZ           = "02:00-05:00"; // London Killzone
input string            InpNYSession          = "08:00-17:00"; // New York session
input string            InpNYKZ               = "07:00-10:00"; // New York Killzone

//+------------------------------------------------------------------+
//| Constants                                                         |
//+------------------------------------------------------------------+
#define OBJ_PREFIX      "MSNR_"
#define LINE_PREFIX     "MSNR_L_"
#define LABEL_PREFIX    "MSNR_T_"
#define TABLE_PREFIX    "MSNR_TBL_"

#define KIND_A      1
#define KIND_V      2
#define KIND_OCL_O  3
#define KIND_OCL_C  4

#define TF_BIT_H1   1
#define TF_BIT_H4   2
#define TF_BIT_D1   4

// Table geometry (pixels)
#define TBL_WIDTH        150
#define TBL_HEADER_H     20
#define TBL_ROW_H        16
#define TBL_PAD          6
#define TBL_FONT         "Arial"
#define TBL_FONT_SIZE    8

// Table colors (dashboard is always dark, like the original)
#define CLR_TBL_BG        C'30,34,45'
#define CLR_TBL_BORDER    C'54,58,69'
#define CLR_TBL_HEADER    C'41,98,255'
#define CLR_TBL_TITLE     clrWhite
#define CLR_TBL_LABEL     C'178,181,190'
#define CLR_TBL_STORY     C'255,213,79'
#define CLR_BULL          C'0,230,118'
#define CLR_BEAR          C'255,82,82'
#define CLR_NEUTRAL       C'158,158,158'
#define CLR_SES_ASIA      C'224,64,251'
#define CLR_SES_LONDON    C'255,152,0'
#define CLR_SES_NY        C'66,165,245'
#define CLR_SES_OFF       C'120,123,134'

//+------------------------------------------------------------------+
//| Data structures                                                   |
//+------------------------------------------------------------------+
struct SCandidate
  {
   double          price;
   datetime        start;      // time of the candle where the level is born (line start)
   datetime        formedAt;   // moment from which tests/breaks are counted
   ENUM_TIMEFRAMES tf;
   int             kind;       // KIND_A, KIND_V, KIND_OCL_O, KIND_OCL_C
  };

struct SLevel
  {
   double          price;
   datetime        start;
   datetime        formedAt;
   int             tfMask;
   string          types;         // e.g. "A,OCL-O"
   int             primaryShape;  // +1 = A (resistance), -1 = V (support), 0 = OCL only
   bool            hasOCL;
   int             oclKind;       // KIND_OCL_O / KIND_OCL_C of the first OCL merged
   ENUM_TIMEFRAMES oclTF;
   bool            fresh;
   bool            broken;
  };

struct SSessionRange
  {
   int startMin;
   int endMin;
   bool valid;
  };

//+------------------------------------------------------------------+
//| Globals                                                           |
//+------------------------------------------------------------------+
SLevel        g_levels[];
int           g_drawnCount     = 0;
datetime      g_lastRebuild    = 0;
datetime      g_lastChartBar   = 0;
bool          g_dataMissing    = false;
bool          g_tableCreated   = false;
bool          g_levelObjectsCreated = false;
SSessionRange g_asia, g_asiaKZ, g_london, g_londonKZ, g_ny, g_nyKZ;

// cached table state to avoid redundant object updates
string        g_prevSession    = "";
string        g_prevWeekly     = "";
string        g_prevDaily      = "";

//+------------------------------------------------------------------+
//| Helpers: time ranges                                              |
//+------------------------------------------------------------------+
bool ParseRange(const string text, SSessionRange &rng)
  {
   rng.valid = false;
   string parts[];
   if(StringSplit(text, '-', parts) != 2)
      return(false);
   string a[], b[];
   if(StringSplit(parts[0], ':', a) != 2 || StringSplit(parts[1], ':', b) != 2)
      return(false);
   rng.startMin = (int)StringToInteger(a[0]) * 60 + (int)StringToInteger(a[1]);
   rng.endMin   = (int)StringToInteger(b[0]) * 60 + (int)StringToInteger(b[1]);
   if(rng.endMin == 0)
      rng.endMin = 1440;
   rng.valid = true;
   return(true);
  }

bool InRange(const int minuteOfDay, const SSessionRange &rng)
  {
   if(!rng.valid)
      return(false);
   if(rng.startMin <= rng.endMin)
      return(minuteOfDay >= rng.startMin && minuteOfDay < rng.endMin);
   // range crossing midnight
   return(minuteOfDay >= rng.startMin || minuteOfDay < rng.endMin);
  }

//+------------------------------------------------------------------+
//| Helpers: New York time with US daylight saving rules              |
//+------------------------------------------------------------------+
datetime NthSundayUTC(const int year, const int month, const int nth, const int hourUTC)
  {
   MqlDateTime d;
   d.year = year; d.mon = month; d.day = 1;
   d.hour = 0;    d.min = 0;     d.sec = 0;
   datetime first = StructToTime(d);
   TimeToStruct(first, d);
   int firstSunday = 1 + ((7 - d.day_of_week) % 7);
   int day = firstSunday + 7 * (nth - 1);
   d.day  = day;
   d.hour = hourUTC;
   return(StructToTime(d));
  }

bool IsUSDaylightSaving(const datetime gmt)
  {
   MqlDateTime s;
   TimeToStruct(gmt, s);
   // DST starts 2nd Sunday of March 02:00 local (07:00 UTC) and ends 1st Sunday of November 02:00 local (06:00 UTC)
   datetime start = NthSundayUTC(s.year, 3, 2, 7);
   datetime end   = NthSundayUTC(s.year, 11, 1, 6);
   return(gmt >= start && gmt < end);
  }

datetime NewYorkTime()
  {
   if(InpTimeMode == TIME_MANUAL)
      return(TimeCurrent() + InpManualOffsetHours * 3600);
   datetime gmt = TimeGMT();
   int offsetHours = IsUSDaylightSaving(gmt) ? -4 : -5;
   return(gmt + offsetHours * 3600);
  }

//+------------------------------------------------------------------+
//| Helpers: colors                                                   |
//+------------------------------------------------------------------+
color BlendWithBackground(const color c, const int transparencyPct)
  {
   int t = MathMax(0, MathMin(100, transparencyPct));
   if(t == 0)
      return(c);
   uint fg = (uint)c;
   uint bg = (uint)ChartGetInteger(0, CHART_COLOR_BACKGROUND);
   int r  = (int)(fg & 0xFF),  g  = (int)((fg >> 8) & 0xFF),  b  = (int)((fg >> 16) & 0xFF);
   int rb = (int)(bg & 0xFF),  gb = (int)((bg >> 8) & 0xFF),  bb = (int)((bg >> 16) & 0xFF);
   r = r + (rb - r) * t / 100;
   g = g + (gb - g) * t / 100;
   b = b + (bb - b) * t / 100;
   return((color)(r | (g << 8) | (b << 16)));
  }

color OCLColor(const ENUM_TIMEFRAMES tf, const int kind)
  {
   if(tf == PERIOD_D1)
      return(kind == KIND_OCL_O ? InpDailyOpenColor : InpDailyCloseColor);
   if(tf == PERIOD_H4)
      return(kind == KIND_OCL_O ? InpH4OpenColor : InpH4CloseColor);
   return(kind == KIND_OCL_O ? InpH1OpenColor : InpH1CloseColor);
  }

color ShapeColor(const int tfMask, const bool resistance)
  {
   if((tfMask & TF_BIT_D1) != 0)
      return(resistance ? InpDailyResColor : InpDailySupColor);
   if((tfMask & TF_BIT_H4) != 0)
      return(resistance ? InpH4ResColor : InpH4SupColor);
   return(resistance ? InpH1ResColor : InpH1SupColor);
  }

ENUM_LINE_STYLE OCLLineStyle()
  {
   switch(InpOCLStyle)
     {
      case OCL_DASH:    return(STYLE_DASH);
      case OCL_DASHDOT: return(STYLE_DASHDOT);
      case OCL_SOLID:   return(STYLE_SOLID);
      default:          return(STYLE_DOT);
     }
  }

//+------------------------------------------------------------------+
//| Helpers: text                                                     |
//+------------------------------------------------------------------+
int TFBit(const ENUM_TIMEFRAMES tf)
  {
   if(tf == PERIOD_D1) return(TF_BIT_D1);
   if(tf == PERIOD_H4) return(TF_BIT_H4);
   return(TF_BIT_H1);
  }

string TFMaskText(const int mask)
  {
   string s = "";
   if((mask & TF_BIT_D1) != 0) s += "D";
   if((mask & TF_BIT_H4) != 0) s += (s == "" ? "" : ",") + "H4";
   if((mask & TF_BIT_H1) != 0) s += (s == "" ? "" : ",") + "H1";
   return(s);
  }

string KindName(const int kind)
  {
   switch(kind)
     {
      case KIND_A:     return("A");
      case KIND_V:     return("V");
      case KIND_OCL_O: return("OCL-O");
      case KIND_OCL_C: return("OCL-C");
     }
   return("");
  }

void AppendType(string &types, const string name)
  {
   if(name == "")
      return;
   string parts[];
   int n = StringSplit(types, ',', parts);
   for(int i = 0; i < n; i++)
      if(parts[i] == name)
         return;
   types += (types == "" ? "" : ",") + name;
  }

int LabelFontSize()
  {
   switch(InpLabelSize)
     {
      case LBL_TINY:   return(7);
      case LBL_SMALL:  return(8);
      case LBL_NORMAL: return(10);
      case LBL_LARGE:  return(12);
      case LBL_HUGE:   return(14);
     }
   return(8);
  }

color LabelTextColor()
  {
   return(InpTheme == THEME_DARK ? clrWhite : C'19,23,34');
  }

//+------------------------------------------------------------------+
//| Level collection                                                  |
//+------------------------------------------------------------------+
void AddCandidate(SCandidate &arr[], int &n, const double price, const datetime start,
                  const datetime formedAt, const ENUM_TIMEFRAMES tf, const int kind)
  {
   if(n >= ArraySize(arr))
      ArrayResize(arr, n + 64);
   arr[n].price    = price;
   arr[n].start    = start;
   arr[n].formedAt = formedAt;
   arr[n].tf       = tf;
   arr[n].kind     = kind;
   n++;
  }

void CollectTimeframe(const ENUM_TIMEFRAMES tf, const bool shapes, const bool ocl,
                      const int lookback, const int oclLookback, SCandidate &arr[], int &n)
  {
   if(!shapes && !ocl)
      return;
   int need = MathMax(shapes ? lookback : 0, ocl ? oclLookback : 0) + 3;
   MqlRates r[];
   ArraySetAsSeries(r, true);
   int got = CopyRates(_Symbol, tf, 0, need, r);
   if(got < 3)
     {
      g_dataMissing = true;
      return;
     }
   int ps = PeriodSeconds(tf);

   if(shapes)
     {
      // Minimum body size filter, relative to the average range of the last 14 completed candles
      double minBody = 0.0;
      if(InpMinBodyATR > 0)
        {
         double sum = 0.0;
         int cnt = 0;
         for(int a = 1; a <= 14 && a < got; a++)
           {
            sum += (r[a].high - r[a].low);
            cnt++;
           }
         if(cnt > 0)
            minBody = (sum / cnt) * InpMinBodyATR;
        }

      // Only the most recent N A-shapes and N V-shapes of this timeframe are kept (like the original),
      // scanning from the newest completed candle backwards. i is the SECOND candle of the pattern.
      int maxPerType = MathMax(1, InpRecentPerType);
      int foundA = 0, foundV = 0;
      for(int i = 1; i <= lookback && i + 1 < got; i++)
        {
         if(foundA >= maxPerType && foundV >= maxPerType)
            break;
         double body1 = MathAbs(r[i + 1].close - r[i + 1].open);
         double body2 = MathAbs(r[i].close - r[i].open);
         if(body1 < minBody || body2 < minBody)
            continue;
         bool bull1 = r[i + 1].close > r[i + 1].open;
         bool bear1 = r[i + 1].close < r[i + 1].open;
         bool bull2 = r[i].close > r[i].open;
         bool bear2 = r[i].close < r[i].open;
         if(bull1 && bear2 && foundA < maxPerType)
           {
            // A-shape: peak formed by the bodies (bullish close / bearish open)
            double p = MathMax(r[i + 1].close, r[i].open);
            AddCandidate(arr, n, p, r[i].time, r[i].time + ps, tf, KIND_A);
            foundA++;
           }
         else if(bear1 && bull2 && foundV < maxPerType)
           {
            // V-shape: valley formed by the bodies (bearish close / bullish open)
            double p = MathMin(r[i + 1].close, r[i].open);
            AddCandidate(arr, n, p, r[i].time, r[i].time + ps, tf, KIND_V);
            foundV++;
           }
        }
     }

   if(ocl)
     {
      for(int k = 1; k <= oclLookback && k < got; k++)
        {
         AddCandidate(arr, n, r[k].open,  r[k].time, r[k].time + ps, tf, KIND_OCL_O);
         AddCandidate(arr, n, r[k].close, r[k].time, r[k].time + ps, tf, KIND_OCL_C);
        }
     }
  }

double MergeTolerance(const double price)
  {
   if(InpMergeTolerancePts > 0)
      return(InpMergeTolerancePts * _Point);
   return(MathAbs(price) * InpMergeTolerancePct / 100.0);
  }

void MergeCandidates(SCandidate &cand[], const int n, SLevel &levels[], int &count)
  {
   count = 0;
   ArrayResize(levels, 0);
   for(int i = 0; i < n; i++)
     {
      double tol = MergeTolerance(cand[i].price);
      int found = -1;
      for(int j = 0; j < count; j++)
        {
         if(MathAbs(levels[j].price - cand[i].price) <= tol)
           {
            found = j;
            break;
           }
        }
      int bit = TFBit(cand[i].tf);
      bool isOCL = (cand[i].kind == KIND_OCL_O || cand[i].kind == KIND_OCL_C);
      if(found < 0)
        {
         ArrayResize(levels, count + 1);
         levels[count].price        = cand[i].price;
         levels[count].start        = cand[i].start;
         levels[count].formedAt     = cand[i].formedAt;
         levels[count].tfMask       = bit;
         levels[count].types        = KindName(cand[i].kind);
         levels[count].primaryShape = (cand[i].kind == KIND_A ? 1 : (cand[i].kind == KIND_V ? -1 : 0));
         levels[count].hasOCL       = isOCL;
         levels[count].oclKind      = isOCL ? cand[i].kind : 0;
         levels[count].oclTF        = cand[i].tf;
         levels[count].fresh        = true;
         levels[count].broken       = false;
         count++;
        }
      else
        {
         levels[found].tfMask |= bit;
         AppendType(levels[found].types, KindName(cand[i].kind));
         if(cand[i].start < levels[found].start)
            levels[found].start = cand[i].start;
         if(cand[i].formedAt < levels[found].formedAt)
            levels[found].formedAt = cand[i].formedAt;
         if(isOCL && !levels[found].hasOCL)
           {
            levels[found].hasOCL  = true;
            levels[found].oclKind = cand[i].kind;
            levels[found].oclTF   = cand[i].tf;
           }
         if(!isOCL && levels[found].primaryShape == 0)
            levels[found].primaryShape = (cand[i].kind == KIND_A ? 1 : -1);
        }
     }
  }

//+------------------------------------------------------------------+
//| Freshness / break evaluation                                      |
//| Each level is checked on the lowest timeframe among its merged    |
//| components, from the moment it was formed up to the current bar.  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES LowestTF(const int mask)
  {
   if((mask & TF_BIT_H1) != 0) return(PERIOD_H1);
   if((mask & TF_BIT_H4) != 0) return(PERIOD_H4);
   return(PERIOD_D1);
  }

void EvaluateLevel(SLevel &lv, const MqlRates &r[], const int got, const datetime currentBar)
  {
   lv.fresh  = true;
   lv.broken = false;
   for(int j = 0; j < got; j++)   // series order: newest first
     {
      if(r[j].time < lv.formedAt)
         break;
      if(r[j].low <= lv.price && r[j].high >= lv.price)
         lv.fresh = false;
      if(r[j].time != currentBar)   // only completed candles can break a level
        {
         if(lv.primaryShape > 0 && r[j].close > lv.price)
            lv.broken = true;
         else if(lv.primaryShape < 0 && r[j].close < lv.price)
            lv.broken = true;
        }
      if(!lv.fresh && lv.broken)
         break;
     }
  }

void EvaluateAll(SLevel &levels[], const int count)
  {
   ENUM_TIMEFRAMES tfs[3];
   tfs[0] = PERIOD_H1;
   tfs[1] = PERIOD_H4;
   tfs[2] = PERIOD_D1;
   datetime now = TimeCurrent();

   for(int t = 0; t < 3; t++)
     {
      datetime oldest = 0;
      bool any = false;
      for(int i = 0; i < count; i++)
        {
         if(LowestTF(levels[i].tfMask) != tfs[t])
            continue;
         any = true;
         if(oldest == 0 || levels[i].formedAt < oldest)
            oldest = levels[i].formedAt;
        }
      if(!any)
         continue;

      MqlRates r[];
      ArraySetAsSeries(r, true);
      int got = CopyRates(_Symbol, tfs[t], oldest, now, r);
      if(got <= 0)
        {
         g_dataMissing = true;
         continue;
        }
      datetime currentBar = r[0].time;
      for(int i = 0; i < count; i++)
         if(LowestTF(levels[i].tfMask) == tfs[t])
            EvaluateLevel(levels[i], r, got, currentBar);
     }
  }

//+------------------------------------------------------------------+
//| Selection of the levels to display                                |
//+------------------------------------------------------------------+
int CompareLevels(const SLevel &a, const SLevel &b, const double refPrice)
  {
   if(InpLevelSelection == SELECT_RECENT)
     {
      if(a.start > b.start) return(-1);
      if(a.start < b.start) return(1);
      return(0);
     }
   double da = MathAbs(a.price - refPrice);
   double db = MathAbs(b.price - refPrice);
   if(da < db) return(-1);
   if(da > db) return(1);
   return(0);
  }

void SortIndices(int &idx[], const int n, const SLevel &levels[], const double refPrice)
  {
   // simple insertion sort, n is small
   for(int i = 1; i < n; i++)
     {
      int key = idx[i];
      int j = i - 1;
      while(j >= 0 && CompareLevels(levels[idx[j]], levels[key], refPrice) > 0)
        {
         idx[j + 1] = idx[j];
         j--;
        }
      idx[j + 1] = key;
     }
  }

void SelectLevels(SLevel &all[], const int count, const double refPrice, SLevel &out[], int &outCount)
  {
   int resIdx[], supIdx[];
   int nr = 0, ns = 0;
   ArrayResize(resIdx, count);
   ArrayResize(supIdx, count);
   for(int i = 0; i < count; i++)
     {
      if(InpHideBroken && all[i].broken)
         continue;
      bool isRes = (all[i].primaryShape > 0) || (all[i].primaryShape == 0 && all[i].price >= refPrice);
      if(isRes) resIdx[nr++] = i;
      else      supIdx[ns++] = i;
     }
   SortIndices(resIdx, nr, all, refPrice);
   SortIndices(supIdx, ns, all, refPrice);
   int keepR = MathMin(nr, MathMax(0, InpMaxResistance));
   int keepS = MathMin(ns, MathMax(0, InpMaxSupport));

   outCount = 0;
   ArrayResize(out, keepR + keepS);
   for(int i = 0; i < keepR; i++) CopyLevel(out[outCount++], all[resIdx[i]]);
   for(int i = 0; i < keepS; i++) CopyLevel(out[outCount++], all[supIdx[i]]);
  }

void CopyLevel(SLevel &dst, const SLevel &src)
  {
   dst.price        = src.price;
   dst.start        = src.start;
   dst.formedAt     = src.formedAt;
   dst.tfMask       = src.tfMask;
   dst.types        = src.types;
   dst.primaryShape = src.primaryShape;
   dst.hasOCL       = src.hasOCL;
   dst.oclKind      = src.oclKind;
   dst.oclTF        = src.oclTF;
   dst.fresh        = src.fresh;
   dst.broken       = src.broken;
  }

//+------------------------------------------------------------------+
//| Drawing                                                           |
//+------------------------------------------------------------------+
string BuildLabel(const SLevel &lv)
  {
   string s = "";
   if(InpShowTimeframe)
      s += TFMaskText(lv.tfMask);
   if(InpShowType)
      s += (s == "" ? "" : " ") + lv.types;
   if(InpShowStatus)
      s += (s == "" ? "" : " ") + (lv.fresh ? ShortToString(0x25CF) : "=");   // U+25CF black circle
   if(InpShowPrice)
      s += (s == "" ? "" : " ") + DoubleToString(lv.price, _Digits);
   return(s);
  }

void DrawLevel(const int index, const SLevel &lv, const datetime endTime)
  {
   string lname = LINE_PREFIX + IntegerToString(index);
   string tname = LABEL_PREFIX + IntegerToString(index);

   color  clr;
   ENUM_LINE_STYLE style;
   int    width;
   if(lv.hasOCL)
     {
      clr   = OCLColor(lv.oclTF, lv.oclKind);
      style = OCLLineStyle();
     }
   else
     {
      clr   = ShapeColor(lv.tfMask, lv.primaryShape >= 0);
      style = STYLE_SOLID;
     }
   if(lv.fresh)
      width = MathMax(1, InpFreshWidth);
   else
     {
      width = MathMax(1, InpUnfreshWidth);
      clr   = BlendWithBackground(clr, InpUnfreshTransp);
     }
   // MT5 only renders non-solid styles with width 1
   if(style != STYLE_SOLID)
      width = 1;

   if(ObjectFind(0, lname) < 0)
     {
      g_levelObjectsCreated = true;
      ObjectCreate(0, lname, OBJ_TREND, 0, lv.start, lv.price, endTime, lv.price);
      ObjectSetInteger(0, lname, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, lname, OBJPROP_RAY_LEFT, false);
      ObjectSetInteger(0, lname, OBJPROP_BACK, false);
      ObjectSetInteger(0, lname, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, lname, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, lname, OBJPROP_HIDDEN, true);
     }
   else
     {
      ObjectMove(0, lname, 0, lv.start, lv.price);
      ObjectMove(0, lname, 1, endTime, lv.price);
     }
   ObjectSetInteger(0, lname, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, lname, OBJPROP_STYLE, style);
   ObjectSetInteger(0, lname, OBJPROP_WIDTH, width);
   string tip = TFMaskText(lv.tfMask) + " " + lv.types + " @ " + DoubleToString(lv.price, _Digits)
                + (lv.fresh ? " | Fresh" : " | Tested") + (lv.broken ? " | Broken" : "");
   ObjectSetString(0, lname, OBJPROP_TOOLTIP, tip);

   if(!InpShowLabels)
     {
      ObjectDelete(0, tname);
      return;
     }
   if(ObjectFind(0, tname) < 0)
     {
      g_levelObjectsCreated = true;
      ObjectCreate(0, tname, OBJ_TEXT, 0, endTime, lv.price);
      ObjectSetInteger(0, tname, OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetInteger(0, tname, OBJPROP_BACK, false);
      ObjectSetInteger(0, tname, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, tname, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, tname, OBJPROP_HIDDEN, true);
      ObjectSetString(0, tname, OBJPROP_FONT, "Arial");
     }
   else
      ObjectMove(0, tname, 0, endTime, lv.price);
   ObjectSetString(0, tname, OBJPROP_TEXT, " " + BuildLabel(lv));
   ObjectSetInteger(0, tname, OBJPROP_FONTSIZE, LabelFontSize());
   ObjectSetInteger(0, tname, OBJPROP_COLOR, LabelTextColor());
   ObjectSetString(0, tname, OBJPROP_TOOLTIP, tip);
  }

void RemoveStaleObjects(const int fromIndex, const int toIndex)
  {
   for(int i = fromIndex; i < toIndex; i++)
     {
      ObjectDelete(0, LINE_PREFIX + IntegerToString(i));
      ObjectDelete(0, LABEL_PREFIX + IntegerToString(i));
     }
  }

//+------------------------------------------------------------------+
//| Main rebuild                                                      |
//+------------------------------------------------------------------+
void Rebuild(const datetime lastBarTime, const double lastClose)
  {
   g_dataMissing = false;
   int chartSeconds = PeriodSeconds(_Period);

   SCandidate cand[];
   int n = 0;
   ArrayResize(cand, 256);

   // Higher timeframes first so the merged label order is D, H4, H1 and HTF defines the primary shape
   if(InpShowDaily && chartSeconds <= PeriodSeconds(PERIOD_D1))
      CollectTimeframe(PERIOD_D1, true, InpShowDailyOCL, InpLookbackDaily, InpDailyOCLLookback, cand, n);
   if(InpShowH4 && chartSeconds <= PeriodSeconds(PERIOD_H4))
      CollectTimeframe(PERIOD_H4, true, InpShowH4OCL, InpLookbackH4, InpH4OCLLookback, cand, n);
   if(InpShowH1 && chartSeconds <= PeriodSeconds(PERIOD_H1))
      CollectTimeframe(PERIOD_H1, true, InpShowH1OCL, InpLookbackH1, InpH1OCLLookback, cand, n);

   SLevel merged[];
   int mergedCount = 0;
   MergeCandidates(cand, n, merged, mergedCount);

   EvaluateAll(merged, mergedCount);

   double refPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(refPrice <= 0)
      refPrice = lastClose;

   int shown = 0;
   SelectLevels(merged, mergedCount, refPrice, g_levels, shown);

   datetime endTime = lastBarTime + MathMax(1, InpExtendBars) * chartSeconds;
   g_levelObjectsCreated = false;
   for(int i = 0; i < shown; i++)
      DrawLevel(i, g_levels[i], endTime);
   if(shown < g_drawnCount)
      RemoveStaleObjects(shown, g_drawnCount);
   g_drawnCount = shown;

   // Chart objects are painted in creation order: re-create the table whenever new level
   // objects appeared so the dashboard always stays on top of lines and labels.
   if(g_levelObjectsCreated && InpShowTable)
      RecreateTable();
  }

//+------------------------------------------------------------------+
//| Bias table                                                        |
//+------------------------------------------------------------------+
bool IsRightCorner()
  {
   return(InpTableCorner == CORNER_RIGHT_UPPER || InpTableCorner == CORNER_RIGHT_LOWER);
  }

bool IsLowerCorner()
  {
   return(InpTableCorner == CORNER_LEFT_LOWER || InpTableCorner == CORNER_RIGHT_LOWER);
  }

int TableHeight()
  {
   return(TBL_HEADER_H + 4 * TBL_ROW_H + 4);
  }

// Places a label at table-relative coordinates. relX is measured from the table's left edge,
// relY from the table's top edge. alignRight anchors the text on its right side.
void PlaceText(const string name, const string text, const int relX, const int relY,
               const bool alignRight, const color clr, const bool bold = false)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
     }
   bool right = IsRightCorner();
   bool lower = IsLowerCorner();
   int xdist = right ? (InpTableX + TBL_WIDTH - relX) : (InpTableX + relX);
   int ydist = lower ? (InpTableY + TableHeight() - relY - TBL_ROW_H) : (InpTableY + relY);

   ENUM_ANCHOR_POINT anchor;
   if(alignRight)
      anchor = lower ? ANCHOR_RIGHT_LOWER : ANCHOR_RIGHT_UPPER;
   else
      anchor = lower ? ANCHOR_LEFT_LOWER : ANCHOR_LEFT_UPPER;

   ObjectSetInteger(0, name, OBJPROP_CORNER, InpTableCorner);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, xdist);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, ydist);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Arial Bold" : TBL_FONT);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, TBL_FONT_SIZE);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
  }

void PlaceRect(const string name, const int relY, const int height, const color bg, const color border)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
     }
   // A rectangle label always grows to the right and downwards from its anchor point, so in
   // right/lower corners the anchor must be placed at the far side of the table.
   bool right = IsRightCorner();
   bool lower = IsLowerCorner();
   int xdist = right ? (InpTableX + TBL_WIDTH) : InpTableX;
   int ydist = lower ? (InpTableY + TableHeight() - relY) : (InpTableY + relY);
   ObjectSetInteger(0, name, OBJPROP_CORNER, InpTableCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, xdist);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, ydist);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, TBL_WIDTH);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
  }

void CreateTable()
  {
   if(!InpShowTable)
      return;
   PlaceRect(TABLE_PREFIX + "BG", 0, TableHeight(), CLR_TBL_BG, CLR_TBL_BORDER);
   PlaceRect(TABLE_PREFIX + "HDR", 0, TBL_HEADER_H, CLR_TBL_HEADER, CLR_TBL_HEADER);
   PlaceText(TABLE_PREFIX + "TITLE", InpTableTitle, TBL_PAD, 3, false, CLR_TBL_TITLE, true);

   int y0 = TBL_HEADER_H + 2;
   PlaceText(TABLE_PREFIX + "SES_L", "Session", TBL_PAD, y0, false, CLR_TBL_LABEL);
   PlaceText(TABLE_PREFIX + "SES_V", "-", TBL_WIDTH - TBL_PAD, y0, true, CLR_SES_OFF);

   // separator row, centered: anchor the text at the middle of the table (U+2550 = double horizontal bar)
   string bars  = ShortToString(0x2550) + ShortToString(0x2550);
   string story = bars + " " + InpStorylineTitle + " " + bars;
   PlaceText(TABLE_PREFIX + "STORY", story, TBL_WIDTH / 2, y0 + TBL_ROW_H, false, CLR_TBL_STORY);
   ObjectSetInteger(0, TABLE_PREFIX + "STORY", OBJPROP_ANCHOR, IsLowerCorner() ? ANCHOR_LOWER : ANCHOR_UPPER);

   PlaceText(TABLE_PREFIX + "WK_L", "Weekly", TBL_PAD, y0 + 2 * TBL_ROW_H, false, CLR_TBL_LABEL);
   PlaceText(TABLE_PREFIX + "WK_V", "-", TBL_WIDTH - TBL_PAD, y0 + 2 * TBL_ROW_H, true, CLR_NEUTRAL);
   PlaceText(TABLE_PREFIX + "DY_L", "Daily", TBL_PAD, y0 + 3 * TBL_ROW_H, false, CLR_TBL_LABEL);
   PlaceText(TABLE_PREFIX + "DY_V", "-", TBL_WIDTH - TBL_PAD, y0 + 3 * TBL_ROW_H, true, CLR_NEUTRAL);
   g_tableCreated = true;
  }

void RecreateTable()
  {
   ObjectsDeleteAll(0, TABLE_PREFIX);
   g_tableCreated = false;
   g_prevSession  = "";
   g_prevWeekly   = "";
   g_prevDaily    = "";
   CreateTable();
   UpdateTable();
  }

string CurrentSession(color &clr)
  {
   datetime ny = NewYorkTime();
   MqlDateTime s;
   TimeToStruct(ny, s);
   int m = s.hour * 60 + s.min;

   // Weekend handling (New York time): closed from Friday NY close until the Sunday Asia open
   bool asiaCrossesMidnight = g_asia.valid && g_asia.startMin > g_asia.endMin;
   bool sundayOpen          = asiaCrossesMidnight && m >= g_asia.startMin;
   bool weekend = (s.day_of_week == 6) ||
                  (s.day_of_week == 0 && !sundayOpen) ||
                  (s.day_of_week == 5 && g_ny.valid && m >= g_ny.endMin);
   if(weekend)
     {
      clr = CLR_SES_OFF;
      return("Off-Market");
     }

   if(InRange(m, g_londonKZ)) { clr = CLR_SES_LONDON; return("London KZ"); }
   if(InRange(m, g_nyKZ))     { clr = CLR_SES_NY;     return("New York KZ"); }
   if(InRange(m, g_asiaKZ))   { clr = CLR_SES_ASIA;   return("Asia KZ"); }
   if(InRange(m, g_london))   { clr = CLR_SES_LONDON; return("London"); }
   if(InRange(m, g_ny))       { clr = CLR_SES_NY;     return("New York"); }
   if(InRange(m, g_asia))     { clr = CLR_SES_ASIA;   return("Asia"); }

   clr = CLR_SES_OFF;
   return("Off-Market");
  }

string Storyline(const ENUM_TIMEFRAMES tf, const double price, color &clr)
  {
   double open = iOpen(_Symbol, tf, 0);
   if(open <= 0 || price <= 0)
     {
      clr = CLR_NEUTRAL;
      return("N/A");
     }
   if(price > open) { clr = CLR_BULL;    return("BULLISH"); }
   if(price < open) { clr = CLR_BEAR;    return("BEARISH"); }
   clr = CLR_NEUTRAL;
   return("NEUTRAL");
  }

void UpdateTable()
  {
   if(!InpShowTable)
      return;
   if(!g_tableCreated)
      CreateTable();

   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(price <= 0)
      price = iClose(_Symbol, PERIOD_CURRENT, 0);

   color cs, cw, cd;
   string ses = CurrentSession(cs);
   string wk  = Storyline(PERIOD_W1, price, cw);
   string dy  = Storyline(PERIOD_D1, price, cd);

   bool changed = false;
   if(ses != g_prevSession)
     {
      ObjectSetString(0, TABLE_PREFIX + "SES_V", OBJPROP_TEXT, ses);
      ObjectSetInteger(0, TABLE_PREFIX + "SES_V", OBJPROP_COLOR, cs);
      g_prevSession = ses;
      changed = true;
     }
   if(wk != g_prevWeekly)
     {
      ObjectSetString(0, TABLE_PREFIX + "WK_V", OBJPROP_TEXT, wk);
      ObjectSetInteger(0, TABLE_PREFIX + "WK_V", OBJPROP_COLOR, cw);
      g_prevWeekly = wk;
      changed = true;
     }
   if(dy != g_prevDaily)
     {
      ObjectSetString(0, TABLE_PREFIX + "DY_V", OBJPROP_TEXT, dy);
      ObjectSetInteger(0, TABLE_PREFIX + "DY_V", OBJPROP_COLOR, cd);
      g_prevDaily = dy;
      changed = true;
     }
   if(changed)
      ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Standard handlers                                                 |
//+------------------------------------------------------------------+
int OnInit()
  {
   ParseRange(InpAsiaSession,   g_asia);
   ParseRange(InpAsiaKZ,        g_asiaKZ);
   ParseRange(InpLondonSession, g_london);
   ParseRange(InpLondonKZ,      g_londonKZ);
   ParseRange(InpNYSession,     g_ny);
   ParseRange(InpNYKZ,          g_nyKZ);

   if(InpAutoChartShift)
      ChartSetInteger(0, CHART_SHIFT, true);

   g_drawnCount  = 0;
   g_lastRebuild = 0;
   g_lastChartBar = 0;
   g_prevSession = "";
   g_prevWeekly  = "";
   g_prevDaily   = "";
   g_tableCreated = false;

   // Pre-request higher timeframe history so the first calculation has data
   MqlRates tmp[];
   CopyRates(_Symbol, PERIOD_D1, 0, 5, tmp);
   CopyRates(_Symbol, PERIOD_H4, 0, 5, tmp);
   CopyRates(_Symbol, PERIOD_H1, 0, 5, tmp);
   CopyRates(_Symbol, PERIOD_W1, 0, 2, tmp);

   CreateTable();
   UpdateTable();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   ObjectsDeleteAll(0, OBJ_PREFIX);
   ChartRedraw(0);
  }

void OnTimer()
  {
   UpdateTable();
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total < 3)
      return(0);

   // indexing direction of OnCalculate arrays is not guaranteed, so detect it
   int last = ArrayGetAsSeries(time) ? 0 : rates_total - 1;
   datetime lastBarTime = time[last];
   double   lastClose   = close[last];

   datetime now = TimeCurrent();
   bool newBar  = (lastBarTime != g_lastChartBar);
   bool stale   = (now - g_lastRebuild) >= 1;
   if(newBar || stale || g_dataMissing || prev_calculated == 0)
     {
      Rebuild(lastBarTime, lastClose);
      g_lastRebuild  = now;
      g_lastChartBar = lastBarTime;
      UpdateTable();
      ChartRedraw(0);
     }
   return(rates_total);
  }

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      // background color may have changed (theme), recompute colors on next tick
      g_lastRebuild = 0;
      ChartRedraw(0);
     }
  }
//+------------------------------------------------------------------+
