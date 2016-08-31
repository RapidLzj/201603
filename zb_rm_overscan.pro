function zb_rm_overscan, dat, dir, dofit=dofit

  ; dat: original image of one emplifier, 2036*2048*uint16
  ; return: image removed overscan, 2016*2048*single32

  if ~keyword_set(dir) then dir = 1
  dofit = keyword_set(dofit)

  nx = 2016 & nxa = 2036 & ny = 2048 & nya = 2068

  ;dat_o = dblarr(nx, ny)
  ;dat_o[*, *] = dat[0:nx-1, 0:ny-1]
  dat_o = double(dat[0:nx-1, 0:ny-1])

  begin
    ;process overscan of x
    os = median(dat[nx:nxa-1, 0:ny-1], dim=1, /double)

    if dofit then begin
        p = dindgen(ny)
        ab = poly_fit(p, os, 3, yfit=osf, /double)
        ;osf = poly(p, ab)
    endif else begin
        osf = os
    endelse

    for line = 0, ny-1 do begin
      dat_o[0:nx-1, line] -= osf[line]
    endfor
  end

  if dir ne 1 then begin
    ; process overscan of y
    os = median(dat[0:nx-1, ny:nya-1], dim=2, /double)

    if dofit then begin
        p = dindgen(nx)
        ab = poly_fit(p, os, 3, yfit=osf, /double)
        ;osf = poly(p, ab)
    endif else begin
        osf = os
    endelse

    for line = 0, nx-1 do begin
      dat_o[line, 0:ny-1] -= osf[line]
    endfor

    ; add cross area
    os = median(dat[nx:nxa-1, ny:nya-1], /double)
    dat_o += os
  endif

  return, dat_o

end
