class ThumbnailPresenter
    def initialize(id)
      @image_model = Acda.where(id: id).first
    end
  
    def thumbnail_exists?
      if @image_model.thumbnail_file
        true
      else
        false
      end
    end
  end