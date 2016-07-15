; pipeline shell

args = command_line_args(count=cnt)

tel  = args[0]
rawp = args[1]
redp = args[2]
bare = args[3]
bias = args[4]
flat = args[5]
if cnt gt 6 then version = args[6] else version=''
if cnt gt 7 then works = fix(args[7]) else works = 0

print, tel,rawp,redp,bare,bias,flat,format='("(",a,")")'

restore, 'zb_pip_all.sav'
zb_pip, rawp, redp, bare, bias, flat, /magauto,/over,/verbose, $
    /ub1, /keep, catamag='catalog/block1.ldac',version=version, works=works,magmatchmax=1200

exit
