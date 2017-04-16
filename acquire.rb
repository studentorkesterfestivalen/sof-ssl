require 'net/http'
require 'open-uri'
require 'pty'

class Acquire
  def initialize(stdout, stdin)
    @stdout = stdout
    @stdin = stdin
    @app = ARGV[1]
    @domain = nil
    @base_url = nil
    @challenge = nil
    @key_countdown = -1
  end

  def handle_line(line)
    puts line
    if line.start_with? 'http-01 challenge for'
      update_domain line
    elsif line.include? 'IP being logged'
      confirm_ip_logging
    elsif line.strip == 'Make sure your web server displays the following content at'
      @key_countdown = 3
    elsif countdown_key
      update_challenge line
      update_app_configuration

      puts 'Waiting for endpoint to come online...'
      if test_endpoint
        confirm_challenge_online
      end
    end
  end

  def update_domain(line)
    @domain = line.strip.split[-1]
    @base_url = 'http://' + @domain
  end

  def update_challenge(line)
    @challenge = line.strip
  end

  def confirm_ip_logging
    @stdin.puts 'y'
  end

  def confirm_challenge_online
    @stdin.puts '\n'
  end

  def update_app_configuration
    puts 'Updating environment variable with challenge...'
    system("heroku config:set LETSENCRYPT_CHALLENGE=#{@challenge} --app #{@app}")
    puts 'Done!'
  end

  def test_endpoint(retries=10)
    retries -= 1
    key = @challenge.split('.')[0]

    begin
      URI.parse("#{@base_url}/.well-known/acme-challenge/#{key}").read
      puts 'Endpoint is online!'
      return true
    rescue OpenURI::HTTPError
      if retries > 0
        puts "Retrying connection #{retries} more times"
        sleep(5)
        return test_endpoint(retries)
      else
        return false
      end
    end
  end

  def countdown_key
    if @key_countdown > 0
      @key_countdown -= 1
      return @key_countdown == 0
    else
      return false
    end
  end
end

puts 'Disabling SSL enforcement...'
system("heroku config:set DANGEROUSLY_DONT_FORCE_SSL=true --app #{ARGV[1]}")

cmd = "certbot certonly --manual --email sof-it-putte2@lintek.liu.se --agree-tos --config-dir config --work-dir letsencrypt --logs-dir logs -d #{ARGV[0]}"
PTY.spawn cmd do |r, w, pid|
  begin
    r.sync

    acquire = Acquire.new(r, w)
    r.each_line { |l| acquire.handle_line l }
  rescue Exception => e
    puts e
    puts e.backtrace
  ensure
    ::Process.wait pid
  end
end


if ARGV[2] == '--create'
  cert_cmd = 'certs:add'
else
  cert_cmd = 'certs:update'
end
system("heroku #{cert_cmd} --confirm #{ARGV[1]} config/live/#{ARGV[0]}/fullchain.pem config/live/#{ARGV[0]}/privkey.pem --app #{ARGV[1]}")

puts 'Re-enabling SSL enforcement...'
system("heroku config:unset DANGEROUSLY_DONT_FORCE_SSL --app #{ARGV[1]}")
puts 'Done!'

exit "#{cmd} failed" unless $? && $?.exitstatus == 0
