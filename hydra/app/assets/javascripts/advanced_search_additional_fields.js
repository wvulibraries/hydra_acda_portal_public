// Allows the `Additional fields` button on the advanced search page
// to toggle the additional fields div on and off.
$(document).ready(function() {
  $('.additional-fields').click(function(e) {
    e.preventDefault();
    $('#additionalFieldsDiv').collapse('toggle');
  });
});
