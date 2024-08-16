class ImagePresenter
    def initialize(id)
      @image_model = Acda.where(id: id).first
    end
  
    def show_image_button?
      if @image_model.image_file
        false
      else
        true
      end
    end
  end