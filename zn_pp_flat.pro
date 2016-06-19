pro zn_pp_flat, listfile, bias, outfile
; use previous version
    if ~ file_test (bias) then begin
        message, 'BIAS file (' + file + ') is missing, QUIT!', /cont
        return
    endif

    readcol, listfile, flatfiles, count=n_file, format='A', /silent

    nx = 4096 & ny = 4136

    hdr = headfits(flatfiles[0], /silent)

    flat_dat = fltarr(nx, ny, n_file)
    bias_dat = readfits(bias)

    for ff = 0, n_file-1 do begin
        print, ff+1, n_file, flatfiles[ff], format='("Load ",I3,"/",I-3," : ",A)'

        dat0 = readfits(flatfiles[ff], /silent)
        dat1 = zn_rm_overscan(dat0) - bias_dat
        dat1 /= median(dat1)
        flat_dat[*,*, ff] = dat1
    endfor

    print, format='("Merging....")'
    merge_flat_dat = median(flat_dat, dim=3, /even)

    sxaddpar, hdr, 'ROVER', 0
    sxaddpar, hdr, 'COVER', 0
    sxaddpar, hdr, 'BZERO', 0.0
    sxaddpar, hdr, 'MERGE-DT', r_now()
    sxaddpar, hdr, 'DATA_CNT', n_file
    sxaddpar, hdr, 'OBJECT'  , 'MERGED_FLAT'

    writefits, outfile, merge_flat_dat, hdr

    print, 'FLAT Done'
end