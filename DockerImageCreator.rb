# Common helpers for docker image creation for building projects that
# use RubySetupSystem
require 'optparse'

require_relative 'RubyCommon.rb'

def checkRunFolder(suggested)

  buildFolder = File.join(suggested, "build")

  onError("Not ran from base folder (no build directory exists)") if
    not File.exist?(buildFolder)

  target = File.join suggested, "build", "docker"

  FileUtils.mkdir_p target

  target
  
end

def projectFolder(baseDir)

  File.expand_path File.join(baseDir, "../../")
  
end

def getExtraOptions(opts)

  opts.on("--build-docker", "If specified builds a docker file automatically otherwise " +
         "only a Dockerfile is created") do |b|
    $options[:dockerbuild] = true
  end 
  
end

def extraHelp
  puts $extraParser
end

require_relative 'RubySetupSystem.rb'

# Read extraOptions
$doBuild = if $options.include?(:dockerbuild) then $options[:dockerbuild] else false end

# Overwrite the the operating system to work well with the fedora
# images
def getLinuxOS
  "fedora"
end

# Main run method
def runDockerCreate(libsList, mainProjectAsDep = nil)

  if mainProjectAsDep
    libsList.push mainProjectAsDep
  end

  packageNames = []

  libsList.each{|lib|

    if not lib.respond_to?(:installPrerequisites)

      puts "Skipping #{lib.Name} which doesn't specify packages to install"
      next
    end

    packageNames.push(*lib.depsList)
  }

  # We need lsb_release
  packageNames.push "redhat-lsb-core"

  # Might as well install all the svc tools
  packageNames.push "git", "svn", "mercurial"

  packageNames.uniq!
  
  puts ""
  success "Successfully ran package collection"
  info "Detected packages: #{packageNames}"

  info "Package count: #{packageNames.count}"

  dockerFile = File.join CurrentDir, "Dockerfile"
  
  puts "Writing docker file at '#{dockerFile}'"

  File.open(dockerFile, 'w'){|file|
    
    file.puts("FROM fedora:latest")
    file.puts("RUN dnf install -y --setopt=deltarpm=false ruby ruby-devel")
    file.puts("RUN gem install os colorize rubyzip")    
    file.puts("RUN dnf install -y --setopt=deltarpm=false #{packageNames.join ' '}; exit 0")
    file.puts("RUN dnf install -y --setopt=deltarpm=false #{packageNames.join ' '}")

    # vnc setup part
    # This doesn't seem to actually help with a missing x server
    # file.puts("RUN dnf install -y x11vnc")
    # file.puts("RUN mkdir /root/.vnc")
    # file.puts(%q(RUN x11vnc -storepasswd "vncdocker" ~/.vnc/passwd))
  }

  if !$doBuild

    success "Skipping building. Run 'docker build' manually. All done."
    exit 0
  end  

  success "Done writing docker file. Building the image..."

  if runOpen3("docker", "build", CurrentDir) != 0

    warning "Failed to run docker as normal user, trying sudo"
    
    runOpen3Checked("sudo", "docker", "build", CurrentDir)
    
  end
  
  success "Done. See above output for the created image details"
end






