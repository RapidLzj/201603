pro zb_pp_flat2, listfile, bias, outfile, dir=dir, super=super, rawbase=rawbase

  dir = keyword_set(dir)
  super = keyword_set(super)

  if super then begin
    if ~keyword_set(rawbase) then begin
      p = strsplit(listfile, '/', /ex)
      rawbase = string(p[3],p[5],p[6], format='("/data/raw/bok/",A,"/",A,"/",A)')
      print, 'Default raw base dir is: ' + rawbase
    endif

    if file_test(listfile + '/list/good.lst') then $
      readcol, listfile + '/list/good.lst', goodfiles, count=n_good, format='A', /silent $
    else $
      n_good = 0
    if file_test(listfile + '/list/other.lst') then $
      readcol, listfile + '/list/other.lst', otherfiles, count=n_other, format='A', /silent $
    else $
       n_other = 0

    if n_good eq 0 and n_other gt 0 then begin
      flatfiles = rawbase+'/other/'+otherfiles+'.fits'
      n_file = n_other
    endif else if n_good gt 0 and n_other eq 0 then begin
      flatfiles = rawbase+'/good/'+goodfiles+'.fits'
      n_file = n_good
    endif else if n_good gt 0 and n_other gt 0 then begin
      flatfiles = [rawbase+'/good/'+goodfiles+'.fits', rawbase+'/other/'+otherfiles+'.fits']
      n_file = n_good + n_other
    endif else begin
      n_file = 0
    endelse

    if ~ keyword_set(bias) then bias = listfile + '/bias.fits'
    if ~ keyword_set(outfile) then outfile = listfile + '/superflat.fits'

  endif else if dir then begin
    readcol, listfile + '/list/flat.lst', flatfiles, count=n_file, format='A', /silent
    if ~ keyword_set(bias) then bias = listfile + '/bias.fits'
    if ~ keyword_set(outfile) then outfile = listfile + '/flat.fits'

  endif else begin
    readcol, listfile, flatfiles, count=n_file, format='A', /silent

  endelse

  if n_file lt 5 then begin
      message, 'No or few file for flat generation. QUIT!', /cont
      return
  endif

  if ~ file_test (bias) then begin
    message, 'BIAS file (' + file + ') is missing, QUIT!', /cont
    return
  endif

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
