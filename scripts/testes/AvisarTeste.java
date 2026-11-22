import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

// Testa o scripts/Avisar.java contra um GitHub falso, local (sem rede).
// Uso, da raiz do repo: java scripts/testes/AvisarTeste.java
public class AvisarTeste {
    public static void main(String[] args) throws Exception {
        List<String> vistos = new ArrayList<>();
        HttpServer srv = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        srv.createContext("/", e -> {
            vistos.add(e.getRequestMethod() + " " + e.getRequestURI().getPath() + " " + e.getRequestHeaders().getFirst("Authorization")
                + " " + new String(e.getRequestBody().readAllBytes()));
            e.sendResponseHeaders(204, -1);
            e.close();
        });
        srv.start();
        Path drive = Files.createTempDirectory("avisar");
        try {
            roda(srv, drive, "status.yml");                                  // sem dispatch.txt: nao faz nada
            confere(vistos.isEmpty(), "sem dispatch.txt nao pode chamar o GitHub");
            Files.writeString(drive.resolve("dispatch.txt"), "﻿tok123\r\nfulano/repo\r\n");
            roda(srv, drive, "status.yml");
            confere(vistos.size() == 1 && vistos.get(0).equals(
                "POST /repos/fulano/repo/actions/workflows/status.yml/dispatches Bearer tok123 {\"ref\":\"main\"}"), "pedido errado: " + vistos);
            roda(srv, drive, "../x");                                        // nome de Action invalido: ignora
            confere(vistos.size() == 1, "aceitou nome de Action invalido");
        } finally {
            srv.stop(0);
        }
        System.out.println("AvisarTeste: ok");
    }

    static void roda(HttpServer srv, Path drive, String fluxo) throws Exception {
        String java = Path.of(System.getProperty("java.home"), "bin", "java").toString();
        ProcessBuilder pb = new ProcessBuilder(java, "scripts/Avisar.java", drive.toString(), fluxo).inheritIO();
        pb.environment().put("MINEZADA_API", "http://127.0.0.1:" + srv.getAddress().getPort());
        if (pb.start().waitFor() != 0) throw new RuntimeException("Avisar saiu com erro");
    }

    static void confere(boolean ok, String msg) {
        if (!ok) throw new RuntimeException(msg);
    }
}
