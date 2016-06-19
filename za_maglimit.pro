function za_maglimit, magstar, magerr, errlimit, $  ; input
    magfit, errfit, $                  ; output
    degree=degree, countlimit=countlimit

    r_default, degree, 1
    r_default, countlimit, 10

    ; default output, null value
    magfit = (findgen(21) - 10.0) * 0.2 ; -2..+2, step 0.2
    errfit = fltarr(21)
    maglimit = 99.99

    ix = where( magerr gt errlimit * 0.5 and magerr lt errlimit / 0.5 , nix) ; find stars close to the limit
    if nix eq 0 then begin ; no found
        return, maglimit

    endif else if degree lt 0 or nix lt countlimit then begin ; too few, directly mean
        maglimit = mean(magstar[ix])
        magfit += maglimit
        errfit = fltarr(21) + errlimit

    endif else begin
        r1 = poly_fit( magstar[ix], alog(magerr[ix]), degree, yfit=magerrfit )
        magerrdiff = exp(magerrfit) - errlimit
        ; prevent only on side fit
        if min(magerrdiff) gt 0.0 or max(magerrdiff) lt 0.0 then return, maglimit

        kix = where(abs(magerrdiff) eq min(abs(magerrdiff)))
        maglimit = magstar[ix[kix[0]]]
        magfit += maglimit
        errfit = exp(poly(magfit, r1))
    endelse

    return, maglimit
end