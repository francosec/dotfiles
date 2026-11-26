static const char norm_fg[] = "#95e2f2";
static const char norm_bg[] = "#020A13";
static const char norm_border[] = "#689ea9";

static const char sel_fg[] = "#95e2f2";
static const char sel_bg[] = "#1B4290";
static const char sel_border[] = "#95e2f2";

static const char urg_fg[] = "#95e2f2";
static const char urg_bg[] = "#134E8D";
static const char urg_border[] = "#134E8D";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
