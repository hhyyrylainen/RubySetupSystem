# Supported extra options:
# disableExamples
# disableDemos
# disableUnity
# disableTests
# # shared If true builds shared libs of everything, false for static
class DiligentEngine < StandardCMakeDep
  def initialize(args)
    super('DiligentEngine', 'diligent', args)

    self.HandleStandardCMakeOptions

    # Doesn't seem to actually work
    # @Options.push "-DBUILD_SHARED_LIBS=#{args[:shared]}" if args.include? [:shared]

    @Options.push '-DDILIGENT_BUILD_SAMPLES=OFF' if args[:disableExamples]
    @Options.push '-DDILIGENT_BUILD_TESTS=OFF' if args[:disableTests]
    @Options.push '-DDILIGENT_BUILD_DEMOS=OFF' if args[:disableDemos]
    @Options.push '-DDILIGENT_BUILD_UNITY_PLUGIN=OFF' if args[:disableUnity]

    @RepoURL ||= 'https://github.com/DiligentGraphics/DiligentEngine.git'
  end

  def depsList
    os = getLinuxOS

    if fedora_compatible_oses.include? os
      return ['vulkan-headers', 'vulkan-loader', 'vulkan-loader-devel', 'vulkan-tools',
              'vulkan-validation-layers', 'libX11-devel', 'mesa-libGLU-devel',
              'mesa-libGL-devel', 'python3']
    end

    if ubuntu_compatible_oses.include? os
      return ['build-essential', 'libvulkan-dev', 'vulkan-tools', 'vulkan-validationlayers',
              'libx11-dev', 'mesa-common-dev', 'mesa-utils', 'libgl-dev', 'python3-distutils']
    end

    onError "#{@name} unknown packages for os: #{os}"
  end

  def installPrerequisites
    installDepsList depsList
  end

  def DoClone
    runSystemSafe('git', 'clone', @RepoURL, 'diligent', '--recursive') == 0
  end

  def DoUpdate
    standardGitUpdate
  end

  def DoSetup
    return false if runSystemSafe('git', 'submodule', 'update', '--init', '--recursive') != 0

    super
  end

  def getInstalledFiles
    if OS.windows?
      nil
    elsif OS.linux?
      [
        'lib64/DiligentCore/RelWithDebInfo/',

        'lib64/DiligentCore/RelWithDebInfo/libDiligentCore.a',
        'lib64/DiligentCore/RelWithDebInfo/libGraphicsEngineOpenGL.so',
        'lib64/DiligentCore/RelWithDebInfo/libGraphicsEngineVk.so',
        'lib64/DiligentCore/RelWithDebInfo/libHLSL.a',
        'lib64/DiligentCore/RelWithDebInfo/libOGLCompiler.a',
        'lib64/DiligentCore/RelWithDebInfo/libOSDependent.a',
        'lib64/DiligentCore/RelWithDebInfo/libSPIRV-Tools-opt.a',
        'lib64/DiligentCore/RelWithDebInfo/libSPIRV-Tools.a',
        'lib64/DiligentCore/RelWithDebInfo/libSPIRV.a',
        'lib64/DiligentCore/RelWithDebInfo/libglew-static.a',
        'lib64/DiligentCore/RelWithDebInfo/libglslang.a',
        'lib64/DiligentCore/RelWithDebInfo/libspirv-cross-core.a',
        'lib64/DiligentFX/RelWithDebInfo/libDiligentFX.a',
        'lib64/DiligentTools/RelWithDebInfo/libDiligentTools.a',
        'lib64/DiligentTools/RelWithDebInfo/libLibJpeg.a',
        'lib64/DiligentTools/RelWithDebInfo/libLibPng.a',
        'lib64/DiligentTools/RelWithDebInfo/libLibTiff.a',
        'lib64/DiligentTools/RelWithDebInfo/libZLib.a',

        'include/DiligentCore',
        'include/DiligentTools',
        'include/DiligentFX',

        'Shaders',

        'Licenses/DiligentEngine-License.txt',
        'Licenses/ThirdParty/DiligentCore',
        'Licenses/ThirdParty/DiligentTools'
      ]
    end
  end
end
