# frozen_string_literal: true

# Overrides Bulkrax's default entry retry link, which uses Bootstrap 4
# attributes (data-toggle/data-target). Our app uses Bootstrap 5, which
# renamed these to data-bs-toggle/data-bs-target - without this fix,
# clicking the retry icon does nothing (modal never opens).
module Bulkrax
  module DatatablesBehaviorDecorator
    def entry_util_links(e, item)
      links = []
      links << view_context.link_to(view_context.raw('<span class="fa fa-info-circle"></span>'), view_context.item_entry_path(item, e))
      links << "<a class='fa fa-repeat' data-bs-toggle='modal' data-bs-target='#bulkraxItemModal' data-entry-id='#{e.id}'></a>" if view_context.an_importer?(item)
      links << view_context.link_to(view_context.raw('<span class="fa fa-trash"></span>'), view_context.item_entry_path(item, e), method: :delete, data: { confirm: 'This will delete the entry and any work associated with it. Are you sure?' })
      links.join(" ")
    end
  end
end

Bulkrax::DatatablesBehavior.prepend(Bulkrax::DatatablesBehaviorDecorator)