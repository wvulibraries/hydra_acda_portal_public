echo "Install Gems"
bundle install

echo "Preparing Database"
bin/rails db:drop db:create

# if schema.rb exists load schema else run the migrations
FILE="/home/hydra/db/schema.rb"
if [ -e $FILE ]; then
    bin/rails db:schema:load
else
    bin/rails db:migrate
fi

bin/rails db:seed


