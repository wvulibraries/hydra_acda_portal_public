# set environmentals
ENV.each { |k, v| env(k, v) }

# set logs and environment
set :output, {:standard => "#{path}/log/cron.log", :error => "#{path}/log/cron_error.log"}
set :environment, ENV['RAILS_ENV']

every 1.hour do
  command "cd #{path} && bin/rails r import/cron_import.rb acda_portal"
end

# clobber the tmp folder daily and logs to keep files small 
every 1.day do
  command "cd #{path} && rake log:clear"
  command "cd #{path} && bin/rails tmp:clear"
  command "cd #{path} && bin/rails restart" # restart the server
end