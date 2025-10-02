document.addEventListener('DOMContentLoaded', function () {
    var el = document.querySelector('#featuredCarousel');
    if (!el) return;
  
    var minPerSlide = 3;
    var items = el.querySelectorAll('.carousel-item');
  
    items.forEach(function (item) {
      var next = item.nextElementSibling;
      for (var i = 1; i < minPerSlide; i++) {
        if (!next) next = items[0];
        item.appendChild(next.firstElementChild.cloneNode(true));
        next = next.nextElementSibling;
      }
    });
  });
  