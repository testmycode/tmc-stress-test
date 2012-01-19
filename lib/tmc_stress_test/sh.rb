require 'shellwords'

class Sh
  def self.run(*parts)
    cmd = Shellwords.join(parts.flatten.reject(&:nil?).map(&:to_s))
    output = `#{cmd} 2>&1`
    raise "#{cmd} exited with #{$?}. Output:\n#{output}" unless $?.success?
    output
  end
end