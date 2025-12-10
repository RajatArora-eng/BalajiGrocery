<%@ page contentType="text/html;charset=UTF-8" %>
<script src="https://cdn.tailwindcss.com"></script>

<%
    // session protection (optional)
    jakarta.servlet.http.HttpSession s = request.getSession(false);
    if(s == null || s.getAttribute("role") == null || !"admin".equals(s.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/admin/login.jsp");
        return;
    }
%>

<style>
    .slide-in {
        animation: slidein .6s ease forwards;
    }
    @keyframes slidein {
        from { transform: translateX(-20px); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
</style>

<div class="flex min-h-screen">

    <!-- Sidebar -->
    <aside class="w-64 bg-white shadow-xl slide-in">
        <div class="p-6 border-b">
            <h2 class="text-xl font-bold text-green-700">Admin Panel</h2>
            <p class="text-sm text-gray-600 mt-1">
                Hello, <%= s.getAttribute("adminName") %>
            </p>
        </div>

        <nav class="p-4 space-y-2">
            <a href="<%=request.getContextPath()%>/admin/admindashboard.jsp"
               class="block bg-gray-50 hover:bg-green-50 px-4 py-2 rounded transition">
               Dashboard
            </a>

            <a href="<%=request.getContextPath()%>/admin/categories.jsp"
               class="block bg-gray-50 hover:bg-green-50 px-4 py-2 rounded transition">
               Categories
            </a>

            <a href="<%=request.getContextPath()%>/admin/products.jsp"
               class="block bg-gray-50 hover:bg-green-50 px-4 py-2 rounded transition">
               Products
            </a>

            <a href="<%=request.getContextPath()%>/AdminLogoutServlet"
               class="block bg-red-50 text-red-700 hover:bg-red-100 px-4 py-2 rounded transition">
               Logout
            </a>
        </nav>
    </aside>

    <!-- Main section wrapper starts (page content begins after this include) -->
    <main class="flex-1 p-6">
