<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<jsp:include page="/navbar.jsp" />

<!doctype html>
<html>
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Cart — Balaji Grocery</title>
  <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 text-gray-800">

<main class="max-w-6xl mx-auto p-6">
  <h1 class="text-2xl font-bold mb-4">Your Cart</h1>

  <div id="cart-wrapper" class="bg-white rounded-lg shadow p-4">
    <div id="cart-empty" class="hidden text-center py-16">
      <svg class="mx-auto h-16 w-16 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13l-1.5 7H19"/></svg>
      <p class="mt-4 text-gray-500">Your cart is empty. <a href="<%=request.getContextPath()%>/" class="text-green-600 underline">Start shopping</a></p>
    </div>

    <div id="cart-content" class="hidden">
      <div class="overflow-x-auto">
        <table class="w-full table-auto">
          <thead class="text-left text-sm text-gray-600">
            <tr>
              <th class="p-3">Product</th>
              <th class="p-3">Price</th>
              <th class="p-3">Quantity</th>
              <th class="p-3 text-right">Subtotal</th>
              <th class="p-3"></th>
            </tr>
          </thead>
          <tbody id="cart-items" class="divide-y"></tbody>
        </table>
      </div>

      <div class="mt-6 flex flex-col md:flex-row md:justify-end md:items-center gap-4">
        <div class="flex-1 text-sm text-gray-600">
          <p>Need help? <a href="#" class="text-green-600 underline">Contact support</a></p>
        </div>

        <div class="w-full md:w-1/3 bg-gray-50 p-4 rounded">
          <div class="flex justify-between"><span>Subtotal</span><span id="subtotal">₹0</span></div>
          <div class="flex justify-between mt-2"><span>Delivery</span><span id="delivery">Free</span></div>
          <hr class="my-3">
          <div class="flex justify-between font-bold text-lg"><span>Total</span><span id="total">₹0</span></div>
          <button id="checkout-btn" class="mt-4 w-full bg-green-700 text-white py-2 rounded disabled:opacity-60" disabled>Proceed to Checkout</button>
        </div>
      </div>
    </div>
  </div>
</main>

<jsp:include page="/footer.jsp" />

<script>
  (function(){
    const ctx = '<%=request.getContextPath()%>';

    // endpoints (adjust if your servlet names differ)
    const URL_CART_ITEMS = ctx + '/CartItemsServlet';
    const URL_UPDATE = ctx + '/UpdateCartServlet';
    const URL_REMOVE = ctx + '/RemoveFromCartServlet';
    const URL_COUNT = ctx + '/CartCountServlet';

    const $cartWrapper = $('#cart-wrapper');
    const $cartContent = $('#cart-content');
    const $cartEmpty = $('#cart-empty');
    const $cartItems = $('#cart-items');
    const $subtotal = $('#subtotal');
    const $total = $('#total');
    const $checkout = $('#checkout-btn');

    async function loadCart() {
      try {
        const res = await fetch(URL_CART_ITEMS, { credentials: 'same-origin' });
        if (!res.ok) throw new Error('Network error');
        const items = await res.json(); // expect array
        renderItems(items || []);
        updateNavbarCount();
      } catch(err) {
        console.error('Cart load error', err);
        Swal.fire('Error','Unable to load cart','error');
      }
    }

    function renderItems(items) {
      $cartItems.empty();
      if (!items || items.length === 0) {
        $cartEmpty.removeClass('hidden');
        $cartContent.addClass('hidden');
        $checkout.prop('disabled', true);
        $subtotal.text('₹0'); $total.text('₹0');
        return;
      }

      $cartEmpty.addClass('hidden');
      $cartContent.removeClass('hidden');

      let subtotalVal = 0;
      items.forEach(item => {
        const cartId = item.cart_id || '';
        const pid = item.product_id;
        const name = item.name || 'Product';
        const price = Number(item.price || 0);
        const qty = Number(item.quantity || 1);
        const img = item.image || (ctx + '/assets/placeholder.png');
        const itemSubtotal = Number(item.subtotal || (price * qty));
        subtotalVal += itemSubtotal;

        // build HTML using concatenation (avoids server-side EL parsing)
        var rowHtml = ''
          + '<tr data-product-id="' + pid + '" class="align-top">'
          + '<td class="p-3">'
          + '  <div class="flex items-center gap-3">'
          + '    <img src="' + escapeHtml(img) + '" alt="' + escapeHtml(name) + '" class="h-16 w-16 object-cover rounded">'
          + '    <div>'
          + '      <div class="font-medium">' + escapeHtml(name) + '</div>'
          + '      <div class="text-xs text-gray-500">Product ID: ' + pid + '</div>'
          + '    </div>'
          + '  </div>'
          + '</td>'
          + '<td class="p-3">₹' + price.toFixed(2) + '</td>'
          + '<td class="p-3">'
          + '  <div class="flex items-center gap-2">'
          + '    <button class="qty-dec bg-gray-100 px-2 py-1 rounded">−</button>'
          + '    <input type="number" class="qty-input w-16 p-1 border rounded text-center" value="' + qty + '" min="1" />'
          + '    <button class="qty-inc bg-gray-100 px-2 py-1 rounded">+</button>'
          + '  </div>'
          + '</td>'
          + '<td class="p-3 text-right font-semibold">₹<span class="item-subtotal">' + itemSubtotal.toFixed(2) + '</span></td>'
          + '<td class="p-3 text-right">'
          + '  <button class="remove-item text-red-600 underline">Remove</button>'
          + '</td>'
          + '</tr>';

        var row = $(rowHtml);

        // bind events (use closures to capture row)
        (function(rowRef){
          rowRef.find('.qty-inc').on('click', function(){
            const cur = Number(rowRef.find('.qty-input').val()||1);
            changeQty(pid, cur + 1, rowRef);
          });
          rowRef.find('.qty-dec').on('click', function(){
            const cur = Number(rowRef.find('.qty-input').val()||1);
            if (cur > 1) changeQty(pid, cur - 1, rowRef);
          });
          rowRef.find('.qty-input').on('change', function(){
            let v = Number($(this).val());
            if (!v || v < 1) { $(this).val(1); v = 1; }
            changeQty(pid, v, rowRef);
          });
          rowRef.find('.remove-item').on('click', function(){ removeItem(pid); });
        })(row);

        $cartItems.append(row);
      });

      $subtotal.text('₹' + subtotalVal.toFixed(2));
      $total.text('₹' + subtotalVal.toFixed(2)); // delivery free; adjust if needed
      $checkout.prop('disabled', subtotalVal <= 0);
    }

    // sanitize for simple html insertion
    function escapeHtml(s) {
      if (!s) return '';
      return String(s).replace(/[&<>"'`=\/]/g, function(ch){
        return ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;', "'":'&#39;','/':'&#x2F;','`':'&#x60;','=':'&#x3D;' })[ch] || ch;
      });
    }

    // change quantity (send update to server)
    let qtyLock = {};
    async function changeQty(productId, newQty, row) {
      if (qtyLock[productId]) return;
      qtyLock[productId] = true;
      try {
        const body = new URLSearchParams({ product_id: productId, quantity: newQty });
        const res = await fetch(URL_UPDATE, { method: 'POST', headers: {'Content-Type':'application/x-www-form-urlencoded'}, body });
        const json = await res.json();
        if (json.success) {
          row.find('.qty-input').val(newQty);
          const price = Number(row.find('td').eq(1).text().replace('₹','')||0);
          const newSub = price * newQty;
          row.find('.item-subtotal').text(newSub.toFixed(2));
          recalcTotals();
          if (json.count !== undefined) $('#cart-count').text(json.count);
        } else {
          Swal.fire('Error', json.message || 'Could not update cart', 'error');
        }
      } catch(err) {
        console.error(err);
        Swal.fire('Error','Failed to update quantity','error');
      } finally {
        qtyLock[productId] = false;
      }
    }

    // remove item
    async function removeItem(productId) {
      const r = await Swal.fire({
        title: 'Remove item?',
        text: 'Are you sure you want to remove this item from cart?',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonText: 'Yes, remove'
      });
      if (!r.isConfirmed) return;

      try {
        const body = new URLSearchParams({ product_id: productId });
        const res = await fetch(URL_REMOVE, { method: 'POST', headers: {'Content-Type':'application/x-www-form-urlencoded'}, body });
        const json = await res.json();
        if (json.success) {
          Swal.fire({ icon:'success', title:'Removed', timer:900, showConfirmButton:false });
          loadCart();
          if (json.count !== undefined) $('#cart-count').text(json.count);
        } else {
          Swal.fire('Error', json.message || 'Could not remove', 'error');
        }
      } catch(err) {
        console.error(err);
        Swal.fire('Error','Failed to remove item','error');
      }
    }

    function recalcTotals() {
      let sum = 0;
      $cartItems.find('tr').each(function(){
        const sub = Number($(this).find('.item-subtotal').text() || 0);
        sum += sub;
      });
      $subtotal.text('₹' + sum.toFixed(2));
      $total.text('₹' + sum.toFixed(2));
      $checkout.prop('disabled', sum <= 0);
    }

    // update cart count in navbar
    async function updateNavbarCount() {
      try {
        const r = await fetch(URL_COUNT);
        if (!r.ok) return;
        const json = await r.json();
        if (json.count !== undefined) $('#cart-count').text(json.count);
      } catch(e){ console.error(e); }
    }

    // checkout click (example: redirect)
    $checkout.on('click', function(){
      window.location.href = ctx + '/checkout.jsp';
    });

    // init
    $(function(){ loadCart(); });

  })();
</script>
</body>
</html>
