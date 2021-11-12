// Handle the logic for switching the location of the facets on the page
$(function(){
  facetfun = $('#sidebar').html();
});

var facetLogic = function(){ 
  // get items for making things "sticky"
  var windowh = document.documentElement.clientHeight;
	var tabbar = $('.sticky-header').height();
	var fheight = windowh - tabbar;
    
  // set a max height 
  $('.sticky-header-filter-sidebar').css('max-height', fheight); 

  // remove the facets html so it can be placed in whichever place it needs 
	$('#facets').remove();

  // determine where to place the facets 
  if( $(window).width() < 768) {
    $('.sticky-header-filter-sidebar').html(facetfun);
  }
  else { 
    $('#sidebar').html(facetfun);
  }
  
	$(".sticky-header-filter-sidebar #facets #facet-panel-collapse").removeClass("collapse");
}

// Mobile Facet Move
$(window).bind("load resize", facetLogic);