require 'fileutils'
require 'tmc_stress_test/sh'

class GitRepo
  def initialize(path)
    @path = Pathname(path)
  end
  
  attr_reader :path
  
  def self.init(path)
    FileUtils.mkdir_p(path)
    Dir.chdir(path) do
      Sh.run('git', 'init')
    end
    GitRepo.new(path)
  end
  
  def add_remote(name, url)
    chdir { Sh.run('git', 'remote', 'add', name, url) }
  end
  
  def pull(remote = nil, branch = nil)
    chdir { Sh.run('git', 'pull', remote, branch) }
  end
  
  def add_commit_push
    add
    commit
    push
  end
  
  def add(paths = '.')
    chdir { Sh.run('git', 'add', paths) }
  end
  
  def commit(msg = '...')
    chdir { Sh.run('git', 'commit', '-m', msg) }
  end
  
  def push(remote = 'origin', branch = 'master')
    chdir { Sh.run('git', 'push', remote, branch) }
  end
  
  def force_push(remote = 'origin', branch = 'master')
    chdir { Sh.run('git', 'push', '--force', remote, branch) }
  end
  
  def chdir(&block)
    Dir.chdir(path, &block)
  end
end
