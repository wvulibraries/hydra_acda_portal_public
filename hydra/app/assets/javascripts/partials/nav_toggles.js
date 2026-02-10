// enables the tabs in the importers/exporters pages.
  $(document).ready(function() {
    $('.bulkrax-nav-tab-top-margin.nav-tabs a').click(function(e) {
      e.preventDefault();

      // Remove active class from all tabs and hide all tab content
      $('.bulkrax-nav-tab-top-margin.nav-tabs a').parent().removeClass('active');
      $('.tab-content .tab-pane').removeClass('active');

      // Add active class to clicked tab and show its content
      $(this).parent().addClass('active');
      $($(this).attr('href')).addClass('active');
    });

    // toggles tabs on the errors page
    $('#full-errors-tab, #full-errors-tab a').click(function(e) {
      $('#raw-errors-tab, #bulkrax-raw-toggle-1').removeClass('active');
      $('#full-errors-tab, #bulkrax-full-toggle-1').addClass('active');
    })

    $('#raw-errors-tab, #raw-errors-tab a').click(function(e) {
      $('#full-errors-tab, #bulkrax-full-toggle-1').removeClass('active');
      $('#raw-errors-tab, #bulkrax-raw-toggle-1').addClass('active');
    })

    // toggles tabs on the parser mappings page
    $('#full-mappings-tab, #full-mappings-tab a').click(function(e) {
      $('#raw-mappings-tab, #bulkrax-raw-toggle-2').removeClass('active');
      $('#full-mappings-tab, #bulkrax-full-toggle-2').addClass('active');
    })

    $('#raw-mappings-tab, #raw-mappings-tab a').click(function(e) {
      $('#full-mappings-tab, #bulkrax-full-toggle-2').removeClass('active');
      $('#raw-mappings-tab, #bulkrax-raw-toggle-2').addClass('active');
    })
  });

  // Mobile hamburger menu toggle for navigation
  $(document).ready(function() {
    var hamburger = $('#navbar-hamburger-toggle');
    var menu = $('#sticky-header-nav-menu');

    hamburger.on('click', function() {
      menu.toggleClass('active');
    });
  });
