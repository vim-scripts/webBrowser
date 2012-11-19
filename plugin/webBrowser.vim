"-------------------------------------------------------------------
" WebBrowser
"-------------------------------------------------------------------
" Author: Alexandre Viau
"
" Version: 1.1
"
" Description: Uses the lynx text browser to browse websites and local files
" and return the rendered web pages inside vim. The links in the web pages may
" be "clicked" to follow them, so it turns vim into a simple web text based web browser.
"
" This plugin is based on the browser.vim plugin.
"
" NOTE: In the lynx.cfg file, set the following parameters: 
" ACCEPT_ALL_COOKIES:TRUE
" MAKE_LINKS_FOR_ALL_IMAGES:TRUE

" Tests using the utl plugin
" <url:http://www.cars.com/crp/vp/images/13ford_fusion/Titanium_Action_7.jpg>
" <url:http://www.codeproject.com/Articles/36091/Top-10-steps-to-optimize-data-access-in-SQL-Server> 
" <url:http://www.cheat-sheets.org/>
" <url:http://www.cheat-sheets.org/saved-copy/msnet-formatting-strings.pdf>
" <url:http://www.cars.com>
" <url:http://www.smartisans.com/articles/vb_templates.aspx>
"
" History
"
" Version 1.1
"
" 1. Changed the file format to unix
"
"-------------------------------------------------------------------

com! -nargs=+ WebBrowser call OpenWebBrowser(<q-args>, 1)

nmap <tab>W :WebBrowser 
nmap <tab>S :exe 'WebBrowser www.google.com/search?q="' . input("Google ") . '"'<cr>
nmap <tab>P :exe 'WebBrowser www.wikipedia.com/wiki/"' . input("Wikipedia ") . '"'<cr>

let s:lynxPath = 'c:\lynx\'
let s:lynxExe = s:lynxPath . 'lynx.exe'
let s:lynxCfg = '-cfg=' . s:lynxPath . 'lynx.cfg'
let s:lynxLss = '-lss=' . s:lynxPath . 'lynx.lss'
let s:lynxCmd = s:lynxExe . ' ' . s:lynxCfg . ' ' . s:lynxLss

let s:lynxDumpPath = 'c:\lynx\dump\'
let s:lynxToolsPath = 'c:\lynx\tools\'

" Create path to dump the files (may act as an history path but files of same name are replaced)
if isdirectory(s:lynxDumpPath) == 0
    call mkdir(s:lynxDumpPath)
endif

fun! OpenWebBrowser(address, openInNewTab)
    " Percent-encode some characters because it causes problems in the command line on the windows test computer
    "! 	# 	$ 	& 	' 	( 	) 	* 	+ 	, 	/ 	: 	; 	= 	? 	@ 	[ 	]
    "%21 	%23 	%24 	%26 	%27 	%28 	%29 	%2A 	%2B 	%2C 	%2F 	%3A 	%3B 	%3D 	%3F 	%40 	%5B 	%5D
    let l:address = substitute(a:address, '&', '\\%26', 'g')
    let l:address = substitute(l:address, '#', '\\%23', 'g')
    " Substitute invalid characters
    let l:dumpFile = substitute(l:address, '\', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '/', '-', 'g')
    let l:dumpFile = substitute(l:dumpFile, ':', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '*', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '?', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '"', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '<', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '>', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '|', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '%', '_', 'g')
    let l:dumpFile = substitute(l:dumpFile, '=', '_', 'g')
    " Get extension of the file
    let l:extPos = strridx(a:address, '.')
    let l:extLen = strlen(a:address) - l:extPos
    let l:extName = strpart(a:address, l:extPos, l:extLen)
    " Open the webpage/file and dump it using the lynx -dump feature to the dump directory
    exe 'silent ! ' . s:lynxCmd . ' -dump ' . l:address . ' > "' . s:lynxDumpPath . l:dumpFile . '"'
    if l:extName == '.jpg' || l:extName == '.gif' || l:extName == '.png'
        let l:lynxDumpStr = system(s:lynxCmd . ' -dump ' . l:address)
        call writefile([l:lynxDumpStr], s:lynxDumpPath . l:dumpFile)
    else
        let l:lynxDumpStr = system(s:lynxCmd . ' -dump ' . l:address)
        let l:lynxDumpArr = split(l:lynxDumpStr, '\n')
        call writefile(l:lynxDumpArr, s:lynxDumpPath . l:dumpFile, 'b')
    endif
    " Select view method according to the page/file extension
    let l:vimFile = ''
    if l:extName == '.jpg' || l:extName == '.gif' || l:extName == '.png'
        exe 'silent !start "' . s:lynxToolsPath . 'i_view32.exe" "' . s:lynxDumpPath . l:dumpFile . '"'
    elseif l:extName == '.pdf'
        "exe 'silent !start ' . s:lynxToolsPath . 'foxitreader.exe "' . s:lynxDumpPath . l:dumpFile . '"'
        exe 'silent ! "' . s:lynxToolsPath . 'pdftotext.exe" "' . s:lynxDumpPath . l:dumpFile . '" "' . s:lynxDumpPath . l:dumpFile . '.txt"'
        let l:vimFile = s:lynxDumpPath . l:dumpFile . '.txt'
    else " Any other extension (html, htm or no extension etc.)
        let l:vimFile = s:lynxDumpPath . l:dumpFile
    endif
    " Open a file in the buffer
    if l:vimFile != ''
        if a:openInNewTab == 1
            exe "tabnew"
            exe "set buftype=nofile"
            " Open link
            exe 'nnoremap <buffer> <space>l F[h/^ *<c-r><c-w>. \(http\\|file\)<cr>f l"py$:call OpenWebBrowser("<c-r>p", 0)<cr>'
            " Previous page ("back button")
            exe 'nnoremap <buffer> <space>h :normal u<cr>'
            " Highlight links and go to next link
            exe "nnoremap <buffer> <space>j /\\d*\\]\\w*<cr>"
            " Highlight links and go to previous link
            exe "nnoremap <buffer> <space>k ?\\d*\\]\\w*<cr>"
        else
            " Clear the buffer
            exe "norm ggdG"
        endif
        " Read the file in the buffer
        exe 'silent r ' . l:vimFile
        " Set syntax to have bold links
        syn reset
        syn match Keyword /\[\d*\]\w*/ contains=Ignore
        syn match Ignore /\[\d*\]/ contained 
        exe "norm gg"
        call append(0, [a:address])
    else
        " Return to previous cursor position to return to where the link was executed
        exe "norm! \<c-o>"
    endif 
    " Add address to append register which acts as an history for the current session
    let @H = strftime("%x %X") . ' <url:' . substitute(a:address, '\"', '\\"', 'g') . '>'
endfun
