document.addEventListener('DOMContentLoaded', function () {
  // YouTube API for hero video
  var tag = document.createElement('script');
  tag.src = "https://www.youtube.com/iframe_api";
  var firstScriptTag = document.getElementsByTagName('script')[0];
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
  
  var player;
  window.onYouTubeIframeAPIReady = function() {
    player = new YT.Player('hero-video-player', {
      events: {
        'onStateChange': onPlayerStateChange
      }
    });
  };
  
  function onPlayerStateChange(event) {
    var heroContent = document.getElementById('hero-content');
    var heroOverlay = document.querySelector('.hero-overlay');
    
    // When video starts playing (state 1)
    if (event.data == YT.PlayerState.PLAYING) {
      if (heroContent) heroContent.classList.add('fade-out');
      if (heroOverlay) heroOverlay.classList.add('fade-out');
    }
    // When video is paused or ended (state 2 or 0)
    else if (event.data == YT.PlayerState.PAUSED || event.data == YT.PlayerState.ENDED) {
      if (heroContent) heroContent.classList.remove('fade-out');
      if (heroOverlay) heroOverlay.classList.remove('fade-out');
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
    if (isLandingPage) {
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