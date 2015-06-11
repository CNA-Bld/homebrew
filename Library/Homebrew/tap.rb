require 'utils/json'

class Tap
  TAP_DIRECTORY = HOMEBREW_LIBRARY/"Taps"

  extend Enumerable

  attr_reader :user
  attr_reader :repo
  attr_reader :name
  attr_reader :path
  attr_reader :remote

  def initialize(user, repo, remote=nil)
    # we special case homebrew so users don't have to shift in a terminal
    @user = user == "homebrew" ? "Homebrew" : user
    @repo = repo
    @name = "#{@user}/#{@repo}".downcase
    @path = TAP_DIRECTORY/"#{@user}/homebrew-#{@repo}".downcase
    @json_path = TAP_DIRECTORY/"#{@user}/#{@repo}.json".downcase
    if installed?
      @path.cd do
        @remote = Utils.popen_read("git", "config", "--get", "remote.origin.url").chomp
      end
    else
      @remote = remote || "https://github.com/#{@user}/homebrew-#{@repo}"
    end
  end

  def to_s
    name
  end

  def official?
    @user == "Homebrew"
  end

  def private?
    return true if custom_remote?
    GitHub.private_repo?(@user, "homebrew-#{@repo}")
  rescue GitHub::HTTPNotFoundError
    true
  rescue GitHub::Error
    false
  end

  def installed?
    @path.directory?
  end

  def custom_remote?
    @remote.casecmp("https://github.com/#{@user}/homebrew-#{@repo}") != 0
  end

  def formula_files
    dir = [@path/"Formula", @path/"HomebrewFormula", @path].detect(&:directory?)
    return [] unless dir
    dir.children.select { |p| p.extname == ".rb" }
  end

  def formula_names
    formula_files.map { |f| "#{name}/#{f.basename(".rb")}" }
  end

  def command_files
    Pathname.glob("#{path}/cmd/brew-*").select(&:executable?)
  end

  def get_priority
    @json_path.exist?? Utils::JSON.load(File.read(@json_path))["priority"] : 99
  end

  def set_priority priority
    attributes = {
        "priority" => priority
    }
    @json_path.atomic_write(Utils::JSON.dump(attributes))
    if priority == 50
      opoo "Core formulae has a priority of 50, we don't recommand do this!"
    end
    Tap.each do |other_tap|
      if !(other_tap.name.eql? self.name) && other_tap.get_priority == priority
        opoo "Same priority: #{other_tap.name}"
      end
    end
  end

  def to_hash
    {
      "name" => @name,
      "user" => @user,
      "repo" => @repo,
      "path" => @path.to_s,
      "remote" => @remote,
      "priority" => get_priority,
      "installed" => installed?,
      "official" => official?,
      "custom_remote" => custom_remote?,
      "formula_names" => formula_names,
      "formula_files" => formula_files.map(&:to_s),
      "command_files" => command_files.map(&:to_s),
    }
  end

  def self.each
    return unless TAP_DIRECTORY.directory?

    TAP_DIRECTORY.subdirs.each do |user|
      user.subdirs.each do |repo|
        if (repo/".git").directory?
          yield new(user.basename.to_s, repo.basename.to_s.sub("homebrew-", ""))
        end
      end
    end
  end

  def self.names
    map(&:name)
  end
end
