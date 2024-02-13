# Congress Archives (Rails 6)

## Contents

----

# Setup Instructions

# Upgrade testing issues

## Unresolved errors
Appears to be issue with blacklight and qa autocomplete
Showing /home/hydra/app/views/catalog/_search_form.html.erb where line #14 raised:
undefined method `suggest_index_path' for #<ActionDispatch::Routing::RoutesProxy:0x00007f78a31ca4f8>
Note to get past error removed data section from line 14
Original line -    <%= text_field_tag :q, params[:q], placeholder: t('blacklight.search.form.search.placeholder'), class: "search_q q form-control", id: "q", autofocus: should_autofocus_on_search_box?, data: { autocomplete_enabled: autocomplete_enabled?, autocomplete_path: blacklight.suggest_index_path }  %>



# Bulkrax Imports
To Access Bulkrax on a dev setup go to 'http:/localhost:3000/importers?locale=en' use the Username and Password that you have setup in the env file.

# Releases

To release code to the dev server, create a pre-release tag in the WVU Github repo for the application. The dev server will pick up the code in 5 or so minutes and pull, build, deploy it for you. The same can be done on production by editing your release and marking the release latest instead of pre-release.
