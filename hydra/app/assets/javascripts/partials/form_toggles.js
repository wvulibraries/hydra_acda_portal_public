// Document Ready 
// ===================================================================================
$(function () {
    $('.prints').hide(); 
    $('.digital').hide(); 
    
  	$(".print-toggle").click(function(e) {
      e.preventDefault(); 
      $('.prints').show(); 
      $('.digital').hide(); 
    });

   	$(".digital-toggle").click(function(e) {
      e.preventDefault(); 
      $('.prints').hide(); 
      $('.digital').show(); 
    });
}); 