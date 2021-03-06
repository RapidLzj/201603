function zh_magcata, ra, dec, halfsize
    if ~ keyword_set(halfsize) then halfsize = 0.6
    readcol, 'apass_block.txt', fn, de0, de1, ra0, ra1, format='a,f,f,f,f'
    ix = where(ra0 le ra and ra lt ra1 and de0 le dec and dec lt de1, nix)
    if nix eq 1 then begin
        ss = r_ldac_read("catalog/apass/"+fn[ix[0]])
        ras = halfsize / cos(dec / 180.0 * !pi)
        six = where(ra-ras lt ss.radeg and ss.radeg lt ra+ras and $
                    dec-halfsize lt ss.decdeg and ss.decdeg lt dec+halfsize, nix)
        if nix gt 0 then $
            return, ss[six] $
        else return, 0
    endif else begin
        return, 0
    endelse
end