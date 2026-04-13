# frozen_string_literal: true

class UrlHealthController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :validate_domain

  def report_down
    Rails.logger.warn "UrlHealthController: onerror received for URL — #{params[:url]}"
    DomainHealthService.mark_down!(params[:url])
    head :ok
  end

  private

  def validate_domain
    return head(:bad_request) if params[:url].blank?

    uri = URI.parse(params[:url])
    our_host = URI.parse(request.base_url).host

    if uri.host.blank? || uri.host == our_host
      Rails.logger.warn "UrlHealthController: rejected invalid domain — #{params[:url]}"
      head :bad_request and return
    end
  rescue URI::InvalidURIError
    head :bad_request
  end
end