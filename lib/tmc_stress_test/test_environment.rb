
require 'tmc_stress_test/test_config'
require 'tmc_stress_test/tmc_server'
require 'tmc_stress_test/git_repo'
require 'tmc_stress_test/sh'
require 'tmc_stress_test/paths'
require 'tmc_stress_test/tasks'
require 'fileutils'
require 'thread'

class TestEnvironment
  def initialize(config, server, output)
    @config = config
    @server = server
    @output = output
    @mutex = Mutex.new
    
    @user_accounts = []
    @next_user_account_number = 1
    
    check_prerequisites
  end
  
  def init
    FileUtils.rm_rf(work_dir)
    FileUtils.mkdir(work_dir)
    Dir.chdir(work_dir) do
      initialize_repo
      add_exercise_to_repo
      delete_course_if_exists
      delete_user_accounts
      create_course
      refresh_course
      create_submission_zip
      @start_time = Time.now
    end
  end
  
  def clean_up
    delete_course_if_exists
    delete_user_accounts
  end
  
  attr_reader :config
  attr_reader :server
  attr_reader :output
  attr_reader :mutex
  
  include Paths
  
  attr_reader :course_id
  attr_reader :exercise_id
  
  attr_reader :start_time
  
  attr_reader :user_accounts
  attr_accessor :next_user_account_number
  
  def random_user_name # thread-safe
    @mutex.synchronize do
      user_accounts[rand(0...user_accounts.size)]
    end
  end
  
  def course_name
    'stress_test_course'
  end
  
  def exercise_name
    'stress_exercise'
  end
  
  def tasks
    Tasks.new(self)
  end
  
  def log(msg)
    $stderr.puts msg
  end
  
private
  def check_prerequisites
    required_commands = ['git', 'zip', 'unzip']
    required_commands.each {|cmd| raise "Program missing: #{cmd}" if `which #{cmd}`.empty? }
  end
  
  def initialize_repo
    log "Initializing git repo from template..."
    @repo = GitRepo.init(repo_dir)
    @repo.add_remote('template', @config['template_repo_url'])
    @repo.add_remote('origin', @config['repo_url_for_push'])
    @repo.pull('template', 'master')
    @repo.force_push('origin', 'master')
  end
  
  def add_exercise_to_repo
    log "Adding exercise to repo..."
    @repo.chdir do
      Sh.run('scripts/create-project', exercise_name)
      File.open("#{exercise_name}/test/OneSecondTest.java", 'wb') do |f|
        f.puts "import org.junit.Test;"
        f.puts "import fi.helsinki.cs.tmc.edutestutils.Points;"
        f.puts "public class OneSecondTest {"
        f.puts "    @Test"
        f.puts "    @Points(\"stress\")"
        f.puts "    public void sleep1sec() throws Exception { Thread.sleep(1000); }"
        f.puts "}"
      end
    end
    @repo.add_commit_push
  end
  
  def delete_course_if_exists
    course_id = find_course_id
    if course_id
      log "Deleting old course instance from server..."
      @server.post("/courses/#{course_id}", {
        '_method' => 'delete'
      })
    end
  end
  
  def create_course
    log "Creating new course instance on server..."
    resp = @server.post('/courses', {
      'course[name]' => course_name,
      'course[source_backend]' => 'git',
      'course[source_url]' => @config['repo_url_for_tmc'],
      'course[git_branch]' => 'master'
    })
    raise "Course creation failed: #{resp.inspect}" if resp.code >= 400
    
    @course_id = find_course_id
    raise "Failed to find course after creating it" if !@course_id
  end
  
  def refresh_course
    log "Refreshing course..."
    @server.post("/courses/#{@course_id}/refresh")
    
    @exercise_id = find_exercise_id
    raise "Failed to find exercise after refreshing course" if !@exercise_id
  end
  
  def find_course_id
    courses = @server.get_courses
    for course in courses
      return course['id'] if course['name'] == course_name
    end
    nil
  end
  
  def find_exercise_id
    courses = @server.get_courses
    for course in courses
      if course['name'] == course_name
        for exercise in course['exercises']
          if exercise['name'] == exercise_name
            return exercise['id']
          end
        end
      end
    end
    nil
  end
  
  def delete_user_accounts
    log "Deleting stress test user accounts..."
    users = MultiJson.decode(@server.get('/participants.json'))['participants']
    for user in users
      if user['username'].include?('_stress_tester_')
        @server.post("/participants/#{user['id']}", :_method => 'delete')
      end
    end
  end
  
  def create_submission_zip
    FileUtils.cp_r(@repo.path + 'stress_exercise', local_exercise_dir)
      File.open("#{local_exercise_dir}/src/Main.java", 'wb') do |f|
        f.puts "public class Main {"
        f.puts "    public static void main(String[] args) {}"
        f.puts "}"
      end
    Sh.run('zip', '-r', submission_zip_path, local_exercise_dir)
  end
end
