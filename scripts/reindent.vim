filetype indent on
filetype detect
if &filetype ==# ''
    echoerr 'failed to detect filetype...exit.'
    finish
endif

setlocal expandtab shiftwidth=2

normal! gg=G
