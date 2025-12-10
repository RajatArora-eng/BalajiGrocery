<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Ensure catId is defined at top-level so JSP expressions can use it safely.
    String catId = request.getParameter("cat");
    if (catId == null || catId.trim().isEmpty()) catId = "0";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Category Products</title>

    <!-- Tailwind + jQuery -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>

    <!-- SweetAlert2 for nice toasts/dialogs -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <style>
        .fade-card { opacity:0; transform: translateY(18px); transition: all .45s cubic-bezier(.2,.9,.3,1); }
        .fade-card.show { opacity:1; transform: translateY(0); }
        @keyframes cartPulse { 0%{transform:scale(1);}50%{transform:scale(1.25);}100%{transform:scale(1);} }
        .cart-pulse { animation: cartPulse 0.7s ease; }
    </style>
</head>
<body class="bg-gray-50 text-gray-800">

<!-- NAVBAR INCLUDE -->
<jsp:include page="navbar.jsp" />

<div class="max-w-7xl mx-auto px-4 mt-10">

    <h2 class="text-2xl font-semibold mb-4">
        Category Products
    </h2>

    <!-- Product Grid -->
    <div id="product-container" class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-6 mt-5">

        <!-- Loading skeletons -->
        <div class="h-72 rounded-lg bg-white shadow animate-pulse"></div>
        <div class="h-72 rounded-lg bg-white shadow animate-pulse"></div>
        <div class="h-72 rounded-lg bg-white shadow animate-pulse"></div>
        <div class="h-72 rounded-lg bg-white shadow animate-pulse"></div>

    </div>

</div>

<!-- FOOTER INCLUDE -->
<jsp:include page="footer.jsp" />

<script>
(function($){

    // HTML escape helper
    function escapeHtml(str){
        if(!str) return '';
        return String(str).replace(/[&<>"'`=\/]/g,function(s){
            return ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;','/':'&#x2F;','`':'&#x60;','=':'&#x3D;'})[s];
        });
    }

    // Render product cards
    function renderProducts(items){
        var $p = $('#product-container').empty();
        if (!items || items.length === 0){
            $p.html('<div class="col-span-4 text-gray-500 p-6 text-center">No products in this category.</div>');
            return;
        }

        for (var i=0;i<items.length;i++){
            var it = items[i] || {};
            var card = $(
                '<div class="bg-white rounded-lg shadow p-3 flex flex-col fade-card">' +
                  '<div class="h-40 w-full overflow-hidden rounded-md bg-gray-100 flex items-center justify-center">' +
                    '<img src="'+(it.image||"https://via.placeholder.com/400")+'" alt="'+escapeHtml(it.name||'')+'" class="w-full h-full object-cover"/>' +
                  '</div>' +
                  '<div class="mt-3 flex-1 flex flex-col">' +
                    '<h3 class="font-semibold">'+escapeHtml(it.name||'Unnamed')+'</h3>' +
                    '<p class="text-sm text-gray-500 mt-1 truncate">'+escapeHtml(it.description||"")+'</p>' +
                    '<div class="mt-3 flex items-center justify-between">' +
                        '<span class="text-green-700 font-bold">₹'+(it.price||0)+'</span>' +
                        '<span class="line-through text-gray-400 text-sm">'+(it.mrp ? '₹'+it.mrp : '')+'</span>' +
                    '</div>' +
                    '<div class="text-xs text-gray-500 mt-1">Stock: '+(it.stock!=null ? it.stock : 'N/A')+'</div>' +
                    '<div class="mt-3 grid grid-cols-2 gap-2">' +
                        '<button class="buy-now py-2 rounded border border-green-700 text-green-700" data-id="'+(it.id||'')+'">Buy Now</button>' +
                        '<button class="add-to-cart py-2 rounded bg-green-700 text-white" data-id="'+(it.id||'')+'">Add to Cart</button>' +
                    '</div>' +
                  '</div>' +
                '</div>'
            );
            (function(el,delay){ setTimeout(function(){ el.addClass('show'); }, delay); })(card, i*80);
            $p.append(card);
        }
    }

    // Pulse cart-count element to draw attention after add
    function pulseCartCount(){
        var $cc = $('#cart-count');
        if (!$cc.length) return;
        $cc.addClass('cart-pulse');
        setTimeout(function(){ $cc.removeClass('cart-pulse'); }, 900);
    }

    // Safely get category id from JSP variable
    var categoryParam = "<%=catId%>"; // declared at top of JSP; safe to use here
    var servletUrl = "<%=request.getContextPath()%>/CategoryProductsServlet";

    function loadCategoryProducts(){
        $.ajax({
            url: servletUrl,
            method: "GET",
            data: { category_id: categoryParam },
            dataType: "json",
            timeout: 10000,
            success: function(data){
                // Expecting an array of products
                renderProducts(Array.isArray(data) ? data : []);
            },
            error: function(xhr, status, err){
                console.error("Error loading category:", status, err);
                // If server returned HTML stacktrace, show concise message and provide option to view raw response
                var message = 'Failed to load products.';
                $('#product-container').html('<div class="col-span-4 text-red-500 p-6 text-center">'+message+' <br/><small>Check console/network for details.</small></div>');

                // Optional: show raw response in a SweetAlert for debugging (if content not too large)
                var resp = xhr.responseText || '';
                if (resp && resp.length < 10000) {
                    Swal.fire({
                      title: 'Server response (debug)',
                      html: '<pre style="text-align:left;white-space:pre-wrap;max-height:300px;overflow:auto;">' + $('<div/>').text(resp).html() + '</pre>',
                      width: '75%',
                      icon: 'error'
                    });
                }
            }
        });
    }

    // Bind add-to-cart and buy-now with SweetAlert feedback
    function bindProductActions(){
        $('#product-container').on('click', '.add-to-cart', function(){
            var id = $(this).data('id');
            if(!id){
                Swal.fire({ icon:'error', title:'Missing product id' });
                return;
            }
            $.post(servletUrl = "<%=request.getContextPath()%>/AddToCartServlet", { product_id: id, quantity: 1 }, function(res){
                if (res && res.success){
                    $('#cart-count').text(res.count || 0);
                    pulseCartCount();
                    Swal.fire({
                        toast: true,
                        position: 'top-end',
                        icon: 'success',
                        title: 'Added to cart',
                        showConfirmButton: false,
                        timer: 1400,
                        timerProgressBar: true
                    });
                } else {
                    Swal.fire({
                        icon: 'error',
                        title: 'Could not add',
                        text: (res && res.message) ? res.message : 'Server returned an error.'
                    });
                }
            }, "json").fail(function(xhr, status, err){
                console.error('AddToCart error', status, err);
                Swal.fire({ icon:'error', title:'Network error', text:'Failed to add to cart.' });
            });
        });

        $('#product-container').on('click', '.buy-now', function(){
            var id = $(this).data('id');
            if(!id){
                Swal.fire({ icon:'error', title:'Missing product id' });
                return;
            }
            $.post("<%=request.getContextPath()%>/AddToCartServlet", { product_id: id, quantity: 1 }, function(res){
                if (res && res.success){
                    $('#cart-count').text(res.count || 0);
                    pulseCartCount();
                    Swal.fire({
                        icon: 'success',
                        title: 'Ready to checkout',
                        text: 'Redirecting to checkout...',
                        showConfirmButton: false,
                        timer: 900,
                        timerProgressBar: true
                    }).then(function(){ window.location.href = "<%=request.getContextPath()%>/checkout.jsp"; });
                } else {
                    Swal.fire({ icon:'error', title:'Could not add', text: (res && res.message) ? res.message : 'Server returned an error.' });
                }
            }, "json").fail(function(xhr, status, err){
                console.error('BuyNow AddToCart error', status, err);
                Swal.fire({ icon:'error', title:'Network error', text:'Failed to add to cart.' });
            });
        });
    }

    // Initialize
    $(function(){
        loadCategoryProducts();
        bindProductActions();
    });

})(jQuery);
</script>

</body>
</html>
