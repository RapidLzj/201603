function zn_rm_overscan, dat
; use previous version

    ; image size
    nx = 4096 & nxa = 4160 & ny = 4136
    hnx = nx / 2 & hnxa = (nx + nxa) / 2 & hny = ny / 2

    dat_o = fltarr(nx, ny)
    dat_o[*, *] = dat[0:nx-1, 0:ny-1]

    os = fltarr(hny, 4)
    for line = 0, hny-1 do begin
        os[line, 0] = median(dat[ nx :hnxa-1,     line])
        os[line, 1] = median(dat[hnxa: nxa-1,     line])
        os[line, 2] = median(dat[ nx :hnxa-1, hny+line])
        os[line, 3] = median(dat[hnxa: nxa-1, hny+line])
    endfor

    p = findgen(hny)
    for g = 0, 3 do begin
        ab = poly_fit(p, os[*, g], 3)
        os[*, g] = poly(p, ab)
    endfor

    for line = 0, hny-1 do begin
        dat_o[  0:hnx-1,     line] -= os[line, 0]
        dat_o[hnx: nx-1,     line] -= os[line, 1]
        dat_o[  0:hnx-1, hny+line] -= os[line, 2]
        dat_o[hnx: nx-1, hny+line] -= os[line, 3]
    endfor

    return, dat_o
end
