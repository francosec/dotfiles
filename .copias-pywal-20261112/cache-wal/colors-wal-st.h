const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#020A13", /* black   */
  [1] = "#134E8D", /* red     */
  [2] = "#1B4290", /* green   */
  [3] = "#215CA6", /* yellow  */
  [4] = "#1968B2", /* blue    */
  [5] = "#2174CD", /* magenta */
  [6] = "#2497EA", /* cyan    */
  [7] = "#95e2f2", /* white   */

  /* 8 bright colors */
  [8]  = "#689ea9",  /* black   */
  [9]  = "#134E8D",  /* red     */
  [10] = "#1B4290", /* green   */
  [11] = "#215CA6", /* yellow  */
  [12] = "#1968B2", /* blue    */
  [13] = "#2174CD", /* magenta */
  [14] = "#2497EA", /* cyan    */
  [15] = "#95e2f2", /* white   */

  /* special colors */
  [256] = "#020A13", /* background */
  [257] = "#95e2f2", /* foreground */
  [258] = "#95e2f2",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
