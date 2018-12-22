# List of libraries that should be included in releases

### LDD found libraries that should be included in full package
# Used to filter ldd results
def isGoodLDDFound(lib)
  case lib
  when /.*vorbis.*/i
    true      
  when /.*opus.*/i
    true
  when /.*pcre.*/i
    true
  when /.*ogg.*/i
    true
  when /.*tinyxml.*/i
    true
  when /.*rtmp.*/i
    true
  when /.*gsm.*/i
    true
  when /.*soxr.*/i
    true
  when /.*x2.*/i
    true
  when /.*libstdc++.*/i
    true
  when /.*jpeg.*/i
    true
  when /.*jxrglue.*/i
    true
  when /.*IlmImf.*/i
    true
  when /.*Imath.*/i
    true
  when /.*Half.*/i
    true
  when /.*Iex.*/i
    true
  when /.*IlmThread.*/i
    true
  when /.*openjp.*/i
    true
  when /.*libraw.*/i
    true
  when /.*png.*/i
    true
  when /.*freeimage.*/i
    true
  when /.*gnutls.*/i
    true
  when /.*atomic.*/i
    true
  when /.*zzip.*/i
    true
  when /.*libz.*/i
    true
  when /.*webp.*/i
    true
  when /.*Xaw.*/i
    true
  when /.*jasper.*/i
    true
  when /.*sdl2.*/i
    true
  when /.*openal.*/i
    true    
    # GCC libraries
  when /.*stdc++.*/i
    true
  when /libm.*/i
    true
  when /.*libgcc.*/i
    true
  # These would be for bundling the system libc, but that doesn't work
  # due to also needing to bundle ld-linux-x86-64.so.2 and modifying
  # to active program loader
  # when /.*libc.*/i
  #   true
  else
    false
  end
end
