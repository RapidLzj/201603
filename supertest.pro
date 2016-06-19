readcol, 'supertest.lst', et, fn, format='i,a', count=nf
fi = strarr(nf) & bn = fi & redp = fi & rawp = redp
for i = 0, nf-1 do begin $
  p = strsplit(fn[i],'/',/ex) & $
  caldat,2450000+strmid(p[5],1),mn,dy,yr & $
  fi[i] = p[3] & bn[i] = strmid(p[7],0,10) & $
  redp[i] = string(format='("/data/red/bok/",A,"/pass1/",A,"/",I4.4,I2.2,I2.2,"/")',p[3],p[4],yr,mn,dy) & $
  rawp[i] = strmid(fn[i], 0, strlen(fn[i])-15) & $
endfor

for i = 0, nf-1 do begin $
  zb_pip, rawp[i], '/data/flattest/', bn[i], redp[i]+'bias.fits',redp[i]+'superflat.fits', $
    /magauto, /verbose, /ub1, /keep, /over & $
end

