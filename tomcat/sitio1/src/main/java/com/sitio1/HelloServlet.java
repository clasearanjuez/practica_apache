package com.sitio1;

import java.io.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;

public class HelloServlet extends HttpServlet {

    public void doGet(HttpServletRequest request, HttpServletResponse response)
            throws IOException, ServletException {

        response.setContentType("text/html");
        PrintWriter out = response.getWriter();

        String javaVersion = System.getProperty("java.version");
        String hostname = request.getServerName();
        String tomcatVersion = getServletContext().getServerInfo();

        out.println("<html>");
          out.println("<head><title>Sitio 1</title></head>");
            out.println("<body>");
              out.println("<h1>Hola mundo desde el Sitio 1!</h1>");
              out.println("<p>Java: " + javaVersion + "</p>");
              out.println("<p>Servidor: " + tomcatVersion + "</p>");
              out.println("<p>Hostname: " + hostname + "</p>");
            out.println("</body>");
        out.println("</html>");
    }
}
