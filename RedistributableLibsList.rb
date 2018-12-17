# List of libraries that should be included in releases

### LDD found libraries that should be included in full package
# Used to filter ldd results
def isGoodLDDFound(lib)

  case lib
  # FFMPEG is now bundled so there should not be needed
  # when /.*swresample.*/i
  #   true
  # when /.*avcodec.*/i
  #   true
  # when /.*avformat.*/i
  #   true
  # when /.*avutil.*/i
  #   true
  # when /.*swscale.*/i
  #   true    
  # when /.*ilbc.*/i
  #   true
  # when /.*theora.*/i
  #   true
  # when /.*vpx.*/i
  #   true    
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
  # when /.*Cg.*/i
  #   true
  # when /.*va.*/i
  #   true
  # when /.*xvid.*/i
  #   true
  # when /.*zvbi.*/i
  #   true
  # when /.*amr.*/i
  #   true
  # when /.*mfx.*/i
  #   true
  # when /.*aac.*/i
  #   true
  # # nvidia stuff for ffmpeg
  # when /.*nvcu.*/i
  #   true
  # when /.*cuda.*/i
  #   true
  # when /.*nvidia-fatbinary.*/i
  #   true
  # when /.*vdpau.*/i
  #   true
  # when /.*twolame.*/i
  #   true
  # when /.*h26.*/i
  #   true
  # when /.*mp3.*/i
  #   true
  # when /.*bluray.*/i
  #   true
  # when /.*OpenCL.*/i
  #   true
  when /.*webp.*/i
    true
  # when /.*schroedinger.*/i
  #   true
  # when /.*Xaw.*/i
  #   true
  # when /.*numa.*/i
  #   true
  # when /.*hogweed.*/i
  #   true
  when /.*jasper.*/i
    true
  when /.*sdl2.*/i
    true    
  else
    false
  end
end
