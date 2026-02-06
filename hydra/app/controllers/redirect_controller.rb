class RedirectController < ApplicationController
  def search_history
    redirect_to 'https://congressarchives.org/search_history', allow_other_host: true
  end
end
