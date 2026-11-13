# set environmentals
ENV.each { |k, v| env(k, v) }

# set logs and environment
set :output, {:standard => "#{path}/log/cron.log", :error => "#{path}/log/cron_error.log"}
set :environment, ENV['RAILS_ENV']

# clobber the tmp folder daily and logs to keep files small 
every 1.day do
  # Clean up old URL checks first
  rake "url_checks:cleanup"
  
  # Then do system maintenance
  command "cd #{path} && bundle exec rake log:clear"
  command "cd #{path} && bin/rails tmp:clear"
  command "cd #{path} && bin/rails tmp:create"  
  command "cd #{path} && bin/rails restart" # restart the server
end
