require "cmd/tap"

module Homebrew
  def tap_unpin
    taps = ARGV.named.map do |name|
      Tap.new(*tap_args(name))
    end
    taps.each do |tap|
      unless tap.installed?
        opoo "#{tap.name} not tapped"
        return
      end
      unless tap.pinned?
        opoo "#{tap.name} already unpinned"
      else
        tap.unpin
        ohai "Unpinned #{tap.name}"
      end
    end
  end
end
