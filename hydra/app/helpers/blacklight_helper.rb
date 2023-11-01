module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  def application_name
    'American Congress Digital Archives Portal'
  end

  def extract_year(date_string)
    if date_string =~ /\A\d{4}-\d{2}-\d{2}\z/
      # Matches YYYY-MM-DD
      Date.strptime(date_string, '%Y-%m-%d').year
    elsif date_string =~ /\A\d{4}-\d{2}\z/
      # Matches YYYY-MM
      Date.strptime(date_string, '%Y-%m').year
    elsif date_string =~ /\A\d{4}\z/
      # Matches YYYY
      Date.new(date_string.to_i).year
    else
      date_string
    end
  end
end
