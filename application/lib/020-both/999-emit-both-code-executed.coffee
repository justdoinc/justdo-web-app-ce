# /client and /server code loads after /020-both , this is a
# workaround to let code there to run only after the code
# in this folder is done (remember emit is sync, exec of
# events binded won't wait for next tick)
APP.emit "both-code-executed"