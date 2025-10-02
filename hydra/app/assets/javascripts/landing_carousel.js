document.addEventListener('DOMContentLoaded', function () {
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
  