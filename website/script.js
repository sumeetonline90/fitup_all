// =========================================================
// Footer year
// =========================================================
document.getElementById('year').textContent = new Date().getFullYear();

// =========================================================
// Smooth-scroll for nav anchors
// =========================================================
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

// =========================================================
// Reveal-on-scroll via IntersectionObserver
// =========================================================
var io = new IntersectionObserver(function (entries) {
  entries.forEach(function (entry) {
    if (entry.isIntersecting) {
      entry.target.classList.add('in');
      io.unobserve(entry.target);
    }
  });
}, { threshold: 0.12, rootMargin: '0px 0px -60px 0px' });

document.querySelectorAll('.reveal').forEach(function (el) {
  io.observe(el);
});

// =========================================================
// Cursor glow follows mouse
// =========================================================
var cursorGlow = document.getElementById('cursorGlow');
if (cursorGlow && window.matchMedia('(hover: hover)').matches) {
  var mx = window.innerWidth / 2, my = window.innerHeight / 2;
  var cx = mx, cy = my;
  window.addEventListener('mousemove', function (e) {
    mx = e.clientX;
    my = e.clientY;
  }, { passive: true });
  function tick() {
    cx += (mx - cx) * 0.08;
    cy += (my - cy) * 0.08;
    cursorGlow.style.transform = 'translate(' + (cx - 300) + 'px, ' + (cy - 300) + 'px)';
    requestAnimationFrame(tick);
  }
  tick();
}

// =========================================================
// Animated counters in the hero stats
// =========================================================
var counters = document.querySelectorAll('[data-count]');
var counterIO = new IntersectionObserver(function (entries) {
  entries.forEach(function (entry) {
    if (!entry.isIntersecting) return;
    var el = entry.target;
    var target = parseInt(el.dataset.count, 10);
    var suffix = el.dataset.suffix || '';
    var duration = 1400;
    var start = performance.now();
    function update(now) {
      var t = Math.min((now - start) / duration, 1);
      // easeOutCubic
      var eased = 1 - Math.pow(1 - t, 3);
      el.textContent = Math.round(target * eased) + suffix;
      if (t < 1) requestAnimationFrame(update);
    }
    requestAnimationFrame(update);
    counterIO.unobserve(el);
  });
}, { threshold: 0.5 });
counters.forEach(function (c) { counterIO.observe(c); });

// =========================================================
// AI chat — typewriter effect, triggered on scroll-in
// =========================================================
function typeBubble(bubble, onDone) {
  var text = bubble.dataset.typed;
  var typing = bubble.querySelector('.typing');
  // brief delay so the dots are visible first
  setTimeout(function () {
    if (typing) typing.remove();
    var i = 0;
    function step() {
      if (i <= text.length) {
        bubble.textContent = text.slice(0, i);
        i++;
        var delay = 18 + Math.random() * 22;
        setTimeout(step, delay);
      } else if (onDone) {
        onDone();
      }
    }
    step();
  }, 900);
}

var aiThread = document.getElementById('aiThread');
if (aiThread) {
  var aiIO = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      var bubbles = aiThread.querySelectorAll('.bubble-ai[data-typed]');
      var first = bubbles[0];
      var second = bubbles[1];
      typeBubble(first, function () {
        if (second) {
          second.classList.remove('bubble-pending');
          typeBubble(second);
        }
      });
      aiIO.unobserve(aiThread);
    });
  }, { threshold: 0.4 });
  aiIO.observe(aiThread);
}

// =========================================================
// Module-card 3D tilt on hover (desktop only)
// =========================================================
if (window.matchMedia('(hover: hover)').matches) {
  document.querySelectorAll('.module-card').forEach(function (card) {
    card.addEventListener('mousemove', function (e) {
      var rect = card.getBoundingClientRect();
      var x = (e.clientX - rect.left) / rect.width;
      var y = (e.clientY - rect.top) / rect.height;
      var rx = (y - 0.5) * -6;
      var ry = (x - 0.5) * 6;
      card.style.transform = 'perspective(1000px) rotateX(' + rx + 'deg) rotateY(' + ry + 'deg) translateY(-6px)';
    });
    card.addEventListener('mouseleave', function () {
      card.style.transform = '';
    });
  });
}

// =========================================================
// Subtle parallax on hero floaters
// =========================================================
var floaters = document.querySelectorAll('.floater');
if (floaters.length && window.matchMedia('(hover: hover)').matches) {
  window.addEventListener('scroll', function () {
    var y = window.scrollY;
    floaters.forEach(function (f, i) {
      var speed = (i + 1) * 0.04;
      f.style.transform = 'translateY(' + (y * speed) + 'px)';
    });
  }, { passive: true });
}
