function zh_conv_xy, xc, yc, magc, xs, ys, mags, sig
  if not keyword_set(sig) then sig = 60.0d

  nc = n_elements(magc)
  ns = n_elements(mags)

  ;fluxc = exp( -magc ) ;fltarr(nc)+1.0 ;
  ;fluxs = exp( -mags ) ;fltarr(ns)+1.0 ;

  res = 0.0d
  sig2 = 2.0 * sig^2
  sig1 = 17.0 * sig
  for is = 0, ns-1 do begin
    ix1 = where(abs(xs[is]-xc) lt sig1 and abs(ys[is]-yc) lt sig1, nix1)
    if nix1 gt 0 then begin
      csdis2 = ((xs[is]-xc[ix1])^2.0 + (ys[is]-yc[ix1])^2.0) / sig2
      ix2 = where( csdis2 lt 150.0d , nix2)
      if nix2 gt 0 then begin
        res += total( exp ( -csdis2[ix2] ) ) ; * fluxs[is] * fluxc[ix]
      endif
    endif
  endfor
  return, res
end
