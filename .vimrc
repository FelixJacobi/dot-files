set pastetoggle=<F2>

" allow toggling between local and default mode
function TabToggle()
  if &expandtab
    set shiftwidth=8
    set softtabstop=0
    set noexpandtab
  else
    set shiftwidth=4
    set softtabstop=4
    set expandtab
  endif
endfunction
nmap <F9> mz:execute TabToggle()<CR>'z

" For never youcompleteme versions no longer providing autoload files
if !empty(expand(glob("/usr/share/vim/vimfiles/pack/dist-bundle/opt/youcompleteme")))
  packadd! youcompleteme
endif
