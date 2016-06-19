function zb_pip_flagtitle, flag
    @zh_const.pro
    if flag eq FLAG_SKIP then $
        title = 'SKIP' $
    else if flag eq FLAG_FAIL then $
        title = 'FAIL' $
    else if flag eq FLAG_ERROR then $
        title = 'ERRO' $
    else $
        title = string(flag, format='(I4)')
    return, title
end

pro zb_pip_report, sci_path, file, $
        flag_bf, flag_sex, flag_wcs, flag_mag, flag_cross, $
        version, screenmode=screenmode

    @zh_const.pro
    horline = strjoin(replicate('=',80),'')
    r_default, flag_bf   , FLAG_SKIP
    r_default, flag_sex  , FLAG_SKIP
    r_default, flag_wcs  , FLAG_SKIP
    r_default, flag_mag  , FLAG_SKIP
    r_default, flag_cross, FLAG_SKIP

    if flag_cross ge FLAG_OK then begin
        final_step = 4
        final_ldac = sci_path + file + '.cross.ldac'
    endif else if flag_mag ge FLAG_OK then begin
        final_step = 3
        final_ldac = sci_path + file + '.mag.ldac'
    endif else if flag_wcs ge FLAG_OK then begin
        final_step = 2
        final_ldac = sci_path + file + '.wcs.ldac'
    endif else if flag_sex ge FLAG_OK then begin
        final_step = 1
        final_ldac = sci_path + file + '.phot.ldac'
    endif else begin
        final_step = 0
        final_ldac = ''
        print, 'Simple bias and flat reduction goes with no report.'
        return
    endelse

    r_default, version, '.' & if version ne '.' then version = '.' + version else version = ''
    rep_txt = sci_path + file + version + '.report.txt'
    db_txt = sci_path + file + version + '.db.txt'

    stars = r_ldac_read(final_ldac, hdr, /silent)

    n_star = n_elements(stars)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; load fields from header, and default value
    ; basic
    date_obs  = sxpar(hdr, 'DATE-OBS')
    time_obs  = sxpar(hdr, 'TIME-OBS')
    filter    = sxpar(hdr, 'FILTER'  ) & filter = strtrim(filter, 2)
    exptime   = sxpar(hdr, 'EXPTIME' )
    obj       = sxpar(hdr, 'OBJECT'  ) & obj = strtrim(obj, 2) & obj = (obj eq '') ? 'UNKNOWN' : obj
    fileno    = strmid(file, 3, 4, /reverse)
    jd = julday(strmid(date_obs, 5,2), strmid(date_obs, 8,2), strmid(date_obs, 0,4), $
                strmid(time_obs,0,2), strmid(time_obs,3,2), strmid(time_obs,6,6))
    ; source extractor
    skymed    = fltarr(ngg)
    skysig    = fltarr(ngg)
    skymag    = fltarr(ngg)
    skyerr    = fltarr(ngg)
    if final_step ge 1 then begin
        n_star    = sxpar(hdr, 'STARCNT' )
        med_fwhm  = sxpar(hdr, 'FWHMMED' )
        sig_fwhm  = sxpar(hdr, 'FWHMSIG' )
        med_elong = sxpar(hdr, 'ELONMED' )
        sig_elong = sxpar(hdr, 'ELONSIG' )
        skymedx   = sxpar(hdr, 'SKYMED'  )
        skysigx   = sxpar(hdr, 'SKYSIG'  )
        skymagx   = sxpar(hdr, 'SKYMAG'  )
        skyerrx   = sxpar(hdr, 'SKYERR'  )
        for gg = 0, ngg-1 do begin
            skymed[gg] = sxpar(hdr, 'SKYMED'+ggs[gg])
            skysig[gg] = sxpar(hdr, 'SKYSIG'+ggs[gg])
            skymag[gg] = sxpar(hdr, 'SKYMAG'+ggs[gg])
            skyerr[gg] = sxpar(hdr, 'SKYERR'+ggs[gg])
        endfor
        limitsig  = sxpar(hdr, 'LIMITSIG')
        limitmag  = sxpar(hdr, 'LIMITMAG')
        limitsigx = float(strsplit(limitsig, ' ', /ext))
        limitmagx = float(strsplit(limitmag, ' ', /ext))
        limiterrx = 1.0 / limitsigx
        nlimit = strn(n_elements(limitsigx))
        checkmag  = sxpar(hdr, 'CHECKMAG')
        checkerr  = sxpar(hdr, 'CHECKERR')
        checkmagx = float(strsplit(checkmag, ' ', /ext))
        checkerrx = float(strsplit(checkerr, ' ', /ext))
        ncheck = strn(n_elements(checkmagx))
        if checkmag eq 0 then begin
            ; for check mag missing (old version result)
            checkmagx = [15.0, 16.0, 17.0, 18.0, 19.0]
            ncheck = strn(n_elements(checkmagx))
            checkerrx = fltarr(ncheck)
            for i = 0, ncheck-1 do begin
                checkerrx[i] = za_magerr(stars.mag_corr, stars.magerr_auto, checkmagx[i], degree=-1)
            endfor
            checkmag = strjoin(string(checkmagx, format='(F4.1)'), ' ')
            checkerr = strjoin(string(checkerrx, format='(F5.3)'), ' ')
        endif
    endif else begin
        n_star    = 0
        med_fwhm  = 0
        sig_fwhm  = 0
        med_elong = 0
        sig_elong = 0
        skymedx   = 0
        skysigx   = 0
        skymagx   = 0
        skyerrx   = 0
        limiterr  = 'x'
        limitmag  = 'x'
        limitsigx = 99.99
        limitmagx = 99.99
        limiterrx = 0.0
        nlimit = '1'
        checkmag  = 'x'
        checkerr  = 'x'
        checkmagx = 99.99
        checkerrx = 9.999
        ncheck = '1'
    endelse
    ; mag calibrate
    if final_step ge 3 then begin
        nmag      = sxpar(hdr, 'NMAG'    )
        mag_const = sxpar(hdr, 'MAGCONST')
        mag_error = sxpar(hdr, 'MAGERROR')
    endif else begin
        nmag      = 0
        mag_const = 99.99
        mag_error = 9.999
    endelse
    ; astrometry
    ; these are added in photometry, so always here
    oldra         = sxpar(hdr, 'OLD-RA'  )
    oldradeg      = sxpar(hdr, 'OLD-CRV2')
    olddec        = sxpar(hdr, 'OLD-DEC' )
    olddecdeg     = sxpar(hdr, 'OLD-CRV1')
    obsazi        = sxpar(hdr, 'AZIMUTH' )
    obsele        = sxpar(hdr, 'ELEVAT'  )
    obsairm       = sxpar(hdr, 'AIRMASS' )
    mphase        = sxpar(hdr, 'MPHASE'  )
    malt          = sxpar(hdr, 'MALTITUD')
    mangle        = sxpar(hdr, 'MANGLE'  )
    if final_step ge 2 then begin
        nwcs          = sxpar(hdr, 'WCSSTAR' )
        wcsorder      = sxpar(hdr, 'WCSORDER')
        wcsmag_const  = sxpar(hdr, 'WCSCONST')
        med_resid_ra  = sxpar(hdr, 'RESRAMED')
        sig_resid_ra  = sxpar(hdr, 'RESRASIG')
        med_resid_dec = sxpar(hdr, 'RESDEMED')
        sig_resid_dec = sxpar(hdr, 'RESDESIG')
        med_resid_dis = sxpar(hdr, 'RESCTMED')
        sig_resid_dis = sxpar(hdr, 'RESCTSIG')
        ra            = sxpar(hdr, 'RA'      )
        radeg         = sxpar(hdr, 'CRVAL1'  )
        dec           = sxpar(hdr, 'DEC'     )
        decdeg        = sxpar(hdr, 'CRVAL2'  )
        ra_bias       = 3600.0 * (radeg  - oldradeg )
        dec_bias      = 3600.0 * (decdeg - olddecdeg)
    endif else begin
        nwcs          = 0
        wcsorder      = -1
        wcsmag_const  = 99.99
        med_resid_ra  = 999.99
        sig_resid_ra  = 999.99
        med_resid_dec = 999.99
        sig_resid_dec = 999.99
        med_resid_dis = 999.99
        sig_resid_dis = 999.99
        ra            = '-'
        radeg         = 999.99
        dec           = '-'
        decdeg        = 99.99
        ra_bias       = 0.0
        dec_bias      = 0.0
    endelse

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; draw mag-err graph
    @zb_pip_report_magerr.pro

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; print report and db file
    get_lun, lun_out

    openw, lun_out, rep_txt
    printf, lun_out, horline
    printf, lun_out, file, version, format='(5X,"File [ ",A," ] Reduction Report",10x,"Version Code: ",A)'
    printf, lun_out, final_ldac
    printf, lun_out, format='(5(A10,":",A5,2x))', $
            'BIAS&FLAT', zb_pip_flagtitle(flag_bf),  $
            'SOURCEAPER', zb_pip_flagtitle(flag_sex), $
            'ASTROMETRY ', zb_pip_flagtitle(flag_wcs), $
            'FLUXCALIBR', zb_pip_flagtitle(flag_mag), $
            'CROSSIDENT', zb_pip_flagtitle(flag_cross)

    printf, lun_out, horline

    printf, lun_out, format='("--------------------",2X,A18,2X,"--------------------")', 'Observation   info'

    printf, lun_out, date_obs, time_obs, $
      format='("Observe date and time  UTC ", A,1X,A)'
    printf, lun_out, filter, exptime, $
      format='("Filter: ", A, ",     Exposure: ", F5.1, "s")'
    printf, lun_out, obj, fileno, jd-2450000.5, $
      format='("Object: ",A20,"  File No ",I4,"   MJD ",F9.4)'

    printf, lun_out, format='("--------------------",2X,A18,2X,"--------------------")', 'Astrometry  Result'

    printf, lun_out, med_resid_ra , sig_resid_ra, med_resid_dec, sig_resid_dec, med_resid_dis, sig_resid_dis, $
      format='("Astrometry residual: RA=",F5.2,"+-",F-5.2,", Dec=",F5.2,"+-",F-5.2,", Dis=",F5.2,"+-",F-5.2," (arcsec)")'

    printf, lun_out, nwcs, wcsmag_const, $
      format='("Astrometry using ",I5," stars, mag correction const = ",F5.2)'

    printf, lun_out, oldra, oldradeg, olddec, olddecdeg, $
      format='("Original   Coord:    ", A-12,"(",F8.4,") ", A-12,"(",F8.4,")")'
    printf, lun_out, ra, radeg, dec, decdeg, $
      format='("Calibrated Coord:    ", A-12,"(",F8.4,") ", A-12,"(",F8.4,")")'
    printf, lun_out, ra_bias, dec_bias, $
      format='("Pointing correction: ", F7.2, 2X, F7.2, " (arcsec)")'

    printf, lun_out, obsazi, obsele, obsairm, $
      format='("Azi: ", F6.1, "   Alt: ",F6.1, "   Airmass: ", F5.2)'

    printf, lun_out, mphase, malt, mangle, $
      format='("Moon Phase: ", F5.1, "%  Moon Alt: ",F5.1,"(deg)  Moon-Object Angle: ", F5.1, "(deg)")'

    printf, lun_out, format='("--------------------",2X,A18,2X,"--------------------")', 'Photometry  Result'

    printf, lun_out, n_star, med_fwhm, sig_fwhm, med_elong, sig_elong, $
      format='("Total ",I5," stars detected.    FWHM=",F5.2,"+-",F-5.2,"    Elongation=",F4.2,"+-",F-4.2)'

    printf, lun_out, limitsig, limitmag, $
      format='("Limit mag of ",A," sigmas:  ",A)'
    if nmag gt 0 then printf, lun_out, limitmagx+mag_const, $
      format='("Corrected Limit mag: ",'+nlimit+'(1x,F6.2))'

    ;printf, lun_out, checkmag, checkerr, $
    ;  format='("Error of mag ",A," is ",A)'

    printf, lun_out, nmag, mag_const, mag_error, $
      format='("Mag correction using ",I3," star(s)    mag const = ",F5.2,"+-",F6.4)'

    printf, lun_out, format='("--------------------",2X,A18,2X,"--------------------")', 'Skylight  Data'

    if nmag gt 0 then skymagxx = string(skymagx+mag_const,format='(F5.2)') else skymagxx = 'x'
    printf, lun_out, skymedx, skysigx, skymagx, skyerrx, skymagxx, $
      format='("Sky Flux (ADU/as^2): ",F8.2,"+-",F8.4,"   Mag: ",F5.2,"+-",F6.4,"  Corrected: ",A5)'
    for gg = 0, ngg-1 do $
    printf, lun_out, gg+1, skymed[gg], skysig[gg], skymag[gg], skyerr[gg], $
      format='("Sky        AMP # ",I2.2,": ",F8.2,"+-",F8.4,"   Mag: ",F5.2,"+-",F6.4)'

    printf, lun_out, horline
    printf, lun_out, r_now(), format='(40X, "Report Date & Time: ",A20)'
    close, lun_out

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; write report database
    openw, lun_out, db_txt

    printf, lun_out, 'OBJECT', 'MJD', 'No', 'Date', 'Time', 'Filter', 'ExpT', $ ;A
      'NWCS', 'MagWcs', $ ;B
      'SidRaM', 'SidRaS', 'SidDecM', 'SidDecS', 'SidDisM', 'SidDisS', $ ;C
      'OriRa', 'OriDec', 'Ra', 'Dec', 'CorRa', 'CorDec', $ ;D
      'Azi', 'Alt', 'AirM', 'MPh', 'MAlt', 'MAng', $ ;E
      'NStar', 'FwhmM', 'FwhmS', 'ElonM', 'ElonS', $ ;F
      'NMag', 'MagCst', 'MagErr', $ ;G
      'Mag'+string(limitsigx,format='(I-3)'), $ ;H
      'SkyFlux', 'SkySig', 'SkyMag', 'SkyErr', $, ;I
      ;'Err'+string(checkmagx,format='(F-4.1)'), $ ;J
      Format='("#",A9,1X,A4,1x, A4,1x, A10,1x, A10,1x, A7,1x, A5,1x, ' + $ ;A
      'A4,1x, A6,1x, ' + $ ;B
      '6(A7,1x), ' + $ ;C
      '4(A9,1x), 2(A7,1x), ' + $ ;D
      'A6,1x, A6,1x, A5,1x, A5,1x, A5,1x, A5,1x, ' + $ ;E
      'A5,1x, 2(A5,1x), 2(A5,1x), ' + $ ;F
      'A4,1x, A6,1x,A6,1x, ' + $ ;G
       nlimit+'(A6,1x), ' + $ ;H
      'A9,1x, A9,1x, A5,2x, A6,2x, '+ $ ;I
       ;ncheck+'(A7,2x), )' + ;J
      '1x )'

    printf, lun_out, obj, jd-2450000.5, fileno, date_obs, time_obs, $ ;A1
      filter, exptime, $;A2
      Format='(A10,1X,I4,1x, I4,1x, A10,1x, A10,1x, A7,1x, F5.1, $ ) ' ;A

    printf, lun_out, nwcs, wcsmag_const, $ ;B
      med_resid_ra , sig_resid_ra, med_resid_dec, sig_resid_dec, med_resid_dis, sig_resid_dis, $ ;C
      oldradeg, olddecdeg, radeg, decdeg, $ ;D1
      ra_bias, dec_bias, $ ;D2
      obsazi, obsele, obsairm, $ ;E1
      mphase, malt, mangle, $ ;E2
      format='(1x, I4,1x, F6.3,1x, ' + $ ;B
      '6(F7.3,1x), ' + $ ;C
      '4(F9.5,1x), 2(F7.2,1x), ' + $ ;D
      'F6.1,1x, F6.1,1x, F5.2,1x, F5.1,1x, F5.1,1x, F5.1, $ )' ;E

    printf, lun_out, n_star, med_fwhm, sig_fwhm, med_elong, sig_elong, $ ;F
      nmag, mag_const, mag_error, $ ;G
      limitmagx, $ ;H  mag_limit
      format='(1x, I5,1x, 2(F5.2,1x), 2(F5.3,1x), ' + $ ;F
      'I4,1x, F6.2,1x, F6.2,1x, ' + $ ;G
       nlimit+'(F6.2,1x), $ )' ;H

    printf, lun_out, skymedx, skysigx, skymagx, skyerrx, $ ; I
      format='(1x, F9.2,1x, F9.4,1x, F5.2,2x, F6.4,2x, $)' ;I

    printf, lun_out, checkerrx, $ ;J
      format='(2x, '+ncheck+'(F7.3,2x), $ )' ;J

    printf, lun_out, ' ' ; ending

    close, lun_out
    free_lun, lun_out

    print, rep_txt
    spawn, 'cat ' + rep_txt

end