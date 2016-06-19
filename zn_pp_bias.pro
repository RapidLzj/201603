pro zn_pp_bias, listfile, outfile
; use previous version
    readcol, listfile, biasfiles, count=n_file, format='A', /silent

    nx = 4096 & ny = 4136

    hdr = headfits(biasfiles[0], /silent)

    bias_dat = fltarr(nx, ny, n_file)
    for ff = 0, n_file-1 do begin
        print, ff+1, n_file, biasfiles[ff], format='("Load ",I3,"/",I-3," : ",A)'

        dat0 = readfits(biasfiles[ff], /silent)
        bias_dat[*,*, ff] = zn_rm_overscan(dat0)
    endfor

    print, format='("Merging....")'
    merge_bias_dat = median(bias_dat, dim=3, /even)

    sxaddpar, hdr, 'ROVER', 0
    sxaddpar, hdr, 'COVER', 0
    sxaddpar, hdr, 'MERGE-DT', r_now()
    sxaddpar, hdr, 'DATA_CNT', n_file
    sxaddpar, hdr, 'BZERO', 0.0
    sxaddpar, hdr, 'OBJECT'  , 'MERGED_BIAS'

    writefits, outfile, merge_bias_dat, hdr

    print, 'BIAS Done'
end