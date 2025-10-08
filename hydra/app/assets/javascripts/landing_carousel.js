document.addEventListener('DOMContentLoaded', function () {
    var hero = document.querySelector('.hero-bleed');
    var nav = document.getElementById('site-navbar');
    if (hero && nav) nav.classList.add('nav-hidden');
  
    var heroSearch = document.getElementById('hero-search');
    function revealNav() {
      if (!nav) return;
      nav.classList.remove('nav-hidden');
      heroSearch && heroSearch.removeEventListener('click', revealNav);
      heroSearch && heroSearch.removeEventListener('focusin', revealNav);
      var form = heroSearch ? heroSearch.querySelector('form') : null;
      form && form.removeEventListener('submit', revealNav);
    }
    if (heroSearch) {
      heroSearch.addEventListener('click', revealNav);
      heroSearch.addEventListener('focusin', revealNav);
      var form = heroSearch.querySelector('form');
      form && form.addEventListener('submit', revealNav);
    }
  
    var el = document.getElementById('featuredCarousel');
    if (!el || el.dataset.prepared) return;
    el.dataset.prepared = 'true';
  
    var minPerSlide = 3;
    var items = el.querySelectorAll('.carousel-item');
    items.forEach(function (item) {
      var next = item.nextElementSibling || items[0];
      for (var i = 1; i < minPerSlide; i++) {
        var col = next.querySelector('.col-md-4');
        if (col) item.appendChild(col.cloneNode(true));
        next = next.nextElementSibling || items[0];
      }
    });
  
    try { new bootstrap.Carousel(el, { interval: false, wrap: true }); } catch(e) {}
  });
  