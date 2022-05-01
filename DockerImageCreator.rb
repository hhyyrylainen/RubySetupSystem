# Common helpers for docker image creation for building projects that
# use RubySetupSystem
require 'optparse'

require_relative 'RubyCommon'

def checkRunFolder(suggested)
  buildFolder = File.join(suggested, 'build')

  onError('Not ran from base folder (no build directory exists)') unless
    File.exist?(buildFolder)

  target = File.join suggested, 'build', 'docker'

  FileUtils.mkdir_p target

  target
end

def projectFolder(baseDir)
  File.expand_path File.join(baseDir, '../../')
end

def getExtraOptions(opts)
  opts.on('--build-docker', 'If specified builds a docker file automatically otherwise ' \
         'only a Dockerfile is created') do |_b|
    $options[:dockerbuild] = true
  end
end

def extraHelp
  puts $extraParser
end

require_relative 'RubySetupSystem'

# Read extraOptions
$doBuild = $options.include?(:dockerbuild) ? $options[:dockerbuild] : false

# Overwrite the the operating system to work well with the fedora
# images
def getLinuxOS
  'fedora'
end

def doDockerBuild(folder)
  if runSystemSafe('docker', 'build', folder) != 0

    warning 'Failed to run docker as normal user, trying sudo'

    runOpen3Checked('sudo', 'docker', 'build', folder)

  end
end

def writeCommonDockerFile(file, packageNames, extraSteps)
  file.puts('FROM fedora:35')
  file.puts('RUN dnf install -y --setopt=deltarpm=false ruby ruby-devel ' +
            packageNames.join(' ') + ' gcc make redhat-rpm-config fedora-repos-rawhide ' \
                                     'clang cmake && dnf clean all')
  file.puts('RUN git lfs install') if packageNames.include? 'git-lfs'
  file.puts('RUN gem install os colorize rubyzip json sha3')

  # vnc setup part
  # This doesn't seem to actually help with a missing x server
  # file.puts("RUN dnf install -y x11vnc")
  # file.puts("RUN mkdir /root/.vnc")
  # file.puts(%q(RUN x11vnc -storepasswd "vncdocker" ~/.vnc/passwd))

  # Rawhide overrides
  # glm is no longer used
  # file.puts("RUN dnf install -y --disablerepo=* --enablerepo=rawhide " +
  #           "--setopt=deltarpm=false glm-devel")

  # Disable SVN password saving
  file.puts('RUN mkdir /root/.subversion')
  file.puts("RUN echo $'[global]\\n\\
store-plaintext-passwords = no\\n' > /root/.subversion/servers")

  if extraSteps
    extraSteps.each do |step|
      file.puts step
    end
  end
end

# Main run method
def runDockerCreate(libsList, mainProjectAsDep = nil, extraPackages: [], extraSteps: [])
  libsList.push mainProjectAsDep if mainProjectAsDep

  packageNames = []

  libsList.each do |lib|
    unless lib.respond_to?(:installPrerequisites)

      puts "Skipping #{lib.Name} which doesn't specify packages to install"
      next
    end

    packageNames.push(*lib.depsList)
  end

  # We need lsb_release
  packageNames.push 'redhat-lsb-core'

  # Might as well install all the svc tools
  packageNames.push 'git', 'svn', 'mercurial'

  # And 7z
  packageNames.push 'p7zip'

  # And make sure tar with lzma support is there
  packageNames.push 'tar'
  # On ubuntu this is called xz-utils
  packageNames.push 'xz'

  # Optional
  packageNames.concat extraPackages

  packageNames.uniq!

  puts ''
  success 'Successfully ran package collection'
  info "Detected packages: #{packageNames}"

  info "Package count: #{packageNames.count}"

  FileUtils.mkdir_p File.join(CurrentDir, 'simple')
  FileUtils.mkdir_p File.join(CurrentDir, 'jenkins')

  dockerFile = File.join CurrentDir, 'simple', 'Dockerfile'

  puts "Writing docker file at '#{dockerFile}'"

  File.open(dockerFile, 'w') do |file|
    writeCommonDockerFile file, packageNames, extraSteps
  end

  jenkinsDocker = File.join CurrentDir, 'jenkins', 'Dockerfile'
  jenkinsSetupSSHD = File.join CurrentDir, 'jenkins', 'setup-sshd'

  puts "Writing docker (jenkins) file at '#{jenkinsDocker}'"

  File.open(jenkinsDocker, 'w') do |file|
    writeCommonDockerFile file, packageNames, extraSteps

    # Needed things for jenkins.
    # From here: https://wiki.jenkins.io/display/JENKINS/Docker+Plugin
    file.puts('RUN dnf install -y --setopt=deltarpm=false openssh-server ' \
              'java-1.8.0-openjdk && dnf clean all')
    # This probably messes up everything as this probably runs before the keys are fine
    # file.puts("RUN systemctl enable sshd")
    # And stuff from: https://hub.docker.com/r/jenkins/ssh-slave/~/dockerfile/
    # The MIT License
    #
    #  Copyright (c) 2015, CloudBees, Inc.
    #
    #  Permission is hereby granted, free of charge, to any person obtaining a copy
    #  of this software and associated documentation files (the "Software"), to deal
    #  in the Software without restriction, including without limitation the rights
    #  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    #  copies of the Software, and to permit persons to whom the Software is
    #  furnished to do so, subject to the following conditions:
    #
    #  The above copyright notice and this permission notice shall be included in
    #  all copies or substantial portions of the Software.
    #
    #  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    #  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    #  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    #  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    #  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    #  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    #  THE SOFTWARE.
    file.puts <<~END
      ARG user=jenkins
      ARG group=jenkins
      ARG uid=1000
      ARG gid=1000
      ARG JENKINS_AGENT_HOME=/home/${user}

      ENV JENKINS_AGENT_HOME ${JENKINS_AGENT_HOME}

      RUN groupadd -g ${gid} ${group} \
          && useradd -d "${JENKINS_AGENT_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}"

      # setup SSH server
      RUN sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
      RUN sed -i 's/#RSAAuthentication.*/RSAAuthentication yes/' /etc/ssh/sshd_config
      RUN sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
      RUN sed -i 's/#SyslogFacility.*/SyslogFacility AUTH/' /etc/ssh/sshd_config
      RUN sed -i 's/#LogLevel.*/LogLevel INFO/' /etc/ssh/sshd_config
      RUN mkdir /var/run/sshd

      VOLUME "${JENKINS_AGENT_HOME}" "/tmp" "/run" "/var/run"
      WORKDIR "${JENKINS_AGENT_HOME}"

      COPY setup-sshd /usr/bin/setup-sshd

      EXPOSE 22

      ENTRYPOINT ["setup-sshd"]

    END

    File.write(jenkinsSetupSSHD, <<~END
      #!/bin/bash

      set -ex

      # The MIT License
      #
      #  Copyright (c) 2015, CloudBees, Inc.
      #
      #  Permission is hereby granted, free of charge, to any person obtaining a copy
      #  of this software and associated documentation files (the "Software"), to deal
      #  in the Software without restriction, including without limitation the rights
      #  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
      #  copies of the Software, and to permit persons to whom the Software is
      #  furnished to do so, subject to the following conditions:
      #
      #  The above copyright notice and this permission notice shall be included in
      #  all copies or substantial portions of the Software.
      #
      #  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
      #  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
      #  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
      #  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      #  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
      #  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
      #  THE SOFTWARE.

      # Usage:
      #  docker run jenkinsci/ssh-slave <public key>
      # or
      #  docker run -e "JENKINS_SLAVE_SSH_PUBKEY=<public key>" jenkinsci/ssh-slave

      # key first
      echo "Leviathan jenkins dep container ssh setup."
      ssh-keygen -A

      write_key() {
      	mkdir -p "${JENKINS_AGENT_HOME}/.ssh"
      	echo "$1" > "${JENKINS_AGENT_HOME}/.ssh/authorized_keys"
      	chown -Rf jenkins:jenkins "${JENKINS_AGENT_HOME}/.ssh"
      	chmod 0700 -R "${JENKINS_AGENT_HOME}/.ssh"
      }

      if [[ $JENKINS_SLAVE_SSH_PUBKEY == ssh-* ]]; then
        write_key "${JENKINS_SLAVE_SSH_PUBKEY}"
      fi
      if [[ $# -gt 0 ]]; then
        if [[ $1 == ssh-* ]]; then
          write_key "$1"
          shift 1
        else
          exec "$@"
        fi
      fi


      # ensure variables passed to docker container are also exposed to ssh sessions
      env | grep _ >> /etc/environment

      exec /usr/sbin/sshd -D -e "${@}"
    END
    )

    FileUtils.chmod '+x', jenkinsSetupSSHD
  end

  unless $doBuild

    success "Skipping building. Run 'docker build' manually. All done."
    exit 0
  end

  success 'Done writing docker file. Building the image(s)...'

  doDockerBuild File.join(CurrentDir, 'simple')
  doDockerBuild File.join(CurrentDir, 'jenkins')

  success 'Done. See above output for the created image details'
end
