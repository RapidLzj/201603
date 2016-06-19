function zn_pip_biasflat, rawpath, sci_path, file, bias, flat, $
    screenmode=screenmode

    @zh_const.pro
    r_default, screenmode, 1
    obs_fits = rawpath + '/' + file + '.fits'

    bias_dat = readfits(bias, /silent)
    flat_dat = readfits(flat, /silent)
    dat0 = readfits(obs_fits, hdr, /silent)
    dat1 = (zn_rm_overscan(dat0) - bias_dat) / flat_dat
    sxaddpar, hdr, 'BZERO', 0.0

    nx = 2048 & ny = 2068
    nx2 = nx * 2 & ny2 =ny * 2
    nx0 = [0,1,0,1] * nx ; x/y start of each amp in whole image
    ny0 = [0,0,1,1] * ny

    sec_fits = sci_path + file +'.'+ ggs + '.fits'

    for gg = 0, ngg-1 do begin
        dat2 = dat1[nx0[gg]:nx0[gg]+nx-1, ny0[gg]:ny0[gg]+ny-1]

        ; save temp sec fits and call SourceEXtractor
        writefits, sec_fits[gg], dat2, hdr
    endfor

    return, FLAG_OK
 end
