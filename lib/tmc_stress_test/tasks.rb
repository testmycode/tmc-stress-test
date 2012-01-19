
require 'tmc_stress_test/paths'
require 'multi_json'

# Things we're able to call in the test script as env.tasks.method.
# All are thread-safe.
class Tasks
  def initialize(env)
    @env = env
    @server = env.server
  end
  
  include Paths
  
  def create_user_account
    user_name = nil
    @env.mutex.synchronize do
      user_name = "_stress_tester_" + @env.next_user_account_number.to_s
      @env.next_user_account_number += 1
    end
    @server.post('/user', {
      'user[login]' => user_name,
      'user[email]' => "#{user_name}@example.com",
      'user[email_repeat]' => "#{user_name}@example.com",
      'user[password]' => user_name,
      'user[password_repeat]' => user_name
    })
    @env.mutex.synchronize do
      @env.user_accounts << user_name
    end
    user_name
  end
  
  def post_submission(options = {})
    File.open(submission_zip_path, 'rb') do |file|
      response = @server.post(submission_server_path, {
        'submission[file]' => file
      }, options)
      MultiJson.decode(response.to_s)['submission_url']
    end
  end
  
  def wait_for_submission(url)
    while true
      response = MultiJson.decode(@server.get(url))
      case response['status']
      when 'ok'
        break
      when 'processing'
        sleep 3
      else
        raise "Status: #{response['status']}"
      end
    end
  end
  
  def load_stats
    @server.get('/stats.json')
  end
  
  def submission_server_path
    "/courses/#{@env.course_id}/exercises/#{@env.exercise_id}/submissions.json"
  end
end
