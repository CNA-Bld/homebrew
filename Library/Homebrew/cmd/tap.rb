require "tap"

module Homebrew
  def tap
    if ARGV.empty?
      puts Tap.names
    elsif ARGV.first == "--repair"
      migrate_taps :force => true
    else
      user, repo = tap_args
      clone_target = ARGV.named[1]
      opoo "Already tapped!" unless install_tap(user, repo, clone_target)
    end
  end

  def install_tap user, repo, clone_target=nil
    tap = Tap.new user, repo, clone_target

    if tap.installed?
      ohai "#{user}/#{repo} Already Tapped. Changing Prioirity."
      priority = ARGV.value("priority")
      if priority.nil?
        opoo "Priority not specified, terminating."
      else
        priority = priority.to_i
        if priority < 0 or priority > 99
          opoo "Priority not allowed, terminating."
        else
          tap.set_priority priority
        end
      end
      true
    else
      ohai "Tapping #{tap}"
      args = %W[clone #{tap.remote} #{tap.path}]
      args << "--depth=1" unless ARGV.include?("--full")
      safe_system "git", *args

      formula_count = tap.formula_files.size
      puts "Tapped #{formula_count} formula#{plural(formula_count, 'e')} (#{tap.path.abv})"

      priority = ARGV.value("priority")
      if priority.nil?
        opoo "Priority not specified, default to 99."
        priority = 99
      else
        priority = priority.to_i
        if priority < 0 or priority > 99
          opoo "Priority not allowed, default to 99."
          priority = 99
        end
      end

      tap.set_priority priority

      if !clone_target && tap.private?
        puts <<-EOS.undent
        It looks like you tapped a private repository. To avoid entering your
        credentials each time you update, you can use git HTTP credential
        caching or issue the following command:

          cd #{tap.path}
          git remote set-url origin git@github.com:#{tap.user}/homebrew-#{tap.repo}.git
        EOS
      end
      true
    end
  end

  def check_same_priority(user, repo, priority)
    other_sources = []
    other_sources << HOMEBREW_LIBRARY.join("Formula/") if priority == 50
    other_sources += Pathname.glob(HOMEBREW_LIBRARY.to_s + "/LinkedTaps/#{priority}.*")
    if other_sources.length > 0
      opoo "Taps with same priority detected: " + other_sources.to_s
    end
  end

  # Migrate tapped formulae from symlink-based to directory-based structure.
  def migrate_taps(options={})
    ignore = HOMEBREW_LIBRARY/"Formula/.gitignore"
    return unless ignore.exist? || options.fetch(:force, false)
    (HOMEBREW_LIBRARY/"Formula").children.select(&:symlink?).each(&:unlink)
    ignore.unlink if ignore.exist?
  end

  private

  def tap_args(tap_name=ARGV.named.first)
    tap_name =~ HOMEBREW_TAP_ARGS_REGEX
    raise "Invalid tap name" unless $1 && $3
    [$1, $3]
  end
end
