# Find a record by idno 
class RecordController < ApplicationController
  def index
    id = params[:id]
    data = Acda.where(id: id).first

    if id.nil? || id.empty? || data.nil?
      flash[:error] = "No Record idno has been found please try again."
      redirect_to "/catalog"
    else 
      record_id = CGI.escape data.id
      redirect_to "/catalog/#{record_id}"
    end 
  end
end
