function zb_pip_biasflat, rawpath, sci_path, file, bias, flat, $
    screenmode=screenmode

    @zh_const.pro
    r_default, screenmode, 1
    obs_fits = rawpath + '/' + file + '.fits'

    hdr = headfits(obs_fits)
    expt = sxpar(hdr, 'EXPTIME') * 1.0

    for gg = 1, ngg do begin
        ; section file full name
        sec_fits = string(sci_path, file, gg, format='(A,A,".",I2.2,".fits")')

        bias_dat = mrdfits(bias, gg, /silent)
        flat_dat = mrdfits(flat, gg, /silent)

        ; load sec data, remove overscan, correct bias and flat
        dat0 = mrdfits(obs_fits, gg, hdr1, /silent)
        ;osdir = (sxpar(hdr1, 'OVRSCAN2') eq 0 ? 1 : 2)
        dat1 = zb_rm_overscan(dat0 + 32768L) ; U, osdir)
        dat2 = (dat1 - bias_dat) / flat_dat / expt

        ; save temp sec fits and call SourceEXtractor
        writefits, sec_fits, dat2, hdr1
    endfor

    return, FLAG_OK
 end
