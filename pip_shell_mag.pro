; pipeline shell

args = command_line_args(count=cnt)

tel  = args[0]
rawp = args[1]
redp = args[2]
bare = args[3]
bias = args[4]
flat = args[5]

print, tel,rawp,redp,bare,bias,flat,format='("(",a,")")'

zb_pip, rawp, redp, bare, bias, flat, /magauto,/over,/verbose, $
    /ub1, /keep, catamag='catalog/block1x.ldac',version='fit'

exit
