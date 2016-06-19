function zb_pip_astrometry_new, sci_path, file,  $
            catawcs, recenter, checkmag, $
            screenmode=screenmode

    r_default, recenter, 0
    r_default, catawcs, 'ub1';'sdss'
    r_default, checkmag, [15.0, 16.0, 17.0, 18.0, 19.0]
    r_default, screenmode, 2
    @zh_const.pro

    phot_ldac = sci_path + file + '.phot.ldac'
    wcs_ldac  = sci_path + file + '.wcs.ldac'
    wcs_cat   = sci_path + file + '.wcs.cat'

    ; load photometry result
    stars = r_ldac_read(phot_ldac, hdr)
    n_star = n_elements(stars)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; astrometry
    ; result: wcs parameter (poly factor), fit residual
    ; wcs star number, corrected ra and dec, telescope alt and az
    ; moon phase, alt, distance

    ;     y                            N y
    ;     |                             |
    ; N <-+-> x   ==ROTATE CW90==>  E <-+-> x
    ;     |                             |
    ;     E

    ; some basic info for wcs processing
    ctra  = sxpar(hdr, 'CRVAL2')
    ctdec = sxpar(hdr, 'CRVAL1')
    ctx = sxpar(hdr, 'CRPIX1')
    cty = sxpar(hdr, 'CRPIX2')
    cd11 = -0.00012638 ;- 0.455 / 3600.0 * cos(0 * !pi / 180.0)
    cd12 = -0.0        ;- 0.455 / 3600.0 * sin(0 * !pi / 180.0)
    cd21 = +0.0        ;+ 0.455 / 3600.0 * sin(0 * !pi / 180.0)
    cd22 = +0.00012638 ;+ 0.455 / 3600.0 * cos(0 * !pi / 180.0)
    rotang = 0.0 / 180.0 * !pi  ; rotate angle of image, not amp
    pixel_scale = sxpar(hdr, 'PIXSCAL1')

    ; get astrometry reference catalog
    if screenmode eq 0 then sisi = 1
    scat_txt = sci_path + file + '.ub1.txt'
    sdss_txt = sci_path + file + '.sdss.txt'
    if catawcs eq 'sdss' then begin
        wcscata = r_sdss(ctra, ctdec, 1200, 1.1, filename=sdss_txt, silent=sisi)
        if wcscata[0].radeg eq 0.0 then catawcs = 'ub1'
    endif
    if catawcs ne 'sdss' then $
        wcscata = r_scat(ctra, ctdec, 1200, 1.1, filename=scat_txt, silent=sisi)

    n_cata = n_elements(wcscata)
    rac = wcscata.radeg
    decc = wcscata.decdeg
    if catawcs eq 'sdss' then $
        magc = wcscata.magu $
    else $
        magc = wcscata.magb1

    ; rotate stars CW 90
    roted = r_rot_cata(stars.x - ctx, stars.y - cty, 1)
    stars.x = roted.x + cty
    stars.y = roted.y + ctx
    t = ctx & ctx = cty & cty = t
    ; update header
    sxaddpar, hdr, 'CRVAL1', ctra
    sxaddpar, hdr, 'CRVAL2', ctdec
    sxaddpar, hdr, 'CRPIX1', ctx
    sxaddpar, hdr, 'CRPIX2', cty
    sxaddpar, hdr, 'CTYPE1', 'RA---TAN'
    sxaddpar, hdr, 'CTYPE2', 'DEC--TAN'
    sxaddpar, hdr, 'CD1_1',  cd11
    sxaddpar, hdr, 'CD1_2',  cd12
    sxaddpar, hdr, 'CD2_1',  cd21
    sxaddpar, hdr, 'CD2_2',  cd22

    ; choose 'good' star from stars
    xs = stars.x & ys = stars.y & mags = stars.mag_auto & magse = stars.magerr_auto
    ;ix = where( stars.elong lt 2.0, n_bstar)
    ix = where( stars.flags eq 0, n_bstar)
    xs = xs[ix] & ys = ys[ix] & mags = mags[ix] & magse = magse[ix] & pix = ix ; index from original list

    n_bstar = 1000 < n_bstar
    ix = (sort(magse))[0:n_bstar-1]
    n_bstar = n_elements(ix)
    xs = xs[ix] & ys = ys[ix] & mags = mags[ix] & magse = magse[ix] & pix = pix[ix]

    ; calc distance between stars, remove close pairs
    mindis = fltarr(n_bstar)
    for ss = 0, n_bstar-1 do begin
        dis = sqrt( (xs-xs[ss])^2 + (ys-ys[ss])^2 )
        mindis[ss] = min(dis[where(dis gt 0.0d)])
    endfor
    ix = where(mindis gt 135.0d, n_bstar) ; 135 pixels, about 1 arcmin
    xs = xs[ix] & ys = ys[ix] & mags = mags[ix] & magse = magse[ix] & pix = pix[ix]

    extast, hdr, ast_ini
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; If necessory, insert center relocating here
    if recenter then begin
        ;@zb_pip_center.pro
    endif

    ; steps
    ; do linear conversion, get xi and eta
    ; match catalog and image
    ; if few match or unbalanced match, report error and quit
    ; regress, then get xi' and eta'
    ; alter original crval1/2, repeat the process
    ; stop when pv1/2_0 is little enough? or match residual is small enough

    maxdisx = [60.0, 30.0, 15.0, 5.0] / 3600.0d
    levelx  = [1, 2, 3, 4]
    matchx  = [20, 30, 40, 50]
    nx = 4-1
    crxs = xs - ctx & crys = ys - cty ; this will not change in all iterations

    ; initial linear pv
    pvini = {crpix:[ctx, cty], crval:[ctra, ctdec], cd:[[cd11, cd21], [cd12, cd22]], $
        pv:{ level:0, n_item:1, $; 0 level pv, same as linear
            pv10:0.0d, pv1:[1.0d], pv1sigma:[0.0d], $
            pv20:0.0d, pv2:[1.0d], pv2sigma:[0.0d] }  }

    ; get initial star ra/dec
    ;xis  = cd11 * crxs + cd12 * crys
    ;etas = cd21 * crxs + cd22 * crys
    ;ras = ctra + xis & decs = ctdec + etas
    ; operations above merged into xy2ad, with original linear pv

    ; xi/eta of s, is related with crx/y and cd, not related with crval, is fixed in repeats
    ; xi/eta of c, is related with crval, will change
    ; xi/eta prime of s, is related with xi/eta and pv, pv will change
    ; ra/dec related with xi/eta prime and crval, will change

    ; if crval is fixed, xi/eta of s, xi/eta of c are all fixed
    ; xi'/eta' of will change after pv, new pv leads new ra/dec s, and new match

    ; xi/eta for catalog, use original crval
    xic = rac - pvini.crval[0] & etac = decc - pvini.crval[1]

    rep = 0
    last_resid = 0.0
    resid_limit = 1e-4 ; 0.36 arcsec
    status = 0 ; 0 continue  1 rep over  2 residual tiny enough  9 fail

    ; initial convert
    zb_pip_xy2ad, xs, ys, pvini, ras, decs, xis, etas, xip, etap
    xy2ad, xs, ys, ast_ini, ras, decs

    print, '#', '+RA', '+DEC', 'RESID', 'CRXY', 'NMatch', $
      format='(A-2,2x,A7,2x,A7,2x,A7,2x,A6,2x,A6)'

    while status eq 0 do begin

        ; match, check the matchlimit and balance
        resid = r_match(rac, decc, magc, ras, decs, mags, maxdis=maxdisx[rep<nx], $ ; 18as for first round
                nmatch, cid, sid, csdis, matchlimit=matchx[rep<nx], /nosigma)
        crxym = max(abs([mean(crxs[sid]), mean(crys[sid])]))

        if resid lt 0 or crxym gt 2000 then begin
            status = 9
            print, nmatch, crxym
            continue  ; here continue same as break
        endif

        pv = zb_pip_regress(xis[sid], etas[sid], xic[cid], etac[cid], $
            xip=xip, etap=etap, level=levelx[rep<nx])
        pvini = {crpix:[ctx, cty], crval:[ctra, ctdec], cd:[[cd11, cd12], [cd21, cd22]], pv:pv}

        ; get new xi/eta/ra/dec of s using latest pvini
        zb_pip_xy2ad, xs, ys, pvini, ras, decs, xis, etas, xip, etap

        print, rep, pv.pv10*3600.0, pv.pv20*3600.0, resid*3600.0, crxym, nmatch, $
            format='(I2,2x,F7.2,2x,F7.2,2x,F7.2,2x,F6.1,2x,I3)'

        if rep gt 5 then status = 1
        if resid lt resid_limit or abs(resid - last_resid) lt resid_limit then status = 2
        rep++
        last_resid = resid

    endwhile

    ;zb_pip_xy2ad, xs, ys, pvini, ras, decs, xis, etas, xip, etap ; move before repeat, 20160413
    zb_pip_ad2xy, rac, decc, pvini, xc, yc
    zb_pip_xy2ad, stars.x, stars.y, pvini, starra, stardec
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; do polynorminal regress
    ;max_rep_n = 30 & resid_limit = 0.5d / 3600.0 & resid_preci = 0.1d / 3600.0
    ;rep_n = 1
    ;resid = 100.0d       ; initial resid, used for loop
    ;last_resid = 100.0d  ; init last
    ;sigma_resid = 0.0d   ; init sigma

    ; max distance, match limit, level: be more strict by repeat time
    ;amaxdis = [0, 60.0d, 30.0d, 15.0d, 5.0d] / 3600.0d
    ;amatchlimit = [0, 10, 20, 30, 40]
    ;matchlimitcheck = 20

    ;finish1 = 0
    ;fail1 = 0
    ;wcsmag_const = 99.99
    ;while not finish1 do begin ;rep_n le max_rep_n and rep_n ge 0 do begin
    ;    resid = r_match(rac, decc, magc, ras, decs, mags, maxdis=amaxdis[rep_n < 4], $
    ;        nmatch, cid, sid, csdis, matchlimit=amatchlimit[rep_n < 4], /nosigma)  ; shrink by steps
    ;    if resid lt 0 then begin
    ;        print, nmatch, format='("FAIL!!  match=", I)'
    ;        fail1 = 1
    ;        crxym = 0
    ;        break
    ;    endif

        ;result = zh_astrom_regress(crxs[sid], crys[sid], rac[cid], decc[cid], $
        ;    RAS=rasout, DECS=decsout, LEVEL=4<rep_n)

    ;    resid_dis = r_distance(xisout[0:*]+ctra, etasout[0:*]+ctdec, rac[cid], decc[cid]) * 3600.0d
    ;    resid = sqrt( total(resid_dis*resid_dis) / nmatch )
    ;    sigma_resid = resid / sqrt((nmatch-3) > 1)
    ;    ; center of matched stars, judge balance
    ;    crxm = mean(crxs[sid]) & crym = mean(crys[sid])
    ;    crxym = sqrt( crxm*crxm + crym*crym )  ;(abs(crxm) > abs(crym))

    ;    ;zh_xy2ad, crxs, crys, result, ras, decs

    ;    if screenmode eq 2 then print, rep_n, nmatch, sigma_resid, $
    ;        result.aconst, result.bconst, r_hms([result.aconst/15, result.bconst]), $
    ;        sqrt(ast_ini.cd[0,0]^2 + ast_ini.cd[0,1]^2)*3600.0, sqrt(ast_ini.cd[1,1]^2 + ast_ini.cd[1,0]^2)*3600.0, $
    ;        atan( -ast_ini.cd[0,1], -ast_ini.cd[0,0] ) /!pi*180.0, atan( -ast_ini.cd[1,0],  ast_ini.cd[1,1] ) /!pi*180.0, crxym, $
    ;        format='("#",I2.2 , "|N=",I3 , "|SIGMA",F9.4 , "|CT",2(1X,F10.6),2(1X,A12) , "|CDELT",2(1X,F7.4) , "|CROTA",2(1X,F5.2),"|CRXYM",1X,F6.1)'

    ;    if (abs(resid - last_resid) lt resid_preci) or (sigma_resid lt resid_limit) then begin
    ;    finish1 = 1
    ;    endif else begin
    ;        rep_n++
    ;        last_resid = resid
    ;        if rep_n gt max_rep_n then finish1 = 1
    ;    endelse
    ;endwhile

    ;if fail1 or crxym gt 3500  then begin
    ;    print, nmatch, crxym, format='("FAIL: nmatch = ",I3,"  crxym = ",F9.3)'
    ;    goto, wcsfail
    ;endif

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; astrometry success. good stars [sid] -- catalog [cid] matched
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; calc linear astrometry parameters
    ;ast_ini.crval[0] = ctra  + result.aconst
    ;ast_ini.crval[1] = ctdec + result.bconst
    ;ast_ini.cd[0, 0] = result.a[0]
    ;ast_ini.cd[0, 1] = result.a[1]
    ;ast_ini.cd[1, 0] = result.b[1]
    ;ast_ini.cd[1, 1] = result.b[0]
    ;crota1 = atan( -ast_ini.cd[0,1], -ast_ini.cd[0,0] ) /!dpi*180.0d
    ;crota2 = atan( -ast_ini.cd[1,0],  ast_ini.cd[1,1] ) /!dpi*180.0d
    ;cdelt1 = sqrt(ast_ini.cd[0,0]^2 + ast_ini.cd[0,1]^2)
    ;cdelt2 = sqrt(ast_ini.cd[1,1]^2 + ast_ini.cd[1,0]^2)
    ; keep original linear parameters, add distortion PV

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; do catalog ra/dex to x/y, add center because ad2xy returns xy to center
    ;zh_ad2xy, rac[cid], decc[cid], result, xc, yc
    ;xc += ast_ini.crpix[0] & yc += ast_ini.crpix[1]

    ; reload photometry result and add fields
    ;zh_xy2ad, stars.x - (ast_ini.crpix[0]), stars.y - (ast_ini.crpix[1]) , result, rasall, decsall
    meanclip, magc[cid] - mags[sid], wcsmag_const, wcserr_const

    if screenmode eq 2 then begin
    ;    print, result.aconst, result.bconst, r_hms([result.aconst/15, result.bconst]), $
    ;        cdelt1*3600.0, cdelt2*3600.0, crota1, crota2, $
    ;        format='("CENTER",2(1X,F10.6),2(1X,A12) , "  CDELT",2(1X,F7.4) , "  CROTA:",2(1X,F5.2))'
    ;    print, crxm, crym, ((abs(crxm)>abs(crym)) lt 800)?'OK':'DOUBT', $
    ;        format='("Center of matched stars: ", 2(F9.3,2X), "Balance: ", A)'
    endif

    ; calc final residual of matched stars
    resid_ra  = (ras [sid] - rac [cid]) * 3600.0d
    resid_dec = (decs[sid] - decc[cid]) * 3600.0d
    resid_dis = sqrt((resid_ra/cos(pvini.crval[1]/180.0*!pi))^2.0 + resid_dec^2.0)
    meanclip, resid_ra , med_resid_ra , sig_resid_ra
    meanclip, resid_dec, med_resid_dec, sig_resid_dec
    meanclip, resid_dis, med_resid_dis, sig_resid_dis

    stars.radeg  = starra
    stars.decdeg = stardec
    stars.rastr  = r_hms(starra / 15.0)
    stars.decstr = r_hms(stardec)
    stars.mag_corr = stars.mag_auto + wcsmag_const
    stars[pix[sid]].ixWcs = cid

    ; check mag err calc
    if screenmode eq 2 then print, 'Check mag err (astrometry) ...'
    ncheck = n_elements(checkmag)
    checkerr = fltarr(ncheck)
    for i = 0, ncheck-1 do begin
        checkerr[i] = za_magerr(stars.mag_corr, stars.magerr_auto, checkmag[i], degree=-1)
    endfor
    checkmagx = strjoin(string(checkmag, format='(F4.1)'), ' ')
    checkerrx = strjoin(string(checkerr, format='(F5.3)'), ' ')

    sxaddpar, hdr, 'RESRAMED', med_resid_ra
    sxaddpar, hdr, 'RESRASIG', sig_resid_ra
    sxaddpar, hdr, 'RESDEMED', med_resid_dec
    sxaddpar, hdr, 'RESDESIG', sig_resid_dec
    sxaddpar, hdr, 'RESCTMED', med_resid_dis
    sxaddpar, hdr, 'RESCTSIG', sig_resid_dis

    sxaddpar, hdr, 'CHECKMAG', checkmagx, 'Check mag (astrometry)'
    sxaddpar, hdr, 'CHECKERR', checkerrx, 'Err of check mag (astrometry)'


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; calculate other info about observation
    ; extract site elev, lat and long (read SITEELEV SITELAT SITELONG)
    site_ele = sxpar(hdr, 'SITEELEV') * 1.0
    site_lat = hms2dec(sxpar(hdr, 'SITELAT' ))
    site_lon = hms2dec(sxpar(hdr, 'SITELONG')) * (-1.0)

    ; find obs date and time, convert to mjd (read DATE-OBS)
    ; (write DATE TIME DATE-OBS TIME-OBS LMST MJD)
    date_obs = sxpar(hdr, 'DATE-OBS')
    time_obs = sxpar(hdr, 'TIME-OBS')
    ;if verbose then print, date_obs, format='("Observation date: ",A)'
    jd = julday(strmid(date_obs, 5,2), strmid(date_obs, 8,2), strmid(date_obs, 0,4), $
      strmid(time_obs,0,2), strmid(time_obs,3,2), strmid(time_obs,6,6))
    ct2lst, lmst, site_lon, 0, jd
    ;sxaddpar, hdr, 'DATE', dateo, 'UTC date of observation'
    ;sxaddpar, hdr, 'TIME', timeo, 'UTC time of observation'
    ;sxaddpar, hdr, 'MJD' , jd - 2400000.5,   'Modified Julian day'
    ;sxaddpar, hdr, 'LMST', lmst,  'Local mean sidereal time'
    ;if verbose then print, jd-2450000.5, lzju_hms(lmst), format='("MJD ", F10.5, " Local Mean Sidereal Time ", A9)'

    ; this section moved to photometry, so do not repeat here
    ; calc moon phase/ra/dec, transfer to moon azimuth/altitud (MPHASE RA_MOON DEC_MOON MAZIMUTH MALTITUD)
    ;moonpos, jd, mra, mdec
    ;mphase, jd, mph
    ;eq2hor, mra, mdec, jd, malt, maz, mha, lat=site_alt, lon=site_lon, alt=site_ele
    ;sxaddpar, hdr, 'MPHASE'  , mph*100.0,  'Moon phase, percent'
    ;sxaddpar, hdr, 'RA_MOON' , mra,  'RA of Moon (degree)'
    ;sxaddpar, hdr, 'DEC_MOON', mdec, 'Dec of Moon (degree)'
    ;sxaddpar, hdr, 'MAZIMUTH', maz,  'Azimuth of Moon (degree)'
    ;sxaddpar, hdr, 'MALTITUD', malt, 'Altitude of Moon (degree)'
    ;if verbose then print, lzju_hms(mra/15.0), lzju_hms(mdec), mph*100, maz, malt, $
    ;  format='("Moon ", A11,1X,A11, 1X,F5.1,"%", 2(1X,F5.1))'

    ; transfer center floating from pv to ra/dec, will not change other pv
    pvini.crval[0] += pvini.pv.pv10
    pvini.crval[1] += pvini.pv.pv20
    pvini.pv.pv10 = 0.0
    pvini.pv.pv20 = 0.0
    ;sxaddpar, hdr, 'RA'      , dec2hms(pvini.crval[0] / 15.0), 'RA of Object (hms)'
    ;sxaddpar, hdr, 'DEC'     , dec2hms(pvini.crval[1]), 'Dec of Object (dms)'
    ;sxaddpar, hdr, 'OBJCTRA' , pvini.crval[0], 'RA of Object (degree)'
    ;sxaddpar, hdr, 'OBJCTDEC', pvini.crval[1], 'Dec of Object (degree)'
    ;sxaddpar, hdr, 'CRVAL1'  , pvini.crval[0]
    ;sxaddpar, hdr, 'CRVAL2'  , pvini.crval[1]

    ; object Alt and Az, HA (write AZMTHANG ELEANG HA AIRMASS)
    eq2hor, pvini.crval[0], pvini.crval[1], jd, objalt, objaz, objha, lat=site_alt, lon=site_lon, alt=site_ele
    airmass = 1.0 / sin(( objalt + 244.0 /(165.0 + 47.0 * objalt ^ 1.1) ) * !pi / 180.d)
    sxaddpar, hdr, 'AZIMUTH', objaz
    sxaddpar, hdr, 'ELEVAT', objalt
    sxaddpar, hdr, 'HA', objha
    sxaddpar, hdr, 'AIRMASS', airmass
    ;if verbose then print, objaz, objalt, objha, airmass, $
    ;  format='("Object Az-Alt ", F8.4,1X,F8.4, "  HA ",F6.2," AIRMASS ",F6.3)'

    ; this section moved to photometry, so do not repeat here
    ; calc moon-object angle (MANGLE)
    ;ma = map_2points(mra, mdec, objra, objdec)
    ;ma = ma[0]
    ;sxaddpar, hdr, 'MANGLE'  , ma, 'Angle from Moon to Object (degree)'
    ;if verbose then print, ma, format='("Moon angle: ", F5.1)'


    ; update header, add wcs fields
    sxaddpar, hdr, 'CRVAL1'  , pvini.crval[0], '[deg] X-axis coordinate value '
    sxaddpar, hdr, 'CRVAL2'  , pvini.crval[1], '[deg] Y-axis coordinate value '
    sxaddpar, hdr, 'RA'      , dec2hms(pvini.crval[0]/15.0d), '[hms J2000] Target right ascension'
    sxaddpar, hdr, 'DEC'     , dec2hms(pvini.crval[1]),       '[dms +N J2000] Target declination'
    sxaddpar, hdr, 'OBJCTRA' , dec2hms(pvini.crval[0]/15.0d), '[hms J2000] Target right ascension'
    sxaddpar, hdr, 'OBJCTDEC', dec2hms(pvini.crval[1]),       '[dms +N J2000] Target declination'
    ; the following 4 keywords need revised
    ;sxaddpar, hdr, 'CDELT1'  , cdelt1, '[deg/pixel] X-axis plate scale'
    ;sxaddpar, hdr, 'CDELT2'  , cdelt2, '[deg/pixel] Y-axis plate scale'
    ;sxaddpar, hdr, 'CROTA1'  , crota1, '[deg] Roll angle wrt X-axis'
    ;sxaddpar, hdr, 'CROTA2'  , crota2, '[deg] Roll angle wrt Y-axis'
    sxaddpar, hdr, 'CD1_1'   , pvini.cd[0,0], 'Change in RA---TAN along X-Axis'
    sxaddpar, hdr, 'CD1_2'   , pvini.cd[0,1], 'Change in RA---TAN along Y-Axis'
    sxaddpar, hdr, 'CD2_1'   , pvini.cd[1,0], 'Change in DEC---TAN along X-Axis'
    sxaddpar, hdr, 'CD2_2'   , pvini.cd[1,1], 'Change in DEC---TAN along Y-Axis'
    sxaddpar, hdr, 'PV1_0'   , pvini.pv.pv10
    sxaddpar, hdr, 'PV2_0'   , pvini.pv.pv20
    for kk = 0, pvini.pv.n_item-1 do begin
        sxaddpar, hdr, 'PV1_'+strn(kk+1), pvini.pv.pv1[kk]
        sxaddpar, hdr, 'PV2_'+strn(kk+1), pvini.pv.pv2[kk]
    endfor
    sxaddpar, hdr, 'WCSORDER', pvini.pv.level,    'Order of wcs polinominal'
    sxaddpar, hdr, 'WCSSTAR' , nmatch,          'Stars used in wcs'
    sxaddpar, hdr, 'WCSRESID', resid,     'Sigma of residual of matching stars'
    sxaddpar, hdr, 'WCSCONST', wcsmag_const, 'Mag correction with V'
    sxaddpar, hdr, 'WCS-DATE', r_now(), 'wcs date and time'
    sxaddhist, 'wcs processed by lzj: jiezheng at nao.cas.cn',hdr

    ;writefits, out_fits, dat, hdr

    ; output new stars info data
    save, stars, n_star, pvini, wcscata, wcsmag_const, filename=sci_path + file + '.wcs.sav'
    ; output new stars ldac
    r_ldac_write, wcs_ldac, stars, hdr, wcscata, /silent
    zb_pip_outcat, wcs_cat, stars

    @zb_pip_astrometry_new_draw.pro

    return, nmatch ; FLAG_OK

wcsfail:
    return, FLAG_FAIL

end