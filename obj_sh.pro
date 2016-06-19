pro obj_sh, yr, mn, dy, run, typ 
    r_default, run, string(yr, mn, format='(I4.4,I2.2)')
    r_default, typ, ['good','bad','other']
    days = string(yr, mn, dy,format='(I4.4,I2.2,I2.2)')
    ntyp = n_elements(typ)
    dpu = '/data/red/bok/u/pass1/'+run+'/'+days+'/'
    dpv = '/data/red/bok/v/pass1/'+run+'/'+days+'/'
    rpu = '/data/raw/bok/u/'      +run+'/'+days+'/'
    rpv = '/data/raw/bok/v/'      +run+'/'+days+'/'

    for t = 0, ntyp-1 do begin

        readcol, dpu+'list/'+typ[t]+'.lst', files, format='a',count=nf
        for f = 0, nf-1 do begin
            zb_pip, rpu+typ[t], dpu+typ[t], files[f], $ ; default standard bias & flat
                /magauto, /keep, /verbose, /overwrite
        endfor

        readcol, dpv+'list/'+typ[t]+'.lst', files, format='a',count=nf
        for f = 0, nf-1 do begin
            zb_pip, rpv+typ[t], dpv+typ[t], files[f], $ ; default standard bias & flat
                /magauto, /keep, /verbose, /overwrite
        endfor

    endfor
end
