class Ability
  include Hydra::Ability
  
  # Define any customized permissions here.
  def custom_permissions
    # Limits deleting objects to a the admin user
    #
    # if current_user.admin?
    #   can [:destroy], ActiveFedora::Base
    # end

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end

    # OVERRIDE Bulkrax 5.0.0 requires these. Set to true because these abilities don't exist in this app
    def can_import_works?
      # can_create_any_work?  
      true
    end

    def can_export_works?
      # can_create_any_work?  
      true
    end
  end
end
