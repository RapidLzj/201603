pro zb_pp_mklst, yr, mn, dy, filter, runcode, $
    rawbase=rawbase, redbase=redbase

    if ~ keyword_set(runcode) then runcode = string(yr, mn, format='(I4.4,I2.2)')

    r_default, rawbase, string(filter, runcode, yr, mn, dy, $
        format='("/data/raw/bok/",A,"/",A,"/",I4.4,I2.2,I2.2,"/")')
    r_default, redbase, string(filter, runcode, yr, mn, dy, $
        format='("/data/red/bok/",A,"/pass1/",A,"/",I4.4,I2.2,I2.2,"/")')

    file_mkdir, redbase+['good','other','bad','list']

    keys = ['bias', 'flat', 'good', 'other', 'bad']

    for k = 0, 1 do begin
        ff = file_search(rawbase+keys[k]+'/*.fits', count=nf)
        openw, 1, redbase+'list/'+keys[k]+'.lst'
        print, redbase+'list/'+keys[k]+'.lst', nf
        for f = 0, nf-1 do begin
            printf, 1, ff[f]
        endfor
        close, 1
    endfor

    for k = 2, 4 do begin
        ff = file_search(rawbase+keys[k]+'/*.fits', count=nf)
        openw, 1, redbase+'list/'+keys[k]+'.lst'
        print, redbase+'list/'+keys[k]+'.lst', nf
        for f = 0, nf-1 do begin
            sf = reverse(strsplit(ff[f], '/', /extr))
            pos = strpos(sf[0], '.', /reverse_search)
            printf, 1, strmid(sf[0], 0, pos)
        endfor
        close, 1
    endfor

    ;spawn, 'ls '+rawbase+'bias/*.fits  > '+redbase+'list/'+'bias.lst'
    ;spawn, 'ls '+rawbase+'flat/*.fits  > '+redbase+'list/'+'flat.lst'
    ;spawn, 'ls '+rawbase+'good/*.fits  > '+redbase+'list/'+'good.lst'
    ;spawn, 'ls '+rawbase+'other/*.fits > '+redbase+'list/'+'other.lst'
    ;spawn, 'ls '+rawbase+'bad/*.fits   > '+redbase+'list/'+'bad.lst'

    print, 'list generated'

end

