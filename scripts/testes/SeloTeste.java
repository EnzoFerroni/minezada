import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

// Testa o scripts/Selo.java contra um GitHub falso, local (sem rede).
// Uso, da raiz do repo: java scripts/testes/SeloTeste.java
public class SeloTeste {
    static final List<String> erros = new ArrayList<>();
    static final List<String> pedidos = new ArrayList<>();
    static int resposta = 204;
    static String base;

    public static void main(String[] args) throws Exception {
        HttpServer srv = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        srv.createContext("/", SeloTeste::responde);
        srv.start();
        base = "http://127.0.0.1:" + srv.getAddress().getPort();
        Path drive = Files.createTempDirectory("minezada-drive");

        // Sem dispatch.txt: nao faz nada.
        int s = roda(drive, "ligou");
        if (s != 0 || !pedidos.isEmpty()) erros.add("sem dispatch.txt: saiu com " + s + " e fez " + pedidos);

        Files.writeString(drive.resolve("dispatch.txt"), "﻿token-de-teste\nalguem/pack\n");
        for (String m : List.of("ligou", "ligado", "desligou")) {
            s = roda(drive, m);
            if (s != 0) erros.add(m + ": saiu com " + s);
        }
        List<String> quer = List.of("ligou", "ligado", "desligou");
        if (!pedidos.equals(quer)) erros.add("pedidos: " + pedidos + ", esperado " + quer);

        // Motivo errado nem chega no GitHub; token sem permissao avisa e sai com 1.
        if (roda(drive, "qualquer") != 2) erros.add("motivo errado deveria sair com 2");
        resposta = 403;
        if (roda(drive, "ligou") != 1) erros.add("token sem permissao deveria sair com 1");

        srv.stop(0);
        if (!erros.isEmpty()) {
            System.out.println("FALHA selo:\n  " + String.join("\n  ", erros));
            System.exit(1);
        }
        System.out.println("ok    selo");
    }

    static int roda(Path drive, String motivo) throws Exception {
        String java = Path.of(System.getProperty("java.home"), "bin", "java").toString();
        ProcessBuilder pb = new ProcessBuilder(java, "scripts/Selo.java", drive.toString(), motivo).inheritIO();
        pb.environment().put("MINEZADA_API", base);
        return pb.start().waitFor();
    }

    static void responde(HttpExchange x) throws java.io.IOException {
        String corpo = new String(x.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
        if (!x.getRequestMethod().equals("POST") || !x.getRequestURI().getPath().equals("/repos/alguem/pack/actions/workflows/status.yml/dispatches"))
            erros.add("pedido inesperado: " + x.getRequestMethod() + " " + x.getRequestURI());
        if (!"Bearer token-de-teste".equals(x.getRequestHeaders().getFirst("Authorization"))) erros.add("sem o token");
        if (!corpo.contains("\"ref\":\"main\"")) erros.add("sem ref main: " + corpo);
        if (resposta == 204) pedidos.add(corpo.replaceAll(".*\"motivo\":\"(\\w+)\".*", "$1"));
        x.sendResponseHeaders(resposta, -1);
        x.close();
    }
}
