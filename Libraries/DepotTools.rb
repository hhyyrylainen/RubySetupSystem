# Helper for downloading and enabling depot tools
class DepotTools < BaseDep

  def initialize(args)
    super("Google Depot Tools", "depot_tools", args)

    if !@InstallPath
      @InstallPath = @Folder
    end

    @Folder = @InstallPath

    if !@RepoURL
      @RepoURL = "https://chromium.googlesource.com/chromium/tools/depot_tools.git"
    end

    @UpdateDone = false
  end

  def DoClone
    runSystemSafe("git", "clone", @RepoURL) == 0
  end

  def DoUpdate
    self.standardGitUpdate
  end

  # Makes the tools usable with the block given to this method
  def activate

    if !@UpdateDone

      # Make sure everything is fine first
      if !SkipPullUpdates || self.RequiresClone

        self.Retrieve

      else

        if self.IsUsingSpecificCommit
          self.MakeSureRightCommitIsCheckedOut
        end

      end
    end

    # Run with it added to path
    runWithModifiedPath(@Folder, OS.windows?){

      # Windows gclient run
      if OS.windows? && !@UpdateDone = true
        if runSystemSafe("cmd", %{"glclient"}) != 0
          raise "Failed to do initial gclient run"
        end
      end

      # Run the commands
      yield
    }

    @UpdateDone = true
  end

end
