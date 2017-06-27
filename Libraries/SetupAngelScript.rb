# Supported extra options:
#
class AngelScript < BaseDep
  def initialize(args)
    super("AngelScript", "angelscript", args)
    @WantedURL = "http://svn.code.sf.net/p/angelscript/code/tags/#{@Version}"

    if @WantedURL[-1, 1] == '/'
      onError "Invalid configuraion in Setup.rb AngelScript tag has an ending '/'. Remove it!"
    end
  end

  def DoClone
    requireCMD "svn"
    system "svn co #{@WantedURL} angelscript"
    $?.exitstatus == 0
  end

  def DoUpdate

    # Check is tag correct
    match = `svn info`.strip.match(/.*URL:\s?(.*angelscript\S+).*/i)

    onError("'svn info' unable to find URL with regex") if !match
    
    currenturl = match.captures[0]

    if currenturl != @WantedURL
      
      info "Switching AngelScript tag from #{currenturl} to #{@WantedURL}"
      
      system "svn switch #{@WantedURL}"
      onError "Failed to switch svn url" if $?.exitstatus > 0
    end
    
    system "svn update"
    $?.exitstatus == 0
  end

  def DoSetup
    if OS.windows?
      # TODO: msvc version
      return File.exist? "sdk/angelscript/projects/msvc2015/angelscript.sln"
    else
      return true
    end
  end
  
  def DoCompile

    if OS.windows?
      
      info "Verifying that angelscript solution has Runtime Library = MultiThreadedDLL"
      verifyVSProjectRuntimeLibrary "sdk/angelscript/projects/msvc2015/angelscript.vcxproj", 
                                    %r{Release\|x64}, "MultiThreadedDLL"  
      
      success "AngelScript solution is correctly configured. Compiling"

      return runVSCompiler(CompileThreads,
                           project: "sdk/angelscript/projects/msvc2015/angelscript.sln",
                           configuration: "Release",
                           platform: "x64")
      
    else
      
      Dir.chdir("sdk/angelscript/projects/gnuc") do

        return runCompiler CompileThreads
      end
    end
  end
  
  def DoInstall

    # Copy files to Project folder
    createDependencyTargetFolder

    # First header files and addons
    FileUtils.cp File.join(@Folder, "sdk/angelscript/include", "angelscript.h"),
                 ProjectDebDirInclude

    addondir = File.join(ProjectDebDirInclude, "add_on")

    FileUtils.mkdir_p addondir

    # All the addons from
    # `ls -m | awk 'BEGIN { RS = ","; ORS = ", "}; NF { print "\""$1"\""};'`
    addonnames = Array[
      "autowrapper", "contextmgr", "datetime", "debugger", "scriptany", "scriptarray",
      "scriptbuilder", "scriptdictionary", "scriptfile", "scriptgrid", "scripthandle",
      "scripthelper", "scriptmath", "scriptstdstring", "serializer", "weakref"
    ]

    addonnames.each do |x|

      FileUtils.copy_entry File.join(@Folder, "sdk/add_on/", x),
                           File.join(addondir, x)
    end

    # Then the library
    if OS.linux?

      FileUtils.cp File.join(@Folder, "sdk/angelscript/lib", "libangelscript.a"),
                   ProjectDebDirLibs
      
    elsif OS.windows?
      FileUtils.cp File.join(@Folder, "sdk/angelscript/lib", "angelscript64.lib"),
                   ProjectDebDirLibs
    else
      onError "Unkown OS"
    end
    true
  end
end
