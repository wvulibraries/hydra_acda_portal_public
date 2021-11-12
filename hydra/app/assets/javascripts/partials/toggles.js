// Document Ready 
// ===================================================================================
$(function () {
	 // Add classes for logic later
  $(".wvu-header .list").addClass("destroy").prop('aria-hidden', true); 
  $(".wvrhc-header .list2").addClass("destroy").prop('aria-hidden', true);  
  $("#wvrhctoggle .fa-chevron-up").addClass("hiding").prop('aria-hidden', true);  
  $("#wvutoggle .fa-chevron-up").addClass("hiding").prop('aria-hidden', true);  
  $("#menu-toggle #menu-toggle2").addClass("hiding").prop('aria-hidden', true); 
  $("#search-toggle #search-toggle2").addClass("hiding").prop('aria-hidden', true); 
  $("#facet-toggle #filter-toggle2").addClass("hiding").prop('aria-hidden', true);   

	// WVU MENU TOGGLE 
	// ===================================================================================
	$("#wvutoggle").click(function(e) {		
		// Must have prevent default to work with new rails
		e.preventDefault(); 
		// Aria Roles 
		accessible_toggler($('#wvutoggle'))
		// Toggling and Asethics 
		$(".list").slideToggle("fast");
		$("#wvutoggle .fa-chevron-up").toggleClass("hiding");
		$("#wvutoggle .fa-chevron-down").toggleClass("hiding");
	});

	// WVRHC MENU TOGGLES 
	// ===================================================================================
	$("#wvrhctoggle").click(function(e){
		e.preventDefault(); 		
		// Aria Roles 
		accessible_toggler($('#wvrhctoggle'))
		// Toggling 
		$(".list2").slideToggle("fast");
		$("#wvrhctoggle .fa-chevron-up").toggleClass("hiding");
		$("#wvrhctoggle .fa-chevron-down").toggleClass("hiding");
	});

	// MENU
	// ===================================================================================
	$("#menu-toggle").click(function(e) {
		e.preventDefault();
		// Aria Roles 
		accessible_toggler($('#menu-toggle')) 
		// Other Toggles		
		$("#sticky-header-nav-menu").toggleClass("tabbarToggle");
		$(".sticky-header-nav").toggleClass("tabbarBlue");
		$("#menu-toggle #menu-toggle1").toggleClass("hiding");
		$("#menu-toggle #menu-toggle2").toggleClass("hiding");

		$(".search-query-form").removeClass("tabbarToggle");
		$(".search-query-form").removeClass("tabbarToggleSearch");
		$(".sticky-header-search").removeClass("tabbarBlue");
		$("#search-toggle #search-toggle1").removeClass("hiding");
		$("#search-toggle #search-toggle2").addClass("hiding");	

		$(".sticky-header-filter-sidebar").removeClass("tabbarToggle2");
		$(".sticky-header-filter").removeClass("tabbarBlue");
		$("#facet-toggle #filter-toggle1").removeClass("hiding");
		$("#facet-toggle #filter-toggle2").addClass("hiding");	
	});

	// Search
	// ===================================================================================
	$("#search-toggle").click(function(e) {
		e.preventDefault();
		// Aria Roles 
		accessible_toggler($('#search-toggle')) 
		// Other Toggles		 		
		$(".search-query-form").toggleClass("tabbarToggle");
		$(".search-query-form").toggleClass("tabbarToggleSearch");
		$(".sticky-header-search").toggleClass("tabbarBlue");
		$("#search-toggle #search-toggle1").toggleClass("hiding");
		$("#search-toggle #search-toggle2").toggleClass("hiding");

		$("#sticky-header-nav-menu").removeClass("tabbarToggle");
		$(".sticky-header-nav").removeClass("tabbarBlue");
		$("#menu-toggle #menu-toggle1").removeClass("hiding");
		$("#menu-toggle #menu-toggle2").addClass("hiding");

		$(".sticky-header-filter-sidebar").removeClass("tabbarToggle2");
		$(".sticky-header-filter").removeClass("tabbarBlue");
		$("#facet-toggle #filter-toggle1").removeClass("hiding");
		$("#facet-toggle #filter-toggle2").addClass("hiding");		
	});

	// Facet Toggles
	// ===================================================================================
	$("#facet-toggle").click(function(e) {		
		e.preventDefault();
		// Aria Roles 
		accessible_toggler($('#facet-toggle')) 
		// Other Toggles		 
		$(".sticky-header-filter-sidebar").toggleClass("tabbarToggle2");
		$(".sticky-header-filter-sidebar").toggleClass("tabbarToggleSearch");
		$(".sticky-header-filter").toggleClass("tabbarBlue");
		$("#facet-toggle #filter-toggle1").toggleClass("hiding");
		$("#facet-toggle #filter-toggle2").toggleClass("hiding");

		$("#sticky-header-nav-menu").removeClass("tabbarToggle");
		$(".sticky-header-nav").removeClass("tabbarBlue");
		$("#menu-toggle #menu-toggle1").removeClass("hiding");
		$("#menu-toggle #menu-toggle2").addClass("hiding");

		$(".search-query-form").removeClass("tabbarToggle");
		$(".search-query-form").removeClass("tabbarToggleSearch");
		$(".sticky-header-search").removeClass("tabbarBlue");
		$("#search-toggle #search-toggle1").removeClass("hiding");
		$("#search-toggle #search-toggle2").addClass("hiding");			
	});
});


// Accessability toggle 
// ===================================================================================
var accessible_toggler = function($elm){ 
	// If element doesn't exist, add it.  
	if (!$elm[0].hasAttribute('aria-expanded')) {
		$elm.attr('aria-expanded', 'false')
	}

	// get the label to test it 
	var aria_label = $elm.attr('aria-expanded'); 

	// test the condition and change it based on the
	if(aria_label == 'false'){ 
		$elm.attr('aria-expanded', 'true')
	} else { 
		$elm.attr('aria-expanded', 'false')
	}
};