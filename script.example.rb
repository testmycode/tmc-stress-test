# Write a script.rb to be something like this.
# See lib/tmc_stress_test/dsl.rb
# Each repetition of each block is run in its own thread, so be thread-safe.

repeat(100).times.with_label('create_user') do |env|
  env.tasks.create_user_account
end

after(5.seconds).repeat(10).times.over(60.seconds).with_label('submission') do |env|
  user_name = env.random_user_name
  url = env.tasks.post_submission(:user => user_name, :password => user_name)
  env.tasks.wait_for_submission(url)
end

after(10.seconds).repeat(20).times.over(60.seconds).with_label('load_stats') do |env|
  env.tasks.load_stats
end
