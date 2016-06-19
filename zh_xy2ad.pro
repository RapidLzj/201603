; convert x/y to ra/dec bu up to 7 ordered poly
; input: crx/y: x/y minus center, a/b: up to 39 elements of factor list
; order 7, 39 items, order 5, 23 items, order 3, 11 items
; a/bconst
; output: ra/dec, ra/dec of points by degree
pro zh_xy2ad, x, y, ab, ra, dec

  xyr_power = [ $
    [ 1, 0, 0, 2, 1, 0, 3, 2, 1, 0, 0, 4, 3, 2, 1, 0, 5, 4, 3, 2, 1, 0, 0, 6, 5, 4, 3, 2, 1, 0, 7, 6, 5, 4, 3, 2, 1, 0, 0 ], $
    [ 0, 1, 0, 0, 1, 2, 0, 1, 2, 3, 0, 0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 5, 0, 0, 1, 2, 3, 4, 5, 6, 0, 1, 2, 3, 4, 5, 6, 7, 0 ], $
    [ 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7 ] ]

  ns = n_elements(x)
  ;crx = x / 1000.0 & cry = y / 1000.0
  crx = x & cry = y
  
  r = sqrt(crx * crx + cry * cry)
  
  xyr = dblarr(ab.n_item, ns)
  yxr = dblarr(ab.n_item, ns)
  for c = 0, ab.n_item-1 do begin
    xyr[c, *] = crx ^ xyr_power[c,0] * cry ^ xyr_power[c,1] * r ^ xyr_power[c,2] 
    yxr[c, *] = cry ^ xyr_power[c,0] * crx ^ xyr_power[c,1] * r ^ xyr_power[c,2] 
  endfor

  ra  = (ab.a # xyr + ab.aconst)[0:*]
  dec = (ab.b # yxr + ab.bconst)[0:*]
 
end 