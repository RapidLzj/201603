; convert ra/dec to x/y bu up to 7 ordered poly
; input: ra/dec, ab: up to 39 elements of factor list
; order 7, 39 items, order 5, 23 items, order 3, 11 items
; a/bconst
; output: x/y, relative to center
pro zh_ad2xy, ra, dec, ab, x, y, precision=precision

  if not keyword_set(precision) then precision = 2
  precision = (precision < 3) > 1

  ns = n_elements(ra)

  ; use grid, for each point, find nearest
  ; grid size will shrink 

  ; use 0/0 (image center) as initial position
  x = fltarr(ns) & y = x
  steps = [300.0, 10.0, 0.3, 0.01] & ntry1 = 16 & ntry = ntry1+ntry1+1
  gridx = fltarr(ntry, ntry) & gridy = gridx
  
  ;first grid, initial position are all center
  ss = 0  
  for k=0,ntry-1 do begin gridx[k,*]=(k-ntry1)*steps[ss] & gridy[*,k]=(k-ntry1)*steps[ss] & endfor
  ; grid around original x/y
  gx = gridx & gy = gridy
  ; grid x/y to grid ra/dec
  zh_xy2ad, gx, gy, ab, gra, gdec
  for k = 0, ns-1 do begin
    ; find grid point  nearest to ra/dex
    dis = r_distance(ra[k], dec[k], gra, gdec)
    ix = (where(dis eq min(dis)))[0]
    ; update x/y
    x[k] = gx[ix] & y[k] = gy[ix]
  endfor
  
  ; next steps
  for ss = 1, precision do begin
    ; grid base
    for k=0,ntry-1 do begin gridx[k,*]=(k-ntry1)*steps[ss] & gridy[*,k]=(k-ntry1)*steps[ss] & endfor
  
    for k = 0, ns-1 do begin
      ; grid around original x/y
      gx = x[k] + gridx & gy = y[k] + gridy
      ; grid x/y to grid ra/dec
      zh_xy2ad, gx, gy, ab, gra, gdec
      ; find grid point  nearest to ra/dex
      dis = r_distance(ra[k], dec[k], gra, gdec)
      ix = (where(dis eq min(dis)))[0]
      ; update x/y
      x[k] = gx[ix] & y[k] = gy[ix]
    endfor
  
  endfor
 
end 
