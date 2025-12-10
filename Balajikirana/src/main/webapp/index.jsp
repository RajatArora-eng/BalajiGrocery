<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Balaji Grocery - Home</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://unpkg.com/tailwindcss@^2.2.19/dist/tailwind.min.css" onerror="console.warn('Tailwind fallback failed')">
  <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

  <style>
    .fade-card { opacity:0; transform: translateY(18px); transition: all .45s cubic-bezier(.2,.9,.3,1); }
    .fade-card.show { opacity:1; transform: translateY(0); }

    .hero-slide { 
      position:absolute; inset:0; 
      background-size:cover; 
      background-position:center; 
      opacity:0; 
      transform:scale(1.05);
      transition:opacity .7s ease, transform .7s ease; 
    }
    .hero-slide.active { opacity:1; transform:scale(1); }

    .dot {
      width:10px; height:10px;
      background:#ccc; 
      border-radius:50%;
      cursor:pointer;
    }
    .dot.active { background:#16a34a; }
  </style>
</head>
<body class="bg-gray-50 text-gray-800">

<!-- NAVBAR -->
<header class="bg-green-700 text-white p-4 sticky top-0 z-50">
  <div class="max-w-7xl mx-auto flex justify-between items-center">
    <div class="flex items-center gap-3">
      <img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQeG0lJUCy0vpQicYdylROhLu-lUOXbN1cinuc-eHGcmJZD5K0zsPJ5eZtetbjjT7-VFcI&usqp=CAU" alt="logo" class="h-12 w-12 rounded" />
      <div>
        <div class="text-lg font-bold">Balaji Grocery</div>
        <div class="text-xs text-white/80">Freshness delivered</div>
      </div>
    </div>

    <div class="flex items-center gap-6">
      <div class="hidden sm:block">
        <input id="global-search" type="search" placeholder="Search products..." class="px-3 py-2 rounded-lg border w-64 focus:outline-none"/>
      </div>
      <div class="flex items-center gap-4">
        <a href="<%= request.getContextPath() %>/cart.jsp" class="flex items-center gap-2 text-white no-select">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none"
               viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round"
               stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13l-1.5 7H19"/></svg>
          <span id="cart-count" class="font-medium">0</span>
        </a>
        <a href="<%= request.getContextPath() %>/login.jsp" class="text-sm text-white">Login</a>
      </div>
    </div>
  </div>
</header>

<!-- HERO SLIDER -->
<section class="relative h-[320px] sm:h-[450px] md:h-[520px] overflow-hidden">
  <div id="hero" class="relative w-full h-full"></div>

  <!-- Dots -->
  <div id="hero-dots" class="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-3"></div>
</section>

<main class="max-w-7xl mx-auto px-4 mt-8">
  <section>
    <h2 class="text-2xl font-semibold mb-4">Shop by category</h2>
    <div id="category-container" class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-6">
      <div class="h-36 rounded-lg bg-white shadow animate-pulse"></div>
      <div class="h-36 rounded-lg bg-white shadow animate-pulse"></div>
      <div class="h-36 rounded-lg bg-white shadow animate-pulse"></div>
      <div class="h-36 rounded-lg bg-white shadow animate-pulse"></div>
    </div>
  </section>

  <section class="mt-10">
    <div class="flex justify-between items-center">
      <h2 class="text-2xl font-semibold">Popular products</h2>
      <select id="sort-select" class="px-2 py-1 rounded border text-sm">
        <option value="popular">Popular</option>
        <option value="price_asc">Price: Low to High</option>
        <option value="price_desc">Price: High to Low</option>
      </select>
    </div>

    <div id="product-container" class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-6 mt-5">
      <div class="h-72 rounded-lg bg-white shadow animate-pulse"></div>
      <div class="h-72 rounded-lg bg-white shadow animate-pulse"></div>
      <div class="h-72 rounded-lg bg-white shadow animate-pulse"></div>
      <div class="h-72 rounded-lg bg-white shadow animate-pulse"></div>
    </div>
  </section>
</main>

<footer class="mt-14 bg-white border-t text-center py-6">
  <div class="text-sm text-gray-600">© 2025 Balaji Grocery</div>
</footer>

<!-- SCRIPT -->
<script>
(function($){
  'use strict';

  /* ---------------- HERO SLIDER ---------------- */
  var slides = [
    { image: "https://images.unsplash.com/photo-1587132137056-bfbf0166836e?auto=format&fit=crop&w=1000&q=80" },
    { image: "https://images.unsplash.com/photo-1584270354949-3aa5b2b3d7c6?auto=format&fit=crop&w=1000&q=80" },
    { image: "https://images.unsplash.com/photo-1514996937319-344454492b37?auto=format&fit=crop&w=1000&q=80" }
  ];

  function buildHeroSlides(){
    var $hero = $('#hero').empty();
    slides.forEach((s,i)=>{
      var slide = $('<div class="hero-slide"></div>').css('background-image','url('+s.image+')');
      if(i===0) slide.addClass('active');
      $hero.append(slide);
    });

    var $dots = $('#hero-dots').empty();
    slides.forEach((s,i)=>{
      var d = $('<div class="dot"></div>');
      if(i===0) d.addClass('active');
      d.attr('data-index', i);
      $dots.append(d);
    });
  }

  var current = 0;
  function nextSlide(){
    var total = slides.length;
    $('#hero .hero-slide').removeClass('active').eq(current).removeClass('active');
    $('#hero-dots .dot').removeClass('active').eq(current).removeClass('active');

    current = (current + 1) % total;

    $('#hero .hero-slide').eq(current).addClass('active');
    $('#hero-dots .dot').eq(current).addClass('active');
  }

  setInterval(nextSlide, 4000);

  $('#hero-dots').on('click', '.dot', function(){
    current = parseInt($(this).data('index'));
    $('#hero .hero-slide').removeClass('active').eq(current).addClass('active');
    $('#hero-dots .dot').removeClass('active').eq(current).addClass('active');
  });

  buildHeroSlides();

  /* ---------------- CATEGORY + PRODUCTS (YOUR ORIGINAL WORKING CODE) ---------------- */

  function escapeHtml(str){ if(!str) return ''; return String(str).replace(/[&<>"'`=\/]/g,function(s){return({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;','/':'&#x2F;','`':'&#x60;','=':'&#x3D;'})[s];}); }

  function renderProducts(items){
    var $p = $('#product-container').empty();
    for (var i=0;i<items.length;i++){
      var it = items[i];
      var card = $(
        '<div class="bg-white rounded-lg shadow p-3 flex flex-col fade-card">' +
          '<div class="h-40 w-full overflow-hidden rounded-md"><img src="'+(it.image||'https://via.placeholder.com/400')+'" alt="'+escapeHtml(it.name)+'" class="w-full h-full object-cover"/></div>' +
          '<div class="mt-3 flex-1 flex flex-col"><h3 class="font-semibold">'+escapeHtml(it.name)+'</h3>' +
          '<p class="text-sm text-gray-500 mt-1 truncate">'+escapeHtml(it.description||'')+'</p>' +
          '<div class="mt-3 flex items-center justify-between"><div><span class="text-green-700 font-bold">₹'+(it.price||0)+'</span> <span class="line-through text-gray-400 text-sm">₹'+(it.mrp||'')+'</span></div><div class="text-xs text-gray-500">Stock: '+(it.stock||0)+'</div></div>' +
          '<div class="mt-3 grid grid-cols-2 gap-2"><button class="buy-now w-full py-2 rounded border border-green-700 text-green-700" data-id="'+it.id+'">Buy Now</button>' +
          '<button class="add-to-cart w-full py-2 rounded bg-green-700 text-white" data-id="'+it.id+'">Add to cart</button></div>' +
        '</div></div>'
      );
      (function(el,delay){ setTimeout(function(){ el.addClass('show'); }, delay); })(card, i*80);
      $p.append(card);
    }
  }

  function loadCategories(){
    return $.ajax({
      url: '<%= request.getContextPath() %>/CategoryServlet',
      method: 'GET',
      dataType: 'json',
      timeout: 7000
    })
    .done(function(data){
      var $c = $('#category-container').empty();
      data.forEach(function(cat,i){
        var card = $('<div class="bg-white rounded-lg shadow overflow-hidden cursor-pointer fade-card p-2" data-id="'+cat.id+'"><img src="'+cat.image+'" class="h-36 w-full object-cover"/><div class="p-3 text-center font-medium">'+cat.name+'</div></div>');
        (function(el,delay){ setTimeout(function(){ el.addClass('show'); }, delay); })(card, i*90);
        $c.append(card);
      });
    });
  }

  function loadProducts(sort){
    return $.ajax({
      url: '<%= request.getContextPath() %>/ProductListServlet',
      method: 'GET',
      data:{ sort: sort||'' },
      dataType:'json',
      timeout:8000
    })
    .done(function(data){
      if (Array.isArray(data) && data.length) renderProducts(data);
    });
  }

  function bindProductActions(){
    $('#product-container').on('click', '.add-to-cart', function(){
      var id = $(this).data('id');
      $.post('<%= request.getContextPath() %>/AddToCartServlet', { product_id:id, quantity:1 }, function(){}, 'json');
    });
  }

  function bindCategoryRedirect(){
    $('#category-container').on('click', '.fade-card', function(){
      var id = $(this).data('id');
      window.location.href = '<%= request.getContextPath() %>/category.jsp?cat=' + id;
    });
  }

  loadCategories().always(bindCategoryRedirect);
  loadProducts().always(bindProductActions);

})(jQuery);
/* ---------------- FIX: Add to Cart + Buy Now for POPULAR PRODUCTS ---------------- */

function bindPopularProductActions() {

  // ADD TO CART
  $('#product-container').off('click', '.add-to-cart').on('click', '.add-to-cart', function(){
    let id = $(this).data('id');
    let btn = $(this);
    btn.prop('disabled', true).text('Adding...');

    $.ajax({
      url: '<%=request.getContextPath()%>/AddToCartServlet',
      method: 'POST',
      data: { product_id: id, quantity: 1 },
      dataType: 'json',
      success: function(res){
        if (res && res.success) {

          // Update cart count
          $('#cart-count').text(res.count || 0);

          // SweetAlert
          Swal.fire({
            icon: 'success',
            title: 'Added to cart',
            toast: true,
            position: 'top-end',
            timer: 1200,
            showConfirmButton: false
          });

        } else {
          Swal.fire('Error', res.message || 'Unable to add', 'error');
        }
      },
      error: function(){
        Swal.fire('Network Error', 'Could not reach server', 'error');
      },
      complete: function(){
        btn.prop('disabled', false).text('Add to cart');
      }
    });

  });


  // BUY NOW
  $('#product-container').off('click', '.buy-now').on('click', '.buy-now', function(){
    let id = $(this).data('id');

    $.ajax({
      url: '<%=request.getContextPath()%>/AddToCartServlet',
      method: 'POST',
      data: { product_id: id, quantity: 1 },
      dataType: 'json',
      success: function(res){
        if (res && res.success) {

          Swal.fire({
            icon: 'success',
            title: 'Redirecting...',
            timer: 800,
            showConfirmButton: false
          });

          setTimeout(() => {
            window.location.href = '<%=request.getContextPath()%>/checkout.jsp';
          }, 800);

        } else {
          Swal.fire('Error', res.message || 'Unable to process', 'error');
        }
      },
      error: function(){
        Swal.fire('Network Error', 'Could not reach server', 'error');
      }
    });

  });
}

/* Automatically bind when products load */
bindPopularProductActions();

/* Rebind after category filter / sort / search updates products */
$(document).ajaxComplete(function(){
  bindPopularProductActions();
});

</script>

</body>
</html>
