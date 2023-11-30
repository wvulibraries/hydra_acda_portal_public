# config/initializers/activerecord_yaml.rb
# Psych solution found here:
# https://stackoverflow.com/questions/71191685/visit-psych-nodes-alias-unknown-alias-default-psychbadalias
ActiveRecord.use_yaml_unsafe_load = true