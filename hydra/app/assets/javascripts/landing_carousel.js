document.addEventListener('DOMContentLoaded', function () {
  // Vimeo player for hero video - wait for API to load
  function initVimeoPlayer() {
    var iframe = document.getElementById('hero-vimeo-player');
    if (iframe && typeof Vimeo !== 'undefined') {
      var player = new Vimeo.Player(iframe);
      var heroContent = document.getElementById('hero-content');
      var heroOverlay = document.querySelector('.hero-overlay');
      
      console.log('Vimeo player initialized');
      
      player.on('play', function() {
        console.log('Video playing');
        if (heroContent) heroContent.classList.add('fade-out');
        if (heroOverlay) heroOverlay.classList.add('fade-out');
      });
      
      player.on('pause', function() {
        console.log('Video paused');
        if (heroContent) heroContent.classList.remove('fade-out');
        if (heroOverlay) heroOverlay.classList.remove('fade-out');
      });
      
      player.on('ended', function() {
        console.log('Video ended');
        if (heroContent) heroContent.classList.remove('fade-out');
        if (heroOverlay) heroOverlay.classList.remove('fade-out');
      });
    } else {
      console.log('Vimeo API not ready, retrying...');
      setTimeout(initVimeoPlayer, 100);
    }
  }
  
  // Check if Vimeo script exists and initialize
  if (document.getElementById('hero-vimeo-player')) {
    if (typeof Vimeo !== 'undefined') {
      initVimeoPlayer();
    } else {
      // Wait for Vimeo API to load
      window.addEventListener('load', function() {
        setTimeout(initVimeoPlayer, 500);
      });
    }
  }
  
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
  
  // Navbar toggle functionality - hidden by default ONLY on landing page
  const navbar = document.getElementById('site-navbar');
  const heroSearchButton = document.querySelector('.hero-bleed .btn');
  const hamburgerToggle = document.getElementById('navbar-hamburger-toggle');
  const isLandingPage = document.querySelector('.hero-bleed') !== null;
  
  if (navbar) {
    // Hide navbar on page load ONLY if on landing page
    // Only hide navbar on landing page for desktop, always show on mobile
    if (isLandingPage && window.innerWidth > 767) {
      navbar.classList.add('navbar-hidden');
    }
    
    // Toggle function
    function toggleNavbar(e) {
      e.preventDefault();
      navbar.classList.toggle('navbar-hidden');
      
      // Toggle hamburger icon animation
      if (hamburgerToggle) {
        hamburgerToggle.classList.toggle('active');
      }
    }
    
    // Hero search button toggle (only exists on landing page)
    if (heroSearchButton) {
      heroSearchButton.addEventListener('click', toggleNavbar);
    }
    
    // Hamburger menu toggle
    if (hamburgerToggle) {
      hamburgerToggle.addEventListener('click', toggleNavbar);
    }
  }
});