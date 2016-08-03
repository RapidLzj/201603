pro sdss_csv_ldac, csvf, ldacf
    ; Transfer SDSS csv file to ldac catalog
    readcol, csvf, ra,dec,u,g,r,i,z,Err_u,Err_g,Err_r,Err_i,Err_z, $
        format='x,x,x,x,x,x,x, f,f, f,f,f,f,f, f,f,f,f,f', count=ns
    s1 = {radeg:0.0d, decdeg:0.0d, $
          u  :0.0, g  :0.0, r  :0.0, i  :0.0, z  :0.0, $
          uer:0.0, ger:0.0, rer:0.0, ier:0.0, zer:0.0}
    ss = replicate(s1, ns)
    ss.radeg = ra
    ss.decdeg = dec
    ss.u = u
    ss.g = g
    ss.r = r
    ss.i = i
    ss.z = z
    ss.uer = Err_u
    ss.ger = Err_g
    ss.rer = Err_r
    ss.ier = Err_i
    ss.zer = Err_z
    r_ldac_write, ldacf, ss
end