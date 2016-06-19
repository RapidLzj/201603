f = 0 & t = 0
read, f, t
print, f, t
readcol, 'bat/bok.date2.lst', r, y, m, d, format='a,i,i,i'
for k = f, t-1 do $
    obj_sh, y[k], m[k], d[k], r[k], 'good'

exit

