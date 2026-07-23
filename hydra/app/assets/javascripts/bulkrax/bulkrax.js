// Global JS file for Bulkrax
// OVERRIDE: fixed the entry-id replacement in the retry modal. The
// original regex (/\d+\?/) only matched an ID followed by a literal "?",
// but our routes are plain paths like /entries/123 with no query string,
// so the link was never actually rewritten - it always kept whichever
// entry ID was first rendered on the page (b-1-0), no matter which row's
// retry icon you clicked.


// CACHE BUST TEST 1

$('button#err_toggle').click(function() {
  $('#error_trace').toggle();
});

$('button#fm_toggle').click(function() {
  $('#field_mapping').toggle();
});

$('#bulkraxItemModal').on('show.bs.modal', function (event) {
  var button = $(event.relatedTarget);
  var recipient = button.data('entry-id');
  var modal = $(this);
  modal.find('a').each(function() {
    this.href = this.href.replace(/\/entries\/\d+/, '/entries/' + recipient);
  });
  return true;
});