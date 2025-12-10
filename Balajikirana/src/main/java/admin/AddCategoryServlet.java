package admin;

import dao.Dbconn;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.*;

@WebServlet("/AddCategoryServlet")
@MultipartConfig
public class AddCategoryServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {

        resp.setContentType("text/html;charset=UTF-8");

        try {
            String name = req.getParameter("name");
            String imageUrl = req.getParameter("imageUrl"); // URL input

            Part part = null;
            try {
                part = req.getPart("image");
            } catch (Exception ex) {
                part = null;
            }

            String finalImagePath = null;

            // CASE 1: File uploaded
            if (part != null && part.getSize() > 0) {

                String originalName = part.getSubmittedFileName();
                String fileName = System.currentTimeMillis() + "_" + originalName;

                // Upload folder path
                String uploadPath = req.getServletContext().getRealPath("") + "category";
                File uploadDir = new File(uploadPath);
                if (!uploadDir.exists()) uploadDir.mkdirs();

                File file = new File(uploadDir, fileName);

                try (InputStream in = part.getInputStream();
                     FileOutputStream out = new FileOutputStream(file)) {

                    byte[] buffer = new byte[1024];
                    int len;
                    while ((len = in.read(buffer)) != -1) {
                        out.write(buffer, 0, len);
                    }
                }

                finalImagePath = "category/" + fileName;
            }

            // CASE 2: Image URL provided (only if no file)
            else if (imageUrl != null && !imageUrl.trim().isEmpty()) {
                finalImagePath = imageUrl.trim();
            }

            // CASE 3: No image at all
            else {
                resp.getWriter().write("<p style='color:red;'>No image or URL provided.</p>");
                return;
            }

            // Insert in DB
            Dbconn db = new Dbconn();
            db.insertCategory(name, finalImagePath);
            db.close();

            resp.getWriter().write("<h2>Category Added Successfully!</h2><a href='admin-add-category.jsp'>Back</a>");

        } catch (Exception e) {
            e.printStackTrace();
            resp.getWriter().write("Error: " + e.getMessage());
        }
    }
}
