document.addEventListener('DOMContentLoaded', function () {
    var nav = document.getElementById('site-navbar');
    var heroBtn = document.getElementById('hero-reveal-nav');
    if (nav && heroBtn) {
      nav.classList.add('nav-hidden');
      heroBtn.addEventListener('click', function (e) {
        e.preventDefault();
        nav.classList.remove('nav-hidden');
        var navInput = nav.querySelector("input[name='q'], #search_q, input[type='search']");
        if (navInput) navInput.focus();
        window.scrollTo({ top: 0, behavior: 'smooth' });
      });
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
  
    try { new bootstrap.Carousel(el, { interval: false, wrap: true }); } catch (e) {}
  });
  