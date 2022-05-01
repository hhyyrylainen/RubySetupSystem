# Helper for downloading and enabling depot tools
class DepotTools < BaseDep
  def initialize(args)
    super('Google Depot Tools', 'depot_tools', args)

    @InstallPath ||= @Folder

    @Folder = @InstallPath

    @RepoURL ||= 'https://chromium.googlesource.com/chromium/tools/depot_tools.git'

    @Version = 'main' if @Version == 'master'

    @UpdateDone = false
  end

  def DoClone
    runSystemSafe('git', 'clone', @RepoURL) == 0
  end

  def DoUpdate
    standardGitUpdate
  end

  # Makes the tools usable with the block given to this method
  def activate
    unless @UpdateDone

      # Make sure everything is fine first
      if !SkipPullUpdates || self.RequiresClone

        self.Retrieve

      elsif self.IsUsingSpecificCommit

        self.MakeSureRightCommitIsCheckedOut

      end
    end

    # Run with it added to path
    runWithModifiedPath(@Folder, OS.windows?) do
      # Windows gclient run
      if OS.windows? && @UpdateDone != true
        puts 'Doing initial gclient run.'
        if runSystemSafe(File.realpath(File.join(@Folder, 'gclient.bat'))) != 0
          raise 'Failed to do initial gclient run'
        end
      end

      # Run the commands
      yield
    end

    @UpdateDone = true
  end
end
