;zn_pp_mklst, yr, mn, dy, filter, runcode
readcol, 'bat/xaodate', y, m, d0, d1, f1, f2, r, format='i,i,i,i,a,a,a', count=nd

fmtday = '("/data/red/XAO/",A,"/pass1/",A,"/",I4.4,I2.2,I2.2,"/")'

for k = 0, nd-1 do begin $
    for d = d0[k], d1[k] do begin $
        p = string(f1[k],r[k],y[k], m[k], d, format=fmtday) & $
        if file_test(p+"list/bias.lst") then $
            zn_pp_bias, p+"list/bias.lst", p+'bias.fits' & $
        p = string(f2[k],r[k],y[k], m[k], d, format=fmtday) & $
        if file_test(p+"list/bias.lst") then $
            zn_pp_bias, p+"list/bias.lst", p+'bias.fits' & $
    endfor & $
endfor

exit

