"======================================================================
"
" terminal_help.vim -
"
" Created by skywind on 2020/01/01
" Last Modified: 2020/01/01 01:21:33
"
"======================================================================

"----------------------------------------------------------------------
" check compatible
"----------------------------------------------------------------------
if has('patch-8.1.1') == 0 && has('nvim') == 0
	finish
endif


"----------------------------------------------------------------------
" Initialize
"----------------------------------------------------------------------
let $VIM_SERVERNAME = v:servername
let $VIM_EXE = v:progpath

let s:home = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:script = fnamemodify(s:home . '/../tools/utils', ':p')
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')

" setup PATH for utils
if stridx($PATH, s:script) < 0
	if s:windows == 0
		let $PATH .= ':' . s:script
	else
		let $PATH .= ';' . s:script
	endif
endif

" search for neovim-remote for nvim
let $VIM_NVR = ''
if has('nvim')
	let name = get(g:, 'terminal_nvr', 'nvr')
	if executable(name)
		let $VIM_NVR=name
	endif
endif


"----------------------------------------------------------------------
" open a new/previous terminal
"----------------------------------------------------------------------
function! TerminalOpen()
	let bid = get(t:, '__terminal_bid__', -1)
	let pos = get(g:, 'terminal_pos', 'rightbelow')
	let height = get(g:, 'terminal_height', 10)
	let succeed = 0
	function! s:terminal_view(mode)
		if a:mode == 0
			let w:__terminal_view__ = winsaveview()
		elseif exists('w:__terminal_view__')
			call winrestview(w:__terminal_view__)
			unlet w:__terminal_view__
		endif
	endfunc
	let uid = win_getid()
	noautocmd windo call s:terminal_view(0)
	call win_gotoid(uid)
	if bid > 0
		let name = bufname(bid)
		if name != ''
			let wid = bufwinnr(bid)
			if wid < 0
				exec pos . ' ' . height . 'split'
				exec 'b '. bid
				if has('nvim')
					startinsert
				endif
			else
				exec "normal ". wid . "\<c-w>w"
			endif
			let succeed = 1
		endif
	endif
	if has('nvim')
		let cd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	endif
	if succeed == 0
		let shell = get(g:, 'terminal_shell', '')
		let close = get(g:, 'terminal_close', 0)
		let savedir = getcwd()
		let workdir = (expand('%') == '')? expand('~') : expand('%:p:h')
		silent execute cd . ' '. fnameescape(workdir)
		if has('nvim') == 0
			let cmd = pos . ' term ' . (close? '++close' : '++noclose') 
			exec cmd . ' ++norestore ++rows=' . height . ' ' . shell
		else
			exec pos . ' ' . height . 'split'
			exec 'term ' . shell
			setlocal nonumber signcolumn=no
			startinsert
		endif
		silent execute cd . ' '. fnameescape(savedir)
		let t:__terminal_bid__ = bufnr('')
		setlocal bufhidden=hide
	endif
	let uid = win_getid()
	noautocmd windo call s:terminal_view(1)
	call win_gotoid(uid)
endfunc


"----------------------------------------------------------------------
" hide terminal
"----------------------------------------------------------------------
function! TerminalClose()
	let bid = get(t:, '__terminal_bid__', -1)
	if bid < 0
		return
	endif
	let name = bufname(bid)
	if name == ''
		return
	endif
	let wid = bufwinnr(bid)
	if wid < 0
		return
	endif
	let sid = win_getid()
	noautocmd windo call s:terminal_view(0)
	call win_gotoid(sid)
	if wid != winnr()
		let uid = win_getid()
		exec "normal ". wid . "\<c-w>w"
		close
		call win_gotoid(uid)
	else
		close
	endif
	let sid = win_getid()
	noautocmd windo call s:terminal_view(1)
	call win_gotoid(sid)
endfunc


"----------------------------------------------------------------------
" toggle open/close
"----------------------------------------------------------------------
function! TerminalToggle()
	let bid = get(t:, '__terminal_bid__', -1)
	let alive = 0
	if bid > 0 && bufname(bid) != ''
		let alive = (bufwinnr(bid) > 0)? 1 : 0
	endif
	if alive == 0
		call TerminalOpen()
	else
		call TerminalClose()
	endif
endfunc


"----------------------------------------------------------------------
" can be calling from internal terminal.
"----------------------------------------------------------------------
function! Tapi_TerminalEdit(bid, arglist)
	let name = (type(a:arglist) == v:t_string)? a:arglist : a:arglist[0]
	let cmd = get(g:, 'terminal_edit', 'tab drop')
	silent exec cmd . ' ' . fnameescape(name)
	return ''
endfunc



"----------------------------------------------------------------------
" fast window switching: ALT+SHIFT+HJKL
"----------------------------------------------------------------------
noremap <m-H> <c-w>h
noremap <m-L> <c-w>l
noremap <m-J> <c-w>j
noremap <m-K> <c-w>k
inoremap <m-H> <esc><c-w>h
inoremap <m-L> <esc><c-w>l
inoremap <m-J> <esc><c-w>j
inoremap <m-K> <esc><c-w>k

if has('terminal') && exists(':terminal') == 2 && has('patch-8.1.1')
	set termwinkey=<c-_>
	tnoremap <m-H> <c-_>h
	tnoremap <m-L> <c-_>l
	tnoremap <m-J> <c-_>j
	tnoremap <m-K> <c-_>k
	tnoremap <m-q> <c-\><c-n>
elseif has('nvim')
	tnoremap <m-H> <c-\><c-n><c-w>h
	tnoremap <m-L> <c-\><c-n><c-w>l
	tnoremap <m-J> <c-\><c-n><c-w>j
	tnoremap <m-K> <c-\><c-n><c-w>k
	tnoremap <m-q> <c-\><c-n>
endif

nnoremap <silent><m-=> :call TerminalToggle()<cr>

if has('nvim') == 0
	tnoremap <silent><m-=> <c-_>p:call TerminalToggle()<cr>
else
	tnoremap <silent><m-=> <c-\><c-n>:call TerminalToggle()<cr>
endif


" set twt=conpty


