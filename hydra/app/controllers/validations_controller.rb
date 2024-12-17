# frozen_string_literal: true

# Validations Class
class ValidationsController < ApplicationController
  def upload
  end

  def show
    unless params[:csv_file]&.content_type == 'text/csv'
      flash[:error] = 'Please upload a CSV file'
      return redirect_to validate_path
    end

    @path = params[:csv_file].tempfile.path
    if params[:background_job] == '1'
      submit_validate_job
      flash[:notice] = 'Validation Job has been submitted. Results will be sent to provided email address.'
      redirect_to validate_path
    else
      @results = validate_file
    end
  rescue CSV::MalformedCSVError
    flash[:error] = 'Invalid CSV file format'
    redirect_to validate_path
  end

  private

  def submit_validate_job
    ValidateJob.perform_later(path: @path, file_name: params['csv_file'].original_filename, mail_to: params[:mail_to])
  end

  def validate_file
    ValidationService.new(path: @path).validate
  end
end
