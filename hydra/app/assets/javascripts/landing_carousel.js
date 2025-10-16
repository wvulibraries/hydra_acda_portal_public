document.addEventListener('DOMContentLoaded', function () {
    // Carousel functionality
    const track = document.querySelector('.carousel-track');
    const slides = Array.from(document.querySelectorAll('.carousel-slide'));
    const prevButton = document.querySelector('.carousel-nav-prev');
    const nextButton = document.querySelector('.carousel-nav-next');
    
    if (track && slides.length > 0 && prevButton && nextButton) {
      let currentIndex = 0;
      
      function getSlidesPerView() {
        return window.innerWidth >= 768 ? 3 : 1;
      }
      
      let slidesPerView = getSlidesPerView();
      
      function updateCarousel() {
        const containerWidth = track.parentElement.offsetWidth;
        const gap = 24;
        
        let slideWidth;
        if (slidesPerView === 1) {
          slideWidth = containerWidth;
        } else {
          slideWidth = (containerWidth - (gap * (slidesPerView - 1))) / slidesPerView;
        }
        
        const moveAmount = -(currentIndex * (slideWidth + gap));
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
        e.preventDefault();
        e.stopPropagation();
        if (currentIndex > 0) {
          currentIndex--;
          updateCarousel();
        }
      });
      
      nextButton.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        const maxIndex = Math.max(0, slides.length - slidesPerView);
        if (currentIndex < maxIndex) {
          currentIndex++;
          updateCarousel();
        }
      });
      
      updateCarousel();
      
      window.addEventListener('load', function() {
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
    }
    
    // Navbar toggle functionality - hidden by default
    const navbar = document.getElementById('site-navbar');
    const heroSearchButton = document.querySelector('.hero-bleed .btn');
    
    if (navbar && heroSearchButton) {
      // Hide navbar on page load
      navbar.classList.add('navbar-hidden');
      
      heroSearchButton.addEventListener('click', function(e) {
        e.preventDefault();
        navbar.classList.toggle('navbar-hidden');
      });
    }
  });