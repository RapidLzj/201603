function zb_pip_magcalibrate, sci_path, file, $
            magauto, catamag, checkmag, matchdis=matchdis, magmatchmax=magmatchmax$
            version=version, screenmode=screenmode

    r_default, magauto, 0
    r_default, catamag, 'catalog/HM1998.fits'
    r_default, checkmag, [15.0, 16.0, 17.0, 18.0, 19.0]
    r_default, matchdis, 0.002  ; 7.2 as
    r_default, magmatchmax, 60
    r_default, screenmode, 1
    r_default, version, '.' & if version ne '.' then version = '.' + version else version = ''
    @zh_const.pro

    wcs_ldac = sci_path + file + '.wcs.ldac'
    mag_ldac = sci_path + file + version + '.mag.ldac'
    mag_cat  = sci_path + file + version + '.mag.cat'

    ; load astrometry result
    stars = r_ldac_read(wcs_ldac, hdr, /silent)
    n_star = n_elements(stars)

    ; load catalogue
    magcatalog = mrdfits(catamag, 1, /silent)

    ; assume no match of catalog
    mag_const = 99.99
    nmag = 0

    ; use correct and bright enough stars only
    six = where(stars.mag_auto lt 90.0 and stars.magerr_auto lt 0.05, nsix)
    mras = stars[six].radeg & mdecs = stars[six].decdeg
    mmags = stars[six].mag_auto

    ; 20160311: no region judge, use whole catalog, and use r_match function
    ; ra/dec low and high of data
    ;border_ra_l  = min(mras)
    ;border_ra_h  = max(mras)
    ;border_dec_l = min(mdecs)
    ;border_dec_h = max(mdecs)

    ; if accross 360(0) degree
    ;if border_ra_h - border_ra_l ge 350 then begin
    ;  ix = where(mras gt 300.0, n_ix)
    ;  if (n_ix gt 0) then mras[ix] -= 360.0
    ;  border_ra_l  = min(mras) + 360.0
    ;  border_ra_h  = max(mras)
    ;endif

    ; catalogue stars inside the area
    ;if border_ra_l lt border_ra_h then begin
    ;  c_ix = where(magcatalog.radeg  ge border_ra_l  and magcatalog.radeg  le border_ra_h $
    ;    and magcatalog.decdeg ge border_dec_l and magcatalog.decdeg le border_dec_h, n_in)
    ;endif else begin
    ;  c_ix = where(magcatalog.radeg  le border_ra_l  and magcatalog.radeg  ge border_ra_h $
    ;    and magcatalog.decdeg ge border_dec_l and magcatalog.decdeg le border_dec_h, n_in)
    ;endelse

    ;if n_in eq 0 then begin
    ;  goto, magfail
    ;endif
    ; match stars with catalogue
    ;cata_in = magcatalog[c_ix]

    ; 20160311: change cata_in to mag limit, but not coord limit, make sure mag is valid

    fi = strtrim(sxpar(hdr, 'FILTER'))
    if fi eq 'strumu' then $
        mmagc = magcatalog.u $
    else if fi eq 'strumv' then $
        mmagc = magcatalog.v $
    else if fi eq 'b' then $
        mmagc = magcatalog.b $
    else $
        mmagc = magcatalog.y
    ix = where(finite(mmagc) and mmagc lt 90.0)
    cata_in = magcatalog[ix]
    mmagc = mmagc[ix]
    mrac  = cata_in.radeg
    mdecc = cata_in.decdeg

    ;ix = where(mrac gt 300.0, n_ix)
    ;if (n_ix gt 0) then mrac[ix] -= 360.0

    ; use r_match to match image stars and catalog stars, no manual match
    ; find matches
    ;mcsdis = [0.0] & mcid = [-1] & msid = [-1] & mmagdiff = [0.0] & magmatch = 0
    ;for ii = 0, n_in-1 do begin
    ;  dis = r_distance(mrac[ii], mdecc[ii], mras, mdecs) * 3600.0
    ;  d_ix = where(dis lt 2.0, n_dis)
    ;  if finite(mmagc[ii]) and n_dis gt 0 then begin
    ;    magmatch += n_dis
    ;    mcsdis = [mcsdis, dis[d_ix]]
    ;    mcid = [mcid, replicate(ii, n_dis)]
    ;    msid = [msid, d_ix]
    ;    mmagdiff = [mmagdiff, mmagc[ii]-mmags[d_ix] ]
    ;  endif
    ;endfor

    msgres = r_match(mrac, mdecc, mmagc, mras, mdecs, mmags, magmatch, mcid, msid, mcsdis, $
        matchlimit=1, maxdis=matchdis)


    if magmatch eq 0 then begin
        goto, magfail
    endif

    mmagdiff = mmagc[mcid]-mmags[msid]
    ;mcsdis = mcsdis[1:*] & mcid = mcid[1:*] & msid = msid[1:*] & mmagdiff = mmagdiff[1:*]
    hit = strarr(magmatch) + ' '
    ;ix = where(mmagdiff gt -6.0 and mmagdiff lt 3.0) ; empirical data
    ;if ix[0] ne -1 then begin
    ;magmed = lzju_trisigma(mmagdiff , magstd, /normal )
    ;magix = where(abs(magd - magmed) le 0.5, nmag)
    if magmatch lt 10 then begin
        ; 20160626 if match few, auto choose all
        magix = lindgen(magmatch) ; auto chosen all matched stars, r_match already do mag 3 sigma
    endif else if magmatch le magmatchmax then begin
        ; if 10-magmatchmax, use 3 sigma clip
        meanclip, mmagdiff, mag_const, err_const, subs=magix
    endif else begin
        ; more than magmatchmax, choose brightest 10%<20th to 90%<100th
        ixlow = fix(magmatch * 0.1) < (magmatchmax * 0.2)
        ixhgh = fix(magmatch * 0.9) < (magmatchmax * 1.2)
        magix = (sort(mmags[msid]))[ixlow:ixhgh]
        meanclip, mmagdiff[magix], mag_const, err_const, subs=magix2
        magix = magix[magix2]
    endelse
    hit[magix] = '+'
    ;endif

    ; print matched list, for manual chosen and check
    if ~magauto or screenmode eq 2 then begin
        print, 'No', 'CID', 'CATA RA', 'DEC', 'MAG', $
            'SID', 'STAR RA', 'DEC', 'MAG', $
            'Distan', 'Diff', $
            format='(A-4,2X, 2("|",A6,2(X,A12),X,A9,2X), "|",A7," (",A9,") ")'
        magix2 = sort(mmags[msid])
        for ii = 0, magmatch-1 do begin
            iii = magix2[ii]
            print, iii, hit[iii], $
                mcid[iii], r_hms(mrac[mcid[iii]]/15.0), r_hms(mdecc[mcid[iii]]), mmagc[mcid[iii]], $
                msid[iii], r_hms(mras[msid[iii]]/15.0), r_hms(mdecs[msid[iii]]), mmags[msid[iii]], $
                mcsdis[iii]* 3600.0, mmagdiff[iii], hit[iii], iii, $
                format='(I4.2,1A,1X, 2("|",I6,2(X,A12),X,F9.5,2X), "|",F7.4," (",F9.5,") ", 1A,I4.2)'
        endfor
    endif
    print, magmatch, n_elements(magix), format='(I5," matched, ",I5," auto choosed")'

    if magauto then begin
        ;magix = where(mmagc[mcid] lt 90.0 and mmags[msid] lt 90.0) ; already checked before
        ;if magix[0] eq -1 then goto, magfail
        ;if nmatch gt 10 then
        ids = [-1, magix]
    endif else begin
        ; manual matching
        ids = [-1] & id1 = 0
        print, 'Select line no, -1 finish, -2 auto , -3 all: '
        repeat begin
            read, id1
            if id1 ge 0 then ids = [ids, id1]
        endrep until id1 lt 0
        nmag = n_elements(ids) - 1
        if id1 eq -2 then begin
            ids = [-1, magix]
        endif else if id1 eq -3 then begin
            ids = [-1, indgen(magmatch)]
        endif else if nmag eq 0 then begin
            message, 'ERROR!  No manual matched stars in this area.', /cont
            goto, magfail
        endif
    endelse
    ; keep and use chosen pairs
    ids = ids[1:*]
    mcid = mcid[ids] & msid = msid[ids] & mmagdiff = mmagdiff[ids]
    nmag = n_elements(ids)

    ;get magconst
    meanclip, mmagdiff, mag_const, err_const

    if screenmode ge 1 then $
        print, nmag, mag_const, err_const, format='(I4," star(s) used, const=",F6.3,"+-",F6.4)'

    stars.mag_corr = stars.mag_auto + mag_const
    ;mag_limit = mag_limit_0 + mag_const
    stars[six[msid]].ixMag = mcid

    ; check mag err calc
    ;if screenmode eq 2 then print, 'Check mag err (magcalibrate) ...'
    ;ncheck = n_elements(checkmag)
    ;checkerr = fltarr(ncheck)
    ;for i = 0, ncheck-1 do begin
    ;    checkerr[i] = za_magerr(stars.mag_corr, stars.magerr_auto, checkmag[i], degree=-1)
    ;endfor
    ;checkmagx = strjoin(string(checkmag, format='(F4.1)'), ' ')
    ;checkerrx = strjoin(string(checkerr, format='(F5.3)'), ' ')

    sxaddpar, hdr, 'NMAG', nmag
    sxaddpar, hdr, 'MAGCONST', mag_const
    sxaddpar, hdr, 'MAGERROR', err_const

    ;sxaddpar, hdr, 'CHECKMAG', checkmagx, 'Check mag (magcalibrate)'
    ;sxaddpar, hdr, 'CHECKERR', checkerrx, 'Err of check mag (magcalibrate)'

    r_ldac_write, mag_ldac, stars, hdr
    zh_outcat, mag_cat, stars

    ; draw mag difference histogram
    old_device = !d.name
    set_plot, 'ps'
    device,filename=sci_path + file + version + '.magconst.eps',$
        /color,bits_per_pixel=16,xsize=30,ysize=20, $
        /encapsulated,yoffset=0,xoffset=0,/TT_FONT,/helvetica,/bold,font_size=12
    plothist, mmagdiff, bin=0.05, title='Mag Calibration Value', $
        xtitle=string(mag_const, err_const, nmag, format='("Const = ",F7.4,"+-",F7.5," (N=",I4,")")'), $
        position=[0.1,0.1,0.9,0.9]
    oplot, [0,0]+mag_const-err_const, [0,25], line=1
    oplot, [0,0]+mag_const+err_const, [0,25], line=1
    oplot, [0,0]+mag_const, [0,25], line=2
    device, /close
    set_plot, old_device


    return, nmag ;FLAG_OK

magfail:
    return, FLAG_FAIL

end
