pro zn_pp_mklst, yr, mn, dy, filter, runcode, $
    rawbase=rawbase, redbase=redbase

    r_default, runcode, string(yr, mn, format='(I4.4,I2.2)')

    r_default, rawbase, string(runcode, yr, mn, dy, $
        format='("/data/raw/XAO/",A,"/",I4.4,I2.2,I2.2,"/")')
    r_default, redbase, string(filter, runcode, yr, mn, dy, $
        format='("/data/red/XAO/",A,"/pass1/",A,"/",I4.4,I2.2,I2.2,"/")')

    file_mkdir, redbase+['good','other','bad','list']
    lstpath = redbase + 'list/'

  ; bias list
  files = file_search(rawbase + 'BIAS/', 'BIAS_*.fits', count=nf)
  lst = lstpath + 'bias.lst'
  if nf gt 0 then begin
    openw, 1, lst
    for f = 0, nf-1 do begin
      if (file_info(files[f])).size eq 34424640 then $
        printf, 1, files[f]
    endfor
    close, 1
    print, lst, nf
  endif else begin
    print, lst, '  NULL'
  endelse

  ; flat list
    files = file_search(rawbase + 'FLAT/', 'FLAT_'+filter+'_*.fits', count=nf)
    if nf lt 5 then $
      lst = lstpath + 'flat_few.lst' $
    else $
      lst = lstpath + 'flat.lst'
    if nf gt 0 then begin
      openw, 1, lst
      for f = 0, nf-1 do begin
        if (file_info(files[f])).size eq 34424640 then $
          printf, 1, files[f]
      endfor
      close, 1
      print, lst, nf
    endif else begin
      print, lst, '  NULL'
    endelse

  ; super flat list and data file list
    files = file_search(rawbase + 'uvby_survey/', '*_'+filter+'_*.fits', count=nf)
    if nf gt 0 then begin
        ob = strarr(nf)
        for f = 0, nf-1 do begin
            sp = reverse(strsplit(files[f], '/', /ex))
            ob[f] = sp[1]
        end
        uob = uniq(ob, sort(ob))
        if n_elements(uob) lt 10 then $
          lst = lstpath + 'superflat_few.lst' $
        else $
          lst = lstpath + 'superflat.lst'
        openw, 1, lst
        for f = 0, nf-1 do begin
            if (file_info(files[f])).size eq 34424640 then $
                printf, 1, files[f]
        endfor
        close, 1
        print, lst, nf, n_elements(uob)
    endif else begin
        print, lst, '  NULL'
    endelse

    goodlst = lstpath + 'good.lst'
    otherlst = lstpath + 'other.lst'
    if nf gt 0 then begin
      openw, 1, goodlst
      openw, 2, otherlst
      gg = 0 & oo = 0
      for f = 0, nf-1 do begin
        if (file_info(files[f])).size eq 34424640 then begin
          sp = strpos(files[f], '/', /reverse_search)
          fp = strmid(files[f], 0, sp + 1)
          fn = strmid(files[f], sp + 1, strlen(files[f]) - sp - 6)
          ob = (strsplit(fn, '_', /ex))[0]
          if r_strint(ob) then begin
              gg++
              printf, 1, fp, fn, format='(A,2X,A)'
          endif else begin
              oo++
              printf, 2, fp, fn, format='(A,2X,A)'
          endelse
        endif
      endfor
      close, 1, 2
      print, goodlst, gg
      print, otherlst, oo
    endif else begin
      print, goodlst, '  NULL'
      print, otherlst, ' NULL'
    endelse

    print, 'list generated'

end

