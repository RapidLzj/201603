pro zb_pip, rawpath, redpath, file, bias, flat, $
    overwrite=overwrite, silent=silent, verbose=verbose, $
    works=works, version=version, $
    matchdis=matchdis, $
    nobf=nobf, $
    nosex=nosex, limitsig=limitsig, checkmag=checkmag, keep=keep, sexcmd=sexcmd, $
    nowcs=nowcs, catawcs=catawcs, sdss=sdss, ub1=ub1, recenter=recenter, $
    nomag=nomag, magauto=magauto, catamag=catamag, magmatchmax=magmatchmax, $
    cross=cross, catacross=catacross, wcscross=wcscross

    horline = strjoin(replicate('=',80),'')
    if n_params() lt 3 then begin
        print, format='(A)', horline, $
        'BOK telescope image data process pipeline', $
        'Syntax:', $
        '  zb_onsite, rawpath, redpath, file, bias, flat, $', $
        '    /overwrite, /silent, /verbose,               $', $
        '    works=, version=, matchdis=,                 $', $
        '    /nobf,                                       $', $
        '    /nosex, limitsig=, checkmag=, /keep, sexcmd=,$', $
        '    /nowcs, catawcs=, /sdss, /ub1, /recenter,    $', $
        '    /nomag, /magauto, catamag=,                  $', $
        '    /cross, catacross=, /wcscross                 ', $
        horline
        return
    endif

    ; works do or donot, and check
    if keyword_set(works) then begin
        if works eq -1 then works = 0
        workstr = string(works, format='(B5.5)')
        nobf  = strmid(workstr, 0, 1) eq 0
        nosex = strmid(workstr, 1, 1) eq 0
        nowcs = strmid(workstr, 2, 1) eq 0
        nomag = strmid(workstr, 3, 1) eq 0
        cross = strmid(workstr, 4, 1) eq 1
    endif else begin
        r_default, nobf
        r_default, nosex
        r_default, nowcs
        r_default, nomag
        r_default, cross ; default no cross now
        works = (~nobf)*16 + (~nosex)*8 + (~nowcs)*4 + (~nomag)*2 + (cross)*1
    endelse
    ; valid combine:
    ; +++++ 31
    ; ++++- 30  -++++ 15
    ; +++-- 28  -+++- 14  --+++ 7
    ; ++--- 24  -++-- 12  --++- 6  ---++ 3
    ; +---- 16  -+---  8  --+-- 4  ---+- 2  ----+ 1
    ; ----- 0 (only report)
    ; invalid: others

    if r_complist(works, [31,30,15,28,14,7,24,12,6,3,16,8,4,2,1,0]) eq -1 then begin
       print, 'Invalid combine of control. Abort'
       return
    endif

    ; path postfix check
    if strmid(rawpath, 0, 1, /reverse) ne '/' then rawpath = rawpath+'/'
    if strmid(redpath, 0, 1, /reverse) ne '/' then redpath = redpath+'/'
    ; default bias and flat file
    r_default, bias, redpath+'../bias.fits'
    r_default, flat, redpath+'../flat.fits'
    ; keyword process
    ; general keyword
    r_default, overwrite
    r_default, version, '.'  ; used in report module
    if keyword_set(verbose) then $
        screenmode = 2 $
    else if keyword_set(silent) then $
        screenmode = 0 $
    else $
        screenmode = 1
    r_default, matchdis, 0.002  ; 7.2 as
    ; bias flat keyword
    ; photometry keyword
    r_default, limitsig, [5, 10, 33.3, 50, 100, 333.3]
    r_default, checkmag, [15.0, 16.0, 17.0, 18.0, 19.0]
    r_default, keep
    r_default, sexcmd, 'sextractor' ; sextractor or sex
    ; astrometry catalog keyword
    if keyword_set(sdss) then catawcs = 'sdss' $
    else if keyword_set(ub1) then catawcs = 'ub1' $
    else if ~keyword_set(catawcs) then catawcs = 'sdss'
    ; center keyword
    r_default, recenter
    ; mag correction keyword
    r_default, magauto
    r_default, catamag, 'catalog/HM1998.fits'
    r_default, magmatchmax, 80
    ; cross identifier keywords
    r_default, catacross, 'catalog/hd.ldac'
    r_default, wcscross

    defsysv, '!TELESCOPE', 'BOK'
    @zh_const.pro

    ; file full path
    obs_fits = rawpath + file + '.fits'
    sci_path = redpath + file + '/'
    file_mkdir, sci_path

    ggs = string(indgen(16)+1,format='(I2.2)')
    versiond = version eq '.' ? '' : '.' + version
    sec_fits = sci_path + file + '.' + ggs +'.fits'
    sex_ldac = sci_path + file + '.phot.ldac'
    wcs_ldac = sci_path + file + '.wcs.ldac'
    mag_ldac = sci_path + file + '.mag.ldac'
    cross_ldac = sci_path + file + '.cross.ldac'
    rep_txt  = sci_path + file + versiond + '.report.txt'
    db_txt   = sci_path + file + versiond + '.db.txt'

    needoverwrite = ( ~nobf  && max(file_test(sec_fits)) ) || $
                    ( ~nosex && file_test(sex_ldac) ) || $
                    ( ~nowcs && file_test(wcs_ldac) ) || $
                    ( ~nomag && file_test(mag_ldac) ) || $
                    (  cross && file_test(cross_ldac) )
    if needoverwrite then begin
        if overwrite then begin
            print, file+' already reduced, overwrite!'
        endif else begin
            print, file+' already reduced, skip!'
            return
        endelse
    endif

    ; file existing check
    if ~nobf or ~nosex then if ~ file_test(obs_fits) then begin
        print, 'Observation fits needed, but not found. Abort!'
        return
    endif
    if ~nobf then if ~ file_test(bias) or ~ file_test(flat) then begin
        print, 'bias and flat needed, but not found. Abort!'
        return
    endif
    if nobf and ~nosex then if ~ min(file_test(sec_fits)) then begin
        print, 'Calibration result needed, but not found. Abort!'
        return
    endif
    if nosex and ~nowcs then if ~ file_test(sex_ldac) then begin
        print, 'Photometry result needed, but not found. Abort!'
        return
    endif
    if nowcs and ~nomag then if ~ file_test(wcs_ldac) then begin
        print, 'Astrometry result needed, but not found. Abort!'
        return
    endif

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    timebegin = systime(/seconds)

    if ~ nobf then begin
        flag_bf = zb_pip_biasflat( rawpath, sci_path, file, bias, flat, $
            screenmode=screenmode)
    endif else begin
        flag_bf = FLAG_SKIP
    endelse

    if ~ nosex and flag_bf ne FLAG_FAIL and flag_bf ne FLAG_ERROR then begin
        flag_sex = zb_pip_photometry( rawpath, sci_path, file, $
            limitsig, checkmag, keep, sexcmd, $
            screenmode=screenmode)
    endif else begin
        flag_sex = FLAG_SKIP
    endelse

    timewcs = systime(/seconds)
    if (~nobf or ~nosex) and screenmode gt 0 then print, horline, timewcs - timebegin, horline, $
        format='(A/"Photometry finished. ",F5.1," seconds used."/A)'

    if ~ nowcs and flag_sex ne FLAG_FAIL and flag_sex ne FLAG_ERROR then begin
        flag_wcs = zb_pip_astrometry( sci_path, file,  $
            catawcs, recenter, checkmag, $
            screenmode=screenmode)
    endif else begin
        flag_wcs = FLAG_SKIP
    endelse

    timeall = systime(/second)
    if (~nowcs) and screenmode gt 0 then print, horline, timeall - timewcs, horline, timeall - timebegin, horline, $
        format='(A/"Astrometry finished. ",F5.1," seconds used for WCS."/A/ "All fnished.",F5.1," seconds for all.")'

    if ~ nomag and flag_wcs ne FLAG_FAIL and flag_wcs ne FLAG_ERROR then begin
        flag_mag = zb_pip_magcalibrate( sci_path, file, $
            magauto, catamag, checkmag, matchdis=matchdis, magmatchmax=magmatchmax, $
            screenmode=screenmode)
    endif else begin
        flag_mag = FLAG_SKIP
    endelse

    if cross and flag_wcs ne FLAG_FAIL and flag_wcs ne FLAG_ERROR then begin
        flag_cross = zb_pip_cross( sci_path, file, $
            catacross, wcscross, matchdis=matchdis, $
            screenmode=screenmode)
    endif else begin
        flag_cross = FLAG_SKIP
    endelse

    if works eq 0 then begin ; for only report, found out previous last step
        if file_test(cross_ldac) then $
            flag_cross = FLAG_OK $
        else if file_test(mag_ldac) then $
            flag_mag = FLAG_OK $
        else if file_test(wcs_ldac) then $
            flag_wcs = FLAG_OK $
        else if file_test(sex_ldac) then $
            flag_sex = FLAG_OK $
        else $
            flag_bf = FLAG_OK
    end

    zb_pip_report, sci_path, file, $
        flag_bf, flag_sex, flag_wcs, flag_mag, flag_cross, $
        version, screenmode=screenmode

end


