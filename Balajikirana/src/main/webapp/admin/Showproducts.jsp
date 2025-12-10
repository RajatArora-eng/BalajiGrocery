<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="dao.Dbconn,java.sql.ResultSet" %>
<script src="https://cdn.tailwindcss.com"></script>
<%
    Dbconn db = new Dbconn();
    ResultSet rs = db.getProducts(null, null); // default sorting
%>
<!doctype html>
<html>
<head><meta charset="utf-8"><title>Products - Admin</title></head>
<body class="bg-gray-100 min-h-screen p-8">
  <div class="max-w-6xl mx-auto">
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold">Products</h1>
      <!-- agar aapka add page addProduct.jsp hai to isi link par bhejo -->
      <a href="<%=request.getContextPath()%>/admin/products.jsp" class="bg-green-600 text-white px-4 py-2 rounded">Add Product</a>
    </div>

    <% if(request.getParameter("success") != null) { %>
      <div class="mb-4 p-3 rounded bg-green-100 border text-green-800">Done.</div>
    <% } else if(request.getParameter("error") != null) { %>
      <div class="mb-4 p-3 rounded bg-red-100 border text-red-800"><%=request.getParameter("error")%></div>
    <% } %>

    <div class="bg-white p-4 rounded shadow overflow-x-auto">
      <table class="w-full table-auto">
        <thead>
          <tr class="text-left border-b">
            <th class="py-2">#</th>
            <th>Name</th>
            <th>Category</th>
            <th>Price</th>
            <th>MRP</th>
            <th>Stock</th>
            <th>Image</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <%
            int idx=1;
            while(rs.next()) {
              int id = rs.getInt("id");
              String name = rs.getString("name");
              String cat = rs.getString("category_name");
              double price = rs.getDouble("price");
              double mrp = rs.getDouble("mrp");
              int stock = rs.getInt("stock");
              String image = rs.getString("image");
              // decide image src: if DB stores only filename, use contextPath + /images/products/<filename>
              String imgSrc;
              if (image == null || image.isBlank() || "null".equals(image)) {
                  imgSrc = request.getContextPath() + "/images/no-image.png"; // optional placeholder
              } else if (image.startsWith("http://") || image.startsWith("https://") || image.startsWith("/")) {
                  imgSrc = image; // already full/absolute path
              } else {
                  imgSrc = request.getContextPath() + "/images/products/" + image; // assumed filename
              }
          %>
          <tr class="border-b">
            <td class="py-3"><%=idx++%></td>
            <td><%=name%></td>
            <td><%=cat%></td>
            <td>₹<%=price%></td>
            <td>₹<%=mrp%></td>
            <td><%=stock%></td>
            <td><img src="<%=imgSrc%>" class="h-16 object-contain"/></td>
            <td class="space-x-2">
              <!-- FIXED: use id variable here (not p.get(...)) -->
              <a href="<%=request.getContextPath()%>/admin/EditProductServlet?id=<%=id%>" 
   class="px-3 py-1 rounded bg-blue-600 text-white">Edit</a>

              <form action="<%=request.getContextPath()%>/admin/DeleteProductServlet" method="post" style="display:inline" onsubmit="return confirm('Delete this product?');">
                <input type="hidden" name="id" value="<%=id%>"/>
                <button class="px-3 py-1 rounded bg-red-600 text-white">Delete</button>
              </form>
            </td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>
  </div>
<% db.close(); %>
</body>
</html>
