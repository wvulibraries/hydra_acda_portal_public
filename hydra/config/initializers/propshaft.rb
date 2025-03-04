# Configure Propshaft asset pipeline
Rails.application.config.assets.paths << Rails.root.join("app/assets/builds")
Rails.application.config.assets.precompile += %w( application.js application.css )