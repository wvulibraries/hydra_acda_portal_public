class RedirectController < ApplicationController
  def search_history
    redirect_to 'https://congressarchivesdev.lib.wvu.edu/search_history', allow_other_host: true
  end
end
