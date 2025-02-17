RSpec::Matchers.define :have_property do |property_name|
    match do |model|
      model.respond_to?(property_name) && 
      model.class.properties[property_name.to_s].present?
    end
  end
  