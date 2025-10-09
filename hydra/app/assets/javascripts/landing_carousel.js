document.addEventListener('DOMContentLoaded', function () {
    const track = document.querySelector('.carousel-track');
    const slides = Array.from(track.children);
    const prevButton = document.querySelector('.carousel-nav-prev');
    const nextButton = document.querySelector('.carousel-nav-next');
    
    if (!track || slides.length === 0) return;
    
    let currentIndex = 0;
    let slidesPerView = window.innerWidth >= 768 ? 3 : 1;
    
    // Update slides per view on resize
    window.addEventListener('resize', function() {
      const newSlidesPerView = window.innerWidth >= 768 ? 3 : 1;
      if (newSlidesPerView !== slidesPerView) {
        slidesPerView = newSlidesPerView;
        updateCarousel();
      }
    });
    
    function updateCarousel() {
      const slideWidth = slides[0].getBoundingClientRect().width;
      const gap = 24; // 1.5rem in pixels
      const moveAmount = -(currentIndex * (slideWidth + gap));
      track.style.transform = `translateX(${moveAmount}px)`;
      
      // Update button states
      prevButton.disabled = currentIndex === 0;
      nextButton.disabled = currentIndex >= slides.length - slidesPerView;
      
      prevButton.style.opacity = prevButton.disabled ? '0.5' : '1';
      nextButton.style.opacity = nextButton.disabled ? '0.5' : '1';
      prevButton.style.cursor = prevButton.disabled ? 'not-allowed' : 'pointer';
      nextButton.style.cursor = nextButton.disabled ? 'not-allowed' : 'pointer';
    }
    
    prevButton.addEventListener('click', function() {
      if (currentIndex > 0) {
        currentIndex--;
        updateCarousel();
      }
    });
    
    nextButton.addEventListener('click', function() {
      if (currentIndex < slides.length - slidesPerView) {
        currentIndex++;
        updateCarousel();
      }
    });
    
    // Initial setup
    updateCarousel();
  });