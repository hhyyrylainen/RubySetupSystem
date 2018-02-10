# Supported extra options:
#
class AngelScript < StandardCMakeDep
  def initialize(args)
    super("AngelScript", "angelscript", args)
    @WantedURL = "http://svn.code.sf.net/p/angelscript/code/tags/#{@Version}"

    if @WantedURL[-1, 1] == '/'
      onError "Invalid configuraion in Setup.rb AngelScript tag has an ending '/'. Remove it!"
    end

    @CMakeListFolder = "../sdk/angelscript/projects/cmake/"
  end

  def DoClone
    runOpen3("svn", "co", @WantedURL, "angelscript") == 0
  end

  def DoUpdate

    # Check is tag correct
    match = `svn info`.strip.match(/.*URL:\s?(.*angelscript\S+).*/i)

    onError("'svn info' unable to find URL with regex") if !match
    
    currenturl = match.captures[0]

    if currenturl != @WantedURL
      
      info "Switching AngelScript tag from #{currenturl} to #{@WantedURL}"
      
      if runOpen3("svn", "switch", @WantedURL) != 0
        onError "Failed to switch svn url"
      end
    end
    
    runOpen3("svn", "update") == 0
  end
  
  def DoCompile

    if TC.is_a? WindowsMSVC
      
      # info "Verifying that angelscript solution has Runtime Library = MultiThreadedDLL"
      # verifyVSProjectRuntimeLibrary "sdk/angelscript/projects/msvc2015/angelscript.vcxproj",
      #                               "sdk/angelscript/projects/msvc2015/angelscript.sln", 
      #                               %r{Release\|x64}, "MultiThreadedDLL"  
      
      # success "AngelScript solution is correctly configured. Compiling"

      return runVSCompiler($compileThreads,
                           project: "build/angelscript.sln",
                           configuration: "Release",
                           platform: "x64",
                           runtimelibrary: "MD")
      
    else
      
      Dir.chdir("build") do

        return TC.runCompiler
      end
    end
  end
  
  def DoInstall

    # Copy files to the install target folder
    installer = CustomInstaller.new(@InstallPath,
                                    File.join(@Folder, "sdk/angelscript/include"))

    
    # First header files and libs
    installer.addInclude(File.join(@Folder, "sdk/angelscript/include", "angelscript.h"))

    
    # The library
    if OS.linux?

      installer.addLibrary File.join(@Folder, "build/Release", "libangelscript.a")
      
    elsif OS.windows?
      # todo bitness
      installer.addLibrary File.join(@Folder, "build/Release", "angelscript.lib")
    else
      onError "Unkown OS"
    end
    
    installer.run

    # Then the addons
    installer = CustomInstaller.new(@InstallPath,
                                    File.join(@Folder, "sdk/add_on/"))

    installer.IncludeFolder = "include/add_on"

    # All the addons from
    # `ls -m | awk 'BEGIN { RS = ","; ORS = ", "}; NF { print "\""$1"\""};'`
    addonnames = Array[
      "autowrapper", "contextmgr", "datetime", "debugger", "scriptany", "scriptarray",
      "scriptbuilder", "scriptdictionary", "scriptfile", "scriptgrid", "scripthandle",
      "scripthelper", "scriptmath", "scriptstdstring", "serializer", "weakref"
    ]

    addonnames.each do |x|

      installer.addInclude File.join(@Folder, "sdk/add_on/", x)
    end

    installer.run

    true
  end
end
