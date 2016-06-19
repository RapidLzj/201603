function zn_pip_photometry, rawpath, sci_path, file, $
    limitsig, checkmag, keep, sexcmd, $
    screenmode=screenmode

    @zh_const.pro
    r_default, keep, 0
    r_default, sexcmd, 'sextractor'
    r_default, limitsig, [5.0, 10.0, 33.3, 50.0, 100.0, 333.3]
    r_default, checkmag, [15.0, 16.0, 17.0, 18.0, 19.0]
    r_default, screenmode, 1

    ; x/y size const for NOWT
    nx = 2048 & ny = 2068
    nx2 = nx * 2 & ny2 =ny * 2
    nx0 = [0,1,0,1] * nx ; x/y start of each amp in whole image
    ny0 = [0,0,1,1] * ny

    sec_fits = sci_path + file + '.' + ggs + '.fits'
    sec_ldac = sci_path + file + '.' + ggs + '.ldac'
    obs_fits = rawpath + file + '.fits'
    phot_ldac = sci_path + file + '.phot.ldac'
    phot_cat  = sci_path + file + '.phot.cat'
    phot_sav  = sci_path + file + '.phot.sav'

    @zn_pip_fixhdr.pro

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;  Constant for photometry
    ; structure of stars
    star1 = { sn:0L, mjd:jd, file:fs, filter:fi, $
        x:0.0, y:0.0, elong:0.0, fwhm: 0.0, $
        mag_auto :0.0, magerr_auto :0.0, $
        mag_best :0.0, magerr_best :0.0, $
        mag_petro:0.0, magerr_petro:0.0, $
        mag_aper :0.0, magerr_aper :0.0, $
        flags: 0B, $
        mag_corr:0.0, magerr_corr:0.0, $
        radeg:0.0d, decdeg:0.0d, raerr:0.0d, decerr:0.0d, rastr:'x', decstr:'x', $
        ixWcs:-1L, ixMag:-1L, ixCross:-1L, amp:-1 }
    ; border of discarded stars
    border = 5.0

    ; configure for NOWT
    sec_gain = [1.861, 1.857, 1.907, 1.872]
    sec_read = [4.41,  4.25,  6.08,  6.93 ]

    skymed = fltarr(ngg)
    skysig = fltarr(ngg)
    skymag = fltarr(ngg)
    skyerr = fltarr(ngg)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; bias & flat correct and photometry of each amplifier(section)
    if screenmode eq 0 then sv = '-VERBOSE_TYPE QUIET' else sv = ''
    for gg = 0, ngg-1 do begin
        ; section file full name

        ;dat1 = readfits(sec_fits[gg], hdr1)
        dat1 = mrdfits(sec_fits[gg], 0, hdr1)
        if gg eq 0 then datx = dat1 else datx = [datx,dat1]
        ;sec_gain = sxpar(hdr, 'GAIN'+ggx[gg])
        ; call SExtractor
        cmd = string(sexcmd, sec_fits[gg], sec_ldac[gg], sec_gain[gg], pix_scales, sv, $
            format='(A," ",A," -c lzj.sex -CATALOG_NAME ",A," -GAIN ",F5.3," -PIXEL_SCALE ",F6.3," ",A)')
        if screenmode ge 1 then print, cmd
        spawn, cmd
        if ~ keep then file_delete, sec_fits[gg]

        ; sky data
        ;sky, dat1, smod, ssig, /silent
        skymed[gg] = median(dat1)
        skysig[gg] = get_sigma(dat1)
        skymag[gg] = 25.0 - 2.5 * alog10(skymed[gg] / pixscl2)
        skyerr[gg] = 2.5 * alog10(1.0 + skysig[gg] / skymed[gg])

        ; load sec catalog and transfer to our catalog structure
        s_ldac = mrdfits(sec_ldac[gg], 2, /silent)

        if n_elements(s_ldac) lt 10 then continue  ; skip for empty amplifier, even too few stars

        n_sec = n_elements(s_ldac)
        stars_sec = replicate(star1, n_sec)
        stars_sec.x     = s_ldac.x_image
        stars_sec.y     = s_ldac.y_image
        stars_sec.elong = s_ldac.elongation
        stars_sec.fwhm  = s_ldac.fwhm_image
        stars_sec.flags = s_ldac.flags
        stars_sec.mag_auto     = s_ldac.mag_auto
        stars_sec.magerr_auto  = s_ldac.magerr_auto
        stars_sec.mag_best     = s_ldac.mag_best
        stars_sec.magerr_best  = s_ldac.magerr_best
        stars_sec.mag_petro    = s_ldac.mag_petro
        stars_sec.magerr_petro = s_ldac.magerr_petro
        stars_sec.mag_aper     = s_ldac.mag_aper
        stars_sec.magerr_aper  = s_ldac.magerr_aper
        stars_sec.amp = gg+1

        ; remove border stars ( will change to judging by FLAGS )
        ix = where(stars_sec.x gt border and stars_sec.x lt nx-border $
               and stars_sec.y gt border and stars_sec.y lt ny-border, nix)
        if nix eq 0 then continue
        stars_sec = stars_sec[ix]

        ; add xy original, and then rotate
        stars_sec.x += nx0[gg]
        stars_sec.y += ny0[gg]

        ; merge into total catalog
        if n_elements(stars) eq 0 then stars = stars_sec else stars = [stars, stars_sec]

    endfor ; gg

    if screenmode eq 2 then print, 'Sky mag working...'
    ; sky data for whole frame
    ;sky, datx, smod, ssig, /silent
    skymedx = median(datx)
    skysigx = get_sigma(datx)
    skymagx = 25.0 - 2.5 * alog10(skymedx / pixscl2)
    skyerrx = 2.5 * alog10(1.0 + skysigx / skymedx)

    ; sort stars by mag, and assign serial number(sn)
    ix = sort(stars.mag_auto)
    stars = stars[ix]
    n_star = n_elements(stars)
    stars.sn = lindgen(n_star) + 1

    ; limit mag calc
    if screenmode eq 2 then print, 'Limit mag ...'
    nlimit = n_elements(limitsig)
    limiterr = 1.0 / limitsig
    limitmag = fltarr(nlimit)
    for i = 0, nlimit-1 do begin
        limitmag[i] = za_maglimit(stars.mag_auto, stars.magerr_auto, limiterr[i], degree=-1)
    endfor
    limitsigx = strjoin(string(limitsig, format='(I3)'), ' ')
    limitmagx = strjoin(string(limitmag, format='(F5.2)'), ' ')

    ; check mag err calc
    ;if screenmode eq 2 then print, 'Check mag err ...'
    ;ncheck = n_elements(checkmag)
    ;checkerr = fltarr(ncheck)
    ;for i = 0, ncheck-1 do begin
    ;    checkerr[i] = za_magerr(stars.mag_auto, stars.magerr_auto, checkmag[i], degree=-1)
    ;endfor
    ;checkmagx = strjoin(string(checkmag, format='(F4.1)'), ' ')
    ;checkerrx = strjoin(string(checkerr, format='(F5.3)'), ' ')

    if screenmode eq 2 then print, 'Star stat working...'
    ; stat about stars
    ix_flags = where(stars.flags eq 0, nix)
    if nix gt 0 then begin
        ;meanclip, stars[ix_flags].fwhm, med_fwhm, sig_fwhm
        med_fwhm = median(stars[ix_flags].fwhm)
        sig_fwhm = get_sigma(stars[ix_flags].fwhm)
        ;meanclip, stars[ix_flags].elong, med_elong, sig_elong
        med_elong = median(stars[ix_flags].elong)
        sig_elong = get_sigma(stars[ix_flags].elong)
    endif else begin
        med_fwhm = 0.0
        sig_fwhm = 0.0
        med_elong = 0.0
        sig_elong = 0.0
    endelse

    if screenmode eq 2 then print, 'Photometry result output...'
    ;update header, add sky data and stat datascreenmode eq 2 then print, 'Star stat working...'
    sxaddpar, hdr, 'STARCNT', n_star, 'Number of stars found in all sections'
    sxaddpar, hdr, 'FWHMMED', med_fwhm, 'Star fwhm median'
    sxaddpar, hdr, 'FWHMSIG', sig_fwhm, 'Star fwhm sigma'
    sxaddpar, hdr, 'ELONMED', med_elong, 'Star elongation median'
    sxaddpar, hdr, 'ELONSIG', sig_elong, 'Star elongation sigma'
    sxaddpar, hdr, 'SKYMED', skymedx, 'Median of sky ADU (per pixel)'
    sxaddpar, hdr, 'SKYSIG', skysigx, 'Sigma of sky ADU (per pixel)'
    sxaddpar, hdr, 'SKYMAG', skymagx, 'Mag of skylight (Instrumental)'
    sxaddpar, hdr, 'SKYERR', skyerrx, 'Error of mag of skylight'
    sxaddpar, hdr, 'LIMITSIG', limitsigx, 'Limit sigma(s)'
    sxaddpar, hdr, 'LIMITMAG', limitmagx, 'Limit Mag of sigma'
    ;sxaddpar, hdr, 'CHECKMAG', checkmagx, 'Check mag (instrumental)'
    ;sxaddpar, hdr, 'CHECKERR', checkerrx, 'Err of check mag (instrumental)'
    for gg = 0, ngg-1 do begin
        sxaddpar, hdr, 'SKYMED'+ggs[gg], skymed[gg], 'Median of sky ADU (per pixel) of Section ' +ggs[gg]
        sxaddpar, hdr, 'SKYSIG'+ggs[gg], skysig[gg], 'Sigma of sky ADU (per pixel) of Section '  +ggs[gg]
        sxaddpar, hdr, 'SKYMAG'+ggs[gg], skymag[gg], 'Mag of skylight (Instrumental) of Section '+ggs[gg]
        sxaddpar, hdr, 'SKYERR'+ggs[gg], skyerr[gg], 'Error of mag of skylight of Section '      +ggs[gg]
    endfor

    ; save data into ldac and text file
    r_ldac_write, phot_ldac, stars, hdr
    zh_outcat, phot_cat, stars
    save, file=phot_sav, stars, n_star, $
        skymag, skyerr, skymed, skysig, skymagx, skyerrx, skymedx, skysigx

    return, n_star ;FLAG_OK
end
