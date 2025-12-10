package admin;

import dao.Dbconn;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;

@WebServlet("/admin/UpdateProductServlet")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 5 * 1024 * 1024,
        maxRequestSize = 10 * 1024 * 1024
)
public class UpdateProductServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        try {
            // ---- Read Form Fields ----
            int id = Integer.parseInt(request.getParameter("id"));
            int categoryId = Integer.parseInt(request.getParameter("category_id"));
            String name = request.getParameter("name");
            String description = request.getParameter("description");
            double price = Double.parseDouble(request.getParameter("price"));
            int stock = Integer.parseInt(request.getParameter("stock"));

            String oldImage = request.getParameter("oldImage");

            // ---- Image Upload ----
            Part imagePart = request.getPart("image");
            String finalImage = oldImage;

            if (imagePart != null && imagePart.getSize() > 0) {

                String submittedName = imagePart.getSubmittedFileName();
                String safeName = System.currentTimeMillis() + "_" + submittedName.replaceAll("[^a-zA-Z0-9._-]", "_");

                String uploadPath = request.getServletContext().getRealPath("/images/products");
                File dir = new File(uploadPath);
                if (!dir.exists()) dir.mkdirs();

                File savedFile = new File(dir, safeName);

                try (InputStream in = imagePart.getInputStream()) {
                    Files.copy(in, savedFile.toPath());
                }

                // delete old file
                if (oldImage != null && !oldImage.isBlank()) {
                    File old = new File(dir, oldImage);
                    if (old.exists()) old.delete();
                }

                finalImage = safeName;
            }

            // ---- Update DB ----
            Dbconn db = new Dbconn();
            int rows = db.updateProduct(id, categoryId, name, description, price, price, stock, finalImage, 0);

            if (rows > 0) {
                response.sendRedirect(request.getContextPath() + "/admin/Showproducts.jsp?success=updated");
            } else {
                response.sendRedirect(request.getContextPath() + "/admin/Showproducts.jsp?error=not_updated");
            }

        } catch (Exception e) {
            e.printStackTrace();
            throw new ServletException("Update product failed", e);
        }
    }
}

