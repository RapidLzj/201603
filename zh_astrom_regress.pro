function zh_astrom_regress, x, y, rac, decc, AST_INI=ast_ini, LEVEL=level, RAS=ras, DECS=decs

xyr_power = [ $
  [ 1, 0, 0, 2, 1, 0, 3, 2, 1, 0, 0, 4, 3, 2, 1, 0, 5, 4, 3, 2, 1, 0, 0, 6, 5, 4, 3, 2, 1, 0, 7, 6, 5, 4, 3, 2, 1, 0, 0 ], $
  [ 0, 1, 0, 0, 1, 2, 0, 1, 2, 3, 0, 0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 5, 0, 0, 1, 2, 3, 4, 5, 6, 0, 1, 2, 3, 4, 5, 6, 7, 0 ], $
  [ 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7 ] ]
  
  if ~ keyword_set(level) then level = 5
  case level of
    7: ni = 39
    6: ni = 30
    5: ni = 23
    4: ni = 16
    3: ni = 11
    2: ni = 6
    1: ni = 3
    0: ni = 2
  endcase
  
  ns = n_elements(x)
  if keyword_set(ast_ini) then begin
    crx = x - ast_ini.crpix[0]
    cry = y - ast_ini.crpix[1]
    crra  = (rac  - ast_ini.crval[0])
    crdec = (decc - ast_ini.crval[1])
  endif else begin
    crx = x[0:*]
    cry = y[0:*]
    crra  = rac[0:*]
    crdec = decc[0:*]
  endelse
  ; crx /= 1000.0 & cry /= 1000.0
  r = sqrt(crx * crx + cry * cry)
  
  xyr = dblarr(ni, ns)
  yxr = dblarr(ni, ns)
  for c = 0, ni-1 do begin
    xyr[c, *] = crx ^ xyr_power[c,0] * cry ^ xyr_power[c,1] * r ^ xyr_power[c,2] 
    yxr[c, *] = cry ^ xyr_power[c,0] * crx ^ xyr_power[c,1] * r ^ xyr_power[c,2] 
  endfor
  
  measure_errors = replicate(0.5/3600, n_elements(crdec))
  a = regress(xyr, crra,  SIGMA=asigma, CONST=aconst, MEASURE_ERRORS=measure_errors, YFIT=ras )
  b = regress(yxr, crdec, SIGMA=bsigma, CONST=bconst, MEASURE_ERRORS=measure_errors, YFIT=decs)
  
  ; analysis
  ;r_ra  = ra  - crra  & avg_r_ra  = avg(r_ra)  & sig_r_ra  = stddev(r_ra)
  ;r_dec = dec - crdec & avg_r_dec = avg(r_dec) & sig_r_dec = stddev(r_dec)
  
  ;print, format='("RA  :",F8.4,"~",F8.4,"   ra5  :",F8.4,"~",F8.4,"   ra3  :",F8.4,"~",F8.4)', $
  ;  avg_r_ra7, sig_r_ra7, avg_r_ra5, sig_r_ra5, avg_r_ra3, sig_r_ra3
  ;print, format='("dec7 :",F8.4,"~",F8.4,"   dec5 :",F8.4,"~",F8.4,"   dec3 :",F8.4,"~",F8.4)', $
  ;  avg_r_dec7, sig_r_dec7, avg_r_dec5, sig_r_dec5, avg_r_dec3, sig_r_dec3
    
  return, { level: level, n_item:ni, $
    aconst:aconst, a:a[0:*], asigma:asigma, $
    bconst:bconst, b:b[0:*], bsigma:bsigma }
end

  
