package com.sitio2;

import java.io.*;
import java.time.*;
import java.time.format.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;

public class HelloServlet extends HttpServlet {

    public void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException, ServletException {

        response.setContentType("text/html");
        PrintWriter out = response.getWriter();

        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss"));
        String ip = request.getLocalAddr();

        out.println("<html>");
          out.println("<head><title>Sitio 2</title></head>");
            out.println("<body>");
              out.println("<h1>Hola mundo desde el Sitio 2!</h1>");
              out.println("<p>Fecha y hora: " + timestamp + "</p>");
              out.println("<p>IP del contenedor: " + ip + "</p>");
          out.println("</body>");
        out.println("</html>");
    }
}
