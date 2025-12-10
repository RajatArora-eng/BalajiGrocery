<%@ page contentType="text/html;charset=UTF-8" %>

<!-- Tailwind + jQuery -->
<script src="https://cdn.tailwindcss.com"></script>
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>

<header class="bg-green-700 text-white sticky top-0 z-50 shadow">
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
    <div class="flex items-center justify-between py-3">

      <!-- Logo + Name -->
      <div class="flex items-center gap-3">
        <img src="<%=request.getContextPath()%>/assets/logo.png"
             alt="Logo"
             class="h-10 w-10 rounded-md object-cover"/>

        <div class="leading-tight">
          <div class="text-lg font-bold">Balaji Grocery</div>
          <div class="text-xs text-white/80">Freshness delivered</div>
        </div>
      </div>

      <!-- Search + Links -->
      <div class="flex items-center gap-6">

        <!-- Search -->
        <div class="hidden md:block">
          <input id="global-search"
                 type="search"
                 placeholder="Search products..."
                 class="px-3 py-2 rounded-lg border w-64 text-black focus:outline-none" />
        </div>

        <!-- Cart + Login -->
        <div class="flex items-center gap-4">

          <!-- Cart -->
          <a href="<%=request.getContextPath()%>/cart.jsp"
             class="flex items-center gap-1 hover:text-yellow-300">
            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                    d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5 21h14" />
            </svg>
            <span id="cart-count" class="font-medium">0</span>
          </a>

          <!-- Login -->
          <a href="<%=request.getContextPath()%>/login.jsp"
             class="hover:text-yellow-300">Login</a>
        </div>
        <!-- Home -->
          <a href="<%=request.getContextPath()%>/index.jsp"
             class="hover:text-yellow-300">Home</a>
        </div>
      </div>

    </div>
  </div>
</header>

<script>
// update cart count (if servlet available)
function loadCartCount(){
  $.ajax({
    url: "<%=request.getContextPath()%>/CartCountServlet",
    method: "GET",
    success: function(cnt){
      try{
        let n = JSON.parse(cnt);
        $("#cart-count").text(n.count || 0);
      }catch(e){
        $("#cart-count").text(cnt || 0);
      }
    }
  });
}

$(function(){
  loadCartCount();
});
</script>
