;zn_pp_mklst, yr, mn, dy, filter, runcode
readcol, 'bat/xaodate', y, m, d0, d1, f1, f2, r, format='i,i,i,i,a,a,a', count=nd

for k = 0, nd-1 do begin $
    for d = d0[k], d1[k] do begin $
;help,y[k],m[k],d,f1[k],f2[k],r[k],k &$
        zn_pp_mklst, y[k], m[k], d, f1[k], r[k] & $
        zn_pp_mklst, y[k], m[k], d, f2[k], r[k] & $
    endfor & $
endfor


