require 'cmd/tap' # for tap_args

module Homebrew
  def untap
    raise "Usage is `brew untap <tap-name>`" if ARGV.empty?

    ARGV.named.each do |tapname|
      tap = Tap.new(*tap_args(tapname))

      raise "No such tap!" unless tap.installed?
      puts "Untapping #{tap}... (#{tap.path.abv})"

      formula_count = tap.formula_files.size
      tap.path.rmtree
      tap.path.dirname.rmdir_if_possible

      t = HOMEBREW_LIBRARY.to_s + "/LinkedTaps/??.#{user}.#{repo}"
      linked_tapd = Pathname.glob(t)[0]
      linked_tapd.delete unless linked_tapd.nil?

      puts "Untapped #{formula_count} formula#{plural(formula_count, 'e')}"
    end
  end
end
