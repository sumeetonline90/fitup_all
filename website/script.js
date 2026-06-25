// Year in footer
document.getElementById('year').textContent = new Date().getFullYear();

// Smooth scroll for nav anchors
document.querySelectorAll('a[href^="#"]').forEach(function (link) {
  link.addEventListener('click', function (e) {
    var id = link.getAttribute('href');
    if (id.length <= 1) return;
    var el = document.querySelector(id);
    if (!el) return;
    e.preventDefault();
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });
});

// Parallax on bg glows
var glows = document.querySelectorAll('.bg-glow');
window.addEventListener('scroll', function () {
  var y = window.scrollY;
  glows.forEach(function (g, i) {
    var speed = (i + 1) * 0.05;
    g.style.transform = 'translateY(' + (y * speed) + 'px)';
  });
}, { passive: true });
