require 'open-uri'
require 'nokogiri'

module Discuz
  class Robot
    def initialize base_url = "http://localhost/bbs/"
      @base_url  = base_url
      @logged_in = false
      @agent     = CurlAgent.new
    end
    
    def login username, password
      return if @logged_in
      
      form_url       = @base_url + "logging.php?action=login"
      form_resp      = @agent.get form_url, :save_cookie => true
      form_doc       = Nokogiri::HTML(form_resp)
      formhash_input = form_doc.css("form input[name=formhash]")
      if formhash_input.first
        # Login
        formhash     = formhash_input.first['value']
        login_url    = @base_url + "logging.php?action=login&loginsubmit=yes&inajax=0"
        @agent.post login_url, 
          "submit=true&formhash=#{formhash}&loginfield=username&username=#{username}&password=#{password}&questionid=0&answer=&cookietime=2592000", 
          :save_cookie => true
      else
        # Already logged in (this can happen if login is called multiple times in one session)
      end
      
      @logged_in = true
    end
    
    def post forum_id, subject, message, options = {}
      login unless @logged_in
      
      form_url  = @base_url + "post.php?action=newthread&fid=#{forum_id}"
      form_resp = @agent.get form_url
      # puts form_resp
      form_doc  = Nokogiri::HTML(form_resp)
      formhash  = form_doc.css("form input[name=formhash]").first['value']
      posttime  = form_doc.css("form input[name=posttime]").first['value']

      post_url  = @base_url + "post.php?action=newthread&fid=#{forum_id}&extra=&topicsubmit=yes"
      @agent.post post_url, "action=newthread&fid=#{forum_id}&formhash=#{formhash}&posttime=#{posttime}&subject=#{subject}&message=#{message}"
    end
  end
  
  class CurlAgent
    def initialize
      @cookie_file = "/tmp/c.txt"
      `test #{@cookie_file} && rm #{@cookie_file}`   # remove existing cookie file if any
      
      user_agent  = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.2.6) Gecko/20100625 Firefox/3.6.6"
      @curl_cmd   = %Q(curl --stderr /dev/null -A "#{user_agent}" -b #{@cookie_file})
    end
    
    def get url, options = {}
      cmd = @curl_cmd
      cmd += " -D #{@cookie_file}" if options[:save_cookie]
      cmd += %Q( "#{url}")
      puts cmd
      %x(#{cmd})
    end
    
    def post url, data, options = {}
      cmd = @curl_cmd
      cmd += " -D #{@cookie_file}" if options[:save_cookie]
      cmd += %Q( -d "#{data}")
      cmd += %Q( "#{url}")
      puts cmd
      %x(#{cmd})
    end
  end
end
