<%@ page contentType="text/html;charset=UTF-8" %>
<script src="https://cdn.tailwindcss.com"></script>


<div class="min-h-screen flex items-center justify-center bg-gray-50 py-10">
    <div class="bg-white shadow-lg rounded-xl p-8 w-full max-w-md">

        <h2 class="text-2xl font-bold mb-6 text-center text-green-700">Login</h2>

        <% String err = (String) request.getAttribute("error"); 
           if(err != null) { %>
            <div class="bg-red-100 text-red-700 p-3 rounded mb-4 text-sm">
                <%= err %>
            </div>
        <% } %>

        <form action="AuthServlet" method="post">
            <input type="hidden" name="action" value="login" />

            <label class="block mb-2 text-gray-700">Email</label>
            <input type="email" name="email" required
                   class="w-full px-3 py-2 border rounded focus:ring focus:ring-green-300" />

            <label class="block mt-4 mb-2 text-gray-700">Password</label>
            <input type="password" name="password" required
                   class="w-full px-3 py-2 border rounded focus:ring focus:ring-green-300" />

            <button class="mt-6 bg-green-700 hover:bg-green-800 text-white w-full py-2 rounded-md">
                Login
            </button>

            <p class="text-center text-sm mt-4">
                New user?
                <a href="ragister.jsp" class="text-green-700 underline">Create an account</a>
            </p>
        </form>
    </div>
</div>

<%@ include file="/footer.jsp" %>
