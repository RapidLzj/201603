function za_magerr, magstar, magerr, maglimit, $  ; input
    magfit, errfit, $                  ; output
    degree=degree, countlimit=countlimit, magrange=magrange

    r_default, degree, 1
    r_default, countlimit, 10
    r_default, magrange, 0.1

    ; default output, null value
    magfit = (findgen(21) - 10.0) * 0.2 + maglimit ; -2..+2, step 0.2
    errfit = fltarr(21) + 9.99
    errlimit = 9.99

    ix = where( magstar gt maglimit - magrange and magstar lt maglimit + magrange , nix) ; find stars close to the limit
    if nix eq 0 then begin ; no found
        return, errlimit

    endif else if degree lt 0 or nix lt countlimit then begin ; too few, directly mean
        errlimit = mean(magerr[ix])
        errfit = fltarr(21) + errlimit

    endif else begin
        if min(magstar[ix]) gt maglimit or max(magstar[ix]) lt maglimit then $
            return, maglimit ; one side, no fit

        r1 = poly_fit( magstar[ix], alog(magerr[ix]), degree, yfit=magerrfit )

        ;magdiff = abs(magstar[ix] - maglimit)
        ;kix = where(abs(magdiff) eq min(abs(magdiff)))
        errlimit = exp(poly(maglimit, r1)) ; magerr[ix[kix[0]]]
        errfit = exp(poly(magfit, r1))
    endelse

    return, errlimit
end