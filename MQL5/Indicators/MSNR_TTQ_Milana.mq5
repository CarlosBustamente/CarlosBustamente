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

#include <Canvas\Canvas.mqh>

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

enum ENUM_LABEL_COLOR
  {
   LABEL_COLOR_LINE  = 0, // Same color as the level line
   LABEL_COLOR_THEME = 1  // Theme color (dark / white)
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
input bool              InpRayRight           = true;          // Extend lines to the right edge (ray)
input int               InpExtendBars         = 20;            // Extend lines to the right (bars, if not ray)
input bool              InpAutoChartShift     = false;         // Enable chart shift on attach

input group "=== LABEL SETTINGS ==="
input bool              InpShowLabels         = true;          // Show labels
input ENUM_LABEL_SIZE   InpLabelSize          = LBL_SMALL;     // Label Size
input bool              InpShowPrice          = false;         // Show Price
input bool              InpShowTimeframe      = true;          // Show Timeframe
input bool              InpShowType           = true;          // Show Type (A/V/OCL)
input bool              InpShowStatus         = false;         // Show Status (dot = fresh, "=" = tested)
input int               InpLabelMargin        = 4;             // Label distance from the right edge (px)
input bool              InpAvoidOverlap       = true;          // Avoid overlapping labels
input string            InpLabelFont          = "Arial Black"; // Label font (Arial Black, Segoe UI Black, Impact...)
input ENUM_LABEL_COLOR  InpLabelColorMode     = LABEL_COLOR_LINE; // Label color

input group "=== DASHBOARD PANEL ==="
input bool              InpShowTable          = true;          // Show panel
input bool              InpPanelCollapsed     = false;         // Start collapsed (header only)
input ENUM_BASE_CORNER  InpTableCorner        = CORNER_LEFT_UPPER; // Panel corner
input int               InpTableX             = 10;            // Panel X offset (px)
input int               InpTableY             = 25;            // Panel Y offset (px)
input string            InpTableTitle         = "MSNR by TTQxMilana"; // Panel title
input string            InpStorylineTitle     = "STORYLINE";    // Storyline separator text (BIAS, STORYLINE...)
input int               InpToggleKey          = 80;            // Key code to hide/show the panel (80 = P)

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
#define KIND_A      1
#define KIND_V      2
#define KIND_OCL_O  3
#define KIND_OCL_C  4

#define TF_BIT_H1   1
#define TF_BIT_H4   2
#define TF_BIT_D1   4

// Canvas panel geometry (pixels)
#define PANEL_NAME       "MSNR_PANEL"
#define PNL_W            210
#define PNL_HDR_H        28
#define PNL_ROW_H        21
#define PNL_BTN_ROW_H    34
#define PNL_BTN_H        24
#define PNL_PAD          12
#define PNL_BODY_PAD     4
#define PNL_RADIUS       9

// Dashboard colors (always dark, like the original)
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
bool          g_levelObjectsCreated = false;
SSessionRange g_asia, g_asiaKZ, g_london, g_londonKZ, g_ny, g_nyKZ;

// last chart bar seen by OnCalculate (used to rebuild from UI events)
datetime      g_lastBarTime    = 0;
double        g_lastClose      = 0.0;

// canvas panel state
CCanvas       g_canvas;
bool          g_panelReady     = false;
bool          g_panelVisible   = true;
bool          g_panelCollapsed = false;
int           g_panelX         = 0;
int           g_panelY         = 0;
int           g_tfFilter       = 0;        // 0 = all timeframes, otherwise a TF_BIT_* mask
int           g_mouseX         = 0;
int           g_mouseY         = 0;
bool          g_mouseDown      = false;
uint          g_lastClickTick  = 0;

// cached panel values to avoid redundant repaints
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

string LabelFontName()
  {
   return(InpLabelFont == "" ? "Arial Black" : InpLabelFont);
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
      if(g_tfFilter != 0 && (all[i].tfMask & g_tfFilter) == 0)   // panel timeframe filter
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
   color labelClr = (InpLabelColorMode == LABEL_COLOR_LINE) ? clr : LabelTextColor();
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
      ObjectSetInteger(0, lname, OBJPROP_RAY_RIGHT, InpRayRight);
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
   // Labels are pixel-based objects pinned to the right edge of the visible chart area, so they
   // stay visible no matter how far the chart is scrolled. Their Y is computed in PositionLabels().
   if(ObjectFind(0, tname) < 0)
     {
      g_levelObjectsCreated = true;
      ObjectCreate(0, tname, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, tname, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, tname, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, tname, OBJPROP_BACK, false);
      ObjectSetInteger(0, tname, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, tname, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, tname, OBJPROP_HIDDEN, true);
      ObjectSetString(0, tname, OBJPROP_FONT, LabelFontName());
      ObjectSetInteger(0, tname, OBJPROP_XDISTANCE, InpLabelMargin);
      ObjectSetInteger(0, tname, OBJPROP_YDISTANCE, -100);
     }
   ObjectSetString(0, tname, OBJPROP_TEXT, BuildLabel(lv));
   ObjectSetInteger(0, tname, OBJPROP_FONTSIZE, LabelFontSize());
   ObjectSetInteger(0, tname, OBJPROP_COLOR, labelClr);
   ObjectSetString(0, tname, OBJPROP_TOOLTIP, tip);
  }

//+------------------------------------------------------------------+
//| Places every level label at the right edge of the chart, just     |
//| above its line, pushing labels apart when they would overlap.     |
//+------------------------------------------------------------------+
void PositionLabels()
  {
   if(!InpShowLabels || g_drawnCount <= 0)
      return;

   int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   int firstBar    = (int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR, 0);
   datetime refTime = iTime(_Symbol, PERIOD_CURRENT, MathMax(0, firstBar));
   if(refTime == 0)
      refTime = TimeCurrent();

   TextSetFont(LabelFontName(), -LabelFontSize() * 10, FW_BOLD);

   int    ys[], order[];
   int    ws[], hs[];
   ArrayResize(ys, g_drawnCount);
   ArrayResize(order, g_drawnCount);
   ArrayResize(ws, g_drawnCount);
   ArrayResize(hs, g_drawnCount);

   uint textW = 0, textH = 0;
   int maxW = 0;
   for(int i = 0; i < g_drawnCount; i++)
     {
      int x = 0, y = 0;
      if(!ChartTimePriceToXY(0, 0, refTime, g_levels[i].price, x, y))
         y = -10000;
      ys[i]    = y;
      order[i] = i;
      string text = BuildLabel(g_levels[i]);
      if(!TextGetSize(text, textW, textH))
        {
         textW = (uint)(StringLen(text) * 6);
         textH = 12;
        }
      ws[i] = (int)textW;
      hs[i] = (int)textH;
      if(ws[i] > maxW)
         maxW = ws[i];
     }

   // sort by vertical position (top of chart first)
   for(int i = 1; i < g_drawnCount; i++)
     {
      int key = order[i];
      int j = i - 1;
      while(j >= 0 && ys[order[j]] > ys[key])
        {
         order[j + 1] = order[j];
         j--;
        }
      order[j + 1] = key;
     }

   // two columns: labels that would collide in the first column move to a second column on the left,
   // and if that one is busy as well they are pushed below the previous label
   int bottomCol0 = -100000, bottomCol1 = -100000;
   for(int k = 0; k < g_drawnCount; k++)
     {
      int i = order[k];
      string tname = LABEL_PREFIX + IntegerToString(i);
      if(ObjectFind(0, tname) < 0)
         continue;

      int h   = hs[i];
      int top = ys[i] - h - 1;      // sit just above the line
      int xdist = InpLabelMargin;
      if(InpAvoidOverlap)
        {
         if(top < bottomCol0)
           {
            if(top >= bottomCol1)
              {
               xdist = InpLabelMargin + maxW + 6;
               bottomCol1 = top + h;
              }
            else
              {
               top = bottomCol0;
               bottomCol0 = top + h;
              }
           }
         else
            bottomCol0 = top + h;
        }

      bool visible = (ys[i] > -5000) && (top + h >= 0) && (top <= chartHeight);
      ObjectSetInteger(0, tname, OBJPROP_TIMEFRAMES, visible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
      ObjectSetInteger(0, tname, OBJPROP_XDISTANCE, xdist);
      ObjectSetInteger(0, tname, OBJPROP_YDISTANCE, top);
     }
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

   // Chart objects are painted in creation order: re-create the panel whenever new level
   // objects appeared so the dashboard always stays on top of lines and labels.
   if(g_levelObjectsCreated && InpShowTable)
      PanelRecreate();

   PositionLabels();
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

//+------------------------------------------------------------------+
//| Canvas dashboard                                                  |
//| Rounded semi-transparent panel drawn with CCanvas: session,       |
//| storyline and timeframe filter buttons (ALL / H1 / H4 / D).       |
//| Click on the header to collapse/expand, press the toggle key to   |
//| hide/show the whole panel.                                        |
//+------------------------------------------------------------------+
uint ToARGB(const color c, const int alpha = 255)
  {
   return(ColorToARGB(c, (uchar)MathMax(0, MathMin(255, alpha))));
  }

int PanelHeight()
  {
   if(g_panelCollapsed)
      return(PNL_HDR_H);
   return(PNL_HDR_H + PNL_BODY_PAD + 4 * PNL_ROW_H + PNL_BTN_ROW_H + PNL_BODY_PAD);
  }

// absolute pixel position of the panel's upper-left corner, derived from the configured corner
void PanelComputePosition()
  {
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   int chartH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   int h = PanelHeight();
   bool right = (InpTableCorner == CORNER_RIGHT_UPPER || InpTableCorner == CORNER_RIGHT_LOWER);
   bool lower = (InpTableCorner == CORNER_LEFT_LOWER  || InpTableCorner == CORNER_RIGHT_LOWER);
   g_panelX = right ? (chartW - InpTableX - PNL_W) : InpTableX;
   g_panelY = lower ? (chartH - InpTableY - h) : InpTableY;
   if(g_panelX < 0) g_panelX = 0;
   if(g_panelY < 0) g_panelY = 0;
  }

void FillRoundRect(const int x1, const int y1, const int x2, const int y2, const int r, const uint clr)
  {
   g_canvas.FillRectangle(x1 + r, y1, x2 - r, y2, clr);
   g_canvas.FillRectangle(x1, y1 + r, x1 + r, y2 - r, clr);
   g_canvas.FillRectangle(x2 - r, y1 + r, x2, y2 - r, clr);
   g_canvas.FillCircle(x1 + r, y1 + r, r, clr);
   g_canvas.FillCircle(x2 - r, y1 + r, r, clr);
   g_canvas.FillCircle(x1 + r, y2 - r, r, clr);
   g_canvas.FillCircle(x2 - r, y2 - r, r, clr);
  }

bool PanelCreate()
  {
   if(!InpShowTable)
      return(false);
   PanelComputePosition();
   int h = PanelHeight();
   if(!g_canvas.CreateBitmapLabel(0, 0, PANEL_NAME, g_panelX, g_panelY, PNL_W, h, COLOR_FORMAT_ARGB_NORMALIZE))
     {
      Print("MSNR: cannot create canvas panel, error ", GetLastError());
      return(false);
     }
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_BACK, false);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_TIMEFRAMES, g_panelVisible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
   g_panelReady = true;
   PanelDraw();
   return(true);
  }

void PanelDestroy()
  {
   if(g_panelReady)
      g_canvas.Destroy();
   ObjectDelete(0, PANEL_NAME);
   g_panelReady = false;
  }

// re-created so that it is painted above level lines/labels (objects are drawn in creation order)
void PanelRecreate()
  {
   PanelDestroy();
   PanelCreate();
  }

void PanelApplyGeometry()
  {
   if(!g_panelReady)
      return;
   PanelComputePosition();
   int h = PanelHeight();
   if(g_canvas.Height() != h)
      g_canvas.Resize(PNL_W, h);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_XDISTANCE, g_panelX);
   ObjectSetInteger(0, PANEL_NAME, OBJPROP_YDISTANCE, g_panelY);
  }

void PanelButtonRect(const int index, int &x1, int &y1, int &x2, int &y2)
  {
   int rowTop = PNL_HDR_H + PNL_BODY_PAD + 4 * PNL_ROW_H;
   int gap    = 6;
   int bw     = (PNL_W - 2 * PNL_PAD - 3 * gap) / 4;
   x1 = PNL_PAD + index * (bw + gap);
   x2 = x1 + bw - 1;
   y1 = rowTop + (PNL_BTN_ROW_H - PNL_BTN_H) / 2;
   y2 = y1 + PNL_BTN_H - 1;
  }

void PanelDraw()
  {
   if(!g_panelReady)
      return;

   int w = PNL_W;
   int h = PanelHeight();
   g_canvas.Erase(0);   // fully transparent

   // body
   FillRoundRect(0, 0, w - 1, h - 1, PNL_RADIUS, ToARGB(C'22,26,36', 235));
   // header (rounded top, squared bottom when expanded) with a soft two-tone gradient
   FillRoundRect(0, 0, w - 1, PNL_HDR_H - 1, PNL_RADIUS, ToARGB(C'41,98,255'));
   if(!g_panelCollapsed)
      g_canvas.FillRectangle(0, PNL_HDR_H - PNL_RADIUS, w - 1, PNL_HDR_H - 1, ToARGB(C'41,98,255'));
   g_canvas.FillRectangle(0, PNL_HDR_H / 2, w - 1, PNL_HDR_H - 1 - (g_panelCollapsed ? PNL_RADIUS : 0), ToARGB(C'33,84,230'));
   if(!g_panelCollapsed)
      g_canvas.FillRectangle(0, PNL_HDR_H - 1, w - 1, PNL_HDR_H - 1, ToARGB(C'80,130,255'));

   // title + collapse button
   g_canvas.FontSet("Segoe UI", -100, FW_BOLD);
   g_canvas.TextOut(PNL_PAD, PNL_HDR_H / 2, InpTableTitle, ToARGB(clrWhite), TA_LEFT | TA_VCENTER);
   int bx = w - PNL_PAD - 8, by = PNL_HDR_H / 2;
   g_canvas.FillCircle(bx, by, 8, ToARGB(C'20,55,170'));
   g_canvas.FillRectangle(bx - 4, by - 1, bx + 4, by, ToARGB(clrWhite));
   if(g_panelCollapsed)
      g_canvas.FillRectangle(bx - 1, by - 4, bx, by + 4, ToARGB(clrWhite));

   if(!g_panelCollapsed)
     {
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(price <= 0)
         price = iClose(_Symbol, PERIOD_CURRENT, 0);
      color cs, cw, cd;
      string ses = CurrentSession(cs);
      string wk  = Storyline(PERIOD_W1, price, cw);
      string dy  = Storyline(PERIOD_D1, price, cd);

      int y = PNL_HDR_H + PNL_BODY_PAD;
      uint clrLabel = ToARGB(C'170,176,190');

      // Session row: value inside a colored pill
      g_canvas.FontSet("Segoe UI", -90, FW_NORMAL);
      g_canvas.TextOut(PNL_PAD, y + PNL_ROW_H / 2, "Session", clrLabel, TA_LEFT | TA_VCENTER);
      g_canvas.FontSet("Segoe UI", -90, FW_BOLD);
      int tw = g_canvas.TextWidth(ses);
      int px2 = w - PNL_PAD, px1 = px2 - tw - 14;
      FillRoundRect(px1, y + 2, px2, y + PNL_ROW_H - 3, 7, ToARGB(cs, 60));
      g_canvas.TextOut(px2 - 7, y + PNL_ROW_H / 2, ses, ToARGB(cs), TA_RIGHT | TA_VCENTER);
      y += PNL_ROW_H;

      // Storyline separator
      g_canvas.FontSet("Segoe UI", -80, FW_BOLD);
      string story = InpStorylineTitle;
      StringToUpper(story);
      int sw = g_canvas.TextWidth(story);
      int cx = w / 2, cy = y + PNL_ROW_H / 2;
      uint gold = ToARGB(C'255,213,79');
      g_canvas.Line(PNL_PAD, cy, cx - sw / 2 - 8, cy, ToARGB(C'255,213,79', 140));
      g_canvas.Line(cx + sw / 2 + 8, cy, w - PNL_PAD - 1, cy, ToARGB(C'255,213,79', 140));
      g_canvas.TextOut(cx, cy, story, gold, TA_CENTER | TA_VCENTER);
      y += PNL_ROW_H;

      // Weekly / Daily rows
      g_canvas.FontSet("Segoe UI", -90, FW_NORMAL);
      g_canvas.TextOut(PNL_PAD, y + PNL_ROW_H / 2, "Weekly", clrLabel, TA_LEFT | TA_VCENTER);
      g_canvas.FontSet("Segoe UI", -90, FW_BOLD);
      g_canvas.TextOut(w - PNL_PAD, y + PNL_ROW_H / 2, wk, ToARGB(cw), TA_RIGHT | TA_VCENTER);
      y += PNL_ROW_H;
      g_canvas.FontSet("Segoe UI", -90, FW_NORMAL);
      g_canvas.TextOut(PNL_PAD, y + PNL_ROW_H / 2, "Daily", clrLabel, TA_LEFT | TA_VCENTER);
      g_canvas.FontSet("Segoe UI", -90, FW_BOLD);
      g_canvas.TextOut(w - PNL_PAD, y + PNL_ROW_H / 2, dy, ToARGB(cd), TA_RIGHT | TA_VCENTER);
      y += PNL_ROW_H;

      // Timeframe filter buttons
      string names[4];
      names[0] = "ALL"; names[1] = "H1"; names[2] = "H4"; names[3] = "D";
      int masks[4];
      masks[0] = 0; masks[1] = TF_BIT_H1; masks[2] = TF_BIT_H4; masks[3] = TF_BIT_D1;
      g_canvas.FontSet("Segoe UI", -85, FW_BOLD);
      for(int i = 0; i < 4; i++)
        {
         int x1, y1, x2, y2;
         PanelButtonRect(i, x1, y1, x2, y2);
         bool active = (g_tfFilter == masks[i]);
         if(active)
           {
            FillRoundRect(x1, y1, x2, y2, 5, ToARGB(C'41,98,255'));
            FillRoundRect(x1, y1, x2, y1 + (y2 - y1) / 2, 5, ToARGB(C'62,116,255'));
            g_canvas.FillRectangle(x1, y1 + 5, x2, y1 + (y2 - y1) / 2, ToARGB(C'62,116,255'));
           }
         else
            FillRoundRect(x1, y1, x2, y2, 5, ToARGB(C'44,50,66'));
         g_canvas.TextOut((x1 + x2) / 2, (y1 + y2) / 2 + 1, names[i],
                          active ? ToARGB(clrWhite) : ToARGB(C'190,196,210'), TA_CENTER | TA_VCENTER);
        }
     }

   g_canvas.Update(false);
  }

void PanelSetVisible(const bool visible)
  {
   g_panelVisible = visible;
   if(g_panelReady)
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_TIMEFRAMES, visible ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
  }

// returns true when the click was consumed by the panel
bool PanelHandleClick(const int x, const int y)
  {
   if(!g_panelReady || !g_panelVisible)
      return(false);
   int px = x - g_panelX;
   int py = y - g_panelY;
   if(px < 0 || py < 0 || px >= PNL_W || py >= PanelHeight())
      return(false);

   if(py < PNL_HDR_H)
     {
      g_panelCollapsed = !g_panelCollapsed;
      PanelApplyGeometry();
      PanelDraw();
      return(true);
     }
   if(!g_panelCollapsed)
     {
      int masks[4];
      masks[0] = 0; masks[1] = TF_BIT_H1; masks[2] = TF_BIT_H4; masks[3] = TF_BIT_D1;
      for(int i = 0; i < 4; i++)
        {
         int x1, y1, x2, y2;
         PanelButtonRect(i, x1, y1, x2, y2);
         if(px >= x1 && px <= x2 && py >= y1 && py <= y2)
           {
            g_tfFilter = masks[i];
            if(g_lastBarTime > 0)
               Rebuild(g_lastBarTime, g_lastClose);
            PanelDraw();
            return(true);
           }
        }
     }
   return(true);
  }

void UpdateTable()
  {
   if(!InpShowTable)
      return;
   if(!g_panelReady)
      PanelCreate();
   if(!g_panelReady || g_panelCollapsed)
      return;

   // only repaint when the displayed values changed
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(price <= 0)
      price = iClose(_Symbol, PERIOD_CURRENT, 0);
   color cs, cw, cd;
   string ses = CurrentSession(cs);
   string wk  = Storyline(PERIOD_W1, price, cw);
   string dy  = Storyline(PERIOD_D1, price, cd);
   if(ses != g_prevSession || wk != g_prevWeekly || dy != g_prevDaily)
     {
      g_prevSession = ses;
      g_prevWeekly  = wk;
      g_prevDaily   = dy;
      PanelDraw();
      ChartRedraw(0);
     }
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
   g_panelReady     = false;
   g_panelVisible   = true;
   g_panelCollapsed = InpPanelCollapsed;
   g_tfFilter       = 0;
   g_mouseDown      = false;

   // mouse move events are needed to detect clicks on the canvas panel
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);

   // Pre-request higher timeframe history so the first calculation has data
   MqlRates tmp[];
   CopyRates(_Symbol, PERIOD_D1, 0, 5, tmp);
   CopyRates(_Symbol, PERIOD_H4, 0, 5, tmp);
   CopyRates(_Symbol, PERIOD_H1, 0, 5, tmp);
   CopyRates(_Symbol, PERIOD_W1, 0, 2, tmp);

   PanelCreate();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   PanelDestroy();
   ObjectsDeleteAll(0, OBJ_PREFIX);
   ChartRedraw(0);
  }

void OnTimer()
  {
   UpdateTable();
   // keeps labels glued to the right edge even when there are no ticks (weekend / scroll)
   PositionLabels();
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

   g_lastBarTime = lastBarTime;
   g_lastClose   = lastClose;

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
      // scroll / zoom / resize / scale change: re-pin the labels, keep the panel in its corner
      g_lastRebuild = 0;
      PanelApplyGeometry();
      PositionLabels();
      ChartRedraw(0);
      return;
     }

   if(id == CHARTEVENT_MOUSE_MOVE)
     {
      // sparam holds the mouse button flags; bit 0 = left button pressed
      g_mouseX = (int)lparam;
      g_mouseY = (int)dparam;
      bool down = ((StringToInteger(sparam) & 1) != 0);
      if(down && !g_mouseDown)
         HandleClick(g_mouseX, g_mouseY);
      g_mouseDown = down;
      return;
     }

   if(id == CHARTEVENT_CLICK)
     {
      HandleClick((int)lparam, (int)dparam);
      return;
     }

   if(id == CHARTEVENT_OBJECT_CLICK && sparam == PANEL_NAME)
     {
      HandleClick(g_mouseX, g_mouseY);
      return;
     }

   if(id == CHARTEVENT_KEYDOWN && (int)lparam == InpToggleKey)
     {
      PanelSetVisible(!g_panelVisible);
      ChartRedraw(0);
      return;
     }
  }

// Same click may arrive through several events (mouse move, click, object click); handle it once.
void HandleClick(const int x, const int y)
  {
   uint tick = GetTickCount();
   if(tick - g_lastClickTick < 400)
      return;
   if(PanelHandleClick(x, y))
     {
      g_lastClickTick = tick;
      ChartRedraw(0);
     }
  }
//+------------------------------------------------------------------+
