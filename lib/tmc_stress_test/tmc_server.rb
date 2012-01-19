
require 'tmc_stress_test/test_config'
require 'rest_client'
require 'multi_json'

class TmcServer
  def initialize(config)
    @config = config
  end
  
  def api_version
    2
  end
  
  def get_courses
    MultiJson.decode(get('/courses.json').body)['courses']
  end
  
  def get(path, options = {})
    request(:get, path, options)
  end
  
  def post(path, data = {}, options = {})
    resp = request(:post, path, options.merge(:payload => data))
  end
  
private
  def request(method, path, options = {})
    if path.start_with?('http')
      url = path
    else
      url = baseurl + path
    end
    url += "?api_version=#{api_version}" unless url.include?('api_version=')
    options = { :method => method, :url => url, :user => user, :password => password }.merge(options)
    begin
      RestClient::Request.new(options).execute do |resp, req, result, &block|
        response = resp
        resp.return!(req, result, &block)
      end
    rescue RestClient::Exception => e
      if e.response.code == 302
        e.response
      else
        raise
      end
    end
  end
  
  def baseurl
    @config['baseurl'].sub(/\/+$/, '')
  end
  
  def user
    @config['admin_user']
  end
  
  def password
    @config['admin_password']
  end
end
