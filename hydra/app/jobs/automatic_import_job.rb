# AutomaticImportJob
# Author:: David J. Davis  (mailto:djdavis@mail.wvu.edu)
# Modified_By:: Tracy A. McCormick (mailto:tam0013@mail.wvu.edu)
# Modified:: January 20, 2023
# Automatic import Job.
class AutomaticImportJob < ApplicationJob
  queue_as :default

  before_perform do |job|
    control_file = job.arguments.first
    project_name = control_file["project_name"]
    time_stamp = control_file["time_stamp"]

    # if rails is in development do not send emails
    if Rails.env.production?    
      emails = control_file['contact_emails']
      date_of_export = DateTime.strptime(time_stamp.to_s,'%s')
      subject = "Queueing Automatic Import for #{project_name.capitalize}"
      item_count = control_file['digital_items_count']

      # format body of the email 
      body = "The export for #{project_name} was made on, #{date_of_export}. This email is to " \
      'inform you that the import has been placed in the queue. The number ' \
      "of records in the update is {#{control_file['record_count']}} and the " \
      "number of digital objects {#{item_count}}."

      ImportMailer.email(emails, subject, body).deliver_now
    end

    control_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/mfcs"
    process_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/hydra/in-progress"
    puts "Starting Job"
    File.rename("#{control_dir}/#{time_stamp}.yaml", "#{process_dir}/#{time_stamp}.yaml")
  end

  after_perform do |job|
    control_file = job.arguments.first
    project_name = control_file["project_name"]
    time_stamp = control_file["time_stamp"]
    process_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/hydra/in-progress"
    finished_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/hydra/finished"
    puts "Completed Job"
    File.rename("#{process_dir}/#{time_stamp}.yaml", "#{finished_dir}/#{time_stamp}.yaml") 
  end

  def perform(*args)
    # setup emails stuff
    control_file = args[0]
    project_name = control_file["project_name"]
    time_stamp = control_file["time_stamp"]
    emails = control_file['contact_emails']
    retry_count = 0
    
    # send the email
    begin  
      puts "Starting the job."
      import = AutomaticImport.new(control_file)
      import.run
    rescue => e
      # pause processing and retry
      sleep 10
      retry_count += 1
      if retry_count < 5
        # print the error and retry
        puts "Error: #{e}"
        puts "Retrying"
        retry
      else 
        # move the control file to the failed directory
        process_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/hydra/in-progress"
        failed_dir = "/mnt/nfs-exports/mfcs-exports/#{project_name}/control/hydra/failed"
        File.rename("#{process_dir}/#{time_stamp}.yaml", "#{failed_dir}/#{time_stamp}.yaml")

        # if rails is in development do not send emails
        if Rails.env.production?
          subject = "Failed Automatic Import for #{project_name.capitalize}"
      
          # format body of the email 
          body = "The import failed for #{project_name}.  This is the error thrown: #{e}. \n\n StackTrace: #{e.backtrace.join("\n")}"
          ImportMailer.email(emails, subject, body).deliver_now
        end
        abort "Could not complete the automatic import." 
      end
    end
  end
end