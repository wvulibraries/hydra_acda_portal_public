class Ability
  include CanCan::Ability

  def initialize(user)
    @user = user
    custom_permissions
  end

  # OVERRIDE Bulkrax 5.0.0 requires these. Set to true because these abilities don't exist in this app
  def custom_permissions
    def can_import_works?
      true
    end

    def can_export_works?
      true
    end
  end
end