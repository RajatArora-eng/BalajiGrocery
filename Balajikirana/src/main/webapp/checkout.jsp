<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Checkout - Balaji Grocery</title>
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <script src="https://cdn.tailwindcss.com"></script>

  <style>
    :root{ --brand-green:#1f9d55; --brand-dark:#16663f; --muted:#6b7280; }
    body{ background:#f3f7f5; font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial; }
    .card{ background:white; border-radius:12px; box-shadow:0 10px 28px rgba(16,24,40,0.06); padding:18px; max-width:920px; margin:28px auto; }
    #map{ width:100%; height:240px; border-radius:10px; }
    .label{ font-weight:600; color:var(--brand-dark); font-size:.95rem; }
    .input{ width:100%; padding:.6rem .75rem; border:1px solid #e6efea; border-radius:.6rem; background:#fbfff9; }
    .muted{ color:var(--muted); font-size:.92rem; }
    .btn{ background:var(--brand-green); color:white; padding:.7rem .95rem; border-radius:10px; font-weight:700; }
    .btn:hover{ background:var(--brand-dark); }
    .small-btn{ padding:.45rem .6rem; border-radius:8px; font-weight:600; }
    table.items { width:100%; border-collapse:collapse; margin-top:10px; }
    table.items th, table.items td { border-bottom:1px solid #eee; padding:8px; text-align:left; font-size:13px; }
    table.items th { font-weight:700; color:var(--brand-dark); }
    #bill-area { display:none; padding:12px; background:white; border-radius:8px; }
    @media print { body * { visibility:hidden; } #print-bill, #print-bill * { visibility:visible; } #print-bill { position:absolute; left:0; top:0; width:100%; } }
  </style>
</head>
<body>

<div class="card">
  <h2 class="text-xl font-semibold" style="color:var(--brand-dark)">Checkout</h2>
  <p class="muted mb-4">Fill address manually. Map for precise location.</p>

  <!-- MAP -->
  <div id="map" class="mb-4"></div>

  <!-- ADDRESS FORM -->
  <form id="address-form">
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
      <div>
        <label class="label">Receiver name</label>
        <input id="receiver_name" class="input mt-1" placeholder="e.g. Rajat Arora" required>
      </div>
      <div>
        <label class="label">Contact number</label>
        <input id="contact" class="input mt-1" placeholder="10-digit mobile" inputmode="numeric" required>
      </div>

      <div>
        <label class="label">House / Flat No.</label>
        <input id="house" class="input mt-1" placeholder="House / Flat / Block" required>
      </div>
      <div>
        <label class="label">Street / Landmark</label>
        <input id="landmark" class="input mt-1" placeholder="Near XYZ, Landmark" required>
      </div>

      <div>
        <label class="label">Locality / Area</label>
        <input id="area" class="input mt-1" placeholder="Colony / Society" required>
      </div>
      <div>
        <label class="label">City</label>
        <input id="city" class="input mt-1" placeholder="e.g. Gwalior" required>
      </div>

      <div>
        <label class="label">State</label>
        <input id="state" class="input mt-1" placeholder="e.g. Madhya Pradesh" required>
      </div>
      <div>
        <label class="label">Pincode</label>
        <input id="pincode" class="input mt-1" placeholder="6-digit pincode" inputmode="numeric" required>
      </div>
    </div>

    <div class="mt-4">
      <label class="label">Full formatted address</label>
      <textarea id="address" class="input mt-1" rows="2" placeholder="Flat, street, area, city, state, pincode" required></textarea>
    </div>

    <input type="hidden" id="lat" />
    <input type="hidden" id="lng" />
  </form>

  <div class="divider" style="height:1px;background:#f0f6f2;margin:14px 0;"></div>

  <!-- PRODUCTS SECTION (now visible) -->
  <h3 class="text-lg font-semibold" style="color:var(--brand-dark)">Your Items</h3>
  <div id="products-list" class="mt-2"></div>

  <!-- ORDER SUMMARY -->
  <div class="mt-4">
    <h3 class="text-lg font-semibold" style="color:var(--brand-dark)">Order Summary</h3>
    <div class="muted text-sm mb-2">Review totals below.</div>

    <div class="mb-3">
      <div class="flex justify-between"><div class="muted">Subtotal</div><div id="subtotal">₹0.00</div></div>
      <div class="flex justify-between"><div class="muted">Delivery</div><div id="delivery-charge">₹0.00</div></div>
      <div class="flex justify-between"><div class="muted">Discount</div><div id="discount">₹0.00</div></div>
      <hr style="margin:8px 0"/>
      <div class="flex justify-between font-bold text-lg"><div>Total</div><div id="cart-total">₹0.00</div></div>
    </div>

    <div class="mb-3">
      <label class="label mb-1">Payment Method</label>
      <div class="space-y-2 mt-2">
        <label class="flex items-center gap-3"><input type="radio" name="paytype" value="COD" checked> <span class="muted">Cash On Delivery</span></label>
        <label class="flex items-center gap-3"><input type="radio" name="paytype" value="ONLINE"> <span class="muted">Online (Razorpay)</span></label>
        <label class="flex items-center gap-3"><input type="radio" name="paytype" value="CARD"> <span class="muted">Card (not configured)</span></label>
      </div>
    </div>

    <div class="flex gap-3">
      <button id="place-order-btn" class="btn">Place Order</button>
      <button id="preview-bill-btn" class="small-btn" style="background:#f3f7f5;color:var(--brand-dark);border-radius:8px">Preview Bill</button>
    </div>
  </div>

  <!-- Bill area (hidden, used for print/preview) -->
  <div id="bill-area" class="mt-6">
    <div id="print-bill" style="background:#fff;padding:14px;border-radius:8px;"></div>
    <div class="mt-3 flex gap-2">
      <button id="print-btn" class="small-btn" style="background:#fff;color:var(--brand-dark);border:1px solid #e6efea">Print</button>
    </div>
  </div>
</div>

<script>
  const GMAPS_API_KEY = '';
  const RAZORPAY_KEY = '';

  /* ---------- Google Maps (unchanged behavior) ---------- */
  let map, marker, geocoder, INITIAL_POS = null;
  function requestUserLocationThenLoadMap(){ if(!navigator.geolocation){ loadGoogleMaps(); return; } navigator.geolocation.getCurrentPosition(function(pos){ INITIAL_POS = { lat: pos.coords.latitude, lng: pos.coords.longitude }; loadGoogleMaps(); }, function(){ loadGoogleMaps(); }, { enableHighAccuracy:true, timeout:8000, maximumAge:0 }); }
  function initMap(){ let defaultPos = INITIAL_POS || { lat:26.2183, lng:78.1828 }; map = new google.maps.Map(document.getElementById('map'), { center: defaultPos, zoom: 13 }); marker = new google.maps.Marker({ position: defaultPos, map, draggable:true }); geocoder = new google.maps.Geocoder(); setLatLngFields(defaultPos); reverseGeocodeAndFill(defaultPos); if(INITIAL_POS){ map.setCenter(INITIAL_POS); marker.setPosition(INITIAL_POS); } marker.addListener('dragend', function(){ let p = marker.getPosition(); setLatLngFields({ lat: p.lat(), lng: p.lng() }); reverseGeocodeAndFill({ lat: p.lat(), lng: p.lng() }); }); map.addListener('click', function(e){ marker.setPosition(e.latLng); map.panTo(e.latLng); setLatLngFields({ lat: e.latLng.lat(), lng: e.latLng.lng() }); reverseGeocodeAndFill({ lat: e.latLng.lat(), lng: e.latLng.lng() }); }); marker.addListener('click', function(){ let p = marker.getPosition(); setLatLngFields({ lat: p.lat(), lng: p.lng() }); reverseGeocodeAndFill({ lat: p.lat(), lng: p.lng() }); }); }
  function setLatLngFields(latlng){ document.getElementById('lat').value = latlng.lat; document.getElementById('lng').value = latlng.lng; }
  function reverseGeocodeAndFill(latlng){ if(!geocoder) return; geocoder.geocode({ location: latlng }, function(results, status){ if(status==='OK'&&results&&results[0]){ document.getElementById('address').value = results[0].formatted_address; } }); }
  function loadGoogleMaps(){ if(window.google && window.google.maps){ initMap(); return; } const s=document.createElement('script'); s.src='https://maps.googleapis.com/maps/api/js?key='+encodeURIComponent(GMAPS_API_KEY)+'&callback=initMap'; s.async=true; s.defer=true; document.head.appendChild(s); }
  requestUserLocationThenLoadMap();

  /* ---------- Cart items + totals ---------- */
  let cartTotal = 0, deliveryCharge = 0, discount = 0;
  function formatINR(x){ return '₹' + x.toFixed(2); }

  function loadCartItemsAndTotals(){
    fetch('CartItemsServlet')
      .then(r=>{ if(!r.ok) throw new Error('network'); return r.json(); })
      .then(data=>{
        cartTotal = 0;
        const container = $("#products-list");
        container.empty();
        if(!Array.isArray(data) || data.length===0){
          container.html('<div class="muted">Your cart is empty.</div>');
        } else {
          // build items table
          let tbl = '<table class="items"><thead><tr><th>Product</th><th>Qty</th><th>Price</th><th>Subtotal</th></tr></thead><tbody>';
          data.forEach(it=>{
            const name = it.name || 'Product';
            const qty = parseInt(it.quantity || 1);
            const price = parseFloat(it.price || 0);
            const subtotal = parseFloat(it.subtotal || price * qty);
            cartTotal += subtotal;
            tbl += '<tr><td>' + escapeHtml(name) + '</td><td>' + qty + '</td><td>' + formatINR(price) + '</td><td>' + formatINR(subtotal) + '</td></tr>';
          });
          tbl += '</tbody></table>';
          container.html(tbl);
        }
        deliveryCharge = (cartTotal > 0 && cartTotal < 500) ? 30 : 0;
        discount = 0;
        const total = cartTotal + deliveryCharge - discount;
        $("#subtotal").text(formatINR(cartTotal));
        $("#delivery-charge").text(formatINR(deliveryCharge));
        $("#discount").text(formatINR(discount));
        $("#cart-total").text(formatINR(total));
      })
      .catch(err=>{
        console.error(err);
        $("#products-list").html('<div class="muted">Error loading cart</div>');
        $("#subtotal,#delivery-charge,#discount,#cart-total").text(formatINR(0));
      });
  }

  $(function(){
    loadCartItemsAndTotals();

    $("#preview-bill-btn").click(function(){ buildBillPreview(); });

    $("#place-order-btn").click(function(){
      // validate
      const required = ['receiver_name','contact','house','landmark','area','city','state','pincode','address'];
      for(let id of required){
        let el = document.getElementById(id);
        if(!el || !el.value.trim()){ alert('Please fill: ' + (el ? el.previousElementSibling.innerText : id)); el && el.focus(); return; }
      }
      const payType = $("input[name='paytype']:checked").val();
      const address = buildFormattedAddress();
      const lat = $("#lat").val(), lng = $("#lng").val();
      const totalStr = $("#cart-total").text().replace('₹',''); const totalVal = parseFloat(totalStr) || 0;

      if(payType==='COD'){
        // send order to CreateOrderServlet
        $.post('CreateOrderServlet', { paytype:'COD', address:address, lat:lat, lng:lng }, function(res){
          if(res && res.success){
            alert('Order placed. Order id: ' + res.order_id);
            buildBillPreview(res.order_id, res.total);
            // Automatically send bill text to WhatsApp
            const contact = $("#contact").val().trim();
            if(contact) sendBillTextToWhatsApp(contact);
          } else { alert('Order failed: ' + (res && res.message ? res.message : 'Server error')); }
        }).fail(function(xhr){ console.error(xhr); alert('Server error placing order'); });
      } else if(payType==='ONLINE'){
        if(!RAZORPAY_KEY || RAZORPAY_KEY.indexOf('REPLACE')===0){ alert('Configure RAZORPAY_KEY'); return; }
        startRazorpay(totalVal, address, lat, lng);
      } else {
        alert('Card flow not configured on server. Choose COD or Online.');
      }
    });

    $("#print-btn").click(function(){ if(!$("#print-bill").html().trim()){ alert('Create bill first (Preview Bill)'); return; } window.print(); });
  });

  function buildFormattedAddress(){
    const r = $("#receiver_name").val().trim(), c = $("#contact").val().trim(), h = $("#house").val().trim(), l = $("#landmark").val().trim(), a = $("#area").val().trim(), city = $("#city").val().trim(), s = $("#state").val().trim(), pin = $("#pincode").val().trim(), full = $("#address").val().trim();
    return r + ", " + h + ", " + l + ", " + a + ", " + city + ", " + s + " - " + pin + ". Contact: " + c + " | " + full;
  }

  function buildBillPreview(orderId, totalFromServer){
    const now = new Date(); const dt = now.toLocaleString();
    const receiver = $("#receiver_name").val().trim(); const contact = $("#contact").val().trim(); const addr = $("#address").val().trim();
    fetch('CartItemsServlet').then(r=>r.json()).then(data=>{
      let itemsHtml = '<table style="width:100%;border-collapse:collapse"><thead><tr><th style="text-align:left;padding:6px 0">Item</th><th style="text-align:right;padding:6px 0">Qty</th><th style="text-align:right;padding:6px 0">Price</th><th style="text-align:right;padding:6px 0">Total</th></tr></thead><tbody>';
      let subtotalVal = 0;
      if(Array.isArray(data) && data.length>0){
        data.forEach(it=>{
          const name = it.name || ''; const qty = parseInt(it.quantity||1); const price = parseFloat(it.price||0); const sub = parseFloat(it.subtotal || price*qty); subtotalVal += sub;
          itemsHtml += '<tr><td style="padding:6px 0">'+escapeHtml(name)+'</td><td style="padding:6px 0;text-align:right">'+qty+'</td><td style="padding:6px 0;text-align:right">'+formatINR(price)+'</td><td style="padding:6px 0;text-align:right">'+formatINR(sub)+'</td></tr>';
        });
      } else {
        itemsHtml += '<tr><td colspan="4" style="padding:6px 0">No items</td></tr>';
      }
      itemsHtml += '</tbody></table>';

      const delivery = (subtotalVal>0 && subtotalVal<500) ? 30 : 0; const discount = 0; const total = subtotalVal + delivery - discount;

      let html = '';
      html += '<div style="font-family:Arial,Helvetica,sans-serif;color:#222">';
      html += '<div style="display:flex;justify-content:space-between;align-items:baseline"><div><h1 style="margin:0;color:#16663f">Balaji Grocery</h1><div style="font-size:12px;color:#666">Fresh groceries delivered</div></div><div style="text-align:right;font-size:12px">Date: '+dt+'<br/>Order ID: '+(orderId||'—')+'</div></div>';
      html += '<hr style="margin:8px 0"/>';
      html += '<div style="margin-top:8px"><strong>Deliver To</strong><div style="font-size:13px">'+escapeHtml(receiver)+' — '+escapeHtml(contact)+'</div><div style="font-size:13px;margin-top:4px">'+escapeHtml(addr)+'</div></div>';
      html += '<div style="margin-top:12px">'+itemsHtml+'</div>';
      html += '<div style="margin-top:8px"><div style="display:flex;justify-content:space-between;padding:6px 0"><div>Subtotal</div><div>'+formatINR(subtotalVal)+'</div></div>';
      html += '<div style="display:flex;justify-content:space-between;padding:6px 0"><div>Delivery</div><div>'+formatINR(delivery)+'</div></div>';
      html += '<div style="display:flex;justify-content:space-between;padding:6px 0"><div>Discount</div><div>'+formatINR(discount)+'</div></div>';
      html += '<hr/>';
      html += '<div style="display:flex;justify-content:space-between;font-weight:700;font-size:16px;padding:6px 0"><div>Total</div><div>'+formatINR(total)+'</div></div>';
      html += '<div style="margin-top:12px;font-size:12px;color:#666">This is a system generated bill. For queries call/WhatsApp: ' + escapeHtml($("#contact").val().trim()) + '</div>';
      html += '</div>';
      html += '</div>';

      $("#print-bill").html(html);
      $("#print-bill").data('order-id', orderId || '');
      $("#bill-area").show();
    }).catch(err=>{
      console.error(err); alert('Failed to build bill preview');
    });
  }

  // builds a compact WhatsApp text
  function buildWhatsAppText(){
    const receiver = $("#receiver_name").val().trim(); const contact = $("#contact").val().trim(); const addr = $("#address").val().trim();
    const subtotal = $("#subtotal").text(), delivery = $("#delivery-charge").text(), discount = $("#discount").text(), total = $("#cart-total").text();
    let lines = []; lines.push('Balaji Grocery - Order'); lines.push('Receiver: ' + receiver); lines.push('Contact: ' + contact); lines.push('Address: ' + addr); lines.push(''); lines.push('Subtotal: ' + subtotal); lines.push('Delivery: ' + delivery); lines.push('Discount: ' + discount); lines.push('Total: ' + total); lines.push(''); lines.push('Thank you! BALAJI KIRANA😃🙏🏻🙏🏻');
    return lines.join('\n');
  }

  function normalizePhoneForWhatsapp(num){
    let n = (num || '').replace(/\D/g,'');
    if(n.length===10) n = '91' + n; // assume India if 10-digit
    return n;
  }

  function sendBillTextToWhatsApp(rawNumber){
    try {
      const waNumber = normalizePhoneForWhatsapp(rawNumber);
      if(!waNumber){ console.warn('No valid phone to send WhatsApp'); return; }
      const msg = buildWhatsAppText();
      const url = 'https://wa.me/' + encodeURIComponent(waNumber) + '?text=' + encodeURIComponent(msg);
      window.open(url, '_blank');
    } catch(e){
      console.error('WhatsApp send error', e);
    }
  }

  function escapeHtml(s){ if(!s) return ''; return String(s).replace(/[&<>"'`=\/]/g,function(c){ return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;','/':'&#x2F;','`':'&#x60;','=':'&#x3D;'}[c]; }); }

  // Razorpay flow
  function startRazorpay(amountRs, address, lat, lng){
    const amountPaise = Math.round(amountRs * 100);
    const options = {
      key: RAZORPAY_KEY,
      amount: amountPaise,
      currency: "INR",
      name: "Balaji Grocery",
      description: "Order Payment",
      handler: function(response){
        $.post('CreateOrderServlet', { paytype:'ONLINE', payment_id: response.razorpay_payment_id, address: address, lat:lat, lng:lng }, function(res){
          if(res && res.success){
            alert('Payment successful. Order id: ' + res.order_id);
            buildBillPreview(res.order_id, res.total);
            // automatically send bill text
            const contact = $("#contact").val().trim();
            if(contact) sendBillTextToWhatsApp(contact);
          } else { alert('Failed to create order on server: ' + (res && res.message)); }
        }).fail(function(xhr){ console.error(xhr); alert('Server error creating order'); });
      },
      prefill: { contact: $("#contact").val() }
    };
    const rzp = new Razorpay(options);
    rzp.open();
  }
</script>
</body>
</html>
