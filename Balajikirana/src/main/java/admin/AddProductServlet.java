package admin;

import dao.Dbconn;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.*;

@WebServlet("/admin/AddProductServlet")
@MultipartConfig
public class AddProductServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("text/html;charset=UTF-8");

        try {
            int categoryId = Integer.parseInt(req.getParameter("category_id"));
            String name = req.getParameter("name");
            String description = req.getParameter("description");
            double price = Double.parseDouble(req.getParameter("price"));
            double mrp = Double.parseDouble(req.getParameter("mrp"));
            int stock = Integer.parseInt(req.getParameter("stock"));
            int discount = Integer.parseInt(req.getParameter("discount"));

            // IMAGE UPLOAD
            Part part = req.getPart("image");
            String fileName = System.currentTimeMillis() + "_" + part.getSubmittedFileName();

            String uploadPath = req.getServletContext().getRealPath("") + "products";
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) uploadDir.mkdirs();

            File file = new File(uploadDir, fileName);
            try (InputStream in = part.getInputStream();
                 FileOutputStream fos = new FileOutputStream(file)) {
                byte[] buf = new byte[1024];
                int len;
                while ((len = in.read(buf)) != -1) fos.write(buf, 0, len);
            }

            String imagePath = "products/" + fileName;

            // INSERT INTO DB
            Dbconn db = new Dbconn();
            db.insertProduct(categoryId, name, description, price, mrp, stock, imagePath, discount);
            db.close();

            resp.sendRedirect(req.getContextPath() + "/admin/Showproducts.jsp");

        } catch (Exception e) {
            e.printStackTrace();
            resp.getWriter().write("<h3>Error: " + e.getMessage() + "</h3>");
        }
    }
}
