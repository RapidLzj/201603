function zb_pip_cross, sci_path, file, $
            catacross, wcscross, matchdis=matchdis, $
            screenmode=screenmode

    r_default, catacross, 'catalog/hd.ldac'
    r_default, wcscross, 0
    r_default, matchdis, 0.002  ; 7.2 as
    r_default, screenmode, 1
    @zh_const.pro

    wcs_ldac = sci_path + file + '.wcs.ldac'
    mag_ldac = sci_path + file + '.mag.ldac'
    cross_ldac = sci_path + file + '.cross.ldac'
    cross_cat = sci_path + file + '.cross.cat'

    ; when mag exists and not specify wcs, use mag
    ori_ldac = (wcscross || ~ file_test(mag_ldac) ) ? wcs_ldac : mag_ldac

    if ~ file_test(ori_ldac) then begin
        print, 'WCS or MAG result is missing. ABORT'
        return, FLAG_ERROR
    endif
    if ~ file_test(catacross) then begin
        print, 'Cross catalogue is missing. ABORT'
        return, FLAG_ERROR
    endif

    stars = r_ldac_read(ori_ldac, hdr, /silent)
    cata  = r_ldac_read(catacross, /silent)
    n_star = n_elements(stars)
    n_cata = n_elements(cata)

    rac =  cata.radeg & decc =  cata.decdeg & magc =  cata.mag1
    ras = stars.radeg & decs = stars.decdeg & mags = stars.mag_auto

    msgres = r_match(rac, decc, magc, ras, decs, mags, nmatch, cid, sid, msdis, $
        matchlimit=1, maxdis=matchdis)

    if screenmode ge 1 then print, nmatch, n_star, n_cata, $
        format='(I4," star(s) cross matched between ",I4," image stars and ",I7," catalogue stars")'

    if nmatch eq 0 then return, FLAG_FAIL

    stars[sid].ixCross = cid

    sxaddpar, hdr, 'NCROSS', nmatch

    r_ldac_write, cross_ldac, stars, hdr
    zh_outcat, cross_cat, stars

    return, nmatch ;FLAG_OK


end