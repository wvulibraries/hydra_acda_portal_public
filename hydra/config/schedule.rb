# set environmentals
ENV.each { |k, v| env(k, v) }

# set logs and environment
set :output, {:standard => "#{path}/log/cron.log", :error => "#{path}/log/cron_error.log"}
set :environment, ENV['RAILS_ENV']

# if rails env is production run cron_import every hour
if ENV['RAILS_ENV'] == 'production'
  every 1.hour do
    command "cd #{path} && bin/rails r import/cron_import.rb acda_portal_public"
  end
else
  every 5.minute do
    command "cd #{path} && bin/rails r import/cron_import.rb acda_portal_public"
  end
end

# clobber the tmp folder daily and logs to keep files small 
every 1.day do
  command "cd #{path} && bundle exec rake log:clear"
  command "cd #{path} && bin/rails tmp:clear"
  command "cd #{path} && bin/rails tmp:create"  
  command "cd #{path} && bin/rails restart" # restart the server
end
