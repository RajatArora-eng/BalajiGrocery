<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*, java.util.*, dao.Dbconn" %>
<%
  // ---- Admin guard ----
  jakarta.servlet.http.HttpSession s = request.getSession(false);
  if (s == null || s.getAttribute("role") == null || !"admin".equalsIgnoreCase((String)s.getAttribute("role"))) {
    response.sendRedirect(request.getContextPath() + "/admin/login.jsp");
    return;
  }

  // ---- Dashboard data ----
  int cntCategories = 0, cntProducts = 0, cntOrders = 0, cntUsers = 0, activeUsers = 0;
  double revenue = 0.0;

  List<String> catLabels = new ArrayList<>();
  List<Integer> catPercents = new ArrayList<>();

  class OrderRow { public int id; public String customer; public int items; public double total; public String status; public Timestamp createdAt; }
  class UserRow { public int id; public String name; public String email; public String phone; public Timestamp createdAt; }

  List<OrderRow> recentOrders = new ArrayList<>();
  List<UserRow> recentUsers = new ArrayList<>();

  Dbconn db = null;
  Connection conn = null;
  try {
    db = new Dbconn();
    conn = db.getConnection();

    // counts
    try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) AS cnt FROM categories");
         ResultSet rs = ps.executeQuery()) { if (rs.next()) cntCategories = rs.getInt("cnt"); }

    try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) AS cnt FROM products");
         ResultSet rs = ps.executeQuery()) { if (rs.next()) cntProducts = rs.getInt("cnt"); }

    try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) AS cnt, COALESCE(SUM(total_amount),0) AS rev FROM orders");
         ResultSet rs = ps.executeQuery()) { if (rs.next()) { cntOrders = rs.getInt("cnt"); revenue = rs.getDouble("rev"); } }

    try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) AS cnt FROM users");
         ResultSet rs = ps.executeQuery()) { if (rs.next()) cntUsers = rs.getInt("cnt"); }

    try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(DISTINCT user_id) AS active FROM orders WHERE created_at >= (NOW() - INTERVAL 1 DAY)");
         ResultSet rs = ps.executeQuery()) { if (rs.next()) activeUsers = rs.getInt("active"); }
    catch (SQLException ignore) { /* if INTERVAL not supported keep 0 */ }

    // category distribution by product count
    String catSql = "SELECT c.name, COUNT(p.id) AS cnt " +
                    "FROM categories c LEFT JOIN products p ON p.category_id = c.id " +
                    "GROUP BY c.id, c.name ORDER BY cnt DESC";
    List<Integer> catCounts = new ArrayList<>();
    int totalCount = 0;
    try (PreparedStatement ps = conn.prepareStatement(catSql);
         ResultSet rs = ps.executeQuery()) {
      while (rs.next()) {
        String nm = rs.getString("name");
        int cnt = rs.getInt("cnt");
        catLabels.add(nm);
        catCounts.add(cnt);
        totalCount += cnt;
      }
    }
    for (int cnt : catCounts) {
      if (totalCount == 0) catPercents.add(0);
      else catPercents.add((int)Math.round((cnt * 100.0) / totalCount));
    }

    // recent orders
    String recentSql = "SELECT o.id, o.total_amount, o.status, o.created_at, u.name AS customer, " +
                       "(SELECT COUNT(*) FROM order_items oi WHERE oi.order_id = o.id) AS items " +
                       "FROM orders o LEFT JOIN users u ON o.user_id = u.id " +
                       "ORDER BY o.created_at DESC LIMIT 8";
    try (PreparedStatement ps = conn.prepareStatement(recentSql);
         ResultSet rs = ps.executeQuery()) {
      while (rs.next()) {
        OrderRow r = new OrderRow();
        r.id = rs.getInt("id");
        r.customer = rs.getString("customer");
        r.items = rs.getInt("items");
        r.total = rs.getDouble("total_amount");
        r.status = rs.getString("status");
        r.createdAt = rs.getTimestamp("created_at");
        recentOrders.add(r);
      }
    }

    // recent users
    String usersSql = "SELECT id, name, email, phone, created_at FROM users ORDER BY created_at DESC LIMIT 6";
    try (PreparedStatement ps = conn.prepareStatement(usersSql);
         ResultSet rs = ps.executeQuery()) {
      while (rs.next()) {
        UserRow u = new UserRow();
        u.id = rs.getInt("id");
        u.name = rs.getString("name");
        u.email = rs.getString("email");
        u.phone = rs.getString("phone");
        u.createdAt = rs.getTimestamp("created_at");
        recentUsers.add(u);
      }
    }

  } catch (Exception e) {
    e.printStackTrace();
  } finally {
    try { if (db != null) db.close(); } catch (Exception ignored) {}
  }
%>

<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Admin Dashboard — Balaji Grocery</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3.12.2/dist/gsap.min.js"></script>

  <style>
    .gradient-anim {
      background: linear-gradient(90deg,#06b6d4,#4f46e5,#f97316);
      background-size: 300% 300%;
      animation: gradientShift 8s ease infinite;
    }
    @keyframes gradientShift {
      0%{background-position:0% 50%}
      50%{background-position:100% 50%}
      100%{background-position:0% 50%}
    }

    @keyframes popIn {
      0%{opacity:0;transform:translateY(10px) scale(.995)}
      60%{opacity:1;transform:translateY(-6px) scale(1.02)}
      100%{opacity:1;transform:translateY(0) scale(1)}
    }
    .animate-pop { animation: popIn 560ms cubic-bezier(.2,.9,.3,1) both; }

    .card-shadow { box-shadow: 0 6px 24px rgba(17,24,39,0.06); }
    .mini { font-size: .82rem; color: #64748b; }

    .progress-track { background: #f1f5f9; height: 12px; border-radius: 999px; overflow: hidden; }
    .progress-fill { height: 100%; border-radius: 999px; transform-origin: left center; }

    .order-row { transform-origin: 0 0; }
    .status-chip { display:inline-block; padding:6px 10px; border-radius:999px; font-size:0.75rem; color:#fff; }
    .status-complete { background:#10b981; }
    .status-pending  { background:#f59e0b; }
    .status-other    { background:#0ea5e9; }
  </style>
</head>


<body class="antialiased bg-slate-50 text-slate-800">
  <div class="min-h-screen flex">
    <!-- Sidebar -->
    <aside class="w-72 bg-white h-screen shadow-md p-6 sticky top-0 flex flex-col">
      <div class="mb-6">
        <div class="text-2xl font-extrabold">Admin Panel</div>
        <div class="mt-2 text-xs text-slate-500">Welcome back,</div>
        <div class="mt-1 text-lg font-semibold text-slate-700">
          <%= (String)((s.getAttribute("adminName")!=null)?s.getAttribute("adminName"):s.getAttribute("userName")) %>
        </div>
      </div>

      <nav class="mt-6 space-y-2 flex-1">
        <a href="<%= request.getContextPath() %>/admin/admindashboard.jsp"
           class="group flex items-center gap-3 p-3 rounded-lg bg-slate-50 text-slate-900">
          <span class="w-8 h-8 bg-green-100 text-green-700 rounded flex items-center justify-center">🏠</span>
          <span class="font-medium">Overview</span>
        </a>

        <a href="<%= request.getContextPath() %>/admin/Showcategories.jsp"
           class="group flex items-center gap-3 p-3 rounded-lg hover:bg-slate-50 transition">
          <span class="w-8 h-8 bg-indigo-100 text-indigo-700 rounded flex items-center justify-center">📂</span>
          <span class="font-medium">Categories</span>
        </a>

        <a href="<%= request.getContextPath() %>/admin/Showproducts.jsp"
           class="group flex items-center gap-3 p-3 rounded-lg hover:bg-slate-50 transition">
          <span class="w-8 h-8 bg-yellow-100 text-yellow-700 rounded flex items-center justify-center">📦</span>
          <span class="font-medium">Products</span>
        </a>

        <!-- IMPORTANT: Users & Orders go to SERVLETS -->
        <a href="<%= request.getContextPath() %>/admin/ShowUsersServlet"
           class="group flex items-center gap-3 p-3 rounded-lg hover:bg-slate-50 transition">
          <span class="w-8 h-8 bg-fuchsia-100 text-fuchsia-700 rounded flex items-center justify-center">👤</span>
          <span class="font-medium">Users</span>
        </a>

        <a href="<%= request.getContextPath() %>/admin/ShowOrdersServlet"
           class="group flex items-center gap-3 p-3 rounded-lg hover:bg-slate-50 transition">
          <span class="w-8 h-8 bg-cyan-100 text-cyan-700 rounded flex items-center justify-center">🛒</span>
          <span class="font-medium">Orders</span>
        </a>
      </nav>

      <div class="mt-6 text-xs text-slate-500">
        Tip: Hover cards to see subtle motion.  
      </div>
    </aside>

    <!-- Content -->
    <main class="flex-1 p-8">
      <!-- Header -->
      <header class="rounded-lg overflow-hidden mb-8 gradient-anim text-white p-6 shadow-lg relative">
        <div class="flex items-center justify-between gap-4">
          <div>
            <h1 class="text-3xl font-bold leading-tight">
              Welcome back,
              <span class="underline decoration-white/30">
                <%= (String)((s.getAttribute("adminName")!=null)?s.getAttribute("adminName"):s.getAttribute("userName")) %>
              </span>
            </h1>
            <p class="mt-2 text-white/90">Animated overview of users, orders, products and categories.</p>
          </div>

          <div class="flex items-center gap-3">
            <div class="bg-white/20 rounded-full px-4 py-2 text-sm">
              <div class="mini">Active users (24h)</div>
              <div id="activeUsers" class="font-semibold"><%= activeUsers %></div>
            </div>
            <div class="bg-white/10 rounded-lg p-3 text-sm">
              <div class="mini">Total revenue</div>
              <div class="font-semibold">₹<%= String.format("%.2f", revenue) %></div>
            </div>
          </div>
        </div>
      </header>

      <!-- Stat cards -->
      <section class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <div class="bg-white p-6 rounded-lg card-shadow transform hover:scale-[1.02] transition animate-pop">
          <div class="flex items-start justify-between">
            <div>
              <div class="mini">Users</div>
              <div class="mt-2 text-2xl font-bold" id="countUsers"><%= cntUsers %></div>
              <div class="mini text-slate-500 mt-2">Registered customers.</div>
            </div>
            <div class="text-3xl text-slate-300">👤</div>
          </div>
        </div>

        <div class="bg-white p-6 rounded-lg card-shadow transform hover:scale-[1.02] transition animate-pop">
          <div class="flex items-start justify-between">
            <div>
              <div class="mini">Orders</div>
              <div class="mt-2 text-2xl font-bold" id="countOrders"><%= cntOrders %></div>
              <div class="mini text-slate-500 mt-2">Track fulfillment.</div>
            </div>
            <div class="text-3xl text-slate-300">🧾</div>
          </div>
        </div>

        <div class="bg-white p-6 rounded-lg card-shadow transform hover:scale-[1.02] transition animate-pop">
          <div class="flex items-start justify-between">
            <div>
              <div class="mini">Categories</div>
              <div class="mt-2 text-2xl font-bold" id="countCategories"><%= cntCategories %></div>
              <div class="mini text-slate-500 mt-2">Organize inventory.</div>
            </div>
            <div class="text-3xl text-slate-300">📂</div>
          </div>
        </div>

        <div class="bg-white p-6 rounded-lg card-shadow transform hover:scale-[1.02] transition animate-pop">
          <div class="flex items-start justify-between">
            <div>
              <div class="mini">Products</div>
              <div class="mt-2 text-2xl font-bold" id="countProducts"><%= cntProducts %></div>
              <div class="mini text-slate-500 mt-2">Available items.</div>
            </div>
            <div class="text-3xl text-slate-300">📦</div>
          </div>
        </div>
      </section>

      <!-- Main grid: categories + recent orders + recent users -->
      <section class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        <!-- Category share -->
        <div class="bg-white rounded-xl p-4 shadow card-shadow lg:col-span-1">
          <div class="flex items-center justify-between mb-3">
            <h3 class="text-sm font-semibold text-slate-700">Category distribution</h3>
            <div class="mini text-slate-500">By product count</div>
          </div>

          <div id="categoriesList" class="space-y-3">
            <%
              String[] palette = new String[] { "#4f46e5", "#06b6d4", "#10b981", "#f59e0b", "#ef4444" };
              for (int i = 0; i < catLabels.size(); i++) {
                String lbl = catLabels.get(i);
                int pct = catPercents.get(i);
                String color = palette[i % palette.length];
            %>
              <div class="flex items-center justify-between">
                <div class="flex-1 pr-4">
                  <div class="flex items-center justify-between">
                    <div class="font-medium"><%= lbl %></div>
                    <div class="mini text-slate-500"><%= pct %>%</div>
                  </div>
                  <div class="mt-2 progress-track">
                    <div class="progress-fill"
                         data-fill="<%= pct %>"
                         style="width:0%; background: linear-gradient(90deg, <%= color %> 0%, rgba(0,0,0,0.08) 100%);"></div>
                  </div>
                </div>
              </div>
            <% } %>

            <% if (catLabels.isEmpty()) { %>
              <div class="mini text-slate-500 mt-2">No categories yet.</div>
            <% } %>
          </div>
        </div>

        <!-- Recent orders -->
        <div class="bg-white rounded-xl p-4 shadow card-shadow lg:col-span-2">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-semibold text-slate-700">Recent Orders</h3>
            <a href="<%= request.getContextPath() %>/admin/ShowOrdersServlet"
               class="mini text-blue-600 hover:underline">View all</a>
          </div>

          <div id="recentOrders" class="space-y-2">
            <% for (OrderRow r : recentOrders) {
                 String st = (r.status==null) ? "" : r.status;
                 String chipClass = "status-other";
                 if ("Complete".equalsIgnoreCase(st)) chipClass = "status-complete";
                 else if ("Pending".equalsIgnoreCase(st)) chipClass = "status-pending";
            %>
              <div class="order-row bg-white border rounded p-3 flex items-center justify-between" data-id="<%= r.id %>">
                <div class="flex items-center gap-4">
                  <div class="text-slate-500 mini">#<%= r.id %></div>
                  <div>
                    <div class="font-medium"><%= (r.customer==null?"Guest":r.customer) %></div>
                    <div class="mini text-slate-500">
                      Items: <%= r.items %> ·
                      <%= r.createdAt != null ? r.createdAt.toLocalDateTime().toLocalDate().toString() : "" %>
                    </div>
                  </div>
                </div>

                <div class="flex items-center gap-4">
                  <div class="text-right">
                    <div class="font-semibold">₹<%= String.format("%.2f", r.total) %></div>
                  </div>
                  <div><span class="status-chip <%= chipClass %>"><%= (st.isEmpty() ? "-" : st) %></span></div>
                  <div>
                    <a href="<%= request.getContextPath() %>/admin/orderDetails.jsp?id=<%= r.id %>"
                       class="text-blue-600 hover:underline mini">View</a>
                  </div>
                </div>
              </div>
            <% } %>

            <% if (recentOrders.isEmpty()) { %>
              <div class="mini text-slate-500">No orders yet.</div>
            <% } %>
          </div>
        </div>
      </section>

      <!-- Recent users + quick actions -->
      <section class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Recent users -->
        <div class="bg-white rounded-xl p-4 shadow card-shadow lg:col-span-2">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-sm font-semibold text-slate-700">Recent Users</h3>
            <a href="<%= request.getContextPath() %>/admin/ShowUsersServlet"
               class="mini text-blue-600 hover:underline">Manage all</a>
          </div>

          <div class="space-y-2">
            <% for (UserRow u : recentUsers) { %>
              <div class="bg-white border rounded p-3 flex items-center justify-between">
                <div>
                  <div class="font-medium"><%= u.name %> <span class="mini text-slate-400">#<%= u.id %></span></div>
                  <div class="mini text-slate-500">
                    <%= u.email %> · <%= (u.phone == null ? "No phone" : u.phone) %>
                  </div>
                </div>
                <div class="text-right mini text-slate-500">
                  <%= u.createdAt != null ? u.createdAt.toLocalDateTime().toLocalDate().toString() : "-" %>
                </div>
              </div>
            <% } %>

            <% if (recentUsers.isEmpty()) { %>
              <div class="mini text-slate-500">No users yet.</div>
            <% } %>
          </div>
        </div>

        <!-- Quick actions -->
        <div class="space-y-4">
          <div class="bg-gradient-to-br from-white to-slate-50 border p-6 rounded-lg shadow-sm hover:translate-y-[-6px] transition transform">
            <div class="flex items-center justify-between">
              <div>
                <h4 class="font-semibold">Add Product</h4>
                <div class="mini mt-1 text-slate-500">Open full add product form.</div>
              </div>
              <a href="<%= request.getContextPath() %>/admin/products.jsp"
                 class="inline-flex items-center gap-2 bg-green-600 hover:bg-green-700 text-white px-3 py-2 rounded shadow-sm">Add</a>
            </div>
          </div>

          <div class="bg-white p-6 rounded-lg shadow-sm">
            <h4 class="font-semibold">Stock Alerts</h4>
            <div class="mini mt-1 text-slate-500">Low-stock products can be shown here later.</div>
          </div>

          <div class="bg-white p-6 rounded-lg shadow-sm">
            <h4 class="font-semibold">Today’s Snapshot</h4>
            <div class="mini mt-1 text-slate-500">Use this card for notes or quick metrics.</div>
          </div>
        </div>
      </section>
    </main>
    
  </div>
<%@ include file="/admin/includes/footer.jsp" %>
  <script>
    document.addEventListener('DOMContentLoaded', function () {
      function animateNumber(el, to, duration = 900) {
        if (!el) return;
        const start = 0;
        const startTime = performance.now();
        function step(now) {
          const progress = Math.min((now - startTime) / duration, 1);
          const val = Math.floor(progress * (to - start) + start);
          el.textContent = val.toLocaleString();
          if (progress < 1) requestAnimationFrame(step);
        }
        requestAnimationFrame(step);
      }

      animateNumber(document.getElementById('countUsers'), parseInt('<%= cntUsers %>') || 0, 900);
      animateNumber(document.getElementById('countOrders'), parseInt('<%= cntOrders %>') || 0, 900);
      animateNumber(document.getElementById('countCategories'), parseInt('<%= cntCategories %>') || 0, 900);
      animateNumber(document.getElementById('countProducts'), parseInt('<%= cntProducts %>') || 0, 900);

      const activeEl = document.getElementById('activeUsers');
      if (activeEl) animateNumber(activeEl, parseInt('<%= activeUsers %>') || 0, 900);

      document.querySelectorAll('.progress-fill').forEach(function (el, idx) {
        const pct = parseInt(el.getAttribute('data-fill') || '0', 10);
        if (window.gsap) {
          gsap.to(el, { width: pct + "%", duration: 1.0, delay: idx * 0.12, ease: 'power3.out' });
        } else {
          el.style.width = pct + "%";
        }
      });

      const rows = document.querySelectorAll('#recentOrders .order-row');
      if (window.gsap && rows.length) {
        gsap.from(rows, { y: 18, opacity: 0, stagger: 0.08, duration: 0.6, ease: 'power3.out' });
      }
    });
  </script>
 
</body>
</html>
