pro bias_sh, yr, mn, dy, run
    r_default, run, string(yr, mn, format='(I4.4,I2.2)')
    days = string(yr, mn, dy,format='(I4.4,I2.2,I2.2)')
    dpu = '/data/red/bok/u/pass1/'+run+'/'+days+'/'
    dpv = '/data/red/bok/v/pass1/'+run+'/'+days+'/'
    zb_pp_bias, dpu+'list/bias.lst', dpu+'bias.fits'
    file_copy, dpu+'bias.fits', dpv+'bias.fits'
end
