pro zb_pp_bias, listfile, outfile

  readcol, listfile, biasfiles, count=n_file, format='A', /silent

  nx = 2016 & ny = 2048

  hdr = headfits(biasfiles[0], /silent)
  mwrfits, 0, outfile, hdr, /create

  bias_dat = dblarr(nx, ny, n_file)
  for gg = 1, 16 do begin
    for ff = 0, n_file-1 do begin
      print, ff+1, n_file, gg, biasfiles[ff], format='("Load ",I3,"/",I-3," Section ",I2," : ",A)'

      dat0 = mrdfits(biasfiles[ff], gg, hdr1, /silent, /dscale)
      bias_dat[*,*, ff] = zb_rm_overscan(dat0); + 32768L)
    endfor
    print, gg, format='("Section ",I2," merging....")'
    merge_bias_dat = median(bias_dat, dim=3, /even, /double)
    ;sxaddpar, hdr1, 'BZERO', 0.0
    mwrfits, float(merge_bias_dat), outfile, hdr1
  endfor

  print, 'BIAS Done'
end