var equalheight = function(container){

	var currentTallest = 0,
	currentRowStart    = 0,
	rowDivs            = new Array(),
	$el,
	topPosition        = 0;

	$(container).each(function() {

		$el = $(this);
		$($el).height('auto')
		topPostion = $el.position().top;

    if (currentRowStart != topPostion) {
      for (currentDiv = 0 ; currentDiv < rowDivs.length ; currentDiv++) {
        rowDivs[currentDiv].height(currentTallest);
      }
      rowDivs.length  = 0; // empty the array
      currentRowStart = topPostion;
      currentTallest  = $el.height();
      rowDivs.push($el);
    } 
    else {
      rowDivs.push($el);
      currentTallest = (currentTallest < $el.height()) ? ($el.height()) : (currentTallest);
    }

    for (currentDiv = 0 ; currentDiv < rowDivs.length ; currentDiv++) {
      rowDivs[currentDiv].height(currentTallest);
    }
    });
}

  $(window).bind('load resize', function(e) {
    // do the initial equal heights on load, but images may not be included
    if($('.document').length){ 
      equalheight('.document');
    }

    if($('.form-section').length){ 
       equalheight('.form-section');
    }
  });

  $(document).on("turbolinks:load", function() {
    setTimeout(function(){ 
      $(window).trigger('resize');
    }, 3000);
  });