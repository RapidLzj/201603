pro zb_pp_flat, listfile, bias, outfile

  if ~ file_test (bias) then begin
    message, 'BIAS file (' + file + ') is missing, QUIT!', /cont
    return
  endif

  readcol, listfile, flatfiles, count=n_file, format='A', /silent

  nx = 2016 & ny = 2048

  hdr = headfits(flatfiles[0], /silent)
  mwrfits, 0, outfile, hdr, /create

  flat_dat = fltarr(nx, ny, n_file)
  for gg = 1, 16 do begin
    bias_dat = mrdfits(bias, gg)
    for ff = 0, n_file-1 do begin
      print, ff+1, n_file, gg, flatfiles[ff], format='("Load ",I3,"/",I-3," Section ",I2," : ",A)'

      dat0 = mrdfits(flatfiles[ff], gg, hdr1, /silent)
      dat1 = zb_rm_overscan(dat0 + 32768U) - bias_dat
      dat1 /= median(dat1)
      flat_dat[*,*, ff] = dat1
    endfor
    print, gg, format='("Section ",I2," merging....")'
    if n_file gt 1 then $
      merge_flat_dat = median(flat_dat, dim=3, /even) $
    else $
      merge_flat_dat = flat_dat[*,*,0]
    sxaddpar, hdr1, 'BZERO', 0.0
    mwrfits, merge_flat_dat, outfile, hdr1
  endfor

  print, 'FLAT Done'
end