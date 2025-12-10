<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="dao.Dbconn,java.sql.ResultSet" %>
<script src="https://cdn.tailwindcss.com"></script>
<%
    int id = Integer.parseInt(request.getParameter("id"));
    Dbconn db = new Dbconn();
    ResultSet rs = db.getCategory(id);
    if (!rs.next()) {
        out.println("Category not found"); db.close(); return;
    }
    String name = rs.getString("name");
    String image = rs.getString("image");
%>

<!doctype html>
<html>
<head><meta charset="utf-8"><title>Edit Category</title></head>
<body class="bg-gray-100 min-h-screen p-8">
<%@ include file="/admin/includes/navbar.jsp" %>
  <div class="max-w-xl mx-auto">
    <% if(request.getParameter("success") != null) { %>
      <div class="mb-4 p-3 rounded bg-green-100 border text-green-800 animate-pop">Category updated successfully!</div>
    <% } %>

    <div class="bg-white p-6 rounded-lg shadow">
      <h2 class="text-2xl font-bold text-green-700 mb-4">Edit Category</h2>

      <form action="<%=request.getContextPath()%>/UpdateCategoryServlet" method="post" enctype="multipart/form-data" class="space-y-4">
        <input type="hidden" name="id" value="<%=id%>"/>
        <div>
          <label class="block text-sm font-medium">Name</label>
          <input name="name" value="<%=name%>" required class="w-full rounded border px-3 py-2"/>
        </div>

        <div>
          <label class="block text-sm font-medium">Current Image</label>
          <div class="mt-2">
            <img src="<%=image%>" class="h-28 rounded object-contain"/>
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium">Replace Image (optional)</label>
          <input type="file" name="image" accept="image/*" class="w-full"/>
          <div class="text-xs text-slate-400 mt-1">If left empty, current image remains.</div>
        </div>

        <div class="flex gap-3">
          <button class="bg-green-600 text-white px-4 py-2 rounded">Update</button>
          <a href="<%=request.getContextPath()%>/admin/categories.jsp" class="px-4 py-2 rounded border">Cancel</a>
        </div>
      </form>
    </div>
  </div>

<% db.close(); %>
<%@ include file="/admin/includes/footer.jsp" %>
</body>
</html>
