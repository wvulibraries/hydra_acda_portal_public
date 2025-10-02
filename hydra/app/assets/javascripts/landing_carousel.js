// app/assets/javascripts/landing_carousel.js
//= require bootstrap   // ensure bootstrap is available before this runs

document.addEventListener('DOMContentLoaded', function () {
    var carouselEl = document.querySelector('#featuredCarousel');
    if (!carouselEl) return;
  
    // On md+ we want 3 cards visible per slide.
    var minPerSlide = 3;
    var items = carouselEl.querySelectorAll('.carousel-item');
  
    items.forEach(function (el) {
      var next = el.nextElementSibling;
      for (var i = 1; i < minPerSlide; i++) {
        if (!next) {
          // wrap to start
          next = items[0];
        }
        // Clone the next card column into this slide
        el.appendChild(next.firstElementChild.cloneNode(true));
        next = next.nextElementSibling;
      }
    });
  
    // Optional: don’t auto-advance
    // new bootstrap.Carousel(carouselEl, { interval: false });
  });
  