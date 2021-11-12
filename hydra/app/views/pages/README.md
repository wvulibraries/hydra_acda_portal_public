each page needs a view here, and needs put into the routes.rb

```
get '/about' => 'pages#about'
get '/' => 'pages#index'
```

a corisponding method needs added to the pages controller:

```
  def about
  	(@response, @document_list) = get_search_results
	render  	
  end

  def index
  end
```