;f = 0 & t = 0
;read, f, t
;print, f, t
readcol, 'bat/bok.date2.lst', r, y, m, d, format='a,i,i,i',count=nn
for k = 0, nn-1 do $
    objr_sh, y[k], m[k], d[k], r[k]

exit

