# Work in progress module for luajit

abort("unfinished")

# Make sure XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT is uncommented
outdata = File.read("Makefile").gsub(/#XCFLAGS\+= -DLUAJIT_ENABLE_LUA52COMPAT/,
                                     "XCFLAGS+= -DLUAJIT_ENABLE_LUA52COMPAT")

File.open("Makefile", 'w') do |out|
  out << outdata
end  

runCompiler $compileThreads

onError "Failed to compile luajit" if $?.exitstatus > 0
