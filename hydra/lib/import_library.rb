# Import Helper for both automatic and manual imports
# @author Tracy A. McCormick
# @return [Boolean]
# 
# ================================================================================
module ImportLibrary
    def self.create_new_record(obj)  
        # create the new record
        Acda.create(obj.except(:image_path, :thumb_path, :audio_path, 
        :video_path, :video_image_path, :video_thumb_path, 
        :pdf_path, :pdf_image_path, :pdf_thumb_path))
    end

    def self.set_file(file_obj, type, path)
        # ensure the file exists in the path
        return unless File.exist?(path.to_s)

        file_obj.mime_type = type
        file_obj.content = File.open(path)
        file_obj.original_name = path
    end     

    # importing the record
    def self.import_record(id, obj)   
        begin
          retries ||= 0
    
          jpg_path = obj[:image_path]
          thumb_path = obj[:thumb_path]
          audio_path = obj[:audio_path]
          video_path = obj[:video_path]
          video_image_path = obj[:video_image_path]
          video_thumb_path = obj[:video_thumb_path]
          pdf_path = obj[:pdf_path]
          pdf_image_path = obj[:pdf_image_path]
          pdf_thumb_path = obj[:pdf_thumb_path]
      
          new_record = create_new_record(obj)
      
          new_record.files.build
          set_file(new_record.build_image_file, 'application/jpg', jpg_path) if File.exist?(jpg_path.to_s)
          set_file(new_record.build_thumbnail_file, 'application/jpg', thumb_path) if File.exist?(thumb_path.to_s)
          set_file(new_record.build_pdf_file, 'application/pdf', pdf_path) if File.exist?(pdf_path.to_s)
          set_file(new_record.build_image_file, 'application/jpg', pdf_image_path) if File.exist?(pdf_image_path.to_s)
          set_file(new_record.build_thumbnail_file, 'application/jpg', pdf_thumb_path) if File.exist?(pdf_thumb_path.to_s)
          set_file(new_record.build_audio_file, 'audio/mpeg', audio_path) if File.exist?(audio_path.to_s)
          set_file(new_record.build_video_file, 'video/mp4', video_path) if File.exist?(video_path.to_s)
          set_file(new_record.build_image_file, 'application/jpg', video_image_path) if File.exist?(video_image_path.to_s)
          set_file(new_record.build_thumbnail_file, 'application/jpg', video_thumb_path) if File.exist?(video_thumb_path.to_s) 
    
          new_record.save
        rescue RuntimeError => e
          puts "Error: #{e} - retrying record creation"
    
          # if tombstone exists, delete it
          if e.message.include? "Can't call create on an existing resource"
            # get resource id from error message
            uri = e.message.split("(").last.split(")").first
    
            puts "deleting record and tombstone from fedora and retrying create"
            # try to use curl to delete the record and tombstone
            %x{ curl -X DELETE #{uri} }
            %x{ curl -X DELETE #{uri}/fcr:tombstone }
          else
            # delete tombstone from fedora
            result = Acda.eradicate(id)
            puts "Result of eradication on #{id} was #{result} \n"
          end
          retry if (retries += 1) < 3
        end  
    end

    def self.update_file(file_obj, type, path)
        file_obj.mime_type = type
        file_obj.content = File.open(path)
        file_obj.original_name = path
        file_obj.save
    end      
      
    # update the record
    def self.update_record(updated_record, obj)
      jpg_path = obj[:image_path]
      thumb_path = obj[:thumb_path]
      audio_path = obj[:audio_path]
      video_path = obj[:video_path]
      video_image_path = obj[:video_image_path]
      video_thumb_path = obj[:video_thumb_path]
      pdf_path = obj[:pdf_path]
      pdf_image_path = obj[:pdf_image_path]
      pdf_thumb_path = obj[:pdf_thumb_path]
  
      updated_record.update(obj.except(:image_path, :thumb_path, :audio_path, 
                                  :video_path, :video_image_path, :video_thumb_path, 
                                  :pdf_path, :pdf_image_path, :pdf_thumb_path))
  
      if File.exist?(jpg_path)
        image_file = updated_record.image_file
        if image_file.nil?
          set_file(updated_record.build_image_file, 'application/jpg', jpg_path)
        else
          update_file(image_file, 'application/jpg', jpg_path)
        end
      end
  
      if File.exist?(thumb_path)
        thumb_file = updated_record.thumbnail_file
        if thumb_file.nil?  
          set_file(updated_record.build_thumbnail_file, 'application/jpg', thumb_path)
        else
          update_file(thumb_file, 'application/jpg', thumb_path)
        end
      end
  
      if File.exist?(pdf_path)
        pdf_file = updated_record.pdf_file
        if pdf_file.nil?
          set_file(updated_record.build_pdf_file, 'application/pdf', pdf_path)
        else
          update_file(pdf_file, 'application/pdf', pdf_path)
        end
      end
  
      if File.exist?(pdf_image_path)
        pdf_image_file = updated_record.image_file
        if pdf_image_file.nil?
          set_file(updated_record.build_image_file, 'application/jpg', pdf_image_path)
        else
          update_file(pdf_image_file, 'application/jpg', pdf_image_path)
        end
      end   
  
      if File.exist?(pdf_thumb_path)
        pdf_thumb_file = updated_record.thumbnail_file
        if pdf_thumb_file.nil?
          set_file(updated_record.build_thumbnail_file, 'application/jpg', pdf_thumb_path)
        else
          update_file(pdf_thumb_file, 'application/jpg', pdf_thumb_path)
        end
      end
  
      if File.exist?(audio_path)
        audio_file = updated_record.audio_file
        if audio_file.nil?
          set_file(updated_record.build_audio_file, 'audio/mpeg', audio_path)
        else
          update_file(audio_file, 'audio/mpeg', audio_path)
        end
      end
  
      if File.exist?(video_path)
        video_file = updated_record.video_file
        if video_file.nil? 
          set_file(updated_record.build_video_file, 'application/jpg', video_path)
        else
          update_file(video_file, 'application/jpg', video_path)
        end
      end
  
      if File.exist?(video_image_path)
        video_image_file = updated_record.image_file
        if video_image_file.nil?
          set_file(updated_record.build_image_file, 'application/jpg', video_image_path)
        else
          update_file(video_image_file, 'application/jpg', video_image_path)
        end
      end
  
      if File.exist?(video_thumb_path)
        video_thumb_file = updated_record.thumbnail_file
        if video_thumb_file.nil?
          set_file(updated_record.build_thumbnail_file, 'application/jpg', video_thumb_path)
        else
          update_file(video_thumb_file, 'application/jpg', video_thumb_path)
        end
      end
  
      updated_record.save
    end      

    # Checks if a file named with the idno is present
    # If it is, it will return the path to the file
    # If it is not, it will return identifier file path.
    # @return String
    # @author Tracy A McCormick
    # Created: 09/18/2021
    def self.find_file_name(path, idno, identifier, extension)
      idno_file = "#{path}/#{idno}.#{extension}"
      identifier_file = "#{path}/#{identifier}.#{extension}"
      File.exist?(idno_file) ? idno_file : identifier_file
    end    
    
    def self.modify_record(export_path, record)  
      # modify each record
      {
        # insert fields here
        id: HydraFormatting.valid_string(record['identifier']), 
        contributing_institution: HydraFormatting.valid_string(record['contributing_institution']), 
        title: HydraFormatting.valid_string(record['title']),
        date: HydraFormatting.valid_string(record['date']),
        edtf: HydraFormatting.valid_string(record['edtf']),
        creator: HydraFormatting.valid_string(record['creator']), 
        rights: HydraFormatting.valid_string(record['rights']), 
        language: HydraFormatting.split_subjects(record['language']),
        congress: HydraFormatting.valid_string(record['coverage_congress']),
        collection_title: HydraFormatting.valid_string(record['collection']), 
        # physical_location: \"Collection 012, Box 35, Folder 31\", 
        collection_finding_aid: HydraFormatting.valid_string(record['collection_finding_aid']), 
        identifier: HydraFormatting.valid_string(record['identifier']), 
        # preview: \"https://dolearchivecollections.ku.edu/index.php?p=...\", 
        # available_at: \"https://dolearchivecollections.ku.edu/index.php?p=...\", 
        record_type: HydraFormatting.split_subjects(record['record_type']), 
        policy_area: HydraFormatting.split_subjects(record['subject_policy']),
        topic: HydraFormatting.split_subjects(record['subject_topical']), 
        names: HydraFormatting.split_subjects(record['subject_names']), 
        location_represented: HydraFormatting.split_subjects(record['coverage_spatial']),
        extent: HydraFormatting.valid_string(record['extent']),  
        publisher: HydraFormatting.split_subjects(record['publisher']),
        description: HydraFormatting.remove_special_chars(record['description'].to_s),  
        dc_type: HydraFormatting.valid_string(record['dc_type']), 

        # end of insert fields
        
        project: ['acda', 'ACDA Portal'],
        read_groups: ['public'],
        image_path: find_file_name("#{export_path}/jpg", record['idno'], record['identifier'], "jpg"),
        thumb_path: find_file_name("#{export_path}/thumbs", record['idno'], record['identifier'], "jpg"),
        audio_path: find_file_name("#{export_path}/audio", record['idno'], record['identifier'], "mp3"),
        video_path: find_file_name("#{export_path}/video", record['idno'], record['identifier'], "mp4"),
        video_image_path: find_file_name("#{export_path}/videoimages", record['idno'], record['identifier'], "jpg"),
        video_thumb_path: find_file_name("#{export_path}/videothumbs", record['idno'], record['identifier'], "jpg"),
        pdf_path: find_file_name("#{export_path}/pdf", record['idno'], record['identifier'], "pdf"),
        pdf_image_path: find_file_name("#{export_path}/pdfimages", record['idno'], record['identifier'], "jpg"),
        pdf_thumb_path: find_file_name("#{export_path}/pdfthumbs", record['idno'], record['identifier'], "jpg")
      }
    end  

    def self.prompt
      result = gets.to_s
      result.downcase!
      result.strip!
      result.empty? ? 'no' : result
    end
end