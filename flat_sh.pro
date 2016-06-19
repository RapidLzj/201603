pro flat_sh, yr, mn, dy, run
    r_default, run, string(yr, mn, format='(I4.4,I2.2)')
    days = string(yr, mn, dy,format='(I4.4,I2.2,I2.2)')
    dpu = '/data/red/bok/u/pass1/'+run+'/'+days+'/'
    dpv = '/data/red/bok/v/pass1/'+run+'/'+days+'/'
    zb_pp_flat, dpu+'list/flat.lst', dpu+'bias.fits', dpu+'flat.fits'
    zb_pp_flat, dpv+'list/flat.lst', dpv+'bias.fits', dpv+'flat.fits'
end
