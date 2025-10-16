document.addEventListener('DOMContentLoaded', function () {
    const track = document.querySelector('.carousel-track');
    const slides = Array.from(document.querySelectorAll('.carousel-slide'));
    const prevButton = document.querySelector('.carousel-nav-prev');
    const nextButton = document.querySelector('.carousel-nav-next');
    
    if (!track || slides.length === 0 || !prevButton || !nextButton) return;
    
    let currentIndex = 0;
    
    function getSlidesPerView() {
      return window.innerWidth >= 768 ? 3 : 1;
    }
    
    let slidesPerView = getSlidesPerView();
    
    // Update slides per view on resize
    let resizeTimeout;
    window.addEventListener('resize', function() {
      clearTimeout(resizeTimeout);
      resizeTimeout = setTimeout(function() {
        const newSlidesPerView = getSlidesPerView();
        if (newSlidesPerView !== slidesPerView) {
          slidesPerView = newSlidesPerView;
          currentIndex = 0; // Reset to start on resize
          updateCarousel();
        }
      }, 250);
    });
    
    function updateCarousel() {
      const containerWidth = track.parentElement.offsetWidth;
      const gap = 24; // 1.5rem = 24px
      
      // Calculate slide width based on container and gaps
      let slideWidth;
      if (slidesPerView === 1) {
        slideWidth = containerWidth;
      } else {
        // For 3 slides: total width - (2 gaps) = usable width, divided by 3
        slideWidth = (containerWidth - (gap * (slidesPerView - 1))) / slidesPerView;
      }
      
      // Move by one slide width plus one gap
      const moveAmount = -(currentIndex * (slideWidth + gap));
      track.style.transform = `translateX(${moveAmount}px)`;
      
      // Update button states
      const maxIndex = Math.max(0, slides.length - slidesPerView);
      prevButton.disabled = currentIndex === 0;
      nextButton.disabled = currentIndex >= maxIndex;
      
      prevButton.style.opacity = prevButton.disabled ? '0.5' : '1';
      nextButton.style.opacity = nextButton.disabled ? '0.5' : '1';
      prevButton.style.cursor = prevButton.disabled ? 'not-allowed' : 'pointer';
      nextButton.style.cursor = nextButton.disabled ? 'not-allowed' : 'pointer';
    }
    
    prevButton.addEventListener('click', function(e) {
      e.preventDefault();
      if (currentIndex > 0) {
        currentIndex--;
        updateCarousel();
      }
    });
    
    nextButton.addEventListener('click', function(e) {
      e.preventDefault();
      const maxIndex = Math.max(0, slides.length - slidesPerView);
      if (currentIndex < maxIndex) {
        currentIndex++;
        updateCarousel();
      }
    });
    
    // Initial setup
    updateCarousel();
    
    // Update on window load to ensure correct measurements
    window.addEventListener('load', updateCarousel);
  });