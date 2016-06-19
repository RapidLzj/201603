pro obj_xao, yr, mn, dy, run, typ, fil
    r_default, run, string(yr, mn, format='(I4.4,I2.2)')
    r_default, typ, ['good','other','bad']
    r_default, fil, ['u', 'v', 'b', 'y', 'Hw', 'Hn']
    days = string(yr, mn, dy,format='(I4.4,I2.2,I2.2)')
    ntyp = n_elements(typ)
    nfil = n_elements(fil)

    for t = 0, ntyp-1 do begin
    for ff = 0, nfil-1 do begin

        dp = '/data/red/XAO/'+fil[ff]+'/pass1/'+run+'/'+days+'/'
        if ~ file_test(dp+'list/'+typ[t]+'.lst') then continue
        readcol, dp+'list/'+typ[t]+'.lst', paths,files, format='a,a',count=nf

        for f = 0, nf-1 do begin
            zn_pip, paths[f], dp+typ[t], files[f], dp+'bias.fits', dp+'flat.fits', $
                /magauto, /keep, /verbose;, /overwrite
        endfor

    endfor
    endfor
end
