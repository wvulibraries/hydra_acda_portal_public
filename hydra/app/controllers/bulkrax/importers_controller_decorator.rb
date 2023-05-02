# frozen_string_literal: true

module Bulkrax::ImportersControllerDecorator
  def check_permissions
    @current_user = User.find_or_create_by(email: 'bulkrax@example.com') do |u|
      u.password = 'bulkrax' unless u.password
    end
    @current_ability = Ability.new(current_user)
    raise CanCan::AccessDenied unless current_ability.can_import_works?
  end
end

Bulkrax::ImportersController.prepend(Bulkrax::ImportersControllerDecorator)
