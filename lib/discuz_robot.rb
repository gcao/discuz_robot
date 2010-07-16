require 'open-uri'
require 'nokogiri'

module Discuz
  class Robot
    def initialize base_url = "http://localhost/bbs/"
      @base_url   = base_url
      @agent = CurlAgent.new
    end
    
    def login username, password
      form_url       = @base_url + "logging.php?action=login"
      form_resp      = @agent.get form_url, "-D #{@agent.cookie_file}"
      puts form_resp
      form_doc       = Nokogiri::HTML(form_resp)
      formhash_input = form_doc.css("form input[name=formhash]")
      if formhash_input.first
        # Login
        formhash     = formhash_input.first['value']
        login_url    = @base_url + "logging.php?action=login&loginsubmit=yes&inajax=0"
        @agent.post login_url, "submit=true&formhash=#{formhash}&loginfield=username&username=#{username}&password=#{password}&questionid=0&answer=&cookietime=2592000"
      else
        # Already logged in (this can happen if login is called multiple times in one session)
      end
    end
    
    def post forum_id, subject, message, options = {}
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
    attr :cookie_file
    
    def initialize
      @cookie_file = "/tmp/c.txt"
      `rm #{@cookie_file}`   # remove existing cookie file if any
      
      user_agent  = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.2.6) Gecko/20100625 Firefox/3.6.6"
      @curl_cmd   = %Q(curl --stderr /dev/null -A "#{user_agent}" -b #{@cookie_file})
    end
    
    def get url, extras = nil
      cmd = %Q(#{@curl_cmd} #{extras} "#{url}")
      puts cmd
      %x(#{cmd})
    end
    
    def post url, data, extras = nil
      cmd = %Q(#{@curl_cmd} -d "#{data}" #{extras} "#{url}")
      puts cmd
      %x(#{cmd})
    end
  end
end
