# Class for Static Methods
# formats and modifies things from the mfcs export
class HydraFormatting
  def self.valid_string(str)
    return nil if str.to_s.mb_chars.length == 0
    str
  end

  # split a subject string to array
  def self.split_subjects(str)
    # return nil if string length is 0
    return nil if str.to_s.mb_chars.length == 0
    str.split('|||')
  end

  # remove special chars
  # ==================================================
  # Author(s) : David J. Davis, Tracy A. McCormick
  # Modified : 9/15/2021
  # Description :
  # remove special characters from string return nil if string is empty
  def self.remove_special_chars(str) 
    # return nil if string length is 0
    return nil if str.to_s.mb_chars.length == 0
    temp = decode_html(str)
    temp.gsub(/ *\n/ , '').gsub(/ *\r/, '').gsub(/ *\t/ , ' ').to_s
  end

  # remove ascii character references for the actual character
  def self.decode_html(str = '')
    # return nil if string length is 0
    return nil if str.to_s.mb_chars.length == 0  
    temp_string = Nokogiri::HTML.parse str
    temp_string.text.to_s
  end 

  # mime type
  def self.mime_type(filename)
    MIME::Types.type_for("#{filename}").first.content_type
  end
end