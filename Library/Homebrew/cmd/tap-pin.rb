require "cmd/tap"

module Homebrew
  def tap_pin
    taps = ARGV.named.map do |name|
      Tap.new(*tap_args(name))
    end
    taps.each do |tap|
      unless tap.installed?
        opoo "#{tap.name} not tapped"
        return
      end
      if tap.pinned?
        opoo "#{tap.name} already pinned"
      else
        tap.pin
        ohai "Pinned #{tap.name}"
      end
    end
  end
end
