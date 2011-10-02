if argc() isnot 2
    %delete _
    finish
endif
execute 'edit' argv(0)
execute 'v/'.argv(1).'/d'
