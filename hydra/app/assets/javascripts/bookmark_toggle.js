
// Set up a MutationObserver to observe when the bookmark form is added to the DOM.
// The original javascript wasn't working on the record's show page because the form
// element was not loaded when the event listener was being added.  It works fine on
// the index page, however.

(function ($) {
  function toggleBookmarkBehavior() {
    //change form submit toggle to checkbox
    $(Blacklight.do_bookmark_toggle_behavior.selector).bl_checkbox_submit({
      //css_class is added to elements added, plus used for id base
      css_class: "toggle_bookmark",
      success: function (checked, response) {
        if (response.bookmarks) {
          $("[data-role=bookmark-counter]").text(response.bookmarks.count);
        }
      },
    });
  }
  Blacklight.do_bookmark_toggle_behavior.selector = "form.bookmark_toggle";

  var observer = new MutationObserver(function (mutations, obs) {
    mutations.forEach(function (mutation) {
      if (mutation.addedNodes) {
        for (var i = 0; i < mutation.addedNodes.length; i++) {
          // Check if the added node is the form or contains the form
          var addedNode = mutation.addedNodes[i];
          if (
            addedNode.nodeType === 1 &&
            (addedNode.matches(
              Blacklight.do_bookmark_toggle_behavior.selector
            ) ||
              addedNode.querySelector("form.bookmark_toggle"))
          ) {
            toggleBookmarkBehavior();
            obs.disconnect();
          }
        }
      }
    });
  });

  // Start observing
  observer.observe(document.body, {
    childList: true, // observe direct children
    subtree: true, // and lower descendants too
  });
})(jQuery);
