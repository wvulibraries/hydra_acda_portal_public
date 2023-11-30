# AutomaticImport
# Author:: David J. Davis  (mailto:djdavis@mail.wvu.edu)
# Date:: Nov. 2017
# Modified_By:: Tracy A. McCormick (mailto:tam0013@mail.wvu.edu)
# Date:: September 2021
# The logic behind the background task for the automatic import.

class AutomaticImport
  include ImportLibrary

  def initialize(*args)
    # global vars 
    @control_file = args[0]
    @project = @control_file['project_name']
    @base_path = "/mnt/nfs-exports/mfcs-exports/#{@project}"
    time_stamp = @control_file['time_stamp']
    export_date = DateTime.strptime(time_stamp.to_s,'%s').strftime('%D %r') 
    @export_path = "/mnt/nfs-exports/mfcs-exports/#{@project}/export/#{time_stamp}"
    
    # log information
    log_file = File.open("/home/hydra/log/#{@project}_#{time_stamp}.log", 'w')
    @logger = Logger.new log_file
    
    @logger.info "Starting import for #{@project} on #{export_date}"
    @logger.info "Importing from #{@export_path}"
  
    # email details 
    @email_details = "\n ---- Project: #{@project} \n ---- Export Date: #{export_date} \n ---- Time Stamp: #{time_stamp} \n\n"
  end

  def write_logs(log_message)
    @logger.debug log_message
  end 

  # email details 
  def send_feedback
    # send emails only if in production
    return unless Rails.env.production?
    
    emails = @control_file['contact_emails']
    subject = "Import for #{@project.capitalize} Completed"
    ImportMailer.email(emails, subject, @email_details).deliver_now
  end 

  def parse_data(json_file)
    # parse the json file
    @objects = JSON.parse json_file
    # set objects
    @objects.each do |record|
      begin
        # skip record if EXCLUDE is in title
        next if record['title'].include?("EXCLUDE")

        puts "Processing #{record['identifier']}"

        # remove . in identifier
        id = record['identifier'].gsub('.', '').to_s
        puts "ID: #{id}"

        # record exists
        record_exists = Acda.where(identifier: id).first

        if record_exists.nil?
          new_record = ImportLibrary.modify_record(@export_path, record)
          puts new_record.inspect

          if ImportLibrary.import_record(id, new_record)
            log_text = "#{record['identifier']} record created. \n"
            @email_details.concat log_text 
          else
            error_text = "#{record['identifier']} record failed to create. \n"
            @email_details.concat error_text 
          end            
        else                 
          if ImportLibrary.update_record(record_exists, ImportLibrary.modify_record(@export_path, record))
            log_text = "#{record['identifier']} record updated. \n"
            @email_details.concat log_text 
          else
            error_text = "#{record['identifier']} record failed to update. \n" 
            @email_details.concat error_text  
          end            
        end
      rescue RuntimeError => e
        puts "Record (#{record['identifier']})"
        abort "Error (#{e})"
      end
    end
    self.send_feedback 
  end  

  def run
    # find the json file in the directory
    matched_files = Dir["#{@export_path}/data/*-data.json"]

    if File.exist?(matched_files.first)
      # read and parse the json file
      self.parse_data(File.read matched_files[0])
    else
      abort "No data file found"
    end
  end

end
