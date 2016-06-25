pro zb_pp_flat, listfile, bias, outfile

    if ~ file_test (bias) then begin
        message, 'BIAS file (' + file + ') is missing, QUIT!', /cont
        return
    endif

    readcol, listfile, flatfiles, count=n_file, format='A', /silent

    nx = 2016 & ny = 2048 & namp = 16

    hdr = headfits(flatfiles[0], /silent)
    mwrfits, 0, outfile, hdr, /create

    flat_dat = fltarr(nx, ny, namp, n_file)
    bias_dat = fltarr(nx, ny, namp)
    flat_1 = fltarr(nx, ny, namp)

    print, bias, format='("Load BIAS : ",A / 12x,"Section : ",$)'
    for gg = 1, namp do begin
        print, gg, format='(" ",I2,",",$)'
        bias_dat[*,*, gg-1] = mrdfits(bias, gg, /silent)
    endfor
    print, ''

    for ff = 0, n_file-1 do begin
        print, ff+1, n_file, flatfiles[ff], format='("Load ",I3,"/",I-3," : ",A / 12x,"Section : ",$)'
        for gg = 1, namp do begin
            print, gg, format='(" ",I2,",",$)'
            dat0 = mrdfits(flatfiles[ff], gg, hdr1, /silent)
            flat_1[*,*, gg-1] = zb_rm_overscan(dat0 + 32768U)
        endfor
        print, ' Normalize ...'
        flat_1 -= bias_dat
        flat_1 /= median(flat_1)
        flat_dat[*,*,*, ff] = flat_1
    endfor

    print, format='("Merging....")'
    merge_flat_dat = median(flat_dat, dim=4, /even)

    for gg = 1, namp do begin
        hdr1 = headfits(flatfiles[0], ext=gg, /silent)
        sxaddpar, hdr1, 'BZERO', 0.0
        mwrfits, merge_flat_dat[*,*, gg-1], outfile, hdr1, /silent
    endfor

    print, 'FLAT Done'
end
