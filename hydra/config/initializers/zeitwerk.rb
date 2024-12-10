# Bulkrax is still a very Hyrax focused gem and though there has been
# work to make it more generic, there are still some Hyrax specific
# constants that are loaded when the gem is loaded. This initializer
# will ignore all files that have 'hyrax' in the path so that Bulkrax
# can be used in this Hydra application
Dir.glob(Bulkrax::Engine.root.join('**', '*hyrax*')).each do |path|
  Rails.autoloaders.main.ignore(path) if File.directory?(path)
end
