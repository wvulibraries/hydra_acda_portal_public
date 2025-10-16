document.addEventListener('DOMContentLoaded', function () {
    console.log('Carousel script loaded');
    
    const track = document.querySelector('.carousel-track');
    const slides = Array.from(document.querySelectorAll('.carousel-slide'));
    const prevButton = document.querySelector('.carousel-nav-prev');
    const nextButton = document.querySelector('.carousel-nav-next');
    
    console.log('Track:', track);
    console.log('Slides:', slides);
    console.log('Prev button:', prevButton);
    console.log('Next button:', nextButton);
    
    if (!track || slides.length === 0 || !prevButton || !nextButton) {
      console.error('Missing carousel elements!');
      return;
    }
    
    let currentIndex = 0;
    
    function getSlidesPerView() {
      return window.innerWidth >= 768 ? 3 : 1;
    }
    
    let slidesPerView = getSlidesPerView();
    
    function updateCarousel() {
      console.log('Updating carousel, currentIndex:', currentIndex);
      
      const containerWidth = track.parentElement.offsetWidth;
      const gap = 24;
      
      let slideWidth;
      if (slidesPerView === 1) {
        slideWidth = containerWidth;
      } else {
        slideWidth = (containerWidth - (gap * (slidesPerView - 1))) / slidesPerView;
      }
      
      const moveAmount = -(currentIndex * (slideWidth + gap));
      console.log('Moving to:', moveAmount + 'px');
      track.style.transform = `translateX(${moveAmount}px)`;
      
      const maxIndex = Math.max(0, slides.length - slidesPerView);
      prevButton.disabled = currentIndex === 0;
      nextButton.disabled = currentIndex >= maxIndex;
      
      prevButton.style.opacity = prevButton.disabled ? '0.5' : '1';
      nextButton.style.opacity = nextButton.disabled ? '0.5' : '1';
      prevButton.style.cursor = prevButton.disabled ? 'not-allowed' : 'pointer';
      nextButton.style.cursor = nextButton.disabled ? 'not-allowed' : 'pointer';
    }
    
    prevButton.addEventListener('click', function(e) {
      console.log('Prev button clicked');
      e.preventDefault();
      e.stopPropagation();
      if (currentIndex > 0) {
        currentIndex--;
        updateCarousel();
      }
    });
    
    nextButton.addEventListener('click', function(e) {
      console.log('Next button clicked');
      e.preventDefault();
      e.stopPropagation();
      const maxIndex = Math.max(0, slides.length - slidesPerView);
      if (currentIndex < maxIndex) {
        currentIndex++;
        updateCarousel();
      }
    });
    
    // Initial setup
    console.log('Initial carousel setup');
    updateCarousel();
    
    window.addEventListener('load', function() {
      console.log('Window loaded, updating carousel');
      updateCarousel();
    });
    
    let resizeTimeout;
    window.addEventListener('resize', function() {
      clearTimeout(resizeTimeout);
      resizeTimeout = setTimeout(function() {
        const newSlidesPerView = getSlidesPerView();
        if (newSlidesPerView !== slidesPerView) {
          slidesPerView = newSlidesPerView;
          currentIndex = 0;
          updateCarousel();
        }
      }, 250);
    });
  });