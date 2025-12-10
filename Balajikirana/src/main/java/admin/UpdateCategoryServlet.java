package admin;

import dao.Dbconn;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import jakarta.servlet.ServletException;
import java.io.*;
import java.nio.file.*;

@WebServlet("/admin/UpdateCategoryServlet")
@MultipartConfig
public class UpdateCategoryServlet extends HttpServlet {

    private String saveUploadedFile(Part part, String folder, HttpServletRequest req) throws IOException {
        if (part == null || part.getSize() == 0) return null;

        String submitted = Path.of(part.getSubmittedFileName()).getFileName().toString();
        String filename = System.currentTimeMillis() + "_" + submitted;

        String uploadPath = req.getServletContext().getRealPath("/uploads/" + folder);
        File dir = new File(uploadPath);
        if (!dir.exists()) dir.mkdirs();

        File file = new File(dir, filename);

        try (InputStream in = part.getInputStream()) {
            Files.copy(in, file.toPath(), StandardCopyOption.REPLACE_EXISTING);
        }

        return req.getContextPath() + "/uploads/" + folder + "/" + filename;
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int id = Integer.parseInt(request.getParameter("id"));
        String name = request.getParameter("name");
        Part imagePart = request.getPart("image");

        try {
            Dbconn db = new Dbconn();

            String imageUrl = saveUploadedFile(imagePart, "categories", request);

            // If no new file uploaded → use old image
            if (imageUrl == null) {
                var rs = db.getCategory(id);
                if (rs.next()) {
                    imageUrl = rs.getString("image");
                }
            }

            db.updateCategory(id, name, imageUrl);
            db.close();

            response.sendRedirect(request.getContextPath() + "/admin/Showcategories.jsp?success=1");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() +
                    "/admin/editCategory.jsp?id=" + id + "&error=" + e.getMessage());
        }
    }
}
