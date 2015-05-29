if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif
if exists("b:did_tmux_copy")
    finish
endif
let b:did_tmux_copy = 1 

python << EOF
import vim
import os
import uuid

def  tmuxCopyQuote(lines):
    result="\""
    for line in lines:
        line=line.replace("\\","\\\\");
        line=line.replace("\"","\\\"");
        result +=line
    result +="\""
    return result
EOF

function! TmuxCopyRange() range
python << EOF
file_name = "tmux_copy_"+uuid.uuid4().hex
start = int(vim.eval("a:firstline"))
end = int(vim.eval("a:lastline"))

f = file(file_name, 'w')
buf = vim.current.buffer
lines=[]
for line in buf.range(start, end):
    f.write(line+"\n")
    lines.append(line+"\n")

f.close()

vim.eval("setreg('\"', {0})".format(tmuxCopyQuote(lines)))
os.system("tmux load-buffer %s"%(file_name))

os.system("rm -f %s"%(file_name))
EOF
endfunction

function! TmuxCopy()
python << EOF
file_name = "tmux_copy_"+uuid.uuid4().hex

f = file(file_name, 'w')
content=vim.eval("@*")
f.write(content)
f.close()

vim.eval("setreg('\"', {0})".format(tmuxCopyQuote(content)))
os.system("tmux load-buffer %s"%(file_name))

os.system("rm -f %s"%(file_name))
EOF
endfunction

function! TmuxPaste()
python << EOF
file_name = "tmux_copy_"+uuid.uuid4().hex
os.system("tmux save-buffer %s"%(file_name))

f = file(file_name, 'r')
lines = f.readlines()
f.close()

vim.eval("setreg('\"', {0})".format(tmuxCopyQuote(lines)))
vim.command("normal p")

os.system("rm -f %s"%(file_name))
EOF
endfunction


command! -nargs=0 -range TmuxCopyRange <line1>,<line2> call TmuxCopyRange()
command! -nargs=0 TmuxCopy  call TmuxCopy()
command! -nargs=0 TmuxPaste  call TmuxPaste()
vmap <silent> zy  :<C-U>TmuxCopy<CR>
nmap <silent> zp  :TmuxPaste<CR>
